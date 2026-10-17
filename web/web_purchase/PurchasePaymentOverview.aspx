<%@ Page Language="C#" AutoEventWireup="true" CodeFile="PurchasePaymentOverview.aspx.cs" Inherits="web_purchase_PurchasePaymentOverview" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Payments Against Purchase Overview | Invoice Me</title>
    <script src="../js/common.js" type="text/javascript"></script>
    <script type="text/javascript" src="../js/jquery-2.0.3.js"></script>

    <script type="text/javascript" src="../js/jquery.cookie.js"></script>
    <script type="text/javascript" src="../js/jQuery.print.js"></script>
    <script src="../js/pagination.js" type="text/javascript"></script>
    <link rel="stylesheet" href="../mobiscroll/css/jquery.mobile-1.1.0.min.css" />
    <script src="../mobiscroll/js/mobiscroll-2.0rc3.full.min.js" type="text/javascript"></script>
    <link href="../mobiscroll/css/mobiscroll-2.0rc3.full.min.css" rel="stylesheet" type="text/css" />
    <!-- Bootstrap -->
    <link href="../css/bootstrap/bootstrap.min.css" rel="stylesheet" />
    <!-- Font Awesome -->
    <link href="../css/bootstrap/font-awesome/css/font-awesome.min.css" rel="stylesheet" />
    <!-- NProgress -->
    <link href="../css/bootstrap/nprogress.css" rel="stylesheet" />
    <!-- Custom Theme Style -->
    <link href="../css/bootstrap/custom.min.css" rel="stylesheet" />
    <!--My Style-->
    <link href="../css/bootstrap/mystyle.css" rel="stylesheet" type="text/css" />
    <%-- autosearch --%>
    <script src="../autosearch/jquery-ui.js" type="text/javascript"></script>
    <link href="../autosearch/jquery-ui.css" rel="Stylesheet" type="text/css" />
    <script src="../autosearch/jquery-ui.min.js" type="text/javascript"></script>
    <script src="../autosearch/jquery-1.12.4.js" type="text/css"></script>
    <%-- autosearch --%>

    <script type="text/javascript">
        // console.log(actionTypes);
        var customer_id = -1;
        $(document).ready(function () {

            $("#customerNames").val('');
            BranchId = $.cookie("invntrystaffBranchId");
            if (!BranchId) {
                location.href = "../dashboard.aspx";
                return false;
            }
            SearchAutoCustomer();
            $("#txtSearchFromDate").val('');
            $("#txtSearchToDate").val('');
            // console.log(actionTypeobj[0].name);
            ShowUTCDate();
            customer_id = -1;

        });

        $(function () {
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
            });
        });//end
        function ShowUTCDate() {
            var dNow = new Date();
            var date = dNow.getDate();
            if (date < 10) {
                date = "0" + date;
            }
            var localdate = date + '-' + GetMonthName(dNow.getMonth() + 1) + '-' + dNow.getFullYear();
            $("#txtSearchFromDate").val(localdate);
            $("#txtSearchToDate").val(localdate);
            //showsalespersons();
            //showDailyReports(1);
            showTransactions(1);
        }//end
        function GetMonthName(monthNumber) {
            var months = ['01', '02', '03', '04', '05', '06',
            '07', '08', '09', '10', '11', '12'];
            return months[monthNumber - 1];

        }//end

        function dateformat(idate) {

            var med = idate.split("-");
            var dd = med[0];
            var mm = med[1];
            var yy = med[2];

            var nDate = yy + '-' + mm + '-' + dd;
            return nDate;

        }

        function SearchAutoCustomer() {
            var warehouse = $.cookie("invntrystaffBranchId");
            $("#customerNames").keyup(function () {
                //alert("ch");
                if ($("#customerNames").val().trim() === "") {
                    $("#searchTitle").hide();
                }
            });

            $("#customerNames").autocomplete({
                source: function (request, response) {
                    $.ajax({
                        type: "POST",
                        contentType: "application/json; charset=utf-8",
                        url: "PurchasePaymentOverview.aspx/GetAutoCompleteVendorData",
                        data: "{'variable':'" + $("#customerNames").val() + "'}",
                        dataType: "json",
                        success: function (data) {
                            
                            var data1 = jQuery.parseJSON(data.d);
                            console.log(data1);
                            response(data1.slice(0, 20));
                        }
                    });
                },
                select: function (event, ui) {
                    //alert(123);
                    if (ui.item.id == -1) {

                        $("#customerNames").val("");

                    } else {

                        $("#customerNames").val(ui.item.label);
                        customer_id = ui.item.id;
                        showTransactions(1);
                    }
                    
                    event.preventDefault();
                },
                minLength: 1

            });

        }

        function showsalespersons() {
            loading();
            $.ajax({
                type: "POST",
                url: "PurchasePaymentOverview.aspx/showsalespersons",
                data: "{}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    // alert(msg.d);
                    var obj = JSON.parse(msg.d);
                    var htm = "";
                    htm += '<option value="0" selected="selected">-- Select User--</option>';
                    $.each(obj, function (i, row) {
                        htm += '<option value="' + row.user_id + '">' + row.first_name + '&nbsp' + row.last_name + '</option>';
                    });
                    $("#comboSalesInReport").html(htm);
                    showTransactions(1);
                    //showDailyReports(1);


                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }//end

        //function for table clearing
        function tableclear() {
            $(".classtest").remove();
            $("#txtposTotalCost").text("");
            $("#txtTotalDiscountRate").text("");
            $("#txtTotalDiscountAmount").text("");
            $("#txtTotalNetAmount").text("");
            $("#txtTotalGrossamount").text("");
            $("#txtPosPaidAmount").val("0");
            $("#txtPosBalanceAmount").val("0");
            $("#customerNames").val("");
            $("#txtNames").val("");
            $("#ItemTypecheck").attr("checked", false);
            //disablepayment();
        }

        function popupclose(divid) {
            $("#" + divid).modal('hide');
        }

        //function for reset
        function resetcustomerdata() {
            tableclear();
            $("#divchangeDetails").hide();
            //  $("#hdnCurrentAction").val('main');
            for (var i = 1; i <= 9; i++) {
                $("#searchvalContent" + i).val('');
            }
            $("#combopricegroupdiv").val(0);
            $("#txtNames").val("");


            //  showpricegroups();
            searchCustomersCheck(1);

        }

        //for showing search values in  popup...
        function searchCustomersCheck(page) {
            var filters = {};
            if ($("#searchvalContent1").val() != "") {
                filters.cust_id = $.trim($("#searchvalContent1").val());
            }
            if ($("#searchvalContent2").val() != "") {
                filters.cust_name = $.trim($("#searchvalContent2").val());
            }

            if ($("#searchvalContent3").val() != "") {
                filters.cust_phone = $.trim($("#searchvalContent3").val());
            }
            if ($("#searchvalContent4").val() != "") {
                filters.cust_amount = $.trim($("#searchvalContent4").val());
            }

            
            filters.warehouse = $.cookie("invntrystaffBranchId");
            console.log(JSON.stringify(filters));
            //   alert(filters.warehouse);
            var perpage = $("#txtpageno").val();
            console.log(JSON.stringify(filters));

            loading();

            $.ajax({
                type: "POST",
                url: "neworder.aspx/searchOrderCustomers",
                data: "{'page':" + page + ",'filters':" + JSON.stringify(filters) + ",'perpage':" + perpage + "}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    //alert(msg.d);
                    //alert("Success");
                    if (msg.d == "N") {
                        Unloading();
                        $("#lblCustTotalrecords").text(0);
                        //   alert("No Search Results");
                        $('#TBLshowSearchMembers tbody').html('<td colspan="6" style="background:#ebebeb; padding:5px;font-weight:bold;"><div style="width:100%;text-align:center"><div style="display:inline-block">Nothing Found...</div></div></td>');
                        $("#paginatediv").html("");
                        //  $("#showSearchMembers").html('');
                        //$("#findMember").show();
                    }
                    else {
                        var obj = JSON.parse(msg.d)
                        //  console.log(obj);
                        Unloading();
                        $("#lblCustTotalrecords").text(obj.count);
                        var htm = "";
                        $.each(obj.data, function (i, row) {
                            console.log(row);
                            htm += '<tr id="customerRow' + i + '" onclick="javascript:selectCustomer(\'' + row.cust_id + '\',\'' + row.cust_name + '\');" style="cursor:pointer;">';
                            htm += "<td>" + getHighlightedValue(filters.cust_id, row.cust_id.toString()) + "</td>";
                            if (row.new_custtype == 0 && row.new_creditamt == 0 && row.new_creditperiod == 0) {
                                htm += "<td>" + getHighlightedValue(filters.cust_name, row.cust_name) + "</td>";
                            } else {
                                htm += "<td>" + getHighlightedValue(filters.cust_name, row.cust_name) + "<label class='label label-warning' style='margin-left:5px;'>To be confirmed</label></td>";
                            }


                            if (row.cust_amount == null) {
                                row.cust_amount = 0;
                            }
                           // htm += "<td>" + row.class + "</td>";
                            htm += "<td>" + getHighlightedValue(filters.cust_phone, row.cust_phone.toString()) + "</td>";
                            var style = "";
                            if (row.cust_amount <= 0) {
                                style = "color:green";
                            } else {
                                style = "color:red";
                            }
                            htm += "<td style='" + style + "'>" + getHighlightedValue(filters.cust_amount, row.cust_amount.toString()) + "</td>";

                            htm += "</tr>";
                        });
                        htm += '<tr>';
                        htm += '<td colspan="6">';
                        htm += '<div  id="paginatediv" style="text-align: center;">';
                        htm += '</div>';
                        htm += '</td>';
                        htm += '</tr>';
                        // $("#showSearchMembers table").html(htm);

                        $("#TBLshowSearchMembers tbody").html(htm);

                        $("#paginatediv").html(paginate(obj.count, perpage, page, "searchCustomersCheck"));
                        //$("#popupcustomer").show();
                    }

                },
                error: function (xhr, status) {
                    Unloading();
                    //alert("fail" + status + ":::" + xhr.d);
                    alert("Internet Problem..!");
                }
            });
        }
        // showing search values in  popup


        function showTransactions(page) {
            var postObj = {
                page: page,
                perpage: $("#txtpageno").val(),
                filters: {
                }
            }

            if ($("#txtSearchFromDate").val() != "" && $("#txtSearchFromDate").val() != undefined) {
                postObj.filters.from_date = dateformat($("#txtSearchFromDate").val());
            }
            if ($("#txtSearchToDate").val() != "" && $("#txtSearchToDate").val() != undefined) {
                postObj.filters.to_date = dateformat($("#txtSearchToDate").val());
            }

            if ($("#comboSalesInReport").val() && $("#comboSalesInReport").val() != "-1" && $("#comboSalesInReport").val() != "") {
                postObj.filters.salesmanId = $("#comboSalesInReport").val();
            }


            if ($("#selWarehouse").val() && $("#selWarehouse").val() != "-1" && $("#selWarehouse").val() != "") {
                postObj.filters.warehouse = $("#selWarehouse").val();
            }

            

            if ($("#customerNames").val() == "") { customer_id = -1; }

            if (customer_id != -1) {
                
                postObj.filters.customer_id = customer_id;
            }

            //alert('hi');
            console.log(JSON.stringify(postObj));


            $.ajax({
                type: "POST",
                url: "PurchasePaymentOverview.aspx/showCollections",
                data: JSON.stringify(postObj),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    transactionObj = JSON.parse(msg.d);
                    if (transactionObj.wallet_to_clear > 0) {

                        $("#wallet_notify_link").show();
                        $("#lbl_usable_wallet").html('<a class="btn btn-danger" href="PendingPaymentClearance.aspx" target="blank"><b style="color:#fff">' + transactionObj.wallet_to_clear + '</b></a>');
                    }
                    else {
                        $("#wallet_notify_link").hide();
                        $("#lbl_usable_wallet").html('0.00');
                    }
                   
                    var htm = "";
                    var html = "";
                    var phtm = "";
                    var classType = "";

                    var total_wallet_credit_amt = 0;
                    var total_debit_amt = 0;
                    var total_return_amt = 0;
                    var total_paid = 0;
                    var with_wallet = 0;
                    var without_wallet = 0;
                    var with_cash = 0;
                    var with_cheque = 0;

                    $('#tblTransactions > tbody').html("");

                    $('#lbl_paycnt').html(transactionObj.payment_count);


                    var sl = 0;
                    if (transactionObj.payment_count > 0) {
                        $.each(transactionObj.payment_data, function (i, row) {

                            sl++;
                            $("#txttotalordercount").text(transactionObj.payment_count);
                            phtm += '<tr>';
                            phtm += '<td>' + sl + '</td>';

                            //phtm += '<td>' + row.location_name + '</td>';
                            phtm += '<td><b>' + row.cust_name + '</b><br />' + row.cust_address + ',' + row.cust_city + '</td>';
                            phtm += '<td><b>' + row.trans_date + '</b></td>';
                            phtm += '<td>' + row.user + '</td>';
                            phtm += '<td><b>' + row.invoice + '</b><br />' + row.bill_date + '<br /><b>Bill Amount:' + row.netAmt + '</b></td>';

                            if (row.cash_amt > 0) {

                                phtm += '<td><b>' + row.cash_amt + '</b></td>';
                            }
                            else {
                                phtm += '<td>' + row.cash_amt + '</td>';
                            }

                            if (row.cheque_amt > 0) {

                                phtm += '<td>Amt:<b>' + row.cheque_amt + '</b><br />Cheque No: ' + row.cheque_no + '<br />Date: ' + row.cheque_date + '<br />Bank: ' + row.cheque_bank + '</td>';
                            }
                            else {

                                phtm += '<td>' + row.cheque_amt + '</td>';
                            }

                            if (row.wallet_amt > 0) {

                                phtm += '<td><b>' + row.wallet_amt + '</b></td>';
                            }
                            else {
                                phtm += '<td>' + row.wallet_amt + '</td>';
                            }

                            phtm += '<td><b>' + row.dr + '</b></td>';
                            phtm += '</tr>';

                            total_paid = parseFloat(total_paid) + parseFloat(row.dr);
                            with_wallet = parseFloat(with_wallet) + parseFloat(row.wallet_amt);
                            with_cash = parseFloat(with_cash) + parseFloat(row.cash_amt);
                            with_cheque = parseFloat(with_cheque) + parseFloat(row.cheque_amt);

                        });
                    }
                    else {

                        phtm = '<tr><td colspan="9" style="text-align:center"></div></div><div class="cl" style="height:5px;"></div><label>Empty</label></td></tr>';
                    }
                    $('#tblTransactions_paid > tbody').html(phtm);

                    $('#lbl_paycnt0').html(total_paid + ' In Total');
                    $('#lbl_paycnt1').html(with_cash + ' As Cash');
                    $('#lbl_paycnt2').html(with_cheque + ' As Cheque');
                    $('#lbl_paycnt3').html(with_wallet + ' From Wallet');
                    

                    


                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }

        function resetFilter() {
            //ShowUTCDate();
            //$("#customerNames").val('');
            //customer_id = -1;
            //$("#comboSalesInReport").val(0);
            //$("#selWarehouse").val(-1);
            //$("#selDebitCredit").val(-1);
            location.reload();
        }

        function DownloadExcel(type) {

            var postObj = {
                type: type,                
                filters: {
                }
            }

            if ($("#txtSearchFromDate").val() != "" && $("#txtSearchFromDate").val() != undefined) {
                postObj.filters.from_date = dateformat($("#txtSearchFromDate").val());
            }
            if ($("#txtSearchToDate").val() != "" && $("#txtSearchToDate").val() != undefined) {
                postObj.filters.to_date = dateformat($("#txtSearchToDate").val());
            }

            if ($("#comboSalesInReport").val() && $("#comboSalesInReport").val() != "-1" && $("#comboSalesInReport").val() != "") {
                postObj.filters.salesmanId = $("#comboSalesInReport").val();
            }


            if ($("#selWarehouse").val() && $("#selWarehouse").val() != "-1" && $("#selWarehouse").val() != "") {
                postObj.filters.warehouse = $("#selWarehouse").val();
            }
            

            if ($("#customerNames").val() == "") { customer_id = -1; }

            if (customer_id != -1) {

                postObj.filters.customer_id = customer_id;
            }

           
            $.ajax({
                type: "POST",
                url: "PurchasePaymentOverview.aspx/DownloadExcel",
                data: JSON.stringify(postObj),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {

                    if (msg.d == "N" || msg.d == "0") {
                        alert("No results found!");
                        return false;
                    }
                    else {
                        location.href = "DownloadPurchasePayments.aspx";
                        return false;
                    }

                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }

        //Start:TO Replace single quotes with double quotes
        function sqlInjection() {
            $('input, select, textarea').each(
                function (index) {
                    var input = $(this);
                    var type = this.type ? this.type : this.nodeName.toLowerCase();
                    //alert(type);
                    if (type == "text" || type == "textarea") {
                        //var mytest=input.val().replace("'",'"');
                        //alert('Type: ' + type + 'Name: ' + input.attr('id') + 'Value: ' + input.val().replace("'",'"'));

                        //$("#"+input.attr('id')).val(input.val().replace("'",'"'));
                        $("#" + input.attr('id')).val(input.val().replace(/'/g, '"'));
                    }
                    else {
                    }
                }
            );
        }
        //Stop:TO Replace single quotes with double quotes

        function selectCustomer(customerId,customer_name) {

            customer_id = customerId;
            $('#customerNames').val(customer_name);
            $('#popupcustomer').modal('hide');
            showTransactions(1);

        }

    </script>


    <style media="print">
        @page {
            size: auto;
            margin: 0;
        }

        thead {
            display: table-header-group;
        }
    </style>

</head>
<body class="nav-md">
    <div class="container body">
        <div class="main_container">
            <div class="col-md-3 left_col">
                <div class="left_col scroll-view">
                    <div class="navbar nav_title" style="border: 0;">
                        <a href="../index.html" class="site_title">
                            <!--<i class="fa fa-paw"></i> -->
                            <span>Invoice Me</span></a>
                    </div>

                    <div class="clearfix"></div>

                    <!-- menu profile quick info -->
                    <div class="profile clearfix">
                        <div class="profile_pic">
                            <img src="../images/img.jpg" alt="..." class="img-circle profile_img">
                        </div>
                        <div class="profile_info">
                            <span>Welcome,</span>
                            <h2>John Doe</h2>
                        </div>
                    </div>
                    <!-- /menu profile quick info -->

                    <br />

                    <!-- sidebar menu -->
                    <div id="sidebar-menu" class="main_menu_side hidden-print main_menu">
                        <div class="menu_section">
                            <h3>General</h3>
                            <ul class="nav side-menu">
                                <li><a href="../index.html" a><i class="fa fa-home"></i>Home <span class="fa fa-chevron-down"></span></a>
                                </li>
                                <li><a><i class="fa fa-user"></i>Customer <span class="fa fa-chevron-down"></span></a>
                                    <ul class="nav child_menu">
                                        <li><a href="../customer/newcustomer.html">New Customer</a></li>
                                        <li><a href="../customer/customers.html">Customers</a></li>
                                        <li><a href="../customer/customerconfirmation.html">Customer Confirmation</a></li>
                                        <li><a href="../customer/assigncustomers.html">Assign Customer</a></li>
                                    </ul>
                                </li>
                                <li><a><i class="fa fa-shopping-cart"></i>Sales <span class="fa fa-chevron-down"></span></a>
                                    <ul class="nav child_menu">
                                        <li><a href="#">New Order</a></li>
                                        <li><a href="#">Orders</a></li>
                                        <li><a href="#">Edit Order</a></li>
                                        <li><a href="#">Confirm Order</a></li>
                                    </ul>
                                </li>
                                <li><a><i class="fa fa-cubes"></i>Inventory <span class="fa fa-chevron-down"></span></a>
                                    <ul class="nav child_menu">
                                        <li><a href="warehouse.html">Warehouses</a></li>
                                        <li><a href="itemmaster.html">Item Master</a></li>
                                        <li><a href="stockmanagement.html">Stock Management</a></li>
                                        <li><a href="salescommission.html">Sales Commission</a></li>
                                        <li><a href="offermaster.html">Offer</a></li>
                                        <li><a href="itembrand.html">Item Brand</a></li>
                                        <li><a href="itemcategory.html">Item Category</a></li>
                                        <li><a href="managevendor.html">Manage Vendor</a></li>
                                        <li><a href="#">Purchase Entry</a></li>

                                    </ul>
                                </li>
                                <li><a><i class="fa fa-wrench"></i>OP Center <span class="fa fa-chevron-down"></span></a>
                                    <ul class="nav child_menu">
                                        <li><a href="../opcenter/manageuser.html">Manage User</a></li>
                                        <li><a href="#">Manage Role</a></li>
                                        <li><a href="#">Track Users</a></li>
                                    </ul>
                                </li>
                                <li><a><i class="fa fa-gears"></i>Settings <span class="fa fa-chevron-down"></span></a>
                                    <ul class="nav child_menu">
                                        <li><a href="#">Settings</a></li>
                                        <li><a href="#">Export to Tally</a></li>
                                    </ul>
                                </li>
                                <li><a><i class="fa fa-file-text-o"></i>Reports<span class="fa fa-chevron-down"></span></a>
                                    <ul class="nav child_menu">
                                        <li><a href="#">Sales Reports</a></li>
                                        <li><a href="#">Sales Reports Advanced</a></li>
                                        <li><a href="#">Sales Return Reports</a></li>
                                        <li><a href="#">Item Report</a></li>
                                        <li><a href="#">Graphical Item Report</a></li>
                                        <li><a href="#">Purchase Report</a></li>
                                        <li><a href="#">Purchase Report Advance</a></li>
                                    </ul>
                                </li>
                            </ul>
                        </div>


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
                            <label style="font-weight: bold; font-size: 16px;">Payments Against Purchases - Overview</label>

                        </div>

                    </nav>
                </div>
            </div>

            <!-- /top navigation -->
            <!-- page content -->

            <div id="divReportContent">

                <div class="right_col" role="main" id="">
                    <div class="">
                        <div class="page-title">
                            <%--  <div class="title_left">
                <h3>Sales Advanced Report</h3>
              </div> --%>
                        </div>

                        <div class="clearfix"></div>

                        <div class="row">
                            <div class="col-md-12 col-sm-12 col-xs-12">
                                <div class="x_panel" style="padding-left: 5px; padding-right: 5px;">
                                    <div class="x_title" style="margin-bottom: 3px;">
                                        <label>Filter</label>
                                        <ul class="nav navbar-right panel_toolbox">
                                            <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                            </li>

                                            <%-- <li><a class="close-link"><i class="fa fa-close"></i></a>
                      </li>--%>
                                        </ul>


                                        <div class="clearfix"></div>

                                        <div class="clearfix"></div>
                                    </div>
                                    <div class="x_content">


                                        

                                        <section class="content invoice">
                                            <div class="col-md-12 col-sm-6 col-xs-12 form-group has-feedback">

                                                <div class="col-md-2 col-sm-6 col-xs-12 form-group" id="divfrmdte">
                                                    <input type="text" placeholder="From Date" id="txtSearchFromDate" class="form-control has-feedback-left" style="padding-right: 10px;" />
                                                    <span aria-hidden="true" class="fa fa-calendar form-control-feedback left"></span>
                                                </div>
                                                <div class="col-md-2 col-sm-6 col-xs-12 form-group" id="divtodate">
                                                    <input type="text" placeholder="To Date" id="txtSearchToDate" class="form-control has-feedback-left" style="padding-right: 10px;" />
                                                    <span aria-hidden="true" class="fa fa-calendar form-control-feedback left"></span>
                                                </div>

                                               <%-- <div class="col-md-2 col-sm-6 col-xs-12 form-group has-feedback" id="divshowSles1">
                                                    <div id="">
                                                        <select id="comboLocationInReport" style="text-indent: 25px; padding-right: 5px;" class="form-control" onchange="javascript:showTransactions(1);" runat="server">
                                                           
                                                        </select>
                                                    </div>
                                                    <span aria-hidden="true" class="fa fa-users form-control-feedback left"></span>
                                                </div>--%>

                                                <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback" id="divshowSles">
                                                    <div id="showsalesmansInReport">
                                                        <select id="comboSalesInReport" style="text-indent: 25px; padding-right: 5px;" class="form-control" onchange="javascript:showTransactions(1);" runat="server">
                                                            
                                                        </select>
                                                    </div>
                                                    <span aria-hidden="true" class="fa fa-users form-control-feedback left"></span>
                                                </div>

                                                <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback" id="div1">
                                                    <div id="Div2">
                                                        <select id="selWarehouse" style="text-indent: 25px; padding-right: 5px;" class="form-control" onchange="javascript:showTransactions(1);" runat="server">
                                                        </select>
                                                    </div>
                                                    <span aria-hidden="true" class="fa fa-users form-control-feedback left"></span>
                                                </div>
                                                
                                <div class="col-md-5 col-sm-6 col-xs-12 form-group has-feedback">
                                    
                                    <input type="text" class="form-control has-feedback-left" id="customerNames" placeholder="Search Suppliers" />
                                    <span class="fa fa-search form-control-feedback left" aria-hidden="true">
                                    </span>
                                    
                                </div>

<div class="col-md-1 col-sm-6 col-xs-12 form-group has-feedback">
<%--<div class="pull-left" style="font-size: 20px;" data-toggle="modal" data-target="#popupcustomer" onclick="javascript:resetcustomerdata();">
                                        <label class="fa fa-user" style="cursor: pointer;"></label>
                                        <label class="fa fa-search" style="cursor: pointer; font-size: 20px; color: #ff6a00; position: relative; margin-left: -12px;"></label>
                                    </div>--%>


    <div class="container">

                                        <!-- Trigger the modal with a button -->
                                        <%--  <button >Open Modal</button>--%>

                                        <!-- Modal -->
                                        <div class="modal fade" id="popupcustomer" role="dialog">
                                            <div class="modal-dialog modal-lg" style="">

                                                <!-- Modal content-->
                                                <div class="modal-content">
                                                    <div class="modal-header">
                                                        <button type="button" class="close" onclick="javascript:popupclose('popupcustomer');">&times;</button>
                                                        <div class="col-md-7 col-sm-6 col-xs-8">
                                                            <h4 class="modal-title">Customers</h4>
                                                        </div>
                                                         <div class="col-md-4 col-sm-12 col-xs-12">
                                                           

                                                                <div class="col-md-10 col-sm-12 col-xs-12">
                                                                      <button class="btn btn-primary mybtnstyl" type="button" style="float:right;" onclick="javascript:searchOrderCustomers();">
                                                                        <li class="fa fa-refresh" style="margin-right: 5px;"></li>
                                                                        Reset
                                                                    </button>
                                                                   <%-- <button type="button" class="btn btn-success mybtnstyl" style="float:right;"  onclick="javascript:searchCustomersCheck(1);">
                                                                        <li class="fa fa-search" style="margin-right: 5px;"></li>
                                                                        Search
                                                                    </button>--%>
                                                              
                                                                  
                                                                </div>
                                                                  <div class="col-md-2 col-sm-12 col-xs-3">
                                                                    <select id="txtpageno" onchange="javascript:searchCustomersCheck(1);"  name="datatable-checkbox_length" aria-controls="datatable-checkbox" class=" input-sm">
                                                                        <option value="25">25</option>
                                                                        <option value="50">50</option>
                                                                        <option value="100">100</option>
                                                                        <option value="250">250</option>
                                                                        <option value="500">500</option>
                                                                    </select>
                                                                </div>
                                                            </div>
                                                    </div>
                                                    <div class="col-md-12 col-sm-12 col-xs-12" style="overflow-x: auto;">
                                                        <div class="x_content">

                                                            <table id="TBLshowSearchMembers" class="table table-striped table-bordered" style="table-layout: auto;">
                                                                <thead>
                                                                    <tr>
                                                                        <th>ID</th>
                                                                        <th>Name</th>
                                                                       <%-- <th>Type	</th>--%>
                                                                        <th>Phone</th>
                                                                        <th>Outstanding</th>

                                                                    </tr>


                                                                    <tr>
                                                                        <td>
                                                                            <input type="text" class="form-control" id="searchvalContent1" style="width: 80px; padding-right: 2px;" /></td>
                                                                        <td>
                                                                            <input type="text" id="searchvalContent2" class="form-control" /></td>
                                                                        <%--<td>
                                                                            <select id="combopricegroupdiv" class="form-control" runat="server">
                                                                               
                                                                            </select>

                                                                        </td>--%>
                                                                        <td>
                                                                            <input type="text" class="form-control" id="searchvalContent3" style="width: 120px; padding-right: 2px;" /></td>
                                                                        <td>
                                                                            <input type="text" class="form-control" id="searchvalContent4" style="width: 100px; padding-right: 2px;" /></td>

                                                                    </tr>
                                                                </thead>
                                                                <tbody>
                                                                    

                                                                </tbody>
                                                            </table>
                                                        </div>
                                                    </div>
                                                    <div class="clearfix"></div>
                                                </div>

                                            </div>
                                        </div>

                                    </div>

    </div>


                                                <div class="col-md-2 col-sm-6 col-xs-12 form-group">
                                                    <button id="btnreset" style="font-size: 11px; padding: 4px; font-weight: bold;" class="btn btn-primary pull-right" type="button" onclick="javascript:resetFilter();">
                                                        <li style="margin-right: 5px;" class="fa fa-refresh"></li>
                                                        Reset 
                                                    </button>

                                                    <button id="btnsearch" style="font-size: 11px; padding: 4px; font-weight: bold;" class="btn btn-success pull-right" type="button" onclick="javascript:showTransactions(1);">
                                                        <li style="margin-right: 5px;" class="fa fa-search"></li>
                                                        Search 
                                                    </button>

                                                </div>
                                            </div>

                                            

                                            <div class="row">

                                                <!-- /.col -->
                                            </div>
                                            <!-- info row -->
                                            
                                            <!-- /.row -->




                                            <div class="col-md-12 col-sm-12 col-xs-12" style="overflow-x: auto;">
                                                <div class="x_content">

                                                    <hr />
                                                    
                                                    <a name="chapter0"></a>
                                                    <h4 style="color:#3176c3"><span class="label label-primary" id="lbl_paycnt">0</span> PAYMENTS AGAINST PURCHASES <small><b>(Cash/Cheque/Wallet payments made directly to purchases)</b></small>
                                                        <a><span class="label label-info btn" id="" onclick="DownloadExcel(1)">Download Excel</span></a>
                                                        <br /><br />
                                                       <span class="label label-success" id="lbl_paycnt0">0</span>  <span class="label label-primary" id="lbl_paycnt1">0</span> <span class="label label-primary" id="lbl_paycnt2">0</span> <span class="label label-warning" id="lbl_paycnt3">0</span>
                                                    </h4>
                                                    
                                                    <table id="tblTransactions_paid" class="table table-striped jambo_table bulk_action" style="table-layout: auto;">
                                                        <thead style="background-color:#f1eeee;color:#525252">

                                                            <tr>
                                                                <th>Sl No.</th>                                                                
                                                                <%--<th>Route</th>--%>
                                                                <th>Supplier Name</th>
                                                                <th>Date</th>
                                                                <th>User</th>
                                                                <th>Invoice Details</th>
                                                                <th>Cash</th>
                                                                <th>Cheque</th>
                                                                <th>Wallet</th>
                                                                <th>Net Payment</th>
                                                                
                                                            </tr>
                                                        </thead>
                                                        <tbody>
                                                        </tbody>
                                                    </table>

                                                    <a name="chapter1"></a>
                                                    <hr />
                                                                                                                                                          


                                                </div>

                                            </div>

                                        </section>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="clearfix"></div>
                    
                        <div class="col-md-9 col-sm-12 col-xs-12" style="margin-top: 10px;display:none;" id="divSumry">
                                                    <label style="font-weight: bold; font-size: 14px;color:#3176c3">Collection Summary</label>
                                                    <div class="table-responsive" style="font-weight: bold;" id="SummaryReportDiv">
                                                        <table class="table">
                                                            <tbody>
                                                                
                                                            </tbody>
                                                        </table>
                                                    </div>
                                                </div>
                          
                          <div class="clearfix"></div>
                        

                    </div>
                </div>
                <!-- /page content -->

            </div>
            <!<!-- footer content -->
            <footer>
                <div class="pull-right">
                    <div class="footerDiv">
                        <div class="footerDivContent">
                            Copyright 2017 ©
                        </div>
                    </div>
                </div>
                <div class="clearfix"></div>
            </footer>
            <!-- /footer content -->
        </div>
    </div>
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
