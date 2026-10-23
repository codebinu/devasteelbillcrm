/*
 * UomConversion - reusable, DOM-independent UOM conversion engine.
 *
 * Public API (all results are plain objects: { value, uomId, uomName, error, warning }):
 *   UomConversion.init(uoms, types)            Load configuration once.
 *       uoms:  [{ tum_id, tum_name, tum_type_id, tum_convertion_fac }]   (tbl_item_uom)
 *       types: [{ tumt_id, tumt_name, tum_id }]                          (tbl_item_uom_type; tum_id = default UOM)
 *   UomConversion.findUom(id)                  UOM record or null.
 *   UomConversion.findType(typeId)             Category record or null.
 *   UomConversion.getDefaultUom(typeId)        Default UOM record of a category, or null.
 *   UomConversion.getTypeByName(name)          Category record by name (case-insensitive), or null.
 *   UomConversion.validate(uomId)              { valid, error, uom, type }.
 *   UomConversion.convert(qty, fromId, toId)   Converts between compatible units: qty * fromFac / toFac.
 *   UomConversion.toDefault(qty, uomId)        Converts into the default UOM of the unit's category.
 *   UomConversion.calculateFinalQuantity({ uomId, quantity, length, width })
 *       Length only        -> length converted to the Length category default UOM.
 *       Length and Width   -> (length x width) converted to the Area category default UOM.
 *       Neither            -> quantity converted to its own category default UOM.
 *   UomConversion.checkMasterData()            Array of inconsistency messages.
 *
 * Usage:
 *   UomConversion.init(uomRows, typeRows);
 *   var r = UomConversion.calculateFinalQuantity({ uomId: 5, length: 8, width: 4 });
 *   if (r.error) { ... } else { show(r.value, r.uomName); }
 */
