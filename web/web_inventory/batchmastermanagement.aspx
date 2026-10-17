<%@ Page Language="C#" AutoEventWireup="true" CodeFile="batchmastermanagement.aspx.cs" Inherits="web_inventory_batchmastermanagement" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Batch Master Management | Invoice Me</title>

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
        .batch-preview-box {
            background: #f8fafc;
            border: 1px solid #cbd5e1;
            border-left: 4px solid #3b82f6;
            padding: 10px 15px;
            border-radius: 4px;
            margin-top: 5px;
            margin-bottom: 10px;
        }
        .batch-chip {
            font-family: 'Consolas', 'Courier New', monospace;
            font-size: 16px;
            font-weight: bold;
            letter-spacing: 1px;
            padding: 4px 10px;
            background: #1e293b;
            color: #38bdf8;
            border-radius: 4px;
            display: inline-block;
        }
        .ui-autocomplete {
            max-height: 250px;
            overflow-y: auto;
            overflow-x: hidden;
            z-index: 9999 !important;
            font-size: 12px;
        }
        .assigned-table th {
            background-color: #f7f9fa;
            color: #555;
            font-size: 12px;
            font-weight: bold;
            padding: 7px 10px;
            border: 1px solid #e6e9ed;
        }
        .assigned-table td {
            vertical-align: middle !important;
            padding: 6px 8px !important;
            border: 1px solid #e6e9ed;
            font-size: 12px;
        }
        .radio-box {
            display: inline-block;
            margin-right: 20px;
            font-size: 13px;
            font-weight: normal;
            cursor: pointer;
        }
        .radio-box input {
            margin-right: 6px;
        }
    </style>

    <script type="text/javascript">
        var currentBatchId = 0;
        var currentAction = "insert";
        var assignedItemsMap = {}; // item_id -> { id, code, name, brandCat }
        var catalogPage = 1;
        var modalViewBatchId = 0;
        var modalViewPage = 1;

        $(document).ready(function () {
            loadMenu();
            clearform();
            loadModalDropdowns();
            setupItemAutocomplete();
            searchBatchMasterList(1);

            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " © ");

            // Live preview updates
            $("#txtPrefix, #txtSerial, #txtSuffix").on("input keyup change", function () {
                updateBatchPreview();
            });

            $("#txtSearchPattern, #txtSearchItem").keypress(function (e) {
                if (e.which == 13) {
                    searchBatchMasterList(1);
                    return false;
                }
            });

            $("#txtCatalogSearch").keypress(function (e) {
                if (e.which == 13) {
                    loadCatalogItemsPage(1);
                    return false;
                }
            });

            $("#txtViewSearch").keypress(function (e) {
                if (e.which == 13) {
                    loadAssignedItemsPage(1);
                    return false;
                }
            });

            $("#txtInlineSearch").keypress(function (e) {
                if (e.which == 13) {
                    loadInlineLinkedPage(1);
                    return false;
                }
            });

            // Radio change
            $('input[name="assignModeRadio"]').change(function () {
                var mode = $('input[name="assignModeRadio"]:checked').val();
                if (mode === "SPECIFIC") {
                    $("#divSpecificItemsPanel").slideDown(200);
                } else {
                    $("#divSpecificItemsPanel").slideUp(200);
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

        // Live preview of the batch number
        function updateBatchPreview() {
            var prefix = $("#txtPrefix").val() || "";
            var serial = $("#txtSerial").val() || "0";
            var suffix = $("#txtSuffix").val() || "";
            var sample = prefix + serial + suffix;
            $("#lblBatchPreview").text(sample);
            $("#spanPrefixPreview").text(prefix || "(none)");
            $("#spanSerialPreview").text(serial);
            $("#spanSuffixPreview").text(suffix || "(none)");
        }

        // Load Spec Brand options for modal filters
        function loadModalDropdowns() {
            $.ajax({
                type: "POST",
                url: "batchmastermanagement.aspx/loadFilterDropdowns",
                data: "{}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    if (msg.d) {
                        var res = JSON.parse(msg.d);
                        if (res.specBrands) {
                            $("#comboCatalogSpecBrand, #comboViewSpecBrand, #comboInlineSpecBrand").html(res.specBrands);
                        }
                    }
                }
            });
        }

        // Setup Autocomplete for single item search
        function setupItemAutocomplete() {
            $("#txtItemSearch").autocomplete({
                source: function (request, response) {
                    $.ajax({
                        type: "POST",
                        contentType: "application/json; charset=utf-8",
                        url: "batchmastermanagement.aspx/searchItemsAutocomplete",
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
                    addSingleItemToAssigned(ui.item);
                    $("#txtItemSearch").val('');
                    return false;
                },
                minLength: 1
            });
        }

        // Add single item to assigned map and update table
        function addSingleItemToAssigned(item) {
            if (!item || !item.id) return;
            if (assignedItemsMap[item.id]) {
                alert("Item is already added to this Batch Master!");
                return;
            }
            assignedItemsMap[item.id] = {
                id: item.id,
                code: item.code,
                name: item.name,
                printingName: item.printingName,
                specBrand: item.specBrand || ''
            };
            renderAssignedItemsTable();
        }

        // Remove item from assigned map
        function removeAssignedItem(id) {
            delete assignedItemsMap[id];
            renderAssignedItemsTable();
        }

        // Render Assigned Items Table
        function renderAssignedItemsTable() {
            var keys = Object.keys(assignedItemsMap);
            var count = keys.length;
            $("#lblAssignedCount").text(count + " Items Assigned");

            if (count === 0) {
                $("#tblAssignedItems tbody").html('<tr><td colspan="5" style="text-align:center; padding:15px; color:#73879C;"><i class="fa fa-info-circle"></i> No specific items added yet. Search above or click "Select Items from Catalog".</td></tr>');
                return;
            }

            var trs = "";
            for (var i = 0; i < keys.length; i++) {
                var itm = assignedItemsMap[keys[i]];
                trs += "<tr>" +
                    "<td style='text-align:center; font-weight:bold; width:45px;'>" + (i + 1) + "</td>" +
                    "<td style='width:120px;'><b>" + (itm.code || '-') + "</b></td>" +
                    "<td>" + itm.name + (itm.printingName && itm.printingName != itm.name ? "<br/><small style='color:#73879C;'>Print: " + itm.printingName + "</small>" : "") + "</td>" +
                    "<td style='width:160px;'><b>" + (itm.specBrand || '-') + "</b></td>" +
                    "<td style='text-align:center; width:50px;'>" +
                        "<button type='button' class='btn btn-danger btn-xs' onclick='removeAssignedItem(" + itm.id + ");' title='Remove'>" +
                            "<i class='fa fa-trash'></i>" +
                        "</button>" +
                    "</td>" +
                "</tr>";
            }
            $("#tblAssignedItems tbody").html(trs);
        }

        // Clear Form
        function clearform() {
            currentBatchId = 0;
            currentAction = "insert";
            assignedItemsMap = {};
            $("#txtPrefix").val('');
            $("#txtSerial").val(100);
            $("#txtSuffix").val('');
            updateBatchPreview();

            // Default to ALL items for new batch master
            $("#radioAllItems").prop("checked", true);
            $("#divRadioKeep").hide();
            $("#divSpecificItemsPanel").hide();
            $("#divInlineLinkedSection").hide();
            $("#lblInlineSelectedCount").hide();
            $("#lblBtnUnlinkCount").text("0");
            renderAssignedItemsTable();

            $("#btnBatchMasterAction").html("<div class='btn btn-success fl mybtnstyl' onclick='javascript:saveBatchMasterDetails();'><i class='fa fa-save'></i> SAVE BATCH MASTER</div>");
        }

        // Save or Update Batch Master Details
        function saveBatchMasterDetails() {
            sqlInjection();
            var prefix = $("#txtPrefix").val().trim();
            var suffix = $("#txtSuffix").val().trim();
            var serialVal = $("#txtSerial").val();
            var serialNo = parseInt(serialVal);

            if (prefix === "" && suffix === "") {
                alert("Please enter a valid Prefix or Suffix for the Batch Master format!");
                $("#txtPrefix").focus();
                return;
            }

            if (isNaN(serialNo) || serialNo < 0) {
                alert("Serial Number must be 0 or a positive integer!");
                $("#txtSerial").focus();
                return;
            }

            var assignMode = $('input[name="assignModeRadio"]:checked').val() || "ALL";
            var itemIds = [];

            if (assignMode === "SPECIFIC") {
                itemIds = Object.keys(assignedItemsMap).map(function (k) { return parseInt(k); });
                if (itemIds.length === 0) {
                    alert("You selected 'Assign Specific Items', but haven't added any items yet! Please add items or choose 'Assign All Items'.");
                    return;
                }
            }

            loading();
            $.ajax({
                type: "POST",
                url: "batchmastermanagement.aspx/saveBatchMaster",
                data: JSON.stringify({
                    actionType: currentAction,
                    batchId: currentBatchId,
                    prefix: prefix,
                    suffix: suffix,
                    serialNo: serialNo,
                    assignMode: assignMode,
                    itemIds: itemIds
                }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d === "Y") {
                        alert(currentAction === "insert" ? "Batch Master Created Successfully!" : "Batch Master Updated Successfully!");
                        clearform();
                        searchBatchMasterList(1);
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

        // Search Batch Master List
        function searchBatchMasterList(page) {
            sqlInjection();
            var filters = {};
            var search = $("#txtSearchPattern").val();
            if (search !== undefined && search.trim() !== "") {
                filters.search = search.trim();
            }

            var item = $("#txtSearchItem").val();
            if (item !== undefined && item.trim() !== "") {
                filters.item = item.trim();
            }

            var perpage = $("#txtpageno").val() || 25;
            loading();
            $.ajax({
                type: "POST",
                url: "batchmastermanagement.aspx/searchBatchMasterList",
                data: JSON.stringify({ page: page, filters: filters, perpage: parseInt(perpage) }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d === "N" || !msg.d) {
                        $("#tableBatchMasterList tbody").html('<tr><td colspan="8" style="padding:25px; text-align:center; font-weight:bold; color:#73879C;"><i class="fa fa-info-circle"></i> No Batch Master records found.</td></tr>');
                        $("#paginatediv").html('');
                        $("#lblTotalRecords").text(0);
                    } else {
                        var res = JSON.parse(msg.d);
                        $("#lblTotalRecords").text(res.count);
                        var htm = "";
                        var startSno = (page - 1) * perpage;

                        $.each(res.data, function (i, row) {
                            htm += "<tr style='font-size:12px;'>";
                            htm += "<td style='text-align:center; font-weight:bold; vertical-align:middle; width:45px;'>" + (startSno + i + 1) + "</td>";
                            htm += "<td style='text-align:center; vertical-align:middle; width:80px;'><b>#" + row.itbm_id + "</b></td>";
                            htm += "<td style='vertical-align:middle;'><b>" + (row.itbm_prefix || '<span style=\"color:#aaa;\">(none)</span>') + "</b></td>";
                            htm += "<td style='text-align:center; vertical-align:middle; font-weight:bold;'>" + row.itbm_serl + "</td>";
                            htm += "<td style='vertical-align:middle;'><b>" + (row.itbm_suffix || '<span style=\"color:#aaa;\">(none)</span>') + "</b></td>";
                            htm += "<td style='vertical-align:middle;'><span class='batch-chip' style='font-size:13px;'>" + row.sample_batch + "</span></td>";
                            htm += "<td style='text-align:center; vertical-align:middle;'><span class='badge' style='background:#26b99a; font-size:11px; padding:4px 8px;'>" + Number(row.total_items).toLocaleString() + " Items</span></td>";
                            htm += "<td style='text-align:center; vertical-align:middle; white-space:nowrap; width:120px;'>" +
                                   "<button type='button' class='btn btn-info btn-xs' onclick='viewAssignedItems(" + row.itbm_id + ", \"" + (row.sample_batch || '').replace(/"/g, '&quot;') + "\");' title='View Assigned Items' style='margin-right:4px;'><i class='fa fa-eye'></i></button>" +
                                   "<button type='button' class='btn btn-primary btn-xs' onclick='editBatchMaster(" + row.itbm_id + ");' title='Edit Batch Master' style='margin-right:4px;'><i class='fa fa-pencil'></i></button>" +
                                   "<button type='button' class='btn btn-danger btn-xs' onclick='deleteBatchMasterConfirm(" + row.itbm_id + ");' title='Delete Batch Master'><i class='fa fa-trash'></i></button>" +
                                   "</td>";
                            htm += "</tr>";
                        });

                        $("#tableBatchMasterList tbody").html(htm);
                        $("#paginatediv").html(paginate(res.count, perpage, page, "searchBatchMasterList"));
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
            $("#txtSearchPattern").val('');
            $("#txtSearchItem").val('');
            searchBatchMasterList(1);
        }

        // Edit Batch Master
        function editBatchMaster(batchId) {
            loading();
            $.ajax({
                type: "POST",
                url: "batchmastermanagement.aspx/getBatchMasterDetails",
                data: JSON.stringify({ batchId: batchId }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (!msg.d || msg.d === "N") {
                        alert("Error loading Batch Master details!");
                        return;
                    }
                    var res = JSON.parse(msg.d);
                    var h = res.header[0];

                    clearform();
                    currentBatchId = h.itbm_id;
                    currentAction = "update";

                    $("#txtPrefix").val(h.itbm_prefix || '');
                    $("#txtSerial").val(h.itbm_serl || 0);
                    $("#txtSuffix").val(h.itbm_suffix || '');
                    updateBatchPreview();

                    $("#divRadioKeep").show();
                    $("#radioKeepItems").prop("checked", true);
                    $("#lblKeepCount").text("(" + Number(res.totalAssigned).toLocaleString() + " items currently linked)");
                    $("#lblBtnUnlinkCount").text(Number(res.totalAssigned).toLocaleString());

                    if (parseInt(res.totalAssigned) > 0) {
                        $("#divInlineLinkedSection").slideDown(200);
                        loadInlineLinkedPage(1);
                    } else {
                        $("#divInlineLinkedSection").hide();
                    }

                    if (res.isAllItems) {
                        $("#radioAllItems").prop("checked", true);
                        $("#divSpecificItemsPanel").hide();
                    } else if (res.sampleItems && res.sampleItems.length > 0) {
                        assignedItemsMap = {};
                        for (var i = 0; i < res.sampleItems.length; i++) {
                            var item = res.sampleItems[i];
                            assignedItemsMap[item.itm_id] = {
                                id: item.itm_id,
                                code: item.itm_code,
                                name: item.itm_name,
                                printingName: item.itsv_printing_name,
                                specBrand: item.spec_brand_name || ''
                            };
                        }
                        renderAssignedItemsTable();
                    }

                    $("#btnBatchMasterAction").html("<div class='btn btn-success fl mybtnstyl' onclick='javascript:saveBatchMasterDetails();'><i class='fa fa-refresh'></i> UPDATE BATCH MASTER</div>");

                    $('html,body').animate({
                        scrollTop: $('#DivBatchMasterDetails').offset().top - 20
                    }, 400);
                },
                error: function () {
                    Unloading();
                    alert("Error loading Batch Master details!");
                }
            });
        }

        // Delete Batch Master Confirm
        function deleteBatchMasterConfirm(batchId) {
            if (!confirm("Are you sure you want to delete this Batch Master? All linked item associations will be removed.")) {
                return;
            }
            loading();
            $.ajax({
                type: "POST",
                url: "batchmastermanagement.aspx/deleteBatchMaster",
                data: JSON.stringify({ batchId: batchId }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d === "Y") {
                        alert("Batch Master deleted successfully!");
                        if (currentBatchId === batchId) {
                            clearform();
                        }
                        searchBatchMasterList(1);
                    } else {
                        alert("Error deleting Batch Master: " + msg.d);
                    }
                },
                error: function () {
                    Unloading();
                    alert("Error deleting Batch Master!");
                }
            });
        }

        // View Assigned Items Modal
        function viewAssignedItems(batchId, sampleBatch) {
            modalViewBatchId = batchId;
            modalViewPage = 1;
            $("#modalViewTitle").text("Assigned Items for Batch #" + batchId + " (" + sampleBatch + ")");
            $("#txtViewSearch").val('');
            $("#comboViewSpecBrand").val('-1');
            $("#comboViewPerPage").val('25');
            $("#chkModalUnlinkAll").prop("checked", false);
            updateModalUnlinkSelectedCount();
            loadAssignedItemsPage(1);
            $("#modalViewAssignedItems").modal('show');
        }

        // Open Unlink Modal directly for currently edited batch
        function openUnlinkModalForCurrentBatch() {
            if (currentBatchId <= 0) {
                alert("Please select or save a Batch Master first.");
                return;
            }
            var sample = $("#lblBatchPreview").text();
            viewAssignedItems(currentBatchId, sample);
        }

        // Load Paginated Assigned Items for the View Modal
        function loadAssignedItemsPage(page) {
            modalViewPage = page;
            var search = $("#txtViewSearch").val() || "";
            var specBrand = $("#comboViewSpecBrand").val() || "-1";
            var perpage = parseInt($("#comboViewPerPage").val()) || 25;

            $("#tableModalAssigned tbody").html('<tr><td colspan="7" style="text-align:center; padding:15px;"><i class="fa fa-spinner fa-spin"></i> Loading assigned items...</td></tr>');

            $.ajax({
                type: "POST",
                url: "batchmastermanagement.aspx/getAssignedItems",
                data: JSON.stringify({
                    batchId: modalViewBatchId,
                    page: page,
                    search: search,
                    specBrand: specBrand,
                    perpage: perpage
                }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    if (msg.d === "N" || !msg.d) {
                        $("#tableModalAssigned tbody").html('<tr><td colspan="7" style="text-align:center; padding:15px; color:#73879C;">No assigned items match criteria.</td></tr>');
                        $("#modalViewPagination").html('');
                        $("#lblModalTotalCount").text(0);
                        updateModalUnlinkSelectedCount();
                    } else {
                        var res = JSON.parse(msg.d);
                        $("#lblModalTotalCount").text(Number(res.count).toLocaleString());
                        var trs = "";
                        var startSno = (page - 1) * perpage;

                        $.each(res.data, function (i, r) {
                            trs += "<tr>" +
                                "<td style='text-align:center; width:40px;'>" +
                                    "<input type='checkbox' class='chk-modal-unlink' value='" + r.itm_id + "' onchange='updateModalUnlinkSelectedCount();' />" +
                                "</td>" +
                                "<td style='text-align:center; font-weight:bold; width:45px;'>" + (startSno + i + 1) + "</td>" +
                                "<td style='width:110px;'><b>" + (r.itm_code || '-') + "</b></td>" +
                                "<td>" + r.itm_name + (r.itsv_printing_name && r.itsv_printing_name != r.itm_name ? "<br/><small style='color:#73879C;'>Print: " + r.itsv_printing_name + "</small>" : "") + "</td>" +
                                "<td style='width:160px;'><b>" + (r.spec_brand_name || '-') + "</b></td>" +
                                "<td style='text-align:center; width:80px;'><span class='label label-default'>" + (r.uom_name || '-') + "</span></td>" +
                                "<td style='text-align:center; width:70px;'>" +
                                    "<button type='button' class='btn btn-danger btn-xs' onclick='unlinkSingleAssignedItem(" + r.itm_id + ", \"" + (r.itm_code || '').replace(/"/g, '&quot;') + "\");' title='Unlink Item'><i class='fa fa-chain-broken'></i> Unlink</button>" +
                                "</td>" +
                            "</tr>";
                        });

                        $("#tableModalAssigned tbody").html(trs);
                        $("#modalViewPagination").html(paginate(res.count, perpage, page, "loadAssignedItemsPage"));
                        $("#chkModalUnlinkAll").prop("checked", false);
                        updateModalUnlinkSelectedCount();
                    }
                }
            });
        }

        // Toggle Select All in Assigned Items Modal
        function toggleModalUnlinkSelectAll(master) {
            $(".chk-modal-unlink").prop("checked", $(master).is(":checked"));
            updateModalUnlinkSelectedCount();
        }

        // Update selected badge in Assigned Items Modal
        function updateModalUnlinkSelectedCount() {
            var cnt = $(".chk-modal-unlink:checked").length;
            $("#lblModalSelectedCount").text(cnt + " item(s) selected to unlink").toggle(cnt > 0);
        }

        // Unlink Selected in Assigned Items Modal
        function unlinkSelectedAssignedItems() {
            var itemIds = [];
            $(".chk-modal-unlink:checked").each(function () {
                var id = parseInt($(this).val());
                if (id > 0) itemIds.push(id);
            });

            if (itemIds.length === 0) {
                alert("Please select at least one item to unlink using the checkboxes.");
                return;
            }

            if (!confirm("Are you sure you want to unlink " + itemIds.length + " selected item(s) from Batch #" + modalViewBatchId + "?")) {
                return;
            }

            loading();
            $.ajax({
                type: "POST",
                url: "batchmastermanagement.aspx/unlinkBatchItems",
                data: JSON.stringify({ batchId: modalViewBatchId, itemIds: itemIds, unlinkAll: false }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d === "Y") {
                        alert(itemIds.length + " item(s) unlinked successfully!");
                        loadAssignedItemsPage(modalViewPage);
                        searchBatchMasterList(1);
                        if (currentBatchId === modalViewBatchId) {
                            loadInlineLinkedPage(1);
                        }
                    } else {
                        alert(msg.d);
                    }
                },
                error: function () {
                    Unloading();
                    alert("Error unlinking items!");
                }
            });
        }

        // Unlink All from Batch in Assigned Items Modal
        function unlinkAllAssignedItems() {
            if (!confirm("Are you sure you want to unlink ALL items from Batch #" + modalViewBatchId + "? This action cannot be undone.")) {
                return;
            }

            loading();
            $.ajax({
                type: "POST",
                url: "batchmastermanagement.aspx/unlinkBatchItems",
                data: JSON.stringify({ batchId: modalViewBatchId, itemIds: [], unlinkAll: true }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d === "Y") {
                        alert("All items unlinked successfully!");
                        loadAssignedItemsPage(1);
                        searchBatchMasterList(1);
                        if (currentBatchId === modalViewBatchId) {
                            loadInlineLinkedPage(1);
                        }
                    } else {
                        alert(msg.d);
                    }
                },
                error: function () {
                    Unloading();
                    alert("Error unlinking items!");
                }
            });
        }

        // Unlink Single Item in Assigned Items Modal
        function unlinkSingleAssignedItem(itmId, itmCode) {
            if (!confirm("Are you sure you want to unlink item " + itmCode + " from Batch #" + modalViewBatchId + "?")) {
                return;
            }

            loading();
            $.ajax({
                type: "POST",
                url: "batchmastermanagement.aspx/unlinkBatchItems",
                data: JSON.stringify({ batchId: modalViewBatchId, itemIds: [itmId], unlinkAll: false }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d === "Y") {
                        alert("Item " + itmCode + " unlinked successfully!");
                        loadAssignedItemsPage(modalViewPage);
                        searchBatchMasterList(1);
                        if (currentBatchId === modalViewBatchId) {
                            loadInlineLinkedPage(1);
                        }
                    } else {
                        alert(msg.d);
                    }
                },
                error: function () {
                    Unloading();
                    alert("Error unlinking item!");
                }
            });
        }

        // --- INLINE LINKED ITEMS LISTBOX FOR EDIT FORM ---
        var inlineLinkedPage = 1;
        function loadInlineLinkedPage(page) {
            if (currentBatchId <= 0) return;
            inlineLinkedPage = page;
            var search = $("#txtInlineSearch").val() || "";
            var specBrand = $("#comboInlineSpecBrand").val() || "-1";
            var perpage = parseInt($("#comboInlinePerPage").val()) || 25;

            $("#tableInlineLinked tbody").html('<tr><td colspan="7" style="text-align:center; padding:15px;"><i class="fa fa-spinner fa-spin"></i> Loading linked items...</td></tr>');

            $.ajax({
                type: "POST",
                url: "batchmastermanagement.aspx/getAssignedItems",
                data: JSON.stringify({
                    batchId: currentBatchId,
                    page: page,
                    search: search,
                    specBrand: specBrand,
                    perpage: perpage
                }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    if (msg.d === "N" || !msg.d) {
                        $("#tableInlineLinked tbody").html('<tr><td colspan="7" style="text-align:center; padding:15px; color:#73879C;">No linked items found.</td></tr>');
                        $("#inlineLinkedPagination").html('');
                        $("#lblInlineLinkedCount").text("0 items");
                        $("#lblKeepCount").text("(0 items currently linked)");
                        $("#lblBtnUnlinkCount").text(0);
                        updateInlineUnlinkCount();
                    } else {
                        var res = JSON.parse(msg.d);
                        $("#lblInlineLinkedCount").text(Number(res.count).toLocaleString() + " items");
                        $("#lblKeepCount").text("(" + Number(res.count).toLocaleString() + " items currently linked)");
                        $("#lblBtnUnlinkCount").text(Number(res.count).toLocaleString());
                        var trs = "";
                        var startSno = (page - 1) * perpage;

                        $.each(res.data, function (i, r) {
                            trs += "<tr>" +
                                "<td style='text-align:center; width:40px;'>" +
                                    "<input type='checkbox' class='chk-inline-unlink' value='" + r.itm_id + "' onchange='updateInlineUnlinkCount();' />" +
                                "</td>" +
                                "<td style='text-align:center; font-weight:bold; width:45px;'>" + (startSno + i + 1) + "</td>" +
                                "<td style='width:110px;'><b>" + (r.itm_code || '-') + "</b></td>" +
                                "<td>" + r.itm_name + (r.itsv_printing_name && r.itsv_printing_name != r.itm_name ? "<br/><small style='color:#73879C;'>Print: " + r.itsv_printing_name + "</small>" : "") + "</td>" +
                                "<td style='width:160px;'><b>" + (r.spec_brand_name || '-') + "</b></td>" +
                                "<td style='text-align:center; width:80px;'><span class='label label-default'>" + (r.uom_name || '-') + "</span></td>" +
                                "<td style='text-align:center; width:70px;'>" +
                                    "<button type='button' class='btn btn-danger btn-xs' onclick='unlinkSingleInline(" + r.itm_id + ", \"" + (r.itm_code || '').replace(/"/g, '&quot;') + "\");' title='Unlink Item'><i class='fa fa-chain-broken'></i> Unlink</button>" +
                                "</td>" +
                            "</tr>";
                        });

                        $("#tableInlineLinked tbody").html(trs);
                        $("#inlineLinkedPagination").html(paginate(res.count, perpage, page, "loadInlineLinkedPage"));
                        $("#chkInlineUnlinkAll").prop("checked", false);
                        updateInlineUnlinkCount();
                    }
                }
            });
        }

        // Toggle Select All in Inline Listbox
        function toggleInlineUnlinkSelectAll(master) {
            $(".chk-inline-unlink").prop("checked", $(master).is(":checked"));
            updateInlineUnlinkCount();
        }

        // Update selected badge in Inline Listbox
        function updateInlineUnlinkCount() {
            var cnt = $(".chk-inline-unlink:checked").length;
            $("#lblInlineSelectedCount").text(cnt + " selected to unlink").toggle(cnt > 0);
        }

        // Unlink Selected in Inline Listbox
        function unlinkSelectedInline() {
            var itemIds = [];
            $(".chk-inline-unlink:checked").each(function () {
                var id = parseInt($(this).val());
                if (id > 0) itemIds.push(id);
            });

            if (itemIds.length === 0) {
                alert("Please select at least one item to unlink using the checkboxes.");
                return;
            }

            if (!confirm("Are you sure you want to unlink " + itemIds.length + " selected item(s) from this Batch Master?")) {
                return;
            }

            loading();
            $.ajax({
                type: "POST",
                url: "batchmastermanagement.aspx/unlinkBatchItems",
                data: JSON.stringify({ batchId: currentBatchId, itemIds: itemIds, unlinkAll: false }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d === "Y") {
                        alert(itemIds.length + " item(s) unlinked successfully!");
                        loadInlineLinkedPage(inlineLinkedPage);
                        searchBatchMasterList(1);
                    } else {
                        alert(msg.d);
                    }
                },
                error: function () {
                    Unloading();
                    alert("Error unlinking items!");
                }
            });
        }

        // Unlink All in Inline Listbox
        function unlinkAllInline() {
            if (!confirm("Are you sure you want to unlink ALL items from this Batch Master? This action cannot be undone.")) {
                return;
            }

            loading();
            $.ajax({
                type: "POST",
                url: "batchmastermanagement.aspx/unlinkBatchItems",
                data: JSON.stringify({ batchId: currentBatchId, itemIds: [], unlinkAll: true }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d === "Y") {
                        alert("All items unlinked successfully!");
                        loadInlineLinkedPage(1);
                        searchBatchMasterList(1);
                    } else {
                        alert(msg.d);
                    }
                },
                error: function () {
                    Unloading();
                    alert("Error unlinking items!");
                }
            });
        }

        // Unlink Single Item in Inline Listbox
        function unlinkSingleInline(itmId, itmCode) {
            if (!confirm("Are you sure you want to unlink item " + itmCode + " from this Batch Master?")) {
                return;
            }

            loading();
            $.ajax({
                type: "POST",
                url: "batchmastermanagement.aspx/unlinkBatchItems",
                data: JSON.stringify({ batchId: currentBatchId, itemIds: [itmId], unlinkAll: false }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d === "Y") {
                        alert("Item " + itmCode + " unlinked successfully!");
                        loadInlineLinkedPage(inlineLinkedPage);
                        searchBatchMasterList(1);
                    } else {
                        alert(msg.d);
                    }
                },
                error: function () {
                    Unloading();
                    alert("Error unlinking item!");
                }
            });
        }

        // Open Catalog Picker Modal
        function openCatalogPicker() {
            catalogPage = 1;
            $("#txtCatalogSearch").val('');
            $("#comboCatalogSpecBrand").val('-1');
            $("#comboCatalogPerPage").val('25');
            loadCatalogItemsPage(1);
            $("#modalCatalogPicker").modal('show');
        }

        // Load Catalog Items Page for Picker Modal
        function loadCatalogItemsPage(page) {
            catalogPage = page;
            var search = $("#txtCatalogSearch").val() || "";
            var specBrand = $("#comboCatalogSpecBrand").val() || "-1";
            var perpage = parseInt($("#comboCatalogPerPage").val()) || 25;

            $("#tableCatalogItems tbody").html('<tr><td colspan="5" style="text-align:center; padding:15px;"><i class="fa fa-spinner fa-spin"></i> Loading catalog items...</td></tr>');

            $.ajax({
                type: "POST",
                url: "batchmastermanagement.aspx/searchCatalogItems",
                data: JSON.stringify({
                    page: page,
                    search: search,
                    specBrand: specBrand,
                    perpage: perpage
                }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    if (msg.d === "N" || !msg.d) {
                        $("#tableCatalogItems tbody").html('<tr><td colspan="5" style="text-align:center; padding:15px; color:#73879C;">No items found.</td></tr>');
                        $("#modalCatalogPagination").html('');
                        $("#lblCatalogTotalCount").text(0);
                    } else {
                        var res = JSON.parse(msg.d);
                        $("#lblCatalogTotalCount").text(Number(res.count).toLocaleString());
                        var trs = "";

                        $.each(res.data, function (i, r) {
                            var checked = assignedItemsMap[r.itm_id] ? "checked" : "";
                            var specBrandName = r.spec_brand_name || '-';
                            trs += "<tr>" +
                                "<td style='text-align:center; width:40px;'>" +
                                    "<input type='checkbox' class='chk-catalog-item' value='" + r.itm_id + "' data-code='" + (r.itm_code || '').replace(/'/g, "&#39;") + "' data-name='" + (r.itm_name || '').replace(/'/g, "&#39;") + "' data-specbrand='" + (specBrandName).replace(/'/g, "&#39;") + "' " + checked + " />" +
                                "</td>" +
                                "<td style='width:120px;'><b>" + (r.itm_code || '-') + "</b></td>" +
                                "<td>" + r.itm_name + "</td>" +
                                "<td style='width:180px;'><b>" + specBrandName + "</b></td>" +
                                "<td style='text-align:center; width:80px;'><span class='label label-default'>" + (r.uom_name || '-') + "</span></td>" +
                            "</tr>";
                        });

                        $("#tableCatalogItems tbody").html(trs);
                        $("#modalCatalogPagination").html(paginate(res.count, perpage, page, "loadCatalogItemsPage"));
                    }
                }
            });
        }

        // Toggle All Checkboxes in Catalog Picker
        function toggleCatalogSelectAll(master) {
            $(".chk-catalog-item").prop("checked", $(master).is(":checked"));
        }

        // Add Selected Catalog Items to Assigned Map
        function addSelectedCatalogItems() {
            var addedCount = 0;
            $(".chk-catalog-item:checked").each(function () {
                var itmId = parseInt($(this).val());
                if (itmId > 0 && !assignedItemsMap[itmId]) {
                    assignedItemsMap[itmId] = {
                        id: itmId,
                        code: $(this).data("code"),
                        name: $(this).data("name"),
                        specBrand: $(this).data("specbrand")
                    };
                    addedCount++;
                }
            });

            renderAssignedItemsTable();
            $("#modalCatalogPicker").modal('hide');
            alert(addedCount + " item(s) added to the Batch Master configuration!");
        }

        // Download Excel
        function downloadBatchMasterExcel() {
            sqlInjection();
            var filters = {};
            var search = $("#txtSearchPattern").val();
            if (search !== undefined && search.trim() !== "") {
                filters.search = search.trim();
            }

            var item = $("#txtSearchItem").val();
            if (item !== undefined && item.trim() !== "") {
                filters.item = item.trim();
            }

            loading();
            $.ajax({
                type: "POST",
                url: "batchmastermanagement.aspx/prepareBatchMasterExport",
                data: JSON.stringify({ filters: filters }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d === "N" || msg.d === "0") {
                        alert("No Batch Master records found to download!");
                    } else if (msg.d === "Y") {
                        location.href = "downloadBatchMaster.aspx";
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
                                <label style="font-weight: bold; font-size: 16px;">Batch Master Management</label>
                            </div>
                            <div class="col-md-6 col-xs-5">
                                <div onclick="javascript:clearform();" class="btn btn-primary btn-xs pull-right" style="margin-top:5px">
                                    <label style="color: #fff; margin-right: 5px; font-size: 14px;" class="fa fa-plus-square"></label> Create New Batch Master
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

                    <!-- SECTION 1: BATCH MASTER FORM -->
                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12" id="DivBatchMasterDetails">
                            <div class="x_panel">
                                <div class="x_title" style="margin-bottom: 10px;">
                                    <label style="font-size: 15px; color: #2A3F54;">
                                        <i class="fa fa-cogs" style="color: #3498DB; margin-right: 6px;"></i>Batch Master Configuration
                                    </label>
                                    <ul class="nav navbar-right panel_toolbox">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a></li>
                                    </ul>
                                    <div class="clearfix"></div>
                                </div>

                                <div class="x_content">
                                    <form id="formBatchMaster" class="form-horizontal form-label-left">
                                        <!-- Row 1: Prefix, Serial, Suffix -->
                                        <div class="row">
                                            <div class="col-md-4 col-sm-4 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12" style="text-align: left;">Prefix</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <input type="text" id="txtPrefix" class="form-control" placeholder="e.g. Jind/, Dmax/, BT-" maxlength="30" />
                                                        <small style="color:#73879C;">Batch prefix text</small>
                                                    </div>
                                                </div>
                                            </div>

                                            <div class="col-md-4 col-sm-4 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-5 col-sm-5 col-xs-12" style="text-align: left;">Starting Serial <span style="color:red;">*</span></label>
                                                    <div class="col-md-7 col-sm-7 col-xs-12">
                                                        <input type="number" id="txtSerial" class="form-control" placeholder="100" value="100" min="0" />
                                                        <small style="color:#73879C;">Sequence start number</small>
                                                    </div>
                                                </div>
                                            </div>

                                            <div class="col-md-4 col-sm-4 col-xs-12">
                                                <div class="form-group">
                                                    <label class="control-label col-md-4 col-sm-4 col-xs-12" style="text-align: left;">Suffix</label>
                                                    <div class="col-md-8 col-sm-8 col-xs-12">
                                                        <input type="text" id="txtSuffix" class="form-control" placeholder="e.g. /2026, /2027, -A" maxlength="30" />
                                                        <small style="color:#73879C;">Batch suffix text</small>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <!-- Live Batch Format Preview Callout -->
                                        <div class="row" style="margin-top: 5px;">
                                            <div class="col-md-12 col-sm-12 col-xs-12">
                                                <div class="batch-preview-box">
                                                    <div class="row" style="align-items: center; display: flex; flex-wrap: wrap;">
                                                        <div class="col-md-4 col-sm-6 col-xs-12">
                                                            <span style="font-size: 12px; color: #64748b; font-weight: bold; text-transform: uppercase;">
                                                                <i class="fa fa-eye" style="color: #3b82f6;"></i> Sample Batch Number Format:
                                                            </span>
                                                            <div style="margin-top: 4px;">
                                                                <span class="batch-chip" id="lblBatchPreview">100</span>
                                                            </div>
                                                        </div>
                                                        <div class="col-md-8 col-sm-6 col-xs-12" style="font-size: 12px; color: #475569;">
                                                            <b>Formula Structure:</b>
                                                            <span class="label label-primary" style="font-size:11px; margin-left:5px;">Prefix: <span id="spanPrefixPreview">(none)</span></span>
                                                            <span style="font-weight:bold; margin: 0 4px;">+</span>
                                                            <span class="label label-success" style="font-size:11px;">Serial: <span id="spanSerialPreview">100</span></span>
                                                            <span style="font-weight:bold; margin: 0 4px;">+</span>
                                                            <span class="label label-warning" style="font-size:11px;">Suffix: <span id="spanSuffixPreview">(none)</span></span>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <!-- Item Assignment Options -->
                                        <div class="col-md-12 col-sm-12 col-xs-12" style="margin-top: 10px; padding: 0;">
                                            <div style="background: #f7f9fa; border-left: 4px solid #3498DB; padding: 8px 12px; margin-bottom: 12px; display: flex; justify-content: space-between; align-items: center;">
                                                <label style="font-size: 13px; font-weight: bold; color: #2A3F54; margin: 0;">
                                                    <i class="fa fa-cubes" style="color: #3498DB; margin-right: 6px;"></i>Item Assignment Rules
                                                </label>
                                            </div>

                                            <div style="padding: 5px 15px; margin-bottom: 10px;">
                                                <label class="radio-box">
                                                    <input type="radio" name="assignModeRadio" id="radioAllItems" value="ALL" checked="checked" />
                                                    <b>Assign to All Items</b> <span style="color:#73879C;">(All items in Item Master)</span>
                                                </label>
                                                <label class="radio-box">
                                                    <input type="radio" name="assignModeRadio" id="radioSpecificItems" value="SPECIFIC" />
                                                    <b>Assign to Specific Items</b> <span style="color:#73879C;">(Pick individual items)</span>
                                                </label>
                                                <label class="radio-box" id="divRadioKeep" style="display:none;">
                                                    <input type="radio" name="assignModeRadio" id="radioKeepItems" value="KEEP" />
                                                    <b>Keep Existing Linked Items</b> <span style="color:#26b99a; font-weight:bold;" id="lblKeepCount"></span>
                                                    <button type="button" class="btn btn-warning btn-xs" id="btnManageLinkedItems" onclick="openUnlinkModalForCurrentBatch();" style="margin-left: 10px; font-weight: bold; padding: 2px 8px;" title="Open unlinking window in popup modal">
                                                        <i class="fa fa-chain-broken"></i> Manage / Unlink (<span id="lblBtnUnlinkCount">0</span>)
                                                    </button>
                                                </label>
                                            </div>

                                            <!-- Specific Items Selection Panel -->
                                            <div id="divSpecificItemsPanel" style="display:none; background: #fafafa; border: 1px solid #e2e8f0; border-radius: 4px; padding: 12px 15px; margin-bottom: 15px;">
                                                <div class="row" style="margin-bottom: 10px;">
                                                    <div class="col-md-7 col-sm-8 col-xs-12">
                                                        <input type="text" id="txtItemSearch" class="form-control input-sm" placeholder="Search & add item to batch scheme (Type Code or Name)..." />
                                                    </div>
                                                    <div class="col-md-5 col-sm-4 col-xs-12">
                                                        <button type="button" class="btn btn-info btn-sm" onclick="openCatalogPicker();" style="margin: 0; font-weight: bold;">
                                                            <i class="fa fa-list"></i> Select Items from Catalog
                                                        </button>
                                                        <span class="badge" id="lblAssignedCount" style="background:#3b82f6; font-size:12px; margin-left:10px; padding:6px 10px;">0 Items Assigned</span>
                                                    </div>
                                                </div>

                                                <div class="table-responsive" style="max-height: 250px; overflow-y: auto;">
                                                    <table id="tblAssignedItems" class="table assigned-table table-striped">
                                                        <thead>
                                                            <tr>
                                                                <th style="width:45px; text-align:center;">#</th>
                                                                <th style="width:120px;">Item Code</th>
                                                                <th>Item Name</th>
                                                                <th style="width:160px;">Spec Brand</th>
                                                                <th style="width:50px; text-align:center;">Action</th>
                                                            </tr>
                                                        </thead>
                                                        <tbody>
                                                            <tr>
                                                                <td colspan="5" style="text-align:center; padding:15px; color:#73879C;">
                                                                    <i class="fa fa-info-circle"></i> No specific items added yet. Search above or click "Select Items from Catalog".
                                                                </td>
                                                            </tr>
                                                        </tbody>
                                                    </table>
                                                </div>
                                            </div>

                                            <!-- Inline Linked Items Listbox (Shown when editing a batch that has linked items) -->
                                            <div id="divInlineLinkedSection" style="display:none; background: #fff; border: 1px solid #d2d6de; border-radius: 4px; padding: 12px 15px; margin-bottom: 15px; box-shadow: 0 1px 3px rgba(0,0,0,0.06);">
                                                <div style="display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #e2e8f0; padding-bottom: 8px; margin-bottom: 10px; flex-wrap: wrap;">
                                                    <div style="margin-bottom: 5px;">
                                                        <span style="font-size: 13px; font-weight: bold; color: #2A3F54;">
                                                            <i class="fa fa-chain-broken" style="color: #e67e22; margin-right: 5px;"></i>Currently Linked Items in this Batch Master
                                                        </span>
                                                        <span class="badge" id="lblInlineLinkedCount" style="background:#26b99a; font-size:11px; margin-left:8px;">0 items</span>
                                                        <span class="badge" id="lblInlineSelectedCount" style="background:#d9534f; font-size:11px; margin-left:5px; display:none;">0 selected to unlink</span>
                                                    </div>
                                                    <div style="margin-bottom: 5px;">
                                                        <button type="button" class="btn btn-danger btn-xs" onclick="unlinkSelectedInline();" style="font-weight: bold; margin: 0 3px;">
                                                            <i class="fa fa-trash"></i> Unlink Selected
                                                        </button>
                                                        <button type="button" class="btn btn-dark btn-xs" onclick="unlinkAllInline();" style="font-weight: bold; margin: 0 3px; background-color: #555; color: #fff;">
                                                            <i class="fa fa-chain-broken"></i> Unlink ALL Items
                                                        </button>
                                                    </div>
                                                </div>

                                                <!-- Inline Filter Bar: Search, Spec Brand, Per Page -->
                                                <div class="row" style="margin-bottom: 8px;">
                                                    <div class="col-md-5 col-sm-5 col-xs-12" style="margin-bottom: 5px;">
                                                        <input type="text" id="txtInlineSearch" class="form-control input-sm" placeholder="Search Code, Name, or Print Name..." />
                                                    </div>
                                                    <div class="col-md-4 col-sm-4 col-xs-12" style="margin-bottom: 5px;">
                                                        <select id="comboInlineSpecBrand" class="form-control input-sm" onchange="loadInlineLinkedPage(1);">
                                                            <option value="-1">--All Spec Brands--</option>
                                                        </select>
                                                    </div>
                                                    <div class="col-md-2 col-sm-2 col-xs-8" style="margin-bottom: 5px;">
                                                        <select id="comboInlinePerPage" class="form-control input-sm" onchange="loadInlineLinkedPage(1);" title="Items per page">
                                                            <option value="10">10</option>
                                                            <option value="25" selected="selected">25</option>
                                                            <option value="50">50</option>
                                                            <option value="100">100</option>
                                                            <option value="500">500</option>
                                                            <option value="1000">1000</option>
                                                            <option value="5000">5000</option>
                                                        </select>
                                                    </div>
                                                    <div class="col-md-1 col-sm-1 col-xs-4" style="margin-bottom: 5px;">
                                                        <button type="button" class="btn btn-primary btn-xs" onclick="loadInlineLinkedPage(1);" style="padding: 5px 8px; height: 30px; font-weight: bold; width: 100%;">
                                                            <i class="fa fa-search"></i>
                                                        </button>
                                                    </div>
                                                </div>

                                                <!-- Inline Linked Items Table / Listbox with checkboxes -->
                                                <div class="table-responsive" style="max-height: 320px; overflow-y: auto;">
                                                    <table id="tableInlineLinked" class="table table-bordered table-striped" style="font-size: 12px; margin-bottom: 5px;">
                                                        <thead style="background: #f8fafc;">
                                                            <tr>
                                                                <th style="width: 40px; text-align: center;">
                                                                    <input type="checkbox" id="chkInlineUnlinkAll" onchange="toggleInlineUnlinkSelectAll(this);" title="Select/Deselect all on this page" />
                                                                </th>
                                                                <th style="width: 45px; text-align: center;">#</th>
                                                                <th style="width: 120px;">Item Code</th>
                                                                <th>Item Name</th>
                                                                <th style="width: 160px;">Spec Brand</th>
                                                                <th style="width: 80px; text-align: center;">UOM</th>
                                                                <th style="width: 70px; text-align: center;">Action</th>
                                                            </tr>
                                                        </thead>
                                                        <tbody>
                                                        </tbody>
                                                    </table>
                                                </div>

                                                <div id="inlineLinkedPagination" style="text-align: center; margin-top: 8px;"></div>
                                            </div>
                                        </div>

                                        <div class="ln_solid" style="margin: 15px 0;"></div>

                                        <!-- Form Buttons -->
                                        <div class="form-group" style="margin-bottom: 5px;">
                                            <div class="col-md-12 col-sm-12 col-xs-12" style="text-align: right;">
                                                <div id="btnBatchMasterAction" style="display: inline-block;">
                                                    <div class="btn btn-success fl mybtnstyl" onclick="javascript:saveBatchMasterDetails();">
                                                        <i class="fa fa-save"></i> SAVE BATCH MASTER
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

                    <!-- SECTION 2: BATCH MASTER DIRECTORY / LIST -->
                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12" id="DivSearchBatchMaster">
                            <div class="x_panel">
                                <div class="x_title">
                                    <label style="font-size: 15px; color: #2A3F54;">
                                        <i class="fa fa-tags" style="color: #3498DB; margin-right: 6px;"></i>Manage Batch Masters
                                    </label>
                                    <span class="badge" style="color: #fff; margin-left: 8px; background: #3498DB; padding: 4px 8px;" id="lblTotalRecords">0</span>
                                    <div class="clearfix"></div>
                                </div>

                                <div class="x_content">
                                    <form class="form-horizontal form-label-left">
                                        <!-- Search Filter Row -->
                                        <div class="row" style="margin-bottom: 10px;">
                                            <div class="col-md-4 col-sm-4 col-xs-12 form-group">
                                                <label style="font-size: 11px; margin-bottom: 2px; color: #73879C;">Batch Pattern / Prefix / Suffix</label>
                                                <input type="text" class="form-control input-sm" id="txtSearchPattern" placeholder="Search Prefix, Suffix, or Format..." />
                                            </div>

                                            <div class="col-md-4 col-sm-4 col-xs-12 form-group">
                                                <label style="font-size: 11px; margin-bottom: 2px; color: #73879C;">Linked Item (Code or Name)</label>
                                                <input type="text" class="form-control input-sm" id="txtSearchItem" placeholder="Search Item Code or Name..." />
                                            </div>

                                            <div class="col-md-4 col-sm-4 col-xs-12 form-group" style="padding-top: 18px;">
                                                <button type="button" class="btn btn-success btn-xs" onclick="javascript:searchBatchMasterList(1);" style="padding: 5px 12px; height: 30px; font-weight: bold;">
                                                    <i class="fa fa-search"></i> Search
                                                </button>
                                                <button type="button" class="btn btn-primary btn-xs" onclick="javascript:resetSearch();" style="padding: 5px 10px; height: 30px;" title="Reset Filters">
                                                    <i class="fa fa-refresh"></i> Reset
                                                </button>
                                                <button type="button" id="btnDownloadBatchExcel" class="btn btn-success btn-xs" onclick="downloadBatchMasterExcel();" style="padding: 5px 12px; height: 30px; background-color: #26b99a; border-color: #26b99a; font-weight: bold;" title="Download Batch Masters in Excel sheet">
                                                    <i class="fa fa-file-excel-o"></i> Download Excel
                                                </button>

                                                <select class="input-sm pull-right" id="txtpageno" onchange="javascript:searchBatchMasterList(1);" style="height: 30px; width: 70px;">
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

                                    <!-- Table -->
                                    <div class="table-responsive" style="overflow-x: auto;">
                                        <table id="tableBatchMasterList" class="table table-striped jambo_table bulk_action" style="table-layout: auto;">
                                            <thead style="background-color: #f1eeee; color: #525252;">
                                                <tr>
                                                    <th style="width: 45px; text-align: center;">#</th>
                                                    <th style="width: 80px; text-align: center;">ID</th>
                                                    <th>Prefix</th>
                                                    <th style="text-align: center; width: 110px;">Current Serial</th>
                                                    <th>Suffix</th>
                                                    <th>Sample Batch Number Format</th>
                                                    <th style="text-align: center; width: 140px;">Assigned Items</th>
                                                    <th style="width: 120px; text-align: center;">Action</th>
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

            <!-- MODAL 1: VIEW ASSIGNED ITEMS MODAL -->
            <div class="modal fade" id="modalViewAssignedItems" tabindex="-1" role="dialog" aria-hidden="true">
                <div class="modal-dialog modal-lg">
                    <div class="modal-content">
                        <div class="modal-header" style="background: #2A3F54; color: white; padding: 12px 15px;">
                            <button type="button" class="close" data-dismiss="modal" style="color: white; opacity: 0.9;">&times;</button>
                            <h4 class="modal-title" style="font-size: 15px;">
                                <i class="fa fa-cubes" style="margin-right: 6px;"></i><span id="modalViewTitle" style="font-weight: bold;">Assigned Items</span>
                                <span class="badge" style="background: #3498DB; font-size: 11px; margin-left: 8px;" id="lblModalTotalCount">0</span>
                                <span class="badge" style="background: #d9534f; font-size: 11px; margin-left: 5px; display: none;" id="lblModalSelectedCount">0 selected</span>
                            </h4>
                        </div>
                        <div class="modal-body" style="padding: 15px;">
                            <!-- Search & Filter Row in Modal with Per Page and Unlink action buttons -->
                            <div class="row" style="margin-bottom: 10px;">
                                <div class="col-md-4 col-sm-4 col-xs-12" style="margin-bottom: 5px;">
                                    <input type="text" id="txtViewSearch" class="form-control input-sm" placeholder="Search Code, Name, or Print Name..." />
                                </div>
                                <div class="col-md-3 col-sm-3 col-xs-12" style="margin-bottom: 5px;">
                                    <select id="comboViewSpecBrand" class="form-control input-sm" onchange="loadAssignedItemsPage(1);">
                                        <option value="-1">--All Spec Brands--</option>
                                    </select>
                                </div>
                                <div class="col-md-2 col-sm-2 col-xs-6" style="margin-bottom: 5px;">
                                    <select id="comboViewPerPage" class="form-control input-sm" onchange="loadAssignedItemsPage(1);" title="Items per page">
                                        <option value="10">10</option>
                                        <option value="25" selected="selected">25</option>
                                        <option value="50">50</option>
                                        <option value="100">100</option>
                                        <option value="500">500</option>
                                        <option value="1000">1000</option>
                                        <option value="5000">5000</option>
                                    </select>
                                </div>
                                <div class="col-md-3 col-sm-3 col-xs-6 text-right" style="margin-bottom: 5px;">
                                    <button type="button" class="btn btn-primary btn-xs" onclick="loadAssignedItemsPage(1);" style="padding: 5px 8px; height: 30px;">
                                        <i class="fa fa-search"></i> Filter
                                    </button>
                                    <button type="button" class="btn btn-danger btn-xs" onclick="unlinkSelectedAssignedItems();" style="padding: 5px 8px; height: 30px; font-weight: bold;">
                                        <i class="fa fa-trash"></i> Unlink Selected
                                    </button>
                                </div>
                            </div>

                            <div class="table-responsive" style="max-height: 380px; overflow-y: auto;">
                                <table id="tableModalAssigned" class="table table-bordered table-striped" style="font-size: 12px;">
                                    <thead style="background: #f1f5f9;">
                                        <tr>
                                            <th style="width: 40px; text-align: center;">
                                                <input type="checkbox" id="chkModalUnlinkAll" onchange="toggleModalUnlinkSelectAll(this);" title="Select/Deselect all on this page" />
                                            </th>
                                            <th style="width: 45px; text-align: center;">#</th>
                                            <th style="width: 110px;">Item Code</th>
                                            <th>Item Name</th>
                                            <th style="width: 160px;">Spec Brand</th>
                                            <th style="width: 80px; text-align: center;">Sales UOM</th>
                                            <th style="width: 70px; text-align: center;">Action</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                    </tbody>
                                </table>
                            </div>

                            <div id="modalViewPagination" style="text-align: center; margin-top: 10px;"></div>
                        </div>
                        <div class="modal-footer" style="padding: 10px 15px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap;">
                            <div>
                                <button type="button" class="btn btn-dark btn-sm" onclick="unlinkAllAssignedItems();" style="font-weight: bold; background: #555; color: white;">
                                    <i class="fa fa-chain-broken"></i> Unlink ALL Items From Batch
                                </button>
                            </div>
                            <div>
                                <button type="button" class="btn btn-default btn-sm" data-dismiss="modal">Close</button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- MODAL 2: CATALOG PICKER MODAL -->
            <div class="modal fade" id="modalCatalogPicker" tabindex="-1" role="dialog" aria-hidden="true">
                <div class="modal-dialog modal-lg">
                    <div class="modal-content">
                        <div class="modal-header" style="background: #2A3F54; color: white; padding: 12px 15px;">
                            <button type="button" class="close" data-dismiss="modal" style="color: white; opacity: 0.9;">&times;</button>
                            <h4 class="modal-title" style="font-size: 15px;">
                                <i class="fa fa-list-alt" style="margin-right: 6px;"></i>Select Items from Item Master Catalog
                                <span class="badge" style="background: #3498DB; font-size: 11px; margin-left: 8px;" id="lblCatalogTotalCount">0</span>
                            </h4>
                        </div>
                        <div class="modal-body" style="padding: 15px;">
                            <!-- Filter row: Search, Spec Brand, Per Page -->
                            <div class="row" style="margin-bottom: 10px;">
                                <div class="col-md-4 col-sm-4 col-xs-12">
                                    <input type="text" id="txtCatalogSearch" class="form-control input-sm" placeholder="Search Item Code, Name, or Spec Brand..." />
                                </div>
                                <div class="col-md-4 col-sm-4 col-xs-12">
                                    <select id="comboCatalogSpecBrand" class="form-control input-sm" onchange="loadCatalogItemsPage(1);">
                                        <option value="-1">--All Spec Brands--</option>
                                    </select>
                                </div>
                                <div class="col-md-2 col-sm-2 col-xs-6">
                                    <select id="comboCatalogPerPage" class="form-control input-sm" onchange="loadCatalogItemsPage(1);" title="Items per page">
                                        <option value="10">10</option>
                                        <option value="25" selected="selected">25</option>
                                        <option value="50">50</option>
                                        <option value="100">100</option>
                                        <option value="500">500</option>
                                        <option value="1000">1000</option>
                                        <option value="5000">5000</option>
                                    </select>
                                </div>
                                <div class="col-md-2 col-sm-2 col-xs-6">
                                    <button type="button" class="btn btn-primary btn-xs" onclick="loadCatalogItemsPage(1);" style="padding: 5px 12px; height: 30px; font-weight: bold; width: 100%;">
                                        <i class="fa fa-search"></i> Filter
                                    </button>
                                </div>
                            </div>

                            <div class="table-responsive" style="max-height: 380px; overflow-y: auto;">
                                <table id="tableCatalogItems" class="table table-bordered table-striped" style="font-size: 12px;">
                                    <thead style="background: #f1f5f9;">
                                        <tr>
                                            <th style="width: 40px; text-align: center;">
                                                <input type="checkbox" id="chkCatalogSelectAll" onchange="toggleCatalogSelectAll(this);" title="Select All on this page" />
                                            </th>
                                            <th style="width: 120px;">Item Code</th>
                                            <th>Item Name</th>
                                            <th style="width: 180px;">Spec Brand</th>
                                            <th style="width: 80px; text-align: center;">UOM</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                    </tbody>
                                </table>
                            </div>

                            <div id="modalCatalogPagination" style="text-align: center; margin-top: 10px;"></div>
                        </div>
                        <div class="modal-footer" style="padding: 10px 15px;">
                            <button type="button" class="btn btn-success btn-sm" onclick="addSelectedCatalogItems();" style="font-weight: bold;">
                                <i class="fa fa-check"></i> Add Selected Items
                            </button>
                            <button type="button" class="btn btn-default btn-sm" data-dismiss="modal">Cancel</button>
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
