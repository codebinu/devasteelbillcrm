<%@ Page Language="C#" AutoEventWireup="true" CodeFile="list_salesreturns.aspx.cs" Inherits="web_sales_list_salesreturns" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Sales Returns  | Invoice Me</title>
    <script src="../js/common.js" type="text/javascript"></script>
    <script type="text/javascript" src="../js/jquery-2.0.3.js"></script>

    <script type="text/javascript" src="../js/jquery.cookie.js"></script>
    <script src="../js/pagination.js" type="text/javascript"></script>

    <!-- Bootstrap -->
    <link href="../css/bootstrap/bootstrap.min.css" rel="stylesheet" />
    <!-- Font Awesome -->
    <link href="../css/font-awesome/css/font-awesome.min.css" rel="stylesheet" />
    <!-- NProgress -->
    <link href="../css/bootstrap/nprogress.css" rel="stylesheet" />
    <!-- bootstrap-daterangepicker -->
    <link href="../css/bootstrap/daterangepicker.css" rel="stylesheet" />

    <!-- Custom Theme Style -->
    <link href="../css/bootstrap/custom.min.css" rel="stylesheet" />
    <!--My Styles-->
    <link href="../css/bootstrap/mystyle.css" type="text/css" rel="stylesheet" />
    <!--date picker-->
    <link rel="stylesheet" href="../mobiscroll/css/jquery.mobile-1.1.0.min.css" />
    <script src="../mobiscroll/js/mobiscroll-2.0rc3.full.min.js" type="text/javascript"></script>
    <link href="../mobiscroll/css/mobiscroll-2.0rc3.full.min.css" rel="stylesheet" type="text/css" />
    <!--date picker-->

    <link href="../css/bootstrap/mystyle.css" rel="stylesheet" />

    <script type="text/javascript">
        var BranchId;
        $(document).ready(function () {

            // console.log(JSON.parse($.cookie("search-data")));
            ////alert(history.previous);
            //if (document.referrer == previousPageURL) {
            //    alert("Its a back button click...");
            //    //Specific code here...
            //}
            BranchId = $.cookie("invntrystaffBranchId");
            if (!BranchId) {
                location.href = "../dashboard.aspx";
                return false;
            }

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
                // dateFormat: 'dd-MM-yy'
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
                //dateFormat: 'dd-MM-yy'
            });
            getBranches();
            //   takeQuerystring();
            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " ©");

            //// resetFilters();

        });

        function getBranches() {
            loading();
            $.ajax({
                type: "POST",
                url: "list_salesreturns.aspx/getBranches",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    var obj = JSON.parse(msg.d);
                    var htm = "";
                    htm += '<option value="-1" selected="selected">--All Warehouses--</option>';
                    $.each(obj, function (i, row) {
                        htm += '<option value="' + row.branch_id + '">' + row.branch_name + '</option>';
                    });
                    $("#slBranch").html(htm);
                    showsalespersons();
                    //     $("#slBranch").val(BranchId);




                },
                error: function (xhr, status) {
                    Unloading();
                    // alert("fail" + status + ":::" + xhr.d);
                    alert("Internet Problem..!");
                }
            });
        }

        // Show sales person
        function showsalespersons() {
            loading();
            $.ajax({
                type: "POST",
                url: "list_salesreturns.aspx/showsalespersons",
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
                        $("#comboSalesPerson").html(msg.d);
                        //  alert(getQueryString("sellerId"));
                        if (getQueryString("sellerId") != undefined && getQueryString("sellerId") != "") {
                            $("#comboSalesPerson").val(getQueryString("sellerId"));
                        }
                     
                            //  alert(searchObject.seller_id);
                            searchReturns(1);

                        } 
                    
                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }//end


        function searchReturns(page) {
            var filters = {};
            var perpage = $("#slPerpage").val();
            var branchId = $.cookie("invntrystaffBranchId");
            // alert(branchId);
            var CountryId = $.cookie("invntrystaffCountryId");

            if ((!branchId || branchId == "undefined" || branchId == "" || branchId == "null") || (!CountryId || CountryId == "undefined" || CountryId == "" || CountryId == "null")) {
                location.href = "../dashboard.aspx";
                return false;
            }
            if ($("#txtCustSearch").val() != "" && $("#txtCustSearch").val() != undefined) {
                filters.custSearch = $("#txtCustSearch").val();
            }

            if ($("#slBranch").val() != undefined) {
                filters.branch = $("#slBranch").val();
            }
            else {
                //  setting branch from cookie if branches are not loaded
                filters.branch = BranchId;
            }


            if ($("#slReturnStatus").val() != -1 && $("#slReturnStatus").val() != undefined) {
                filters.return_status = $("#slReturnStatus").val();
            }
            if ($("#txtSearchFromDate").val() != "" && $("#txtSearchFromDate").val() != undefined) {
                filters.from_date = $("#txtSearchFromDate").val();
            }
            if ($("#txtSearchToDate").val() != "" && $("#txtSearchToDate").val() != undefined) {
                filters.to_date = $("#txtSearchToDate").val();
            }
            if ($("#comboSalesPerson").val() != 0 && $("#comboSalesPerson").val() != undefined) {
                filters.seller_id = $("#comboSalesPerson").val();
            }
       
            $.ajax({
                type: "POST",
                url: "list_salesreturns.aspx/searchReturns",
                data: "{'page':" + page + ",'filters':" + JSON.stringify(filters) + ",'perpage':'" + perpage + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                      console.log(msg.d);
                    var obj = JSON.parse(msg.d);
                    var htm = "";
                    var html = "";
                    var classType = "";
                    $('#tblReturns > tbody').html("");
                    if (obj.count == 0) {
                        //htm += "</div></div><div class='cl' style='height:5px;'></div>";
                        htm += '<td colspan="4" style="text-align:center"></div></div><div class="cl" style="height:5px;"></div><label>Empty</label></td>';
                        $("#txttotalReturnCount").text(0);
                    }
                    $.each(obj.data, function (i, row) {
                        $("#txttotalReturnCount").text(obj.count);
                        //0=New, 1=procesd, 2=deliverd, 3=to be confirm,4=cancel,5=reject
                        var status;
                        var status_class;
                        switch (row.return_status) {
                            case 1: status = "Initiated"; status_class = "label label-warning"; break;
                            case 2: status = "Received"; status_class = "label label-primary"; break;
                            case 3: status = "Approved"; status_class = "label label-success"; break;
                            case 4: status = "cancelled"; status_class = "label label-default"; break;

                        }

                        htm += '<tr>';
                        htm += '<td>';
                        htm += '<div style="width:700px;">';
                        htm += '<div>';
                        htm += '<div class="fl">';
                        htm += '<span class="myorderMData fl">';

                        var invoice_num = "";
                        console.log(row.invoiceNum);
                        htm += '<a href="manage_salesreturns.aspx?returnId=' + row.srm_id + '"><label class="fl" style="color: inherit; margin-bottom:0px;font-weight:normal;cursor:pointer" >#' + getHighlightedValue(filters.search, row.invoiceNum) + '(' + getHighlightedValue(filters.search, row.srm_id.toString()) + ')</label></a>';

                        htm += '<label class="fl" style="margin-bottom:0px; padding-left:5px; padding-right:5px; font-size:14px;"><a>' + getHighlightedValue(filters.search, row.cust_name) + '</a></label>';
                        htm += "<span class='status " + status_class + "'>" + status + "</span>";




                        htm += '</div>';
                        htm += '</div>';
                        htm += '<div class="clear"></div>';
                        htm += '<div style="text-align: left;">';
                        htm += '<span class="myorderSData" style="color:#361efb;font-size:15px;">Returned on:  </span><label class="fa fa-calendar myicons" ></label><span class="myorderSData">' + row.returnDate + '</span>&nbsp;&nbsp;<label class="fa fa-edit myicons"></label>';
                        htm += '<span class="myorderSData">' + row.seller_name + '</span></div>';
              
                        htm += '</div>';
                        htm += '</td>';
                        htm += '<td style="text-align:center";>' + row.net_amount + '</td>';

                        htm += '<td>';
                        htm += '<a href="manage_salesreturns.aspx?returnId=' + row.srm_id + '" class="btn btn-primary btn-xs">';
                        htm += '<li class="fa fa-eye" style="font-size:large;"></li>';
                        htm += '</a>';
                       
                        htm += '</td>';
                        htm += '</tr>';


                    });
                    //  alert(htm);
                    $('#tblReturns > tbody').html(htm);
                    html += '<tr>';
                    html += '<td colspan="4">';
                    html += '<div  id="divPagination" style="text-align: center;">';
                    html += '</div>';
                    html += '</td>';
                    html += '</tr>';
                    // alert(htm);
                    $('#tblReturns > tbody').append(html);
                    //$('#tblReturns > tbody').html(htm);
                    $('#divPagination').html(paginate(obj.count, perpage, page, "searchReturns"));
                   // console.log(JSON.parse($.cookie("search-data")));
                    //$("#paginatediv").html(paginate(obj.count, perpage, page, "searchReturns"));
                    Unloading();

                },
                error: function (xhr, status) {
                    Unloading();
                    // alert("fail" + status + ":::" + xhr.d);
                    alert("Internet Problem..!");
                }
            });
        }

        function resetFilters() {
            window.location.href = "list_salesreturns.aspx";


        }

       
    </script>

