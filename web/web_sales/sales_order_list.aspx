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

    <style>
        th.sortable, a.sortable { cursor: pointer; white-space: nowrap; }
        .sortable .fa { margin-left: 4px; color: #999; }
    </style>

    <script type="text/javascript">
        var sortBy = "date", sortDir = "desc";
        var statusMap = {
            0: ["New", "label label-warning"],
            1: ["Approved", "label label-success"],
            2: ["Fully Delivered", "label label-success"],
            3: ["Partially Delivered", "label label-info"],
            4: ["Pending", "label label-info"],
            5: ["Customer Cancelled", "label label-default"],
            6: ["Company Cancelled", "label label-default"],
            7: ["Processed", "label label-primary"]
        };

        function esc(s) {
            return $("<div/>").text(s == null ? "" : String(s)).html();
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
            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " �");
            $("#txtSearch, #txtCustSearch").keypress(function (e) {
                if (e.which == 13) { searchOrders(1); return false; }
            });
            getBranches();
        });

        function getBranches() {
            loading();
            $.ajax({
                type: "POST", url: "sales_order_list.aspx/getBranches", data: "{}",
                contentType: "application/json; charset=utf-8", dataType: "json",
                success: function (msg) {
                    var obj = JSON.parse(msg.d);
                    var htm = '<option value="-1" selected="selected">--All Warehouses--</option>';
                    $.each(obj, function (i, row) {
                        htm += '<option value="' + esc(row.branch_id) + '">' + esc(row.branch_name) + '</option>';
                    });
                    $("#slBranch").html(htm);
                    Unloading();
                    searchOrders(1);
                },
                error: function () { Unloading(); alert("Internet Problem..!"); }
            });
        }

        function sortOrders(col) {
            if (sortBy == col) { sortDir = sortDir == "asc" ? "desc" : "asc"; }
            else { sortBy = col; sortDir = "asc"; }
            searchOrders(1);
        }

        function updateSortIcons() {
            $(".sortable .fa").attr("class", "fa fa-sort");
            $(".sortable[data-col='" + sortBy + "'] .fa").attr("class", "fa " + (sortDir == "asc" ? "fa-sort-asc" : "fa-sort-desc"));
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
            $.ajax({
                type: "POST",
                url: "sales_order_list.aspx/searchSalesOrders",
                data: JSON.stringify({ page: page, filters: filters, perpage: parseInt(perpage, 10), sortBy: sortBy, sortDir: sortDir }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d == "E") {
                        $('#tblOrders > tbody').html('<tr><td colspan="5" style="text-align:center;color:red">Unable to load sales orders. Please try again.</td></tr>');
                        $("#txttotalordercount").text(0);
                        $('#divPagination').html("");
                        return;
                    }
                    var obj = JSON.parse(msg.d);
                    var htm = "";
                    $("#txttotalordercount").text(obj.count);
                    if (obj.count == 0) {
                            htm = '<tr><td colspan="5" style="text-align:center"><label>Empty</label></td></tr>';
                        }
                    $.each(obj.data, function (i, row) {
                        var st = statusMap[row.order_status] || statusMap[0];
                        var num = '#' + esc(row.smo_id) + (row.smo_invoice_no ? ' (' + esc(row.smo_invoice_no) + ')' : '');
                        var money = function (x) { return x == null ? "0.00" : Number(x).toFixed(2); };
                        var payMap = { 1: "Cash", 2: "Credit", 3: "Bill to bill" };
                        var typeMap = { 1: "Direct visit", 2: "Telephonic", 3: "Mail" };
                        var hl = function (t) { return getHighlightedValue(filters.search, String(t == null ? "" : t)); };
                        htm += '<tr>';
                        htm += '<td><div style="min-width:420px;">';
                        htm += '<div><span class="myorderMData"><b>' + num + '</b></span> ';
                        htm += '<label style="margin:0 5px;font-size:14px;"><a>' + esc(row.cust_name) + '</a></label>';
                        if (row['class']) htm += '<span>(Class ' + esc(row['class']) + ')</span> ';
                        if (row.smo_payment_type > 0) htm += ' <span class="label label-default" style="margin-left:2px;">' + (payMap[row.smo_payment_type] || '') + '</span>';
                        htm += '</div>';
                        htm += '<div class="clear"></div><div style="text-align:left;">';
                        htm += '<label class="fa fa-edit myicons"></label><span class="myorderSData">' + esc($.trim(row.seller_name)) + '</span>&nbsp;&nbsp;';
                        htm += '<label class="fa fa-map-marker myicons"></label><span class="myorderSData">' + esc(row.branch_name) + '</span>';
                        if (typeMap[row.smo_order_type]) htm += '&nbsp;&nbsp;<span class="myorderSData">(' + typeMap[row.smo_order_type] + ')</span>';
                        htm += '</div><div style="text-align:left;">';
                        htm += '<span class="myorderSData" style="color:#361efb;font-size:15px;">Customer: </span>';
                        htm += '<label class="fa fa-user myicons"></label><span class="myorderSData">ID ' + esc(row.cust_id) + '</span>&nbsp;&nbsp;';
                        if (row.cust_phone) htm += '<label class="fa fa-phone myicons"></label><span class="myorderSData">' + esc(row.cust_phone) + '</span>&nbsp;&nbsp;';
                        if (row.cust_email) htm += '<label class="fa fa-envelope myicons"></label><span class="myorderSData">' + esc(row.cust_email) + '</span>&nbsp;&nbsp;';
                        if (row.cust_city) htm += '<label class="fa fa-building myicons"></label><span class="myorderSData">' + esc(row.cust_city) + '</span>&nbsp;&nbsp;';
                        if (row.cust_tax_reg_id) htm += '<span class="myorderSData">Tax Reg: ' + esc(row.cust_tax_reg_id) + '</span>';
                        htm += '</div></div></td>';
                        htm += '<td style="text-align:center"><label class="fa fa-calendar myicons"></label><span class="myorderSData">' + esc(row.orderDate) + '</span></td>';
                        htm += '<td style="text-align:center"><span class="status ' + st[1] + '">' + st[0] + '</span></td>';
                        htm += '<td style="text-align:center"><b>' + money(row.net_amount) + '</b></td>';
                        htm += '<td style="text-align:center"><a href="view_sales_order.aspx?smoId=' + encodeURIComponent(row.smo_id) + '" target="_blank" class="btn btn-primary btn-xs" title="View"><li class="fa fa-eye" style="font-size:large;"></li></a></td>';
                        htm += '</tr>';
                    });
                    $('#tblOrders > tbody').html(htm);
                    $('#divPagination').html(obj.count > 0 ? paginate(obj.count, perpage, page, "searchOrders") : "");
                },
                error: function () { Unloading(); alert("Internet Problem..!"); }
            });
        }

        function resetFilters() {
            $("#txtSearch, #txtCustSearch, #txtSearchFromDate, #txtSearchToDate").val("");
            $("#slBranch, #slOrderStatus").val("-1");
            $("#slPerpage").val("50");
            sortBy = "date"; sortDir = "desc";
            searchOrders(1);
        }
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
                                <div class="col-md-6 col-xs-6">
                                    <label style="font-weight: bold; font-size: 16px;">Sales Orders</label>
                                </div>
                                <div class="col-md-6 col-xs-5">
                                    <a href="new_sales_order.aspx" target="_blank">
                                        <div class="btn btn-primary btn-xs pull-right" style="margin-top: 5px"><label style="color: #fff; margin-right: 5px; font-size: 14px;" class="fa fa-plus-square"></label>New Sales Order</div>
                                    </a>
                                </div>
                            </div>
                        </nav>
                    </div>
                </div>

                <div class="right_col" role="main">
                    <div class="">
                        <div class="clearfix"></div>
                        <div class="row">
                            <div class="col-md-12 col-sm-12 col-xs-12">
                                <div class="x_panel">
                                    <div class="x_title" style="margin-bottom: 0px;">
                                        <strong>Filter</strong>
                                        <ul class="nav navbar-right panel_toolbox">
                                            <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a></li>
                                        </ul>
                                    </div>
                                    <div class="x_content">
                                        <div class="form-horizontal form-label-left input_mask">
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Warehouse</label>
                                                <select class="form-control" style="text-indent: 25px;" id="slBranch" onchange="searchOrders(1);"></select>
                                                <span class="fa fa-map-marker form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Order Status</label>
                                                <select class="form-control" style="text-indent: 25px;" id="slOrderStatus" onchange="searchOrders(1);">
                                                    <option value="-1" selected="selected">--All Status--</option>
                                                    <option value="0">New</option>
                                                    <option value="4">Pending</option>
                                                    <option value="1">Approved</option>
                                                    <option value="7">Processed</option>
                                                    <option value="3">Partially Delivered</option>
                                                    <option value="2">Fully Delivered</option>
                                                    <option value="5">Customer Cancelled</option>
                                                    <option value="6">Company Cancelled</option>
                                                </select>
                                                <span class="fa fa-file form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Dated from</label>
                                                <input type="text" class="form-control has-feedback-left" style="background-color: #fff" id="txtSearchFromDate" placeholder="From Date" />
                                                <span class="fa fa-calendar form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Dated Upto</label>
                                                <input type="text" class="form-control has-feedback-left" style="background-color: #fff" id="txtSearchToDate" placeholder="To Date" />
                                                <span class="fa fa-calendar form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-6 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Search</label>
                                                <input type="text" class="form-control has-feedback-left" id="txtSearch" placeholder="Order no / Invoice no / Customer / Status" />
                                                <span class="fa fa-search form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-6 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Search for Customer</label>
                                                <input type="text" class="form-control has-feedback-left" id="txtCustSearch" placeholder="Search with Customer ID/ Customer Name" />
                                                <span class="fa fa-search form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-12 col-sm-12 col-xs-12">
                                                <div class="btn btn-success mybtnstyl" onclick="searchOrders(1);" style="float: right">
                                                    <li class="fa fa-search" style="margin-right: 5px;"></li>
                                                    Search
                                                </div>
                                                <div class="btn btn-primary mybtnstyl" onclick="resetFilters();" style="float: right">
                                                    <li class="fa fa-refresh" style="margin-right: 5px;"></li>
                                                    Reset
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="clearfix"></div>

                        <div class="row">
                            <div class="col-md-12 col-sm-12 col-xs-12">
                                <div class="x_panel">
                                    <div class="x_title" style="margin-bottom: 0px;">
                                        <div class="col-md-6 col-sm-12 col-xs-12">
                                            <label>Sales Orders</label><span class="badge" style="color: #fff; margin-left: 5px; background: #d00101; padding-left: 5px; padding-right: 5px;" id="txttotalordercount"></span>
                                        </div>
                                        <div class="col-md-6 col-sm-12 col-xs-12">
                                            <ul class="nav navbar-right panel_toolbox">
                                                <li>
                                                    <select id="slPerpage" onchange="searchOrders(1);" class="input-sm">
                                                        <option value="50">50</option>
                                                        <option value="100">100</option>
                                                        <option value="250">250</option>
                                                        <option value="500">500</option>
                                                    </select></li>
                                            </ul>
                                        </div>
                                        <div class="clearfix"></div>
                                    </div>
                                    <div class="col-md-12 col-sm-12 col-xs-12" style="overflow-x: auto;">
                                        <div class="x_content">
                                            <table id="tblOrders" class="table table-striped jambo_table bulk_action" style="table-layout: auto;">
                                                <thead style="background-color: #f1eeee; color: #525252">
                                                    <tr>
                                                        <th>Order Details &nbsp;<span style="font-weight:normal;font-size:12px;">Sort:
                                                            <a class="sortable" data-col="number" onclick="sortOrders('number')">No<i class="fa fa-sort"></i></a> |
                                                            <a class="sortable" data-col="customer" onclick="sortOrders('customer')">Customer<i class="fa fa-sort"></i></a> |
                                                            <a class="sortable" data-col="warehouse" onclick="sortOrders('warehouse')">Warehouse<i class="fa fa-sort"></i></a></span></th>
                                                        <th class="sortable" data-col="date" style="text-align: center;" onclick="sortOrders('date')">Date<i class="fa fa-sort"></i></th>
                                                        <th class="sortable" data-col="status" style="text-align: center;" onclick="sortOrders('status')">Status<i class="fa fa-sort"></i></th>
                                                        <th class="sortable" data-col="total" style="text-align: center;" onclick="sortOrders('total')">Net Amount<i class="fa fa-sort"></i></th>
                                                        <th style="text-align: center;">Action</th>
                                                    </tr>
                                                </thead>
                                                <tbody>
                                                    <tr>
                                                        <td colspan="5" style="text-align: center"><label>Empty</label></td>
                                                    </tr>
                                                </tbody>
                                            </table>
                                            <div id="divPagination" style="text-align: center;"></div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <footer>
                    <div class="pull-right">
                        <div class="footerDiv">
                            <div class="footerDivContent">Copyright 2014 �</div>
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
