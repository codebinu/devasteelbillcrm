<%@ Page Language="C#" AutoEventWireup="true" CodeFile="sales_order_invoice.aspx.cs" Inherits="web_sales_sales_order_invoice" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Create Sales Order Invoice | Invoice Me</title>
    <script src="../js/common.js" type="text/javascript"></script>
    <script type="text/javascript" src="../js/jquery-2.0.3.js"></script>
    <script type="text/javascript" src="../js/jquery.cookie.js"></script>

    <link href="../css/bootstrap/bootstrap.min.css" rel="stylesheet" />
    <link href="../css/font-awesome/css/font-awesome.min.css" rel="stylesheet" />
    <link href="../css/bootstrap/nprogress.css" rel="stylesheet" />
    <link href="../css/bootstrap/custom.min.css" rel="stylesheet" />
    <link href="../css/bootstrap/mystyle.css" type="text/css" rel="stylesheet" />

    <style>
        .info-row { padding: 4px 0; border-bottom: 1px dashed #eee; overflow: hidden; }
        .info-row .k { color: #777; float: left; width: 42%; }
        .info-row .v { float: left; width: 58%; font-weight: 600; word-break: break-word; }
        #invoiceItems .qty-input { width: 90px; text-align: right; }
        #invoiceItems tr.row-disabled td { color: #999; background: #fafafa; }
        #invoiceItems tr.row-error .qty-input { border-color: #a94442; }
        #invoiceItems .row-note { display: block; font-size: 11px; color: #a94442; }
        #invoiceItems .sub-note { display: block; font-size: 11px; color: #777; }
        .totals-table td { padding: 4px 8px; }
        .totals-table td.amt { text-align: right; font-weight: 600; min-width: 110px; }
        #invoiceMessage .alert { margin-bottom: 10px; }
    </style>

    <script type="text/javascript">
        $(document).ready(function () {
            if (!$.cookie("invntrystaffBranchId")) {
                location.href = "../dashboard.aspx";
                return false;
            }
            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " &copy;");
            $('#form1').on('submit', function (e) { e.preventDefault(); });
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
                                    <label style="font-weight: bold; font-size: 16px;">Create Sales Order Invoice</label>
                                </div>
                                <div class="col-md-6 col-xs-5">
                                    <a href="view_sales_order.aspx?smoId=<%= SmoId %>#tabInvoices">
                                        <div class="btn btn-primary btn-xs pull-right" style="margin-top: 5px"><label style="color: #fff; margin-right: 5px; font-size: 14px;" class="fa fa-arrow-left"></label>Back to Sales Order</div>
                                    </a>
                                </div>
                            </div>
                        </nav>
                    </div>
                </div>

                <div class="right_col" role="main">
                    <% if (Data == null || Data.Header == null) { %>
                    <div class="x_panel">
                        <div class="x_content" style="text-align: center; padding: 30px 0;">
                            <p style="color: red"><%= Enc(ErrorMessage) %></p>
                            <a href="sales_order_list.aspx" class="btn btn-primary">Back to Sales Orders</a>
                        </div>
                    </div>
                    <% } else { %>
                    <div class="row">
                        <div class="col-md-6 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title"><strong><i class="fa fa-user"></i> Customer Information</strong><div class="clearfix"></div></div>
                                <div class="x_content">
                                    <div class="info-row"><span class="k">Customer</span><span class="v"><%= Enc(Data.Header.CustomerName) %></span></div>
                                    <div class="info-row"><span class="k">Customer ID</span><span class="v"><%= Data.Header.CustId %></span></div>
                                    <% if (Data.Header.Phone != "") { %><div class="info-row"><span class="k">Contact</span><span class="v"><%= Enc(Data.Header.Phone) %></span></div><% } %>
                                    <% if (Data.Header.Phone2 != "") { %><div class="info-row"><span class="k">Alt. Contact</span><span class="v"><%= Enc(Data.Header.Phone2) %></span></div><% } %>
                                    <% if (Data.Header.Email != "") { %><div class="info-row"><span class="k">Email</span><span class="v"><%= Enc(Data.Header.Email) %></span></div><% } %>
                                    <% if (Data.Header.Address != "") { %><div class="info-row"><span class="k">Address</span><span class="v"><%= Enc(Data.Header.Address) %></span></div><% } %>
                                    <% if (Data.Header.City != "") { %><div class="info-row"><span class="k">City</span><span class="v"><%= Enc(Data.Header.City) %></span></div><% } %>
                                    <% if (Data.Header.TaxRegId != "") { %><div class="info-row"><span class="k">Tax Reg. ID</span><span class="v"><%= Enc(Data.Header.TaxRegId) %></span></div><% } %>
                                    <div class="info-row"><span class="k">A/C Balance</span><span class="v"><%= Money(Data.Header.AccountBalance) %></span></div>
                                    <div class="info-row"><span class="k">Credit Amount / Period</span><span class="v"><%= Money(Data.Header.CreditAmount) %> / <%= Num(Data.Header.CreditPeriod) %> days</span></div>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-6 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title"><strong><i class="fa fa-file-text-o"></i> Sales Order</strong><div class="clearfix"></div></div>
                                <div class="x_content">
                                    <div class="info-row"><span class="k">Sales Order No</span><span class="v"><%= Enc(Data.Header.OrderNo) %></span></div>
                                    <div class="info-row"><span class="k">Sales Order Date</span><span class="v"><%= Enc(Data.Header.OrderDate) %></span></div>
                                    <div class="info-row"><span class="k">Status</span><span class="v"><% if (Data.Header.StatusText != "") { %><span class="status <%= Data.Header.StatusCss %>"><%= Data.Header.StatusText %></span><% } %></span></div>
                                    <% if (Data.Header.BranchName != "") { %><div class="info-row"><span class="k">Warehouse</span><span class="v"><%= Enc(Data.Header.BranchName) %></span></div><% } %>
                                    <div class="info-row"><span class="k">Invoice Date</span><span class="v">Today (set when the invoice is saved)</span></div>
                                    <div class="info-row"><span class="k">Tax</span><span class="v"><%= Data.Header.TaxMethod == 0 ? "No tax" : (Data.Header.TaxMethod == 1 ? "VAT" : "GST") %><%= Data.Header.TaxMethod != 0 ? (Data.Header.TaxInclusive == 1 ? " (prices include tax)" : " (prices exclude tax)") : "" %></span></div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title"><strong><i class="fa fa-list"></i> Items to Invoice</strong><div class="clearfix"></div></div>
                                <div class="x_content">
                                    <div id="invoiceMessage">
                                        <% if (!Data.CanInvoice && Data.Message != null) { %><div class="alert alert-warning"><%= Enc(Data.Message) %></div><% } %>
                                    </div>
                                    <div style="overflow-x: auto;">
                                        <table class="table table-striped jambo_table table-bordered" id="invoiceItems">
                                            <thead style="background-color: #f1eeee; color: #525252">
                                                <tr>
                                                    <th style="width: 30px;"><input type="checkbox" id="selectAll" title="Select all" <%= Data.CanInvoice ? "" : "disabled=\"disabled\"" %> /></th>
                                                    <th>#</th>
                                                    <th>Item</th>
                                                    <th class="text-right">Ordered Qty</th>
                                                    <th class="text-right">Previously Invoiced</th>
                                                    <th class="text-right">Remaining</th>
                                                    <th class="text-right">Reserved</th>
                                                    <th class="text-right">Qty to Invoice</th>
                                                    <th class="text-right">Unit Price</th>
                                                    <th class="text-right">Discount</th>
                                                    <th class="text-right">Tax</th>
                                                    <th class="text-right">Line Total</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <% int sl = 1; foreach (SalesOrderInvoiceLine l in Data.Lines) { bool enabled = Data.CanInvoice && l.MaxQty > 0; %>
                                                <tr class="inv-row<%= enabled ? "" : " row-disabled" %>" data-sio="<%= l.SioId %>" data-max="<%= Inv(l.MaxQty) %>" data-price="<%= Inv(l.Price) %>" data-rate="<%= Inv(l.DiscountRate) %>" data-tax="<%= Inv(l.TaxPercent) %>" data-cess="<%= Inv(l.CessPercent) %>">
                                                    <td><input type="checkbox" class="row-check" <%= enabled ? "" : "disabled=\"disabled\"" %> /></td>
                                                    <td><%= sl++ %></td>
                                                    <td>
                                                        <%= Enc(l.Name) %>
                                                        <% if (l.Code != "") { %><span class="sub-note"><%= Enc(l.Code) %></span><% } %>
                                                        <% if (RowNote(l) != "") { %><span class="row-note"><%= Enc(RowNote(l)) %></span><% } %>
                                                    </td>
                                                    <td class="text-right"><%= Num(l.Ordered) %> <%= Enc(l.Uom) %></td>
                                                    <td class="text-right"><%= Num(l.Invoiced) %></td>
                                                    <td class="text-right"><%= Num(l.Remaining) %></td>
                                                    <td class="text-right"><%= l.IsProduct ? Num(l.Reserved) : "-" %></td>
                                                    <td class="text-right"><input type="number" class="form-control input-sm qty-input" min="0.001" max="<%= Inv(l.MaxQty) %>" step="0.001" disabled="disabled" /></td>
                                                    <td class="text-right"><%= Money(l.Price) %></td>
                                                    <td class="text-right"><%= Num(l.DiscountRate) %>%</td>
                                                    <td class="text-right"><%= Data.Header.TaxMethod == 0 ? "-" : Num(l.TaxPercent) + "%" + (l.CessPercent > 0 ? " + " + Num(l.CessPercent) + "% cess" : "") %></td>
                                                    <td class="text-right line-total">0.00</td>
                                                </tr>
                                                <% } %>
                                            </tbody>
                                        </table>
                                    </div>
                                    <p class="text-muted" style="font-size: 11px;">Quantities can have up to 3 decimal places and are in the order line's unit. A quantity can be invoiced only while it is still remaining on the order and reserved for it. Invoicing reduces the reservation and the batch stock by the invoiced quantity.</p>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-8 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title"><strong><i class="fa fa-credit-card"></i> Payment &amp; Notes</strong><div class="clearfix"></div></div>
                                <div class="x_content">
                                    <div class="row">
                                        <div class="col-md-4 col-sm-6 col-xs-12 form-group">
                                            <label for="payMode">Payment Mode</label>
                                            <select id="payMode" class="form-control">
                                                <option value="1">Cash</option>
                                                <option value="2">Credit</option>
                                                <option value="3">Bill to bill</option>
                                            </select>
                                        </div>
                                        <div class="col-md-4 col-sm-6 col-xs-12 form-group">
                                            <label for="cashAmount">Cash Amount</label>
                                            <input type="number" id="cashAmount" class="form-control" min="0" step="any" value="0" />
                                        </div>
                                        <div class="col-md-4 col-sm-6 col-xs-12 form-group">
                                            <label for="chequeAmount">Cheque Amount</label>
                                            <input type="number" id="chequeAmount" class="form-control" min="0" step="any" value="0" />
                                        </div>
                                    </div>
                                    <div class="row" id="chequeDetails" style="display: none;">
                                        <div class="col-md-4 col-sm-6 col-xs-12 form-group">
                                            <label for="chequeNo">Cheque No.</label>
                                            <input type="text" id="chequeNo" class="form-control" maxlength="50" />
                                        </div>
                                        <div class="col-md-4 col-sm-6 col-xs-12 form-group">
                                            <label for="chequeDate">Cheque Date</label>
                                            <input type="date" id="chequeDate" class="form-control" />
                                        </div>
                                        <div class="col-md-4 col-sm-6 col-xs-12 form-group">
                                            <label for="chequeBank">Bank</label>
                                            <input type="text" id="chequeBank" class="form-control" maxlength="100" />
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <label for="invoiceNote">Notes / Remarks</label>
                                        <textarea id="invoiceNote" class="form-control" rows="3" maxlength="1000" style="resize: none;"></textarea>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-4 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title"><strong><i class="fa fa-calculator"></i> Invoice Totals</strong><div class="clearfix"></div></div>
                                <div class="x_content">
                                    <table class="totals-table" style="width: 100%;">
                                        <tr><td>Sub Total</td><td class="amt" id="tSubTotal">0.00</td></tr>
                                        <tr><td>Discount</td><td class="amt" id="tDiscount">0.00</td></tr>
                                        <tr><td>Tax</td><td class="amt" id="tTax">0.00</td></tr>
                                        <tr><td><strong>Grand Total</strong></td><td class="amt" id="tGrand" style="font-size: 16px;">0.00</td></tr>
                                        <tr><td>Paid</td><td class="amt" id="tPaid">0.00</td></tr>
                                        <tr><td>Balance</td><td class="amt" id="tBalance">0.00</td></tr>
                                    </table>
                                    <div style="margin-top: 15px;">
                                        <button type="button" id="btnSave" class="btn btn-success btn-block" <%= Data.CanInvoice ? "" : "disabled=\"disabled\"" %>><i class="fa fa-save"></i> Save Invoice</button>
                                        <a href="view_sales_order.aspx?smoId=<%= SmoId %>#tabInvoices" class="btn btn-default btn-block">Cancel</a>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
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
    <% if (Data != null && Data.Header != null) { %>
    <script type="text/javascript">
        $(function () {
            var cfg = { smoId: <%= SmoId %>, token: '<%= SessionToken %>', method: <%= Data.Header.TaxMethod %>, inclusive: <%= Data.Header.TaxInclusive %>, acc: <%= Accuracy %> };
            var saving = false;

            function fmt(n) { return (isFinite(n) ? n : 0).toFixed(cfg.acc); }
            function num(v) { var n = parseFloat(v); return isFinite(n) ? n : 0; }

            function showMessage(type, text) {
                $('#invoiceMessage').html($('<div class="alert"></div>').addClass('alert-' + type).text(text));
                $('html, body').animate({ scrollTop: $('#invoiceMessage').offset().top - 80 }, 200);
            }

            // Same formulas as the shared invoice saver (neworder.aspx.cs SaveInvoice); the server recalculates and validates everything on save.
            function calcLine(row, qty) {
                var price = num(row.attr('data-price')), rate = num(row.attr('data-rate'));
                var tax = num(row.attr('data-tax')), cess = num(row.attr('data-cess'));
                if (cfg.method === 0) { tax = 0; cess = 0; }
                else if (cfg.inclusive === 1) {
                    price = cess > 0 ? (10000 * price) / (10000 + 100 * tax + tax * cess) : price / (tax / 100 + 1);
                }
                var real = price * qty, disc = real * rate / 100, net = real - disc;
                var taxAmt = net * tax / 100;
                taxAmt = taxAmt + taxAmt * cess / 100;
                return { real: real, disc: disc, tax: taxAmt, total: net + taxAmt };
            }

            function rowQty(row) {
                var text = $.trim(row.find('.qty-input').val());
                var max = parseFloat(row.attr('data-max'));
                if (!/^(\d+(\.\d{1,3})?|\.\d{1,3})$/.test(text)) return { valid: false, qty: 0 };
                var qty = parseFloat(text);
                return { valid: qty >= 0.001 && qty <= max + 1e-9, qty: qty };
            }

            function recalc() {
                var sub = 0, disc = 0, tax = 0, total = 0, selected = 0, invalid = 0;
                $('#invoiceItems tr.inv-row').each(function () {
                    var row = $(this), checked = row.find('.row-check').is(':checked');
                    row.toggleClass('row-error', false);
                    if (!checked) { row.find('.line-total').text('0.00'); return; }
                    selected++;
                    var q = rowQty(row);
                    if (!q.valid) { invalid++; row.addClass('row-error'); row.find('.line-total').text('0.00'); return; }
                    var c = calcLine(row, q.qty);
                    row.find('.line-total').text(fmt(c.total));
                    sub += c.real; disc += c.disc; tax += c.tax; total += c.total;
                });
                var grand = parseFloat(total.toFixed(cfg.acc));
                var paid = num($('#cashAmount').val()) + num($('#chequeAmount').val());
                $('#tSubTotal').text(fmt(sub));
                $('#tDiscount').text(fmt(disc));
                $('#tTax').text(fmt(tax));
                $('#tGrand').text(fmt(grand));
                $('#tPaid').text(fmt(paid));
                $('#tBalance').text(fmt(grand - paid));
                $('#chequeDetails').toggle(num($('#chequeAmount').val()) > 0);
                return { selected: selected, invalid: invalid, grand: grand, paid: paid };
            }

            $('#invoiceItems').on('change', '.row-check', function () {
                var row = $(this).closest('tr'), input = row.find('.qty-input');
                if ($(this).is(':checked')) {
                    input.prop('disabled', false);
                    if ($.trim(input.val()) === '') input.val(row.attr('data-max'));
                } else {
                    input.prop('disabled', true).val('');
                }
                recalc();
            });
            $('#invoiceItems').on('input change', '.qty-input', recalc);
            $('#selectAll').on('change', function () {
                var on = $(this).is(':checked');
                $('#invoiceItems tr.inv-row .row-check:enabled').each(function () {
                    $(this).prop('checked', on).trigger('change');
                });
            });
            $('#cashAmount, #chequeAmount').on('input change', recalc);
            $('#payMode').on('change', recalc);

            $('#btnSave').on('click', function () {
                if (saving) return;
                var t = recalc();
                if (t.selected === 0) { showMessage('warning', 'Select at least one item to invoice.'); return; }
                if (t.invalid > 0) { showMessage('danger', 'Enter a quantity (up to 3 decimal places) between 0.001 and the available quantity for every selected item.'); return; }
                if (t.paid < 0 || t.paid > t.grand + 0.005) { showMessage('danger', 'The paid amount cannot be greater than the invoice amount.'); return; }
                if (num($('#chequeAmount').val()) > 0 && ($.trim($('#chequeNo').val()) === '' || $.trim($('#chequeBank').val()) === '' || $('#chequeDate').val() === '')) {
                    showMessage('danger', 'Enter the cheque number, date and bank.'); return;
                }
                var lines = [];
                $('#invoiceItems tr.inv-row').each(function () {
                    var row = $(this);
                    if (row.find('.row-check').is(':checked')) lines.push({ sioId: parseInt(row.attr('data-sio'), 10), qty: rowQty(row).qty });
                });
                var request = {
                    smoId: cfg.smoId, sessionId: cfg.token, paymentMode: parseInt($('#payMode').val(), 10),
                    cashAmount: num($('#cashAmount').val()), chequeAmount: num($('#chequeAmount').val()),
                    chequeNo: $('#chequeNo').val(), chequeDate: $('#chequeDate').val(), chequeBank: $('#chequeBank').val(),
                    note: $('#invoiceNote').val(), lines: lines
                };
                bootbox.confirm('Create this invoice? The reservations and batch stock of the invoiced items will be reduced.', function (ok) {
                    if (!ok || saving) return;
                    saving = true;
                    $('#btnSave').prop('disabled', true);
                    loading();
                    $.ajax({
                        type: 'POST',
                        url: 'neworder.aspx/saveSalesOrderInvoice',
                        data: JSON.stringify({ request: request }),
                        contentType: 'application/json; charset=utf-8',
                        dataType: 'json',
                        success: function (msg) {
                            var r;
                            try { r = JSON.parse(msg.d); } catch (e) { r = { ok: false, message: 'Unexpected response from the server.' }; }
                            if (r.ok) {
                                location.href = 'view_sales_order.aspx?smoId=' + cfg.smoId + '&done=invoiced&invoiceId=' + r.invoiceId + '#tabInvoices';
                                return;
                            }
                            Unloading();
                            saving = false;
                            $('#btnSave').prop('disabled', false);
                            showMessage('danger', r.message || 'The invoice could not be saved.');
                        },
                        error: function () {
                            Unloading();
                            saving = false;
                            $('#btnSave').prop('disabled', false);
                            showMessage('danger', 'The invoice could not be saved. Please check the sales order before trying again.');
                        }
                    });
                });
            });

            recalc();
        });
    </script>
    <% } %>
</body>
</html>
