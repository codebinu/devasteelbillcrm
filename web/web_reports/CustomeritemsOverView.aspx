<%@ Page Language="C#" AutoEventWireup="true" CodeFile="CustomeritemsOverView.aspx.cs" Inherits="web_reports_CustomeritemsOverView" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Item OverView | Invoice Me</title>
    <script type="text/javascript" src="../js/common.js"></script>
    <script type="text/javascript" src="../js/jquery-2.0.3.js"></script>
    <script type="text/javascript" src="../js/jquery.cookie.js"></script>
    <script type="text/javascript" src="../js/jQuery.print.js"></script>
    <script type="text/javascript" src="../js/pagination.js"></script>
    <!-- Bootstrap -->
    <link href="../css/bootstrap/bootstrap.min.css" rel="stylesheet" />
    <!-- Font Awesome -->
    <link href="../css/bootstrap/font-awesome/css/font-awesome.min.css" rel="stylesheet" />
    <!-- NProgress -->
    <link href="../css/bootstrap/nprogress.css" rel="stylesheet" />
    <!-- iCheck -->
    <link href="../css/bootstrap/green.css" rel="stylesheet" />

    <!-- Custom Theme Style -->
    <link href="../css/bootstrap/custom.min.css" rel="stylesheet" />
    <!-- mystyle Style -->
    <link href="../css/bootstrap/mystyle.css" rel="stylesheet" />



    <!--date picker-->
    <link rel="stylesheet" href="../mobiscroll/css/jquery.mobile-1.1.0.min.css" />
    <script src="../mobiscroll/js/mobiscroll-2.0rc3.full.min.js" type="text/javascript"></script>
    <link href="../mobiscroll/css/mobiscroll-2.0rc3.full.min.css" rel="stylesheet" type="text/css" />
    <!--date picker-->


    <script type="text/javascript">

        var BranchId;
        $(document).ready(function () {
            BranchId = $.cookie("invntrystaffBranchId");
            $('#Chkbx_assigned_delivery').prop('checked', false);
            $('#Chkbx_undelivered_order').prop('checked', false);
            if (!BranchId) {
                location.href = "../dashboard.aspx";
                return false;
            }
            $("#txtSearchFromDate").val('');
            $("#txtSearchToDate").val('');
            $("#lblReportFromDate").text('');
            $("#lblReportToDate").text('');
            $("#lblSummaryFromDate").text('');
            $("#lblSummaryToDate").text('');
            // showProfileHeader(1);
            ShowUTCDate();

            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " ©");

        });
        //date time start
        $(function () {
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
                dateFormat: 'dd-mm-yy'
            });
        });
        function ShowUTCDate() {
            var dNow = new Date();
            var date = dNow.getDate();
            if (date < 10) {
                date = "0" + date;
            }
            var localdate = date + '-' + GetMonthName(dNow.getMonth() + 1) + '-' + dNow.getFullYear();
            $("#txtSearchFromDate").val(localdate);
            $("#txtSearchToDate").val(localdate);
            showBranches();
            return;
        }

        function GetMonthName(monthNumber) {
            var months = ['01', '02', '03', '04', '05', '06',
            '07', '08', '09', '10', '11', '12'];
            return months[monthNumber - 1];
        }
        //Start:TO Replace single quotes with double quotes
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
        //Stop:TO Replace single quotes with double quotes

        //start: show warehouse in Reports page

        function showBranches() {
            //  loading();
            var userid = $.cookie("invntrystaffId");
            var branchid = $.cookie("invntrystaffBranchId");
            $.ajax({
                type: "POST",
                url: "CustomeritemsOverView.aspx/showBranches",
                data: "{'userid':'" + userid + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    //  Unloading();
                    var obj = JSON.parse(msg.d);
                    var htm = "";
                    htm += '<option value="0" selected="selected">--All Warehouses--</option>';
                    $.each(obj, function (i, row) {
                        htm += '<option value="' + row.branch_id + '">' + row.branch_name + '</option>';
                    });
                    $("#selWarehouse").html(htm);
                    $("#selWarehouse").val(branchid);
                    ShowItemBrands();
                    //  Unloading();

                },
                error: function (xhr, status) {
                    // Unloading(); 
                    alert("Internet Problem..!");
                }
            });
        }//end showing warehouse

        // show brand name in report

        function ShowItemBrands() {
            //loading();
            $.ajax({
                type: "POST",
                url: "CustomeritemsOverView.aspx/ShowItemBrands",
                data: "{}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    // Unloading();
                    var obj = JSON.parse(msg.d);
                    var htm = "";
                    htm += '<option value="-1" selected="selected">--Brand Name--</option>';
                    $.each(obj, function (i, row) {
                        htm += '<option value="' + row.brand_id + '">' + row.brand_name + '</option>';
                    });
                    $("#selBrand").html(htm);
                    ShowItemCategry();
                    //  Unloading();

                },
                error: function (xhr, status) {
                    //  Unloading();
                    alert("Internet Problem..!");
                }
            });

        }// end brandname

        // show category in report

        function ShowItemCategry() {
            // loading();
            $.ajax({
                type: "POST",
                url: "CustomeritemsOverView.aspx/ShowItemCategry",
                data: "{}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    // Unloading();
                    //alert(msg.d);
                    var obj = JSON.parse(msg.d);
                    var htm = "";
                    htm += '<option value="-1" selected="selected">--Category--</option>';
                    $.each(obj, function (i, row) {
                        htm += '<option value="' + row.cat_id + '">' + row.cat_name + '</option>';
                    });
                    $("#selCategory").html(htm);
                    showItemOverView(1);
                    // showsalespersons();
                    //  Unloading();

                },
                error: function (xhr, status) {
                    // Unloading();
                    alert("Internet Problem..!");

                }
            });
        }//end category




        //Start:Show Daily Reports List
        function showItemOverView(page) {
            var postObj = {
                page: page,
                perpage: $("#txtpageno").val(),
                filters: {}
            };
            if ($.trim($("#txtSearchItem").val()) != "") {
                postObj.filters.searchItem = $("#txtSearchItem").val();
            }

            if ($("#selBrand").val() != "-1") {
                postObj.filters.brand = $("#selBrand").val();
            }
            if ($("#selCategory").val() != "-1") {
                postObj.filters.category = $("#selCategory").val();
            }
            if ($("#selWarehouse").val() != undefined) {
                postObj.filters.warehouse = $("#selWarehouse").val();
            }
            if ($("#txtSearchFromDate").val() != "" && $("#txtSearchFromDate").val() != undefined) {
                postObj.filters.from_date = $("#txtSearchFromDate").val();
            }
            if ($("#txtSearchToDate").val() != "" && $("#txtSearchToDate").val() != undefined) {
                postObj.filters.to_date = $("#txtSearchToDate").val();
            }
         
            // alert(JSON.stringify(postObj));
            // alert(postObj.filters);
            $("#tblitmoverview tbody").html("");

            // alert(searchResult);
            $.ajax({
                type: "POST",
                url: "CustomeritemsOverView.aspx/showItemOverView",
                data: JSON.stringify(postObj),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    console.log(msg.d);
                    if (msg.d == "N") {

                        $("#lblTotalRecords").text(0);
                        $('#tblitmoverview  tbody').html("<tr class=''><td colspan='8' align='center' style='font-weight:bold; padding:8px;'>No Results Found</td></tr>");

                        $("#divSummryall").hide();
                        $("#divsumry").hide();
                        $("#paginatediv").hide();
                        $("#lblSummaryFromDate").text('');
                        $("#lblSummaryToDate").text('');
                        $("#lblSummaryBranchName").text('');
                        $("#lblReportBranchName").text('');

                        return false;

                        alert("Not Found..!");
                        return false;
                    }
                    else {
                        var obj = JSON.parse(msg.d);
                        //alert(msg.d);
                        console.log(obj);
                        var htm = "";
                        var htmlsum = "";
                        var cnt = obj.count;
                        //$("#lblcountCollection").text(cnt);
                     //   $("#lblcountSales").text(cnt);
                        var totalStockAmt = 0;
                        $.each(obj.data, function (i, rows) {

                            htm += "<tr>";
                            htm += "<td>" + rows.customer + "</td>";
                            htm += "<td>" + rows.location + "</td>";
                            htm += "<td style='width:300px;'>#<i>" + rows.itm_code + "</i> <b>" + rows.Item_Name + "</b></td>";
                            htm += "<td>" + rows.totalQty + "</td>";
                          //  htm += "<td>" + rows.originalCost + "</td>";
                            htm += "<td>" + rows.billNetamount + "</td>";
                            //if (rows.totaldiff <= 0) {
                            //    htm += "<td style='text-align:center;color:green;font-weight:bold'>+" + (rows.totaldiff * -1) + "</td>";
                            //} else {
                            //    htm += "<td style='text-align:center;color:red;font-weight:bold'>" + (rows.totaldiff * -1) + "</td>";
                            //}
                        });



                    }
                    $("#divsumry").show();
                    $("#lblTotalStockAmt").text(totalStockAmt.toFixed(2));
                    var BranchName = $("#selWarehouse option:selected").text();
                    $("#lblTotalRecords").text(obj.count);
                    $("#lblSummaryBranchName").text(BranchName);
                    $('#tblitmoverview  tbody').html(htm);

                    $("#paginatediv").show();

                    $("#paginatediv").html(paginate(obj.count, $("#txtpageno").val(), page, "showItemOverView"));


                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }//end


        //start reset/clear
        function resetFunctn() {

            ShowUTCDate();
            var brnchid = $.cookie("invntrystaffBranchId");
            $("#selWarehouse").val(brnchid);
            $("#selCategory").val(-1);
            $("#selBrand").val(-1);
            $("#txtSearchItem").val("");
            showItemOverView(1);
        }//end

        //Start:Download Daily Reports List
        function downloaditemoverview() {
            var postObj = {
                filters: {}
            };
            if ($.trim($("#txtSearchItem").val()) != "") {
                postObj.filters.searchItem = $("#txtSearchItem").val();
            }

            if ($("#selBrand").val() != "-1") {
                postObj.filters.brand = $("#selBrand").val();
            }
            if ($("#selCategory").val() != "-1") {
                postObj.filters.category = $("#selCategory").val();
            }
            if ($("#selWarehouse").val() != undefined) {
                postObj.filters.warehouse = $("#selWarehouse").val();
            }
            if ($("#txtSearchFromDate").val() != "" && $("#txtSearchFromDate").val() != undefined) {
                postObj.filters.from_date = $("#txtSearchFromDate").val();
            }
            if ($("#txtSearchToDate").val() != "" && $("#txtSearchToDate").val() != undefined) {
                postObj.filters.to_date = $("#txtSearchToDate").val();
            }

            $.ajax({
                type: "POST",
                url: "CustomeritemsOverView.aspx/downloaditemoverview",
                data: JSON.stringify(postObj),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    // alert(msg.d);
                    if (msg.d == "N" || msg.d == "0") {
                        alert("Not Found...!");
                        return false;
                    }
                    else {
                        // location.href = "DownloadItemReport.aspx";
                        location.href = "downloaditemoverview.aspx";
                        return false;
                    }
                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });

        }//Stop:Download stockReport 

        //print report
        function printMainReport() {

            var searchtype = "";

            $("#divtopHead").hide();
            $("#tdDownloadBtn").hide();
            $("#tdPrintBtn").hide();
            $("#showBranchesDiv").hide();
            $("#DivshoWBrandname").hide();
            $("#divshowCategory").hide();
            $("#divshwBranch").hide();
            $("#divbrnd").hide();
            $("#divCatgry").hide();
            $("#divfrmdte").hide();
            $("#divtodate").hide();
            $("#divReportContent").print();
            $("#divshwBranch").show();
            $("#divbrnd").show();
            $("#divCatgry").show();
            $("#divfrmdte").show();
            $("#divtodate").show();
            $("#divtopHead").show();
            $("#tdDownloadBtn").show();
            $("#tdPrintBtn").show();
            $("#showBranchesDiv").show();
            $("#DivshoWBrandname").show();
            $("#divshowCategory").show();
        }








    </script>






</head>
<body class="nav-md">
    <div class="container body">
        <div class="main_container">
            <div class="col-md-3 left_col">
                <div class="left_col scroll-view">
                    <div class="navbar nav_title" style="border: 0;">
                        <a href="../index.html" class="site_title">
                            <!--<i class="fa fa-paw"></i> -->
                            <span>Invoice Me</span></a>
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
                                <li><a href="../index.html" a><i class="fa fa-home"></i>Home <span class="fa fa-chevron-down"></span></a>
                                </li>
                                <li><a><i class="fa fa-user"></i>Customer <span class="fa fa-chevron-down"></span></a>
                                    <ul class="nav child_menu">
                                        <li><a href="../customer/newcustomer.html">New Customer</a></li>
                                        <li><a href="../customer/customers.html">Customers</a></li>
                                        <li><a href="../customer/customerconfirmation.html">Customer Confirmation</a></li>
                                        <li><a href="../customer/assigncustomers.html">Assign Customer</a></li>
                                    </ul>
                                </li>
                                <li><a><i class="fa fa-shopping-cart"></i>Sales <span class="fa fa-chevron-down"></span></a>
                                    <ul class="nav child_menu">
                                        <li><a href="#">New Order</a></li>
                                        <li><a href="#">Orders</a></li>
                                        <li><a href="#">Edit Order</a></li>
                                        <li><a href="#">Confirm Order</a></li>
                                    </ul>
                                </li>
                                <li><a><i class="fa fa-cubes"></i>Inventory <span class="fa fa-chevron-down"></span></a>
                                    <ul class="nav child_menu">
                                        <li><a href="warehouse.html">Warehouses</a></li>
                                        <li><a href="itemmaster.html">Item Master</a></li>
                                        <li><a href="stockmanagement.html">Stock Management</a></li>
                                        <li><a href="salescommission.html">Sales Commission</a></li>
                                        <li><a href="offermaster.html">Offer</a></li>
                                        <li><a href="itembrand.html">Item Brand</a></li>
                                        <li><a href="itemcategory.html">Item Category</a></li>
                                        <li><a href="managevendor.html">Manage Vendor</a></li>
                                        <li><a href="#">Purchase Entry</a></li>

                                    </ul>
                                </li>
                                <li><a><i class="fa fa-wrench"></i>OP Center <span class="fa fa-chevron-down"></span></a>
                                    <ul class="nav child_menu">
                                        <li><a href="../opcenter/manageuser.html">Manage User</a></li>
                                        <li><a href="#">Manage Role</a></li>
                                        <li><a href="#">Track Users</a></li>
                                    </ul>
                                </li>
                                <li><a><i class="fa fa-gears"></i>Settings <span class="fa fa-chevron-down"></span></a>
                                    <ul class="nav child_menu">
                                        <li><a href="#">Settings</a></li>
                                        <li><a href="#">Export to Tally</a></li>
                                    </ul>
                                </li>
                                <li><a><i class="fa fa-file-text-o"></i>Reports<span class="fa fa-chevron-down"></span></a>
                                    <ul class="nav child_menu">
                                        <li><a href="#">Sales Reports</a></li>
                                        <li><a href="#">Sales Reports Advanced</a></li>
                                        <li><a href="#">Sales Return Reports</a></li>
                                        <li><a href="#">Item Report</a></li>
                                        <li><a href="#">Graphical Item Report</a></li>
                                        <li><a href="#">Purchase Report</a></li>
                                        <li><a href="#">Purchase Report Advance</a></li>
                                    </ul>
                                </li>
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
            <div class="top_nav">
                <div class="nav_menu">
                    <nav>

                        <div class="navbar-header" style="width: 100%; display: flex; align-items: center">
                            <div class="nav toggle" style="padding: 5px;">
                                <a id="menu_toggle"><i class="fa fa-bars"></i></a>
                            </div>
                            <label style="font-weight: bold; font-size: 16px;">Item OverView</label>

                        </div>

                    </nav>
                </div>
            </div>
            <!-- /top navigation -->
            <!-- page content -->
            <div id="divReportContent">
                <div class="right_col" role="main">
                    <div class="">
                        <div class="page-title">
                            <%--<div class="title_left">
                                <h3>Sales Item Report</h3>
                            </div>--%>
                        </div>

                        <div class="clearfix"></div>

                        <div class="row">
                            <div class="col-md-12 col-sm-6 col-xs-12 form-group has-feedback">
                                <div class="x_panel" id="divtopHead" style="padding-left: 5px; padding-right: 5px;">
                                    <div class="x_title">
                                        <label>Filters</label>
                                        <ul class="nav navbar-right panel_toolbox">
                                            <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                            </li>

                                            <%--<li><a class="close-link"><i class="fa fa-close"></i></a>
                                        </li>--%>
                                        </ul>
                                    </div>
                                    <div class="x_content">
                                        <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback" id="divshwBranch">
                                            <div id="showBranchesDiv">
                                                <select id="selWarehouse" style="text-indent: 25px; padding-right:5px;" class="form-control" onchange="javascript:showItemOverView(1);">
                                                    <option>--Warehouse--</option>
                                                    <option>Abu Dhabi</option>
                                                    <option>Ajman</option>
                                                </select>
                                            </div>
                                            <span aria-hidden="true" class="fa fa-map-marker form-control-feedback left"></span>
                                        </div>
                                        <div class="col-md-2 col-sm-6 col-xs-12 form-group has-feedback" id="divbrnd">
                                            <div id="DivshoWBrandname">
                                                <select id="selBrand" style="text-indent: 25px; padding-right:5px;" class="form-control" onchange="javascript:showItemOverView(1);">
                                                    <option>--Brand Name--</option>
                                                    <option>Abu Dhabi</option>
                                                    <option>Ajman</option>
                                                </select>
                                            </div>
                                            <span aria-hidden="true" class="fa fa-briefcase form-control-feedback left"></span>
                                        </div>
                                        <div class="col-md-2 col-sm-6 col-xs-12 form-group has-feedback" id="divCatgry">
                                            <div id="divshowCategory">
                                                <select id="selCategory" style="text-indent: 25px; padding-right:5px;" class="form-control" onchange="javascript:showItemOverView(1);">
                                                   
                                                </select>
                                            </div>
                                            <span aria-hidden="true" class="fa fa-clone  form-control-feedback left"></span>
                                        </div>
                                        <div class="col-md-5 col-sm-6 col-xs-10 form-group has-feedback" style="padding-right: 0px;">
                                            <input type="text" placeholder="Search Item Name/Code" id="txtSearchItem" class="form-control has-feedback-left" style="padding-right: 10px;">
                                                    <span aria-hidden="true" class="fa fa-search form-control-feedback left"></span>
                                                </div>
                                        
                                       <%-- <div class="checkbox">
            <label style="font-size: 1.3em">
                <input type="checkbox" value="" id="cbCashPayment" onclick="javascript: paymentMethod();" />
                <span class="cr"><i class="cr-icon fa fa-check"></i></span>              
            </label>
        </div>--%>

                                        <%-- start div for salesperson combo --%>
                                        <div class="col-md-3 col-sm-6 col-xs-12 form-group" id="divfrmdte">
                                                    <input type="text" placeholder="From Date" id="txtSearchFromDate" class="form-control has-feedback-left" style="padding-right: 10px;" readonly="">
                                                    <span aria-hidden="true" class="fa fa-calendar form-control-feedback left"></span>
                                                </div>

                                         <div class="col-md-3 col-sm-6 col-xs-12 form-group" id="divtodte">
                                                    <input type="text" placeholder="To Date" id="txtSearchToDate" class="form-control has-feedback-left" style="padding-right: 10px;" readonly="">
                                                    <span aria-hidden="true" class="fa fa-calendar form-control-feedback left"></span>
                                                </div>
                                  
                                        <div class="col-md-2 col-sm-6 col-xs-12 form-group">
                                       
                                      
                                            <div class="col-md-12 col-sm-6 col-xs-12 form-group pull-right">
                                                <button id="btnreset" style="font-size: 11px; padding: 4px; font-weight: bold;" class="btn btn-primary pull-right" type="button" onclick="javascript:resetFunctn();">
                                                    <li style="margin-right: 5px;" class="fa fa-refresh"></li>
                                                    Reset 
                                                </button>

                                                <button id="btnsearch" style="font-size: 11px; padding: 4px; font-weight: bold;" class="btn btn-success pull-right" type="button" onclick="javascript:showItemOverView(1);">
                                                    <li style="margin-right: 5px;" class="fa fa-search"></li>
                                                    Search 
                                                </button>

                                            </div>
                                        </div>

                                        

                                    </div>

                                    
                                </div>

                            </div>
                            
                        </div>

                        

                        <div class="row">
                            <div class="col-md-12 col-md-12 col-sm-12 col-xs-12">
                                <div class="x_panel" style="padding-left: 5px; padding-right: 5px;">
                                    <div class="x_title" style="margin-bottom: 2px;">
                                        <label>Details</label>
                                        <ul class="nav navbar-right panel_toolbox">
                                            <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                            </li>

                                            <%--<li><a class="close-link"><i class="fa fa-close"></i></a>
                                        </li>--%>
                                        </ul>
                                    </div>
                                    <div class="x_content">

                                        <section class="content invoice">
                                            <!-- title row -->
                                            <div class="row">

                                                <!-- /.col -->
                                            </div>
                                            <!-- info row -->
                                            <div class="row invoice-info" style="background: #f1eded; padding-top: 15px;">
                                               
                          
                                             
                                                                      <div class="col-md-6 col-sm-6 col-xs-12 pull-right;" style="float: right;">

                                                    <div class="col-md-3 col-sm-6 col-xs-12 form-group pull-right" style="padding-right: 2px;">
                                                        <label style="font-weight: bold; font-size: 11px;">Total Records:</label>
                                                        <label id="lblTotalRecords">1</label>
                                                    </div>
                                                    <div id="tdDownloadBtn" class="col-md-2 col-sm-6 col-xs-8 form-group pull-right" style="" onclick="javascript:downloaditemoverview();">
                                                        <label class="fa fa-download" style="font-size: 20px; color: red; cursor: pointer;"></label>
                                                        <label style="font-weight: bold; font-size: 11px;">Report</label>
                                                    </div>
                                                    <div id="tdPrintBtn" class="col-md-2 col-sm-6 col-xs-4 form-group pull-right" style="" onclick="javascript:printMainReport();">
                                                        <label class="fa fa-print" style="font-size: 20px; color: blue; cursor: pointer;"></label>
                                                        <label style="font-weight: bold; font-size: 11px;">print</label>
                                                    </div>
                                                                                   <div class="col-md-2 col-sm-6 col-xs-6 form-group pull-right">
                                                <select id="txtpageno" class="" onchange="javascript:showItemOverView(1);">
                                                    <option value="25">25</option>
                                                    <option value="50">50</option>
                                                    <option value="100">100</option>
                                                    <option value="500">500</option>
                                                    <option value="1000">1000</option>
                                                    <option value="5000">5000</option>
                                                    <option value="10000">10000</option>
                                                </select>
                                            </div>
                                                </div>
                                                <!-- /.col -->
                                            </div>
                                            <!-- /.row -->

                                            <!-- Table row -->
                                            <div class="col-md-12 col-sm-12 col-xs-12" style="overflow-x: auto; padding-left: 0px; padding-right: 0px;">

                                                <div class="x_content">

                                                    <table class="table table-striped jambo_table bulk_action" style="table-layout: auto;" id="tblitmoverview">
                                                        <thead style="background-color:#f1eeee;color:#525252">
                                                            <tr>
                                                                   <th>Customer Name</th>
                                                                 <th>Loaction </th>
                                                                <th>Item Name</th>
                                                                 <th>Total Qty</th>
                                                               <%-- <th>Original Net Amount</th>    --%>                                                      
                                                                <th>Billed Net Amount</th>
                                                                <%-- <th>Total Difference</th>--%>
                                                               
                                                            </tr>
                                                        </thead>


                                                        <tbody>
                                                            
                                                        </tbody>
                                                    </table>


                                                    <div style="text-align:center;" id="paginatediv"></div>



                                                </div>
                                            </div>
                                    </div>
                                    <!-- /.row -->
                                    </section>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="clearfix"></div>

                    
                </div>
            </div>
        </div>
        <!-- /page content -->


        <!<!-- footer content -->
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
    <%--<script src="../js/bootstrap/jquery.min.js"></script>--%>
    <!-- Bootstrap -->
    <script src="../js/bootstrap/bootstrap.min.js"></script>
    <!-- FastClick -->
    <script src="../js/bootstrap/fastclick.js"></script>
    <!-- NProgress -->
    <script src="../js/bootstrap/nprogress.js"></script>

    <!-- Custom Theme Scripts -->
    <script src="../js/bootstrap/custom.min.js"></script>
    <!-- Alert Scripts -->
    <script src="../js/bootbox.min.js"></script>
</body>
</html>
