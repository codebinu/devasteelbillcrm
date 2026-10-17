<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Print_StockTransfer.aspx.cs" Inherits="web_reports_Print_StockTransfer" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Print Stock Transfer  | Invoice Me</title>

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

        var stDatas;

        stDatas = <%=stDatas%>

        
        $(document).ready(function () {

            var BranchId = $.cookie("invntrystaffBranchId");
            var CountryId = $.cookie("invntrystaffCountryId");           
            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " © ");

            load_stock_transfer_data();            

        });

        function load_stock_transfer_data(){
        
            var basic_details = stDatas.basedata[0];

            $("#Div_lbl_hdr").html('<h4> Ref ID : #' + basic_details.st_id + ' <br /> <small><b>Source Warehouse :</b></small> ' + basic_details.sr_branch + '<br /> <small><b>Destination Warehouse :</b></small> ' + basic_details.dr_branch + '<br /><small><b>Date :</b> ' + basic_details.st_date + '</small><br /><small><b>User :</b> ' + basic_details.username + '</small></h4>');

            var htm = "";
            $.each(stDatas.itemdata, function (i, item) {
                
                htm += '<tr class="even pointer">';
                htm += '<td class="text-left" style="width:50px">' + (i +1 ) + '</td>';
                htm += '<td class="text-left "><strong>' + item.itm_name + '</strong></td>';
                htm += '<td class=" text-center" >' + item.sti_quantity + '</td>';
                htm += '</tr>';

            });

            $('#Tbody2').html(htm);
        }

        function print_st(){
        
            $("#btn_btn").hide();
            window.print();
            $("#btn_btn").show();
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

                        <div class="navbar-header" style="width: 100%; display:flex; align-items: center">
                            <div class="nav toggle" style="padding: 5px;">
                                <a id="menu_toggle"><i class="fa fa-bars"></i></a>
                            </div>
                            <label style="font-weight: 400; font-size: 14px;">Stock Transfer</label>

                        </div>

                    </nav>
                </div>
            </div>
            <!-- /top navigation -->
            
            <!-- page content -->
            <div class="right_col" role="main" id="print_div">
                <div class="">

                   <div class="form-group" id="btn_btn">
                                        <div class="col-md-12 col-sm-12 col-xs-12">
                                           
                                            <div onclick="javascript:print_st();" style="margin-bottom:20px" class="btn btn-success">Print Stock Transfer</div>

                                        </div>
                                    </div>

                    <div class="row">

                        <div class="col-md-12 col-sm-12 col-xs-12" id="Div3">
                            <div class="x_panel">
                                <div class="x_content">

                                    <form id="Form2" data-parsley-validate class="form-horizontal form-label-left">
                                       

                                        <div class="col-md-12 col-sm-12 col-xs-12" id="Div_lbl_hdr" style="border:1px solid #d2cccc">
                            
                        </div>

                                    </form>

                                    <div class="clearfix"></div>

                                </div>
                            </div>
                        </div>

                        
                       

                    </div>
                  
                   
                    
                    
                    <div class="row">
<div class="col-md-12 col-sm-12 col-xs-12">

<div class="x_panel">
<div class="x_title">
<h2> Particulars </h2>

<div class="clearfix"></div>
</div>
<div class="x_content">

  

    <div class="col-md-12 col-sm-12 col-xs-12">
                                            
                                            <table class="table table-striped jambo_table bulk_action">
                                    <thead style="background-color:#566777">
                                        <tr class="headings">                                            
                                            <th class="column-title">Sl. </th>
                                            <th class="column-title">Item Name </th>
                                            <th class="column-title">Transferred Qty </th>                                                                                                                             
                                        </tr>
                                    </thead>
                                    <tbody id="Tbody2">

                                      
                                    </tbody>
                                </table>

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
                    <%--<div class="footerDiv">
                        <div class="footerDivContent">
                            Copyright 2017 ©
                        </div>
                    </div>--%>
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
