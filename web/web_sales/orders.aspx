<%@ Page Language="C#" AutoEventWireup="true" CodeFile="orders.aspx.cs" Inherits="web_sales_orders" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Orders &amp; Invoices | Invoice Me</title>
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

    <style type="text/css">
        .od-page { --od-ink: #1f2d3d; --od-muted: #7b8794; --od-line: #e6e9ee; --od-brand: #2a3f54; }

        .od-filter label { font-size: 12px; font-weight: 600; color: var(--od-muted); text-transform: uppercase; letter-spacing: .4px; margin-bottom: 4px; }
        .od-filter .form-control { height: 36px; background: #fff; }
        .od-filter .od-filter-actions { padding-top: 4px; }
        .od-filter .od-filter-actions .btn { margin: 0 0 0 6px; }

        .od-list-head { display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 10px; padding: 4px 0 10px; }
        .od-list-head .od-count { font-weight: 600; color: var(--od-ink); }
        .od-list-head .od-count .badge { background: var(--od-brand); margin-left: 6px; }
        .od-list-head .od-perpage { color: var(--od-muted); font-size: 13px; }
        .od-list-head .od-perpage select { margin-left: 6px; }

        #tblOrders { margin-bottom: 0; }
        #tblOrders thead th { background: #f6f8fa; color: #52606d; font-size: 12px; text-transform: uppercase; letter-spacing: .4px; border-bottom: 2px solid var(--od-line); white-space: nowrap; vertical-align: middle; }
        #tblOrders tbody td { vertical-align: middle; border-top: 1px solid var(--od-line); padding: 12px 8px; }
        #tblOrders tbody tr.od-row { cursor: pointer; transition: background-color .15s; }
        #tblOrders tbody tr.od-row:hover { background-color: #f1f6fb; }
        #tblOrders tbody tr.od-row.od-cancelled td { opacity: .6; }
        #tblOrders tbody tr.od-row.od-cancelled .od-amount { text-decoration: line-through; }
        .od-num { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap; }
        .od-invoice { font-weight: 600; color: #1a73b8; }
        .od-invoice small { display: block; font-weight: 400; color: var(--od-muted); }
        .od-unbilled { color: #d9534f; }
        .od-customer { color: var(--od-ink); font-weight: 600; }
        .od-tag { font-size: 11px; padding: 2px 6px; border-radius: 3px; background: #eef1f4; color: #52606d; margin-left: 6px; font-weight: 600; }
        .od-meta { color: var(--od-muted); font-size: 13px; }
        .od-meta .fa { margin-right: 5px; }
        .od-meta small { display: block; }
        .od-due { color: #d9534f; font-weight: 600; }
        .od-settled { color: #26b99a; }
        .od-status { font-size: 11px; padding: 4px 8px; border-radius: 10px; font-weight: 600; margin: 0 2px 2px 0; display: inline-block; }
        .od-hl { background: #fff3a8; color: inherit; padding: 0; }
        .od-empty { text-align: center; padding: 40px 10px !important; color: var(--od-muted); }
        .od-empty .fa { font-size: 36px; display: block; margin-bottom: 10px; color: #c5ccd3; }
        .od-skeleton td { padding: 16px 8px !important; }
        .od-skeleton .od-bar { height: 12px; border-radius: 6px; background: linear-gradient(90deg, #eef1f4 25%, #f8f9fb 50%, #eef1f4 75%); background-size: 200% 100%; animation: od-shimmer 1.2s infinite; }
        @keyframes od-shimmer { from { background-position: 200% 0; } to { background-position: -200% 0; } }
        #divPagination { text-align: center; padding-top: 10px; }

        @media (max-width: 767px) {
            .od-hide-sm { display: none !important; }
            #tblOrders thead { display: none; }
            #tblOrders, #tblOrders tbody, #tblOrders tbody tr.od-row, #tblOrders tbody td { display: block; width: 100%; }
            #tblOrders tbody tr.od-row { border: 1px solid var(--od-line); border-radius: 4px; margin-bottom: 10px; padding: 6px 4px; background: #fff; }
            #tblOrders tbody td { border-top: 0; padding: 4px 10px; }
            #tblOrders tbody td.od-num { text-align: left; }
            #tblOrders tbody td[data-label]:before { content: attr(data-label) ": "; color: var(--od-muted); font-size: 12px; }
        }
    </style>

    <script type="text/javascript">
        var BranchId;

        //0=New, 1=Processed, 2=Delivered, 3=To be confirmed, 4=Canceled, 5=Rejected, 6=Pending
        var statusMap = {
            0: ["New", "label-warning"],
            1: ["Processed", "label-primary"],
            2: ["Delivered", "label-success"],
            3: ["To be confirmed", "label-info"],
            4: ["Canceled", "label-default"],
            5: ["Rejected", "label-default"],
            6: ["Pending", "label-default"]
        };
        var printPages = { 0: "billreceipt.aspx", 1: "normalBillreceipt.aspx", 2: "gstBillreceipt.aspx" };

        // helpers for safe, readable rendering of values
        function odEscape(value) {
            return $('<div/>').text(value == null ? '' : String(value)).html();
        }

        function odHighlight(search, value) {
            var text = odEscape(value);
            if (!search) return text;
            var safe = odEscape(search).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
            return text.replace(new RegExp('(' + safe + ')', 'gi'), '<mark class="od-hl">$1</mark>');
        }

        function odMoney(value) {
            var n = parseFloat(value);
            if (isNaN(n)) n = 0;
            return n.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
        }

        function odSkeleton() {
            var htm = '';
            for (var i = 0; i < 5; i++) {
                htm += '<tr class="od-skeleton"><td colspan="8"><div class="od-bar"></div></td></tr>';
            }
            $('#tblOrders > tbody').html(htm);
        }

        function odEmpty(message) {
            $('#tblOrders > tbody').html('<tr><td colspan="8" class="od-empty"><i class="fa fa-inbox"></i>' + message + '</td></tr>');
            $('#txttotalordercount').text(0);
            $('#divPagination').html('');
        }

        $(document).ready(function () {
            BranchId = $.cookie("invntrystaffBranchId");
            if (!BranchId) {
                location.href = "../dashboard.aspx";
                return false;
            }

            var yyyy = new Date().getFullYear();
            $('#txtSearchFromDate, #txtSearchToDate').scroller({
                preset: 'date',
                endYear: yyyy + 100,
                setText: 'Next',
                invalid: {},
                theme: 'ios',
                display: 'modal',
                mode: 'scroller',
                dateFormat: 'dd-mm-yy'
            });
            getBranches();
            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " &copy;");
        });

        function getBranches() {
            loading();
            $.ajax({
                type: "POST",
                url: "orders.aspx/getBranches",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    var obj = JSON.parse(msg.d);
                    var htm = '<option value="-1" selected="selected">All warehouses</option>';
                    $.each(obj, function (i, row) {
                        htm += '<option value="' + odEscape(row.branch_id) + '">' + odEscape(row.branch_name) + '</option>';
                    });
                    $("#slBranch").html(htm);
                    showsalespersons();
                },
                error: function () {
                    Unloading();
                    odEmpty('Could not load warehouses. Please check your connection and try again.');
                }
            });
        }

        // Show sales person
        function showsalespersons() {
            loading();
            $.ajax({
                type: "POST",
                url: "Orders.aspx/showsalespersons",
                data: "{}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d == "") {
                        odEmpty('Could not load sales persons.');
                        return;
                    }
                    $("#comboSalesPerson").html(msg.d);
                    if (getQueryString("sellerId") != undefined && getQueryString("sellerId") != "") {
                        $("#comboSalesPerson").val(getQueryString("sellerId"));
                    }
                    if (getQueryString("event") == "back" && restoreSavedSearch()) {
                        searchOrders(1);
                    } else {
                        takeQuerystring();
                    }
                },
                error: function () {
                    Unloading();
                    odEmpty('Could not load sales persons. Please check your connection and try again.');
                }
            });
        }

        // restores the filters saved by the last search (used when coming back from an order)
        function restoreSavedSearch() {
            var saved;
            try {
                saved = JSON.parse($.cookie("search-data"));
            } catch (ex) {
                return false;
            }
            if (!saved) return false;
            $("#slBranch").val(saved.branch == undefined ? -1 : saved.branch);
            $("#selType").val(saved.type == undefined ? -1 : saved.type);
            $("#comboSalesPerson").val(saved.seller_id == undefined ? 0 : saved.seller_id);
            $("#slOrderStatus").val(saved.order_status == undefined ? -1 : saved.order_status);
            $("#slPaymentStatus").val(saved.payment_status == undefined ? -1 : saved.payment_status);
            $("#txtSearch").val(saved.search == undefined ? "" : saved.search);
            $("#txtCustSearch").val(saved.custSearch == undefined ? "" : saved.custSearch);
            $("#txtSearchToDate").val(saved.to_date == undefined ? "" : saved.to_date);
            $("#txtSearchFromDate").val(saved.from_date == undefined ? "" : saved.from_date);
            return true;
        }

        function takeQuerystring() {
            var orderStatus = getQueryString("orderStatus");
            var paymentStatus = getQueryString("paymentStatus");
            var fromDate = getQueryString("fromdate");
            var toDate = getQueryString("todate");
            var customerId = getQueryString("customerid");
            if (customerId == undefined) customerId = "";
            if (orderStatus == undefined) orderStatus = -1;
            if (paymentStatus == undefined) paymentStatus = -1;
            if (fromDate == undefined) fromDate = "";
            if (toDate == undefined) toDate = "";

            $("#txtCustSearch").val(customerId);
            $("#slBranch").val(-1);
            $("#slPaymentStatus").val(paymentStatus);
            $("#slOrderStatus").val(orderStatus);
            $("#txtSearchFromDate").val(fromDate);
            $("#txtSearchToDate").val(toDate);
            searchOrders(1);
        }

        function searchOrders(page) {
            var filters = {};
            var perpage = $("#slPerpage").val();
            var branchId = $.cookie("invntrystaffBranchId");
            var CountryId = $.cookie("invntrystaffCountryId");

            if ((!branchId || branchId == "undefined" || branchId == "null") || (!CountryId || CountryId == "undefined" || CountryId == "null")) {
                location.href = "../dashboard.aspx";
                return false;
            }
            if ($("#txtSearch").val() != "" && $("#txtSearch").val() != undefined) {
                filters.search = $("#txtSearch").val();
            }
            if ($("#txtCustSearch").val() != "" && $("#txtCustSearch").val() != undefined) {
                filters.custSearch = $("#txtCustSearch").val();
            }

            if ($("#slBranch").val() != undefined) {
                filters.branch = $("#slBranch").val();
            } else {
                // setting branch from cookie if branches are not loaded
                filters.branch = BranchId;
            }

            if ($("#slPaymentStatus").val() != -1 && $("#slPaymentStatus").val() != undefined) {
                filters.payment_status = $("#slPaymentStatus").val();
            }
            if ($("#slOrderStatus").val() != -1 && $("#slOrderStatus").val() != undefined) {
                filters.order_status = $("#slOrderStatus").val();
            }
            if ($("#txtSearchFromDate").val() != "" && $("#txtSearchFromDate").val() != undefined) {
                filters.from_date = $("#txtSearchFromDate").val();
            }
            if ($("#txtSearchToDate").val() != "" && $("#txtSearchToDate").val() != undefined) {
                filters.to_date = $("#txtSearchToDate").val();
            }
            if (getQueryString("customerId") != undefined && getQueryString("customerId") != "") {
                filters.cus_id = getQueryString("customerId");
            }
            if ($("#selType").val() != -1 && $("#selType").val() != undefined) {
                filters.type = $("#selType").val();
            }
            filters.seller_id = $("#comboSalesPerson").val();

            $.cookie("search-data", JSON.stringify(filters));
            loading();
            odSkeleton();

            $.ajax({
                type: "POST",
                url: "Orders.aspx/searchOrders",
                data: JSON.stringify({ page: page, filters: filters, perpage: parseInt(perpage, 10) }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    var obj;
                    try {
                        obj = JSON.parse(msg.d);
                    } catch (ex) {
                        // server returns "N" (or an error text) when nothing can be listed
                        odEmpty('No orders or invoices found');
                        return;
                    }
                    if (!obj.data || obj.count == 0) {
                        odEmpty('No orders or invoices found<br /><small>Try changing the filters or create a new order.</small>');
                        return;
                    }

                    var htm = "";
                    $.each(obj.data, function (i, row) {
                        var status = parseInt(row.order_status, 10);
                        var st = statusMap[status] || statusMap[0];
                        var cancelled = status == 4 || status == 5;
                        var billed = row.invoiceNum !== null && row.invoiceNum !== "";
                        var balance = parseFloat(row.total_balance) || 0;
                        var net = parseFloat(row.net_amount) || 0;
                        var url = 'manageorders.aspx?orderId=' + encodeURIComponent(row.ref_id);
                        var printPage = printPages[row.branch_tax_method];

                        htm += '<tr class="od-row' + (cancelled ? ' od-cancelled' : '') + '" data-href="' + url + '">';
                        htm += '<td data-label="Invoice"><a class="od-invoice" href="' + url + '">';
                        if (billed) {
                            htm += odHighlight(filters.search, row.invoiceNum);
                        } else {
                            htm += '<span class="od-unbilled">Not billed yet</span>';
                        }
                        htm += '<small>Order #' + odHighlight(filters.search, row.sm_id) + '</small></a></td>';

                        htm += '<td data-label="Customer" class="od-customer">' + odHighlight(filters.custSearch, row.cust_name);
                        if (row['class']) htm += '<span class="od-tag">Class ' + odEscape(row['class']) + '</span>';
                        htm += '</td>';

                        htm += '<td data-label="Dates" class="od-meta od-hide-sm"><i class="fa fa-calendar"></i>' + odEscape(row.orderDate)
                            + '<small><i class="fa fa-user"></i>' + odEscape($.trim(row.seller_name)) + '</small>';
                        if (billed && row.billedDate) {
                            htm += '<small><i class="fa fa-file-text-o"></i>Billed ' + odEscape(row.billedDate)
                                + (row.billedBy ? ' by ' + odEscape($.trim(row.billedBy)) : '') + '</small>';
                        }
                        htm += '</td>';

                        htm += '<td data-label="Net Amount" class="od-num od-amount">&#8377; ' + odMoney(net) + '</td>';
                        if (cancelled) {
                            htm += '<td data-label="Balance" class="od-num od-meta">&mdash;</td>';
                        } else if (balance > 0) {
                            htm += '<td data-label="Balance" class="od-num od-due">&#8377; ' + odMoney(balance) + '</td>';
                        } else {
                            htm += '<td data-label="Balance" class="od-num od-settled">&#8377; ' + odMoney(0) + '</td>';
                        }

                        htm += '<td data-label="Payment">';
                        if (cancelled) {
                            htm += '<span class="od-meta">&mdash;</span>';
                        } else if (balance > 0) {
                            htm += '<span class="label label-danger od-status">Outstanding</span>';
                        } else {
                            htm += '<span class="label label-success od-status">Paid</span>';
                        }
                        htm += '</td>';

                        htm += '<td data-label="Status"><span class="label ' + st[1] + ' od-status">' + st[0] + '</span>';
                        if (row.srm_smid != null) htm += '<span class="label label-default od-status">Returned</span>';
                        htm += '</td>';

                        htm += '<td class="text-right" style="white-space:nowrap"><a href="' + url + '" class="btn btn-primary btn-xs" title="View"><i class="fa fa-eye"></i> View</a>';
                        if (printPage) {
                            htm += ' <a href="' + printPage + '?orderId=' + encodeURIComponent(row.ref_id) + '" class="btn btn-default btn-xs" title="Print"><i class="fa fa-print"></i></a>';
                        }
                        htm += '</td>';
                        htm += '</tr>';
                    });

                    $('#tblOrders > tbody').html(htm);
                    $('#txttotalordercount').text(obj.count);
                    $('#divPagination').html(paginate(obj.count, perpage, page, "searchOrders"));
                },
                error: function () {
                    Unloading();
                    odEmpty('Could not load orders. Please check your connection and try again.');
                }
            });
        }

        function resetFilters() {
            window.location.href = "orders.aspx";
        }

        // whole row is clickable, links/buttons keep their own behaviour
        $(document).on('click', '#tblOrders tr.od-row', function (e) {
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
                                <label style="font-weight: bold; font-size: 16px; margin: 0 auto 0 0;">Orders &amp; Invoices</label>
                                <a href="neworder.aspx" target="_blank" class="btn btn-primary btn-xs" style="margin-right: 10px;"><i class="fa fa-plus-square"></i>&nbsp; New Order / Invoice</a>
                            </div>
                        </nav>
                    </div>
                </div>
                <!-- /top navigation -->

                <!-- page content -->
                <div class="right_col od-page" role="main">
                    <div class="">

                        <div class="clearfix"></div>
                        <div class="row">
                            <div class="col-md-12 col-sm-12 col-xs-12">
                                <div class="x_panel od-filter">
                                    <div class="x_title" style="margin-bottom: 0px;">
                                        <strong><i class="fa fa-filter"></i>&nbsp; Filters</strong>
                                        <ul class="nav navbar-right panel_toolbox">
                                            <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                            </li>
                                        </ul>
                                        <div class="clearfix"></div>
                                    </div>
                                    <div class="x_content">

                                        <div class="form-horizontal form-label-left input_mask">
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group">
                                                <label for="slBranch">Warehouse</label>
                                                <select class="form-control" id="slBranch" onchange="searchOrders(1);">
                                                </select>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group">
                                                <label for="selType">Orders / Invoices</label>
                                                <select class="form-control" id="selType" onchange="searchOrders(1);">
                                                    <option value="-1" selected="selected">All orders &amp; invoices</option>
                                                    <option value="0">Orders only</option>
                                                    <option value="1">Invoices only</option>
                                                </select>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group">
                                                <label for="comboSalesPerson">Salesman / User</label>
                                                <select class="form-control" id="comboSalesPerson" onchange="searchOrders(1);">
                                                    <option value="0">Select Sales Person</option>
                                                </select>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group">
                                                <label for="slOrderStatus">Status</label>
                                                <select class="form-control" id="slOrderStatus" onchange="searchOrders(1);">
                                                    <option value="-1" selected="selected">All status</option>
                                                    <option value="3">To be Confirmed</option>
                                                    <option value="0">New</option>
                                                    <option value="1">Processed</option>
                                                    <option value="2">Delivered</option>
                                                    <option value="4">Canceled</option>
                                                    <option value="5">Rejected</option>
                                                </select>
                                            </div>

                                            <div class="col-md-2 col-sm-6 col-xs-12 form-group">
                                                <label for="slPaymentStatus">Payment</label>
                                                <select class="form-control" id="slPaymentStatus" onchange="searchOrders(1);">
                                                    <option value="-1" selected="selected">All</option>
                                                    <option value="1">Completed</option>
                                                    <option value="2">Outstanding</option>
                                                </select>
                                            </div>
                                            <div class="col-md-2 col-sm-6 col-xs-12 form-group">
                                                <label for="txtSearchFromDate">From date</label>
                                                <input type="text" class="form-control" id="txtSearchFromDate" placeholder="dd-mm-yyyy" />
                                            </div>
                                            <div class="col-md-2 col-sm-6 col-xs-12 form-group">
                                                <label for="txtSearchToDate">To date</label>
                                                <input type="text" class="form-control" id="txtSearchToDate" placeholder="dd-mm-yyyy" />
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group">
                                                <label for="txtSearch">Order / Invoice</label>
                                                <input type="text" class="form-control" id="txtSearch" placeholder="Order id / invoice no." />
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group">
                                                <label for="txtCustSearch">Customer</label>
                                                <input type="text" class="form-control" id="txtCustSearch" placeholder="Customer ID / name" />
                                            </div>

                                            <div class="col-md-12 col-sm-12 col-xs-12 od-filter-actions">
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
                                    <div class="od-list-head">
                                        <div class="od-count">Orders / Invoices<span class="badge" id="txttotalordercount">0</span></div>
                                        <div class="od-perpage">
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
                                                    <th>Invoice</th>
                                                    <th>Customer</th>
                                                    <th class="od-hide-sm">Dates</th>
                                                    <th class="od-num">Net Amount</th>
                                                    <th class="od-num">Balance</th>
                                                    <th>Payment</th>
                                                    <th>Status</th>
                                                    <th></th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr>
                                                    <td colspan="8" class="od-empty"><i class="fa fa-spinner fa-spin"></i>Loading orders...</td>
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
                                Copyright 2014 &copy;
                            </div>
                        </div>
                    </div>
                    <div class="clearfix"></div>
                </footer>
                <!-- /footer content -->
            </div>
        </div>
    </form>

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
