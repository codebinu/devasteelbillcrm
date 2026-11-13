<%@ Page Language="C#" AutoEventWireup="true" CodeFile="view_sales_order.aspx.cs" Inherits="web_sales_view_sales_order" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>View Sales Order | Invoice Me</title>
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
        .tab-empty { text-align: center; color: #888; padding: 30px 0; }
        .nav-tabs > li.active > a, .nav-tabs > li.active > a:hover { border-top: 3px solid #26b99a; font-weight: bold; color: #333; }
        .tab-pane { padding-top: 15px; }
        .tabs-scroll { overflow-x: auto; }
        #reservedMessage .alert { margin-bottom: 10px; }
        #tabReserved .sub-note, #tabProduction .sub-note { display: block; color: #777; font-size: 11px; }
        #tabReserved .bom-list, #productionModal .bom-list { margin: 5px 0 0 0; padding-left: 16px; font-size: 12px; }
        #productionMessage .alert { margin-bottom: 10px; }
        #tabReserved .res-actions .btn { display: block; margin-bottom: 4px; white-space: nowrap; }
        #tabReserved .link-action { display: block; font-size: 11px; margin-top: 2px; white-space: nowrap; }
        #tabReserved .raw-table .link-action { display: inline-block; margin-right: 8px; }
        #tabReserved .release-batch { font-size: 11px; white-space: nowrap; }
        #tabReserved.busy a { pointer-events: none; opacity: .65; }
        #tabReserved th.num, #tabReserved td.num { text-align: right; white-space: nowrap; }
        #tabReserved thead th { vertical-align: middle; }
        #tabReserved td.short { color: #a94442; font-weight: 600; }
        #tabReserved .stock-toggle, #tabReserved .alloc-toggle { display: block; margin-top: 3px; font-size: 11px; }
        #tabReserved .stock-box { margin: 4px 0 0 0; padding: 4px 6px; background: #f9f9f9; border: 1px solid #e6e6e6; border-radius: 3px; font-size: 11px; color: #555; }
        #tabReserved tr.raw-row > td { background: #fafafa; border-top: 0; }
        #tabReserved .raw-head { margin-bottom: 6px; color: #333; }
        #tabReserved .raw-table { margin-bottom: 0; background: #fff; }
        #tabReserved .raw-table > thead > tr > th, #tabReserved .raw-table > tbody > tr > td { padding: 4px 8px; font-size: 12px; vertical-align: middle; }
        #tabReserved .raw-table .res-actions .btn { display: inline-block; margin-right: 4px; }
        #tabReserved.busy .btn { pointer-events: none; opacity: .65; }
        #tabReserved .comp-actions { margin: 3px 0 2px 0; }
        #tabReserved .comp-actions .btn { margin-right: 4px; }
        #tabReserved .bom-list > li { margin-bottom: 8px; }
        #tabReserved .alloc-box { margin: 4px 0 0 0; padding: 4px 6px; background: #f9f9f9; border: 1px solid #e6e6e6; border-radius: 3px; }
        #tabReserved .alloc-box table { margin-bottom: 0; font-size: 11px; }
        #tabReserved .alloc-box table > thead > tr > th, #tabReserved .alloc-box table > tbody > tr > td { padding: 2px 5px; }
        #batchModal .pick-summary { margin-bottom: 10px; }
        #batchModal .pick-summary .info-row { padding: 3px 0; }
        #batchModal .batch-qty { width: 110px; text-align: right; }
        #batchModal .has-error .batch-qty { border-color: #a94442; }
        #batchModal .batch-err { display: block; color: #a94442; font-size: 11px; }
        #batchModal .pick-totals { float: left; text-align: left; line-height: 30px; font-weight: 600; }
        #batchModal.processing .modal-body, #batchModal.processing .modal-footer .pick-totals { opacity: .6; }
        #batchModal .batch-table-wrap { max-height: 320px; overflow: auto; }
    </style>

    <script type="text/javascript">
        $(document).ready(function () {
            if (!$.cookie("invntrystaffBranchId")) {
                location.href = "../dashboard.aspx";
                return false;
            }
            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " &copy;");
            $('#soTabs a').click(function (e) {
                e.preventDefault();
                $(this).tab('show');
                $('#statusActionsRow').toggle($(this).attr('href') === '#tabItems');
                if ($(this).attr('href') === '#tabNotes') {
                    loadRemarks();
                }
                if ($(this).attr('href') === '#tabReserved') {
                    loadReserved();
                }
                if ($(this).attr('href') === '#tabProduction') {
                    loadProduction();
                }
            });

            function loadRemarks() {
                var panel = $('#tabNotes');
                if (!panel.length || panel.data('loaded') || panel.data('loading')) {
                    return;
                }

                panel.data('loading', true);
                $('#remarksLoading').text('Loading notes and remarks...');
                $.ajax({
                    type: 'POST',
                    url: 'view_sales_order.aspx/LoadRemarks',
                    data: JSON.stringify({ smoId: parseInt(panel.attr('data-order-id'), 10) }),
                    contentType: 'application/json; charset=utf-8',
                    dataType: 'json',
                    success: function (response) {
                        panel.data('loading', false).data('loaded', true);
                        $('#remarksInput').val(response.d || '');
                        $('#remarksLoading').hide();
                        $('#remarksEditor').show();
                    },
                    error: function () {
                        panel.data('loading', false);
                        $('#remarksLoading').html('Unable to load notes and remarks. <button type="button" id="retryRemarks" class="btn btn-default btn-xs">Retry</button>');
                    }
                });
            }

            $('#tabNotes').on('click', '#retryRemarks', loadRemarks);
            $('#tabNotes').on('click', '#saveRemarks', function () {
                var button = $(this);
                button.prop('disabled', true);
                $('#remarksStatus').removeClass('text-danger text-success').text('Saving...');
                $.ajax({
                    type: 'POST',
                    url: 'view_sales_order.aspx/SaveRemarks',
                    data: JSON.stringify({
                        smoId: parseInt($('#tabNotes').attr('data-order-id'), 10),
                        remark: $('#remarksInput').val()
                    }),
                    contentType: 'application/json; charset=utf-8',
                    dataType: 'json',
                    success: function (response) {
                        if (response.d) {
                            $('#remarksStatus').removeClass('text-danger').addClass('text-success').text('Notes and remarks saved.');
                        } else {
                            $('#remarksStatus').removeClass('text-success').addClass('text-danger').text('Unable to save notes and remarks. Please try again.');
                        }
                    },
                    error: function () {
                        $('#remarksStatus').removeClass('text-success').addClass('text-danger').text('Unable to save notes and remarks. Please try again.');
                    },
                    complete: function () {
                        button.prop('disabled', false);
                    }
                });
            });

            var reservedBusy = false;

            function esc(value) {
                return $('<div>').text(value == null ? '' : String(value)).html();
            }

            function num(value) {
                return String(Math.round((Number(value) || 0) * 10000) / 10000);
            }

            function showReservedMessage(ok, text) {
                $('#reservedMessage').html('<div class="alert ' + (ok ? 'alert-success' : 'alert-danger') + '">' + esc(text) + '</div>');
            }

            var uiState = { open: {} };
            var reservedCanAct = false;

            function allocHtml(list, key, title, sioId) {
                if (!list || !list.length) {
                    return '';
                }
                var isOpen = !!uiState.open[key];
                var total = 0;
                var rows = $.map(list, function (a) {
                    total += Number(a.qty) || 0;
                    var priority = reservedCanAct
                        ? '<input type="number" class="priority-input" min="0" max="999" step="1" value="' + (parseInt(a.priority, 10) || 0) + '" data-orig="' + (parseInt(a.priority, 10) || 0) + '" data-sio="' + sioId + '" data-batch="' + a.batchId + '" style="width: 60px;" title="Higher priority is used first for invoicing and production. Press Enter or leave the field to save." />'
                        : esc(a.priority || 0);
                    var release = reservedCanAct
                        ? '<a href="#" class="release-batch" data-sio="' + sioId + '" data-batch="' + a.batchId + '" data-no="' + esc(a.batchNo) + '" data-qty="' + a.qty + '" data-uom="' + esc(a.uom) + '"><i class="fa fa-unlock"></i> Release</a>'
                        : '';
                    return '<tr><td>' + esc(a.warehouse || '-') + '</td><td>' + esc(a.batchNo) + '</td><td style="text-align: right;">' + num(a.qty) + '</td><td>' + esc(a.uom) + '</td>'
                        + '<td>' + priority + '</td>'
                        + '<td><span class="label label-success">' + esc(a.status) + '</span></td><td>' + release + '</td></tr>';
                }).join('');
                var noun = list.length === 1 ? 'batch' : 'batches';
                return '<a href="#" class="alloc-toggle" data-key="' + key + '"><i class="fa fa-' + (isOpen ? 'caret-down' : 'caret-right') + '"></i> ' + esc(title) + ': ' + num(total) + ' ' + esc(list[0].uom) + ' in ' + list.length + ' ' + noun + '</a>'
                    + '<div class="alloc-box" style="' + (isOpen ? '' : 'display: none;') + '"><table class="table table-bordered"><thead><tr><th>Warehouse</th><th>Batch</th><th style="text-align: right;">Qty reserved</th><th>UOM</th><th>Priority</th><th>Status</th><th></th></tr></thead><tbody>' + rows + '</tbody></table></div>';
            }

            // One main button per item: Reserve while stock can still be added, otherwise Release. Less common actions are small links under it.
            function actionButtons(canAct, canReserve, canUnreserve, canPick, sioId, compItmId, available, name, uom) {
                if (!canAct) {
                    return '';
                }
                var attrs = ' data-sio="' + sioId + '" data-comp="' + compItmId + '" data-name="' + esc(name) + '" data-uom="' + esc(uom) + '"';
                var html = '';
                if (canReserve) {
                    html += '<button type="button" class="btn btn-xs btn-success reserve-btn"' + attrs + ' data-qty="' + available + '" title="Reserve the oldest stock in the order\'s warehouse"><i class="fa fa-lock"></i> Reserve ' + num(available) + ' ' + esc(uom) + '</button>';
                } else if (canUnreserve) {
                    html += '<button type="button" class="btn btn-xs btn-warning unreserve-btn"' + attrs + ' title="Release everything reserved for this order"><i class="fa fa-unlock"></i> Release</button>';
                }
                var links = '';
                if (canPick) {
                    links += '<a href="#" class="link-action pick-btn"' + attrs + '><i class="fa fa-th-list"></i> Choose warehouse / batches</a>';
                }
                if (canReserve && canUnreserve) {
                    links += '<a href="#" class="link-action unreserve-btn"' + attrs + '><i class="fa fa-unlock"></i> Release all</a>';
                }
                return html + links;
            }

            // Raw materials for the quantity that has to be produced, shown as a small table under the item row.
            function rawMaterialRow(row, canAct) {
                if (!row.hasBom || !(row.needsProduction > 0 || $.grep(row.bom, function (c) { return c.reserved > 0; }).length)) {
                    return '';
                }
                var uom = ' ' + esc(row.uom);
                var count = row.bom.length + ' raw material' + (row.bom.length === 1 ? '' : 's');
                var head = row.needsProduction > 0
                    ? 'Raw material needed to produce the <strong>' + num(row.needsProduction) + uom + '</strong> that is short (' + count + ')'
                    : 'Raw material still reserved for this order (' + count + ') &mdash; no production is needed any more';
                var body = $.map(row.bom, function (c) {
                    var u = ' ' + esc(c.uom);
                    var name = '<strong>' + esc(c.name) + '</strong>' + (c.code ? ' <span class="text-muted">(' + esc(c.code) + ')</span>' : '');
                    if (c.issue) {
                        return '<tr><td>' + name + '</td><td colspan="4"><span class="text-danger">' + esc(c.issue) + '</span></td><td></td></tr>';
                    }
                    var note = '<span class="sub-note">Uses ' + num(c.perUnit) + ' ' + esc(c.uom) + ' for each ' + esc(row.uom) + '</span>'
                        + allocHtml(c.allocations, 'c' + row.sioId + '-' + c.itmId, 'Reservation details', row.sioId);
                    var state = c.shortage > 0
                        ? '<span class="text-danger">Short by ' + num(c.shortage) + u + '</span>'
                        : (c.surplus > 0 ? '<span class="text-warning">' + num(c.surplus) + u + ' reserved more than needed &mdash; unreserve the surplus</span>'
                            : (c.required > 0 && c.reserved >= c.required ? '<span class="text-success">Fully reserved</span>' : ''));
                    var actions = actionButtons(canAct, c.canReserve, c.canUnreserve, c.canPick, row.sioId, c.itmId, c.available, c.name, c.uom);
                    return '<tr><td>' + name + note + '</td>'
                        + '<td class="num">' + num(c.required) + u + '</td><td class="num">' + num(c.reserved) + u + '</td><td class="num">' + num(c.free) + u + '</td>'
                        + '<td>' + state + '</td><td><div class="res-actions">' + actions + '</div></td></tr>';
                }).join('');
                return '<tr class="raw-row"><td></td><td colspan="9"><div class="raw-head">' + head + '</div>'
                    + '<table class="table table-bordered raw-table"><thead><tr><th>Raw material</th><th class="num">Needed</th><th class="num">Reserved</th><th class="num">Available</th><th>Status</th><th>Actions</th></tr></thead>'
                    + '<tbody>' + body + '</tbody></table></td></tr>';
            }

            // One plain-language status per order line, derived from the figures the server already sends.
            function lineStatus(r) {
                if (!r.ordered) {
                    return { cls: 'label-default', text: 'Not available' };
                }
                if (r.required <= 0) {
                    return { cls: 'label-success', text: 'Delivered' };
                }
                if (r.needsProduction > 0) {
                    if (r.available > 0) {
                        return { cls: 'label-warning', text: 'Reserve stock first' };
                    }
                    return r.canProduce ? { cls: 'label-warning', text: 'Needs production' } : { cls: 'label-danger', text: 'Short' };
                }
                if (r.remaining > 0) {
                    return r.reservedThis > 0 ? { cls: 'label-info', text: 'Partly reserved' } : { cls: 'label-default', text: 'Not reserved' };
                }
                return { cls: 'label-success', text: 'Fully reserved' };
            }

            function reservedRowHtml(r, canAct) {
                var st = lineStatus(r);
                var uom = ' ' + esc(r.uom);
                var unavailable = !r.ordered;
                function cell(v, cls) { return '<td class="num' + (cls ? ' ' + cls : '') + '">' + (unavailable ? '<span class="text-muted">-</span>' : num(v)) + '</td>'; }

                var stockKey = 's' + r.sioId;
                var stockOpen = !!uiState.open[stockKey];
                var details = '';
                if (!unavailable) {
                    details = '<a href="#" class="stock-toggle" data-key="' + stockKey + '"><i class="fa fa-' + (stockOpen ? 'caret-down' : 'caret-right') + '"></i> Stock details</a>'
                        + '<div class="stock-box" style="' + (stockOpen ? '' : 'display: none;') + '">'
                        + '<div>In stock: <strong>' + num(r.physical) + uom + '</strong></div>'
                        + '<div>Reserved by other orders: ' + num(r.reservedOthers) + uom + '</div>'
                        + (Math.abs(r.branchStock - r.physical) > 0.0005 ? '<div>Branch total: ' + num(r.branchStock) + uom + '</div>' : '')
                        + '</div>';
                }
                var item = '<strong>' + esc(r.itemName) + '</strong>'
                    + (r.itemCode ? ' <span class="text-muted">(' + esc(r.itemCode) + ')</span>' : '')
                    + (r.uom ? ' <span class="text-muted">&middot; ' + esc(r.uom) + '</span>' : '')
                    + details
                    + allocHtml(r.allocations, 'i' + r.sioId, 'Reservation details', r.sioId);

                var note = '';
                if (r.message) {
                    note += '<span class="sub-note text-danger">' + esc(r.message) + '</span>';
                }
                if (r.needsProduction > 0 && !r.canProduce && r.productionMessage) {
                    note += '<span class="sub-note text-danger">' + esc(r.productionMessage) + '</span>';
                }
                var status = '<span class="label ' + st.cls + '">' + st.text + '</span>' + note;

                var actions;
                if (!canAct) {
                    actions = '<span class="text-muted">View only</span>';
                } else {
                    var buttons = actionButtons(true, r.canReserve, r.canUnreserve, r.canPick, r.sioId, 0, r.available, r.itemName, r.uom);
                    if (r.needsProduction > 0) {
                        buttons += '<button type="button" class="btn btn-xs btn-primary produce-btn" data-sio="' + r.sioId + '" data-qty="' + r.needsProduction + '"'
                            + ' data-name="' + esc(r.itemName) + '" data-uom="' + esc(r.uom) + '"' + (r.canProduce ? '' : ' disabled') + '>'
                            + '<i class="fa fa-cogs"></i> Produce ' + num(r.needsProduction) + ' ' + esc(r.uom) + '</button>';
                    }
                    actions = buttons ? '<div class="res-actions">' + buttons + '</div>' : '<span class="text-muted">-</span>';
                }
                return '<tr>'
                    + '<td>' + r.sl + '</td>'
                    + '<td>' + item + '</td>'
                    + cell(r.ordered) + cell(r.delivered) + cell(r.required)
                    + cell(r.reservedThis) + cell(r.needsProduction, r.needsProduction > 0 ? 'short' : '') + cell(r.free)
                    + '<td>' + status + '</td>'
                    + '<td>' + actions + '</td>'
                    + '</tr>'
                    + rawMaterialRow(r, canAct);
            }

            function loadReserved(fromAction) {
                var panel = $('#tabReserved');
                if (!panel.length || panel.data('loading') || (reservedBusy && fromAction !== true)) {
                    return;
                }

                panel.data('loading', true);
                if (!panel.data('loaded')) {
                    $('#reservedLoading').show().html('<i class="fa fa-spinner fa-spin"></i> Loading reserved items...');
                }
                $.ajax({
                    type: 'POST',
                    url: 'view_sales_order.aspx/LoadReserved',
                    data: JSON.stringify({ smoId: parseInt(panel.attr('data-order-id'), 10) }),
                    contentType: 'application/json; charset=utf-8',
                    dataType: 'json',
                    success: function (response) {
                        var d = response.d;
                        if (!d || !d.ok) {
                            $('#reservedGrid').hide();
                            $('#reservedLoading').show().html(esc((d && d.message) || 'Unable to load reserved items.') + ' <button type="button" id="retryReserved" class="btn btn-default btn-xs">Retry</button>');
                            return;
                        }
                        panel.data('loaded', true);
                        reservedCanAct = !!d.canAct;
                        var html = $.map(d.rows, function (r) { return reservedRowHtml(r, d.canAct); }).join('');
                        $('#reservedBody').html(html || '<tr><td colspan="10" style="text-align: center">No items found for this sales order.</td></tr>');
                        $('#reservedLoading').hide();
                        $('#reservedGrid').show();
                    },
                    error: function () {
                        $('#reservedLoading').show().html('Unable to load reserved items. <button type="button" id="retryReserved" class="btn btn-default btn-xs">Retry</button>');
                    },
                    complete: function () {
                        panel.data('loading', false);
                        if (fromAction === true) {
                            panel.removeClass('busy');
                            reservedBusy = false;
                        }
                    }
                });
            }

            function runStockAction(method, data, confirmText) {
                if (reservedBusy || !window.confirm(confirmText)) {
                    return;
                }
                reservedBusy = true;
                data.smoId = parseInt($('#tabReserved').attr('data-order-id'), 10);
                $('#tabReserved').addClass('busy').find('button').prop('disabled', true);
                $('#reservedMessage').html('<div class="alert alert-info"><i class="fa fa-spinner fa-spin"></i> Processing, please wait...</div>');
                $.ajax({
                    type: 'POST',
                    url: 'view_sales_order.aspx/' + method,
                    data: JSON.stringify(data),
                    contentType: 'application/json; charset=utf-8',
                    dataType: 'json',
                    success: function (response) {
                        var d = response.d || {};
                        showReservedMessage(!!d.ok, d.message || 'The request could not be completed.');
                    },
                    error: function () {
                        showReservedMessage(false, 'The request failed. Please check the grid and try again.');
                    },
                    complete: function () {
                        loadReserved(true);
                    }
                });
            }

            $('#tabReserved').on('click', '#retryReserved', function () { loadReserved(); });
            $('#tabReserved').on('keydown', '.priority-input', function (e) {
                if (e.which === 13) {
                    e.preventDefault();
                    $(this).blur();
                }
            });
            $('#tabReserved').on('change', '.priority-input', function () {
                var input = $(this);
                var value = parseInt(input.val(), 10);
                if (reservedBusy) {
                    input.val(input.attr('data-orig'));
                    return;
                }
                if (isNaN(value) || value < 0 || value > 999) {
                    input.val(input.attr('data-orig'));
                    showReservedMessage(false, 'Priority must be a whole number between 0 and 999.');
                    return;
                }
                reservedBusy = true;
                $('#tabReserved').addClass('busy').find('button, input').prop('disabled', true);
                $.ajax({
                    type: 'POST',
                    url: 'view_sales_order.aspx/SetReservationPriority',
                    data: JSON.stringify({ smoId: parseInt($('#tabReserved').attr('data-order-id'), 10), sioId: parseInt(input.attr('data-sio'), 10), batchId: parseInt(input.attr('data-batch'), 10), priority: value }),
                    contentType: 'application/json; charset=utf-8',
                    dataType: 'json',
                    success: function (response) {
                        var d = response.d || {};
                        showReservedMessage(!!d.ok, d.message || 'The request could not be completed.');
                    },
                    error: function () {
                        showReservedMessage(false, 'The request failed. Please check the grid and try again.');
                    },
                    complete: function () {
                        loadReserved(true);
                    }
                });
            });
            $('#tabReserved').on('click', '.stock-toggle', function (e) {
                e.preventDefault();
                var box = $(this).next('.stock-box').toggle();
                uiState.open[$(this).attr('data-key')] = box.is(':visible');
                $(this).find('i').attr('class', 'fa fa-' + (box.is(':visible') ? 'caret-down' : 'caret-right'));
            });
            $('#tabReserved').on('click', '.alloc-toggle', function (e) {
                e.preventDefault();
                var box = $(this).next('.alloc-box').toggle();
                uiState.open[$(this).attr('data-key')] = box.is(':visible');
                $(this).find('i').attr('class', 'fa fa-' + (box.is(':visible') ? 'caret-down' : 'caret-right'));
            });
            $('#tabReserved').on('click', '.reserve-btn', function () {
                var b = $(this);
                runStockAction('ReserveItem', { sioId: parseInt(b.attr('data-sio'), 10), compItmId: parseInt(b.attr('data-comp'), 10) || 0, expectedQty: Number(b.attr('data-qty')) },
                    'Reserve ' + num(b.attr('data-qty')) + ' ' + b.attr('data-uom') + ' of "' + b.attr('data-name') + '" for this order (oldest stock first, order warehouse)?\n'
                    + 'Use "Choose warehouse / batches" to pick another warehouse or specific batches.');
            });
            $('#tabReserved').on('click', '.unreserve-btn', function (e) {
                e.preventDefault();
                var b = $(this);
                runStockAction('UnreserveItem', { sioId: parseInt(b.attr('data-sio'), 10), compItmId: parseInt(b.attr('data-comp'), 10) || 0 },
                    'Release everything reserved for "' + b.attr('data-name') + '" on this order (all warehouses and batches)? Stock quantities are not changed.');
            });
            $('#tabReserved').on('click', '.release-batch', function (e) {
                e.preventDefault();
                var b = $(this);
                runStockAction('UnreserveBatch', { sioId: parseInt(b.attr('data-sio'), 10), batchId: parseInt(b.attr('data-batch'), 10) },
                    'Release ' + num(b.attr('data-qty')) + ' ' + b.attr('data-uom') + ' reserved in batch ' + b.attr('data-no') + '? Stock quantities are not changed.');
            });
            $('#tabReserved').on('click', '.produce-btn', function () {
                var b = $(this);
                runStockAction('ProduceItem', { sioId: parseInt(b.attr('data-sio'), 10), expectedQty: Number(b.attr('data-qty')) },
                    'Produce ' + num(b.attr('data-qty')) + ' ' + b.attr('data-uom') + ' of "' + b.attr('data-name') + '"?\n'
                    + 'The raw material is taken from the batches reserved for this order first, then from the oldest stock in the order warehouse. '
                    + 'The finished stock is reserved for this order.');
            });

            // ---- Warehouse / batch picker (finished items and BOM components) ----
            var pick = null;

            function pickWarehouse() {
                var found = null;
                $.each(pick.data.warehouses, function (i, w) {
                    if (w.branchId === pick.warehouseId) {
                        found = w;
                    }
                });
                return found;
            }

            function pickTotal() {
                var total = 0;
                $.each(pick.selected, function (id, q) { total += q; });
                return Math.round(total * 1000) / 1000;
            }

            function pickMessage(ok, text) {
                $('#batchModalMessage').html(text ? '<div class="alert ' + (ok ? 'alert-success' : 'alert-danger') + '" style="margin-bottom: 10px;">' + esc(text) + '</div>' : '');
            }

            function pickBusy(on) {
                pick.busy = on;
                $('#batchModal').toggleClass('processing', on);
                $('#batchModal .modal-footer button, #batchModal input, #batchModal select').prop('disabled', on);
                $('#batchSpinner').toggle(on);
                if (!on) {
                    $('#batchBody .batch-qty').each(function () {
                        $(this).prop('disabled', Number($(this).attr('data-max')) <= 0);
                    });
                    pickRefreshTotals();
                }
            }

            function pickRefreshTotals() {
                var d = pick.data, total = pickTotal(), over = false, errors = 0;
                $('#batchBody tr').each(function () {
                    var row = $(this), id = row.attr('data-batch'), input = row.find('.batch-qty');
                    var raw = $.trim(input.val()), v = raw === '' ? 0 : Number(raw), err = '';
                    if (isNaN(v) || v < 0) {
                        err = 'Enter a valid quantity.';
                    } else if (v > Number(input.attr('data-max')) + 0.0005) {
                        err = 'Only ' + num(input.attr('data-max')) + ' ' + d.uom + ' available in this batch.';
                    }
                    row.toggleClass('has-error', !!err).find('.batch-err').text(err);
                    if (err) {
                        errors++;
                    }
                });
                var left = Math.round((d.remaining - total) * 1000) / 1000;
                if (left < -0.0005) {
                    over = true;
                }
                var other = 0;
                $.each(pick.selected, function (id, q) {
                    if (q > 0 && pick.batchWarehouse[id] !== pick.warehouseId) {
                        other++;
                    }
                });
                $('#batchTotals').html('Selected: <span class="' + (over ? 'text-danger' : 'text-success') + '">' + num(total) + ' ' + esc(d.uom) + '</span> &nbsp;|&nbsp; Remaining: <span class="' + (over ? 'text-danger' : '') + '">'
                    + num(left) + ' ' + esc(d.uom) + '</span>' + (other > 0 ? '<span class="sub-note" style="line-height: 14px;">Includes ' + other + ' batch(es) from other warehouses</span>' : ''));
                $('#batchOverMessage').text(over ? 'The selected quantity exceeds the remaining requirement (' + num(d.remaining) + ' ' + d.uom + ').' : '').toggle(over);
                $('#batchSubmit').prop('disabled', pick.busy || over || errors > 0 || total <= 0);
            }

            function renderPicker() {
                var d = pick.data;
                var warehouseOptions = $.map(d.warehouses, function (w) {
                    return '<option value="' + w.branchId + '"' + (w.branchId === pick.warehouseId ? ' selected' : '') + '>' + esc(w.name) + (w.isHome ? ' (order warehouse)' : '')
                        + ' - ' + num(w.available) + ' ' + esc(d.uom) + ' available</option>';
                }).join('');
                function info(k, v) { return '<div class="info-row"><span class="k">' + k + '</span><span class="v">' + v + '</span></div>'; }
                $('#batchModalTitle').text(d.isComponent ? 'Reserve Raw Material: ' + d.itemName : 'Select Warehouse & Batches: ' + d.itemName);
                var summary = '<div class="pick-summary row"><div class="col-sm-6">'
                    + info('Item', esc(d.itemName) + (d.itemCode ? ' (' + esc(d.itemCode) + ')' : ''))
                    + (d.isComponent ? info('BOM component of', esc(d.parentName)) : '')
                    + '</div><div class="col-sm-6">'
                    + info(d.isComponent ? 'Required for production' : 'Ordered', num(d.required) + ' ' + esc(d.uom))
                    + info('Already reserved', num(d.reservedThis) + ' ' + esc(d.uom))
                    + info('Remaining to reserve', num(d.remaining) + ' ' + esc(d.uom))
                    + '</div></div>';
                var wh = '<div class="form-group"><label for="batchWarehouse">Warehouse</label>'
                    + '<select id="batchWarehouse" class="form-control">' + (warehouseOptions || '<option value="0">No warehouse available</option>') + '</select></div>'
                    + '<div id="batchModalMessage" role="status" aria-live="polite"></div>';
                var w = pickWarehouse();
                var rows = '';
                if (w) {
                    rows = $.map(w.batches, function (b, i) {
                        var saved = pick.selected[b.batchId];
                        return '<tr data-batch="' + b.batchId + '"><td>' + (i + 1) + '</td><td>' + esc(w.name) + '</td><td>' + esc(b.batchNo) + '</td>'
                            + '<td>' + (b.batchDate ? esc(b.batchDate) : '<span class="text-muted">-</span>') + '</td>'
                            + '<td style="text-align: right;">' + num(b.physical) + '</td>'
                            + '<td style="text-align: right;">' + num(b.reserved) + (b.mine > 0 ? '<span class="sub-note">this order: ' + num(b.mine) + '</span>' : '') + '</td>'
                            + '<td style="text-align: right;">' + num(b.available) + '</td>'
                            + '<td style="text-align: right;"><input type="number" class="form-control input-sm batch-qty" min="0" step="any" data-batch="' + b.batchId + '" data-max="' + b.available + '"'
                            + (b.available <= 0 ? ' disabled' : '') + (saved > 0 ? ' value="' + num(saved) + '"' : '') + ' /><span class="batch-err"></span></td></tr>';
                    }).join('');
                }
                var table = '<div class="batch-table-wrap"><table class="table table-striped jambo_table table-bordered" style="margin-bottom: 0;"><thead style="background-color: #f1eeee; color: #525252"><tr>'
                    + '<th>#</th><th>Warehouse</th><th>Batch No</th><th>Batch Date</th><th style="text-align: right;">Physical Stock</th><th style="text-align: right;">Reserved</th>'
                    + '<th style="text-align: right;">Available</th><th style="text-align: right;">Qty to Reserve (' + esc(d.uom) + ')</th></tr></thead>'
                    + '<tbody id="batchBody">' + (rows || '<tr><td colspan="8" style="text-align: center;">No batches with stock in this warehouse.</td></tr>') + '</tbody></table></div>'
                    + '<p class="text-danger" id="batchOverMessage" style="display: none; margin: 8px 0 0 0;"></p>'
                    + '<p class="text-muted" style="font-size: 11px; margin: 8px 0 0 0;">Quantities are in ' + esc(d.uom) + '. Leave all quantities empty and use Auto-fill to allocate oldest batches first. '
                    + 'Selections are kept when you switch warehouse.</p>';
                $('#batchModalBody').html(summary + wh + table);
                $('#batchRelease').toggle(d.reservedThis > 0);
                $('#batchFooterButtons').show();
                pickRefreshTotals();
            }

            function loadPicker(keepMessage) {
                $('#batchModalBody').html('<div class="tab-empty"><i class="fa fa-spinner fa-spin"></i> Loading warehouse stock...</div>');
                $('#batchFooterButtons').hide();
                $('#batchTotals').empty();
                var req = pick;
                $.ajax({
                    type: 'POST',
                    url: 'view_sales_order.aspx/LoadReserveOptions',
                    data: JSON.stringify({ smoId: parseInt($('#tabReserved').attr('data-order-id'), 10), sioId: req.sioId, compItmId: req.compItmId }),
                    contentType: 'application/json; charset=utf-8',
                    dataType: 'json',
                    success: function (response) {
                        if (pick !== req) {
                            return;
                        }
                        var d = response.d;
                        if (!d || !d.ok) {
                            $('#batchModalBody').html('<p class="text-danger">' + esc((d && d.message) || 'Unable to load warehouse stock.') + '</p>');
                            return;
                        }
                        req.data = d;
                        req.selected = {};
                        req.batchWarehouse = {};
                        var first = null, home = null;
                        $.each(d.warehouses, function (i, w) {
                            $.each(w.batches, function (j, b) { req.batchWarehouse[b.batchId] = w.branchId; });
                            if (w.isHome) { home = w; }
                            if (!first && w.available > 0) { first = w; }
                        });
                        var keep = d.warehouses.filter(function (w) { return w.branchId === req.warehouseId; }).length > 0;
                        if (!keep) {
                            req.warehouseId = home && home.available > 0 ? home.branchId : (first ? first.branchId : (home ? home.branchId : 0));
                        }
                        renderPicker();
                        if (keepMessage) {
                            pickMessage(keepMessage.ok, keepMessage.text);
                        }
                    },
                    error: function () {
                        if (pick === req) {
                            $('#batchModalBody').html('<p class="text-danger">Unable to load warehouse stock. Please close this window and try again.</p>');
                        }
                    }
                });
            }

            $('#tabReserved').on('click', '.pick-btn', function (e) {
                e.preventDefault();
                if (reservedBusy) {
                    return;
                }
                var b = $(this);
                pick = { sioId: parseInt(b.attr('data-sio'), 10), compItmId: parseInt(b.attr('data-comp'), 10) || 0, warehouseId: 0, busy: false, selected: {}, batchWarehouse: {} };
                $('#batchModalTitle').text('Select Warehouse & Batches: ' + b.attr('data-name'));
                $('#batchModal').removeClass('processing').modal('show');
                loadPicker();
            });

            $('#batchModal').on('hidden.bs.modal', function () { pick = null; });
            $('#batchModal').on('change', '#batchWarehouse', function () {
                pick.warehouseId = parseInt($(this).val(), 10) || 0;
                renderPicker();
            });
            $('#batchModal').on('input change', '.batch-qty', function () {
                var v = Number($(this).val());
                var id = $(this).attr('data-batch');
                if ($.trim($(this).val()) !== '' && !isNaN(v) && v > 0) {
                    pick.selected[id] = v;
                } else {
                    delete pick.selected[id];
                }
                pickRefreshTotals();
            });
            $('#batchModal').on('click', '#batchClear', function () {
                if (pick.busy) { return; }
                pick.selected = {};
                renderPicker();
            });
            $('#batchModal').on('click', '#batchFifo', function () {
                if (pick.busy) { return; }
                var w = pickWarehouse();
                if (!w) { return; }
                $.each(w.batches, function (i, b) { delete pick.selected[b.batchId]; });
                var left = Math.floor((pick.data.remaining - pickTotal()) * 1000) / 1000;
                $.each(w.batches, function (i, b) {
                    var q = Math.floor(Math.min(b.available, left) * 1000) / 1000;
                    if (q > 0) {
                        pick.selected[b.batchId] = q;
                        left = Math.round((left - q) * 1000) / 1000;
                    }
                });
                renderPicker();
                if (pickTotal() <= 0) {
                    pickMessage(false, 'No stock is available to allocate in this warehouse (or the requirement is already covered by other selections).');
                }
            });

            function pickFinish(method, data, confirmText) {
                if (pick.busy || reservedBusy || (confirmText && !window.confirm(confirmText))) {
                    return;
                }
                var req = pick;
                reservedBusy = true;
                data.smoId = parseInt($('#tabReserved').attr('data-order-id'), 10);
                data.sioId = req.sioId;
                data.compItmId = req.compItmId;
                pickMessage(true, '');
                pickBusy(true);
                $.ajax({
                    type: 'POST',
                    url: 'view_sales_order.aspx/' + method,
                    data: JSON.stringify(data),
                    contentType: 'application/json; charset=utf-8',
                    dataType: 'json',
                    success: function (response) {
                        var d = response.d || {};
                        showReservedMessage(!!d.ok, d.message || 'The request could not be completed.');
                        reservedBusy = false;
                        pickBusy(false);
                        if (d.ok) {
                            $('#batchModal').modal('hide');
                        } else if (pick === req) {
                            loadPicker({ ok: false, text: d.message || 'The request could not be completed.' });
                        }
                        loadReserved();
                    },
                    error: function () {
                        reservedBusy = false;
                        pickBusy(false);
                        pickMessage(false, 'The request failed. Please check the grid and try again.');
                        loadReserved();
                    }
                });
            }

            $('#batchModal').on('click', '#batchSubmit', function () {
                var allocations = [];
                $.each(pick.selected, function (id, q) {
                    allocations.push({ batchId: parseInt(id, 10), qty: q });
                });
                if (!allocations.length) {
                    return;
                }
                pickFinish('ReserveBatches', { allocations: allocations }, null);
            });
            $('#batchModal').on('click', '#batchRelease', function () {
                pickFinish('UnreserveItem', {}, 'Release this order\'s existing reservations for "' + pick.data.itemName + '" (all warehouses and batches)?');
            });

            function totalsHtml(totals, field) {
                if (!totals.length) {
                    return '<span class="text-muted">0</span>';
                }
                return $.map(totals, function (t) { return esc(num(t[field])) + ' ' + esc(t.uom); }).join('<br />');
            }

            function summaryCard(title, html) {
                return '<div class="col-md-2 col-sm-4 col-xs-6"><div class="x_panel" style="padding: 10px;"><span class="sub-note" style="margin-bottom: 4px;">' + esc(title) + '</span>'
                    + '<strong style="font-size: 15px;">' + html + '</strong></div></div>';
            }

            function productionLineHtml(r, canAct) {
                var refs = r.references && r.references.length ? $.map(r.references, esc).join('<br />') : '<span class="text-muted">None</span>';
                var action = '<span class="text-muted">-</span>';
                if (r.canProduce) {
                    action = '<button type="button" class="btn btn-xs btn-primary production-entry-btn" data-sio="' + r.sioId + '"><i class="fa fa-cogs"></i> Produce ' + num(r.pending) + ' ' + esc(r.uom) + '</button>';
                } else if (canAct && r.produceMessage && r.pending > 0) {
                    action = '<button type="button" class="btn btn-xs btn-default production-entry-btn" data-sio="' + r.sioId + '"><i class="fa fa-info-circle"></i> Why not?</button>'
                        + '<span class="sub-note" style="max-width: 260px;">' + esc(r.produceMessage) + '</span>';
                }
                return '<tr>'
                    + '<td>' + r.sl + '</td>'
                    + '<td><strong>' + esc(r.itemName) + '</strong>' + (r.itemCode ? ' <span class="text-muted">(' + esc(r.itemCode) + ')</span>' : '') + (r.uom ? ' <span class="text-muted">&middot; ' + esc(r.uom) + '</span>' : '') + '</td>'
                    + '<td style="text-align: right; white-space: nowrap;">' + num(r.orderQty) + '</td>'
                    + '<td style="text-align: right; white-space: nowrap;">' + num(r.produced) + '</td>'
                    + '<td style="text-align: right; white-space: nowrap;">' + num(r.pending) + '</td>'
                    + '<td style="text-align: right; white-space: nowrap;">' + num(r.reserved) + '</td>'
                    + '<td>' + refs + '</td>'
                    + '<td><span class="label ' + esc(r.statusClass) + '">' + esc(r.status) + '</span></td>'
                    + '<td>' + action + '</td>'
                    + '</tr>';
            }

            function productionRowHtml(r) {
                var uom = ' ' + esc(r.uom);
                return '<tr>'
                    + '<td>' + r.sl + '</td>'
                    + '<td><strong>' + esc(r.docNo) + '</strong><span class="sub-note">Production #' + r.itpmId + '</span></td>'
                    + '<td><strong>' + esc(r.itemName) + '</strong>' + (r.itemCode ? '<span class="sub-note">' + esc(r.itemCode) + '</span>' : '') + '</td>'
                    + '<td style="text-align: right;">' + num(r.produced) + uom + '</td>'
                    + '<td style="text-align: right;">' + num(r.reserved) + uom + '</td>'
                    + '<td>' + esc(r.materialSummary) + '</td>'
                    + '<td>' + (r.batchNo ? esc(r.batchNo) : '<span class="text-muted">-</span>') + '</td>'
                    + '<td>' + (r.createdDate ? esc(r.createdDate) : '<span class="text-muted">Not recorded</span>') + '</td>'
                    + '<td><span class="label label-success" title="Derived: the production record and finished batch exist. No status is stored.">' + esc(r.status) + '</span></td>'
                    + '<td><button type="button" class="btn btn-xs btn-default production-view-btn" data-job="' + r.itpmId + '"><i class="fa fa-eye"></i> View Details</button>'
                    + (r.canUndo ? ' <button type="button" class="btn btn-xs btn-danger production-undo-btn" data-job="' + r.itpmId + '" data-ref="' + esc(r.docNo) + '"><i class="fa fa-undo"></i> Undo</button>'
                        : (r.undoMessage ? '<span class="sub-note text-muted">Cannot undo: ' + esc(r.undoMessage) + '</span>' : '')) + '</td>'
                    + '</tr>';
            }

            function loadProduction(keepMessage) {
                var panel = $('#tabProduction');
                if (!panel.length || panel.data('loading')) {
                    return;
                }

                panel.data('loading', true);
                if (keepMessage !== true) {
                    $('#productionMessage').empty();
                }
                if (!panel.data('loaded')) {
                    $('#productionLoading').show().html('<i class="fa fa-spinner fa-spin"></i> Loading production details...');
                }
                $.ajax({
                    type: 'POST',
                    url: 'view_sales_order.aspx/LoadProduction',
                    data: JSON.stringify({ smoId: parseInt(panel.attr('data-order-id'), 10) }),
                    contentType: 'application/json; charset=utf-8',
                    dataType: 'json',
                    success: function (response) {
                        var d = response.d;
                        if (!d || !d.ok) {
                            $('#productionContent').hide();
                            $('#productionLoading').show().html(esc((d && d.message) || 'Unable to load production details.') + ' <button type="button" id="retryProduction" class="btn btn-default btn-xs">Retry</button>');
                            return;
                        }
                        panel.data('loaded', true);
                        $('#productionSummary').html(
                            summaryCard('Sales order reference', esc(d.orderRef))
                            + summaryCard('Production status', '<span class="label ' + (d.status === 'Produced' ? 'label-success' : d.status === 'Pending production' ? 'label-warning' : d.status === 'Partially produced' ? 'label-info' : d.status === 'Over-produced' ? 'label-danger' : 'label-default') + '">' + esc(d.status) + '</span>')
                            + summaryCard('Produced', totalsHtml(d.totals, 'produced'))
                            + summaryCard('Pending', totalsHtml(d.totals, 'pending'))
                            + summaryCard('Production entries', d.totalJobs));
                        $('#productionLinesBody').html($.map(d.lines, function (r) { return productionLineHtml(r, d.canAct); }).join(''));
                        $('#productionLinesEmpty').toggle(d.lines.length === 0);
                        $('#productionLinesGrid').toggle(d.lines.length > 0);
                        $('#productionBody').html($.map(d.rows, productionRowHtml).join(''));
                        $('#productionEmpty').toggle(d.rows.length === 0);
                        $('#productionGrid').toggle(d.rows.length > 0);
                        $('#productionLoading').hide();
                        $('#productionContent').show();
                    },
                    error: function () {
                        $('#productionContent').hide();
                        $('#productionLoading').show().html('Unable to load production details. <button type="button" id="retryProduction" class="btn btn-default btn-xs">Retry</button>');
                    },
                    complete: function () {
                        panel.data('loading', false);
                    }
                });
            }

            function jobDetailHtml(d) {
                var uom = ' ' + esc(d.uom);
                function row(k, v) { return '<div class="info-row"><span class="k">' + esc(k) + '</span><span class="v">' + v + '</span></div>'; }
                function notRecorded() { return '<span class="text-muted">Not recorded</span>'; }
                var html = '<h5><strong>Production Information</strong></h5>'
                    + row('Production job', esc(d.docNo) + ' (#' + d.itpmId + ')')
                    + row('Sales order', '#' + esc($('#tabProduction').attr('data-order-id')) + ' (' + esc(d.orderRef) + ')')
                    + row('Finished item', esc(d.itemName) + (d.itemCode ? ' (' + esc(d.itemCode) + ')' : ''))
                    + row('Warehouse', d.branch ? esc(d.branch) : notRecorded())
                    + row('Planned quantity', notRecorded())
                    + row('Actual produced quantity', num(d.produced) + uom)
                    + row('Reserved for this order', num(d.reserved) + uom)
                    + row('Created', (d.createdDate ? esc(d.createdDate) : notRecorded()) + (d.createdBy ? ' by ' + esc(d.createdBy) : ''))
                    + row('Document date', d.docDate ? esc(d.docDate) : notRecorded())
                    + row('Completed', notRecorded())
                    + row('Status', '<span class="label label-success">' + esc(d.status) + '</span>');

                html += '<h5 style="margin-top: 15px;"><strong>Raw Materials Consumed</strong></h5>';
                if (!d.materials.length) {
                    html += '<p class="text-muted">No raw-material record exists for this job.</p>';
                } else {
                    html += '<div style="overflow-x: auto;"><table class="table table-striped jambo_table table-bordered"><thead style="background-color: #f1eeee; color: #525252"><tr>'
                        + '<th>Item</th><th style="text-align: right;">Quantity (per production record)</th><th>UOM</th><th>Source batch</th></tr></thead><tbody>'
                        + $.map(d.materials, function (m) {
                            return '<tr><td>' + esc(m.name) + (m.code ? ' (' + esc(m.code) + ')' : '') + '</td><td style="text-align: right;">' + num(m.quantity)
                                + '</td><td>' + esc(m.uom) + '</td><td>' + esc(m.batchNo) + '</td></tr>';
                        }).join('') + '</tbody></table></div>'
                        + '<p class="text-muted" style="font-size: 11px;">Required, reserved and remaining raw-material quantities are not stored per job, and no BOM snapshot exists, so only the recorded consumption is shown.</p>';
                }

                html += '<h5 style="margin-top: 15px;"><strong>Production Items (tbl_item_pro_items)</strong></h5>';
                if (!d.items || !d.items.length) {
                    html += '<p class="text-muted">No production item rows exist for this production.</p>';
                } else {
                    html += '<div style="overflow-x: auto;"><table class="table table-striped jambo_table table-bordered"><thead style="background-color: #f1eeee; color: #525252"><tr>'
                        + '<th>#</th><th>Type</th><th>Item</th><th>Batch</th><th style="text-align: right;">Quantity (batch UOM)</th><th style="text-align: right;">Unit cost</th></tr></thead><tbody>'
                        + $.map(d.items, function (it) {
                            return '<tr><td>' + it.Serial + '</td><td>' + (it.InputOutput === 1 ? 'Input (consumed)' : it.InputOutput === 2 ? 'Output (produced)' : esc(it.InputOutput))
                                + '</td><td>' + esc(it.ItemName) + (it.ItemCode ? ' (' + esc(it.ItemCode) + ')' : '') + '</td><td>' + esc(it.BatchNo) + ' (#' + it.BatchId + ')'
                                + '</td><td style="text-align: right;">' + num(it.Quantity) + '</td><td style="text-align: right;">' + num(it.Cost) + '</td></tr>';
                        }).join('') + '</tbody></table></div>';
                }

                html += '<h5 style="margin-top: 15px;"><strong>Finished Goods</strong></h5>'
                    + row('Finished item', esc(d.itemName))
                    + row('Planned / actual output', 'Not recorded / ' + num(d.produced) + uom)
                    + row('Finished batch', d.batchNo ? esc(d.batchNo) + ' (batch #' + d.batchId + ', stock #' + d.itbsId + ')' : notRecorded())
                    + row('Production date', d.createdDate ? esc(d.createdDate) : notRecorded())
                    + row('Reserved for this order', num(d.reserved) + uom)
                    + row('Remaining unreserved in batch', num(d.unreserved) + uom);

                html += '<h5 style="margin-top: 15px;"><strong>Production History</strong></h5>';
                html += '<ul class="bom-list" style="padding-left: 18px; font-size: 13px;">' + $.map(d.events, function (e) {
                    return '<li>' + (e.when ? esc(e.when) : 'Date not recorded') + ' &mdash; ' + esc(e.text) + (e.by ? ' (' + esc(e.by) + ')' : '') + '</li>';
                }).join('') + '</ul>'
                    + (d.movementNote ? '<p class="text-muted" style="font-size: 11px;">' + esc(d.movementNote) + '</p>' : '')
                    + '<p class="text-muted" style="font-size: 11px;">Only persisted records are listed. Start, completion and cancellation events are not recorded by the database.</p>';
                return html;
            }

            $('#tabProduction').on('click', '#retryProduction', loadProduction);
            $('#tabProduction').on('click', '.production-undo-btn', function () {
                var button = $(this);
                if (button.prop('disabled')) {
                    return;
                }
                if (!window.confirm('Undo production ' + button.attr('data-ref') + '?\n'
                    + 'The finished stock is removed, the raw material is returned and reserved for this order again, and the production record is deleted.')) {
                    return;
                }
                $('#tabProduction .production-undo-btn').prop('disabled', true);
                $.ajax({
                    type: 'POST',
                    url: 'view_sales_order.aspx/UndoProduction',
                    data: JSON.stringify({ smoId: parseInt($('#tabProduction').attr('data-order-id'), 10), itpmId: parseInt(button.attr('data-job'), 10) }),
                    contentType: 'application/json; charset=utf-8',
                    dataType: 'json',
                    success: function (response) {
                        var r = response.d || {};
                        $('#productionMessage').html('<div class="alert ' + (r.ok ? 'alert-success' : 'alert-danger') + '">' + esc(r.message || 'The production could not be undone.') + '</div>');
                    },
                    error: function () {
                        $('#productionMessage').html('<div class="alert alert-danger">The request failed. Check the production history before trying again.</div>');
                    },
                    complete: function () {
                        loadProduction(true);
                    }
                });
            });
            $('#tabProduction').on('click', '.production-view-btn', function () {
                var button = $(this);
                if (button.prop('disabled')) {
                    return;
                }
                button.prop('disabled', true);
                $('#productionModalBody').html('<div class="tab-empty"><i class="fa fa-spinner fa-spin"></i> Loading job details...</div>');
                $('#productionModal').modal('show');
                $.ajax({
                    type: 'POST',
                    url: 'view_sales_order.aspx/LoadProductionJob',
                    data: JSON.stringify({ smoId: parseInt($('#tabProduction').attr('data-order-id'), 10), itpmId: parseInt(button.attr('data-job'), 10) }),
                    contentType: 'application/json; charset=utf-8',
                    dataType: 'json',
                    success: function (response) {
                        var d = response.d;
                        $('#productionModalBody').html(d && d.ok ? jobDetailHtml(d) : '<p class="text-danger">' + esc((d && d.message) || 'Unable to load the production job details.') + '</p>');
                    },
                    error: function () {
                        $('#productionModalBody').html('<p class="text-danger">Unable to load the production job details. Please try again.</p>');
                    },
                    complete: function () {
                        button.prop('disabled', false);
                    }
                });
            });

            // ---- Production entry (sp_save_production_entry through ProductionService) ----
            var entryState = { sioId: 0, busy: false, data: null };

            function entryShowMessage(ok, text) {
                $('#productionEntryAlert').html(text ? '<div class="alert ' + (ok ? 'alert-success' : 'alert-danger') + '">' + esc(text) + '</div>' : '');
            }

            function entrySelected() {
                var id = parseInt($('#productionEntryBody input[name="entryReservation"]:checked').val(), 10);
                var found = null;
                if (entryState.data && id) {
                    $.each(entryState.data.inputs, function (i, x) { if (x.reservationId === id) { found = x; } });
                }
                return found;
            }

            function entryRefreshButton() {
                var sel = entrySelected();
                $('#productionEntrySave').prop('disabled', entryState.busy || !sel || !!sel.issue || !entryState.data.canSubmit);
            }

            function renderProductionEntry(o) {
                function info(k, v) { return '<div class="info-row"><span class="k">' + k + '</span><span class="v">' + v + '</span></div>'; }
                var uom = ' ' + esc(o.uom);
                var html = '<div id="productionEntryAlert"></div>'
                    + '<h5><strong>Finished Item</strong></h5>'
                    + info('Sales order', esc(o.orderRef) + ' (#' + esc($('#tabProduction').attr('data-order-id')) + ')')
                    + info('Finished item', esc(o.itemName) + (o.itemCode ? ' (' + esc(o.itemCode) + ')' : ''))
                    + info('Sales order quantity', num(o.orderQty) + uom)
                    + info('Finished stock reserved for this order', num(o.finishedReserved) + uom)
                    + info('Pending production', '<span class="text-danger">' + num(o.pending) + uom + '</span>')
                    + info('Production reference', esc(o.docNo));
                if (o.componentName) {
                    html += '<h5 style="margin-top: 15px;"><strong>BOM Component</strong></h5>'
                        + info('Component', esc(o.componentName) + (o.componentCode ? ' (' + esc(o.componentCode) + ')' : ''))
                        + info('BOM quantity per unit', num(o.perUnit) + ' ' + esc(o.componentUom))
                        + info('Raw material needed for the pending quantity', num(o.requiredRaw) + ' ' + esc(o.componentUom));
                }
                if (o.blocker) {
                    html += '<div class="alert alert-warning" style="margin-top: 15px;"><i class="fa fa-exclamation-triangle"></i> ' + esc(o.blocker) + '</div>';
                }
                if (o.inputs.length) {
                    html += '<h5 style="margin-top: 15px;"><strong>Raw Material Reserved for this Order</strong></h5>'
                        + '<div style="overflow-x: auto;"><table class="table table-striped jambo_table table-bordered"><thead style="background-color: #f1eeee; color: #525252"><tr>'
                        + '<th></th><th>Batch</th><th>Warehouse</th><th style="text-align: right;">Reserved</th><th style="text-align: right;">Finished quantity it produces</th><th>Check</th></tr></thead><tbody>'
                        + $.map(o.inputs, function (x) {
                            return '<tr' + (x.issue ? ' class="text-muted"' : '') + '><td><input type="radio" name="entryReservation" value="' + x.reservationId + '"' + (x.issue ? ' disabled="disabled"' : '') + ' /></td>'
                                + '<td>' + esc(x.batchNo) + '</td><td>' + (x.warehouse ? esc(x.warehouse) : '<span class="text-muted">-</span>') + '</td>'
                                + '<td style="text-align: right;">' + num(x.reservedQty) + ' ' + esc(x.uom) + '</td>'
                                + '<td style="text-align: right;">' + num(x.outputQty) + uom + '</td>'
                                + '<td>' + (x.issue ? '<span class="text-danger">' + esc(x.issue) + '</span>' : '<span class="text-success"><i class="fa fa-check"></i> Ready</span>') + '</td></tr>';
                        }).join('') + '</tbody></table></div>'
                        + '<p class="text-muted" style="font-size: 11px;">Producing uses the <strong>whole</strong> selected reservation, creates a finished batch of the quantity shown and reserves it for this order. '
                        + 'Stock quantities are updated automatically. This screen allows one production per sales order and one raw material; use <strong>Produce</strong> in the Reserved Items tab for other cases. Only this order\'s own reservations are listed.</p>';
                }
                $('#productionEntryBody').html(html);
                var first = $('#productionEntryBody input[name="entryReservation"]:not(:disabled)').first();
                first.prop('checked', true);
                entryRefreshButton();
            }

            function loadProductionEntry(sioId, notice) {
                entryState.sioId = sioId;
                entryState.data = null;
                $('#productionEntrySave').prop('disabled', true);
                $('#productionEntryBody').html('<div class="tab-empty"><i class="fa fa-spinner fa-spin"></i> Loading production entry...</div>');
                $.ajax({
                    type: 'POST',
                    url: 'view_sales_order.aspx/LoadProductionEntry',
                    data: JSON.stringify({ smoId: parseInt($('#tabProduction').attr('data-order-id'), 10), sioId: sioId }),
                    contentType: 'application/json; charset=utf-8',
                    dataType: 'json',
                    success: function (response) {
                        var d = response.d;
                        if (!d || !d.ok) {
                            $('#productionEntryBody').html('<p class="text-danger">' + esc((d && d.message) || 'Unable to load the production entry.') + '</p>');
                            return;
                        }
                        entryState.data = d;
                        renderProductionEntry(d);
                        if (notice) {
                            entryShowMessage(false, notice);
                        }
                    },
                    error: function () {
                        $('#productionEntryBody').html('<p class="text-danger">Unable to load the production entry. Please try again.</p>');
                    }
                });
            }

            $('#tabProduction').on('click', '.production-entry-btn', function () {
                if (entryState.busy) {
                    return;
                }
                $('#productionEntryModal').modal('show');
                loadProductionEntry(parseInt($(this).attr('data-sio'), 10));
            });
            $('#productionEntryModal').on('change', 'input[name="entryReservation"]', entryRefreshButton);
            $('#productionEntrySave').on('click', function () {
                var sel = entrySelected();
                if (entryState.busy || !sel || sel.issue) {
                    return;
                }
                var d = entryState.data;
                if (!window.confirm('Produce ' + num(sel.outputQty) + ' ' + d.uom + ' of "' + d.itemName + '"?\n'
                    + 'This uses the whole reserved raw material of ' + num(sel.reservedQty) + ' ' + sel.uom + ' (batch ' + sel.batchNo + '). '
                    + 'The finished stock is reserved for this order.')) {
                    return;
                }
                entryState.busy = true;
                $('#productionEntrySave, #productionEntryCancel').prop('disabled', true);
                $('#productionEntryModal .close').hide();
                $('#productionEntrySpinner').show();
                $.ajax({
                    type: 'POST',
                    url: 'view_sales_order.aspx/SaveProduction',
                    data: JSON.stringify({ smoId: parseInt($('#tabProduction').attr('data-order-id'), 10), sioId: entryState.sioId, reservationId: sel.reservationId, expectedOutput: sel.outputQty }),
                    contentType: 'application/json; charset=utf-8',
                    dataType: 'json',
                    success: function (response) {
                        var r = response.d || {};
                        entryState.busy = false;
                        if (r.ok) {
                            $('#productionEntryModal').modal('hide');
                            $('#productionMessage').html('<div class="alert alert-success">' + esc(r.message) + '</div>');
                            loadProduction(true);
                        } else {
                            loadProductionEntry(entryState.sioId, r.message || 'The production entry could not be saved.');
                        }
                    },
                    error: function () {
                        entryState.busy = false;
                        loadProductionEntry(entryState.sioId, 'The request failed. Check the production history before trying again.');
                        loadProduction(true);
                    },
                    complete: function () {
                        $('#productionEntrySpinner').hide();
                        $('#productionEntryCancel').prop('disabled', false);
                        $('#productionEntryModal .close').show();
                    }
                });
            });

            if (location.hash === '#tabReserved' || location.hash === '#tabProduction' || location.hash === '#tabInvoices') {
                $('#soTabs a[href="' + location.hash + '"]').trigger('click');
            }
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
                                    <label style="font-weight: bold; font-size: 16px;">Sales Order Details</label>
                                </div>
                                <div class="col-md-6 col-xs-5">
                                    <% if (Order != null) { %>
                                    <a href="edit_sales_order.aspx?smoId=<%= Enc(Order["smo_id"]) %>">
                                        <div class="btn btn-success btn-xs pull-right" style="margin-top: 5px; margin-left: 5px"><label style="color: #fff; margin-right: 5px; font-size: 14px;" class="fa fa-pencil"></label>Edit</div>
                                    </a>
                                    <% } %>
                                    <a href="sales_order_list.aspx">
                                        <div class="btn btn-primary btn-xs pull-right" style="margin-top: 5px"><label style="color: #fff; margin-right: 5px; font-size: 14px;" class="fa fa-arrow-left"></label>Back to Sales Orders</div>
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
                                    <div class="info-row"><span class="k">Order Date</span><span class="v"><%= Enc(Order["orderDate"]) %></span></div>
                                    <% if (Has("branch_name")) { %><div class="info-row"><span class="k">Warehouse</span><span class="v"><%= Enc(Order["branch_name"]) %></span></div><% } %>
                                    <% if (Enc(Order["seller_name"]).Trim() != "") { %><div class="info-row"><span class="k">Created By</span><span class="v"><%= Enc(Order["seller_name"]).Trim() %></span></div><% } %>
                                    <% if (PaymentText() != "") { %><div class="info-row"><span class="k">Payment Type</span><span class="v"><%= PaymentText() %></span></div><% } %>
                                    <% if (OrderTypeText() != "") { %><div class="info-row"><span class="k">Order Type</span><span class="v"><%= OrderTypeText() %></span></div><% } %>
                                    <div class="info-row"><span class="k">Grand Total</span><span class="v" style="font-size: 16px;"><%= Money(Order["smo_netamount"]) %></span></div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-12 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_content">
                                    <div class="tabs-scroll">
                                        <ul class="nav nav-tabs" id="soTabs" role="tablist" style="white-space: nowrap;">
                                            <li class="active"><a href="#tabItems">Sales Order Items</a></li>
                                            <li><a href="#tabReserved">Reserved Items</a></li>
                                            <li><a href="#tabProduction">Production Details</a></li>
                                            <li><a href="#tabInvoices">Invoices</a></li>
                                            <li><a href="#tabNotes">Notes / Remarks</a></li>
                                        </ul>
                                    </div>
                                    <div class="tab-content">
                                        <div class="tab-pane active" id="tabItems">
                                            <div style="overflow-x: auto;">
                                                <table class="table table-striped jambo_table table-bordered">
                                                    <thead style="background-color: #f1eeee; color: #525252">
                                                        <tr>
                                                            <th>Sl. No.</th>
                                                            <th>Item Code</th>
                                                            <th>Item Name</th>
                                                            <th style="text-align: right;">Qty</th>
                                                            <th>Size (L x W)</th>
                                                            <th>UOM</th>
                                                            <th style="text-align: right;">Final Qty</th>
                                                            <th>Final UOM</th>
                                                            <th style="text-align: right;">Unit Price</th>
                                                            <th style="text-align: right;">Discount</th>
                                                            <th style="text-align: right;">Tax / GST</th>
                                                            <th style="text-align: right;">Line Total</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody>
                                                        <asp:Repeater ID="rptItems" runat="server">
                                                            <ItemTemplate>
                                                                <tr>
                                                                    <td><%# Eval("sl") %></td>
                                                                    <td><%# Enc(Eval("itm_code")) %></td>
                                                                    <td><%# Enc(Eval("itm_name")) %></td>
                                                                    <td style="text-align: right;"><%# Enc(Eval("cust_qty")) %></td>
                                                                    <td><%# Enc(Eval("cust_size")) %></td>
                                                                    <td><%# Enc(Eval("cust_uom")) %></td>
                                                                    <td style="text-align: right;"><%# Num(Eval("sio_finalqty")) %></td>
                                                                    <td><%# Enc(Eval("uom")) %></td>
                                                                    <td style="text-align: right;"><%# Money(Eval("sio_price")) %></td>
                                                                    <td style="text-align: right;"><%# Money(Eval("sio_discount_amount")) %> (<%# Num(Eval("sio_discount_rate")) %>%)</td>
                                                                    <td style="text-align: right;"><%# Money(Eval("sio_tax_amount")) %> (<%# Num(Eval("sio_item_tax")) %>%)</td>
                                                                    <td style="text-align: right;"><b><%# Money(Eval("sio_net_amount")) %></b></td>
                                                                </tr>
                                                            </ItemTemplate>
                                                        </asp:Repeater>
                                                        <% if (ItemCount == 0) { %>
                                                        <tr><td colspan="12" style="text-align: center">No items found for this sales order.</td></tr>
                                                        <% } else { %>
                                                        <tr style="font-weight: bold; background: #f9f9f9;">
                                                            <td colspan="3" style="text-align: right;">Total</td>
                                                                                                                    <td colspan="3"></td>
                                                            <td style="text-align: right;"><%= Num(ItemsQty) %></td>
                                                            <td colspan="2"></td>
                                                            <td style="text-align: right;"><%= Money(ItemsDiscount) %></td>
                                                            <td style="text-align: right;"><%= Money(ItemsTax) %></td>
                                                            <td style="text-align: right;"><%= Money(ItemsNet) %></td>
                                                        </tr>
                                                        <% } %>
                                                    </tbody>
                                                </table>
                                            </div>
                                        </div>
                                        <div class="tab-pane" id="tabReserved" data-order-id="<%= Enc(Order["smo_id"]) %>">
                                            <div id="reservedMessage" role="status" aria-live="polite"></div>
                                            <div id="reservedLoading" class="tab-empty">Open this tab to load reserved items.</div>
                                            <div id="reservedGrid" style="display: none; overflow-x: auto;">
                                                <table class="table table-striped jambo_table table-bordered">
                                                    <thead style="background-color: #f1eeee; color: #525252">
                                                        <tr>
                                                            <th rowspan="2">#</th>
                                                            <th rowspan="2">Item</th>
                                                            <th colspan="3" class="text-center">Order quantity</th>
                                                            <th colspan="3" class="text-center">Stock cover</th>
                                                            <th rowspan="2">Status</th>
                                                            <th rowspan="2">Actions</th>
                                                        </tr>
                                                        <tr>
                                                            <th class="num">Ordered</th>
                                                            <th class="num">Delivered</th>
                                                            <th class="num">To deliver</th>
                                                            <th class="num">Reserved</th>
                                                            <th class="num">Short</th>
                                                            <th class="num">Available</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody id="reservedBody"></tbody>
                                                </table>
                                            </div>
                                        </div>
                                        <div class="tab-pane" id="tabProduction" data-order-id="<%= Enc(Order["smo_id"]) %>">
                                            <div id="productionMessage" role="status" aria-live="polite"></div>
                                            <div id="productionLoading" class="tab-empty">Open this tab to load production details.</div>
                                            <div id="productionContent" style="display: none;">
                                                <h5><strong>Production Overview</strong></h5>
                                                <div class="row" id="productionSummary"></div>
                                                <div id="productionLinesEmpty" class="tab-empty" style="display: none;">No item on this sales order requires manufacturing (no BOM is defined).</div>
                                                <div id="productionLinesGrid" style="overflow-x: auto;">
                                                    <table class="table table-striped jambo_table table-bordered">
                                                        <thead style="background-color: #f1eeee; color: #525252">
                                                            <tr>
                                                                <th>#</th>
                                                                <th>Item</th>
                                                                <th style="text-align: right;">Ordered</th>
                                                                <th style="text-align: right;">Produced</th>
                                                                <th style="text-align: right;">Pending</th>
                                                                <th style="text-align: right;">Reserved</th>
                                                                <th>Production Numbers</th>
                                                                <th>Status</th>
                                                                <th>Action</th>
                                                            </tr>
                                                        </thead>
                                                        <tbody id="productionLinesBody"></tbody>
                                                    </table>
                                                </div>
                                                <h5 style="margin-top: 20px;"><strong>Production History</strong></h5>
                                                <div id="productionEmpty" class="tab-empty" style="display: none;">No production entries have been created for this sales order.</div>
                                                <div id="productionGrid" style="overflow-x: auto;">
                                                    <table class="table table-striped jambo_table table-bordered">
                                                        <thead style="background-color: #f1eeee; color: #525252">
                                                            <tr>
                                                                <th>#</th>
                                                                <th>Production Reference</th>
                                                                <th>Item</th>
                                                                <th style="text-align: right;">Produced</th>
                                                                <th style="text-align: right;">Reserved</th>
                                                                <th>Raw Material Used</th>
                                                                <th>Batch</th>
                                                                <th>Date</th>
                                                                <th>Status</th>
                                                                <th>Action</th>
                                                            </tr>
                                                        </thead>
                                                        <tbody id="productionBody"></tbody>
                                                    </table>
                                                </div>
                                                <p class="text-muted" style="font-size: 11px;">Status is worked out from the order: "Produced" means the order's shortfall has been produced; "Pending production" is what is still short after the stock reserved for this order. Reserve the raw material in the Reserved Items tab before producing here.</p>
                                            </div>
                                        </div>
                                        <div class="tab-pane" id="tabInvoices">
                                            <% if (InvoiceMessage != "") { %><div class="alert alert-success"><%= Enc(InvoiceMessage) %></div><% } %>
                                            <div style="margin-bottom: 10px; overflow: hidden;">
                                                <% if (CanCreateInvoice) { %>
                                                <a href="sales_order_invoice.aspx?smoId=<%= Enc(Order["smo_id"]) %>" class="btn btn-success pull-right"><i class="fa fa-plus"></i> Create Invoice</a>
                                                <% } else { %>
                                                <span class="btn btn-success pull-right disabled" title="<%= Enc(InvoiceHint) %>"><i class="fa fa-plus"></i> Create Invoice</span>
                                                <% } %>
                                                                                               <a href="sales_order_interstock_transfer.aspx?smoId=<%= Enc(Order["smo_id"]) %>" class="btn btn-primary pull-right" style="margin-right: 5px;"><i class="fa fa-exchange"></i> Inter Stock Transfer</a>                                                <% if (InvoiceHint != "") { %><span class="text-muted" style="line-height: 34px;"><%= Enc(InvoiceHint) %></span><% } %>
                                            </div>
                                            <% if (Invoices.Count == 0) { %>
                                            <div class="tab-empty">No invoices have been created for this sales order.</div>
                                            <% } else { %>
                                            <div style="overflow-x: auto;">
                                                <table class="table table-striped jambo_table table-bordered">
                                                    <thead style="background-color: #f1eeee; color: #525252">
                                                        <tr>
                                                            <th>Invoice No</th>
                                                            <th>Invoice Date</th>
                                                            <th>Customer</th>
                                                            <th class="text-right">Items</th>
                                                            <th class="text-right">Invoice Amount</th>
                                                            <th>Payment Status</th>
                                                            <th>Invoice Status</th>
                                                            <th>Action</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody>
                                                        <% foreach (var inv in Invoices) { %>
                                                        <tr>
                                                            <td>#<%= inv.SmId %><% if (inv.InvoiceNo != "") { %> (<%= Enc(inv.InvoiceNo) %>)<% } %></td>
                                                            <td><%= Enc(inv.Date) %></td>
                                                            <td><%= Enc(inv.Customer) %></td>
                                                            <td class="text-right"><%= inv.ItemCount %></td>
                                                            <td class="text-right"><%= Money(inv.Amount) %></td>
                                                            <td><span class="status <%= inv.PaymentCss %>"><%= inv.PaymentText %></span></td>
                                                            <td><% if (inv.StatusText != "") { %><span class="status <%= inv.StatusCss %>"><%= inv.StatusText %></span><% } else { %><span class="text-muted">Not available</span><% } %></td>
                                                            <td><a href="manageorders.aspx?orderId=<%= inv.SmId %>" class="btn btn-primary btn-xs"><i class="fa fa-eye"></i> View</a></td>
                                                        </tr>
                                                        <% } %>
                                                    </tbody>
                                                </table>
                                            </div>
                                            <% } %>
                                        </div>
                                        <div class="tab-pane" id="tabNotes" data-order-id="<%= Enc(Order["smo_id"]) %>">
                                            <div id="remarksLoading" class="tab-empty">Open this tab to load notes and remarks.</div>
                                            <div id="remarksEditor" style="display: none;">
                                                <label for="remarksInput">Notes / Remarks</label>
                                                <textarea id="remarksInput" class="form-control" rows="5"></textarea>
                                                <div style="margin-top: 10px;">
                                                    <button type="button" id="saveRemarks" class="btn btn-primary">Save Notes / Remarks</button>
                                                    <span id="remarksStatus" role="status" aria-live="polite"></span>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="row" id="statusActionsRow">
                        <div class="col-md-12 col-sm-12 col-xs-12">
                            <div class="x_panel">
                                <div class="x_title"><strong><i class="fa fa-flag"></i> Order Status &amp; Actions</strong><div class="clearfix"></div></div>
                                <div class="x_content">
                                    <% if (ActionMessage != "") { %>
                                    <div class="alert alert-info" style="margin-bottom: 10px;"><%= Enc(ActionMessage) %></div>
                                    <% } %>
                                    <div style="margin-bottom: 10px;">
                                        <span class="k" style="color: #777;">Current status:&nbsp;</span>
                                        <% if (StatusText != "") { %><span class="status <%= StatusCss %>" style="font-size: 14px;"><%= StatusText %></span><% } else { %><span class="text-muted">Not available</span><% } %>
                                    </div>
                                    <div class="table-responsive">
                                        <table class="table table-striped jambo_table table-bordered">
                                            <caption>Recorded status actions (latest saved details, not a complete change history).</caption>
                                            <thead style="background-color: #f1eeee; color: #525252">
                                                <tr>
                                                    <th scope="col">Status</th>
                                                    <th scope="col">Action By</th>
                                                    <th scope="col">Date of Action</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <% foreach (var action in StatusActions) { %>
                                                <tr>
                                                    <td><span class="status <%= action.Css %>"><%= Enc(action.Status) %></span></td>
                                                    <td><%= Enc(action.User) %></td>
                                                    <td><%= Enc(action.Date) %></td>
                                                </tr>
                                                <% } %>
                                            </tbody>
                                        </table>
                                    </div>
                                    <div>
                                        <asp:LinkButton ID="btnApprove" runat="server" CssClass="btn btn-success" OnClick="btnApprove_Click" OnClientClick="return confirm('Approve this sales order? It will become eligible for stock reservation.');"><i class="fa fa-check"></i> Approve</asp:LinkButton>
                                        <asp:LinkButton ID="btnResume" runat="server" CssClass="btn btn-success" OnClick="btnResume_Click" OnClientClick="return confirm('Resume and approve this sales order? Stock will not be reserved automatically.');"><i class="fa fa-play"></i> Resume / Approve</asp:LinkButton>
                                        <asp:LinkButton ID="btnHold" runat="server" CssClass="btn btn-info" OnClick="btnHold_Click" OnClientClick="return confirm('Put this sales order on hold (Pending)? No further stock can be reserved until it is resumed. Existing reservations are kept.');"><i class="fa fa-pause"></i> Put on Hold</asp:LinkButton>
                                        <asp:LinkButton ID="btnCancelCustomer" runat="server" CssClass="btn btn-warning" OnClick="btnCancelCustomer_Click" OnClientClick="return confirm('Cancel this sales order as cancelled by the customer? All of its stock reservations will be released.');"><i class="fa fa-times"></i> Cancel (Customer)</asp:LinkButton>
                                        <asp:LinkButton ID="btnCancelCompany" runat="server" CssClass="btn btn-danger" OnClick="btnCancelCompany_Click" OnClientClick="return confirm('Cancel this sales order as cancelled by the company? All of its stock reservations will be released.');"><i class="fa fa-ban"></i> Cancel (Company)</asp:LinkButton>
                                        <asp:LinkButton ID="btnReopen" runat="server" CssClass="btn btn-primary" OnClick="btnReopen_Click" OnClientClick="return confirm('Reopen this sales order as New?');"><i class="fa fa-undo"></i> Reopen</asp:LinkButton>
                                        <% if (ActionHint != "") { %><span class="text-muted"><%= Enc(ActionHint) %></span><% } %>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="modal fade" id="productionEntryModal" tabindex="-1" role="dialog" aria-labelledby="productionEntryTitle" data-backdrop="static">
                        <div class="modal-dialog modal-lg" role="document">
                            <div class="modal-content">
                                <div class="modal-header">
                                    <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                                    <h4 class="modal-title" id="productionEntryTitle">Produce</h4>
                                </div>
                                <div class="modal-body" id="productionEntryBody"></div>
                                <div class="modal-footer">
                                    <span id="productionEntrySpinner" style="display: none; margin-right: 10px;"><i class="fa fa-spinner fa-spin"></i> Producing...</span>
                                    <button type="button" class="btn btn-default" data-dismiss="modal" id="productionEntryCancel">Cancel</button>
                                    <button type="button" class="btn btn-primary" id="productionEntrySave" disabled="disabled"><i class="fa fa-cogs"></i> Produce</button>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="modal fade" id="productionModal" tabindex="-1" role="dialog" aria-labelledby="productionModalTitle">
                        <div class="modal-dialog modal-lg" role="document">
                            <div class="modal-content">
                                <div class="modal-header">
                                    <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                                    <h4 class="modal-title" id="productionModalTitle">Production Job Details</h4>
                                </div>
                                <div class="modal-body" id="productionModalBody"></div>
                                <div class="modal-footer"><button type="button" class="btn btn-default" data-dismiss="modal">Close</button></div>
                            </div>
                        </div>
                    </div>
                    <div class="modal fade" id="batchModal" tabindex="-1" role="dialog" aria-labelledby="batchModalTitle" data-backdrop="static">
                        <div class="modal-dialog modal-lg" role="document">
                            <div class="modal-content">
                                <div class="modal-header">
                                    <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                                    <h4 class="modal-title" id="batchModalTitle">Select Warehouse &amp; Batches</h4>
                                </div>
                                <div class="modal-body" id="batchModalBody"></div>
                                <div class="modal-footer">
                                    <div class="pick-totals"><span id="batchTotals"></span> <span id="batchSpinner" style="display: none;"><i class="fa fa-spinner fa-spin"></i> Processing...</span></div>
                                    <span id="batchFooterButtons" style="display: none;">
                                        <button type="button" class="btn btn-default pull-left" id="batchRelease" style="display: none; margin-left: 10px;"><i class="fa fa-unlock"></i> Release existing reservation</button>
                                        <button type="button" class="btn btn-default" id="batchFifo"><i class="fa fa-sort-amount-asc"></i> Auto-fill (oldest first)</button>
                                        <button type="button" class="btn btn-default" id="batchClear">Clear</button>
                                        <button type="button" class="btn btn-success" id="batchSubmit" disabled><i class="fa fa-lock"></i> Reserve Selected</button>
                                    </span>
                                    <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
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
</body>
</html>