var UomConversion = (function () {
    var uoms = {}, types = {}, typeNames = {}, uomList = [];

    function num(v) {
        var n = parseFloat(v);
        return isNaN(n) ? 0 : n;
    }
    function res(value, uom, error, warning) {
        return {
            value: value,
            uomId: uom ? Number(uom.tum_id) : null,
            uomName: uom ? uom.tum_name : null,
            error: error || null,
            warning: warning || null
        };
    }
    function factor(u) {
        var f = parseFloat(u && u.tum_convertion_fac);
        return (isNaN(f) || f <= 0) ? 0 : f;
    }
    // Round to 4 decimals, avoiding binary floating point artefacts.
    function round(v) {
        return Math.round((v + Number.EPSILON) * 10000) / 10000;
    }

    function init(uomRows, typeRows) {
        uoms = {}; types = {}; typeNames = {}; uomList = uomRows || [];
        for (var i = 0; i < uomList.length; i++) uoms[String(uomList[i].tum_id)] = uomList[i];
        var t = typeRows || [];
        for (var j = 0; j < t.length; j++) {
            types[String(t[j].tumt_id)] = t[j];
            typeNames[String(t[j].tumt_name || "").toLowerCase()] = t[j];
        }
    }
    function findUom(id) { return uoms[String(id)] || null; }
    function findType(id) { return types[String(id)] || null; }
    function getTypeByName(name) { return typeNames[String(name || "").toLowerCase()] || null; }
    function getDefaultUom(typeId) {
        var t = findType(typeId);
        if (!t || !t.tum_id || Number(t.tum_id) <= 0) return null;
        return findUom(t.tum_id);
    }

    function validate(uomId) {
        var u = findUom(uomId);
        if (!u) return { valid: false, error: "Unit of measure is missing or unknown.", uom: null, type: null };
        var t = findType(u.tum_type_id);
        if (!t) return { valid: false, error: "Category of " + u.tum_name + " is not configured.", uom: u, type: null };
        if (!factor(u)) return { valid: false, error: "Conversion factor of " + u.tum_name + " is missing or invalid.", uom: u, type: t };
        return { valid: true, error: null, uom: u, type: t };
    }

    function convert(qty, fromId, toId) {
        var a = validate(fromId), b = validate(toId);
        if (!a.valid) return res(null, null, a.error);
        if (!b.valid) return res(null, null, b.error);
        if (String(a.uom.tum_type_id) !== String(b.uom.tum_type_id))
            return res(null, null, "Cannot convert " + a.uom.tum_name + " to " + b.uom.tum_name + ": incompatible categories.");
        return res(round(num(qty) * factor(a.uom) / factor(b.uom)), b.uom);
    }

    function toDefault(qty, uomId) {
        var v = validate(uomId);
        if (!v.valid) return res(null, null, v.error);
        var def = getDefaultUom(v.uom.tum_type_id);
        if (!def) return res(round(num(qty)), v.uom, null, "No default UOM configured for " + v.type.tumt_name + "; quantity kept in " + v.uom.tum_name + ".");
        return convert(qty, uomId, def.tum_id);
    }

    // UOMs that can be converted into targetId (same category). Empty array if target is unknown.
    function getCompatibleUoms(targetId) {
        var t = findUom(targetId), out = [];
        if (!t) return out;
        for (var i = 0; i < uomList.length; i++)
            if (String(uomList[i].tum_type_id) === String(t.tum_type_id) && factor(uomList[i])) out.push(uomList[i]);
        return out;
    }

    // Which measurement inputs the UOM needs: { length, width, kg } (kg and length inputs stay enabled by the UI).
    function getRequirements(uomId) {
        var u = findUom(uomId), r = { length: false, width: false, kg: true };
        if (!u) return r;
        var lt = getTypeByName("Length"), at = getTypeByName("Area");
        if (lt && String(u.tum_type_id) === String(lt.tumt_id)) r.length = true;
        else if (at && String(u.tum_type_id) === String(at.tumt_id)) { r.length = true; r.width = true; }
        return r;
    }

    // Target-aware calculation: o.targetUomId = item's Final Quantity UOM (itsv_uom_purchase).
    // Length UOM: Length x Quantity (Quantity treated as 1 when blank). Area UOM: Length x Width x Quantity,
    // with Length/Width entered in the selected UOM's linear unit (SQMT->MTR, SQFT->FEET). Others: Quantity.
    function calculateForTarget(o) {
        var qty = num(o.quantity), len = num(o.length), wid = num(o.width);
        var v = validate(o.uomId), t = validate(o.targetUomId);
        if (!v.valid) return res(null, null, v.error);
        if (!t.valid) return res(null, null, t.error);
        if (String(v.uom.tum_type_id) !== String(t.uom.tum_type_id))
            return res(null, null, v.uom.tum_name + " cannot be converted to " + t.uom.tum_name + ".");
        var req = getRequirements(v.uom.tum_id), mult = qty > 0 ? qty : 1, base;
        if (!req.length) {
            if (qty <= 0) return res(null, null, "");
            base = qty;
        } else {
            if (len <= 0) return res(null, null, "Length is required for " + v.uom.tum_name + ".");
            if (req.width && wid <= 0) return res(null, null, "Width is required for " + v.uom.tum_name + ".");
            base = req.width ? len * wid * mult : len * mult;
        }
        return convert(base, v.uom.tum_id, t.uom.tum_id);
    }

    function calculateFinalQuantity(o) {
        o = o || {};
        if (o.targetUomId) return calculateForTarget(o);
        var qty = num(o.quantity), len = num(o.length), wid = num(o.width);
        if (len <= 0 && wid <= 0) return toDefault(qty, o.uomId);
        if (len <= 0) return res(null, null, "Length is required when Width is entered.");

        var v = validate(o.uomId);
        if (!v.valid) return res(null, null, v.error);
        var lenType = getTypeByName("Length");
        if (!lenType || String(v.uom.tum_type_id) !== String(lenType.tumt_id))
            return res(null, null, "Length/Width require a Length unit; " + v.uom.tum_name + " belongs to " + v.type.tumt_name + ".");
        var defLen = getDefaultUom(lenType.tumt_id);
        if (!defLen) return res(null, null, "No default UOM configured for Length.");
        var l = convert(len, v.uom.tum_id, defLen.tum_id);
        if (l.error) return l;
        if (wid <= 0) return l;
        var w = convert(wid, v.uom.tum_id, defLen.tum_id);
        if (w.error) return w;

        var areaType = getTypeByName("Area");
        var defArea = areaType ? getDefaultUom(areaType.tumt_id) : null;
        if (!defArea) return res(null, null, "No default UOM configured for Area.");
        return res(round(l.value * w.value), defArea);
    }

    function checkMasterData() {
        var msgs = [];
        for (var i = 0; i < uomList.length; i++) {
            var u = uomList[i];
            if (!findType(u.tum_type_id)) msgs.push(u.tum_name + ": unknown category " + u.tum_type_id);
            if (!factor(u)) msgs.push(u.tum_name + ": invalid conversion factor");
        }
        for (var k in types) {
            var t = types[k];
            if (t.tum_id && Number(t.tum_id) > 0) {
                var d = findUom(t.tum_id);
                if (!d) msgs.push(t.tumt_name + ": default UOM " + t.tum_id + " not found");
                else if (String(d.tum_type_id) !== String(t.tumt_id)) msgs.push(t.tumt_name + ": default UOM " + d.tum_name + " belongs to a different category");
            }
        }
        return msgs;
    }

    return {
        init: init, findUom: findUom, findType: findType, getDefaultUom: getDefaultUom,
        getTypeByName: getTypeByName, validate: validate, convert: convert, toDefault: toDefault,
        getCompatibleUoms: getCompatibleUoms, getRequirements: getRequirements,
        calculateFinalQuantity: calculateFinalQuantity, checkMasterData
    };
})();
