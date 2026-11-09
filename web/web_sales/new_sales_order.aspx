<%@ Page Language="C#" AutoEventWireup="true" CodeFile="new_sales_order.aspx.cs" Inherits="web_sales_new_sales_order" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>New Sales Order | Invoice Me</title>

    <script src="../js/common.js" type="text/javascript"></script>
    <script type="text/javascript" src="../js/jquery-2.0.3.js"></script>
    <script type="text/javascript" src="../js/jquery.cookie.js"></script>
    <script src="../js/uom-conversion.js" type="text/javascript"></script>
    <script src="../js/pagination.js" type="text/javascript"></script>
    <!-- Bootstrap -->
    <link href="../css/bootstrap/bootstrap.min.css" rel="stylesheet" />
    <link href="../css/bootstrap/font-awesome/css/font-awesome.min.css" rel="stylesheet" />
    <link href="../css/bootstrap/nprogress.css" rel="stylesheet" />
    <link href="../css/bootstrap/custom.min.css" rel="stylesheet" />
    <link href="../css/bootstrap/mystyle.css" rel="stylesheet" type="text/css" />
    <%-- autosearch --%>
    <script src="../autosearch/jquery-ui.js" type="text/javascript"></script>
    <link href="../autosearch/jquery-ui.css" rel="Stylesheet" type="text/css" />
    <script src="../autosearch/jquery-ui.min.js" type="text/javascript"></script>

    <style>
        .so-search-group { display: flex; align-items: stretch; gap: 6px; }
        .so-search-group .form-control { flex: 1 1 auto; width: auto; min-width: 0; height: 34px; border-radius: 3px; }
        .so-search-group .btn { flex: 0 0 auto; height: 34px; margin: 0; padding: 6px 14px; border-radius: 3px; }
        .so-modal .modal-dialog { max-width: calc(100vw - 20px); }
        .so-modal .modal-body { max-height: calc(100vh - 230px); overflow: auto; padding: 10px 15px; }
        .so-modal .so-modal-head { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; }
        .so-modal .so-modal-head h4 { margin: 0; flex: 1 1 auto; }
        .so-modal .so-modal-head .close { margin: 0; }
        .so-modal .so-filters .form-control { min-width: 90px; }
        .so-modal .so-results tbody tr { cursor: pointer; }
        .so-modal .so-results tbody tr.so-active, .so-modal .so-results tbody tr:hover { background: #e3f2fa !important; }
        .so-modal mark { background: #fff3a8; padding: 0; }
        .so-modal .so-state { text-align: center; padding: 18px; color: #73879c; font-weight: bold; }
        .so-modal .so-state.so-error { color: #d9534f; }
        .so-modal .pagination { margin: 8px 0 0; }
        .so-modal .so-foot { display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 8px; }
        .so-section { margin-bottom: 15px; }
        .so-section .x_title h2 { font-size: 16px; font-weight: 600; }
        .so-totals td { padding: 4px 8px; }
        .so-totals .grand td { font-size: 18px; font-weight: bold; border-top: 2px solid #1e99c7; }
        #tblSoItems td, #tblSoItems th { vertical-align: middle; white-space: nowrap; }
        .so-err { color: #d9534f; font-size: 12px; }
        .so-info { font-weight: bold; color: #1e99c7; }
        .so-cust { margin-top: 8px; padding: 10px 12px; border: 1px solid #e6e9ed; border-left: 4px solid #1e99c7; border-radius: 3px; background: #f7fbfd; position: relative; }
        .so-cust-head { display: flex; align-items: center; }
        .so-cust-avatar { width: 38px; height: 38px; border-radius: 50%; background: #1e99c7; color: #fff; font-size: 18px; line-height: 38px; text-align: center; margin-right: 10px; flex: 0 0 38px; }
        .so-cust-name { font-size: 15px; font-weight: 600; color: #2a3f54; line-height: 1.2; }
        .so-cust-id { display: inline-block; font-size: 11px; color: #73879c; background: #e8eef3; border-radius: 10px; padding: 1px 8px; margin-top: 2px; }
        .so-cust-clear { position: absolute; top: 6px; right: 10px; }
        #itemSpec_Panel .so-cust { padding: 6px 10px; margin-top: 4px; }
        #itemSpec_Panel .so-cust-avatar { width: 28px; height: 28px; line-height: 28px; font-size: 14px; flex: 0 0 28px; margin-right: 8px; }
        #itemSpec_Panel .so-cust-name { font-size: 14px; display: inline-block; margin-right: 6px; }
        .so-cust-stats { display: flex; flex-wrap: wrap; margin: 6px -2px 0; }
        .so-cust-stat { flex: 1 1 70px; margin: 2px; padding: 2px 8px; background: #fff; border: 1px solid #e6e9ed; border-radius: 3px; }
        .so-cust-stat small { display: block; color: #73879c; font-size: 10px; line-height: 1.2; text-transform: uppercase; letter-spacing: .3px; }
        .so-cust-stat b { font-size: 13px; line-height: 1.3; display: block; min-height: 17px; word-break: break-word; }
        .so-cust-address { margin: 4px 0 0; padding: 4px 8px; background: #fff; border: 1px solid #e6e9ed; border-radius: 3px; }
        .so-cust-address small { display: block; color: #73879c; font-size: 10px; line-height: 1.2; text-transform: uppercase; letter-spacing: .3px; }
        .so-cust-address b { display: block; font-size: 13px; line-height: 1.3; font-weight: 600; word-break: break-word; white-space: pre-line; }
        .so-item-row { display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 8px 16px; }
        .so-item-main { display: flex; align-items: center; flex: 1 1 260px; min-width: 0; }
        .so-item-title { min-width: 0; }
        #itemSpec_Panel .so-cust-name { display: block; margin: 0 0 2px; overflow-wrap: anywhere; }
        .so-item-stats { display: grid; grid-template-columns: repeat(4, minmax(80px, 1fr)); gap: 6px; flex: 1 1 380px; max-width: 100%; }
        .so-item-stats .so-cust-stat { margin: 0; min-width: 0; }
        @media (max-width: 767px) { .so-item-stats { grid-template-columns: repeat(2, minmax(0, 1fr)); flex-basis: 100%; } }
    </style>

    <script type="text/javascript">
        var systemSettings = <%=settings%>;
        var accuracyNum = 2, allowZeroStockOrder = 0;
        var uomData = [];
        var soItems = [];
        var specItem = null;      // item currently selected in entry form
        var editIndex = -1;
        var custId = 0, custType = 0, taxMethod = 0, taxInclusive = 0;
        var isSaving = false;
        var sessionId = 0;

        function newSessionId() {
            var n = new Date(), p = function (v) { return (v < 10 ? "0" : "") + v; };
            return parseInt(p(n.getFullYear() % 100) + p(n.getMonth() + 1) + p(n.getDate()) + p(n.getHours()) + p(n.getMinutes()) + p(n.getSeconds()) + String(Math.floor(Math.random() * 900) + 100), 10);
        }
        function num(v) { var n = parseFloat(v); return isNaN(n) ? 0 : n; }
        function rnd(v) { var f = Math.pow(10, accuracyNum); return Math.round((v + Number.EPSILON) * f) / f; }
        function esc(s) { return $("<div>").text(s == null ? "" : s).html(); }
        function showMsg(type, text) {
            $("#soMsg").attr("class", "alert alert-" + type).text(text).show();
            if (type === "success") { $("html,body").animate({ scrollTop: 0 }, 200); }
        }
        function ajaxCall(method, data, ok, fail) {
            $.ajax({
                type: "POST", url: "new_sales_order.aspx/" + method,
                data: JSON.stringify(data || {}), contentType: "application/json; charset=utf-8", dataType: "json",
                success: function (r) { ok(r.d); },
                error: function (xhr) { if (fail) fail(xhr); else showMsg("danger", "Network or server error while calling " + method + "."); }
            });
        }

        $(document).ready(function () {
            if (!$.cookie("invntrystaffId")) { location.href = "../dashboard.aspx"; return; }
            accuracyNum = parseInt(systemSettings[0].ss_decimal_accuracy) || 2;
            allowZeroStockOrder = parseInt(systemSettings[0].ss_allow_zero_stock_order) || 0;
            sessionId = newSessionId();
            $("#txtOrderDate").text(new Date().toLocaleDateString());
            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " &copy;");
            loadWarehouses();
            loadUom();
            bindCustomerSearch();
            bindItemSearch();
            $(document).on("input", "#itemSpec_Qty,#itemSpec_Length,#itemSpec_Width,#itemSpec_Price,#itemSpec_Discount", function () { specRecalc(); });
            $(document).on("change", "#itemSpec_Uom", function () { specRecalc(); });
            renderItems();
        });

        // ---------- master data ----------
        function loadWarehouses() {
            ajaxCall("loadWarehouses", {}, function (d) {
                var rows = JSON.parse(d), $w = $("#comboWarehouse");
                $w.empty().append('<option value="0">-- Warehouse --</option>');
                if (!rows.length) { showMsg("warning", "No warehouse is assigned to this user."); return; }
                $.each(rows, function (i, r) {
                    $w.append($("<option></option>").val(r.branch_id).text(r.branch_name)
                        .attr("data-tax", r.branch_tax_method).attr("data-inc", r.branch_tax_inclusive));
                });
                var def = $.cookie("invntrystaffBranchId");
                if (def && $w.find("option[value='" + def + "']").length) { $w.val(def); }
                onWarehouseChange();
            }, function () { showMsg("danger", "Unable to load warehouses."); });
        }
        function onWarehouseChange() {
            var $o = $("#comboWarehouse option:selected");
            taxMethod = parseInt($o.attr("data-tax")) || 0;
            taxInclusive = parseInt($o.attr("data-inc")) || 0;
            if (soItems.length) { soItems = []; showMsg("info", "Warehouse changed - order items were cleared."); }
            clearSpec();
            renderItems();
        }
        function loadUom() {
            ajaxCall("loadUomData", {}, function (d) {
                uomData = JSON.parse(d);
                ajaxCall("loadUomTypes", {}, function (t) {
                    UomConversion.init(uomData, JSON.parse(t));
                    var issues = UomConversion.checkMasterData();
                    if (issues.length) console.warn("UOM master data issues:", issues);
                    fillUom();
                });
            }, function () { showMsg("danger", "Unable to load units of measure."); });
        }

        // ---------- customer ----------
        var custReqId = 0, custRows = [], custTimer = null;

        function hl(text, q) {
            var t = text == null ? "" : String(text), s = (q || "").trim();
            if (!s) return esc(t);
            var i = t.toLowerCase().indexOf(s.toLowerCase());
            if (i < 0) return esc(t);
            return esc(t.substring(0, i)) + "<mark>" + esc(t.substring(i, i + s.length)) + "</mark>" + esc(t.substring(i + s.length));
        }
        function modalState($tbody, cols, text, isErr) {
            $tbody.html('<tr><td colspan="' + cols + '" class="so-state' + (isErr ? ' so-error' : '') + '">' + text + '</td></tr>');
        }
        // Arrow keys move through result rows, Enter picks the highlighted one
        function bindModalKeys(modalSel, tableSel) {
            $(modalSel).on("keydown", function (e) {
                var $rows = $(tableSel + " tbody tr[data-idx]");
                if (!$rows.length || e.target.tagName === "SELECT" || (e.which !== 40 && e.which !== 38 && e.which !== 13)) return;
                var $cur = $rows.filter(".so-active"), i = $rows.index($cur);
                if (e.which === 13) {
                    if ($cur.length) { e.preventDefault(); $cur.click(); }
                    return;
                }
                e.preventDefault();
                i = e.which === 40 ? Math.min(i + 1, $rows.length - 1) : Math.max(i - 1, 0);
                $rows.removeClass("so-active");
                var el = $rows.eq(i).addClass("so-active")[0];
                if (el && el.scrollIntoView) el.scrollIntoView({ block: "nearest" });
            });
        }
        // Page methods of neworder.aspx are reused for the modals (same queries, paging and filters)
        function ajaxNewOrder(method, data, ok, fail) {
            $.ajax({
                type: "POST", url: "neworder.aspx/" + method,
                data: JSON.stringify(data), contentType: "application/json; charset=utf-8", dataType: "json",
                success: function (r) { ok(r.d); },
                error: function (xhr) { fail(xhr); }
            });
        }
        // neworder.aspx builds SQL from these values, so quotes and backslashes are never sent
        function cleanTerm(v) { return $.trim(String(v || "").replace(/['"\\]/g, "")); }

        function bindCustomerSearch() {
            // autocomplete (typing)
            $("#customerNames").autocomplete({
                minLength: 1,
                source: function (req, resp) {
                    ajaxCall("searchCustomers", { variable: req.term }, function (d) { resp(JSON.parse(d)); }, function () { resp([]); });
                },
                select: function (e, ui) {
                    e.preventDefault();
                    if (ui.item.id == "-1") { $("#customerNames").val(""); return; }
                    setCustomer(ui.item.id, ui.item.label, ui.item.custType, ui.item);
                }
            });
            // modal search
            $("#btnCustSearch").on("click", openCustomerModal);
            $("#custFilters input").on("input", function () { clearTimeout(custTimer); custTimer = setTimeout(function () { searchCustomerPage(1); }, 300); });
            $("#custFilters input").on("keydown", function (e) { if (e.which === 13 && !$("#tblCustResults tr.so-active").length) { e.preventDefault(); clearTimeout(custTimer); searchCustomerPage(1); } });
            $("#custPerPage").on("change", function () { searchCustomerPage(1); });
            $("#tblCustResults tbody").on("click", "tr[data-idx]", function () { pickCustomer(parseInt($(this).attr("data-idx"))); });
            $("#popupCustomer").on("shown.bs.modal", function () { $("#custName").focus(); });
            bindModalKeys("#popupCustomer", "#tblCustResults");
        }
        function openCustomerModal() {
            $("#customerNames").autocomplete("close");
            $("#popupCustomer").modal("show");
            searchCustomerPage(1);
        }
        function resetCustomerSearch() {
            $("#custFilters input").val("");
            searchCustomerPage(1);
        }
        function searchCustomerPage(page) {
            var $tb = $("#tblCustResults tbody"), reqId = ++custReqId, perpage = parseInt($("#custPerPage").val()) || 25;
            var f = { id: cleanTerm($("#custCode").val()), name: cleanTerm($("#custName").val()), phone: cleanTerm($("#custPhone").val()) };
            modalState($tb, 6, '<i class="fa fa-spinner fa-spin"></i> Loading...');
            $("#custPaging").empty();
            ajaxCall("searchCustomerList", { page: page, perpage: perpage, custId: f.id, name: f.name, phone: f.phone }, function (d) {
                if (reqId !== custReqId) return;
                if (d == "N") { custRows = []; $("#lblCustCount").text(0); modalState($tb, 6, "No customers match your search."); return; }
                var r;
                try { r = JSON.parse(d); } catch (ex) { custRows = []; $("#lblCustCount").text(0); modalState($tb, 6, "Unable to load customers.", true); return; }
                custRows = r.data;
                $("#lblCustCount").text(r.count);
                var h = "";
                $.each(r.data, function (i, c) {
                    var bal = num(c.cust_amount);
                    c.name = c.cust_name; c.address = c.cust_address;
                    var pending = num(c.new_custtype) !== 0 || num(c.new_creditamt) !== 0 || num(c.new_creditperiod) !== 0;
                    h += '<tr data-idx="' + i + '"><td>' + hl(c.cust_id, f.id) + '</td><td>' + hl(c.name, f.name)
                        + (pending ? ' <span class="label label-warning">To be confirmed</span>' : '') + '</td>'
                        + '<td>' + esc(c.address) + '</td><td>' + esc(c["class"]) + '</td><td>' + hl(c.cust_phone, f.phone) + '</td>'
                        + '<td class="text-right" style="color:' + (bal > 0 ? 'red' : 'green') + '">' + esc(bal) + '</td></tr>';
                });
                $tb.html(h);
                $("#custPaging").html(paginate(r.count, perpage, page, "searchCustomerPage"));
            }, function () {
                if (reqId !== custReqId) return;
                modalState($tb, 6, 'Could not load customers. <a href="javascript:void(0);" onclick="searchCustomerPage(' + page + ');">Retry</a>', true);
            });
        }
        function pickCustomer(i) {
            var c = custRows[i];
            if (!c) return;
            var $tb = $("#tblCustResults tbody");
            $tb.css("opacity", .5);
            // same lookup neworder.aspx performs after a customer is chosen
            ajaxNewOrder("selectCustomerdata", { customerid: String(c.cust_id) }, function (d) {
                $tb.css("opacity", 1);
                var r;
                try { r = JSON.parse(d); } catch (ex) { r = null; }
                if (!r || !r.length) { modalState($tb, 6, "Customer is not available.", true); return; }
                var x = r[0];
                $("#popupCustomer").modal("hide");
                setCustomer(c.cust_id, x.cust_name, x.cust_type, { cls: x["class"], creditAmt: x.max_creditamt, creditPeriod: x.max_creditperiod, balance: x.cust_amount == null ? 0 : x.cust_amount, cust_phone: c.cust_phone, cust_address: c.address });
            }, function (xhr) {
                $tb.css("opacity", 1);
                var msg = "Could not select the customer. Please try again.";
                try { if (xhr.status === 401) msg = JSON.parse(xhr.responseText).message || msg; } catch (ex) { }
                modalState($tb, 6, esc(msg), true);
            });
        }
        function custHas(v) { return v !== undefined && v !== null && String(v).trim() !== ""; }
                function renderCustDetails(it) {
                    it = it || {};
                    var $d = $("#divCustDetails").empty();
                    function add(label, val, color) {
                        if (!custHas(val)) return;
                        var $s = $("<div class='so-cust-stat'></div>").append($("<small></small>").text(label)).append($("<b></b>").text(val));
                        if (color) $s.find("b").css("color", color);
                        $d.append($s);
                    }
                    add("Phone", it.cust_phone);
                    add("Class", it.cls);
                    add("Credit Amt", it.creditAmt);
                    add("Period", custHas(it.creditPeriod) ? it.creditPeriod + " Days" : "");
                    var bal = custHas(it.balance) ? it.balance : 0;
                    add("A/C Balance", bal, parseFloat(bal) > 0 ? "red" : "green");
                    var $a = $("#divCustAddress").empty();
                    if (custHas(it.cust_address)) $a.append($("<small></small>").text("Address")).append($("<b></b>").text($.trim(it.cust_address))).show();
                    else $a.hide();
                }
                function setCustomer(id, name, type, it) {
            if (soItems.length && String(type) !== String(custType)) { soItems = []; renderItems(); showMsg("info", "Customer price class changed - order items were cleared."); }
            custId = parseInt(id); custType = parseInt(type) || 0;
            $("#lblCustName").text(name);
            $("#lblCustId").text("ID: " + id);
            renderCustDetails(it);
            $("#customerNames").val("");
            $("#divCustSelected").show();
            if ($("#soMsg").text() === "Select a customer first.") $("#soMsg").hide();
            clearSpec();
        }
        function clearCustomer() {
            custId = 0; custType = 0;
            $("#lblCustName").text(""); $("#lblCustId").text("");
            $("#divCustDetails").empty(); $("#divCustAddress").empty().hide();
            $("#divCustSelected").hide();
            $("#customerNames").val("").focus();
            if (soItems.length) { soItems = []; renderItems(); }
            clearSpec();
        }

        // ---------- item entry ----------
        var itemReqId = 0, itemRows = [], itemTimer = null;

        function bindItemSearch() {
            // autocomplete (typing)
            $("#txtNames").autocomplete({
                minLength: 1,
                source: function (req, resp) {
                    var b = parseInt($("#comboWarehouse").val()) || 0;
                    if (!b) { showMsg("warning", "Select a warehouse first."); resp([]); return; }
                    if (!custId) { showMsg("warning", "Select a customer first."); resp([]); return; }
                    ajaxCall("searchItems", { variable: req.term, branchId: b, custType: custType, allowZeroStockOrder: allowZeroStockOrder },
                        function (d) { resp(JSON.parse(d)); }, function () { resp([]); });
                },
                select: function (e, ui) {
                    e.preventDefault();
                    if (ui.item.id == "-1") { $("#txtNames").val(""); return; }
                    $("#txtNames").val("");
                    chooseItem(ui.item);
                }
            });
            // modal search
            $("#btnItemSearch").on("click", openItemModal);
            $("#itemFilters input").on("input", function () { clearTimeout(itemTimer); itemTimer = setTimeout(function () { searchItemPage(1); }, 300); });
            $("#itemFilters input").on("keydown", function (e) { if (e.which === 13 && !$("#tblItemResults tr.so-active").length) { e.preventDefault(); clearTimeout(itemTimer); searchItemPage(1); } });
            $("#itemPerPage").on("change", function () { searchItemPage(1); });
            $("#tblItemResults tbody").on("click", "tr[data-idx]", function () { pickItem(parseInt($(this).attr("data-idx"))); });
            $("#popupItems").on("shown.bs.modal", function () { $("#itemName").focus(); });
            bindModalKeys("#popupItems", "#tblItemResults");
        }
        // Single entry point for both search methods: an item already in the order is opened for editing instead of being added twice
        function chooseItem(it) {
            var dup = -1;
            $.each(soItems, function (k, l) { if (l.itbs_id === it.itbs_id) dup = k; });
            if (dup >= 0) {
                showMsg("info", "This item is already in the order - edit the existing row instead.");
                editItem(dup);
                return;
            }
            selectItem(it);
        }
        function openItemModal() {
            if (!(parseInt($("#comboWarehouse").val()) > 0)) { showMsg("warning", "Select a warehouse first."); return; }
            if (!custId) { showMsg("warning", "Select a customer first."); return; }
            $("#txtNames").autocomplete("close");
            $("#soMsg").hide();
            $("#popupItems").modal("show");
            searchItemPage(1);
        }
        function resetItemSearch() {
            $("#itemFilters input").val("");
            searchItemPage(1);
        }
        function searchItemPage(page) {
            var $tb = $("#tblItemResults tbody"), reqId = ++itemReqId, perpage = parseInt($("#itemPerPage").val()) || 25;
            var f = { code: cleanTerm($("#itemCode").val()), name: cleanTerm($("#itemName").val()) };
            var filters = { warehouse: String(parseInt($("#comboWarehouse").val()) || 0), allowZeroStockOrder: String(allowZeroStockOrder) };
            if (f.name) filters.itemname = f.name;
            if (f.code) filters.itemcode = f.code;
            modalState($tb, 4, '<i class="fa fa-spinner fa-spin"></i> Loading...');
            $("#itemPaging").empty();
            ajaxNewOrder("searchOrderitem", { page: page, filters: filters, perpage: perpage, customertype: custType, cust_id: String(custId) }, function (d) {
                if (reqId !== itemReqId) return;
                if (d == "N") { itemRows = []; $("#lblItemCount").text(0); modalState($tb, 4, "No items match your search."); return; }
                var r;
                try { r = JSON.parse(d); } catch (ex) { itemRows = []; $("#lblItemCount").text(0); modalState($tb, 4, "Unable to load items.", true); return; }
                itemRows = r.data;
                $("#lblItemCount").text(r.count);
                var h = "";
                $.each(r.data, function (i, it) {
                    var price = it.classPrice != null ? it.classPrice : (it.itm_mrp != null ? it.itm_mrp : 0);
                    var inOrder = $.grep(soItems, function (l) { return l.itbs_id === it.itbs_id; }).length;
                    var carton = it.itm_qty_per_carton > 1 ? '<br /><small class="text-info">1 Carton = ' + esc(it.itm_qty_per_carton) + ' Pieces</small>' : '';
                    h += '<tr data-idx="' + i + '"><td>' + hl(it.itm_code, f.code) + '</td><td>' + hl(it.itm_name, f.name)
                        + (inOrder ? ' <span class="label label-info">In order</span>' : '') + carton + '</td>'
                        + '<td class="text-right">' + esc(it.itbs_stock) + '</td>'
                        + '<td class="text-right">' + num(price).toFixed(accuracyNum) + '</td></tr>';
                });
                $tb.html(h);
                $("#itemPaging").html(paginate(r.count, perpage, page, "searchItemPage"));
            }, function () {
                if (reqId !== itemReqId) return;
                modalState($tb, 4, 'Could not load items. <a href="javascript:void(0);" onclick="searchItemPage(' + page + ');">Retry</a>', true);
            });
        }
        function pickItem(i) {
            var row = itemRows[i];
            if (!row) return;
            var $tb = $("#tblItemResults tbody");
            $tb.css("opacity", .5);
            // The modal list has no HSN / sales UOM, so the full entry data comes from the same query the autocomplete uses
            ajaxCall("searchItems", { variable: row.itm_name, branchId: parseInt($("#comboWarehouse").val()) || 0, custType: custType, allowZeroStockOrder: allowZeroStockOrder }, function (d) {
                $tb.css("opacity", 1);
                var match = null;
                $.each(JSON.parse(d), function (k, it) { if (it.itbs_id === row.itbs_id) match = it; });
                if (!match) { modalState($tb, 4, "Item details could not be loaded. Please search for it by name in the item field.", true); return; }
                $("#popupItems").modal("hide");
                $("#soMsg").hide();
                chooseItem(match);
            }, function () {
                $tb.css("opacity", 1);
                modalState($tb, 4, 'Could not select the item. Please try again.', true);
            });
        }
        function selectItem(it) {
            specItem = it; editIndex = -1;
            $("#itemSpec_Panel").show();
            $("#itemSpec_Name").text(it.label);
            $("#itemSpec_Code").text(it.itm_code);
            $("#itemSpec_Hsn").text(it.hsn || "-");
            var du = it.defUomId && UomConversion.findUom(it.defUomId);
            $("#itemSpec_DefUom").text(du && du.tum_name ? du.tum_name : "-");
            $("#itemSpec_Stock").text(it.stock);
            $("#itemSpec_TaxPerc").text(taxMethod == 0 ? 0 : it.tax);
            $("#itemSpec_Qty,#itemSpec_Length,#itemSpec_Width,#itemSpec_Discount").val("");
            $("#itemSpec_Price").val(it.price);
            $("#btnSpecAdd").html('<i class="fa fa-plus"></i> Add Item');
            fillUom(true);
            $("#itemSpec_Qty").focus();
            specRecalc();
        }
        function clearSpec() {
            specItem = null; editIndex = -1;
            $("#itemSpec_Name,#itemSpec_Code,#itemSpec_Stock,#itemSpec_TaxPerc,#itemSpec_Hsn,#itemSpec_DefUom").text("");
            $("#itemSpec_Qty,#itemSpec_Length,#itemSpec_Width,#itemSpec_Discount,#itemSpec_Price,#itemSpec_FinalQty,#itemSpec_Net").val("");
            $("#btnSpecAdd").html('<i class="fa fa-plus"></i> Add Item');
            fillUom();
            $("#itemSpec_FinalQtyErr,#itemSpec_LineErr").text("");
        }
        function fillUom(useDefault) {
            var $d = $("#itemSpec_Uom"), prev = useDefault ? null : $d.val(), data = uomData;
            if (specItem && specItem.defUomId && UomConversion.findUom(specItem.defUomId)) data = UomConversion.getCompatibleUoms(specItem.defUomId);
            $d.empty().append('<option value="-1">Select</option>');
            $.each(data, function (i, u) { $d.append($("<option></option>").val(u.tum_id).text(u.tum_name)); });
            if (prev && $d.find("option[value='" + prev + "']").length) $d.val(prev);
            else if (specItem && specItem.defUomId && $d.find("option[value='" + specItem.defUomId + "']").length) $d.val(specItem.defUomId);
            else $d.val("-1");
            var dn = specItem && specItem.defUomId && UomConversion.findUom(specItem.defUomId) ? UomConversion.findUom(specItem.defUomId).tum_name : "";
            $("#itemSpec_FinalQtyUom").text(dn ? " (" + dn + ")" : "");
        }
        // returns {qty, error}
        function calcFinal(o) {
            if (!o.uomId || o.uomId == "-1") return { qty: 0, error: "" };
            var r = UomConversion.calculateFinalQuantity({ uomId: o.uomId, targetUomId: o.defUomId, quantity: o.quantity, length: o.length, width: o.width });
            if (r.error || r.value === null) return { qty: 0, error: r.error || "" };
            return { qty: r.value, error: "" };
        }
        // line amounts: mirrors server-side logic (branch tax method / inclusive)
        function lineAmounts(qty, price, rate, tax, cess) {
            if (taxMethod == 0) { tax = 0; cess = 0; }
            var basePrice = price;
            if (taxMethod != 0 && taxInclusive == 1) {
                basePrice = cess > 0 ? 10000 * price / (10000 + 100 * tax + tax * cess) : price / (tax / 100 + 1);
            }
            var real = basePrice * qty, disc = real * rate / 100, nb = real - disc;
            var ta = nb * tax / 100; ta = ta + ta * cess / 100;
            return { total: rnd(real), disc: rnd(disc), tax: rnd(ta), net: rnd(nb + ta) };
        }
        function specRecalc() {
            if (!specItem) return;
            var uomId = $("#itemSpec_Uom").val();
            var req = (uomId && uomId != "-1") ? UomConversion.getRequirements(uomId) : { length: false, width: false };
            $("#itemSpec_Length").prop("disabled", !req.length);
            $("#itemSpec_Width").prop("disabled", !req.width);
            var f = calcFinal({ uomId: uomId, defUomId: specItem.defUomId, quantity: $("#itemSpec_Qty").val(), length: $("#itemSpec_Length").val(), width: $("#itemSpec_Width").val() });
            $("#itemSpec_FinalQty").val(f.qty > 0 ? f.qty.toFixed(2) : "");
            $("#itemSpec_FinalQtyErr").text(f.error);
            var a = lineAmounts(f.qty, num($("#itemSpec_Price").val()), num($("#itemSpec_Discount").val()), num(specItem.tax), num(specItem.cess));
            $("#itemSpec_Net").val(f.qty > 0 ? a.net.toFixed(accuracyNum) : "");
        }
        function addOrUpdateItem() {
            var $e = $("#itemSpec_LineErr");
            $e.text("");
            if (!specItem) { $e.text("Search and select an item first."); return; }
            var uomId = $("#itemSpec_Uom").val();
            if (!uomId || uomId == "-1") { $e.text("Select a unit of measure."); return; }
            var raw = { qty: $("#itemSpec_Qty").val(), len: $("#itemSpec_Length").val(), wid: $("#itemSpec_Width").val(), price: $("#itemSpec_Price").val(), disc: $("#itemSpec_Discount").val() };
            var f = calcFinal({ uomId: uomId, defUomId: specItem.defUomId, quantity: raw.qty, length: raw.len, width: raw.wid });
            if (f.error) { $e.text(f.error); return; }
            if (!(f.qty > 0)) { $e.text("Enter a valid quantity."); return; }
            if (raw.price === "" || isNaN(parseFloat(raw.price)) || num(raw.price) < 0) { $e.text("Enter a valid price."); return; }
            var d = raw.disc === "" ? 0 : parseFloat(raw.disc);
            if (isNaN(d) || d < 0 || d > 100) { $e.text("Discount must be between 0 and 100."); return; }
            for (var i = 0; i < soItems.length; i++) {
                if (soItems[i].itbs_id === specItem.itbs_id && i !== editIndex) { $e.text("This item is already in the order. Edit the existing row instead."); return; }
            }
            if (!allowZeroStockOrder && f.qty > num(specItem.stock)) { $e.text("Quantity exceeds available stock (" + specItem.stock + ")."); return; }
            var uom = UomConversion.findUom(uomId);
            var line = {
                itbs_id: specItem.itbs_id, itm_id: specItem.itm_id, code: specItem.itm_code, name: specItem.label,
                stock: specItem.stock, tax: specItem.tax, cess: specItem.cess, defUomId: specItem.defUomId, orgPrice: specItem.price, hsn: specItem.hsn,
                tum_id: parseInt(uomId), uomName: uom ? uom.tum_name : "",
                no_piece: num(raw.qty), length: num(raw.len), width: num(raw.wid),
                finalQty: f.qty, price: num(raw.price), discount: d
            };
            if (editIndex >= 0) soItems[editIndex] = line; else soItems.push(line);
            clearSpec();
            renderItems();
            $("#txtNames").focus();
        }
        function editItem(i) {
            var l = soItems[i];
            specItem = { id: l.itbs_id, label: l.name, itbs_id: l.itbs_id, itm_id: l.itm_id, itm_code: l.code, stock: l.stock, tax: l.tax, cess: l.cess, defUomId: l.defUomId, price: l.orgPrice, hsn: l.hsn };
            editIndex = i;
            $("#itemSpec_Panel").show();
            $("#itemSpec_Name").text(l.name); $("#itemSpec_Code").text(l.code); $("#itemSpec_Stock").text(l.stock);
            $("#itemSpec_TaxPerc").text(taxMethod == 0 ? 0 : l.tax);
            $("#itemSpec_Hsn").text(l.hsn || "-");
            var du = l.defUomId && UomConversion.findUom(l.defUomId);
            $("#itemSpec_DefUom").text(du && du.tum_name ? du.tum_name : "-");
            fillUom();
            $("#itemSpec_Uom").val(l.tum_id);
            $("#itemSpec_Qty").val(l.no_piece || ""); $("#itemSpec_Length").val(l.length || ""); $("#itemSpec_Width").val(l.width || "");
            $("#itemSpec_Price").val(l.price); $("#itemSpec_Discount").val(l.discount || "");
            $("#btnSpecAdd").html('<i class="fa fa-check"></i> Update Item');
            specRecalc();
            $("html,body").animate({ scrollTop: $("#itemSpec_Panel").offset().top - 80 }, 200);
        }
        function removeItem(i) {
            if (!confirm("Remove this item from the order?")) return;
            soItems.splice(i, 1);
            if (editIndex === i) clearSpec(); else if (editIndex > i) editIndex--;
            renderItems();
        }

        // ---------- order items table / totals ----------
        function renderItems() {
            var $b = $("#tblSoItems tbody").empty(), t = { total: 0, disc: 0, tax: 0, net: 0 };
            if (!soItems.length) $b.append('<tr><td colspan="13" class="text-center text-muted">No items added</td></tr>');
            $.each(soItems, function (i, l) {
                var a = lineAmounts(l.finalQty, l.price, l.discount, num(l.tax), num(l.cess));
                t.total += a.total; t.disc += a.disc; t.tax += a.tax; t.net += a.net;
                var dims = (l.length ? l.length : "") + (l.width ? " x " + l.width : "");
                $b.append('<tr><td>' + (i + 1) + '</td><td>' + esc(l.code) + '</td><td>' + esc(l.name) + '</td><td>' + esc(l.uomName) + '</td>'
                    + '<td class="text-right">' + l.no_piece + '</td><td>' + esc(dims) + '</td>'
                    + '<td class="text-right">' + l.finalQty.toFixed(2) + '</td><td class="text-right">' + l.price.toFixed(accuracyNum) + '</td>'
                    + '<td class="text-right">' + l.discount + '%</td>'
                                        + '<td class="text-right">' + (taxMethod == 0 ? 0 : num(l.tax)) + '%</td><td class="text-right">' + a.tax.toFixed(accuracyNum) + '</td>'
                                        + '<td class="text-right">' + a.net.toFixed(accuracyNum) + '</td>'
                    + '<td><button type="button" class="btn btn-xs btn-info" onclick="editItem(' + i + ')"><i class="fa fa-pencil"></i></button> '
                    + '<button type="button" class="btn btn-xs btn-danger" onclick="removeItem(' + i + ')"><i class="fa fa-trash"></i></button></td></tr>');
            });
            $("#lblTotal").text(t.total.toFixed(accuracyNum));
            $("#lblDiscount").text(t.disc.toFixed(accuracyNum));
            $("#lblTax").text(t.tax.toFixed(accuracyNum));
            $("#lblNet").text(t.net.toFixed(accuracyNum));
            $("#lblCount").text(soItems.length);
        }

        // ---------- save ----------
        function validateOrder() {
            if (!(parseInt($("#comboWarehouse").val()) > 0)) return "Select a warehouse.";
            if (!custId) return "Select a customer.";
            if (!soItems.length) return "Add at least one item.";
            for (var i = 0; i < soItems.length; i++) {
                var l = soItems[i];
                if (!l.tum_id || !(l.finalQty > 0) || l.price < 0) return "Row " + (i + 1) + " has invalid data.";
            }
            return "";
        }
        function buildRequest() {
            var items = $.map(soItems, function (l, i) {
                return {
                    row_no: i, itbs_id: l.itbs_id, itm_id: l.itm_id, itm_name: l.name, tum_id: l.defUomId,
                    no_piece: l.no_piece, length: l.length, width: l.width,
                    si_qty: l.finalQty, si_price: l.price, si_discount_rate: l.discount
                };
            });
            return {
                request: {
                    master: {
                        cust_id: custId, branch_id: parseInt($("#comboWarehouse").val()),
                        sm_specialnote: $("#txtSpecialNote").val(), sm_sales_sessionid: sessionId
                    },
                    items: items
                }
            };
        }
        function saveSalesOrder() {
            if (isSaving) return;
            var err = validateOrder();
            if (err) { showMsg("danger", err); return; }
            isSaving = true;
            $("#btnSave").prop("disabled", true).html('<i class="fa fa-spinner fa-spin"></i> Saving...');
            $("#soMsg").hide();
            ajaxCall("SaveSalesOrder", buildRequest(), function (d) {
                var r = JSON.parse(d);
                if (r.status) {
                    showMsg("success", "Sales order #" + r.smo_id + " saved. Net amount: " + num(r.net_amount).toFixed(accuracyNum));
                    soItems = []; clearSpec(); clearCustomer(); $("#txtSpecialNote").val("");
                    sessionId = newSessionId();
                    renderItems();
                } else {
                    showMsg("danger", r.message || "Sales order could not be saved.");
                }
                endSave();
            }, function () {
                showMsg("danger", "Network or server error. Your entries were kept; please retry.");
                endSave();
            });
        }
        function endSave() {
            isSaving = false;
            $("#btnSave").prop("disabled", false).html('<i class="fa fa-save"></i> Save Order');
        }
    </script>
</head>
<body class="nav-md">
    <div class="container body">
        <div class="main_container">
            <div class="col-md-3 left_col">
                <div class="left_col scroll-view">
                    <div class="navbar nav_title" style="border: 0;">
                        <a href="../index.html" class="site_title"><i class="fa fa-file-text"></i><span>Invoice Me</span></a>
                    </div>
                    <div class="clearfix"></div>
                    <div class="profile clearfix">
                        <div class="profile_pic">
                            <img src="../images/img.jpg" alt="..." class="img-circle profile_img">
                        </div>
                        <div class="profile_info">
                            <span>Welcome,</span>
                            <h2>John Doe</h2>
                        </div>
                    </div>
                    <br />
                    <div id="sidebar-menu" class="main_menu_side hidden-print main_menu"></div>
                    <div class="sidebar-footer hidden-small">
                        <a data-toggle="tooltip" data-placement="top" title="Settings"><span class="glyphicon glyphicon-cog" aria-hidden="true"></span></a>
                        <a data-toggle="tooltip" data-placement="top" title="FullScreen"><span class="glyphicon glyphicon-fullscreen" aria-hidden="true"></span></a>
                        <a data-toggle="tooltip" data-placement="top" title="Lock"><span class="glyphicon glyphicon-eye-close" aria-hidden="true"></span></a>
                        <a data-toggle="tooltip" data-placement="top" title="Logout" href="../login.html"><span class="glyphicon glyphicon-off" aria-hidden="true"></span></a>
                    </div>
                </div>
            </div>

            <!-- top navigation -->
            <div class="top_nav">
                <div class="nav_menu">
                    <nav>
                        <div class="navbar-header" style="width: 100%; display: flex; align-items: center">
                            <div class="nav toggle" style="padding: 5px;">
                                <a id="menu_toggle"><i class="fa fa-bars"></i></a>
                            </div>
                            <label style="font-weight: bold; font-size: 16px;">New Sales Order</label>
                        </div>
                    </nav>
                </div>
            </div>

            <!-- page content -->
            <div class="right_col" role="main">
                <div class="clearfix"></div>
                <div id="soMsg" class="alert" style="display: none;"></div>
                <div class="row">
                    <!-- Order details -->
                    <div class="col-md-5 col-sm-12 col-xs-12">
                        <div class="x_panel so-section">
                            <div class="x_title"><h2><i class="fa fa-info-circle"></i> Order Details</h2><div class="clearfix"></div></div>
                            <div class="x_content">
                                <div class="form-group">
                                    <label>Date</label>
                                    <div class="so-info" id="txtOrderDate"></div>
                                </div>
                                <div class="form-group">
                                    <label for="comboWarehouse">Warehouse</label>
                                    <select id="comboWarehouse" class="form-control" onchange="onWarehouseChange();"></select>
                                </div>
                                <div class="form-group">
                                    <label for="customerNames">Customer</label>
                                    <div class="so-search-group">
                                        <input type="text" class="form-control" id="customerNames" placeholder="Search customer" autocomplete="off" />
                                        <button type="button" class="btn btn-primary" id="btnCustSearch" title="Customer list"><i class="fa fa-users"></i></button>
                                    </div>
                                    <div id="divCustSelected" class="so-cust" style="display: none;">
                                        <a href="javascript:void(0);" onclick="clearCustomer();" class="text-danger so-cust-clear" title="Change customer"><i class="fa fa-times"></i></a>
                                        <div class="so-cust-head">
                                            <div class="so-cust-avatar"><i class="fa fa-user"></i></div>
                                            <div>
                                                <div class="so-cust-name" id="lblCustName"></div>
                                                <span class="so-cust-id" id="lblCustId"></span>
                                            </div>
                                        </div>
                                        <div class="so-cust-stats" id="divCustDetails"></div>
                                        <div class="so-cust-address" id="divCustAddress" style="display: none;"></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Item entry -->
                    <div class="col-md-7 col-sm-12 col-xs-12">
                        <div class="x_panel so-section">
                            <div class="x_title"><h2><i class="fa fa-cube"></i> Item Entry</h2><div class="clearfix"></div></div>
                            <div class="x_content">
                                <div class="form-group">
                                    <div class="so-search-group">
                                        <input type="text" class="form-control" id="txtNames" placeholder="Search item by name" autocomplete="off" />
                                        <button type="button" class="btn btn-primary" id="btnItemSearch" title="Item list"><i class="fa fa-list-ul"></i></button>
                                    </div>
                                </div>
                                <div id="itemSpec_Panel">
                                    <div class="so-cust so-item-row" style="margin-bottom: 12px;">
                                        <div class="so-item-main">
                                            <div class="so-cust-avatar"><i class="fa fa-cube"></i></div>
                                            <div class="so-item-title">
                                                <div class="so-cust-name" id="itemSpec_Name"></div>
                                                <span class="so-cust-id">Code: <span id="itemSpec_Code"></span></span>
                                            </div>
                                        </div>
                                        <div class="so-item-stats">
                                            <div class="so-cust-stat"><small>Stock</small><b id="itemSpec_Stock"></b></div>
                                            <div class="so-cust-stat"><small>HSN Code</small><b id="itemSpec_Hsn"></b></div>
                                            <div class="so-cust-stat"><small>UOM</small><b id="itemSpec_DefUom"></b></div>
                                            <div class="so-cust-stat"><small>Tax %</small><b id="itemSpec_TaxPerc"></b></div>
                                        </div>
                                    </div>
                                    <div class="row">
                                        <div class="col-sm-3 col-xs-6 form-group"><label for="itemSpec_Qty">Quantity</label><input type="text" class="form-control" id="itemSpec_Qty" /></div>
                                        <div class="col-sm-3 col-xs-6 form-group"><label for="itemSpec_Uom">UOM</label><select class="form-control" id="itemSpec_Uom"><option value="-1">Select</option></select></div>
                                        <div class="col-sm-3 col-xs-6 form-group"><label for="itemSpec_Length">Length</label><input type="text" class="form-control" id="itemSpec_Length" /></div>
                                        <div class="col-sm-3 col-xs-6 form-group"><label for="itemSpec_Width">Width</label><input type="text" class="form-control" id="itemSpec_Width" /></div>
                                    </div>
                                    <div class="row">
                                        <div class="col-sm-3 col-xs-6 form-group"><label>Final Qty<span id="itemSpec_FinalQtyUom"></span></label><input type="text" class="form-control" id="itemSpec_FinalQty" readonly="readonly" /><small id="itemSpec_FinalQtyErr" class="so-err"></small></div>
                                        <div class="col-sm-3 col-xs-6 form-group"><label for="itemSpec_Price">Price</label><input type="text" class="form-control" id="itemSpec_Price" /></div>
                                        <div class="col-sm-3 col-xs-6 form-group"><label for="itemSpec_Discount">Discount %</label><input type="text" class="form-control" id="itemSpec_Discount" /></div>
                                        <div class="col-sm-3 col-xs-6 form-group"><label>Line Net</label><input type="text" class="form-control" id="itemSpec_Net" readonly="readonly" /></div>
                                    </div>
                                    <div class="so-err" id="itemSpec_LineErr" style="margin-bottom: 8px;"></div>
                                    <button type="button" id="btnSpecAdd" class="btn btn-success" onclick="addOrUpdateItem();"><i class="fa fa-plus"></i> Add Item</button>
                                    <button type="button" class="btn btn-default" onclick="clearSpec();">Cancel</button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Order items -->
                <div class="row">
                    <div class="col-md-12">
                        <div class="x_panel so-section">
                            <div class="x_title"><h2><i class="fa fa-list"></i> Order Items <span class="badge" id="lblCount">0</span></h2><div class="clearfix"></div></div>
                            <div class="x_content" style="overflow-x: auto;">
                                <table class="table table-striped table-bordered" id="tblSoItems">
                                    <thead>
                                        <tr><th>#</th><th>Code</th><th>Item</th><th>UOM</th><th>Qty</th><th>Length x Width</th><th>Final Qty</th><th>Price</th><th>Disc</th><th>Tax %</th><th>Tax</th><th>Net</th><th></th></tr>
                                    </thead>
                                    <tbody></tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Totals and actions -->
                <div class="row">
                    <div class="col-md-7 col-sm-12">
                        <div class="x_panel so-section">
                            <div class="x_title"><h2><i class="fa fa-sticky-note-o"></i> Special Note</h2><div class="clearfix"></div></div>
                            <div class="x_content">
                                <textarea id="txtSpecialNote" class="form-control" rows="4" maxlength="500"></textarea>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-5 col-sm-12">
                        <div class="x_panel so-section">
                            <div class="x_content">
                                <table class="table so-totals">
                                    <tr><td>Total</td><td class="text-right" id="lblTotal">0</td></tr>
                                    <tr><td>Discount</td><td class="text-right" id="lblDiscount">0</td></tr>
                                    <tr><td>Tax</td><td class="text-right" id="lblTax">0</td></tr>
                                    <tr class="grand"><td>Net Amount</td><td class="text-right" id="lblNet">0</td></tr>
                                </table>
                                <button type="button" id="btnSave" class="btn btn-primary pull-right" onclick="saveSalesOrder();"><i class="fa fa-save"></i> Save Order</button>
                                <div class="clearfix"></div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <footer>
                <div class="pull-right">
                    <div class="footerDiv"><div class="footerDivContent">Copyright 2014 &copy;</div></div>
                </div>
                <div class="clearfix"></div>
            </footer>
        </div>
    </div>

    <!-- Customer search modal -->
    <div class="modal fade so-modal" id="popupCustomer" tabindex="-1" role="dialog" aria-labelledby="popupCustomerTitle">
        <div class="modal-dialog modal-lg" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <div class="so-modal-head">
                        <h4 class="modal-title" id="popupCustomerTitle">Customers <span class="badge" style="background: #d00101;" id="lblCustCount">0</span></h4>
                        <button type="button" class="btn btn-primary btn-sm" onclick="resetCustomerSearch();"><i class="fa fa-refresh"></i> Reset</button>
                        <button type="button" class="btn btn-success btn-sm" onclick="searchCustomerPage(1);"><i class="fa fa-search"></i> Search</button>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">&times;</button>
                    </div>
                </div>
                <div class="modal-body">
                    <table class="table table-striped table-bordered so-results" id="tblCustResults">
                        <thead>
                            <tr><th>Code</th><th>Name</th><th>Address</th><th>Class</th><th>Mobile</th><th class="text-right">Outstanding</th></tr>
                            <tr id="custFilters">
                                <td><input type="text" class="form-control input-sm" id="custCode" style="width: 80px;" placeholder="Code" /></td>
                                <td><input type="text" class="form-control input-sm" id="custName" placeholder="Name" autocomplete="off" /></td>
                                <td></td>
                                <td></td>
                                <td><input type="text" class="form-control input-sm" id="custPhone" style="width: 120px;" placeholder="Mobile" /></td>
                                <td></td>
                            </tr>
                        </thead>
                        <tbody></tbody>
                    </table>
                </div>
                <div class="modal-footer so-foot">
                    <div id="custPaging"></div>
                    <div>
                        <select id="custPerPage" class="input-sm" title="Rows per page">
                            <option value="10">10</option><option value="25" selected="selected">25</option><option value="50">50</option><option value="100">100</option>
                        </select>
                        <button type="button" class="btn btn-default btn-sm" data-dismiss="modal">Close</button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Item search modal -->
    <div class="modal fade so-modal" id="popupItems" tabindex="-1" role="dialog" aria-labelledby="popupItemsTitle">
        <div class="modal-dialog modal-lg" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <div class="so-modal-head">
                        <h4 class="modal-title" id="popupItemsTitle">Items <span class="badge" style="background: #d00101;" id="lblItemCount">0</span></h4>
                        <button type="button" class="btn btn-primary btn-sm" onclick="resetItemSearch();"><i class="fa fa-refresh"></i> Reset</button>
                        <button type="button" class="btn btn-success btn-sm" onclick="searchItemPage(1);"><i class="fa fa-search"></i> Search</button>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">&times;</button>
                    </div>
                </div>
                <div class="modal-body">
                    <table class="table table-striped table-bordered so-results" id="tblItemResults">
                        <thead>
                            <tr><th>Code</th><th>Name</th><th class="text-right">Stock</th><th class="text-right">Price</th></tr>
                            <tr id="itemFilters">
                                <td><input type="text" class="form-control input-sm" id="itemCode" style="width: 100px;" placeholder="Code" autocomplete="off" /></td>
                                <td><input type="text" class="form-control input-sm" id="itemName" placeholder="Name" autocomplete="off" /></td>
                                <td></td><td></td>
                            </tr>
                        </thead>
                        <tbody></tbody>
                    </table>
                </div>
                <div class="modal-footer so-foot">
                    <div id="itemPaging"></div>
                    <div>
                        <select id="itemPerPage" class="input-sm" title="Rows per page">
                            <option value="10">10</option><option value="25" selected="selected">25</option><option value="50">50</option><option value="100">100</option>
                        </select>
                        <button type="button" class="btn btn-default btn-sm" data-dismiss="modal">Close</button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="../js/bootstrap/bootstrap.min.js"></script>
    <script src="../js/bootstrap/fastclick.js"></script>
    <script src="../js/bootstrap/nprogress.js"></script>
    <script src="../js/bootstrap/icheck.min.js"></script>
    <script src="../js/bootstrap/custom.min.js"></script>
    <script src="../js/bootbox.min.js"></script>
</body>
</html>
