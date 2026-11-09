<%@ Page Language="C#" AutoEventWireup="true" CodeFile="editPurchase.aspx.cs" Inherits="web_purchase_editPurchase" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Edit Purchase  | Invoice Me</title>
    <script src="../js/common.js" type="text/javascript"></script>
    <script type="text/javascript" src="../js/jquery-2.0.3.js"></script>

    <script type="text/javascript" src="../js/jquery.cookie.js"></script>
    <script src="../js/pagination.js" type="text/javascript"></script>
    <script src="../js/uom-conversion.js" type="text/javascript"></script>
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
        var branchId=0;
        var taxType="";
        var branchName="";
        var tax_type = 0;
        var isInclusive = 0;
        var roundOffValue=0;
        var uomData = [];
        var specEditUid = null;
        var specRowSeq = 0;
        var specItem = null;
        var specFields = "#itemSpec_Qty,#itemSpec_Length,#itemSpec_Width,#itemSpec_TotalKg,#itemSpec_FinalQty,#itemSpec_Price,#itemSpec_Discount,#itemSpec_DiscountAmt,#itemSpec_CostWith,#itemSpec_CostWithout,#itemSpec_VendorBatch,#itemSpec_NetCost";

        function setSpecAction(action) {
            $("#btnSpecSave").text(action).attr("data-action", action);
        }

        function getUomNameById(uomId) {
            var name = "";
            $.each(uomData, function (i, u) {
                if (String(u.tum_id) === String(uomId)) {
                    name = u.tum_name;
                    return false;
                }
            });
            return name;
        }

        function loadUomData(uom_type) {
            $.ajax({
                type: "POST",
                url: "editPurchase.aspx/loadUomData",
                data: JSON.stringify({ uom_type: uom_type || 0 }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                async: false,
                success: function (response) {
                    uomData = JSON.parse(response.d);
                    fillItemSpecUom(uom_type);
                    if (!uom_type) loadUomTypes();
                },
                error: function (xhr) {
                    console.log(xhr.responseText);
                }
            });
            return uomData;
        }

        function loadUomTypes() {
            $.ajax({
                type: "POST",
                url: "editPurchase.aspx/loadUomTypes",
                data: "{}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                async: false,
                success: function (response) {
                    UomConversion.init(uomData, JSON.parse(response.d));
                    var issues = UomConversion.checkMasterData();
                    if (issues.length) console.warn("UOM master data issues:", issues);
                },
                error: function (xhr) {
                    console.log(xhr.responseText);
                }
            });
        }

        function specShowDefUom(name) {
            $("#itemSpec_DefUom").text(name || "");
            $("#itemSpec_FinalQtyUom").text(name ? " (" + name + ")" : "");
        }

        function updateSpecDimLabels() {
            var uomId = $("#itemSpec_Uom").val();
            var name = "";
            if (uomId && uomId != "-1") {
                name = $.trim($("#itemSpec_Uom option:selected").text());
            }
            var suffix = name ? " (" + name + ")" : "";
            $("label[for='itemSpec_Length']").text("Length/Unit" + suffix);
            $("label[for='itemSpec_Width']").text("Width/Unit" + suffix);
        }

        function fillItemSpecUom(uom_type) {
            var data = uomData;
            var $ddl = $("#itemSpec_Uom");
            var prev = $ddl.val();
            if (specItem && specItem.defUomId && UomConversion.findUom(specItem.defUomId)) {
                data = UomConversion.getCompatibleUoms(specItem.defUomId);
            }
            $ddl.empty().append('<option value="-1">Select</option>');
            $.each(data, function (i, u) {
                $ddl.append($('<option></option>').val(u.tum_id).text(u.tum_name));
            });
            if (prev && $ddl.find("option[value='" + prev + "']").length) {
                $ddl.val(prev);
            } else if (specItem && specItem.defUomId && $ddl.find("option[value='" + specItem.defUomId + "']").length) {
                $ddl.val(specItem.defUomId);
            } else {
                $ddl.val("-1");
            }
            updateSpecDimLabels();
        }

        function specApplyFieldRules() {
            var uomId = $("#itemSpec_Uom").val();
            var req = (uomId && uomId != "-1") ? UomConversion.getRequirements(uomId) : { length: false, width: true, kg: true };
            $("#itemSpec_Length,#itemSpec_TotalKg").prop("disabled", false);
            $("#itemSpec_Width").prop("disabled", !req.width);
        }

        function specRecalcFinal() {
            specApplyFieldRules();
            updateSpecDimLabels();
            var $f = $("#itemSpec_FinalQty"), $e = $("#itemSpec_FinalQtyErr");
            var uomId = $("#itemSpec_Uom").val();
            if (!uomId || uomId == "-1") {
                $f.val("");
                $e.text("");
                return;
            }
            var r = UomConversion.calculateFinalQuantity({
                uomId: uomId,
                targetUomId: specItem ? specItem.defUomId : null,
                quantity: $("#itemSpec_Qty").val(),
                length: $("#itemSpec_Length").val(),
                width: $("#itemSpec_Width").val()
            });
            if (r.error || r.value === null) {
                $f.val("");
                $e.text(r.error || "");
            } else {
                $f.val(r.value > 0 ? r.value.toFixed(2) : "");
                $e.text(r.warning || "");
            }
        }
        $(document).ready(function () {
            purchaseId = getQueryString('purchaseId');
            //  alert(BillNo);
            //  alert(BillNo);
            if (purchaseId == undefined) {
                location.href = "listPurchaseEntries.aspx";
                return;
            }
            searchAutoItems();
            bindItemModalSearch();
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
            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " ©");
            //call to select order details
            
             loadUomData(0);
             retrievePurchaseDetail();

            var yyyy = new Date().getFullYear();
            var curr_date = new Date().getDate();
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

            $('#txtEntryDate').scroller({
                preset: 'date',
                endYear: yyyy + 100,
                setText: 'Next',
                invalid: {},
                theme: 'ios',
                display: 'modal',
                mode: 'scroller',
                //dateFormat :'yy-mm-dd'
                //dateFormat: 'yyyy-mm-dd'
                dateFormat: 'yy-mm-dd'
            });
            
        });

        //auto populate for item search
        function searchAutoItems() {
            $("#itemNames").keyup(function () {             
                if ($("#itemNames").val().trim() === "") {
                    $("#searchTitle").hide();
                }
            });

            $("#itemNames").autocomplete({
                source: function (request, response) {
                    if (!branchId) { response([]); return; }
                    $.ajax({
                        type: "POST",
                        contentType: "application/json; charset=utf-8",
                        url: "editPurchase.aspx/GetAutoCompleteItemData",
                        data: JSON.stringify({ variable: request.term, BranchId: String(branchId) }),
                        dataType: "json",
                        success: function (data) {
                            response(JSON.parse(data.d).slice(0, 20));
                        },
                        error: function () { response([]); }
                    });
                },
                select: function (event, ui) {
                    event.preventDefault();
                    if (ui.item.id == "-1") { $("#itemNames").val(""); return; }
                    $("#itemNames").val(ui.item.label);
                    selectOrderItem(ui.item.id);
                },
                minLength: 1

            });
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
            $("#divUpdateOrder").css('pointer-events', 'none');
        }

        function dateformat(idate) {

            var med = idate.split("-");
            var dd = med[0];
            var mm = med[1];
            var yy = med[2];

            var nDate = yy + '-' + mm + '-' + dd;
            return nDate;

        }

        //start: Showing Details of selected Outsatnding Bill from Popup
        function retrievePurchaseDetail() {
            //  alert(paid);
            loading();

            $.ajax({
                type: "POST",
                url: "editPurchase.aspx/retrieveData",
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
                    $("#lblUserName").text(entry_details.user);
                  //  $("#txtTotalCost").text(entry_details.pm_total);
                  //  $("#txtTotalTaxableValue").text(entry_details.pm_tax_excluded_amt);
                //    $("#txtTotalDiscountRate").text(entry_details.pm_discount_rate);
                 //   $("#txtTotalDiscountAmount").text(entry_details.pm_discount_amount);
                    $("#txtPaidAmount").val(entry_details.pm_paidamount);
                    $("#txtBalanceAmount").val(entry_details.pm_balance);                   
               //     $("#txtTotalNetAmount").text(entry_details.net_amount);
                    $("#txtTotalGrossamount").text(entry_details.net_amount);
                    $("#txtTotalTaxamt").text(entry_details.tax_amount);
                    $("#txtEntryRefNo").val(entry_details.pm_invoice_no);
                    $("#txtVendorName").text(entry_details.vn_name);
                    $("#txtVendorId").text(entry_details.vn_id);
                    $("#txtEntryDate").val(entry_details.date);
                    roundOffValue=entry_details.roundOff;
                    $("#lblRoundOff").text(roundOffValue);
                    branchId=entry_details.branch_id;
                    taxType=entry_details.branch_tax_method;
                    branchName=entry_details.branch_name;
                    tax_type = entry_details.branch_tax_method;
                    if(tax_type==0){
                        $("#lbltaxMethod").text("No Tax");
                    }else if(tax_type==1){
                        $("#lbltaxMethod").text("VAT");
                    }else if(tax_type==2){
                        $("#lbltaxMethod").text("GST");
                    }
                    isInclusive = entry_details.branch_tax_inclusive;
                    if(isInclusive==0){
                        $("#lblTaxType").text("Exclusive");
                    }else if(isInclusive==1){
                        $("#lblTaxType").text("Inclusive");
                    }
                   // alert(isInclusive);
                    if (entry_details.vn_balance <= 0) {
                        $("#txtBalance").text(entry_details.vn_balance);
                        $("#txtBalance").css("color", "green");
                    } else {
                        $("#txtBalance").text(entry_details.vn_balance);
                        $("#txtBalance").css("color", "red");
                    }

                    $("#txtTotalCurrentAmount").val('0');
                  
                    $("#txtSpecialNote").val(entry_details.pm_note);

                    // showing order_items
                    $("#tbodyItems").html("");
                    specRowSeq = 0;
                    $.each(entryObj.items, function (i, item) {
                        var defaultUomId = item.itsv_uom_purchase ? String(item.itsv_uom_purchase) : null;
                        var defaultUomName = defaultUomId ? getUomNameById(defaultUomId) : "";
                        var selectedUomId = (item.tum_id !== null && item.tum_id !== undefined && item.tum_id !== "") ? String(item.tum_id) : "-1";
                        var qty = parseFloat(item.itbh_no_piece);
                        if (isNaN(qty)) {
                            qty = parseFloat(item.pi_qty) || 0;
                        }
                        var finalQty = parseFloat(item.pi_qty);
                        if (isNaN(finalQty)) {
                            finalQty = qty;
                        }
                        var net = parseFloat(item.pi_net_amount) || 0;
                        var d = {
                            id: item.itbs_id,
                            itm_id: item.itm_id,
                            pi_id: item.pi_id,
                            cess: parseFloat(item.pi_item_cess) || 0,
                            code: item.itm_code,
                            name: (item.itm_name || "").replace(/\u00a0/g, " "),
                            hsn: item.tp_tax_title || "",
                            taxPerc: item.pi_item_tax,
                            uom: selectedUomId,
                            defUomId: defaultUomId,
                            defUomName: defaultUomName,
                            Qty: qty,
                            Length: item.itbh_length || "",
                            Width: item.itbh_width || "",
                            TotalKg: item.itbh_kg || "",
                            FinalQty: finalQty,
                            Price: item.pi_price,
                            Discount: item.pi_discount_rate,
                            DiscountAmt: item.pi_discount_amount,
                            CostWith: item.itbh_costwithinvoice || "",
                            CostWithout: item.itbh_costwithoutinvoice || "",
                            VendorBatch: item.itbh_custbatchid || "",
                            NetCost: item.itbh_cost || (qty > 0 ? (net / qty).toFixed(2) : "")
                        };
                        specRowSeq++;
                        $("#tbodyItems").append($(specBuildRow(d, specRowSeq)).data("spec", d));
                    });

                    finalCalculation();
                    specResetForm();
                    $("#tblPayments > tbody").html("");
                    $.each(entryObj.transaction_details, function (i, row) {
                        console.log(row);
                        var htmPaymentDetails = '<tr>';
                        htmPaymentDetails += '<td>#' + row.id + '</td>';
                        htmPaymentDetails += '<td>' + row.date + '</td>';
                        htmPaymentDetails += '<td>' + row.narration + '</td>';
                        htmPaymentDetails += '<td>' + row.user_name + '</td>';
                        htmPaymentDetails += '<td><b>' + (row.dr != 0 ? row.dr + " Dr" : (row.cr != 0 ? row.cr + " Cr" : 0)) + '</b></td>';
                        htmPaymentDetails += '<td align="center">' +
                            '<div onclick="showTransactionDetails(' + row.id + ')" class="btn btn-primary btn-xs"><li class="fa fa-eye" style="font-size:large;"></li></div>' +
                            ((row.is_reconciliation == 0 && row.dr != 0) ? '<div onclick="showTransactionEdit(' + row.id + ')" class="btn btn-primary btn-xs"><li class="fa fa-pencil" style="font-size:large;"></li></div>' : '') +
                            '</td>';
                        htmPaymentDetails += '</tr>';

                        $("#tblPayments > tbody").append(htmPaymentDetails);
                    });
                   // loadTaxes(taxType);

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

        //function to show popup for editing transaction
        function showTransactionEdit(trans_id) {
            //var transaction = entryObj.transaction_details.find(x=>x.id == trans_id);
            //$("#lblTransRefEdit").text(transaction.id);
            //$("#txtTotalAmount").text(transaction.dr);
            //$("#txtCashAmt").val(transaction.cash_amt);
            //$("#txtWalletAmt").val(transaction.wallet_amt);
            //$("#txtChequeAmt").val(transaction.cheque_amt);
            //$("#popupTransactionEdit").modal('show');

            var transaction = entryObj.transaction_details.find(x=>x.id == trans_id);
            $("#lblTransRefEdit").text(transaction.id);
            $("#txtTotalAmount").text(transaction.cr);
            $("#txtCashAmt").val(transaction.cash_amt);
            //$("#txtWalletAmt").val(transaction.wallet_amt);
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
        }

        //function to calculate changes in payment
        function calcPaymentEditForm() {
            var cash_amt = isNaN(parseFloat($("#txtCashAmt").val())) ? 0 : parseFloat($("#txtCashAmt").val());
            var wallet_amt = isNaN(parseFloat($("#txtWalletAmt").val())) ? 0 : parseFloat($("#txtWalletAmt").val());
            var cheque_amt = isNaN(parseFloat($("#txtChequeAmt").val())) ? 0 : parseFloat($("#txtChequeAmt").val());
            $("#txtTotalAmount").text( cash_amt + wallet_amt + cheque_amt);
        }

        //function to save payment edit
        function savePaymentEdit() {

            sqlInjection();
            if(isNaN(parseFloat($("#txtChequeAmt").val())) || $("#txtChequeAmt").val() == "0")
            {
            }
            else
            {
                if($("#txt_chq_no").val() == "")
                {
                    alert("Enter the Cheque Number!");return;
                }

                if($("#txt_chq_date").val() == "")
                {
                    alert("Enter the Cheque Date!");return;
                }

                if($("#txt_bank_name").val() == "")
                {
                    alert("Enter the Cheque Bank!");return;
                }
            }

            var postObj = {
                trans_id: $("#lblTransRefEdit").text(),
                cash_amt: isNaN(parseFloat($("#txtCashAmt").val())) ? 0 : parseFloat($("#txtCashAmt").val()),
                cheque_amt: isNaN(parseFloat($("#txtChequeAmt").val())) ? 0 : parseFloat($("#txtChequeAmt").val()),
                cheque_no :$("#txt_chq_no").val(),
                cheque_date : dateformat( $("#txt_chq_date").val()),
                cheque_bank :$("#txt_bank_name").val(),
            }
            loading();
            $.ajax({
                type: "POST",
                url: "editPurchase.aspx/savePaymentEdit",
                data: JSON.stringify(postObj),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    location.reload();
                },
                error: function (xhr, status) {
                    Unloading();
                    console.log(xhr);
                    alert("error");
                }
            });
        }

        function itemSpecNum(sel) {
            var v = parseFloat($(sel).val());
            return isNaN(v) ? 0 : v;
        }

        function itemSpecPopulate(item) {
            item = item || {};
            $("#itemSpec_Code").text(item.itm_code || "");
            $("#itemSpec_Name").text((item.itm_name || "").replace(/\u00a0/g, " "));
            $("#itemSpec_Hsn").text(item.tp_tax_title || "");
            var rate = parseFloat(item.tp_tax_percentage);
            $("#itemSpec_TaxPerc").text(isNaN(rate) ? "" : rate);
            $("#itemSpec_Qty,#itemSpec_Length,#itemSpec_Width,#itemSpec_TotalKg,#itemSpec_FinalQty,#itemSpec_Discount,#itemSpec_CostWith,#itemSpec_CostWithout,#itemSpec_VendorBatch,#itemSpec_NetCost").val("");
            var pp = parseFloat(item.itbs_purchase_price);
            $("#itemSpec_Price").val(isNaN(pp) ? "" : pp);
            specRecalcFinal();
            itemSpecCalc();
        }

        function itemSpecCalc() {
            var qty = itemSpecNum("#itemSpec_FinalQty") || itemSpecNum("#itemSpec_Qty");
            var price = itemSpecNum("#itemSpec_Price");
            var disc = itemSpecNum("#itemSpec_Discount");
            var rate = parseFloat($("#itemSpec_TaxPerc").text());
            if (isNaN(rate) || tax_type == 0) rate = 0;
            var cess = (specItem && specItem.cess) || 0;
            var real = price;
            if (typeof isInclusive !== "undefined" && isInclusive == 1) {
                real = cess > 0 ? (10000 * price) / (10000 + 100 * rate + rate * cess) : price / (rate / 100 + 1);
            }
            var amount = real * qty;
            var discAmt = amount * disc / 100;
            var taxable = amount - discAmt;
            var tax = taxable * rate / 100;
            if (cess > 0) tax += tax * cess / 100;
            var net = taxable + tax;
            $("#itemSpec_DiscountAmt").val(discAmt.toFixed(2));
            $("#itemSpec_Taxable").val(taxable.toFixed(2));
            $("#itemSpec_TaxAmount").val(tax.toFixed(2));
            $("#itemSpec_Net").val(net.toFixed(2));
            var costQty = itemSpecNum("#itemSpec_Qty") || qty;
            $("#itemSpec_NetCost").val(costQty > 0 ? ((net + itemSpecNum("#itemSpec_CostWithout")) / costQty).toFixed(2) : "");
        }

        function specResetForm() {
            specEditUid = null;
            specItem = null;
            $("#itemSpec_Code,#itemSpec_Name,#itemSpec_Hsn,#itemSpec_TaxPerc").text("");
            $(specFields).val("");
            fillItemSpecUom();
            $("#itemSpec_Uom").val("-1");
            specApplyFieldRules();
            updateSpecDimLabels();
            specShowDefUom("");
            $("#itemSpec_Taxable,#itemSpec_TaxAmount,#itemSpec_Net").val("");
            $("#tblPurchaseItems tr.spec-editing").removeClass("spec-editing").css("background-color", "");
            setSpecAction("Add");
        }

        function specCollect() {
            var d = {
                id: specItem.id,
                itm_id: specItem.itm_id,
                pi_id: specItem.pi_id || null,
                cess: specItem.cess,
                code: $("#itemSpec_Code").text(),
                name: $("#itemSpec_Name").text(),
                hsn: $("#itemSpec_Hsn").text(),
                taxPerc: $("#itemSpec_TaxPerc").text(),
                uom: $("#itemSpec_Uom").val(),
                defUomId: specItem.defUomId,
                defUomName: specItem.defUomName
            };
            $.each(["Qty", "Length", "Width", "TotalKg", "FinalQty", "Price", "Discount", "DiscountAmt", "CostWith", "CostWithout", "VendorBatch", "NetCost"], function (i, k) {
                d[k] = $("#itemSpec_" + k).val();
            });
            return d;
        }

        function specLoad(d) {
            specItem = {
                id: d.id,
                itm_id: d.itm_id,
                pi_id: d.pi_id || null,
                cess: d.cess,
                defUomId: d.defUomId,
                defUomName: d.defUomName
            };
            specShowDefUom(d.defUomName);
            $("#itemSpec_Code").text(d.code);
            $("#itemSpec_Name").text(d.name);
            $("#itemSpec_Hsn").text(d.hsn);
            $("#itemSpec_TaxPerc").text(d.taxPerc);
            fillItemSpecUom();
            $("#itemSpec_Uom").val(d.uom);
            $.each(["Qty", "Length", "Width", "TotalKg", "FinalQty", "Price", "Discount", "DiscountAmt", "CostWith", "CostWithout", "VendorBatch", "NetCost"], function (i, k) {
                $("#itemSpec_" + k).val(d[k]);
            });
            specRecalcFinal();
            itemSpecCalc();
        }

        function specBuildRow(d, uid) {
            var qty = parseFloat(d.FinalQty) || parseFloat(d.Qty) || 0;
            var price = parseFloat(d.Price) || 0;
            var disc = parseFloat(d.Discount) || 0;
            var rate = parseFloat(d.taxPerc);
            if (isNaN(rate) || tax_type == 0) rate = 0;
            var cess = d.cess || 0;
            var real = price;
            if (isInclusive == 1) {
                real = cess > 0 ? (10000 * price) / (10000 + 100 * rate + rate * cess) : price / (rate / 100 + 1);
            }
            var amount = real * qty;
            var discAmt = amount * disc / 100;
            var taxable = amount - discAmt;
            var tax = tax_type == 0 ? 0 : calculateTaxAmt(taxable, rate, cess);
            var net = taxable + parseFloat(tax);
            var h = "<tr class='classtest' data-uid='" + uid + "'>";
            h += "<td>" + d.code + "</td>";
            h += "<td>" + d.name + "</td>";
            h += "<td data-value='" + qty + "' data-taxrate='" + rate + "' data-cessrate='" + cess + "'>" + qty + "</td>";
            h += "<td data-value='" + price + "'>" + price + "</td>";
            h += "<td>" + amount.toFixed(2) + "</td>";
            h += "<td data-value='" + disc + "'>" + disc + "</td>";
            h += "<td>" + discAmt.toFixed(2) + "</td>";
            h += "<td>" + taxable.toFixed(2) + "</td>";
            h += "<td data-value='" + rate + "'>" + rate + "</td>";
            h += "<td data-value='" + parseFloat(tax).toFixed(2) + "'>" + parseFloat(tax).toFixed(2) + "</td>";
            h += "<td>" + net.toFixed(2) + "</td>";
            h += "<td>" + (d.defUomName || getUomNameById(d.defUomId) || "") + "</td>";
            h += "<td style='white-space:nowrap;'><a class='btn btn-info btn-xs' title='Edit' onclick='EditRaw(this);'><li class='fa fa-pencil'></li></a> <a class='btn btn-danger btn-xs'><li class='fa fa-close' onclick='DeleteRaw(this);'></li></a></td>";
            h += "</tr>";
            return h;
        }

        function specSave() {
            if (!specItem) {
                alert("Please select an item first");
                return;
            }
            var d = specCollect();
            if (!(parseFloat(d.FinalQty) > 0 || parseFloat(d.Qty) > 0)) {
                alert("Enter a quantity");
                $("#itemSpec_Qty").focus();
                return;
            }
            if (!(parseFloat(d.Price) >= 0) || d.Price === "") {
                alert("Enter a purchase price");
                $("#itemSpec_Price").focus();
                return;
            }
            if (specEditUid !== null) {
                var $old = $("#tblPurchaseItems tr[data-uid='" + specEditUid + "']");
                if ($old.length == 0) {
                    alert("The row being edited no longer exists");
                    specResetForm();
                    return;
                }
                var $new = $(specBuildRow(d, specEditUid)).data("spec", d);
                $old.replaceWith($new);
            } else {
                specRowSeq++;
                $("#tbodyItems").append($(specBuildRow(d, specRowSeq)).data("spec", d));
            }
            finalCalculation();
            specResetForm();
            popupclose('popupItems');
        }

        function EditRaw(ctrl) {
            var $tr = $(ctrl).closest("tr");
            var d = $tr.data("spec");
            if (!d) return;
            if (specEditUid !== null && specEditUid != $tr.attr("data-uid") && !confirm("Discard the pending edit and edit this row instead?")) {
                return;
            }
            specResetForm();
            specEditUid = $tr.attr("data-uid");
            $tr.addClass("spec-editing").css("background-color", "#fff3cd");
            d.Price = $tr.find('td:eq(3)').attr('data-value') || d.Price;
            d.Discount = $tr.find('td:eq(5)').attr('data-value') || d.Discount;
            d.taxPerc = $tr.find('td:eq(8)').attr('data-value') || d.taxPerc;
            specLoad(d);
            setSpecAction("Update");
        }

        $(document).on("click", "#btnSpecSave", specSave);
        $(document).on("click", "#btnSpecCancel", function () {
            if (specEditUid !== null || specItem) {
                if (!confirm("Clear the item specification form?")) return;
            }
            specResetForm();
        });
        $(document).on("input", ".itemspec-decimal", function () {
            var v = this.value.replace(/[^0-9.]/g, "");
            var p = v.indexOf(".");
            if (p >= 0) v = v.substring(0, p + 1) + v.substring(p + 1).replace(/\./g, "").substring(0, 3);
            this.value = v;
        });
        $(document).on("input", ".itemspec-calc", itemSpecCalc);
        $(document).on("input", "#itemSpec_Qty,#itemSpec_Length,#itemSpec_Width", function () { specRecalcFinal(); itemSpecCalc(); });
        $(document).on("change", "#itemSpec_Uom", function () { specRecalcFinal(); itemSpecCalc(); });

        //changing each value in table
        function modifyValues(thisRowId, valueType) {
            //start check number only
            roundOffValue=0;
            $('.number-only').keyup(function (e) {
                if (this.value != '-')
                    while (isNaN(this.value))
                        this.value = this.value.split('').reverse().join('').replace(/[\D]/i, '')
                                               .split('').reverse().join('');
            })
             .on("cut copy paste", function (e) {
                 e.preventDefault();
             });
            //end check number only
            if (thisRowId != "1") {
                var rowId = $(thisRowId).closest('td').parent()[0].sectionRowIndex;
            }
            else {
                var rowId = thisRowId;
            }

            var unit_price = $.trim($('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(3)').find('input').val());//price
            var item_qty = $.trim($('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(2)').find('input').val());//qty
            var purchase_amount = $.trim($('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(4)').text());//amount
            var discnt_percent = $.trim($('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(5)').find('input').val());//dis %
            var discnt_amount = $.trim($('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(6)').text());//dis amount
            var tax_rate = $.trim($('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(8)').find('input').val());//tax amt
            var tax_amt = $.trim($('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(9)').find('input').val());//tax amt
            var net_amount = $.trim($('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(10)').text());//net amount
            var regexqty = new RegExp(/^\+?[0-9(),]+$/);
            if (item_qty.match(regexqty)) {

            }
            else {
                var newVal1 = item_qty.toString();
                var newVal = newVal1.substr(0, newVal1.length - 1);
                $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(4)').find('input').val(newVal);
            }


            if (discnt_percent == "") {
                discnt_percent = 0.00;
            }
            else {
                discnt_percent = (parseFloat($.trim($('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(5)').find('input').val()))).toFixed(2);
            }
            if (discnt_amount == "") {
                discnt_amount = 0.00;
            }
            else {
                discnt_amount = (parseFloat($.trim($('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(6)').text()))).toFixed(2);
            }
            if (tax_amt == "") {
                tax_amt = 0.00;
            }
            else {
                tax_amt = (parseFloat($.trim($('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(9)').find('input').val()))).toFixed(2);
                
            }
            if (tax_rate == "") {
                tax_rate = 0.00;
            }
            else {
                tax_rate = (parseFloat($.trim($('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(10)').find('input').val()))).toFixed(2);
            }
            if (net_amount == "") {
                net_amount = 0.00;
            }
            else {
                net_amount = (parseFloat($.trim($('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(10)').text()))).toFixed(2);
            }
            if (purchase_amount == "") {
                purchase_amount = 0.00;
            }
            else {
                purchase_amount = (parseFloat($.trim($('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(4)').text()))).toFixed(2);
            }

            purchase_amount = unit_price * item_qty;
            var realprice = 0;
            var discount = 0;
            if (valueType == "ItemPrice") {
                saleprice = parseFloat($('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(3)').find('input').val());
                if (isNaN(saleprice) == true) {
                    //   alert("Check Sales Price..!");
                    $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(3)').find('input').val("");
                    $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(4)').text(0);
                    // $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(5)').find('input').val(0);
                    $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(6)').text(0);
                    $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(10)').text(0);
                    $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(7)').text(0);
                    //    $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(8)').find('input').val(0);
                    $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(9)').find('input').val(0);
                    $("#txtTotalDiscountRate").text("0");
                    $("#txtTotalDiscountAmount").text("0");
                    $(thisRowId).addClass("err");
                    // return false;
                } else {
                    $(thisRowId).removeClass("err");
                    calculateValues(thisRowId);

                }
            } else if (valueType == "ItemQty") {
                if (item_qty == "" || item_qty == "0") {
                    $(thisRowId).addClass("err");
                    $("#divsaveorder").css('pointer-events', 'none');
                    $("#divprintorder").css('pointer-events', 'none');
                    $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(7)').text(0);
                    $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(10)').text(0);
                    $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(9)').find('input').val(0);
                    // return;
                }
                item_qty = parseFloat($.trim($('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(2)').find('input').val()));

                if (isNaN(item_qty) == true) {
                    // alert("Check Quantity..!");
                    $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(2)').find('input').val("0");
                    // return false;
                }
                else {
                    $(thisRowId).removeClass("err");
                    calculateValues(thisRowId);
                }
               
            } else if (valueType == "DiscountPercent") {
                discount = parseFloat($('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(5)').find('input').val());
                if (discnt_percent == "") {
                    $(thisRowId).addClass("err");
                    $("#divsaveorder").css('pointer-events', 'none');
                    $("#divprintorder").css('pointer-events', 'none');
                   
                    return;
                }
                if (discnt_percent > 100) {
                    // alert("Check Discount Percentage..!");
                    var newVal1 = discnt_percent.toString();
                    var newVal = newVal1.substr(0, newVal1.length - 1);
                    $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(5)').find('input').val(newVal);
                    $(thisRowId).addClass("err");

                }
                else if (isNaN(discnt_percent) == true) {
                    $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(5)').find('input').val("0");
                    return false;
                } else if (discnt_percent == "") {
                    return true;
                }
                else {
                    $(thisRowId).removeClass("err");
                    calculateValues(thisRowId);

                }
            } else if (valueType == "ItemTax") {
                //   alert(discnt_amount);

                taxAmt = parseFloat($('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(9)').find('input').val());
                if (isNaN(taxAmt) == true) {
                    //   alert("Check Sales Price..!");
                    $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(3)').find('input').val("");
                    $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(4)').text(0);
                    $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(5)').find('input').val(0);
                    $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(6)').text(0);
                    $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(10)').text(0);
                    $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(7)').text(0);
                    $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(8)').find('input').val(0);
                    $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(9)').find('input').val(0);
                    $("#txtTotalDiscountRate").text("0");
                    $("#txtTotalDiscountAmount").text("0");
                    $(thisRowId).addClass("err");
                    // return false;
                } else {
                    $(thisRowId).removeClass("err");
                    calculateValues(thisRowId);

                }
            }
            else if (valueType == "ItemTaxPerc") {
                //   alert(discnt_amount);

                taxAmtperc = parseFloat($('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(8)').find('input').val());
                if (isNaN(taxAmtperc) == true) {
                    //   alert("Check Sales Price..!");
                    //  $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(3)').find('input').val("");
                    // $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(4)').text(0);
                    //  $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(5)').find('input').val(0);
                    // $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(6)').text(0);
                    //     $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(10)').text(0);
                    // $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(7)').text(0);
                    $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(8)').find('input').val(0);
                    $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(9)').find('input').val(0);
                    //  $("#txtTotalDiscountRate").text("0");
                    // $("#txtTotalDiscountAmount").text("0");
                    //  $(thisRowId).addClass("err");
                    // return false;
                } else {
                    $(thisRowId).removeClass("err");
                    calculateValues(thisRowId);

                }
            }
            finalCalculation();
            //finalCalculation(2);

            // paymentMethod();
        }

        function calculateValues(ctrl) {
            var parentRow = $(ctrl).closest('td').parent()[0];
            var rowId = parentRow.sectionRowIndex;
            var cessRate = parseFloat($('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(2)').find('input').attr('data-cessRate'));
            var tax_rate = parseFloat( $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(8)').find('input').val());
            var saleprice = parseFloat($('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(3)').find('input').val());
            var item_qty = $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(2)').find('input').val();
            var discount = parseFloat($('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(5)').find('input').val());
          //  alert(isInclusive);
            if (isInclusive == 1) { // tax is included with the price

                if (parseFloat(cessRate) > 0) {

                    var denominator = 10000 * saleprice;
                    var base = 10000 + (100 * tax_rate) + (tax_rate * cessRate);
                    realtotal = denominator / base;
                }
                else {
                    var constant = (tax_rate / 100) + 1; // equation for the dividing constant
                    realtotal = saleprice / constant;
                }
            }
            else {
                realtotal = saleprice;
            }

            service_cost = parseFloat(realtotal * item_qty);
            discount_amt = ((service_cost * discount) / 100);
            net_amount = (service_cost - ((service_cost * discount) / 100));
            tax_amount = calculateTaxAmt(net_amount, tax_rate, parseFloat($('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(2)').find('input').attr('data-cessRate')));
            Total_net_amount = parseFloat(parseFloat(net_amount) + parseFloat(tax_amount));
            $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(4)').text(service_cost.toFixed(2));
            //$('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(5)').find('input').val(discount);
            $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(6)').text(discount_amt.toFixed(2));
            $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(7)').text(net_amount.toFixed(2));
            $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(8)').find('input').val(tax_rate);
            $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(9)').find('input').val(tax_amount);
            $('#tblPurchaseItems > tbody tr:eq(' + rowId + ') td:eq(10)').text(Total_net_amount.toFixed(2));

        }

        //start function for calculate taxAmount
        function calculateTaxAmt(realprice, tax_rate, cessRate) {
            if (tax_rate == 0) {
                return 0;
            }
            else {

                tax_amount = ((realprice * tax_rate) / 100);
                if (cessRate > 0) {

                    cessAmount = ((tax_amount * cessRate) / 100);
                    tax_amount = parseFloat(parseFloat(tax_amount) + parseFloat(cessAmount)).toFixed(2);
                }
                else {

                    tax_amount = tax_amount;
                }
                return tax_amount.toFixed(2);
            }
        }
        //end function for calculate taxAmount

        //calculations for total
        function finalCalculation() {
            var $rows = $('#tblPurchaseItems tr.classtest');
            if ($rows.length === 0) {
                $("#txtTotalCost,#txtTotalDiscountRate,#txtTotalDiscountAmount,#txtTotalTaxableValue,#txtTotalTaxamt,#txtTotalNetAmount,#txtTotalGrossamount").text("0.00");
                $("#txtPaidAmount,#txtBalanceAmount").val("0.00");
                return false;
            }

            var totalCost = 0, totalDiscAmt = 0, totalTaxable = 0, totalTax = 0, totalNet = 0;
            $rows.each(function () {
                var $tr = $(this);
                totalCost += parseFloat($tr.find('td:eq(4)').text()) || 0;
                totalDiscAmt += parseFloat($tr.find('td:eq(6)').text()) || 0;
                totalTaxable += parseFloat($tr.find('td:eq(7)').text()) || 0;
                totalTax += parseFloat($tr.find('td:eq(9)').attr('data-value') || $tr.find('td:eq(9)').text()) || 0;
                totalNet += parseFloat($tr.find('td:eq(10)').text()) || 0;
            });

            var totalDiscRate = totalCost > 0 ? ((totalCost - totalTaxable) * 100 / totalCost) : 0;
            var gross = totalNet + (parseFloat(roundOffValue) || 0);

            $("#txtTotalCost").text(totalCost.toFixed(2));
            $("#txtTotalDiscountRate").text(totalDiscRate.toFixed(2));
            $("#txtTotalDiscountAmount").text(totalDiscAmt.toFixed(2));
            $("#txtTotalTaxableValue").text(totalTaxable.toFixed(2));
            $("#txtTotalTaxamt").text(totalTax.toFixed(2));
            $("#txtTotalNetAmount").text(totalNet.toFixed(2));
            $("#txtTotalGrossamount").text(gross.toFixed(2));
            $("#txtPaidAmount").val(0.00);
            $("#txtBalanceAmount").val(gross.toFixed(2));
            paymentMethod();
        }

        //for disabling and enabling payment method textboxes
        function paymentMethod() {
            var tblrowCount = $('#tblPurchaseItems > tbody tr').length;
            if ($("#txtTotalGrossamount").text() == "0.00" && tblrowCount <= 3) {
                $("#cbCashPayment").prop("disabled", true);
                $("#cbCashPayment").attr("checked", false);
                $("#cbCardPayment").prop("disabled", true);
                $("#cbCardPayment").attr("checked", false);
                $("#cbChequePayment").attr("disabled", true);
                $("#cbChequePayment").attr("checked", false);
                $("#txtCashAmount").val('');
                $("#txtCardAmount").val('');
                $("#txtCardNo").val('');
                $("#txtCardType").val('');
                $("#txtCardBank").val('');
                $("#txtChequeAmount").val('');
                $("#txtChequeNo").val('');
                $("#txtChequeDate").val('');
                $("#txtBankName").val('');
            }
            else {
                $("#cbCashPayment").prop("disabled", false);
                $("#cbCardPayment").prop("disabled", false);
                $("#cbChequePayment").prop("disabled", false);
            }

            if ($("#cbCashPayment").is(':checked')) {
                $("#txtCashAmount").attr("disabled", false);
                if (isNaN($('#txtCashAmount').val())) {
                    alert("Enter a valid Cash Amount");
                    $('#txtCashAmount').val(0);
                }
            }
            else {
                $("#txtCashAmount").attr("disabled", true);
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
            }
            else {
                $("#txtCardAmount").attr("disabled", true);
                $("#txtCardNo").attr("disabled", true);
                $("#txtCardType").attr("disabled", true);
                $("#txtCardBank").attr("disabled", true);
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
            }
            else {
                $("#txtChequeAmount").attr("disabled", true);
                $("#txtChequeNo").attr("disabled", true);
                $("#txtChequeDate").attr("disabled", true);
                $("#txtBankName").attr("disabled", true);
                $("#txtChequeAmount").val('');
                $("#txtChequeNo").val('');
                $("#txtChequeDate").val('');
                $("#txtBankName").val('');
            }

            if ($(document).find(".error").length > 0) {
                console.log($(document).find(".error").length);
                $("#divUpdateOrder").css('pointer-events', 'none');
                //    $("#divprintorder").css('pointer-events', 'none');
            }
            else {
                $("#divUpdateOrder").css('pointer-events', 'auto');
                //    $("#divprintorder").css('pointer-events', 'auto');
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
            var cashTotal = parseFloat(cashAmount) + parseFloat(cardAmount) + parseFloat(chequeAmount);

            //alert(cashTotal);
            $('#txtPaidAmount').val(cashTotal.toFixed(2));
            var balance = parseFloat($('#txtTotalGrossamount').text()) - parseFloat($('#txtPaidAmount').val());
            //alert(balance);
            //  $('#tblPurchaseItems tr:eq(' + row + ') td:eq(9)').text(total.toFixed(2));
            if (balance <= 0) {
                $("#txtOutstandingBillDate").prop("disabled", true);
                $("#txtOutstandingBillDate").val('');
            }
            else {
                $("#txtOutstandingBillDate").prop("disabled", false);
            }

            $("#txtBalanceAmount").val(balance.toFixed(2));
        }

        function DeleteRaw(ctrl) {

            $(ctrl).closest('tr').remove();
            var rowCount = parseInt($('#tblPurchaseItems tr').length);
            if (rowCount <= 1) {
                //  $("#TrSum").text('');
                $("#txtTotalCost").text(0.0);
                $("#txtTotalDiscountRate").text(0.0);
                $("#txtTotalDiscountAmount").text(0.0);
                $("#txtTotalNetAmount").text(0.0);
                $("#txtTotalGrossamount").text(0.0);
                $("#txtPaidAmount").val(0.0);
                $("#txtBalanceAmount").val(0.0);
            }
            // calculteTable();
            finalCalculation();
        }

        //search items: shows in popup
        function resetItemlist() {
            $("#searchposContent1,#searchposContent2").val('');
            searchOrderitems(1);
        }

        var itemReqId = 0, itemTimer = null;

        function itemEsc(s) { return $("<div>").text(s == null ? "" : s).html(); }
        function itemHl(text, q) {
            var t = text == null ? "" : String(text), s = $.trim(q || "");
            var i = s ? t.toLowerCase().indexOf(s.toLowerCase()) : -1;
            if (i < 0) return itemEsc(t);
            return itemEsc(t.substring(0, i)) + "<mark>" + itemEsc(t.substring(i, i + s.length)) + "</mark>" + itemEsc(t.substring(i + s.length));
        }
        function itemCleanTerm(v) { return $.trim(String(v || "").replace(/['"\\]/g, "")); }
        function itemModalState(text, isErr) {
            $("#tableItemlist tbody").html('<tr><td colspan="3" style="text-align:center;padding:12px;font-weight:bold;' + (isErr ? 'color:#c9302c;' : '') + '">' + text + '</td></tr>');
        }

        // Live search while typing (debounced), results of an outdated request are ignored
        function bindItemModalSearch() {
            $("#searchposContent1,#searchposContent2").on("input", function () {
                clearTimeout(itemTimer);
                itemTimer = setTimeout(function () { searchOrderitems(1); }, 300);
            }).on("keydown", function (e) {
                if (e.which === 13) { e.preventDefault(); clearTimeout(itemTimer); searchOrderitems(1); }
            });
            $("#popupItems").on("shown.bs.modal", function () { $("#searchposContent2").focus(); });
            $("#tableItemlist tbody").on("click", "tr[data-itbs]", function () { selectOrderItem($(this).attr("data-itbs")); });
            $("#tableItemlist tbody").on("click", "button[data-additem]", function (e) {
                e.stopPropagation();
                showAddItemPopUp($(this).attr("data-additem"), $(this).attr("data-name"));
            });
        }

        function searchOrderitems(page) {
            if (!branchId) {
                alert("Purchase details are still loading. Please try again.");
                return false;
            }
            var code = itemCleanTerm($("#searchposContent1").val()), name = itemCleanTerm($("#searchposContent2").val());
            var filters = { warehouse: String(branchId) };
            if (name) filters.itemname = name;
            if (code) filters.itemcode = code;
            var perpage = parseInt($("#txtpospageno").val()) || 25;
            var reqId = ++itemReqId;

            // Open the popup straight away and fill it when the data arrives
            $("#popupItems").modal('show');
            itemModalState('<i class="fa fa-spinner fa-spin"></i> Loading...');
            $("#paginatedivone").empty();

            $.ajax({
                type: "POST",
                url: "editPurchase.aspx/searchOrderitems",
                data: JSON.stringify({ page: page, filters: filters, perpage: perpage }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    if (reqId !== itemReqId) return;
                    if (msg.d == "N") {
                        $("#lblItemTotalrecords").text(0);
                        itemModalState("No items match your search.");
                        return;
                    }
                    var obj;
                    try { obj = JSON.parse(msg.d); } catch (ex) {
                        $("#lblItemTotalrecords").text(0);
                        itemModalState("Unable to load items.", true);
                        return;
                    }
                    $("#lblItemTotalrecords").text(obj.count);
                    var htm = "";
                    $.each(obj.data, function (i, row) {
                        var cells = "<td>" + itemHl(row.itm_code, code) + "</td><td>" + itemHl(row.itm_name, name);
                        if (row.itbsId == 0) {
                            htm += "<tr style='cursor:pointer;color: #a7a7a7;'>" + cells
                                + "  <button type='button' class='btn btn-primary btn-sm pull-right' data-additem='" + row.itm_id + "' data-name=\"" + itemEsc(row.itm_name).replace(/"/g, "&quot;") + "\"><label style='font-weight:950'> + </label></button></td><td>" + itemEsc(row.stock) + "</td></tr>";
                        } else {
                            htm += "<tr data-itbs='" + row.itbsId + "' style='cursor:pointer;'>" + cells + "</td><td>" + itemEsc(row.stock) + "</td></tr>";
                        }
                    });
                    htm += '<tr><td colspan="3"><div id="paginatedivone" style="text-align: center;"></div></td></tr>';
                    $("#tableItemlist tbody").html(htm);
                    $("#paginatedivone").html(paginate(obj.count, perpage, page, "searchOrderitems"));
                },
                error: function () {
                    if (reqId !== itemReqId) return;
                    itemModalState('Could not load items. <a href="javascript:void(0);" onclick="searchOrderitems(' + page + ');">Retry</a>', true);
                }
            });
        }

        // start: Showing Details of selected  Item from autopopulate
        function selectOrderItem(id) {
            if (specEditUid !== null && !confirm("An item is being edited. Discard pending changes and select another item?")) {
                return;
            }
            loading();
            $.ajax({
                type: "POST",
                contentType: "application/json; charset=utf-8",
                url: "editPurchase.aspx/selectOrderItem",
                data: "{'itemId':'" + id + "'}",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    var obj = JSON.parse(msg.d);
                    specResetForm();
                    specItem = { id: id, itm_id: obj[0].itm_id, cess: parseFloat(obj[0].tp_cess) || 0, pi_id: null };
                    itemSpecPopulate(obj[0]);
                    $("#itemNames").val("");
                    var defId = String(obj[0].itsv_uom_purchase || "");
                    var defName = getUomNameById(defId);
                    if (defName) {
                        specItem.defUomId = defId;
                        specItem.defUomName = defName;
                        $("#itemSpec_Uom").val("-1");
                        fillItemSpecUom();
                        $("#itemSpec_Uom").val(defId);
                    } else {
                        specItem.defUomId = null;
                        specItem.defUomName = null;
                        fillItemSpecUom();
                        $("#itemSpec_Uom").val("-1");
                    }
                    specShowDefUom(defName);
                    specRecalcFinal();
                    itemSpecCalc();
                    popupclose('popupItems');
                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }
        // Stop: Showing Details of selected  Item from autopopulate

        //popupclose
        function popupclose(divid) {
            $("#" + divid).modal('hide');
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

        function savePurchaseEntry() {
            function num(v) {
                var n = parseFloat(v);
                return isNaN(n) ? null : n;
            }
            function txt(v) {
                v = $.trim(v || "");
                return v === "" ? null : v;
            }

            var filters = {};
            filters.pm_id = num(purchaseId);
            filters.pm_ref_no = txt($("#txtEntryRefNo").val());
            filters.invoiceno = txt($("#txtEntryRefNo").val());
            filters.vendorId = $("#txtVendorId").text();
            filters.userid = $.cookie("invntrystaffId");
            filters.purchasedate = $("#txtEntryDate").val();
            filters.note = txt($("#txtSpecialNote").val());
            filters.warehouse = String(branchId || 0);
            filters.pm_status = 1;
            filters.pm_cancelled_date = null;
            filters.branch_tax_method = String(tax_type || 0);
            filters.branch_tax_inclusive = String(isInclusive || 0);
            filters.pm_sessionid = null;

            if (!filters.vendorId) {
                alert("Choose a vendor");
                return false;
            }
            if (!filters.invoiceno) {
                alert("Enter an invoice number");
                $("#txtEntryRefNo").focus();
                return false;
            }

            var cash = num($("#txtCashAmount").val()) || 0;
            var cheque = num($("#txtChequeAmount").val()) || 0;
            filters.payment = {
                paid_amount: cash + cheque,
                cash_amount: cash,
                cheque_amount: cheque,
                cheque_no: txt($("#txtChequeNo").val()),
                cheque_date: txt($("#txtChequeDate").val()),
                cheque_bank: txt($("#txtBankName").val())
            };

            var items = [];
            var missingItem = false;
            $("#tblPurchaseItems tr.classtest").each(function (i) {
                var $tr = $(this);
                var d = $tr.data("spec") || {};
                var cell = function (idx) {
                    return $tr.find("td:eq(" + idx + ")").attr("data-value") || $.trim($tr.find("td:eq(" + idx + ")").text());
                };
                var qty = num(cell(2));
                var cost = num(d.NetCost);
                var uom = num(d.uom);
                var defaultUom = num(d.defUomId);
                if (d.itm_id === undefined || d.itm_id === null) {
                    missingItem = true;
                }
                if (defaultUom === null || defaultUom < 0) {
                    defaultUom = (uom === null || uom < 0) ? null : uom;
                }
                items.push({
                    pi_id: num(d.pi_id),
                    row_no: i + 1,
                    itm_id: num(d.itm_id),
                    itm_code: txt($tr.find("td:eq(0)").text()),
                    itm_name: txt($tr.find("td:eq(1)").text()),
                    pi_org_price: num(cell(3)),
                    pi_price: num(cell(3)),
                    pi_qty: qty,
                    pi_discount_rate: num(cell(5)),
                    pi_item_tax: num(cell(8)),
                    pi_item_cess: num(d.cess),
                    pi_carton_count: null,
                    pi_item_per_carton: null,
                    itbh_custbatchid: txt(d.VendorBatch),
                    tum_id: (uom === null || uom < 0) ? null : uom,
                    itbh_no_piece: num(d.Qty),
                    itbh_length: num(d.Length),
                    itbh_width: num(d.Width),
                    itbh_kg: num(d.TotalKg),
                    itbh_kgmeter: null,
                    itbh_sqmt: null,
                    itbh_status: 1,
                    itbh_cost: cost,
                    itbh_costwithinvoice: num(d.CostWith),
                    itbh_costwithoutinvoice: num(d.CostWithout),
                    itbh_costotal: (cost === null || qty === null) ? null : cost * qty,
                    itbh_createddate: null,
                    itbh_createduser: txt(filters.userid),
                    itsv_uom_purchase: defaultUom
                });
            });

            if (items.length === 0) {
                alert("Please Add Item");
                return false;
            }
            if (missingItem) {
                alert("Item id missing for one or more rows. Please re-add the items.");
                return false;
            }

            var request = {
                purchase_filters: filters,
                purchase_items: items,
                time_zone: $.cookie("invntryTimeZone")
            };

            bootbox.confirm("Do you want to continue?", function (result) {
                if (result) {
                    loading();
                    $.ajax({
                        type: "POST",
                        url: "editPurchase.aspx/UpdatePurchaseEntryNew",
                        data: JSON.stringify({ request: request }),
                        contentType: "application/json; charset=utf-8",
                        dataType: "json",
                        success: function (msg) {
                            Unloading();
                            var res = JSON.parse(msg.d);
                            if (res.status) {
                                alert("Entry edited successfully");
                                window.location.href = "listPurchaseEntries.aspx";
                            } else {
                                alert(res.message || "Error!.. Please Try Again...");
                            }
                        },
                        error: function () {
                            Unloading();
                            alert("Error!.. Please Try Again...");
                        }
                    });
                } else {
                    bootbox.hideAll();
                }
            });
        }

        function updatePurchaseMaster() {

            sqlInjection();
            var filters = {};
            filters.TimeZone = $.cookie("invntryTimeZone");
            filters.userid = $.cookie("invntrystaffId");
            filters.vendorId = $("#txtVendorId").text();
            // alert(filters.vendorId);
            filters.purchaseId = purchaseId;
            filters.invoicenum = $("#txtEntryRefNo").val();
            filters.note = $("#txtSpecialNote").val();
            filters.TotalAmount = $("#txtTotalCost").text();
            filters.TotalDiscountRate = $("#txtTotalDiscountRate").text();
            filters.TotalDiscountAmount = $("#txtTotalDiscountAmount").text();
            filters.totalTaxamt = $("#txtTotalTaxamt").text();
            filters.TotalNetAmount = $("#txtTotalGrossamount").text();
            var tblrowCount = $('#tblPurchaseItems tr').length;
            if (tblrowCount <= 3) {
                alert("Please Add Item");
                return;
            }


            // filters.SpecialNote = $("#txtSpecialNote").val();
           
            // save to pos
            filters.rowCount = $('#tblPurchaseItems tr').length;
            filters.rowCount = filters.rowCount - 3;
            //  alert(rowCount);
            if (filters.rowCount == 0) {
                alert("select an item");
                return;
            }

            var query = '';
            var itemstring = '';



            for (var row = 1; row <= filters.rowCount; row++) {
                itemstring += "{";
                for (var col = 0; col <= 12; col++) {
                    if (col != 2 && col != 3 && col != 5 && col != 8) {
                     
                        if (col == 11) {
                            itemstring += "'itbs_id':'" + $("#tblPurchaseItems tr:eq(" + row + ") td:eq(" + col + ")").text() + "',";
                        }
                        if (col == 12) {
                            itemstring += "'purchaseItemId':'" + $("#tblPurchaseItems tr:eq(" + row + ") td:eq(" + col + ")").text() + "',";
                        }

                    }
                    else {
                        //alert($("#tblPurchaseItems tr:eq(" + row + ") td:eq(3) input").val());
                        if ($("#tblPurchaseItems tr:eq(" + row + ") td:eq(" + col + ") input").val() == "") {

                            if ($("#tblPurchaseItems tr:eq(" + row + ") td:eq(2) input").val() == "") {
                                itemstring += "'pi_qty':'1',";
                            }
                            else {
                                itemstring += "'pi_qty':'0',";
                            }

                        }
                        else {
                            if (col == 3) {
                                itemstring += "'pi_price':'" + $("#tblPurchaseItems tr:eq(" + row + ") td:eq(" + col + ") input").val() + "',";
                            }
                            if (col == 2) {
                                itemstring += "'pi_qty':'" + $("#tblPurchaseItems tr:eq(" + row + ") td:eq(" + col + ") input").val() + "',";
                            }

                            if (col == 5) {
                                itemstring += "'pi_discount_rate':'" + $("#tblPurchaseItems tr:eq(" + row + ") td:eq(" + col + ") input").val() + "',";
                            }

                            if (col == 8) {
                                itemstring += "'pi_taxperc':'" + $("#tblPurchaseItems tr:eq(" + row + ") td:eq(" + col + ") input").val() + "',";
                            }

                            // tableString = tableString + $("#tblPurchaseItems tr:eq(" + row + ") td:eq(" + col + ") input").val();
                        }
                    }

                }
                itemstring += "},";
            }

            var lastChar = itemstring.slice(-1);
            if (lastChar == ',') {
                itemstring = itemstring.slice(0, -1);
            }
            console.log(itemstring);
            itemstring = "[" + itemstring + "]";
            console.log(itemstring);
            console.log(filters);
            filters.branch_tax_method = tax_type;
            filters.branch_tax_inclusive = isInclusive;
            filters.purchaseDate=$("#txtEntryDate").val();
            bootbox.confirm("Do you want to continue?", function (result) {
                console.log(result)
                if (result) {
                    loading();
                    // alert("{'MemberId':'" + MemberId + "','MemberName':'" + MemberName + "','TotalCost':'" + TotalCost + "','TotalDiscountRate':'" + TotalDiscountRate + "','TotalDiscountAmount':'" + TotalDiscountAmount + "','Tax':'" + TaxAmount + "','billdate':'" + cur_dat + "','userid':'" + userid + "','TotalAmount':'" + TotalAmount + "','TotalCurrentAmount':'" + TotalCurrentAmount + "','TotalBalanceAmount':'" + TotalBalanceAmount + "','TotalPaidinFull':'" + TotalPaidinFull + "','paymentmode':'" + paymentmode + "','BankName':'" + BankName + "','ChequeAmount':'" + ChequeAmount + "','ChequeDate':'" + ChequeDate + "','ChequeNo':'" + ChequeNo + "','CardAmount':'" + CardAmount + "','CardNo':'" + CardNo + "','CardType':'" + CardType + "','CardBank':'" + CardBank + "','CashAmount':'" + CashAmount + "','CountryId':'" + CountryId + "','BranchId':'" + BranchId + "','SpecialNote':'" + SpecialNote + "','outstandingBillDate':'" + outstand_bl_dt + "','TimeZone':'" + TimeZone + "','tableString':'" + tableString + "','rowCount':" + rowCount + ",'PosCurrentPaidAmount':'" + PosCurrentPaidAmount + "','PosBalanceAmount':'" + PosBalanceAmount + "'}");
                    $.ajax({
                        type: "POST",
                        url: "editPurchase.aspx/editPurchaseEntry",
                        data: "{'filters':" + JSON.stringify(filters) + ",'tableString':" + JSON.stringify(itemstring) + "}",
                        contentType: "application/json; charset=utf-8",
                        dataType: "json",
                        success: function (msg) {
                            Unloading();
                            if (msg.d == "N") {
                                alert("Error!.. Please Try Again...");
                                return;
                            } else if (msg.d == "Y") {
                                alert("Entry edited successfully");
                                window.location.href = "listPurchaseEntries.aspx";

                            }else{
                                alert("Error!.. Please Try Again...");
                                return;
                            }
                        },
                        error: function (xhr, status) {
                            Unloading();
                            console.log(xhr.responseJSON.d);
                            var msgObj = JSON.parse(xhr.responseJSON.d);
                            alert(msgObj.message);
                        }
                    });
                } else {
                    bootbox.hideAll()
                    // What to do here?
                }
            });

        }

        function showAddItemPopUp(itemId, Name) {
            alert("Please add the item "+Name+" on warehousemanagement page..after that you can select the item");
            return;
            //itm_id = itemId;
            //$("#txtItemName").val('');
            //$("#txtWarehouseName").val('');
            //$("#txtClasAprice").val(0);
            //$("#txtClasBprice").val(0);
            //$("#txtClasCprice").val(0);
            //$("#txtItemName").val('-1');
            //$("#popupAddNewItem").modal('show');
            //$("#txtItemName").val(Name);
            //$("#txtWarehouseName").val(branchName);
            // alert($('select[name="warehousediv"] option:selected').val());
        }

        function loadTaxes() {            
            loading();
            $.ajax({
                type: "POST",
                url: "editPurchase.aspx/loadTaxes",
                data: "{'taxType':" + taxType + "}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    // alert(msg.d);
                    if (msg.d == "") {
                        alert("Error..!");
                        return;
                    }
                    else {
                        $("#selTaxcode").html(msg.d);
                        //   $("#selTaxcode").val(currentVal);
                        return;
                    }
                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }
       
        //function for add branch stock details
        function addBranchStockdetail() {
            //  alert($("#hdnItem").val());
            var branch =branchId;
            //var item = $("#txtItemAutoPopulate").val();
            var item = itm_id;
            var taxcode = $("#selTaxcode").val();
            if (taxcode == -1 || taxcode == "") {
                alert("choose item tax code");
                return;
            }

            var pricegroup_one = $("#txtClasAprice").val();
            var pricegroup_two = $("#txtClasBprice").val();
            var pricegroup_three = $("#txtClasCprice").val();
            var itm_mrp = 0;

            if (isNaN($("#txtClasAprice").val())) {
                alert("Price should be in number only");
                $("#txtClasAprice").focus();
                return;
            }
            if (isNaN($("#txtClasBprice").val())) {
                alert("Price should be in number only");
                $("#txtClasBprice").focus();
                return;
            }
            if (isNaN($("#txtClasCprice").val())) {
                alert("Price should be in number only");
                $("#txtClasCprice").focus();
                return;
            }

            loading();
            $.ajax({
                type: "POST",
                url: "editPurchase.aspx/addBranchStockDetails",
                data: "{'branch':'" + branch + "','item':'" + item + "','pricegroup_one':'" + pricegroup_one + "','pricegroup_two':'" + pricegroup_two + "','pricegroup_three':'" + pricegroup_three + "','taxcode':'" + taxcode + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {

                    Unloading();
                    // alert(msg.d);
                    if (msg.d == "E") {
                        alert("already exist");
                    }
                    if (msg.d == "Y") {
                        alert("Item Added Successfully");
                        popupclose('popupAddNewItem');
                        searchOrderitems(1);
                        return;
                    }


                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem");
                }
            });


        }

        function popupclose(divId) {
            $("#" + divId + "").modal('hide');
        }

        function addNewItem() {
            window.open('../web_inventory/itemmaster.aspx', '_blank');
        }

        //function for updating order status
        function cancelFunctn() {
            var result = confirm("Do you want to cancel the purchse entry?");
            if (result) {
                loading();
                $.ajax({
                    type: "POST",
                    url: "editPurchase.aspx/cancelFunctn",
                    data: "{'userId':'" + $.cookie('invntrystaffId') + "','purchaseId':'" + purchaseId + "'}",
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (msg) {
                        Unloading();
                        //alert(msg.d);
                        //alert("Success");
                        // return;
                        if (msg.d == "N") {
                            alert("Error!.. Please Try Again...");
                            return;
                        }else if(msg.d=="E"){
                            var result = confirm("Some One already changed the page..Do you want to reload and continue ?");
                            if(result){
                                window.location.reload();
                            }else{
                                return;
                            }
                        } else {

                            alert("Cancelled Successfully...");
                            window.location.href = "managepurchase.aspx?purchaseId="+purchaseId;
                            //setTimeout(function () {
                            //    window.location.reload();
                            //}, 3000);

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
    </script>

    
    <style>
        .modal {
            overflow: auto !important;
        }
    </style>
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
                            <label style="font-weight: bold; font-size: 16px;">Edit Purchase</label>
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
                                    <label>Basic Details</label>

                                    <ul class="nav navbar-right panel_toolbox pull-right">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                        </li>


                                    </ul>

                                </div>
                                <div class="x_content">
                                    <!-- info row -->
                                    <div class="row invoice-info">
                                       <%--  <div class="col-auto">
            <!-- Default input -->
            <label class="sr-only" for="inlineFormInputGroup">Username</label>
            <div class="input-group mb-2">
                <div class="input-group-prepend">
                    <div class="input-group-text">@</div>
                </div>
                <input type="text" class="form-control py-0" id="inlineFormInputGroup" placeholder="Username">
            </div>
        </div>--%>
                                 
                                          <div style="text-align:center">
                                        <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                    <input type="text" class="form-control has-feedback-left ui-autocomplete-input" id="txtEntryRefNo"  autocomplete="off" style="font-weight:bold;font-size:18px">
                                    <span class="form-control-feedback left" aria-hidden="true" style="background-color: #e9ecef;color:#495057;text-align: center;line-height: 1.5;"></span>
                                </div>
                                              </div>

                                       <%--     <input type="text" class="col-md-12 col-sm-12 col-xs-12 form-control form-control-sm" id="" style="font-size: 15px"/>--%>
                                       

                                       <div style="text-align:center;line-height: 2.5;" >
                                        <div class="col-sm-2 invoice-col" >

                                          
                                                
                                            <input type="text" class="form-control has-feedback-left" style="background-color:#fff" id="txtEntryDate" placeholder="From Date" readonly=""/>
                                        <span class="fa fa-calendar form-control-feedback left" aria-hidden="true"></span>
                                        </div>
                                        <!-- /.col -->

                                        <div class="col-sm-2 invoice-col">
                                            <label id="txtVendorName">Istanbul Supermarket Ajman</label>
                                            <label id="txtVendorId" style="display:none;"></label>
                                        </div>
                                        <!-- /.col -->
                                       
                                         <div class="col-sm-2 invoice-col">
                                            <label id="Label1">Balance:</label>
                                            <label id="txtBalance" style=";">0</label>
                                        </div>
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
                                <div class="x_title" style="margin-bottom: 0px;">
                                    <label>Status Change</label>

                                    <ul class="nav navbar-right panel_toolbox pull-right">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                        </li>


                                    </ul>

                                </div>
                                <div class="x_content">
                                    <!-- info row -->
                                    <div class="row invoice-info">
                                        <div class="col-sm-10 invoice-col">
                                            APPROVED BY: <label style="font-size:14px;color:#2967b5;" id="lblUserName"></label>
                                           

                                        </div>
                                   
                                        <div class="col-sm-2 invoice-col">
                                            <button class="btn btn-danger btn-xs" onclick="cancelFunctn()" style="display:;" id="btnEdit">
                                                
                                                CANCEL</button>
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
                                <div class="x_title" style="margin-bottom: 0px;">
                                    <label>Tax Details</label>

                                    <ul class="nav navbar-right panel_toolbox pull-right">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                        </li>


                                    </ul>

                                </div>
                                <div class="x_content">
                                    <!-- info row -->
                                    <div class="row invoice-info">
                                        <div class="col-sm-6 invoice-col">
                                            TAX METHOD: <label style="font-size:14px;color:#2967b5;" id="lbltaxMethod"></label>
                                           

                                        </div>
                                   
                                           <div class="col-sm-6 invoice-col">
                                            INCLUSIVE/EXCLUSIVE: <label style="font-size:14px;color:#2967b5;" id="lblTaxType"></label>
                                           

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


                              
                                     <div class="col-md-6 col-sm-6 col-xs-12 pull-right" style="padding-right: 0px;">
                                    <div class="col-md-10 col-sm-6 col-xs-8">
                                            <input class="form-control has-feedback-left" placeholder="Search Item" id="itemNames" autocomplete="off" type="search" />
                                            <span class="fa fa-search form-control-feedback left" aria-hidden="true"></span>
                                        </div>
                                        <div class="col-md-2 col-sm-6 col-xs-4" style="padding-right: 0px;" onclick="javascript:resetItemlist();">
                                            <div class="pull-right" style="font-size: 25px;" title="Search Items" data-toggle="modal">
                                                <label class="fa fa-shopping-cart" style="color: #ff6a00; cursor: pointer;"></label>
                                                <label class="fa fa-search" style="font-size: 16px; cursor: pointer; position: relative; margin-left: -12px;"></label>
                                            </div>

                                        </div>

                                          <%-- pop up for show  items --%>
                                            <div class="container">

                                                <div class="container">


                                            <div class="modal fade" id="popupItems" role="dialog" style="z-index: 1400;">
                                                <div class="modal-dialog modal-lg" style="">

                                                    <!-- Modal content-->
                                                    <div class="modal-content">
                                                        <div class="modal-header">
                                                            <button type="button" class="close" onclick="javascript:popupclose('popupItems');">&times;</button>
                                                            <div class="col-md-3 col-sm-6 col-xs-6">
                                                                <h4 class="modal-title">Items<span class="badge" style="color: #fff; margin-left: 5px; background: #d00101; padding-left: 5px; padding-right: 5px;" id="lblItemTotalrecords">0</span></h4>
                                                            </div>
                                                            <div class="col-md-3 col-sm-6 col-xs-6"></div>
                                                            <div class="col-md-4 col-sm-4 col-xs-12 pull-right">

                                                                <div class="col-md-8 col-sm-12 col-xs-12">
                                                                    <div class="" onclick="javascript:searchOrderitems(1);">
                                                                        <button type="button" class="btn btn-success mybtnstyl">
                                                                            <li class="fa fa-search" style="margin-right: 5px;"></li>
                                                                            Search
                                                                        </button>
                                                                    </div>
                                                                    <div class="" onclick="javascript:resetItemlist();">
                                                                        <button class="btn btn-primary mybtnstyl" type="reset">
                                                                            <li class="fa fa-refresh" style="margin-right: 5px;"></li>
                                                                            Reset
                                                                        </button>
                                                                    </div>
                                                                </div>

                                                                <div class="col-md-2 col-sm-12 col-xs-3">
                                                                    <select id="txtpospageno" onchange="javascript:searchOrderitems(1);" name="datatable-checkbox_length" aria-controls="datatable-checkbox" class=" input-sm">
                                                                        <option value="10">10</option>
                                                                        <option value="25" selected="selected">25</option>
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

                                                                <table id="tableItemlist" class="table table-striped table-bordered" style="table-layout: auto;">
                                                                    <thead>
                                                                        <tr>
                                                                            <th>Code</th>
                                                                            <th>Name
                                        <div onclick="javascript:addNewItem();" class="btn btn-success btn-xs pull-right" style="background-color: #d86612; border-color: #d86612;"><span style="color: #fff; margin-right: 5px; font-size: 14px;" class="fa fa-plus-square"></span>New Item</div>
                                                                            </th>
                                                                            <th>Current Stock</th>


                                                                        </tr>


                                                                        <tr>
                                                                            <td>
                                                                                <input type="text" id="searchposContent1" style="width: 80px; padding-right: 2px;" /></td>
                                                                            <td>
                                                                                <input type="text" id="searchposContent2" /></td>
                                                                            <td></td>

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
                                              <%-- pop up for add new item to item branch stock --%>

                                        <div class="container">


                                            <div class="modal fade" id="popupAddNewItem" role="dialog" style="z-index: 1600;">
                                                <div class="modal-dialog modal-md">
                                                    <div class="modal-content">
                                                        <div class="modal-header">
                                                            <button type="button" class="close" onclick="javascript:popupclose('popupAddNewItem');">&times;</button>
                                                            <div class="col-md-6 col-sm-6 col-xs-8">
                                                                <h4 class="modal-title">Add Item</h4>
                                                            </div>

                                                        </div>
                                                        <div class="modal-body">
                                                            <div class="row">
                                                                <div class="col-md-12">
                                                                    <form role="form" class="form-horizontal">
                                                                        <div class="form-group">
                                                                            <label class="control-label col-md-3 col-sm-3 col-xs-12">
                                                                                Item<span class="required">*</span>
                                                                            </label>
                                                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                                                <input type="text" id="txtItemName" placeholder="Enter Item name" required="required" class="form-control col-md-7 col-xs-12" disabled />
                                                                            </div>
                                                                        </div>

                                                                        <div class="form-group">
                                                                            <label class="control-label col-md-3 col-sm-3 col-xs-12">
                                                                                Warehouse<span class="required">*</span>
                                                                            </label>
                                                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                                                <input type="text" id="txtWarehouseName" placeholder="Enter Item name" required="required" class="form-control col-md-7 col-xs-12" disabled />
                                                                            </div>
                                                                        </div>



                                                                        <div class="form-group">
                                                                            <label class="control-label col-md-3 col-sm-3 col-xs-12" for="last-name">
                                                                                Tax code<span class="required">*</span>
                                                                            </label>
                                                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                                                <select id="selTaxcode" class="form-control" style="padding-right: 2px;">
                                                                                    <option value="-1" selected="selected">--Tax Code--</option>
                                                                                </select>
                                                                            </div>
                                                                        </div>

                                                                        <div class="form-group">
                                                                            <label class="control-label col-md-3 col-sm-3 col-xs-12" for="last-name">
                                                                                Class A
                                                                            </label>
                                                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                                                <input type="number" id="txtClasAprice" value="0" style="padding: 0px; text-indent: 3px;" placeholder="Enter price" name="last-name" min="0" required="required" class="form-control col-md-7 col-xs-12" />
                                                                            </div>
                                                                        </div>


                                                                        <div class="form-group">
                                                                            <label class="control-label col-md-3 col-sm-3 col-xs-12" for="last-name">
                                                                                Class B
                                                                            </label>
                                                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                                                <input type="number" id="txtClasBprice" value="0" style="padding: 0px; text-indent: 3px;" placeholder="Enter price" name="last-name" min="0" required="required" class="form-control col-md-7 col-xs-12" />
                                                                            </div>
                                                                        </div>


                                                                        <div class="form-group">
                                                                            <label class="control-label col-md-3 col-sm-3 col-xs-12" for="last-name">
                                                                                Class C
                                                                            </label>
                                                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                                                <input type="number" id="txtClasCprice" value="0" style="padding: 0px; text-indent: 3px;" placeholder="Enter price" name="last-name" min="0" required="required" class="form-control col-md-7 col-xs-12" />
                                                                            </div>
                                                                        </div>
                                                                    </form>
                                                                    <div class="clearfix"></div>

                                                                    <div class="ln_solid"></div>
                                                                    <div class="form-group" style="padding-bottom: 40px;">
                                                                        <div class="col-md-6 col-sm-6 col-xs-12 col-md-offset-3">
                                                                            <div id="btnSave">
                                                                                <div class="btn btn-success mybtnstyl" onclick="javascript:addBranchStockdetail();">SAVE</div>
                                                                            </div>

                                                                            <div id="btnDelete" style="display: =;">
                                                                                <div class="btn btn-danger mybtnstyl" onclick="javascript:popupclose('popupAddNewItem');">CANCEL</div>
                                                                            </div>
                                                                            <%--<div onclick="javascript:clearUsertype();" class="btn btn-danger mybtnstyl" id="btnCancel">CANCEL</div>--%>
                                                                            <%--<button  id="btnUserDetailsUpdate" style="display:none" class="btn btn-success" onclick="javascript:updateUserDetails();" type="reset">Update</button>--%>
                                                                        </div>
                                                                    </div>

                                                                </div>

                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>

                                        </div>
                                         </div>

                                    <div id="itemSpecDiv">
                                        <div class="x_panel" style="margin-bottom: 20px;">
                                            <div class="x_title" style="margin-bottom: 15px;">
                                                <label>Item Specification</label>
                                                <ul class="nav navbar-right panel_toolbox">
                                                    <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a></li>
                                                </ul>
                                            </div>
                                            <div class="x_content">
                                                <div class="row">
                                                    <div class="col-md-2 col-sm-6 col-xs-12 form-group"><label>Item Code</label><div><label id="itemSpec_Code" style="font-weight: bold; color: #1e99c7"></label></div></div>
                                                    <div class="col-md-4 col-sm-6 col-xs-12 form-group"><label>Item Name</label><div><label id="itemSpec_Name" style="font-weight: bold; color: #1e99c7"></label></div></div>
                                                    <div class="col-md-2 col-sm-6 col-xs-12 form-group"><label>UOM</label><div><label id="itemSpec_DefUom" style="font-weight: bold; color: #1e99c7"></label></div></div>
                                                    <div class="col-md-2 col-sm-6 col-xs-12 form-group"><label>HSN Code</label><div><label id="itemSpec_Hsn" style="font-weight: bold; color: #1e99c7"></label></div></div>
                                                    <div class="col-md-2 col-sm-6 col-xs-12 form-group"><label>Tax Percentage</label><div><label id="itemSpec_TaxPerc" style="font-weight: bold; color: #1e99c7"></label></div></div>
                                                </div>
                                                <hr />
                                                <div class="row">
                                                    <div class="col-md-2 col-sm-6 col-xs-12 form-group"><label for="itemSpec_Qty">Quantity</label><input type="text" class="form-control itemspec-decimal itemspec-calc" id="itemSpec_Qty" /></div>
                                                    <div class="col-md-2 col-sm-6 col-xs-12 form-group"><label for="itemSpec_Uom">UOM</label><select class="form-control" id="itemSpec_Uom"><option value="-1">Select</option></select></div>
                                                    <div class="col-md-2 col-sm-4 col-xs-12 form-group"><label for="itemSpec_Length">Length/Unit</label><input type="text" class="form-control itemspec-decimal" id="itemSpec_Length" /></div>
                                                    <div class="col-md-2 col-sm-4 col-xs-12 form-group"><label for="itemSpec_Width">Width/Unit</label><input type="text" class="form-control itemspec-decimal" id="itemSpec_Width" /></div>
                                                    <div class="col-md-2 col-sm-4 col-xs-12 form-group"><label for="itemSpec_TotalKg">Total KG</label><input type="text" class="form-control itemspec-decimal" id="itemSpec_TotalKg" /></div>
                                                    <div class="col-md-2 col-sm-4 col-xs-12 form-group"><label for="itemSpec_FinalQty">Final Quantity<span id="itemSpec_FinalQtyUom"></span></label><input type="text" class="form-control" id="itemSpec_FinalQty" readonly="readonly" /><small id="itemSpec_FinalQtyErr" class="text-danger"></small></div>
                                                </div>
                                                <div class="row">
                                                    <div class="col-md-2 col-sm-6 col-xs-12 form-group"><label for="itemSpec_Price">Purchase Price</label><input type="text" class="form-control itemspec-decimal itemspec-calc" id="itemSpec_Price" /></div>
                                                    <div class="col-md-2 col-sm-6 col-xs-12 form-group"><label for="itemSpec_Discount">Discount (%)</label><input type="number" class="form-control itemspec-decimal itemspec-calc" id="itemSpec_Discount" /></div>
                                                    <div class="col-md-2 col-sm-6 col-xs-12 form-group"><label for="itemSpec_DiscountAmt">Discount Amount</label><input type="text" class="form-control" id="itemSpec_DiscountAmt" readonly="readonly" /></div>
                                                    <div class="col-md-2 col-sm-6 col-xs-12 form-group"><label for="itemSpec_Taxable">Taxable Value</label><input type="text" class="form-control" id="itemSpec_Taxable" readonly="readonly" /></div>
                                                    <div class="col-md-2 col-sm-6 col-xs-12 form-group"><label>Tax Amount</label><input type="text" class="form-control" id="itemSpec_TaxAmount" readonly="readonly" /></div>
                                                    <div class="col-md-2 col-sm-6 col-xs-12 form-group"><label for="itemSpec_Net">Net Amount</label><input type="text" class="form-control" id="itemSpec_Net" readonly="readonly" /></div>
                                                </div>
                                                <div class="row">
                                                    <div class="col-md-2 col-sm-6 col-xs-12 form-group"><label for="itemSpec_VendorBatch">Supplier Batch No.</label><input type="text" class="form-control" id="itemSpec_VendorBatch" maxlength="50" /></div>
                                                    <div class="col-md-2 col-sm-6 col-xs-12 form-group"><label for="itemSpec_CostWith">Cost With Invoice / Unit</label><input type="text" class="form-control itemspec-decimal itemspec-calc" id="itemSpec_CostWith" /></div>
                                                    <div class="col-md-2 col-sm-6 col-xs-12 form-group"><label for="itemSpec_CostWithout">Cost Without Invoice</label><input type="text" class="form-control itemspec-decimal itemspec-calc" id="itemSpec_CostWithout" /></div>
                                                    <div class="col-md-2 col-sm-6 col-xs-12 form-group"><label for="itemSpec_NetCost">Net Purchase Cost</label><input type="text" class="form-control" id="itemSpec_NetCost" readonly="readonly" /></div>
                                                    <div id="specButtons" class="col-md-4 col-xs-12 form-group" style="white-space: nowrap;">
                                                        <br />
                                                        <button type="button" id="btnSpecSave" class="btn btn-success" style="display: inline-block;" data-action="Add">Add</button>
                                                        <button type="button" id="btnSpecCancel" class="btn btn-default" style="display: inline-block;">Cancel</button>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                  <div class="col-md-12 col-sm-12 col-xs-12" style="overflow-x: auto;">
                                    <div class="x_content">

                                        <table id="tblPurchaseItems" class="table table-striped table-bordered" style="table-layout: auto;">
                                            <thead>
                                                <tr>
                                                    <td>Item Code</td>
                                                    <td style="width: 300px;">Name</td>
                                                     <td>QTY</td>
                                                    <td>Price</td>
                                                   
                                                    <td>Amount</td>
                                                    <td>Dis %</td>
                                                    <td>Dis Amount</td>
                                                    <td>Taxable Value</td>
                                                    <td>Tax Perc</td>
                                                    <td>Tax Amount</td>
                                                    <td>Net Amount</td>
                                                    <td>UOM</td>
                                                   
                                                    <td></td>

                                                </tr>
                                            </thead>


                                            <tbody id="tbodyItems">
                                            
                                            </tbody>
                                            <tbody id="tbodyPayments">
                                                <tr>
                                                    <td style="border-right: none;"></td>
                                                    <td style="border-right: none;"></td>
                                                    <td style="border-right: none;"></td>
                                                    <td style="text-align: right;"><b>Total</b></td>
                                                    <td id="txtTotalCost"></td>
                                                    <td id="txtTotalDiscountRate"></td>
                                                    <td id="txtTotalDiscountAmount"></td>
                                                    <td id="txtTotalTaxableValue"></td>
                                                    <td></td>
                                                    <td id="txtTotalTaxamt"></td>
                                                    <td id="txtTotalNetAmount"></td>
                                                    <td></td>
                                                    <td></td>
                                                </tr>
                                             <tr>
                                                    <td colspan="5"></td>
                                                    <td></td>
                                                   
                                                    <%--<td><b>Round</b></td>--%>
                                                    <td colspan="3" style="cursor:pointer"><label style="color:#505258;cursor:">Round off Value: </label><label id="lblRoundOff" style="color:#900c0c"></label></td>

                                                    <td></td>
                                                  <td>
                                                        <label id="txtTotalGrossamount"></label>
                                                    </td>
                                                    <td></td>
                                                    <td></td>
                                                   
                                          

                                                </tr>
                                            </tbody>



                                        </table>
                                         <div class="col-md-1 col-sm-3 col-xs-3" style="float: right;" id="divUpdateOrder" onclick="javascript:savePurchaseEntry();">
                                            <button class="btn btn-primary mybtnstyl pull-right" type="button">Save</button>
                                        </div>
                                    </div>
                                </div>
                          
                        </div>
                    </div>
                    <div class="clearfix"></div>
                   
                      
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

                    <div class="clearfix"></div>
                    <%-- popup for showing transaction details --%>
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


                                


                                 <input type="hidden" id="lblTransRefEdit" value="0" />


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

                    <div class="clearfix"></div>
                    <%-- popup for showing payment edit popup --%>
                    
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
                                                <%--<hr />
                                                <div class="form-group" id="wallet_edit_row" style="background-color:#f6f6f6">
                                                    <label class="col-form-label" for="txtWalletAmt">Wallet</label>
                                                    <input class="form-control" type="number" id="txtWalletAmt" onkeyup="calcPaymentEditForm()"/>
                                                </div>--%>

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
