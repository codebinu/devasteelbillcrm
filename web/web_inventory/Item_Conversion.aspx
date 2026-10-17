<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Item_Conversion.aspx.cs" Inherits="web_incomExpense_Item_Conversion" %>

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

            search_src_item();
            search_dest_item();
            list_input_items();
            list_output_items();


        });

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
                        data: "{'searchText':'" + $("#txtSrcItemAutoPopulate").val() + "','branch_id':'" + $("#select_src_warehouse").val() + "'}",
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
                        data: "{'searchText':'" + $("#txtDestItemAutoPopulate").val() + "','branch_id':'" + $("#select_src_warehouse").val() + "'}",
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

                                control_warehouse_access();
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

                            control_warehouse_access();
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
                htm += '<td class="a-center ">';
                htm += '<div class="icheckbox_flat-green" style="position: relative;">';
                htm += '<input type="checkbox" class="flat" name="table_records" style="position: absolute; opacity: 0;">';
                htm += '<ins class="iCheck-helper" style="position: absolute; top: 0%; left: 0%; display: block; width: 100%; height: 100%; margin: 0px; padding: 0px; background: rgb(255, 255, 255); border: 0px; opacity: 0;"></ins></div>';
                htm += '</td>';
                htm += '<td class="text-left">' + (x + 1) + '</td>';
                htm += '<td class="text-left "><strong>' + src_array[x]['itm_name'] + '</strong></td>';
                htm += ' <td class=" text-left">' + src_array[x]['itm_qty'] + ' <i class="success fa fa-long-arrow-down" style="color: #da2e2e"></i></td>';
                htm += '<td class="text-left"> <i class="fa fa-trash" onclick="remove_input_entry(' + x + ')" style="color:#d00101"> REMOVE</i></td> </tr>';

                }

                $('#src_itm_list').html(htm);
            }
            else {

                htm = "<td colspan='5' style='text-align:center'>No Input Items Added</td>";
                $('#src_itm_list').html(htm);
            }
        }

        function remove_input_entry(index) {

            var result = confirm("Are you sure to remove this item from Input item list?");
            if (result) {
                var start_index = index;
                var rm_count = 1;
                var removed_elements = src_array.splice(start_index, rm_count);
                list_input_items();
                control_warehouse_access();

            } else {
                return false;
            }
        }
        
        function add_item_to_output_list() {

            if (sel_dest_itbs == -1) { alert("Please choose an Output item!"); return; }
            if ($("#text_dest_qty").val() == "0" || isNaN($("#text_dest_qty").val()) || parseInt($("#text_dest_qty").val()) < 0 || $("#text_dest_qty").val() == "" || $("#text_dest_qty").val() == null || $("#text_dest_qty").val() == undefined) {

                alert("Please enter a valid quantity for the Output item");
                return;
            }

            if (src_array.length > 0) {

                for (var x = 0; x < src_array.length; x++) {

                    if (src_array[x]['itbs_id'] == sel_dest_itbs) {

                        alert("This item is already added in the Input item list! Please choose a different item.");
                        return;
                    }
                }
            }

            var arr_len = dest_array.length;
            if (arr_len > 0) {

                if (src_array.length > 1) {
                    alert("The Input item list already having multiple items! Either Input list or output list support multiple items at a time in Item conversion");
                    return;
                }

                for (var x = 0; x < arr_len; x++) {

                    if (dest_array[x]['itbs_id'] == sel_dest_itbs) {

                        alert("The Item is already present in the Output list!");
                        return;
                    }
                }
            }

            try {

                dest_array.push({

                    "itbs_id": sel_dest_itbs,
                    "itm_name": sel_dest_item_name,
                    "itm_qty": $.trim($("#text_dest_qty").val())
                });

                control_warehouse_access();
                list_output_items();
                reset_dest_input_values();

                
            }
            catch (ex) {

                alert(ex.message);
            }
        }

        function list_output_items() {

            var arr_len = dest_array.length;
            var htm = "";
            if (arr_len > 0) {

                for (var x = 0; x < arr_len; x++) {

                    htm += '<tr class="even pointer">';
                    htm += '<td class="a-center ">';
                    htm += '<div class="icheckbox_flat-green" style="position: relative;">';
                    htm += '<input type="checkbox" class="flat" name="table_records" style="position: absolute; opacity: 0;">';
                    htm += '<ins class="iCheck-helper" style="position: absolute; top: 0%; left: 0%; display: block; width: 100%; height: 100%; margin: 0px; padding: 0px; background: rgb(255, 255, 255); border: 0px; opacity: 0;"></ins></div>';
                    htm += '</td>';
                    htm += '<td class="text-left">' + (x + 1) + '</td>';
                    htm += '<td class="text-left "><strong>' + dest_array[x]['itm_name'] + '</strong></td>';
                    htm += ' <td class=" text-left">' + dest_array[x]['itm_qty'] + ' <i class="success fa fa-long-arrow-up" style="color: #54ae2e"></i></td>';
                    htm += '<td class="text-left"><i class="fa fa-trash" onclick="remove_output_entry(' + x + ')" style="color:#d00101"> REMOVE</i></td>  </tr>';

                }

                $('#dest_itm_list').html(htm);
            }
            else {

                htm = "<td colspan='5' style='text-align:center'>No Output Items Added</td>";
                $('#dest_itm_list').html(htm);
            }
        }

        function remove_output_entry(index) {

            var result = confirm("Are you sure to remove this item from Output item list?");
            if (result) {
                var start_index = index;
                var rm_count = 1;
                var removed_elements = dest_array.splice(start_index, rm_count);
                list_output_items();
                control_warehouse_access();

            } else {
                return false;
            }
        }

        function control_warehouse_access() {

            if (src_array.length > 0 || dest_array.length > 0) {

                $('#select_src_warehouse').prop('disabled', true);
            }
            else {
                $('#select_src_warehouse').prop('disabled', false);
            }
        }
        
        function reset_all_data() {

            src_array = []; dest_array = []; reset_src_input_values(); reset_dest_input_values(); control_warehouse_access(); list_input_items(); list_output_items();

        }

        function verify_conversion() {

            if (dest_array.length == 0 || src_array.length == 0) {

                alert('Input & Output items should be entered before conversion!!!');
            }
            else {

                $("#lbl_wh_name").html(' ( ' +$("#select_src_warehouse option:selected").text() + ' )');
                $("#itemModal").modal('show');

                var arr_len = src_array.length;
                var htm = "";

                for (var x = 0; x < arr_len; x++) {

                    htm += '<tr class="even pointer">';
                    htm += '<td class="a-center ">';
                    htm += '<div class="icheckbox_flat-green" style="position: relative;">';
                    htm += '<input type="checkbox" class="flat" name="table_records" style="position: absolute; opacity: 0;">';
                    htm += '<ins class="iCheck-helper" style="position: absolute; top: 0%; left: 0%; display: block; width: 100%; height: 100%; margin: 0px; padding: 0px; background: rgb(255, 255, 255); border: 0px; opacity: 0;"></ins></div>';
                    htm += '</td>';
                    htm += '<td class="text-left">' + (x + 1) + '</td>';
                    htm += '<td class="text-left "><strong>' + src_array[x]['itm_name'] + '</strong></td>';
                    htm += ' <td class=" text-left" style="font-size:18px">' + src_array[x]['itm_qty'] + ' <i class="success fa fa-long-arrow-down" style="color: #da2e2e"></i></td>';
                    htm += ' </tr>';
                }
                $('#Tbody_vrfy_input').html(htm);

                var darr_len = dest_array.length;
                var dhtm = "";

                for (var x = 0; x < darr_len; x++) {

                    dhtm += '<tr class="even pointer">';
                    dhtm += '<td class="a-center ">';
                    dhtm += '<div class="icheckbox_flat-green" style="position: relative;">';
                    dhtm += '<input type="checkbox" class="flat" name="table_records" style="position: absolute; opacity: 0;">';
                    dhtm += '<ins class="iCheck-helper" style="position: absolute; top: 0%; left: 0%; display: block; width: 100%; height: 100%; margin: 0px; padding: 0px; background: rgb(255, 255, 255); border: 0px; opacity: 0;"></ins></div>';
                    dhtm += '</td>';
                    dhtm += '<td class="text-left">' + (x + 1) + '</td>';
                    dhtm += '<td class="text-left "><strong>' + dest_array[x]['itm_name'] + '</strong></td>';
                    dhtm += ' <td class="text-left" style="font-size:18px">' + dest_array[x]['itm_qty'] + ' <i class="success fa fa-long-arrow-up" style="color: #54ae2e"></i></td>';
                    dhtm += '</tr>';

                }

                $('#Tbody_vrfy_output').html(dhtm);
            }
            
        }

        function close_modal() {

            $("#itemModal").modal('hide');
        }

        function perform_conversion() {

            var postObj = {

                convert_data: {

                    conv_session_id: currnt_session_id,
                    branch_id: $("#select_src_warehouse").val(),
                    user_id: $.cookie("invntrystaffId"),
                    input_items: JSON.stringify(src_array),
                    input_count: src_array.length,
                    output_items: JSON.stringify(dest_array),
                    output_count: dest_array.length
                }
            };

            $.ajax({
                type: "POST",
                url: "Item_Conversion.aspx/Convert_Items",
                data: JSON.stringify(postObj),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                crossDomain: true,
                timeout: 15000,
                success: function (resp) {

                    var obj = JSON.parse(resp.d);

                    if (resp.d == "") {

                        alert("An error occured during the conversion! Please Try again.");
                    }
                    else if (obj.result == "REPEAT") {

                        alert("The Conversion is already completed & saved in the database! Please reload the page");
                    }
                    else if (obj.result == "SUCCESS") {

                        reset_all_data();
                        close_modal();
                        currnt_session_id = getSessionID();
                        alert("The Conversion Completed Successfully! The stock has been reflected in the warehouse");
                    }
                    else if (obj.result == "FAILED") {

                        alert("An error occured during the conversion! Please Try again.");
                    }
                    else {

                        alert("An error occured during the conversion! Please Try again.");
                    }
                },
                error: function (e) {

                    alert("An Internet Issue occured! Please Try again.");
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
                                                    Choose Warehouse<span class="required">*</span>
                                                </label>
                                                <div class="col-md-8 col-sm-6 col-xs-12">
                                                    <select class="form-control" id="select_src_warehouse" style="border: 1px solid #2478b4" onchange="change_warehouse();" runat="server">
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
                            <h3>ITEM CONVERTER
                                <br />
                                <small>Convert Items within the Warehouse</small>
                            </h3>
                        </div>
                       

                    </div>
                  
                   
                    <div class="row">
                        <div class="col-md-6 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title" style="margin-bottom: 0px; text-align: center">
                                    <h5 style="text-align: center; color: #2478b4; font-weight: bolder">Input Item Details </h5>
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
                                                    Input Item<span class="required">*</span>
                                                </label>
                                                <div class="col-md-8 col-sm-6 col-xs-12">
                                                    <input type="text" class="form-control col-md-7 col-sm-6 col-xs-12 ui-autocomplete-input" placeholder="Search for Input Item" required="required" id="txtSrcItemAutoPopulate" autocomplete="off" style="margin-bottom:10px">
                                                </div>
                                                <%--<div class="" style="font-size: 20px;" title="Add Product to List">
												<label onclick="add_products();" class="fa fa-plus-square" style="color: #2c5db7; cursor: pointer;"></label>
											</div>--%>
                                            </div>
                                            <div class="form-group">
                                                <label class="control-label col-md-4 col-sm-3 col-xs-12" for="first-name">
                                                    Quantity <span class="required">*</span>
                                                </label>
                                                <div class="col-md-8 col-sm-6 col-xs-12">
                                                    <input type="number" id="txt_src_qty" placeholder="Enter input Item Quantity" required="required" class="form-control col-md-7 col-xs-12" autocomplete="off" style="margin-bottom:10px;" />
                                                </div>
                                            </div>

                                            <div class="form-group">
                                                <div class="control-label col-md-12 col-sm-12 col-xs-12">
                                                    <%--<button  class="btn " style="color: #6f6e6e" onclick="javascript:add_item_to_input_list();">Reset</button>--%>
                                                    <div onclick="javascript:reset_src_input_values();" style="color: #6f6e6e;background-color:#dddddd" class="btn">Clear</div>
                                                    <div onclick="javascript:add_item_to_input_list();"  class="btn btn-primary">Add Item</div>
                                                    <%--<button type="button" class="btn btn-primary">Add Item</button>--%>
                                                </div>
                                            </div>

                                        </div>

                                    </form>


                                </div>

                                <div class="clearfix"></div>
                                <div class="ln_solid"></div>

                                <table class="table table-striped jambo_table bulk_action">
                                    <thead style="background-color:#f1eeee;color:#525252">
                                        <tr class="headings">
                                            <th></th>
                                            <th class="column-title">Sl No. </th>
                                            <th class="column-title">Input Item(s) </th>
                                            <th class="column-title">Quantity </th>
                                            <th class="column-title no-link last"><span class="nobr">Action</span>
                                            </th>

                                        </tr>
                                    </thead>
                                    <tbody id="src_itm_list">

                                      
                                    </tbody>
                                </table>

                            </div>
                        </div>

                        <div class="col-md-6 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title" style="margin-bottom: 0px; text-align: center">
                                    <h5 style="text-align: center; color: #2478b4; font-weight: bolder">Output Item Details </h5>
                                    <ul class="nav navbar-right panel_toolbox">
                                    </ul>

                                </div>
                                <div class="x_content">
                                    <br />
                                    <form id="Form1" data-parsley-validate class="form-horizontal form-label-left">
                                        <div class="col-md-12">

                                            <div class="form-group">
                                                <label class="control-label col-md-4 col-sm-3 col-xs-12" for="first-name">
                                                    Output Item<span class="required">*</span>
                                                </label>
                                                <div class="col-md-8 col-sm-6 col-xs-12">
                                                    <input type="text" class="form-control col-md-7 col-sm-6 col-xs-12 ui-autocomplete-input" placeholder="Search for Output Item" required="required" id="txtDestItemAutoPopulate" autocomplete="off" style="margin-bottom:10px;" />
                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <label class="control-label col-md-4 col-sm-3 col-xs-12" for="first-name">
                                                    Quantity <span class="required">*</span>
                                                </label>
                                                <div class="col-md-8 col-sm-6 col-xs-12">
                                                    <input type="number" id="text_dest_qty" placeholder="Enter Output Item Quantity" required="required" class="form-control col-md-7 col-xs-12" autocomplete="off" style="margin-bottom:10px;" />
                                                </div>
                                            </div>

                                            <div class="form-group">
                                                <div class="control-label col-md-12 col-sm-12 col-xs-12">
                                                    <%--<button type="button" class="btn " style="color: #6f6e6e">add_item_to_output_list</button>--%>
                                                    <div onclick="javascript:reset_dest_input_values();" style="color: #6f6e6e;background-color:#dddddd" class="btn">Clear</div>
                                                    <div onclick="javascript:add_item_to_output_list();" class="btn btn-primary">Add Item</div>
                                                    
                                                </div>
                                            </div>

                                        </div>

                                    </form>


                                </div>

                                <div class="clearfix"></div>
                                <div class="ln_solid"></div>

                                <table class="table table-striped jambo_table bulk_action">
                                    <thead style="background-color:#f1eeee;color:#525252">
                                        <tr class="headings">
                                            <th></th>
                                            <th class="column-title">Sl No. </th>
                                            <th class="column-title">Output Item(s) </th>
                                            <th class="column-title">Quantity </th>
                                            <th class="column-title no-link last"><span class="nobr">Action</span>
                                            </th>

                                        </tr>
                                    </thead>
                                    <tbody id="dest_itm_list">
                                       

                                    </tbody>
                                </table>

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

                                    <div class="form-group">
                                        <div class="col-md-12 col-sm-12 col-xs-12">
                                           

                                            <div onclick="javascript:reset_all_data();" style="color:#6f6e6e;background-color:#dddddd" class="btn">Clear All Added items</div>
                                            <div onclick="javascript:verify_conversion();" class="btn btn-success">Convert Items</div>

                                        </div>
                                    </div>

                                </div>
                            </div>

                        </div>
                    </div>

                    <div class="row">
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
