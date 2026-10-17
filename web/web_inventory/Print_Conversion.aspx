<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Print_Conversion.aspx.cs" Inherits="web_inventory_Print_Conversion" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Item Converter  | Invoice Me</title>

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

        var conversionDatas;

        conversionDatas = <%=conversionDatas%>

        var src_array = [];
        var dest_array = [];
        var sel_src_itbs = -1;
        var sel_dest_itbs = -1;
        var sel_src_item_name = -1;
        var sel_dest_item_name = -1;
        var currnt_session_id = 0;
        currnt_session_id = getSessionID();
        var sel_branch_id = -1;
        var sel_conv_id = 0;

        $(document).ready(function () {

            var BranchId = $.cookie("invntrystaffBranchId");
            var CountryId = $.cookie("invntrystaffCountryId");
            $("#txtitemcountry").val("0");
            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " © ");

            load_conversion_info_for_edit();
            search_src_item();
            search_dest_item();
            //list_input_items();
            //list_output_items();


        });

        function load_conversion_info_for_edit(){
        
            var basic_details = conversionDatas.basedata[0];
            
            $("#Div_lbl_hdr").html('<h4> Ref ID : #'+ basic_details.conv_id +' <br /> <small><b>Warehouse :</b></small> '+ basic_details.branch_name +'<br /><small><b>Date :</b> ' + basic_details.conv_date + '</small><br /><small><b>User :</b> '+ basic_details.username +'</small></h4>');
            sel_branch_id = basic_details.branch_id;
            sel_conv_id = basic_details.conv_id;
            //console.log('branch :' +sel_branch_id);
            src_array = [];
            dest_array = [];

            $.each(conversionDatas.itemdata, function (i, item) {

                if(item.conv_itm_type == 1){

                    src_array.push({

                        "itbs_id": item.itbs_id,
                        "itm_name": item.itm_name,
                        "itm_qty": item.conv_qty
                    });
                }
                if(item.conv_itm_type == 2){

                    dest_array.push({

                        "itbs_id": item.itbs_id,
                        "itm_name": item.itm_name,
                        "itm_qty": item.conv_qty
                    });
                }

            });

            list_input_items();
            list_output_items();

           
            
        }

        function change_warehouse() {

            sel_src_itbs == -1;
            sel_dest_itbs == -1;
            var sel_src_item_name = -1;
            var sel_dest_item_name = -1;
            reset_all_data();
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

        function search_src_item() {
            //Start autocoumplete
            $("#txtSrcItemAutoPopulate").autocomplete({

                source: function (request, response) {
                    $.ajax({
                        type: "POST",
                        contentType: "application/json; charset=utf-8",
                        url: "Item_Conversion.aspx/showItems",
                        data: "{'searchText':'" + $("#txtSrcItemAutoPopulate").val() + "','branch_id':'" + sel_branch_id + "'}",
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
                        sel_src_item_name = '';
                        sel_src_itbs = -1;
                    } else {
                        $("#txtSrcItemAutoPopulate").val(ui.item.label); //ui.item is your object from the array
                        sel_src_item_name = ui.item.label;
                        sel_src_itbs = ui.item.id
                    }

                    event.preventDefault();
                },
                minLength: 1
            });
            //End autocomplete
        }

        function search_dest_item() {
            //Start autocoumplete
            $("#txtDestItemAutoPopulate").autocomplete({

                source: function (request, response) {
                    $.ajax({
                        type: "POST",
                        contentType: "application/json; charset=utf-8",
                        url: "Item_Conversion.aspx/showItems",
                        data: "{'searchText':'" + $("#txtDestItemAutoPopulate").val() + "','branch_id':'" + sel_branch_id + "'}",
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
                        $("#txtDestItemAutoPopulate").val("");
                        sel_dest_item_name = '';
                        sel_dest_itbs = -1;

                    } else {
                        $("#txtDestItemAutoPopulate").val(ui.item.label); //ui.item is your object from the array
                        sel_dest_item_name = ui.item.label;
                        sel_dest_itbs = ui.item.id;
                    }

                    event.preventDefault();
                },
                minLength: 1
            });
            //End autocomplete
        }

        function reset_src_input_values() {

            $("#txtSrcItemAutoPopulate").val("");
            $("#txt_src_qty").val("");
            sel_src_itbs = -1;
            sel_src_item_name = "";
        }

        function reset_dest_input_values() {

            $("#txtDestItemAutoPopulate").val("");
            $("#text_dest_qty").val("");
            sel_dest_itbs = -1;
            sel_dest_item_name = "";
        }

        function add_item_to_input_list() {

            if (sel_src_itbs == -1) { alert("Please choose an Input item!"); return; }
            if ($("#txt_src_qty").val() == "0" || isNaN($("#txt_src_qty").val()) || parseInt($("#txt_src_qty").val()) < 0 || $("#txt_src_qty").val() == "" || $("#txt_src_qty").val() == null || $("#txt_src_qty").val() == undefined) {

                alert("Please enter a valid quantity for the input item");
                return;
            }

            if (dest_array.length > 0) {

                for (var x = 0; x < dest_array.length; x++) {

                    if (dest_array[x]['itbs_id'] == sel_src_itbs) {

                        alert("This item is already added in the output item list! Please choose a different item.");
                        return;
                    }
                }
            }

            var arr_len = src_array.length;
            if (arr_len > 0) {

                if (dest_array.length > 1) {

                    alert("The Output item list already having multiple items! Either Input list or output list support multiple items at a time in Item conversion");
                    return;
                }

                for (var x = 0; x < arr_len; x++) {

                    if (src_array[x]['itbs_id'] == sel_src_itbs) {

                        alert("The Item is already present in the Input list!");
                        return;
                    }
                }
            }



            try {

                $.ajax({

                    type: "POST",
                    url: "Item_Conversion.aspx/Get_Item_Stock",
                    data: "{'itbs_id':'" + sel_src_itbs + "'}",
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (msg) {

                        var obj = JSON.parse(msg.d);
                        //alert(obj.data[0].stock);

                        var tot_req_stock = parseInt(obj.data[0].stock) - parseInt($("#txt_src_qty").val());


                        if (obj.data[0].stock <= 0 || tot_req_stock <= 0) {

                            var r = confirm('The Current Stock of this Item in the warehouse is ' + obj.data[0].stock + ' . Are you sure to Add it to the Input items?');
                            if (r == true) {

                                src_array.push({

                                    "itbs_id": sel_src_itbs,
                                    "itm_name": sel_src_item_name,
                                    "itm_qty": $.trim($("#txt_src_qty").val())
                                });

                                
                                list_input_items();
                                reset_src_input_values();
                            }
                        }
                        else {

                            src_array.push({

                                "itbs_id": sel_src_itbs,
                                "itm_name": sel_src_item_name,
                                "itm_qty": $.trim($("#txt_src_qty").val())
                            });

                            
                            list_input_items();
                            reset_src_input_values();
                        }



                    },
                    error: function (xhr, status) {

                        alert("Internet Problem..!");
                    }
                });


            }
            catch (ex) {

                alert(ex.message);
            }
        }

        function list_input_items() {

            var arr_len = src_array.length;
            var htm = "";
            if (arr_len > 0) {

                for (var x = 0; x < arr_len; x++) {

                    htm += '<tr class="even pointer">';                    
                    htm += '<td class="text-left" style="width:50px">' + (x + 1) + '</td>';
                    htm += '<td class="text-left "><strong>' + src_array[x]['itm_name'] + '</strong></td>';
                    htm += '<td class=" text-left"  style="width:100px">' + src_array[x]['itm_qty'] + '</td>';
                    htm += '</tr>';

                }

                $('#Tbody1').html(htm);
            }
            else {

                htm = "<td colspan='3' style='text-align:center'>No Input Items Added</td>";
                $('#Tbody1').html(htm);
            }
        }

       


        function list_output_items() {

            var arr_len = dest_array.length;
            var htm = "";
            if (arr_len > 0) {

                for (var x = 0; x < arr_len; x++) {

                    htm += '<tr class="even pointer">';                    
                    htm += '<td class="text-left" style="width:50px">' + (x + 1) + '</td>';
                    htm += '<td class="text-left "><strong>' + dest_array[x]['itm_name'] + '</strong></td>';
                    htm += '<td class=" text-left" style="width:100px">' + dest_array[x]['itm_qty'] + '</td>';
                    htm += '</tr>';

                }

                $('#Tbody2').html(htm);
            }
            else {

                htm = "<td colspan='3' style='text-align:center'>No Output Items Added</td>";
                $('#Tbody2').html(htm);
            }
        }
       
        function close_modal() {

            $("#itemModal").modal('hide');
        }

        function print_conversion(){
        
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
                            <label style="font-weight: 400; font-size: 14px;">Item Convertion</label>

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
                                           
                                            <div onclick="javascript:print_conversion();" style="margin-bottom:20px" class="btn btn-success">Print Convertion</div>

                                        </div>
                                    </div>

                    <div class="row">

                        <div class="col-md-12 col-sm-12 col-xs-6" id="Div3">
                            <div class="x_panel">
                                <div class="x_content">

                                    <form id="Form2" data-parsley-validate class="form-horizontal form-label-left">

                                        <div class="col-md-12" style="display:none">
                                            <div class="form-group">
                                                <label class="control-label col-md-4 col-sm-3 col-xs-12" for="first-name" style="color:#2478b4"">
                                                    Warehouse<span class="required">*</span>
                                                </label>
                                                <div class="col-md-8 col-sm-6 col-xs-12">
                                                    <select class="form-control" id="select_src_warehouse" style="border: 1px solid #2478b4" onchange="change_warehouse();" runat="server">
                                                    </select>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="col-md-12 col-sm-12 col-xs-12" id="Div_lbl_hdr" style="border:1px solid #d2cccc">
                            
                        </div>

                                    </form>

                                    <div class="clearfix"></div>

                                </div>
                            </div>
                        </div>

                        <div class="col-md-6 col-sm-12 col-xs-6" id="Div5">
                            <%--<h3> EDIT ITEM CONVERTION
                                <br />
                                <small>Make changes to item conversions</small>
                                
                            </h3>--%>
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
                                            <label>Input Items</label>
                                            <table class="table table-striped jambo_table bulk_action">
                                    <thead style="background-color:#566777">
                                        <tr class="headings">
                                            <th class="column-title">Sl. </th>
                                            <th class="column-title">Item Name </th>
                                            <th class="column-title">Debit Qty </th>                                                                                 
                                        </tr>
                                    </thead>
                                    <tbody id="Tbody1">

                                      
                                    </tbody>
                                </table>

                                            </div>

    <div class="col-md-12 col-sm-12 col-xs-12">
                                            <label>Output Items</label>
                                            <table class="table table-striped jambo_table bulk_action">
                                    <thead style="background-color:#566777">
                                        <tr class="headings">                                            
                                            <th class="column-title">Sl. </th>
                                            <th class="column-title">Item Name </th>
                                            <th class="column-title">Credit Qty </th>                                                                                                                             
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

