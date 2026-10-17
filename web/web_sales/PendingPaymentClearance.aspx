<%@ Page Language="C#" AutoEventWireup="true" CodeFile="PendingPaymentClearance.aspx.cs" Inherits="web_sales_PendingPaymentClearance" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Pending Payment Clearance | Invoice Me</title>
    <script src="../js/common.js" type="text/javascript"></script>
    <script type="text/javascript" src="../js/jquery-2.0.3.js"></script>

    <script type="text/javascript" src="../js/jquery.cookie.js"></script>
    <script type="text/javascript" src="../js/jQuery.print.js"></script>
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
        // console.log(actionTypes);
        $(document).ready(function () {
            BranchId = $.cookie("invntrystaffBranchId");
            if (!BranchId) {
                location.href = "../dashboard.aspx";
                return false;
            }            
           // ShowUTCDate();
            show_Pending_Clearances(1);
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
            //showsalespersons();
            //showDailyReports(1);
        }//end
        function GetMonthName(monthNumber) {
            var months = ['01', '02', '03', '04', '05', '06',
            '07', '08', '09', '10', '11', '12'];
            return months[monthNumber - 1];

        }//end

        function resetFilter() {

            $("#selLocations").val(-1);
            show_Pending_Clearances(1);
        }

        function show_Pending_Clearances(page) {

            var postObj = {
               
                filters: {
                    page: page,
                }
            }
        
            if ($("#selLocations").val() && $("#selLocations").val() != "-1" && $("#selLocations").val() != "") {
                postObj.filters.location_id = $("#selLocations").val();
            }
           
            $.ajax({
                type: "POST",
                url: "PendingPaymentClearance.aspx/getCustomerswithBalance",
                data: JSON.stringify(postObj),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {

                    var obj = JSON.parse(msg.d);
                                       
                    var htm = "";
                    var sl_no = 1;
                    $('#tblCustomers > tbody').html("");
                   
                    if (obj.totalRows == 0) {
                      
                        htm += '<td colspan="5" style="text-align:center"></div></div><div class="cl" style="height:5px;"></div><label>Empty</label></td>';                        
                        $('#tblCustomers > tbody').html(htm);

                    } else {
                       
                        $.each(obj.customer_list, function (i, row) {
                            //$("#txttotalordercount").text(obj.totalRows);

                            htm += '<tr>';
                            htm += '<td> <b>' + sl_no + '</b></td > <td><a href="../Web_Customer/managecustomers.aspx?cusId=' + row.cust_id + '" target="_blank" ><b style="font-size:15px">' + row.cust_name + '</b></a>';
                            htm += '<br><small>' + row.cust_address +','+ row.cust_city +'</small></td>';
                            htm += ' <td style="text-align:center;color:#b42222"><b>' + row.balance_to_clear + '</b></td>';
                            htm += ' <td class="project_progress" style="text-align:center;color:#1e9928"><b>' + row.available_to_clear + '</b></td>';
                            htm += ' <td ><a href="../web_sales/orders.aspx?customerid=' + row.cust_id + '" target="_blank" class="btn btn-primary btn-xs" style="font-size:13px"><i class="fa fa-eye"></i> View Orders </a><a href="../Web_Customer/transactionHistory.aspx?customerid=' + row.cust_id + '" target="_blank" class="btn btn-success btn-xs" style="font-size:13px"><i class="fa fa-money"></i> Transactions </a></td>';
                            htm += '</tr>';
                            sl_no++;                            
                        });

                        $('#tblCustomers > tbody').html(htm);  
                        var html = "";
                        html += '<tr>';
                        html += '<td colspan="5">';
                        html += '<div  id="divPagination" style="text-align: center;">';
                        html += '</div>';
                        html += '</td>';
                        html += '</tr>';
                        $('#tblCustomers > tbody').append(html);

                        $('#divPagination').html(paginate(obj.totalRows, 100, page, "show_Pending_Clearances"));
                    }

                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }
     
        

    </script>


    <style media="print">
        @page {
            size: auto;
            margin: 0;
        }

        thead {
            display: table-header-group;
        }
    </style>


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
                            <label style="font-weight: bold; font-size: 16px;">Pending Payment Clearance<%--<small><br /> Clear Orders using Customer's Wallet Credits</small>--%> </label>

                        </div>

                    </nav>
                </div>
            </div>

            <!-- /top navigation -->
            <!-- page content -->

            <div id="divReportContent">

                <div class="right_col" role="main" id="">
                    <div class="">
                        <div class="page-title">
                            <%--  <div class="title_left">
                <h3>Sales Advanced Report</h3>
              </div> --%>
                        </div>

                        <div class="clearfix"></div>

                        <div class="row">
                            <div class="col-md-12 col-sm-12 col-xs-12">
                                <div class="x_panel" style="padding-left: 5px; padding-right: 5px;">
                                   
                                    <div class="x_content">

                                        <section class="content invoice">
                                            <div class="col-md-12 col-sm-6 col-xs-12 form-group has-feedback">
                                              
                                              
                                                <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback" id="div1">
                                                    <div id="Div2">
                                                        <select id="selLocations" style="text-indent: 25px; padding-right: 5px;" class="form-control" onchange="javascript:show_Pending_Clearances(1);" runat="server">
                                                        </select>
                                                    </div>
                                                    <span aria-hidden="true" class="fa fa-users form-control-feedback left"></span>
                                                </div>
                                                
                                

                                                <div class="col-md-2 col-sm-6 col-xs-12 form-group">
                                                    <button id="btnreset" style="font-size: 13px; padding: 4px; font-weight: bold;" class="btn btn-primary pull-right" type="button" onclick="javascript:resetFilter();">
                                                        <li style="margin-right: 5px;" class="fa fa-refresh"></li>
                                                        Reset 
                                                    </button>

                                                    <button id="btnsearch" style="font-size: 13px; padding: 4px; font-weight: bold;" class="btn btn-success pull-right" type="button" onclick="javascript:show_Pending_Clearances(1);">
                                                        <li style="margin-right: 5px;" class="fa fa-search"></li>
                                                        Search 
                                                    </button>

                                                </div>
                                            </div>

                                            <div class="row">

                                                <!-- /.col -->
                                            </div>
                                         



                                           <div class="row">
              <div class="col-md-12">
                <div class="x_panel">
                  <div class="x_title">
                    <h2 style="font-weight:700">Customer List</h2>
                    
                    <ul class="nav navbar-right panel_toolbox">
                      <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                      </li>
                                          
                    </ul>
                    <div class="clearfix"></div>
                  </div>
                  <div class="x_content" style="overflow-x: auto;">

                    <p style="font-weight:600;color:#000000">Only the Customers with Wallet Amount & Outstanding Orders are shown below:</p>

                    <!-- start project list -->
                    <table class="table table-striped projects" style="table-layout: auto;" id="tblCustomers">
                      <thead style="font-size:14px;color:#406dc9">
                        <tr>
                          <th >#</th>
                          <th >Customer Details</th>
                          <th>Order Balance to Clear</th>
                          <th>Available Wallet Credits</th>                          
                          <th># Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        
                       
                      </tbody>
                    </table>
                    <!-- end project list -->

                  </div>
                </div>
              </div>
            </div>

                                        </section>
                                    </div>
                                </div>
                            </div>
                        </div>
                      
                          
                                            
                          
                          <div class="clearfix"></div>

                    </div>
                </div>
                <!-- /page content -->

            </div>
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

