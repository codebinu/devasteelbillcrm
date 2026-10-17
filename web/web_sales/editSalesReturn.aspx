<%@ Page Language="C#" AutoEventWireup="true" CodeFile="editSalesReturn.aspx.cs" Inherits="web_sales_editSalesReturn" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Edit  Sales Return  | Invoice Me</title>
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
                location.href = "list_salesreturns.aspx";
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


            var yyyy = new Date().getFullYear();
            var curr_date = new Date().getDate();
            $('#txtProcessDate').scroller({
                preset: 'date',
                endYear: yyyy + 100,
                setText: 'Next',
                invalid: {},
                theme: 'ios',
                display: 'modal',
                mode: 'scroller',
                //dateFormat :'yy-mm-dd'
                //dateFormat: 'yyyy-mm-dd'
                dateFormat: 'dd-mm-yy'
            });

            $('#txtProcessTime').scroller({
                preset: 'time',
                endYear: yyyy + 100,
                min: new Date(new Date().setHours(10, 00)),
                max: new Date(new Date().setHours(22, 00)),
                setText: 'Next',
                invalid: {},
                theme: 'ios',
                display: 'modal',
                mode: 'scroller',
            });



            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " ©");
            //  loadBranches();
            selectReturns();

            //call to select order details

        });

        function update_invoice_ref() {

            if ($("#txt_invoice_ref").val() == "") {

                alert("Please enter an invoice reference number");
            }
            sqlInjection()

            $.ajax({
                type: "POST",
                url: "editSalesReturn.aspx/update_invoice_ref",
                data: "{'srm_id':'" + ReturnNo + "','ref_id':'" + $("#txt_invoice_ref").val() + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                crossDomain: true,
                timeout: 15000,
                success: function (msg) {
                   
                    if (msg.d == "N") {
                       
                        alert("Something went wrong! Please try again.");
                    }
                    else if (msg.d == "Y") {

                        alert("Reference number updated successfully!");
                        location.reload();
                    }
                    else {

                        alert("Something went wrong! Please try again.");
                    }


                },
                error: function (xhr, status) {
                    
                    alert("Something went wrong! Please try again.");
                }
            });
        }


        function update_salesreturn_Date() {


            sqlInjection();

            //process date
            var processDate = $("#txtProcessDate").val();
            var processTime = $("#txtProcessTime").val();
            if (processDate != "") {
                var splitarray = processDate.split("-");
                processDate = splitarray[2] + "/" + splitarray[1] + "/" + splitarray[0];
            }

            if (processTime != "") {
                var splitAmPm = processTime.split(" ");
                var splittime = splitAmPm[0].split(":");
                if (splitAmPm[1] == "AM" && splittime[0] == "12") {
                    splittime[0] = "00";
                } else if (splitAmPm[1] == "AM" && splittime[0] != "12") {
                    splittime[0] = splittime[0];
                }
                else if (splitAmPm[1] == "PM" && splittime[0] == "12") {
                    splittime[0] = "12";
                } else {
                    splittime[0] = parseInt(splittime[0]) + 12;
                }
                processTime = splittime[0] + ":" + splittime[1] + ":00";
            }
            else {
                processTime = processTime;
            }

            var finalProcessDateTime = processDate + " " + processTime;

            $.ajax({
                type: "POST",
                url: "editSalesReturn.aspx/update_salesreturn_Date",
                data: "{'srm_id':'" + ReturnNo + "','srm_date':'" + finalProcessDateTime + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                crossDomain: true,
                timeout: 15000,
                success: function (msg) {

                    if (msg.d == "N") {

                        alert("Something went wrong! Please try again.");
                    }
                    else if (msg.d == "Y") {

                        alert("sales return Date updated successfully!");
                        location.reload();
                    }
                    else {

                        alert("Something went wrong! Please try again.");
                    }


                },
                error: function (xhr, status) {

                    alert("Something went wrong! Please try again.");
                }
            });
        }

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
                url: "editSalesReturn.aspx/selectReturns",
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
                    $("#txt_invoice_ref").val(return_details.srm_refInvoiceNo); 
                    
                
                    $("#txtReturnNo").text(return_details.srm_id);
                    $("#txtMemberId").text(return_details.cust_id);
                    var a = document.getElementById('hrefCustomer'); //or grab it by tagname etc
                    a.href = "../Web_Customer/managecustomers.aspx?cusId=" + return_details.cust_id;
                    $("#txtMemberName").text(return_details.cust_name);

                    var processDate = return_details.date.split(' ')[0];
                    var processTime = return_details.date.split(' ')[1] + " " + return_details.date.split(' ')[2];
                    $("#txtProcessDate").val(processDate);
                    $("#txtProcessTime").val(processTime);


                   // $("#txtReturnDate").text(return_details.date);
                    $("#selBranches").val(return_details.branch_id);
                    $("#lbloutstanding").text(return_details.outstanding_amt);
                    if (return_details.outstanding_amt > 0) {
                        $("#lbloutstanding").css("color", "red");
                    } else {
                        $("#lbloutstanding").css("color", "green");
                    }
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
                    }
                 
                  
                    //alert(return_details.type);
                    $("#txtdeliverystatus").val(return_details.status);
                   
                    // showing order_items
                    $("#tbodyItems").html("");
                    $.each(returnObj.items, function (i, item) {


                        var htmItemRow = '';
                        htmItemRow += '<tr>';
                        htmItemRow += '<td>' + item.itm_code + '</td>';

                        htmItemRow += '<td><strong>' + item.itm_name + '</strong></td>';

         
                      
                        htmItemRow += '<td>' + item.sri_qty + '</td>';
                        htmItemRow += '<td>' + item.si_price + '</td>';
                        htmItemRow += '<td>' + item.sri_discount_amount + '</td>';
                        htmItemRow += '<td>' + item.sri_tax_amount + '</td>';
                        htmItemRow += '<td>' + item.sri_total + '</td>';
                        var type="";
                        if(item.sri_type==0){
                            type = "Damaged";
                            htmItemRow += '<td style="color:red">' + type + '</td>';
                        }else if(item.sri_type==1){
                            type = "Expired";
                            htmItemRow += '<td style="color:red">' + type + '</td>';
                        }else if(item.sri_type==2){
                            type = "Ready To Use";
                            htmItemRow += '<td style="color:green"><b>' + type + '</b></td>';
                        }
                        //htmItemRow += '<td style="color:blue">' + type + '</td>';
                      
                        htmItemRow += '<td><a class="btn btn-primary btn-xs" style="text-align:center;"><span class="fa fa-pencil" style="font-size:14px;margin-top:3px;" onclick="showEditItemPopUp('+item.sri_id+');" title="Edit"> </span></a></td>';
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
                    srm_id: ReturnNo,
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
                    url: "editSalesReturn.aspx/updateReturnOrderStatus",
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
            window.location.href = "list_salesreturns.aspx?event=back";

        }

           
        function goToSalesRetun() {
            window.location.href = "editSalesReturn.aspx?returnId=" + ReturnNo;
        }
      
        function showEditItemPopUp(itemId) {
            itemDet = returnObj.items.find(x=>x.sri_id == itemId);
            console.log(itemDet);
            $("#popupEditItem").modal('show');
            $("#txtItemName").val(itemDet.itm_name);
            $("#txtQty").val(itemDet.sri_qty);
            $("#txtPrice").val(itemDet.si_price);
            $("#txtTaxExcludedTotal").val((itemDet.sri_total-itemDet.sri_tax_amount).toFixed(2));
            $("#selReason").val(itemDet.sri_type);
            $("#txtTaxAmt").val(itemDet.sri_tax_amount);
            $("#txtTotal").val(itemDet.sri_total);
        }

        function popupclose(divid) {
          
            $("#" + divid).modal('hide');
        }

        function changeFields(){
            //start check number only
            $('.number-only').keyup(function (e) {
                if (this.value != '-')
                    while (isNaN(this.value))
                        this.value = this.value.split('').reverse().join('').replace(/[\D]/i, '')
                                               .split('').reverse().join('');
            })
             .on("cut copy paste", function (e) {
                 e.preventDefault();
             });
            //end check number only
            var returnQty = $("#txtQty").val();
            var saleprice =  $("#txtPrice").val();
            var tax=itemDet.tax;
            var cess = itemDet.cess;

            var realtotal = 0;
            var nettotal = 0;
            var tax_rate = 0;
            var tax_amount = 0;
            var tax_included_nettotal = 0;
            var cessRate = 0;
            var cessAmount = 0;
            var qty = returnQty;
            var price = saleprice;
            if (returnObj.return[0].branch_tax_method == 0) // no tax
            {
                var total = qty * price;
                total = (parseFloat(total)).toFixed(2);
            }

            tax_rate = (parseFloat(tax)).toFixed(2);
            cessRate = (parseFloat(cess)).toFixed(2);
            if (returnObj.return[0].branch_tax_inclusive == 1) { // tax is included with the price

                if (parseFloat(cessRate) > 0) {

                    var denominator = 10000 * price;
                    var base = 10000 + (100 * tax_rate) + (tax_rate * cessRate);
                    price = denominator / base;
                }
                else {

                    var constant = (tax_rate / 100) + 1; // equation for the dividing constant
                    price = (price / constant).toFixed(2);
                    //  alert(price);
                    cessAmount = 0;
                    cessRate = 0;
                }
            }

            nettotal = price * qty;
            tax_amount = ((nettotal * tax_rate) / 100);
            cessAmount = ((tax_amount * cessRate) / 100);
            tax_amount = parseFloat(tax_amount) + parseFloat(cessAmount);
            tax_included_nettotal = parseFloat(nettotal) + parseFloat(tax_amount);
            //  alert(nettotal);
            $("#txtTaxExcludedTotal").val(nettotal.toFixed(2));
            $("#txtTaxAmt").val(tax_amount.toFixed(2));
            $("#txtTotal").val(tax_included_nettotal.toFixed(2));
            //alert(tax +" " +cess );
        }

        function editReturnItemDetails(){
            if($("#txtQty").val()=="" ||$("#txtQty").val()==0){
                alert("Quantity can not be null");
                return;
            }
            if($("#txtPrice").val()=="" ||$("#txtPrice").val()==0){
                alert("Price can not be null");
                return;
            }
            var postObj = {
                return_data: {

                    sri_id: itemDet.sri_id,
                    srm_id: returnObj.return[0].srm_id,
                    sri_qty: $("#txtQty").val(),
                    si_price: $("#txtPrice").val(),
                    sri_total:$("#txtTotal").val(),
                    sri_tax_amount: $("#txtTaxAmt").val(),
                    user_id: $.cookie("invntrystaffId"),
                    branchid:returnObj.return[0].branch_id,
                    sri_type:$("#selReason").val(),
                }
            };

            console.log(postObj);

            $.ajax({
                type: "POST",
                url: "editSalesReturn.aspx/Edit_Sales_Return_Item",
                data: JSON.stringify(postObj),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();

                    if (msg.d == "Y") {
                        alert("Edited Successfuly");
                        //window.location = 'salesreturn.aspx?customerid=' + custId;
                        location.reload();
                        return;
                    }
                    else  {
                        alert("Error!.. Please Try Again...");
                    }
                },
                error: function (xhr, status) {
                    Unloading();
                    console.log(xhr);
                    console.log(status);
                    var msgObj = JSON.parse(xhr.responseJSON.d);
                    alert(msgObj.message);
                }
            });

        }

        function deleteItem(){
            var postObj = {
                return_data: {

                    sri_id: itemDet.sri_id,
                    srm_id: returnObj.return[0].srm_id,
                    user_id: $.cookie("invntrystaffId"),
                    branchid:returnObj.return[0].branch_id,

                }
            };

            $.ajax({
                type: "POST",
                url: "editSalesReturn.aspx/Remove_Sales_Return_Item",
                data: JSON.stringify(postObj),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();

                    if (msg.d == "Y") {
                        alert("Deleted Successfuly");
                        window.location = 'manage_salesreturns.aspx?returnId=' + returnObj.return[0].srm_id;
                        return;
                    }else if(msg.d=="CANCEL"){
                        alert("The Entry is Cancelled..You can not delete it");
                        return;
                    }else if(msg.d=="ONEITEM"){
                        alert("Only one item exist for this return order..You can not delete it");
                        return;
                    }
                    else  {
                        alert("Error!.. Please Try Again...");
                    }
                },
                error: function (xhr, status) {
                    Unloading();
                    console.log(xhr);
                    console.log(status);
                    var msgObj = JSON.parse(xhr.responseJSON.d);
                    alert(msgObj.message);
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
                                <label style="font-weight: bold; font-size: 16px;">Edit Sales Return</label>
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
                                    Return Id
                                 
                                    (<label id="txtReturnNo"></label>)<a id="txtLabelStatus"></a>

                                </div>
                                <div class="x_content">
                                    <!-- info row -->
                                    <div class="row invoice-info">
                                        <div class="col-sm-4 "  style="display:none">

                                            <b>Return Date</b>
                                            <span style="font-weight: bold;">:</span>
                                            <label id="txtReturnDate"></label>


                                        </div>

                                                    <!-- info row -->
            <div class="col-md-5 col-sm-6 col-xs-12">
              
     <div class="col-md-5 col-sm-6 col-xs-12">
                   <input type="text" id="txtProcessDate" placeholder="Choose Date" class="form-control has-feedback-left" style="height: 28px;" readonly="">
         <span class="fa fa-calendar form-control-feedback left" aria-hidden="true"></span>

                </div>
                                             <div class="col-md-4 col-sm-6 col-xs-12">
                   <input type="text" id="txtProcessTime" placeholder="Choose Date" class="form-control has-feedback-left" style="height: 28px;" readonly="">
         <span class="fa fa-clock-o form-control-feedback left" aria-hidden="true"></span>

                </div>
                <div class="col-md-3 col-sm-6 col-xs-12">
                    <button type="button" class="btn btn-primary" style="height: 28px; padding: 2px 10px;" onclick="update_salesreturn_Date();">Update</button>
                </div>
                </div>
                <!-- /.col -->
                                        <!-- /.col -->
                                        <div class="col-sm-5">
                                            <b>Customer </b>

                                            <span style="font-weight: bold;">:</span>  <a style="text-decoration: underline" href="" id="hrefCustomer" target="_blank">#<span id="txtMemberId"></span></a>&nbsp;<label id="txtMemberName"></label><%--(class <span id="txtClassType"></span>)--%> 
                                        </div>
                                        <!-- /.col -->

                                      
                                        <div class="col-sm-3">
                                            <b>Account Balance:</b>
                                            <span style="font-weight: bold;"></span>
                                            <label id="lbloutstanding" style="color: #432727; font-weight: bold; font-size: 12px; color: red;">0</label>
                                        </div>
                                        <!-- /.col -->

                                        <input type="hidden" id="txtdeliverystatus" />
                                        <!-- /.col -->
                                    </div>
                                    <hr />

                                    <div class="col-sm-3" style="float:left">
                                        <div><b>INVOICE REFERENCE</b></div>
                                    <div class="input-group">
<input type="text" class="form-control" style="height:34px" id="txt_invoice_ref" />
<span class="input-group-btn">
<button type="button" class="btn btn-primary" style="height:34px" onclick="update_invoice_ref();">UPDATE</button>
</span>
</div>
                                        </div>

                                    



                                </div>
                                <div class="clear"></div>


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
                                                 <th></th>
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
                        
                        <div class="clearfix"></div>
                       <div class="container">


                                            <div class="modal fade" id="popupEditItem" role="dialog" style="z-index: 16000;">
                                                <div class="modal-dialog modal-md">
                                                    <div class="modal-content">
                                                        <div class="modal-header">
                                                            <button type="button" class="close" onclick="javascript:popupclose('popupEditItem');">&times;</button>
                                                            <div class="col-md-6 col-sm-6 col-xs-8">
                                                                <h4 class="modal-title">Edit Item</h4>
                                                            </div>

                                                        </div>
                                                        <div class="modal-body">
                                                            <div class="row">
                                                                <div class="col-md-12">
                                                                    <form role="form" class="form-horizontal">
                                                                        <div class="form-group">
                                                                            <label class="control-label col-md-3 col-sm-3 col-xs-12">
                                                                                Item
                                                                            </label>
                                                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                                                <input type="text" id="txtItemName" placeholder="Enter Item name" required="required" class="form-control col-md-7 col-xs-12" disabled />
                                                                            </div>
                                                                        </div>

                                                                        <div class="form-group">
                                                                            <label class="control-label col-md-3 col-sm-3 col-xs-12" for="last-name">
                                                                                Quantity<span class="required">*</span>
                                                                            </label>
                                                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                                                <input type="number" id="txtQty" value="0" style="padding: 0px; text-indent: 3px;" placeholder="Enter price" name="last-name" min="0" required="required" class="form-control col-md-7 col-xs-12" onkeyup="changeFields();"/>
                                                                            </div>
                                                                        </div>
                                                                        
                                                                        <div class="form-group">
                                                                            <label class="control-label col-md-3 col-sm-3 col-xs-12" for="last-name">
                                                                               Price<span class="required">*</span>
                                                                            </label>
                                                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                                                <input type="number" id="txtPrice" value="0" style="padding: 0px; text-indent: 3px;" placeholder="Enter price" name="last-name" min="0" required="required" class="form-control col-md-7 col-xs-12"  onkeyup="changeFields();" />
                                                                            </div>
                                                                        </div>
                                                                            
                                                                        <div class="form-group">
                                                                            <label class="control-label col-md-3 col-sm-3 col-xs-12">
                                                                               Total
                                                                            </label>
                                                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                                                <input type="number" id="txtTaxExcludedTotal" required="required" class="form-control col-md-7 col-xs-12" disabled=""/>
                                                                            </div>
                                                                        </div>
                                                                      
                                                                        <div class="form-group" style="display:">
                                                                            <label class="control-label col-md-3 col-sm-3 col-xs-12">
                                                                               Tax Amt
                                                                            </label>
                                                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                                                <input type="number" id="txtTaxAmt"  required="required" class="form-control col-md-7 col-xs-12" disabled />
                                                                            </div>
                                                                        </div>

                                                                        <div class="form-group">
                                                                            <label class="control-label col-md-3 col-sm-3 col-xs-12">
                                                                                Net Amount
                                                                            </label>
                                                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                                                <input type="number" id="txtTotal"  required="required" class="form-control col-md-7 col-xs-12" disabled="" />
                                                                            </div>(Included Tax amount)
                                                                        </div>
                                                                    
                                                                        <div class="form-group">
                                                                            <label class="control-label col-md-3 col-sm-3 col-xs-12">
                                                                               Reason
                                                                            </label>
                                                                            <div class="col-md-6 col-sm-6 col-xs-12">
                                                                                <select class="form-control" id="selReason"><option value="0">Damaged</option><option value="1">Expired</option><option value="2">No Damage &amp; Ready to use</option></select>
                                                                            </div>
                                                                        </div>
                  
                                                                    </form>
                                                                    <div class="clearfix"></div>

                                                                    <div class="ln_solid"></div>
                                                                    <div class="form-group" style="padding-bottom: 40px;">
                                                                        <div class="col-md-6 col-sm-6 col-xs-12 col-md-offset-3">
                                                                            <div id="btnSave">
                                                                                <div class="btn btn-success mybtnstyl" onclick="javascript:editReturnItemDetails();">Update</div>
                                                                            </div>

                                                                            <div id="btnDelete">
                                                                                <div class="btn btn-danger mybtnstyl" onclick="javascript:deleteItem();">Delete</div>
                                                                            </div>
                                                                            <%--<div onclick="javascript:clearUsertype();" class="btn btn-danger mybtnstyl" id="btnCancel">CANCEL</div>--%>
                                                                            <%--<button  id="btnUserDetailsUpdate" style="display:none" class="btn btn-success" onclick="javascript:updateUserDetails();" type="reset">Update</button>--%>
                                                                        </div>
                                                                    </div>

                                                                </div>

                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>

                                        </div>

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
