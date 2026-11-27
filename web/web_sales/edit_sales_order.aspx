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
        #itemsTable input[type=number] { -moz-appearance: textfield; }
        #itemsTable input[type=number]::-webkit-outer-spin-button, #itemsTable input[type=number]::-webkit-inner-spin-button { -webkit-appearance: none; margin: 0; }
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
                                    <% if (CanEdit) { %>
                                    <div class="form-group" style="position: relative; max-width: 480px;">
                                        <label for="itemSearch">Add Item</label>
                                        <input type="text" id="itemSearch" class="form-control" placeholder="Search item by name or code" autocomplete="off" />
                                        <ul id="itemResults" class="list-group" style="display: none; position: absolute; z-index: 20; left: 0; right: 0; max-height: 260px; overflow-y: auto; margin: 0;"></ul>
                                    </div>
                                    <% } %>
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
                                                    <% if (CanEdit) { %><th></th><% } %>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <% foreach (System.Data.DataRow r in Items.Rows) { %>
                                                <tr data-sio-id="<%= Enc(r["sio_id"]) %>" data-itbs-id="<%= Enc(r["itbs_id"]) %>" data-target="<%= Enc(r["tum_id"]) %>"
                                                    data-tax="<%= Raw(r["sio_item_tax"]) %>" data-cess="<%= NumCol(r, "sio_item_cess") %>"
                                                    data-final="<%= Raw(r["sio_finalqty"]) %>" data-total="<%= Raw(r["sio_total"]) %>" data-disc="<%= Raw(r["sio_discount_amount"]) %>"
                                                    data-taxamt="<%= Raw(r["sio_tax_amount"]) %>" data-net="<%= Raw(r["sio_net_amount"]) %>" data-taxable="<%= Enc(r["edit_taxable"]) %>">
                                                    <td class="c-sl"><%= Enc(r["sl"]) %></td>
                                                    <td><%= Enc(r["itm_code"]) %></td>
                                                    <td><%= Enc(r["itm_name"]) %></td>
                                                    <td class="num"><input type="number" min="0" step="0.001" data-dec="3" inputmode="decimal" class="form-control f-qty so-num" value="<%= Enc(r["edit_qty"]) %>" data-orig="<%= Enc(r["edit_qty_raw"]) %>"<%= ReadOnly %> /></td>
                                                    <td class="num"><input type="number" min="0" step="0.001" data-dec="3" inputmode="decimal" class="form-control f-len so-num" value="<%= Enc(r["edit_length"]) %>" data-orig="<%= Enc(r["edit_length_raw"]) %>"<%= ReadOnly %> /></td>
                                                    <td class="num"><input type="number" min="0" step="0.001" data-dec="3" inputmode="decimal" class="form-control f-wid so-num" value="<%= Enc(r["edit_width"]) %>" data-orig="<%= Enc(r["edit_width_raw"]) %>"<%= ReadOnly %> /></td>
                                                    <td><select class="form-control f-uom"<%= Disabled %>><%= UomOptions(r["tum_id"], r["edit_uom"]) %></select></td>
                                                    <td class="num"><span class="c-final"><%= Num(r["sio_finalqty"]) %></span><span class="row-err"></span><span class="row-note"></span></td>
                                                    <td><%= Enc(r["uom"]) %></td>
                                                    <td class="num"><input type="number" min="0" step="0.01" data-dec="2" inputmode="decimal" class="form-control f-price so-num" value="<%= Money(r["sio_price"]) %>" data-orig="<%= Raw(r["sio_price"]) %>"<%= ReadOnly %> /></td>
                                                    <td class="num"><input type="number" min="0" max="100" step="0.01" data-dec="2" inputmode="decimal" class="form-control f-rate so-num" value="<%= Raw(r["sio_discount_rate"]) %>"<%= ReadOnly %> /></td>
                                                    <td style="text-align: right;" class="c-disc"><%= Money(r["sio_discount_amount"]) %></td>
                                                    <td style="text-align: right;"><%= Raw(r["sio_item_tax"]) %></td>
                                                    <td style="text-align: right;" class="c-tax"><%= Money(r["sio_tax_amount"]) %></td>
                                                    <td style="text-align: right;"><b class="c-net"><%= Money(r["sio_net_amount"]) %></b></td>
                                                    <% if (CanEdit) { %><td><button type="button" class="btn btn-danger btn-xs btn-remove" title="Remove item"><i class="fa fa-trash"></i></button></td><% } %>
                                                </tr>
                                                <% } %>
                                                <% if (Items.Rows.Count == 0) { %>
                                                <tr><td colspan="16" style="text-align: center">No items found for this sales order.</td></tr>
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

            // Number inputs still accept e, +, - ; block them so only plain non-negative decimals can be typed.
            $('#itemsTable').on('keydown', '.so-num', function (e) {
                if (e.key === 'e' || e.key === 'E' || e.key === '+' || e.key === '-') { e.preventDefault(); }
            }).on('paste', '.so-num', function (e) {
                var t = (e.originalEvent.clipboardData || window.clipboardData).getData('text');
                if (!/^\s*\d*\.?\d*\s*$/.test(t)) { e.preventDefault(); }
            }).on('wheel', '.so-num', function () { $(this).blur(); })
              .on('input', '.so-num[data-dec]', function () {
                // Cap decimals: UOM quantities/sizes 3, amounts 2 (data-dec).
                var d = parseInt($(this).data('dec'), 10), v = this.value, i = v.indexOf('.');
                if (i >= 0 && v.length - i - 1 > d) { this.value = v.substring(0, i + 1 + d); }
            });

            var initialTotals = {};
            $('.totals-box .v').each(function () { initialTotals[this.id] = $(this).text(); });
            var initialHeader = headerState();

            function num(v) { var n = parseFloat(v); return isNaN(n) ? 0 : n; }
            // An untouched input shows a rounded value; keep sending the stored full-precision value so the line is not seen as changed.
            function fieldVal($el) {
                var orig = $el.attr('data-orig');
                return orig !== undefined && orig !== '' && $el.val() === $el[0].defaultValue ? num(orig) : num($el.val());
            }
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
                    qty: fieldVal($tr.find('.f-qty')),
                    len: req.length ? fieldVal($len) : 0,
                    wid: req.width ? fieldVal($wid) : 0,
                    priceText: $.trim($tr.find('.f-price').val()),
                    price: fieldVal($tr.find('.f-price')),
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
                    tax: num($tr.attr('data-taxamt')), net: num($tr.attr('data-net')), taxable: num($tr.attr('data-taxable'))
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
                    }
                }
                $tr.find('.c-final').text(r.ok ? String(Math.round(r.final * 1000) / 1000) : '-');
                $tr.find('.c-disc').text(r.disc.toFixed(2));
                $tr.find('.c-tax').text(r.tax.toFixed(2));
                $tr.find('.c-net').text(r.net.toFixed(2));
                return r;
            }

            var structureChanged = false;

            function dataRows() { return $('#itemsTable tbody tr[data-sio-id]'); }

            function renumber() {
                dataRows().each(function (i) { $(this).find('.c-sl').text(i + 1); });
                $('#itemsTable .btn-remove').prop('disabled', dataRows().length <= 1);
            }

            function recalcAll() {
                var t = { qty: 0, total: 0, disc: 0, taxable: 0, tax: 0, net: 0 }, any = structureChanged, bad = false;
                dataRows().each(function () {
                    var r = recalcRow($(this));
                    any = any || r.changed;
                    bad = bad || !r.ok;
                    t.qty += r.final; t.total += r.total; t.disc += r.disc; t.taxable += r.taxable; t.tax += r.tax; t.net += r.net;
                });
                if (any && !bad) {
                    $('#tQty').text(String(Math.round(t.qty * 1000) / 1000));
                    $('#tTotal').text(t.total.toFixed(2)); $('#tDisc').text(t.disc.toFixed(2)); $('#tTaxable').text(t.taxable.toFixed(2));
                    $('#tTax').text(t.tax.toFixed(2)); $('#tRound').text('0.00'); $('#tNet').text(t.net.toFixed(2));
                } else if (!any) {
                    $.each(initialTotals, function (id, text) { $('#' + id).text(text); });
                }
                $('#btnSave').prop('disabled', bad || dataRows().length === 0);
                return { any: any, bad: bad };
            }

            dataRows().each(function () {
                $(this).data('sig', readRow($(this)).sig);
            });
            renumber();
            recalcAll();
            $('#itemsTable').on('input change', 'input, select', recalcAll);

            $('#itemsTable').on('click', '.btn-remove', function () {
                if (dataRows().length <= 1) { showMsg('warning', 'A sales order must have at least one item.'); return; }
                $(this).closest('tr').remove();
                structureChanged = true;
                renumber();
                recalcAll();
            });

            var SPEC_UNIT_METRES = { MM: 0.001, CM: 0.01, MT: 1, FT: 0.3048, Inch: 0.0254 };
            // Unit of an Item Master width such as 1.10M, 8 FEET, 12' or 50"; no unit means metres, unknown units return null.
            function specUnitKey(u) {
                var s = $.trim(u).toUpperCase();
                if (s === '') return 'MT';
                if (s === 'MM') return 'MM';
                if (s === 'CM') return 'CM';
                if (/^(M|MT|MTR|MTRS|METER|METERS|METRE|METRES)$/.test(s)) return 'MT';
                if (/^(FT|FEET|FOOT|')$/.test(s)) return 'FT';
                if (/^(IN|INCH|INCHES|")$/.test(s)) return 'Inch';
                return null;
            }
            // Linear unit of an area UOM name (SQMT -> MT, SQFT -> FT, SQINCH -> Inch); '' if the name isn't recognised.
            function specLinearUnit(areaName) {
                var s = $.trim(areaName).toUpperCase().replace(/^SQ\.?\s*/, '').replace(/[\s.]/g, '');
                if (/^(M|MT|MTR|MTRS|METER|METERS|METRE|METRES)$/.test(s)) return 'MT';
                if (/^(FT|FEET|FOOT)$/.test(s)) return 'FT';
                if (/^(IN|INCH|INCHES)$/.test(s)) return 'Inch';
                return '';
            }
            // Keeps only the number from widths like 1.20M, 12' or 50"; the unit is remembered so Width can follow the line's UOM.
            function specWidthFromItem(item) {
                if (!item || $.trim(item.specType).toLowerCase() !== 'width') return null;
                var wm = String(item.specValue || '').match(/(\d+(?:\.\d+)?|\.\d+)\s*([A-Za-z'"]*)/);
                return wm ? { text: wm[1], unit: specUnitKey(wm[2]) } : null;
            }
            // Re-expresses the item's spec width in the linear unit of the line's selected area UOM (e.g. 1.10M -> 3.609 for SQFT).
            function applyRowSpecWidth($tr) {
                var sw = $tr.data('specWidth');
                if (!sw) return;
                var uomId = $tr.find('.f-uom').val(), val = sw.text;
                if (sw.unit && uomId && UomConversion.getRequirements(uomId).width) {
                    var tu = specLinearUnit($tr.find('.f-uom option:selected').text());
                    if (tu && tu !== sw.unit) {
                        val = (parseFloat(sw.text) * SPEC_UNIT_METRES[sw.unit] / SPEC_UNIT_METRES[tu]).toFixed(3);
                    }
                }
                $tr.find('.f-wid').val(val);
            }
            $('#itemsTable').on('change', '.f-uom', function () { applyRowSpecWidth($(this).closest('tr')); recalcAll(); });

            // Adds a new line for a searched item; its values are entered like any other line and the server recalculates them on save.
            function addItem(item) {
                var exists = false;
                dataRows().each(function () { if (parseInt($(this).attr('data-itbs-id'), 10) === item.itbsId) { exists = true; } });
                if (exists) { showMsg('warning', item.name + ' is already in this sales order.'); return; }
                var uoms = UomConversion.getCompatibleUoms(item.uomId);
                if (!item.uomId || !UomConversion.findUom(item.uomId) || uoms.length === 0) {
                    showMsg('danger', 'The sales unit of measure is not configured for ' + item.name + '.');
                    return;
                }
                var $tr = $('<tr data-sio-id="0" class="changed"></tr>')
                    .attr('data-itbs-id', item.itbsId).attr('data-target', item.uomId).attr('data-tax', item.tax).attr('data-cess', item.cess)
                    .attr('data-final', 0).attr('data-total', 0).attr('data-disc', 0).attr('data-taxamt', 0).attr('data-net', 0).attr('data-taxable', 0);
                function td(cls) { return $('<td></td>').addClass(cls || '').appendTo($tr); }
                function numInput(cls, step, dec, value) {
                    return $('<input type="number" min="0" inputmode="decimal" />').addClass('form-control so-num ' + cls)
                        .attr('step', step).attr('data-dec', dec).val(value);
                }
                td('c-sl');
                td().text(item.code);
                td().text(item.name);
                numInput('f-qty', '0.001', 3, '').appendTo(td('num'));
                numInput('f-len', '0.001', 3, '').appendTo(td('num'));
                numInput('f-wid', '0.001', 3, '').appendTo(td('num'));
                var $uom = $('<select class="form-control f-uom"></select>').appendTo(td());
                $.each(uoms, function (i, u) {
                    $('<option></option>').val(u.tum_id).text(u.tum_name).prop('selected', String(u.tum_id) === String(item.uomId)).appendTo($uom);
                });
                $('<span class="c-final"></span>').appendTo(td('num')).after('<span class="row-err"></span><span class="row-note"></span>');
                td().text(UomConversion.findUom(item.uomId).tum_name);
                numInput('f-price', '0.01', 2, num(item.price).toFixed(2)).appendTo(td('num'));
                numInput('f-rate', '0.01', 2, '0').attr('max', 100).appendTo(td('num'));
                td().css('text-align', 'right').addClass('c-disc');
                td().css('text-align', 'right').text(item.tax);
                td().css('text-align', 'right').addClass('c-tax');
                td().css('text-align', 'right').append('<b class="c-net"></b>');
                $('<button type="button" class="btn btn-danger btn-xs btn-remove" title="Remove item"><i class="fa fa-trash"></i></button>').appendTo(td());
                $tr.data('sig', '');
                $tr.data('specWidth', specWidthFromItem(item));
                applyRowSpecWidth($tr);
                $('#itemsTable tbody').append($tr);
                structureChanged = true;
                renumber();
                recalcAll();
                $tr.find('.f-qty').focus();
            }

            var searchTimer = null, searchSeq = 0;
            function hideResults() { $('#itemResults').hide().empty(); }
            $('#itemSearch').on('input', function () {
                var term = $.trim($(this).val());
                clearTimeout(searchTimer);
                if (term.length < 2) { hideResults(); return; }
                searchTimer = setTimeout(function () {
                    var seq = ++searchSeq;
                    $.ajax({
                        type: 'POST', url: 'edit_sales_order.aspx/SearchItems',
                        data: JSON.stringify({ smoId: cfg.smoId, term: term }),
                        contentType: 'application/json; charset=utf-8', dataType: 'json',
                        success: function (response) {
                            if (seq !== searchSeq) { return; }
                            var $list = $('#itemResults').empty();
                            var items = (response && response.d) || [];
                            if (items.length === 0) {
                                $list.append($('<li class="list-group-item text-muted"></li>').text('No items found'));
                            }
                            $.each(items, function (i, item) {
                                $('<li class="list-group-item" style="cursor: pointer;"></li>')
                                    .text(item.name + (item.code ? ' (' + item.code + ')' : '') + ' - stock ' + item.stock)
                                    .on('mousedown', function (e) { e.preventDefault(); addItem(item); $('#itemSearch').val(''); hideResults(); })
                                    .appendTo($list);
                            });
                            $list.show();
                        },
                        error: function () { hideResults(); showMsg('danger', 'Unable to search items. Please sign in again or try later.'); }
                    });
                }, 250);
            }).on('blur', function () { setTimeout(hideResults, 150); });

            $('#btnSave').on('click', function () {
                var state = recalcAll();
                if (state.bad) { showMsg('danger', 'Fix the highlighted items before saving.'); return; }
                if (dataRows().length === 0) { showMsg('danger', 'A sales order must have at least one item.'); return; }
                if (!state.any && headerState() === initialHeader) { showMsg('info', 'There are no changes to save.'); return; }

                var lines = [];
                dataRows().each(function () {
                    var $tr = $(this), s = readRow($tr);
                    lines.push({
                        sioId: parseInt($tr.attr('data-sio-id'), 10) || 0, itbsId: parseInt($tr.attr('data-itbs-id'), 10) || 0,
                        qty: s.qty, length: s.len, width: s.wid, tumIdCust: s.uom, price: s.price, discountRate: s.rate
                    });
                });

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
