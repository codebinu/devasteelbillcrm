<%@ Page Language="C#" AutoEventWireup="true" CodeFile="printwaybilling.aspx.cs" Inherits="web_sales_printwaybilling" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">

<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Invoice Me</title>
    <script src="../js/common.js" type="text/javascript"></script>
    <script type="text/javascript" src="../js/jquery-2.0.3.js"></script>
    <script type="text/javascript" src="../js/jquery.cookie.js"></script>
    <!-- Bootstrap -->
    <link href="../css/bootstrap/bootstrap.min.css" rel="stylesheet" />
    <!-- Font Awesome -->
    <link href="../css/font-awesome/css/font-awesome.min.css" rel="stylesheet" />
    <!-- NProgress -->
    <link href="../css/bootstrap/nprogress.css" rel="stylesheet" />
    <!-- Custom Theme Style -->
    <link href="../css/bootstrap/custom.min.css" rel="stylesheet" />
    <!--My Styles-->
    <link href="../css/bootstrap/mystyle.css" type="text/css" rel="stylesheet" />

    <style media="print">
        @page {
            size: auto;
            margin: 0;
        }

        thead {
            display: table-header-group;
        }

        #header, #footer {
            display: none;
        }

        @media print {
            #header, #footer {
                position: fixed;
                display: block;
                top: 0;
            }

            #footer {
                bottom: 0;
            }
        }
    </style>

    <script type="text/javascript">

        $(document).ready(function () {
            $("#slPrintType").val(-1);

            $("#spanPrintType").text("");

            showBillReceipt();


        });

        function sendPdfmail(billno) {
            //var jSon = JSON.stringify({ htm: $("#divReceiptDetails").html() });
            //,'mailid': 'fredpjoseph@yahoo.com'
            //billreceipt.aspx/SendPDFAttchedMail

            //alert(jSon);
            $.ajax({
                type: "POST",
                url: "../wm/sendpdfmail.asmx/sendmail",
                data: "{'billno':'" + billno + "','email':'testp7741@gmail.com'}",
                contentType: "application/json; charset=utf-8",
                datatype: "json",
                success: function (msg) {
                    //alert(msg.d)
                },
                error: function (xhr, status) {
                    alert(status);
                }

            });
        }

        function showBillReceipt() {
            var billno = getQueryString("orderId");
            // alert(billno);
            if (!billno || billno == "" || billno == 0) {
                location.href = "../login.aspx";
                return false;
            }

            loading();
            $.ajax({
                type: "POST",
                url: "gstBillreceipt.aspx/showBillReceipt",
                data: "{'billno':'" + billno + "'}",
                contentType: "application/json; charset=utf-8",
                datatype: "json",
                success: function (msg) {

                    var htm = "";
                    //showing div
                    $("#divReceiptDetails").show();
                    Unloading();
                    // console.log(msg.d);
                    var obj = JSON.parse(msg.d);
                    // console.log(obj);
                    // setting order details

                    // adding order items
                    var sl_no = 0;
                    var cgstAmt = 0;
                    var sgstAmt = 0;
                    var igstAmt = 0;
                    $.each(obj.items, function (i, row) {
                        htm = "";
                        if (sl_no % 43 == 0 && sl_no != 0) {

                            htm += "<tr><td colspan='17' style='text-align:right; font-weight:bold;'></br></br>Continue...</br></br></td></tr>";
                            htm += "<tr><td colspan='17' style='text-align:left; font-weight:bold;border-left:1px solid #fff;border-right:1px solid #fff;padding-top:30px;'>";
                            if ($("#slPrintType").val() == 1) {
                                htm += '<div style="width: 1000px; margin: auto; font-weight: bold; text-align: center; font-size: 16px;">Tax Invoice <span style="float: right; font-weight: normal; font-size: 12px;" id="spanPrintType">(DUPLICATE FOR TRANSPORTER)</span> </div>';
                            } else if ($("#slPrintType").val() == 2) {
                                htm += '<div style="width: 1000px; margin: auto; font-weight: bold; text-align: center; font-size: 16px;">Tax Invoice <span style="float: right; font-weight: normal; font-size: 12px;" id="spanPrintType">(ORIGINAL FOR RECIPIENT)</span> </div>';
                            } else if ($("#slPrintType").val() == 3) {
                                htm += '<div style="width: 1000px; margin: auto; font-weight: bold; text-align: center; font-size: 16px;">Tax Invoice <span style="float: right; font-weight: normal; font-size: 12px;" id="spanPrintType">(TRIPLICATE FOR SUPPLIER)</span> </div>';
                            } else {
                                htm += '<div style="width: 1000px; margin: auto; font-weight: bold; text-align: center; font-size: 16px;">Tax Invoice </div>';
                            }


                            var style = "style=display:block";
                            var styleEmail = "";
                            htm += '<div style="width: 100%; border: 1px solid #73879c;">';
                            htm += '<div style="width: 100%; float: left;">';
                            htm += '<div style="width: 50%; min-height: 160px; float: left; padding: 10px; border-right: 1px solid #73879c; border-bottom: 1px solid #73879c;">';
                            var branchdata = obj.branch[0].branch_invoice_address;
                            htm += '' + branchdata + ''

                            htm += '</div>';
                            htm += '<div style="width: 50%; min-height: 160px; float: left; padding: 10px; border-bottom: 1px solid #73879c;">';
                            htm += '<div>Name & Address of Customer</div>';
                            htm += '<div>';
                            htm += '<label for="" id="" style="margin-bottom: 0px; font-size: 15px;">' + obj.order[0].cust_name + '</label>';
                            htm += '</div>';
                            htm += '<div id="">' + obj.order[0].address + '</div>';
                            htm += '<div id="">' + obj.order[0].city + '</div>';
                            htm += '<div id="">State : ' + obj.order[0].state_name + '</div>';

                            //htm += ' <div style="float: left;">';
                            //if (obj.order[0].email == "" || obj.order[0].email == null || obj.order[0].email == 'null') {
                            //}
                            //else {

                            //    htm += '<span style="margin-right:5px;">Email:' + obj.order[0].email + '</span>';
                            //}

                            //if (obj.order[0].phone == "" || obj.order[0].phone == null || obj.order[0].phone == 'null') {

                            //}
                            //else {

                            //    htm += '<span><label>Mobile No</label>:' + obj.order[0].phone + '</span><br />';
                            //}

                            //if (obj.order[0].gst != "" && obj.order[0].gst != "null" && obj.order[0].gst != null) {

                            //    htm += '<span><label>GSTIN/UINL</label>:' + obj.order[0].gst + '</span>';

                            //}
                            //else {
                            //    htm += '<span><label>GSTIN/UINL</label>: UNREGISTERED</span>';                               
                            //}
                            //htm += '</div>';




                            if (obj.order[0].email == "" || obj.order[0].email == null || obj.order[0].email == 'null') {
                                styleEmail = "display:none";
                            }
                            htm += ' <div style="float: left;"><span id="" style="margin-right:5px;' + styleEmail + '">Email:' + obj.order[0].email + '</span>';

                            if (obj.order[0].phone == "" || obj.order[0].phone == null || obj.order[0].phone == 'null') {
                                style = "style=display:none";
                            }
                            htm += '<span ' + style + '><label>Mobile No</label>:' + obj.order[0].phone + '</span></div>';

                            if (obj.order[0].gst != "" && obj.order[0].gst != "null" && obj.order[0].gst != null) {
                                htm += ' <div id="" style="float: right; font-weight: bold;">GSTIN/UINL:' + obj.order[0].gst + '</div>';
                            }
                            else {

                                htm += ' <div id="" style="float: right; font-weight: bold;">GSTIN/UINL: UNREGISTERED</div>';
                            }


                            htm += ' </div>';
                            htm += ' </div>';
                            htm += ' <div style="clear: both;"></div>';
                            htm += ' <div style="float: left; width: 50%; border-left: none; border-right: 1px solid #73879c; padding: 10px;">';
                            htm += ' <table style="width: 100%;">';
                            htm += ' <tr>';
                            htm += '<td style="font-weight: bold;">Invoice No&nbsp &nbsp&nbsp&nbsp:';
                            if (obj.order[0].invoiceNum != null || obj.order[0].invoiceNum != 'null' || obj.order[0].invoiceNum == "") {
                                htm += ' <label id="" style="font-size: 15px;">#' + obj.order[0].invoiceNum + '</label>';
                            }
                            else {
                                htm += ' <label id="" style="font-size: 15px;">#' + obj.order[0].invoiceNum + '</label>';
                            }

                            htm += ' <label id="" style="font-size: 15px;">' + obj.order[0].sm_refno + '</label>';
                            htm += ' </td>';
                            htm += ' <td style="font-weight: bold;">Date:';
                            htm += ' <label id="" style="font-size: 15px;">' + obj.order[0].sm_date + '</label>';
                            htm += ' </td>';
                            htm += ' </tr>';
                            htm += ' <tr>';
                            htm += '<td>&nbsp</td>';
                            htm += '</tr>';
                            htm += ' <tr>';
                            htm += ' <td style="font-weight: bold">Delivery Note:';
                            htm += ' </td>';
                            htm += ' <td style="font-weight: bold">Mode/Term of Payments:';
                            htm += ' </td>';
                            htm += ' </tr>';
                            htm += '</table>';
                            htm += '</div>';
                            htm += '<div style="float: left; width: 50%; border-left: none; padding: 10px;">';
                            htm += '<table style="width: 100%;">';
                            htm += '<tr>';
                            htm += ' <td colspan="2" style="font-weight: bold; font-size: 15px; text-transform: uppercase;">Terms of Delivery<br />';
                            htm += '</td>';

                            htm += '</tr>';
                            htm += '</table>';
                            htm += '</div>';
                            htm += '<div style="clear: both;"></div>';
                            htm += '</div>';
                            htm += '<div style="clear: both;"></div>';

                            htm += '<tr>';
                            htm += '<td class="tablefonthead" style="font-weight: bold; font-size: 12px; text-align: center;">Sl No</td>';
                            htm += '<td class="tablefonthead" style="font-weight: bold; font-size: 12px; text-align: center;">HSN SAC</td>';
                            htm += '<td class="tablefonthead" style="font-weight: bold; font-size: 12px; text-align: center;">Description of Goods</td>';
                            htm += '<td class="tablefonthead" style="font-weight: bold; font-size: 12px; text-align: center;">Qty</td>';
                            htm += '<td class="tablefonthead" style="font-weight: bold; font-size: 12px; text-align: center;">FOC</td>';
                            htm += '<td class="tablefonthead" style="font-weight: bold; font-size: 12px; text-align: center;">Price</td>';
                            htm += '<td class="tablefonthead" style="font-weight: bold; font-size: 12px; text-align: center;">Amt</td>';
                            htm += '<td class="" style="text-align: center; font-size: 12px;"><span style="font-weight: bold;">Disc</span>';
                            htm += '<table cellspacing="0" cellpadding="0" width="100%">';
                            htm += '<tbody>';
                            htm += '<tr>';
                            htm += '<td class="tablefonthead bordertopbot" style="width: 50%;">%</td>';
                            htm += '<td class="tablefonthead bodertopleft">Amt</td>';
                            htm += '</tr>';
                            htm += '</tbody>';
                            htm += '</table>';
                            htm += '</td>';
                            htm += '<td class="tablefonthead" style="font-weight: bold; font-size: 12px; width: 60px; text-align: center;">Taxable Value</td>';
                            htm += '<td class="" style="text-align: center; font-size: 12px;"><span style="font-weight: bold;">CGST</span>';
                            htm += '<table cellspacing="0" cellpadding="0" width="100%">';
                            htm += '<tbody>';
                            htm += '<tr>';
                            htm += '<td class="tablefonthead bordertopbot" style="width: 30%;">%</td>';
                            htm += '<td class="tablefonthead bodertopleft">Amt</td>';
                            htm += '</tr>';
                            htm += '</tbody>';
                            htm += '</table>';
                            htm += '</td>';
                            htm += '<td class="" style="text-align: center; font-size: 12px;"><span style="font-weight: bold;">SGST</span>';
                            htm += '<table cellspacing="0" cellpadding="0" width="100%">';
                            htm += '<tbody>';
                            htm += '<tr>';
                            htm += '<td class="tablefonthead bordertopbot" style="width: 30%;">%</td>';
                            htm += '<td class="tablefonthead bodertopleft">Amt</td>';
                            htm += '</tr>';
                            htm += '</tbody>';
                            htm += '</table>';
                            htm += '</td>';
                            htm += '<td class="" style="text-align: center; font-size: 12px;"><span style="font-weight: bold;">IGST</span>';
                            htm += '<table cellspacing="0" cellpadding="0" width="100%">';
                            htm += '<tbody>';
                            htm += '<tr>';
                            htm += '<td class="tablefonthead bordertopbot" style="width: 30%;">%</td>';
                            htm += '<td class="tablefonthead bodertopleft">Amt</td>';
                            htm += '</tr>';
                            htm += '</tbody>';
                            htm += '</table>';
                            htm += '</td>';
                            htm += '<td class="tablefonthead" style="font-weight: bold; font-size: 12px; width: 70px; text-align: center">Net Amt</td>';
                            htm += '</tr>';


                        }
                        sl_no++;
                        // alert(((row.taxableValue) * (row.cgst) / 100).toFixed(2));
                        cgstAmt += parseFloat(((row.taxableValue) * (row.cgst) / 100));
                        sgstAmt += parseFloat(((row.taxableValue) * (row.sgst) / 100));
                        igstAmt += parseFloat(((row.taxableValue) * (row.igst) / 100));
                        htm += '<tr style="font-size:20px;">';
                        htm += '<td class="tablefont" style="text-align:center;">' + sl_no + '</td>';
                        htm += '<td class="tablefont" style="text-align:center;">' + row.tp_tax_code + '</td>';
                        htm += '<td class="tablefont" style="text-align:left; padding-left:5px;">' + row.itm_name + '</td>';

                        htm += '<td class="tablefont" style="text-align:center;">' + row.qty + '</td>';
                        htm += '<td class="tablefont" style="text-align:center;">' + row.foc + '</td>';

                        htm += '<td class="tablefont" style="text-align:center;">' + row.net_amount + '</td>';
                        htm += '</tr>';

                        $("#tblOrderDetailsTbody").append(htm);

                    });
                    var amuntWords = number2text(obj.order[0].net_amount);
                    $("#spantxtAmt").text(amuntWords);
                    var taxAmuntwords = number2text(obj.order[0].tax);
                    $("#spantxtTax").text(taxAmuntwords);
                    // adding payment details
                    $.each(obj.payment_details, function (i, row) {
                        var htmPaymentDetails = '<tr>';
                        htmPaymentDetails += '<td>#' + row.id + '</td>';
                        htmPaymentDetails += '<td>' + row.date + '</td>';
                        htmPaymentDetails += '<td>' + row.narration + '</td>';
                        htmPaymentDetails += '<td>' + row.user_name + '</td>';
                        htmPaymentDetails += '<td>' + (row.dr != 0 ? row.dr + " Dr" : (row.cr != 0 ? row.cr + " Cr" : 0)) + '</td>';
                        htmPaymentDetails += '<td>' + row.closing_balance + '</td>';
                        htmPaymentDetails += '</tr>';

                        $("#tblPaymentDetails > tbody").append(htmPaymentDetails);
                    });
                    //adding return details
                    if (obj.return_details.length == 0) {
                        $("#divReturnDetails").hide();
                    }
                    // console.log(obj.return_details);
                    sl_no = 0;
                    $.each(obj.return_details, function (i, row) {
                        console.log(row);
                        htm = "";
                        $.each(row.items, function (k, item) {
                            sl_no++;
                            htm += '<tr>';
                            htm += '<td class="tablefonthead" style="font-weight:bold; font-size:12px;">' + sl_no + '</td>';
                            htm += '<td class="tablefonthead" style="font-weight:bold; font-size:12px;">' + item.itm_code + '</td>';
                            htm += '<td class="tablefonthead" style="font-weight:bold; font-size:12px;">' + item.itm_name + '</td>';
                            htm += '<td class="tablefonthead" style="font-weight:bold; font-size:12px;">' + item.qty + '</td>';

                            htm += '<td class="tablefonthead" style="font-weight:bold; font-size:12px;">' + item.price + '</td>';
                            htm += '<td class="tablefonthead" style="font-weight:bold; font-size:12px;">' + item.discount + '</td>';
                            htm += '<td class="tablefonthead" style="font-weight:bold; font-size:12px;">' + item.total + '</td>';
                            htm += '</tr>';
                        });
                        htm += '<tr>';
                        htm += '<td colspan="7">';
                        htm += '<div style="width:100%;">';
                        htm += '<div style="display:inline-block;margin-left:10px;float:left">';
                        htm += '<span style="font-weight:bold;">Date : </span><label for="" id="">' + row.date + '</label><br/>';
                        htm += '</div>';
                        htm += '<div style="display:inline-block;margin-rght:10px;float:right">';
                        htm += '<span style="font-weight:bold;">Net Amount : </span><label for="" id="">' + row.amount + '</label><br/>';
                        htm += '</div>';
                        htm += '</div>';
                        htm += '<div class="space cl"></div>';
                        htm += '</td>';
                        htm += '</tr>';
                        $("#tblReturnDetails > tbody").append(htm);


                    });
                    if ((obj.branch[0].branch_declaration) != "") {
                        $("#tblDeclaration").show();
                        $("#divDeclaration").html(obj.branch[0].branch_declaration);
                    }
                    $("#lblCusId").text(obj.order[0].cust_id);
                    $("#lblCusName").text(obj.order[0].cust_name);
                    $("#lblAddress").text(obj.order[0].address);
                    $("#spanCity").text(obj.order[0].city);
                    $("#spanState").text(obj.order[0].state);
                    $("#lblStaffName").text(obj.order[0].staff_name);
                    if (obj.order[0].sm_roundoff == 0) {
                        $("#tdRoundOff").hide();
                    } else {
                        $("#tdRoundOff").show();
                    }
                    if (obj.order[0].sm_roundoff < 0) {
                        $("#lblRoundOffVal").text("(-) " + -(obj.order[0].sm_roundoff));
                    } else {
                        $("#lblRoundOffVal").text("(+) " + obj.order[0].sm_roundoff);
                    }
                    $("#txt_inv_address").html(obj.branch[0].branch_invoice_address);

                    if (obj.order[0].gst != "" && obj.order[0].gst != "null" && obj.order[0].gst != null) {
                        $("#spanGst").text("GSTIN/UINL:" + obj.order[0].gst);
                    }
                    else {

                        $("#spanGst").text("GSTIN/UINL: UNREGISTERED");
                    }

                    if (obj.order[0].gst != null) {

                    }
                    //    $("#spanCountry").text(obj.order[0].country);
                    if (obj.order[0].sm_payment_type == "" || obj.order[0].sm_payment_type == 0) {
                        $("#spanPaymentMode").hide();
                        $("#lblPaymentMode").text("");
                    } else {
                        $("#spanPaymentMode").show();
                    }
                    if (obj.order[0].sm_payment_type == 1) {
                        $("#lblPaymentMode").text("Cash");
                    } else if (obj.order[0].sm_payment_type == 2) {
                        $("#lblPaymentMode").text("Credit");
                    } else if (obj.order[0].sm_payment_type == 3) {
                        $("#lblPaymentMode").text("Bill to bill");
                    }

                    if (obj.order[0].phone != "") {
                        $("#spanmob").show();
                        $("#lblMobilenum").text(obj.order[0].phone);
                    } else {
                        $("#spanmob").hide();
                        $("#lblMobilenum").text("");
                    }
                    if (obj.order[0].email != "" && obj.order[0].email != "null" && obj.order[0].email != null) {
                        $("#lblEmailId").show();
                        $("#lblEmailId").text("Email:" + obj.order[0].email);
                    } else {
                        $("#lblEmailId").hide();
                        $("#lblEmailId").text("");
                    }
                    if (obj.order[0].phone != "" && obj.order[0].phone != "null" && obj.order[0].phone != null) {
                        $("#spanPhone").html("<label>Mobile No</label>:" + obj.order[0].phone);
                    } else {
                        $("#spanPhone").text("");
                    }

                    $("#spanStateCode").text(obj.order[0].state_name);
                    if (obj.order[0].sm_refno != "") {
                        $("#lblOrderId").text("(" + obj.order[0].sm_refno + ")");
                    }

                    if (obj.order[0].invoiceNum != "" && obj.order[0].invoiceNum != null) {
                        $("#lblInvoiceNum").text("#" + obj.order[0].invoiceNum + "");
                    } else {
                        $("#lblInvoiceNum").text("Not yet billed");
                    }
                    $("#lblOrderDate").text(obj.order[0].sm_date);
                    $("#lblWarehouse").text(obj.branch[0].branch_name);
                    $("#lblBillDisclosure").html(obj.branch[0].branch_bill_disclosure);
                    $("#divBranchAddress").html(obj.branch[0].branch_address);
                    $("#divBranchCountry").html(obj.branch[0].branch_country_name);
                    $("#divBranchEmail").html(obj.branch[0].branch_email);
                    $("#divRegno").html(obj.branch[0].branch_reg_id);
                    $("#spanNetAmt").text(parseFloat(obj.order[0].net_amount));
                    $("#lblStaffNam").text(obj.order[0].staff_name);
                    $("#lblNetAmount").text("Rs " + obj.order[0].net_amount);
                    $("#lblTotalAmount").text(obj.order[0].total);
                    $("#lblTotalTaxAmount").text(obj.order[0].tax);
                    $("#lblTotalDiscAmount").text(obj.order[0].discAmt);
                    $("#lblTotalTaxExAmount").text(obj.order[0].taxExcluded);
                    $("#lblTotalCgstAmount").text(cgstAmt.toFixed(2));
                    $("#lblTotalSgstAmount").text(sgstAmt.toFixed(2));
                    $("#lblTotalIgstAmount").text(igstAmt.toFixed(2));
                    $("#lblNetAmt").text("Rs " + obj.order[0].net_amount);

                    $("#lblPaidAmount").text(obj.order[0].total_paid);
                    $("#lblBalanceAmount").text(obj.order[0].total_balance);
                    $("#imgLogo").attr("src", "../logoImage/" + obj.branch[0].branch_image);
                    //  sendPdfmail(billno);
                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                    return false;
                }

            });
        }


        function printReceipt() {
            $("#divBack").hide();
            $("#divPrint").hide();
            $("#divPayment").hide();
            $("#slPrintType").hide();

            $("#divPaymentDetails").hide();
            $("#divReturnDetails").hide();
			// $("#lblOrderId").hide();
            window.print();
            $("#divBack").show();
            $("#divPrint").show();
            $("#divPayment").show();
            $("#divPaymentDetails").show();
            $("#divReturnDetails").show();
            $("#lblOrderId").show();
            $("#slPrintType").show();
        }

        function backPressed() {
            window.history.back();

        }

        //Start function for converting amount to words
        function number2text(value) {
            var fraction = Math.round(frac(value) * 100);
            var f_text = "";

            if (fraction > 0) {
                f_text = "AND " + convert_number(fraction) + " PAISE";
            }

            return convert_number(value) + " RUPEE " + f_text + " ONLY";
        }

        function frac(f) {
            return f % 1;
        }

        function convert_number(number) {
            if ((number < 0) || (number > 999999999)) {
                return "NUMBER OUT OF RANGE!";
            }
            var Gn = Math.floor(number / 10000000);  /* Crore */
            number -= Gn * 10000000;
            var kn = Math.floor(number / 100000);     /* lakhs */
            number -= kn * 100000;
            var Hn = Math.floor(number / 1000);      /* thousand */
            number -= Hn * 1000;
            var Dn = Math.floor(number / 100);       /* Tens (deca) */
            number = number % 100;               /* Ones */
            var tn = Math.floor(number / 10);
            var one = Math.floor(number % 10);
            var res = "";

            if (Gn > 0) {
                res += (convert_number(Gn) + " CRORE");
            }
            if (kn > 0) {
                res += (((res == "") ? "" : " ") +
                convert_number(kn) + " LAKH");
            }
            if (Hn > 0) {
                res += (((res == "") ? "" : " ") +
                    convert_number(Hn) + " THOUSAND");
            }

            if (Dn) {
                res += (((res == "") ? "" : " ") +
                    convert_number(Dn) + " HUNDRED");
            }


            var ones = Array("", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTEEN", "NINETEEN");
            var tens = Array("", "", "TWENTY", "THIRTY", "FOURTY", "FIFTY", "SIXTY", "SEVENTY", "EIGHTY", "NINETY");

            if (tn > 0 || one > 0) {
                if (!(res == "")) {
                    res += " AND ";
                }
                if (tn < 2) {
                    res += ones[tn * 10 + one];
                }
                else {

                    res += tens[tn];
                    if (one > 0) {
                        res += ("-" + ones[one]);
                    }
                }
            }

            if (res == "") {
                res = "zero";
            }
            return res;
        }

        //Stop function for converting amount to words

        function changePrintType() {
            if ($("#slPrintType").val() == 1) {
                $("#spanPrintType").text("(DUPLICATE FOR TRANSPORTER)");
            } else if ($("#slPrintType").val() == 2) {
                $("#spanPrintType").text("(ORIGINAL FOR RECIPIENT)");
            } else if ($("#slPrintType").val() == 3) {
                $("#spanPrintType").text("(TRIPLICATE FOR SUPPLIER)");
            } else {
                $("#spanPrintType").text("");
            }

        }
    </script>
    <style type="text/css">
        body {
            background: #ffffff;
        }
    </style>

</head>

<body>

    <form id="form1" runat="server">

        <!-- Start div For loading image-->

        <div id="loading" style="background-repeat: no-repeat; margin: auto; height: 100%; display: none">
            <div align="center" style="margin: auto">
                <img id="loading-image" src="../images/loader.gif" alt="Loading..." />
            </div>
        </div>

        <!-- End div For loading image-->

        <!--Main Div Starts Here-->

        <div class="mainDiv" style="padding: 10px; padding-left: 30px; padding-right: 30px;">

            <!----Start Logo Div Here--->
            <div class="cl"></div>
            <div class="space1"></div>
            <div style="height: 20px">
                <div id="divBack" class="recbtn fl" onclick="javascript:backPressed();" style="cursor: pointer">
                    <img src="../images/backreceipt.png" width="20" height="16" class="fl" style="margin-right: 3px;" />
                    <div class="backbtntext fl" style="line-height: 18px;">Back</div>
                </div>
                <!-- <div id="logoDiv" class="logoDivs fl" style="margin-left:300px; position:absolute;">
                        <img src="../images/logo.png" />
                    </div> -->
                <div id="divPrint" class="recbtn fr" onclick="javascript:printReceipt();" style="cursor: pointer;">
                    <img src="../images/print.png" width="20" height="20" class="fl" style="margin-left: 8px; margin-right: 3px;" />
                    <div class="backbtntext fl">Print</div>
                </div>
                <div>
                    <select onchange="javascript:changePrintType();" id="slPrintType">
                        <option selected="selected" value="-1">--Type--</option>
                        <option value="1">Duplicate for transporter</option>
                        <option value="2">Original for recipient</option>
                        <option value="3">Triplicate for supplier</option>
                    </select>
                </div>

            </div>
            <%--     <div class="logoDiv" style="width:100%;">
                <div style="margin:auto;width:100px; ">
                <img src="" style="width:100px; height:64px;" id="imgLogo" /></div></div>
            <div class="cl"></div>
            <div class="spaceDiv"></div>--%>
            <!----End Logo Div Here--->
            <div style="width: 100%">
                <div style="width: 100%;">
                    <div style="width: 1000px; margin: auto; font-weight: bold; text-align: center; font-size: 16px;">Way Bill <span style="float: right; font-weight: normal; font-size: 12px;" id="spanPrintType">(DUPLICATE)</span> </div>

                </div>
                <div style="width: 100%; border: 1px solid #73879c;">
                    <div style="width: 100%; float: left;">
                        <div style="width: 50%; height: 150px; float: left; padding: 10px; border-right: 1px solid #73879c; border-bottom: 1px solid #73879c;">
                            <%--<div style="font-weight: bold;font-size:16px;" id="lblWarehouse"></div>
                            <div id="divBranchAddress"></div>
                            <div id="divBranchCountry"></div>

                            <div>GSTIN/UINL:<span id="divRegno"></span></div>
                            <div>Email:<span id="divBranchEmail"></span>  </div>--%>
                            <div id="txt_inv_address"></div>
                            

                        </div>
                        <div style="width: 50%; height: 150px; float: left; padding: 10px; border-bottom: 1px solid #73879c;">
                            <div>Name & Address of Customer</div>
                            <div>
                                <label for="" id="lblCusName" style="margin-bottom: 0px; font-size: 15px;"></label>
                            </div>
                            <div id="lblAddress"></div>
                            <div><span id="spanCity">SELAM</span></div>
                            <div>State:<span id="spanStateCode"></span></div>

                            <div style="float: left;"><span id="lblEmailId" style="margin-right:5px;display:none"></span><span id="spanPhone"></span><br /><span id="spanGst" style="float: left; font-weight: bold;"></span></div>
                            <%--<br />--%>
                        </div>
                    </div>
                    <div style="clear: both;"></div>
                    <div style="float: left; width: 50%; border-left: none; border-right: 1px solid #73879c; padding: 10px;">
                        <table style="width: 100%;">
                            <tr>
                                <td style="font-weight: bold;">Invoice No&nbsp:
                                    <label id="lblInvoiceNum" style="font-size: 15px;"></label>
                                   
                                </td>
                                 <td style="font-weight: bold;">OrderId&nbsp:
                                    <label id="lblOrderId" style="font-size: 15px;"></label>
                                </td>
                                <td style="font-weight: bold;">Date:
                                    <label id="lblOrderDate" style="font-size: 15px;"></label>
                                </td>
                            </tr>
                            <tr>
                                <td>&nbsp</td>
                            </tr>
                            <tr>
                                <td style="font-weight: bold">Delivery Note:
                                </td>
                                <td style="font-weight: bold">Mode/Term of Payments:
                                </td>
                                <td style="font-weight: bold;">Staff:
                                    <label id="lblStaffName" style=""></label>
                                </td>
                            </tr>
                            <%--  <tr style="border-bottom: 1px solid #73879c;">
                                <td>Supplier's Ref.<br />
                                </td>
                                <td>Other Ref.<br />
                                </td>
                            </tr>
                            <tr style="border-bottom: 1px solid #73879c;">
                                <td>Buyer's Order No.<br />
                                </td>
                                <td>Dated<br />
                                </td>
                            </tr>--%>
                        </table>
                    </div>
                    <div style="float: left; width: 50%; border-left: none; padding: 10px;">
                        <table style="width: 100%;">
                            <tr>
                                <td colspan="2" style="font-weight: bold; font-size: 15px; text-transform: uppercase;">Terms of Delivery<br />
                                </td>

                            </tr>
                        </table>
                    </div>
                    <div style="clear: both;"></div>
                </div>
                <div style="clear: both;"></div>

                <div style="width: 100%;" id="divReceiptDetails">

                    <div class="details" style="margin-top: 15px; display: ;">


                        <div style="clear: both;"></div>
                        <table id="tblOrderDetails" style="margin-top: 8px; margin-bottom: 8px;font-size:13px;font-weight:bold" cellspacing="0" cellpadding="0" border="1" width="100%">
                            <tr>
                                <td class="tablefonthead" style="font-weight: bold; font-size: 12px; text-align: center;">Sl No</td>
                                <td class="tablefonthead" style="font-weight: bold; font-size: 12px; text-align: center;">HSN SAC</td>
                                <td class="tablefonthead" style="font-weight: bold; font-size: 12px; text-align: center;">Description of Goods</td>
                                
                                <td class="tablefonthead" style="font-weight: bold; font-size: 12px; text-align: center;">Qty</td>
                                <td class="tablefonthead" style="font-weight: bold; font-size: 12px; text-align: center;">FOC</td>
                                <td class="tablefonthead" style="font-weight: bold; font-size: 12px; width: 70px; text-align: center">Net Amt</td>
                                <!-- <td class='tablefonthead'>Paid.Amt</td>-->
                            </tr>


                            <tbody id="tblOrderDetailsTbody">
                            </tbody>

                            <tbody id="tbodyPayments">


                                <tr>
                                     
                                    <td style="text-align: right; padding-right: 10px;" colspan="5"><b>TOTAL</b></td>

                                  
                                    <td style="text-align: center">
                                        <label id="lblNetAmount" style="font-size:17px;">--</label></td>
                                </tr>

                            </tbody>
                        </table>
                        <div style="width: 100%; border: 1px solid #000000; padding: 5px;">
                            <div style="text-align: left; float: left;">Amount Chargeable (in words)

                            </div>
                            <div style="text-align: right;">E & O.E.</div>
                            
                            <span style="font-weight: bold;" id="spantxtAmt"></span> &nbsp&nbsp&nbsp <label id="lblNetAmt" style="font-weight: bold;font-size:16px"></label>
                            
                            <br />
                            <div style="display: none;">
                                <span>Tax Amount (in words)</span><br />
                                <span style="font-weight: bold;" id="spantxtTax"></span>
                            </div>
                        </div>

                        <br />
                  
          
                    </div>

                </div>
              
                <!-- footer content -->
                <footer>
                    <div style="text-align: center; margin-top: 10px;">
                        <div class="footerDiv">
                            <div class="footerDivContent">
                                This is a Computer Generated Invoice
                            </div>
                        </div>
                    </div>
                    <div class="clearfix"></div>
                </footer>
                <!-- /footer content -->

            </div>
        </div>

        <!--Main Div Starts Here-->
    </form>
    <script src="../js/bootstrap/bootstrap.min.js"></script>
    <!-- FastClick -->
    <script src="../js/bootstrap/fastclick.js"></script>
    <!-- NProgress -->
    <script src="../js/bootstrap/nprogress.js"></script>

</body>

</html>

