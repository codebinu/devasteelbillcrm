<%@ Page Language="C#" AutoEventWireup="true" CodeFile="track_batch_details.aspx.cs" Inherits="web_inventory_track_batch_details" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Batch Details | Track Batch | Invoice Me</title>
    <script src="../js/common.js" type="text/javascript"></script>
    <script type="text/javascript" src="../js/jquery-2.0.3.js"></script>
    <script type="text/javascript" src="../js/jquery.cookie.js"></script>
    <script src="../js/track-batch.js" type="text/javascript"></script>

    <link href="../css/bootstrap/bootstrap.min.css" rel="stylesheet" />
    <link href="../css/font-awesome/css/font-awesome.min.css" rel="stylesheet" />
    <link href="../css/bootstrap/nprogress.css" rel="stylesheet" />
    <link href="../css/bootstrap/daterangepicker.css" rel="stylesheet" />
    <link href="../css/bootstrap/custom.min.css" rel="stylesheet" />
    <link href="../css/bootstrap/mystyle.css" type="text/css" rel="stylesheet" />
    <link href="../css/track-batch.css" type="text/css" rel="stylesheet" />

    <script type="text/javascript">
        var batchId = 0;
        var batchUom = "";

        $(document).ready(function () {
            if (!$.cookie("invntrystaffBranchId")) {
                location.href = "../dashboard.aspx";
                return false;
            }
            batchId = parseInt((location.search.match(/[?&]batchId=(\d+)/) || [])[1], 10) || 0;
            if (!batchId) { showNotFound(); return; }
            loadOverview();
        });

        function showNotFound() {
            $("#divOverview").html('<div class="tb-state tb-error"><i class="fa fa-ban"></i>Batch not found, or you do not have access to its warehouse.</div>');
            $("#divStats, #divTimelinePanel, #divHistoryPanel").hide();
        }

        function loadError(target, retry) {
            $(target).html('<div class="tb-state tb-error"><i class="fa fa-exclamation-triangle"></i>Unable to load this section.<br />'
                + '<button type="button" class="btn btn-primary btn-sm" style="margin-top:10px" onclick="' + retry + '()"><i class="fa fa-refresh"></i> Retry</button></div>');
        }

        // ---------- 1. overview (loaded first) ----------
        function loadOverview() {
            $("#divOverview").html('<span class="tb-skel" style="width:40%;height:28px;margin-bottom:14px"></span><span class="tb-skel" style="width:80%;margin-bottom:8px"></span><span class="tb-skel" style="width:65%"></span>');
            TB.ajax("track_batch_details.aspx/getOverview", { batchId: batchId }, function (o) {
                if (o.notFound) { showNotFound(); return; }
                renderOverview(o);
                loadHistory();
            }, function () { loadError("#divOverview", "loadOverview"); });
        }

        function kv(label, value) {
            return '<dt>' + TB.esc(label) + '</dt><dd>' + (value == null || value === "" ? '<span class="tb-muted">&mdash;</span>' : value) + '</dd>';
        }

        function renderOverview(o) {
            var b = o.batch;
            batchUom = b.uom;
            document.title = b.no + " | Track Batch | Invoice Me";
            var h = '<div class="row"><div class="col-md-12">';
            h += '<div><span class="tb-batchno" id="spBatchNo">' + TB.esc(b.no) + '</span>'
                + '<button type="button" class="btn btn-default btn-xs tb-copy" id="btnCopy" onclick="copyBatchNo()" title="Copy batch number"><i class="fa fa-copy"></i> Copy</button></div>';
            h += '<div style="margin:6px 0 10px">' + TB.typeBadge(b.type) + ' ' + TB.originBadge(b.originLabel == "Purchase" ? "purchase" : b.originLabel == "Production" ? "production" : "none", b.originLabel) + '</div>';
            h += '</div></div>';
            h += '<div class="row">';
            h += '<div class="col-md-3 col-sm-6"><dl class="tb-kv">' + kv("Item", TB.esc(b.item)) + kv("Item code", TB.esc(b.code)) + '</dl></div>';
            h += '<div class="col-md-3 col-sm-6"><dl class="tb-kv">' + kv("Batch ID", TB.esc(b.id)) + kv("Customer batch number", b.type == "customer" ? TB.esc(b.cust) : "") + '</dl></div>';
            h += '<div class="col-md-3 col-sm-6"><dl class="tb-kv">' + kv("Created", TB.date(b.created) + (b.createdBy ? ' <span class="tb-muted tb-small">by ' + TB.esc(b.createdBy) + '</span>' : "")) + kv("Warehouse", TB.esc(b.branch)) + '</dl></div>';
            h += '<div class="col-md-3 col-sm-6"><dl class="tb-kv">' + kv("Current quantity", '<b>' + TB.qtyUom(b.current, b.uom) + '</b>') + kv("Original quantity", TB.qtyUom(b.original, b.uom)) + '</dl></div>';
            h += '</div>';
            h += '<div class="tb-section-title" style="margin-top:14px">Batch origin &ndash; where was this batch created?</div>';
            h += renderOrigin(o.origin);
            $("#divOverview").html(h);
        }

        function renderOrigin(g) {
            if (g.kind == "none") {
                return '<div class="tb-origin none"><div class="tb-origin-title"><i class="fa fa-question-circle"></i> Origin Not Identified</div>'
                    + '<div class="tb-small tb-muted">No purchase line or production output references this batch, or the references are ambiguous, so no origin is shown.</div></div>';
            }
            var h = '<div class="tb-origin ' + TB.esc(g.kind) + '"><div class="tb-origin-title">' + TB.esc(g.title)
                + (g.interstock ? ' <span class="tb-badge tb-badge-interstock">Interstock receipt</span>' : '') + ' ' + TB.status(g.status) + '</div>';
            h += '<div class="row"><div class="col-md-3 col-sm-6"><dl class="tb-kv">' + kv(g.kind == "purchase" ? "Purchase Number" : "Production Number", TB.esc(g.number))
                + kv(g.kind == "purchase" ? "Purchase Entry ID" : "Production Entry ID", TB.esc(g.entryId)) + '</dl></div>';
            h += '<div class="col-md-3 col-sm-6"><dl class="tb-kv">' + kv(g.kind == "purchase" ? "Purchase Date" : "Production Date", TB.date(g.date))
                + (g.partyLabel ? kv(g.partyLabel, TB.esc(g.party)) : "") + '</dl></div>';
            h += '<div class="col-md-3 col-sm-6"><dl class="tb-kv">' + kv(g.kind == "purchase" ? "Purchased Quantity" : "Produced Quantity", TB.qtyUom(g.qty, g.uom))
                + kv(g.kind == "purchase" ? "Item" : "Finished Item", TB.esc(g.item) + (g.code ? ' <span class="tb-muted tb-small">(' + TB.esc(g.code) + ')</span>' : "")) + '</dl></div>';
            h += '<div class="col-md-3 col-sm-6" style="padding-top:18px">';
            if (g.url) h += '<a class="btn btn-primary btn-sm" href="' + TB.esc(g.url) + '"><i class="fa fa-external-link"></i> ' + TB.esc(g.linkLabel) + '</a>';
            h += '</div></div></div>';
            return h;
        }

        function copyBatchNo() {
            TB.copyText($("#spBatchNo").text(), function () {
                $("#btnCopy").html('<i class="fa fa-check"></i> Copied');
                setTimeout(function () { $("#btnCopy").html('<i class="fa fa-copy"></i> Copy'); }, 1500);
            });
        }

        // ---------- 2-4. statistics, timeline and transaction history (loaded after the overview) ----------
        function loadHistory() {
            var sk = '<span class="tb-skel" style="width:90%;margin:10px 0"></span><span class="tb-skel" style="width:70%;margin:10px 0"></span><span class="tb-skel" style="width:80%;margin:10px 0"></span>';
            $("#divStatsBody, #divTimeline, #divHistoryState").html(sk);
            $("#divHistory").hide();
            TB.ajax("track_batch_details.aspx/getHistory", { batchId: batchId }, function (h) {
                if (h.notFound) { showNotFound(); return; }
                renderStats(h);
                renderTimeline(h.timeline);
                renderHistory(h);
            }, function () {
                loadError("#divStatsBody", "loadHistory");
                $("#divTimeline, #divHistoryState").html("");
            });
        }

        function tile(label, value, cls, unit) {
            return '<div class="tb-tile ' + (cls || "") + '"><div class="v">' + value + '</div><div class="l">' + TB.esc(label) + '</div>' + (unit ? '<div class="u">' + TB.esc(unit) + '</div>' : '') + '</div>';
        }

        function renderStats(h) {
            var c = h.counts, q = h.quantities;
            var s = '<div class="tb-section-title">Connected records</div><div class="tb-tiles">'
                + tile("Purchase references", c.purchases) + tile("Production references", c.production) + tile("Sales orders connected", c.salesOrders)
                + tile("Reservations", c.reservations) + tile("Invoices", c.invoices) + tile("Interstock transfers", c.transfers) + tile("Other transactions", c.other) + '</div>';
            s += '<div class="tb-section-title" style="margin-top:12px">Quantities <span class="tb-muted" style="text-transform:none;letter-spacing:0;font-weight:normal">(batch unit: ' + TB.esc(q.uom || "not set") + ')</span></div><div class="tb-tiles">'
                + tile("Original created", TB.qty(q.original), "q") + tile("Currently available", TB.qty(q.current), "q", "physical stock in the batch")
                + tile("Currently reserved", TB.qty(q.reserved), "q") + tile("Total invoiced", TB.qty(q.invoiced), "q")
                + tile("Transferred out", TB.qty(q.transferredOut), "q") + tile("Transferred in", TB.qty(q.transferredIn), "q")
                + tile("Used in production", TB.qty(q.usedInProduction), "q") + '</div>';
            var notes = [];
            notes.push("Currently available is the batch quantity kept by the application (reservations do not reduce it); free stock is available minus reserved.");
            if (q.cancelledConsumed > 0) notes.push(TB.qty(q.cancelledConsumed) + " " + TB.esc(q.uom) + " was invoiced on cancelled or rejected documents; the application does not return it to the batch, so it is not counted in Total invoiced.");
            if (q.partial) notes.push("Some quantities are recorded in a different unit than the batch unit and are not added to the totals above.");
            s += '<div class="tb-note">' + notes.join("<br />") + '</div>';
            $("#divStatsBody").html(s);
        }

        var tlIcons = { created: "fa-plus", received: "fa-download", reservation: "fa-bookmark", invoice: "fa-file-text-o", transfer_in: "fa-sign-in", transfer_out: "fa-sign-out", production: "fa-industry", other: "fa-exchange" };

        function renderTimeline(events) {
            var h = '<ul class="tb-timeline">';
            $.each(events, function (i, e) {
                h += '<li class="tb-tl-item"><span class="tb-tl-dot ' + TB.esc(e.type) + '"><i class="fa ' + (tlIcons[e.type] || "fa-circle") + '"></i></span>';
                h += '<div class="tb-tl-title">' + TB.esc(e.title) + ' &ndash; ' + TB.link(e.reference, e.url) + '</div>';
                h += '<div class="tb-tl-meta">' + (e.ts ? TB.date(e.ts) : '<span class="tb-muted">date not recorded</span>')
                    + (e.qty != null ? ' &middot; ' + TB.qty(e.qty) + ' ' + TB.esc(e.uom || "") : '')
                    + ' &middot; ' + TB.status([e.status, e.statusCss]) + (e.note ? ' &middot; <i>' + TB.esc(e.note) + '</i>' : '') + '</div></li>';
            });
            h += '</ul>';
            $("#divTimeline").html(h);
        }

        function table(head, rows, emptyText) {
            if (!rows.length) return '<div class="tb-state" style="padding:18px"><i class="fa fa-inbox" style="font-size:22px"></i>' + TB.esc(emptyText) + '</div>';
            return '<div style="overflow-x:auto"><table class="table table-hover tb-table"><thead><tr><th>' + head.join("</th><th>") + '</th></tr></thead><tbody>' + rows.join("") + '</tbody></table></div>';
        }

        function row(cells) { return "<tr><td>" + cells.join("</td><td>") + "</td></tr>"; }

        function batchLinks(list) {
            if (!list || !list.length) return '<span class="tb-muted">&mdash;</span>';
            return $.map(list, function (b) { return TB.link(b.no, b.url) + (b.item ? ' <span class="tb-muted tb-small">' + TB.qty(b.qty) + '</span>' : ''); }).join("<br />");
        }

        function renderHistory(h) {
            var c = h.counts;
            var purTotal = c.purchases + h.production.length;
            $("#lblPP").text(purTotal); $("#lblSO").text(c.salesOrders); $("#lblInv").text(c.invoices); $("#lblIst").text(c.transfers); $("#lblOth").text(c.other);

            // purchases & production
            var p = '<div class="tb-sub-title">Purchase entries</div>' + table(["Purchase", "Date", "Supplier / source", "Warehouse", "Quantity", "Status", "Role"],
                $.map(h.purchases, function (r) {
                    return row([TB.link(r.number, r.url) + (r.interstock ? ' <span class="tb-badge tb-badge-interstock">Interstock</span>' : '') + '<div class="tb-muted tb-small">Entry ID ' + TB.esc(r.id) + '</div>',
                        TB.date(r.date), TB.esc(r.party), TB.esc(r.branch), TB.qtyUom(r.qty, r.uom), TB.status(r.status), TB.esc(r.role)]);
                }), "No purchase entry references this batch.");
            p += '<div class="tb-sub-title">Production entries</div>' + table(["Production", "Date", "Role", "Quantity", "Sales order", "Connected batches", "Status"],
                $.map(h.production, function (r) {
                    return row([TB.link(r.number, r.url) + '<div class="tb-muted tb-small">Entry ID ' + TB.esc(r.id) + '</div>', TB.date(r.date), TB.esc(r.role), TB.qtyUom(r.qty, r.uom),
                        r.order ? TB.link(r.order, r.url) : '<span class="tb-muted">&mdash;</span>',
                        '<div class="tb-muted tb-small">' + TB.esc(r.relatedLabel) + '</div>' + batchLinks(r.related), TB.status(r.status)]);
                }), "No production entry references this batch.");
            $("#tabPP").html(p);

            // sales orders & reservations
            var s = table(["Sales order", "Customer", "Order date", "Order status", "Reserved now", "Reservation date", "Released / consumed", "Reservation status"],
                $.map(h.reservations, function (r) {
                    var used = [];
                    if (r.invoiced > 0) used.push("Invoiced " + TB.qty(r.invoiced));
                    if (r.transferred > 0) used.push("Transferred " + TB.qty(r.transferred));
                    if (r.production > 0) used.push("Production " + TB.qty(r.production));
                    return row([TB.link(r.number, r.url), TB.esc(r.customer), TB.date(r.date), TB.status(r.orderStatus), TB.qtyUom(r.reservedNow, batchUom),
                        TB.date(r.reservationDate), used.length ? used.join("<br />") : '<span class="tb-muted">&mdash;</span>', TB.status(r.status)]);
                }), "This batch is not reserved for, or used by, any sales order.");
            s += '<div class="tb-note">The application deletes a reservation when it is consumed or released and keeps no history of it. Active reservations are listed as reserved; consumption is taken from invoices, inter-stock transfers and production entries. A missing reservation date means none was recorded.'
                + (h.orphanReservations > 0 ? ' ' + h.orphanReservations + ' reservation row(s) point to an order line that no longer exists.' : '') + '</div>';
            $("#tabSO").html(s);

            // invoices
            $("#tabInv").html(table(["Invoice", "Date", "Customer", "Sales order", "Invoiced quantity", "Status"],
                $.map(h.invoices, function (r) {
                    return row([TB.link(r.number, r.url), TB.date(r.date), TB.esc(r.customer), r.order ? TB.link(r.order, r.orderUrl) : '<span class="tb-muted">&mdash;</span>',
                        TB.qtyUom(r.qty, r.uom), TB.status(r.status)]);
                }), "No invoice consumed this batch.") + '<div class="tb-note">Inter-stock transfer invoices are listed under Interstock Transfers.</div>');

            // interstock transfers
            $("#tabIst").html(table(["Direction", "Transfer", "Date", "Source", "Destination", "Quantity", "Status", "Related", "Batches"],
                $.map(h.transfers, function (r) {
                    return row([r.direction == "out" ? '<span class="tb-badge tb-badge-interstock"><i class="fa fa-sign-out"></i> Transferred out</span>' : '<span class="tb-badge tb-badge-interstock"><i class="fa fa-sign-in"></i> Transferred in</span>',
                        TB.link(r.urlLabel, r.url), TB.date(r.date), TB.esc(r.fromBranch), TB.esc(r.toBranch), TB.qtyUom(r.qty, r.uom), TB.status(r.status),
                        r.related ? TB.link(r.related, r.relatedUrl) : '<span class="tb-muted">&mdash;</span>',
                        (r.batches && r.batches.length ? '<div class="tb-muted tb-small">' + TB.esc(r.batchesLabel) + '</div>' : '') + batchLinks(r.batches)]);
                }), "This batch was not part of an inter-stock transfer.")
                + '<div class="tb-note">A transfer creates a separate batch in the receiving warehouse; the source batch and the received batch are linked through the transfer invoice and its purchase.</div>');

            // other
            $("#tabOth").html(table(["Type", "Reference", "Date", "Quantity", "Direction", "Note", "Status"],
                $.map(h.other, function (r) {
                    return row([TB.esc(r.type), TB.link(r.reference, r.url), TB.date(r.date), TB.qtyUom(r.qty, r.uom), r.direction == "in" ? "In" : "Out", TB.esc(r.note), TB.status(r.status)]);
                }), "No other stock movement is recorded for this batch.") + '<div class="tb-note">Stock-ledger rows that are not explained by the purchase, production, invoice or transfer records above.</div>');
            $("#divHistoryState").html("");
            $("#divHistory").show();
        }
    </script>
