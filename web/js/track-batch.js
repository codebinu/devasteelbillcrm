// Shared helpers for the Track Batch pages.
var TB = (function () {
    var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

    function esc(s) {
        return $("<div/>").text(s == null ? "" : String(s)).html();
    }

    // up to 6 decimals (the batch columns are DECIMAL(10,6)), trailing zeros removed
    function qty(v) {
        if (v == null || v === "") return "&mdash;";
        var n = Number(v);
        if (isNaN(n)) return "&mdash;";
        var parts = n.toFixed(6).replace(/0+$/, "").replace(/\.$/, "").split(".");
        parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        return parts.join(".");
    }

    function qtyUom(v, uom) {
        if (v == null) return "&mdash;";
        return qty(v) + (uom ? ' <span class="tb-muted tb-small">' + esc(uom) + '</span>' : '');
    }

    // "yyyy-MM-dd HH:mm:ss" -> "dd-Mon-yyyy HH:mm" (time omitted for midnight)
    function date(s) {
        if (!s) return '<span class="tb-muted">&mdash;</span>';
        var m = /^(\d{4})-(\d{2})-(\d{2})(?: (\d{2}):(\d{2}))?/.exec(s);
        if (!m) return esc(s);
        var d = m[3] + "-" + months[parseInt(m[2], 10) - 1] + "-" + m[1];
        return (m[4] && !(m[4] == "00" && m[5] == "00")) ? d + " " + m[4] + ":" + m[5] : d;
    }

    function status(st) {
        if (!st || !st[0]) return "";
        return '<span class="' + esc(st[1] || "label label-default") + '">' + esc(st[0]) + '</span>';
    }

    function typeBadge(type) {
        return type == "customer" ? '<span class="tb-badge tb-badge-customer">Customer Batch</span>'
            : '<span class="tb-badge tb-badge-system">System Generated</span>';
    }

    function originBadge(kind, label) {
        var cls = kind == "purchase" ? "tb-badge-purchase" : kind == "production" ? "tb-badge-production" : "tb-badge-none";
        var icon = kind == "purchase" ? "fa-truck" : kind == "production" ? "fa-industry" : "fa-question-circle";
        return '<span class="tb-badge ' + cls + '"><i class="fa ' + icon + '"></i> ' + esc(label) + '</span>';
    }

    // a reference that opens the original record; plain text when no page exists for it
    function link(text, url, blank) {
        if (!url) return esc(text);
        return '<a href="' + esc(url) + '"' + (blank ? ' target="_blank"' : '') + '>' + esc(text) + '</a>';
    }

    function skeletonRows(rows, cols) {
        var h = "";
        for (var r = 0; r < rows; r++) {
            h += "<tr>";
            for (var c = 0; c < cols; c++) h += '<td><span class="tb-skel" style="width:' + (50 + ((r + c) * 17) % 45) + '%"></span></td>';
            h += "</tr>";
        }
        return h;
    }

    function copyText(text, done) {
        if (navigator.clipboard && window.isSecureContext) {
            navigator.clipboard.writeText(text).then(done);
            return;
        }
        var ta = document.createElement("textarea");
        ta.value = text;
        document.body.appendChild(ta);
        ta.select();
        try { document.execCommand("copy"); } catch (e) { }
        document.body.removeChild(ta);
        done();
    }

    function ajax(url, data, ok, fail) {
        $.ajax({
            type: "POST", url: url, data: JSON.stringify(data || {}),
            contentType: "application/json; charset=utf-8", dataType: "json",
            success: function (msg) {
                if (msg.d == "E") { fail(); return; }
                var obj;
                try { obj = JSON.parse(msg.d); } catch (e) { fail(); return; }
                ok(obj);
            },
            error: fail
        });
    }

    return { esc: esc, qty: qty, qtyUom: qtyUom, date: date, status: status, typeBadge: typeBadge, originBadge: originBadge, link: link, skeletonRows: skeletonRows, copyText: copyText, ajax: ajax };
})();
