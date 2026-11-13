<%@ Page Language="C#" AutoEventWireup="true" CodeFile="sales_order_interstock_transfer.aspx.cs" Inherits="web_sales_sales_order_interstock_transfer" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Inter Stock Transfer | Invoice Me</title>
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
        #transferItems .qty-input { width: 90px; text-align: right; }
        #transferItems tr.row-disabled td { color: #999; background: #fafafa; }
        #transferItems tr.row-error .qty-input { border-color: #a94442; }
        #transferItems .row-note { display: block; font-size: 11px; color: #a94442; }
        #transferItems .sub-note { display: block; font-size: 11px; color: #777; }
        .totals-table td { padding: 4px 8px; }
        .totals-table td.amt { text-align: right; font-weight: 600; min-width: 110px; }
        #transferMessage .alert { margin-bottom: 10px; }
        .busy { color: #777; padding: 8px 0; }
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
                                    <label style="font-weight: bold; font-size: 16px;">Inter Stock Transfer</label>
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
                    <% if (ErrorMessage != "") { %>
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
                                <div class="x_title"><strong><i class="fa fa-exchange"></i> Transfer Details</strong><div class="clearfix"></div></div>
                                <div class="x_content">
                                    <div class="form-group">
                                        <label for="sourceBranch">Source Warehouse</label>
                                        <select id="sourceBranch" class="form-control" <%= CanTransfer && Sources.Count > 0 ? "" : "disabled=\"disabled\"" %>>
                                            <option value="">-- Select source warehouse --</option>
                                            <% foreach (InterStockSource s in Sources) { %>
                                            <option value="<%= s.branchId %>"><%= Enc(s.name) %></option>
                                            <% } %>
                                        </select>
                                        <% if (Sources.Count == 0) { %><span class="help-block text-danger">None of your warehouses has both a customer and a vendor account.</span><% } %>
                                    </div>
                                    <div class="form-group">
                                        <label for="targetCust">Target Customer / Warehouse</label>
                                        <select id="targetCust" class="form-control" disabled="disabled">
                                            <option value="">-- Select the source warehouse first --</option>
                                        </select>
                                    </div>
                                    <div id="targetInfo"></div>
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
                                    <div class="info-row"><span class="k">Customer</span><span class="v"><%= Enc(Data.Header.CustomerName) %></span></div>
                                    <% if (Data.Header.BranchName != "") { %><div class="info-row"><span class="k">Order Warehouse</span><span class="v"><%= Enc(Data.Header.BranchName) %></span></div><% } %>
                                    <div class="info-row"><span class="k">Transfer Date</span><span class="v">Today (set when the transfer is saved)</span></div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title"><strong><i class="fa fa-list"></i> Items to Transfer</strong><div class="clearfix"></div></div>
                                <div class="x_content">
                                    <div id="transferMessage">
                                        <% if (!CanTransfer) { %><div class="alert alert-warning">Stock can be transferred only for an Approved or Processed sales order.</div><% } %>
                                    </div>
                                    <div id="itemsBusy" class="busy" style="display: none;"><i class="fa fa-spinner fa-spin"></i> Loading items...</div>
                                    <div style="overflow-x: auto;">
                                        <table class="table table-striped jambo_table table-bordered" id="transferItems">
                                            <thead style="background-color: #f1eeee; color: #525252">
                                                <tr>
                                                    <th>#</th>
                                                    <th>Item</th>
                                                    <th>Batch</th>
                                                    <th class="text-right">Reserved</th>
                                                    <th class="text-right">Transferable</th>
                                                    <th class="text-right">Transfer Qty</th>
                                                    <th class="text-right">Unit Price</th>
                                                    <th class="text-right">Discount</th>
                                                    <th class="text-right">Tax</th>
                                                    <th class="text-right">Line Total</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr><td colspan="10" class="text-center text-muted">Select the source warehouse to load the order items reserved in it.</td></tr>
                                            </tbody>
                                        </table>
                                    </div>
                                    <p class="text-muted" style="font-size: 11px;">Only stock reserved for this order in the source warehouse can be transferred, in whole units of the batch's unit. The invoice reduces the source warehouse stock, the batch and the reservation; the purchase adds the same quantity to the target warehouse, reserved for the same order item.</p>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-8 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title"><strong><i class="fa fa-history"></i> Stock Transfers of this Order</strong><div class="clearfix"></div></div>
                                <div class="x_content">
                                    <div style="overflow-x: auto;">
                                        <table class="table table-striped table-bordered" id="transfersTable">
                                            <thead>
                                                <tr><th>Invoice</th><th>Date</th><th>From</th><th>To Customer</th><th class="text-right">Amount</th><th>Purchase</th><th></th></tr>
                                            </thead>
                                            <tbody><tr><td colspan="7" class="text-center text-muted">Loading...</td></tr></tbody>
                                        </table>
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
                                    </table>
                                    <div style="margin-top: 15px;">
                                        <button type="button" id="btnSave" class="btn btn-success btn-block" disabled="disabled"><i class="fa fa-save"></i> Save Transfer</button>
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
    <% if (ErrorMessage == "" && Data != null && Data.Header != null) { %>
    <script type="text/javascript">
        $(function () {
            var cfg = { smoId: <%= SmoId %>, token: '<%= SessionToken %>', acc: <%= Accuracy %>, canTransfer: <%= CanTransfer ? "true" : "false" %> };
            var page = 'sales_order_interstock_transfer.aspx/';
            var items = null, taxMethod = 0, taxInclusive = 0;
            var targetOk = false, saving = false, finished = false, sourceSeq = 0, targetSeq = 0;

            function fmt(n) { return (isFinite(n) ? n : 0).toFixed(cfg.acc); }
            function num(v) { var n = parseFloat(v); return isFinite(n) ? n : 0; }
            function trim4(n) { return String(Math.round(n * 10000) / 10000); }

            function showMessage(type, text) {
                $('#transferMessage').html($('<div class="alert"></div>').addClass('alert-' + type).text(text));
                $('html, body').animate({ scrollTop: $('#transferMessage').offset().top - 80 }, 200);
            }

            // Page methods return the serialized result in msg.d.
            function call(method, data, done, fail) {
                $.ajax({
                    type: 'POST', url: page + method, data: JSON.stringify(data),
                    contentType: 'application/json; charset=utf-8', dataType: 'json',
                    success: function (msg) {
                        var r;
                        try { r = JSON.parse(msg.d); } catch (e) { r = { ok: false, message: 'Unexpected response from the server.' }; }
                        done(r);
                    },
                    error: function () { fail(); }
                });
            }

            function resetTarget() {
                targetOk = false;
                $('#targetCust').prop('disabled', true).empty().append($('<option></option>').val('').text('-- Select the source warehouse first --'));
                $('#targetInfo').empty();
            }

            function resetItems(text) {
                items = null;
                $('#transferItems tbody').empty().append($('<tr></tr>').append($('<td colspan="10" class="text-center text-muted"></td>').text(text)));
                recalc();
            }

            function infoRow(k, v) {
                return $('<div class="info-row"></div>').append($('<span class="k"></span>').text(k)).append($('<span class="v"></span>').text(v));
            }

            function renderTarget(t) {
                var box = $('#targetInfo').empty();
                box.append(infoRow('Customer', t.name)).append(infoRow('Customer ID', t.custId)).append(infoRow('Target Warehouse', t.branchName));
                if (t.phone) box.append(infoRow('Contact', t.phone));
                if (t.phone2) box.append(infoRow('Alt. Contact', t.phone2));
                if (t.email) box.append(infoRow('Email', t.email));
                if (t.address) box.append(infoRow('Address', t.address));
                if (t.city) box.append(infoRow('City', t.city));
                if (t.taxRegId) box.append(infoRow('Tax Reg. ID', t.taxRegId));
                box.append(infoRow('A/C Balance', fmt(t.balance)));
                if (taxMethod === 2) box.append(infoRow('GST', t.interState ? 'Interstate (IGST)' : 'Within the state (CGST + SGST)'));
            }

            function calcLine(line, qty) {
                var price = line.price, rate = line.discountRate, tax = line.taxPercent, cess = line.cessPercent;
                if (taxMethod === 0) { tax = 0; cess = 0; }
                else if (taxInclusive === 1) {
                    price = cess > 0 ? (10000 * price) / (10000 + 100 * tax + tax * cess) : price / (tax / 100 + 1);
                }
                var real = price * qty, disc = real * rate / 100, net = real - disc;
                var taxAmt = net * tax / 100;
                taxAmt = taxAmt + taxAmt * cess / 100;
                return { real: real, disc: disc, tax: taxAmt, total: net + taxAmt };
            }

            function rowQty(row) {
                var text = $.trim(row.find('.qty-input').val());
                if (text === '') return { empty: true, valid: true, qty: 0 };
                var max = parseFloat(row.attr('data-max'));
                if (!/^\d+$/.test(text)) return { empty: false, valid: false, qty: 0 };
                var qty = parseInt(text, 10);
                return { empty: false, valid: qty >= 1 && qty <= max, qty: qty };
            }

            function recalc() {
                var sub = 0, disc = 0, tax = 0, total = 0, selected = 0, invalid = 0;
                $('#transferItems tr.tr-row').each(function () {
                    var row = $(this), line = row.data('line');
                    row.removeClass('row-error');
                    var q = rowQty(row);
                    if (q.empty) { row.find('.line-total').text('0.00'); return; }
                    if (!q.valid) { invalid++; row.addClass('row-error'); row.find('.line-total').text('0.00'); return; }
                    selected++;
                    var c = calcLine(line, q.qty);
                    row.find('.line-total').text(fmt(c.total));
                    sub += c.real; disc += c.disc; tax += c.tax; total += c.total;
                });
                $('#tSubTotal').text(fmt(sub));
                $('#tDiscount').text(fmt(disc));
                $('#tTax').text(fmt(tax));
                $('#tGrand').text(fmt(parseFloat(total.toFixed(cfg.acc))));
                $('#btnSave').prop('disabled', !(cfg.canTransfer && !saving && !finished && targetOk && items !== null && selected > 0));
                return { selected: selected, invalid: invalid };
            }

            function renderItems(r) {
                items = r.lines;
                taxMethod = r.taxMethod;
                taxInclusive = r.taxInclusive;
                var body = $('#transferItems tbody').empty(), sl = 1, any = false;
                if (!items.length) { resetItems('This sales order has no stock items.'); items = []; return; }
                $.each(items, function (i, line) {
                    var n = sl++;
                    var first = true;
                    var rows = line.batches.length ? line.batches : [null];
                    $.each(rows, function (j, b) {
                        var enabled = b !== null && b.max > 0;
                        any = any || enabled;
                        var tr = $('<tr class="tr-row"></tr>').addClass(enabled ? '' : 'row-disabled').data('line', line).attr('data-sio', line.sioId).attr('data-max', b ? b.max : 0);
                        if (b) tr.attr('data-batch', b.itbhId);
                        var nameCell = $('<td></td>');
                        if (first) {
                            nameCell.text(line.name);
                            if (line.code) nameCell.append($('<span class="sub-note"></span>').text(line.code));
                            if (line.note) nameCell.append($('<span class="row-note"></span>').text(line.note));
                        }
                        tr.append($('<td></td>').text(first ? n : '')).append(nameCell);
                        tr.append($('<td></td>').text(b ? b.batchNo : '-'));
                        tr.append($('<td class="text-right"></td>').text(b ? trim4(b.reserved) + ' ' + line.uom : '-'));
                        tr.append($('<td class="text-right"></td>').text(b ? trim4(b.max) + ' ' + line.uom : '-'));
                        tr.append($('<td class="text-right"></td>').append($('<input type="number" class="form-control input-sm qty-input" min="1" step="1" />').attr('max', b ? b.max : 0).prop('disabled', !enabled)));
                        tr.append($('<td class="text-right"></td>').text(fmt(line.price)));
                        tr.append($('<td class="text-right"></td>').text(trim4(line.discountRate) + '%'));
                        tr.append($('<td class="text-right"></td>').text(taxMethod === 0 ? '-' : trim4(line.taxPercent) + '%' + (line.cessPercent > 0 ? ' + ' + trim4(line.cessPercent) + '% cess' : '')));
                        tr.append($('<td class="text-right line-total">0.00</td>'));
                        body.append(tr);
                        first = false;
                    });
                });
                if (!any) showMessage('warning', 'No stock is reserved for this order in the selected warehouse. Reserve stock from this warehouse in the Reserved Items tab first.');
                recalc();
            }

            $('#sourceBranch').on('change', function () {
                var branch = parseInt($(this).val(), 10), my = ++sourceSeq;
                targetSeq++;
                resetTarget();
                resetItems('Select the source warehouse to load the order items reserved in it.');
                $('#transferMessage').empty();
                $('#itemsBusy').hide();
                if (!branch) return;
                $('#targetCust').empty().append($('<option></option>').val('').text('Loading customers...'));
                $('#itemsBusy').show();
                call('getTargets', { smoId: cfg.smoId, sourceBranchId: branch }, function (r) {
                    if (my !== sourceSeq) return;
                    $('#targetCust').empty().append($('<option></option>').val('').text('-- Select target customer --'));
                    if (!r.ok) { showMessage('danger', r.message || 'The customers could not be loaded.'); return; }
                    $.each(r.targets, function (i, t) {
                        $('#targetCust').append($('<option></option>').val(t.custId).text(t.custName + ' (' + t.branchName + ')'));
                    });
                    if (r.message) showMessage('warning', r.message);
                    $('#targetCust').prop('disabled', r.targets.length === 0);
                }, function () {
                    if (my !== sourceSeq) return;
                    showMessage('danger', 'The customers could not be loaded. Please try again.');
                });
                call('getItems', { smoId: cfg.smoId, sourceBranchId: branch }, function (r) {
                    if (my !== sourceSeq) return;
                    $('#itemsBusy').hide();
                    if (!r.ok) { resetItems('The items could not be loaded.'); showMessage('danger', r.message || 'The items could not be loaded.'); return; }
                    renderItems(r);
                }, function () {
                    if (my !== sourceSeq) return;
                    $('#itemsBusy').hide();
                    resetItems('The items could not be loaded.');
                    showMessage('danger', 'The items could not be loaded. Please try again.');
                });
            });

            $('#targetCust').on('change', function () {
                var cust = parseInt($(this).val(), 10), branch = parseInt($('#sourceBranch').val(), 10), my = ++targetSeq;
                targetOk = false;
                $('#targetInfo').empty();
                recalc();
                if (!cust || !branch) return;
                $('#targetInfo').html('<div class="busy"><i class="fa fa-spinner fa-spin"></i> Loading customer...</div>');
                call('getTarget', { smoId: cfg.smoId, sourceBranchId: branch, custId: cust }, function (r) {
                    if (my !== targetSeq) return;
                    $('#targetInfo').empty();
                    if (!r.ok) { showMessage('danger', r.message || 'The customer could not be loaded.'); return; }
                    $('#transferMessage').empty();
                    targetOk = true;
                    renderTarget(r);
                    recalc();
                }, function () {
                    if (my !== targetSeq) return;
                    $('#targetInfo').empty();
                    showMessage('danger', 'The customer could not be loaded. Please try again.');
                });
            });

            $('#transferItems').on('input change', '.qty-input', recalc);

            function loadTransfers() {
                call('getTransfers', { smoId: cfg.smoId }, function (rows) {
                    var body = $('#transfersTable tbody').empty();
                    if (!rows.length) { body.append($('<tr></tr>').append($('<td colspan="7" class="text-center text-muted"></td>').text('No stock transfers have been made for this sales order.'))); return; }
                    $.each(rows, function (i, t) {
                        var tr = $('<tr></tr>');
                        tr.append($('<td></td>').text('#' + t.salesId)).append($('<td></td>').text(t.date)).append($('<td></td>').text(t.source))
                            .append($('<td></td>').text(t.target)).append($('<td class="text-right"></td>').text(fmt(t.amount)));
                        if (t.purchaseId > 0) {
                            tr.append($('<td></td>').append($('<span class="label label-success"></span>').text('#' + t.purchaseId))).append($('<td></td>'));
                        } else {
                            tr.append($('<td></td>').append($('<span class="label label-danger"></span>').text('Purchase pending')));
                            tr.append($('<td></td>').append($('<button type="button" class="btn btn-warning btn-xs btn-retry"></button>').attr('data-sm', t.salesId).text('Retry Purchase')));
                        }
                        body.append(tr);
                    });
                }, function () {
                    $('#transfersTable tbody').empty().append($('<tr></tr>').append($('<td colspan="7" class="text-center text-danger"></td>').text('The transfers could not be loaded.')));
                });
            }

            $('#transfersTable').on('click', '.btn-retry', function () {
                if (saving) return;
                var btn = $(this), smId = parseInt(btn.attr('data-sm'), 10);
                saving = true;
                btn.prop('disabled', true);
                loading();
                call('retryPurchase', { smoId: cfg.smoId, smId: smId }, function (r) {
                    Unloading();
                    saving = false;
                    showMessage(r.ok ? 'success' : 'danger', r.message || (r.ok ? 'The transfer is complete.' : 'The purchase could not be generated.'));
                    loadTransfers();
                }, function () {
                    Unloading();
                    saving = false;
                    btn.prop('disabled', false);
                    showMessage('danger', 'The purchase could not be generated. Please check the transfers list before trying again.');
                });
            });

            $('#btnSave').on('click', function () {
                if (saving || finished) return;
                var t = recalc();
                if (!targetOk) { showMessage('warning', 'Select the source warehouse and a valid target customer.'); return; }
                if (t.invalid > 0) { showMessage('danger', 'Enter a whole number between 1 and the transferable quantity for every item you transfer.'); return; }
                if (t.selected === 0) { showMessage('warning', 'Enter a transfer quantity for at least one item.'); return; }
                var lines = [];
                $('#transferItems tr.tr-row').each(function () {
                    var row = $(this), q = rowQty(row);
                    if (!q.empty) lines.push({ sioId: parseInt(row.attr('data-sio'), 10), itbhId: parseInt(row.attr('data-batch'), 10), qty: q.qty });
                });
                var request = { smoId: cfg.smoId, sourceBranchId: parseInt($('#sourceBranch').val(), 10), targetCustId: parseInt($('#targetCust').val(), 10), sessionId: cfg.token, lines: lines };
                bootbox.confirm('Create this stock transfer? The source warehouse stock, batches and reservations will be reduced and the target warehouse will receive the stock.', function (ok) {
                    if (!ok || saving || finished) return;
                    saving = true;
                    $('#btnSave').prop('disabled', true);
                    loading();
                    call('saveTransfer', { request: request }, function (r) {
                        Unloading();
                        saving = false;
                        if (r.ok || r.salesDone) {
                            // The same page token can no longer be used, so the form is closed once the invoice exists.
                            finished = true;
                            $('#sourceBranch, #targetCust, #transferItems .qty-input').prop('disabled', true);
                            showMessage(r.ok ? 'success' : 'danger', r.ok
                                ? r.message + ' (Sales ID ' + r.salesId + ', Purchase ID ' + r.purchaseId + ')'
                                : r.message);
                            loadTransfers();
                            recalc();
                            return;
                        }
                        showMessage('danger', r.message || 'The transfer could not be saved.');
                        recalc();
                    }, function () {
                        Unloading();
                        saving = false;
                        recalc();
                        showMessage('danger', 'The transfer could not be saved. Check the transfers list below before trying again.');
                        loadTransfers();
                    });
                });
            });

            loadTransfers();
            recalc();
        });
    </script>
    <% } %>
</body>
</html>
