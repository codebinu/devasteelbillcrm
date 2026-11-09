<%@ Page Language="C#" AutoEventWireup="true" CodeFile="edit_sales_order.aspx.cs" Inherits="web_sales_edit_sales_order" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Edit Sales Order | Invoice Me</title>
    <script src="../js/common.js" type="text/javascript"></script>
    <script type="text/javascript" src="../js/jquery-2.0.3.js"></script>
    <script type="text/javascript" src="../js/jquery.cookie.js"></script>
    <script type="text/javascript" src="../js/uom-conversion.js"></script>

    <link href="../css/bootstrap/bootstrap.min.css" rel="stylesheet" />
    <link href="../css/font-awesome/css/font-awesome.min.css" rel="stylesheet" />
    <link href="../css/bootstrap/nprogress.css" rel="stylesheet" />
    <link href="../css/bootstrap/custom.min.css" rel="stylesheet" />
    <link href="../css/bootstrap/mystyle.css" type="text/css" rel="stylesheet" />

    <style>
        .info-row { padding: 4px 0; border-bottom: 1px dashed #eee; overflow: hidden; }
        .info-row .k { color: #777; float: left; width: 42%; }
        .info-row .v { float: left; width: 58%; font-weight: 600; word-break: break-word; }
        #itemsTable input.form-control, #itemsTable select.form-control { min-width: 70px; padding: 3px 6px; height: 30px; }
        #itemsTable td.num input { text-align: right; }
        #itemsTable .name-col { min-width: 200px; }
        #itemsTable tr.changed > td { background: #fff8e1; }
        #itemsTable tr.invalid input, #itemsTable tr.invalid select { border-color: #a94442; }
        #itemsTable .row-note { display: block; font-size: 11px; color: #8a6d3b; }
        #itemsTable .row-err { display: block; font-size: 11px; color: #a94442; }
        .totals-box .info-row .v { text-align: right; }
        #saveBar .btn { margin-right: 6px; }
    </style>

    <script type="text/javascript">
        $(document).ready(function () {
            if (!$.cookie("invntrystaffBranchId")) {
                location.href = "../dashboard.aspx";
                return false;
            }
            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " &copy;");
        });
    </script>
</head>

<body class="nav-md">
    <form id="form1" runat="server" autocomplete="off">
        <div class="container body">
            <div class="main_container">
                <div id="loading" style="background-repeat: no-repeat; margin: auto; height: 100%; display: none">
                    <div align="center" style="margin: auto">
                        <img id="loading-image" src="../images/loader.gif" alt="Loading..." />
                    </div>
                </div>
                <div class="col-md-3 left_col">
                    <div class="left_col scroll-view">
                        <div class="navbar nav_title" style="border: 0;">
                            <a href="#" class="site_title"><span>Invoice</span></a>
                        </div>
                        <div class="clearfix"></div>
                        <div class="profile clearfix"></div>
                        <br />
                        <div id="sidebar-menu" class="main_menu_side hidden-print main_menu"></div>
                        <div class="sidebar-footer hidden-small">
                            <a data-toggle="tooltip" data-placement="top" title="Settings"><span class="glyphicon glyphicon-cog" aria-hidden="true"></span></a>
                            <a data-toggle="tooltip" data-placement="top" title="FullScreen"><span class="glyphicon glyphicon-fullscreen" aria-hidden="true"></span></a>
                            <a data-toggle="tooltip" data-placement="top" title="Lock"><span class="glyphicon glyphicon-eye-close" aria-hidden="true"></span></a>
                            <a data-toggle="tooltip" data-placement="top" title="Logout" href="../login.html"><span class="glyphicon glyphicon-off" aria-hidden="true"></span></a>
                        </div>
                    </div>
                </div>

                <div class="top_nav">
                    <div class="nav_menu">
                        <nav>
                            <div class="navbar-header" style="width: 100%; display: flex; align-items: center">
                                <div class="nav toggle" style="padding: 5px;">
                                    <a id="menu_toggle"><i class="fa fa-bars"></i></a>
                                </div>
                                <div class="col-md-6 col-xs-6">
                                    <label style="font-weight: bold; font-size: 16px;">Edit Sales Order</label>
                                </div>
                                <div class="col-md-6 col-xs-5">
                                    <a href="<%= Order == null ? "sales_order_list.aspx" : "view_sales_order.aspx?smoId=" + SmoId %>">
                                        <div class="btn btn-primary btn-xs pull-right" style="margin-top: 5px"><label style="color: #fff; margin-right: 5px; font-size: 14px;" class="fa fa-arrow-left"></label><%= Order == null ? "Back to Sales Orders" : "Back to Order" %></div>
                                    </a>
                                </div>
                            </div>
                        </nav>
                    </div>
                </div>

                <div class="right_col" role="main">
                    <% if (Order == null) { %>
                    <div class="x_panel">
                        <div class="x_content" style="text-align: center; padding: 30px 0;">
                            <p style="color: red"><%= Enc(ErrorMessage) %></p>
                            <a href="sales_order_list.aspx" class="btn btn-primary">Back to Sales Orders</a>
                        </div>
                    </div>
                    <% } else { %>
                    <% if (SavedMessage != "") { %>
                    <div class="alert alert-success" id="savedBanner" style="margin-bottom: 10px;"><%= Enc(SavedMessage) %></div>
                    <% } %>
                    <% if (!CanEdit) { %>
                    <div class="alert alert-warning" style="margin-bottom: 10px;">
                        This sales order is shown read-only. <%= Enc(EditHint) %>
                    </div>
                    <% } else { %>
                    <div class="alert alert-info" style="margin-bottom: 10px;">
                        You can change the payment type, order type, notes, and each item's quantity, size, unit, price and discount.
                        Changing an item's final quantity releases its stock reservations.
                    </div>
                    <% } %>
                    <div id="editMessage" role="status" aria-live="polite"></div>

                    <div class="row">
                        <div class="col-md-6 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title"><strong><i class="fa fa-user"></i> Customer Information</strong><div class="clearfix"></div></div>
                                <div class="x_content">
                                    <div class="info-row"><span class="k">Customer</span><span class="v"><%= Enc(Order["cust_name"]) %></span></div>
                                    <div class="info-row"><span class="k">Customer ID</span><span class="v"><%= Enc(Order["cust_id"]) %></span></div>
                                    <% if (Has("cust_phone")) { %><div class="info-row"><span class="k">Contact</span><span class="v"><%= Enc(Order["cust_phone"]) %></span></div><% } %>
                                    <% if (Has("cust_email")) { %><div class="info-row"><span class="k">Email</span><span class="v"><%= Enc(Order["cust_email"]) %></span></div><% } %>
                                    <% if (Has("cust_phone1")) { %><div class="info-row"><span class="k">Alt. Contact</span><span class="v"><%= Enc(Order["cust_phone1"]) %></span></div><% } %>
                                    <% if (Has("cust_address")) { %><div class="info-row"><span class="k">Address</span><span class="v"><%= Enc(Order["cust_address"]) %></span></div><% } %>
                                    <% if (Has("cust_city")) { %><div class="info-row"><span class="k">City</span><span class="v"><%= Enc(Order["cust_city"]) %></span></div><% } %>
                                    <% if (Has("cust_tax_reg_id")) { %><div class="info-row"><span class="k">Tax Reg. ID</span><span class="v"><%= Enc(Order["cust_tax_reg_id"]) %></span></div><% } %>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-6 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title"><strong><i class="fa fa-file-text-o"></i> Order Details</strong><div class="clearfix"></div></div>
                                <div class="x_content">
                                    <div class="info-row"><span class="k">Sales Order No</span><span class="v">#<%= Enc(Order["smo_id"]) %><% if (Has("smo_invoice_no")) { %> (<%= Enc(Order["smo_invoice_no"]) %>)<% } %></span></div>
                                    <div class="info-row"><span class="k">Sales Order Status</span><span class="v"><% if (StatusText != "") { %><span class="status <%= StatusCss %>"><%= StatusText %></span><% } else { %><span class="text-muted">Not available</span><% } %></span></div>
                                    <div class="info-row"><span class="k">Created By</span><span class="v"><%= Enc(Order["seller_name"]).Trim() %></span></div>
                                    <div class="form-group" style="margin-top: 10px;">
                                        <label for="orderDate">Order Date</label>
                                        <input type="text" id="orderDate" class="form-control" readonly="readonly" value="<%= Enc(Order["orderDate"]) %>" />
                                    </div>
                                    <div class="form-group">
                                        <label for="warehouse">Warehouse</label>
                                        <select id="warehouse" class="form-control" disabled="disabled">
                                            <option value="<%= Enc(Order["branch_id"]) %>" selected="selected"><%= Enc(Order["branch_name"]) %></option>
                                        </select>
                                    </div>
                                    <div class="row">
                                        <div class="col-sm-6">
                                            <div class="form-group">
                                                <label for="paymentType">Payment Type</label>
                                                <select id="paymentType" class="form-control"<%= Disabled %>>
                                                    <option value="0"<%= Selected("smo_payment_type", "0") %>>Not set</option>
                                                    <option value="1"<%= Selected("smo_payment_type", "1") %>>Cash</option>
                                                    <option value="2"<%= Selected("smo_payment_type", "2") %>>Credit</option>
                                                    <option value="3"<%= Selected("smo_payment_type", "3") %>>Bill to bill</option>
                                                </select>
                                            </div>
                                        </div>
                                        <div class="col-sm-6">
                                            <div class="form-group">
                                                <label for="orderType">Order Type</label>
                                                <select id="orderType" class="form-control"<%= Disabled %>>
                                                    <option value="0"<%= Selected("smo_order_type", "0") %>>Not set</option>
                                                    <option value="1"<%= Selected("smo_order_type", "1") %>>Direct visit</option>
                                                    <option value="2"<%= Selected("smo_order_type", "2") %>>Telephonic</option>
                                                    <option value="3"<%= Selected("smo_order_type", "3") %>>Mail</option>
                                                </select>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title"><strong><i class="fa fa-list"></i> Sales Order Items</strong><div class="clearfix"></div></div>
                                <div class="x_content">
                                    <div style="overflow-x: auto;">
                                        <table class="table table-striped jambo_table table-bordered" id="itemsTable">
                                            <thead style="background-color: #f1eeee; color: #525252">
                                                <tr>
                                                    <th>Sl. No.</th>
                                                    <th>Item Code</th>
                                                    <th class="name-col">Item Name</th>
                                                    <th style="text-align: right;">Qty</th>
                                                    <th style="text-align: right;">Length</th>
                                                    <th style="text-align: right;">Width</th>
                                                    <th>UOM</th>
                                                    <th style="text-align: right;">Final Qty</th>
                                                    <th>Final UOM</th>
                                                    <th style="text-align: right;">Unit Price</th>
                                                    <th style="text-align: right;">Discount %</th>
                                                    <th style="text-align: right;">Discount</th>
                                                    <th style="text-align: right;">Tax %</th>
                                                    <th style="text-align: right;">Tax / GST</th>
                                                    <th style="text-align: right;">Line Total</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <% foreach (System.Data.DataRow r in Items.Rows) { %>
                                                <tr data-sio-id="<%= Enc(r["sio_id"]) %>" data-target="<%= Enc(r["tum_id"]) %>" data-reserved="<%= Enc(r["edit_reserved"]) %>"
                                                    data-tax="<%= Num(r["sio_item_tax"]) %>" data-cess="<%= NumCol(r, "sio_item_cess") %>"
                                                    data-final="<%= Num(r["sio_finalqty"]) %>" data-total="<%= Num(r["sio_total"]) %>" data-disc="<%= Num(r["sio_discount_amount"]) %>"
                                                    data-taxamt="<%= Num(r["sio_tax_amount"]) %>" data-net="<%= Num(r["sio_net_amount"]) %>" data-taxable="<%= Enc(r["edit_taxable"]) %>">
                                                    <td><%= Enc(r["sl"]) %></td>
                                                    <td><%= Enc(r["itm_code"]) %></td>
                                                    <td><%= Enc(r["itm_name"]) %><% if (r["edit_reserved"].ToString() != "0") { %> <span class="label label-info" title="Stock is reserved for this item">Reserved</span><% } %></td>
                                                    <td class="num"><input type="text" class="form-control f-qty" value="<%= Enc(r["edit_qty"]) %>"<%= ReadOnly %> /></td>
                                                    <td class="num"><input type="text" class="form-control f-len" value="<%= Enc(r["edit_length"]) %>"<%= ReadOnly %> /></td>
                                                    <td class="num"><input type="text" class="form-control f-wid" value="<%= Enc(r["edit_width"]) %>"<%= ReadOnly %> /></td>
                                                    <td><select class="form-control f-uom"<%= Disabled %>><%= UomOptions(r["tum_id"], r["edit_uom"]) %></select></td>
                                                    <td class="num"><span class="c-final"><%= Num(r["sio_finalqty"]) %></span><span class="row-err"></span><span class="row-note"></span></td>
                                                    <td><%= Enc(r["uom"]) %></td>
                                                    <td class="num"><input type="text" class="form-control f-price" value="<%= Num(r["sio_price"]) %>"<%= ReadOnly %> /></td>
                                                    <td class="num"><input type="text" class="form-control f-rate" value="<%= Num(r["sio_discount_rate"]) %>"<%= ReadOnly %> /></td>
                                                    <td style="text-align: right;" class="c-disc"><%= Money(r["sio_discount_amount"]) %></td>
                                                    <td style="text-align: right;"><%= Num(r["sio_item_tax"]) %></td>
                                                    <td style="text-align: right;" class="c-tax"><%= Money(r["sio_tax_amount"]) %></td>
                                                    <td style="text-align: right;"><b class="c-net"><%= Money(r["sio_net_amount"]) %></b></td>
                                                </tr>
                                                <% } %>
                                                <% if (Items.Rows.Count == 0) { %>
                                                <tr><td colspan="15" style="text-align: center">No items found for this sales order.</td></tr>
                                                <% } %>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-6 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title"><strong><i class="fa fa-pencil"></i> Notes / Remarks</strong><div class="clearfix"></div></div>
                                <div class="x_content">
                                    <textarea id="remarks" class="form-control" rows="5" maxlength="500"<%= ReadOnly %>><%= Enc(Order["smo_specialnote"]) %></textarea>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-6 col-sm-12 col-xs-12">
                            <div class="x_panel totals-box">
                                <div class="x_title"><strong><i class="fa fa-calculator"></i> Order Totals</strong><div class="clearfix"></div></div>
                                <div class="x_content">
                                    <div class="info-row"><span class="k">Total Qty</span><span class="v" id="tQty"><%= Num(ItemsQty) %></span></div>
                                    <div class="info-row"><span class="k">Sub Total</span><span class="v" id="tTotal"><%= Money(Order["smo_total"]) %></span></div>
                                    <div class="info-row"><span class="k">Discount</span><span class="v" id="tDisc"><%= Money(Order["smo_discount_amount"]) %></span></div>
                                    <div class="info-row"><span class="k">Taxable Amount</span><span class="v" id="tTaxable"><%= Money(Order["smo_tax_excluded_amt"]) %></span></div>
                                    <div class="info-row"><span class="k">Tax / GST</span><span class="v" id="tTax"><%= Money(Order["smo_tax_amount"]) %></span></div>
                                    <div class="info-row"><span class="k">Round Off</span><span class="v" id="tRound"><%= Money(Order["smo_roundoff"]) %></span></div>
                                    <div class="info-row"><span class="k">Grand Total</span><span class="v" id="tNet" style="font-size: 16px;"><%= Money(Order["smo_netamount"]) %></span></div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <% if (CanEdit) { %>
                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12 text-right" id="saveBar">
                            <span id="saveStatus" role="status" aria-live="polite" style="margin-right: 10px;"></span>
                            <a href="view_sales_order.aspx?smoId=<%= SmoId %>" class="btn btn-default">Cancel</a>
                            <button type="button" id="btnSave" class="btn btn-success"><i class="fa fa-save"></i> Save Changes</button>
                        </div>
                    </div>
                    <% } %>
                    <% } %>
                </div>
                <footer>
                    <div class="pull-right">
                        <div class="footerDiv">
                            <div class="footerDivContent">Copyright 2014 &copy;</div>
                        </div>
                    </div>
                    <div class="clearfix"></div>
                </footer>
            </div>
        </div>
    </form>

    <script src="../js/bootstrap/bootstrap.min.js"></script>
    <script src="../js/bootstrap/fastclick.js"></script>
    <script src="../js/bootstrap/nprogress.js"></script>
    <script src="../js/bootstrap/icheck.min.js"></script>
    <script src="../js/bootstrap/custom.min.js"></script>
    <script src="../js/bootbox.min.js"></script>
    <% if (Order != null) { %>
    <script type="text/javascript">
        $(function () {
            var cfg = {
                smoId: <%= SmoId %>, token: '<%= Token %>', accuracy: <%= Accuracy %>,
                taxMethod: <%= TaxMethod %>, taxInclusive: <%= TaxInclusive %>, canEdit: <%= CanEdit ? "true" : "false" %>
            };
            UomConversion.init(<%= UomJson %>, <%= TypeJson %>);

            var stored = sessionStorage.getItem('soEditMessage');
            if (stored) {
                sessionStorage.removeItem('soEditMessage');
                $('#savedBanner').text(stored);
            }
            if (!cfg.canEdit) { return; }

            var initialTotals = {};
            $('.totals-box .v').each(function () { initialTotals[this.id] = $(this).text(); });
            var initialHeader = headerState();

            function num(v) { var n = parseFloat(v); return isNaN(n) ? 0 : n; }
            function rnd(v) { var f = Math.pow(10, cfg.accuracy); return Math.round((v + Number.EPSILON) * f) / f; }
            function showMsg(type, text) {
                $('#editMessage').html($('<div class="alert"></div>').addClass('alert-' + type).css('margin-bottom', '10px').text(text));
                $('html,body').animate({ scrollTop: 0 }, 150);
            }
            function headerState() {
                return [$('#paymentType').val(), $('#orderType').val(), $('#remarks').val().replace(/\r\n/g, '\n')].join('\u0001');
            }

            // Same line amount rules as the server (branch tax method / inclusive); the server recalculates on save.
            function lineAmounts(qty, price, rate, tax, cess) {
                if (cfg.taxMethod == 0) { tax = 0; cess = 0; }
                var basePrice = price;
                if (cfg.taxMethod != 0 && cfg.taxInclusive == 1) {
                    basePrice = cess > 0 ? 10000 * price / (10000 + 100 * tax + tax * cess) : price / (tax / 100 + 1);
                }
                var real = basePrice * qty, disc = real * rate / 100, nb = real - disc;
                var ta = nb * tax / 100; ta = ta + ta * cess / 100;
                return { total: rnd(real), disc: rnd(disc), tax: rnd(ta), net: rnd(nb + ta) };
            }

            function readRow($tr) {
                var uomId = $tr.find('.f-uom').val(), req = UomConversion.getRequirements(uomId);
                var $len = $tr.find('.f-len'), $wid = $tr.find('.f-wid');
                $len.prop('disabled', !req.length);
                $wid.prop('disabled', !req.width);
                var s = {
                    uom: parseInt(uomId, 10) || 0,
                    qty: num($tr.find('.f-qty').val()),
                    len: req.length ? num($len.val()) : 0,
                    wid: req.width ? num($wid.val()) : 0,
                    priceText: $.trim($tr.find('.f-price').val()),
                    price: num($tr.find('.f-price').val()),
                    rate: num($tr.find('.f-rate').val())
                };
                s.sig = [s.uom, s.qty, s.len, s.wid, s.price, s.rate].join('|');
                return s;
            }

            function recalcRow($tr) {
                var s = readRow($tr);
                var changed = s.sig !== $tr.data('sig');
                var $err = $tr.find('.row-err').text(''), $note = $tr.find('.row-note').text('');
                $tr.toggleClass('changed', changed).removeClass('invalid');
                var origFinal = num($tr.attr('data-final'));
                var r = {
                    ok: true, changed: changed, final: origFinal, total: num($tr.attr('data-total')), disc: num($tr.attr('data-disc')),
                    tax: num($tr.attr('data-taxamt')), net: num($tr.attr('data-net')), taxable: num($tr.attr('data-taxable')),
                    releases: false
                };
                if (changed) {
                    var f = UomConversion.calculateFinalQuantity({
                        uomId: s.uom, targetUomId: $tr.attr('data-target'), quantity: s.qty, length: s.len, width: s.wid
                    });
                    var msg = '';
                    if (f.error) msg = f.error;
                    else if (f.value === null || !(f.value > 0)) msg = 'Enter a valid quantity.';
                    else if (s.priceText === '' || s.price < 0) msg = 'Enter a valid price.';
                    else if (s.rate < 0 || s.rate > 100) msg = 'Discount must be between 0 and 100.';
                    if (msg) {
                        r.ok = false;
                        $err.text(msg);
                        $tr.addClass('invalid');
                    } else {
                        var a = lineAmounts(f.value, s.price, s.rate, num($tr.attr('data-tax')), num($tr.attr('data-cess')));
                        r.final = f.value; r.total = a.total; r.disc = a.disc; r.tax = a.tax; r.net = a.net; r.taxable = a.net - a.tax;
                        if (Math.abs(f.value - origFinal) > 0.00005 && num($tr.attr('data-reserved')) > 0) {
                            r.releases = true;
                            $note.text('Reservations of this item will be released.');
                        }
                    }
                }
                $tr.find('.c-final').text(r.ok ? String(Math.round(r.final * 10000) / 10000) : '-');
                $tr.find('.c-disc').text(r.disc.toFixed(2));
                $tr.find('.c-tax').text(r.tax.toFixed(2));
                $tr.find('.c-net').text(r.net.toFixed(2));
                return r;
            }

            function recalcAll() {
                var t = { qty: 0, total: 0, disc: 0, taxable: 0, tax: 0, net: 0 }, any = false, bad = false;
                $('#itemsTable tbody tr[data-sio-id]').each(function () {
                    var r = recalcRow($(this));
                    any = any || r.changed;
                    bad = bad || !r.ok;
                    t.qty += r.final; t.total += r.total; t.disc += r.disc; t.taxable += r.taxable; t.tax += r.tax; t.net += r.net;
                });
                if (any && !bad) {
                    $('#tQty').text(String(Math.round(t.qty * 10000) / 10000));
                    $('#tTotal').text(t.total.toFixed(2)); $('#tDisc').text(t.disc.toFixed(2)); $('#tTaxable').text(t.taxable.toFixed(2));
                    $('#tTax').text(t.tax.toFixed(2)); $('#tRound').text('0.00'); $('#tNet').text(t.net.toFixed(2));
                } else if (!any) {
                    $.each(initialTotals, function (id, text) { $('#' + id).text(text); });
                }
                $('#btnSave').prop('disabled', bad);
                return { any: any, bad: bad };
            }

            $('#itemsTable tbody tr[data-sio-id]').each(function () {
                $(this).data('sig', readRow($(this)).sig);
            });
            recalcAll();
            $('#itemsTable').on('input change', 'input, select', recalcAll);

            $('#btnSave').on('click', function () {
                var state = recalcAll();
                if (state.bad) { showMsg('danger', 'Fix the highlighted items before saving.'); return; }
                if (!state.any && headerState() === initialHeader) { showMsg('info', 'There are no changes to save.'); return; }

                var lines = [], releases = 0;
                $('#itemsTable tbody tr[data-sio-id]').each(function () {
                    var $tr = $(this), s = readRow($tr);
                    if ($tr.find('.row-note').text() !== '') { releases++; }
                    lines.push({
                        sioId: parseInt($tr.attr('data-sio-id'), 10), qty: s.qty, length: s.len, width: s.wid,
                        tumIdCust: s.uom, price: s.price, discountRate: s.rate
                    });
                });
                if (releases > 0 && !confirm('The final quantity of ' + releases + ' item(s) changed, so their stock reservations will be released. Continue?')) {
                    return;
                }

                var $btn = $(this).prop('disabled', true);
                $('#saveStatus').text('Saving...');
                $.ajax({
                    type: 'POST',
                    url: 'edit_sales_order.aspx/SaveEdit',
                    data: JSON.stringify({
                        request: {
                            smoId: cfg.smoId, token: cfg.token,
                            paymentType: parseInt($('#paymentType').val(), 10) || 0,
                            orderType: parseInt($('#orderType').val(), 10) || 0,
                            note: $('#remarks').val(), lines: lines
                        }
                    }),
                    contentType: 'application/json; charset=utf-8',
                    dataType: 'json',
                    success: function (response) {
                        var d = response.d;
                        if (d && d.ok && d.message === 'No changes to save.') {
                            $('#saveStatus').text('');
                            $btn.prop('disabled', false);
                            showMsg('info', d.message);
                        } else if (d && d.ok) {
                            sessionStorage.setItem('soEditMessage', d.message);
                            location.href = 'edit_sales_order.aspx?smoId=' + cfg.smoId + '&done=saved';
                        } else {
                            $('#saveStatus').text('');
                            $btn.prop('disabled', false);
                            showMsg('danger', (d && d.message) || 'Unable to save the sales order.');
                        }
                    },
                    error: function () {
                        $('#saveStatus').text('');
                        $btn.prop('disabled', false);
                        showMsg('danger', 'Unable to save the sales order. Please sign in again or try later.');
                    }
                });
            });
        });
    </script>
    <% } %>
</body>
</html>
