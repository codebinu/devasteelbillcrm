<%@ Page Language="C#" AutoEventWireup="true" CodeFile="itemmasterspec.aspx.cs" Inherits="web_inventory_itemmasterspec" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Item Master Spec | Invoice Me</title>

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

    <script type="text/javascript">
        var currentSpecId = 0;
        var currentAction = "insert";
        var editingTypeId = 0;

        $(document).ready(function () {
            var BranchId = $.cookie("invntrystaffBranchId");
            var CountryId = $.cookie("invntrystaffCountryId");

            clearform();
            loadSpecTypes();
            loadSearchSpecTypes();
            searchSpecList(1);

            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " © ");

            $("#txtSpecSeq").keypress(function (e) {
                if (e.which != 8 && e.which != 0 && (e.which < 48 || e.which > 57)) {
                    $("#errmsgSeq").html("Digits Only").show().fadeOut("slow");
                    return false;
                }
            });

            $("#txtSearchSpec").keypress(function (e) {
                if (e.which == 13) {
                    searchSpecList(1);
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
        // Stop: Replace single quotes with double quotes

        // Load Spec Types for Form Dropdown
        function loadSpecTypes(selectedVal) {
            loading();
            $.ajax({
                type: "POST",
                url: "itemmasterspec.aspx/showSpecTypes",
                data: "{}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d == "") {
                        alert("Error loading specification types!");
                        return;
                    }
                    $("#comboSpecType").html(msg.d);
                    if (selectedVal !== undefined && selectedVal > 0) {
                        $("#comboSpecType").val(selectedVal);
                    }
                },
                error: function () {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }

        // Load Spec Types for Search Dropdown
        function loadSearchSpecTypes(selectedVal) {
            loading();
            $.ajax({
                type: "POST",
                url: "itemmasterspec.aspx/showSearchSpecTypes",
                data: "{}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d == "") {
                        alert("Error loading specification types for search!");
                        return;
                    }
                    $("#combosearchSpecType").html(msg.d);
                    if (selectedVal !== undefined && selectedVal > 0) {
                        $("#combosearchSpecType").val(selectedVal);
                    }
                },
                error: function () {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }

        // Auto-fetch Next Sequence on Type Selection
        function onSpecTypeChange() {
            var typeId = $("#comboSpecType").val();
            if (typeId != "-1" && currentAction == "insert") {
                loading();
                $.ajax({
                    type: "POST",
                    url: "itemmasterspec.aspx/getNextSeq",
                    data: JSON.stringify({ typeId: parseInt(typeId) }),
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (msg) {
                        Unloading();
                        $("#txtSpecSeq").val(msg.d);
                    },
                    error: function () {
                        Unloading();
                    }
                });
            }
        }

        // Add or Update Specification Value
        function addSpecDetails(actionType, specId) {
            sqlInjection();
            var specType = $("#comboSpecType").val();
            var specSeq = $("#txtSpecSeq").val();
            var specValue = $("#txtSpecValue").val().trim();

            if (specType == "-1" || specType == "" || specType == "0") {
                alert("Please select a Specification Type");
                $("#comboSpecType").focus();
                return;
            }

            if (specSeq == "" || parseInt(specSeq) < 0) {
                alert("Please enter a valid Sequence Number (0 or greater)");
                $("#txtSpecSeq").focus();
                return;
            }

            if (specValue == "") {
                alert("Please enter Specification Value");
                $("#txtSpecValue").focus();
                return;
            }

            loading();
            $.ajax({
                type: "POST",
                url: "itemmasterspec.aspx/addSpecValue",
                data: JSON.stringify({
                    actionType: actionType,
                    specId: specId ? specId.toString() : "0",
                    typeId: parseInt(specType),
                    seq: parseInt(specSeq),
                    specValue: specValue
                }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d == "E") {
                        alert("Specification Value already exists for this Specification Type!");
                        return;
                    }
                    if (msg.d == "Y") {
                        if (actionType == "insert") {
                            alert("Specification Value Added Successfully");
                        } else {
                            alert("Specification Value Updated Successfully");
                        }
                        var savedType = specType;
                        clearform();
                        $("#comboSpecType").val(savedType);
                        onSpecTypeChange();
                        searchSpecList(1);
                        return;
                    }
                    alert("Operation failed: " + msg.d);
                },
                error: function () {
                    Unloading();
                    alert("Internet Problem");
                }
            });
        }

        // Search Specification Values List
        function searchSpecList(page) {
            sqlInjection();
            var filters = {};

            if ($("#txtSearchSpec").val() !== undefined && $("#txtSearchSpec").val() != "") {
                filters.search = $("#txtSearchSpec").val().trim();
            }

            if ($("#combosearchSpecType").val() !== undefined && $("#combosearchSpecType").val() != "-1") {
                filters.typeId = $("#combosearchSpecType").val();
            }

            var perpage = $("#txtpageno").val();

            loading();
            $.ajax({
                type: "POST",
                url: "itemmasterspec.aspx/searchSpecList",
                data: JSON.stringify({
                    page: page,
                    filters: filters,
                    perpage: parseInt(perpage)
                }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d == "N") {
                        $("#divSearchSpecTable tbody").html('<tr><td colspan="6" style="padding:15px; text-align:center; font-weight:bold; background:#f9f9f9;">Nothing Found...</td></tr>');
                        $("#paginatediv").html('');
                        $("#lblTotalrerd").text(0);
                    } else {
                        var obj = JSON.parse(msg.d);
                        var htm = "";
                        $("#lblTotalrerd").text(obj.count);

                        $.each(obj.data, function (i, row) {
                            htm += "<tr style='cursor:pointer; font-size:12px;' id='specRow" + i + "'>";
                            htm += "<td>" + row.itsv_id + "</td>";
                            htm += "<td><b>" + row.itst_name + "</b></td>";
                            htm += "<td style='text-align:center;'><span class='badge' style='background:#2A3F54; padding:3px 7px;'>" + row.itsv_seq + "</span></td>";
                            htm += "<td><b>" + getHighlightedValue(filters.search, row.itsv_name) + "</b></td>";
                            htm += "<td>" + (row.last_update ? row.last_update : "-") + "</td>";
                            htm += "<td style='text-align:center;'>";
                            htm += '<div class="btn btn-primary btn-xs" title="Edit Specification" onclick="javascript:editSpecDetails(' + row.itsv_id + ');">';
                            htm += '<li class="fa fa-pencil" style="font-size:13px;"></li> Edit';
                            htm += '</div> ';
                            htm += '<div class="btn btn-danger btn-xs" title="Delete Specification" onclick="javascript:deleteSpecValue(' + row.itsv_id + ');">';
                            htm += '<li class="fa fa-trash" style="font-size:13px;"></li>';
                            htm += '</div>';
                            htm += '</td>';
                            htm += "</tr>";
                        });

                        htm += '<tr>';
                        htm += '<td colspan="6">';
                        htm += '<div id="paginatediv" style="text-align: center; margin-top:10px;">';
                        htm += '</div>';
                        htm += '</td>';
                        htm += '</tr>';

                        $("#divSearchSpecTable tbody").html(htm);
                        $("#paginatediv").html(paginate(obj.count, perpage, page, "searchSpecList"));
                    }
                },
                error: function () {
                    Unloading();
                    alert("Internet Problem");
                }
            });
        }

        // Edit Specification Value Details
        function editSpecDetails(id) {
            currentSpecId = id;
            currentAction = "update";
            loading();
            $.ajax({
                type: "POST",
                url: "itemmasterspec.aspx/editSpecDetails",
                data: JSON.stringify({ specId: id.toString() }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    var obj = JSON.parse(msg.d);
                    if (obj && obj.length > 0) {
                        $("#comboSpecType").val(obj[0].itst_id);
                        $("#txtSpecSeq").val(obj[0].itsv_seq);
                        $("#txtSpecValue").val(obj[0].itsv_name);

                        $("#btnSpecAction").html("<div class='btn btn-success mybtnstyl' onclick='javascript:addSpecDetails(\"update\", " + obj[0].itsv_id + ");'>UPDATE</div>");

                        $('html,body').animate({
                            scrollTop: $('#DivSpecDetails').offset().top
                        }, 500);
                    }
                },
                error: function () {
                    Unloading();
                    alert("Internet Problem");
                }
            });
        }

        // Delete Specification Value
        function deleteSpecValue(id) {
            if (confirm("Are you sure you want to delete this specification value?")) {
                loading();
                $.ajax({
                    type: "POST",
                    url: "itemmasterspec.aspx/deleteSpecValue",
                    data: JSON.stringify({ specId: id.toString() }),
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (msg) {
                        Unloading();
                        if (msg.d == "Y") {
                            alert("Specification Value deleted successfully");
                            searchSpecList(1);
                        } else {
                            alert("Failed to delete specification value: " + msg.d);
                        }
                    },
                    error: function () {
                        Unloading();
                        alert("Internet Problem");
                    }
                });
            }
        }

        // Reset Search Filters
        function resetSearch() {
            $("#txtSearchSpec").val('');
            $("#combosearchSpecType").val(-1);
            searchSpecList(1);
        }

        // Clear Form to Insert Mode
        function clearform() {
            currentSpecId = 0;
            currentAction = "insert";
            $("#btnSpecAction").html("<div class='btn btn-success fl mybtnstyl' onclick='javascript:addSpecDetails(\"insert\", 0);'>SAVE</div>");
            $("#comboSpecType").val(-1);
            $("#txtSpecSeq").val(1);
            $("#txtSpecValue").val('');
        }

        // Modal for Managing Spec Types
        function openManageTypesModal() {
            editingTypeId = 0;
            $("#txtNewTypeName").val('');
            $("#btnSaveType").text("Add Type");
            $("#popupManageTypes").modal('show');
            loadManageTypesTable();
        }

        function popupclose(modalId) {
            $("#" + modalId).modal('hide');
        }

        function loadManageTypesTable() {
            loading();
            $.ajax({
                type: "POST",
                url: "itemmasterspec.aspx/getSpecTypesList",
                data: "{}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    var data = JSON.parse(msg.d);
                    $("#lblTypeTotalrecords").text(data.length);
                    var htm = "";
                    $.each(data, function (i, row) {
                        htm += "<tr>";
                        htm += "<td>" + row.itst_id + "</td>";
                        htm += "<td><b>" + row.itst_name + "</b></td>";
                        htm += "<td style='text-align:center;'><span class='badge' style='background:#1ABB9C;'>" + row.value_count + "</span></td>";
                        htm += "<td>" + (row.last_update ? row.last_update : "-") + "</td>";
                        htm += "<td style='text-align:center;'>";
                        htm += "<div class='btn btn-primary btn-xs' title='Edit Type' onclick='javascript:editQuickType(" + row.itst_id + ", \"" + row.itst_name.replace(/"/g, '&quot;') + "\");'><i class='fa fa-pencil'></i></div> ";
                        if (row.value_count == 0) {
                            htm += "<div class='btn btn-danger btn-xs' title='Delete Type' onclick='javascript:deleteQuickType(" + row.itst_id + ");'><i class='fa fa-trash'></i></div>";
                        } else {
                            htm += "<div class='btn btn-default btn-xs' disabled title='Cannot delete type with values'><i class='fa fa-lock'></i></div>";
                        }
                        htm += "</td>";
                        htm += "</tr>";
                    });
                    $("#tblManageTypes tbody").html(htm);
                },
                error: function () {
                    Unloading();
                    alert("Internet Problem");
                }
            });
        }

        function editQuickType(id, name) {
            editingTypeId = id;
            $("#txtNewTypeName").val(name);
            $("#btnSaveType").text("Update Type");
            $("#txtNewTypeName").focus();
        }

        function saveQuickType() {
            var typeName = $("#txtNewTypeName").val().trim();
            if (typeName == "") {
                alert("Please enter Specification Type Name");
                $("#txtNewTypeName").focus();
                return;
            }

            var action = editingTypeId > 0 ? "update" : "insert";
            loading();
            $.ajax({
                type: "POST",
                url: "itemmasterspec.aspx/saveSpecType",
                data: JSON.stringify({
                    actionType: action,
                    typeId: editingTypeId.toString(),
                    typeName: typeName
                }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d == "E") {
                        alert("Specification Type already exists!");
                        return;
                    }
                    if (msg.d == "Y") {
                        alert(action == "insert" ? "Specification Type Added Successfully" : "Specification Type Updated Successfully");
                        $("#txtNewTypeName").val('');
                        editingTypeId = 0;
                        $("#btnSaveType").text("Add Type");
                        loadManageTypesTable();
                        loadSpecTypes();
                        loadSearchSpecTypes();
                        return;
                    }
                    alert("Failed: " + msg.d);
                },
                error: function () {
                    Unloading();
                    alert("Internet Problem");
                }
            });
        }

        function deleteQuickType(typeId) {
            if (confirm("Are you sure you want to delete this Specification Type?")) {
                loading();
                $.ajax({
                    type: "POST",
                    url: "itemmasterspec.aspx/deleteSpecType",
                    data: JSON.stringify({ typeId: typeId.toString() }),
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (msg) {
                        Unloading();
                        if (msg.d == "HAS_VALUES") {
                            alert("Cannot delete this Specification Type because it has associated values!");
                            return;
                        }
                        if (msg.d == "Y") {
                            alert("Specification Type deleted successfully");
                            loadManageTypesTable();
                            loadSpecTypes();
                            loadSearchSpecTypes();
                            return;
                        }
                        alert("Failed to delete type: " + msg.d);
                    },
                    error: function () {
                        Unloading();
                        alert("Internet Problem");
                    }
                });
            }
        }
    </script>
    <style>
        #errmsgSeq {
            color: red;
            font-size: 11px;
            margin-left: 5px;
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
                            <span>Invoice Me</span>
                        </a>
                    </div>

                    <div class="clearfix"></div>

                    <!-- menu profile quick info -->
                    <div class="profile clearfix">
                        <div class="profile_pic"></div>
                        <div class="profile_info"></div>
                    </div>
                    <!-- /menu profile quick info -->

                    <br />

                    <!-- sidebar menu -->
                    <div id="sidebar-menu" class="main_menu_side hidden-print main_menu">
                    </div>
                    <!-- /sidebar menu -->

                    <!-- menu footer buttons -->
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
                            <div class="col-md-4 col-xs-4">
                                <label style="font-weight: bold; font-size: 16px;">Item Master Spec</label>
                            </div>
                            <div class="col-md-8 col-xs-8 text-right">
                                <div onclick="javascript:clearform();" class="btn btn-primary btn-xs pull-right" style="margin-top: 5px; margin-left: 6px;">
                                    <label style="color: #fff; margin-right: 5px; font-size: 14px;" class="fa fa-plus-square"></label>Create New Spec Value
                                </div>
                                <div onclick="javascript:openManageTypesModal();" class="btn btn-info btn-xs pull-right" style="margin-top: 5px;">
                                    <label style="color: #fff; margin-right: 5px; font-size: 14px;" class="fa fa-list"></label>Manage Spec Types
                                </div>
                            </div>
                        </div>
                    </nav>
                </div>
            </div>
            <!-- /top navigation -->

            <!-- page content -->
            <div class="right_col" role="main">
                <div class="">
                    <div class="clearfix"></div>

                    <!-- Basic Details Form Row -->
                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12" id="DivSpecDetails">
                            <div class="x_panel">
                                <div class="x_title" style="margin-bottom: 0px;">
                                    <label>Specification Value Details</label>
                                    <ul class="nav navbar-right panel_toolbox">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a></li>
                                    </ul>
                                </div>
                                <div class="x_content">
                                    <br />
                                    <form id="spec-form" data-parsley-validate class="form-horizontal form-label-left">
                                        
                                        <!-- Spec Type -->
                                        <div class="form-group">
                                            <label class="control-label col-md-3 col-sm-3 col-xs-12" for="comboSpecType">
                                                Specification Type<span class="required">*</span>
                                            </label>
                                            <div class="col-md-6 col-sm-6 col-xs-11">
                                                <select class="form-control" id="comboSpecType" onchange="javascript:onSpecTypeChange();">
                                                    <option value="-1">--Select Spec Type--</option>
                                                </select>
                                            </div>
                                            <div class="col-md-1 col-sm-1 col-xs-1" style="padding-left: 0px; padding-top: 5px;">
                                                <div style="font-size: 20px;" onclick="javascript:openManageTypesModal();" title="Add / Manage Spec Types">
                                                    <label class="fa fa-plus-square" style="color: #ff6a00; cursor: pointer;"></label>
                                                </div>
                                            </div>
                                        </div>

                                        <!-- Sequence -->
                                        <div class="form-group">
                                            <label class="control-label col-md-3 col-sm-3 col-xs-12" for="txtSpecSeq">
                                                Sequence No.<span class="required">*</span>
                                            </label>
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <input type="number" id="txtSpecSeq" placeholder="Enter Sequence No." required="required" class="form-control col-md-7 col-xs-12" value="1" min="0" />
                                                <span id="errmsgSeq"></span>
                                            </div>
                                        </div>

                                        <!-- Spec Value -->
                                        <div class="form-group">
                                            <label class="control-label col-md-3 col-sm-3 col-xs-12" for="txtSpecValue">
                                                Specification Value<span class="required">*</span>
                                            </label>
                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                <input type="text" id="txtSpecValue" placeholder="Enter Specification Value (e.g. 0.45MM, RED, NOS)" required="required" class="form-control col-md-7 col-xs-12" />
                                            </div>
                                        </div>

                                    </form>

                                    <div class="clearfix"></div>
                                    <div class="ln_solid"></div>
                                    <div class="form-group" style="padding-bottom: 20px;">
                                        <div class="col-md-6 col-sm-6 col-xs-12 col-md-offset-5">
                                            <div id="btnSpecAction">
                                                <div class="btn btn-success mybtnstyl" onclick="javascript:addSpecDetails('insert', 0);">SAVE</div>
                                            </div>
                                            <div onclick="javascript:clearform();" class="btn btn-danger mybtnstyl">CANCEL</div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="clearfix"></div>

                    <!-- Search and Listing Row -->
                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title" style="margin-bottom: 5px;">
                                    <label>Specification Values <span class="badge" style="color: #fff; margin-left: 5px; background: #d00101; padding-left: 5px; padding-right: 5px;" id="lblTotalrerd">0</span></label>
                                    <ul class="nav navbar-right panel_toolbox">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a></li>
                                    </ul>
                                </div>

                                <div class="x_content" style="padding-bottom: 0px;">
                                    <form class="form-horizontal form-label-left input_mask" onsubmit="return false;">
                                        <div class="col-md-12 col-sm-12 col-xs-12 form-group has-feedback" style="margin-bottom: 5px;">
                                            
                                            <!-- Spec Type Filter -->
                                            <div class="col-md-3 col-sm-4 col-xs-12 form-group has-feedback">
                                                <select class="form-control" style="text-indent: 25px;" id="combosearchSpecType" onchange="javascript:searchSpecList(1);">
                                                    <option value="-1">--All Spec Types--</option>
                                                </select>
                                                <span class="fa fa-filter form-control-feedback left" aria-hidden="true"></span>
                                            </div>

                                            <!-- Search Value Input -->
                                            <div class="col-md-4 col-sm-5 col-xs-8" style="padding-right: 0px;">
                                                <div class="input-group">
                                                    <input type="text" class="form-control" id="txtSearchSpec" placeholder="Search spec value or sequence" style="height: 30px; padding-right: 2px;" />
                                                    <span class="input-group-btn" title="Search">
                                                        <button type="button" class="btn btn-default" onclick="javascript:searchSpecList(1);" style="padding: 4px 12px;">
                                                            <i class="fa fa-search" title="Search"></i>
                                                        </button>
                                                    </span>
                                                </div>
                                            </div>

                                            <!-- Reset Button -->
                                            <div class="col-md-1 col-sm-1 col-xs-2" style="padding-left: 10px;" onclick="javascript:resetSearch();">
                                                <a class="btn btn-primary btn-xs" style="text-align: center; background: #337ab7; border-color: #2e6da4;" title="Reset">
                                                    <li class="fa fa-refresh" style="padding: 3px; font-size: 17px; color: white; margin-top: 0px;"></li>
                                                </a>
                                            </div>

                                            <!-- Page Size Select -->
                                            <ul class="nav navbar-right panel_toolbox">
                                                <li>
                                                    <select class="input-sm" id="txtpageno" onchange="javascript:searchSpecList(1);">
                                                        <option value="25">25</option>
                                                        <option value="50">50</option>
                                                        <option value="100">100</option>
                                                        <option value="250">250</option>
                                                        <option value="500">500</option>
                                                    </select>
                                                </li>
                                            </ul>

                                        </div>
                                    </form>
                                </div>

                                <div class="clearfix"></div>
                                <div class="ln_solid" style="margin-top: 0px;"></div>

                                <!-- Specification Values Table -->
                                <div id="divSearchSpecContainer" class="col-md-12 col-sm-12 col-xs-12" style="overflow-x: auto;">
                                    <div class="x_content">
                                        <table id="divSearchSpecTable" class="table table-striped jambo_table bulk_action" style="table-layout: auto;">
                                            <thead style="background-color: #f1eeee; color: #525252">
                                                <tr>
                                                    <th style="width: 60px;">ID</th>
                                                    <th>Specification Type</th>
                                                    <th style="width: 90px; text-align: center;">Seq</th>
                                                    <th>Specification Value</th>
                                                    <th style="width: 170px;">Last Updated</th>
                                                    <th style="width: 120px; text-align: center;">Action</th>
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

                    <!-- Modal for Managing Spec Types -->
                    <div class="modal fade" id="popupManageTypes" role="dialog">
                        <div class="modal-dialog modal-lg">
                            <div class="modal-content">
                                <div class="modal-header">
                                    <button type="button" class="close" onclick="javascript:popupclose('popupManageTypes');">&times;</button>
                                    <h4 class="modal-title">
                                        Specification Types 
                                        <span class="badge" style="color: #fff; margin-left: 5px; background: #d00101; padding-left: 5px; padding-right: 5px;" id="lblTypeTotalrecords">0</span>
                                    </h4>
                                </div>
                                <div class="modal-body">
                                    <!-- Quick Add / Edit Spec Type -->
                                    <div class="row" style="margin-bottom: 15px;">
                                        <div class="col-md-8 col-sm-8 col-xs-12">
                                            <div class="input-group">
                                                <input type="text" id="txtNewTypeName" class="form-control" placeholder="Enter Specification Type Name (e.g. colour, thickness, brand)" />
                                                <span class="input-group-btn">
                                                    <button type="button" id="btnSaveType" class="btn btn-success" onclick="javascript:saveQuickType();">
                                                        Add Type
                                                    </button>
                                                </span>
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-sm-4 col-xs-12 text-right">
                                            <button type="button" class="btn btn-default" onclick="javascript:loadManageTypesTable();">
                                                <i class="fa fa-refresh"></i> Refresh
                                            </button>
                                        </div>
                                    </div>

                                    <!-- Table of Types -->
                                    <div style="max-height: 400px; overflow-y: auto;">
                                        <table id="tblManageTypes" class="table table-striped table-bordered">
                                            <thead style="background: #2A3F54; color: #fff;">
                                                <tr>
                                                    <th style="width: 60px;">ID</th>
                                                    <th>Type Name</th>
                                                    <th style="width: 110px; text-align: center;">Total Values</th>
                                                    <th style="width: 170px;">Last Updated</th>
                                                    <th style="width: 100px; text-align: center;">Action</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                                <div class="modal-footer">
                                    <button type="button" class="btn btn-default" onclick="javascript:popupclose('popupManageTypes');">Close</button>
                                </div>
                            </div>
                        </div>
                    </div>
                    <!-- /Modal -->

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

    <!-- Bootstrap & Plugins -->
    <script src="../js/bootstrap/bootstrap.min.js"></script>
    <script src="../js/bootstrap/nprogress.js"></script>
    <script src="../js/bootstrap/custom.min.js"></script>
    <script src="../js/bootbox.min.js"></script>
</body>
</html>
