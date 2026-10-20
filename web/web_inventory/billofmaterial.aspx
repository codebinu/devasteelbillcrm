<%@ Page Language="C#" AutoEventWireup="true" CodeFile="billofmaterial.aspx.cs" Inherits="web_inventory_billofmaterial" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Bill of Material | Invoice Me</title>

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

    <style type="text/css">
        .mybtnstyl {
            padding: 5px 14px;
            font-size: 12px;
            font-weight: bold;
            cursor: pointer;
            border-radius: 3px;
        }
        .comp-table th {
            background-color: #f7f9fa;
            color: #555;
            font-size: 12px;
            font-weight: bold;
            padding: 8px 10px;
            border: 1px solid #e6e9ed;
        }
        .comp-table td {
            vertical-align: middle !important;
            padding: 6px 8px !important;
            border: 1px solid #e6e9ed;
        }
        .ui-autocomplete {
            max-height: 250px;
            overflow-y: auto;
            overflow-x: hidden;
            z-index: 9999 !important;
            font-size: 12px;
        }
        .item-info-badge {
            background: #f8fafc;
            border: 1px solid #dbeafe;
            border-left: 4px solid #3b82f6;
            padding: 8px 12px;
            border-radius: 4px;
            margin-top: 6px;
        }
        .tag-pill {
            display: inline-block;
            background: #eef2f7;
            color: #334155;
            padding: 2px 7px;
            border-radius: 12px;
            font-size: 11px;
            margin: 2px 3px 2px 0;
            border: 1px solid #cbd5e1;
        }
    </style>

    <script type="text/javascript">
        var uomOptionsHtml = "<option value='-1'>--Select UOM--</option>";
        var currentOutputId = 0;
        var currentAction = "insert";
        var componentRowIndex = 0;

        $(document).ready(function () {
            loadMenu();
            clearform();
            loadUomDropdownOptions();
            setupOutputItemAutocomplete();
            searchBomList(1);

            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " © ");

            $("#txtSearchOutput, #txtSearchComponent").keypress(function (e) {
                if (e.which == 13) {
                    searchBomList(1);
                    return false;
                }
            });
        });

        // Start: Replace single quotes with double quotes
        function sqlInjection() {
            $('input, select, textarea').each(function () {
                var input = $(this);
                var type = this.type ? this.type : this.nodeName.toLowerCase();
                if (type == "text" || type == "textarea") {
                    $("#" + input.attr('id')).val(input.val().replace(/'/g, '"'));
                }
            });
        }

        // Load UOM options from tbl_item_uom
        function loadUomDropdownOptions() {
            $.ajax({
                type: "POST",
                url: "billofmaterial.aspx/loadUomOptions",
                data: "{}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    if (msg.d) {
                        uomOptionsHtml = msg.d;
                        $("#combosearchUom").html(uomOptionsHtml);
                        $("#combosearchUom option:first").text("--All UOM--");
                    }
                }
            });
        }

        // Setup Autocomplete for Output Item
        function setupOutputItemAutocomplete() {
            $("#txtOutputItemSearch").autocomplete({
                source: function (request, response) {
                    $.ajax({
                        type: "POST",
                        contentType: "application/json; charset=utf-8",
                        url: "billofmaterial.aspx/searchItemsAutocomplete",
                        data: JSON.stringify({ term: request.term }),
                        dataType: "json",
                        success: function (data) {
                            if (!data.d) { response([]); return; }
                            var items = JSON.parse(data.d);
                            response(items);
                        }
                    });
                },
                select: function (event, ui) {
                    selectOutputItem(ui.item);
                    return false;
                },
                minLength: 1
            });
        }

        // Set selected Output Item
        function selectOutputItem(item) {
            currentOutputId = item.id;
            $("#hdnOutputItemId").val(item.id);
            $("#txtOutputItemSearch").val(item.code + " - " + item.name);
            $("#lblOutputCode").text(item.code || '-');
            $("#lblOutputName").text(item.name || '-');
            $("#lblOutputPrintingName").text(item.printingName || item.name || '-');
            $("#lblOutputUom").text(item.uomName || '-');
            $("#divOutputItemInfo").slideDown(200);

            // Add first empty component row if none exists
            if ($("#tblBomComponents tbody tr").length === 0) {
                addNewComponentRow();
            }
        }

        // Add a new component row in the BOM recipe table
        function addNewComponentRow(compData) {
            componentRowIndex++;
            var idx = componentRowIndex;
            var itmId = compData ? compData.itm_id_input : 0;
            var itmText = compData ? (compData.input_code + " - " + compData.input_name) : "";
            var qty = compData ? parseFloat(compData.itmbi_qty) : 1;
            var uomId = compData ? compData.tum_id : 1;
            var typeVal = compData ? compData.itmbi_type : 1;

            var tr = "<tr id='compRow_" + idx + "'>" +
                "<td style='text-align:center; font-weight:bold;' class='comp-sno'></td>" +
                "<td>" +
                    "<input type='hidden' id='hdnCompItemId_" + idx + "' value='" + itmId + "' />" +
                    "<div class='input-group' style='margin-bottom: 2px;'>" +
                        "<input type='text' id='txtCompItemSearch_" + idx + "' class='form-control input-sm comp-item-input' placeholder='Type Item Code or Name...' value='" + itmText.replace(/'/g, "&#39;") + "' style='font-size:12px;' />" +
                        "<span class='input-group-btn'>" +
                            "<button type='button' class='btn btn-primary btn-sm' onclick='openItemMasterSearchModalForComponent(" + idx + ");' title='Search Component from Item Master with Specifications' style='padding: 4px 10px; height: 30px;'>" +
                                "<i class='fa fa-search'></i>" +
                            "</button>" +
                        "</span>" +
                    "</div>" +
                    "<div id='lblCompDetail_" + idx + "' style='font-size:11px; color:#555; margin-top:2px; display:" + (itmId > 0 ? "block" : "none") + ";'>" +
                        "<i class='fa fa-check-circle' style='color:#16a34a;'></i> <span id='spanCompName_" + idx + "'>" + itmText.replace(/'/g, "&#39;") + "</span>" +
                    "</div>" +
                "</td>" +
                "<td style='width: 140px;'>" +
                    "<select id='comboCompType_" + idx + "' class='form-control input-sm' style='font-size:12px;'>" +
                        "<option value='1' " + (typeVal == 1 ? "selected" : "") + ">Component / Raw Material</option>" +
                    "</select>" +
                "</td>" +
                "<td style='width: 150px;'>" +
                    "<select id='comboCompUom_" + idx + "' class='form-control input-sm' style='font-size:12px;'>" +
                        uomOptionsHtml +
                    "</select>" +
                "</td>" +
                "<td style='width: 140px;'>" +
                    "<input type='number' step='any' min='0.000001' id='txtCompQty_" + idx + "' class='form-control input-sm text-right' placeholder='Qty' value='" + qty + "' style='font-size:12px; font-weight:bold;' />" +
                "</td>" +
                "<td style='text-align:center; width: 60px;'>" +
                    "<button type='button' class='btn btn-danger btn-xs' onclick='removeComponentRow(" + idx + ");' title='Remove Component'>" +
                        "<i class='fa fa-trash'></i>" +
                    "</button>" +
                "</td>" +
            "</tr>";

            $("#tblBomComponents tbody").append(tr);
            if (uomId > 0) {
                $("#comboCompUom_" + idx).val(uomId);
            }

            // Setup autocomplete on this component row input
            setupComponentAutocomplete(idx);
            recalculateSNo();
        }

        // Setup Autocomplete for a component row
        function setupComponentAutocomplete(idx) {
            $("#txtCompItemSearch_" + idx).autocomplete({
                source: function (request, response) {
                    $.ajax({
                        type: "POST",
                        contentType: "application/json; charset=utf-8",
                        url: "billofmaterial.aspx/searchItemsAutocomplete",
                        data: JSON.stringify({ term: request.term }),
                        dataType: "json",
                        success: function (data) {
                            if (!data.d) { response([]); return; }
                            var items = JSON.parse(data.d);
                            response(items);
                        }
                    });
                },
                select: function (event, ui) {
                    $("#hdnCompItemId_" + idx).val(ui.item.id);
                    $("#txtCompItemSearch_" + idx).val(ui.item.label);
                    $("#spanCompName_" + idx).text(ui.item.code + " - " + ui.item.name);
                    $("#lblCompDetail_" + idx).show();
                    if (ui.item.uomId && ui.item.uomId > 0) {
                        $("#comboCompUom_" + idx).val(ui.item.uomId);
                    }
                    return false;
                },
                minLength: 1
            });
        }

        // Remove component row
        function removeComponentRow(idx) {
            $("#compRow_" + idx).remove();
            recalculateSNo();
        }

        // Recalculate Serial Numbers
        function recalculateSNo() {
            $("#tblBomComponents tbody tr").each(function (i) {
                $(this).find(".comp-sno").text(i + 1);
            });
        }

        // Clear Form
        function clearform() {
            currentOutputId = 0;
            currentAction = "insert";
            $("#hdnOutputItemId").val(0);
            $("#txtOutputItemSearch").val('');
            $("#lblOutputCode").text('-');
            $("#lblOutputName").text('-');
            $("#lblOutputPrintingName").text('-');
            $("#lblOutputUom").text('-');
            $("#divOutputItemInfo").hide();
            $("#tblBomComponents tbody").html('');
            $("#btnBomAction").html("<div class='btn btn-success fl mybtnstyl' onclick='javascript:saveBomDetails();'><i class='fa fa-save'></i> SAVE BOM</div>");
        }

        // Save or Update BOM Details
        function saveBomDetails() {
            sqlInjection();
            var outputId = parseInt($("#hdnOutputItemId").val());
            if (isNaN(outputId) || outputId <= 0) {
                alert("Please search and select a Finished Good / Output Item!");
                $("#txtOutputItemSearch").focus();
                return;
            }

            var components = [];
            var hasError = false;
            var errorMsg = "";

            $("#tblBomComponents tbody tr").each(function (index) {
                var rowId = $(this).attr("id").replace("compRow_", "");
                var inId = parseInt($("#hdnCompItemId_" + rowId).val());
                var inName = $("#txtCompItemSearch_" + rowId).val().trim();
                var qtyVal = $("#txtCompQty_" + rowId).val();
                var qty = parseFloat(qtyVal);
                var uomId = parseInt($("#comboCompUom_" + rowId).val());
                var typeVal = parseInt($("#comboCompType_" + rowId).val());

                if (isNaN(inId) || inId <= 0 || inName === "") {
                    hasError = true;
                    errorMsg = "Row " + (index + 1) + ": Please select a valid Component item from search.";
                    $("#txtCompItemSearch_" + rowId).focus();
                    return false;
                }
                if (inId === outputId) {
                    hasError = true;
                    errorMsg = "Row " + (index + 1) + ": A component item cannot be the same as the Output item!";
                    return false;
                }
                if (isNaN(qty) || qty <= 0) {
                    hasError = true;
                    errorMsg = "Row " + (index + 1) + ": Quantity must be greater than zero.";
                    $("#txtCompQty_" + rowId).focus();
                    return false;
                }

                components.push({
                    itm_id_input: inId,
                    itmbi_serialno: index + 1,
                    itmbi_type: isNaN(typeVal) ? 1 : typeVal,
                    tum_id: isNaN(uomId) || uomId <= 0 ? 1 : uomId,
                    itmbi_qty: qty
                });
            });

            if (hasError) {
                alert(errorMsg);
                return;
            }

            if (components.length === 0) {
                alert("Please add at least one Component / Raw Material to the BOM!");
                return;
            }

            loading();
            $.ajax({
                type: "POST",
                url: "billofmaterial.aspx/saveBomDetails",
                data: JSON.stringify({
                    actionType: currentAction,
                    outputItemId: outputId,
                    componentsJson: JSON.stringify(components)
                }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d === "E_EXISTS") {
                        alert("A Bill of Material already exists for this Output Item! Please click Edit from the list below to update it.");
                        return;
                    }
                    if (msg.d === "Y") {
                        alert(currentAction === "insert" ? "Bill of Material Saved Successfully!" : "Bill of Material Updated Successfully!");
                        clearform();
                        searchBomList(1);
                        return;
                    }
                    alert(msg.d);
                },
                error: function () {
                    Unloading();
                    alert("Internet Problem.. Please try again.");
                }
            });
        }

        // Search BOM List
        function searchBomList(page) {
            sqlInjection();
            var filters = {};
            var outItem = $("#txtSearchOutput").val();
            if (outItem !== undefined && outItem.trim() !== "") {
                filters.outputItem = outItem.trim();
            }

            var compItem = $("#txtSearchComponent").val();
            if (compItem !== undefined && compItem.trim() !== "") {
                filters.componentItem = compItem.trim();
            }

            var uom = $("#combosearchUom").val();
            if (uom !== undefined && uom !== "-1" && uom !== "") {
                filters.uom = uom;
            }

            var perpage = $("#txtpageno").val() || 25;
            loading();
            $.ajax({
                type: "POST",
                url: "billofmaterial.aspx/searchBomList",
                data: JSON.stringify({ page: page, filters: filters, perpage: parseInt(perpage) }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d === "N" || !msg.d) {
                        $("#tableBomList tbody").html('<tr><td colspan="5" style="padding:25px; text-align:center; font-weight:bold; color:#73879C;"><i class="fa fa-info-circle"></i> No Bill of Material records found.</td></tr>');
                        $("#paginatediv").html('');
                        $("#lblTotalRecords").text(0);
                    } else {
                        var res = JSON.parse(msg.d);
                        $("#lblTotalRecords").text(res.count);
                        var htm = "";
                        var startSno = (page - 1) * perpage;

                        $.each(res.data, function (i, row) {
                            var components = (row.components_summary || '').split(' || ');
                            var tagsHtml = "";
                            for (var c = 0; c < components.length; c++) {
                                if (components[c].trim() !== "") {
                                    tagsHtml += "<span class='tag-pill'><i class='fa fa-cube'></i> " + components[c].trim() + "</span>";
                                }
                            }

                            htm += "<tr style='font-size:12px;'>";
                            htm += "<td style='text-align:center; font-weight:bold; vertical-align:middle;'>" + (startSno + i + 1) + "</td>";
                            htm += "<td style='vertical-align:middle;'><b>" + (row.output_code || '-') + "</b></td>";
                            htm += "<td style='vertical-align:middle;'>" +
                                   "<b>" + row.output_name + "</b>" +
                                   (row.output_printing_name && row.output_printing_name != row.output_name ? "<br/><small style='color:#73879C;'>Print: " + row.output_printing_name + "</small>" : "") +
                                   "</td>";
                            htm += "<td style='vertical-align:middle;'>" + tagsHtml + "</td>";
                            htm += "<td style='text-align:center; vertical-align:middle; white-space:nowrap;'>" +
                                   "<button type='button' class='btn btn-info btn-xs' onclick='viewBomDetails(" + row.itm_id_output + ");' title='View Components' style='margin-right:4px;'><i class='fa fa-eye'></i></button>" +
                                   "<button type='button' class='btn btn-primary btn-xs' onclick='editBomDetails(" + row.itm_id_output + ");' title='Edit BOM' style='margin-right:4px;'><i class='fa fa-pencil'></i></button>" +
                                   "<button type='button' class='btn btn-danger btn-xs' onclick='deleteBomConfirm(" + row.itm_id_output + ");' title='Delete BOM'><i class='fa fa-trash'></i></button>" +
                                   "</td>";
                            htm += "</tr>";
                        });

                        $("#tableBomList tbody").html(htm);
                        $("#paginatediv").html(paginate(res.count, perpage, page, "searchBomList"));
                    }
                },
                error: function () {
                    Unloading();
                    alert("Internet Problem.. Please try again.");
                }
            });
        }

        // Reset Search Filters
        function resetSearch() {
            $("#txtSearchOutput").val('');
            $("#txtSearchComponent").val('');
            $("#combosearchUom").val(-1);
            searchBomList(1);
        }

        // Edit BOM Details: loads into form
        function editBomDetails(outputId) {
            loading();
            $.ajax({
                type: "POST",
                url: "billofmaterial.aspx/getBomDetails",
                data: JSON.stringify({ outputItemId: outputId }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (!msg.d) return;
                    var res = JSON.parse(msg.d);
                    if (!res.output || res.output.length === 0) {
                        alert("Error loading Output Item details!");
                        return;
                    }

                    clearform();
                    currentAction = "update";
                    var out = res.output[0];
                    currentOutputId = out.itm_id;
                    $("#hdnOutputItemId").val(out.itm_id);
                    $("#txtOutputItemSearch").val(out.itm_code + " - " + out.itm_name);
                    $("#lblOutputCode").text(out.itm_code || '-');
                    $("#lblOutputName").text(out.itm_name || '-');
                    $("#lblOutputPrintingName").text(out.itsv_printing_name || out.itm_name || '-');
                    $("#lblOutputUom").text(out.uom_name || '-');
                    $("#divOutputItemInfo").show();

                    $("#btnBomAction").html("<div class='btn btn-success fl mybtnstyl' onclick='javascript:saveBomDetails();'><i class='fa fa-refresh'></i> UPDATE BOM</div>");

                    if (res.components && res.components.length > 0) {
                        for (var i = 0; i < res.components.length; i++) {
                            addNewComponentRow(res.components[i]);
                        }
                    } else {
                        addNewComponentRow();
                    }

                    $('html,body').animate({
                        scrollTop: $('#DivBomDetails').offset().top - 20
                    }, 400);
                },
                error: function () {
                    Unloading();
                    alert("Error loading BOM details!");
                }
            });
        }

        // View BOM Details Modal
        function viewBomDetails(outputId) {
            loading();
            $.ajax({
                type: "POST",
                url: "billofmaterial.aspx/getBomDetails",
                data: JSON.stringify({ outputItemId: outputId }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (!msg.d) return;
                    var res = JSON.parse(msg.d);
                    if (!res.output || res.output.length === 0) return;

                    var out = res.output[0];
                    $("#modalOutputTitle").text(out.itm_code + " - " + out.itm_name);
                    $("#modalOutputCode").text(out.itm_code);
                    $("#modalOutputName").text(out.itm_name);
                    $("#modalOutputPrinting").text(out.itsv_printing_name || out.itm_name);
                    $("#modalOutputUom").text(out.uom_name || '-');

                    var trs = "";
                    if (res.components && res.components.length > 0) {
                        for (var i = 0; i < res.components.length; i++) {
                            var c = res.components[i];
                            trs += "<tr>" +
                                "<td style='text-align:center; font-weight:bold;'>" + (i + 1) + "</td>" +
                                "<td><b>" + (c.input_code || '-') + "</b></td>" +
                                "<td>" + c.input_name + (c.input_printing_name && c.input_printing_name != c.input_name ? "<br/><small style='color:#73879C;'>Print: " + c.input_printing_name + "</small>" : "") + "</td>" +
                                "<td style='text-align:right; font-weight:bold;'>" + parseFloat(c.itmbi_qty).toFixed(4) + "</td>" +
                                "<td style='text-align:center;'><span class='label label-default' style='font-size:11px;'>" + (c.uom_name || '-') + "</span></td>" +
                            "</tr>";
                        }
                    } else {
                        trs = "<tr><td colspan='5' style='text-align:center;'>No components found.</td></tr>";
                    }
                    $("#tableModalComponents tbody").html(trs);
                    $("#modalBomView").modal('show');
                },
                error: function () {
                    Unloading();
                    alert("Error viewing BOM details!");
                }
            });
        }

        // Delete BOM with Confirmation
        function deleteBomConfirm(outputId) {
            if (!confirm("Are you sure you want to delete this Bill of Material? All components will be removed.")) {
                return;
            }
            loading();
            $.ajax({
                type: "POST",
                url: "billofmaterial.aspx/deleteBom",
                data: JSON.stringify({ outputItemId: outputId }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d === "Y") {
                        alert("Bill of Material deleted successfully!");
                        if (currentOutputId === outputId) {
                            clearform();
                        }
                        searchBomList(1);
                    } else {
                        alert("Error deleting BOM: " + msg.d);
                    }
                },
                error: function () {
                    Unloading();
                    alert("Error deleting BOM!");
                }
            });
        }

        // Download BOM Excel
        function downloadBomExcel() {
            sqlInjection();
            var filters = {};
            var outItem = $("#txtSearchOutput").val();
            if (outItem !== undefined && outItem.trim() !== "") {
                filters.outputItem = outItem.trim();
            }

            var compItem = $("#txtSearchComponent").val();
            if (compItem !== undefined && compItem.trim() !== "") {
                filters.componentItem = compItem.trim();
            }

            var uom = $("#combosearchUom").val();
            if (uom !== undefined && uom !== "-1" && uom !== "") {
                filters.uom = uom;
            }

            loading();
            $.ajax({
                type: "POST",
                url: "billofmaterial.aspx/prepareBomExport",
                data: JSON.stringify({ filters: filters }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d === "N" || msg.d === "0") {
                        alert("No Bill of Material records found to download!");
                    } else if (msg.d === "Y") {
                        location.href = "downloadBom.aspx";
                    } else {
                        alert("Error preparing export: " + msg.d);
                    }
                },
                error: function () {
                    Unloading();
                    alert("Internet Problem.. Please try again.");
                }
            });
        }

        // ==========================================
        // ITEM MASTER MODAL SEARCH WITH SPECIFICATIONS
        // ==========================================
        var modalSpecFiltersLoaded = false;
        var modalItemsCache = [];
        var modalTarget = "output"; // "output" or component row idx (number)

        function openItemMasterSearchModal() {
            modalTarget = "output";
            $("#modalItemSearchTitleText").text("Item Master Search (Select Output Item by Specifications)");
            var initialSearch = $("#txtOutputItemSearch").val() || "";
            if (initialSearch.indexOf(" - ") > -1) {
                initialSearch = initialSearch.split(" - ")[0].trim();
            }
            $("#txtModalSearchQuery").val(initialSearch);

            if (!modalSpecFiltersLoaded) {
                loadModalSpecFilters();
            }
            $("#modalItemMasterSearch").modal('show');
            setTimeout(function () {
                $("#txtModalSearchQuery").focus();
            }, 300);
            searchModalItems(1);
        }

        function openItemMasterSearchModalForComponent(rowIdx) {
            modalTarget = parseInt(rowIdx);
            $("#modalItemSearchTitleText").text("Item Master Search (Select Component / Raw Material Item - Row #" + rowIdx + ")");
            var initialSearch = $("#txtCompItemSearch_" + rowIdx).val() || "";
            if (initialSearch.indexOf(" - ") > -1) {
                initialSearch = initialSearch.split(" - ")[0].trim();
            }
            $("#txtModalSearchQuery").val(initialSearch);

            if (!modalSpecFiltersLoaded) {
                loadModalSpecFilters();
            }
            $("#modalItemMasterSearch").modal('show');
            setTimeout(function () {
                $("#txtModalSearchQuery").focus();
            }, 300);
            searchModalItems(1);
        }

        function loadModalSpecFilters() {
            $.ajax({
                type: "POST",
                url: "billofmaterial.aspx/loadItemMasterSpecFilters",
                data: "{}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    if (msg.d) {
                        var d = JSON.parse(msg.d);
                        if (d.specItem) $("#comboModalSpecItem").html(d.specItem);
                        if (d.specBrand) $("#comboModalSpecBrand").html(d.specBrand);
                        if (d.specThickness) $("#comboModalSpecThickness").html(d.specThickness);
                        if (d.specColour) $("#comboModalSpecColour").html(d.specColour);
                        if (d.specMachine) $("#comboModalSpecMachine").html(d.specMachine);
                        if (d.uom) $("#comboModalUom").html(d.uom);
                        modalSpecFiltersLoaded = true;
                    }
                }
            });
        }

        function resetModalFilters() {
            $("#txtModalSearchQuery").val('');
            $("#comboModalSpecItem").val('-1');
            $("#comboModalSpecBrand").val('-1');
            $("#comboModalSpecThickness").val('-1');
            $("#comboModalSpecColour").val('-1');
            $("#comboModalSpecMachine").val('-1');
            $("#comboModalUom").val('-1');
            searchModalItems(1);
        }

        function searchModalItems(page) {
            var filters = {};
            var s = $("#txtModalSearchQuery").val();
            if (s && s.trim() !== "") filters.search = s.trim();

            var si = $("#comboModalSpecItem").val();
            if (si && si !== "-1") filters.specItem = si;

            var sb = $("#comboModalSpecBrand").val();
            if (sb && sb !== "-1") filters.specBrand = sb;

            var st = $("#comboModalSpecThickness").val();
            if (st && st !== "-1") filters.specThickness = st;

            var sc = $("#comboModalSpecColour").val();
            if (sc && sc !== "-1") filters.specColour = sc;

            var sm = $("#comboModalSpecMachine").val();
            if (sm && sm !== "-1") filters.specMachine = sm;

            var uom = $("#comboModalUom").val();
            if (uom && uom !== "-1") filters.uom = uom;

            var perpage = parseInt($("#selModalPerPage").val()) || 25;

            $("#tableModalItemMaster tbody").html('<tr><td colspan="7" style="padding:25px; text-align:center; color:#73879C;"><i class="fa fa-spinner fa-spin fa-2x"></i><br/>Loading items with specifications...</td></tr>');

            $.ajax({
                type: "POST",
                url: "billofmaterial.aspx/searchItemMasterWithSpec",
                data: JSON.stringify({ page: page, filters: filters, perpage: perpage }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    if (msg.d === "N" || !msg.d) {
                        $("#tableModalItemMaster tbody").html('<tr><td colspan="7" style="padding:25px; text-align:center; font-weight:bold; color:#73879C;"><i class="fa fa-info-circle"></i> No items found matching the selected filters.</td></tr>');
                        $("#modalItemPaginateDiv").html('');
                        $("#lblModalItemTotalRecords").text('0');
                        modalItemsCache = [];
                    } else {
                        var res = JSON.parse(msg.d);
                        $("#lblModalItemTotalRecords").text(res.count);
                        modalItemsCache = res.data;
                        var htm = "";
                        var startSno = (page - 1) * perpage;

                        $.each(res.data, function (i, item) {
                            var specs = [];
                            if (item.spec_item_name) specs.push("<span class='tag-pill' style='background:#e0f2fe; color:#0369a1; border-color:#bae6fd;'><b>Item:</b> " + item.spec_item_name + "</span>");
                            if (item.spec_pitch_name) specs.push("<span class='tag-pill'><b>Pitch:</b> " + item.spec_pitch_name + "</span>");
                            if (item.spec_crust_name) specs.push("<span class='tag-pill'><b>Crust:</b> " + item.spec_crust_name + "</span>");
                            if (item.spec_brand_name) specs.push("<span class='tag-pill' style='background:#fef3c7; color:#92400e; border-color:#fde68a;'><b>Brand:</b> " + item.spec_brand_name + "</span>");
                            if (item.spec_thickness_name) specs.push("<span class='tag-pill' style='background:#f3e8ff; color:#6b21a8; border-color:#e9d5ff;'><b>Thick:</b> " + item.spec_thickness_name + "</span>");
                            if (item.spec_colour_name) specs.push("<span class='tag-pill' style='background:#fee2e2; color:#991b1b; border-color:#fecaca;'><b>Colour:</b> " + item.spec_colour_name + "</span>");
                            if (item.spec_coating_name) specs.push("<span class='tag-pill'><b>Coating:</b> " + item.spec_coating_name + "</span>");
                            if (item.spec_yield_name) specs.push("<span class='tag-pill'><b>Yield:</b> " + item.spec_yield_name + "</span>");
                            if (item.spec_width_name) specs.push("<span class='tag-pill'><b>Width:</b> " + item.spec_width_name + "</span>");
                            if (item.spec_machine_name) specs.push("<span class='tag-pill'><b>Machine:</b> " + item.spec_machine_name + "</span>");

                            var specsHtml = specs.length > 0 ? specs.join(' ') : "<span style='color:#9ca3af;'>-</span>";

                            htm += "<tr style='vertical-align:middle;'>";
                            htm += "<td style='text-align:center; font-weight:bold; vertical-align:middle;'>" + (startSno + i + 1) + "</td>";
                            htm += "<td style='vertical-align:middle;'><b>" + (item.itm_code || '-') + "</b></td>";
                            htm += "<td style='vertical-align:middle; color:#475569;'>" + (item.itsv_part_no || '-') + "</td>";
                            htm += "<td style='vertical-align:middle;'><b>" + item.itm_name + "</b>" +
                                   (item.itsv_printing_name && item.itsv_printing_name !== item.itm_name ? "<br/><small style='color:#73879C;'>Print: " + item.itsv_printing_name + "</small>" : "") +
                                   "</td>";
                            htm += "<td style='vertical-align:middle;'>" + specsHtml + "</td>";
                            htm += "<td style='text-align:center; vertical-align:middle;'><span class='badge' style='background:#26b99a; font-size:11px;'>" + (item.uom_name || '-') + "</span></td>";
                            htm += "<td style='text-align:center; vertical-align:middle;'>" +
                                   "<button type='button' class='btn btn-success btn-xs' onclick='chooseModalItem(" + i + ");' style='font-weight:bold; padding:4px 10px;'>" +
                                   "<i class='fa fa-check'></i> Select" +
                                   "</button>" +
                                   "</td>";
                            htm += "</tr>";
                        });

                        $("#tableModalItemMaster tbody").html(htm);
                        $("#modalItemPaginateDiv").html(paginate(res.count, perpage, page, "searchModalItems"));
                    }
                },
                error: function () {
                    $("#tableModalItemMaster tbody").html('<tr><td colspan="7" style="padding:25px; text-align:center; color:#dc2626;"><i class="fa fa-exclamation-triangle"></i> Error loading items. Please try again.</td></tr>');
                }
            });
        }

        function chooseModalItem(index) {
            if (!modalItemsCache || !modalItemsCache[index]) return;
            var itm = modalItemsCache[index];

            if (modalTarget === "output") {
                selectOutputItem({
                    id: itm.itm_id,
                    code: itm.itm_code,
                    name: itm.itm_name,
                    printingName: itm.itsv_printing_name,
                    uomId: itm.uom_id,
                    uomName: itm.uom_name
                });
            } else {
                var rowIdx = modalTarget;
                $("#hdnCompItemId_" + rowIdx).val(itm.itm_id);
                var fullText = itm.itm_code + " - " + itm.itm_name;
                $("#txtCompItemSearch_" + rowIdx).val(fullText);
                $("#spanCompName_" + rowIdx).text(fullText);
                $("#lblCompDetail_" + rowIdx).show();
                if (itm.uom_id && itm.uom_id > 0) {
                    $("#comboCompUom_" + rowIdx).val(itm.uom_id);
                }
                setTimeout(function () {
                    $("#txtCompQty_" + rowIdx).focus().select();
                }, 350);
            }
            $("#modalItemMasterSearch").modal('hide');
        }

        function chooseModalOutputItem(index) {
            chooseModalItem(index);
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

                    <!-- sidebar menu -->
                    <div id="sidebar-menu" class="main_menu_side hidden-print main_menu">
                    </div>
                    <!-- /sidebar menu -->

                    <!-- /menu footer buttons -->
                    <div class="sidebar-footer hidden-small">
                        <a data-toggle="tooltip" data-placement="top" title="Logout" href="">
                            <span class="glyphicon glyphicon-off" aria-hidden="true"></span>
                        </a>
                    </div>
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
                                <label style="font-weight: bold; font-size: 16px;">Bill of Material</label>
                            </div>
                            <div class="col-md-6 col-xs-5">
                                <div onclick="javascript:clearform();" class="btn btn-primary btn-xs pull-right" style="margin-top:5px">
                                    <label style="color: #fff; margin-right: 5px; font-size: 14px;" class="fa fa-plus-square"></label> Create New BOM
                                </div>
                            </div>
                        </div>
                    </nav>
                </div>
            </div>
            <!-- /top navigation -->

            <!-- page content -->
            <div class="right_col" role="main">
                <div>
                    <div class="clearfix"></div>

                    <!-- SECTION 1: BOM ENTRY / EDIT FORM -->
                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12" id="DivBomDetails">
                            <div class="x_panel">
                                <div class="x_title" style="margin-bottom: 10px;">
                                    <label style="font-size: 15px; color: #2A3F54;">
                                        <i class="fa fa-cogs" style="color: #3498DB; margin-right: 6px;"></i>Bill of Material Setup
                                    </label>
                                    <ul class="nav navbar-right panel_toolbox">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a></li>
                                    </ul>
                                    <div class="clearfix"></div>
                                </div>

                                <div class="x_content">
                                    <form id="formBom" class="form-horizontal form-label-left">
                                        <!-- Step 1: Select Output Item -->
                                        <div class="form-group" style="margin-bottom: 10px;">
                                            <label class="control-label col-md-2 col-sm-3 col-xs-12" style="text-align: left; font-size: 13px;">
                                                Finished Good / Output Item <span class="required" style="color: red;">*</span>
                                            </label>
                                            <div class="col-md-8 col-sm-9 col-xs-12">
                                                <input type="hidden" id="hdnOutputItemId" value="0" />
                                                <div class="input-group" style="margin-bottom: 0px;">
                                                    <input type="text" id="txtOutputItemSearch" class="form-control" placeholder="Search Finished Good / Produced Item (Type Code or Name)..." style="font-size: 13px;" />
                                                    <span class="input-group-btn">
                                                        <button type="button" class="btn btn-primary" id="btnSearchItemMasterModal" onclick="javascript:openItemMasterSearchModal();" title="Search Item Master with Specifications" style="padding: 6px 14px; font-weight: bold;">
                                                            <i class="fa fa-search" style="margin-right: 5px;"></i> Search Item Master
                                                        </button>
                                                    </span>
                                                </div>

                                                <!-- Selected Item Details Card -->
                                                <div id="divOutputItemInfo" class="item-info-badge" style="display: none;">
                                                    <div class="row" style="margin: 0; font-size: 12px;">
                                                        <div class="col-md-3 col-sm-6 col-xs-12" style="padding: 2px 5px;">
                                                            <b>Item Code:</b> <span id="lblOutputCode" style="color: #1e3a8a; font-weight: bold;">-</span>
                                                        </div>
                                                        <div class="col-md-4 col-sm-6 col-xs-12" style="padding: 2px 5px;">
                                                            <b>Item Name:</b> <span id="lblOutputName" style="color: #1e3a8a; font-weight: bold;">-</span>
                                                        </div>
                                                        <div class="col-md-3 col-sm-6 col-xs-12" style="padding: 2px 5px;">
                                                            <b>Printing Name:</b> <span id="lblOutputPrintingName">-</span>
                                                        </div>
                                                        <div class="col-md-2 col-sm-6 col-xs-12" style="padding: 2px 5px;">
                                                            <b>Base / Sales UOM:</b> <span id="lblOutputUom" class="badge" style="background:#26b99a; font-size:11px;">-</span>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <!-- Step 2: Recipe Components Table -->
                                        <div class="col-md-12 col-sm-12 col-xs-12" style="margin-top: 15px; padding: 0;">
                                            <div style="background: #f7f9fa; border-left: 4px solid #1ABB9C; padding: 8px 12px; margin-bottom: 10px; display: flex; justify-content: space-between; align-items: center;">
                                                <label style="font-size: 13px; font-weight: bold; color: #2A3F54; margin: 0;">
                                                    <i class="fa fa-list" style="color: #1ABB9C; margin-right: 6px;"></i>Raw Materials & Components Required (per 1 Unit of Output Item)
                                                </label>
                                                <button type="button" class="btn btn-success btn-xs" onclick="addNewComponentRow();" style="margin: 0; font-weight: bold;">
                                                    <i class="fa fa-plus"></i> Add Component
                                                </button>
                                            </div>

                                            <div class="table-responsive" style="overflow-x: visible;">
                                                <table id="tblBomComponents" class="table comp-table">
                                                    <thead>
                                                        <tr>
                                                            <th style="width: 45px; text-align: center;">#</th>
                                                            <th>Component / Raw Material Item <span style="color:red;">*</span></th>
                                                            <th style="width: 170px;">Type</th>
                                                            <th style="width: 170px;">Unit (UOM) <span style="color:red;">*</span></th>
                                                            <th style="width: 150px; text-align: right;">Quantity Required <span style="color:red;">*</span></th>
                                                            <th style="width: 60px; text-align: center;">Action</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody>
                                                        <!-- Dynamic Component Rows -->
                                                    </tbody>
                                                </table>
                                            </div>

                                            <div style="margin-top: 5px; margin-bottom: 15px;">
                                                <button type="button" class="btn btn-default btn-xs" onclick="addNewComponentRow();">
                                                    <i class="fa fa-plus-circle" style="color: #1ABB9C;"></i> Add Another Component
                                                </button>
                                            </div>
                                        </div>

                                        <div class="ln_solid" style="margin: 15px 0;"></div>

                                        <!-- Form Action Buttons -->
                                        <div class="form-group" style="margin-bottom: 5px;">
                                            <div class="col-md-12 col-sm-12 col-xs-12" style="text-align: right;">
                                                <div id="btnBomAction" style="display: inline-block;">
                                                    <div class="btn btn-success fl mybtnstyl" onclick="javascript:saveBomDetails();">
                                                        <i class="fa fa-save"></i> SAVE BOM
                                                    </div>
                                                </div>
                                                <div class="btn btn-primary mybtnstyl" onclick="javascript:clearform();" style="margin-left: 8px;">
                                                    <i class="fa fa-refresh"></i> RESET
                                                </div>
                                            </div>
                                        </div>
                                    </form>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- SECTION 2: BOM SEARCH & LIST GRID -->
                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12" id="DivSearchBom">
                            <div class="x_panel">
                                <div class="x_title">
                                    <label style="font-size: 15px; color: #2A3F54;">
                                        <i class="fa fa-book" style="color: #3498DB; margin-right: 6px;"></i>Manage Bills of Material
                                    </label>
                                    <span class="badge" style="color: #fff; margin-left: 8px; background: #3498DB; padding: 4px 8px;" id="lblTotalRecords">0</span>
                                    <div class="clearfix"></div>
                                </div>

                                <div class="x_content">
                                    <form class="form-horizontal form-label-left">
                                        <!-- Search Filter Row -->
                                        <div class="row" style="margin-bottom: 10px;">
                                            <div class="col-md-3 col-sm-4 col-xs-12 form-group">
                                                <label style="font-size: 11px; margin-bottom: 2px; color: #73879C;">Finished Good / Output Item</label>
                                                <input type="text" class="form-control input-sm" id="txtSearchOutput" placeholder="Search Output Item Code / Name..." />
                                            </div>

                                            <div class="col-md-3 col-sm-4 col-xs-12 form-group">
                                                <label style="font-size: 11px; margin-bottom: 2px; color: #73879C;">Component / Raw Material</label>
                                                <input type="text" class="form-control input-sm" id="txtSearchComponent" placeholder="Search Component Item Code / Name..." />
                                            </div>

                                            <div class="col-md-2 col-sm-4 col-xs-12 form-group">
                                                <label style="font-size: 11px; margin-bottom: 2px; color: #73879C;">Component UOM</label>
                                                <select class="form-control input-sm" id="combosearchUom" onchange="javascript:searchBomList(1);">
                                                    <option value="-1">--All UOM--</option>
                                                </select>
                                            </div>

                                            <div class="col-md-4 col-sm-12 col-xs-12 form-group" style="padding-top: 18px;">
                                                <button type="button" class="btn btn-success btn-xs" onclick="javascript:searchBomList(1);" style="padding: 5px 12px; height: 30px; font-weight: bold;">
                                                    <i class="fa fa-search"></i> Search
                                                </button>
                                                <button type="button" class="btn btn-primary btn-xs" onclick="javascript:resetSearch();" style="padding: 5px 10px; height: 30px;" title="Reset Filters">
                                                    <i class="fa fa-refresh"></i> Reset
                                                </button>
                                                <button type="button" id="btnDownloadBomExcel" class="btn btn-success btn-xs" onclick="downloadBomExcel();" style="padding: 5px 12px; height: 30px; background-color: #26b99a; border-color: #26b99a; font-weight: bold;" title="Download all BOM records in Excel sheet">
                                                    <i class="fa fa-file-excel-o"></i> Download Excel
                                                </button>

                                                <select class="input-sm pull-right" id="txtpageno" onchange="javascript:searchBomList(1);" style="height: 30px; width: 70px;">
                                                    <option value="25">25</option>
                                                    <option value="50">50</option>
                                                    <option value="100">100</option>
                                                    <option value="500">500</option>
                                                </select>
                                            </div>
                                        </div>
                                    </form>

                                    <div class="clearfix"></div>
                                    <div class="ln_solid" style="margin-top: 5px; margin-bottom: 12px;"></div>

                                    <!-- BOM List Table -->
                                    <div class="table-responsive" style="overflow-x: auto;">
                                        <table id="tableBomList" class="table table-striped jambo_table bulk_action" style="table-layout: auto;">
                                            <thead style="background-color: #f1eeee; color: #525252;">
                                                <tr>
                                                    <th style="width: 45px; text-align: center;">#</th>
                                                    <th style="width: 130px;">Output Code</th>
                                                    <th>Finished Good / Output Item Name</th>
                                                    <th>Components Breakdown (Item, Qty, Unit)</th>
                                                    <th style="width: 110px; text-align: center;">Action</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <!-- Dynamic Rows -->
                                            </tbody>
                                        </table>
                                    </div>

                                    <div id="paginatediv" style="text-align: center; margin-top: 15px;"></div>
                                </div>
                            </div>
                        </div>
                    </div>

                </div>
            </div>
            <!-- /page content -->

            <!-- MODAL: BOM VIEW DETAILS -->
            <div class="modal fade" id="modalBomView" tabindex="-1" role="dialog" aria-hidden="true">
                <div class="modal-dialog modal-lg">
                    <div class="modal-content">
                        <div class="modal-header" style="background: #2A3F54; color: white; padding: 12px 15px;">
                            <button type="button" class="close" data-dismiss="modal" style="color: white; opacity: 0.9;">&times;</button>
                            <h4 class="modal-title" style="font-size: 15px;">
                                <i class="fa fa-sitemap" style="margin-right: 6px;"></i>Bill of Material Recipe: <span id="modalOutputTitle" style="font-weight: bold;"></span>
                            </h4>
                        </div>
                        <div class="modal-body" style="padding: 15px;">
                            <!-- Output Item Header Summary -->
                            <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 4px; padding: 10px 15px; margin-bottom: 15px;">
                                <div class="row" style="font-size: 12px;">
                                    <div class="col-md-3 col-sm-6"><b>Code:</b> <span id="modalOutputCode">-</span></div>
                                    <div class="col-md-5 col-sm-6"><b>Name:</b> <span id="modalOutputName">-</span></div>
                                    <div class="col-md-4 col-sm-6"><b>Base UOM:</b> <span id="modalOutputUom">-</span></div>
                                </div>
                            </div>

                            <label style="font-size: 13px; font-weight: bold; color: #2A3F54; margin-bottom: 8px;">
                                <i class="fa fa-cubes" style="color: #3498DB;"></i> Required Raw Materials & Components:
                            </label>

                            <div class="table-responsive">
                                <table id="tableModalComponents" class="table table-bordered table-striped" style="font-size: 12px;">
                                    <thead style="background: #f1f5f9;">
                                        <tr>
                                            <th style="width: 45px; text-align: center;">#</th>
                                            <th style="width: 120px;">Code</th>
                                            <th>Component / Raw Material Item</th>
                                            <th style="width: 140px; text-align: right;">Quantity</th>
                                            <th style="width: 110px; text-align: center;">Unit (UOM)</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                        <div class="modal-footer" style="padding: 10px 15px;">
                            <button type="button" class="btn btn-default btn-sm" data-dismiss="modal">Close</button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- MODAL: ITEM MASTER SEARCH WITH TECHNICAL SPECIFICATIONS -->
            <div class="modal fade" id="modalItemMasterSearch" tabindex="-1" role="dialog" aria-hidden="true" style="z-index: 1500;">
                <div class="modal-dialog" style="width: 94%; max-width: 1250px;">
                    <div class="modal-content">
                        <div class="modal-header" style="background: #2A3F54; color: white; padding: 12px 18px;">
                            <button type="button" class="close" data-dismiss="modal" style="color: white; opacity: 0.9; font-size: 24px;">&times;</button>
                            <h4 class="modal-title" style="font-size: 15px; font-weight: bold;">
                                <i class="fa fa-sliders" style="margin-right: 8px; color: #1ABB9C;"></i><span id="modalItemSearchTitleText">Item Master Search (Select by Specifications)</span>
                                <span class="badge" style="background: #1ABB9C; margin-left: 10px; font-size: 12px;" id="lblModalItemTotalRecords">0</span>
                            </h4>
                        </div>
                        <div class="modal-body" style="padding: 15px; background: #fdfdfd;">
                            <!-- Filter Section -->
                            <div class="well" style="padding: 12px; margin-bottom: 12px; background: #ffffff; border: 1px solid #e5e7eb; border-radius: 4px; box-shadow: 0 1px 2px rgba(0,0,0,0.05);">
                                <div class="row">
                                    <div class="col-md-3 col-sm-6 col-xs-12 form-group" style="margin-bottom: 8px;">
                                        <label style="font-size: 11px; margin-bottom: 2px; color: #4b5563; font-weight: 600;">Search Text (Code / Name / Part No)</label>
                                        <input type="text" class="form-control input-sm" id="txtModalSearchQuery" placeholder="Type Code, Name, Part No..." onkeypress="if(event.which==13){searchModalItems(1);return false;}" />
                                    </div>
                                    <div class="col-md-2 col-sm-3 col-xs-6 form-group" style="margin-bottom: 8px;">
                                        <label style="font-size: 11px; margin-bottom: 2px; color: #4b5563; font-weight: 600;">Spec Item</label>
                                        <select class="form-control input-sm" id="comboModalSpecItem" onchange="searchModalItems(1);">
                                            <option value="-1">--All Spec Items--</option>
                                        </select>
                                    </div>
                                    <div class="col-md-2 col-sm-3 col-xs-6 form-group" style="margin-bottom: 8px;">
                                        <label style="font-size: 11px; margin-bottom: 2px; color: #4b5563; font-weight: 600;">Spec Brand</label>
                                        <select class="form-control input-sm" id="comboModalSpecBrand" onchange="searchModalItems(1);">
                                            <option value="-1">--All Spec Brands--</option>
                                        </select>
                                    </div>
                                    <div class="col-md-2 col-sm-3 col-xs-6 form-group" style="margin-bottom: 8px;">
                                        <label style="font-size: 11px; margin-bottom: 2px; color: #4b5563; font-weight: 600;">Thickness</label>
                                        <select class="form-control input-sm" id="comboModalSpecThickness" onchange="searchModalItems(1);">
                                            <option value="-1">--All Thickness--</option>
                                        </select>
                                    </div>
                                    <div class="col-md-1 col-sm-3 col-xs-6 form-group" style="margin-bottom: 8px;">
                                        <label style="font-size: 11px; margin-bottom: 2px; color: #4b5563; font-weight: 600;">Per Page</label>
                                        <select class="form-control input-sm" id="selModalPerPage" onchange="searchModalItems(1);">
                                            <option value="10">10</option>
                                            <option value="25" selected="selected">25</option>
                                            <option value="50">50</option>
                                            <option value="100">100</option>
                                        </select>
                                    </div>
                                    <div class="col-md-2 col-sm-6 col-xs-12 form-group" style="margin-bottom: 8px; padding-top: 19px;">
                                        <button type="button" class="btn btn-success btn-sm" onclick="searchModalItems(1);" style="font-weight: bold;">
                                            <i class="fa fa-search"></i> Search
                                        </button>
                                        <button type="button" class="btn btn-default btn-sm" onclick="resetModalFilters();" style="margin-left: 4px;">
                                            <i class="fa fa-refresh"></i> Reset
                                        </button>
                                        <button type="button" class="btn btn-link btn-sm" onclick="$('#divModalMoreFilters').slideToggle(150);" style="padding: 0 5px; font-size: 11px; text-decoration: none;">
                                            <i class="fa fa-filter"></i> More...
                                        </button>
                                    </div>
                                </div>
                                <!-- Additional Spec Filters Collapsible Row -->
                                <div id="divModalMoreFilters" style="display: none; padding-top: 8px; border-top: 1px dashed #e2e8f0; margin-top: 4px;">
                                    <div class="row">
                                        <div class="col-md-3 col-sm-4 col-xs-12 form-group" style="margin-bottom: 4px;">
                                            <label style="font-size: 11px; margin-bottom: 2px; color: #73879C;">Spec Colour</label>
                                            <select class="form-control input-sm" id="comboModalSpecColour" onchange="searchModalItems(1);">
                                                <option value="-1">--All Colours--</option>
                                            </select>
                                        </div>
                                        <div class="col-md-3 col-sm-4 col-xs-12 form-group" style="margin-bottom: 4px;">
                                            <label style="font-size: 11px; margin-bottom: 2px; color: #73879C;">Spec Machine</label>
                                            <select class="form-control input-sm" id="comboModalSpecMachine" onchange="searchModalItems(1);">
                                                <option value="-1">--All Machines--</option>
                                            </select>
                                        </div>
                                        <div class="col-md-3 col-sm-4 col-xs-12 form-group" style="margin-bottom: 4px;">
                                            <label style="font-size: 11px; margin-bottom: 2px; color: #73879C;">Sales UOM</label>
                                            <select class="form-control input-sm" id="comboModalUom" onchange="searchModalItems(1);">
                                                <option value="-1">--All UOM--</option>
                                            </select>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Table Section -->
                            <div class="table-responsive" style="max-height: 480px; overflow-y: auto; border: 1px solid #e6e9ed;">
                                <table id="tableModalItemMaster" class="table table-striped table-bordered jambo_table" style="margin-bottom: 0; font-size: 12px; table-layout: auto;">
                                    <thead style="background-color: #f1eeee; color: #525252; position: sticky; top: 0; z-index: 2;">
                                        <tr>
                                            <th style="width: 40px; text-align: center;">#</th>
                                            <th style="width: 120px;">Item Code</th>
                                            <th style="width: 110px;">Part No</th>
                                            <th style="width: 250px;">Item Name / Printing Name</th>
                                            <th>Technical Specifications</th>
                                            <th style="width: 90px; text-align: center;">Sales UOM</th>
                                            <th style="width: 80px; text-align: center;">Action</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <!-- Dynamic Rows -->
                                    </tbody>
                                </table>
                            </div>

                            <!-- Pagination Section -->
                            <div id="modalItemPaginateDiv" style="text-align: center; margin-top: 10px;"></div>
                        </div>
                        <div class="modal-footer" style="padding: 10px 15px; background: #f8fafc;">
                            <button type="button" class="btn btn-default btn-sm" data-dismiss="modal">Close</button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- footer content -->
            <footer>
                <div class="pull-right">
                    <div class="footerDiv">
                        <div class="footerDivContent">
                            Copyright 2026 ©
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
    <!-- NProgress -->
    <script src="../js/bootstrap/nprogress.js"></script>
    <!-- Custom Theme Scripts -->
    <script src="../js/bootstrap/custom.min.js"></script>
    <script src="../js/bootbox.min.js"></script>
</body>
</html>
