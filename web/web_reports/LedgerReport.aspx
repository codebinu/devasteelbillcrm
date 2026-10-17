<%@ Page Language="C#" AutoEventWireup="true" CodeFile="LedgerReport.aspx.cs" Inherits="web_reports_Item_LedgerReport" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Ledger Report  | Invoice Me</title>

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

        var sel_src_customer = -1;
        var sel_src_customer_name = -1;

        $(document).ready(function () {

            var BranchId = $.cookie("invntrystaffBranchId");
            var CountryId = $.cookie("invntrystaffCountryId");
            $("#txtitemcountry").val("0");
            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " © ");

            var yyyy = new Date().getFullYear();
            var curr_date = new Date().getDate();
            $('#Text_date_from').scroller({
                preset: 'date',
                endYear: yyyy + 100,
                setText: 'Next',
                invalid: {},
                theme: 'ios',
                display: 'modal',
                mode: 'scroller',
                dateFormat: 'dd-mm-yy'
                // dateFormat: 'dd-MM-yy'
            });

            $('#Text_date_to').scroller({
                preset: 'date',
                endYear: yyyy + 100,
                setText: 'Next',
                invalid: {},
                theme: 'ios',
                display: 'modal',
                mode: 'scroller',
                dateFormat: 'dd-mm-yy'
                // dateFormat: 'dd-MM-yy'
            });

            search_src_item();            
            $("#supplierChecks").hide();
            $("#customerChecks").show();

        });

        function change_everything() {

            sel_src_customer == -1;
            var sel_src_customer_name = -1;
            reset_all_data();
            if ($("#change_type").val() == "1") {

                $("#supplierChecks").hide();
                $("#customerChecks").show();
            }
            else {
                $("#supplierChecks").show();
                $("#customerChecks").hide();
            }
        }

        function sqlInjection() {

            $('input, select, textarea').each(
                function (index) {
                    var input = $(this);
                    var type = this.type ? this.type : this.nodeName.toLowerCase();
                    if (type == "text" || type == "textarea") {

                        $("#" + input.attr('id')).val(input.val().replace(/'/g, '"'));
                    }
                    else {
                    }
                }
            );
        }

        function loadEntity() {

            $.ajax({
                type: "POST",
                contentType: "application/json; charset=utf-8",
                url: "LedgerReport.aspx/showSelectedEntity",
                data: "{'type_id':'" + $("#change_type").val() + "','id':'" + sel_src_customer + "'}",
                dataType: "json",
                success: function (data) {

                    var entity = JSON.parse(data.d);

                    if (!entity || entity.length === 0) {
                        $("#entityDetails").html("<div>No details found.</div>");
                        return;
                    }

                    var item = entity[0];
                    var html = "";

                    if ($("#change_type").val() == "1") {
                        // Customer
                        html += `
                    <div class="entity-card">
                        <h5>${item.cust_name}</h5>
                        <p>${item.cust_address || ""}</p>
                        <p>${item.cust_city || ""}, ${item.state_name || ""}</p>
                        <p><strong>Location:</strong> ${item.location_name || ""}</p>
                        <p><strong>Phone:</strong> ${item.cust_phone || item.cust_phone1 || "-"}</p>
                        <p><strong>Email:</strong> ${item.cust_email || "-"}</p>
                        <p><strong>GST:</strong> ${item.cust_tax_reg_id || "-"}</p>
                        <p><strong>Reg ID:</strong> ${item.cust_reg_id || "-"}</p>
                    </div>`;
                    }
                    else {
                        // Supplier
                        html += `
                    <div class="entity-card">
                        <h5>${item.vn_name}</h5>
                        <p>${item.vn_address || ""}</p>
                        <p>${item.vn_city || ""}</p>
                        <p><strong>State:</strong> ${item.vn_state || ""}</p>
                        <p><strong>Phone:</strong> ${item.vn_phone1 || item.vn_phone2 || "-"}</p>
                        <p><strong>GST:</strong> ${item.vn_gst || "-"}</p>
                    </div>`;
                    }

                    $("#entityDetails").html(html);
                    
                }
            });

        }


        function search_src_item() {
            //Start autocoumplete
            $("#txtSrcItemAutoPopulate").autocomplete({

                source: function (request, response) {
                    $.ajax({
                        type: "POST",
                        contentType: "application/json; charset=utf-8",
                        url: "LedgerReport.aspx/showItems",
                        data: "{'searchText':'" + $("#txtSrcItemAutoPopulate").val() + "','type_id':'" + $("#change_type").val() + "'}",
                        dataType: "json",
                        success: function (data) {

                            var data1 = jQuery.parseJSON(data.d);
                            console.log(data1);
                            response(data1.slice(0, 20));
                        }
                    });
                },
                select: function (event, ui) {

                    if (ui.item.id == -1) {
                        $("#txtSrcItemAutoPopulate").val("");
                        sel_src_customer_name = '';
                        sel_src_customer = -1;
                    } else {
                        $("#txtSrcItemAutoPopulate").val(ui.item.label); //ui.item is your object from the array
                        sel_src_customer_name = ui.item.label;
                        sel_src_customer = ui.item.id
                        loadEntity();
                    }

                    event.preventDefault();
                },
                minLength: 1
            });
            //End autocomplete
        }

        function dateformat(idate) {

            var med = idate.split("-");
            var dd = med[0];
            var mm = med[1];
            var yy = med[2];

            var nDate = yy + '-' + mm + '-' + dd;
            return nDate;

        }

        function reset_all_data() {

            $("#Text_date_from").val("");
            $("#Text_date_to").val("");
            $("#txtSrcItemAutoPopulate").val("");
            $("#chkSales, #chkReturns, #chkDebits, #chkCredits").prop("checked", false);
            $("#chkPurchase, #chkPurchaseReturns").prop("checked", false);
            $("#entityDetails").html('');
            $("#dlbtn").hide();
        }

        function reset_report() {

            window.location.reload();
        }
        

        function load_report(page) {
            
            var postObj = {
                page: page,
                perpage: $("#txtpageno").val(),
                filters: {}
            };

            postObj.filters.partner_type = $("#change_type").val();
            postObj.filters.partner_id = sel_src_customer;
            postObj.filters.action_type = selectedActions;
            
            

            if (!postObj.filters.partner_id || postObj.filters.partner_id == 0 || postObj.filters.partner_id == -1) {
                if (postObj.filters.partner_type == "1") {
                    alert("Please select a customer.");
                } else {
                    alert("Please select a supplier.");
                }

                return false;
            }

            var dateFrom = $("#Text_date_from").val().trim();
            var dateTo = $("#Text_date_to").val().trim();

            if (dateFrom === "") {
                alert("Please select the From Date.");
                $("#Text_date_from").focus();
                return false;
            }

            if (dateTo === "") {
                alert("Please select the To Date.");
                $("#Text_date_to").focus();
                return false;
            }

            if ($("#Text_date_from").val() != "") {
                postObj.filters.date_from = dateformat($("#Text_date_from").val());
            }

            if ($("#Text_date_to").val() != "") {
                postObj.filters.date_to = dateformat($("#Text_date_to").val());
            }

            // read check boxes
            var actionTypes = [];

            if (postObj.filters.partner_type == "1") {
                if ($("#chkSales").is(":checked")) {
                    actionTypes.push(1);
                }

                if ($("#chkReturns").is(":checked")) {
                    actionTypes.push(3);
                }

                if ($("#chkDebits").is(":checked")) {
                    actionTypes.push(7);
                }

                if ($("#chkCredits").is(":checked")) {
                    actionTypes.push(6);
                }
            }
            else {

                if ($("#chkPurchase").is(":checked")) {
                    actionTypes.push(2);
                }

                if ($("#chkPurchaseReturns").is(":checked")) {
                    actionTypes.push(4);
                }
            }

            if (actionTypes.length === 0) {
                alert("Please select at least one transaction type.");
                return false; // or simply return; depending on your function
            }

            var selectedActions = actionTypes.join(",");
            postObj.filters.action_type = selectedActions;

            $("#tblConvItems tbody").html("");

            $.ajax({
                type: "POST",
                url: "LedgerReport.aspx/Get_Transactions",
                data: JSON.stringify(postObj),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {

                    console.log(msg.d);
                    if (msg.d == "N") {

                        $("#lblcount").html('0');
                        $('#tblConvItems  tbody').html("<tr class=''><td colspan='9' align='center' style='font-weight:bold; padding:8px;'>No Records Found</td></tr>");
                        $("#paginatediv").hide();
                        $("#dlbtn").hide();
                        return false;

                    }
                    else {
                        var obj = JSON.parse(msg.d);
                        console.log(obj);
                        var htm = "";
                        var htmlsum = "";

                        $("#lblcount").text(obj.count);

                        $.each(obj.data, function (i, rows) {

                            htm += '<tr class="even pointer">';
                            htm += '<td class="a-center ">';
                            htm += '<div class="icheckbox_flat-green" style="position: relative;">';
                            htm += '<input type="checkbox" class="flat" name="table_records" style="position: absolute; opacity: 0;">';
                            htm += '<ins class="iCheck-helper" style="position: absolute; top: 0%; left: 0%; display: block; width: 100%; height: 100%; margin: 0px; padding: 0px; background: rgb(255, 255, 255); border: 0px; opacity: 0;"></ins></div>';
                            htm += '</td>';
                            htm += '<td class="text-left"># ' + rows.Date + '</td>';
                            htm += '<td class="text-left "><strong>' + rows.Ref_ID + '</strong></td>';
                            htm += '<td class="text-left" style="color:#494646">' + rows.Transaction_Type + '</td>';
                            
                            htm += '<td class="text-left"><b>' + rows.Debit + '</b></td>';
                            htm += '<td class="text-left" style="color:#2e6da4">' + rows.Credit + '</td>';
                            htm += '<td class="text-left"> <small style="color:gray">' + rows.Description + '</small></td>';
                            htm += '<td class="text-left" style="color:#494646">' + rows.Voucher_No + '</td>';
                            htm += '<td class="text-left" style="color:#494646">' + rows.PO_Number + '</td>';
                            htm += '</tr>';

                        });

                    }

                    $('#tblConvItems  tbody').html(htm);

                    var html = "";

                    html += '<tr>';
                    html += '<td colspan="8">';
                    html += '<div  id="divPagination" style="text-align: center;">';
                    html += '</div>';
                    html += '</td>';
                    html += '</tr>';

                    $('#tblConvItems  tbody').append(html);
                    $("#dlbtn").show();
                    $("#divPagination").html(paginate(obj.count, $("#txtpageno").val(), page, "load_report"));


                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Something went wrong..!");
                }
            });
        }

        function download_report() {

            var postObj = {
                page: 1,
                perpage: 0,
                filters: {}
            };

            postObj.filters.partner_type = $("#change_type").val();
            postObj.filters.partner_id = sel_src_customer;
            postObj.filters.action_type = selectedActions;



            if (!postObj.filters.partner_id || postObj.filters.partner_id == 0 || postObj.filters.partner_id == -1) {
                if (postObj.filters.partner_type == "1") {
                    alert("Please select a customer.");
                } else {
                    alert("Please select a supplier.");
                }

                return false;
            }

            var dateFrom = $("#Text_date_from").val().trim();
            var dateTo = $("#Text_date_to").val().trim();

            if (dateFrom === "") {
                alert("Please select the From Date.");
                $("#Text_date_from").focus();
                return false;
            }

            if (dateTo === "") {
                alert("Please select the To Date.");
                $("#Text_date_to").focus();
                return false;
            }

            if ($("#Text_date_from").val() != "") {
                postObj.filters.date_from = dateformat($("#Text_date_from").val());
            }

            if ($("#Text_date_to").val() != "") {
                postObj.filters.date_to = dateformat($("#Text_date_to").val());
            }

            // read check boxes
            var actionTypes = [];

            if (postObj.filters.partner_type == "1") {
                if ($("#chkSales").is(":checked")) {
                    actionTypes.push(1);
                }

                if ($("#chkReturns").is(":checked")) {
                    actionTypes.push(3);
                }

                if ($("#chkDebits").is(":checked")) {
                    actionTypes.push(7);
                }

                if ($("#chkCredits").is(":checked")) {
                    actionTypes.push(6);
                }
            }
            else {

                if ($("#chkPurchase").is(":checked")) {
                    actionTypes.push(2);
                }

                if ($("#chkPurchaseReturns").is(":checked")) {
                    actionTypes.push(4);
                }
            }

            if (actionTypes.length === 0) {
                alert("Please select at least one transaction type.");
                return false; // or simply return; depending on your function
            }

            var selectedActions = actionTypes.join(",");
            postObj.filters.action_type = selectedActions;


            $.ajax({
                type: "POST",
                url: "LedgerReport.aspx/Download_Transactions",
                data: JSON.stringify(postObj),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {

                    console.log(msg.d);
                    if (msg.d == "N") {

                        alert("No Records Found!");
                        return false;

                    }
                    else {

                        location.href = "DownloadLedgerReport.aspx";
                        return false;

                    }


                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Something went wrong..!");
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
                            <%--<img src="../images/img.jpg" alt="..." class="img-circle profile_img">--%>
                        </div>
                        <div class="profile_info">
                            <%-- <span>Welcome,</span>
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
                            <label style="font-weight: 400; font-size: 14px;">Warehouse \ Item Converter</label>

                        </div>

                    </nav>
                </div>
            </div>
            <!-- /top navigation -->

            <!-- page content -->
            <div class="right_col" role="main">
                <div class="">

                    <%--<div class="page-title">
                        <div style="text-align:center;margin-top:40px;">
                            <h4>Item Converter</h4>
                            
                        </div>
                       
                    </div>--%>

                    <div class="row">

                        <div class="col-md-6 col-sm-12 col-xs-6" id="Div3">
                            <div class="x_panel">
                                <div class="x_content">

                                    <form id="Form2" data-parsley-validate class="form-horizontal form-label-left">

                                        <div class="col-md-12">
                                            <div class="form-group">
                                                <label class="control-label col-md-4 col-sm-3 col-xs-12" for="first-name" style="color:#2478b4"">
                                                    Choose Ledger Type<span class="required">*</span>
                                                </label>
                                                <div class="col-md-8 col-sm-6 col-xs-12">
                                                    <select class="form-control" id="change_type" style="border: 1px solid #2478b4" onchange="change_everything();">
                                                        <option value="1">Customer</option>
                                                        <option value="2">Supplier</option>
                                                    </select>
                                                </div>
                                            </div>
                                        </div>

                                    </form>

                                    <div class="clearfix"></div>

                                </div>
                            </div>
                        </div>

                        <div class="col-md-6 col-sm-12 col-xs-6" id="Div5">
                            <h3>Ledger Report
                                <br />
                                <small>View Ledger Information</small>
                            </h3>
                        </div>
                       

                    </div>
                  
                   
                    <div class="row">
                        <div class="col-md-6 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title" style="margin-bottom: 0px; text-align: center">
                                    <h5 style="text-align: center; color: #2478b4; font-weight: bolder">Filter Details </h5>
                                    <ul class="nav navbar-right panel_toolbox">
                                    </ul>

                                </div>
                                <input type="hidden" id="src_id" value="-1" />
                                <input type="hidden" id="dest_id" value="-1" />

                                <div class="x_content">
                                    <br />
                                    <form id="demo-form2" data-parsley-validate class="form-horizontal form-label-left">
                                        <div class="col-md-12">

                                            <div class="form-group">
                                                <label class="control-label col-md-4 col-sm-3 col-xs-12" for="first-name">
     Select Customer/Supplier<span class="required"> *</span>
 </label>
 <div class="col-md-8 col-sm-6 col-xs-12">
     <input type="text" class="form-control col-md-7 col-sm-6 col-xs-12 ui-autocomplete-input" placeholder="Search for Customer/Supplier" required="required" id="txtSrcItemAutoPopulate" autocomplete="off" style="margin-bottom:10px">
 </div>
                                            </div>

                                                                                       <div class="form-group">
                                               <label class="control-label col-md-4 col-sm-3 col-xs-12" for="first-name">
    Report From:<span class="required"> *</span>
</label>
<div class="col-md-8 col-sm-6 col-xs-12">
    <input id="Text_date_from" type="text" class="form-control" required="" style="background-color:#ffffff" />
</div>
                                           </div>

                                                                                                                                   <div class="form-group">
                                               <label class="control-label col-md-4 col-sm-3 col-xs-12" for="first-name">
    Report Till:<span class="required"> *</span>
</label>
<div class="col-md-8 col-sm-6 col-xs-12">
    <input id="Text_date_to" type="text" class="form-control" required="" style="background-color:#ffffff" />
</div>
                                           </div>

                                            <br />
                                                                                       <div class="form-group" id="customerChecks" style="display:none">
                                               <label class="control-label col-md-4 col-sm-3 col-xs-12" for="first-name">
    Load:<span class="required"> *</span>
</label>
<div class="col-md-8 col-sm-6 col-xs-12">
    <div style="margin-bottom: 10px;">
        <label style="font-weight: normal; margin-right: 20px;">
            <input type="checkbox" val="1" id="chkSales" style="margin-right: 5px;" />
            Sales
        </label>
        <label style="font-weight: normal;">
            <input type="checkbox" id="chkReturns" style="margin-right: 5px;" />
            Sales Return
        </label>
    </div>
    <div>
        <label style="font-weight: normal; margin-right: 20px;">
            <input type="checkbox" id="chkDebits" style="margin-right: 5px;" />
            Debit Entries
        </label>
        <label style="font-weight: normal;">
            <input type="checkbox" id="chkCredits" style="margin-right: 5px;" />
            Credit Entries
        </label>
    </div>
</div>
                                           </div>

                                                                                                                                   <div class="form-group" id="supplierChecks" style="display:none">
                                               <label class="control-label col-md-4 col-sm-3 col-xs-12" for="first-name">
    Load:<span class="required"> *</span>
</label>
<div class="col-md-8 col-sm-6 col-xs-12">
    <div style="margin-bottom: 10px;">
        <label style="font-weight: normal; margin-right: 20px;">
            <input type="checkbox" val="1" id="chkPurchase" style="margin-right: 5px;" />
            Purchase
        </label>
        <label style="font-weight: normal;">
            <input type="checkbox" id="chkPurchaseReturns" style="margin-right: 5px;" />
            Purchase Return
        </label>
    </div>
    <%--<div>
        <label style="font-weight: normal; margin-right: 20px;">
            <input type="checkbox" id="chkSupDebits" style="margin-right: 5px;" />
            Debit Entries
        </label>
        <label style="font-weight: normal;">
            <input type="checkbox" id="chkSupCredits" style="margin-right: 5px;" />
            Credit Entries
        </label>
    </div>--%>
</div>
                                           </div>



                                            <div class="form-group">
                                                <div class="control-label col-md-12 col-sm-12 col-xs-12">
                                                    <%--<button  class="btn " style="color: #6f6e6e" onclick="javascript:add_item_to_input_list();">Reset</button>--%>
                                                    <div onclick="javascript:reset_report();" style="color: #6f6e6e;background-color:#dddddd" class="btn">Reset</div>
                                                    <div onclick="javascript:load_report(1);"  class="btn btn-primary">Load Report</div>
                                                    <%--<button type="button" class="btn btn-primary">Add Item</button>--%>
                                                </div>
                                            </div>

                                        </div>

                                    </form>


                                </div>

                                <div class="clearfix"></div>
                                <div class="ln_solid"></div>

                            </div>
                        </div>

                        <div class="col-md-6 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title" style="margin-bottom: 0px; text-align: center">
                                    <h5 style="text-align: center; color: #2478b4; font-weight: bolder">Customer/Supplier Details </h5>
                                    <ul class="nav navbar-right panel_toolbox">
                                    </ul>

                                </div>
                                <div class="x_content">
                                    <br />
                                 <div class="col-md-12 col-sm-12 col-xs-12" style="text-align:right">
    <div style="text-align:left" id="entityDetails"></div>

     <div onclick="javascript:download_report();" class="btn btn-success" id="dlbtn" style="display:none">Download Report</div>

 </div>
                                </div>

                                <div class="clearfix"></div>
                                <div class="ln_solid"></div>

                            </div>
                        </div>
                        <div class="col-md-12 col-sm-12 col-xs-12" id="Div2">
                        </div>

                    </div>
                    <%-- <div class="clearfix"></div>--%>
                    <div class="row" style="display: none">
                        <div class="col-md-12 col-sm-12 col-xs-12">

                            <div class="x_panel" style="text-align: center">
                                <div class="x_content">
                                    <div class="form-group">
                                        <div class="col-md-12 col-sm-12 col-xs-12">
                                            <button class="btn " style="color: #6f6e6e">Reset Values</button>
                                            <button class="btn btn-primary">Add for Conversion</button>
                                        </div>
                                    </div>

                                </div>
                            </div>

                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12">

                            <div class="x_panel" style="text-align: center">

                                <div class="table-responsive" style="display:none">

                                    <div style="text-align: center;">
                                        <h4>Conversion Preview</h4>
                                    </div>
                                    <%--<label style="font-weight: 400; font-size: 18px; text-align:center">Conversion List</label>--%>
                                    
                                </div>

                                <div class="x_content">

                                    <div class="fl" style="float:right">
                                       
                                       <div class="col-md-5 col-sm-6 col-xs-6 form-group" id="divresultpage" style="padding-left: 0px; padding-right: 0px;">
               <%--  <div class="col-md-4 col-sm-6 col-xs-7 form-group" style="">
                     <label style="font-weight: bold; font-size: 11px;">Per Page</label>
                 </div>--%>
                 <div class="col-md-4 col-sm-6 col-xs-3 form-group" style="padding-left: 0px;">
                     <select class="" style="text-indent: 0; padding: 0px; height: 20px;" id="txtpageno" onchange="javascript:load_report(1);">
                         <option value="25">Show 25 records</option>
                         <option value="50">Show 50 records</option>
                         <option value="100">Show 100 records</option>
                         <option value="500">Show 500 records</option>
                     </select>
                 </div>
             </div>
                                    </div>

                                  <table class="table table-striped jambo_table bulk_action " id="tblConvItems">
                                <thead style="background-color:#f1eeee;color:#525252">
                                    <tr class="headings">
                                        <th></th>
                                        <%--<th class="column-title">Sl No. </th>--%>
                                        <th class="column-title">Date </th>
                                        <th class="column-title">Ref.ID </th>
                                        <th class="column-title">Transaction Type </th>
                                        
                                        <th class="column-title">Debit </th>
                                        <th class="column-title">Credit </th>
                                        <th class="column-title">Description </th>
                                        <th class="column-title">Voucher No </th>
                                        <th class="column-title">PO No </th>

                                    </tr>
                                </thead>
                                <tbody id="src_itm_list"><td colspan="9" style="text-align:center">No Records Found</td></tbody>
                            </table>

                                </div>
                            </div>

                        </div>
                    </div>

                    <div class="row" style="display: none">
<div class="col-md-12">

<div class="x_panel">
<div class="x_title">
<h2> Quick Links : </h2>

<div class="clearfix"></div>
</div>
<div class="x_content">

<a class="btn btn-app" href="Manage_Conversions.aspx" target="_blank">
<i class="fa fa-edit" style="color:#2478b4"></i> <b>Manage Conversions</b>
</a>
<a class="btn btn-app" href="itemmaster.aspx" target="_blank">
<i class="fa fa-plus-square-o" style="color:#2478b4"></i> <b>Create New Item</b>
</a>
<a class="btn btn-app" href="warehousemanagement.aspx" target="_blank">
<i class="fa fa-sitemap" style="color:#2478b4"></i> <b>Item Management</b>
</a>

    <a class="btn btn-app" href="stockTransfer.aspx" target="_blank">
<i class="fa fa-exchange" style="color:#2478b4"></i> <b>Transfer Stock</b>
</a>

<a class="btn btn-app" href="../web_reports/stockReport.aspx" target="_blank">
<i class="fa fa-cubes" style="color:#2478b4"></i> <b>Stock Statistics</b>
</a>

    <a class="btn btn-app" href="../web_reports/stockTransactionReport.aspx" target="_blank">
<i class="fa fa-retweet" style="color:#2478b4"></i> <b>Stock Transactions</b>
</a>

</div>
</div>
</div>

</div>

                    <!-- Modal PO Number-->
						<div class="modal fade" id="itemModal" role="dialog" data-keyboard="false" data-backdrop="static">
							<div class="modal-dialog modal-lg" >

								<!-- Modal content-->
								<div class="modal-content">
									<div class="modal-header" style="padding-bottom: 5px;">
										<button type="button" class="close" data-dismiss="modal">&times;</button>
										<div class="col-md-12 col-sm-12 col-xs-12">
											<h4 class="modal-title" style="color:#da2e2e">Confirm Item Conversion <small id="lbl_wh_name"></small></h4>
										
                                            <div class="ln_solid"></div>
                                            <h4>Input</h4>
                                            <h5 style="color:#2478b4">The following Item's Stock will be <strong>Deducted</strong> from the Stock in the warehouse </h5>
                                            <table class="table table-striped jambo_table bulk_action">
                                    <thead style="background-color:#f1eeee;color:#525252">
                                        <tr class="headings">
                                            <th></th>
                                            <th class="column-title">Sl No. </th>
                                            <th class="column-title">Input Item(s) </th>
                                            <th class="column-title">Quantity </th>                                                                                       
                                        </tr>
                                    </thead>
                                    <tbody id="Tbody_vrfy_input">

                                      
                                    </tbody>
                                </table>

                                            <div class="ln_solid"></div>
                                            <h4>Output</h4>
                                            <h5 style="color:#2478b4">The following Item's Stock will be <strong>Credited</strong> to the Stock in the warehouse </h5>
                                            <table class="table table-striped jambo_table bulk_action">
                                    <thead style="background-color:#f1eeee;color:#525252">
                                        <tr class="headings">
                                            <th></th>
                                            <th class="column-title">Sl No. </th>
                                            <th class="column-title">Output Item(s) </th>
                                            <th class="column-title">Quantity </th>                                                                                       
                                        </tr>
                                    </thead>
                                    <tbody id="Tbody_vrfy_output">

                                      
                                    </tbody>
                                </table>


                                        </div>
										
                                        <div class="col-md-12 col-sm-12 col-xs-12" style="text-align:center">
                                           

                                            <div onclick="javascript:close_modal();" style="color:#6f6e6e;background-color:#dddddd" class="btn">Cancel</div>
                                            <div onclick="javascript:perform_conversion();" class="btn btn-success">Confirm & Convert</div>

                                        </div>
                                        

									</div>
									
									
								</div>

							</div>
						</div>

                </div>
                <!-- /page content -->

            </div>

            <!-- footer content -->
            <footer>
                <div class="pull-right">
                    <div class="footerDiv">
                        <div class="footerDivContent">
                            Copyright 2017 ©
                        </div>
                    </div>
                    <%--Invoice Me Admin  by <a href="">Lucidplus IT Solutions</a>--%>
                </div>
                <div class="clearfix"></div>
            </footer>
            <!-- /footer content -->
        </div>

        <script src="../js/bootstrap/icheck.min.js"></script>

        <!-- jQuery -->
        <%--<script src="../js/bootstrap/jquery.min.js"></script>--%>
        <!-- Bootstrap -->
        <script src="../js/bootstrap/bootstrap.min.js"></script>
        <script src="../js/bootstrap/nprogress.js"></script>
        <!-- FastClick -->
        <!-- Custom Theme Scripts -->
        <script src="../js/bootstrap/custom.min.js"></script>
        <script src="../js/bootbox.min.js"></script>
</body>
</html>
