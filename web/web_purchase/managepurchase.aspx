<%@ Page Language="C#" AutoEventWireup="true" CodeFile="managepurchase.aspx.cs" Inherits="web_purchase_managepurchase" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Manage Purchase  | Invoice Me</title>
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
    <%-- autosearch --%>
    <script src="../autosearch/jquery-ui.js" type="text/javascript"></script>
    <link href="../autosearch/jquery-ui.css" rel="Stylesheet" type="text/css" />
    <script src="../autosearch/jquery-ui.min.js" type="text/javascript"></script>
    <script src="../autosearch/jquery-1.12.4.js" type="text/css"></script>
    <%-- autosearch --%>

    <script type="text/javascript">
        var exactwalletamt = 0;
        var purchaseId;
        var entryObj = "";
        var status = 1;
        var accuracyNum = 2;

        $(document).ready(function () {
            purchaseId = getQueryString('purchaseId');
            //  alert(BillNo);
            //  alert(BillNo);
            if (purchaseId == undefined) {
                location.href = "listPurchaseEntries.aspx";
                return;
            }
            //console.log(location.search);
            var dt = new Date();
            var cur_dat = dt.getDate() + '-' + (dt.getMonth() + 1) + '-' + dt.getFullYear();


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
            var yyyy = new Date().getFullYear();
            var curr_date = new Date().getDate();
            $('#txtChequeDate').scroller({
                preset: 'date',
                endYear: yyyy + 100,
                setText: 'Next',
                invalid: {},
                theme: 'ios',
                display: 'modal',
                mode: 'scroller',
                dateFormat: 'yy-mm-dd'
                // dateFormat: 'dd-MM-yy'
            });
            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " ©");
            //call to select order details
            retrievePurchaseDetail();

            $('#walletPayment').change(function () {
                var currentwalletamount = parseFloat($("#lblwalletamt").text());
                var grand_netamount = parseFloat($("#txtTotalBalanceAmount").val());
                //alert(grand_netamount);
                if ($(this).is(":checked")) {
                    $("#textwalletamt").prop("disabled", false);
                    if (grand_netamount.toFixed(accuracyNum) > currentwalletamount) {
                        $("#textwalletamt").val(currentwalletamount.toFixed(accuracyNum));
                    } else {
                        $("#textwalletamt").val(grand_netamount.toFixed(accuracyNum));
                    }
                    var paidwalletamt = parseFloat($("#textwalletamt").val());
                    currentwalletamount = currentwalletamount - paidwalletamt;

                    $("#lblwalletamt").text(currentwalletamount.toFixed(accuracyNum));
                } else {
                    $("#textwalletamt").prop("disabled", true);
                    $("#textwalletamt").val(0);
                    $("#lblwalletamt").text(exactwalletamt.toFixed(accuracyNum));
                }
                paymentMethod();
            });

        });


        //start: Showing Details of selected Outsatnding Bill from Popup
        function retrievePurchaseDetail() {
            //  alert(paid);
            loading();

            $.ajax({
                type: "POST",
                url: "managepurchase.aspx/retrieveData",
                data: "{'purchaseId':'" + purchaseId + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    //$.cookie('salesreturnOrderId', BillNo, {
                    //    path: '/'
                    //});
                    entryObj = JSON.parse(msg.d);
                    console.log(entryObj);
                    var entry_details = entryObj.entry[0];

                    $("#txtPreviousPaid").text(entry_details.pm_total_paid);
                    $("#txtPreviousBalance").text(entry_details.pm_total_balance);
                    //  alert(order_details.total_balance);
                    $("#txtTotalBalanceAmount").val(entry_details.pm_total_balance);
                    $("#txtTotalAmt").text(entry_details.total_amount);
                    status=entry_details.status;
                    if(status==0){
                        $("#btnEdit").hide();
                    }else{
                        $("#btnEdit").show();
                    }
                   // alert(entry_details.status);
                    if(entry_details.status==0){
                        $("#txtLabelStatus").html('<span class="label label-default" style="margin-left: 2px; margin-right: 2px; color: #fff;">Cancelled</span>');
                    }else if(entry_details.status==1){
                        $("#txtLabelStatus").html('<span class="label label-success" style="margin-left: 2px; margin-right: 2px; color: #fff;">Completed</span>');
                    }
                    $("#txtLabelBarnch").text(entry_details.branchname);
                    $("#txtEntryRefNo").text(entry_details.pm_invoice_no);
                    $("#txtVendorName").text(entry_details.vn_name);
                    $("#txtVendorId").text(entry_details.vn_id);
                    $("#txtEntryDate").text(entry_details.date);
                    $("#txtTotalCurrentAmount").val('0');
                    $("#cbCashPayment").removeProp("checked");
                    $("#cbCardPayment").removeProp("checked");
                    $("#cbChequePayment").removeProp("checked");
                    $("#txtSpecialNote").val(entry_details.pm_note);
                    if (entry_details.vn_balance <= 0) {
                        $("#txtBalance").text(entry_details.vn_balance);
                        $("#txtBalance").css("color", "green");
                        exactwalletamt = entryObj.wallet_balance[0].available_wallet_balance;
                        $("#txtWalletBalance").text(exactwalletamt);
                        $("#lblwalletamt").text(exactwalletamt);
                    } else {
                        $("#txtBalance").text(entry_details.vn_balance);
                        $("#txtBalance").css("color", "red");
                        $("#lblwalletamt").text(0);
                    }
                    $("#lblRoundoff").text(entry_details.roundoff);
                    // showing order_items
                    $("#tbodyItems").html("");
                    $.each(entryObj.items, function (i, item) {
                        var htmItemRow = '';
                        htmItemRow += '<tr>';
                        htmItemRow += '<td>' + item.itm_code + '</td>';
                        htmItemRow += '<td>' + item.itm_name + '</td>';
                        htmItemRow += '<td>' + item.pi_qty + '</td>';
                        htmItemRow += '<td>' + item.pi_price + '</td>';
                       
                        htmItemRow += '<td>' + item.pi_total + '</td>';
                        htmItemRow += '<td>' + item.pi_discount_rate + '</td>';

                        htmItemRow += '<td>' + item.pi_discount_amount + '</td>';
                        htmItemRow += '<td>' + item.pi_item_tax + '</td>';
                        htmItemRow += '<td>' + item.pi_tax_amount + '</td>';
                        htmItemRow += '<td>' + item.pi_net_amount + '</td>';
                        htmItemRow += '<td></td>';
                        htmItemRow += '<td style="border-right:none;"></td>';
                        htmItemRow += '</tr>';
                        $("#tbodyItems").append(htmItemRow);
                    });


                    // showing payment details
                    $("#tblPaymentDetails > tbody").html("");
                    $.each(entryObj.transaction_details, function (i, row) {

                        var htmPaymentDetails = '<tr>';
                        htmPaymentDetails += '<td>#' + row.id + '</td>';
                        htmPaymentDetails += '<td>' + row.date + '</td>';
                        htmPaymentDetails += '<td>' + row.narration + '</td>';
                        htmPaymentDetails += '<td>' + row.user_name + '</td>';
                        htmPaymentDetails += '<td><b>' + (row.dr != 0 ? row.dr + " Dr" : (row.cr != 0 ? row.cr + " Cr" : 0)) + '</b></td>';
                        htmPaymentDetails += '<td><div onclick="showTransactionDetails(' + row.id + ')" class="btn btn-primary btn-xs"><li class="fa fa-eye" style="font-size:large;"></li></div></td>';
                        htmPaymentDetails += '</tr>';

                        $("#tblPaymentDetails > tbody").append(htmPaymentDetails);
                    });

                    if (parseFloat($("#txtPreviousBalance").text()) <= 0) {
                        disablepayment();

                    }
                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }
        // Stop: Showing Details of selected Outsatnding Bill from Popup

        //showing transaction details
        function showTransactionDetails(trans_id) {

            //var transaction = entryObj.transaction_details.find(x=>x.id == trans_id);
            //console.log(transaction)
            //$("#lblTransRef").text(transaction.id);
            //$("#transAmount").text((transaction.dr != 0 ? transaction.dr : transaction.cr));
            //$("#transDate").text(transaction.date);
            //$("#transType").text((transaction.dr != 0 ? "Debit" : "Credit"));
            //$("#transUserName").text(transaction.user_name);
            //$("#transNarration").text(transaction.narration);
            //$("#cashAmt").text(transaction.cash_amt);
            //$("#walletAmt").text(transaction.wallet_amt);
            //$("#chequeAmt").text(transaction.cheque_amt);
            //$("#chequeNo").text(transaction.cheque_no);
            //$("#chequeDate").text(transaction.cheque_date);
            //$("#chequeBank").text(transaction.cheque_bank);
            //$("#popupTransaction").modal('show');

            var transaction = entryObj.transaction_details.find(x=>x.id == trans_id);
            $("#lblTransRef").text(transaction.id);
            $("#transAmount").text((transaction.dr != 0 ? transaction.dr : transaction.cr));
            $("#transDate").text(transaction.date);
            $("#transType").text((transaction.dr != 0 ? "Debit" : "Credit"));
            $("#transUserName").text(transaction.user_name);
            $("#transNarration").text(transaction.narration);
            $("#cashAmt").text(transaction.cash_amt);
            $("#walletAmt").text(transaction.wallet_amt);
            $("#chequeAmt").text(transaction.cheque_amt);
            $("#chequeNo").text(transaction.cheque_no);
            $("#chequeDate").text(transaction.cheque_date);
            $("#chequeBank").text(transaction.cheque_bank);
            $("#popupTransaction").modal('show');

            if(transaction.cash_amt != 0 && transaction.is_reconciliation !=1 ){ $("#cash_row").show(); } else{$("#cash_row").hide();}
            if(transaction.cheque_amt != 0){ $("#cheque_row").show(); } else{$("#cheque_row").hide();}
            if(transaction.wallet_amt != 0){ $("#wallet_row").show(); } else{$("#wallet_row").hide();}

            if((transaction.cash_amt == 0 && transaction.cheque_amt == 0 && transaction.wallet_amt == 0 )|| (transaction.is_reconciliation == 1))
            {
                $("#tbl_payment_info").hide();
            }
            else{
               
                $("#tbl_payment_info").show();
            }

        }

        //for disabling and enabling payment method textboxes
        function paymentMethod() {
            //  alert("");
            $("#cbCashPayment").prop("disabled", false);
            $("#walletPayment").prop("disabled", false);
            $("#cbCardPayment").prop("disabled", false);
            $("#cbChequePayment").prop("disabled", false);
            $("#divsaveorder").css('pointer-events', '');
            //$("#divprintorder").css('pointer-events', '');

            if ($("#cbCashPayment").is(':checked')) {
                $("#txtCashAmount").attr("disabled", false);
                if (isNaN($('#txtCashAmount').val())) {
                    alert("Enter a valid Cash Amount");
                    $('#txtCashAmount').val(0);
                }
            } else {
                $("#txtCashAmount").attr("disabled", "disabled");
                $("#txtCashAmount").val('');
            }
            if ($("#cbCardPayment").is(':checked')) {
                $("#txtCardAmount").attr("disabled", false);
                $("#txtCardNo").attr("disabled", false);
                $("#txtCardType").attr("disabled", false);
                $("#txtCardBank").attr("disabled", false);
                if (isNaN($('#txtCardAmount').val())) {
                    alert("Enter a valid Card Amount");
                    $('#txtCardAmount').val(0);
                }
            } else {
                $("#txtCardAmount").attr("disabled", "disabled");
                $("#txtCardNo").attr("disabled", "disabled");
                $("#txtCardType").attr("disabled", "disabled");
                $("#txtCardBank").attr("disabled", "disabled");
                $("#txtCardAmount").val('');
                $("#txtCardNo").val('');
                $("#txtCardType").val('');
                $("#txtCardBank").val('');
            }
            if ($("#cbChequePayment").is(':checked')) {

                $("#txtChequeAmount").attr("disabled", false);
                $("#txtChequeNo").attr("disabled", false);
                $("#txtChequeDate").attr("disabled", false);
                $("#txtBankName").attr("disabled", false);
                if (isNaN($('#txtChequeAmount').val())) {
                    alert("Enter a valid Cheque Amount");
                    $('#txtChequeAmount').val(0);
                }
            } else {
                $("#txtChequeAmount").attr("disabled", "disabled");
                $("#txtChequeNo").attr("disabled", "disabled");
                $("#txtChequeDate").attr("disabled", "disabled");
                $("#txtBankName").attr("disabled", "disabled");
                $("#txtChequeAmount").val('');
                $("#txtChequeNo").val('');
                $("#txtChequeDate").val('');
                $("#txtBankName").val('');
            }

            //handlw wallet validations here
            //exactwalletamt
            if ($("#walletPayment").is(':checked')) {

                if (isNaN($('#textwalletamt').val())) {
                    alert("Enter a valid wallet Amount");
                    $('#textwalletamt').val(0);
                }

                var inputtedWallet = $('#textwalletamt').val();
                if (parseFloat(inputtedWallet) > parseFloat(exactwalletamt)) {

                    $('#textwalletamt').val(exactwalletamt.toFixed(accuracyNum));
                    alert("Maximum Wallet Amount is " + exactwalletamt.toFixed(accuracyNum));
                }

                /*if (isNaN(inputtedWallet))*/

            }

            calculteFromPayMethod();
        }

        // calculating total and balance from payment method values
        function calculteFromPayMethod() {

            var cashAmount = $("#txtCashAmount").val();
            //alert(cashAmount);
            if (cashAmount == "") {
                cashAmount = 0;
            }
            var cardAmount = $("#txtCardAmount").val();
            if (cardAmount == "") {
                cardAmount = 0;
            }
            var chequeAmount = $("#txtChequeAmount").val();
            if (chequeAmount == "") {
                chequeAmount = 0;
            }
            var walletamt = 0;
            if ($("#walletPayment").is(':checked')) {
                walletamt = $("#textwalletamt").val();

            } else {
                walletamt = 0;
            }
            var cashTotal = parseFloat(cashAmount) + parseFloat(cardAmount) + parseFloat(chequeAmount) + parseFloat(walletamt);

            //   alert(cashTotal);
            $('#txtTotalCurrentAmount').val(cashTotal.toFixed(2));

            var balance = parseFloat($('#txtPreviousBalance').text()) - parseFloat(cashTotal);
            // alert(balance);
            $("#txtTotalBalanceAmount").val(balance.toFixed(2));


        }

        function saveToPurchaseMaster() {
            var filters = {};
            filters.TimeZone = $.cookie("invntryTimeZone");
            //alert(TimeZone);
            // var TimeZone = 'Arabian Standard Time';
            
            filters.purchaseId = purchaseId;
            filters.invoiceNum = $("#txtEntryRefNo").text();
            filters.vendorId = $("#txtVendorId").text();
            filters.currentPaidamt = $("#txtTotalCurrentAmount").val();
            filters.currentBalance = $("#txtTotalBalanceAmount").val();
            filters.previousPaid = $("#txtPreviousPaid").text();
            if (filters.currentPaidamt == "" || parseFloat(filters.currentPaidamt) == 0) {
                alert("Please Enter Payment Amount");
                return;
            }
            var paymentmode = '';
            if ($("#cbCashPayment").is(':checked')) {
                paymentmode = "Cash";
                if ($('#txtCashAmount').val() == "" || isNaN($('#txtCashAmount').val())) {
                    alert("Enter a valid Cash Amount");
                    return;
                }

            }
            if ($("#cbCardPayment").is(':checked')) {
                paymentmode = "Card";
                if ($('#txtCardAmount').val() == "" || isNaN($('#txtCardAmount').val())) {
                    alert("Enter a valid Card Amount");
                    return;
                } else if ($('#txtCardNo').val() == "") {
                    alert("Enter Card No");
                    return;
                } else if ($('#txtCardType').val() == "") {
                    alert("Enter Card Type");
                    return;
                } else if ($('#txtCardBank').val() == "") {
                    alert("Enter Card Bank");
                    return;
                }
            }
            if ($("#cbChequePayment").is(':checked')) {
                paymentmode = "Cheque";
                if ($('#txtChequeAmount').val() == "" || isNaN($('#txtChequeAmount').val())) {
                    alert("Enter a valid Cheque Amount");
                    return;
                } else if ($('#txtChequeNo').val() == "") {
                    alert("Enter Cheque No");
                    return;
                } else if ($('#txtChequeDate').val() == "") {
                    alert("Enter Cheque Date");
                    return;
                } else if ($('#txtBankName').val() == "") {
                    alert("Enter Bank Name");
                    return;
                }
            }
            if ($("#walletPayment").is(':checked')) {
                paymentmode = "wallet";
            }
            if (paymentmode == '') {
                alert("Please Select your Payment Method");
                return;
            }

            filters.UserId = $.cookie('invntrystaffId');
            filters.SpecialNote = $("#txtSpecialNote").val();
            filters.BankName = $("#txtBankName").val();
            filters.ChequeDate = $("#txtChequeDate").val();
            filters.ChequeNo = $("#txtChequeNo").val();
            filters.ChequeAmount = $("#txtChequeAmount").val();
            filters.walletamt = $("#textwalletamt").val();
            //filters.CardType = $("#txtCardType").val();
            //filters.CardBank = $("#txtCardBank").val();
            //filters.CardNo = $("#txtCardNo").val();
            //filters.CardAmount = $("#txtCardAmount").val();
            filters.CashAmount = $("#txtCashAmount").val();
            //if (filters.CardAmount == '') {
            //    filters.CardAmount = 0;
            //}
            if (filters.CashAmount == '') {
                filters.CashAmount = 0;
            }
            if (filters.ChequeAmount == '') {
                filters.ChequeAmount = 0;
            }
            var creditamount = 0;
            //if (parseFloat(filters.currentBalance) < 0) {
            //    creditamount = parseFloat(-filters.currentBalance);
            //    var confirmVal = confirm("Do you want to add the excess amount " + creditamount + " in to your wallet?");
            //    if (confirmVal == true) {
            //        creditamount = creditamount;
            //    } else {
            //        creditamount = 0;
            //        alert("Paid amount should not be greater than Net Amount");
            //        return;
            //    }

            //}
            console.log(creditamount);
        //    filters.walletAmt = creditamount;
            if (filters.walletamt == '') {
                filters.walletamt = 0;
            }

            if (parseFloat($("#txtTotalBalanceAmount").val()) < 0) {
                alert("Payment should not be greater than Net Amount");
                return false;
            }

            //   alert("{'BillNo':'" + BillNo + "','BillRefNo':'" + BillRefNo + "','currentamount':'" + prvNetamount + "','paidamount':'" + paidamount + "','TotalBalanceAmount':'" + TotalBalanceAmount + "','TotalPaidinFull':'" + TotalPaidinFull + "','BankName':'" + BankName + "','ChequeAmount':'" + ChequeAmount + "','ChequeDate':'" + ChequeDate + "','ChequeNo':'" + ChequeNo + "','CardAmount':'" + CardAmount + "','CardNo':'" + CardNo + "','CardType':'" + CardType + "','CardBank':'" + CardBank + "','CashAmount':'" + CashAmount + "','SpecialNote':'" + SpecialNote + "','outstandingBillDate':'" + outstand_bl_dt + "','TimeZone':'" + TimeZone + "'}");
            loading();
            $.ajax({
                type: "POST",
                url: "managepurchase.aspx/saveToPurchaseMaster",
                data: "{'filters':" + JSON.stringify(filters) + "}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();

                    if (msg.d == "N") {
                        alert("Error!.. Please Try Again...");
                        return;
                    } else {

                        alert("Updated Successfully...!");
                        location.href = "managepurchase.aspx?purchaseId=" + purchaseId + "";
                        return false;
                    }
                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }

        function refreshpage() {
            selectOrders();
            //  window.location.reload();
        }

        function printbill() {

            location.href = "billreceipt.aspx?orderId=" + BillNo;
        }


        //function for disable payment section
        function disablepayment() {
            $("#cbCashPayment").prop("disabled", true);
            $("#cbCashPayment").attr("checked", false);
            $("#walletPayment").prop("disabled", true);
            $("#walletPayment").attr("checked", false);
            $("#cbCardPayment").prop("disabled", true);
            $("#cbCardPayment").attr("checked", false);
            $("#cbChequePayment").prop("disabled", true);
            $("#cbChequePayment").attr("checked", false);
            $('#txtCashAmount').val('0');
            $("#textwalletamt").val('0');
            $('#txtCashAmount').prop("disabled", true);
            $('#txtCardAmount').val('0');
            $('#txtCardAmount').prop("disabled", true);
            $('#txtCardNo').val('');
            $('#txtCardNo').prop("disabled", true);
            $('#txtCardType').val('');
            $('#txtCardType').prop("disabled", true);
            $('#txtCardBank').val('');
            $('#txtCardBank').prop("disabled", true);
            $('#txtChequeAmount').val('0');
            $('#txtChequeAmount').prop("disabled", true);
            $('#txtChequeNo').val('');
            $('#txtChequeNo').prop("disabled", true);
            $('#txtChequeDate').val('');
            $('#txtChequeDate').prop("disabled", true);
            $('#txtBankName').val('');
            $('#txtBankName').prop("disabled", true);
            $("#divsaveorder").css('pointer-events', 'none');
        }

        function editPurchase() {
            location.href = "editPurchase.aspx?purchaseId="+ purchaseId + "";
        }

        // get payment edits
        function load_payment_edits() {
           
            if (purchaseId == 0 || purchaseId == undefined) {

                alert('An issue occured! Please reload the page & try again');
                return;
            }

            $.ajax({
                type: "POST",
                url: "managepurchase.aspx/load_payment_edits",
                data: "{'purchaseId':'" + purchaseId + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {

                    if (msg.d == "N") {

                        alert("No payment editing found against this purchase!");
                    }
                    else {

                        var obj = JSON.parse(msg.d);
                        var htm = "";
                        $.each(obj, function (i, row) {
                            htm += '<tr>';
                            htm += '<td>' + row.transaction_id + '</td>';
                            htm += '<td>' + row.tpe_date + '</td>';
                            htm += '<td>' + row.username + '</td>';

                            var changes = "";
                            if (row.tpe_prev_cashamt != row.tpe_new_cashamt) {

                                changes += "Cash Payment : " + row.tpe_new_cashamt + " (From " + row.tpe_prev_cashamt + ")<br/>";
                            }

                            if (row.tpe_prev_chequeamt != row.tpe_new_chequeamt) {

                                changes += "Cheque Payment : " + row.tpe_new_chequeamt + " (From " + row.tpe_prev_chequeamt + ")<br/>";
                            }

                            if (row.tpe_prev_walletamt != row.tpe_new_walletamt) {

                                changes += "Wallet Payment : " + row.tpe_new_walletamt + " (From " + row.tpe_prev_walletamt + ")<br/>";
                            }
                            htm += '<td>' + changes + '</td>';

                            htm += '</tr>';
                        });

                        $("#tbl_PaymentEdits").html(htm)
                        $("#transType1").html('Purchase Ref: #' + purchaseId)
                        $("#popupPaymentEdits").modal("show")
                    }


                },
                error: function (xhr, status) {

                    alert("Internet Problem..!");
                }
            })

        }


    </script>
</head>

<body class="nav-md">
    <div class="container body">
        <div class="main_container">
            <div class="col-md-3 left_col">
                <div class="left_col scroll-view">
                    <div class="navbar nav_title" style="border: 0;">
                        <a href="#" class="site_title"><span>Invoice Me</span></a>
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
            <!-- top navigation -->
            <div class="top_nav">
                <div class="nav_menu">
                    <nav>

                        <div class="navbar-header" style="width: 100%; display: flex; align-items: center">
                            <div class="nav toggle" style="padding: 5px;">
                                <a id="menu_toggle"><i class="fa fa-bars"></i></a>
                            </div>
                            <label style="font-weight: bold; font-size: 16px;">Manage Purchase</label>
                            <%--<div style="margin-left:5px;">
                                   <label class="glyphicon glyphicon-chevron-left" style="font-size:24px;  margin-left:20px;"></label>
                  <label class="fa fa-refresh pull-right" style="font-size:24px;"></label>
                                    </div>--%>
                        </div>

                    </nav>
                </div>
            </div>
            <!-- /top navigation -->
            <!-- /top navigation -->

            <!-- page content -->
            <div class="right_col" role="main">
                <div class="">
                    <%--<div class="page-title">
			
              <div class="title_left" style="width:100%;">
                <label style="font-size:16px; font-weight:bold;">Manage Order</label>
                   <label class="fa fa-backward pull-right" style="font-size:24px;  margin-left:20px;"></label>
                  <label class="fa fa-refresh pull-right" style="font-size:24px;"></label>
                 

              </div>

              
            </div>--%>

                    <div class="clearfix"></div>
                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title" style="margin-bottom: 0px;">

                                    <label>Branch Name:  </label><a id="txtLabelBarnch"></a> <a > ==== </a>
                                    <label>Status </label><a id="txtLabelStatus"></a>

                                    <ul class="nav navbar-right panel_toolbox pull-right">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                        </li>


                                    </ul>

                                </div>
                                <div class="x_content">
                                    <!-- info row -->
                                    <div class="row invoice-info">
                                        <div class="col-sm-1 invoice-col">
                                            <b><label id="txtEntryRefNo" style="font-size: 15px"></label>
                                            </b>

                                        </div>
                                        <!-- /.col -->
                                        <div class="col-sm-2 invoice-col">

                                            <b><span title="City" class="fa fa-calendar"></span>
                                                <label id="txtEntryDate">24-Feb-2017</label></b>

                                        </div>
                                        <!-- /.col -->

                                        <div class="col-sm-3 invoice-col">
                                            <label id="txtVendorName">Istanbul Supermarket Ajman</label>
                                            <label id="txtVendorId" style="display:none;"></label>
                                        </div>
                                          <div class="col-sm-2 invoice-col">
                                            <label id="Label1">Balance:</label>
                                            <label id="txtBalance" style=";">0</label>
                                        </div>
                                          <div class="col-sm-2 invoice-col">
    <label id="Label12">Wallet:</label>
    <label id="txtWalletBalance" >0</label>
</div>
                                        <!-- /.col -->
                                        <div class="col-sm-2 invoice-col">
                                            <button class="btn btn-success btn-xs" onclick="editPurchase()" style="display:;" id="btnEdit">
                                                <li class="fa fa-pencil"></li>
                                                <b>Edit Purchase</b></button>
                                        </div>


                                        <!-- /.col -->
                                    </div>
                                    <!-- /.row -->
                                </div>
                                <div class="clear"></div>


                            </div>
                        </div>
                    </div>
                    <div class="clearfix"></div>
                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title">
                                    <label>Item Details</label>
                                    <ul class="nav navbar-right panel_toolbox">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                        </li>


                                    </ul>
                                </div>


                                <div class="col-md-12 col-sm-12 col-xs-12" style="overflow-x: auto;">
                                    <div class="x_content">

                                        <table id="tblOrderItems" class="table table-striped jambo_table bulk_action" style="table-layout: auto;">
                                            <thead  style="background-color:#f1eeee;color:#525252">
                                                <tr>
                                                    <td>Item Code</td>
                                                    <td style="width: 300px;">Name</td>
                                                    <td>QTY</td>
                                                    <td>Price</td>
                                                    
                                                    <td>Amt</td>
                                                    <td>Dis %</td>
                                                    <td>Dis Amt</td>
                                                    <td>Tax Perc</td>
                                                    <td>Tax Amt</td>
                                                    <td>Net Amt</td>
                                                    <td>Paid</td>
                                                    <td>Balance</td>


                                                </tr>
                                            </thead>


                                            <tbody id="tbodyItems">
                                                
                                            </tbody>
                                            <tbody id="tbodyPayments">


                                                <tr>
                                                    <td colspan="4" style="text-align: right;"><b>Round Off Value: <label id="lblRoundoff" style="color:#900c0c"></label></b></td>
                                                    <td colspan="5" style="text-align: right;"><b>Total</b></td>

                                                    <td>
                                                        <label id="txtTotalAmt">0</label></td>
                                                    <td>
                                                        <label id="">--</label></td>
                                                    <td>
                                                        <label id="Label2">--</label></td>

                                                </tr>
                                                <tr>
                                                    <td colspan="10" style="text-align: right;"><b>Previous Payment</b></td>

                                                    <td style="font-weight: bold;">
                                                        <label id="txtPreviousPaid"></label>
                                                    </td>
                                                    <td style="font-weight: bold;">
                                                        <label id="txtPreviousBalance"></label>
                                                    </td>

                                                </tr>
                                                <tr>
                                                    <td colspan="10" style="text-align: right;"><b>Current Payment</b></td>
                                                    <td style="color: red; font-weight: bold;">
                                                        <input style="width: 97%; background: none; border: none;" id="txtTotalCurrentAmount" value="0" disabled="" type="text" /></td>
                                                    <td style="color: red; font-weight: bold;">
                                                        <input style="width: 97%; background: none; border: none;" id="txtTotalBalanceAmount" value="0.00" disabled="" type="text" /></td>
                                                </tr>
                                            </tbody>



                                        </table>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="clearfix"></div>
                    <%-- Cas,Card,Cheque start--%>
                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12">
                            <div class="x_panel" style="background: #eeeeee;">
                                <div class="col-md-12 col-sm-12 col-xs-12" style="padding-left: 0px; padding-right: 0px;">
                                    <div class="col-md-3 col-sm-6 col-xs-12" style="padding-left: 0px; padding-right: 0px;">
                                        <div class="col-md-2 col-sm-1 col-xs-2" style="padding-right: 0px;">
                                            <div class="checkbox">
                                                <label style="font-size: 1.3em">
                                                    <input type="checkbox" value="" id="cbCashPayment" onclick="javascript: paymentMethod();">
                                                    <span class="cr"><i class="cr-icon fa fa-check"></i></span>
                                                </label>
                                            </div>
                                            <%--                                            <input type="checkbox"   class="flat" />--%>
                                        </div>

                                        <div class="col-md-4 col-sm-4 col-xs-12" style="line-height: 3; padding-left: 0px;"><b>CASH</b> </div>
                                        <div class="clearfix"></div>
                                        <div class="col-md-4 col-sm-6 col-xs-12">CashAmt</div>
                                        <div class="col-md-8 col-sm-6 col-xs-12">
                                            <input type="text" id="txtCashAmount" class="form-control" style="height: 25px;" placeholder="Enter amt." onkeyup="javascript:paymentMethod();" value="0" />
                                        </div>
                                        <div class="clearfix"></div>

                                         <div class="col-md-2 col-sm-1 col-xs-2" style="padding-right: 0px;">
     <div class="checkbox">
         <label style="font-size: 1.3em">
             <input type="checkbox" value="" id="walletPayment">
             <span class="cr"><i class="cr-icon fa fa-check"></i></span>
         </label>
     </div>

 </div>
 <div class="col-md-8 col-sm-4 col-xs-4" style="line-height: 3; padding-left: 0px;"><b>WALLET</b> (Wallet contains:  <label id="lblwalletamt" style="color: #432727; font-weight: bold; font-size: 12px; color: #40c863;"></label>)</div>
 <div class="clearfix"></div>
 <div class="col-md-3 col-sm-6 col-xs-12">WalletAmt</div>
 <div class="col-md-9 col-sm-6 col-xs-12">
     <input type="text" id="textwalletamt" class="form-control" style="height: 25px;" value="0" disabled="disabled" onkeyup="javascript:paymentMethod();" />
 </div>

                                    </div>

                                    <div class="col-md-4 col-sm-4 col-xs-12" style="padding-left: 0px; padding-right: 0px;display:none;">
                                        <div class="col-md-2 col-sm-1 col-xs-2" style="padding-right: 0px;">
                                            <div class="checkbox">
                                                <label style="font-size: 1.3em">
                                                    <input type="checkbox" value="" id="cbCardPayment" onclick="javascript: paymentMethod();">
                                                    <span class="cr"><i class="cr-icon fa fa-check"></i></span>
                                                </label>
                                            </div>

                                        </div>
                                        <div class="col-md-4 col-sm-4 col-xs-12" style="line-height: 3; padding-left: 0px;"><b>CARD</b> </div>
                                        <div class="clearfix"></div>
                                        <div class="col-md-5 col-sm-6 col-xs-12">Card Amt</div>
                                        <div class="col-md-7 col-sm-6 col-xs-12">
                                            <input type="text" id="txtCardAmount" class="form-control" style="height: 25px; margin-bottom: 5px;" placeholder="Enter amt." onkeyup="javascript:paymentMethod();" value="0" />
                                        </div>
                                        <div class="clearfix"></div>
                                        <div class="col-md-5 col-sm-6 col-xs-12">Card No</div>
                                        <div class="col-md-7 col-sm-6 col-xs-12">
                                            <input type="text" id="txtCardNo" class="form-control" style="height: 25px; margin-bottom: 5px;" placeholder="Enter No" />
                                        </div>
                                        <div class="clearfix"></div>
                                        <div class="col-md-5 col-sm-6 col-xs-12">Card Type</div>
                                        <div class="col-md-7 col-sm-6 col-xs-12">
                                            <input type="text" id="txtCardType" class="form-control" style="height: 25px; margin-bottom: 5px;" placeholder="Enter Type" />
                                        </div>
                                        <div class="clearfix"></div>
                                        <div class="col-md-5 col-sm-6 col-xs-12">Bank</div>
                                        <div class="col-md-7 col-sm-6 col-xs-12">
                                            <input type="text" id="txtCardBank" class="form-control" style="height: 25px; margin-bottom: 5px;" placeholder="Enter Bank" />
                                        </div>
                                        <div class="clearfix"></div>
                                    </div>

                                    <div class="col-md-4 col-sm-4 col-xs-12" style="padding-left: 0px; padding-right: 0px">
                                        <div class="col-md-2 col-sm-1 col-xs-2" style="padding-right: 0px;">
                                            <div class="checkbox">
                                                <label style="font-size: 1.3em">
                                                    <input type="checkbox" value="" id="cbChequePayment" onclick="javascript: paymentMethod();">
                                                    <span class="cr"><i class="cr-icon fa fa-check"></i></span>
                                                </label>
                                            </div>

                                        </div>
                                        <div class="col-md-4 col-sm-4 col-xs-4" style="line-height: 3; padding-left: 0px;"><b>CHEQUE</b> </div>
                                        <div class="clearfix"></div>
                                        <div class="col-md-5 col-sm-6 col-xs-12">Cheque Amt.</div>
                                        <div class="col-md-7 col-sm-6 col-xs-12">
                                            <input type="text" id="txtChequeAmount" class="form-control" style="height: 25px; margin-bottom: 5px;" placeholder="Enter amt." onkeyup="javascript:paymentMethod();" />
                                        </div>
                                        <div class="clearfix"></div>
                                        <div class="col-md-5 col-sm-6 col-xs-12">Cheque No.</div>
                                        <div class="col-md-7 col-sm-6 col-xs-12">
                                            <input type="text" id="txtChequeNo" class="form-control" style="height: 25px; margin-bottom: 5px;" placeholder="Enter No." />
                                        </div>
                                        <div class="clearfix"></div>
                                        <div class="col-md-5 col-sm-6 col-xs-12">Date</div>
                                        <div class="col-md-7 col-sm-6 col-xs-12">
                                            <input type="text" id="txtChequeDate" class="form-control" style="height: 25px; margin-bottom: 5px;" placeholder="Enter Date" />
                                        </div>
                                        <div class="clearfix"></div>
                                        <div class="col-md-5 col-sm-6 col-xs-12">Bank</div>
                                        <div class="col-md-7 col-sm-6 col-xs-12">
                                            <input type="text" id="txtBankName" class="form-control" style="height: 25px; margin-bottom: 5px;" placeholder="Enter Bank" />
                                        </div>
                                        <div class="clearfix"></div>
                                    </div>

                                    <div class="col-md-4 col-sm-4 col-xs-12" style="padding-left: 0px; padding-right: 0px">

                                        <div class="col-md-8 col-sm-6 col-xs-12"><b>Special Notes</b> </div>
                                        <div class="clearfix"></div>

                                        <div class="col-md-12 col-sm-12 col-xs-12">
                                            <textarea id="txtSpecialNote" class="form-control" style="resize: none;"></textarea>
                                        </div>
                                        <div class="clearfix"></div>

                                        <div class="col-md-3 col-sm-3 col-xs-3" style="margin-top: 10px;" id="divsaveorder" onclick="javascript:saveToPurchaseMaster();">
                                            <button class="btn btn-primary" type="button">Update</button>
                                        </div>


                                        <div class="clearfix"></div>

                                    </div>
                                </div>

                            </div>
                        </div>
                    </div>
                    <%-- Cas,Card,Cheque End--%>

                    <div class="clearfix"></div>
                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title">
                                    <label>Transaction History</label>
                                    <label class="fa fa-hover btn btn-primary" onclick="load_payment_edits();" style="margin-left:20px;color:#fff;font-family:Arial"><b style="color:#fff"> View Payment Edits</b></label> 
                                    <ul class="nav navbar-right panel_toolbox">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                        </li>


                                    </ul>
                                </div>


                                <div class="col-md-12 col-sm-12 col-xs-12" style="overflow-x: auto;">
                                    <div class="x_content">

                                        <table id="tblPaymentDetails" class="table table-striped table-bordered" style="table-layout: auto;">
                                            <thead>
                                                <tr>
                                                    <th>Ref.</th>
                                                    <th>Date</th>
                                                    <th>Narration</th>
                                                    <th>User</th>
                                                    <th>Amount</th>
                                                    <th></th>
                                                </tr>
                                            </thead>


                                            <tbody>
                                                <tr>
                                                    <td>0021</td>
                                                    <td>UAE</td>
                                                    <td>1000</td>
                                                    <td>545</td>
                                                    <td>454</td>
                                                    <td>5</td>
                                                    <td>45</td>
                                                    <td>5</td>
                                                </tr>



                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                     <div class="clearfix"></div>
                    <%--<div class="modal fade" id="popupTransaction" role="dialog">
                        <div class="modal-dialog modal-md" style="">

                            <!-- Modal content-->
                            <div class="modal-content">
                                <div class="modal-header" style="padding-bottom: 5px;">
                                    <button type="button" class="close" data-dismiss="modal">&times;</button>
                                    <div class="col-md-6 col-sm-6 col-xs-12">
                                        <h4 class="modal-title">Transaction #<span id="lblTransRef"></span></h4>
                                    </div>
                                </div>
                                <div class="x_content">
                                    <div class="col-md-6" style="margin-bottom:10px;"><b>Amount :</b><span id="transAmount"></span></div>
                                    <div class="col-md-6" style="margin-bottom:10px;"><b>Date :</b><span id="transDate"></span></div>
                                    <div class="col-md-6" style="margin-bottom:10px;"><b>Type :</b><span id="transType"></span></div>
                                    <div class="col-md-6" style="margin-bottom:10px;"><b>User :</b><span id="transUserName"></span></div>
                                    <div class="col-md-12"><b>Narration :</b><p id="transNarration" style="text-indent:20px;"></p></div>
                                    <div class="col-md-6" style="margin-bottom:10px;">
                                        <b>Cash</b><br />
                                        <div style="margin-left:10px;">Amount :<span id="cashAmt">0</span></div><br />
                                        <b>Wallet</b><br />
                                        <div style="margin-left:10px;">Amount :<span id="walletAmt">0</span></div>
                                    </div>
                                    <div class="col-md-6" style="margin-bottom:10px;">
                                        <b>Cheque</b><br />
                                        <div style="margin-left: 10px;">
                                            Amount :<span id="chequeAmt">0</span><br />
                                            number :<span id="chequeNo"></span><br />
                                            Date :<span id="chequeDate"></span><br />
                                            Bank :<span id="chequeBank"></span>
                                        </div>
                                    </div>
                                </div>
                                <div class="clearfix"></div>
                                <div class="ln_solid"></div>
                            </div>

                        </div>
                    </div>--%>

                    <div class="modal fade" id="popupTransaction" role="dialog">
                        <div class="modal-dialog modal-md" style="">

                            <!-- Modal content-->
                            <div class="modal-content">


                                





                                <div class="modal-header" style="padding-bottom: 5px;">
                                    <button type="button" class="close" data-dismiss="modal">&times;</button>
                                    <div class="col-md-12 col-sm-12 col-xs-12" style="text-align:center">
                                        <h4 class="modal-title" style="color:#337ab7">Transaction #<span id="lblTransRef"></span><br /><small>[ <b><span id="transType"></span></b> ] </small>
                                            <br />
                                            <small style="color:#525252"><b>Date :</b><span id="transDate"></span></small> | 
                                            <small style="color:#525252"><b>User :</b><span id="transUserName"></span></small>
                                        </h4>
                                    </div>
                                  
                                </div>
                                <div class="x_content">

                                    <div>
                                        <table style="margin-bottom:0px;padding-bottom:0px" class="table table-responsive">
                                            <tbody>
                                                
                                                <tr>
                                                    <td><b>Amount :</b><strong style="color:#337ab7"><span id="transAmount"></span></strong>
                                                        <br /><b>Details :</b><span id="transNarration"></span>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td></td>
                                                </tr>
                                            </tbody>
                                        </table>
                                        <table style="margin-top:0px;padding-top:0px" class="table table-responsive table-bordered" id="tbl_payment_info">
                                            <thead style="color:#337ab7;background-color:#f6f6f6">
                                                <tr>
                                                <th>Mode of Payment</th>
                                                <th>Amount & Details</th>
                                                    </tr>
                                            </thead>
                                            <tbody>
                                                
                                                <tr id="cash_row">
                                                    <td><b>CASH</b></td>
                                                    <td>Amount : <b><span id="cashAmt"></span></b></td>
                                                </tr>
                                                <tr id="cheque_row">
                                                    <td><b>CHEQUE</b></td>
                                                    <td>Amount : <b><span id="chequeAmt"></span></b><br />
                                            Cheque Number :<span id="chequeNo"></span><br />
                                            Date :<span id="chequeDate"></span><br />
                                            Bank :<span id="chequeBank"></span></td>
                                                </tr>
                                                 <tr id="wallet_row">
                                                    <td><b>WALLET</b></td>
                                                    <td><b>Amount : </b><span id="walletAmt"></span></td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                                                                                                                             
                                </div>
                                <div class="clearfix"></div>
                                <div class="ln_solid"></div>
                            </div>

                        </div>
                    </div>

                    <div class="modal fade" id="popupPaymentEdits" role="dialog">
                        <div class="modal-dialog modal-lg" style="">

                            <!-- Modal content-->
                            <div class="modal-content">
                               
                                <div class="modal-header" style="padding-bottom: 5px;">
                                    <button type="button" class="close" data-dismiss="modal">&times;</button>
                                    <div class="col-md-12 col-sm-12 col-xs-12" style="text-align:center">
                                        <h4 class="modal-title" style="color:#337ab7">Payment Edits <br /><small>[ <b><span id="transType1"></span></b> ] </small>
                                            <%--<br />
                                            <small style="color:#525252"><b>Date :</b><span id="transDate1"></span></small> | 
                                            <small style="color:#525252"><b>User :</b><span id="transUserName1"></span></small>--%>
                                        </h4>
                                    </div>
                                  
                                </div>
                                <div class="x_content">

                                    <div>                                      
                                        <table style="margin-top:0px;padding-top:0px" class="table table-responsive table-bordered" >
                                            <thead style="color:#337ab7;background-color:#f6f6f6">
                                                <tr>
                                                <th>Txn.ID</th>
                                                <th>Date</th>
                                                    <th>Edited By</th>
                                                    <th>Changes Made</th>
                                                    </tr>
                                            </thead>
                                            <tbody id="tbl_PaymentEdits">
                                                                                                
                                            </tbody>
                                        </table>
                                    </div>
                                                                                                                                             
                                </div>
                                <div class="clearfix"></div>
                                <div class="ln_solid"></div>
                            </div>

                        </div>
                    </div>

                    <div class="clearfix"></div>

                </div>
            </div>
            <!-- /page content -->

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
