// Shared helpers for the Stock View pages (builds on the TB helpers of track-batch.js).
var SV = (function () {
    var STATUS = {
        healthy: ["Healthy", "Enough stock after the pending sales-order demand."],
        reserved: ["Reserved", "Stock is available but already committed to sales orders."],
        pending: ["Pending Demand", "Active sales orders still need stock reserved; free stock covers it."],
        shortage: ["Shortage", "Free stock is not enough for the stock still needed by active sales orders."],
        zero: ["Zero Stock", "No physical stock."],
        negative: ["Negative Stock", "The recorded stock is below zero."]
    };
    var TYPES = { finished: "Finished Goods", raw: "Raw Material", other: "Other" };

    function statusBadge(s) {
        var d = STATUS[s] || [s || "", ""];
        return '<span class="sv-badge sv-badge-' + TB.esc(s) + '" title="' + TB.esc(d[1]) + '">' + TB.esc(d[0]) + '</span>';
    }

    function typeBadge(t) {
        return '<span class="sv-badge sv-badge-' + TB.esc(t) + '">' + TB.esc(TYPES[t] || t) + '</span>';
    }

    // every stock quantity is shown with exactly 3 decimals
    function q(v) {
        var n = Number(v);
        if (v == null || v === "" || isNaN(n)) return "&mdash;";
        var s = n.toFixed(3);
        if (/^-0\.000$/.test(s)) s = "0.000";
        var parts = s.split(".");
        parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        return parts.join(".");
    }

    // quantity cell: tabular, zero muted, optional negative highlight
    function numCell(v, highlightNegative) {
        var n = Number(v), cls = "num";
        if (Math.abs(n) < 0.0005) cls += " zero";
        else if (n < 0 && highlightNegative) cls += " neg";
        return '<td class="' + cls + '">' + q(v) + '</td>';
    }

    function tip(text) {
        return '<i class="fa fa-info-circle" title="' + TB.esc(text) + '"></i>';
    }

    var HELP = {
        phys: "Physical Stock: the stock currently held (the stock balance the stock workflows maintain). Invoiced quantity has already left it.",
        resv: "Reserved Stock: quantity held for sales orders that has not been invoiced or released yet.",
        free: "Free Stock = Physical Stock - Reserved Stock.",
        pend: "Pending Reservation: what active sales orders (Approved, Processed, Partially Delivered) still need, less what is already reserved and invoiced.",
        proj: "Projected Balance = Free Stock - Pending Reservation. A negative value is a planning warning, not a ledger balance."
    };

    return { q: q, statusBadge: statusBadge, typeBadge: typeBadge, numCell: numCell, tip: tip, help: HELP };
})();
