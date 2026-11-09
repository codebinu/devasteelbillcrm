<%@ Page Language="C#" AutoEventWireup="true" CodeFile="start_production.aspx.cs" Inherits="web_production_start_production" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Production Queue | Invoice Me</title>
    <script src="../js/common.js" type="text/javascript"></script>
    <script type="text/javascript" src="../js/jquery-2.0.3.js"></script>
    <script type="text/javascript" src="../js/jquery.cookie.js"></script>
    <script src="../js/pagination.js" type="text/javascript"></script>

    <link href="../css/bootstrap/bootstrap.min.css" rel="stylesheet" />
    <link href="../css/font-awesome/css/font-awesome.min.css" rel="stylesheet" />
    <link href="../css/bootstrap/nprogress.css" rel="stylesheet" />
    <link href="../css/bootstrap/daterangepicker.css" rel="stylesheet" />
    <link href="../css/bootstrap/custom.min.css" rel="stylesheet" />
    <link href="../css/bootstrap/mystyle.css" type="text/css" rel="stylesheet" />
    <link rel="stylesheet" href="../mobiscroll/css/jquery.mobile-1.1.0.min.css" />
    <script src="../mobiscroll/js/mobiscroll-2.0rc3.full.min.js" type="text/javascript"></script>
    <link href="../mobiscroll/css/mobiscroll-2.0rc3.full.min.css" rel="stylesheet" type="text/css" />

    <style>
        .info-row { padding: 4px 0; border-bottom: 1px dashed #eee; overflow: hidden; }
        .info-row .k { color: #777; float: left; width: 42%; }
        .info-row .v { float: left; width: 58%; font-weight: 600; word-break: break-word; }
        .tab-empty { text-align: center; color: #888; padding: 30px 0; }
        .sub-note { display: block; color: #777; font-size: 11px; }
        #pageMessage .alert { margin-bottom: 10px; }
        #tblItems th.num, #tblItems td.num { text-align: right; white-space: nowrap; }
        #tblItems td.short { color: #a94442; font-weight: 600; }
        #tblItems .res-actions .btn { display: block; margin-bottom: 4px; white-space: nowrap; }
        #tblItems .link-action { display: block; font-size: 11px; margin-top: 2px; white-space: nowrap; }
        #tblItems tr.raw-row > td { background: #fafafa; border-top: 0; }
        #tblItems .raw-table { margin-bottom: 0; background: #fff; }
        #tblItems .raw-table > thead > tr > th, #tblItems .raw-table > tbody > tr > td { padding: 4px 8px; font-size: 12px; vertical-align: middle; }
        #tblItems .raw-table .res-actions .btn { display: inline-block; margin-right: 4px; }
        #tblItems .alloc-list { margin: 4px 0 0 0; padding-left: 16px; font-size: 11px; color: #555; }
        #tblItems.busy .btn, #tblItems.busy a { pointer-events: none; opacity: .65; }
        .status-chip { margin: 0 4px 6px 0; }
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
        var STATUS_LABELS = { awaiting: 'Awaiting raw material', ready: 'Ready to produce', partial: 'Partially produced', produced: 'Produced', covered: 'Covered by stock', unavailable: 'Unavailable' };
        var STATUS_CLASS = { awaiting: 'label-warning', ready: 'label-primary', partial: 'label-info', produced: 'label-success', covered: 'label-default', unavailable: 'label-default' };
        var currentPage = 1;
        var busy = false;
        var openRaw = {};

        function esc(s) {
            return $("<div/>").text(s == null ? "" : String(s)).html();
        }

        // For values placed inside HTML attributes (esc does not escape quotes).
        function attr(s) {
            return esc(s).replace(/"/g, '&quot;').replace(/'/g, '&#39;');
        }

        function num(value) {
            return String(Math.round((Number(value) || 0) * 10000) / 10000);
        }

        function post(method, data, ok, fail) {
            return $.ajax({
                type: 'POST',
                url: 'start_production.aspx/' + method,
                data: JSON.stringify(data),
                contentType: 'application/json; charset=utf-8',
                dataType: 'json',
                success: ok,
                error: fail
            });
        }

        function showMessage(ok, text) {
            $('#pageMessage').html(text ? '<div class="alert ' + (ok ? 'alert-success' : 'alert-danger') + '">' + esc(text) + '</div>' : '');
        }

        $(document).ready(function () {
            if (!$.cookie("invntrystaffBranchId")) {
                location.href = "../dashboard.aspx";
                return false;
            }
            var yyyy = new Date().getFullYear();
            $('#txtSearchFromDate, #txtSearchToDate').scroller({
                preset: 'date', endYear: yyyy + 100, setText: 'Next', invalid: {},
                theme: 'ios', display: 'modal', mode: 'scroller', dateFormat: 'dd-mm-yy'
            });
            $('.footerDivContent').html("Copyright " + new Date().getFullYear() + " &copy;");
            $("#txtOrder, #txtCustomer, #txtProduct").keypress(function (e) {
                if (e.which == 13) { searchItems(1, true); return false; }
            });
            getStaff();
            getBranches();
        });

        function getStaff() {
            $.ajax({
                type: "POST", url: "start_production.aspx/getStaff", data: "{}",
                contentType: "application/json; charset=utf-8", dataType: "json",
                success: function (msg) {
                    var htm = '<option value="-1" selected="selected">--All Users--</option>';
                    $.each(JSON.parse(msg.d), function (i, row) {
                        htm += '<option value="' + attr(row.user_id) + '">' + esc(row.name) + '</option>';
                    });
                    $("#slActor").html(htm);
                },
                error: function () { $("#slActor").html('<option value="-1">--All Users--</option>'); }
            });
        }

        function getBranches() {
            loading();
            $.ajax({
                type: "POST", url: "start_production.aspx/getBranches", data: "{}",
                contentType: "application/json; charset=utf-8", dataType: "json",
                success: function (msg) {
                    var obj = JSON.parse(msg.d);
                    var htm = '<option value="-1" selected="selected">--All Warehouses--</option>';
                    $.each(obj, function (i, row) {
                        htm += '<option value="' + attr(row.branch_id) + '">' + esc(row.branch_name) + '</option>';
                    });
                    $("#slBranch").html(htm);
                    Unloading();
                    searchItems(1);
                },
                error: function () { Unloading(); alert("Internet Problem..!"); }
            });
        }

        function currentFilters() {
            var filters = {};
            if ($.trim($("#txtOrder").val()) != "") filters.order = $.trim($("#txtOrder").val());
            if ($.trim($("#txtCustomer").val()) != "") filters.customer = $.trim($("#txtCustomer").val());
            if ($.trim($("#txtProduct").val()) != "") filters.product = $.trim($("#txtProduct").val());
            if ($("#slBranch").val() && $("#slBranch").val() != "-1") filters.branch = $("#slBranch").val();
            if ($("#txtSearchFromDate").val() != "") filters.from_date = $("#txtSearchFromDate").val();
            if ($("#txtSearchToDate").val() != "") filters.to_date = $("#txtSearchToDate").val();
            filters.status = $("#slStatus").val();
            if ($("#slActor").val() && $("#slActor").val() != "-1") filters.actor = $("#slActor").val();
            return filters;
        }

        function setStatus(key) {
            $("#slStatus").val(key);
            searchItems(1);
        }

        function renderChips(counts) {
            var current = $("#slStatus").val();
            var total = 0, open = 0;
            $.each(counts || {}, function (k, n) {
                total += n;
                if (k === 'awaiting' || k === 'ready' || k === 'partial') { open += n; }
            });
            var chips = [{ key: 'open', text: 'Needs action', n: open }];
            $.each(['awaiting', 'ready', 'partial', 'produced', 'covered'], function (i, k) {
                chips.push({ key: k, text: STATUS_LABELS[k], n: (counts || {})[k] || 0 });
            });
            if ((counts || {}).unavailable) {
                chips.push({ key: 'unavailable', text: STATUS_LABELS.unavailable, n: counts.unavailable });
            }
            chips.push({ key: 'all', text: 'All', n: total });
            $('#statusChips').html($.map(chips, function (c) {
                var active = c.key === current;
                return '<button type="button" class="btn btn-sm status-chip ' + (active ? 'btn-success' : 'btn-default') + '" onclick="setStatus(\'' + c.key + '\');">'
                    + esc(c.text) + ' <span class="badge" style="background: ' + (active ? '#1f8f75' : '#73879C') + '; color: #fff;">' + c.n + '</span></button>';
            }).join(''));
        }

        var lastResult = null;

        function renderGrid(obj, page, perpage) {
            $("#txttotalcount").text(obj.count);
            renderChips(obj.counts);
            $('#truncatedNote').toggle(!!obj.truncated);
            var htm = obj.count == 0
                ? '<tr><td colspan="10" style="text-align:center"><label>No items match the selected filters.</label></td></tr>'
                : $.map(obj.data, itemRowHtml).join('');
            $('#tblItems > tbody').html(htm);
            $('#divPagination').html(obj.count > 0 ? paginate(obj.count, perpage, page, "searchItems") : "");
        }

        // refresh = true recomputes the board on the server; otherwise a recent result for the same filters is reused (paging, status, sort).
        function searchItems(page, refresh) {
            currentPage = page;
            var perpage = $("#slPerpage").val();
            var filters = currentFilters();
            if (refresh === true) { filters.refresh = '1'; }
            loading();
            post('searchItems', { page: page, filters: filters, perpage: parseInt(perpage, 10) }, function (msg) {
                Unloading();
                if (msg.d == "E") {
                    lastResult = null;
                    $('#tblItems > tbody').html('<tr><td colspan="10" style="text-align:center;color:red">Unable to load production items. Please try again.</td></tr>');
                    $("#txttotalcount").text(0);
                    $('#divPagination').html("");
                    return;
                }
                var obj = JSON.parse(msg.d);
                if (obj.count > 0 && obj.data.length === 0 && page > 1) {
                    searchItems(page - 1);
                    return;
                }
                lastResult = { obj: obj, page: page, perpage: perpage };
                renderGrid(obj, page, perpage);
            }, function () { Unloading(); alert("Internet Problem..!"); });
        }

        function resetFilters() {
            $("#txtOrder, #txtCustomer, #txtProduct, #txtSearchFromDate, #txtSearchToDate").val("");
            $("#slBranch, #slActor").val("-1");
            $("#slStatus").val("open");
            $("#slPerpage").val("25");
            searchItems(1, true);
        }

        // ---- Grid ----
        function actionAttrs(r, compId, name, uom) {
            return ' data-order="' + attr(r.smoId) + '" data-sio="' + attr(r.sioId) + '" data-comp="' + attr(compId) + '" data-name="' + attr(name) + '" data-uom="' + attr(uom) + '"';
        }

        function allocListHtml(list, r) {
            if (!list || !list.length) { return ''; }
            return '<ul class="alloc-list">' + $.map(list, function (a) {
                return '<li>' + esc(a.warehouse || '-') + ' &middot; batch ' + esc(a.batchNo) + ': ' + num(a.qty) + ' ' + esc(a.uom)
                    + (r.canAct ? ' <a href="#" class="release-batch" data-order="' + attr(r.smoId) + '" data-sio="' + attr(r.sioId) + '" data-batch="' + attr(a.batchId) + '" data-no="' + attr(a.batchNo) + '" data-qty="' + attr(a.qty) + '" data-uom="' + attr(a.uom) + '"><i class="fa fa-unlock"></i> Release</a>' : '')
                    + '</li>';
            }).join('') + '</ul>';
        }

        function rawStateHtml(c) {
            if (c.issue) { return '<span class="text-danger">' + esc(c.issue) + '</span>'; }
            if (c.shortage > 0) { return '<span class="text-danger">Short by ' + num(c.shortage) + ' ' + esc(c.uom) + '</span>'; }
            if (c.surplus > 0) { return '<span class="text-warning">' + num(c.surplus) + ' ' + esc(c.uom) + ' reserved more than needed</span>'; }
            if (c.required > 0 && c.reserved + 0.0005 >= c.required) { return '<span class="text-success"><i class="fa fa-check"></i> Fully reserved</span>'; }
            return '<span class="text-warning">Reservation pending</span>';
        }

        function rawActionsHtml(r, c) {
            if (!r.canAct) { return ''; }
            var attrs = actionAttrs(r, c.itmId, c.name, c.uom);
            var html = '';
            if (c.canReserve) {
                html += '<button type="button" class="btn btn-xs btn-success reserve-btn"' + attrs + ' data-qty="' + attr(c.available) + '" title="Reserve the oldest stock in the order\'s warehouse"><i class="fa fa-lock"></i> Reserve ' + num(c.available) + ' ' + esc(c.uom) + '</button>';
            }
            if (c.canPick) {
                html += '<a href="#" class="link-action pick-btn"' + attrs + '><i class="fa fa-th-list"></i> Choose warehouse / batches</a>';
            }
            if (c.canUnreserve) {
                html += '<a href="#" class="link-action unreserve-btn"' + attrs + '><i class="fa fa-unlock"></i> Release all</a>';
            }
            return html;
        }

        function rawRowHtml(r) {
            var body = $.map(r.raw, function (c) {
                var name = '<strong>' + esc(c.name) + '</strong>' + (c.code ? ' <span class="text-muted">(' + esc(c.code) + ')</span>' : '');
                if (c.issue) {
                    return '<tr><td>' + name + '</td><td colspan="4"><span class="text-danger">' + esc(c.issue) + '</span></td><td></td></tr>';
                }
                return '<tr><td>' + name + '<span class="sub-note">Uses ' + num(c.perUnit) + ' ' + esc(c.uom) + ' for each ' + esc(r.uom) + '</span>' + allocListHtml(c.allocations, r) + '</td>'
                    + '<td class="num">' + num(c.required) + ' ' + esc(c.uom) + '</td>'
                    + '<td class="num">' + num(c.reserved) + ' ' + esc(c.uom) + '</td>'
                    + '<td class="num">' + num(c.free) + ' ' + esc(c.uom) + '</td>'
                    + '<td>' + rawStateHtml(c) + '</td>'
                    + '<td><div class="res-actions">' + rawActionsHtml(r, c) + '</div></td></tr>';
            }).join('');
            return '<tr class="raw-row"><td colspan="10"><table class="table table-bordered raw-table"><thead><tr><th>Raw material</th><th class="num">Needed</th><th class="num">Reserved</th><th class="num">Available</th><th>Status</th><th>Actions</th></tr></thead>'
                + '<tbody>' + body + '</tbody></table></td></tr>';
        }

        function rowKey(r) { return r.smoId + '-' + r.sioId; }

        function itemRowHtml(r) {
            var key = rowKey(r);
            var isOpen = !!openRaw[key];
            var hasRaw = r.raw && r.raw.length > 0;
            var actions = '';
            if (!r.canAct) {
                actions = '<span class="text-muted">View only</span>';
            } else {
                var attrs = actionAttrs(r, 0, r.itemName, r.uom);
                if (r.canProduce) {
                    actions += '<button type="button" class="btn btn-xs btn-primary production-entry-btn" data-order="' + attr(r.smoId) + '" data-sio="' + attr(r.sioId) + '"><i class="fa fa-cogs"></i> Produce ' + num(r.pending) + ' ' + esc(r.uom) + '</button>';
                } else if (r.statusKey === 'awaiting' && hasRaw) {
                    actions += '<button type="button" class="btn btn-xs btn-default production-entry-btn" data-order="' + attr(r.smoId) + '" data-sio="' + attr(r.sioId) + '"><i class="fa fa-info-circle"></i> Why not?</button>';
                }
                if (r.canReserveFinished) {
                    actions += '<button type="button" class="btn btn-xs btn-success reserve-btn"' + attrs + ' data-qty="' + attr(r.availableFinished) + '" title="Reserve existing finished stock before producing"><i class="fa fa-lock"></i> Reserve stock ' + num(r.availableFinished) + ' ' + esc(r.uom) + '</button>';
                }
                if (r.canPickFinished) {
                    actions += '<a href="#" class="link-action pick-btn"' + attrs + '><i class="fa fa-th-list"></i> Choose finished-stock batches</a>';
                }
                if (r.canUnreserveFinished) {
                    actions += '<a href="#" class="link-action unreserve-btn"' + attrs + '><i class="fa fa-unlock"></i> Release finished stock</a>';
                }
                actions = actions ? '<div class="res-actions">' + actions + '</div>' : '<span class="text-muted">-</span>';
            }

            var rawCount = hasRaw ? r.raw.length : 0;
            var rawSummary = hasRaw
                ? '<a href="#" class="raw-toggle" data-key="' + attr(key) + '"><i class="fa fa-' + (isOpen ? 'caret-down' : 'caret-right') + '"></i> ' + rawCount + ' raw material' + (rawCount === 1 ? '' : 's')
                    + (r.rawReady ? ' &middot; <span class="text-success">reserved</span>' : '') + '</a>'
                : '<span class="text-muted">-</span>';

            var html = '<tr>'
                + '<td><b>#' + esc(r.smoId) + '</b><span class="sub-note">' + esc(r.orderRef) + '</span><span class="sub-note">' + esc(r.orderDate) + ' &middot; ' + esc(r.orderStatusText) + '</span></td>'
                + '<td>' + esc(r.customer) + '<span class="sub-note">' + esc(r.warehouse) + '</span></td>'
                + '<td><strong>' + esc(r.itemName) + '</strong>' + (r.itemCode ? '<span class="sub-note">' + esc(r.itemCode) + '</span>' : '') + (r.uom ? '<span class="sub-note">' + esc(r.uom) + '</span>' : '') + '</td>'
                + '<td class="num">' + num(r.ordered) + '</td>'
                + '<td class="num">' + num(r.required) + '</td>'
                + '<td class="num">' + num(r.produced) + '</td>'
                + '<td class="num' + (r.pending > 0 ? ' short' : '') + '">' + num(r.pending) + '</td>'
                + '<td><span class="label ' + attr(r.statusClass) + '">' + esc(r.status) + '</span>' + (r.message ? '<span class="sub-note">' + esc(r.message) + '</span>' : '') + '</td>'
                + '<td>' + rawSummary + '</td>'
                + '<td>' + actions + '</td>'
                + '</tr>';
            return html + (hasRaw && isOpen ? rawRowHtml(r) : '');
        }

        $(document).on('click', '.raw-toggle', function (e) {
            e.preventDefault();
            var key = $(this).attr('data-key');
            openRaw[key] = !openRaw[key];
            if (lastResult) {
                renderGrid(lastResult.obj, lastResult.page, lastResult.perpage);
            }
        });

        // ---- Reservation actions (same server rules as the sales order Reserved Items tab) ----
        function runAction(method, data, confirmText) {
            if (busy || !window.confirm(confirmText)) {
                return;
            }
            busy = true;
            $('#tblItems').addClass('busy').find('button').prop('disabled', true);
            $('#pageMessage').html('<div class="alert alert-info"><i class="fa fa-spinner fa-spin"></i> Processing, please wait...</div>');
            post(method, data, function (response) {
                var d = response.d || {};
                showMessage(!!d.ok, d.message || 'The request could not be completed.');
            }, function () {
                showMessage(false, 'The request failed. Please check the grid and try again.');
            }).always(function () {
                busy = false;
                $('#tblItems').removeClass('busy');
                searchItems(currentPage);
            });
        }

        $(document).on('click', '#tblItems .reserve-btn', function () {
            var b = $(this);
            runAction('ReserveItem', { smoId: parseInt(b.attr('data-order'), 10), sioId: parseInt(b.attr('data-sio'), 10), compItmId: parseInt(b.attr('data-comp'), 10) || 0, expectedQty: Number(b.attr('data-qty')) },
                'Reserve ' + num(b.attr('data-qty')) + ' ' + b.attr('data-uom') + ' of "' + b.attr('data-name') + '" for order #' + b.attr('data-order') + ' (oldest stock first, order warehouse)?\n'
                + 'Use "Choose warehouse / batches" to pick another warehouse or specific batches.');
        });
        $(document).on('click', '#tblItems .unreserve-btn', function (e) {
            e.preventDefault();
            var b = $(this);
            runAction('UnreserveItem', { smoId: parseInt(b.attr('data-order'), 10), sioId: parseInt(b.attr('data-sio'), 10), compItmId: parseInt(b.attr('data-comp'), 10) || 0 },
                'Release everything reserved for "' + b.attr('data-name') + '" on order #' + b.attr('data-order') + ' (all warehouses and batches)? Stock quantities are not changed.');
        });
        $(document).on('click', '#tblItems .release-batch', function (e) {
            e.preventDefault();
            var b = $(this);
            runAction('UnreserveBatch', { smoId: parseInt(b.attr('data-order'), 10), sioId: parseInt(b.attr('data-sio'), 10), batchId: parseInt(b.attr('data-batch'), 10) },
                'Release ' + num(b.attr('data-qty')) + ' ' + b.attr('data-uom') + ' reserved in batch ' + b.attr('data-no') + '? Stock quantities are not changed.');
        });

        // ---- Warehouse / batch picker ----
        var pick = null;

        function pickWarehouse() {
            var found = null;
            $.each(pick.data.warehouses, function (i, w) {
                if (w.branchId === pick.warehouseId) { found = w; }
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
                var row = $(this), input = row.find('.batch-qty');
                var raw = $.trim(input.val()), v = raw === '' ? 0 : Number(raw), err = '';
                if (isNaN(v) || v < 0) {
                    err = 'Enter a valid quantity.';
                } else if (v > Number(input.attr('data-max')) + 0.0005) {
                    err = 'Only ' + num(input.attr('data-max')) + ' ' + d.uom + ' available in this batch.';
                }
                row.toggleClass('has-error', !!err).find('.batch-err').text(err);
                if (err) { errors++; }
            });
            var left = Math.round((d.remaining - total) * 1000) / 1000;
            if (left < -0.0005) { over = true; }
            var other = 0;
            $.each(pick.selected, function (id, q) {
                if (q > 0 && pick.batchWarehouse[id] !== pick.warehouseId) { other++; }
            });
            $('#batchTotals').html('Selected: <span class="' + (over ? 'text-danger' : 'text-success') + '">' + num(total) + ' ' + esc(d.uom) + '</span> &nbsp;|&nbsp; Remaining: <span class="' + (over ? 'text-danger' : '') + '">'
                + num(left) + ' ' + esc(d.uom) + '</span>' + (other > 0 ? '<span class="sub-note" style="line-height: 14px;">Includes ' + other + ' batch(es) from other warehouses</span>' : ''));
            $('#batchOverMessage').text(over ? 'The selected quantity exceeds the remaining requirement (' + num(d.remaining) + ' ' + d.uom + ').' : '').toggle(over);
            $('#batchSubmit').prop('disabled', pick.busy || over || errors > 0 || total <= 0);
        }

        function renderPicker() {
            var d = pick.data;
            var warehouseOptions = $.map(d.warehouses, function (w) {
                return '<option value="' + attr(w.branchId) + '"' + (w.branchId === pick.warehouseId ? ' selected' : '') + '>' + esc(w.name) + (w.isHome ? ' (order warehouse)' : '')
                    + ' - ' + num(w.available) + ' ' + esc(d.uom) + ' available</option>';
            }).join('');
            function info(k, v) { return '<div class="info-row"><span class="k">' + k + '</span><span class="v">' + v + '</span></div>'; }
            $('#batchModalTitle').text(d.isComponent ? 'Reserve Raw Material: ' + d.itemName : 'Select Warehouse & Batches: ' + d.itemName);
            var summary = '<div class="pick-summary row"><div class="col-sm-6">'
                + info('Item', esc(d.itemName) + (d.itemCode ? ' (' + esc(d.itemCode) + ')' : ''))
                + (d.isComponent ? info('BOM component of', esc(d.parentName)) : '')
                + info('Sales order', '#' + esc(pick.smoId))
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
                    return '<tr data-batch="' + attr(b.batchId) + '"><td>' + (i + 1) + '</td><td>' + esc(w.name) + '</td><td>' + esc(b.batchNo) + '</td>'
                        + '<td>' + (b.batchDate ? esc(b.batchDate) : '<span class="text-muted">-</span>') + '</td>'
                        + '<td style="text-align: right;">' + num(b.physical) + '</td>'
                        + '<td style="text-align: right;">' + num(b.reserved) + (b.mine > 0 ? '<span class="sub-note">this order: ' + num(b.mine) + '</span>' : '') + '</td>'
                        + '<td style="text-align: right;">' + num(b.available) + '</td>'
                        + '<td style="text-align: right;"><input type="number" class="form-control input-sm batch-qty" min="0" step="any" data-batch="' + attr(b.batchId) + '" data-max="' + attr(b.available) + '"'
                        + (b.available <= 0 ? ' disabled' : '') + (saved > 0 ? ' value="' + num(saved) + '"' : '') + ' /><span class="batch-err"></span></td></tr>';
                }).join('');
            }
            var table = '<div class="batch-table-wrap"><table class="table table-striped jambo_table table-bordered" style="margin-bottom: 0;"><thead style="background-color: #f1eeee; color: #525252"><tr>'
                + '<th>#</th><th>Warehouse</th><th>Batch No</th><th>Batch Date</th><th style="text-align: right;">Physical Stock</th><th style="text-align: right;">Reserved</th>'
                + '<th style="text-align: right;">Available</th><th style="text-align: right;">Qty to Reserve (' + esc(d.uom) + ')</th></tr></thead>'
                + '<tbody id="batchBody">' + (rows || '<tr><td colspan="8" style="text-align: center;">No batches with stock in this warehouse.</td></tr>') + '</tbody></table></div>'
                + '<p class="text-danger" id="batchOverMessage" style="display: none; margin: 8px 0 0 0;"></p>'
                + '<p class="text-muted" style="font-size: 11px; margin: 8px 0 0 0;">Quantities are in ' + esc(d.uom) + '. Use Auto-fill to allocate oldest batches first. Selections are kept when you switch warehouse.</p>';
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
            post('LoadReserveOptions', { smoId: req.smoId, sioId: req.sioId, compItmId: req.compItmId }, function (response) {
                if (pick !== req) { return; }
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
                if (keepMessage) { pickMessage(keepMessage.ok, keepMessage.text); }
            }, function () {
                if (pick === req) {
                    $('#batchModalBody').html('<p class="text-danger">Unable to load warehouse stock. Please close this window and try again.</p>');
                }
            });
        }

        $(document).on('click', '#tblItems .pick-btn', function (e) {
            e.preventDefault();
            if (busy) { return; }
            var b = $(this);
            pick = { smoId: parseInt(b.attr('data-order'), 10), sioId: parseInt(b.attr('data-sio'), 10), compItmId: parseInt(b.attr('data-comp'), 10) || 0, warehouseId: 0, busy: false, selected: {}, batchWarehouse: {} };
            $('#batchModalTitle').text('Select Warehouse & Batches: ' + b.attr('data-name'));
            $('#batchModal').removeClass('processing').modal('show');
            loadPicker();
        });

        $(document).on('hidden.bs.modal', '#batchModal', function () { pick = null; });
        $(document).on('change', '#batchModal #batchWarehouse', function () {
            pick.warehouseId = parseInt($(this).val(), 10) || 0;
            renderPicker();
        });
        $(document).on('input change', '#batchModal .batch-qty', function () {
            var v = Number($(this).val());
            var id = $(this).attr('data-batch');
            if ($.trim($(this).val()) !== '' && !isNaN(v) && v > 0) {
                pick.selected[id] = v;
            } else {
                delete pick.selected[id];
            }
            pickRefreshTotals();
        });
        $(document).on('click', '#batchClear', function () {
            if (pick.busy) { return; }
            pick.selected = {};
            renderPicker();
        });
        $(document).on('click', '#batchFifo', function () {
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
            if (pick.busy || busy || (confirmText && !window.confirm(confirmText))) { return; }
            var req = pick;
            busy = true;
            data.smoId = req.smoId;
            data.sioId = req.sioId;
            data.compItmId = req.compItmId;
            pickMessage(true, '');
            pickBusy(true);
            post(method, data, function (response) {
                var d = response.d || {};
                showMessage(!!d.ok, d.message || 'The request could not be completed.');
                busy = false;
                pickBusy(false);
                if (d.ok) {
                    $('#batchModal').modal('hide');
                } else if (pick === req) {
                    loadPicker({ ok: false, text: d.message || 'The request could not be completed.' });
                }
                searchItems(currentPage);
            }, function () {
                busy = false;
                pickBusy(false);
                pickMessage(false, 'The request failed. Please check the grid and try again.');
                searchItems(currentPage);
            });
        }

        $(document).on('click', '#batchSubmit', function () {
            var allocations = [];
            $.each(pick.selected, function (id, q) {
                allocations.push({ batchId: parseInt(id, 10), qty: q });
            });
            if (!allocations.length) { return; }
            pickFinish('ReserveBatches', { allocations: allocations }, null);
        });
        $(document).on('click', '#batchRelease', function () {
            pickFinish('UnreserveItem', {}, 'Release this order\'s existing reservations for "' + pick.data.itemName + '" (all warehouses and batches)?');
        });

        // ---- Production entry (sp_save_production_entry through ProductionService) ----
        var entryState = { smoId: 0, sioId: 0, busy: false, data: null };

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
                + info('Sales order', esc(o.orderRef) + ' (#' + entryState.smoId + ')')
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
                        return '<tr' + (x.issue ? ' class="text-muted"' : '') + '><td><input type="radio" name="entryReservation" value="' + attr(x.reservationId) + '"' + (x.issue ? ' disabled="disabled"' : '') + ' /></td>'
                            + '<td>' + esc(x.batchNo) + '</td><td>' + (x.warehouse ? esc(x.warehouse) : '<span class="text-muted">-</span>') + '</td>'
                            + '<td style="text-align: right;">' + num(x.reservedQty) + ' ' + esc(x.uom) + '</td>'
                            + '<td style="text-align: right;">' + num(x.outputQty) + uom + '</td>'
                            + '<td>' + (x.issue ? '<span class="text-danger">' + esc(x.issue) + '</span>' : '<span class="text-success"><i class="fa fa-check"></i> Ready</span>') + '</td></tr>';
                    }).join('') + '</tbody></table></div>'
                    + '<p class="text-muted" style="font-size: 11px;">Producing uses the <strong>whole</strong> selected reservation, creates a finished batch of the quantity shown and reserves it for this order. '
                    + 'Stock quantities are updated automatically. This screen allows one production per sales order and one raw material; use <strong>Produce</strong> in the Reserved Items tab of the sales order for other cases.</p>';
            }
            $('#productionEntryBody').html(html);
            $('#productionEntryBody input[name="entryReservation"]:not(:disabled)').first().prop('checked', true);
            entryRefreshButton();
        }

        function loadProductionEntry(smoId, sioId, notice) {
            entryState.smoId = smoId;
            entryState.sioId = sioId;
            entryState.data = null;
            $('#productionEntrySave').prop('disabled', true);
            $('#productionEntryBody').html('<div class="tab-empty"><i class="fa fa-spinner fa-spin"></i> Loading production entry...</div>');
            post('LoadProductionEntry', { smoId: smoId, sioId: sioId }, function (response) {
                var d = response.d;
                if (!d || !d.ok) {
                    $('#productionEntryBody').html('<p class="text-danger">' + esc((d && d.message) || 'Unable to load the production entry.') + '</p>');
                    return;
                }
                entryState.data = d;
                renderProductionEntry(d);
                if (notice) { entryShowMessage(false, notice); }
            }, function () {
                $('#productionEntryBody').html('<p class="text-danger">Unable to load the production entry. Please try again.</p>');
            });
        }

        $(document).on('click', '#tblItems .production-entry-btn', function () {
            if (entryState.busy || busy) { return; }
            $('#productionEntryModal').modal('show');
            loadProductionEntry(parseInt($(this).attr('data-order'), 10), parseInt($(this).attr('data-sio'), 10));
        });
        $(document).on('change', '#productionEntryModal input[name="entryReservation"]', entryRefreshButton);
        $(document).on('click', '#productionEntrySave', function () {
            var sel = entrySelected();
            if (entryState.busy || !sel || sel.issue) { return; }
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
            post('SaveProduction', { smoId: entryState.smoId, sioId: entryState.sioId, reservationId: sel.reservationId, expectedOutput: sel.outputQty }, function (response) {
                var r = response.d || {};
                entryState.busy = false;
                if (r.ok) {
                    $('#productionEntryModal').modal('hide');
                    showMessage(true, r.message);
                    searchItems(currentPage);
                } else {
                    loadProductionEntry(entryState.smoId, entryState.sioId, r.message || 'The production entry could not be saved.');
                }
            }, function () {
                entryState.busy = false;
                loadProductionEntry(entryState.smoId, entryState.sioId, 'The request failed. Check the production history before trying again.');
                searchItems(currentPage);
            }).always(function () {
                $('#productionEntrySpinner').hide();
                $('#productionEntryCancel').prop('disabled', false);
                $('#productionEntryModal .close').show();
            });
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
                                    <label style="font-weight: bold; font-size: 16px;">Production Queue</label>
                                </div>
                                <div class="col-md-6 col-xs-5">
                                    <a href="production_history.aspx">
                                        <div class="btn btn-primary btn-xs pull-right" style="margin-top: 5px"><label style="color: #fff; margin-right: 5px; font-size: 14px;" class="fa fa-history"></label>Production History</div>
                                    </a>
                                    <a href="bulk_production.aspx">
                                        <div class="btn btn-success btn-xs pull-right" style="margin-top: 5px; margin-right: 5px;"><label style="color: #fff; margin-right: 5px; font-size: 14px;" class="fa fa-cubes"></label>Bulk Production</div>
                                    </a>
                                </div>
                            </div>
                        </nav>
                    </div>
                </div>

                <div class="right_col" role="main">
                    <div class="">
                        <div class="clearfix"></div>
                        <% if (!CanProduce) { %>
                        <div class="alert alert-danger">You do not have permission to enter production.</div>
                        <% } else { %>
                        <div id="pageMessage"></div>

                        <div class="row">
                            <div class="col-md-12 col-sm-12 col-xs-12">
                                <div class="x_panel">
                                    <div class="x_title" style="margin-bottom: 0px;">
                                        <strong>Filter</strong>
                                        <ul class="nav navbar-right panel_toolbox">
                                            <li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a></li>
                                        </ul>
                                    </div>
                                    <div class="x_content">
                                        <div class="form-horizontal form-label-left input_mask">
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Order No</label>
                                                <input type="text" class="form-control has-feedback-left" id="txtOrder" placeholder="Order no / Invoice no" />
                                                <span class="fa fa-hashtag form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Customer</label>
                                                <input type="text" class="form-control has-feedback-left" id="txtCustomer" placeholder="Customer name / ID" />
                                                <span class="fa fa-user form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Product</label>
                                                <input type="text" class="form-control has-feedback-left" id="txtProduct" placeholder="Item name / code" />
                                                <span class="fa fa-cube form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Production Status</label>
                                                <select class="form-control" style="text-indent: 25px;" id="slStatus" onchange="searchItems(1);">
                                                    <option value="open" selected="selected">Needs action</option>
                                                    <option value="awaiting">Awaiting raw material</option>
                                                    <option value="ready">Ready to produce</option>
                                                    <option value="partial">Partially produced</option>
                                                    <option value="produced">Produced</option>
                                                    <option value="covered">Covered by stock</option>
                                                    <option value="unavailable">Unavailable</option>
                                                    <option value="all">All statuses</option>
                                                </select>
                                                <span class="fa fa-cogs form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-2 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Date from</label>
                                                <input type="text" class="form-control has-feedback-left" style="background-color: #fff" id="txtSearchFromDate" placeholder="From Date" />
                                                <span class="fa fa-calendar form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-2 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Date upto</label>
                                                <input type="text" class="form-control has-feedback-left" style="background-color: #fff" id="txtSearchToDate" placeholder="To Date" />
                                                <span class="fa fa-calendar form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-2 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Warehouse</label>
                                                <select class="form-control" style="text-indent: 25px;" id="slBranch" onchange="searchItems(1);"></select>
                                                <span class="fa fa-map-marker form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Action By</label>
                                                <select class="form-control" style="text-indent: 25px;" id="slActor" onchange="searchItems(1);"></select>
                                                <span class="fa fa-user-circle form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group">
                                                <label>&nbsp;</label>
                                                <div>
                                                    <div class="btn btn-success mybtnstyl" onclick="searchItems(1, true);">
                                                        <li class="fa fa-search" style="margin-right: 5px;"></li>
                                                        Search
                                                    </div>
                                                    <div class="btn btn-primary mybtnstyl" onclick="resetFilters();">
                                                        <li class="fa fa-refresh" style="margin-right: 5px;"></li>
                                                        Reset
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="clearfix"></div>

                        <div class="row">
                            <div class="col-md-12 col-sm-12 col-xs-12">
                                <div class="x_panel">
                                    <div class="x_title" style="margin-bottom: 0px;">
                                        <div class="col-md-8 col-sm-12 col-xs-12">
                                            <label>Items to Produce</label><span class="badge" style="color: #fff; margin-left: 5px; background: #d00101; padding-left: 5px; padding-right: 5px;" id="txttotalcount"></span>
                                        </div>
                                        <div class="col-md-4 col-sm-12 col-xs-12">
                                            <ul class="nav navbar-right panel_toolbox">
                                                <li>
                                                    <select id="slPerpage" onchange="searchItems(1);" class="input-sm">
                                                        <option value="25">25</option>
                                                        <option value="50">50</option>
                                                        <option value="100">100</option>
                                                    </select></li>
                                            </ul>
                                        </div>
                                        <div class="clearfix"></div>
                                    </div>
                                    <div class="col-md-12 col-sm-12 col-xs-12" id="statusChips" style="padding-top: 10px;"></div>
                                    <div class="clearfix"></div>
                                    <div class="col-md-12 col-sm-12 col-xs-12" style="overflow-x: auto;">
                                        <div class="x_content">
                                            <table id="tblItems" class="table table-striped jambo_table bulk_action" style="table-layout: auto;">
                                                <thead style="background-color: #f1eeee; color: #525252">
                                                    <tr>
                                                        <th>Order</th>
                                                        <th>Customer</th>
                                                        <th>Item</th>
                                                        <th class="num">Ordered</th>
                                                        <th class="num">To Deliver</th>
                                                        <th class="num">Produced</th>
                                                        <th class="num">To Produce</th>
                                                        <th>Status</th>
                                                        <th>Raw Materials</th>
                                                        <th>Actions</th>
                                                    </tr>
                                                </thead>
                                                <tbody></tbody>
                                            </table>
                                            <div id="divPagination"></div>
                                            <p id="truncatedNote" class="text-warning" style="display: none; font-size: 12px;">Only the newest 150 matching orders are shown. Narrow the filters to see older orders.</p>
                                            <p class="text-muted" style="font-size: 11px;">Lists items that have a bill of materials on Approved / Processed sales orders that are not fully delivered. Reserve the raw materials for an item (expand <strong>Raw Materials</strong>), then use <strong>Produce</strong>. Reservations follow the same rules as the Reserved Items tab of the sales order.</p>
                                        </div>
                                    </div>
                                    <div class="clearfix"></div>
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