</head>

<body class="nav-md">
    <form id="form1" runat="server" autocomplete="off">

        <div class="container body">
            <div class="main_container">
                <!-- Start div For loading image-->
                <div id="loading" style="background-repeat: no-repeat; margin: auto; height: 100%; display: none">
                    <div align="center" style="margin: auto">
                        <img id="loading-image" src="../images/loader.gif" alt="Loading..." />
                    </div>
                </div>
                <!-- End  div For loading image-->
                <div class="col-md-3 left_col">
                    <div class="left_col scroll-view">
                        <div class="navbar nav_title" style="border: 0;">
                            <a href="#" class="site_title">
                                <!--<i class="fa fa-paw"></i>-->
                                <span>Invoice</span></a>
                        </div>

                        <div class="clearfix"></div>

                        <!-- menu profile quick info -->
                        <div class="profile clearfix">
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
                                <div class="col-md-6 col-xs-6">
                                    <label style="font-weight: bold; font-size: 16px;">Sales Returns</label>
                                </div>
                                <div class="col-md-6 col-xs-5">



                                   
                                  
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
                        <div class="row">
                            <div class="col-md-12 col-sm-12 col-xs-12">
                                <div class="x_panel">
                                    <div class="x_title" style="margin-bottom: 0px;">
                                        <strong>Filter</strong>
                                        <ul class="nav navbar-right panel_toolbox">
                                            <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                            </li>

                                            <%--<li><a class="close-link"><i class="fa fa-close"></i></a>
                                            </li>--%>
                                        </ul>

                                    </div>
                                    <div class="x_content">

                                        <form class="form-horizontal form-label-left input_mask">
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback" id="divsearchwarehouse">
                                                <label>Warehouse</label>
                                                <select class="form-control" style="text-indent: 25px;" id="slBranch" onchange="javascript:searchReturns(1);">
                                                </select>
                                                <span class="fa fa-map-marker form-control-feedback left" aria-hidden="true"></span>
                                            </div>

                                              
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Salesman / User</label>
                                                <select class="form-control" style="text-indent: 25px;" id="comboSalesPerson" onchange="javascript:searchReturns(1);">
                                                    <option>--Select Sales Person--</option>
                                                    <option>Sales Person1</option>
                                                    <option>Sales Person2</option>
                                                </select>
                                                <span class="fa fa-users form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-2 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Return Status</label>
                                                <select class="form-control" style="text-indent: 25px;" id="slReturnStatus" onchange="javascript:searchReturns(1);">
                                                    <option value="-1" selected="true">--All--</option>

                                                    <option value="1">initiated </option>
                                                    <option value="2">Received</option>
                                                    <option value="3">approved </option>
                                                    <option value="4">cancelled</option>
                                 
                                                </select>
                                                <span class="fa fa-file form-control-feedback left" aria-hidden="true"></span>
                                            </div>



                                            
                                            
                                           
                                            

                                            <div class="col-md-4 col-sm-6 col-xs-12 form-group has-feedback">
                                                 <label>Search for Customer</label>
                                                <input type="text" class="form-control has-feedback-left" id="txtCustSearch" placeholder="Search with Customer ID/ Customer Name" />
                                                <span class="fa fa-search form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Dated from</label>
                                                <input type="text" class="form-control has-feedback-left" style="background-color:#fff" id="txtSearchFromDate" placeholder="From Date" />
                                                <span class="fa fa-calendar form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Dated Upto</label>
                                                <input type="text" class="form-control has-feedback-left" style="background-color:#fff" id="txtSearchToDate" placeholder="To Date" />
                                                <span class="fa fa-calendar form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                             

                                            <div class="col-md-2 col-sm-6 col-xs-12 ">
                                                
                                                <div class="btn btn-success mybtnstyl" onclick="javascript:searchReturns(1);"  style="float:right">
                                                    <li class="fa fa-search" style="margin-right: 5px;"></li>
                                                    Search
                                                </div>

                                                <div class="btn btn-primary mybtnstyl" onclick="javascript:resetFilters();"  style="float:right">
                                                    <li class="fa fa-refresh" style="margin-right: 5px;"></li>
                                                    Reset
                                                </div>
                                            </div>

                                        </form>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="clearfix"></div>

                        <div class="row">
                            <div class="col-md-12 col-sm-12 col-xs-12">
                                <div class="x_panel">
                                    <div class="x_title" style="margin-bottom: 0px;">
                                        <!--      <h2>Hover rows</h2>-->
                                        <div class="col-md-6 col-sm-12 col-xs-12">
                                            <label>Returns</label><span class="badge" style="color: #fff; margin-left: 5px; background: #d00101; padding-left: 5px; padding-right: 5px;" id="txttotalReturnCount"></span>

                                        </div>
                                        <div class="col-md-6 col-sm-12 col-xs-12">
                                            <ul class="nav navbar-right panel_toolbox">

                                                <li>
                                                    <select id="slPerpage" onchange="javascript:searchReturns(1);" name="datatable-checkbox_length" aria-controls="datatable-checkbox" class=" input-sm">
                                                        <option value="50">50</option>
                                                        <option value="100">100</option>
                                                        <option value="250">250</option>
                                                        <option value="500">500</option>
                                                    </select></li>


                                                <%--<li><a class="close-link"><i class="fa fa-close"></i></a>
                                            </li>--%>
                                            </ul>
                                        </div>

                                        <div class="clearfix"></div>
                                    </div>
                                    <div class="col-md-12 col-sm-12 col-xs-12" style="overflow-x: auto;">
                                        <div class="x_content">
                                            <table id="tblReturns" class="table table-striped jambo_table bulk_action" style="table-layout: auto;">
                                                <thead style="background-color:#f1eeee;color:#525252">
                                                    <tr>
                                                        <th>Return Details</th>
                                                        <th style="text-align: center;">Net Amount</th>
                                                        
                                                        <th>Action</th>
                                                    </tr>
                                                </thead>
                                                <tbody>
                                                    <tr>
                                                        <td colspan="4" style="text-align: center">
                                                            <label>Empty</label>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td colspan="3">
                                                            <div class="border"></div>
                                                        </td>

                                                    </tr>

                                                </tbody>
                                            </table>


                                            <div class="col-md-12 col-sm-12 col-xs-12" style="overflow-x: auto;">
                                                <div class="x_content">


                                                    <!--<div class="dataTables_paginate paging_simple_numbers" id="datatable_paginate">
				<div class="col-md-12 text-center">
				<ul class="pagination"><li class="paginate_button previous disabled" id="datatable_previous"><a href="#" aria-controls="datatable" data-dt-idx="0" tabindex="0">Previous</a></li><li class="paginate_button active"><a href="#" aria-controls="datatable" data-dt-idx="1" tabindex="0">1</a></li><li class="paginate_button "><a href="#" aria-controls="datatable" data-dt-idx="2" tabindex="0">2</a></li><li class="paginate_button "><a href="#" aria-controls="datatable" data-dt-idx="3" tabindex="0">3</a></li><li class="paginate_button "><a href="#" aria-controls="datatable" data-dt-idx="4" tabindex="0">4</a></li><li class="paginate_button next" id="datatable_next"><a href="#" aria-controls="datatable" data-dt-idx="7" tabindex="0">Next</a></li></ul></div></div>-->
                                                </div>


                                            </div>

                                        </div>
                                    </div>
                                </div>

                            </div>
                        </div>
                        <!-- /page content -->


                    </div>


                </div>
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

    <!-- jQuery -->
    <%--<script src="../js/bootstrap/jquery.min.js"></script>--%>
    <!-- jQuery -->
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
