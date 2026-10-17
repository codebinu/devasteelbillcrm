<%@ Page Language="C#" AutoEventWireup="true" CodeFile="manage_purchasereturns.aspx.cs" Inherits="web_purchase_manage_purchasereturns" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Manage  Purchase Return  | Invoice Me</title>
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
    <style>
        .blink_text
        {
            animation: 1s blinker linear infinite;
            -webkit-animation: 1s blinker linear infinite;
            -moz-animation: 1s blinker linear infinite;
            color: #ff3300;
        }

        @-moz-keyframes blinker
        {
            0%
            {
                opacity: 1.0;
            }

            50%
            {
                opacity: 0.0;
            }

            100%
            {
                opacity: 1.0;
            }
        }

        @-webkit-keyframes blinker
        {
            0%
            {
                opacity: 1.0;
            }

            50%
            {
                opacity: 0.0;
            }

            100%
            {
                opacity: 1.0;
            }
        }

        @keyframes blinker
        {
            0%
            {
                opacity: 1.0;
            }

            50%
            {
                opacity: 0.0;
            }

            100%
            {
                opacity: 1.0;
            }
        }
    </style>

    <script type="text/javascript">
        var exactwalletamt = 0;
        var ReturnNo;
        var userId;
        var status;
        var tax_type = 0;
        var returnObj = "";
        var accuracyNum=2;
        var lastUpdatedDate="";
        var systemSettings= <%=settings%>;
        //   console.log(systemSettings);
       


        //  window.onbeforeunload = function () { return "Your work will be lost."; };
        $(document).ready(function () {
            accuracyNum=systemSettings[0].ss_decimal_accuracy;
            //console.log(JSON.parse($.cookie("search-data")));
            ReturnNo = getQueryString('returnId');
            //  alert(ReturnNo);
            //  alert(ReturnNo);
            if (ReturnNo == undefined) {
                location.href = "list_purchasereturns.aspx";
                return;
            }
            //console.log(location.search);
         
            var BranchId = $.cookie("invntrystaffBranchId");
            var CountryId = $.cookie("invntrystaffCountryId");
            if (!BranchId) {
                location.href = "../dashboard.aspx";
                return false;
            }
            if (!CountryId) {
                location.href = "../dashboard.aspx";
                return false;
            }
            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " ©");
          //  loadBranches();
            selectReturns();

            //call to select order details

        });

   

        //Start:TO Replace single quotes with double quotes
        function sqlInjection() {
            $('input, select, textarea').each(
                function (index) {
                    var input = $(this);
                    var type = this.type ? this.type : this.nodeName.toLowerCase();

                    if (type == "text" || type == "textarea") {

                        $("#" + input.attr('id')).val(input.val().replace(/'/g, '"'));
                    } else { }
                }
            );
        }

    

        //start: Showing Details of selected Outsatnding Bill from Popup
        function selectReturns() {
            $.ajax({
                type: "POST",
                url: "manage_purchasereturns.aspx/selectReturns",
                data: "{'ReturnNo':'" + ReturnNo + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    //$.cookie('salesreturnOrderId', ReturnNo, {
                    //    path: '/'
                    //});
                    returnObj = JSON.parse(msg.d);
                    var return_details = returnObj.return[0];

                    $("#txtTotalAmt").text(return_details.total_amount);
                    $("#txtPurchaseOrderRef").text(return_details.prm_invoice_no);

                    $("#txtReturnNo").text(return_details.prm_id);
                    $("#txtMemberId").text(return_details.vendor_id);
                    var a = document.getElementById('hrefVendor'); //or grab it by tagname etc
                    a.href = "../Web_purchase/managevendor.aspx?vendorId=" + return_details.vendor_id;
                    $("#txtMemberName").text(return_details.vn_name);
                    $("#txtReturnDate").text(return_details.DATE);
                    $("#selBranches").val(return_details.branch_id);
                    $("#lbloutstanding").text(return_details.outstanding_amt);
                    if (return_details.outstanding_amt > 0) {
                        $("#lbloutstanding").css("color", "red");
                    } else {
                        $("#lbloutstanding").css("color", "green");
                    }
                    $("#lblInvoiceNum").text(return_details.prm_invoice_no);

                    $("#aprcanby").html('Approved By');
                    $("#aprcandate").html('Approved Date');

                    //alert(return_details.status);
                    if (return_details.status == 1) {
                        $("#txtLabelStatus").html('<span class="label label-warning" style="margin-left: 2px; margin-right: 2px; color: #fff;">Initiated</span>');

                    } else if (return_details.status == 2) {
                        $("#txtLabelStatus").html('<span class="status label label-primary" style="margin-left: 2px; margin-right: 2px; color: #fff;">Received</span>');

                    } else if (return_details.status == 3) {
                        $("#txtLabelStatus").html('<span class="status label label-success" style="margin-left: 2px; margin-right: 2px; color: #fff;">Approved</span>');
                    }
                
                    else if (return_details.status == 4 ) {
                        $("#txtLabelStatus").html('<span class="status label label-default" style="margin-left: 2px; margin-right: 2px; color: #fff;">Cancelled</span>');
                        $("#aprcanby").html('Cancelled By');
                        $("#aprcandate").html('Cancelled Date');
                    }
                 
                  
                   // alert(return_details.status);
                    $("#txtdeliverystatus").val(return_details.status);
                    if($.cookie("invntrystaffTypeID")==1){
                        $("#btnEditOrder").show();
                    }else if($.cookie("invntrystaffTypeID")==2){
                        $("#btnEditOrder").show();
                    }
                    else if($.cookie("invntrystaffTypeID")==4){
                        $("#btnEditOrder").hide();
                    }
                    if(return_details.status==1){
                        
                        if($.cookie("invntrystaffTypeID")==1){
                            $("#divReceive").show();
                            $("#divCancel").show();
                            $("#divApprove").hide();
                            $("#divInitiate").hide();
                        }else if($.cookie("invntrystaffTypeID")==2){
                            $("#divReceive").hide();
                            $("#divCancel").show();
                            $("#divApprove").hide();
                            $("#divInitiate").hide();
                        }
                        else if($.cookie("invntrystaffTypeID")==4){
                            $("#divReceive").show();
                            $("#divCancel").hide();
                            $("#divApprove").hide();
                            $("#divInitiate").hide();
                        }
                    }  else if(return_details.status==2){
                        
                        if($.cookie("invntrystaffTypeID")==1){
                            $("#divReceive").hide();
                            $("#divCancel").show();
                            $("#divApprove").show();
                            $("#divInitiate").hide();
                        }else if($.cookie("invntrystaffTypeID")==2){
                            $("#divReceive").hide();
                            $("#divCancel").hide();
                            $("#divApprove").hide();
                            $("#divInitiate").hide();
                        }
                        else if($.cookie("invntrystaffTypeID")==4){
                            $("#divReceive").hide();
                            $("#divCancel").hide();
                            $("#divApprove").hide();
                            $("#divInitiate").hide();
                        }
                    }
                    else if(return_details.status==3){
                        
                        if($.cookie("invntrystaffTypeID")==1){
                            $("#divReceive").hide();
                            $("#divCancel").show();
                            $("#divApprove").hide();
                            $("#divInitiate").hide();
                        }else if($.cookie("invntrystaffTypeID")==2){
                            $("#divReceive").hide();
                            $("#divCancel").hide();
                            $("#divApprove").hide();
                            $("#divInitiate").hide();
                        }
                        else if($.cookie("invntrystaffTypeID")==4){
                            $("#divReceive").hide();
                            $("#divCancel").hide();
                            $("#divApprove").hide();
                            $("#divInitiate").show();
                        }
                    }
                    else if(return_details.status==4){
                        $("#divReceive").hide();
                        $("#divCancel").hide();
                        $("#divApprove").hide();
                        $("#divInitiate").hide();
                        $("#btnEditOrder").hide();
                    }
                    //   alert(return_details.sm_specialnote);
                    $("#txtSpecialNote").val(return_details.prm_description);
             
                    
                    var needDisplay = "none";
                    var statusHtm = "";
                
                    needDisplay = return_details.approver_name == null ? "none" : "block";
                    statusHtm = statusHtm + '<div style="display:' + needDisplay + '">';
                    statusHtm = statusHtm + '<div class="col-md-3"><label style="font-weight:500;">Returned By</label></div>';
                    statusHtm = statusHtm + ' <div class="col-md-8"><span style="font-weight:bold;">:</span> <label>' + return_details.approver_name + '</label><label>(' + return_details.DATE + ')</label></div>';
                    statusHtm = statusHtm + '</div>';
                    //  alert(statusHtm);
                    $("#divStatusData").html(statusHtm);
                    // showing order_items
                    $("#tbodyItems").html("");
                    $.each(returnObj.items, function (i, item) {


                        var htmItemRow = '';
                        htmItemRow += '<tr>';
                        htmItemRow += '<td>' + item.itm_code + '</td>';

                            htmItemRow += '<td><strong>' + item.itm_name + '</strong></td>';

         
                      
                        htmItemRow += '<td>' + item.pri_qty + '</td>';
                        htmItemRow += '<td>' + item.pi_price + '</td>';
                        htmItemRow += '<td>' + item.pri_discount_amount + '</td>';
                        htmItemRow += '<td>' + item.pri_tax_amount + '</td>';
                        htmItemRow += '<td>' + item.pri_total + '</td>';
                        var type="";
                        if(item.pri_type==0){
                            type = "Damaged";
                            htmItemRow += '<td style="color:red">' + type + '</td>';
                        }else if(item.pri_type==1){
                            type = "Expired";
                            htmItemRow += '<td style="color:red">' + type + '</td>';
                        }else if(item.pri_type==2){
                            type = "Ready To Use";
                            htmItemRow += '<td style="color:green"><b>' + type + '</b></td>';
                        }
                        //htmItemRow += '<td style="color:blue">' + type + '</td>';
                      
                        if(item.receiver==null){
                            htmItemRow += '<td></td>';
                            htmItemRow += '<td></td>';
                        }else{
                            htmItemRow += '<td>' + item.receiver + '</td>';
                            htmItemRow += '<td>' + item.receivededdate + '</td>';
                        }
                        if(item.approver==null){
                            htmItemRow += '<td></td>';
                            htmItemRow += '<td></td>';
                        }else{
                            htmItemRow += '<td>' + item.approver + '</td>';
                            htmItemRow += '<td>' + item.approveddate + '</td>';
                        }
                        htmItemRow += '</tr>';
                        $("#tbodyItems").append(htmItemRow);
                    });

                },
                error: function (xhr, status) {
                    Unloading();
                    alert("Internet Problem..!");
                }
            });
        }
        // Stop: Showing Details of selected Outsatnding Bill from Popup

        function changeEvent(objectId, elem) {
            var now = new Date();
            var day = ("0" + now.getDate()).slice(-2);
            var month = ("0" + (now.getMonth() + 1)).slice(-2);

            var today = now.getFullYear() + "-" + (month) + "-" + (day);
            //  console.log("after" + Objapprovehead.approveheads[objectId].date);
            if (elem.checked) {
                Objapprovehead.approveheads[objectId].id = $.cookie("invntrystaffId");
                Objapprovehead.approveheads[objectId].status = "1";
                Objapprovehead.approveheads[objectId].date = today;
            } else {
                Objapprovehead.approveheads[objectId].id = $.cookie("invntrystaffId");
                Objapprovehead.approveheads[objectId].status = "0";
                Objapprovehead.approveheads[objectId].date = today;

            }
            //  console.log(Objapprovehead.approveheads);
        }
    
     

        function refreshpage() {
            selectReturns();
            //  window.location.reload();
        }

     
        //changed by deepika on 02-11-16
        //function for updating order status
        function returnOrderstatuschange(type) {
     
            var postObj = {

                item: {
                    prm_id: ReturnNo,
                    user_id: $.cookie('invntrystaffId'),
                    time_zone: $.cookie("invntryTimeZone"),
                    recep_status: '1',
                    return_status:type
                }
            };
          
            var result = confirm("Do you want to change the status?");
            
            if (result) {
                $.ajax({
                    type: "POST",
                    url: "manage_purchasereturns.aspx/updateReturnOrderStatus",
                    data: JSON.stringify(postObj),
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (msg) {
                        Unloading();
                        //alert(msg.d);
                        //alert("Success");
                        // return;
                        if (msg.d == "FAILED") {
                            alert("Error!.. Please Try Again...");
                            return;
                        }        else if(msg.d=="E"){
                            var result = confirm("Some One already changed the page..Do you want to reload and continue ?");
                            if(result){
                                window.location.reload();
                            }else{
                                return;
                            }
                        } else {
                            alert("Order Status Updated Successfully...");
                            window.location.reload();
                            return false;
                        }
                    },
                    error: function (xhr, status) {
                        Unloading();
                        alert("Internet Problem..!");
                    }
                });
            } else {
                return false;
            }
        }

        

        function backpage() {
            window.location.href = "list_purchasereturns.aspx?event=back";

        }


       

    
        function goToPurchaseRetun() {
            window.location.href = "editPurchaseReturn.aspx?returnId=" + ReturnNo;
        }
      

        function printbill() {

            window.location.href = "printPurchaseReturn.aspx?id=" + ReturnNo;
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
            <!-- top navigation -->
            <div class="top_nav">
                <div class="nav_menu">
                    <nav>

                        <div class="navbar-header" style="width: 100%; display: flex; align-items: center">
                            <div class="nav toggle" style="padding: 5px;">
                                <a id="menu_toggle"><i class="fa fa-bars"></i></a>
                            </div>
                            <div class="col-md-10 col-md-10 col-xs-6">
                                <label style="font-weight: bold; font-size: 16px;">Manage Purchase Return</label>
                            </div>

                            <div class="col-md-6 col-xs-8">
                                <label onclick="javascript:backpage();" class="btn btn-success btn-xs pull-right" style="background-color: #1240d8; border-color: #1240d8;">
                                    <label style="color: #fff; font-size: 14px;" class="fa fa-arrow-left" title="Back"></label>
                                </label>
                                <%-- chnaged by anjana --%>
                                <div class="btn btn-primary btn-xs pull-right" id="divWaybilling" style="display: none; background-color: #109ead" onclick="javascript:gotoWayBilling();">
                                    <label class="fa fa-file-text" style="padding-right: 3px;"></label>
                                    WayBilling
                                </div>
                                <%-- end --%>
                                <div class="btn btn-success btn-xs pull-right" onclick="javascript:goToPurchaseRetun();"  id="btnEditOrder">
                                    <label class="fa fa-pencil"></label> Edit 
                                </div>
                                <div class="btn btn-success btn-xs pull-right" onclick="javascript:printbill();" style="background-color: #00b7fd; border-color: #008fc5;cursor:pointer" id="divprintorder">
                                   <label class="fa fa-print"></label> Print
                                </div>
                                    
                            </div>

                            <%--<div style="margin-left:5px;">
                                   <label class="glyphicon glyphicon-chevron-left" style="font-size:24px;  margin-left:20px;"></label>
                  <label class="fa fa-refresh pull-right" style="font-size:24px;"></label>
                                    </div>--%>
                        </div>

                    </nav>
                </div>
            </div>
            <!-- /top navigation -->
            <!-- /top navigation -->

            <!-- page content -->
            <div class="right_col" role="main">
                <div class="">
            
                    <div class="clearfix"></div>

                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12">


                            <div class="x_panel">
                                <div class="x_title" style="margin-bottom: 0px;">
                                    <ul class="nav navbar-right panel_toolbox pull-right">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                        </li>
                                    </ul>
                                    <b>Return Id </b>
                                     <span style="font-weight: bold;">:</span>&nbsp
                                  <label id="lblInvoiceNum"></label>
                                    (<label id="txtReturnNo"></label>)<a id="txtLabelStatus"></a>

                                </div>
                                <div class="x_content">
                                    <!-- info row -->
                                    <div class="row invoice-info">
                                        <div class="col-sm-4 ">

                                            <b>Return Date</b>
                                            <span style="font-weight: bold;">:</span>
                                            <label id="txtReturnDate"></label>


                                        </div>
                                        <!-- /.col -->
                                        <div class="col-sm-5">
                                            <b>Vendor </b>

                                            <span style="font-weight: bold;">:</span>  <a style="text-decoration: underline" href="" id="hrefVendor" target="_blank">#<span id="txtMemberId"></span></a>&nbsp;<label id="txtMemberName"></label><%--(class <span id="txtClassType"></span>)--%> 
                                        </div>
                                        <!-- /.col -->

                                      
                                        <div class="col-sm-3">
                                            <b>Account Balance:</b>
                                            <span style="font-weight: bold;"></span>
                                            <label id="lbloutstanding" style="color: #432727; font-weight: bold; font-size: 12px; color: red;">0</label>
                                        </div>
                                        <!-- /.col -->

                                        <div class="col-sm-5 ">

                                            <b style="color:#008fc5">Reference Invoice</b>
                                            <span style="font-weight: bold;">:</span>
                                            <label id="txtPurchaseOrderRef"></label>


                                        </div>

                                        <input type="hidden" id="txtdeliverystatus" />
                                        <!-- /.col -->
                                    </div>


                                </div>
                                <div class="clear"></div>


                            </div>
                        </div>
                        <div class="col-md-12 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title" style="margin-bottom: 0px;">
                                    <ul class="nav navbar-right panel_toolbox pull-right">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                        </li>
                                    </ul>
                                    <label>Track Status</label>

                                </div>
                                <div class="x_content">
                                    <div class="row" style="margin-top: 10px;">

                                        <div class="col-md-7" id="divStatusData">
                                        

                                        </div>
                                        <div class="col-sm-5 " style="padding-right: 50px;">
      <div class="btn btn-danger pull-right mybtnstyl" id="divCancel" style="display: none;" onclick="returnOrderstatuschange(4)">Cancel</div>
                                                     <div class="btn btn-primary pull-right mybtnstyl" id="divApprove" style="display: none;" onclick="returnOrderstatuschange(3)">Approve Return</div>
                                          <div class="btn btn-success pull-right mybtnstyl" id="divReceive" style="display: none;" onclick="returnOrderstatuschange(2)">Mark as Received</div>
                                                                          
                                             <div class="btn btn-warning pull-right mybtnstyl" id="divInitiate" style="display: none;" onclick="returnOrderstatuschange(1)">Initiate</div>
                                           
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="clearfix"></div>

                        <div class="col-md-12 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title">
                                    <label>Items</label>
                                    <ul class="nav navbar-right panel_toolbox">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                        </li>
                                    </ul>
                                   
                                </div>

                                
                                <div class="col-md-12 col-sm-12 col-xs-12" style="overflow-x: auto;">
                                    <div class="x_content">

                                        <table id="tblOrderItems" class="table table-striped jambo_table bulk_action table-bordered" style="table-layout: auto;">
                                            <thead style="background-color:#f1eeee;color:#525252">
                                                <tr>
                                                    <th>Item Code</th>
                                                    <th style="width: 300px;">Name</th>
                                                    <th>Qty</th>
                                                    <th>ReturnPrice</th>
                                                    <th>Discount amt</th>
                                                    <th>Tax</th>
                                                    <th>Amount</th>
                                                    <th>Reason</th>
                                                 
                                                    <th>Received By</th>
                                                    <th>Received Date</th>
                                                     <th id="aprcanby"> By</th>
                                                    <th id="aprcandate"> Date</th>
                                                </tr>
                                            </thead>


                                            <tbody id="tbodyItems">
                                            </tbody>
                                            <tbody id="tbodyPayments">


                                                <tr>
                                                    
                                                    <td colspan="6" style="text-align: right;"><b>Total</b></td>

                                                    <td>
                                                        <label id="txtTotalAmt" style="font-size:15px">0</label></td>
                                        
                                                     <td colspan="5"></td>
                                                </tr>
                                               
                                            </tbody>



                                        </table>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-12 col-sm-12 col-xs-12">
                            <div class="x_panel" style="background: #eeeeee;">
                                <div class="col-md-12 col-sm-12 col-xs-12" style="padding-left: 0px; padding-right: 0px;">
                         <div class="col-md-12 col-sm-6 col-xs-12" style="padding-left: 0px; padding-right: 0px">

                                        <div class="col-md-8 col-sm-6 col-xs-12"><b>Special Notes</b> </div>
                                        <div class="clearfix"></div>

                                        <div class="col-md-12 col-sm-12 col-xs-12" style="">
                                            <textarea id="txtSpecialNote" class="form-control" style="resize: none;height: 73px;margin: 0px -645.672px 0px 0px;/* width: 801px; */" disabled></textarea>
                                        </div>
                                        

                                        <%--<div class="col-md-1 col-sm-3 col-xs-3" style="margin-top: 20px;" id="divsaveorder" onclick="javascript:savepayment();">
                                            <button class="btn btn-primary pull-right" style="font-weight:bold;"  type="button">save</button>
                                        </div>--%>
                                        <div class="clearfix"></div>
                                     

                                       

                                    </div>
                                    </div>
                                </div>
                            </div>
                        <div class="clearfix"></div>
                       

                    </div>
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