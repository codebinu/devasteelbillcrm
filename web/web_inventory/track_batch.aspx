<%@ Page Language="C#" AutoEventWireup="true" CodeFile="track_batch.aspx.cs" Inherits="web_inventory_track_batch" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Track Batch | Invoice Me</title>
    <script src="../js/common.js" type="text/javascript"></script>
    <script type="text/javascript" src="../js/jquery-2.0.3.js"></script>
    <script type="text/javascript" src="../js/jquery.cookie.js"></script>
    <script src="../js/pagination.js" type="text/javascript"></script>
    <script src="../js/track-batch.js" type="text/javascript"></script>

    <link href="../css/bootstrap/bootstrap.min.css" rel="stylesheet" />
    <link href="../css/font-awesome/css/font-awesome.min.css" rel="stylesheet" />
    <link href="../css/bootstrap/nprogress.css" rel="stylesheet" />
    <link href="../css/bootstrap/daterangepicker.css" rel="stylesheet" />
    <link href="../css/bootstrap/custom.min.css" rel="stylesheet" />
    <link href="../css/bootstrap/mystyle.css" type="text/css" rel="stylesheet" />
    <link href="../css/track-batch.css" type="text/css" rel="stylesheet" />
    <link rel="stylesheet" href="../mobiscroll/css/jquery.mobile-1.1.0.min.css" />
    <script src="../mobiscroll/js/mobiscroll-2.0rc3.full.min.js" type="text/javascript"></script>
    <link href="../mobiscroll/css/mobiscroll-2.0rc3.full.min.css" rel="stylesheet" type="text/css" />

    <script type="text/javascript">
        // The filters of the last search; paging, sorting and the page size reuse them.
        var query = { filters: {}, perpage: 25, sortBy: "date", sortDir: "desc" };
        var COLS = 9;

        $(document).ready(function () {
            if (!$.cookie("invntrystaffBranchId")) {
                location.href = "../dashboard.aspx";
                return false;
            }
            var yyyy = new Date().getFullYear();
            $('#txtFromDate, #txtToDate').scroller({
                preset: 'date', endYear: yyyy + 100, setText: 'Next', invalid: {},
                theme: 'ios', display: 'modal', mode: 'scroller', dateFormat: 'dd-mm-yy'
            });
            $("#txtSearch").keypress(function (e) {
                if (e.which == 13) { runSearch(); return false; }
            });
            loadItems();
            runSearch();
        });

        function loadItems() {
            TB.ajax("track_batch.aspx/getItems", {}, function (items) {
                var h = '<option value="">All items</option>';
                $.each(items, function (i, it) {
                    h += '<option value="' + TB.esc(it.id) + '">' + TB.esc(it.name) + (it.code ? ' (' + TB.esc(it.code) + ')' : '') + '</option>';
                });
                $("#slItem").html(h);
            }, function () { /* the item filter is optional */ });
        }

        function readFilters() {
            var f = {};
            if ($.trim($("#txtSearch").val()) != "") f.search = $.trim($("#txtSearch").val());
            if ($("#txtFromDate").val() != "") f.from_date = $("#txtFromDate").val();
            if ($("#txtToDate").val() != "") f.to_date = $("#txtToDate").val();
            if ($("#slType").val() != "") f.type = $("#slType").val();
            if ($("#slItem").val() != "") f.item = $("#slItem").val();
            return f;
        }

        function runSearch() {
            query.filters = readFilters();
            query.perpage = parseInt($("#slPerpage").val(), 10);
            loadPage(1);
        }

        function clearFilters() {
            $("#txtSearch, #txtFromDate, #txtToDate").val("");
            $("#slType, #slItem").val("");
            $("#slPerpage").val("25");
            query.sortBy = "date"; query.sortDir = "desc";
            runSearch();
        }

        function changePerPage() {
            query.perpage = parseInt($("#slPerpage").val(), 10);
            loadPage(1);
        }

        function sortBy(col) {
            if (query.sortBy == col) query.sortDir = query.sortDir == "asc" ? "desc" : "asc";
            else { query.sortBy = col; query.sortDir = col == "date" ? "desc" : "asc"; }
            loadPage(1);
        }

        function updateSortIcons() {
            $("#tblBatches th.sortable").removeClass("active").find(".fa").attr("class", "fa fa-sort");
            $("#tblBatches th.sortable[data-col='" + query.sortBy + "']").addClass("active")
                .find(".fa").attr("class", "fa " + (query.sortDir == "asc" ? "fa-sort-asc" : "fa-sort-desc"));
        }

        function showError(page) {
            $("#tblBatches > tbody").html('<tr><td colspan="' + COLS + '"><div class="tb-state tb-error"><i class="fa fa-exclamation-triangle"></i>'
                + 'Unable to load batches.<br /><button type="button" class="btn btn-primary btn-sm" style="margin-top:10px" onclick="loadPage(' + page + ')"><i class="fa fa-refresh"></i> Retry</button></div></td></tr>');
            $("#txtTotal").text("-");
            $("#divRange").text("");
            $("#divPagination").html("");
        }

        function loadPage(page) {
            updateSortIcons();
            $("#tblBatches > tbody").html(TB.skeletonRows(Math.min(query.perpage, 8), COLS));
            TB.ajax("track_batch.aspx/searchBatches",
                { page: page, filters: query.filters, perpage: query.perpage, sortBy: query.sortBy, sortDir: query.sortDir },
                function (obj) { render(obj, page); },
                function () { showError(page); });
        }

        function render(obj, page) {
            $("#txtTotal").text(obj.count);
            if (obj.count == 0) {
                $("#divRange").text("");
                $("#tblBatches > tbody").html('<tr><td colspan="' + COLS + '"><div class="tb-state"><i class="fa fa-search"></i>No batches match your search.'
                    + '<br /><button type="button" class="btn btn-default btn-sm" style="margin-top:10px" onclick="clearFilters()">Clear filters</button></div></td></tr>');
                $("#divPagination").html("");
                return;
            }
            var h = "";
            $.each(obj.rows, function (i, r) {
                h += '<tr>';
                h += '<td class="tb-nowrap">' + TB.esc(r.id) + '</td>';
                h += '<td class="tb-item"><div class="tb-item-name">' + TB.esc(r.item) + '</div><div class="tb-muted tb-small">' + TB.esc(r.code)
                    + (r.branch ? ' &middot; ' + TB.esc(r.branch) : '') + '</div></td>';
                h += '<td><a class="tb-batch-no" href="track_batch_details.aspx?batchId=' + encodeURIComponent(r.id) + '">' + TB.esc(r.no) + '</a></td>';
                h += '<td>' + (r.type == "customer" ? TB.esc(r.cust) : '<span class="tb-muted">&mdash;</span>') + '</td>';
                h += '<td>' + TB.typeBadge(r.type) + '</td>';
                h += '<td class="tb-nowrap">' + TB.date(r.created) + '</td>';
                h += '<td>' + TB.originBadge(r.origin, r.originLabel) + '</td>';
                h += '<td class="tb-nowrap"><b>' + TB.qty(r.current) + '</b> <span class="tb-muted tb-small">' + TB.esc(r.uom) + '</span>'
                    + '<div class="tb-muted tb-small">Free ' + TB.qty(r.free) + ' &middot; Reserved ' + TB.qty(r.reserved) + '</div></td>';
                h += '<td class="tb-nowrap"><a class="btn btn-primary btn-xs" href="track_batch_details.aspx?batchId=' + encodeURIComponent(r.id) + '"><i class="fa fa-eye"></i> View Details</a></td>';
                h += '</tr>';
            });
            $("#tblBatches > tbody").html(h);
            var from = (page - 1) * query.perpage + 1, to = Math.min(page * query.perpage, obj.count);
            $("#divRange").text("Showing " + from + "-" + to + " of " + obj.count);
            $("#divPagination").html(paginate(obj.count, query.perpage, page, "loadPage"));
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
                                    <label style="font-weight: bold; font-size: 16px;">Track Batch</label>
                                </div>
                            </div>
                        </nav>
                    </div>
                </div>

                <div class="right_col" role="main">
                    <div class="clearfix"></div>
                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12">
                            <div class="x_panel tb-filter">
                                <div class="x_content">
                                    <div class="row">
                                        <div class="col-md-5 col-sm-12 col-xs-12 form-group">
                                            <label for="txtSearch">Search</label>
                                            <div class="input-group">
                                                <span class="input-group-addon"><i class="fa fa-search"></i></span>
                                                <input type="text" class="form-control" id="txtSearch" placeholder="Item name, item code, batch number or customer batch number" />
                                            </div>
                                        </div>
                                        <div class="col-md-2 col-sm-6 col-xs-12 form-group">
                                            <label for="txtFromDate">Created from</label>
                                            <input type="text" class="form-control" id="txtFromDate" style="background-color: #fff" placeholder="From date" readonly="readonly" />
                                        </div>
                                        <div class="col-md-2 col-sm-6 col-xs-12 form-group">
                                            <label for="txtToDate">Created to</label>
                                            <input type="text" class="form-control" id="txtToDate" style="background-color: #fff" placeholder="To date" readonly="readonly" />
                                        </div>
                                        <div class="col-md-3 col-sm-6 col-xs-12 form-group">
                                            <label for="slType">Batch type</label>
                                            <select class="form-control" id="slType">
                                                <option value="">All batch types</option>
                                                <option value="customer">Customer Batch</option>
                                                <option value="system">System Generated Batch</option>
                                            </select>
                                        </div>
                                        <div class="clearfix"></div>
                                        <div class="col-md-5 col-sm-6 col-xs-12 form-group">
                                            <label for="slItem">Item</label>
                                            <select class="form-control" id="slItem">
                                                <option value="">All items</option>
                                            </select>
                                        </div>
                                        <div class="col-md-7 col-sm-6 col-xs-12 form-group" style="text-align: right; padding-top: 22px;">
                                            <button type="button" class="btn btn-default" onclick="clearFilters();"><i class="fa fa-times"></i> Clear Filters</button>
                                            <button type="button" class="btn btn-success" onclick="runSearch();"><i class="fa fa-search"></i> Search</button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title" style="margin-bottom: 0;">
                                    <div class="col-md-6 col-sm-6 col-xs-12">
                                        <strong>Batches</strong>
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
                                <div class="x_content" style="overflow-x: auto;">
                                    <table id="tblBatches" class="table table-hover tb-table">
                                        <thead>
                                            <tr>
                                                <th>Batch ID</th>
                                                <th class="sortable" data-col="item" onclick="sortBy('item')">Item<i class="fa fa-sort"></i></th>
                                                <th class="sortable" data-col="batch" onclick="sortBy('batch')">Batch Number<i class="fa fa-sort"></i></th>
                                                <th>Customer Batch</th>
                                                <th>Batch Type</th>
                                                <th class="sortable" data-col="date" onclick="sortBy('date')">Created Date<i class="fa fa-sort"></i></th>
                                                <th>Origin</th>
                                                <th>Current Quantity</th>
                                                <th>Actions</th>
                                            </tr>
                                        </thead>
                                        <tbody></tbody>
                                    </table>
                                    <div class="tb-pager">
                                        <div class="tb-muted tb-small" id="divRange"></div>
                                        <div id="divPagination"></div>
                                    </div>
                                </div>
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
    <script src="../js/bootbox.min.js"></script>
</body>
</html>
