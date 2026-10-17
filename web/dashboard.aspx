<%@ Page Language="C#" AutoEventWireup="true" CodeFile="dashboard.aspx.cs" Inherits="dashboard" %>
<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Dashboard  | Invoice Me</title>
    <script src="js/common.js" type="text/javascript"></script>
    <script type="text/javascript" src="js/jquery-2.0.3.js"></script>
    <script type="text/javascript" src="js/jquery.cookie.js"></script>
    <!-- Bootstrap -->
    <link href="css/bootstrap/bootstrap.min.css" rel="stylesheet" />
    <!-- Font Awesome -->
    <link href="css/font-awesome/css/font-awesome.min.css" rel="stylesheet" />
    <!-- NProgress -->
    <link href="css/bootstrap/nprogress.css" rel="stylesheet" />
    <!-- bootstrap-daterangepicker -->
    <link href="css/bootstrap/daterangepicker.css" rel="stylesheet" />
    <!-- Custom Theme Style -->
    <link href="css/bootstrap/custom.min.css" rel="stylesheet" />


    <script type="text/javascript">
        var branchId;
        $(document).ready(function () {
            $(document).on('click', function (event) {

                if (event.target.id != "comboBranchName" && event.target.id != "divLogoutbtn") {
                    if ($("#comboBranchName").val() == "0") {
                        event.preventDefault();
                        alert("Please select warehouse");
                        //location.href = "dashboard.aspx";
                    }
                }
            });
            var userid = $.cookie("invntrystaffId");
            branchId = $.cookie("invntrystaffBranchId");
            if (!userid) {
                location.href = "login.aspx";
            }
            else {
               // alert("");
                showBranches();
            }

            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " ©");


        });


        //Start:Change Branch
        function changeBranch() {
            var resultValue = $("#comboBranchName").val();

            if (resultValue == "0") {
                $.removeCookie('invntrystaffBranchId');
                $.removeCookie('invntrystaffBranchName');
                $.removeCookie('invntryTimeZone');
                $("#txtnewordercount").text("");
                $("#txtprocessordercount").text("");
                $("#txtdisconfirmorderCount").text("");
                $("#txtConfirmCustomers").text("");
                $("#txtlowstockcount").text("");
                $("#txtOutstandingBillCount").text("");
                //    showProfileHeader(2);

                //alert("Please Select Warehouse");


                return false;
            }

            var branch_name = $("#comboBranchName option[value='" + resultValue + "']").text();
            var branch_id = $("#comboBranchName").val();
            var TimeZone = $("#comboBranchName").find('option:selected').attr('data-timezone');
            var countryId = $("#comboBranchName").find('option:selected').attr('data-country');
            var CookieDate = new Date();
            CookieDate.setFullYear(CookieDate.getFullYear() + 10);
            $.cookie("invntrystaffBranchId", branch_id, { expires: CookieDate }); //set cookie
            $.cookie("invntrystaffBranchName", branch_name, { expires: CookieDate }); //set cookie
            $.cookie("invntryTimeZone", TimeZone, { expires: CookieDate }); //set cookie
            $.cookie("invntrystaffCountryId", countryId, { expires: CookieDate }); //set cookie

            //  showProfileHeader(1);

            getCounts();

            //alert($.cookie("staffCountryId"));

        }
        //Stop:Change Branch

        function showBranches() {
            var userid = $.cookie("invntrystaffId");
            loading();
           // alert("ok");
            $.ajax({
                type: "POST",
                url: "dashboard.aspx/showBranchesInLogin",
                data: "{'userid':'" + userid + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    // alert(msg.d);
                    var htm = "";
                    Unloading();
                    if (msg.d == "N") {
                        htm += '<option value="0" selected="selected">--None--</option>';
                        $("#comboBranchName").html(htm);
                    } else {
                        var Branchobj = JSON.parse(msg.d);
                        if (Branchobj == "") {
                            alert("Error..!");
                            return;
                        } else {
                            
                            htm += '<option value="0">--None--</option>';
                            $.each(Branchobj, function (i, row) {
                                htm += '<option  value="' + row.branch_id + '" data-timezone="' + row.branch_timezone + '" data-country="' + row.branch_countryid + '">' + row.branch_name + '</option>';
                            });
                            //    alert(htm);
                            $("#comboBranchName").html(htm);
                            $("#comboBranchName").val(branchId);
                            if (branchId == undefined) {
                               // alert(branchId);
                                $("#comboBranchName").prop("selectedIndex", 1);
                                $("#comboBranchName").val(1);
                                changeBranch();
                            } 
                            
                            getCounts();
                            return;
                        }
                    }
                   

                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }


        function getCounts() {
            var branchId = $("#comboBranchName").val();
            var TimeZone = $("#comboBranchName").find('option:selected').attr('data-timezone');
            //  alert(TimeZone);
            if (!branchId) {
                $("#comboBranchName").val(0);
               // location.href = "dashboard.aspx";
                return false;
            }
            loading();
            $.ajax({
                type: "POST",
                url: "dashboard.aspx/getNeworderAndProcessedorderCount",
                data: "{'branchId':'" + branchId + "','TimeZone':'" + TimeZone + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    //  alert(msg.d);
                    Unloading();
                    if (msg.d != "N") {
                        var splitarray = msg.d.split("*");
                        if (splitarray[0] == "N") {
                            $("#txtnewordercount").text("(0)");
                        }
                        else {
                            if (splitarray[0] == "0") {
                                $("#hrefneworder").click(function (e) { e.preventDefault(); });
                            }
                            // alert(splitarray[0]);
                            $("#txtnewordercount").text("(" + splitarray[0] + ")");
                        }
                        if (splitarray[1] == "N") {
                            $("#txtprocessordercount").text("(0)");
                        }
                        else {
                            if (splitarray[1] == "0") {
                                $("#hrefProcessOrder").click(function (e) { e.preventDefault(); });
                            }
                            $("#txtprocessordercount").text("(" + splitarray[1] + ")");
                        }
                        if (splitarray[2] == "N") {
                            $("#txtlowstockcount").text("(0)");
                        }
                        else {
                            if (splitarray[2] == "0") {
                                $("#hrefItems").click(function (e) { e.preventDefault(); });
                            }
                            $("#txtlowstockcount").text("(" + splitarray[2] + ")");
                        }
                        if (splitarray[3] == "N") {
                            $("#txtdisconfirmorderCount").text("(0)");
                        }
                        else {

                            if (splitarray[3] == "0") {
                                $("#hrefconfirmorder").click(function (e) { e.preventDefault(); });
                            }
                            $("#txtdisconfirmorderCount").text("(" + splitarray[3] + ")");
                        }
                        if (splitarray[4] == "N") {
                            $("#txtConfirmCustomers").text("(0)");
                        }
                        else {

                            if (splitarray[4] == "0") {
                                $("#hrefconfirmCustomers").click(function (e) { e.preventDefault(); });
                            }
                            $("#txtConfirmCustomers").text("(" + splitarray[4] + ")");
                        }
                        if (splitarray[5] == "N") {
                            $("#txtOutstandingBillCount").text("(0)");
                        }
                        else {

                            if (splitarray[5] == "0") {
                                $("#hrefOutstandings").click(function (e) { e.preventDefault(); });
                            }
                            $("#txtOutstandingBillCount").text("(" + splitarray[5] + ")");
                        }
                        

                    }
                    else {
                        $("#txtnewordercount").text("(0)");
                        $("#txtprocessordercount").text("(0)");
                        $("#txtlowstockcount").text("(0)");
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

<body class="nav-sm">
    <form id="form1" runat="server">
        <div id="loading" class="loader"></div>
        <div class="container body">
            <div class="main_container">
                <div class="col-md-3 left_col">
                    <div class="left_col scroll-view">
                        <div class="navbar nav_title" style="border: 0;">
                            <a href="index.html" class="site_title"><i class="fa fa-file-text"></i><span>Invoice</span></a>
                        </div>

                        <div class="clearfix"></div>

                        <!-- menu profile quick info -->
                        <div class="profile clearfix">
                            <div class="profile_pic">
                                <img src="images/img.jpg" alt="..." class="img-circle profile_img">
                            </div>
                            <div class="profile_info">
                                <span>Customer ID</span>
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
                            <a data-toggle="tooltip" data-placement="top" title="Logout" href="login.html">
                                <span class="fa fa-power-off" aria-hidden="true"></span>
                            </a>
                        </div>
                        <!-- /menu footer buttons -->
                    </div>
                </div>

                <!-- top navigation -->
                <div class="top_nav">
                    <div class="nav_menu">
                        <nav>
                            <div class="nav toggle">
                                <a id="menu_toggle"><i class="fa fa-bars"></i></a>
                            </div>
                            <ul class="nav navbar-nav navbar-right">
                                <li class="">
                                    <a href="javascript:;" class="user-profile dropdown-toggle" data-toggle="dropdown" aria-expanded="false">
                                        <img src="images/img.jpg" alt="">John Doe
                    <span class=" fa fa-angle-down"></span>
                                    </a>
                                    <ul class="dropdown-menu dropdown-usermenu pull-right">
                                        <li><a href="javascript:;">Profile</a></li>
                                        <li>
                                            <a href="javascript:;">
                                                <span class="badge bg-red pull-right">50%</span>
                                                <span>Settings</span>
                                            </a>
                                        </li>
                                        <li><a href="javascript:;">Help</a></li>
                                        <li><a href="login.html"><i class="fa fa-sign-out pull-right"></i>Log Out</a></li>
                                    </ul>
                                </li>
                            </ul>


                            <!--   <li role="presentation" class="dropdown">
                  <a href="javascript:;" class="dropdown-toggle info-number" data-toggle="dropdown" aria-expanded="false">
                    <i class="fa fa-envelope-o"></i>
                    <span class="badge bg-green">6</span>
                  </a>
                  <ul id="menu1" class="dropdown-menu list-unstyled msg_list" role="menu">
                    <li>
                      <a>
                        <span class="image"><img src="images/img.jpg" alt="Profile Image" /></span>
                        <span>
                          <span>John Smith</span>
                          <span class="time">3 mins ago</span>
                        </span>
                        <span class="message">
                          Film festivals used to be do-or-die moments for movie makers. They were where...
                        </span>
                      </a>
                    </li>
                    <li>
                      <a>
                        <span class="image"><img src="images/img.jpg" alt="Profile Image" /></span>
                        <span>
                          <span>John Smith</span>
                          <span class="time">3 mins ago</span>
                        </span>
                        <span class="message">
                          Film festivals used to be do-or-die moments for movie makers. They were where...
                        </span>
                      </a>
                    </li>
                    <li>
                      <a>
                        <span class="image"><img src="images/img.jpg" alt="Profile Image" /></span>
                        <span>
                          <span>John Smith</span>
                          <span class="time">3 mins ago</span>
                        </span>
                        <span class="message">
                          Film festivals used to be do-or-die moments for movie makers. They were where...
                        </span>
                      </a>
                    </li>
                    <li>
                      <a>
                        <span class="image"><img src="images/img.jpg" alt="Profile Image" /></span>
                        <span>
                          <span>John Smith</span>
                          <span class="time">3 mins ago</span>
                        </span>
                        <span class="message">
                          Film festivals used to be do-or-die moments for movie makers. They were where...
                        </span>
                      </a>
                    </li>
                    <li>
                      <div class="text-center">
                        <a>
                          <strong>See All Alerts</strong>
                          <i class="fa fa-angle-right"></i>
                        </a>
                      </div>
                    </li>
                  </ul>
                </li>
              </ul>-->
                        </nav>
                    </div>
                </div>
                <!-- /top navigation -->

                <!-- page content -->
                <div class="right_col" role="main" id="animate" style="background-color:#ededed">
                    <div class="">
                        <div class="col-md-8 col-sm-12 col-xs-2" style="text-align: right; margin-top: 5px; padding-right: 0px;">
                            <label>Warehouse</label>
                        </div>
                        <div class="col-md-4 col-sm-12 col-xs-8 pull-right" style="margin-bottom: 10px;">
                            <select class="form-control" id="comboBranchName" onchange="changeBranch();">
                                <%--<option>--Warehouse--</option>--%>
                            </select>
                        </div>
                        <div class="clearfix"></div>
                       
                        <div class="row top_tiles">
                           
                            <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12">
                                <div class="ln_solid"></div>
                                <h3 style="margin-top:10px;color:#276ea1">Invoice Me : <small style="color:#808080">Quick Links</small> </h3>
                            </div>
                            
                            <%-- Add New Order Start --%>
                            <div class="animated flipInY col-lg-2 col-md-3 col-sm-6 col-xs-12">
                                <a href="web_sales/neworder.aspx">
                                    <div class="tile-stats">
                                        <div class="icon" style="color:#276ea1"><i class="fa fa-star-o"></i></div>
                                        <div class="clear"></div>
                                        <div style="padding-top: 40px; margin-bottom: 10px; text-align: center; font-weight: bold;">Add New Order<ui id="txtAttendanceCount"></ui></div>
                                        <div class="clearfix"></div>
                                    </div>
                                </a>
                            </div>
                            <%-- Add nNew Order End --%>

                            <%-- Orders to Confirm Start --%>
                            <div class="animated flipInY col-lg-2 col-md-3 col-sm-6 col-xs-12">
                                <a id="hrefconfirmorder" href="web_sales/Orders.aspx?orderStatus=3">
                                    <div class="tile-stats">
                                        <div class="icon" style="color:#276ea1"><i class="fa fa-check"></i></div>
                                        <div class="clear"></div>
                                        <div style="padding-top: 40px; margin-bottom: 10px; text-align: center; font-weight: bold;">Orders to Confirm<ui id="txtdisconfirmorderCount"></ui></div>
                                        <div class="clearfix"></div>
                                    </div>
                                </a>
                            </div>
                            <%-- Orders to Confirm end --%>
                            <%-- Customers to Confirm Start --%>
                            <div class="animated flipInY col-lg-2 col-md-3 col-sm-6 col-xs-12">
                                <a id="hrefconfirmCustomers" href="Web_Customer/Customers.aspx?cusConfirm=1">
                                    <div class="tile-stats">
                                        <div class="icon" style="color:#276ea1"><i class="fa fa-check"></i></div>
                                        <div class="clear"></div>
                                        <div style="padding-top: 40px; margin-bottom: 10px; text-align: center; font-weight: bold;">Customers to Confirm<ui id="txtConfirmCustomers"></ui></div>
                                        <div class="clearfix"></div>
                                    </div>
                                </a>
                            </div>
                            <%-- Customers to Confirm end --%>
                            <%-- Low Stock start --%>
                            <div class="animated flipInY col-lg-2 col-md-3 col-sm-6 col-xs-12">
                                <a id="hrefItems" href="web_inventory/warehousemanagement.aspx?stock=2">
                                    <div class="tile-stats">
                                        <div class="icon" style="color:#276ea1"><i class="fa fa-level-down"></i></div>
                                        <div class="clear"></div>
                                        <div style="padding-top: 40px; margin-bottom: 10px; text-align: center; font-weight: bold;">Low Stock<ui id="txtlowstockcount"></ui></div>
                                        <div class="clearfix"></div>
                                    </div>
                                </a>
                            </div>
                            <%-- Low Stock Start --%>

                            <%-- Outstanding Orders Start --%>
                            <div class="animated flipInY col-lg-2 col-md-3 col-sm-6 col-xs-12">
                                <a id="hrefOutstandings" href="web_sales/Orders.aspx?paymentStatus=2">
                                    <div class="tile-stats">
                                        <div class="icon" style="color:#276ea1"><i class="fa fa-file-text"></i></div>
                                        <div class="clear"></div>
                                        <div style="padding-top: 40px; margin-bottom: 10px; text-align: center; font-weight: bold;">Outstanding Orders<ui id="txtOutstandingBillCount"></ui></div>
                                        <div class="clearfix"></div>
                                    </div>
                                </a>
                            </div>
                            <%--Outstanding Orders End--%>
                            <%-- New Orders Start --%>
                            <div class="animated flipInY col-lg-2 col-md-3 col-sm-6 col-xs-12">
                                <a id="hrefneworder" href="web_sales/Orders.aspx?orderStatus=0">
                                    <div class="tile-stats">
                                        <div class="icon" style="color:#276ea1"><i class="fa fa-star"></i></div>
                                        <div class="clear"></div>
                                        <div style="padding-top: 40px; margin-bottom: 10px; text-align: center; font-weight: bold;">New Orders<ui id="txtnewordercount"></ui></div>
                                        <div class="clearfix"></div>
                                    </div>
                                </a>
                            </div>
                            <%-- New Orders End --%>


                            <%--  Users start --%>
                            <div class="animated flipInY col-lg-2 col-md-3 col-sm-6 col-xs-12">
                                <a href="web_opcenter/users.aspx">
                                    <div class="tile-stats">
                                        <div class="icon" style="color:#276ea1"><i class="fa fa-user"></i></div>
                                        <div class="clear"></div>
                                        <div style="padding-top: 40px; margin-bottom: 10px; text-align: center; font-weight: bold;">Users</div>
                                        <div class="clearfix"></div>
                                    </div>
                                </a>
                            </div>
                            <%--  Users End --%>
                            <%-- Customers Start --%>
                            <div class="animated flipInY col-lg-2 col-md-3 col-sm-6 col-xs-12">
                                <a href="Web_Customer/Customers.aspx">
                                    <div class="tile-stats">
                                        <div class="icon" style="color:#276ea1"><i class="fa fa-users"></i></div>
                                        <div class="clear"></div>
                                        <div style="padding-top: 40px; margin-bottom: 10px; text-align: center; font-weight: bold;">Customers</div>
                                        <div class="clearfix"></div>
                                    </div>
                                </a>
                            </div>
                            <%-- Customers End --%>
                            
                                 <%-- Warehouse start --%>
                            <div class="animated flipInY col-lg-2 col-md-3 col-sm-6 col-xs-12">
                                <a href="web_inventory/warehouse.aspx">
                                    <div class="tile-stats">
                                        <div class="icon" style="color:#276ea1"><i class="fa fa-sitemap"></i></div>
                                        <div class="clear"></div>
                                        <div style="padding-top: 40px; margin-bottom: 10px; text-align: center; font-weight: bold;">Warehouses</div>
                                        <div class="clearfix"></div>
                                    </div>
                                </a>
                            </div>
                            <%-- Warehouse End --%>
                            <%-- Item Master Start --%>
                            <div class="animated flipInY col-lg-2 col-md-3 col-sm-6 col-xs-12">
                                <a href="web_inventory/itemmaster.aspx">
                                    <div class="tile-stats">
                                        <div class="icon" style="color:#276ea1"><i class="fa fa-cubes"></i></div>
                                        <div class="clear"></div>
                                        <div style="padding-top: 40px; margin-bottom: 10px; text-align: center; font-weight: bold;">Item Master</div>
                                        <div class="clearfix"></div>
                                    </div>
                                </a>
                            </div>
                            <%-- Item Master end --%>



                            <%-- Stock Management Start --%>
                            <div class="animated flipInY col-lg-2 col-md-3 col-sm-6 col-xs-12">
                                <a href="web_inventory/warehousemanagement.aspx">
                                    <div class="tile-stats">
                                        <div class="icon" style="color:#276ea1"><i class="fa fa-archive"></i></div>
                                        <div class="clear"></div>
                                        <div style="padding-top: 40px; margin-bottom: 10px; text-align: center; font-weight: bold;">Stock Management</div>
                                        <div class="clearfix"></div>
                                    </div>
                                </a>
                            </div>
                            <%-- Stock Management End --%>



                       

                            <%-- Settings start --%>
                            <div class="animated flipInY col-lg-2 col-md-3 col-sm-6 col-xs-12">
                                <a href="settings.aspx">
                                    <div class="tile-stats">
                                        <div class="icon" style="color:#276ea1"><i class="fa fa-gears"></i></div>
                                        <div class="clear"></div>
                                        <div style="padding-top: 40px; margin-bottom: 10px; text-align: center; font-weight: bold;">Settings</div>
                                        <div class="clearfix"></div>
                                    </div>
                                </a>
                            </div>
                            <%-- Settings End --%>



                            <%-- Reports Start --%>
                            <div class="animated flipInY col-lg-2 col-md-3 col-sm-6 col-xs-12">
                                <a href="web_reports/salesreportsadvance.aspx">
                                    <div class="tile-stats">
                                        <div class="icon" style="color:#276ea1"><i class="fa fa-file-text-o"></i></div>
                                        <div class="clear"></div>
                                        <div style="padding-top: 40px; margin-bottom: 10px; text-align: center; font-weight: bold;">Sales Report</div>
                                        <div class="clearfix"></div>
                                    </div>
                                </a>
                            </div>
                            <%-- Reports End --%>
                                                        <%-- Sales Overview Start --%>
                            <div class="animated flipInY col-lg-2 col-md-3 col-sm-6 col-xs-12">
                                <a href="web_reports/salesoverview.aspx">
                                    <div class="tile-stats">
                                        <div class="icon" style="color:#276ea1"><i class="fa fa-truck"></i></div>
                                        <div class="clear"></div>
                                        <div style="padding-top: 40px; margin-bottom: 10px; text-align: center; font-weight: bold;">Sales Overview</div>
                                        <div class="clearfix"></div>
                                    </div>
                                </a>

                            </div>
                            <%-- Sales Overview End --%>
                        </div>

                        <div class="container">

                            <%--  <!-- Trigger the modal with a button -->
  <button type="button" class="btn btn-info btn-lg" data-toggle="modal" data-target="#myModal">Open Modal</button>--%>

                            <!-- Modal -->
                            <div class="modal fade" id="myModal" role="dialog">
                                <div class="modal-dialog">

                                    <!-- Modal content-->
                                    <div class="modal-content">
                                        <div class="modal-header">
                                            <button type="button" class="close" data-dismiss="modal">&times;</button>
                                            <h4 class="modal-title">Modal Header</h4>
                                        </div>
                                        <div class="modal-body">
                                            <p>Some text in the modal.</p>
                                        </div>
                                        <div class="modal-footer">
                                            <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                                        </div>
                                    </div>

                                </div>
                            </div>

                        </div>
                    </div>

                    <%--<div class="row">
<div class="col-md-12 col-sm-12 col-xs-12">
<div class="dashboard_graph x_panel">
<div class="row x_title">
<div class="col-md-6">
<h3>Network Activities <small>Graph title sub-title</small></h3>
</div>
<div class="col-md-6">
<div id="reportrange" class="pull-right" style="background: #fff; cursor: pointer; padding: 5px 10px; border: 1px solid #ccc">
<i class="glyphicon glyphicon-calendar fa fa-calendar"></i>
<span>January 4, 2019 - February 2, 2019</span> <b class="caret"></b>
</div>
</div>
</div>
<div class="x_content">
<div class="demo-container" style="height:250px">
<div id="chart_plot_03" class="demo-placeholder" style="padding: 0px; position: relative;"><canvas class="flot-base" width="477" height="350" style="direction: ltr; position: absolute; left: 0px; top: 0px; width: 382px; height: 280px;"></canvas><div class="flot-text" style="position: absolute; top: 0px; left: 0px; bottom: 0px; right: 0px; font-size: smaller; color: rgb(84, 84, 84);"><div class="flot-x-axis flot-x1-axis xAxis x1Axis" style="position: absolute; top: 0px; left: 0px; bottom: 0px; right: 0px; display: block;"><div class="flot-tick-label tickLabel" style="position: absolute; max-width: 47px; top: 264px; left: 11px; text-align: center;">0.0</div><div class="flot-tick-label tickLabel" style="position: absolute; max-width: 47px; top: 264px; left: 66px; text-align: center;">2.5</div><div class="flot-tick-label tickLabel" style="position: absolute; max-width: 47px; top: 264px; left: 121px; text-align: center;">5.0</div><div class="flot-tick-label tickLabel" style="position: absolute; max-width: 47px; top: 264px; left: 176px; text-align: center;">7.5</div><div class="flot-tick-label tickLabel" style="position: absolute; max-width: 47px; top: 264px; left: 228px; text-align: center;">10.0</div><div class="flot-tick-label tickLabel" style="position: absolute; max-width: 47px; top: 264px; left: 283px; text-align: center;">12.5</div><div class="flot-tick-label tickLabel" style="position: absolute; max-width: 47px; top: 264px; left: 338px; text-align: center;">15.0</div></div><div class="flot-y-axis flot-y1-axis yAxis y1Axis" style="position: absolute; top: 0px; left: 0px; bottom: 0px; right: 0px; display: block;"><div class="flot-tick-label tickLabel" style="position: absolute; top: 252px; left: 7px; text-align: right;">0</div><div class="flot-tick-label tickLabel" style="position: absolute; top: 220px; left: 7px; text-align: right;">5</div><div class="flot-tick-label tickLabel" style="position: absolute; top: 189px; left: 1px; text-align: right;">10</div><div class="flot-tick-label tickLabel" style="position: absolute; top: 157px; left: 1px; text-align: right;">15</div><div class="flot-tick-label tickLabel" style="position: absolute; top: 126px; left: 1px; text-align: right;">20</div><div class="flot-tick-label tickLabel" style="position: absolute; top: 95px; left: 1px; text-align: right;">25</div><div class="flot-tick-label tickLabel" style="position: absolute; top: 63px; left: 1px; text-align: right;">30</div><div class="flot-tick-label tickLabel" style="position: absolute; top: 32px; left: 1px; text-align: right;">35</div><div class="flot-tick-label tickLabel" style="position: absolute; top: 1px; left: 1px; text-align: right;">40</div></div></div><canvas class="flot-overlay" width="477" height="350" style="direction: ltr; position: absolute; left: 0px; top: 0px; width: 382px; height: 280px;"></canvas><div class="legend"><div style="position: absolute; width: 78px; height: 15px; top: 13px; right: 16px; background-color: rgb(255, 255, 255); opacity: 0.85;"> </div><table style="position:absolute;top:13px;right:16px;;font-size:smaller;color:#545454"><tbody><tr><td class="legendColorBox"><div style="border:1px solid #ccc;padding:1px"><div style="width:4px;height:0;border:5px solid rgb(38,185,154);overflow:hidden"></div></div></td><td class="legendLabel">Registrations</td></tr></tbody></table></div></div>
</div>
</div>
</div>
</div>
</div>--%>
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
    </form>
    <%--        <!-- jQuery -->
    <script src="js/bootstrap/jquery.min.js"></script>--%>
    <!-- Bootstrap -->
    <script src="js/bootstrap/bootstrap.min.js"></script>
    <!-- FastClick -->
    <script src="js/bootstrap/fastclick.js"></script>
    <!-- NProgress -->
    <script src="js/bootstrap/nprogress.js"></script>


    <!-- Custom Theme Scripts -->
    <script src="js/bootstrap/custom.min.js"></script>
    <script src="js/bootbox.min.js"></script>
</body>
</html>
                                  