</head>

<body class="nav-md">
    <form id="form1" runat="server" autocomplete="off">
        <div class="container body">
            <div class="main_container">
                <div class="col-md-3 left_col">
                    <div class="left_col scroll-view">
                        <div class="navbar nav_title" style="border: 0;">
                            <a href="#" class="site_title"><span>Invoice</span></a>
                        </div>
                        <div class="clearfix"></div>
                        <div class="profile clearfix"></div>
                        <br />
                        <div id="sidebar-menu" class="main_menu_side hidden-print main_menu"></div>
                        <div class="sidebar-footer hidden-small"></div>
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
                                    <label style="font-weight: bold; font-size: 16px;">Track Batch</label>
                                </div>
                                <div class="col-md-6 col-xs-5">
                                    <a href="track_batch.aspx" class="btn btn-default btn-xs pull-right" style="margin-top: 5px"><i class="fa fa-arrow-left"></i> Back to batches</a>
                                </div>
                            </div>
                        </nav>
                    </div>
                </div>

                <div class="right_col" role="main">
                    <div class="clearfix"></div>

                    <%-- 1. Batch overview --%>
                    <div class="x_panel">
                        <div class="x_content" id="divOverview"></div>
                    </div>

                    <%-- 2. Transaction statistics --%>
                    <div class="x_panel" id="divStats">
                        <div class="x_content" id="divStatsBody"></div>
                    </div>

                    <%-- 3. Batch lifecycle --%>
                    <div class="x_panel" id="divTimelinePanel">
                        <div class="x_title" style="margin-bottom: 8px;"><strong>Batch Lifecycle</strong>
                            <div class="clearfix"></div>
                        </div>
                        <div class="x_content" id="divTimeline"></div>
                    </div>

                    <%-- 4. Transaction history --%>
                    <div class="x_panel" id="divHistoryPanel">
                        <div class="x_title" style="margin-bottom: 0;"><strong>Transaction History</strong>
                            <div class="clearfix"></div>
                        </div>
                        <div class="x_content">
                        <div id="divHistoryState"></div>
                        <div id="divHistory" style="display: none">
                            <ul class="nav nav-tabs tb-tabs" role="tablist">
                                <li class="active"><a href="#tabPP" role="tab" data-toggle="tab">Purchases &amp; Production <span class="badge" id="lblPP">0</span></a></li>
                                <li><a href="#tabSO" role="tab" data-toggle="tab">Sales Orders &amp; Reservations <span class="badge" id="lblSO">0</span></a></li>
                                <li><a href="#tabInv" role="tab" data-toggle="tab">Invoices <span class="badge" id="lblInv">0</span></a></li>
                                <li><a href="#tabIst" role="tab" data-toggle="tab">Interstock Transfers <span class="badge" id="lblIst">0</span></a></li>
                                <li><a href="#tabOth" role="tab" data-toggle="tab">Other Transactions <span class="badge" id="lblOth">0</span></a></li>
                            </ul>
                            <div class="tab-content tb-tab-body">
                                <div class="tab-pane active" id="tabPP"></div>
                                <div class="tab-pane" id="tabSO"></div>
                                <div class="tab-pane" id="tabInv"></div>
                                <div class="tab-pane" id="tabIst"></div>
                                <div class="tab-pane" id="tabOth"></div>
                            </div>
                        </div>
                        </div>
                    </div>
                </div>
                <footer>
                    <div class="pull-right">
                        <div class="footerDiv">
                            <div class="footerDivContent"></div>
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
</body>
</html>
