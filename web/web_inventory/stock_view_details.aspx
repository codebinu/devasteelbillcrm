<%@ Page Language="C#" AutoEventWireup="true" CodeFile="stock_view_details.aspx.cs" Inherits="web_inventory_stock_view_details" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Item Stock | Stock View | Invoice Me</title>
    <script src="../js/common.js" type="text/javascript"></script>
    <script type="text/javascript" src="../js/jquery-2.0.3.js"></script>
    <script type="text/javascript" src="../js/jquery.cookie.js"></script>
    <script src="../js/pagination.js" type="text/javascript"></script>
    <script src="../js/track-batch.js" type="text/javascript"></script>
    <script src="../js/stock-view.js" type="text/javascript"></script>

    <link href="../css/bootstrap/bootstrap.min.css" rel="stylesheet" />
    <link href="../css/font-awesome/css/font-awesome.min.css" rel="stylesheet" />
    <link href="../css/bootstrap/nprogress.css" rel="stylesheet" />
    <link href="../css/bootstrap/custom.min.css" rel="stylesheet" />
    <link href="../css/bootstrap/mystyle.css" type="text/css" rel="stylesheet" />
    <link href="../css/track-batch.css" type="text/css" rel="stylesheet" />
    <link href="../css/stock-view.css" type="text/css" rel="stylesheet" />

    <script type="text/javascript">
        var itemId = 0, wh = "all", uom = "";
        var loaded = {};

        $(document).ready(function () {
            if (!$.cookie("invntrystaffBranchId")) {
                location.href = "../dashboard.aspx";
                return false;
            }
            itemId = parseInt((location.search.match(/[?&]itemId=(\d+)/) || [])[1], 10) || 0;
            wh = decodeURIComponent((location.search.match(/[?&]wh=([^&]*)/) || [])[1] || "all") || "all";
            if (!itemId) { showNotFound(); return; }
            $('a[data-toggle="tab"]').on("shown.bs.tab", function (e) { loadTab($(e.target).attr("href").substring(1)); });
            loadOverview();
        });

        function showNotFound() {
            $("#divOverview").html('<div class="tb-state tb-error"><i class="fa fa-ban"></i>Item not found, or you do not have access to its warehouses.</div>');
            $("#divScope, #divBreakdownPanel, #divTabsPanel").hide();
        }

        function loadError(target, retry) {
            $(target).html('<div class="tb-state tb-error"><i class="fa fa-exclamation-triangle"></i>Unable to load this section.<br />'
                + '<button type="button" class="btn btn-primary btn-sm" style="margin-top:10px" onclick="' + retry + '">'
                + '<i class="fa fa-refresh"></i> Retry</button></div>');
        }

        function skeleton() {
            return '<span class="tb-skel" style="width:90%;margin:10px 0"></span><span class="tb-skel" style="width:70%;margin:10px 0"></span><span class="tb-skel" style="width:80%;margin:10px 0"></span>';
        }

        function kv(label, value) {
            return '<dt>' + TB.esc(label) + '</dt><dd>' + (value == null || value === "" ? '<span class="tb-muted">&mdash;</span>' : value) + '</dd>';
        }

        // ---------- overview: item information, selected warehouse position, warehouse breakdown ----------
        function loadOverview() {
            loaded = {};
            $("#divOverview").html('<span class="tb-skel" style="width:40%;height:28px;margin-bottom:14px"></span><span class="tb-skel" style="width:80%;margin-bottom:8px"></span><span class="tb-skel" style="width:65%"></span>');
            $("#divScopeBody, #divBreakdown").html(skeleton());
            TB.ajax("stock_view_details.aspx/getOverview", { itemId: itemId, wh: wh }, function (o) {
                if (o.notFound) { showNotFound(); return; }
                uom = o.item.uom;
                renderOverview(o);
                renderScope(o);
                renderBreakdown(o);
                $(".tab-pane").html("");
                $("#lblDemand, #lblRes, #lblMov").hide();
                loadTab($("#tabsNav li.active a").attr("href").substring(1));
            }, function () {
                loadError("#divOverview", "loadOverview()");
                $("#divScopeBody, #divBreakdown").html("");
            });
        }

        function renderOverview(o) {
            var i = o.item;
            document.title = i.name + " | Stock View | Invoice Me";
            var h = '<div class="sv-title">' + TB.esc(i.name) + '</div>';
            h += '<div style="margin:6px 0 10px"><span class="sv-code">' + TB.esc(i.code) + '</span> ' + SV.typeBadge(i.role) + '</div>';
            h += '<div class="row">';
            h += '<div class="col-md-3 col-sm-6"><dl class="tb-kv">' + kv("Description", TB.esc(i.description)) + kv("Printing name", TB.esc(i.printingName)) + '</dl></div>';
            h += '<div class="col-md-3 col-sm-6"><dl class="tb-kv">' + kv("Category / Group", TB.esc(i.group)) + kv("Stock category", TB.esc(i.category)) + '</dl></div>';
            h += '<div class="col-md-3 col-sm-6"><dl class="tb-kv">' + kv("Brand", TB.esc(i.brand)) + kv("Item type", TB.esc(i.type)) + '</dl></div>';
            h += '<div class="col-md-3 col-sm-6"><dl class="tb-kv">' + kv("Unit", TB.esc(i.uom)) + kv("Purchase unit", TB.esc(i.purchaseUom)) + '</dl></div>';
            h += '<div class="col-md-3 col-sm-6"><dl class="tb-kv">' + kv("HSN / SAC", TB.esc(i.hsn)) + kv("Qty per carton", TB.esc(i.qtyPerCarton)) + '</dl></div>';
            h += '<div class="col-md-3 col-sm-6"><dl class="tb-kv">' + kv("Bill of material", i.bom ? "Enabled" : "Not enabled") + '</dl></div>';
            h += '</div>';
            $("#divOverview").html(h);
        }

        function tile(label, value, cls, help) {
            return '<div class="tb-tile ' + (cls || "") + '" title="' + TB.esc(help || "") + '"><div class="v">' + value + '</div><div class="l">' + TB.esc(label) + '</div><div class="u">' + TB.esc(uom) + '</div></div>';
        }

        function renderScope(o) {
            var t = o.total;
            if (!o.scoped) {
                $("#divScopeBody").html('<div class="tb-state tb-error"><i class="fa fa-ban"></i>You do not have access to the selected warehouse.</div>');
                return;
            }
            var h = '<div class="tb-tiles sv-tiles">'
                + tile("Physical Stock", SV.q(t.phys), "", SV.help.phys) + tile("Reserved", SV.q(t.resv), "", SV.help.resv)
                + tile("Free Stock", SV.q(t.free), t.free < -0.0005 ? "sv-tile-neg" : "", SV.help.free) + tile("Pending Reservation", SV.q(t.pend), "", SV.help.pend)
                + tile("Projected Balance", SV.q(t.proj), t.proj < -0.0005 ? "sv-tile-neg" : "", SV.help.proj) + '</div>';
            $("#divScopeBody").html(h);
            $("#lblScopeName").text(t.name);
            $("#lblScopeStatus").html(SV.statusBadge(t.status));
        }

        function renderBreakdown(o) {
            var h = '<div style="overflow-x:auto"><table class="table table-hover tb-table sv-table"><thead><tr><th>Warehouse</th>'
                + '<th class="num">Physical Stock' + SV.tip(SV.help.phys) + '</th><th class="num">Reserved' + SV.tip(SV.help.resv) + '</th><th class="num">Free Stock' + SV.tip(SV.help.free) + '</th>'
                + '<th class="num">Pending' + SV.tip(SV.help.pend) + '</th><th class="num">Projected Balance' + SV.tip(SV.help.proj) + '</th><th>Status</th></tr></thead><tbody>';
            $.each(o.warehouses, function (i, w) {
                h += '<tr' + (o.selected == w.id ? ' class="sv-sel"' : '') + '><td><a href="javascript:void(0);" onclick="selectWarehouse(\'' + w.id + '\')">' + TB.esc(w.name) + '</a></td>'
                    + SV.numCell(w.phys, true) + SV.numCell(w.resv) + SV.numCell(w.free, true) + SV.numCell(w.pend) + SV.numCell(w.proj, true) + '<td>' + SV.statusBadge(w.status) + '</td></tr>';
            });
            var c = o.consolidated;
            h += '<tr class="sv-total' + (o.selected == null && o.scoped ? ' sv-sel' : '') + '"><td><a href="javascript:void(0);" onclick="selectWarehouse(\'all\')">All Warehouses (consolidated)</a></td>'
                + SV.numCell(c.phys, true) + SV.numCell(c.resv) + SV.numCell(c.free, true) + SV.numCell(c.pend) + SV.numCell(c.proj, true) + '<td>' + SV.statusBadge(c.status) + '</td></tr>';
            h += '</tbody></table></div>';
            h += '<div class="sv-note">Pending demand is attributed to the warehouse of the sales order. The consolidated row is calculated from the totals, not by adding up the warehouse shortages.</div>';
            $("#divBreakdown").html(h);

            var opts = '<option value="all">All Warehouses</option>';
            $.each(o.warehouses, function (i, w) { opts += '<option value="' + TB.esc(w.id) + '">' + TB.esc(w.name) + '</option>'; });
            $("#slWarehouse").html(opts).val(wh);
            if (!$("#slWarehouse").val()) $("#slWarehouse").val("all");
        }

        function selectWarehouse(id) {
            wh = id;
            $("#slWarehouse").val(id);
            if (history.replaceState) history.replaceState(null, "", "stock_view_details.aspx?itemId=" + itemId + "&wh=" + encodeURIComponent(wh));
            loadOverview();
        }

        function changeWarehouse() { selectWarehouse($("#slWarehouse").val()); }

        // ---------- tabs (loaded when first shown) ----------
        function loadTab(id) {
            if (loaded[id]) return;
            loaded[id] = true;
            if (id == "tabDemand") loadDemand();
            else if (id == "tabRes") loadReservations();
            else if (id == "tabMov") loadMovements(1);
        }

        function retry(id, fn) {
            return function () { loaded[id] = false; fn(); };
        }

        function orderLink(r) { return TB.link(r.no, r.url, false); }

        function loadDemand() {
            $("#tabDemand").html(skeleton());
            TB.ajax("stock_view_details.aspx/getDemand", { itemId: itemId, wh: wh }, function (d) {
                $("#lblDemand").text(d.rows.length).show();
                if (d.rows.length == 0) {
                    $("#tabDemand").html('<div class="tb-state"><i class="fa fa-check-circle"></i>No active sales order is waiting for this item to be reserved.</div>');
                    return;
                }
                var h = '<div style="overflow-x:auto"><table class="table table-hover tb-table sv-table"><thead><tr><th>Sales Order</th><th>Customer</th><th>Order Date</th>'
                    + '<th class="num">Ordered</th><th class="num">Invoiced</th><th class="num">Required</th><th class="num">Reserved</th><th class="num">Pending Reservation</th><th>Warehouse</th><th>Order Status</th></tr></thead><tbody>';
                $.each(d.rows, function (i, r) {
                    h += '<tr><td class="tb-nowrap">' + orderLink(r) + '</td><td>' + TB.esc(r.customer) + '</td><td class="tb-nowrap">' + TB.date(r.date) + '</td>'
                        + SV.numCell(r.ordered) + SV.numCell(r.invoiced) + SV.numCell(r.required) + SV.numCell(r.reserved) + SV.numCell(r.pending)
                        + '<td>' + TB.esc(r.warehouse) + '</td><td>' + TB.status(r.status) + '</td></tr>';
                });
                h += '<tr class="sv-total"><td colspan="7">Total pending reservation (' + TB.esc(d.uom) + ')</td>' + SV.numCell(d.total) + '<td colspan="2"></td></tr></tbody></table></div>';
                h += '<div class="sv-note">Active orders are Approved, Processed and Partially Delivered. Required = ordered - invoiced; Pending = Required - Reserved.</div>';
                $("#tabDemand").html(h);
            }, function () { loadError("#tabDemand", "retryTab('tabDemand')"); });
        }

        function loadReservations() {
            $("#tabRes").html(skeleton());
            TB.ajax("stock_view_details.aspx/getReservations", { itemId: itemId, wh: wh }, function (d) {
                $("#lblRes").text(d.rows.length).show();
                if (d.rows.length == 0) {
                    $("#tabRes").html('<div class="tb-state"><i class="fa fa-inbox"></i>No active reservation holds this item.</div>');
                    return;
                }
                var h = '<div style="overflow-x:auto"><table class="table table-hover tb-table sv-table"><thead><tr><th>Sales Order</th><th>Customer</th><th>Warehouse</th><th>Reservation Date</th>'
                    + '<th class="num">Remaining Active Reservation</th><th class="num">Consumed' + SV.tip("Invoiced quantity of the order line. The application deletes a reservation when it is consumed, so this is not recorded per reservation.") + '</th>'
                    + '<th class="num">Released' + SV.tip("Not recorded: a released reservation is deleted.") + '</th><th>Status</th></tr></thead><tbody>';
                $.each(d.rows, function (i, r) {
                    h += '<tr><td class="tb-nowrap">' + (r.no ? orderLink(r) : '<span class="tb-muted">&mdash;</span>') + '</td><td>' + TB.esc(r.customer) + '</td><td>' + TB.esc(r.warehouse) + '</td>'
                        + '<td class="tb-nowrap">' + TB.date(r.date) + '</td>' + SV.numCell(r.remaining)
                        + (r.consumed == null ? '<td class="num zero">&mdash;</td>' : SV.numCell(r.consumed)) + '<td class="num zero">&mdash;</td>'
                        + '<td>' + (r.material ? '<span class="label label-info">Production material</span>' : TB.status(r.status)) + '</td></tr>';
                });
                h += '<tr class="sv-total"><td colspan="4">Total active reservation (' + TB.esc(d.uom) + ')</td>' + SV.numCell(d.total) + '<td colspan="3"></td></tr></tbody></table></div>';
                $("#tabRes").html(h);
            }, function () { loadError("#tabRes", "retryTab('tabRes')"); });
        }

        function loadMovements(page) {
            $("#tabMov").html(skeleton());
            TB.ajax("stock_view_details.aspx/getMovements", { itemId: itemId, wh: wh, page: page }, function (d) {
                $("#lblMov").text(d.count).show();
                if (d.count == 0) {
                    $("#tabMov").html('<div class="tb-state"><i class="fa fa-exchange"></i>No stock movement is recorded for this item.</div>');
                    return;
                }
                var h = '<div style="overflow-x:auto"><table class="table table-hover tb-table sv-table"><thead><tr><th>Date</th><th>Warehouse</th><th>Movement</th><th>Reference</th><th>Narration</th>'
                    + '<th class="num">In</th><th class="num">Out</th><th class="num">Balance' + SV.tip("Stock balance of that warehouse after the movement.") + '</th></tr></thead><tbody>';
                $.each(d.rows, function (i, r) {
                    h += '<tr><td class="tb-nowrap">' + TB.date(r.date) + '</td><td>' + TB.esc(r.warehouse) + '</td><td>' + TB.esc(r.type) + '</td><td class="tb-nowrap">' + (r.reference ? TB.link(r.reference, r.url, false) : '<span class="tb-muted">&mdash;</span>')
                        + '</td><td class="tb-small">' + TB.esc(r.narration) + '</td>' + SV.numCell(r.inQty) + SV.numCell(r.outQty) + SV.numCell(r.balance, true) + '</tr>';
                });
                h += '</tbody></table></div>';
                h += '<div class="tb-pager"><div class="tb-muted tb-small">Showing ' + ((d.page - 1) * d.perpage + 1) + '-' + Math.min(d.page * d.perpage, d.count) + ' of ' + d.count + ' (' + TB.esc(d.uom) + ')</div><div>' + paginate(d.count, d.perpage, d.page, "loadMovements") + '</div></div>';
                h += '<div class="sv-note">Movements recorded in the stock ledger, newest first. Some older workflows adjust stock without a ledger entry, so the ledger may not explain every change.</div>';
                $("#tabMov").html(h);
            }, function () { loadError("#tabMov", "retryTab('tabMov')"); });
        }

        function retryTab(id) {
            loaded[id] = false;
            loadTab(id);
        }
    </script>
