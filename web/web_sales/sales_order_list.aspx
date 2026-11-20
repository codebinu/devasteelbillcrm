<%@ Page Language="C#" AutoEventWireup="true" CodeFile="sales_order_list.aspx.cs" Inherits="web_sales_sales_order_list" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Sales Orders | Invoice Me</title>
    <script src="../js/common.js" type="text/javascript"></script>
    <script type="text/javascript" src="../js/jquery-2.0.3.js"></script>
    <script type="text/javascript" src="../js/jquery.cookie.js"></script>
    <script src="../js/pagination.js" type="text/javascript"></script>

    <link href="../css/bootstrap/bootstrap.min.css" rel="stylesheet" />
    <link href="../css/font-awesome/css/font-awesome.min.css" rel="stylesheet" />
    <link href="../css/bootstrap/nprogress.css" rel="stylesheet" />
    <link href="../css/bootstrap/daterangepicker.css" rel="stylesheet" />
    <link href="../css/bootstrap/custom.min.css" rel="stylesheet" />
    <link href="../css/bootstrap/mystyle.css" type="text/css" rel="stylesheet" />
    <link rel="stylesheet" href="../mobiscroll/css/jquery.mobile-1.1.0.min.css" />
    <script src="../mobiscroll/js/mobiscroll-2.0rc3.full.min.js" type="text/javascript"></script>
    <link href="../mobiscroll/css/mobiscroll-2.0rc3.full.min.css" rel="stylesheet" type="text/css" />

    <style type="text/css">
        .so-page { --so-ink: #1f2d3d; --so-muted: #7b8794; --so-line: #e6e9ee; --so-brand: #2a3f54; }

        .so-stats { display: flex; flex-wrap: wrap; margin: 12px -6px 0; padding-top: 10px; }
        .so-stat { flex: 1 1 200px; margin: 0 6px 10px; padding: 8px 14px; background: #fff; border: 1px solid var(--so-line); border-left: 4px solid var(--so-brand); border-radius: 4px; }
        .so-stat .so-stat-label { color: var(--so-muted); font-size: 11px; text-transform: uppercase; letter-spacing: .5px; }
        .so-stat .so-stat-value { font-size: 20px; font-weight: 600; color: var(--so-ink); line-height: 1.3; }
        .so-stat.so-stat-warn { border-left-color: #f0ad4e; }
        .so-stat.so-stat-warn .so-stat-value { color: #c77c0a; }
        .so-stat.so-stat-ok { border-left-color: #26b99a; }

        .so-filter label { font-size: 12px; font-weight: 600; color: var(--so-muted); text-transform: uppercase; letter-spacing: .4px; margin-bottom: 4px; }
        .so-filter .form-control { height: 36px; background: #fff; }
        .so-filter .so-filter-actions { padding-top: 4px; }
        .so-filter .so-filter-actions .btn { margin: 0 0 0 6px; }

        .so-list-head { display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 10px; padding: 4px 0 10px; }
        .so-list-head .so-count { font-weight: 600; color: var(--so-ink); }
        .so-list-head .so-count .badge { background: var(--so-brand); margin-left: 6px; }
        .so-list-head .so-perpage { color: var(--so-muted); font-size: 13px; }
        .so-list-head .so-perpage select { margin-left: 6px; }

        #tblOrders { margin-bottom: 0; }
        #tblOrders thead th { background: #f6f8fa; color: #52606d; font-size: 12px; text-transform: uppercase; letter-spacing: .4px; border-bottom: 2px solid var(--so-line); white-space: nowrap; vertical-align: middle; }
        #tblOrders thead th.sortable { cursor: pointer; user-select: none; }
        #tblOrders thead th.sortable:hover { color: var(--so-ink); }
        #tblOrders thead th .fa { margin-left: 4px; color: #b0b8c1; }
        #tblOrders thead th.so-sorted .fa { color: var(--so-brand); }
        #tblOrders tbody td { vertical-align: middle; border-top: 1px solid var(--so-line); padding: 12px 8px; }
        #tblOrders tbody tr.so-row { cursor: pointer; transition: background-color .15s; }
        #tblOrders tbody tr.so-row:hover { background-color: #f1f6fb; }
        #tblOrders tbody tr.so-row.so-cancelled td { opacity: .6; }
        #tblOrders tbody tr.so-row.so-cancelled .so-amount { text-decoration: line-through; }
        .so-num { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap; }
        .so-order { font-weight: 600; color: #1a73b8; }
        .so-order small { display: block; font-weight: 400; color: var(--so-muted); }
        .so-customer { color: var(--so-ink); font-weight: 600; }
        .so-customer small { display: block; font-weight: 400; color: var(--so-muted); }
        .so-customer small .fa { margin: 0 4px 0 8px; }
        .so-customer small .fa:first-child { margin-left: 0; }
        .so-meta { color: var(--so-muted); font-size: 13px; }
        .so-meta .fa { margin-right: 5px; }
        .so-meta small { display: block; }
        .so-tag { font-size: 11px; padding: 2px 6px; border-radius: 3px; background: #eef1f4; color: #52606d; margin-left: 6px; font-weight: 600; }
        .so-status { font-size: 11px; padding: 4px 8px; border-radius: 10px; font-weight: 600; }
        .so-hl { background: #fff3a8; color: inherit; padding: 0; }
        .so-empty { text-align: center; padding: 40px 10px !important; color: var(--so-muted); }
        .so-empty .fa { font-size: 36px; display: block; margin-bottom: 10px; color: #c5ccd3; }
        .so-skeleton td { padding: 16px 8px !important; }
        .so-skeleton .so-bar { height: 12px; border-radius: 6px; background: linear-gradient(90deg, #eef1f4 25%, #f8f9fb 50%, #eef1f4 75%); background-size: 200% 100%; animation: so-shimmer 1.2s infinite; }
        @keyframes so-shimmer { from { background-position: 200% 0; } to { background-position: -200% 0; } }
        #divPagination { text-align: center; padding-top: 10px; }

        @media (max-width: 767px) {
            .so-hide-sm { display: none !important; }
            #tblOrders thead { display: none; }
            #tblOrders, #tblOrders tbody, #tblOrders tbody tr.so-row, #tblOrders tbody td { display: block; width: 100%; }
            #tblOrders tbody tr.so-row { border: 1px solid var(--so-line); border-radius: 4px; margin-bottom: 10px; padding: 6px 4px; background: #fff; }
            #tblOrders tbody td { border-top: 0; padding: 4px 10px; }
            #tblOrders tbody td.so-num { text-align: left; }
            #tblOrders tbody td[data-label]:before { content: attr(data-label) ": "; color: var(--so-muted); font-size: 12px; }
        }
    </style>

    <script type="text/javascript">
        var sortBy = "date", sortDir = "desc";
        var statusMap = {
            0: ["Draft", "label-default"],
            1: ["To be confirmed", "label-warning"],
            2: ["Approved", "label-success"],
            3: ["Processed", "label-primary"],
            9: ["Partially Delivered", "label-info"],
            10: ["Fully Delivered", "label-success"],
            11: ["Cancelled by Company", "label-default"],
            12: ["Cancelled by Customer", "label-default"],
            13: ["On Hold", "label-info"]
        };
        var payMap = { 1: "Cash", 2: "Credit", 3: "Bill to bill" };
        var typeMap = { 1: "Direct visit", 2: "Telephonic", 3: "Mail" };

        // helpers for safe, readable rendering of values
        function soEscape(value) {
            return $('<div/>').text(value == null ? '' : String(value)).html();
        }

        function soHighlight(search, value) {
            var text = soEscape(value);
            if (!search) return text;
            var safe = soEscape(search).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
            return text.replace(new RegExp('(' + safe + ')', 'gi'), '<mark class="so-hl">$1</mark>');
        }

        function soMoney(value) {
            var n = parseFloat(value);
            if (isNaN(n)) n = 0;
            return n.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
        }

        function soSkeleton() {
            var htm = '';
            for (var i = 0; i < 5; i++) {
                htm += '<tr class="so-skeleton"><td colspan="7"><div class="so-bar"></div></td></tr>';
            }
            $('#tblOrders > tbody').html(htm);
        }

        function soEmpty(message) {
            $('#tblOrders > tbody').html('<tr><td colspan="7" class="so-empty"><i class="fa fa-inbox"></i>' + message + '</td></tr>');
            $('#txttotalordercount, #statTotalOrders, #statPageOpen, #statPageDelivered').text(0);
            $('#statPageTotal').text(soMoney(0));
            $('#divPagination').html('');
        }

        $(document).ready(function () {
            if (!$.cookie("invntrystaffBranchId")) {
                location.href = "../dashboard.aspx";
                return false;
            }
            var yyyy = new Date().getFullYear();
            $('#txtSearchFromDate, #txtSearchToDate').scroller({
                preset: 'date', endYear: yyyy + 100, setText: 'Next', invalid: {},
                theme: 'ios', display: 'modal', mode: 'scroller', dateFormat: 'dd-mm-yy'
            });
            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " &copy;");
            getBranches();
        });

        function getBranches() {
            loading();
            $.ajax({
                type: "POST", url: "sales_order_list.aspx/getBranches", data: "{}",
                contentType: "application/json; charset=utf-8", dataType: "json",
                success: function (msg) {
                    var obj = JSON.parse(msg.d);
                    var htm = '<option value="-1" selected="selected">All warehouses</option>';
                    $.each(obj, function (i, row) {
                        htm += '<option value="' + soEscape(row.branch_id) + '">' + soEscape(row.branch_name) + '</option>';
                    });
                    $("#slBranch").html(htm);
                    Unloading();
                    searchOrders(1);
                },
                error: function () {
                    Unloading();
                    soEmpty('Could not load warehouses. Please check your connection and try again.');
                }
            });
        }

        function sortOrders(col) {
            if (sortBy == col) { sortDir = sortDir == "asc" ? "desc" : "asc"; }
            else { sortBy = col; sortDir = "asc"; }
            searchOrders(1);
        }

        function updateSortIcons() {
            $("#tblOrders th.sortable").removeClass("so-sorted").find(".fa").attr("class", "fa fa-sort");
            $("#tblOrders th.sortable[data-col='" + sortBy + "']").addClass("so-sorted")
                .find(".fa").attr("class", "fa " + (sortDir == "asc" ? "fa-sort-asc" : "fa-sort-desc"));
        }

        function searchOrders(page) {
            var filters = {};
            var perpage = $("#slPerpage").val();
            if ($.trim($("#txtSearch").val()) != "") filters.search = $.trim($("#txtSearch").val());
            if ($.trim($("#txtCustSearch").val()) != "") filters.custSearch = $.trim($("#txtCustSearch").val());
            if ($("#slBranch").val() && $("#slBranch").val() != "-1") filters.branch = $("#slBranch").val();
            if ($("#slOrderStatus").val() != "-1") filters.order_status = $("#slOrderStatus").val();
            if ($("#txtSearchFromDate").val() != "") filters.from_date = $("#txtSearchFromDate").val();
            if ($("#txtSearchToDate").val() != "") filters.to_date = $("#txtSearchToDate").val();

            updateSortIcons();
            loading();
            soSkeleton();

            $.ajax({
                type: "POST",
                url: "sales_order_list.aspx/searchSalesOrders",
                data: JSON.stringify({ page: page, filters: filters, perpage: parseInt(perpage, 10), sortBy: sortBy, sortDir: sortDir }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d == "E") {
                        soEmpty('Unable to load sales orders. Please try again.');
                        return;
                    }
                    var obj;
                    try {
                        obj = JSON.parse(msg.d);
                    } catch (ex) {
                        soEmpty('Unable to load sales orders. Please try again.');
                        return;
                    }
                    if (!obj.data || obj.count == 0) {
                        soEmpty('No sales orders found<br /><small>Try changing the filters or create a new sales order.</small>');
                        return;
                    }

                    var htm = "";
                    var pageTotal = 0, pageOpen = 0, pageDelivered = 0;
                    $.each(obj.data, function (i, row) {
                        var status = parseInt(row.order_status, 10);
                        var st = statusMap[status] || statusMap[0];
                        var cancelled = status == 11 || status == 12;
                        var net = parseFloat(row.net_amount) || 0;
                        var url = 'view_sales_order.aspx?smoId=' + encodeURIComponent(row.smo_id);

                        if (!cancelled) {
                            pageTotal += net;
                            if (status == 9 || status == 10) pageDelivered++; else pageOpen++;
                        }

                        htm += '<tr class="so-row' + (cancelled ? ' so-cancelled' : '') + '" data-href="' + url + '">';
                        htm += '<td data-label="Order"><a class="so-order" href="' + url + '">#' + soHighlight(filters.search, row.smo_id) + '<small>'
                            + (row.smo_invoice_no ? 'Invoice ' + soHighlight(filters.search, row.smo_invoice_no) : 'No invoice yet') + '</small></a></td>';

                        htm += '<td data-label="Customer" class="so-customer">' + soHighlight(filters.search || filters.custSearch, row.cust_name);
                        if (row['class']) htm += '<span class="so-tag">Class ' + soEscape(row['class']) + '</span>';
                        htm += '<small><i class="fa fa-user"></i>ID ' + soEscape(row.cust_id);
                        if (row.cust_phone) htm += '<i class="fa fa-phone"></i>' + soEscape(row.cust_phone);
                        if (row.cust_city) htm += '<i class="fa fa-building"></i>' + soEscape(row.cust_city);
                        htm += '</small></td>';

                        htm += '<td data-label="Date" class="so-meta so-hide-sm"><i class="fa fa-calendar"></i>' + soEscape(row.orderDate) + '</td>';

                        htm += '<td data-label="Warehouse" class="so-meta so-hide-sm"><i class="fa fa-map-marker"></i>' + soEscape(row.branch_name)
                            + '<small><i class="fa fa-user"></i>' + soEscape($.trim(row.seller_name));
                        if (typeMap[row.smo_order_type]) htm += ' &middot; ' + typeMap[row.smo_order_type];
                        htm += '</small></td>';

                        htm += '<td data-label="Status"><span class="label ' + st[1] + ' so-status">' + soHighlight(filters.search, st[0]) + '</span>';
                        if (row.smo_payment_type > 0 && payMap[row.smo_payment_type]) htm += '<span class="so-tag">' + payMap[row.smo_payment_type] + '</span>';
                        htm += '</td>';

                        htm += '<td data-label="Net Amount" class="so-num so-amount"><b>&#8377; ' + soMoney(net) + '</b></td>';
                        htm += '<td class="text-right"><a href="' + url + '" class="btn btn-primary btn-xs" title="View order"><i class="fa fa-eye"></i> View</a></td>';
                        htm += '</tr>';
                    });

                    $('#tblOrders > tbody').html(htm);
                    $('#txttotalordercount, #statTotalOrders').text(obj.count);
                    $('#statPageTotal').text(soMoney(pageTotal));
                    $('#statPageOpen').text(pageOpen);
                    $('#statPageDelivered').text(pageDelivered);
                    $('#divPagination').html(paginate(obj.count, perpage, page, "searchOrders"));
                },
                error: function () {
                    Unloading();
                    soEmpty('Could not load sales orders. Please check your connection and try again.');
                }
            });
        }

        function resetFilters() {
            $("#txtSearch, #txtCustSearch, #txtSearchFromDate, #txtSearchToDate").val("");
            $("#slBranch, #slOrderStatus").val("-1");
            $("#slPerpage").val("50");
            sortBy = "date"; sortDir = "desc";
            searchOrders(1);
        }

        // whole row is clickable, links/buttons keep their own behaviour
        $(document).on('click', '#tblOrders tr.so-row', function (e) {
            if ($(e.target).closest('a').length) return;
            location.href = $(this).data('href');
        });

        $(document).on('keydown', '#txtSearch, #txtCustSearch, #txtSearchFromDate, #txtSearchToDate', function (e) {
            if (e.which === 13) {
                e.preventDefault();
                searchOrders(1);
            }
        });
    </script>
</head>

<body class="nav-md">
    <form id="form1" runat="server" autocomplete="off">
        <div class="container body">
            <div class="main_container">
                <div id="loading" style="background-repeat: no-repeat; margin: auto; height: 100%; display: none">
                    <div align="center" style="margin: auto">
                        <img id="loading-image" src="../images/loader.gif" alt="Loading..." />
                    </div>
                </div>
                <div class="col-md-3 left_col">
                    <div class="left_col scroll-view">
                        <div class="navbar nav_title" style="border: 0;">
                            <a href="#" class="site_title"><span>Invoice</span></a>
                        </div>
                        <div class="clearfix"></div>
                        <div class="profile clearfix"></div>
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

                <div class="top_nav">
                    <div class="nav_menu">
                        <nav>
                            <div class="navbar-header" style="width: 100%; display: flex; align-items: center">
                                <div class="nav toggle" style="padding: 5px;">
                                    <a id="menu_toggle"><i class="fa fa-bars"></i></a>
                                </div>
                                <label style="font-weight: bold; font-size: 16px; margin: 0 auto 0 0;">Sales Orders</label>
                                <a href="new_sales_order.aspx" class="btn btn-primary btn-xs" style="margin-right: 10px;"><i class="fa fa-plus-square"></i>&nbsp; New Sales Order</a>
                            </div>
                        </nav>
                    </div>
                </div>

                <div class="right_col so-page" role="main">
                    <div class="">

                        <div class="so-stats">
                            <div class="so-stat">
                                <div class="so-stat-label">Total orders</div>
                                <div class="so-stat-value" id="statTotalOrders">0</div>
                            </div>
                            <div class="so-stat">
                                <div class="so-stat-label">Order value (this page)</div>
                                <div class="so-stat-value">&#8377; <span id="statPageTotal">0.00</span></div>
                            </div>
                            <div class="so-stat so-stat-warn">
                                <div class="so-stat-label">Open orders (this page)</div>
                                <div class="so-stat-value" id="statPageOpen">0</div>
                            </div>
                            <div class="so-stat so-stat-ok">
                                <div class="so-stat-label">Delivered (this page)</div>
                                <div class="so-stat-value" id="statPageDelivered">0</div>
                            </div>
                        </div>

                        <div class="clearfix"></div>
                        <div class="row">
                            <div class="col-md-12 col-sm-12 col-xs-12">
                                <div class="x_panel so-filter">
                                    <div class="x_title" style="margin-bottom: 0px;">
                                        <strong><i class="fa fa-filter"></i>&nbsp; Filters</strong>
                                        <ul class="nav navbar-right panel_toolbox">
                                            <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a></li>
                                        </ul>
                                        <div class="clearfix"></div>
                                    </div>
                                    <div class="x_content">
                                        <div class="form-horizontal form-label-left input_mask">
                                            <div class="col-md-2 col-sm-6 col-xs-12 form-group">
                                                <label for="txtSearchFromDate">From date</label>
                                                <input type="text" class="form-control" id="txtSearchFromDate" placeholder="dd-mm-yyyy" />
                                            </div>
                                            <div class="col-md-2 col-sm-6 col-xs-12 form-group">
                                                <label for="txtSearchToDate">To date</label>
                                                <input type="text" class="form-control" id="txtSearchToDate" placeholder="dd-mm-yyyy" />
                                            </div>
                                            <div class="col-md-2 col-sm-6 col-xs-12 form-group">
                                                <label for="slBranch">Warehouse</label>
                                                <select class="form-control" id="slBranch" onchange="searchOrders(1);"></select>
                                            </div>
                                            <div class="col-md-2 col-sm-6 col-xs-12 form-group">
                                                <label for="slOrderStatus">Status</label>
                                                <select class="form-control" id="slOrderStatus" onchange="searchOrders(1);">
                                                    <option value="-1" selected="selected">All status</option>
                                                    <option value="0">Draft</option>
                                                    <option value="1">To be confirmed</option>
                                                    <option value="13">On Hold</option>
                                                    <option value="2">Approved</option>
                                                    <option value="3">Processed</option>
                                                    <option value="9">Partially Delivered</option>
                                                    <option value="10">Fully Delivered</option>
                                                    <option value="cancelled">Cancelled (All)</option>
                                                    <option value="12">Cancelled by Customer</option>
                                                    <option value="11">Cancelled by Company</option>
                                                </select>
                                            </div>
                                            <div class="col-md-2 col-sm-6 col-xs-12 form-group">
                                                <label for="txtSearch">Search</label>
                                                <input type="text" class="form-control" id="txtSearch" placeholder="Order / invoice / status" />
                                            </div>
                                            <div class="col-md-2 col-sm-6 col-xs-12 form-group">
                                                <label for="txtCustSearch">Customer</label>
                                                <input type="text" class="form-control" id="txtCustSearch" placeholder="Customer ID / name" />
                                            </div>
                                            <div class="col-md-12 col-sm-12 col-xs-12 so-filter-actions">
                                                <div class="btn btn-success pull-right" onclick="searchOrders(1);">
                                                    <i class="fa fa-search"></i>&nbsp; Search
                                                </div>
                                                <div class="btn btn-default pull-right" onclick="resetFilters();">
                                                    <i class="fa fa-refresh"></i>&nbsp; Reset
                                                </div>
                                            </div>
                                            <div class="clearfix"></div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="clearfix"></div>

                        <div class="row">
                            <div class="col-md-12 col-sm-12 col-xs-12">
                                <div class="x_panel">
                                    <div class="so-list-head">
                                        <div class="so-count">Sales Orders<span class="badge" id="txttotalordercount">0</span></div>
                                        <div class="so-perpage">
                                            Rows per page
                                            <select id="slPerpage" onchange="searchOrders(1);" class="input-sm">
                                                <option value="50">50</option>
                                                <option value="100">100</option>
                                                <option value="250">250</option>
                                                <option value="500">500</option>
                                            </select>
                                        </div>
                                    </div>
                                    <div class="table-responsive">
                                        <table id="tblOrders" class="table">
                                            <thead>
                                                <tr>
                                                    <th class="sortable" data-col="number" onclick="sortOrders('number')">Order<i class="fa fa-sort"></i></th>
                                                    <th class="sortable" data-col="customer" onclick="sortOrders('customer')">Customer<i class="fa fa-sort"></i></th>
                                                    <th class="sortable so-hide-sm" data-col="date" onclick="sortOrders('date')">Date<i class="fa fa-sort"></i></th>
                                                    <th class="sortable so-hide-sm" data-col="warehouse" onclick="sortOrders('warehouse')">Warehouse<i class="fa fa-sort"></i></th>
                                                    <th class="sortable" data-col="status" onclick="sortOrders('status')">Status<i class="fa fa-sort"></i></th>
                                                    <th class="sortable so-num" data-col="total" onclick="sortOrders('total')">Net Amount<i class="fa fa-sort"></i></th>
                                                    <th></th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr>
                                                    <td colspan="7" class="so-empty"><i class="fa fa-spinner fa-spin"></i>Loading sales orders...</td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                    <div id="divPagination"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <footer>
                    <div class="pull-right">
                        <div class="footerDiv">
                            <div class="footerDivContent">Copyright 2014 &copy;</div>
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
