<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Manage_Conversions.aspx.cs" Inherits="web_inventory_Manage_Conversions" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Manage Item Conversions  | Invoice Me</title>

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

        var src_array = [];
        var dest_array = [];
        var sel_src_itbs = -1;
        var sel_dest_itbs = -1;
        var sel_src_item_name = -1;
        var sel_dest_item_name = -1;
        var currnt_session_id = 0;
        currnt_session_id = getSessionID();

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

            search_Conversions(1);
        });
       
        function getSessionID() {

            var now = new Date();
            var year = now.getFullYear();
            var month = now.getMonth() + 1;
            var day = now.getDate();
            var hour = now.getHours();
            var minute = now.getMinutes();
            var second = now.getSeconds();
            if (month.toString().length == 1) {
                var month = '0' + month;
            }
            if (day.toString().length == 1) {
                var day = '0' + day;
            }
            if (hour.toString().length == 1) {
                var hour = '0' + hour;
            }
            if (minute.toString().length == 1) {
                var minute = '0' + minute;
            }
            if (second.toString().length == 1) {
                var second = '0' + second;
            }

            var salesman_id = $.cookie("invntrystaffId");

            sessionId = String(year) + String(month) + String(day) + String(hour) + String(minute) + String(second) + String(salesman_id);
            return sessionId;
            //alert(sessionId);
        }

        function dateformat(idate) {

            var med = idate.split("-");
            var dd = med[0];
            var mm = med[1];
            var yy = med[2];

            var nDate = yy + '-' + mm + '-' + dd;
            return nDate;

        }

        function reset_filters() {

            $("#Select_Warehouse").val(-1);
            $("#Select_user").val(-1);
            $("#Text_date_from").val('');
            $("#Text_date_to").val('');
            search_Conversions(1);
        }


        function search_Conversions(page) {

            var postObj = {
                page: page,
                perpage: 50,
                filters: {}
            };
            if ($("#Select_Warehouse").val() != "-1") {
                postObj.filters.branch_id = $("#Select_Warehouse").val();
            }

            if ($("#Select_user").val() != "-1") {
                postObj.filters.user_id = $("#Select_user").val();
            }

            if ($("#Text_date_from").val() != "") {
                postObj.filters.date_from = dateformat($("#Text_date_from").val());
            }

            if ($("#Text_date_to").val() != "") {
                postObj.filters.date_to = dateformat($("#Text_date_to").val());
            }
            
            $("#tblConvItems tbody").html("");

            $.ajax({
                type: "POST",
                url: "Manage_Conversions.aspx/Get_Conversions",
                data: JSON.stringify(postObj),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    
                    console.log(msg.d);
                    if (msg.d == "N") {

                        $("#lblcount").html('0');
                        $('#tblConvItems  tbody').html("<tr class=''><td colspan='8' align='center' style='font-weight:bold; padding:8px;'>No Conversions Found</td></tr>");
                        $("#paginatediv").hide();                        
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
                            htm += '<td class="text-left"># ' + rows.conv_id + '</td>';
                            htm += '<td class="text-left "><strong>' + rows.branch_name + '</strong></td>';
                            htm += '<td class="text-left" style="color:#494646">' + rows.input_items + '</td>';
                            htm += '<td class="text-left" style="color:#494646">' + rows.output_items + '</td>';
                            htm += '<td class="text-left"><b>' + rows.username + '</b></td>';
                            htm += '<td class="text-left" style="color:#2e6da4">' + rows.conv_date + '<br /><small style="color:gray">' + rows.conv_time + '</small></td>';
                            htm += '<td class="text-left"> <a href="Edit_Item_Conversion.aspx?convid=' + rows.conv_id + '" class="btn btn-primary btn-xs"><li class="fa fa-edit" style="font-size:large;"></li></a></td>';
                            htm += '<td class="text-left"><a href="Print_Conversion.aspx?convid=' + rows.conv_id + '" class="btn btn-info btn-xs"><li class="fa fa-print" style="font-size:large;"></li></a></td> </tr>';
                            

                        });

                    }
                                
                    $('#tblConvItems  tbody').html(htm);

                    $("#paginatediv").show();
                    $("#paginatediv").html(paginate(obj.count, 50, page, "search_Conversions"));


                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }

        //end

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
                            <label style="font-weight: 400; font-size: 14px;">Warehouse \ Manage Item Convertions</label>

                        </div>

                    </nav>
                </div>
            </div>
            <!-- /top navigation -->

            <!-- page content -->
            <div class="right_col" role="main">
                <div class="">
                    
                                   
                       
                    <div class="row">
<div class="col-md-12 col-xs-12">

<div class="x_panel">
<div class="x_title">
<h2> Manage Item Conversions <span class="badge" style="color: #fff; margin-left: 5px; background: #d00101; padding-left: 5px; padding-right: 5px;" id="lblcount">0</span></h2>

<div class="clearfix"></div>
</div>
<div class="x_content">


                                        <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback" >
                                          
                                                <label for="heard">Warehouse:</label>
<select id="Select_Warehouse" class="form-control" required="" runat="server" onchange="search_Conversions(1);">

</select>
                                           
                                        </div>

    <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                          
                                                <label for="heard">User:</label>
<select id="Select_user" class="form-control" required="" runat="server" onchange="search_Conversions(1)">

</select>
                                           
                                        </div>

    <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                          
                                                <label for="heard">Date From:</label>
<input id="Text_date_from" type="text" class="form-control" required="" style="background-color:#ffffff" />
                                           
                                        </div>

    <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                          
                                                <label for="heard">Date Upto:</label>
<input id="Text_date_to" type="text" class="form-control" required="" style="background-color:#ffffff" />
                                           
                                        </div>
                                       

          <div class="col-md-12 col-sm-12 col-xs-12 form-group" style="text-align:right;margin-bottom:15px;margin-top:5px">
                                                                                                                        
              <div onclick="javascript:reset_filters();" style="color: #6f6e6e;background-color:#dddddd;" class="btn">RESET</div>
              <div onclick="javascript:search_Conversions(1);"  class="btn btn-primary">SEARCH</div>

                                        </div>                               

                                 

    <table class="table table-striped jambo_table bulk_action " id="tblConvItems">
                                    <thead style="background-color:#f1eeee;color:#525252">
                                        <tr class="headings">
                                            <th></th>
                                            <%--<th class="column-title">Sl No. </th>--%>
                                            <th class="column-title">Ref. ID </th>
                                            <th class="column-title">Warehouse </th>
                                            <th class="column-title">Input Item(s) </th>
                                            <th class="column-title">Output Item(s) </th>
                                            <th class="column-title">Converted By </th>
                                            <th class="column-title">Date </th>

                                            <th class="column-title no-link last"><span class="nobr"></span></th>
                                            <th class="column-title no-link last"><span class="nobr"></span>
                                            </th>

                                        </tr>
                                    </thead>
                                    <tbody id="src_itm_list"><td colspan="8" style="text-align:center">No Conversions Found</td></tbody>
                                </table>
    <div id="paginatediv" style="text-align: center;"></div>
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
                            Copyright 2019 ©
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
