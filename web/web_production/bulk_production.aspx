<%@ Page Language="C#" AutoEventWireup="true" CodeFile="bulk_production.aspx.cs" Inherits="web_production_bulk_production" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Bulk Production | Invoice Me</title>
    <script src="../js/common.js" type="text/javascript"></script>
    <script type="text/javascript" src="../js/jquery-2.0.3.js"></script>
    <script type="text/javascript" src="../js/jquery.cookie.js"></script>

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
        .sub-note { display: block; color: #777; font-size: 11px; }
        #pageMessage .alert { margin-bottom: 10px; }
        .group-panel { margin-bottom: 15px; }
        .group-head { padding: 8px 10px; background: #f1eeee; border: 1px solid #ddd; overflow: hidden; }
        .group-head .title { float: left; font-size: 14px; }
        .group-head .actions { float: right; }
        .group-head .toggle-group { cursor: pointer; margin-right: 6px; }
        .group-body { border: 1px solid #ddd; border-top: 0; overflow-x: auto; }
        .group-body table { margin-bottom: 0; }
        .group-body th.num, .group-body td.num { text-align: right; white-space: nowrap; }
        .group-body th.chk, .group-body td.chk { width: 30px; }
        .busy .btn { pointer-events: none; opacity: .65; }
        #runLog { max-height: 240px; overflow: auto; margin: 8px 0 0 0; padding-left: 18px; font-size: 12px; }
        #runLog li.ok { color: #3c763d; }
        #runLog li.bad { color: #a94442; }
    </style>

    <script type="text/javascript">
        var running = false;
        var groups = [];

        function esc(s) {
            return $("<div/>").text(s == null ? "" : String(s)).html();
        }

        function attr(s) {
            return esc(s).replace(/"/g, '&quot;').replace(/'/g, '&#39;');
        }

        function num(value) {
            return String(Math.round((Number(value) || 0) * 10000) / 10000);
        }

        function post(method, data, ok, fail) {
            return $.ajax({
                type: 'POST',
                url: 'bulk_production.aspx/' + method,
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
            $("#txtProduct").keypress(function (e) {
                if (e.which == 13) { loadGroups(true); return false; }
            });
            getBranches();
        });

        function getBranches() {
            loading();
            $.ajax({
                type: "POST", url: "bulk_production.aspx/getBranches", data: "{}",
                contentType: "application/json; charset=utf-8", dataType: "json",
                success: function (msg) {
                    var htm = '<option value="-1" selected="selected">--All Warehouses--</option>';
                    $.each(JSON.parse(msg.d), function (i, row) {
                        htm += '<option value="' + attr(row.branch_id) + '">' + esc(row.branch_name) + '</option>';
                    });
                    $("#slBranch").html(htm);
                    Unloading();
                    loadGroups(false);
                },
                error: function () { Unloading(); alert("Internet Problem..!"); }
            });
        }

        function currentFilters() {
            var filters = {};
            if ($.trim($("#txtProduct").val()) != "") filters.product = $.trim($("#txtProduct").val());
            if ($("#slBranch").val() && $("#slBranch").val() != "-1") filters.branch = $("#slBranch").val();
            if ($("#txtSearchFromDate").val() != "") filters.from_date = $("#txtSearchFromDate").val();
            if ($("#txtSearchToDate").val() != "") filters.to_date = $("#txtSearchToDate").val();
            return filters;
        }

        function resetFilters() {
            $("#txtProduct, #txtSearchFromDate, #txtSearchToDate").val("");
            $("#slBranch").val("-1");
            loadGroups(true);
        }

        // refresh = true recomputes the board on the server instead of reusing the short-lived cached result.
        function loadGroups(refresh) {
            var filters = currentFilters();
            if (refresh) { filters.refresh = '1'; }
            loading();
            return post('searchGroups', { filters: filters }, function (msg) {
                Unloading();
                if (msg.d == "E") {
                    groups = [];
                    $('#groupList').html('<p class="text-danger">Unable to load production items. Please try again.</p>');
                    $('#txtGroupCount').text(0);
                    return;
                }
                var obj = JSON.parse(msg.d);
                groups = obj.groups;
                $('#txtGroupCount').text(obj.count);
                $('#truncatedNote').toggle(!!obj.truncated);
                renderGroups();
            }, function () { Unloading(); alert("Internet Problem..!"); });
        }

        function lineKey(o) { return o.smoId + '-' + o.sioId; }

        function renderGroups() {
            if (!groups.length) {
                $('#groupList').html('<div class="tab-empty" style="text-align:center;color:#888;padding:30px 0;">No open production items were found for these filters.</div>');
                return;
            }
            $('#groupList').html($.map(groups, function (g, gi) {
                var rows = $.map(g.orders, function (o) {
                    var box = o.ready
                        ? '<input type="checkbox" class="line-check" data-group="' + gi + '" value="' + attr(lineKey(o)) + '" checked="checked" />'
                        : '';
                    return '<tr' + (o.ready ? '' : ' class="text-muted"') + '><td class="chk">' + box + '</td>'
                        + '<td><b>#' + esc(o.smoId) + '</b><span class="sub-note">' + esc(o.orderRef) + ' &middot; ' + esc(o.orderDate) + '</span></td>'
                        + '<td>' + esc(o.customer) + '</td>'
                        + '<td>' + esc(o.warehouse) + '</td>'
                        + '<td class="num">' + num(o.pending) + ' ' + esc(g.uom) + '</td>'
                        + '<td><span class="label ' + attr(o.statusClass) + '">' + esc(o.status) + '</span>' + (o.ready || !o.message ? '' : '<span class="sub-note">' + esc(o.message) + '</span>') + '</td>'
                        + '<td>' + esc(o.raw) + '</td></tr>';
                }).join('');
                return '<div class="group-panel" data-group="' + gi + '">'
                    + '<div class="group-head"><div class="title"><i class="fa fa-caret-down toggle-group"></i><strong>' + esc(g.itemName) + '</strong>'
                    + (g.itemCode ? ' <span class="text-muted">(' + esc(g.itemCode) + ')</span>' : '')
                    + ' &middot; ' + g.orders.length + ' order' + (g.orders.length === 1 ? '' : 's') + ' (' + g.readyCount + ' ready) &middot; ' + num(g.totalPending) + ' ' + esc(g.uom) + '</div>'
                    + '<div class="actions"><span class="group-selected text-muted" style="margin-right: 10px;"></span>'
                    + '<button type="button" class="btn btn-xs btn-primary produce-group" data-group="' + gi + '"><i class="fa fa-cogs"></i> Produce selected</button></div></div>'
                    + '<div class="group-body"><table class="table table-striped table-bordered"><thead><tr><th class="chk"><input type="checkbox" class="group-check" data-group="' + gi + '" checked="checked" /></th>'
                    + '<th>Order</th><th>Customer</th><th>Warehouse</th><th class="num">To Produce</th><th>Status</th><th>Raw material reserved</th></tr></thead><tbody>' + rows + '</tbody></table></div></div>';
            }).join(''));
            $.each(groups, function (gi) { refreshGroup(gi); });
        }

        function selectedLines(gi) {
            var g = groups[gi], keys = {}, list = [];
            $('#groupList .line-check[data-group="' + gi + '"]:checked').each(function () { keys[$(this).val()] = true; });
            $.each(g.orders, function (i, o) { if (o.ready && keys[lineKey(o)]) { list.push(o); } });
            return list;
        }

        function refreshGroup(gi) {
            var list = selectedLines(gi), total = 0;
            $.each(list, function (i, o) { total += Number(o.pending) || 0; });
            var panel = $('#groupList .group-panel[data-group="' + gi + '"]');
            panel.find('.group-selected').text(list.length + ' selected \u00b7 ' + num(total) + ' ' + groups[gi].uom);
            panel.find('.produce-group').prop('disabled', running || list.length === 0);
            var all = $('#groupList .line-check[data-group="' + gi + '"]');
            panel.find('.group-check').prop('disabled', running || all.length === 0).prop('checked', all.length > 0 && all.filter(':checked').length === all.length);
        }

        $(document).on('change', '#groupList .line-check', function () { refreshGroup(parseInt($(this).attr('data-group'), 10)); });
        $(document).on('change', '#groupList .group-check', function () {
            var gi = parseInt($(this).attr('data-group'), 10);
            $('#groupList .line-check[data-group="' + gi + '"]').prop('checked', $(this).is(':checked'));
            refreshGroup(gi);
        });
        $(document).on('click', '#groupList .toggle-group', function () {
            var panel = $(this).closest('.group-panel');
            var hidden = panel.find('.group-body').toggle().is(':hidden');
            $(this).toggleClass('fa-caret-down', !hidden).toggleClass('fa-caret-right', hidden);
        });

        function log(ok, text) {
            $('#runLog').append('<li class="' + (ok ? 'ok' : 'bad') + '">' + esc(text) + '</li>');
            var box = $('#runLog')[0];
            box.scrollTop = box.scrollHeight;
        }

        function setRunning(on) {
            running = on;
            $('#groupList').toggleClass('busy', on);
            $('#groupList input, #groupList button').prop('disabled', on);
            if (!on) { $.each(groups, function (gi) { refreshGroup(gi); }); }
        }

        // Orders are produced one request at a time: the production procedure handles a single order, and one failure must not stop the rest.
        $(document).on('click', '#groupList .produce-group', function () {
            if (running) { return; }
            var gi = parseInt($(this).attr('data-group'), 10), g = groups[gi], list = selectedLines(gi), total = 0;
            if (!list.length) { return; }
            $.each(list, function (i, o) { total += Number(o.pending) || 0; });
            if (!window.confirm('Produce ' + num(total) + ' ' + g.uom + ' of "' + g.itemName + '" for ' + list.length + ' order' + (list.length === 1 ? '' : 's') + '?\n'
                + 'Each order is produced separately: its whole reserved raw material is used and the finished stock is reserved for that order.')) {
                return;
            }
            setRunning(true);
            showMessage(true, '');
            $('#runPanel').show();
            $('#runLog').empty();
            var done = 0, okCount = 0, failCount = 0, stopped = false;

            function progress() {
                $('#runStatus').html('<i class="fa fa-spinner fa-spin"></i> Producing ' + esc(g.itemName) + ': ' + done + ' of ' + list.length + ' processed');
            }

            function finish() {
                setRunning(false);
                $('#runStatus').text(g.itemName + ': ' + okCount + ' produced, ' + failCount + ' failed' + (stopped ? ', ' + (list.length - done) + ' not processed' : '') + '.');
                showMessage(failCount === 0 && !stopped, g.itemName + ': ' + okCount + ' order' + (okCount === 1 ? '' : 's') + ' produced'
                    + (failCount ? ', ' + failCount + ' failed (see the log below)' : '') + (stopped ? '. The connection failed, so ' + (list.length - done) + ' were not processed. Reload and check Production History' : '') + '.');
                loadGroups(true);
            }

            function next(i) {
                if (i >= list.length) { finish(); return; }
                var o = list[i], label = 'Order #' + o.smoId + ' (' + o.orderRef + ')';
                progress();
                post('ProduceLine', { smoId: o.smoId, sioId: o.sioId, expectedPending: Number(o.pending) }, function (response) {
                    var r = response.d || {};
                    done++;
                    if (r.ok) { okCount++; } else { failCount++; }
                    log(!!r.ok, label + ': ' + (r.message || (r.ok ? 'Produced.' : 'Could not be produced.')));
                    next(i + 1);
                }, function () {
                    // The outcome of this order is unknown, so nothing further is attempted.
                    stopped = true;
                    failCount++;
                    done++;
                    log(false, label + ': the request failed. Check Production History before retrying.');
                    finish();
                });
            }
            next(0);
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
                                    <label style="font-weight: bold; font-size: 16px;">Bulk Production</label>
                                </div>
                                <div class="col-md-6 col-xs-5">
                                    <a href="start_production.aspx">
                                        <div class="btn btn-primary btn-xs pull-right" style="margin-top: 5px"><label style="color: #fff; margin-right: 5px; font-size: 14px;" class="fa fa-tasks"></label>Production Queue</div>
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
                                                <label>Product</label>
                                                <input type="text" class="form-control has-feedback-left" id="txtProduct" placeholder="Item name / code" />
                                                <span class="fa fa-cube form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Warehouse</label>
                                                <select class="form-control" style="text-indent: 25px;" id="slBranch" onchange="loadGroups(true);"></select>
                                                <span class="fa fa-map-marker form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-2 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Order date from</label>
                                                <input type="text" class="form-control has-feedback-left" style="background-color: #fff" id="txtSearchFromDate" placeholder="From Date" />
                                                <span class="fa fa-calendar form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-2 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Order date upto</label>
                                                <input type="text" class="form-control has-feedback-left" style="background-color: #fff" id="txtSearchToDate" placeholder="To Date" />
                                                <span class="fa fa-calendar form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-2 col-sm-12 col-xs-12 form-group">
                                                <label>&nbsp;</label>
                                                <div>
                                                    <div class="btn btn-success mybtnstyl" onclick="loadGroups(true);">
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

                        <div class="row" id="runPanel" style="display: none;">
                            <div class="col-md-12 col-sm-12 col-xs-12">
                                <div class="x_panel">
                                    <div id="runStatus" style="font-weight: 600;"></div>
                                    <ul id="runLog"></ul>
                                </div>
                            </div>
                        </div>

                        <div class="row">
                            <div class="col-md-12 col-sm-12 col-xs-12">
                                <div class="x_panel">
                                    <div class="x_title" style="margin-bottom: 0px;">
                                        <label>Items Needing Production</label><span class="badge" style="color: #fff; margin-left: 5px; background: #d00101; padding-left: 5px; padding-right: 5px;" id="txtGroupCount"></span>
                                        <div class="clearfix"></div>
                                    </div>
                                    <div class="x_content">
                                        <div id="groupList"></div>
                                        <p id="truncatedNote" class="text-warning" style="display: none; font-size: 12px;">Only the newest 150 matching orders are considered. Narrow the filters to see older orders.</p>
                                        <p class="text-muted" style="font-size: 11px;">Groups the open Production Queue lines (awaiting raw material, ready, partially produced) by finished item across Approved / Processed sales orders. Only lines whose raw material is fully reserved (<strong>Ready to produce</strong>) can be ticked; reserve the rest in the <a href="start_production.aspx">Production Queue</a>. Use <strong>Produce selected</strong> to process the ticked orders together. Each order still gets its own production entry and finished batch (one entry per order). Ready orders whose raw material is split over several batches or does not match the pending quantity are reported as failed in the log; produce them from the Production Queue.</p>
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
