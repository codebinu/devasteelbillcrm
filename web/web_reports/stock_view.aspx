<%@ Page Language="C#" AutoEventWireup="true" CodeFile="stock_view.aspx.cs" Inherits="web_inventory_stock_view" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Stock View | Invoice Me</title>
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
        var STATE_KEY = "stockViewState";
        // The state of the last search; paging, sorting, the page size and warehouse switches reuse its filters.
        var query = { wh: "all", filters: {}, perpage: 25, sortBy: "name", sortDir: "asc", page: 1 };
        var COLS = 11;

        $(document).ready(function () {
            if (!$.cookie("invntrystaffBranchId")) {
                location.href = "../dashboard.aspx";
                return false;
            }
            restoreState();
            $("#txtSearch, #txtMin, #txtMax").keypress(function (e) {
                if (e.which == 13) { runSearch(); return false; }
            });
            loadOptions();
        });

        function saveState() {
            try { sessionStorage.setItem(STATE_KEY, JSON.stringify(query)); } catch (e) { }
        }

        function restoreState() {
            try {
                var s = JSON.parse(sessionStorage.getItem(STATE_KEY) || "null");
                if (s && s.filters) query = $.extend(query, s);
            } catch (e) { }
            var f = query.filters;
            $("#txtSearch").val(f.search || "");
            $("#txtMin").val(f.min || "");
            $("#txtMax").val(f.max || "");
            $("#slStatus").val(f.status || "");
            $("#slType").val(f.type || "");
            $("#slPerpage").val(String(query.perpage));
        }

        function loadOptions() {
            TB.ajax("stock_view.aspx/getOptions", {}, function (o) {
                var h = '<option value="all">All Warehouses</option>';
                $.each(o.warehouses, function (i, w) { h += '<option value="' + TB.esc(w.id) + '">' + TB.esc(w.name) + '</option>'; });
                $("#slWarehouse").html(h);
                if ($("#slWarehouse option[value='" + query.wh + "']").length == 0) query.wh = "all";
                $("#slWarehouse").val(query.wh);

                var g = '<option value="">All categories</option>';
                $.each(o.groups, function (i, x) { g += '<option value="' + TB.esc(x.id) + '">' + TB.esc(x.name) + '</option>'; });
                $("#slGroup").html(g).val(query.filters.group || "");
                var b = '<option value="">All brands</option>';
                $.each(o.brands, function (i, x) { b += '<option value="' + TB.esc(x.id) + '">' + TB.esc(x.name) + '</option>'; });
                $("#slBrand").html(b).val(query.filters.brand || "");
                loadPage(query.page || 1);
            }, function () { showError(1); });
        }

        function readFilters() {
            var f = {};
            if ($.trim($("#txtSearch").val()) != "") f.search = $.trim($("#txtSearch").val());
            if ($("#slGroup").val()) f.group = $("#slGroup").val();
            if ($("#slBrand").val()) f.brand = $("#slBrand").val();
            if ($("#slType").val()) f.type = $("#slType").val();
            if ($("#slStatus").val()) f.status = $("#slStatus").val();
            if ($.trim($("#txtMin").val()) != "") f.min = $.trim($("#txtMin").val());
            if ($.trim($("#txtMax").val()) != "") f.max = $.trim($("#txtMax").val());
            return f;
        }

        function runSearch() {
            query.filters = readFilters();
            query.perpage = parseInt($("#slPerpage").val(), 10);
            loadPage(1);
        }

        // Switching the warehouse keeps the filters on screen.
        function changeWarehouse() {
            query.wh = $("#slWarehouse").val();
            runSearch();
        }

        function clearFilters() {
            $("#txtSearch, #txtMin, #txtMax").val("");
            $("#slGroup, #slBrand, #slType, #slStatus").val("");
            query.sortBy = "name"; query.sortDir = "asc";
            runSearch();
        }

        function changePerPage() {
            query.perpage = parseInt($("#slPerpage").val(), 10);
            loadPage(1);
        }

        function sortBy(col) {
            if (query.sortBy == col) query.sortDir = query.sortDir == "asc" ? "desc" : "asc";
            else { query.sortBy = col; query.sortDir = (col == "name" || col == "code") ? "asc" : "desc"; }
            loadPage(1);
        }

        function updateSortIcons() {
            $("#tblStock th.sortable").removeClass("active").find(".fa-sort, .fa-sort-asc, .fa-sort-desc").attr("class", "fa fa-sort");
            $("#tblStock th.sortable[data-col='" + query.sortBy + "']").addClass("active")
                .find(".fa-sort, .fa-sort-asc, .fa-sort-desc").attr("class", "fa " + (query.sortDir == "asc" ? "fa-sort-asc" : "fa-sort-desc"));
        }

        function showError(page) {
            $("#tblStock > tbody").html('<tr><td colspan="' + COLS + '"><div class="tb-state tb-error"><i class="fa fa-exclamation-triangle"></i>'
                + 'Unable to load the stock.<br /><button type="button" class="btn btn-primary btn-sm" style="margin-top:10px" onclick="loadPage(' + page + ')"><i class="fa fa-refresh"></i> Retry</button></div></td></tr>');
            $("#txtTotal").text("-");
            $("#divRange, #divPagination").html("");
            $(".sv-card .v").text("-");
            $("#btnExport").prop("disabled", true);
        }

        function summarySkeleton() {
            $(".sv-card .v").html('<span class="tb-skel" style="width:60%;height:22px"></span>');
            $(".sv-card .s").text("");
        }

        function loadPage(page) {
            query.page = page;
            saveState();
            updateSortIcons();
            summarySkeleton();
            $("#btnExport").prop("disabled", false);
            $("#tblStock > tbody").html(TB.skeletonRows(Math.min(query.perpage, 8), COLS));
            TB.ajax("stock_view.aspx/searchStock",
                { page: page, filters: $.extend({ wh: query.wh }, query.filters), perpage: query.perpage, sortBy: query.sortBy, sortDir: query.sortDir },
                function (obj) {
                    if (obj.page) query.page = page = obj.page;
                    render(obj, page);
                },
                function () { showError(page); });
        }

        function renderSummary(s, warehouse) {
            $("#cdItems .v").text(s.items.toLocaleString());
            $("#cdItems .s").text(s.shortage > 0 ? s.shortage + " with a projected shortage" : "");
            $("#cdPhys .v").html(SV.q(s.phys));
            $("#cdResv .v").html(SV.q(s.resv));
            $("#cdFree .v").html(SV.q(s.free));
            $("#cdPend .v").html(SV.q(s.pend));
            $("#lblWarehouse").text(warehouse || "");
        }

        function render(obj, page) {
            renderSummary(obj.summary, obj.warehouse);
            $("#lblUpdated").text("Updated " + (obj.asOf || "").substring(11, 19));
            $("#txtTotal").text(obj.count);
            if (obj.count == 0) {
                $("#divRange").text("");
                $("#tblStock > tbody").html('<tr><td colspan="' + COLS + '"><div class="tb-state"><i class="fa fa-search"></i>No items match your search.'
                    + '<br /><button type="button" class="btn btn-default btn-sm" style="margin-top:10px" onclick="clearFilters()">Clear filters</button></div></td></tr>');
                $("#divPagination").html("");
                $("#btnExport").prop("disabled", true);
                return;
            }
            var h = "";
            $.each(obj.rows, function (i, r) {
                var url = detailsUrl(r.id);
                h += '<tr>';
                h += '<td class="tb-nowrap sv-code">' + TB.esc(r.code) + '</td>';
                h += '<td class="tb-item"><a class="sv-item-link" href="' + url + '">' + TB.esc(r.name) + '</a>'
                    + '<div class="tb-muted tb-small">' + TB.esc({ finished: "Finished Goods", raw: "Raw Material", other: "Other" }[r.itype] || "") + (r.brand ? ' &middot; ' + TB.esc(r.brand) : '') + '</div></td>';
                h += '<td>' + (r.group ? TB.esc(r.group) : '<span class="tb-muted">&mdash;</span>') + '</td>';
                h += '<td class="tb-nowrap">' + TB.esc(r.uom) + '</td>';
                h += SV.numCell(r.phys, true);
                h += SV.numCell(r.resv);
                h += SV.numCell(r.free, true);
                h += SV.numCell(r.pend);
                h += SV.numCell(r.proj, true);
                h += '<td>' + SV.statusBadge(r.status) + '</td>';
                h += '<td class="tb-nowrap"><a class="btn btn-primary btn-xs" href="' + url + '"><i class="fa fa-eye"></i> View Details</a></td>';
                h += '</tr>';
            });
            $("#tblStock > tbody").html(h);
            var from = (page - 1) * query.perpage + 1, to = Math.min(page * query.perpage, obj.count);
            $("#divRange").text("Showing " + from + "-" + to + " of " + obj.count);
            $("#divPagination").html(paginate(obj.count, query.perpage, page, "loadPage"));
        }

        function detailsUrl(id) {
            return "stock_view_details.aspx?itemId=" + encodeURIComponent(id) + "&wh=" + encodeURIComponent(query.wh);
        }

        function exportExcel() {
            var p = $.extend({ wh: query.wh, sortBy: query.sortBy, sortDir: query.sortDir }, query.filters);
            window.location.href = "stock_view_export.aspx?" + $.param(p);
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
                            </div>
                        </nav>
                    </div>
                </div>

                <div class="right_col" role="main">
                    <div class="clearfix"></div>

                    <%-- Header: warehouse selector --%>
                    <div class="x_panel">
                        <div class="x_content">
                            <div class="sv-header">
                                <div class="sv-wh">
                                    <label for="slWarehouse">Warehouse</label>
                                    <select id="slWarehouse" class="form-control" onchange="changeWarehouse();">
                                        <option value="all">All Warehouses</option>
                                    </select>
                                </div>
                                <div class="sv-meta">
                                    Showing <strong id="lblWarehouse">All Warehouses</strong> &middot; <span id="lblUpdated"></span>
                                    <button type="button" class="btn btn-default btn-sm" onclick="loadPage(query.page);"><i class="fa fa-refresh"></i> Refresh</button>
                                    <button type="button" class="btn btn-success btn-sm" id="btnExport" onclick="exportExcel();"><i class="fa fa-file-excel-o"></i> Export to Excel</button>
                                </div>
                            </div>
                        </div>
                    </div>

                    <%-- Summary --%>
                    <div class="sv-cards">
                        <div class="sv-card items" id="cdItems"><div class="l" title="Item master records that match the filters">Total Items</div><div class="v">-</div><div class="s"></div></div>
                        <div class="sv-card phys" id="cdPhys"><div class="l" title="Physical Stock: the stock currently held. The total adds quantities in each item's own unit.">Physical Stock</div><div class="v">-</div><div class="s"></div></div>
                        <div class="sv-card resv" id="cdResv"><div class="l" title="Reserved Stock: held for sales orders, not yet invoiced or released.">Reserved</div><div class="v">-</div><div class="s"></div></div>
                        <div class="sv-card free" id="cdFree"><div class="l" title="Free Stock = Physical Stock - Reserved Stock.">Free Stock</div><div class="v">-</div><div class="s"></div></div>
                        <div class="sv-card pend" id="cdPend"><div class="l" title="Pending Reservation: what active sales orders still need reserved (ordered less invoiced less already reserved).">Pending Reservation</div><div class="v">-</div><div class="s"></div></div>
                    </div>

                    <%-- Filters --%>
                    <div class="x_panel sv-filter">
                        <div class="x_content">
                            <div class="row">
                                <div class="col-md-4 col-sm-12 col-xs-12 form-group">
                                    <label for="txtSearch">Search</label>
                                    <div class="input-group">
                                        <span class="input-group-addon"><i class="fa fa-search"></i></span>
                                        <input type="text" class="form-control" id="txtSearch" placeholder="Item name, code or description" />
                                    </div>
                                </div>
                                <div class="col-md-2 col-sm-6 col-xs-12 form-group">
                                    <label for="slGroup">Category / Group</label>
                                    <select class="form-control" id="slGroup"><option value="">All categories</option></select>
                                </div>
                                <div class="col-md-2 col-sm-6 col-xs-12 form-group">
                                    <label for="slBrand">Brand</label>
                                    <select class="form-control" id="slBrand"><option value="">All brands</option></select>
                                </div>
                                <div class="col-md-2 col-sm-6 col-xs-12 form-group">
                                    <label for="slType">Item Type</label>
                                    <select class="form-control" id="slType">
                                        <option value="">All types</option>
                                        <option value="raw">Raw Material</option>
                                        <option value="finished">Finished Goods</option>
                                        <option value="other">Other</option>
                                    </select>
                                </div>
                                <div class="col-md-2 col-sm-6 col-xs-12 form-group">
                                    <label for="slStatus">Stock Status</label>
                                    <select class="form-control" id="slStatus">
                                        <option value="">All items</option>
                                        <option value="instock">In Stock</option>
                                        <option value="zero">Zero Stock</option>
                                        <option value="negative">Negative Stock</option>
                                        <option value="reserved">Reserved</option>
                                        <option value="pending">Pending Reservation</option>
                                        <option value="shortage">Shortage</option>
                                    </select>
                                </div>
                                <div class="clearfix"></div>
                                <div class="col-md-2 col-sm-6 col-xs-6 form-group">
                                    <label for="txtMin">Min physical stock</label>
                                    <input type="text" class="form-control" id="txtMin" placeholder="Min" />
                                </div>
                                <div class="col-md-2 col-sm-6 col-xs-6 form-group">
                                    <label for="txtMax">Max physical stock</label>
                                    <input type="text" class="form-control" id="txtMax" placeholder="Max" />
                                </div>
                                <div class="col-md-8 col-sm-12 col-xs-12 form-group" style="text-align: right; padding-top: 22px;">
                                    <button type="button" class="btn btn-default" onclick="clearFilters();"><i class="fa fa-times"></i> Clear Filters</button>
                                    <button type="button" class="btn btn-success" onclick="runSearch();"><i class="fa fa-search"></i> Search</button>
                                </div>
                            </div>
                        </div>
                    </div>

                    <%-- Stock table --%>
                    <div class="x_panel">
                        <div class="x_title" style="margin-bottom: 0;">
                            <div class="col-md-6 col-sm-6 col-xs-12">
                                <strong>Items</strong>
                                <span class="badge" style="background: #d00101; margin-left: 5px;" id="txtTotal"></span>
                            </div>
                            <div class="col-md-6 col-sm-6 col-xs-12" style="text-align: right;">
                                <span class="tb-muted tb-small">Rows per page</span>
                                <select id="slPerpage" onchange="changePerPage();" class="input-sm">
                                    <option value="25" selected="selected">25</option>
                                    <option value="50">50</option>
                                    <option value="100">100</option>
                                </select>
                            </div>
                            <div class="clearfix"></div>
                        </div>
                        <div class="x_content sv-scroll">
                            <table id="tblStock" class="table table-hover tb-table sv-table">
                                <thead>
                                    <tr>
                                        <th class="sortable" data-col="code" onclick="sortBy('code')">Item Code<i class="fa fa-sort"></i></th>
                                        <th class="sortable" data-col="name" onclick="sortBy('name')">Item Name<i class="fa fa-sort"></i></th>
                                        <th>Category</th>
                                        <th>Unit</th>
                                        <th class="sortable num" data-col="phys" onclick="sortBy('phys')">Physical Stock<i class="fa fa-sort"></i><i class="fa fa-info-circle" title="Physical Stock: the stock currently held (the stock balance the stock workflows maintain). Invoiced quantity has already left it."></i></th>
                                        <th class="sortable num" data-col="resv" onclick="sortBy('resv')">Reserved<i class="fa fa-sort"></i><i class="fa fa-info-circle" title="Reserved Stock: quantity held for sales orders that has not been invoiced or released yet."></i></th>
                                        <th class="num">Free Stock<i class="fa fa-info-circle" title="Free Stock = Physical Stock - Reserved Stock."></i></th>
                                        <th class="sortable num" data-col="pend" onclick="sortBy('pend')">Pending Reservation<i class="fa fa-sort"></i><i class="fa fa-info-circle" title="Pending Reservation: what active sales orders (Approved, Processed, Partially Delivered) still need, less what is already reserved and invoiced."></i></th>
                                        <th class="sortable num" data-col="proj" onclick="sortBy('proj')">Projected Balance<i class="fa fa-sort"></i><i class="fa fa-info-circle" title="Projected Balance = Free Stock - Pending Reservation. A negative value is a planning warning, not a ledger balance."></i></th>
                                        <th>Stock Status</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody></tbody>
                            </table>
                        </div>
                        <div class="tb-pager" style="padding: 10px 14px;">
                            <div class="tb-muted tb-small" id="divRange"></div>
                            <div id="divPagination"></div>
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
