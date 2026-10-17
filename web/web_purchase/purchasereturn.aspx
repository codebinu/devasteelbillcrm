<%@ Page Language="C#" AutoEventWireup="true" CodeFile="purchasereturn.aspx.cs" Inherits="web_purchase_purchasereturn" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Purchase Return | Invoice Me</title>
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



    <script type="text/javascript">
        var vendorId;
        var returnId;
        var InvoiceNum;
        var sessionId = 0;
        var classType = "";
        var tax_method;
        var isTaxInclusive;
        var returnObj = "";
        var itemDet = "";
        var branchDetails = <%=branchDetails%>
            $(document).ready(function () {
                tax_method = branchDetails[0].branch_tax_method;
                isTaxInclusive = branchDetails[0].branch_tax_inclusive;
                vendorId = getQueryString("vendorId");
                //alert(vendorId);
                sessionId = getSessionID();
                //  alert(orderId);
                console.log(vendorId);
                getBrands();
                if (getQueryString("vendorId") != undefined) {
                    showVendorDetails(vendorId);
                }
                

            });

        //start create session Id
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
        function getBrands() {
            loading();
            $.ajax({
                type: "POST",
                url: "purchasereturn.aspx/getBrands",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    var obj = JSON.parse(msg.d);
                    var htm = "";
                    htm += '<option value="-1" selected="selected">-Brands--</option>';
                    $.each(obj, function (i, row) {
                        htm += '<option value="' + row.brand_id + '">' + row.brand_name + '</option>';
                    });
                    $("#selBrand").html(htm);
                    $("#selBasicBrand").html(htm);
                    getCategories();

                },
                error: function (xhr, status) {
                    Unloading();
                    //alert("fail" + status + ":::" + xhr.d);
                    alert("Internet Problem..!");
                }
            });
        }

        function getCategories() {
            loading();
            $.ajax({
                type: "POST",
                url: "purchasereturn.aspx/getCategories",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    var obj = JSON.parse(msg.d);
                    var htm = "";
                    htm += '<option value="-1" selected="selected">-Categories--</option>';
                    $.each(obj, function (i, row) {
                        htm += '<option value="' + row.cat_id + '">' + row.cat_name + '</option>';
                    });
                    $("#selCategory").html(htm);
                    $("#selBasicCategory").html(htm);

                },
                error: function (xhr, status) {
                    Unloading();
                    // alert("fail" + status + ":::" + xhr.d);
                    alert("Internet Problem..!");
                }
            });
        }
        //basic order details showing
        function showVendorDetails(vendorId) {
            loading();
            //  alert(vendorId);
            $.ajax({
                type: "POST",
                url: "purchasereturn.aspx/showVendorDetails",
                data: "{'vendorId':" + vendorId + "}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    console.log(msg);
                    if (msg.d != "N") {
                        var returnObj = JSON.parse(msg.d);
                        console.log(returnObj);
                        var vendor_details = returnObj.vendor[0];
                        if (vendor_details.outstanding == null || vendor_details.outstanding == "") {
                            vendor_details.outstanding = 0;
                        }
                        $("#txtoutstanding").text(vendor_details.outstanding);
                        if (vendor_details.outstanding_amt > 0) {
                            $("#txtoutstanding").css("color", "red");
                        } else {
                            $("#txtoutstanding").css("color", "green");
                        }
                        $("#lblvendorName").text(vendor_details.name);
                        // classType=vendor_details.class;
                       

                        // showing payment details
                        $("#tblReturnDetails > tbody").html("");
                        if (returnObj.return_details == "") {
                            var htmReturnDetails = '<tr><td colspan="7" style="text-align:center">Nothing Found</td></tr>';
                            $("#tblReturnDetails > tbody").append(htmReturnDetails);
                            return false;
                        }
                        var status;
                        var color;
                        $.each(returnObj.return_details, function (i, row) {
                            //alert(row.custBal-order_details.outstanding_amt);
                            $("#txtInvNo").text('Invoice No : '+ row.prm_invoice_no);
                            var htmReturnDetails = '<tr>';
                            htmReturnDetails += '<td>#' + row.prm_id + '</td>';
                            htmReturnDetails += '<td>' + row.date + '</td>';
                            //htmReturnDetails += '<td>' + row.narration + '</td>';
                            htmReturnDetails += '<td>' + row.user_name + '</td>';
                            htmReturnDetails += '<td>' + row.amount + '</td>';
                            if (row.prm_status == 1) {
                                status = "Initiated";
                                color = "blue";
                            } else if (row.prm_status == 2) {
                                status = "Received";
                                color = "green";
                            } else if (row.prm_status == 3) {
                                status = "Approved";
                                color = "orange";
                            } else if (row.prm_status == 4) {
                                status = "Cancelled";
                                color = "red";
                            }
                            htmReturnDetails += '<td style="color:' + color + ';font-weight:bold">' + status + '</td>';
                            htmReturnDetails += '<td><div onclick="showReturnDetails(' + row.prm_id + ')" class="btn btn-primary btn-xs"><li class="fa fa-eye" style="font-size:large;"></li></div></td>';
                            htmReturnDetails += '</tr>';

                            $("#tblReturnDetails > tbody").append(htmReturnDetails);
                        });

                    } else {
                        alert("No data found");
                    }
                },
                error: function (xhr, status) {
                    Unloading();
                    // alert("fail" + status + ":::" + xhr.d);
                    alert("Internet Problem..!");
                }
            });

        }

        function resetOrderitems() {
            $("#searchcustom1").val("");
            $("#searchInvoiceNum").val("");

            $("#searchcustom2").val("");
            $("#selBrand").val(-1);
            $("#selCategory").val(-1);
            searchOrderitems(1);
        }

        function searchOrderitems(page) {
            var postObj = {
                filters: {

                    vendorId: vendorId,
                    brand: $("#selBrand").val(),
                    category: $("#selCategory").val(),
                    searchCod: $("#searchcustom1").val(),
                    searchName: $("#searchcustom2").val(),
                    searchInvoiceNum: $("#searchInvoiceNum").val(),
                    page: page
                }
            };

            loading();
            //  var json_req = { orderid: orderNo, itemcode: itemcode, itemname: itemname };
            $.ajax({
                type: "POST",
                url: "purchasereturn.aspx/searchOrderitems",
                data: JSON.stringify(postObj),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d != "N") {
                        var itemdetails = JSON.parse(msg.d);
                        console.log(itemdetails);
                        var htm = "";
                        $("#lblReturnTotalrecords").text($(itemdetails).length);
                        //  htm += "<tr><td colspan='7'><div><span style='margin-left:0px;float:right;margin-top:4px;text-align:right;font-size:14px;color:#660000;'>Total Records: " + $(itemdetails).length + "</span></div></td> </tr>";
                        var serialNo = 1;
                        $.each(itemdetails, function (index, item) {
                            //  alert(item.total_qty);
                            var totalqty = item.total_qty - item.returned;
                            //  alert(totalqty);
                            if (totalqty == 0) {
                                htm += "<tr style='cursor:pointer;'";
                                htm += " title='Click to View' onclick=javascript:alertfunctn(); style='cursor:pointer;' alt='Working'><td>" + serialNo + "</td><td>" + item.itm_code + "</td><td>" + item.itm_name + "</td>";
                                htm += "<td>" + totalqty + "</td><td>" + item.return_price + "</td></tr>";
                            } else {
                                htm += "<tr style='cursor:pointer;'";
                                htm += " title='Click to View' onclick=javascript:selectOrderItem('" + item.itm_code.replace(/\s/g, '&nbsp;') + "','" + item.itm_name.replace(/\s/g, '&nbsp;') + "','" + totalqty + "','" + item.return_price + "','" + item.itbs_id + "','" + item.pi_qty + "','" + item.pi_price + "','" + item.pi_discount_rate + "','" + item.pm_id + "','" + item.ItemId + "','" + item.pi_item_cess + "','" + item.pi_item_tax + "','" + item.pm_invoice_no + "'); style='cursor:pointer;'><td>" + serialNo + "</td><td>" + getHighlightedValue($("#searchcustom1").val(), item.itm_code.toString()) + "</td><td>" + getHighlightedValue($("#searchcustom2").val(), item.itm_name) + "</td>";
                                htm += "<td style='font-weight:bold;font-size:14px;color:blue'><a href='/web_purchase/manageorders.aspx?orderId=" + item.pm_id + "' target='_blank'> #" + item.pm_invoice_no + "</a></td><td>" + totalqty + "</td><td>" + item.return_price + "</td></tr>";
                            }
                            serialNo = serialNo + 1;

                        });
                        $('#tableitemlist tbody').html(htm);
                        $("#findOrderItemDiv").show();
                    } else {
                        for (var i = 2; i < ($('#tablepos tr').length); i++) {
                            $('#tableitemlist > tbody > tr:gt(' + i + ')').remove();
                        }
                        $('#tableitemlist > tbody').html('<td colspan="6"><div style="width:100%;text-align:center"><div style="display:inline-block">Nothing Found...</div></div></td>');
                        $("#lblReturnTotalrecords").text(0);
                        $("#findOrderItemDiv").show();
                        Unloading();
                        return;
                    }
                },
                error: function (xhr, status) {
                    Unloading();
                    // alert("fail" + status + ":::" + xhr.d);
                    alert("Internet Problem..!");
                }
            });
        }
        function alertfunctn() {
            alert("Not enough stock for returning this item");
        }
        function popupclose(divid) {
            $("#" + divid).hide();
        }

        // start: Showing Details of selected order Item from Popup
        function selectOrderItem(item_code, item_name, quantity, purchaseprice, itbs_id, purchasedQty, price, discount, orderId, itemId, cess, tax, invoice_num) {
            //alert("product_code: " + product_code + ", product_name: " + product_name + ", sales_price: " + sales_price + ", CountryId: " + CountryId + ", Tax: " + Tax + ", Discount: " + Discount);
            var html = '';

            // product_name.replace('&nbsp;',' '); 
            var rowCount = $('#tblOrderItems tr').length;
            //  alert(rowCount);


            rowid = rowCount - 3;
            rowposition = rowCount - 1;
            //var currentItems = Array();
            //for (i = 1; i < rowposition; i++) {
            //    var currentId = $.trim($('#tblOrderItems tr:eq(' + i + ') td:eq(13)').text());
            //    currentItems.push(currentId);
            //}
            //for (j = 0; j < currentItems.length; j++) {
            //    if (currentItems[j] === itemId) {
            //        alert("This item already selected");
            //        return false;
            //    }
            //}
            var realtotal = 0;
            var nettotal = 0;
            var tax_rate = 0;
            var tax_amount = 0;
            var tax_included_nettotal = 0;
            var cessRate = 0;
            var cessAmount = 0;
            var qty = 1;
            var price = purchaseprice;
            if (tax_method == 0) // no tax
            {
                var tax_included_nettotal = qty * price;
                tax_included_nettotal = (parseFloat(tax_included_nettotal)).toFixed(2);
            }
            else {
                tax_rate = (parseFloat(tax)).toFixed(2);
                cessRate = (parseFloat(cess)).toFixed(2);
                if (isTaxInclusive == 1) { // tax is included with the price

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


            }


            html = "<tr>";
            html = html + "<td>" + item_code + " <span style='color:#337ab7;font-weight:bold'> (Order Item)</span></td>";
            html = html + "<td width='30%'>" + item_name.replace(/\u00a0/g, " "); +"</td>";
            html = html + "<td> " + purchasedQty + "</td>";
            //html = html + "<td> " + foc + "</td>";
            html = html + "<td> " + quantity + "</td>";
            html = html + "<td> " + price + "</td>";
            html = html + "<td> " + tax_amount.toFixed(2) + "</td>";
            html = html + "<td class='col-md-2'><input type='number' style='padding-right:2px;' onkeyup=modifyValues(this,'ReturnPrice'); value= " + purchaseprice + " data-taxtype='" + tax_rate + "' data-cessrate='" + cessRate + "' class='form-control'></td>";
            html = html + "<td class='col-md-1'><input type='number' style='padding-right:2px;' onkeyup=modifyValues(this,'ReturnQuantity'); value='1' data-quantityval='" + quantity + "' class='form-control'/></td>";
            html = html + "<td>" + tax_included_nettotal.toFixed(2) + "</td>";
            html = html + "<td class='col-md-2'><select class='form-control'><option value='0'>Damaged</option><option value='1'>Expired</option><option value='2'>No Damage & Ready to use</option></select></td>";
            html = html + "<td style='display:none;'>" + itbs_id + "</td>";
            html = html + "<td style='display:none;'>" + orderId + "</td>";
            html = html + "<td style='display:none;'>" + discount + "</td>";
            html = html + "<td style='display:none;'>" + tax + "</td>";
            html = html + "<td style='display:none;'>" + cess + "</td>";
            html = html + "<td style='display:none;'>" + invoice_num + "</td>";
            html += '<td><a onclick="DeleteRaw(this);" class="btn btn-danger btn-xs"><li class="fa fa-close"></li></a></td>';
            html = html + "</tr>";
            //alert(html);
            AddNewRaw(html);
            popupclose('popupReturn');


        }
        // Stop: Showing Details of selected order  Item from Popup

        function AddNewRaw(html) {
            $('#TrSum').before(html);
            totalcalculation();
        }

        function modifyValues(rowObj, changefield) {
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
            var rowId = $(rowObj).closest('td').parent()[0].sectionRowIndex;
            var currentstock = parseFloat($('#tblOrderItems tr:eq(' + rowId + ') td:eq(7)').find('input').attr('data-quantityval'));
            var returnQty = $.trim($('#tblOrderItems tr:eq(' + rowId + ') td:eq(7)').find('input').val());
            var purchaseprice = $.trim($('#tblOrderItems tr:eq(' + rowId + ') td:eq(6)').find('input').val());
            var tax = parseFloat($('#tblOrderItems tr:eq(' + rowId + ') td:eq(6)').find('input').attr('data-taxtype'));
            var cess = parseFloat($('#tblOrderItems tr:eq(' + rowId + ') td:eq(6)').find('input').attr('data-cessrate'));

            if (returnQty > currentstock || returnQty == "" || returnQty == 0 || (isNaN(purchaseprice) == true)) {
                if (currentstock != -1) {
                    if (returnQty > currentstock) {
                        alert("Return quantity greater than Purchased quantity");
                    }
                    $(rowObj).addClass("err");
                    if ($(document).find(".err").length > 0) {
                        $("#divsaveReturn").css('pointer-events', 'none');
                    } else {
                        $("#divsaveReturn").css('pointer-events', 'auto');
                    }

                    return;
                } else {
                }
            }
            $(rowObj).removeClass("err");

            var realtotal = 0;
            var nettotal = 0;
            var tax_rate = 0;
            var tax_amount = 0;
            var tax_included_nettotal = 0;
            var cessRate = 0;
            var cessAmount = 0;
            var qty = returnQty;
            var price = purchaseprice;
            if (tax_method == 0) // no tax
            {
                var total = qty * price;
                total = (parseFloat(total)).toFixed(2);
            }

            tax_rate = (parseFloat(tax)).toFixed(2);
            cessRate = (parseFloat(cess)).toFixed(2);
            if (isTaxInclusive == 1) { // tax is included with the price

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

            $('#tblOrderItems tr:eq(' + rowId + ') td:eq(8)').text(tax_included_nettotal.toFixed(2));


            totalcalculation();
        }
        function totalcalculation() {
            var rowCount = $('#tblOrderItems tr').length;
           // alert(rowCount);
            if (rowCount == 2) {
                $("#txtTotalReturnAmount").text("0");

            } else {
                var lastrow = rowCount - 2;
                var net_amount = 0.00;
                for (var i = 1; i <= lastrow; i++) {
                    net_amount += parseFloat($.trim($('#tblOrderItems tr:eq(' + i + ') td:eq(8)').text()));
                }
                //  alert(net_amount);
                $("#txtTotalReturnAmount").text(net_amount.toFixed(2));
            }
            if ($(document).find(".err").length > 0) {
                $("#divsaveReturn").css('pointer-events', 'none');
            } else {
                $("#divsaveReturn").css('pointer-events', 'auto');
            }

        }

        function DeleteRaw(ctrl) {

            $(ctrl).closest('tr').remove();
            var rowCount = parseInt($('#tblOrderItems tr').length);
            if (rowCount <= 3) {
                $("#txtTotalReturnAmount").text(0.0);

            }
            // calculteTable();
            totalcalculation();
        }



        function gotomanageorder() {
            window.location = 'manageorders.aspx?orderId=' + orderId;
        }

        function popupclose(divid) {
            // alert("");
            $("#" + divid).modal('hide');
        }

        function showReturnDetails(returnId) {
            $.ajax({
                type: "POST",
                url: "purchasereturn.aspx/showReturnDetails",
                data: "{'returnId':" + returnId + "}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    console.log(msg);
                    if (msg.d != "N") {
                        returnObj = JSON.parse(msg.d);
                        console.log(returnObj);
                        $("#popupReturnList").modal('show');

                        var htmRetDetails = "";
                        $("#tblReturnItemList > tbody").html("");
                        var type;
                        var color;
                        $.each(returnObj, function (i, item) {
                            // console.log(row);

                            htmRetDetails += '<tr>';
                            if (item.pm_id != 0) {
                                htmRetDetails += '<td>' + item.name + '<span style="color:blue"> (Order Item #' + returnObj[0].prm_invoice_no + ')</span></td>';
                            } else {
                                htmRetDetails += '<td>' + item.name + '<span style="color:blue"> (Basic Item)</span></td>';
                            }
                            htmRetDetails += '<td>' + item.qty + '</td>';
                            htmRetDetails += '<td>' + item.price + '</td>';
                            htmRetDetails += '<td>' + item.total + '</td>';
                            if (item.type == 0) {
                                type = "Damaged";
                                color = "red";
                            } else if (item.type == 1) {
                                type = "Expired";
                                color = "red";
                            } else if (item.type == 2) {
                                type = "No Damage & Ready to use";
                                color = "green";
                            }
                            htmRetDetails += '<td style="color:' + color + ';font-weight:bold">' + type + '</td>';
                            htmRetDetails += '<td><a class="btn btn-primary btn-xs" style="text-align:center;">';

                            htmRetDetails += "<span class='fa fa-pencil' style='font-size:14px;margin-top:3px;' onclick='showEditItemPopUp(" + item.id + ");' title='Edit'> </span></a></td>";
                            htmRetDetails += '</tr>';
                            htmRetDetails += '<tr>';
                            htmRetDetails += '</tr>';
                        });
                        $("#tblReturnItemList > tbody").append(htmRetDetails);
                    } else {
                        alert("No data found");
                    }
                },
                error: function (xhr, status) {
                    alert("Internet Problem..!");
                }
            });
        }

        function searchBasicItems(page) {
            var postObj = {
                filters: {
                    brand: $("#selBasicBrand").val(),
                    category: $("#selBasicCategory").val(),
                    searchCod: $("#searchCode").val(),
                    searchName: $("#searchName").val(),
                    page: page,
                    //cust_class: classType,
                    perPage: $("#selBasicPerPage").val()
                }
            };

            loading();
            //  var json_req = { orderid: orderNo, itemcode: itemcode, itemname: itemname };
            $.ajax({
                type: "POST",
                url: "purchasereturn.aspx/searchBasicItems",
                data: JSON.stringify(postObj),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d != "N") {
                        var itemdetails = JSON.parse(msg.d);
                        console.log(itemdetails);
                        var htm = "";
                        var html = "";
                        $("#spanBasicCount").text(itemdetails.count);
                        //  htm += "<tr><td colspan='7'><div><span style='margin-left:0px;float:right;margin-top:4px;text-align:right;font-size:14px;color:#660000;'>Total Records: " + $(itemdetails).length + "</span></div></td> </tr>";

                        $.each(itemdetails.data, function (index, item) {

                            htm += "<tr style='cursor:pointer;'";
                            htm += " title='Click to View' onclick=javascript:selectBasicItem('" + item.itm_code.replace(/\s/g, '&nbsp;') + "','" + item.itm_name.replace(/\s/g, '&nbsp;') + "','" + item.itbs_id + "','" + item.itm_price + "','" + item.tp_tax_percentage + "','" + item.tp_cess + "'); style='cursor:pointer;'><td>" + getHighlightedValue($("#searchCode").val(), item.itm_code.toString()) + "</td><td>" + getHighlightedValue($("#searchName").val(), item.itm_name) + "</td>";
                            htm += "<td>" + item.itm_price + "</td><td>" + item.tp_tax_percentage + "</td><td>" + item.tp_cess + "</td></tr>";
                        });
                        $('#tblBasicItems tbody').html(htm);
                        html += '<tr>';
                        html += '<td colspan="6">';
                        html += '<div  id="divPagination" style="text-align: center;">';
                        html += '</div>';
                        html += '</td>';
                        html += '</tr>';
                        // alert(htm);
                        $('#tblBasicItems > tbody').append(html);
                        $('#divPagination').html(paginate(itemdetails.count, $("#selBasicPerPage").val(), page, "searchBasicItems"));
                    } else {
                        for (var i = 2; i < ($('#tblBasicItems tr').length); i++) {
                            $('#tblBasicItems > tbody > tr:gt(' + i + ')').remove();
                        }
                        $('#tblBasicItems > tbody').html('<td colspan="6"><div style="width:100%;text-align:center"><div style="display:inline-block">Nothing Found...</div></div></td>');
                        $("#lblReturnTotalrecords").text(0);
                        return;
                    }
                },
                error: function (xhr, status) {
                    Unloading();
                    // alert("fail" + status + ":::" + xhr.d);
                    alert("Internet Problem..!");
                }
            });
        }

        // start: Showing Details of selected  basic Item from Popup
        function selectBasicItem(item_code, item_name, itbs_id, itm_price, tp_tax_percentage, tp_cess) {
            var html = '';
            var realtotal = 0;
            var nettotal = 0;
            var tax_rate = 0;
            var tax_amount = 0;
            var tax_included_nettotal = 0;
            var cessRate = 0;
            var cessAmount = 0;
            var qty = 1;
            var price = itm_price;
            if (tax_method == 0) // no tax
            {
                var tax_included_nettotal = qty * price;
                tax_included_nettotal = (parseFloat(tax_included_nettotal)).toFixed(2);
            }
            else {
                tax_rate = (parseFloat(tp_tax_percentage)).toFixed(2);
                cessRate = (parseFloat(tp_cess)).toFixed(2);
                if (isTaxInclusive == 1) { // tax is included with the price

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

            }



            html = "<tr>";
            html = html + "<td>" + item_code + " <span style='color:#26B99A;font-weight:bold'> (Basic Item)</span></td>";
            html = html + "<td>" + item_name.replace(/\u00a0/g, " "); +"</td>";
            html = html + "<td> 0</td>";
            html = html + "<td>0</td>";
     
            html = html + "<td> " + price + "</td>";
            html = html + "<td> " + tax_amount.toFixed(2) + "</td>";
            html = html + "<td class='col-md-2'><input type='number' style='padding-right:2px;' onkeyup=modifyValues(this,'ReturnPrice'); value= " + itm_price + " data-taxtype='" + tax_rate + "' data-cessrate='" + cessRate + "' class='form-control'></td>";
            html = html + "<td class='col-md-1'><input type='number' style='padding-right:2px;' onkeyup=modifyValues(this,'ReturnQuantity'); value='1' data-quantityval='-1' class='form-control'/></td>";
            html = html + "<td>" + tax_included_nettotal.toFixed(2) + "</td>";
            html = html + "<td class='col-md-2'><select class='form-control'><option value='0'>Damaged</option><option value='1'>Expired</option><option value='2'>No Damage & Ready to use</option></select></td>";
            html = html + "<td style='display:none;'>" + itbs_id + "</td>";
            html = html + "<td style='display:none;'>0</td>";
            html = html + "<td style='display:none;'>0</td>";
            html = html + "<td style='display:none;'>" + tp_tax_percentage + "</td>";
            html = html + "<td style='display:none;'>" + tp_cess + "</td>";
            html += '<td><a onclick="DeleteRaw(this);" class="btn btn-danger btn-xs"><li class="fa fa-close"></li></a></td>';
            html = html + "</tr>";
            //alert(html);
            AddNewRaw(html);
            popupclose('popupBasicReturn');


        }
        // Stop: Showing Details of selected basic Item from Popup

        function savepurchaseReturn() {
            var tblrowCount = $('#tblOrderItems tr').length;
            if (tblrowCount <= 2) {
                alert("Please Add Item");
                return;
            }

            rowCount = tblrowCount - 2;
            //  alert(rowCount);
            if (rowCount == 0) {
                alert("select an item");
                return;
            }
            var ret_Items = '';
            for (var i = 1; i <= rowCount; i++) {
                ret_Items += "{";
                ret_Items += "'itbs_id':'" + $("#tblOrderItems tr:eq(" + i + ") td:eq(10)").text() + "',";
                ret_Items += "'pm_id':'" + $("#tblOrderItems tr:eq(" + i + ") td:eq(11)").text() + "',";
                ret_Items += "'pm_invoice_no':'" + $("#tblOrderItems tr:eq(" + i + ") td:eq(15)").text() + "',";
                ret_Items += "'itm_code':'" + $("#tblOrderItems tr:eq(" + i + ") td:eq(0)").text() + "',";
                ret_Items += "'itm_name':'" + $("#tblOrderItems tr:eq(" + i + ") td:eq(1)").text() + "',";
                ret_Items += "'pi_price':'" + $("#tblOrderItems tr:eq(" + i + ") td:eq(6) input").val() + "',";
                ret_Items += "'pi_discount_rate':'" + $("#tblOrderItems tr:eq(" + i + ") td:eq(12)").text() + "',";
                ret_Items += "'pri_qty':'" + $("#tblOrderItems tr:eq(" + i + ") td:eq(7) input").val() + "',";
                ret_Items += "'pri_total':'" + $("#tblOrderItems tr:eq(" + i + ") td:eq(8)").text() + "',";
                ret_Items += "'pri_tax_percentage':'" + $("#tblOrderItems tr:eq(" + i + ") td:eq(13)").text() + "',";
                ret_Items += "'pri_cess':'" + $("#tblOrderItems tr:eq(" + i + ") td:eq(14)").text() + "',";
                ret_Items += "'pri_tax_amount':'" + $("#tblOrderItems tr:eq(" + i + ") td:eq(5)").text() + "',";
                ret_Items += "'pri_type':'" + $("#tblOrderItems tr:eq(" + i + ") td:eq(9)").find('option:selected').val() + "'";
                ret_Items += "},";
            }
            var lastChar = ret_Items.slice(-1);
            if (lastChar == ',') {
                ret_Items = ret_Items.slice(0, -1);
            }
            ret_Items = "[" + ret_Items + "]";
            console.log(ret_Items);
            var postObj = {

                return_order: {
                    vn_id: vendorId,
                    inv_no: InvoiceNum,
                    branchid: $.cookie("invntrystaffBranchId"),
                    return_Items: ret_Items,
                    item_count: rowCount,
                    user_id: $.cookie("invntrystaffId"),
                    description: $("#txtSpecialNote").val(),
                    session_id: sessionId,
                    status: 1
                }
            };
            // alert(postObj);
            console.log(postObj);
            loading();

            $.ajax({
                type: "POST",
                url: "purchasereturn.aspx/purchase_return",
                data: JSON.stringify(postObj),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();

                    if (msg.d == "FAILED") {
                        alert("Error!.. Please Try Again...");
                        return;
                    }
                    else if (msg.d == "SUCCESS") {
                        alert("Selected items returned successfully...");
                        window.location = 'purchasereturn.aspx?vendorId=' + vendorId;
                        return;

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

        function showEditItemPopUp(itemId) {
            itemDet = returnObj.find(x => x.id == itemId);
            console.log(itemDet);
            $("#popupEditItem").modal('show');
            $("#txtItemName").val(itemDet.name);
            $("#txtQty").val(itemDet.qty);
            $("#txtPrice").val(itemDet.price);
            $("#txtTaxExcludedTotal").val((itemDet.total - itemDet.tax_amount).toFixed(2));
            $("#txtTaxAmt").val(itemDet.tax_amount);
            $("#txtTotal").val(itemDet.total);
        }

        function changeFields() {
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
            var purchaseprice = $("#txtPrice").val();
            var tax = itemDet.tax;
            var cess = itemDet.cess;

            var realtotal = 0;
            var nettotal = 0;
            var tax_rate = 0;
            var tax_amount = 0;
            var tax_included_nettotal = 0;
            var cessRate = 0;
            var cessAmount = 0;
            var qty = returnQty;
            var price = purchaseprice;
            if (itemDet.branch_tax_method == 0) // no tax
            {
                var total = qty * price;
                total = (parseFloat(total)).toFixed(2);
            }

            tax_rate = (parseFloat(tax)).toFixed(2);
            cessRate = (parseFloat(cess)).toFixed(2);
            if (itemDet.branch_tax_inclusive == 1) { // tax is included with the price

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

        function editReturnItemDetails() {
            if ($("#txtQty").val() == "" || $("#txtQty").val() == 0) {
                alert("Quantity can not be null");
                return;
            }
            if ($("#txtPrice").val() == "" || $("#txtPrice").val() == 0) {
                alert("Price can not be null");
                return;
            }
            var postObj = {
                return_data: {

                    pri_id: itemDet.id,
                    prm_id: itemDet.prm_id,
                    pri_qty: $("#txtQty").val(),
                    pi_price: $("#txtPrice").val(),
                    pri_total: $("#txtTotal").val(),
                    pri_tax_amount: $("#txtTaxAmt").val(),
                    user_id: $.cookie("invntrystaffId"),
                    branchid: itemDet.branch_id,
                }
            };

            console.log(postObj);

            $.ajax({
                type: "POST",
                url: "purchasereturn.aspx/Edit_purchase_Return_Item",
                data: JSON.stringify(postObj),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();

                    if (msg.d == "Y") {
                        alert("Edited Successfuly");
                        window.location = 'purchasereturn.aspx?vendorId=' + vendorId;
                        return;
                    }
                    else {
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

        function deleteItem() {
            var postObj = {
                return_data: {

                    pri_id: itemDet.id,
                    prm_id: itemDet.prm_id,
                    user_id: $.cookie("invntrystaffId"),
                    branchid: itemDet.branch_id,

                }
            };

            $.ajax({
                type: "POST",
                url: "purchasereturn.aspx/Remove_purchase_Return_Item",
                data: JSON.stringify(postObj),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();

                    if (msg.d == "Y") {
                        alert("Deleted Successfuly");
                        window.location = 'purchasereturn.aspx?vendorId=' + vendorId;
                        return;
                    } else if (msg.d == "CANCEL") {
                        alert("The Entry is Cancelled..You can not delete it");
                        return;
                    } else if (msg.d == "ONEITEM") {
                        alert("Only one item exist for this return order..You can not delete it");
                        return;
                    }
                    else {
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
                        <a href="../index.html" class="site_title"><span>Invoice Me</span></a>
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
            <div class="top_nav">
                <div class="nav_menu">
                    <nav>

                        <div class="navbar-header" style="width: 100%; display: flex; align-items: center">
                            <div class="nav toggle" style="padding: 5px;">
                                <a id="menu_toggle"><i class="fa fa-bars"></i></a>
                            </div>
                            <div class="col-md-2">
                                <label style="font-weight: bold; font-size: 16px;">Purchase Return</label>
                            </div>
                            <div class="col-md-10 pull-right">
                                <div class="pull-right">
                                    <label id="lblvendorName" style="font-size: 16px; padding-right: 10px; color: #0879da;"></label>
                                    <b>Account Balance:</b><label id="txtoutstanding" style="color: #432727; font-weight: bold; font-size: 12px; color: red;">0</label>
                                </div>
                            </div>

                        </div>

                    </nav>
                </div>
            </div>
            <!-- /top navigation -->

            <!-- page content -->
            <div class="right_col" role="main">
                <div class="">
                    <%--<div class="page-title">

                        <div class="title_left" style="width: 100%;">
                            <label style="font-size: 16px; font-weight: bold;">Edit Sales Order</label>
                        </div>


                    </div>--%>

                    <div class="clearfix"></div>

                    <div class="clearfix"></div>
                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12">
                            <div class="x_panel">

                                <div class="x_title" style="margin-bottom: 3px; padding-bottom: 0px;">
                                    <label>Return Items</label>
                                    <ul class="nav navbar-right panel_toolbox">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                        </li>
                                        <%--<li class="dropdown">
                                            <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false"><i class="fa fa-wrench"></i></a>

                                        </li>--%>
                                        <%--<li><a class="close-link"><i class="fa fa-close"></i></a>
                                        </li>--%>
                                    </ul>
                                    <div class="clearfix"></div>

                                </div>

                                <div class="col-sm-2 invoice-col">
                                    <b>
                                        <label id="txtInvNo" style="font-size: 15px">#</label>
                                    </b>

                                </div>
                                <div onclick="javascript:resetOrderitems();" data-toggle="modal" data-target="#popupReturn" title="Search Order Items" class="btn btn-success mybtnstyl pull-right" style="">
                                    <label style="color: #fff; margin-right: 5px; font-size: 14px;" class="fa fa-search"></label>
                                    Order Items
                                </div>
                                <%--<label class="fa fa-shopping-cart" style="color: #ff6a00; cursor: pointer;"></label>
                                    <label class="fa fa-plus-circle" style="font-size: 20px; cursor: pointer; position: relative; margin-left: -12px;"></label>--%>



                                <div onclick="javascript:searchBasicItems(1);" data-toggle="modal" data-target="#popupBasicReturn" class="btn btn-primary mybtnstyl pull-right" title="Search Basic Items" style="">
                                    <label style="color: #fff; margin-right: 5px; font-size: 14px;" class="fa fa-search"></label>
                                    Basic Items
                                </div>
                                <%-- <label class="fa fa-shopping-cart" style="color: #ff6a00; cursor: pointer;"></label>
                                    <label class="fa fa-plus-circle" style="font-size: 20px; cursor: pointer; position: relative; margin-left: -12px;"></label>--%>

                                <div class="container">

                                    <!-- Trigger the modal with a button -->
                                    <%--  <button >Open Modal</button>--%>

                                    <!-- Modal -->
                                    <div class="modal fade" id="popupReturn" role="dialog">
                                        <div class="modal-dialog modal-lg" style="width: ;">

                                            <!-- Modal content-->
                                            <div class="modal-content">
                                                <div class="modal-header">
                                                    <button type="button" class="close" onclick="javascript:popupclose('popupReturn');">&times;</button>

                                                    <div class="col-md-3 col-xs-6">
                                                        <select class="input-sm" id="slPerpage" onchange="javascript:searchvendors(1);">
                                                            <option value="50">50</option>
                                                            <option value="100">100</option>
                                                            <option value="200">200</option>
                                                        </select>
                                                    </div>
                                                    <div class="col-md-9 col-sm-12 col-xs-12 pull-right">
                                                        <div class="col-md-3 col-sm-12 col-xs-3">
                                                            <select id="selBrand" class="form-control" onchange="searchOrderitems(1);">
                                                                <option value="0" selected="selected" taxtype="-1">--Warehouse--</option>
                                                                <option value="2" taxtype="0">YANA SOLA</option>
                                                                <option value="1" taxtype="0">Five star</option>
                                                            </select>
                                                        </div>
                                                        <div class="col-md-3 col-sm-12 col-xs-3">
                                                            <select id="selCategory" class="form-control" onchange="searchOrderitems(1);">
                                                                <option value="0" selected="selected" taxtype="-1">--Warehouse--</option>
                                                                <option value="2" taxtype="0">YANA SOLA</option>
                                                                <option value="1" taxtype="0">Five star</option>
                                                            </select>
                                                        </div>

                                                        <div class="col-md-4 col-sm-12 col-xs-12 pull-right">
                                                            <button class="btn btn-primary mybtnstyl" type="button" style="float: right;" onclick="javascript:resetOrderitems();">
                                                                <li class="fa fa-refresh" style="margin-right: 5px;"></li>
                                                                Reset
                                                            </button>
                                                            <button type="button" class="btn btn-success mybtnstyl" style="float: right;" onclick="javascript:searchOrderitems(1);">
                                                                <li class="fa fa-search" style="margin-right: 5px;"></li>
                                                                Search
                                                            </button>


                                                        </div>
                                                    </div>
                                                </div>
                                                <div class="col-md-12 col-sm-12 col-xs-12" style="overflow-x: auto;">

                                                    <h4 class="modal-title">Order Items<span class="badge" style="color: #fff; margin-left: 5px; background: #d00101; padding-left: 5px; padding-right: 5px;" id="Span1">0</span></h4>
                                                    <div class="x_content">

                                                        <table id="tableitemlist" class="table table-striped table-bordered" style="table-layout: auto;">
                                                            <thead>
                                                                <tr>
                                                                    <th>Sl.No</th>
                                                                    <th>Code</th>
                                                                    <th>Name</th>
                                                                    <th>Invoice Number</th>
                                                                    <th>Qty</th>
                                                                    <th>Amt</th>

                                                                </tr>


                                                                <tr>
                                                                    <td></td>
                                                                    <td>
                                                                        <input type="text" id="searchcustom1" class="form-control" placeholder="search" /></td>
                                                                    <td>
                                                                        <input type="text" class="form-control" placeholder="search" id="searchcustom2" /></td>


                                                                    <td>
                                                                        <input type="text" class="form-control" placeholder="search" id="searchInvoiceNum" /></td>
                                                                    <td></td>
                                                                    <td></td>
                                                                </tr>
                                                            </thead>
                                                            <tbody>
                                                            </tbody>
                                                        </table>
                                                    </div>
                                                </div>
                                                <div class="clearfix"></div>


                                            </div>

                                        </div>
                                    </div>

                                </div>

                                <div class="container">

                                    <!-- Trigger the modal with a button -->
                                    <%--  <button >Open Modal</button>--%>

                                    <!-- Modal -->
                                    <div class="modal fade" id="popupBasicReturn" role="dialog">
                                        <div class="modal-dialog modal-lg">

                                            <!-- Modal content-->
                                            <div class="modal-content">
                                                <div class="modal-header">
                                                    <button type="button" class="close" onclick="javascript:popupclose('popupBasicReturn');">&times;</button>

                                                    <div class="col-md-3 col-xs-6">
                                                        <select class="input-sm" id="selBasicPerPage" onchange="javascript:searchvendors(1);">
                                                            <option value="20">20</option>
                                                            <option value="50">50</option>
                                                            <option value="100">100</option>
                                                            <option value="200">200</option>
                                                        </select>
                                                    </div>
                                                    <div class="col-md-9 col-sm-12 col-xs-12 pull-right">
                                                        <div class="col-md-3 col-sm-12 col-xs-3">
                                                            <select id="selBasicBrand" class="form-control" onchange="searchBasicItems(1);">
                                                            </select>
                                                        </div>
                                                        <div class="col-md-3 col-sm-12 col-xs-3">
                                                            <select id="selBasicCategory" class="form-control" onchange="searchBasicItems(1);">
                                                            </select>
                                                        </div>

                                                        <div class="col-md-4 col-sm-12 col-xs-12 pull-right">
                                                            <button class="btn btn-primary mybtnstyl" type="button" style="float: right;" onclick="javascript:resetOrderitems();">
                                                                <li class="fa fa-refresh" style="margin-right: 5px;"></li>
                                                                Reset
                                                            </button>
                                                            <button type="button" class="btn btn-success mybtnstyl" style="float: right;" onclick="javascript:searchBasicItems(1);">
                                                                <li class="fa fa-search" style="margin-right: 5px;"></li>
                                                                Search
                                                            </button>


                                                        </div>
                                                    </div>
                                                </div>
                                                <div class="col-md-12 col-sm-12 col-xs-12">
                                                    <h4 class="modal-title">Basic Items<span class="badge" style="color: #fff; margin-left: 5px; background: #d00101; padding-left: 5px; padding-right: 5px;" id="spanBasicCount">0</span></h4>
                                                    <div class="x_content">
                                                        <table id="tblBasicItems" class="table table-striped table-bordered" style="table-layout: auto;">
                                                            <thead>
                                                                <tr>
                                                                    <th>Code</th>
                                                                    <th>Name</th>
                                                                    <th>Price</th>
                                                                    <th>Tax%</th>
                                                                    <th>Cess</th>

                                                                </tr>


                                                                <tr>

                                                                    <td>
                                                                        <input type="text" id="searchCode" class="form-control" placeholder="search" /></td>
                                                                    <td>
                                                                        <input type="text" class="form-control" placeholder="search" id="searchName" /></td>


                                                                    <td></td>
                                                                    <td></td>
                                                                    <td></td>
                                                                </tr>
                                                            </thead>
                                                            <tbody>
                                                            </tbody>
                                                        </table>

                                                    </div>
                                                    <div class="clearfix"></div>

                                                </div>
                                                <div class="clearfix"></div>


                                            </div>

                                        </div>
                                    </div>

                                </div>

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
                                                                        <input type="number" id="txtQty" value="0" style="padding: 0px; text-indent: 3px;" placeholder="Enter price" name="last-name" min="0" required="required" class="form-control col-md-7 col-xs-12" onkeyup="changeFields();" />
                                                                    </div>
                                                                </div>

                                                                <div class="form-group">
                                                                    <label class="control-label col-md-3 col-sm-3 col-xs-12" for="last-name">
                                                                        Price<span class="required">*</span>
                                                                    </label>
                                                                    <div class="col-md-6 col-sm-6 col-xs-12">
                                                                        <input type="number" id="txtPrice" value="0" style="padding: 0px; text-indent: 3px;" placeholder="Enter price" name="last-name" min="0" required="required" class="form-control col-md-7 col-xs-12" onkeyup="changeFields();" />
                                                                    </div>
                                                                </div>
                                                                <div class="form-group">
                                                                    <label class="control-label col-md-3 col-sm-3 col-xs-12">
                                                                        Total
                                                                    </label>
                                                                    <div class="col-md-6 col-sm-6 col-xs-12">
                                                                        <input type="number" id="txtTaxExcludedTotal" required="required" class="form-control col-md-7 col-xs-12" disabled />
                                                                    </div>
                                                                </div>
                                                                <div class="form-group">
                                                                    <label class="control-label col-md-3 col-sm-3 col-xs-12">
                                                                        Tax Amt
                                                                    </label>
                                                                    <div class="col-md-6 col-sm-6 col-xs-12">
                                                                        <input type="number" id="txtTaxAmt" required="required" class="form-control col-md-7 col-xs-12" disabled />
                                                                    </div>
                                                                </div>
                                                                <div class="form-group">
                                                                    <label class="control-label col-md-3 col-sm-3 col-xs-12">
                                                                        Net Amount
                                                                    </label>
                                                                    <div class="col-md-6 col-sm-6 col-xs-12">
                                                                        <input type="number" id="txtTotal" required="required" class="form-control col-md-7 col-xs-12" disabled />
                                                                    </div>
                                                                    (Included Tax amount)
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

                                <div class="col-md-12 col-sm-12 col-xs-12" style="overflow-x: auto;">
                                    <div class="x_content">

                                        <table id="tblOrderItems" class="table table-striped table-bordered" style="table-layout: auto;">

                                            <tbody>
                                                <tr>
                                                    <td>Item Code</td>
                                                    <td>Item Name</td>
                                                    <td>Qty</td>
                                                    <%-- <td>FOC</td>--%>

                                                    <td>Total QTY</td>
                                                    <td>Unit Price</td>
                                                    <td>Tax</td>
                                                    <td>Return Price</td>

                                                    <td>Return QTY</td>
                                                    <td>Return Amount</td>
                                                    <td>Reason</td>
                                                    <td></td>

                                                </tr>




                                                <tr id="TrSum">
                                                    <td></td>
                                                    <td></td>
                                                    <%-- <td></td>--%>
                                                    <td></td>
                                                    <td></td>
                                                    <td></td>
                                                    <td></td>
                                                    <td style="text-align: right;">Total</td>
                                                    <td></td>
                                                    <td id="txtTotalReturnAmount">&nbsp&nbsp;</td>
                                                    <td></td>
                                                    <td></td>
                                                   
                                                </tr>

                                            </tbody>

                                        </table>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="clearfix"></div>
                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title" style="margin-bottom: 3px; padding-bottom: 0px;">
                                    <label class="pull-left">Special Notes</label>

                                    <ul class="nav navbar-right panel_toolbox pull-right">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                        </li>

                                        <%--<li><a class="close-link"><i class="fa fa-close"></i></a>
                      </li>--%>
                                    </ul>

                                    <div class="clearfix"></div>
                                </div>

                                <div class="x_content">
                                    <textarea class="form-control" id="txtSpecialNote" style="resize: none;"></textarea>
                                    <div class="col-md-12 col-sm-12 col-xs-12 pull-right" style="margin-top: 10px;">
                                        <button class="btn btn-danger mybtnstyl pull-right" type="button" onclick="javascript:gotomanageorder();">Cancel</button>
                                        <button class="btn btn-primary mybtnstyl pull-right" type="button" onclick="javascript:savepurchaseReturn();" id="divsaveReturn">Save</button>

                                    </div>
                                </div>
                                <div class="clear"></div>


                            </div>
                        </div>
                    </div>
                    <div class="clearfix"></div>
                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title">
                                    <label>Return History</label>
                                    <ul class="nav navbar-right panel_toolbox">
                                        <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a>
                                        </li>


                                    </ul>
                                </div>


                                <div class="col-md-12 col-sm-12 col-xs-12" style="overflow-x: auto;">
                                    <div class="x_content">

                                        <table id="tblReturnDetails" class="table table-striped table-bordered" style="table-layout: auto;">
                                            <thead>
                                                <tr>
                                                    <th>Ref.</th>
                                                    <th>Date</th>
                                                    <%--<th>Narration</th>--%>
                                                    <th>User</th>
                                                    <th>Amount</th>
                                                    <th>Status</th>
                                                    <th></th>
                                                </tr>
                                            </thead>


                                            <tbody></tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="clearfix"></div>
                    <div class="clearfix"></div>
                    <div class="modal fade" id="popupReturnList" role="dialog">
                        <div class="modal-dialog modal-md" style="">

                            <!-- Modal content-->
                            <div class="modal-content">
                                <div class="modal-header" style="padding-bottom: 5px;">
                                    <button type="button" class="close" data-dismiss="modal">&times;</button>
                                    <div class="col-md-6 col-sm-6 col-xs-12">
                                        <h4 class="modal-title" id="headBill">Returned Items<span id="lblTransRef"></span></h4>
                                    </div>
                                </div>
                                <div class="x_content">
                                    <%--<div class="col-md-6" style="margin-bottom: 10px;"><b>ITEMS :</b></div>--%>
                                    </br>
                                    <table id="tblReturnItemList" class="table table-striped table-bordered" style="table-layout: auto;">
                                        <thead>
                                            <tr>
                                                <th>Name</th>
                                                <th>Qty</th>
                                                <th>Price</th>
                                                <th>Total</th>
                                                <th>Type</th>
                                                <th>Action</th>
                                            </tr>

                                        </thead>
                                        <tbody>
                                        </tbody>

                                    </table>

                                </div>
                                <div class="clearfix"></div>
                                <div class="ln_solid"></div>
                            </div>

                        </div>
                    </div>
                </div>


            </div>

            <%-- popupStart --%>



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
