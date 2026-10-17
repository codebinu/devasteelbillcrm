<%@ Page Language="C#" AutoEventWireup="true" CodeFile="editoldorderentry.aspx.cs" Inherits="web_sales_editoldorderentry" %>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Edit - Old Order Entry  | Invoice Me</title>

   <script src="../js/common.js" type="text/javascript"></script>
    <script type="text/javascript" src="../js/jquery-2.0.3.js"></script>

    <script type="text/javascript" src="../js/jquery.cookie.js"></script>
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



    <script type="text/javascript">
        var sessionId = 0;
        var order_branch_id = 0;
        var orderId = "";
        var orderObj;
        var lastUpdatedDate = "";

        $(document).ready(function () {
            sessionId = getSessionID();
            var BranchId = $.cookie("invntrystaffBranchId");
            var CountryId = $.cookie("invntrystaffCountryId");
            if (!BranchId) {
                location.href = "../dashboard.aspx";
                return false;
            }
            if (!CountryId) {
                location.href = "../dashboard.aspx";
                return false;
            }


            clearform();
            showWarehouses();
            orderId = getQueryString("orderId");
            if (getQueryString("orderId") != undefined && getQueryString("orderId") != "") {
                selectOrderInfo(orderId);
            }

            else {
                window.location.href = "../web_sales/orders.aspx";
            }


            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " © ");

            var yyyy = new Date().getFullYear();
            var dd = new Date().getDate();
            var mm = new Date().getMonth() + 1;
            var curr_date = new Date().getDate();
            $('#textOrderDate').scroller({
                preset: 'date',
                maxDate: new Date(yyyy + ',' + mm + ',' + dd),
                setText: 'Select',
                invalid: {},
                theme: 'ios',
                display: 'modal',
                mode: 'scroller',
                //dateFormat :'yy/mm/dd'
                dateFormat: 'yy-mm-dd'
            });

            $('#txt_chq_date').scroller({
                preset: 'date',
                endYear: yyyy + 100,
                setText: 'Next',
                invalid: {},
                theme: 'ios',
                display: 'modal',
                mode: 'scroller',
                //dateFormat :'yy-mm-dd'
                //dateFormat: 'yyyy-mm-dd'
                dateFormat: 'dd-mm-yy'
            });

            $('#txt_trans_date').scroller({
                preset: 'date',
                endYear: yyyy + 100,
                setText: 'Next',
                invalid: {},
                theme: 'ios',
                display: 'modal',
                mode: 'scroller',
                //dateFormat :'yy-mm-dd'
                //dateFormat: 'yyyy-mm-dd'
                dateFormat: 'dd-mm-yy'
            });

            // $('.headbtn').corner("10px");txt_trans_date
        });

        //Start:TO Replace single quotes with double quotes
        function sqlInjection() {
            $('input, select, textarea').each(
                function (index) {
                    var input = $(this);
                    var type = this.type ? this.type : this.nodeName.toLowerCase();

                    if (type == "text" || type == "textarea") {

                        $("#" + input.attr('id')).val(input.val().replace(/'/g, '"'));
                    } else { }
                }
            );
        }

        //function to calculate changes in payment -
        function calcPaymentEditForm() {
            var cash_amt = isNaN(parseFloat($("#txtCashAmt").val())) ? 0 : parseFloat($("#txtCashAmt").val());
            var wallet_amt = isNaN(parseFloat($("#txtWalletAmt").val())) ? 0 : parseFloat($("#txtWalletAmt").val());
            var cheque_amt = isNaN(parseFloat($("#txtChequeAmt").val())) ? 0 : parseFloat($("#txtChequeAmt").val());
            $("#txtTotalAmount").text(cash_amt + wallet_amt + cheque_amt);
        }

        //start create session Id
        function getSessionID() {

            var now = new Date();
            var year = now.getFullYear();
            var month = now.getMonth() + 1;
            var day = now.getDate();
            var hour = now.getHours();
            var minute = now.getMinutes();
            var second = now.getSeconds();
            if (month.toString().length == 1) {
                var month = '0' + month;
            }
            if (day.toString().length == 1) {
                var day = '0' + day;
            }
            if (hour.toString().length == 1) {
                var hour = '0' + hour;
            }
            if (minute.toString().length == 1) {
                var minute = '0' + minute;
            }
            if (second.toString().length == 1) {
                var second = '0' + second;
            }

            var salesman_id = $.cookie("invntrystaffBranchId");

            sessionId = String(year) + String(month) + String(day) + String(hour) + String(minute) + String(second) + String(salesman_id);
            return sessionId;
            //alert(sessionId);
        }
        //end create session Id

        function showWarehouses() {
            loading();
            $.ajax({
                type: "POST",
                url: "oldorderentry.aspx/warehouseName",
                data: "{'branchid':'" + $.cookie("invntrystaffBranchId") + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    // alert(msg.d);
                    Unloading();
                    var obj = JSON.parse(msg.d);
                    console.log(obj[0]["branch_name"]);
                    $("#lblbranchname").text(obj[0]["branch_name"]);

                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }

        function selectOrderInfo(orderId) {
            console.log(orderId);
            loading();

            $.ajax({
                type: "POST",
                url: "editoldorderentry.aspx/selectOrderdata",
                data: "{'sm_id':'" + orderId + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d == "N") {
                        alert("No Data Found");                       
                        return;
                    } else {

                        var obj = JSON.parse(msg.d);
                       
                        var yyyy = new Date().getFullYear();
                        var dd = new Date().getDate();
                        var mm = new Date().getMonth() + 1;
                        
                        //$('#textOrderDate').scroller({
                        //    preset: 'date',
                        //    maxDate: new Date(yyyy + ',' + mm + ',' + dd),
                        //    setText: 'Select',
                        //    invalid: {},
                        //    theme: 'ios',
                        //    display: 'modal',
                        //    mode: 'scroller',
                        //    //dateFormat :'yy/mm/dd'
                        //    dateFormat: 'yy-mm-dd'
                        //});

                        selectCustomer(obj.data[0].cust_id);

                        $("#textOrderDate").val(obj.data[0].sm_date);
                        //var itm_name = obj.data[0].itm_name;
                        var invoice_id = (obj.data[0].itm_name.split("#"))[0];
                        $("#txtinvoiceno").val(invoice_id);
                        $("#textNetamt").val(obj.data[0].sm_netamount);
                        $("#txtspecialnote").val(obj.data[0].sm_specialnote);
                        order_branch_id = obj.data[0].branch_id;
                        selectOrders();
                    }

                },
                error: function (xhr, status) {
                    Unloading();
                    console.log(xhr);
                    console.log(status);
                    var msgObj = JSON.parse(xhr.responseJSON.d);
                    alert(msgObj.message);
                }
            });



        }

        function dateformat(idate) {

            var med = idate.split("-");
            var dd = med[0];
            var mm = med[1];
            var yy = med[2];

            var nDate = yy + '-' + mm + '-' + dd;
            return nDate;

        }
     

        function saveOldOrderDetails() {
            if ($("#txtinvoiceno").val() == "") {
                alert("Enter Invoice Number");
                $("#txtinvoiceno").focus();
                return false;
            }
            //if (isNaN($("#txtinvoiceno").val())) {
            //    alert("Phone1 should be in number only...!");
            //    return false;
            //}

            $("#txtinvoiceno").val($("#txtinvoiceno").val().replace(/[#]+/g, ''));

            if ($("#textOrderDate").val() == "") {
                alert("Choose Order date");
                $("#textOrderDate").focus();
                return false;
            }
            if ($("#textNetamt").val() == "0") {
                alert("Enter net amount");
                $("#textNetamt").focus();
                return false;
            }
            if (isNaN($("#textNetamt").val())) {
                alert("Net amount should be in number only...!");
                return false;
            }
            //if ($("#txtBalanceamt").val() == "") {
            //    alert("Enter balance amount");
            //    $("#txtBalanceamt").focus();
            //    return false;
            //}
            //if (isNaN($("#txtBalanceamt").val())) {
            //    alert("Balance amount should be in number only...!");
            //    return false;
            //}
            //if (parseFloat($("#txtBalanceamt").val()) > parseFloat($("#textNetamt").val())) {
            //    alert("Balance amount greater than net amount!");
            //    return false;
            //}

            var postObj = {

                editedorder: {

                    sm_id: orderId,
                    order_branch_id: order_branch_id,
                    invoice_id: $.trim($("#txtinvoiceno").val()),
                    user_id: $.cookie("invntrystaffId"),
                    time_zone: $.cookie("invntryTimeZone"),
                    sm_netamount: $("#textNetamt").val(),
                    sm_date: $("#textOrderDate").val(),
                    sm_specialnote: $("#txtspecialnote").val()
                }
            };

            loading();
            $.ajax({
                type: "POST",
                url: "editoldorderentry.aspx/saveOldEntryToSalesMaster",
                data: JSON.stringify(postObj),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();

                    var obj = JSON.parse(msg.d);
                    if (obj.result == "SUCCESS" || obj.result == "EXIST") {

                        alert("Old order updated Sccessfully!");
                        window.location.reload();

                    }
                    else if (obj.result == "REPEAT") { alert("This invoice already exists in the database!"); }
                    else { alert("An error occured in the server! Please try again."); }
                },
                error: function (xhr, status) {
                    Unloading();
                    console.log(xhr);
                    console.log(status);
                    var msgObj = JSON.parse(xhr.responseJSON.d);
                    alert(msgObj.message);
                }
            });
            //alert("");
        }

        function clearform() {
            $("#txtinvoiceno").val("");
            $("#textOrderDate").val("");
            $("#txtBalanceamt").val(0);
            $("#textNetamt").val(0);
        }

        function selectCustomer(customerId) {
            console.log(customerId);
            loading();

            $.ajax({
                type: "POST",
                url: "oldorderentry.aspx/selectCustomerdata",
                data: "{'customerid':" + customerId + "}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d != "N") {
                        var obj = JSON.parse(msg.d);
                        console.log(obj[0].cust_name);
                        $("#dupMemberId").text(customerId);
                        $("#txtMemberId").text(customerId);
                        $("#txtMemberName").text(obj[0].cust_name);

                        $("#customerType").val(obj[0].cust_type);
                        console.log(obj[0].cust_amount);

                        if (obj[0].cust_amount == null || obj[0].cust_amount == "") {
                            obj[0].cust_amount = 0;
                        }

                        $("#txtoutstanding").text(obj[0].cust_amount);
                        if (obj[0].cust_amount > 0) {
                            $("#txtoutstanding").css("color", "red");
                            exactwalletamt = 0;
                        } else {
                            $("#txtoutstanding").css("color", "green");
                        }

                        $("#selcustomertype").val(obj[0].new_custtype);
                        if (obj[0].cust_type == 1) {
                            $("#txtcustomertype").text("A");
                        } else if (obj[0].cust_type == 2) {
                            $("#txtcustomertype").text("B");
                        } else if (obj[0].cust_type == 3) {
                            $("#txtcustomertype").text("C");
                        }
                        $("#txtcreditamount").text(obj[0].max_creditamt);
                        $("#txtcreditperiod").text(obj[0].max_creditperiod);

                        $("#txtnewcreditamt").val(obj[0].new_creditamt);
                        $("#txtnewcreditperiod").val(obj[0].new_creditperiod);
                    } else {
                        alert("No data found");
                    }

                },
                error: function (xhr, status) {
                    Unloading();
                    console.log(xhr);
                    console.log(status);
                    var msgObj = JSON.parse(xhr.responseJSON.d);
                    alert(msgObj.message);
                }
            });



        }

        function selectOrders() {
            loading();

            $.ajax({
                type: "POST",
                url: "editorder.aspx/selectOrders",
                data: "{'billno':'" + orderId + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    orderObj = JSON.parse(msg.d);

                    var order_details = orderObj.order[0];
                    lastUpdatedDate = order_details.lastUpdatedDate;

                    //setting payments
                    $("#tblPayments > tbody").html("");
                    $.each(orderObj.payments, function (i, row) {
                        console.log(row);
                        var htmPaymentDetails = '<tr>';
                        htmPaymentDetails += '<td>#' + row.id + '</td>';
                        htmPaymentDetails += '<td>' + row.date + '</td>';
                        htmPaymentDetails += '<td>' + row.narration + '</td>';
                        htmPaymentDetails += '<td>' + row.voucher_no + '</td>';
                        htmPaymentDetails += '<td>' + row.po_number + '</td>';
                        htmPaymentDetails += '<td>' + row.user_name + '</td>';
                        htmPaymentDetails += '<td><b>' + (row.dr != 0 ? row.dr + " Dr" : (row.cr != 0 ? row.cr + " Cr" : 0)) + '</b></td>';
                        htmPaymentDetails += '<td align="center">' +
                            '<div onclick="showTransactionDetails(' + row.id + ')" class="btn btn-primary btn-xs"><li class="fa fa-eye" style="font-size:large;"></li></div>' +
                            ((row.is_reconciliation == 0 && row.cr != 0) ? '<div onclick="showTransactionEdit(' + row.id + ')" class="btn btn-primary btn-xs"><li class="fa fa-pencil" style="font-size:large;"></li></div>' : '') +
                            '</td>';
                        htmPaymentDetails += '</tr>';

                        $("#tblPayments > tbody").append(htmPaymentDetails);
                    });

                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }

        //function to show popup for editing transaction
        function showTransactionEdit(trans_id) {
            var transaction = orderObj.payments.find(x => x.id == trans_id);
            $("#lblTransRefEdit").text(transaction.id);
            $("#txtTotalAmount").text(transaction.cr);
            $("#txtCashAmt").val(transaction.cash_amt);
            $("#txtWalletAmt").val(transaction.wallet_amt);
            $("#txtChequeAmt").val(transaction.cheque_amt);
            //if(transaction.cheque_amt == 0){ $("#txtChequeAmt").attr("disabled", "disabled");  }
            //else{$("#txtChequeAmt").removeAttr("disabled"); }
            $("#popupTransactionEdit").modal('show');

            $("#Span1").text(transaction.id);
            $("#Span2").text((transaction.dr != 0 ? "Debit" : "Credit"));
            $("#Span3").text(transaction.date);
            $("#Span4").text(transaction.user_name);

            $("#txt_chq_no").val(transaction.cheque_no);
            $("#txt_chq_date").val(transaction.cheque_date);
            $("#txt_bank_name").val(transaction.cheque_bank);

            $("#txtVoucherNo").val(transaction.voucher_no);
            $("#txtPONumber").val(transaction.po_number);

            $("#txt_trans_date").val(transaction.formatted_date);

            //if(transaction.cash_amt != 0 && transaction.is_reconciliation !=1 ){ $("#cash_edit_row").show(); } else{$("#cash_edit_row").hide();}
            //if(transaction.cheque_amt != 0){ $("#cheque_edit_row").show(); } else{$("#cheque_edit_row").hide();}
            //if(transaction.wallet_amt != 0){ $("#wallet_edit_row").show(); } else{$("#wallet_edit_row").hide();} txt_trans_date


        }

        //function to save payment edit
        function savePaymentEdit() {

            sqlInjection();
            if (isNaN(parseFloat($("#txtChequeAmt").val())) || $("#txtChequeAmt").val() == "0") {
            }
            else {
                if ($("#txt_chq_no").val() == "") {
                    alert("Enter the Cheque Number!"); return;
                }

                if ($("#txt_chq_date").val() == "") {
                    alert("Enter the Cheque Date!"); return;
                }

                if ($("#txt_bank_name").val() == "") {
                    alert("Enter the Cheque Bank!"); return;
                }
            }

            var postObj = {
                trans_id: $("#lblTransRefEdit").text(),
                cash_amt: isNaN(parseFloat($("#txtCashAmt").val())) ? 0 : parseFloat($("#txtCashAmt").val()),
                cheque_amt: isNaN(parseFloat($("#txtChequeAmt").val())) ? 0 : parseFloat($("#txtChequeAmt").val()),
                wallet_amt: isNaN(parseFloat($("#txtWalletAmt").val())) ? 0 : parseFloat($("#txtWalletAmt").val()),
                cheque_no: $("#txt_chq_no").val(),
                cheque_date: dateformat($("#txt_chq_date").val()),
                cheque_bank: $("#txt_bank_name").val(),
                lastUpdatedDate: lastUpdatedDate,
                billNo: orderId,
                voucher: $("#txtVoucherNo").val(),
                ponumber: $("#txtPONumber").val(),
                trans_date: dateformat($("#txt_trans_date").val())
            }

            loading();
            $.ajax({
                type: "POST",
                url: "editorder.aspx/savePaymentEdit",
                data: JSON.stringify(postObj),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    if (msg.d == "N") {
                        alert("Error..");
                    }
                    else if (msg.d == "INSUFFICIENTWALLET") {

                        alert("The Customer is not having the required Wallet Credit to be increased!");
                    }
                    //else if(msg.d=="WALLETEXCEED"){

                    //    alert("Wallet Amount Cannot be higher than Initial Wallet Payment. It can only be reduced!");
                    //}
                    else if (msg.d == "E") {
                        var result = confirm("Some One already changed the page..Do you want to reload and continue ?");
                        if (result) {
                            window.location.reload();
                        } else {
                            return;
                        }
                    } else {
                        alert("Payment edited succesfully..");
                        $('#popupTransactionEdit').modal('hide');
                        window.location.reload();
                        return;
                    }
                },
                error: function (xhr, status) {
                    Unloading();
                    console.log(xhr);
                    alert("error");
                }
            });
        }

    </script>

    <%-- <style type="text/css">
        /*for pagination start here*/

        #loading1 {
            width: 100%;
            height: 100%;
            top: 0px;
            left: 0px;
            position: fixed;
            display: block;
            opacity: 0.7;
            background-color: #fff;
            z-index: 99;
            text-align: center;
        }

        #loading-image1 {
            margin-top: 230px;
        }
    </style>
    <style type="text/css">
        .headbtn {
            background: url(../images/headbtn.png);
            border: 1px solid #707070;
            width: 140px;
            height: 20px;
            /*position:absolute; */
            margin-top: -20px;
        }

        .headbtnfont {
            width: 140px;
            height: 27px;
            text-align: center;
            color: #252525;
            line-height: 18px;
            font-size: 12px;
            font-weight: bold;
        }

        .blink {
            animation: blink-animation 1s steps(5, start) infinite;
            -webkit-animation: blink-animation 1s steps(5, start) infinite;
        }

        @keyframes blink-animation {
            to {
                visibility: hidden;
            }
        }

        @-webkit-keyframes blink-animation {
            to {
                visibility: hidden;
            }
        }

        .error {
            border: solid 2px #FF0000;
        }

        input[type=search] {
            background: none;
            font-weight: bold;
            border-color: #aaaaaa;
            border-style: solid;
            border-width: 1px;
            outline: none;
            padding: 1px 2px 1px 2px;
            width: 50px;
        }

        /*ul.ui-autocomplete {
            color: black !important;
            -moz-border-radius: 15px;
            border-radius: 15px;
        }*/

        /*tooltip style*/
        .autoSugest {
            background: #fffdef;
            border: 1px solid #cac6ad;
            -webkit-border-radius: 4px;
            -moz-border-radius: 4px;
            border-radius: 4px;
            color: #7f7943;
            display: none;
            font-size: 12px;
            padding: 7px 15px;
            position: absolute;
            min-width: 100px;
            -o-box-sizing: border-box;
            -ms-box-sizing: border-box;
            -webkit-box-sizing: border-box;
            -moz-box-sizing: border-box;
            box-sizing: border-box;
        }

            .autoSugest:after {
                content: "";
                border-left: solid 10px transparent;
                border-right: solid 10px transparent;
                border-bottom: solid 10px #cac6ad;
                position: absolute;
                top: -11px;
                left: 12px;
            }
    </style>--%>
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
                                <label style="font-weight: bold; font-size: 16px;">Edit Old Order Entry</label>

                            </div>

                        </nav>
                    </div>
            </div>
            <!-- /top navigation -->

            <!-- page content -->
            <div class="right_col" role="main">

                <div class="page-title">

                    <%--<div class="title_left">
                        <label style="font-size: 16px; font-weight: bold;">Old Order Entry</label>
                    </div>--%>
                    <div class="title_right" style="text-align:right;float:right">
                        <label>Warehouse:</label>
                        <label id="lblbranchname">Kerala</label>
                    </div>


                </div>
                <div class="clearfix"></div>

                <div class="row">
                    <div class="col-md-12 col-sm-12 col-xs-12">
                        <div class="x_panel">
                            <div class="x_title" style="margin-bottom: 0px;">
                                <label class="pull-left">Customer Details </label>

                                <%--<ul class="nav navbar-right panel_toolbox pull-right">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                        </li>
                                        <li class="dropdown">
                                            <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false"><i class="fa fa-wrench"></i></a>

                                        </li>
                                        <li><a class="close-link"><i class="fa fa-close"></i></a>
                                        </li>
                                    </ul>--%>

                                <div class="clearfix"></div>
                            </div>
                            <div class="x_content">
                                <!-- info row -->
                                <div class="row invoice-info">
                                    <div class="col-sm-4 invoice-col">
                                        <b>ID:
                                                <label id="dupMemberId" style="display: none;"></label>
                                            <label id="txtMemberId">#007612</label>
                                        </b>
                                        <br />
                                        <b>Name:</b><label id="txtMemberName">Istanbul Supermarket Ajman</label>

                                    </div>
                                    <!-- /.col -->
                                    <div class="col-sm-2 invoice-col">
                                        <b>Credit Amount</b>
                                        <label id="txtcreditamount">1000</label>
                                        <br />
                                       <%-- <b>Wallet Amount:</b><label id="lblwalletamt" style="color: #40c863;">0</label>--%>
                                    </div>
                                    <!-- /.col -->

                                    <div class="col-sm-2 invoice-col">
                                        <b>Credit Period:</b>
                                        <label id="txtcreditperiod">50 Days</label>
                                        <br />
                                        <b>Account Balance:</b><label id="txtoutstanding" style="color: #432727; font-size: 14px; font-weight: bold; color: red;">0</label>
                                    </div>
                                    <!-- /.col -->
                                    <div class="col-sm-2 invoice-col">
                                        <b>Class:</b><label id="txtcustomertype"></label>

                                    </div>


                                    <!-- /.col -->
                                </div>
                                <!-- /.row -->
                            </div>
                            <div class="clear"></div>

                        </div>
                    </div>
                    <div class="clearfix"></div>
                    <div class="col-md-12 col-sm-12 col-xs-12">
                        <div class="x_panel">
                            <div class="x_title">
                                <label>Order Details</label>
                                <ul class="nav navbar-right panel_toolbox">
                                    <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                    </li>
                                    <%--<li class="dropdown">
                                            <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false"><i class="fa fa-wrench"></i></a>

                                        </li>--%>
                                    <%--<li><a class="close-link"><i class="fa fa-close"></i></a>
                                        </li>--%>
                                </ul>
                                <div class="clearfix"></div>

                            </div>
                            <div class="x_content">
                                <form id="Form2" data-parsley-validate class="form-horizontal form-label-left">

                                    <div class="form-group">
                                        <label class="control-label col-md-3 col-sm-3 col-xs-12" for="first-name">
                                            Invoice No<span class="required">*</span>
                                        </label>
                                        <div class="col-md-6 col-sm-6 col-xs-12">
                                            <input id="txtinvoiceno" value="" required="required" class="form-control col-md-7 col-xs-12" type="text" placeholder="Enter invoice number">
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <label class="control-label col-md-3 col-sm-3 col-xs-12" for="first-name">
                                            Order Date <span class="required">*</span>
                                        </label>
                                        <div class="col-md-6 col-sm-6 col-xs-12">
                                            <input type="text" id="textOrderDate" required="required" class="form-control col-md-7 col-xs-12" />
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <label class="control-label col-md-3 col-sm-3 col-xs-12" for="last-name">
                                            Net Amount<span class="required">*</span>
                                        </label>
                                        <div class="col-md-6 col-sm-6 col-xs-12">
                                            <input type="text" id="textNetamt" name="last-name" required="required" class="form-control col-md-7 col-xs-12" />
                                        </div>
                                    </div>
                                    <%--<div class="form-group">
                                        <label class="control-label col-md-3 col-sm-3 col-xs-12" for="first-name">
                                            Balance amount <span class="required">*</span>
                                        </label>
                                        <div class="col-md-6 col-sm-6 col-xs-12">
                                            <input type="text" id="txtBalanceamt" required="required" class="form-control col-md-7 col-xs-12" disabled="disabled" />
                                        </div>
                                    </div>--%>
                                    <div class="form-group">
                                        <label class="control-label col-md-3 col-sm-3 col-xs-12" for="first-name">
                                            Special Note 
                                        </label>
                                        <div class="col-md-6 col-sm-6 col-xs-12">
                                            <textarea id="txtspecialnote" class="form-control" rows="3" placeholder="" style="margin: 0px -0.375px 0px 0px; width: 100%; height: 109px; resize:none;"></textarea>
                                        </div>
                                    </div>
                                    <div class="col-md-8 col-sm-12 col-xs-12"></div>
                                    <div class="col-md-1 col-sm-12 col-xs-12">
                                        <button type="button" class="btn btn-primary mybtnstyl" onclick="saveOldOrderDetails();">
                                            Save
                                        </button>
                                    </div>
                                    <div class="col-md-4 col-sm-12 col-xs-12"></div>
                                </form>

                                                    
                            </div>


                        </div>
                    </div>
                    <div class="clearfix"></div>
                    <input type="hidden" id="lblTransRefEdit" value="0" />
                                                                        <div class="row">
    <div class="col-md-12">
        <div class="x_panel">
            <div class="x_title">
                <label>Transactions</label>
                <ul class="nav navbar-right panel_toolbox">
                    <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                    </li>
                </ul>
            </div>
            <div class="x_content">
                <table id="tblPayments" class="table table-striped table-bordered">
                    <thead>
                        <tr>
                            <th>Ref.</th>
                            <th>Date</th>                                                
                            <th>Narration</th>
                            <th>Voucher No.</th>
                            <th>P.O Number</th>
                            <th>User</th>
                            <th>Amount</th>
                            <th></th>

                        </tr>
                    </thead>
                    <tbody></tbody>
                </table>
            </div>
        </div>
    </div>
</div>

                                        <div class="modal fade" id="popupTransactionEdit" role="dialog">
                        <div class="modal-dialog modal-md" style="">
                            <!-- Modal content-->
                            <div class="modal-content">
                                
                                  <div class="modal-header" style="padding-bottom: 5px;">
                                    <button type="button" class="close" data-dismiss="modal">&times;</button>
                                    <div class="col-md-12 col-sm-12 col-xs-12" style="text-align:center">
                                        <h4 class="modal-title" style="color:#337ab7">Edit Transaction #<span id="Span1"></span><br /><small>[ <b><span id="Span2"></span></b> ] </small>
                                            <br />
                                            <small style="color:#525252"><b>Date :</b><span id="Span3"></span></small> | 
                                            <small style="color:#525252"><b>User :</b><span id="Span4"></span></small>
                                        </h4>
                                    </div>
                                  
                                </div>

                                <div class="x_content">
                                    <form style="background-color:#f6f6f6">
                                            <div class="col-md-12 col-sm-12 col-xs-12">
                                                <div class="form-group">
                                                    <label class="col-form-label" for="txtTotalAmount">Total Amount :</label>
                                                    <label class="" id="txtTotalAmount">0</label>
                                                    <br />
                                                     <label class="col-form-label" for="txtChequeAmt">Trasaction Date</label>
 <input class="form-control" type="text" id="txt_trans_date"" />
                                                    <hr />
                                                </div>
                                                <div class="form-group" id="cash_edit_row" style="background-color:#f6f6f6">
                                                    <label class="col-form-label" for="txtCashAmt">Cash</label>
                                                    <input class="form-control" type="number" id="txtCashAmt" onkeyup="calcPaymentEditForm()" />
                                                </div>
                                                <hr />
                                                <div class="form-group" id="cheque_edit_row" style="background-color:#f6f6f6">
                                                    <label class="col-form-label" for="txtChequeAmt">Cheque Amount</label>
                                                    <input class="form-control" type="number" id="txtChequeAmt" onkeyup="calcPaymentEditForm()" />

                                                    <label class="col-form-label" for="txtChequeAmt">Cheque Number</label>
                                                    <input class="form-control" type="text" id="txt_chq_no" onkeyup="calcPaymentEditForm()" />

                                                    <label class="col-form-label" for="txtChequeAmt">Cheque Date</label>
                                                    <input class="form-control" type="text" id="txt_chq_date" onkeyup="calcPaymentEditForm()" />

                                                    <label class="col-form-label" for="txtChequeAmt">Bank Name</label>
                                                    <input class="form-control" type="text" id="txt_bank_name" onkeyup="calcPaymentEditForm()" />
                                                </div>
                                                <hr />
                                                <div class="form-group" id="wallet_edit_row" style="background-color:#f6f6f6">
                                                    <label class="col-form-label" for="txtWalletAmt">Wallet</label>
                                                    <input class="form-control" style="background-color:#fff" type="number" id="txtWalletAmt" onkeyup="calcPaymentEditForm()" />
                                                </div>

                                                <div class="form-group" style="background-color:#f6f6f6">
    <label class="col-form-label" for="txtCashAmt">Voucher Number (Optional)</label>
    <input class="form-control" type="text" id="txtVoucherNo" />
</div>

                                                <div class="form-group" style="background-color:#f6f6f6">
    <label class="col-form-label" for="txtCashAmt">P.O Number (Optional)</label>
    <input class="form-control" type="text" id="txtPONumber" />
</div>

                                                <div class="form-group" style="text-align:center">
                                                    <div style="display:inline-block">
                                                        <div class="btn btn-default " data-dismiss="modal">Cancel</div>
                                                        <div class="btn btn-primary " onclick="savePaymentEdit()">Save</div>
                                                    </div>
                                                    
                                                </div>
                                            </div>
                                        </form>
                                </div>
                                <div class="clearfix"></div>
                                <div class="ln_solid"></div>
                            </div>

                        </div>
                    </div>

                </div>
            </div>
            <!-- /page content -->


            <!-- footer content -->
            <footer>
                <div class="pull-right">
                    <div class="footerDivContent">Copyright 2017 ©</div>

                </div>
                <div class="clearfix"></div>
            </footer>
            <!-- /footer content -->

            <!-- footer content -->
            <%--  <footer>
                <div class="pull-right">
                    <div class="footerDiv">
                        <div class="footerDivContent">
                            Copyright 2014 ©
                        </div>
                    </div>
                </div>
                <div class="clearfix"></div>
            </footer>--%>
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