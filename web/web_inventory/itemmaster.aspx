<%@ Page Language="C#" AutoEventWireup="true" CodeFile="itemmaster.aspx.cs" Inherits="web_inventory_itemmaster" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Item Master  | Invoice Me</title>

    <script src="../js/common.js"></script>
    <script src="../js/jquery-2.0.3.js"></script>
    <script src="../js/pagination.js"></script>
    <script src="../js/jquery.cookie.js"></script>
    <!-- Bootstrap -->
    <link href="../css/bootstrap/bootstrap.min.css" rel="stylesheet" />
    <!-- Font Awesome -->
    <link href="../css/bootstrap/font-awesome/css/font-awesome.min.css" rel="stylesheet" />
    <!-- NProgress -->
    <link href="../css/bootstrap/nprogress.css" rel="stylesheet" />
    <!-- Custom Theme Style -->
    <link href="../css/bootstrap/custom.min.css" rel="stylesheet" />
    <!-- mystyle Style -->
    <link href="../css/bootstrap/mystyle.css" rel="stylesheet" />
     <%-- autosearch --%>
    <script src="../autosearch/jquery-ui.js" type="text/javascript"></script>
    <link href="../autosearch/jquery-ui.css" rel="Stylesheet" type="text/css" />
    <script src="../autosearch/jquery-ui.min.js" type="text/javascript"></script>
    <script src="../autosearch/jquery-1.12.4.js" type="text/css"></script>
    <%-- autosearch --%>
    <script type="text/javascript">
        var brandval = '';
        var pricegrupsNo = "";
        var pricegruparray = [];
        var itemid = "";
        var couponItemId = 0;
        $(document).ready(function () {

            var BranchId = $.cookie("invntrystaffBranchId");
            var CountryId = $.cookie("invntrystaffCountryId");
            //if (!BranchId) {
            //    location.href = "login.aspx";
            //    return false;
            //}
            //if (!CountryId) {
            //    location.href = "login.aspx";
            //    return false;
            //}
            // showProfileHeader(1);
            //  loadpricegroups();
            SearchAutoItems();
            clearform();
            //showBrands();
            //showsupplierlist();
            //loadcategory();
            loadSpecDropdowns();
            searchitemlist(1);

            $("#Text_qty_per_carton").keypress(function (e) {
                //if the letter is not digit then display error and don't type anything
                if (e.which != 8 && e.which != 0 && (e.which < 48 || e.which > 57)) {
                    //display error message
                    $("#errmsg").html("Digits Only").show().fadeOut("slow");
                    return false;
                }
            });
            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " © ");

        });



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



        //function for showing brand
        function showBrands() {
            //  var loggedInBranch = $.cookie("staffBranchId");
            loading();
            $.ajax({
                type: "POST",
                url: "itemmaster.aspx/showBrands",
                data: "{}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    //alert(msg.d);
                    if (msg.d == "") {
                        alert("Error..!");
                        return;
                    }
                    else {
                        $("#comboBrandtype").html(msg.d);
                        //if (group_id !== undefined) {
                        //    // alert("");
                        //    editGroupDetails(group_id);
                        //}
                        //  searchGroupClass(1);
                        return;
                    }
                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }


        //function for load suppliers
        function showsupplierlist() {
            //  var loggedInBranch = $.cookie("staffBranchId");
            loading();
            $.ajax({
                type: "POST",
                url: "itemmaster.aspx/showsupplierlist",
                data: "{}",
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
                        $("#showSupplierdiv").html(msg.d);
                        //if (group_id !== undefined) {
                        //    // alert("");
                        //    editGroupDetails(group_id);
                        //}
                        //  searchGroupClass(1);
                        return;
                    }
                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }

        //function for load subcategory
        function loadcategory() {
            //  brandval = $("#comboBrandtype").val();
            //  alert(brandVal);
            loading();
            $.ajax({
                type: "POST",
                url: "itemmaster.aspx/showCategoryTypes",
                data: "{}",
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
                        $("#combocategory").html(msg.d);
                        // $("#combocategory").val(val);
                        //if (group_id !== undefined) {
                        //    // alert("");
                        //    editGroupDetails(group_id);
                        //}
                        //  searchGroupClass(1);
                        return;
                    }
                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }

        // Load all specification dropdown values
        function loadSpecDropdowns() {
            loading();
            $.ajax({
                type: "POST",
                url: "itemmaster.aspx/loadAllSpecDropdowns",
                data: "{}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (!msg.d) return;
                    var data = JSON.parse(msg.d);
                    if (data.stockGroups) $("#comboStockGroup").html(data.stockGroups);
                    if (data.stockCategories) $("#comboStockCategory").html(data.stockCategories);
                    if (data.uomPurchase) $("#comboUomPurchase").html(data.uomPurchase);
                    else if (data.units) $("#comboUomPurchase").html(data.units);
                    if (data.uomSales) $("#comboUomSales").html(data.uomSales);
                    else if (data.units) $("#comboUomSales").html(data.units);
                    if (data.alternateUnits) $("#comboAlternateUnits").html(data.alternateUnits);
                    if (data.reportingUoms) $("#comboReportingUom").html(data.reportingUoms);
                    if ($("#combosearchUom").length && (data.uomSales || data.units)) {
                        $("#combosearchUom").html(data.uomSales || data.units);
                        $("#combosearchUom option:first").text("--Select UOM--");
                    }
                    if (data.specItem) {
                        $("#comboSpecItem").html(data.specItem);
                        $("#combosearchSpecItem").html(data.specItem);
                        $("#combosearchSpecItem option:first").text("--Item Technical Specification--");
                    }
                    if (data.specBrand) {
                        $("#comboSpecBrand").html(data.specBrand);
                        if ($("#combosearchSpecBrand").length) {
                            $("#combosearchSpecBrand").html(data.specBrand);
                            $("#combosearchSpecBrand option:first").text("--Spec Brand--");
                        }
                    }
                    if (data.specThickness) {
                        $("#comboSpecThickness").html(data.specThickness);
                        if ($("#combosearchSpecThickness").length) {
                            $("#combosearchSpecThickness").html(data.specThickness);
                            $("#combosearchSpecThickness option:first").text("--Spec Thickness--");
                        }
                    }
                    if (data.specColour) {
                        $("#comboSpecColour").html(data.specColour);
                        if ($("#combosearchSpecColour").length) {
                            $("#combosearchSpecColour").html(data.specColour);
                            $("#combosearchSpecColour option:first").text("--Spec Colour--");
                        }
                    }
                    if (data.specCoating) $("#comboSpecCoating").html(data.specCoating);
                    if (data.specPitch) $("#comboSpecPitch").html(data.specPitch);
                    if (data.specCrust) $("#comboSpecCrust").html(data.specCrust);
                    if (data.specWidth) $("#comboSpecWidth").html(data.specWidth);
                    if (data.specYieldStrength) $("#comboSpecYieldStrength").html(data.specYieldStrength);
                    if (data.specMachine) {
                        $("#comboSpecMachine").html(data.specMachine);
                        if ($("#combosearchSpecMachine").length) {
                            $("#combosearchSpecMachine").html(data.specMachine);
                            $("#combosearchSpecMachine option:first").text("--Spec Machine--");
                        }
                    }
                },
                error: function () {
                    Unloading();
                }
            });
        }

        //function for add item
        function addItemDetails(actionType, itemid) {
            sqlInjection();
            var itmcode = $("#txtitemcode").val();
            var itmname = $("#txtitemname").val();
            var itmdescrptn = $("#txtitemdescrptn").val();
           // var itmbrand = $("#comboBrandtype").val();
           // var itmcatgry = $("#combocategory").val();
           // var itmsubcategory = $("#comboselectsubcategory").val();
            var itemType = $("#comboItemtype").val();
            var couponItemQty=$("#txtitemqty").val();
            if (itemType == -1) {
                alert("Please select item type");
                return;
            } else if (itemType == 3) {
                if ($("#txtAutoitemName").val() == "") {
                    alert("Please add an item");
                    return;
                }
                if (couponItemQty == "" || couponItemQty == 0) {
                    alert("Please enter quantity");
                    return;
                }
                if (isNaN($("#txtitemqty").val())) {
                    alert("Quantity should be in number only");
                    $("#txtitemqty").focus();
                    return;
                }
            }
            if (couponItemQty == "") {
                couponItemQty = 0;
            }
            var supplier = 0;
            itmname = itmname.trim();

            if (itmcode == "") {
                alert("Please enter item code");
                return;
            }
            if (itmname == "") {
                alert("Please enter item name");
                return;
            }
            /*if (itmbrand == "" || itmbrand == -1) {
                alert("Please choose Brand");
                return;
            }

            if (itmcatgry == "" || itmcatgry == -1) {
                alert("Please choose Category type");
                return;
            }
            */
            var qty_per_carton = $("#Text_qty_per_carton").val();

            if (qty_per_carton == "" || parseInt(qty_per_carton) < 1) {
                alert("Quantity per carton should be 1 or greater");
                $("#Text_qty_per_carton").val(1);
                return;
            }

            var specData = {
                itsv_part_no: $("#txtPartNo").val(),
                itsv_stock_group: $("#comboStockGroup").val(),
                itsv_category: $("#comboStockCategory").val(),
                itsv_description: $("#txtItsvDescription").val(),
                itsv_uom_purchase: $("#comboUomPurchase").val(),
                itsv_uom_sales: $("#comboUomSales").val(),
                itsv_alternate_units: $("#comboAlternateUnits").val(),
                itsv_reporting_uom: $("#comboReportingUom").val(),
                itsv_conversion_value: $("#txtConversionValue").val(),
                itsv_denominator: $("#txtDenominator").val(),
                itsv_bom_enabled: $("#comboBomEnabled").val(),
                itsv_hsn_sac: $("#txtHsnSac").val(),
                itsv_printing_name: $("#txtPrintingName").val(),
                itsv_spec_item: $("#comboSpecItem").val(),
                itsv_spec_pitch: $("#comboSpecPitch").val(),
                itsv_spec_crust: $("#comboSpecCrust").val(),
                itsv_spec_brand: $("#comboSpecBrand").val(),
                itsv_spec_thickness: $("#comboSpecThickness").val(),
                itsv_spec_colour: $("#comboSpecColour").val(),
                itsv_spec_coating: $("#comboSpecCoating").val(),
                itsv_spec_yield_strength: $("#comboSpecYieldStrength").val(),
                itsv_spec_width: $("#comboSpecWidth").val(),
                itsv_spec_machine: $("#comboSpecMachine").val()
            };

            loading();
            $.ajax({
                type: "POST",
                url: "itemmaster.aspx/Additemmasters",
                data: JSON.stringify({
                    actionType: actionType,
                    itemid: (itemid !== undefined && itemid !== null) ? itemid.toString() : "0",
                    itemcode: itmcode,
                    itemname: itmname,
                    itemdesc: itmdescrptn,
                    supplier: supplier.toString(),
                    itemType: parseInt(itemType),
                    couponItemId: parseInt(couponItemId),
                    quantity: parseInt(couponItemQty),
                    itm_qty_per_carton: parseInt(qty_per_carton),
                    specData: specData
                }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d == "E") {
                        alert("Item code or Item Name already exist");
                    }
                    if (msg.d == "Y") {
                        if (actionType == "insert") {
                            alert("Item Added Successfully");
                        }
                        if (actionType == "update") {
                            alert("Item Updated Successfully");
                        }
                        clearform();
                        searchitemlist(1);
                        return;
                    }
                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem");
                }
            });
        }

        //search
        function searchitemlist(page) {
            sqlInjection();
            var filters = {};

            var itemName = $("#txtSearchItem").val();
            if (itemName !== undefined && itemName.trim() != "") {
                filters.itemName = itemName.trim();
            }

            var partNo = $("#txtSearchPartNo").val();
            if (partNo !== undefined && partNo.trim() != "") {
                filters.partNo = partNo.trim();
            }

            var specItem = $("#combosearchSpecItem").val();
            if (specItem !== undefined && specItem != "-1") {
                filters.specItem = specItem;
            }

            if ($("#combosearchSpecBrand").length && $("#combosearchSpecBrand").val() != "-1") {
                filters.specBrand = $("#combosearchSpecBrand").val();
            }
            if ($("#combosearchSpecThickness").length && $("#combosearchSpecThickness").val() != "-1") {
                filters.specThickness = $("#combosearchSpecThickness").val();
            }
            if ($("#combosearchSpecColour").length && $("#combosearchSpecColour").val() != "-1") {
                filters.specColour = $("#combosearchSpecColour").val();
            }
            if ($("#combosearchSpecMachine").length && $("#combosearchSpecMachine").val() != "-1") {
                filters.specMachine = $("#combosearchSpecMachine").val();
            }
            if ($("#combosearchUom").length && $("#combosearchUom").val() != "-1") {
                filters.uom = $("#combosearchUom").val();
            }

            var perpage = $("#txtpageno").val();
            console.log(filters);
            loading();
            $.ajax({
                type: "POST",
                url: "itemmaster.aspx/searchItemList",
                data: "{'page':" + page + ",'filters':" + JSON.stringify(filters) + ",'perpage':'" + perpage + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    if (msg.d == "N") {
                        $("#divSearchItems1 tbody").html('<td colspan="8" style="padding:15px;"><div style="width:100%;text-align:center;font-weight:bold;"><div style="display:inline-block">Nothing Found...</div></div></td>');
                        $("#paginatediv").html('');
                        $("#lblTotalrerd").text(0);
                    }
                    else {
                        var obj = JSON.parse(msg.d);
                        var htm = "";
                        $("#lblTotalrerd").text(obj.count);
                        var highlightName = filters.itemName || "";
                        var highlightPart = filters.partNo || "";
                        $.each(obj.data, function (i, row) {
                            htm += "<tr style='cursor:pointer; font-size:12px;' id='itemRow" + i + "' onclick='javascript:editItemDetails(" + row.itm_id + ");'>";
                            htm += "<td>" + getHighlightedValue(highlightName, (row.itm_code || '').toString()) + "</td>";
                            htm += "<td>" + (row.itsv_part_no ? getHighlightedValue(highlightPart, row.itsv_part_no.toString()) : '-') + "</td>";
                            htm += "<td><b>" + getHighlightedValue(highlightName, (row.itm_name || '').toString()) + "</b>" +
                                   (row.itsv_printing_name && row.itsv_printing_name != row.itm_name ? "<br/><small style='color:#73879C;'>Print: " + getHighlightedValue(highlightName, row.itsv_printing_name) + "</small>" : "") +
                                   (row.spec_item_name ? "<br/><small style='color:#1ABB9C;'><i class='fa fa-sliders'></i> Spec: " + row.spec_item_name + "</small>" : "") +
                                   (row.uom_sales_name ? "<br/><small style='color:#337ab7;'><i class='fa fa-balance-scale'></i> UOM: " + row.uom_sales_name + "</small>" : "") + "</td>";
                          
                            htm += "<td>" + (row.stock_group_name ? "<span class='label label-default' style='font-size:11px;'>" + row.stock_group_name + "</span>" : '-') + "</td>";
                            htm += "<td>" + (row.itsv_hsn_sac ? row.itsv_hsn_sac : '-') + "</td>";
                            htm += "<td style='text-align:center;'>" + (row.itm_qty_per_carton || 1) + (row.uom_sales_name ? " <small style='color:#73879C;'>(" + row.uom_sales_name + ")</small>" : "") + "</td>";
                            htm += '<td><div class="btn btn-primary btn-xs" onclick="javascript:editItemDetails(' + row.itm_id + ');">';
                            htm += '<li class="fa fa-eye" style="font-size:large;"></li>';
                            htm += '</div></td>';
                            htm += "</tr>";
                        });
                        htm += '<tr>';
                        htm += '<td colspan="8">';
                        htm += '<div id="paginatediv" style="text-align: center;">';
                        htm += '</div>';
                        htm += '</td>';
                        htm += '</tr>';
                        $("#divSearchItems1 tbody").html(htm);
                        $("#paginatediv").html(paginate(obj.count, perpage, page, "searchitemlist"));
                    }
                    Unloading();
                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem");
                }
            });
        }

        //function for reset
        function resetitem() {
            $("#txtSearchItem").val('');
            $("#txtSearchPartNo").val('');
            $("#combosearchSpecItem").val(-1);
            if ($("#combosearchSpecBrand").length) $("#combosearchSpecBrand").val(-1);
            if ($("#combosearchSpecThickness").length) $("#combosearchSpecThickness").val(-1);
            if ($("#combosearchSpecColour").length) $("#combosearchSpecColour").val(-1);
            if ($("#combosearchSpecMachine").length) $("#combosearchSpecMachine").val(-1);
            if ($("#combosearchUom").length) $("#combosearchUom").val(-1);
            searchitemlist(1);
        }

        //function to toggle additional specification filters
        function toggleMoreSpecs() {
            var $div = $("#divMoreSpecFilters");
            if ($div.is(":visible")) {
                $div.slideUp(200);
                $("#btnToggleMoreSpecs").removeClass("btn-success").addClass("btn-default").html('<i class="fa fa-filter" style="color:#3498DB;"></i> Specs <span class="caret"></span>');
            } else {
                $div.slideDown(200);
                $("#btnToggleMoreSpecs").removeClass("btn-default").addClass("btn-success").html('<i class="fa fa-check"></i> Close Specs');
            }
        }

        //function to download all items details (all columns) in excel sheet
        function downloadItemMasterExcel() {
            sqlInjection();
            var filters = {};

            var itemName = $("#txtSearchItem").val();
            if (itemName !== undefined && itemName.trim() != "") {
                filters.itemName = itemName.trim();
            }

            var partNo = $("#txtSearchPartNo").val();
            if (partNo !== undefined && partNo.trim() != "") {
                filters.partNo = partNo.trim();
            }

            var specItem = $("#combosearchSpecItem").val();
            if (specItem !== undefined && specItem != "-1") {
                filters.specItem = specItem;
            }

            if ($("#combosearchSpecBrand").length && $("#combosearchSpecBrand").val() != "-1") {
                filters.specBrand = $("#combosearchSpecBrand").val();
            }
            if ($("#combosearchSpecThickness").length && $("#combosearchSpecThickness").val() != "-1") {
                filters.specThickness = $("#combosearchSpecThickness").val();
            }
            if ($("#combosearchSpecColour").length && $("#combosearchSpecColour").val() != "-1") {
                filters.specColour = $("#combosearchSpecColour").val();
            }
            if ($("#combosearchSpecMachine").length && $("#combosearchSpecMachine").val() != "-1") {
                filters.specMachine = $("#combosearchSpecMachine").val();
            }
            if ($("#combosearchUom").length && $("#combosearchUom").val() != "-1") {
                filters.uom = $("#combosearchUom").val();
            }

            loading();
            $.ajax({
                type: "POST",
                url: "itemmaster.aspx/prepareItemMasterExport",
                data: "{'filters':" + JSON.stringify(filters) + "}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d == "N" || msg.d == "0") {
                        alert("No items found to download!");
                        return false;
                    } else if (msg.d == "Y") {
                        location.href = "downloadItemMaster.aspx";
                        return false;
                    } else {
                        alert("Error preparing export: " + msg.d);
                        return false;
                    }
                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem");
                }
            });
        }

        //function for clearform
        function clearform() {
            $("#btnservMasterAction").html("<div class='btn btn-success fl mybtnstyl' onclick='javascript:addItemDetails(\"insert\",0);'>SAVE</div>");
            $("#txtitemcode").val('');
           // $("#comboBrandtype").val(-1);
           // $("#combocategory").val(-1);
            $("#combovendorlist").val(0);
            $("#txtitemname").val('');
            $("#txtitemdescrptn").val('');
            $("#txtitemSP").html('');
            $("#comboselectsubcategory").val(-1);
            for (var i = 1; i <= 5; i++) {
                $("#searchvalContent" + i).val('');
            }
            $("#comboItemtype").val(-1);
            $("#txtAutoitemName").val("");
            $("#txtitemqty").val("");
            $("#Text_qty_per_carton").val(1);
            showDivCoupon();

            // Clear additional 23 columns
            $("#txtPartNo").val('');
            $("#txtPrintingName").val('');
            $("#comboStockGroup").val(-1);
            $("#comboStockCategory").val(-1);
            $("#txtItsvDescription").val('');
            $("#comboUomPurchase").val(-1);
            $("#comboUomSales").val(-1);
            $("#comboAlternateUnits").val(-1);
            $("#comboReportingUom").val(-1);
            $("#txtConversionValue").val(0);
            $("#txtDenominator").val(1);
            $("#comboBomEnabled").val(0);
            $("#txtHsnSac").val('');
            $("#comboSpecItem").val(-1);
            $("#comboSpecPitch").val(-1);
            $("#comboSpecCrust").val(-1);
            $("#comboSpecBrand").val(-1);
            $("#comboSpecThickness").val(-1);
            $("#comboSpecColour").val(-1);
            $("#comboSpecCoating").val(-1);
            $("#comboSpecYieldStrength").val(-1);
            $("#comboSpecWidth").val(-1);
            $("#comboSpecMachine").val(-1);
        }

        //function for view item details
        function editItemDetails(id) {
            itemid = id;
            loading();
            $.ajax({
                type: "POST",
                url: "itemmaster.aspx/editItemDetails",
                data: "{'itmid':'" + id + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    var obj = JSON.parse(msg.d);
                    console.log(obj);
                    
                    $("#btnservMasterAction").html("<div class='btn btn-success mybtnstyl' onclick='javascript:addItemDetails(\"update\"," + obj[0].itm_id + ");'>UPDATE</div>");
                    $("#txtitemcode").val(obj[0].itm_code || '');
                    $("#txtitemname").val(obj[0].itm_name || '');
                    $("#txtitemdescrptn").val(obj[0].itm_description || '');
                    //$("#comboBrandtype").val(obj[0].itm_brand_id != null ? obj[0].itm_brand_id : -1);
                   // $("#combocategory").val(obj[0].itm_category_id != null ? obj[0].itm_category_id : -1);
                    $("#combovendorlist").val(obj[0].itm_supplierid != null ? obj[0].itm_supplierid : 0);
                    $("#comboItemtype").val(obj[0].itm_type != null ? obj[0].itm_type : -1);
                    $("#Text_qty_per_carton").val(obj[0].itm_qty_per_carton != null ? obj[0].itm_qty_per_carton : 1);

                    // Populate additional 23 columns
                    $("#txtPartNo").val(obj[0].itsv_part_no != null ? obj[0].itsv_part_no : '');
                    $("#txtPrintingName").val(obj[0].itsv_printing_name || '');
                    $("#comboStockGroup").val(obj[0].itsv_stock_group != null ? obj[0].itsv_stock_group : -1);
                    $("#comboStockCategory").val(obj[0].itsv_category != null ? obj[0].itsv_category : -1);
                    $("#txtItsvDescription").val(obj[0].itsv_description != null ? obj[0].itsv_description : '');
                    $("#comboUomPurchase").val(obj[0].itsv_uom_purchase != null ? obj[0].itsv_uom_purchase : -1);
                    $("#comboUomSales").val(obj[0].itsv_uom_sales != null ? obj[0].itsv_uom_sales : -1);
                    $("#comboAlternateUnits").val(obj[0].itsv_alternate_units != null ? obj[0].itsv_alternate_units : -1);
                    $("#comboReportingUom").val(obj[0].itsv_reporting_uom != null ? obj[0].itsv_reporting_uom : -1);
                    $("#txtConversionValue").val(obj[0].itsv_conversion_value != null ? obj[0].itsv_conversion_value : 0);
                    $("#txtDenominator").val(obj[0].itsv_denominator != null ? obj[0].itsv_denominator : 1);
                    $("#comboBomEnabled").val(obj[0].itsv_bom_enabled == 1 ? "1" : "0");
                    $("#txtHsnSac").val(obj[0].itsv_hsn_sac != null ? obj[0].itsv_hsn_sac : '');
                    $("#comboSpecItem").val(obj[0].itsv_spec_item != null ? obj[0].itsv_spec_item : -1);
                    $("#comboSpecPitch").val(obj[0].itsv_spec_pitch != null ? obj[0].itsv_spec_pitch : -1);
                    $("#comboSpecCrust").val(obj[0].itsv_spec_crust != null ? obj[0].itsv_spec_crust : -1);
                    $("#comboSpecBrand").val(obj[0].itsv_spec_brand != null ? obj[0].itsv_spec_brand : -1);
                    $("#comboSpecThickness").val(obj[0].itsv_spec_thickness != null ? obj[0].itsv_spec_thickness : -1);
                    $("#comboSpecColour").val(obj[0].itsv_spec_colour != null ? obj[0].itsv_spec_colour : -1);
                    $("#comboSpecCoating").val(obj[0].itsv_spec_coating != null ? obj[0].itsv_spec_coating : -1);
                    $("#comboSpecYieldStrength").val(obj[0].itsv_spec_yield_strength != null ? obj[0].itsv_spec_yield_strength : -1);
                    $("#comboSpecWidth").val(obj[0].itsv_spec_width != null ? obj[0].itsv_spec_width : -1);
                    $("#comboSpecMachine").val(obj[0].itsv_spec_machine != null ? obj[0].itsv_spec_machine : -1);

                    if (obj[0].itm_type == 3) {
                        showDivCoupon();
                        $("#txtAutoitemName").val(obj[0].copnItem);
                        $("#txtitemqty").val(obj[0].quantity);
                        couponItemId = obj[0].couponItemId;
                    }
                    //loadsubcategory(obj[0].itm_subcategory_id);

                    $('html,body').animate({
                        scrollTop: $('#Divitemdetails').offset().top
                    }, 500);

                    return;
                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem");
                }
            });
        }


        //function for show brands
        function showsearchbrands() {
            loading();
            $.ajax({
                type: "POST",
                url: "itemmaster.aspx/showsearchbrands",
                data: "{}",
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
                        $("#combobranddiv").html(msg.d);
                        //if (group_id !== undefined) {
                        //    // alert("");
                        //    editGroupDetails(group_id);
                        //}
                        //  searchGroupClass(1);
                        return;
                    }
                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }

        //function for load search subcategory
        function loadsearchcategory() {
            // brandval = $("#combobranddiv").val();
            //  alert(brandVal);
            loading();
            $.ajax({
                type: "POST",
                url: "itemmaster.aspx/loadsearchcategory",
                data: "{}",
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
                        $("#combosearchcategory").html(msg.d);
                        //if (group_id !== undefined) {
                        //    // alert("");
                        //    editGroupDetails(group_id);
                        //}
                        //  searchGroupClass(1);
                        return;
                    }
                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }

        //function for load subcategory
        function loadsubcategory(val) {
            // alert(val);
            categoryVal = $("#combocategory").val();
            //  alert(brandVal);
            loading();
            $.ajax({
                type: "POST",
                url: "itemmaster.aspx/showSubCategoryTypes",
                data: "{'categoryVal':'" + categoryVal + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    //alert(msg.d);
                    if (msg.d == "") {
                        alert("Error..!");
                        return;
                    }
                    else {
                        $("#comboselectsubcategory").html(msg.d);
                        if (val == 0) {
                            val = -1;
                        }
                        $("#comboselectsubcategory").val(val);
                        //if (group_id !== undefined) {
                        //    // alert("");
                        //    editGroupDetails(group_id);
                        //}
                        //  searchGroupClass(1);
                        return;
                    }
                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }

        function addNewBrand() {
            window.open('../web_inventory/itembrand.aspx', '_blank');
        }
        function addNewCategory() {
            window.open('../web_inventory/itemcategory.aspx', '_blank');
        }
        function showDivCoupon() {
            if ($("#comboItemtype").val() == 3) {
                $("#divCoupon").show();
            } else {
                $("#divCoupon").hide();
            }
        }

        //normal items search
        function searchItems() {
            //  alert("");
            //   showsearchItems();
            for (var i = 1; i <= 2; i++) {
                $("#searchposContent" + i).val('');
            }
           // $("#combosearchitemtype").val(0);
            searchOrderitem(1);
        }

        function searchOrderitem(page) {
            var filters = {};
       
            if ($("#searchposContent2").val() !== undefined && $("#searchposContent2").val() != "") {
                filters.itemname = $("#searchposContent2").val();
            }

            //  alert(itemcode);
            if ($("#searchposContent1").val() !== undefined && $("#searchposContent1").val() != "") {
                filters.itemcode = $("#searchposContent1").val();
            }
           // filters.item_type = $("#comboItemtype").val();
            var perpage = $("#txtpospageno").val();
            console.log(JSON.stringify(filters));
            //    alert("{ 'page': " + page + ", 'searchResult1': '" + searchResult + "', 'perpage': '" + perpage + "', 'customertype': '" + customertype + "' }");
            // alert(searchResult);
            loading();

            $.ajax({
                type: "POST",
                url: "itemmaster.aspx/searchOrderitem",
                data: "{'page':" + page + ",'filters':" + JSON.stringify(filters) + ",'perpage':" + perpage + "}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    // alert(msg.d);
                    if (msg.d == "N") {
                        $("#lblItemTotalrecords").text(0);
                        $('#tablePos tbody').html('<td colspan="6" style="background:#ebebeb; padding:5px;font-weight:bold;"><div style="width:100%;text-align:center"><div style="display:inline-block">Nothing Found...</div></div></td>');
                        $("#paginatedivone").html("");
                        $("#popupItems").modal('show');
                        return;
                    }
                    else {
                        var obj = JSON.parse(msg.d);
                        console.log(obj.data);
                        $("#lblItemTotalrecords").text(obj.count);
                        var htm = "";
                        //   htm += "<tr class='overeffect' style='font-size:12px;'><td style='padding:5px; text-align:center; overflow:hidden; border-right:none;' colspan='7' class='nonheadtext'><div><span style='margin-left:0px;float:right;margin-top:4px;text-align:right;font-size:14px;color:#660000;'>Total Records: " + obj.count + "</span></div></td> </tr>";
                        $.each(obj.data, function (i, row) {
                            console.log(row);
                         
                            htm += "<tr ";
                            htm += " onclick=javascript:selectCouponItem('" + row.itm_name.replace(/\s/g, '&nbsp;') + "','" + row.itm_id + "'); style='cursor:pointer;'><td>" + getHighlightedValue(filters.itemcode, row.itm_code.toString()) + "</td><td>" + getHighlightedValue(filters.itemname, row.itm_name.toString()) + "</td>";
                         
                            //alert(htm);
                            // $('#tablepos > tbody > tr:gt(' + (i + 2) + ')').remove();
                        });
                        htm += '<tr>';
                        htm += '<td colspan="6">';
                        htm += '<div  id="paginatedivone" style="text-align: center;">';
                        htm += '</div>';
                        htm += '</td>';
                        htm += '</tr>';

                        //   alert(htm);
                        $('#tablePos tbody').html(htm);
                        $("#popupItems").modal('show');
                        $("#paginatedivone").html(paginate(obj.count, perpage, page, "searchOrderitem"));


                        return;
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

        //normal items search

        //popupclose
        function popupclose(divid) {
            $("#" + divid).modal('hide');
        }

        //autosearch for select an item for coupon 
        function SearchAutoItems() {
            $("#txtAutoitemName").keyup(function () {
                //alert("ch");
                if ($("#txtAutoitemName").val().trim() === "") {
                    $("#searchTitle").hide();
                }
            });

            $("#txtAutoitemName").autocomplete({
                source: function (request, response) {
                    $.ajax({
                        type: "POST",
                        contentType: "application/json; charset=utf-8",
                        url: "itemmaster.aspx/GetAutoCompleteItemData",
                        data: "{'variable':'" + $("#txtAutoitemName").val() + "'}",
                        dataType: "json",
                        success: function (data) {
                            //var objJson = jQuery.parseJSON(data.d);
                            //alert(objJson);                             
                            //response(objJson);

                            //var obj = [{ label: 'Avacado Supermarket', value: '2' }];
                            //alert(data.d);
                            var data1 = jQuery.parseJSON(data.d);
                            console.log(data1);
                            response(data1.slice(0, 20));
                        }
                    });
                },
                select: function (event, ui) {
                    //alert(123);
                    // Prevent value from being put in the input:
                    $("#txtAutoitemName").val(ui.item.label); //ui.item is your object from the array
                    selectCouponItem(ui.item.label, ui.item.id);
                    //console.log(ui.item.value);
                 //   searchCustomers(ui.item.id);
                    event.preventDefault();
                },
                minLength: 1

            });



        }
        //autosearch for select an item for coupon 

        function selectCouponItem(name, id) {
            $("#txtAutoitemName").val(name);
            couponItemId = id;
            popupclose('popupItems');
        }

    </script>
    <style>
        #errmsg
{
color: red;
}
    </style>
</head>
<body class="nav-md">
    <div class="container body">
        <div class="main_container">
            <div class="col-md-3 left_col">
                <div class="left_col scroll-view">
                    <div class="navbar nav_title" style="border: 0;">
                        <a href="#" class="site_title">
                            <!--<i class="fa fa-paw"></i> -->
                            <span>Invoice Me</span></a>
                    </div>

                    <div class="clearfix"></div>

                    <!-- menu profile quick info -->
                    <div class="profile clearfix">
                        <div class="profile_pic">
                            <%--<img src="../images/img.jpg" alt="..." class="img-circle profile_img">--%>
                        </div>
                        <div class="profile_info">
                            <%--<span>Welcome,</span>
                <h2>John Doe</h2>--%>
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
                        <a data-toggle="tooltip" data-placement="top" title="Logout" href="">
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
                            <div class="col-md-6 col-xs-5">
                            <label style="font-weight: bold; font-size: 16px;">Item Master</label>
                            </div>
                            <div class="col-md-6 col-xs-5"><div onclick="javascript:clearform();" class="btn btn-primary btn-xs pull-right" style=" margin-top:5px"><label style="color: #fff; margin-right: 5px; font-size: 14px;" class="fa fa-plus-square"></label>Create New Item</div></div>
                        </div>

                    </nav>
                </div>
            </div>
            <!-- /top navigation -->

            <!-- page content -->
            <div class="right_col" role="main">
                <div class="">
                    <%--<div class="page-title">
			
              <div class="title_left" style="width:100%;">
                <label style="font-size:18px; font-weight:normal;">Item Master</label>
              </div>

              
            </div>
                    --%>
                    <div class="clearfix"></div>
                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12" id="Divitemdetails">
                            <div class="x_panel">
                                <div class="x_title" style="margin-bottom: 0px;">
                                    <label>Basic Details </label>
                                    <ul class="nav navbar-right panel_toolbox">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                        </li>

                                        <%-- <li><a class="close-link"><i class="fa fa-close"></i></a>
                      </li>--%>
                                    </ul>
                                </div>
                                <div class="x_content">
                                    <br />
                                    <form id="demo-form2" data-parsley-validate class="form-horizontal form-label-left">
                                         <div class="form-group">
                                            <label class="control-label col-md-3 col-sm-3 col-xs-12" for="first-name">
                                                Item Type<span class="required">*</span>
                                            </label>
                                              <div class="col-md-6 col-sm-6 col-xs-12">
                                                <select class="form-control" id="comboItemtype" onchange="showDivCoupon()">
                                                    <option value="-1">--Type--</option>
                                                    <option value="1">Product</option>
                                                    <option value="2">Service</option>
                                                    <option value="3">Package</option>
                                                    
                                                </select>
                                            </div>
                                        </div>
                                        <div id="divCoupon" style="display:none;">
                                            <div class="form-group">
                                            <label class="control-label col-md-3 col-sm-3 col-xs-12" for="first-name">
                                                Choose Item<span class="required">*</span>
                                            </label>
                                                <div class="col-md-6 col-sm-6 col-xs-12">
                                                  <input type="text" id="txtAutoitemName" placeholder="Search Item" required="required" class="form-control col-md-7 col-xs-12">
                                            </div>

                                                <div class="col-md-2 col-sm-6 col-xs-4" onclick="javascript:searchItems();" style="padding-right:0px;">
                                                <div class="" style="font-size: 28px;" data-toggle="modal" title="Add Item">
                                                    <label class="fa fa-shopping-cart" style="color: #ff6a00; cursor: pointer;"></label>
                                                    <label class="fa fa-plus-circle" style="font-size: 20px; cursor: pointer; position: relative; margin-left: -12px;"></label>
                                                </div>

                                            </div>

                                        </div>
                                           <div class="form-group">
                                            <label class="control-label col-md-3 col-sm-3 col-xs-12" for="first-name">
                                                Redeem Count<span class="required">*</span>
                                            </label>
                                              <div class="col-md-6 col-sm-6 col-xs-12">
                                                <input type="text" id="txtitemqty" placeholder="Enter Count" required="required" class="form-control col-md-7 col-xs-12">
                                            </div>
                                        </div>

                                             <%-- pop up for show normal items --%>
                                            <div class="container">


                                                <div class="modal fade" id="popupItems" role="dialog">
                                                    <div class="modal-dialog modal-lg" style="">

                                                        <!-- Modal content-->
                                                        <div class="modal-content">
                                                            <div class="modal-header">
                                                                <button type="button" class="close" onclick="javascript:popupclose('popupItems');">&times;</button>
                                                                <div class="col-md-7 col-sm-6 col-xs-6">
                                                                    <h4 class="modal-title">Items<span class="badge" style="color: #fff; margin-left: 5px; background: #d00101; padding-left: 5px; padding-right: 5px;" id="lblItemTotalrecords">0</span></h4>
                                                                </div>
                                                                <div class="col-md-4 col-sm-4 col-xs-12">                                                 
                                                                   
                                                                    <div class="col-md-10 col-sm-12 col-xs-12">
                                                                        
                                                                        <div class="" onclick="javascript:searchItems();" style="float:right;">
                                                                            <button class="btn btn-primary mybtnstyl" type="reset">
                                                                                <li class="fa fa-refresh" style="margin-right: 5px;"></li>
                                                                                Reset
                                                                            </button>
                                                                        </div>
                                                                        <div class="" onclick="javascript:searchOrderitem(1);">
                                                                            <button type="button" class="btn btn-success mybtnstyl" style="float:right;">
                                                                                <li class="fa fa-search" style="margin-right: 5px;"></li>
                                                                                Search
                                                                            </button>
                                                                        </div>
                                                                        </div>
                                                                         <div class="col-md-2 col-sm-12 col-xs-3">
                                                                            <select id="txtpospageno" onchange="javascript:searchOrderitem(1);"  name="datatable-checkbox_length" aria-controls="datatable-checkbox" class=" input-sm">
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

                                                                    <table id="tablePos" class="table table-striped table-bordered" style="table-layout: auto;">
                                                                        <thead>
                                                                            <tr>
                                                                                <th>Code</th>
                                                                                <th>Name</th>
                                                                           

                                                                            </tr>


                                                                            <tr>
                                                                                <td>
                                                                                    <input type="text" class="form-control" id="searchposContent1" style="width: 80px; padding-right: 2px;" /></td>
                                                                                <td>
                                                                                    <input type="text" id="searchposContent2" class="form-control" /></td>
                                                                                

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

                                            <%-- pop up for show offer items --%>
                                        </div>
                                           
                                        <div class="row">
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12" for="txtitemcode">
                                                        Item Code<span class="required">*</span>
                                                    </label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <input type="text" id="txtitemcode" placeholder="Enter Item Code" required="required" class="form-control">
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12" for="txtPartNo">
                                                        Part No
                                                    </label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <input type="number" id="txtPartNo" placeholder="Enter Part No" class="form-control">
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="row">
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12" for="txtitemname">
                                                        Item Name<span class="required">*</span>
                                                    </label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <input type="text" id="txtitemname" placeholder="Enter Item Name" required="required" class="form-control">
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12" for="txtPrintingName">
                                                        Printing Name
                                                    </label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <input type="text" id="txtPrintingName" placeholder="Printing Name (as on invoice/bill)" class="form-control">
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="row">
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12" for="txtitemdescrptn">
                                                        Description
                                                    </label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <textarea id="txtitemdescrptn" class="form-control" rows="2" placeholder="Enter Description" style="resize: vertical;"></textarea>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12" for="Text_qty_per_carton">
                                                        Qty Per Carton<span class="required">*</span>
                                                    </label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <input type="number" id="Text_qty_per_carton" placeholder="Enter Qty/Carton" required="required" class="form-control" value="1" />
                                                        <span id="errmsg"></span>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                           <%-- hide brand cat,sub cat 
                                        <div class="row">
                                            <div class="col-md-4 col-sm-4 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">Brand<span class="required">*</span></label>
                                                    <div class="col-md-7 col-sm-7 col-xs-10" id="showBrandDiv">
                                                        <select class="form-control" id="comboBrandtype">
                                                            <option value="0">--Select Brand--</option>
                                                        </select>
                                                    </div>
                                                    <div class="col-md-1 col-sm-1 col-xs-2" style="font-size: 20px; padding-left: 0;" onclick="javascript:addNewBrand();" title="Add New Brand">
                                                        <label class="fa fa-plus-square" style="color: #ff6a00; cursor: pointer; margin-top: 5px;"></label>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="col-md-4 col-sm-4 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">Category<span class="required">*</span></label>
                                                    <div class="col-md-7 col-sm-7 col-xs-10" id="showcategorydiv">
                                                        <select class="form-control" id="combocategory" onchange="javascript:loadsubcategory(0);">
                                                            <option value="0">--Select Category--</option>
                                                        </select>
                                                    </div>
                                                    <div class="col-md-1 col-sm-1 col-xs-2" style="font-size: 20px; padding-left: 0;" onclick="javascript:addNewCategory();" title="Add New Category">
                                                        <label class="fa fa-plus-square" style="color: #ff6a00; cursor: pointer; margin-top: 5px;"></label>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="col-md-4 col-sm-4 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">Sub Category</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <select class="form-control" id="comboselectsubcategory">
                                                            <option value="-1">--Subcategory--</option>
                                                        </select>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>--%>

                                        <!-- Section 1: Inventory & Units Configuration (Tally / ERP) -->
                                        <div class="col-md-12 col-sm-12 col-xs-12" style="margin-top: 15px; margin-bottom: 12px; padding: 0;">
                                            <div style="background: #f7f9fa; border-left: 4px solid #1ABB9C; padding: 8px 12px; border-radius: 2px;">
                                                <label style="font-size: 14px; font-weight: bold; color: #2A3F54; margin: 0;">
                                                    <i class="fa fa-cubes" style="color: #1ABB9C; margin-right: 6px;"></i>Inventory & Units Configuration (Tally / ERP)
                                                </label>
                                                <div class="pull-right">
                                                    <a href="itemmasterspec.aspx" target="_blank" class="btn btn-default btn-xs" style="margin-right: 5px;">
                                                        <i class="fa fa-external-link"></i> Manage Spec Values
                                                    </a>
                                                    <button type="button" class="btn btn-info btn-xs" onclick="loadSpecDropdowns();" title="Refresh Specifications">
                                                        <i class="fa fa-refresh"></i> Refresh Specs
                                                    </button>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="row">
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">Stock Group</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <select class="form-control" id="comboStockGroup">
                                                            <option value="-1">--Select Stock Group--</option>
                                                        </select>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">Stock Category</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <select class="form-control" id="comboStockCategory">
                                                            <option value="-1">--Select Stock Category--</option>
                                                        </select>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="row">
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">Purchase UOM</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <select class="form-control" id="comboUomPurchase">
                                                            <option value="-1">--Select Purchase UOM--</option>
                                                        </select>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">Sales UOM</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <select class="form-control" id="comboUomSales">
                                                            <option value="-1">--Select Sales UOM--</option>
                                                        </select>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="row">
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">Alternate Units</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <select class="form-control" id="comboAlternateUnits">
                                                            <option value="-1">--Select Alternate Unit--</option>
                                                        </select>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">Reporting UOM</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <select class="form-control" id="comboReportingUom">
                                                            <option value="-1">--Select Reporting UOM--</option>
                                                        </select>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="row">
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">Conversion Value</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <input type="number" id="txtConversionValue" class="form-control" placeholder="Conversion Value" value="0">
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">Denominator</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <input type="number" id="txtDenominator" class="form-control" placeholder="Denominator" value="1">
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="row">
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">BOM Enabled</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <select class="form-control" id="comboBomEnabled">
                                                            <option value="0">No</option>
                                                            <option value="1">Yes</option>
                                                        </select>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">HSN / SAC</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <input type="text" id="txtHsnSac" class="form-control" placeholder="Enter HSN/SAC Code">
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="row">
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">Spec Description ID</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <input type="number" id="txtItsvDescription" class="form-control" placeholder="Spec Description ID / Code">
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <!-- Section 2: Item Technical Specifications -->
                                        <div class="col-md-12 col-sm-12 col-xs-12" style="margin-top: 15px; margin-bottom: 12px; padding: 0;">
                                            <div style="background: #f7f9fa; border-left: 4px solid #3498DB; padding: 8px 12px; border-radius: 2px;">
                                                <label style="font-size: 14px; font-weight: bold; color: #2A3F54; margin: 0;">
                                                    <i class="fa fa-sliders" style="color: #3498DB; margin-right: 6px;"></i>Item Technical Specifications
                                                </label>
                                            </div>
                                        </div>

                                        <div class="row">
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">Spec Item</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <select class="form-control" id="comboSpecItem">
                                                            <option value="-1">--Select Spec Item--</option>
                                                        </select>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">Spec Brand</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <select class="form-control" id="comboSpecBrand">
                                                            <option value="-1">--Select Spec Brand--</option>
                                                        </select>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="row">
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">Thickness</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <select class="form-control" id="comboSpecThickness">
                                                            <option value="-1">--Select Thickness--</option>
                                                        </select>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">Colour</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <select class="form-control" id="comboSpecColour">
                                                            <option value="-1">--Select Colour--</option>
                                                        </select>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="row">
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">Coating</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <select class="form-control" id="comboSpecCoating">
                                                            <option value="-1">--Select Coating--</option>
                                                        </select>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">Yield Strength</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <select class="form-control" id="comboSpecYieldStrength">
                                                            <option value="-1">--Select Yield Strength--</option>
                                                        </select>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="row">
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">Pitch</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <select class="form-control" id="comboSpecPitch">
                                                            <option value="-1">--Select Pitch--</option>
                                                        </select>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">Crust</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <select class="form-control" id="comboSpecCrust">
                                                            <option value="-1">--Select Crust--</option>
                                                        </select>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="row">
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">Width</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <select class="form-control" id="comboSpecWidth">
                                                            <option value="-1">--Select Width--</option>
                                                        </select>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12">Machine</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <select class="form-control" id="comboSpecMachine">
                                                            <option value="-1">--Select Machine--</option>
                                                        </select>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                    </form>

                                    <div class="clearfix"></div>
                                    <div class="ln_solid"></div>
                                    <div class="form-group" style="padding-bottom: 40px;">
                                        <div class="col-md-6 col-sm-6 col-xs-12 col-md-offset-5">
                                            
                                            <div id="btnservMasterAction">
                                                <div class="btn btn-success mybtnstyl" onclick="javascript:addItemDetails('insert',0);">SAVE</div>
                                            </div>

                                            <div onclick="javascript:clearform();" class="btn btn-danger mybtnstyl">CANCEL</div>
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
                                <div class="x_title" style="margin-bottom: 5px;">
                                    <label>Items<span class="badge" style="color: #fff; margin-left: 5px; background: #d00101; padding-left: 5px; padding-right: 5px;" id="lblTotalrerd">0</span></label>
                                    <ul class="nav navbar-right panel_toolbox">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                        </li>

                                        <%--                      <li><a class="close-link"><i class="fa fa-close"></i></a>
                      </li>--%>
                                    </ul>
                                </div>

                                <div class="x_content" style="padding-bottom: 0px;">

                                    <form class="form-horizontal form-label-left input_mask" onsubmit="return false;">

                                        <div class="col-md-12 col-sm-12 col-xs-12 form-group" style="padding-left:0; padding-right:0; margin-bottom: 5px;">
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback" style="margin-bottom: 5px;">
                                                <select class="form-control" style="text-indent: 25px;" id="combosearchSpecItem" onchange="javascript:searchitemlist(1);">
                                                    <option value="-1">--Item Technical Specification--</option>
                                                </select>
                                                <span class="fa fa-sliders form-control-feedback left" aria-hidden="true" style="color:#3498DB;"></span>
                                            </div>

                                            <div class="col-md-2 col-sm-6 col-xs-12 form-group has-feedback" style="margin-bottom: 5px;">
                                                <input type="text" class="form-control" style="text-indent: 25px;" id="txtSearchPartNo" placeholder="Part No" onkeypress="if(event.which==13){searchitemlist(1);return false;}">
                                                <span class="fa fa-hashtag form-control-feedback left" aria-hidden="true"></span>
                                            </div>

                                            <div class="col-md-3 col-sm-6 col-xs-12" style="padding-right:0px; margin-bottom: 5px;">
                                                <div class="input-group">
                                                    <input type="text" class="form-control" id="txtSearchItem" placeholder="Item Name / Printing Name / Code" style="height: 30px; padding-right: 2px;" onkeypress="if(event.which==13){searchitemlist(1);return false;}">
                                                    <span class="input-group-btn" title="Search">
                                                        <button type="button" class="btn btn-default" onclick="searchitemlist(1)" style="padding:4px 12px;">
                                                            <i class="fa fa-search" title="Search"></i>
                                                        </button>
                                                    </span>
                                                </div>                                      
                                            </div>

                                            <div class="col-md-1 col-sm-2 col-xs-3" style="padding-left:8px; padding-right:2px; width:auto;" onclick="resetitem()">
                                                <a class="btn btn-primary btn-xs" style="text-align:center;background:#337ab7; border-color:#2e6da4; height:30px; padding: 5px 10px;" title="Reset Filters">
                                                    <li class="fa fa-refresh" style="font-size:16px;color:white;"></li>
                                                </a>
                                            </div>

                                            <div class="col-md-1 col-sm-2 col-xs-4" style="padding-left:2px; padding-right:2px; width:auto;">
                                                <button type="button" id="btnToggleMoreSpecs" class="btn btn-default btn-xs" onclick="toggleMoreSpecs();" style="padding: 4px 8px; height: 30px; font-size: 11px;" title="More Technical Specification Filters">
                                                    <i class="fa fa-filter" style="color:#3498DB;"></i> Specs <span class="caret"></span>
                                                </button>
                                            </div>

                                            <div class="col-md-2 col-sm-3 col-xs-5" style="padding-left:4px; padding-right:4px; width:auto;">
                                                <button type="button" id="btnDownloadExcel" class="btn btn-success btn-xs" onclick="downloadItemMasterExcel();" style="padding: 5px 12px; height: 30px; font-size: 11px; background-color: #26b99a; border-color: #26b99a; font-weight: bold;" title="Download all items details (all columns) in Excel sheet">
                                                    <i class="fa fa-file-excel-o" style="margin-right: 4px;"></i> Download Excel
                                                </button>
                                            </div>

                                            <ul class="nav navbar-right panel_toolbox" style="min-width:auto; margin-top:2px;">
                                                <li>
                                                    <select class="input-sm" id="txtpageno" onchange="javascript:searchitemlist(1);">
                                                        <option value="25">25</option>
                                                        <option value="50">50</option>
                                                        <option value="100">100</option>
                                                        <option value="500">500</option>
                                                    </select>
                                                </li>
                                            </ul>
                                        </div>

                                        <!-- Collapsible Additional Technical Specification Filters -->
                                        <div id="divMoreSpecFilters" class="col-md-12 col-sm-12 col-xs-12" style="display:none; margin-bottom: 10px; padding: 10px 15px 5px; background: #fcfcfc; border: 1px solid #e6e9ed; border-radius: 4px;">
                                            <div class="row">
                                                <div class="col-md-2 col-sm-4 col-xs-12 form-group">
                                                    <label style="font-size: 11px; margin-bottom: 2px; color: #73879C;">UOM</label>
                                                    <select class="form-control input-sm" id="combosearchUom" onchange="javascript:searchitemlist(1);">
                                                        <option value="-1">--UOM--</option>
                                                    </select>
                                                </div>
                                                <div class="col-md-2 col-sm-4 col-xs-12 form-group">
                                                    <label style="font-size: 11px; margin-bottom: 2px; color: #73879C;">Spec Brand</label>
                                                    <select class="form-control input-sm" id="combosearchSpecBrand" onchange="javascript:searchitemlist(1);">
                                                        <option value="-1">--Spec Brand--</option>
                                                    </select>
                                                </div>
                                                <div class="col-md-2 col-sm-4 col-xs-12 form-group">
                                                    <label style="font-size: 11px; margin-bottom: 2px; color: #73879C;">Spec Thickness</label>
                                                    <select class="form-control input-sm" id="combosearchSpecThickness" onchange="javascript:searchitemlist(1);">
                                                        <option value="-1">--Thickness--</option>
                                                    </select>
                                                </div>
                                                <div class="col-md-3 col-sm-6 col-xs-12 form-group">
                                                    <label style="font-size: 11px; margin-bottom: 2px; color: #73879C;">Spec Colour</label>
                                                    <select class="form-control input-sm" id="combosearchSpecColour" onchange="javascript:searchitemlist(1);">
                                                        <option value="-1">--Colour--</option>
                                                    </select>
                                                </div>
                                                <div class="col-md-3 col-sm-6 col-xs-12 form-group">
                                                    <label style="font-size: 11px; margin-bottom: 2px; color: #73879C;">Spec Machine</label>
                                                    <select class="form-control input-sm" id="combosearchSpecMachine" onchange="javascript:searchitemlist(1);">
                                                        <option value="-1">--Machine--</option>
                                                    </select>
                                                </div>
                                            </div>
                                        </div>
                                    </form>

                                </div>

                                <div class="clearfix"></div>
                                <div class="ln_solid" style="margin-top: 0px;"></div>

                                <div id="divSearchItems" class="col-md-12 col-sm-12 col-xs-12" style="overflow-x: auto;">
                                    <div class="x_content">

                                        <table id="divSearchItems1" class="table table-striped jambo_table bulk_action" style="table-layout: auto;">
                                            <thead style="background-color:#f1eeee;color:#525252">
                                                <tr>
                                                    <th>Item Code</th>
                                                    <th>Part No</th>
                                                    <th>Item Name / Printing Name</th>
                                                    <th>Stock Group</th>
                                                    <th>HSN / SAC</th>
                                                    <th style="text-align:center;">Qty / Carton</th>
                                                    <th style="text-align:center;">Action</th>
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
                    <div class="clearfix"></div>


                </div>
            </div>
            <!-- /page content -->

            <!-- footer content -->
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

    <!-- jQuery -->
    <%--    <script src="../js/bootstrap/jquery.min.js"></script>--%>
    <!-- Bootstrap -->
    <script src="../js/bootstrap/bootstrap.min.js"></script>
    <!-- NProgress -->
    <script src="../js/bootstrap/nprogress.js"></script>
    <!-- Custom Theme Scripts -->
    <script src="../js/bootstrap/custom.min.js"></script>
    <script src="../js/bootbox.min.js"></script>
</body>
</html>