</head>

<body class="nav-md">
    <form id="form1" runat="server" autocomplete="off">
        <div class="container body">
            <div class="main_container">
                <div class="col-md-3 left_col">
                    <div class="left_col scroll-view">
                        <div class="navbar nav_title" style="border: 0;">
                            <a href="#" class="site_title"><span>Invoice</span></a>
                        </div>
                        <div class="clearfix"></div>
                        <div class="profile clearfix"></div>
                        <br />
                        <div id="sidebar-menu" class="main_menu_side hidden-print main_menu"></div>
                        <div class="sidebar-footer hidden-small"></div>
                    </div>
                </div>

                <div class="top_nav">
                    <div class="nav_menu">
                        <nav>
                            <div class="navbar-header" style="width: 100%; display: flex; align-items: center">
                                <div class="nav toggle" style="padding: 5px;">
                                    <a id="menu_toggle"><i class="fa fa-bars"></i></a>
                                </div>
                                <div class="col-md-6 col-xs-6">
                                    <label style="font-weight: bold; font-size: 16px;">Stock View</label>
                                </div>
                                <div class="col-md-6 col-xs-5">
                                    <a href="stock_view.aspx" class="btn btn-default btn-xs pull-right" style="margin-top: 5px"><i class="fa fa-arrow-left"></i> Back to Stock View</a>
                                </div>
                            </div>
                        </nav>
                    </div>
                </div>

                <div class="right_col" role="main">
                    <div class="clearfix"></div>

                    <%-- A. Item information --%>
                    <div class="x_panel">
                        <div class="x_content" id="divOverview"></div>
                    </div>

                    <%-- Selected warehouse position --%>
                    <div class="x_panel" id="divScope">
                        <div class="x_title" style="margin-bottom: 8px;">
                            <div class="sv-header">
                                <div class="sv-wh">
                                    <label for="slWarehouse">Warehouse</label>
                                    <select id="slWarehouse" class="form-control" onchange="changeWarehouse();"><option value="all">All Warehouses</option></select>
                                </div>
                                <div class="sv-meta" style="text-align: left"><strong id="lblScopeName"></strong> <span id="lblScopeStatus"></span></div>
                            </div>
                            <div class="clearfix"></div>
                        </div>
                        <div class="x_content" id="divScopeBody"></div>
                    </div>

                    <%-- B. Warehouse-wise breakdown --%>
                    <div class="x_panel" id="divBreakdownPanel">
                        <div class="x_title" style="margin-bottom: 8px;"><strong>Warehouse-wise Stock</strong>
                            <div class="clearfix"></div>
                        </div>
                        <div class="x_content" id="divBreakdown"></div>
                    </div>

                    <%-- C-E. Demand, reservations, movement history --%>
                    <div class="x_panel" id="divTabsPanel">
                        <div class="x_content">
                            <ul class="nav nav-tabs tb-tabs" role="tablist" id="tabsNav">
                                <li class="active"><a href="#tabDemand" role="tab" data-toggle="tab">Active Sales Order Demand <span class="badge" id="lblDemand" style="display: none"></span></a></li>
                                <li><a href="#tabRes" role="tab" data-toggle="tab">Current Reservations <span class="badge" id="lblRes" style="display: none"></span></a></li>
                                <li><a href="#tabMov" role="tab" data-toggle="tab">Stock Movement History <span class="badge" id="lblMov" style="display: none"></span></a></li>
                            </ul>
                            <div class="tab-content tb-tab-body">
                                <div class="tab-pane active" id="tabDemand"></div>
                                <div class="tab-pane" id="tabRes"></div>
                                <div class="tab-pane" id="tabMov"></div>
                            </div>
                        </div>
                    </div>
                </div>
                <footer>
                    <div class="pull-right">
                        <div class="footerDiv">
                            <div class="footerDivContent"></div>
                        </div>
                    </div>
                    <div class="clearfix"></div>
                </footer>
            </div>
        </div>
    </form>

    <script src="../js/bootstrap/bootstrap.min.js"></script>
    <script src="../js/bootstrap/fastclick.js"></script>
    <script src="../js/bootstrap/nprogress.js"></script>
    <script src="../js/bootstrap/icheck.min.js"></script>
    <script src="../js/bootstrap/custom.min.js"></script>
</body>
</html>
