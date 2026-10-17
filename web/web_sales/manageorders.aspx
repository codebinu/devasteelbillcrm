<%@ Page Language="C#" AutoEventWireup="true" CodeFile="manageorders.aspx.cs" Inherits="web_sales_manageorders" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Manage Bill  | Invoice Me</title>
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
    <style>
        .blink_text
        {
            animation: 1s blinker linear infinite;
            -webkit-animation: 1s blinker linear infinite;
            -moz-animation: 1s blinker linear infinite;
            color: #ff3300;
        }

        @-moz-keyframes blinker
        {
            0%
            {
                opacity: 1.0;
            }

            50%
            {
                opacity: 0.0;
            }

            100%
            {
                opacity: 1.0;
            }
        }

        @-webkit-keyframes blinker
        {
            0%
            {
                opacity: 1.0;
            }

            50%
            {
                opacity: 0.0;
            }

            100%
            {
                opacity: 1.0;
            }
        }

        @keyframes blinker
        {
            0%
            {
                opacity: 1.0;
            }

            50%
            {
                opacity: 0.0;
            }

            100%
            {
                opacity: 1.0;
            }
        }
    </style>

    <script type="text/javascript">
        var exactwalletamt = 0;
        var BillNo;
        var userId;
        var status;
        var tax_type = 0;
        var orderObj = "";
        var accuracyNum=2;
        var lastUpdatedDate="";
        var systemSettings = <%=settings%>;
        var is_invoiced = 0;
        var orderType = 0;
     //   console.log(systemSettings);
        //start globel object for approvehead
        var Objapprovehead = {
            approveheads: [],
            add: function (id, status, date) {
                var head = {
                    id: id,
                    status: status,
                    date: date
                };
                Objapprovehead.approveheads.push(head);
            }
        };
        //end globel object for approvehead


        //  window.onbeforeunload = function () { return "Your work will be lost."; };
        $(document).ready(function () {
            accuracyNum=systemSettings[0].ss_decimal_accuracy;
            //console.log(JSON.parse($.cookie("search-data")));
            BillNo = getQueryString('orderId');
            //  alert(BillNo);
            //  alert(BillNo);
            if (BillNo == undefined) {
                location.href = "orders.aspx";
                return;
            }
            //console.log(location.search);
            var dt = new Date();
            var cur_dat = dt.getDate() + '-' + (dt.getMonth() + 1) + '-' + dt.getFullYear();
            $("#chckcmpnyVehicle").prop("checked", false);
            $("#chckotherVehicle").prop("checked", false);
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
                //dateFormat :'yy-mm-dd'
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
                //dateFormat :'yy-mm-dd'
                dateFormat: 'dd-mm-yy'
            });
            $('#txtChequeDate').scroller({
                preset: 'date',
                endYear: yyyy + 100,
                setText: 'Next',
                invalid: {},
                theme: 'ios',
                display: 'modal',
                mode: 'scroller',
                //dateFormat :'yy-mm-dd'
                dateFormat: 'yy-mm-dd'
            });
            $('#searchvalContent2').scroller({
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

            $('#txtProcessDate').scroller({
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

            $('#txtProcessDate').scroller({
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

            $('#txtTransDate').scroller({
                preset: 'date',
                endYear: yyyy + 100,
                setText: 'Next',
                invalid: {},
                theme: 'ios',
                display: 'modal',
                mode: 'scroller',
                //dateFormat :'yy-mm-dd'
                dateFormat: 'dd-mm-yy'
            });

            var cday = currentdate();
            $('#txtTransDate').val(cday);

            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " ©");
            loadBranches();
            selectOrders();

            //call to select order details txtTransDate

        });

        function userButtonRoles() {
            var userTypeId = $.cookie("invntrystaffTypeID");
            loading();
            $.ajax({
                type: "POST",
                url: "manageorders.aspx/showUserButtons",
                data: "{'userTypeId':'" + userTypeId + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    //  alert(msg.d);
                    if (msg.d == "N") {
                        return;
                    }
                    else {
                        var splitarray = msg.d.split("@#$");
                        var access = "alert('You Have No Permission..!'); return false;";
                        var newclick = new Function(access);
                        for (var i = 1; i <= splitarray[0]; i++) {
                            //alert(splitarray[i]);
                            $("#" + splitarray[i] + "").attr('onclick', '').click(newclick);

                        }
                        return;
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

                    if (type == "text" || type == "textarea") {

                        $("#" + input.attr('id')).val(input.val().replace(/'/g, '"'));
                    } else { }
                }
            );
        }

        function calc_carton(qty, foc, qty_per_ctn) {

            var tot_qty = parseInt(qty) + parseInt(foc);
            var quotient = Math.floor(tot_qty / qty_per_ctn);
            var remainder = tot_qty - (quotient * qty_per_ctn);
            if (quotient != 0) {
                return "" + quotient + " Carton(s) & " + remainder + " Piece(s)";
            }
            else {
                return "" + remainder + " Piece(s)";
            }
        }

        //start: Showing Details of selected Outsatnding Bill from Popup
        function selectOrders() {
            //  alert(paid);
            loading();

            $.ajax({
                type: "POST",
                url: "manageorders.aspx/selectOrders",
                data: "{'billno':'" + BillNo + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    //$.cookie('salesreturnOrderId', BillNo, {
                    //    path: '/'
                    //});
                    orderObj = JSON.parse(msg.d);
                    var classType = "";
                 //   console.log(orderObj);
                    var order_details = orderObj.order[0];
                    lastUpdatedDate=order_details.lastUpdatedDate;
                    tax_type = order_details.branch_tax_method;
                    $("#txtPreviousPaid").text(order_details.total_paid);
                    if(order_details.invoiceNum != "" && order_details.invoiceNum != null ){
                      //  alert(order_details.invoiceNum);
                        var processDate = order_details.processedDate.split(' ')[0];
                        var processTime = order_details.processedDate.split(' ')[1] + " " + order_details.processedDate.split(' ')[2];
                    }else{
                        var d = new Date();
                        var amOrPm = (d.getHours() < 12) ? "AM" : "PM";
                        var hour = (d.getHours() < 12) ? d.getHours() : d.getHours() - 12;
                        var processTime=hour + ':' + d.getMinutes() + ' ' + amOrPm;
                        var processDate = d.getDate() + "-" + (d.getMonth()+1) + "-" +d.getFullYear() ;
                    }
                    $("#txtProcessDate").val(processDate);
                    $("#txtProcessTime").val(processTime);
                    $("#txtPreviousBalance").text(order_details.total_balance);
                    $("#lblRoundoff").text(order_details.roundoff);
                    //  alert(order_details.total_balance);
                    $("#txtTotalBalanceAmount").val(order_details.total_balance);
                    $("#txtTotalAmt").text(order_details.total_amount);
                    if (order_details.invoiceNum != "" && order_details.invoiceNum !== null) {
                        $("#lblInvoiceNum").text(order_details.invoiceNum);
                        is_invoiced = 1;
                        $("#tdExportBtn").show();
                    }else{
                        $("#lblInvoiceNum").html("<label style='color:red'> (Not Yet Billed) </label>");
                        is_invoiced = 0;
                        $("#tdExportBtn").hide();
                    }
                    $("#txtBillRefNo").text(order_details.sm_refno);
                    $("#txtMemberId").text(order_details.cust_id);
                    //if (order_details.cust_type == 1) {
                    //    classType = "A";
                    //} else if (order_details.cust_type == 2) {
                    //    classType = "B";
                    //} else if (order_details.cust_type == 3) {
                    //    classType = "C";
                    //}
                   // $("#txtClassType").text(classType);
                    var a = document.getElementById('hrefCustomer'); //or grab it by tagname etc
                    a.href = "../Web_Customer/managecustomers.aspx?cusId=" + order_details.cust_id;
                    $("#txtMemberName").text(order_details.cust_name);
                    $("#txtOrderDate").text(order_details.date);
                    $("#selBranches").val(order_details.branch_id);
                    loadAssignPersons();
                    $("#txtTotalCurrentAmount").val('0');
                    $("#cbCashPayment").removeProp("checked");
                     $("#cbCardPayment").removeProp("checked");
                    $("#cbChequePayment").removeProp("checked");
                    $("#walletPayment").removeProp("checked");
                    
                    //alert(order_details.order_status);
                    if (order_details.order_status == 0) {
                        $("#txtLabelStatus").html('<span class="label label-warning" style="margin-left: 2px; margin-right: 2px; color: #fff;">New</span>');

                       
                        if (order_details.branch_type == 1) {

                            $("#divAssign").show();
                        }
                        else {

                            $("#divAssign").hide();
                        }
                        
                        $("#divCancel").show();
                        //  $("#divWaybilling").show();

                    } else if (order_details.order_status == 1) {
                        $("#txtLabelStatus").html('<span class="status label label-primary" style="margin-left: 2px; margin-right: 2px; color: #fff;">Processed</span>');
                        $("#divDeliver").show();
                        $("#divPending").show();
                        $("#divNew").show();
                      //  $("#divWaybilling").show();
                        $("#divCancel").show();

                    } else if (order_details.order_status == 2) {
                        $("#txtLabelStatus").html('<span class="status label label-success" style="margin-left: 2px; margin-right: 2px; color: #fff;">Deliverd</span>');
                        $("#divCancel").show();
                    }
                    else if (order_details.order_status == 3) {
                        $("#txtLabelStatus").html('<span class="status label label-info" style="margin-left: 2px; margin-right: 2px; color: #fff;">To be confirmed</span>');
                        $("#divApprove").show();
                        $("#divReject").show();
                          $("#divCancel").show();
                    }
                    else if (order_details.order_status == 4 ) {
                        $("#txtLabelStatus").html('<span class="status label label-danger" style="margin-left: 2px; margin-right: 2px; color: #fff;">Cancelled</span>');
                        $("#btnEditOrder").hide();
                        //$("#divDeliver").show();
                        $("#divNew").show();
                     //   $("#divConfirm").show();

                    }
                    else if (order_details.order_status == 5) {
                        $("#txtLabelStatus").html('<span class="status label label-danger" style="margin-left: 2px; margin-right: 2px; color: #fff;">Rejected</span>');
                        $("#divNew").show();
                        $("#divConfirm").show();
                        $("#btnEditOrder").hide();
                    }
                    else if (order_details.order_status == 6) {
                        $("#txtLabelStatus").html('<span class="status label label-default" style="margin-left: 2px; margin-right: 2px; color: #fff;">Pending</span>');
                        $("#divNew").show();
                        $("#divCancel").show();
                    }

                    orderType = order_details.type;
                    if (order_details.type == "2") {
                        
                        $("#btnEditOrder").show();
                    }
                    //alert(order_details.type);
                    $("#txtdeliverystatus").val(order_details.order_status);
                 //   alert(order_details.sm_specialnote);
                    $("#txtSpecialNote").val(order_details.sm_specialnote);

                    if (order_details.outstanding_amt == null || order_details.outstanding_amt == "") {
                        order_details.outstanding_amt = 0;
                    }
                    $("#lbloutstanding").text(order_details.outstanding_amt);
                    if (order_details.outstanding_amt > 0) {
                        $("#lbloutstanding").css("color", "red");
                    } else {
                        $("#lbloutstanding").css("color", "green");
                    }

                    if (order_details.approver_name == null || order_details.approver_name == "") {
                        $("#trconfirm").hide();
                    } else {
                        $("#lblconfirmusername").text(order_details.approver_name);
                        $("#trconfirm").show();
                    }

                    var wallet_amount_payable = order_details.custBal > order_details.outstanding_amt ? Math.abs(order_details.outstanding_amt - order_details.custBal) : order_details.outstanding_amt < 0 ? Math.abs(order_details.outstanding_amt) : 0;
                    $("#lblwalletamt").text(wallet_amount_payable.toFixed(accuracyNum));
                    exactwalletamt = wallet_amount_payable;
                    if (order_details.approver_name == null || order_details.approver_name == "") {
                        $("#trconfirm").hide();
                    } else {
                        $("#lblconfirmusername").text(order_details.approver_name);
                        $("#trconfirm").show();
                    }
                    // showing order_items
                    $("#tbodyItems").html("");
                    $.each(orderObj.items, function (i, item) {

                        var qhtm = "";
                        if(item.itm_qty_per_carton >1){
                        
                            qhtm = qhtm + "<br />" + calc_carton(item.si_qty,item.si_foc,item.itm_qty_per_carton) + "";
                        }
                        else{
                            
                            qhtm = "";
                        }

                        var htmItemRow = '';
                        htmItemRow += '<tr>';
                        htmItemRow += '<td>' + item.itm_code + '</td>';
                        if (item.si_itm_type == 4) {
                            htmItemRow += '<td><strong>' + item.itm_name + '</strong>(<label class="blink_text">New Item</label>)'+ qhtm +'</td>';
                        } else {
                            htmItemRow += '<td><strong>' + item.itm_name + '</strong>'+ qhtm +'</td>';
                        }
                        htmItemRow += '<td>' + item.si_org_price + '</td>';
                        // htmItemRow += '<td style="color:red">' + item.si_price + '</td>';
                        if (item.si_price < item.si_org_price) {
                            htmItemRow += '<td style="color:red">' + item.si_price + '</td>';
                        } else if (item.si_price > item.si_org_price) {
                            htmItemRow += '<td style="color:#77d217">' + item.si_price + '</td>';
                        } else {
                            htmItemRow += '<td>' + item.si_price + '</td>';
                        }
                        htmItemRow += '<td>' + item.si_qty + '</td>';
                        htmItemRow += '<td>' + item.si_foc + '</td>';
                        htmItemRow += '<td>' + (item.si_total).toFixed(accuracyNum) + '</td>';
                        htmItemRow += '<td>' + item.si_discount_rate + '</td>';
                        htmItemRow += '<td>' + item.si_discount_amount + '</td>';
                        htmItemRow += '<td>' + parseFloat(item.si_tax_excluded_total).toFixed(2) + '</td>';
                        htmItemRow += '<td>' + item.si_tax_amount + '</td>';
                        htmItemRow += '<td>' + item.si_net_amount + '</td>';
                        htmItemRow += '<td style="display:none">' + item.si_itm_type + '</td>';
                        htmItemRow += '<td style="border-right:none;"></td>';
                        htmItemRow += '<td style="border-right:none;"></td>';
                        htmItemRow += '</tr>';
                        $("#tbodyItems").append(htmItemRow);
                    });

                    // show bill return Details
                    $("#tblReturnDetails > tbody").html("");
                    if (orderObj.return_details && orderObj.return_details.length > 0) {
                        $("#divReturnDetails").show();
                        sl_no = 0;
                        $.each(orderObj.return_details, function (i, row) {
                           // console.log(row);
                            var htmRetDetails = "";
                            $.each(row.items, function (k, item) {
                                sl_no++;
                                htmRetDetails += '<tr>';
                                htmRetDetails += '<td>' + sl_no + '</td>';
                                htmRetDetails += '<td>' + item.itm_code + '</td>';
                                htmRetDetails += '<td>' + item.itm_name + '</td>';
                                htmRetDetails += '<td>' + item.qty + '</td>';
                                htmRetDetails += '<td>' + item.price + '</td>';
                                htmRetDetails += '<td>' + item.discount + '</td>';
                                htmRetDetails += '<td>' + item.total + '</td>';
                                htmRetDetails += '</tr>';
                                htmRetDetails += '<tr>';

                                htmRetDetails += '<td colspan="7">';
                                htmRetDetails += '<div class="border"></div>';
                                htmRetDetails += '</td>';
                                htmRetDetails += '</tr>';
                            });
                            htmRetDetails += '<tr>';
                            htmRetDetails += '<td colspan="7" style="font-weight:bold;">';
                            htmRetDetails += '<div class="fl">Date : ' + row.date + '</div>';
                            htmRetDetails += '<div class="fr" style="padding-right:65px;">Net Amount : ' + row.amount + '</div>';
                            htmRetDetails += '<div class="space cl"></div>';
                            htmRetDetails += '</td>';
                            htmRetDetails += '</tr>';

                            $("#tblReturnDetails > tbody").append(htmRetDetails);
                        });
                    }

                    //by anjana showing waybilling history
                    $("#tblWayBillingDetails > tbody").html("");
                    if (orderObj.waybilling_details.length == 0) {
                        $('#tblWayBillingDetails > tbody').html("<tr class='overeffect'><td colspan='6' align='center' style='font-weight:bold; padding:8px;'>No Results Found</td></tr>");
                    } else {
                        $.each(orderObj.waybilling_details, function (i, row) {
                            //console.log(row);
                            htmWayBillingDetails = "";
                            var htmWayBillingDetails = '<tr>';
                            htmWayBillingDetails += '<td>' + row.headerid + '</td>';
                            htmWayBillingDetails += '<td>' + row.date + '</td>';
                            htmWayBillingDetails += '<td>' + row.id + '</td>';
                            htmWayBillingDetails += '<td>' + row.username + '</td>';
                            // htmWayBillingDetails += '<td>' + row.note + '</td>';
                            if (order_details.order_status == 3 || order_details.order_status == 4 || order_details.order_status == 5 || order_details.order_status == 6) {
                                htmWayBillingDetails += '<td><button onclick="javascript:gotoEditWayBill(' + row.headerid + ');" type="button" class="btn btn-success mybtnstyl" id="btnEditWayBill" disabled>Edit</button>';
                                htmWayBillingDetails += '<a href="waybillreceipt.aspx?orderId=' + BillNo + '&headerid=' + row.headerid + '"><div class="btn btn-primary btn-xs" style="line-height:1.8;background-color:#169F85;border-color:#169F85"" title="Print"><li class="fa fa-print" style="font-size:large;color:#ffff"></li></a></td>';
                                $("#btnEditWayBill").css('pointer-events', 'none');
                            } else {
                                htmWayBillingDetails += '<td><button onclick="javascript:gotoEditWayBill(' + row.headerid + ');" class="btn btn-success mybtnstyl" id="btnEditWayBill">Edit</button>';
                                htmWayBillingDetails += '<a href="waybillreceipt.aspx?orderId=' + BillNo + '&headerid=' + row.headerid + '"><div class="btn btn-primary btn-xs" style="line-height:1.8;background-color:#169F85;border-color:#169F85" onclick="gotoPrintPage(0,69)" title="Print"><li class="fa fa-print" style="font-size:large;color:#ffff"></li></a></td>';
                                $("#btnEditWayBill").css('pointer-events', '');
                            }
                            htmWayBillingDetails += '</tr>';
                            sl_no = 0;
                            htmWayBillingDetails += "<tr><td colspan='5'  ><table><tr><td style='vertical-align:top; font-weight:bold; font-size:14px; padding-top:3px; padding-right:8px;'>Items:</td>";
                            htmWayBillingDetails += "<td style='font-size:12px;'>";
                            $.each(row.items, function (k, item) {
                                sl_no++;
                                htmWayBillingDetails += "<span style=font-weight:bold;>" + sl_no + ").</span> " + item.itm_name + "";
                                htmWayBillingDetails += "&nbsp(qty=" + item.stock + ") &nbsp &nbsp ";
                            });
                            htmWayBillingDetails += "</tr><tr><td>Notes:</td>";
                            htmWayBillingDetails += '<td>' + row.note + '</td></tr></td></table>';
                            $("#tblWayBillingDetails > tbody").append(htmWayBillingDetails);
                        });
                    }

                    //end done
                    // showing payment details
                    $("#tblPaymentDetails > tbody").html("");
                    $.each(orderObj.transaction_details, function (i, row) {
                        //alert(row.custBal-order_details.outstanding_amt);

                        var htmPaymentDetails = '<tr>';
                        htmPaymentDetails += '<td>#' + row.id + '</td>';
                        htmPaymentDetails += '<td>' + row.date + '</td>';
                        htmPaymentDetails += '<td>' + row.narration + '</td>';
                        htmPaymentDetails += '<td>' + row.voucher_no + '</td>';
                        htmPaymentDetails += '<td>' + row.po_number + '</td>';
                        htmPaymentDetails += '<td>' + row.user_name + '</td>';
                        htmPaymentDetails += '<td><b>' + (row.dr != 0 ? row.dr + " Dr" : (row.cr != 0 ? row.cr + " Cr" : 0)) + '</b></td>';
                        htmPaymentDetails += '<td>' + row.closing_balance + '</td>';
                        htmPaymentDetails += '<td><div onclick="showTransactionDetails(' + row.id + ')" class="btn btn-primary btn-xs"><li class="fa fa-eye" style="font-size:large;"></li></div></td>';
                        htmPaymentDetails += '</tr>';

                        $("#tblPaymentDetails > tbody").append(htmPaymentDetails);
                    });
                    //  alert(order_details.order_status);
                    if (order_details.order_status != 3 && order_details.order_status != 4 && order_details.order_status != 5) {
                        paymentMethod();

                        $("#ordertitle").hide();
                        if (order_details.order_status == 2) {
                            $("#btnReturnOrder").hide();
                        } else {
                            // alert("");
                            $("#btnReturnOrder").hide();
                        }
                    } else {
                        disablepayment();
                        //   alert("");
                        $("#btnReturnOrder").hide();

                    }

                    if (parseFloat($("#txtPreviousBalance").text()) <= 0) {
                        disablepayment();

                    }
                   

                    //trck status show div
                    var needDisplay = "none";
                    var statusHtm = "";
                    var status_details = orderObj.statusdetails[0];
                    //  alert(status_details.sold_name);
                    needDisplay = status_details.sold_name == null ? "none" : "block";
                    statusHtm = statusHtm + '<div style="display:' + needDisplay + '">';
                    statusHtm = statusHtm + '<div class="col-md-3"><label style="font-weight:500;">Billed By</label></div>';
                    statusHtm = statusHtm + ' <div class="col-md-8"><span style="font-weight:bold;">:</span> <label>' + status_details.sold_name + '</label><label>(' + status_details.sm_sold_date + ')</label></div>';
                    statusHtm = statusHtm + '</div>';
                    if (order_details.order_status == 5) {
                        var head = "Rejected By";
                        needDisplay = status_details.approved_name == null ? "none" : "block";
                        statusHtm = statusHtm + '<div style="display:' + needDisplay + '">';
                        statusHtm = statusHtm + '<div class="col-md-3"><label style="font-weight:500;">' + head + '</label>  </div>';
                        statusHtm = statusHtm + '<div class="col-md-8"><span style="font-weight:bold;">:</span> <label>' + status_details.approved_name + '</label> <label>(' + status_details.sm_approved_date + ')</label></div>';
                        statusHtm = statusHtm + '</div>';
                    }
                    head = order_details.order_status == 6 ? "Pending By" : "Processed By";
                    needDisplay = status_details.procesd_name == null ? "none" : "block";
                    statusHtm = statusHtm + '<div style="display:' + needDisplay + '">';
                    statusHtm = statusHtm + '<div class="col-md-3"><label style="font-weight:500;">' + head + '</label>  </div>';
                    statusHtm = statusHtm + '<div class="col-md-8"><span style="font-weight:bold;">:</span> <label>' + status_details.procesd_name + '</label> <label>(' + status_details.sm_processed_date + ')</label></div>';
                    statusHtm = statusHtm + '</div>';


                    needDisplay = status_details.deliverd__name == null ? "none" : "block";
                    statusHtm = statusHtm + '<div style="display:' + needDisplay + '">';
                    if (order_details.order_status < 2) {
                        statusHtm = statusHtm + '<div class="col-md-3"><label style="font-weight:500;">Delivery</label>  </div>';
                    }
                    else if (order_details.order_status == 2) {
                        statusHtm = statusHtm + '<div class="col-md-3"><label style="font-weight:500;">Deliverd by</label>  </div>';
                    }

                    if (order_details.order_status == 2) {
                        statusHtm = statusHtm + '<div class="col-md-8"><span style="font-weight:bold;">:</span> <label>' + status_details.deliverd__name + '</label> <label>(' + status_details.sm_delivered_date + ')</label></div>';
                    } else if (order_details.order_status < 2) {
                        statusHtm = statusHtm + ' <div class="col-md-8"><span style="font-weight:bold;">:</span> <label>' + status_details.deliverd__name + '</label></div>';
                    }
                    statusHtm = statusHtm + '</div>';

                    //needDisplay = status_details.vehicle_name == null ? "none" : "block";
                    //statusHtm = statusHtm + '<div style="display:' + needDisplay + '">';
                    //statusHtm = statusHtm + '<div class="col-md-3"><label style="font-weight:500;">Vehicle</label>  </div>';
                    //statusHtm = statusHtm + ' <div class="col-md-8"><span style="font-weight:bold;">:</span> <label>' + status_details.vehicle_name + '</label></div>';
                    ////htm = htm + '<div class="col-xs-4" ></div>';
                    ////htm = htm + '<div class="col-xs-8">: ' + row.sm_cancelled_date + '</div>';
                    //statusHtm = statusHtm + '</div>';


                    //needDisplay = status_details.sm_vehicle_no == 0 ? "none" : "block";
                    //statusHtm = statusHtm + '<div style="display:' + needDisplay + '">';
                    //statusHtm = statusHtm + '<div class="col-md-3"><label style="font-weight:500;">Vehicle</label>  </div>';
                    //statusHtm = statusHtm + ' <div class="col-md-8"><span style="font-weight:bold;">:</span> <label>' + status_details.sm_vehicle_no + '</label></div>';
                    ////htm = htm + '<div class="col-xs-4" ></div>';
                    ////htm = htm + '<div class="col-xs-8">: ' + row.sm_cancelled_date + '</div>';
                    //statusHtm = statusHtm + '</div>';

                    needDisplay = status_details.canceld_name == null ? "none" : "block";
                    statusHtm = statusHtm + '<div style="display:' + needDisplay + '">';
                    statusHtm = statusHtm + '<div class="col-md-3"><label style="font-weight:500;">Cancelled By</label>  </div>';
                    statusHtm = statusHtm + '<div class="col-md-8"><span style="font-weight:bold;">:</span> <label>' + status_details.canceld_name + '</label> <label>(' + status_details.sm_cancelled_date + ')</label></div>';
                    statusHtm = statusHtm + '</div>';
                   
                    //Objapprovehead.approveheads[0].id

                    

                    //end delivery head
                        $("#divStatusData").html(statusHtm);



                    //trck status show div
                    userButtonRoles();
                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }
        // Stop: Showing Details of selected Outsatnding Bill from Popup

        function changeEvent(objectId, elem) {
            var now = new Date();
            var day = ("0" + now.getDate()).slice(-2);
            var month = ("0" + (now.getMonth() + 1)).slice(-2);

            var today = now.getFullYear() + "-" + (month) + "-" + (day);
          //  console.log("after" + Objapprovehead.approveheads[objectId].date);
            if (elem.checked) {
                Objapprovehead.approveheads[objectId].id = $.cookie("invntrystaffId");
                Objapprovehead.approveheads[objectId].status = "1";
                Objapprovehead.approveheads[objectId].date = today;
            } else {
                Objapprovehead.approveheads[objectId].id = $.cookie("invntrystaffId");
                Objapprovehead.approveheads[objectId].status = "0";
                Objapprovehead.approveheads[objectId].date = today;

            }
          //  console.log(Objapprovehead.approveheads);
        }

        function currentdate() {

            var today = new Date();
            var dd = today.getDate();
            var mm = today.getMonth() + 1;

            var yyyy = today.getFullYear();
            var hh = today.getHours();
            var minu = today.getMinutes();
            var sec = today.getSeconds();

            if (dd < 10) {
                dd = '0' + dd
            }
            if (mm < 10) {
                mm = '0' + mm
            }

            if (hh < 10) {
                hh = '0' + hh
            }

            if (minu < 10) {

                minu = '0' + minu
            }

            if (sec < 10) {
                sec = '0' + sec

            }

            var curd = dd + '-' + mm + '-' + yyyy;

            return curd;
        }

        function dateformat(idate) {

            var med = idate.split("-");
            var dd = med[0];
            var mm = med[1];
            var yy = med[2];

            var nDate = yy + '-' + mm + '-' + dd;
            return nDate;

        }

        function savePayment() {
            var filters = {};
            var deliver_status = $("#txtdeliverystatus").val();
            if (deliver_status == 3) {
                alert("There is a need of Confirmation");
                return false;
            }

            var paidamount = $("#txtTotalCurrentAmount").val();
            if (paidamount == "" || parseFloat(paidamount) == 0) {
                alert("Please Enter Paid Amount");
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

            if ($("#cbCardPayment").is(':checked')) {
                if ($('#txtCardAmount').val() == "" || isNaN($('#txtCardAmount').val())) {
                    alert("Enter a valid card Amount");
                    return;
                }
                else if ($('#txtCardNo').val() == "") {
                    alert("Enter Card No");
                    return;
                }

                paymentmode = "Card";
            }
            if ($("#walletPayment").is(':checked')) {
                paymentmode = "wallet";
            }
            if (paymentmode == '') {
                alert("Please Select your Payment Method");
                return;
            }
            filters.OrderId = $("#txtBillRefNo").text();
            filters.cust_id = $("#txtMemberId").text();
            filters.SpecialNote = $("#txtSpecialNote").val();
            filters.CashAmount = $("#txtCashAmount").val();
            filters.CardAmount = $("#txtCardAmount").val();
            filters.CardNo = $("#txtCardNo").val();
            filters.ChequeAmount = $("#txtChequeAmount").val();
            filters.ChequeNo = $("#txtChequeNo").val();
            filters.ChequeBank = $("#txtBankName").val();
            filters.ChequeDate = $("#txtChequeDate").val();
            filters.walletamt = $("#textwalletamt").val();
            filters.sm_paid = paidamount;
            filters.sessionId = getSessionID();
            filters.timezone = $.cookie("invntryTimeZone");
            filters.lastUpdatedDate=lastUpdatedDate;
            if (filters.CashAmount == '') {
                filters.CashAmount = 0;
            }
            if (filters.CardAmount == '') {
                filters.CardAmount = 0;
            }
            if (filters.ChequeAmount == '') {
                filters.ChequeAmount = 0;
            }
            if (filters.walletamt == '') {
                filters.walletamt = 0;
            }
            //alert($("#txtPreviousBalance").text());
            if (parseFloat($("#txtTotalBalanceAmount").val()) < 0) {
                alert("Paid amount should not be greater than Net Amount");
                return false;
            }

            filters.voucher_no = $("#txtVoucherNum").val();
            filters.po_number = $("#txtPONum").val();
            filters.transDate = dateformat($("#txtTransDate").val());

            //if($("#txtPreviousBalance").text()<=paidamount){
            //    alert("Paid amount greater than the due amount of the bill, please check the value.. ")
            //    return false;
            //}
            $.ajax({
                type: "POST",
                url: "manageorders.aspx/savePayment",
                data: "{'filters':" + JSON.stringify(filters) + "}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    if (msg.d == "N") {
                        alert("Error!.. Please Try Again...");
                        return;
                    } else if(msg.d=="E"){
                        var result = confirm("Some One already changed the page..Do you want to reload and continue ?");
                        if(result){
                            window.location.reload();
                        }else{
                            return;
                        }
                    } else {

                        alert("Order Updated Successfully...!");
                        window.location.reload();
                    }
                },
                error: function (xhr, status) {
                    Unloading();
                    // alert("fail" + status + ":::" + xhr.d);
                    alert("Internet Problem..!");
                }
            });


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
                if(parseFloat(inputtedWallet) > parseFloat(exactwalletamt)){

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
                if (isNaN(parseFloat(walletamt)) || walletamt == undefined || walletamt == "") {
                    walletamt = 0;
                }

            } else {
                walletamt = 0;
            }
            var cashTotal = parseFloat(cashAmount) + parseFloat(chequeAmount) + parseFloat(walletamt)+ parseFloat(cardAmount);

            //   alert(cashTotal);
            $('#txtTotalCurrentAmount').val(cashTotal.toFixed(accuracyNum));

            var balance = parseFloat($('#txtPreviousBalance').text()) - parseFloat(cashTotal);
            // alert(balance);
            $("#txtTotalBalanceAmount").val(balance.toFixed(accuracyNum));


        }

        function refreshpage() {
            selectOrders();
            //  window.location.reload();
        }

        function printbill() {
            //alert($("#lblInvoiceNum").text());
            if($("#lblInvoiceNum").text()==" (Not Yet Billed) "){
                var result = confirm("Invoice number is unavailable for this bill, do you want to continue?");
                if (result) {
                    if (tax_type == 0) {
                        window.location.href = "billreceipt.aspx?orderId=" + BillNo;
                    } else if (tax_type == 1) {
                        window.location.href = "normalBillreceipt.aspx?orderId=" + BillNo;
                    } else if (tax_type == 2) {
                        window.location.href = "gstBillreceipt.aspx?orderId=" + BillNo;
                    }
                }else{
                    return false;
                }
            }else{
                if (tax_type == 0) {
                    window.location.href = "billreceipt.aspx?orderId=" + BillNo;
                } else if (tax_type == 1) {
                    window.location.href = "normalBillreceipt.aspx?orderId=" + BillNo;
                } else if (tax_type == 2) {
                    window.location.href = "gstBillreceipt.aspx?orderId=" + BillNo;
                }
            }
            
            // location.href = "billreceipt.aspx?orderId=" + BillNo;
        }
        //changed by deepika on 02-11-16
        //function for updating order status
        function orderstatuschange(type) {
            var sm_vehicle_no=0;
            if(type==1){
                assignId = $("#selAssignUsers").val();
                var processDate=$("#txtProcessDate").val();
                // alert(assignId);
                if (assignId == -1) {
                    alert("Choose any person for assigning");
                    return false;
                }
                if ($("#chckcmpnyVehicle").prop("checked") == false && $("#chckotherVehicle").prop("checked") == false) {
                    alert("Please select a vehicle type");
                    return false;
                }
                if ($("#chckcmpnyVehicle").prop("checked") == true) {

                    ownVehicleUsed = 1;
                    if ($("#selVehicles").val() == "-1") {

                        alert('please allot a vehicle for the delivery');
                        return;
                    } else {
                       var sm_delivery_vehicle_id = $("#selVehicles").val();
                    }
                }
                if ($("#chckotherVehicle").prop("checked") == true) {
                    ownVehicleUsed = 0;
                    if ($("#txtVehicle").val() == "") {

                        alert('please enter delivery vehicle number');
                        return;
                    } else {
                        sm_vehicle_no = $("#txtVehicle").val();
                    }
                }
                //process date
                var processDate = $("#txtProcessDate").val();
                var processTime = $("#txtProcessTime").val();
                if (processDate != "") {
                    var splitarray = processDate.split("-");
                    processDate = splitarray[2] + "/" + splitarray[1] + "/" + splitarray[0];
                }

                if (processTime != "") {
                    var splitAmPm = processTime.split(" ");
                    var splittime = splitAmPm[0].split(":");
                    if (splitAmPm[1] == "AM" && splittime[0] == "12") {
                        splittime[0] = "00";
                    } else if (splitAmPm[1] == "AM" && splittime[0] != "12") {
                        splittime[0] = splittime[0];
                    }
                    else if (splitAmPm[1] == "PM" && splittime[0] == "12") {
                        splittime[0] = "12";
                    } else {
                        splittime[0] = parseInt(splittime[0]) + 12;
                    }
                    processTime = splittime[0] + ":" + splittime[1] + ":00";
                }
                else {
                    processTime = processTime;
                }
                //process date
                var postObj = {

                    order: {
                        sm_id: BillNo,
                        user_id: $.cookie('invntrystaffId'),
                        time_zone: $.cookie("invntryTimeZone"),
                        order_status: type,
                        packing_status: 1,
                        delivery_man: assignId,
                        vehicle_type: ownVehicleUsed,
                        vehicle_id: sm_delivery_vehicle_id,
                        vehicle_no: sm_vehicle_no,
                        current_packing_status: 0,
                        processedDate:processDate,
                        processedTime:processTime,
                        lastUpdatedDate:lastUpdatedDate
                    }
                };
            }
            else{
                var postObj = {

                    order: {
                        sm_id: BillNo,
                        user_id: $.cookie('invntrystaffId'),
                        time_zone: $.cookie("invntryTimeZone"),
                        order_status: type,
                        lastUpdatedDate:lastUpdatedDate

                    }
                };
            }
            if(type==1){
                var result = confirm("This will generate Invoice/Bill number against this Order(if unavailable).Are you Sure to continue??");
            }else{
                var result = confirm("Do you want to change the status?");
            }
            if (result) {
                loading();
                $.ajax({
                    type: "POST",
                    url: "manageorders.aspx/updateOrderStatus",
                    data: JSON.stringify(postObj),
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (msg) {
                        Unloading();
                        //alert(msg.d);
                        //alert("Success");
                        // return;
                        if (msg.d == "FAILED") {
                            alert("Error!.. Please Try Again...");
                            return;
                        }        else if(msg.d=="E"){
                            var result = confirm("Some One already changed the page..Do you want to reload and continue ?");
                            if(result){
                                window.location.reload();
                            }else{
                                return;
                            }
                        } else {
                            alert("Order Status Updated Successfully...");
                            window.location.reload();
                            return false;
                        }
                    },
                    error: function (xhr, status) {
                        Unloading();
                        alert("Internet Problem..!");
                    }
                });
            } else {
                return false;
            }
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

        function backpage() {
            window.location.href = "orders.aspx?event=back";

        }

        function loadsalesreturnpage() {
            location.href = "salesreturn.aspx?orderId=" + BillNo + "";
        }

        function loadAssignPersons() {
            $.ajax({
                type: "POST",
                url: "manageorders.aspx/loadAssignPersons",
                data: "{'warehouse':'" + $("#selBranches").val() + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    var obj = JSON.parse(msg.d);
                    var htm = "";
                    htm += '<option value="-1" selected="selected">--select--</option>';
                    $.each(obj, function (i, row) {
                        htm += '<option value="' + row.user_id + '">' + row.name + '</option>';
                    });
                    $("#selAssignUsers").html(htm);


                },
                error: function (xhr, status) {
                    Unloading();
                    // alert("fail" + status + ":::" + xhr.d);
                    alert("Internet Problem..!");
                }
            });
        }

        function loadBranches() {
            $.ajax({
                type: "POST",
                url: "manageorders.aspx/loadBranches",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    var obj = JSON.parse(msg.d);
                    var htm = "";
                    htm += '<option value="-1" selected="selected">--select--</option>';
                    $.each(obj, function (i, row) {
                        htm += '<option value="' + row.branch_id + '">' + row.branch_name + '</option>';
                    });
                    $("#selBranches").html(htm);

                },
                error: function (xhr, status) {
                    Unloading();
                    // alert("fail" + status + ":::" + xhr.d);
                    alert("Internet Problem..!");
                }
            });
        }

        function gotoEditOrder() {
            //alert(orderType);
            if (orderType == "1") {
                window.location.href = "editorder.aspx?orderId=" + BillNo;
            }
            else {
                window.location.href = "editoldorderentry.aspx?orderId=" + BillNo;
            }
        }
        //changed by anjana
        function gotoWayBilling() {
            location.href = "printwaybilling.aspx?orderId=" + BillNo;
        }

        function gotoEditWayBill(wayheaderid) {
            window.location.href = "editwaybill.aspx?orderId=" + BillNo + "&headerid=" + wayheaderid;
        }
        //end

        function loadVehicles() {
            if ($("#chckcmpnyVehicle").prop("checked") == true) {
                $.ajax({
                    type: "POST",
                    url: "manageorders.aspx/loadVehicles",
                    data: "{}",
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (msg) {
                        Unloading();
                        var obj = JSON.parse(msg.d);
                        var htm = "";
                        htm += '<option value="-1" selected="selected">--select--</option>';
                        $.each(obj, function (i, row) {
                            htm += '<option value="' + row.user_id + '">' + row.name + '</option>';
                        });
                        $("#selVehicles").html(htm);
                        $("#divCmpnyVehicle").show();
                        $("#divVehicleText").hide();
                        $('#chckotherVehicle').attr('checked', false);

                    },
                    error: function (xhr, status) {
                        Unloading();
                        // alert("fail" + status + ":::" + xhr.d);
                        alert("Internet Problem..!");
                    }
                });
            } else {
                $("#divCmpnyVehicle").hide();
                $("#divVehicleText").hide();
                $('#chckotherVehicle').attr('checked', false);
            }
        }

        function showVehicleDiv() {
            if ($("#chckotherVehicle").prop("checked") == true) {
                $("#divVehicleText").show();
                $("#divCmpnyVehicle").hide();
                $('#chckcmpnyVehicle').attr('checked', false);
            } else {
                $("#divVehicleText").hide();
                $("#divCmpnyVehicle").hide();
                $('#chckcmpnyVehicle').attr('checked', false);
            }
        }

        //showing transaction details
        function showTransactionDetails(trans_id) {
           // var transaction = orderObj.transaction_details.find(x=>x.id == trans_id);
           //// console.log(transaction)
           // $("#lblTransRef").text(transaction.id);
           // $("#transAmount").text((transaction.dr!=0?transaction.dr:transaction.cr));
           // $("#transDate").text(transaction.date);
           // $("#transType").text((transaction.dr != 0 ? "Debit" : "Credit"));
           // $("#transUserName").text(transaction.user_name);
           // $("#transNarration").text(transaction.narration);
           // $("#cashAmt").text(transaction.cash_amt);
           // $("#walletAmt").text(transaction.wallet_amt);
           // $("#chequeAmt").text(transaction.cheque_amt);
           // $("#chequeNo").text(transaction.cheque_no);
           // $("#cardAmt").text(transaction.card_amt);
           // $("#cardNo").text(transaction.card_no);
           // $("#chequeDate").text(transaction.cheque_date);
           // $("#chequeBank").text(transaction.cheque_bank);
            // $("#popupTransaction").modal('show');

            var transaction = orderObj.transaction_details.find(x=>x.id == trans_id);
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

        // get payment edits
        function load_payment_edits() {

            var sm_id = BillNo;
            if (sm_id == 0 || BillNo == undefined) {

                alert('An issue occured! Please reload the page & try again');
                return;
            }

            $.ajax({
                type: "POST",
                url: "manageorders.aspx/load_payment_edits",
                data: "{'sm_id':'" + BillNo + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {

                    if (msg.d == "N") {

                        alert("No payment editing found against this order!");
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

                                changes += "Cash Payment : " + row.tpe_new_cashamt + " (From " + row.tpe_prev_cashamt +")<br/>";
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
                        $("#transType1").html( 'Order Ref: #'+ BillNo)
                        $("#popupPaymentEdits").modal("show")
                    }
                   

                },
                error: function (xhr, status) {
                  
                    alert("Internet Problem..!");
                }
            })
           
        }

        function DownloadXMLFile() {

            if (is_invoiced == 0) {

                alert("Export to Tally is Only Available for Invoiced Orders");
                return;
            }
            
            $.ajax({
                type: "POST",
                url: "manageorders.aspx/DownloadXMLFile",
                data: "{'order_id':'" + BillNo + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    // alert(msg.d);
                    if (msg.d == "N" || msg.d == "0") {
                        alert("Not Orders / Invoices Found to Download!");
                        return false;
                    }
                    else {
                        location.href = "../web_reports/Download_Tally_XML.aspx";
                        return false;
                    }
                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });

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
                        <div class="menu_section">
                            <h3>General</h3>
                            <ul class="nav side-menu">
  
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
            <!-- top navigation -->
            <div class="top_nav">
                <div class="nav_menu">
                    <nav>

                        <div class="navbar-header" style="width: 100%; display: flex; align-items: center">
                            <div class="nav toggle" style="padding: 5px;">
                                <a id="menu_toggle"><i class="fa fa-bars"></i></a>
                            </div>
                            <div class="col-md-10 col-md-10 col-xs-6">
                                <label style="font-weight: bold; font-size: 16px;">Manage Order / Invoice</label>
                            </div>

                            <div class="col-md-6 col-xs-8">
                                <label onclick="javascript:backpage();" class="btn btn-success btn-xs pull-right" style="background-color: #1240d8; border-color: #1240d8;">
                                    <label style="color: #fff; font-size: 14px;" class="fa fa-arrow-left" title="Back"></label>
                                </label>
                                <%-- chnaged by anjana --%>
                                <div class="btn btn-primary btn-xs pull-right" id="divWaybilling" style="display: ; background-color: #109ead" onclick="javascript:gotoWayBilling();">
                                    <label class="fa fa-file-text" style="padding-right: 3px;"></label>
                                    WayBilling
                                </div>
                                <%-- end --%>
                                <div class="btn btn-success btn-xs pull-right" onclick="javascript:gotoEditOrder();"  id="btnEditOrder">
                                    <label class="fa fa-pencil"></label> <b>Edit Order</b>
                                </div>
                                <div class="btn btn-success btn-xs pull-right" onclick="javascript:printbill();" style="background-color: #00b7fd; border-color: #008fc5;cursor:pointer" id="divprintorder">
                                   <label class="fa fa-print"></label> <b>Print</b>
                                </div>

                                <div class="btn btn-success btn-xs pull-right" onclick="javascript:DownloadXMLFile();" style="background-color: #008fc5;display:none; border-color: #008fc5;cursor:pointer" id="tdExportBtn">
                                   <label class="fa fa-upload"></label> <b>Export to Tally</b>
                                </div>

                              
                                    
                            </div>

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
            
                    <div class="clearfix"></div>

                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12">


                            <div class="x_panel">
                                <div class="x_title" style="margin-bottom: 0px;">
                                    <ul class="nav navbar-right panel_toolbox pull-right">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                        </li>
                                    </ul>
                                    Bill Id
                                    <label id="lblInvoiceNum"></label>
                                    (<label id="txtBillRefNo"></label>)<a id="txtLabelStatus"></a>

                                </div>
                                <div class="x_content">
                                    <!-- info row -->
                                    <div class="row invoice-info">
                                        <div class="col-sm-4 ">

                                            <b>Bill Date</b>
                                            <span style="font-weight: bold;">:</span>
                                            <label id="txtOrderDate"></label>


                                        </div>
                                        <!-- /.col -->
                                        <div class="col-sm-5">
                                            <b>Customer </b>

                                            <span style="font-weight: bold;">:</span>  <a style="text-decoration: underline" href="" id="hrefCustomer" target="_blank"><span id="txtMemberId"></span></a>&nbsp;<label id="txtMemberName"></label><%--(class <span id="txtClassType"></span>)--%> 
                                        </div>
                                        <!-- /.col -->

                                      
                                        <div class="col-sm-3">
                                            <b>Account Balance:</b>
                                            <span style="font-weight: bold;">:</span>
                                            <label id="lbloutstanding" style="color: #432727; font-weight: bold; font-size: 12px; color: red;">0</label>
                                        </div>
                                        <!-- /.col -->

                                        <input type="hidden" id="txtdeliverystatus" />
                                        <!-- /.col -->
                                    </div>



                                    <!-- Modal -->
                                    <div class="modal fade" id="popupAssign" role="dialog">
                                        <div class="modal-dialog modal-md" style="">

                                            <!-- Modal content-->
                                            <div class="modal-content">
                                                <div class="modal-header" style="padding-bottom: 5px;">
                                                    <button type="button" class="close" data-dismiss="modal">&times;</button>
                                                    <div class="col-md-6 col-sm-6 col-xs-12">
                                                        <h4 class="modal-title"><b>ASSIGN</b></h4>
                                                    </div>
                                                </div>
                                                <div class="col-md-12 col-sm-12 col-xs-12" style="overflow-x: auto; margin-top: 5px;">
                                                    <div class="x_content">
                                                        <div class="col-md-12 col-sm-12 col-xs-12 ">
                                                            <form class="form-horizontal form-label-left">
                                                                 <div class="form-group">

                                                                    <label class="col-md-4 col-sm-3 col-xs-12" for="first-name">
                                                                        Process Date(Invoice Date):
                                                                    </label>
                                                                    <div class="col-md-4 col-sm-6 col-xs-12">
                                                                        <input type="text" id="txtProcessDate" placeholder="Choose Date" class="form-control has-feedback-left" style="height: 28px;" />
                                                                        <span class="fa fa-calendar form-control-feedback left" aria-hidden="true"></span>
                                                                    </div>
                                                                     <div class="form-group col-md-4 col-sm-6 col-xs-6">
                                                            <input type="text" id="txtProcessTime" placeholder="00:00:00" required="required" class="form-control has-feedback-left" readonly="" style="height: 28px;">
                                                            <span class="fa fa-clock-o form-control-feedback left" aria-hidden="true"></span>
                                                        </div>

                                                                </div>

                                                                <div class="form-group">
                                                                    <label class="col-md-4 col-sm-3 col-xs-12" for="first-name">
                                                                        Person for delivery:
                                                                    </label>
                                                                    <div class="col-md-8 col-sm-6 col-xs-12">
                                                                        <div id="Div2">
                                                                            <select id="selAssignUsers" class="form-control">
                                                                                <option value="0">--Select--</option>
                                                                            </select>
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                                <div class="form-group">
                                                                    <label class="col-md-4 col-sm-3 col-xs-12" for="first-name">
                                                                        Vechicle Type:
                                                                    </label>
                                                                    <div class="col-md-8 col-sm-6 col-xs-12">
                                                                        Company Vehicle
                                                                        <input type="checkbox" value="" id="chckcmpnyVehicle" onclick="javascript: loadVehicles();">
                                                                        Other Vehicle
                                                                        <input type="checkbox" value="" id="chckotherVehicle" onclick="javascript: showVehicleDiv();">
                                                                    </div>

                                                                </div>
                                                                <div class="form-group" style="display: none;" id="divCmpnyVehicle">

                                                                    <label class="col-md-4 col-sm-3 col-xs-12" for="first-name">
                                                                        Select Vechicle:
                                                                    </label>
                                                                    <div class="col-md-8 col-sm-6 col-xs-12">
                                                                        <div>
                                                                            <select id="selVehicles" class="form-control">
                                                                                <option value="0">--Select--</option>
                                                                            </select>
                                                                        </div>
                                                                    </div>

                                                                </div>
                                                                <div class="form-group" style="display: none;" id="divVehicleText">

                                                                    <label class="col-md-4 col-sm-3 col-xs-12" for="first-name">
                                                                        Vehicle No:
                                                                    </label>
                                                                    <div class="col-md-8 col-sm-6 col-xs-12">
                                                                        <input type="text" id="txtVehicle" placeholder="enter vehicle number" class="form-control" style="height: 25px;" />
                                                                    </div>

                                                                </div>
                                                                <div class="clearfix"></div>

                                                            </form>

                                                        </div>

                                                    </div>
                                                </div>
                                                <div class="clearfix"></div>
                                                <div class="ln_solid"></div>
                                                <div class="form-group" style="padding-bottom: 40px;">
                                                    <div class="col-md-6 col-sm-6 col-xs-12 col-md-offset-5">

                                                        <div class="btn btn-success mybtnstyl" onclick="javascript:orderstatuschange(1);">
                                                            Assign
                                                        </div>

                                                    </div>
                                                </div>
                                            </div>

                                        </div>
                                    </div>
                                    <!-- /.row -->
                                </div>
                                <div class="clear"></div>


                            </div>
                        </div>
                        <div class="col-md-12 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title" style="margin-bottom: 0px;">
                                    <ul class="nav navbar-right panel_toolbox pull-right">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                        </li>
                                    </ul>
                                    <label>Track Status</label>

                                </div>
                                <div class="x_content">
                                    <div class="row" style="margin-top: 10px;">

                                        <div class="col-md-7" id="divStatusData">

                                        





                                        </div>
                                        <div class="col-sm-5 " style="padding-right: 50px;">
                                            <div class="btn btn-danger pull-right mybtnstyl" id="divCancel" style="display: none;" onclick="orderstatuschange(4)">Cancel</div>
                                            <div class="btn btn-primary pull-right mybtnstyl" id="divAssign" style="display: none;" onclick="" data-toggle="modal" data-target="#popupAssign">Assign</div>
                                            <div class="btn btn-warning pull-right mybtnstyl" id="divNew" style="display: none;" onclick="orderstatuschange(0)">New</div>
                                            <div class="btn btn-success pull-right mybtnstyl" id="divDeliver" style="display: none;" onclick="orderstatuschange(2)">Deliver</div>
                                            <div class="btn btn-success pull-right mybtnstyl" id="divApprove" style="display: none;" onclick="orderstatuschange(7)">Approve</div>
                                            <div class="btn btn-danger pull-right mybtnstyl" id="divReject" style="display: none;" onclick="orderstatuschange(5)">Reject</div>
                                            <div class="btn btn-default pull-right mybtnstyl" id="divPending" style="display: none;" onclick="orderstatuschange(6)">Pending</div>
                                            <div class="btn btn-default pull-right mybtnstyl" id="divConfirm" style="display: none; background-color: #6facd5; color: #ffffff" onclick="orderstatuschange(3)">To be confirm</div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="clearfix"></div>

                        <div class="col-md-12 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title">
                                    <label>Items</label>
                                    <ul class="nav navbar-right panel_toolbox">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                        </li>
                                    </ul>
                                   
                                </div>

                                <%--<div class="row">
					<div class="col-sm-6">
					<div class="dataTables_length" id="datatable-checkbox_length">
                        <label>
                         <select name="datatable-checkbox_length" aria-controls="datatable-checkbox" class="form-control input-sm">
                             <option value="10">10</option>
                             <option value="25">25</option>
                             <option value="50">50</option>
                             <option value="100">100</option>
                         </select> 
                        </label>
					</div>
					</div>
					
					<div class="form-group"  style="float:right;">
								<div class="col-md-12 col-sm-12 col-xs-12 ">
								  <button type="submit" class="btn btn-success">
								  <li class="fa fa-search" style="margin-right:5px;"></li>Search
								  </button>
								     <button class="btn btn-primary" type="reset">
									 <li class="fa fa-refresh" style="margin-right:5px;"></li>Reset
									 </button>
								</div>
							  </div>
					</div>--%>
                                <div class="col-md-12 col-sm-12 col-xs-12" style="overflow-x: auto;">
                                    <div class="x_content">

                                        <table id="tblOrderItems" class="table table-striped jambo_table bulk_action table-bordered" style="table-layout: auto;">
                                            <thead style="background-color:#f1eeee;color:#525252">
                                                <tr>
                                                    <th>Item Code</th>
                                                    <th style="width: 300px;">Name</th>
                                                    <th>RealPrice	</th>
                                                    <th>SalePrice</th>
                                                    <th>QTY</th>
                                                    <th>FOC</th>
                                                    <th>Amt</th>
                                                    <th>Dis %</th>
                                                    <th>Dis Amt</th>
                                                    <th>Taxable Value</th>
                                                    <th>Tax Amt</th>
                                                    <th>Net Amt</th>
                                                    <th>Paid</th>
                                                    <th>Balance</th>


                                                </tr>
                                            </thead>


                                            <tbody id="tbodyItems">
                                            </tbody>
                                            <tbody id="tbodyPayments">


                                                <tr>
                                                    <td colspan="4" style="text-align: right;"><b>Round Off Value: <label id="lblRoundoff" style="color:#900c0c"></label></b></td>
                                                    <td colspan="7" style="text-align: right;"><b>Total</b></td>

                                                    <td>
                                                        <label id="txtTotalAmt">0</label></td>
                                                    <td>
                                                        <label id="">--</label></td>
                                                    <td>
                                                        <label id="">--</label></td>

                                                </tr>
                                                <tr>
                                                    <td colspan="12" style="text-align: right;"><b>Previous Payment</b></td>

                                                    <td style="font-weight: bold;">
                                                        <label id="txtPreviousPaid"></label>
                                                    </td>
                                                    <td style="font-weight: bold;">
                                                        <label id="txtPreviousBalance"></label>
                                                    </td>

                                                </tr>
                                                <tr>
                                                    <td colspan="12" style="text-align: right;"><b>Current Payment</b></td>
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

                        <div class="clearfix"></div>
                        <%-- Cas,Card,Cheque start--%>

                        <div class="col-md-12 col-sm-12 col-xs-12">
                            <div class="x_panel" style="background: #eeeeee;">
                                <div class="col-md-12 col-sm-12 col-xs-12" style="padding-left: 0px; padding-right: 0px;">
                                    <div class="col-md-4 col-sm-6 col-xs-12" style="padding-left: 0px; padding-right: 0px;">
                                        <div class="col-md-2 col-sm-1 col-xs-2" style="padding-right: 0px;">
                                            <div class="checkbox">
                                                <label style="font-size: 1.3em">
                                                    <input type="checkbox" value="" id="cbCashPayment" onclick="javascript: paymentMethod();">
                                                    <span class="cr"><i class="cr-icon fa fa-check"></i></span>
                                                </label>
                                            </div>
                                            <%--                                            <input type="checkbox"   class="flat" />--%>
                                        </div>

                                        <div class="col-md-4 col-sm-4 col-xs-4" style="line-height: 3; padding-left: 0px;"><b>CASH</b> </div>
                                        <div class="clearfix"></div>
                                        <div class="col-md-3 col-sm-6 col-xs-12">CashAmt</div>
                                        <div class="col-md-9 col-sm-6 col-xs-12">
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

                                    

                                    <div class="col-md-4 col-sm-6 col-xs-12" style="padding-left: 0px; padding-right: 0px">
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
                                        <div class="col-md-4 col-sm-6 col-xs-12">Cheque Amt.</div>
                                        <div class="col-md-8 col-sm-6 col-xs-12">
                                            <input type="text" id="txtChequeAmount" class="form-control" style="height: 25px; margin-bottom: 5px;" placeholder="Enter amt." onkeyup="javascript:paymentMethod();" />
                                        </div>
                                        <div class="clearfix"></div>
                                        <div class="col-md-4 col-sm-6 col-xs-12">Cheque No.</div>
                                        <div class="col-md-8 col-sm-6 col-xs-12">
                                            <input type="text" id="txtChequeNo" class="form-control" style="height: 25px; margin-bottom: 5px;" placeholder="Enter No." />
                                        </div>
                                        <div class="clearfix"></div>
                                        <div class="col-md-4 col-sm-6 col-xs-12">Date</div>
                                        <div class="col-md-8 col-sm-6 col-xs-12">
                                            <input type="text" id="txtChequeDate" class="form-control" style="height: 25px; margin-bottom: 5px;" placeholder="Enter Date" />
                                        </div>
                                        <div class="clearfix"></div>
                                        <div class="col-md-4 col-sm-6 col-xs-12">Bank</div>
                                        <div class="col-md-8 col-sm-6 col-xs-12">
                                            <input type="text" id="txtBankName" class="form-control" style="height: 25px; margin-bottom: 5px;" placeholder="Enter Bank" />
                                        </div>
                                        <div class="clearfix"></div>
                                    </div>

                                    <div class="col-md-4 col-sm-6 col-xs-12" style="padding-left: 0px; padding-right: 0px;">
  
    <div class="col-md-4 col-sm-4 col-xs-4" style="line-height: 3; padding-left: 0px;"><b>References</b> </div>
    <div class="clearfix"></div>
    <div class="col-md-3 col-sm-6 col-xs-12">Voucher No.</div>
    <div class="col-md-9 col-sm-6 col-xs-12">
        <input type="text" id="txtVoucherNum" class="form-control" style="height: 25px; margin-bottom: 5px;" placeholder="Enter Voucher No. (optional)" autocomplete="off"/>
    </div>
    <div class="clearfix"></div>
    <div class="col-md-3 col-sm-6 col-xs-12">P.O. No.</div>
    <div class="col-md-9 col-sm-6 col-xs-12">
        <input type="text" id="txtPONum" class="form-control" style="height: 25px; margin-bottom: 5px;" placeholder="Enter P.O. No. (optional)" autocomplete="off" />
    </div>
    <div class="clearfix"></div>

                                                                                        <hr />
                                        <div class="col-md-3 col-sm-6 col-xs-12">Transaction Date</div>

                                                                                               <div class="col-md-9 col-sm-6 col-xs-12">
     <input type="text" id="txtTransDate" class="form-control" style="height: 25px; margin-bottom: 5px;" />
 </div>

</div>

                                    <div class="col-md-4 col-sm-6 col-xs-12" style="padding-left: 0px; padding-right: 0px;display:none">
                                        <div class="col-md-2 col-sm-1 col-xs-2" style="padding-right: 0px;">
                                            <div class="checkbox">
                                                <label style="font-size: 1.3em">
                                                    <input type="checkbox" value="" id="cbCardPayment" onclick="javascript: paymentMethod();">
                                                    <span class="cr"><i class="cr-icon fa fa-check"></i></span>
                                                </label>
                                            </div>

                                        </div>
                                        <div class="col-md-4 col-sm-4 col-xs-4" style="line-height: 3; padding-left: 0px;"><b>CARD</b> </div>
                                        <div class="clearfix"></div>
                                        <div class="col-md-3 col-sm-6 col-xs-12">Card Amt</div>
                                        <div class="col-md-9 col-sm-6 col-xs-12">
                                            <input type="text" id="txtCardAmount" class="form-control" style="height: 25px; margin-bottom: 5px;" placeholder="Enter amt." onkeyup="javascript:paymentMethod();" value="0" />
                                        </div>
                                        <div class="clearfix"></div>
                                        <div class="col-md-3 col-sm-6 col-xs-12">Card No</div>
                                        <div class="col-md-9 col-sm-6 col-xs-12">
                                            <input type="text" id="txtCardNo" class="form-control" style="height: 25px; margin-bottom: 5px;" placeholder="Enter No" />
                                        </div>
                                        <div class="clearfix"></div>
                                        <div class="col-md-5 col-sm-6 col-xs-12" style="display:none">Card Type</div>
                                        <div class="col-md-7 col-sm-6 col-xs-12" style="display:none">
                                            <input type="text" id="txtCardType" class="form-control" style="height: 25px; margin-bottom: 5px;" placeholder="Enter Type" />
                                        </div>
                                        <div class="clearfix"></div>
                                        <div class="col-md-5 col-sm-6 col-xs-12" style="display:none">Bank</div>
                                        <div class="col-md-7 col-sm-6 col-xs-12" style="display:none">
                                            <input type="text" id="txtCardBank" class="form-control" style="height: 25px; margin-bottom: 5px;" placeholder="Enter Bank" />
                                        </div>
                                        <div class="clearfix"></div>
                                    </div>

                                    <div class="col-md-12 col-sm-6 col-xs-12" style="padding-left: 0px; padding-right: 0px">

                                        <div class="col-md-8 col-sm-6 col-xs-12"><b>Special Notes</b> </div>
                                        <div class="clearfix"></div>

                                        <div class="col-md-11 col-sm-12 col-xs-12" style="">
                                            <textarea id="txtSpecialNote" class="form-control" style="resize: none;height: 73px;margin: 0px -645.672px 0px 0px;/* width: 801px; */"></textarea>
                                        </div>
                                        

                                        <div class="col-md-1 col-sm-3 col-xs-3" style="margin-top: 20px;" id="divsaveorder" onclick="javascript:savePayment();">
                                            <button class="btn btn-primary pull-right" style="font-weight:bold;"  type="button">Save</button>
                                        </div>
                                        <div class="clearfix"></div>
                                     

                                       

                                    </div>
                                </div>

                            </div>
                        </div>

                        <%-- Cas,Card,Cheque End--%>

                        <div class="clearfix"></div>

                        <div class="col-md-12 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title">
                                    <label class="pull-left">Transaction History</label>

                                    
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
                                                    <th>Voucher No.</th>
                                                    <th>P.O Number</th>
                                                    <th>User</th>
                                                    <th>Amount</th>
                                                    <th>Closing Balance</th>
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
                                    <div class="col-md-6" style="margin-bottom: 10px;"><b>Amount :</b><span id="transAmount"></span></div>
                                    <div class="col-md-6" style="margin-bottom: 10px;"><b>Date :</b><span id="transDate"></span></div>
                                    <div class="col-md-6" style="margin-bottom: 10px;"><b>Type :</b><span id="transType"></span></div>
                                    <div class="col-md-6" style="margin-bottom: 10px;"><b>User :</b><span id="transUserName"></span></div>
                                    <div class="col-md-12"><b>Narration :</b><p id="transNarration" style="text-indent: 20px;"></p>
                                    </div>
                                    <div class="col-md-6" style="margin-bottom: 10px;">
                                        <b>Cash</b><br />
                                        <div style="margin-left: 10px;">Amount :<span id="cashAmt">0</span></div>
                                        <br />
                                        <b>Wallet</b><br />
                                        <div style="margin-left: 10px;">Amount :<span id="walletAmt">0</span></div>
                                    </div>
                                    <div class="col-md-6" style="margin-bottom: 10px;">
                                        <b>Cheque</b><br />
                                        <div style="margin-left: 10px;">
                                            Amount :<span id="chequeAmt">0</span><br />
                                            number :<span id="chequeNo"></span><br />
                                            Date :<span id="chequeDate"></span><br />
                                            Bank :<span id="chequeBank"></span>
                                        </div>
                                    </div>
                                      <div class="col-md-6" style="margin-bottom: 10px;">
                                        <b>Card</b><br />
                                        <div style="margin-left: 10px;">
                                            Amount :<span id="cardAmt">0</span><br />
                                            number :<span id="cardNo"></span><br />
                                      
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

                        <div class="col-md-12 col-sm-12 col-xs-12" style="display: none;" id="divReturnDetails">
                            <div class="x_panel">
                                <div class="x_title">
                                    <label>Returns</label>
                                    <ul class="nav navbar-right panel_toolbox">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                        </li>


                                    </ul>
                                </div>


                                <div class="col-md-12 col-sm-12 col-xs-12" style="overflow-x: auto;">
                                    <div class="x_content">

                                        <table id="tblReturnDetails" class="table table-striped table-bordered" style="table-layout: auto;">
                                            <thead>
                                                <tr>
                                                    <th>No</th>
                                                    <th>Item Code</th>
                                                    <th>Item Name</th>
                                                    <th>Qty</th>
                                                    <th>Price</th>
                                                    <th>Discount</th>
                                                    <th>Total</th>

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

                                                </tr>



                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="clearfix"></div>

                        <div class="col-md-12 col-sm-12 col-xs-12" style="display:none;">
                            <div class="x_panel">
                                <div class="x_title">
                                    <label>Way Billing History</label>
                                    <ul class="nav navbar-right panel_toolbox">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                        </li>


                                    </ul>
                                </div>


                                <div class="col-md-12 col-sm-12 col-xs-12" style="overflow-x: auto;">
                                    <div class="x_content">

                                        <table id="tblWayBillingDetails" class="table table-striped" style="table-layout: auto;">
                                            <thead>
                                                <tr>
                                                    <th>Id</th>
                                                    <th>Date</th>
                                                    <th>Bill No.</th>
                                                    <th>Billed by</th>
                                                    <%--<th>Notes</th>--%>
                                                    <th>Edit</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>
                        </div>

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
