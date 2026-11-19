<%@ Page Language="C#" AutoEventWireup="true" CodeFile="listPurchaseEntries.aspx.cs" Inherits="web_purchase_listPurchaseEntries" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Purchase Entries  | Invoice Me</title>
    <script src="../js/common.js" type="text/javascript"></script>
    <script type="text/javascript" src="../js/jquery-2.0.3.js"></script>

    <script type="text/javascript" src="../js/jquery.cookie.js"></script>
    <script src="../js/pagination.js" type="text/javascript"></script>

    <!-- Bootstrap -->
    <link href="../css/bootstrap/bootstrap.min.css" rel="stylesheet" />
    <!-- Font Awesome -->
    <link href="../css/font-awesome/css/font-awesome.min.css" rel="stylesheet" />
    <!-- NProgress -->
    <link href="../css/bootstrap/nprogress.css" rel="stylesheet" />
    <!-- bootstrap-daterangepicker -->
    <link href="../css/bootstrap/daterangepicker.css" rel="stylesheet" />

    <!-- Custom Theme Style -->
    <link href="../css/bootstrap/custom.min.css" rel="stylesheet" />
    <!--My Styles-->
    <link href="../css/bootstrap/mystyle.css" type="text/css" rel="stylesheet" />
    <!--date picker-->
    <link rel="stylesheet" href="../mobiscroll/css/jquery.mobile-1.1.0.min.css" />
    <script src="../mobiscroll/js/mobiscroll-2.0rc3.full.min.js" type="text/javascript"></script>
    <link href="../mobiscroll/css/mobiscroll-2.0rc3.full.min.css" rel="stylesheet" type="text/css" />
    <!--date picker-->

    <link href="../css/bootstrap/mystyle.css" rel="stylesheet" />

    <style type="text/css">
        .pe-page { --pe-ink: #1f2d3d; --pe-muted: #7b8794; --pe-line: #e6e9ee; --pe-brand: #2a3f54; }

        .pe-stats { display: flex; flex-wrap: wrap; margin: 12px -6px 0; padding-top: 10px; }
        .pe-stat { flex: 1 1 200px; margin: 0 6px 10px; padding: 8px 14px; background: #fff; border: 1px solid var(--pe-line); border-left: 4px solid var(--pe-brand); border-radius: 4px; }
        .pe-stat .pe-stat-label { color: var(--pe-muted); font-size: 11px; text-transform: uppercase; letter-spacing: .5px; }
        .pe-stat .pe-stat-value { font-size: 20px; font-weight: 600; color: var(--pe-ink); line-height: 1.3; }
        .pe-stat.pe-stat-warn { border-left-color: #d9534f; }
        .pe-stat.pe-stat-warn .pe-stat-value { color: #d9534f; }
        .pe-stat.pe-stat-ok { border-left-color: #26b99a; }
        .pe-stat small { color: var(--pe-muted); }

        .pe-filter label { font-size: 12px; font-weight: 600; color: var(--pe-muted); text-transform: uppercase; letter-spacing: .4px; margin-bottom: 4px; }
        .pe-filter .form-control { height: 36px; background: #fff; }
        .pe-filter .pe-filter-actions { padding-top: 22px; }
        .pe-filter .pe-filter-actions .btn { margin: 0 0 0 6px; }

        .pe-list-head { display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 10px; padding: 4px 0 10px; }
        .pe-list-head .pe-count { font-weight: 600; color: var(--pe-ink); }
        .pe-list-head .pe-count .badge { background: var(--pe-brand); margin-left: 6px; }
        .pe-list-head .pe-perpage { color: var(--pe-muted); font-size: 13px; }
        .pe-list-head .pe-perpage select { margin-left: 6px; }

        #tblEntries { margin-bottom: 0; }
        #tblEntries thead th { background: #f6f8fa; color: #52606d; font-size: 12px; text-transform: uppercase; letter-spacing: .4px; border-bottom: 2px solid var(--pe-line); white-space: nowrap; vertical-align: middle; }
        #tblEntries tbody td { vertical-align: middle; border-top: 1px solid var(--pe-line); padding: 12px 8px; }
        #tblEntries tbody tr.pe-row { cursor: pointer; transition: background-color .15s; }
        #tblEntries tbody tr.pe-row:hover { background-color: #f1f6fb; }
        #tblEntries tbody tr.pe-row.pe-cancelled td { opacity: .6; }
        #tblEntries tbody tr.pe-row.pe-cancelled .pe-amount { text-decoration: line-through; }
        .pe-num { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap; }
        .pe-invoice { font-weight: 600; color: #1a73b8; }
        .pe-invoice small { display: block; font-weight: 400; color: var(--pe-muted); }
        .pe-vendor { color: var(--pe-ink); }
        .pe-meta { color: var(--pe-muted); font-size: 13px; }
        .pe-meta .fa { margin-right: 5px; }
        .pe-due { color: #d9534f; font-weight: 600; }
        .pe-settled { color: #26b99a; }
        .pe-status { font-size: 11px; padding: 4px 8px; border-radius: 10px; font-weight: 600; }
        .pe-hl { background: #fff3a8; color: inherit; padding: 0; }
        .pe-empty { text-align: center; padding: 40px 10px !important; color: var(--pe-muted); }
        .pe-empty .fa { font-size: 36px; display: block; margin-bottom: 10px; color: #c5ccd3; }
        .pe-skeleton td { padding: 16px 8px !important; }
        .pe-skeleton .pe-bar { height: 12px; border-radius: 6px; background: linear-gradient(90deg, #eef1f4 25%, #f8f9fb 50%, #eef1f4 75%); background-size: 200% 100%; animation: pe-shimmer 1.2s infinite; }
        @keyframes pe-shimmer { from { background-position: 200% 0; } to { background-position: -200% 0; } }
        #divPagination { text-align: center; padding-top: 10px; }

        @media (max-width: 767px) {
            .pe-hide-sm { display: none !important; }
            #tblEntries thead { display: none; }
            #tblEntries, #tblEntries tbody, #tblEntries tbody tr.pe-row, #tblEntries tbody td { display: block; width: 100%; }
            #tblEntries tbody tr.pe-row { border: 1px solid var(--pe-line); border-radius: 4px; margin-bottom: 10px; padding: 6px 4px; background: #fff; }
            #tblEntries tbody td { border-top: 0; padding: 4px 10px; }
            #tblEntries tbody td.pe-num { text-align: left; }
            #tblEntries tbody td[data-label]:before { content: attr(data-label) ": "; color: var(--pe-muted); font-size: 12px; }
        }
    </style>

    <script type="text/javascript">
        // helpers for safe, readable rendering of values
        function peEscape(value) {
            return $('<div/>').text(value == null ? '' : String(value)).html();
        }

        function peHighlight(search, value) {
            var text = peEscape(value);
            if (!search) return text;
            var safe = peEscape(search).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
            return text.replace(new RegExp('(' + safe + ')', 'gi'), '<mark class="pe-hl">$1</mark>');
        }

        function peMoney(value) {
            var n = parseFloat(value);
            if (isNaN(n)) n = 0;
            return n.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
        }

        function peSkeleton() {
            var htm = '';
            for (var i = 0; i < 5; i++) {
                htm += '<tr class="pe-skeleton"><td colspan="8"><div class="pe-bar"></div></td></tr>';
            }
            $('#tblEntries > tbody').html(htm);
        }

        function peEmpty(message) {
            $('#tblEntries > tbody').html('<tr><td colspan="8" class="pe-empty"><i class="fa fa-inbox"></i>' + message + '</td></tr>');
            $('#txttotalordercount, #statTotalEntries').text(0);
            $('#divPagination').html('');
            $('#statPageTotal, #statPageDue').text(peMoney(0));
            $('#statPageSettled').text(0);
        }

        $(document).ready(function () {
            BranchId = $.cookie("invntrystaffBranchId");
            if (!BranchId) {
                location.href = "../dashboard.aspx";
                return false;
            }

            var yyyy = new Date().getFullYear();
            var curr_date = new Date().getDate();
            $('#txtSearchFromDate').scroller({
                preset: 'date',
                endYear: yyyy + 100,
                setText: 'Next',
                invalid: {},
                theme: 'ios',
                display: 'modal',
                mode: 'scroller',
                dateFormat: 'dd-mm-yy'
                // dateFormat: 'dd-MM-yy'
            });
            $('#txtSearchToDate').scroller({
                preset: 'date',
                endYear: yyyy + 100,
                setText: 'Next',
                invalid: {},
                theme: 'ios',
                display: 'modal',
                mode: 'scroller',
                dateFormat: 'dd-mm-yy'
                //dateFormat: 'dd-MM-yy'
            });

            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " ©");
            resetFilters();
            //// resetFilters();

        });


        function searchEntries(page) {
            var filters = {};
            var perpage = $("#slPerpage").val();

            if ($("#txtSearch").val() != "" && $("#txtSearch").val() != undefined) {
                filters.search = $("#txtSearch").val();
            }

            if ($("#txtSearchFromDate").val() != "" && $("#txtSearchFromDate").val() != undefined) {
                filters.from_date = $("#txtSearchFromDate").val();
            }
            if ($("#txtSearchToDate").val() != "" && $("#txtSearchToDate").val() != undefined) {
                filters.to_date = $("#txtSearchToDate").val();
            }
            if ($("#selWarehouse").val() && $("#selWarehouse").val() != "-1" && $("#selWarehouse").val() != "") {
                filters.branch = $("#selWarehouse").val();
            }

            loading();
            peSkeleton();

            $.ajax({
                type: "POST",
                url: "listPurchaseEntries.aspx/searchEntries",
                data: "{'page':" + page + ",'filters':" + JSON.stringify(filters) + ",'perpage':'" + perpage + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    var obj;
                    try {
                        obj = JSON.parse(msg.d);
                    } catch (ex) {
                        // server returns "N" (or an error text) when nothing can be listed
                        peEmpty('No purchase entries found');
                        return;
                    }
                    if (!obj.data || obj.count == 0) {
                        peEmpty('No purchase entries found<br /><small>Try changing the filters or create a new entry.</small>');
                        return;
                    }

                    var htm = "";
                    var pageTotal = 0, pageDue = 0, pageSettled = 0;
                    $.each(obj.data, function (i, row) {
                        var active = row.pm_status == 1;
                        var balance = parseFloat(row.pm_total_balance) || 0;
                        var net = parseFloat(row.net_amount) || 0;
                        var url = 'managepurchase.aspx?purchaseId=' + encodeURIComponent(row.pm_id);

                        if (active) {
                            pageTotal += net;
                            if (balance > 0) pageDue += balance; else pageSettled++;
                        }

                        htm += '<tr class="pe-row' + (active ? '' : ' pe-cancelled') + '" data-href="' + url + '">';
                        htm += '<td data-label="Invoice"><a class="pe-invoice" href="' + url + '">' + peHighlight(filters.search, row.pm_invoice_no) + '<small>Entry #' + peEscape(row.pm_id) + '</small></a></td>';
                        htm += '<td data-label="Vendor" class="pe-vendor">' + peHighlight(filters.search, row.vendor_name) + '</td>';
                        htm += '<td data-label="Date" class="pe-meta pe-hide-sm"><i class="fa fa-calendar"></i>' + peEscape(row.purchaseDate) + '</td>';
                        htm += '<td data-label="Entered by" class="pe-meta pe-hide-sm"><i class="fa fa-user"></i>' + peEscape(row.user_name) + '</td>';
                        htm += '<td data-label="Net Amount" class="pe-num pe-amount">&#8377; ' + peMoney(net) + '</td>';
                        if (!active) {
                            htm += '<td data-label="Balance" class="pe-num pe-meta">&mdash;</td>';
                        } else if (balance > 0) {
                            htm += '<td data-label="Balance" class="pe-num pe-due">&#8377; ' + peMoney(balance) + '</td>';
                        } else {
                            htm += '<td data-label="Balance" class="pe-num pe-settled"><i class="fa fa-check"></i> Paid</td>';
                        }
                        htm += '<td data-label="Status">';
                        if (!active) {
                            htm += '<span class="label label-default pe-status">Cancelled</span>';
                        } else if (balance > 0) {
                            htm += '<span class="label label-danger pe-status">Outstanding</span>';
                        } else {
                            htm += '<span class="label label-success pe-status">Complete</span>';
                        }
                        htm += '</td>';
                        htm += '<td class="text-right"><a href="' + url + '" class="btn btn-primary btn-xs" title="View entry"><i class="fa fa-eye"></i> View</a></td>';
                        htm += '</tr>';
                    });

                    $('#tblEntries > tbody').html(htm);
                    $('#txttotalordercount, #statTotalEntries').text(obj.count);
                    $('#statPageTotal').text(peMoney(pageTotal));
                    $('#statPageDue').text(peMoney(pageDue));
                    $('#statPageSettled').text(pageSettled);
                    $('#divPagination').html(paginate(obj.count, perpage, page, "searchEntries"));
                },
                error: function (xhr, status) {
                    Unloading();
                    peEmpty('Could not load purchase entries. Please check your connection and try again.');
                }
            });
        }

        function resetFilters() {
            $("#txtSearch").val("");
            $("#txtSearchToDate").val("");
            $("#txtSearchFromDate").val("");
            searchEntries(1);
        }

        // whole row is clickable, links/buttons keep their own behaviour
        $(document).on('click', '#tblEntries tr.pe-row', function (e) {
            if ($(e.target).closest('a').length) return;
            location.href = $(this).data('href');
        });

        $(document).on('keydown', '#txtSearch, #txtSearchFromDate, #txtSearchToDate', function (e) {
            if (e.which === 13) {
                e.preventDefault();
                searchEntries(1);
            }
        });
    </script>

</head>

<body class="nav-md">
    <form id="form1" runat="server">

        <div class="container body">
            <div class="main_container">
                <!-- Start div For loading image-->
                <div id="loading" style="background-repeat: no-repeat; margin: auto; height: 100%; display: none">
                    <div align="center" style="margin: auto">
                        <img id="loading-image" src="../images/loader.gif" alt="Loading..." />
                    </div>
                </div>
                <!-- End  div For loading image-->
                <div class="col-md-3 left_col">
                    <div class="left_col scroll-view">
                        <div class="navbar nav_title" style="border: 0;">
                            <a href="#" class="site_title">
                                <!--<i class="fa fa-paw"></i>-->
                                <span>Invoice</span></a>
                        </div>

                        <div class="clearfix"></div>

                        <!-- menu profile quick info -->
                        <div class="profile clearfix">
                        </div>
                        <!-- /menu profile quick info -->

                        <br />

                        <!-- sidebar menu -->
                        <div id="sidebar-menu" class="main_menu_side hidden-print main_menu">
                        </div>

                        <!-- /sidebar menu -->

                        <!-- /menu footer buttons -->
                        <div class="sidebar-footer hidden-small">
                            <a data-toggle="tooltip" data-placement="top" title="Settings">
                                <span class="glyphicon glyphicon-cog" aria-hidden="true"></span>
                            </a>
                            <a data-toggle="tooltip" data-placement="top" title="FullScreen">
                                <span class="glyphicon glyphicon-fullscreen" aria-hidden="true"></span>
                            </a>
                            <a data-toggle="tooltip" data-placement="top" title="Lock">
                                <span class="glyphicon glyphicon-eye-close" aria-hidden="true"></span>
                            </a>
                            <a data-toggle="tooltip" data-placement="top" title="Logout" href="../login.html">
                                <span class="glyphicon glyphicon-off" aria-hidden="true"></span>
                            </a>
                        </div>
                        <!-- /menu footer buttons -->
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
                                <label style="font-weight: bold; font-size: 16px; margin: 0 auto 0 0;">Purchase Entries</label>
                                <a href="purchaseentry.aspx" target="_blank" class="btn btn-primary btn-xs" style="margin-right: 10px;"><i class="fa fa-plus-square"></i>&nbsp; New Entry</a>
                            </div>

                        </nav>
                    </div>
                </div>
                <!-- /top navigation -->

                <!-- page content -->
                <div class="right_col pe-page" role="main">
                    <div class="">

                        <div class="pe-stats">
                            <div class="pe-stat">
                                <div class="pe-stat-label">Total entries</div>
                                <div class="pe-stat-value" id="statTotalEntries">0</div>
                            </div>
                            <div class="pe-stat">
                                <div class="pe-stat-label">Purchase value (this page)</div>
                                <div class="pe-stat-value">&#8377; <span id="statPageTotal">0.00</span></div>
                            </div>
                            <div class="pe-stat pe-stat-warn">
                                <div class="pe-stat-label">Outstanding (this page)</div>
                                <div class="pe-stat-value">&#8377; <span id="statPageDue">0.00</span></div>
                            </div>
                            <div class="pe-stat pe-stat-ok">
                                <div class="pe-stat-label">Fully paid (this page)</div>
                                <div class="pe-stat-value" id="statPageSettled">0</div>
                            </div>
                        </div>

                        <div class="clearfix"></div>
                        <div class="row">
                            <div class="col-md-12 col-sm-12 col-xs-12">
                                <div class="x_panel pe-filter">
                                    <div class="x_title" style="margin-bottom: 0px;">
                                        <strong><i class="fa fa-filter"></i>&nbsp; Filters</strong>
                                        <ul class="nav navbar-right panel_toolbox">
                                            <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                            </li>
                                        </ul>
                                        <div class="clearfix"></div>
                                    </div>
                                    <div class="x_content">

                                        <form class="form-horizontal form-label-left input_mask" onsubmit="return false;">

                                            <div class="col-md-2 col-sm-6 col-xs-12 form-group">
                                                <label for="txtSearchFromDate">From date</label>
                                                <input type="text" class="form-control" id="txtSearchFromDate" placeholder="dd-mm-yyyy" />
                                            </div>

                                            <div class="col-md-2 col-sm-6 col-xs-12 form-group">
                                                <label for="txtSearchToDate">To date</label>
                                                <input type="text" class="form-control" id="txtSearchToDate" placeholder="dd-mm-yyyy" />
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group">
                                                <label for="selWarehouse">Warehouse</label>
                                                <select class="form-control" id="selWarehouse" onchange="javascript:searchEntries(1);" runat="server">
                                                </select>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group">
                                                <label for="txtSearch">Search</label>
                                                <input type="text" class="form-control" id="txtSearch" placeholder="Entry id / invoice no. / vendor" />
                                            </div>

                                            <div class="col-md-2 col-sm-12 col-xs-12 pe-filter-actions">
                                                <div class="btn btn-success pull-right" onclick="javascript:searchEntries(1);">
                                                    <i class="fa fa-search"></i>&nbsp; Search
                                                </div>
                                                <div class="btn btn-default pull-right" onclick="javascript:resetFilters();">
                                                    <i class="fa fa-refresh"></i>&nbsp; Reset
                                                </div>
                                            </div>
                                            <div class="clearfix"></div>

                                        </form>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="clearfix"></div>

                        <div class="row">
                            <div class="col-md-12 col-sm-12 col-xs-12">
                                <div class="x_panel">
                                    <div class="pe-list-head">
                                        <div class="pe-count">Purchases<span class="badge" id="txttotalordercount">0</span></div>
                                        <div class="pe-perpage">
                                            Rows per page
                                            <select id="slPerpage" onchange="javascript:searchEntries(1);" class="input-sm">
                                                <option value="50">50</option>
                                                <option value="100">100</option>
                                                <option value="250">250</option>
                                                <option value="500">500</option>
                                            </select>
                                        </div>
                                    </div>
                                    <div class="table-responsive">
                                        <table id="tblEntries" class="table">
                                            <thead>
                                                <tr>
                                                    <th>Invoice</th>
                                                    <th>Vendor</th>
                                                    <th class="pe-hide-sm">Date</th>
                                                    <th class="pe-hide-sm">Entered by</th>
                                                    <th class="pe-num">Net Amount</th>
                                                    <th class="pe-num">Balance</th>
                                                    <th>Status</th>
                                                    <th></th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr>
                                                    <td colspan="8" class="pe-empty"><i class="fa fa-spinner fa-spin"></i>Loading purchase entries...</td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                    <div id="divPagination"></div>
                                </div>

                            </div>
                        </div>
                        <!-- /page content -->


                    </div>


                </div>
                <!-- footer content -->
                <footer>
                    <div class="pull-right">
                        <div class="footerDiv">
                            <div class="footerDivContent">
                                Copyright 2014 ©
                            </div>
                        </div>
                    </div>
                    <div class="clearfix"></div>
                </footer>
                <!-- /footer content -->
            </div>
        </div>
    </form>

    <!-- jQuery -->
    <%--<script src="../js/bootstrap/jquery.min.js"></script>--%>
    <!-- jQuery -->
    <!-- Bootstrap -->


    <script src="../js/bootstrap/bootstrap.min.js"></script>
    <!-- FastClick -->
    <script src="../js/bootstrap/fastclick.js"></script>
    <!-- NProgress -->
    <script src="../js/bootstrap/nprogress.js"></script>
    <!-- iCheck -->
    <script src="../js/bootstrap/icheck.min.js"></script>

    <!-- Custom Theme Scripts -->
    <script src="../js/bootstrap/custom.min.js"></script>
    <script src="../js/bootbox.min.js"></script>

</body>
</html>
