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
        #tabReserved .res-actions .btn { display: block; margin-bottom: 4px; white-space: nowrap; min-width: 96px; }
        #produceModal .modal-content { display: flex; flex-direction: column; max-height: calc(100vh - 60px); border-radius: 4px; }
        #produceModal .modal-header { flex: 0 0 auto; padding: 14px 20px 12px; border-bottom: 1px solid #e6e9ed; }
        #produceModal .modal-title { font-size: 17px; font-weight: 600; color: #2a3f54; line-height: 22px; }
        #produceModal .modal-subtitle { margin-top: 2px; font-size: 13px; color: #6b7785; word-break: break-word; }
        #produceModal .modal-header .close { margin-top: 0; font-size: 26px; opacity: .6; }
        #produceModal .modal-header .close:hover { opacity: 1; }
        #produceModal .modal-body { flex: 1 1 auto; min-height: 0; overflow-y: auto; padding: 16px 20px; }
        #produceModal .modal-footer { flex: 0 0 auto; display: flex; flex-wrap: wrap; align-items: center; justify-content: flex-end; gap: 8px; padding: 12px 20px; border-top: 1px solid #e6e9ed; background: #fff; }
        #produceModal .modal-footer:before, #produceModal .modal-footer:after { display: none; }
        #produceModal .modal-footer .btn { min-width: 84px; height: 34px; margin: 0; }
        #produceModal .modal-footer .pc-spinner { margin-right: auto; color: #6b7785; }
        #produceModal.processing .modal-body { opacity: .6; }
        #produceModal .pc-qty-box { display: flex; flex-wrap: wrap; align-items: center; gap: 8px 16px; margin-bottom: 16px; padding: 10px 14px; background: #fdf3e0; border-left: 4px solid #f0ad4e; }
        #produceModal .pc-qty-box label { margin: 0; font-size: 13px; font-weight: 600; color: #2a3f54; }
        #produceModal .pc-qty-input { display: inline-flex; align-items: center; gap: 6px; }
        #produceModal .pc-qty-input .form-control { width: 140px; height: 34px; text-align: right; }
        #produceModal .pc-qty-hint { font-size: 12px; color: #6b7785; }
        #produceModal .pc-heading { margin: 22px 0 10px 0; font-size: 15px; font-weight: 600; color: #2a3f54; }
        #produceModal .pc-heading:first-child, #produceModal .pc-alert + .pc-heading { margin-top: 6px; }
        #produceModal .pc-k { margin-bottom: 4px; font-size: 11px; font-weight: 600; letter-spacing: .04em; text-transform: uppercase; color: #8a95a3; }
        #produceModal .pc-res-row { display: flex; align-items: baseline; justify-content: space-between; gap: 16px; padding: 6px 0; font-size: 13px; color: #2a3f54; }
        #produceModal .pc-res-name { flex: 1 1 auto; min-width: 0; word-break: break-word; }
        #produceModal .pc-deduct { margin-top: 14px; padding: 10px 14px; background: #f6f9fc; border-radius: 3px; }
        #produceModal .pc-table { margin-bottom: 12px; }
        #produceModal .pc-table > thead > tr > th { background: #f1f3f6; color: #4a5766; font-size: 12px; font-weight: 600; vertical-align: middle; }
        #produceModal .pc-table > tbody > tr > td { font-size: 13px; vertical-align: middle; }
        #produceModal .pc-table .num { text-align: right; white-space: nowrap; }
        #produceModal .pc-table .sub-note { display: block; color: #777; font-size: 11px; }
        #produceModal .pc-alert { margin-bottom: 12px; }
        #produceModal .pc-wh { margin-bottom: 14px; padding: 16px 18px; border: 1px solid #d9e0e8; border-left: 4px solid #5cb85c; background: #fff; }
        #produceModal .pc-wh-head { display: flex; flex-wrap: wrap; justify-content: space-between; align-items: baseline; gap: 4px 12px; margin-bottom: 12px; font-size: 15px; }
        #produceModal .pc-wh-max { font-size: 13px; color: #4a5766; }
        #produceModal .pc-wh-action { display: flex; flex-wrap: wrap; align-items: center; gap: 8px 10px; margin-top: 14px; padding-top: 14px; border-top: 1px solid #eef0f3; font-size: 14px; }
        #produceModal .pc-wh-action label { margin: 0; font-weight: 600; color: #2a3f54; }
        #produceModal .pc-wh-action .form-control { width: 130px; height: 36px; text-align: right; }
        #produceModal .pc-wh-action .btn { height: 36px; padding: 6px 20px; font-weight: 600; }
        #produceModal .pc-calc { margin-top: 0; }
        #produceModal .pc-calc .pc-table { margin: 8px 0 4px; }
        #produceModal .pc-calc .pc-mat > td { background: #f7f9fb; font-weight: 600; }
        #produceModal .pc-bom { margin-bottom: 20px; }
        #produceModal .pc-bom-head, #produceModal .pc-mat-main { display: grid; grid-template-columns: minmax(0, 3fr) repeat(2, minmax(0, 1fr)) minmax(0, 1.4fr) 76px; column-gap: 16px; align-items: center; }
        #produceModal .pc-bom-head { padding: 0 4px 8px; border-bottom: 1px solid #e3e7ec; font-size: 11px; font-weight: 600; letter-spacing: .04em; text-transform: uppercase; color: #8a95a3; }
        #produceModal .pc-bom-head > div:nth-child(n+2):nth-child(-n+3) { text-align: right; }
        #produceModal .pc-mat-row { padding: 14px 4px; border-bottom: 1px solid #eef0f3; }
        #produceModal .pc-mat-row:last-child { border-bottom: 0; }
        #produceModal .pc-mat-title { font-size: 14px; font-weight: 600; line-height: 1.35; color: #2a3f54; overflow: hidden; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; word-break: break-word; }
        #produceModal .pc-mat-sub { margin-top: 2px; font-size: 11px; color: #8a95a3; }
        #produceModal .pc-tip { margin-left: 3px; color: #a9b2bd; cursor: help; }
        #produceModal .pc-q { text-align: right; font-size: 14px; font-weight: 500; color: #34495e; font-variant-numeric: tabular-nums; white-space: nowrap; }
        #produceModal .pc-u { margin-left: 4px; font-size: 11px; font-weight: 400; color: #9aa4b1; }
        #produceModal .pc-q.pc-ok { color: #3f8f5b; }
        #produceModal .pc-q.pc-bad { color: #d9534f; font-weight: 600; }
        #produceModal .pc-q.pc-bad .pc-u { color: #e49a98; }
        #produceModal .pc-q.pc-none { color: #c3cad3; }
        #produceModal .pc-status { display: flex; align-items: center; gap: 6px; font-size: 12px; color: #6b7785; }
        #produceModal .pc-dot { flex: 0 0 auto; width: 7px; height: 7px; border-radius: 50%; background: #c3cad3; }
        #produceModal .pc-status.pc-ok .pc-dot { background: #5cb85c; }
        #produceModal .pc-status.pc-warn .pc-dot { background: #f0ad4e; }
        #produceModal .pc-status.pc-bad .pc-dot { background: #d9534f; }
        #produceModal .pc-status.pc-info .pc-dot { background: #5bc0de; }
        #produceModal .pc-act { display: flex; justify-content: flex-end; }
        #produceModal .pc-act .btn { padding: 3px 12px; font-size: 12px; line-height: 1.5; border-radius: 3px; color: #337ab7; background: #fff; border: 1px solid #b9d3ea; }
        #produceModal .pc-act .btn:hover, #produceModal .pc-act .btn:focus { background: #eef5fb; border-color: #337ab7; }
        #produceModal .pc-act.pc-act-need .btn { color: #fff; background: #337ab7; border-color: #337ab7; }
        #produceModal .pc-act.pc-act-need .btn:hover, #produceModal .pc-act.pc-act-need .btn:focus { background: #2a699e; }
        #produceModal .pc-mat-issue .pc-issue-text { grid-column: 2 / -1; font-size: 12px; color: #d9534f; }
        #produceModal .pc-details { margin-top: 8px; font-size: 12px; color: #6b7785; }
        #produceModal .pc-details summary { display: inline-block; cursor: pointer; color: #8a95a3; outline: 0; }
        #produceModal .pc-details > div { margin-top: 4px; padding-left: 14px; }
        #produceModal .pc-det-qty { margin-left: 6px; color: #34495e; font-variant-numeric: tabular-nums; }
        @media (max-width: 767px) {
            #produceModal .pc-bom-head { display: none; }
            #produceModal .pc-mat-main { grid-template-columns: repeat(3, minmax(0, 1fr)); row-gap: 12px; }
            #produceModal .pc-mat-name { grid-column: 1 / -1; }
            #produceModal .pc-mat-issue .pc-issue-text { grid-column: 1 / -1; }
            #produceModal .pc-q { text-align: left; }
            #produceModal .pc-q:before, #produceModal .pc-status:before { display: block; content: attr(data-label); font-size: 10px; font-weight: 600; letter-spacing: .04em; text-transform: uppercase; color: #9aa4b1; }
            #produceModal .pc-status { display: block; }
            #produceModal .pc-dot { display: inline-block; margin-right: 6px; }
            #produceModal .pc-act { grid-column: 1 / -1; }
        }
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
        #batchModal .modal-content { display: flex; flex-direction: column; max-height: calc(100vh - 60px); border-radius: 4px; }
        #batchModal .modal-header { flex: 0 0 auto; padding: 14px 20px 12px; border-bottom: 1px solid #e6e9ed; }
        #batchModal .modal-title { font-size: 17px; font-weight: 600; color: #2a3f54; line-height: 22px; }
        #batchModal .modal-subtitle { margin-top: 2px; font-size: 13px; color: #6b7785; word-break: break-word; }
        #batchModal .modal-header .close { margin-top: 0; font-size: 26px; opacity: .6; }
        #batchModal .modal-header .close:hover { opacity: 1; }
        #batchModal .modal-body { flex: 1 1 auto; min-height: 0; overflow-y: auto; padding: 16px 20px; }
        #batchModal .modal-footer { flex: 0 0 auto; display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 8px 16px; padding: 12px 20px; border-top: 1px solid #e6e9ed; background: #fff; }
        #batchModal .modal-footer:before, #batchModal .modal-footer:after { display: none; }
        #batchModal .modal-footer .btn { min-width: 84px; height: 34px; margin: 0 0 0 8px; }
        #batchModal .modal-footer .btn-link { min-width: 0; color: #a94442; }
        #batchModal .pick-totals { display: flex; flex-wrap: wrap; align-items: center; gap: 2px 20px; text-align: left; font-weight: 400; color: #6b7785; line-height: 20px; }
        #batchModal .pick-totals #batchTotals { display: flex; flex-wrap: wrap; align-items: center; gap: 2px 0; }
        #batchModal .pick-totals .pt-item { white-space: nowrap; margin-right: 20px; }
        #batchModal .pick-totals .pt-item + .pt-item { padding-left: 20px; border-left: 1px solid #dfe3e8; }
        #batchModal .pick-totals .pt-item strong { margin-left: 6px; font-size: 14px; color: #2a3f54; }
        #batchModal .pick-totals .pt-item strong.text-success { color: #1a7f4b; }
        #batchModal .pick-totals .pt-item strong.text-warning { color: #b26a00; }
        #batchModal .pick-actions { display: flex; flex-wrap: wrap; align-items: center; justify-content: flex-end; }
        #batchModal.processing .modal-body, #batchModal.processing .modal-footer .pick-totals { opacity: .6; }
        #batchModal .pick-summary { display: flex; flex-direction: column; gap: 12px; margin-bottom: 18px; }
        #batchModal .pick-metrics { display: flex; gap: 12px; }
        #batchModal .pick-metric { flex: 1 1 0; min-width: 0; padding: 10px 14px; background: #f6f7f9; border: 1px solid #e6e9ed; border-left: 4px solid #c3cad3; border-radius: 3px; }
        #batchModal .pick-metric .pick-n { display: block; margin-top: 4px; font-size: 20px; line-height: 24px; font-weight: 600; color: #2a3f54; white-space: nowrap; }
        #batchModal .pick-metric .pick-n small { margin-left: 2px; font-size: 12px; font-weight: 400; color: #6b7785; }
        #batchModal .pick-metric-main { background: #eef5fc; border-color: #b9d4ee; border-left-color: #1f6fb5; }
        #batchModal .pick-metric-main .pick-n { color: #1f6fb5; }
        #batchModal .pick-items { display: flex; flex-wrap: wrap; gap: 12px 24px; padding: 10px 14px; border: 1px solid #e6e9ed; border-radius: 3px; }
        #batchModal .pick-info { flex: 1 1 260px; min-width: 0; }
        #batchModal .pick-k { display: block; margin-bottom: 2px; font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: .4px; color: #8a94a0; }
        #batchModal .pick-v { display: block; font-size: 13px; line-height: 18px; font-weight: 600; color: #2a3f54; word-break: break-word; }
        #batchModal .pick-section { margin-bottom: 16px; }
        #batchModal .pick-heading { display: block; margin-bottom: 6px; font-size: 13px; font-weight: 600; color: #2a3f54; }
        #batchModal #batchWarehouse { height: 36px; }
        #batchModal .batch-table-wrap { max-height: 320px; overflow: auto; border: 1px solid #e6e9ed; border-radius: 3px; }
        #batchModal .batch-table { width: 100%; margin: 0; table-layout: auto; }
        #batchModal .batch-table > thead > tr > th { position: sticky; top: 0; z-index: 1; padding: 10px 10px; background: #f1f3f6; color: #4a5766; font-size: 12px; font-weight: 600; border-bottom: 1px solid #dfe3e8; border-top: 0; vertical-align: middle; }
        #batchModal .batch-table > tbody > tr > td { padding: 8px 10px; border-top: 1px solid #eef0f3; vertical-align: middle; font-size: 13px; }
        #batchModal .batch-table .num { text-align: right; white-space: nowrap; }
        #batchModal .batch-table .qty-col { background: #f5f9fd; width: 150px; }
        #batchModal .batch-table > thead > tr > th.qty-col { background: #e9f1fa; }
        #batchModal .batch-table .sub-note { font-size: 11px; }
        #batchModal .batch-table tr.batch-empty td { padding: 28px 10px; text-align: center; color: #8a94a0; }
        #batchModal .batch-table tr.batch-empty .fa { margin-right: 6px; }
        #batchModal .batch-qty { width: 120px; height: 30px; margin-left: auto; text-align: right; }
        #batchModal .has-error .batch-qty { border-color: #a94442; }
        #batchModal .batch-err { display: block; color: #a94442; font-size: 11px; }
        #batchModal .pick-help { display: flex; gap: 8px; margin-top: 12px; padding: 8px 12px; background: #f6f7f9; border-radius: 3px; font-size: 11px; line-height: 16px; color: #6b7785; }
        #batchModal .pick-help .fa { margin-top: 2px; }
        #batchModal .pick-help ul { margin: 0; padding: 0; list-style: none; columns: 2; column-gap: 20px; }
        #batchModal .pick-help li { break-inside: avoid; padding-bottom: 2px; }
        #tabInterstock .sub-note { display: block; color: #777; font-size: 11px; }
        #tabInterstock .it-actions .btn { margin-right: 4px; white-space: nowrap; }
        #tabInterstock .it-toolbar { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; }
        #tabInterstock tr.it-detail > td { background: #fafafa; }
        #tabInterstock .it-box { display: flex; flex-wrap: wrap; gap: 16px; }
        #tabInterstock .it-section { flex: 1 1 420px; min-width: 0; }
        #tabInterstock .it-section h5 { font-weight: bold; margin: 0 0 6px 0; }
        #tabInterstock .it-pair { overflow: hidden; padding: 2px 0; font-size: 12px; }
        #tabInterstock .it-pair .k { float: left; width: 90px; color: #777; }
        #tabInterstock .it-pair .v { font-weight: 600; }
        #tabInterstock .it-section table { margin: 6px 0; background: #fff; font-size: 12px; }
        #tabInterstock .it-totals { margin-bottom: 6px; font-size: 12px; font-weight: 600; }

        /* One-row overview below the order header */
        .so-overview { display: flex; align-items: stretch; background: #fff; border: 1px solid #E6E9ED; border-radius: 3px; margin: 0 0 10px 0; min-height: 46px; }
        .so-overview .ov-item { display: flex; align-items: center; flex: 1 1 0; min-width: 0; padding: 6px 14px; color: #333; text-decoration: none; border-left: 1px solid #eef0f2; line-height: 1.25; }
        .so-overview .ov-item:first-child { border-left: 0; }
        .so-overview .ov-metric { flex: 1.3 1 0; }
        a.ov-item:hover, a.ov-item:focus { background: #f7f9fa; text-decoration: none; color: #333; outline: none; }
        .so-overview .ov-ico { flex: 0 0 auto; width: 26px; height: 26px; border-radius: 50%; background: #eef6f4; color: #26b99a; text-align: center; line-height: 26px; font-size: 13px; margin-right: 10px; }
        .so-overview .ov-body { min-width: 0; flex: 1 1 auto; }
        .so-overview .ov-label { display: block; color: #8a949b; font-size: 10px; letter-spacing: .5px; text-transform: uppercase; white-space: nowrap; }
        .so-overview .ov-value { display: block; font-size: 13px; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .so-overview .ov-value small { font-weight: 400; color: #8a949b; font-size: 12px; }
        .so-overview .ov-pct { font-size: 17px; font-weight: 700; margin-right: 4px; }
        .so-overview .ov-bar { height: 4px; background: #eceff1; border-radius: 2px; margin-top: 4px; overflow: hidden; }
        .so-overview .ov-bar > span { display: block; height: 100%; width: 0; border-radius: 2px; transition: width .5s ease, background-color .5s ease; }
        .so-overview .ov-real { display: block; }
        .so-overview .ov-skel { display: none; }
        .so-overview.ov-loading .ov-skel { display: block; height: 10px; width: 80%; border-radius: 3px; margin: 3px 0; background: linear-gradient(90deg, #eceff1 25%, #f6f8f9 50%, #eceff1 75%); background-size: 200% 100%; animation: ovShimmer 1.2s linear infinite; }
        .so-overview.ov-loading .ov-real { display: none; }
        .so-overview .ov-error { color: #a94442; font-size: 12px; padding: 12px 14px; }
        @keyframes ovShimmer { from { background-position: 200% 0; } to { background-position: -200% 0; } }
        @media (max-width: 991px) {
            .so-overview { flex-wrap: wrap; }
            .so-overview .ov-item, .so-overview .ov-metric { flex: 1 1 30%; border-left: 0; border-top: 1px solid #eef0f2; }
            .so-overview .ov-item:nth-child(-n+2) { flex-basis: 50%; border-top: 0; }
            .so-overview .ov-item:nth-child(2) { border-left: 1px solid #eef0f2; }
        }
        @media (max-width: 480px) { .so-overview .ov-item, .so-overview .ov-item:nth-child(-n+2) { flex-basis: 100%; border-left: 0; } .so-overview .ov-item:nth-child(2) { border-top: 1px solid #eef0f2; } }
    </style>

    <script type="text/javascript">
        // Overview row: fetched once after the page has rendered, and again only when stock actions change the figures.
        var ovBusy = false, ovQueued = false, ovTimer = null;
        function ovEsc(s) { return $('<div/>').text(s == null ? '' : String(s)).html(); }
        function ovFmt(n) { return (Number(n) || 0).toLocaleString(undefined, { maximumFractionDigits: 3 }); }
        function ovPlural(n, one, many) { return n + ' ' + (n === 1 ? one : many); }
        function ovColor(pct) { return 'hsl(' + Math.round(28 + 94 * Math.min(100, Math.max(0, pct)) / 100) + ',68%,45%)'; }
        function ovColorBlue(pct) { return 'hsl(' + Math.round(210 - 45 * Math.min(100, Math.max(0, pct)) / 100) + ',65%,46%)'; }
        function ovMetric(id, pct, color, title) {
            $('#' + id + 'Text').text(ovFmt(pct) + '%').css('color', color);
            $('#' + id + 'Bar').css({ width: Math.min(100, pct) + '%', backgroundColor: color });
            $('#' + id).attr('title', title);
        }
        function ovRender(d) {
            var box = $('#soOverview');
            ovMetric('ovOverall', d.overallPct, ovColor(d.overallPct),
                'Overall progress of the ordered quantities through reservation, production (where a BOM applies), invoicing and delivery. Stages that do not apply are left out.');
            ovMetric('ovDelivery', d.deliveryPct, ovColorBlue(d.deliveryPct),
                'Delivered ' + ovFmt(d.deliveredQty) + ' of ' + ovFmt(d.orderedQty) + ' ordered (delivered, non-cancelled invoices only)');            $('#ovInvoices .ov-value').html(ovEsc(ovPlural(d.invoiceTotal, 'Invoice', 'Invoices')) + ' <small>&middot; ' + d.invoiceDelivered + ' Delivered</small>');
            $('#ovInvoices').attr('title', d.invoiceDelivered + ' delivered, ' + d.invoicePending + ' pending (cancelled invoices are not counted)');
            $('#ovProduction .ov-value').html(ovEsc(ovPlural(d.productionTotal, 'Production', 'Productions')) + ' <small>&middot; ' + d.productionCompleted + ' Completed</small>');
            $('#ovProduction').attr('title', d.productionCompleted + ' completed, ' + d.productionPending + ' pending (stock movements not yet applied)');
            $('#ovTransfers .ov-value').html(ovEsc(ovPlural(d.transferTotal, 'Transfer', 'Transfers')) + ' <small>&middot; ' + d.transferCompleted + ' Completed</small>');
            $('#ovTransfers').attr('title', d.transferCompleted + ' completed, ' + d.transferPending + ' pending purchase' + (d.transferCancelled ? ', ' + d.transferCancelled + ' cancelled' : ''));
            $('#ovReserved .ov-value').html(ovEsc(ovFmt(d.reservedPct) + '%') + ' <small>Reserved</small>');
            $('#ovReserved').attr('title', ovFmt(d.reservedActualQty) + ' reserved of ' + ovFmt(d.reservableQty) + ' ordered stock quantity (' + ovFmt(d.unreservedQty) + ' still to reserve)');
            box.removeClass('ov-loading').find('.ov-error').remove();
            box.find('.ov-item').show();
        }
        function loadOverview() {
            var box = $('#soOverview');
            if (!box.length || ovBusy) { ovQueued = ovQueued || ovBusy; return; }
            ovBusy = true;
            $.ajax({
                type: 'POST',
                url: 'view_sales_order.aspx/LoadOverview',
                data: JSON.stringify({ smoId: parseInt(box.attr('data-order-id'), 10) }),
                contentType: 'application/json; charset=utf-8',
                dataType: 'json',
                success: function (response) {
                    if (response.d && response.d.ok) { ovRender(response.d); return; }
                    ovFail();
                },
                error: ovFail,
                complete: function () {
                    ovBusy = false;
                    if (ovQueued) { ovQueued = false; loadOverview(); }
                }
            });
        }
        function ovFail() {
            var box = $('#soOverview');
            box.removeClass('ov-loading');
            if (!box.find('.ov-error').length) {
                box.find('.ov-item').hide();
                box.append('<div class="ov-error">Overview unavailable. <a href="#" id="ovRetry">Retry</a></div>');
            }
        }
        function refreshOverview() {
            clearTimeout(ovTimer);
            ovTimer = setTimeout(loadOverview, 400);
        }
        $(window).on('load', function () { setTimeout(loadOverview, 0); });
        $(document).on('click', '#ovRetry', function (e) {
            e.preventDefault();
            $('#soOverview').addClass('ov-loading').find('.ov-error').remove();
            $('#soOverview .ov-item').show();
            loadOverview();
        });
        $(document).on('click', '#soOverview a.ov-item[data-tab]', function (e) {
            e.preventDefault();
            var tab = $('#soTabs a[href="' + $(this).attr('data-tab') + '"]');
            tab.trigger('click');
            $('html, body').animate({ scrollTop: tab.closest('.x_panel').offset().top - 70 }, 250);
        });
        // Used by the status buttons: confirm first, then show the shared page loader while the postback runs.
        function confirmStatusChange(message) {
            if (!confirm(message)) return false;
            $(".loader-overlay").css("display", "flex");
            return true;
        }
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

            function escAttr(value) {
                return esc(value).replace(/"/g, '&quot;');
            }

            function num(value) {
                return (Math.round((Number(value) || 0) * 1000) / 1000).toFixed(3);
            }


            function money(value) {
                return (Number(value) || 0).toFixed(2);
            }

            // A reservation can move the order between Approved and Processed; update the status badges in place instead of reloading the page.
            function syncStatus(d) {
                if (!d || !d.ok || d.status < 0 || !d.statusText) {
                    return;
                }
                $('.so-status').attr('class', 'status so-status ' + d.statusCss).text(d.statusText);
            }

            function showReservedMessage(ok, text) {
                $('#reservedMessage').html('<div class="alert ' + (ok ? 'alert-success' : 'alert-danger') + '">' + esc(text) + '</div>');
            }

            var uiState = { open: {}, plan: {}, rows: {} };
            var reservedCanAct = false;

            // Production quantity the user typed per order line; it survives grid reloads and is sent with every reserve / produce request.
            function planOf(sioId) {
                return Number(uiState.plan[sioId]) || 0;
            }
            function plansPayload() {
                return $.map(uiState.plan, function (q, id) { return { sioId: parseInt(id, 10), qty: Number(q) || 0 }; });
            }

            function allocHtml(list, key, title, sioId) {
                if (!list || !list.length) {
                    return '';
                }
                var isOpen = uiState.open[key] !== false;
                var total = 0;
                var rows = $.map(list, function (a) {
                    total += Number(a.qty) || 0;
                    var priority = reservedCanAct
                        ? '<input type="number" class="priority-input" min="0" max="999" step="1" value="' + (parseInt(a.priority, 10) || 0) + '" data-orig="' + (parseInt(a.priority, 10) || 0) + '" data-sio="' + sioId + '" data-batch="' + a.batchId + '" style="width: 60px;" title="Higher priority is used first for invoicing and production. Press Enter or leave the field to save." />'
                        : esc(a.priority || 0);
                    var release = !reservedCanAct ? ''
                        : (a.locked
                            ? '<span class="text-muted" style="font-size: 11px; white-space: nowrap;" title="Raw material cannot be released once finished goods have been produced for this item."><i class="fa fa-lock"></i> Locked</span>'
                            : '<a href="#" class="release-batch" data-sio="' + sioId + '" data-batch="' + a.batchId + '" data-no="' + esc(a.batchNo) + '" data-qty="' + a.qty + '" data-uom="' + esc(a.uom) + '"><i class="fa fa-unlock"></i> Release</a>');
                    return '<tr><td>' + esc(a.warehouse || '-') + '</td><td>' + esc(a.batchNo) + '</td><td style="text-align: right;">' + num(a.qty) + '</td><td>' + esc(a.uom) + '</td>'
                        + '<td>' + priority + '</td>'
                        + '<td><span class="label label-success">' + esc(a.status) + '</span></td><td>' + release + '</td></tr>';
                }).join('');
                var noun = list.length === 1 ? 'batch' : 'batches';
                return '<a href="#" class="alloc-toggle" data-key="' + key + '"><i class="fa fa-' + (isOpen ? 'caret-down' : 'caret-right') + '"></i> ' + esc(title) + ': ' + num(total) + ' ' + esc(list[0].uom) + ' in ' + list.length + ' ' + noun + '</a>'
                    + '<div class="alloc-box" style="' + (isOpen ? '' : 'display: none;') + '"><table class="table table-bordered"><thead><tr><th>Warehouse</th><th>Batch</th><th style="text-align: right;">Qty reserved</th><th>UOM</th><th>Priority</th><th>Status</th><th></th></tr></thead><tbody>' + rows + '</tbody></table></div>';
            }

            // The only reserve entry point: it always opens the warehouse / batch picker, which holds the whole reservation flow (including Release).
            // Nothing is reserved automatically from the grid.
            function reserveButton(canPick, sioId, compItmId, name, uom) {
                return '<button type="button" class="btn btn-sm btn-primary pick-btn" data-sio="' + sioId + '" data-comp="' + compItmId + '" data-name="' + escAttr(name) + '" data-uom="' + escAttr(uom) + '"'
                    + (canPick ? '' : ' disabled') + ' title="Choose the warehouse, batches and quantities to reserve"><i class="fa fa-lock"></i> Reserve</button>';
            }

            // Always clickable: the production modal sets the planned quantity and shows what raw material is still missing; the reason is shown under the button.
            function produceButton(row) {
                if (!row.hasBom) {
                    return '';
                }
                var reason = !row.canProduce && row.productionMessage && (row.produceQty > 0 || row.required > 0) ? row.productionMessage : '';
                return '<button type="button" class="btn btn-sm btn-success produce-btn" data-sio="' + row.sioId + '"'
                    + ' title="Set the quantity to produce and review the raw material"><i class="fa fa-cogs"></i> Produce</button>'
                    + (reason ? '<span class="sub-note text-danger produce-reason">' + esc(reason) + '</span>' : '');
            }

            // Raw materials for the quantity that has to be produced, shown as a small table under the item row.
            function rawMaterialRow(row, canAct) {
                if (!row.hasBom) {
                    return '';
                }
                var uom = ' ' + esc(row.uom);
                var count = row.bom.length + ' raw material' + (row.bom.length === 1 ? '' : 's');
                var head = row.planQty > 0
                    ? 'Bill of materials (' + count + ') &mdash; raw material needed to produce the <strong>' + num(row.produceQty) + uom + '</strong> you entered'
                    : (row.needsProduction > 0
                        ? 'Raw material needed to produce the <strong>' + num(row.needsProduction) + uom + '</strong> that is short (' + count + ')'
                        : (row.produceQty > 0
                            ? 'Bill of materials (' + count + ') &mdash; raw material needed if you produce the <strong>' + num(row.produceQty) + uom + '</strong> still to be supplied'
                            : 'Bill of materials (' + count + ')'));
                // Always shown with the BOM, whatever the raw material availability; the production modal explains what is still missing.
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
                        : (c.surplus > 0 ? '<span class="text-warning">' + num(c.surplus) + u + ' reserved more than needed &mdash; it stays reserved after production, release it if not required</span>'
                            : (c.required > 0 && c.reserved + 0.0005 >= c.required ? '<span class="text-success">Fully reserved</span>' : ''));
                    if (c.required > 0 && c.reserved + 0.0005 < c.required && c.surplus <= 0) {
                        var partial = c.reserved > 0
                            ? '<span class="label label-info">Partly reserved</span> <span class="sub-note">' + num(c.reserved) + ' of ' + num(c.required) + u + ' reserved</span>'
                            : '<span class="label label-default">Not reserved</span>';
                        state = partial + (state ? '<div>' + state + '</div>' : '');
                    }
                    if (c.required <= 0 && c.reserved <= 0.0005) {
                        state = '<span class="label label-default">Not required</span><span class="sub-note">Nothing needs to be produced for this order right now</span>';
                    }
                    var actions = canAct ? reserveButton(c.canPick, row.sioId, c.itmId, c.name, c.uom) : '';
                    return '<tr><td>' + name + note + '</td>'
                        + '<td class="num">' + num(c.required) + u + '</td><td class="num">' + num(c.reserved) + u + '</td><td class="num">' + num(c.free) + u + '</td>'
                        + '<td>' + state + '</td><td><div class="res-actions">' + actions + '</div></td></tr>';
                }).join('');
                return '<tr class="raw-row"><td></td><td colspan="10">'
                    + '<div class="raw-head">' + head + '</div>'
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
                    if (r.canProduce) {
                        return { cls: 'label-success', text: 'Ready to produce' };
                    }
                    var rawShort = false;
                    $.each(r.bom || [], function (i, c) { if (c.issue || c.shortage > 0) { rawShort = true; } });
                    return r.hasBom && !rawShort ? { cls: 'label-warning', text: 'Reserve raw material' } : { cls: 'label-danger', text: 'Short' };
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
                var status = '<span class="label ' + st.cls + '">' + st.text + '</span>' + note;

                var reserveCell, produceCell;
                if (!canAct) {
                    reserveCell = '<span class="text-muted">View only</span>';
                    produceCell = '<span class="text-muted">-</span>';
                } else {
                    reserveCell = '<div class="res-actions">' + reserveButton(r.canPick, r.sioId, 0, r.itemName, r.uom) + '</div>';
                    produceCell = r.hasBom ? '<div class="res-actions">' + produceButton(r) + '</div>' : '<span class="text-muted">-</span>';
                }
                return '<tr>'
                    + '<td>' + r.sl + '</td>'
                    + '<td>' + item + '</td>'
                    + cell(r.ordered) + cell(r.delivered) + cell(r.required)
                    + cell(r.reservedThis) + cell(r.needsProduction, r.needsProduction > 0 ? 'short' : '') + cell(r.free)
                    + '<td>' + status + '</td>'
                    + '<td>' + reserveCell + '</td>'
                    + '<td>' + produceCell + '</td>'
                    + '</tr>'
                    + rawMaterialRow(r, canAct);
            }

            function loadReserved(fromAction) {
                var panel = $('#tabReserved');
                if (panel.data('loading') && !reservedBusy) {
                    // A newer request (for example a changed production quantity) must not be lost while a load is running.
                    panel.data('again', true);
                    return;
                }
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
                    data: JSON.stringify({ smoId: parseInt(panel.attr('data-order-id'), 10), plans: plansPayload() }),
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
                        uiState.rows = {};
                        $.each(d.rows, function (i, r) { uiState.rows[r.sioId] = r; });
                        var html = $.map(d.rows, function (r) { return reservedRowHtml(r, d.canAct); }).join('');
                        $('#reservedBody').html(html || '<tr><td colspan="11" style="text-align: center">No items found for this sales order.</td></tr>');
                        $('#reservedLoading').hide();
                        $('#reservedGrid').show();
                        renderProduceModal();
                        if (fromAction === true) {
                            refreshOverview();
                        }
                    },
                    error: function () {
                        $('#reservedLoading').show().html('Unable to load reserved items. <button type="button" id="retryReserved" class="btn btn-default btn-xs">Retry</button>');
                    },
                    complete: function () {
                        panel.data('loading', false);
                        if (fromAction === true) {
                            panel.removeClass('busy');
                            reservedBusy = false;
                            // The modal was last drawn while the action was still running; re-enable its buttons now that it has finished.
                            updateProduceButtons();
                        }
                        if (panel.data('again')) {
                            panel.data('again', false);
                            loadReserved();
                        }
                    }
                });
            }

            // Runs a stock action after the caller has already confirmed it. done(d) receives the server result (null when the request failed); returns false when another action is running.
            function doStockAction(method, data, done) {
                if (reservedBusy) {
                    return false;
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
                        if (method === 'ProduceInWarehouse' && d.ok) {
                            delete uiState.plan[data.sioId];
                        }
                        showReservedMessage(!!d.ok, d.message || 'The request could not be completed.');
                        syncStatus(d);
                        if (done) {
                            done(d);
                        }
                    },
                    error: function () {
                        showReservedMessage(false, 'The request failed. Please check the grid and try again.');
                        if (done) {
                            done(null);
                        }
                    },
                    complete: function () {
                        loadReserved(true);
                    }
                });
                return true;
            }

            function runStockAction(method, data, confirmText) {
                if (reservedBusy || !window.confirm(confirmText)) {
                    return;
                }
                doStockAction(method, data);
            }

            // ---- Production modal: quantity to produce, BOM requirements, raw material reservation and the production confirmation ----
            // All figures come from the server (LoadReserved with the typed quantity as the plan), so the calculation lives in one place.
            var produceCtx = null;
            var produceTimer = null;

            // Blank means "use the suggested quantity" (0); NaN means the text is not a valid quantity.
            function produceTyped() {
                var raw = $.trim($('#produceQtyInput').val());
                if (raw === '') {
                    return 0;
                }
                var v = Number(raw);
                return isNaN(v) || v < 0 ? NaN : Math.round(v * 1000) / 1000;
            }

            // True when the typed quantity has been applied and the figures on screen were calculated for it.
            function produceInSync(r) {
                var t = produceTyped();
                return !isNaN(t) && t === planOf(r.sioId) && Math.abs((Number(r.planQty) || 0) - t) < 0.0000005;
            }

            function produceMessage(ok, text) {
                $('#produceModalMessage').html(text ? '<div class="alert ' + (ok ? 'alert-success' : 'alert-danger') + ' pc-alert">' + esc(text) + '</div>' : '');
            }

            function produceStatus(c) {
                if (c.issue) {
                    return { cls: 'label-danger', text: 'Unavailable' };
                }
                if (c.required <= 0) {
                    return { cls: 'label-default', text: 'Not required' };
                }
                if (c.shortage > 0) {
                    return { cls: 'label-danger', text: 'Short' };
                }
                if (c.remaining > 0) {
                    return { cls: 'label-warning', text: 'Reserve more' };
                }
                return c.surplus > 0 ? { cls: 'label-info', text: 'Over-reserved' } : { cls: 'label-success', text: 'Reserved' };
            }

            function produceContentHtml(r) {
                var uom = ' ' + esc(r.uom);
                var qty = Number(r.produceQty) || 0;
                var warehouses = {}, warehouseCount = 0;
                var rows = $.map(r.bom, function (c) {
                    var u = '<span class="pc-u">' + esc(c.uom) + '</span>';
                    var name = '<div class="pc-mat-name"><div class="pc-mat-title" title="' + escAttr(c.name) + '">' + esc(c.name) + '</div>'
                        + (c.code ? '<div class="pc-mat-sub">' + esc(c.code) + '</div>' : '') + '</div>';
                    if (c.issue) {
                        return '<div class="pc-mat-row"><div class="pc-mat-main pc-mat-issue">' + name + '<div class="pc-issue-text">' + esc(c.issue) + '</div></div></div>';
                    }
                    var allocs = $.map(c.allocations || [], function (a) {
                        if (!warehouses[a.branchId]) {
                            warehouses[a.branchId] = true;
                            warehouseCount++;
                        }
                        return '<div>' + esc(a.warehouse || '-') + (a.batchNo ? ' &middot; Batch ' + esc(a.batchNo) : '') + ' <span class="pc-det-qty">' + num(a.qty) + ' ' + esc(a.uom) + '</span></div>';
                    });
                    var st = produceStatus(c);
                    var statusText = st.text === 'Short' ? 'Short by ' + num(c.shortage) + ' ' + c.uom : st.text;
                    var tone = { 'label-danger': 'bad', 'label-warning': 'warn', 'label-success': 'ok', 'label-info': 'info' }[st.cls] || 'muted';
                    var statusTip = c.surplus > 0 ? num(c.surplus) + ' ' + c.uom + ' reserved more than needed; the extra stays reserved until you produce more or release it' : '';
                    var reservedOk = c.required > 0 && c.shortage <= 0 && c.remaining <= 0;
                    var act = c.canPick ? reserveButton(true, r.sioId, c.itmId, c.name, c.uom) : '';
                    return '<div class="pc-mat-row"><div class="pc-mat-main">'
                        + '<div class="pc-mat-name"><div class="pc-mat-title" title="' + escAttr(c.name) + '">' + esc(c.name) + '</div>'
                        + (c.code ? '<div class="pc-mat-sub">' + esc(c.code) + '</div>' : '') + '</div>'
                        + '<div class="pc-q" data-label="Needed">' + num(c.required) + u + '</div>'
                        + '<div class="pc-q' + (reservedOk ? ' pc-ok' : '') + '" data-label="Reserved">' + num(c.reserved) + u + '</div>'
                        + '<div class="pc-status pc-' + tone + '" data-label="Status"' + (statusTip ? ' title="' + escAttr(statusTip) + '"' : '') + '><span class="pc-dot"></span>' + esc(statusText) + '</div>'
                        + '<div class="pc-act' + (c.remaining > 0 ? ' pc-act-need' : '') + '">' + act + '</div></div>'
                        + (allocs.length ? '<details class="pc-details"><summary>Reserved in ' + allocs.length + ' batch' + (allocs.length > 1 ? 'es' : '') + '</summary>' + allocs.join('') + '</details>' : '')
                        + '</div>';
                }).join('');
                var html = '';
                var reason = r.productionMessage || r.message;
                if (!r.canProduce && reason) {
                    html += '<div class="alert alert-warning pc-alert">' + esc(reason) + '</div>';
                }
                if (warehouseCount > 1) {
                    html += '<div class="alert alert-info pc-alert">Raw material is reserved in more than one warehouse. Each warehouse is produced separately, using only the raw material reserved in it.</div>';
                }
                html += '<div class="pc-heading">1. Produce in a warehouse</div>' + warehouseProductionHtml(r);
                html += '<div class="pc-heading">2. Raw material needed for ' + num(qty) + uom + '</div>'
                    + '<div class="pc-bom"><div class="pc-bom-head"><div>Raw material</div><div>Needed</div><div>Reserved</div><div>Status</div><div></div></div>'
                    + rows + '</div>';
                html += '<div class="pc-heading">3. Order progress</div>'
                    + '<table class="table table-bordered table-condensed pc-table"><tbody>'
                    + '<tr><td>Ordered</td><td class="num">' + num(r.ordered) + uom + '</td></tr>'
                    + '<tr><td>Produced so far</td><td class="num"><strong>' + num(r.produced) + uom + '</strong> (' + num(r.producedPct) + '%)</td></tr>'
                    + $.map(r.warehouses || [], function (w) { return w.produced > 0 ? '<tr><td>&nbsp;&nbsp;Produced in ' + esc(w.warehouse) + '</td><td class="num">' + num(w.produced) + uom + '</td></tr>' : ''; }).join('')
                    + '</tbody></table>'
                    + '<p class="text-muted" style="font-size: 12px; margin: 8px 0 0 0;">Finished goods stay in the warehouse where they were produced. Raw material that is not used stays reserved for later production.</p>';
                return html;
            }

            // One section per warehouse that holds reserved raw material (or finished goods produced for this order). Quantities typed here are kept
            // in produceCtx.whQty so a reload of the figures does not wipe them.
            function warehouseProductionHtml(r) {
                var uom = ' ' + esc(r.uom);
                var list = r.warehouses || [];
                if (!list.length) {
                    return '<div class="alert alert-warning pc-alert">No raw material is reserved for this item yet. Reserve it first; production is done in the warehouse where the raw material is reserved.</div>';
                }
                return $.map(list, function (w) {
                    var typed = produceCtx && produceCtx.whQty ? produceCtx.whQty[w.branchId] : undefined;
                    var value = typed !== undefined ? typed : (w.suggestedQty > 0 ? w.suggestedQty : '');
                    var mats = $.map(w.materials, function (m) {
                        var u = ' ' + esc(m.uom);
                        var batches = $.map(m.batches || [], function (b) {
                            var calc = m.method && b.kgPerMetre > 0
                                ? ' &middot; ' + num(b.kgPerMetre) + ' kg/m &middot; ' + num(b.kgPerUnit) + ' kg per ' + esc(r.uom) + ' &middot; makes ' + num(b.makes) + uom : '';
                            return '<div>Batch ' + esc(b.batchNo) + ': ' + num(b.qty) + u + calc + '</div>';
                        }).join('');
                        var how = m.method ? 'Calculated from each batch\'s weight and length (' + esc(m.method) + ')' : 'Uses ' + num(m.perUnit) + u + ' for each ' + esc(r.uom);
                        return '<div class="pc-res-row"><div class="pc-res-name"><strong>' + esc(m.name) + '</strong>' + (m.code ? ' <span class="text-muted">(' + esc(m.code) + ')</span>' : '')
                            + '<div class="pc-mat-sub">Enough for ' + num(m.supports) + uom + '</div></div>'
                            + '<div class="pc-q">' + num(m.reserved) + u + '</div></div>'
                            + '<details class="pc-details"><summary>How this is calculated</summary><div>' + how + '</div>' + batches + '</details>';
                    }).join('');
                    var head = '<strong>' + esc(w.warehouse) + '</strong>' + (w.isHome ? ' <span class="label label-default">Order warehouse</span>' : '')
                        + (w.produced > 0 ? ' <span class="text-muted">&middot; produced here: ' + num(w.produced) + uom + '</span>' : '');
                    var action;
                    if (w.canProduce) {
                        action = '<div class="pc-wh-action"><label>Quantity to produce</label> '
                            + '<input type="number" class="form-control wh-qty" data-branch="' + w.branchId + '" min="0" max="' + w.maxQty + '" step="any" value="' + escAttr(value) + '" />'
                            + ' <strong>' + esc(r.uom) + '</strong> '
                            + '<button type="button" class="btn btn-success wh-produce" data-branch="' + w.branchId + '"><i class="fa fa-cogs"></i> Produce</button></div>';
                    } else {
                        action = '<div class="text-muted pc-wh-action">' + esc(w.message || (w.materials.length ? 'Production is not available for this warehouse.' : 'No raw material is reserved in this warehouse.')) + '</div>';
                    }
                    return '<div class="pc-wh">'
                        + '<div class="pc-wh-head">' + head + '<span class="pc-wh-max">You can make up to <strong>' + num(w.maxQty) + uom + '</strong></span></div>'
                        + (w.materials.length ? '<div class="pc-k">Raw material reserved here</div><div class="pc-res">' + mats + '</div>' : '')
                        + action
                        + (warehouseHasCalc(w) ? '<div class="pc-calc" data-branch="' + w.branchId + '"></div>' : '') + '</div>';
                }).join('');
            }

            // Warehouse production is independent of the planned quantity above: each warehouse produces what its own reservation allows.
            function whQtyInput(branch) {
                return $('#produceModal .wh-qty[data-branch="' + branch + '"]');
            }

            // Valid when the typed quantity is above zero, has at most 3 decimals and is not above what the warehouse's own reservation can make.
            function whQtyValue(w) {
                var raw = $.trim(whQtyInput(w.branchId).val());
                var v = Number(raw);
                if (raw === '' || isNaN(v) || v <= 0 || Math.abs(Math.round(v * 1000) / 1000 - v) > 1e-9 || v > Number(w.maxQty) + 1e-9) {
                    return NaN;
                }
                return Math.round(v * 1000) / 1000;
            }

            // A warehouse needs the server-side raw-material preview when any of its reserved materials is calculated from batch weight and length.
            function warehouseHasCalc(w) {
                return $.grep(w.materials || [], function (m) { return !!m.method; }).length > 0;
            }

            function previewHtml(p, r) {
                var uom = ' ' + esc(r.uom);
                if (!p || !p.ok) {
                    return '<div class="alert alert-danger pc-alert" style="margin-bottom: 0;">' + esc((p && p.message) || 'The raw-material requirement could not be calculated.') + '</div>';
                }
                var rows = $.map(p.materials, function (m) {
                    var u = ' ' + esc(m.uom);
                    var calc = !!m.method;
                    var head = '<tr class="pc-mat"><td>' + esc(m.name) + (calc ? ' <span class="text-muted" style="font-weight: normal;">(' + esc(m.method) + ')</span>' : '') + '</td>'
                        + '<td></td><td></td>' + (calc ? '<td class="num">' + num(m.metres) + ' m</td><td class="num">' + num(m.kg) + ' kg</td>' : '<td></td><td></td>')
                        + '<td class="num">' + num(m.required) + u + '</td></tr>';
                    var batches = $.map(m.batches, function (b) {
                        return '<tr><td>&nbsp;&nbsp;Batch ' + esc(b.batchNo) + (calc ? '<span class="sub-note">covers ' + num(b.finished) + uom + '</span>' : '') + '</td>'
                            + (calc ? '<td class="num">' + num(b.kgPerMetre) + '</td><td class="num">' + num(b.kgPerUnit) + '</td><td class="num">' + num(b.metres) + ' m</td><td class="num">' + num(b.kg) + ' kg</td>'
                                : '<td></td><td></td><td></td><td></td>')
                            + '<td class="num">' + num(b.qty) + u + '</td></tr>';
                    }).join('');
                    return head + batches;
                }).join('');
                var summary = $.map(p.materials, function (m) {
                    var u = ' ' + esc(m.uom);
                    var used = $.map(m.batches, function (b) { return '<div class="pc-mat-sub">From batch ' + esc(b.batchNo) + ': ' + num(b.qty) + u + '</div>'; }).join('');
                    return '<div class="pc-res-row"><div class="pc-res-name"><strong>' + esc(m.name) + '</strong>' + used + '</div><div class="pc-q">' + num(m.required) + u + '</div></div>';
                }).join('');
                return '<div class="pc-deduct"><div class="pc-k">Raw material that will be used for ' + num(p.qty) + uom + '</div><div class="pc-res">' + summary + '</div>'
                    + '<details class="pc-details"><summary>Show calculation details</summary>'
                    + '<table class="table table-bordered table-condensed pc-table"><thead><tr><th>Raw material / batch</th><th class="num">kg per metre</th><th class="num">kg per ' + esc(r.uom)
                    + '</th><th class="num">Length</th><th class="num">Weight</th><th class="num">Deducted from stock</th></tr></thead><tbody>' + rows + '</tbody></table>'
                    + '<p class="text-muted" style="font-size: 12px; margin: 0;">Each batch is calculated on its own weight and length.</p></details></div>';
            }

            // Asks the server what producing the typed quantity would consume, batch by batch, and shows it under the warehouse before the user confirms.
            function loadPreview(branch) {
                if (!produceCtx) {
                    return;
                }
                var r = uiState.rows[produceCtx.sioId];
                var w = r && $.grep(r.warehouses || [], function (x) { return x.branchId === branch; })[0];
                var box = $('#produceModal .pc-calc[data-branch="' + branch + '"]');
                if (!w || !box.length) {
                    return;
                }
                produceCtx.preview = produceCtx.preview || {};
                produceCtx.previewSeq = produceCtx.previewSeq || {};
                var seq = (produceCtx.previewSeq[branch] || 0) + 1;
                produceCtx.previewSeq[branch] = seq;
                var qty = whQtyValue(w);
                if (!w.canProduce || isNaN(qty)) {
                    delete produceCtx.preview[branch];
                    box.html(w.canProduce ? '<span class="text-muted">Enter a quantity to see the raw material that will be deducted.</span>' : '');
                    updateProduceButtons();
                    return;
                }
                box.html('<span class="text-muted"><i class="fa fa-spinner fa-spin"></i> Calculating raw material from the reserved batches...</span>');
                var ctx = produceCtx;
                $.ajax({
                    type: 'POST',
                    url: 'view_sales_order.aspx/PreviewProduction',
                    data: JSON.stringify({ smoId: parseInt($('#tabReserved').attr('data-order-id'), 10), sioId: r.sioId, warehouseId: branch, qty: qty }),
                    contentType: 'application/json; charset=utf-8',
                    dataType: 'json',
                    success: function (response) {
                        if (produceCtx !== ctx || ctx.previewSeq[branch] !== seq) {
                            return;
                        }
                        var d = response.d;
                        ctx.preview[branch] = { qty: qty, data: d };
                        box.html(previewHtml(d, r));
                        updateProduceButtons();
                    },
                    error: function () {
                        if (produceCtx !== ctx || ctx.previewSeq[branch] !== seq) {
                            return;
                        }
                        ctx.preview[branch] = { qty: qty, data: null };
                        box.html(previewHtml(null, r));
                        updateProduceButtons();
                    }
                });
            }

            function loadAllPreviews() {
                $('#produceModal .pc-calc').each(function () {
                    loadPreview(parseInt($(this).attr('data-branch'), 10));
                });
            }

            // Production is blocked while the preview of the typed quantity reports a problem (missing batch weight / length, not enough reserved, ...).
            function previewBlocks(branch, qty) {
                var p = produceCtx && produceCtx.preview ? produceCtx.preview[branch] : null;
                return !!p && p.qty === qty && !(p.data && p.data.ok);
            }

            // Text for the confirmation: what will be deducted, per raw material and batch.
            function previewSummary(branch, qty) {
                var p = produceCtx && produceCtx.preview ? produceCtx.preview[branch] : null;
                if (!p || p.qty !== qty || !p.data || !p.data.ok) {
                    return '';
                }
                var lines = $.map(p.data.materials, function (m) {
                    if (!m.method) {
                        return '';
                    }
                    return '\n' + m.name + ': ' + num(m.kg) + ' kg (' + $.map(m.batches, function (b) { return 'batch ' + b.batchNo + ' ' + num(b.kg) + ' kg'; }).join(', ') + ')';
                }).join('');
                return lines ? '\n\nRaw material to be deducted:' + lines : '';
            }

            function updateProduceButtons() {
                if (!produceCtx) {
                    return;
                }
                var r = uiState.rows[produceCtx.sioId];
                var busy = produceCtx.busy || reservedBusy;
                $('#produceQtyInput').prop('disabled', produceCtx.busy);
                $('#produceModal .wh-qty').prop('disabled', busy);
                $('#produceModal .wh-produce').each(function () {
                    var branch = parseInt($(this).attr('data-branch'), 10);
                    var w = r && $.grep(r.warehouses || [], function (x) { return x.branchId === branch; })[0];
                    var qtyNow = w ? whQtyValue(w) : NaN;
                    var blocked = !!w && !isNaN(qtyNow) && previewBlocks(branch, qtyNow);
                    var ok = !!w && w.canProduce && !busy && !isNaN(qtyNow) && !blocked;
                    $(this).prop('disabled', !ok).attr('title', ok ? 'Produce ' + num(whQtyValue(w)) + ' ' + escAttr(r.uom) + ' in ' + escAttr(w.warehouse) + ' using only the raw material reserved there'
                        : (blocked ? 'The raw-material calculation for this quantity reports a problem; see the details below the quantity.' : 'Enter a quantity up to ' + num(w ? w.maxQty : 0) + ' ' + escAttr(r ? r.uom : '')));
                });
                $('#produceModal').toggleClass('processing', produceCtx.busy);
                $('#produceSpinner').toggle(produceCtx.busy);
            }

            function renderProduceModal() {
                if (!produceCtx) {
                    return;
                }
                var r = uiState.rows[produceCtx.sioId];
                if (!r || !r.hasBom) {
                    $('#produceModalContent').html('<p class="text-danger">This item can no longer be produced from this order.</p>');
                    updateProduceButtons();
                    return;
                }
                var qty = Number(r.produceQty) || 0;
                $('#produceModalSubtitle').text(r.itemName + (r.itemCode ? ' (' + r.itemCode + ')' : '') + ' \u00b7 Sales Order #' + $('#tabReserved').attr('data-order-id'));
                $('#produceQtyUom').text(r.uom);
                $('#produceQtyInput').attr('placeholder', qty > 0 ? qty : '');
                $('#produceQtyHint').html(r.planQty > 0 ? 'Custom quantity. Clear the field to use the suggested <strong>' + esc(num(qty)) + ' ' + esc(r.uom) + '</strong>.'
                    : 'Suggested for this order. Type a different quantity to change it.');
                $('#produceModalContent').html(produceContentHtml(r));
                loadAllPreviews();
                updateProduceButtons();
            }

            // The typed quantity is applied shortly after typing stops (or on Enter / leaving the field) and the figures are recalculated by the server.
            function applyProducePlan() {
                clearTimeout(produceTimer);
                if (!produceCtx) {
                    return;
                }
                var r = uiState.rows[produceCtx.sioId];
                var v = produceTyped();
                if (isNaN(v)) {
                    produceMessage(false, 'Enter a valid quantity to produce.');
                    updateProduceButtons();
                    return;
                }
                if (r && produceInSync(r)) {
                    updateProduceButtons();
                    return;
                }
                if (reservedBusy) {
                    produceTimer = setTimeout(applyProducePlan, 400);
                    return;
                }
                if (v > 0) {
                    uiState.plan[produceCtx.sioId] = v;
                } else {
                    delete uiState.plan[produceCtx.sioId];
                }
                produceMessage(true, '');
                $('#reservedMessage').empty();
                loadReserved();
            }

            function openProduceModal(sioId) {
                var r = uiState.rows[sioId];
                if (reservedBusy || !r) {
                    return;
                }
                clearTimeout(produceTimer);
                produceCtx = { sioId: sioId, busy: false, switching: false };
                $('#produceQtyInput').val(planOf(sioId) > 0 ? planOf(sioId) : '');
                produceMessage(true, '');
                renderProduceModal();
                $('#produceModal').modal('show');
            }

            $('#produceModal').on('input', '#produceQtyInput', function () {
                clearTimeout(produceTimer);
                updateProduceButtons();
                produceTimer = setTimeout(applyProducePlan, 600);
            });
            $('#produceModal').on('change', '#produceQtyInput', applyProducePlan);
            $('#produceModal').on('keydown', '#produceQtyInput', function (e) {
                if (e.which === 13) {
                    e.preventDefault();
                    applyProducePlan();
                }
            });
            $('#produceModal').on('input', '.wh-qty', function () {
                var branch = parseInt($(this).attr('data-branch'), 10);
                if (produceCtx) {
                    produceCtx.whQty = produceCtx.whQty || {};
                    produceCtx.whQty[branch] = $(this).val();
                    produceCtx.previewTimers = produceCtx.previewTimers || {};
                    clearTimeout(produceCtx.previewTimers[branch]);
                    produceCtx.previewTimers[branch] = setTimeout(function () { loadPreview(branch); }, 500);
                }
                updateProduceButtons();
            });
            $('#produceModal').on('click', '.wh-produce', function () {
                var r = produceCtx && uiState.rows[produceCtx.sioId];
                var branch = parseInt($(this).attr('data-branch'), 10);
                var w = r && $.grep(r.warehouses || [], function (x) { return x.branchId === branch; })[0];
                if (!w || produceCtx.busy || reservedBusy || !w.canProduce) {
                    return;
                }
                var qty = whQtyValue(w);
                if (isNaN(qty)) {
                    produceMessage(false, 'Enter a quantity between 0 and ' + num(w.maxQty) + ' ' + r.uom + ' (up to 3 decimals) for ' + w.warehouse + '.');
                    return;
                }
                if (!window.confirm('Produce ' + num(qty) + ' ' + r.uom + ' of ' + r.itemName + ' in the ' + w.warehouse + ' warehouse? Only the raw material reserved in ' + w.warehouse + ' is used and the finished goods stay there.' + previewSummary(branch, qty))) {
                    return;
                }
                var ctx = produceCtx;
                ctx.busy = true;
                produceMessage(true, '');
                var started = doStockAction('ProduceInWarehouse', { sioId: r.sioId, warehouseId: branch, qty: qty, expectedProduced: Number(w.produced) || 0 }, function (d) {
                    ctx.busy = false;
                    if (ctx.whQty) {
                        delete ctx.whQty[branch];
                    }
                    produceMessage(!!(d && d.ok), (d && d.message) || 'The request failed. Please review the figures and try again.');
                    updateProduceButtons();
                });
                if (!started) {
                    ctx.busy = false;
                    produceMessage(false, 'Another action is still running. Please try again in a moment.');
                }
                updateProduceButtons();
            });
            $('#produceModal').on('hidden.bs.modal', function () {
                clearTimeout(produceTimer);
                if (produceCtx && !produceCtx.switching) {
                    produceCtx = null;
                }
            });
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
            $('#tabReserved').on('click', '.release-batch', function (e) {
                e.preventDefault();
                var b = $(this);
                runStockAction('UnreserveBatch', { sioId: parseInt(b.attr('data-sio'), 10), batchId: parseInt(b.attr('data-batch'), 10) },
                    'Release ' + num(b.attr('data-qty')) + ' ' + b.attr('data-uom') + ' reserved in batch ' + b.attr('data-no') + '? Stock quantities are not changed.');
            });
            $('#tabReserved').on('click', '.produce-btn', function () {
                openProduceModal(parseInt($(this).attr('data-sio'), 10));
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
                $('#batchTotals').html('<span class="pt-item">Selected <strong class="' + (over ? 'text-warning' : 'text-success') + '">' + num(total) + ' ' + esc(d.uom) + '</strong></span>'
                    + '<span class="pt-item">Remaining <strong class="' + (over ? 'text-warning' : '') + '">' + num(left) + ' ' + esc(d.uom) + '</strong></span>'
                    + (other > 0 ? '<span class="sub-note" style="line-height: 14px;">Includes ' + other + ' batch(es) from other warehouses</span>' : ''));
                $('#batchOverMessage').text(over ? 'This reserves ' + num(-left) + ' ' + d.uom + ' more than the remaining requirement (' + num(d.remaining) + ' ' + d.uom + '). The extra stays reserved for this order until you release it or use it in production.' : '').toggle(over);
                $('#batchSubmit').prop('disabled', pick.busy || errors > 0 || total <= 0);
            }

            function renderPicker() {
                var d = pick.data;
                var warehouseOptions = $.map(d.warehouses, function (w) {
                    return '<option value="' + w.branchId + '"' + (w.branchId === pick.warehouseId ? ' selected' : '') + '>' + esc(w.name) + (w.isHome ? ' (order warehouse)' : '')
                        + ' - ' + num(w.available) + ' ' + esc(d.uom) + ' available</option>';
                }).join('');
                function info(k, v) { return '<div class="pick-info"><span class="pick-k">' + k + '</span><span class="pick-v">' + v + '</span></div>'; }
                function metric(cls, k, v) { return '<div class="pick-metric ' + cls + '"><span class="pick-k">' + k + '</span><span class="pick-n">' + num(v) + ' <small>' + esc(d.uom) + '</small></span></div>'; }
                $('#batchModalTitle').text(d.isComponent ? 'Reserve Raw Material' : 'Reserve Stock');
                $('#batchModalSubtitle').text(d.itemName || '');
                var summary = '<div class="pick-summary"><div class="pick-metrics">'
                    + metric('', d.isComponent ? 'Required for production' : 'Ordered', d.required)
                    + metric('', 'Already reserved', d.reservedThis)
                    + metric('pick-metric-main', 'Remaining to reserve', d.remaining)
                    + '</div><div class="pick-items">'
                    + info('Item', esc(d.itemName) + (d.itemCode ? ' <span class="text-muted">(' + esc(d.itemCode) + ')</span>' : ''))
                    + (d.isComponent ? info('BOM component of', esc(d.parentName)) : '')
                    + '</div></div>';
                var wh = '<div class="pick-section"><label class="pick-heading" for="batchWarehouse">Select Warehouse</label>'
                    + '<select id="batchWarehouse" class="form-control">' + (warehouseOptions || '<option value="0">No warehouse available</option>') + '</select></div>'
                    + '<div id="batchModalMessage" role="status" aria-live="polite"></div>';
                var w = pickWarehouse();
                var rows = '';
                if (w) {
                    rows = $.map(w.batches, function (b, i) {
                        var saved = pick.selected[b.batchId];
                        return '<tr data-batch="' + b.batchId + '"><td>' + (i + 1) + '</td><td>' + esc(w.name) + '</td><td>' + esc(b.batchNo) + '</td>'
                            + '<td>' + (b.batchDate ? esc(b.batchDate) : '<span class="text-muted">-</span>') + '</td>'
                            + '<td class="num">' + num(b.physical) + '</td>'
                            + '<td class="num">' + num(b.reserved) + (b.mine > 0 ? '<span class="sub-note">this order: ' + num(b.mine) + '</span>' : '') + '</td>'
                            + '<td class="num">' + num(b.available) + '</td>'
                            + '<td class="num qty-col"><input type="number" class="form-control input-sm batch-qty" min="0" step="any" data-batch="' + b.batchId + '" data-max="' + b.available + '"'
                            + (b.available <= 0 ? ' disabled' : '') + (saved > 0 ? ' value="' + num(saved) + '"' : '') + ' aria-label="Quantity to reserve from batch ' + escAttr(b.batchNo) + '" /><span class="batch-err"></span></td></tr>';
                    }).join('');
                }
                var table = '<div class="batch-table-wrap"><table class="table batch-table">'
                    + '<thead><tr><th>#</th><th>Warehouse</th><th>Batch No</th><th>Batch Date</th><th class="num">Physical Stock</th><th class="num">Reserved</th>'
                    + '<th class="num">Available</th><th class="num qty-col">Qty to Reserve (' + esc(d.uom) + ')</th></tr></thead>'
                    + '<tbody id="batchBody">' + (rows || '<tr class="batch-empty"><td colspan="8"><i class="fa fa-inbox"></i> No batches with stock in this warehouse.</td></tr>') + '</tbody></table></div>'
                    + '<p class="text-warning" id="batchOverMessage" style="display: none; margin: 8px 0 0 0;"></p>'
                    + '<div class="pick-help"><i class="fa fa-info-circle"></i><ul>'
                    + '<li>All quantities are in ' + esc(d.uom) + '.</li>'
                    + '<li>Leave quantities empty and use Auto-fill to allocate oldest batches first.</li>'
                    + '<li>You can reserve more than the remaining requirement to hold extra stock for this order.</li>'
                    + '<li>Selections are retained when you switch warehouse.</li></ul></div>';
                $('#batchModalBody').html(summary + wh + table);
                $('#batchRelease').toggle(d.reservedThis > 0 && d.canRelease !== false);
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
                    data: JSON.stringify({ smoId: parseInt($('#tabReserved').attr('data-order-id'), 10), sioId: req.sioId, compItmId: req.compItmId, planQty: planOf(req.sioId) }),
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

            $('#tabReserved, #produceModal').on('click', '.pick-btn', function (e) {
                e.preventDefault();
                if (reservedBusy) {
                    return;
                }
                var b = $(this);
                pick = { sioId: parseInt(b.attr('data-sio'), 10), compItmId: parseInt(b.attr('data-comp'), 10) || 0, warehouseId: 0, busy: false, selected: {}, batchWarehouse: {} };
                $('#batchModalTitle').text(pick.compItmId > 0 ? 'Reserve Raw Material' : 'Reserve Stock');
                $('#batchModalSubtitle').text(b.attr('data-name') || '');
                function openPicker() {
                    $('#batchModal').removeClass('processing').modal('show');
                    loadPicker();
                }
                // Bootstrap 3 cannot stack modals: the production modal steps aside and comes back when the picker closes.
                if (produceCtx && b.closest('#produceModal').length) {
                    produceCtx.switching = true;
                    $('#produceModal').one('hidden.bs.modal', openPicker).modal('hide');
                } else {
                    openPicker();
                }
            });

            $('#batchModal').on('hidden.bs.modal', function () {
                pick = null;
                if (produceCtx && produceCtx.switching) {
                    produceCtx.switching = false;
                    renderProduceModal();
                    $('#produceModal').modal('show');
                }
            });
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
                if (method === 'ReserveBatches') {
                    data.planQty = planOf(req.sioId);
                }
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
                        syncStatus(d);
                        loadReserved(d.ok === true);
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
                var excess = Math.round((pickTotal() - pick.data.remaining) * 1000) / 1000;
                pickFinish('ReserveBatches', { allocations: allocations },
                    excess > 0.0005 ? 'You are reserving ' + num(excess) + ' ' + pick.data.uom + ' more than the remaining requirement. Reserve the extra quantity as well?' : null);
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
                    + '<td style="text-align: right; white-space: nowrap;">' + num(r.produced)
                    + (r.warehouses && r.warehouses.length ? $.map(r.warehouses, function (w) { return '<span class="sub-note">' + esc(w) + '</span>'; }).join('') : '') + '</td>'
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
                    + '<td>' + (r.warehouse ? esc(r.warehouse) : '<span class="text-muted">-</span>') + '</td>'
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
                        if (keepMessage === true) {
                            refreshOverview();
                        }
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
                                + '</td><td style="text-align: right;">' + num(it.Quantity) + '</td><td style="text-align: right;">' + money(it.Cost) + '</td></tr>';
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

            // Interstock Transfer Invoices tab: search, expandable details of both documents, and Create Purchase.
            // Every typed word must appear in the row (invoice, purchase, warehouses, customer, date, status).
            var transferTimer = null;
            function filterTransfers() {
                var words = $.trim($('#transferSearch').val()).toLowerCase().replace(/#/g, '').split(/\s+/), shown = 0, total = 0;
                $('#transferList tr.it-row').each(function () {
                    var row = $(this), text = row.text().toLowerCase().replace(/#/g, ''), show = true;
                    total++;
                    for (var i = 0; show && i < words.length; i++) {
                        if (words[i] !== '' && text.indexOf(words[i]) < 0) show = false;
                    }
                    row.toggle(show);
                    if (!show) row.next('.it-detail').hide();
                    if (show) shown++;
                });
                $('#transferList tr.it-empty').toggle(total > 0 && shown === 0);
                $('#transferSearchClear').toggle($.trim($('#transferSearch').val()) !== '');
                $('#transferCount').text(shown === total ? total + ' transfer(s)' : 'Showing ' + shown + ' of ' + total);
            }
            $('#transferSearch').on('input', function () {
                clearTimeout(transferTimer);
                transferTimer = setTimeout(filterTransfers, 150);
            }).on('keydown', function (e) {
                if (e.which === 27) { $(this).val(''); filterTransfers(); }
            });
            $('#transferSearchClear').on('click', function () { $('#transferSearch').val('').focus(); filterTransfers(); });
            if ($('#transferList').length) filterTransfers();

            function itNum(v) { var n = parseFloat(v); return (isFinite(n) ? n : 0).toFixed(2); }
            function itQty(v) { var n = parseFloat(v); return (isFinite(n) ? Math.round(n * 1000) / 1000 : 0).toFixed(3); }
            function itPct(v) { var n = parseFloat(v); return String(isFinite(n) ? Math.round(n * 10000) / 10000 : 0); }
            function itPair(k, v) {
                return $('<div class="it-pair"></div>').append($('<span class="k"></span>').text(k)).append($('<span class="v"></span>').text(v));
            }
            function itItems(items, totals) {
                var table = $('<table class="table table-bordered table-condensed"></table>');
                table.append('<thead><tr><th>Item</th><th>Batch</th><th class="text-right">Qty</th><th class="text-right">Price</th><th class="text-right">Tax %</th><th class="text-right">CGST</th><th class="text-right">SGST</th><th class="text-right">IGST</th><th class="text-right">Net</th></tr></thead>');
                var body = $('<tbody></tbody>');
                $.each(items, function (i, x) {
                    var name = $('<td></td>').text(x.name);
                    if (x.code) name.append($('<span class="sub-note"></span>').text(x.code));
                    body.append($('<tr></tr>').append(name).append($('<td></td>').text(x.batchNo || '-'))
                        .append($('<td class="text-right"></td>').text(itQty(x.qty) + (x.uom ? ' ' + x.uom : '')))
                        .append($('<td class="text-right"></td>').text(itNum(x.price)))
                        .append($('<td class="text-right"></td>').text(                        itPct(x.taxPercent) + '%'))
                                                .append($('<td class="text-right"></td>').text(x.cgst > 0 ? itPct(x.cgst) + '%' : '-'))
                                                .append($('<td class="text-right"></td>').text(x.sgst > 0 ? itPct(x.sgst) + '%' : '-'))
                                                .append($('<td class="text-right"></td>').text(x.igst > 0 ? itPct(x.igst) + '%' : '-'))
                        .append($('<td class="text-right"></td>').text(itNum(x.netAmount))));
                });
                table.append(body);
                var foot = $('<div class="it-totals"></div>').text('Total ' + itNum(totals.total) + '  |  Discount ' + itNum(totals.discount) + '  |  Tax ' + itNum(totals.tax) + '  |  Net ' + itNum(totals.net));
                return $('<div style="overflow-x: auto;"></div>').append(table).append(foot);
            }
            function itRender(d) {
                var h = d.header, box = $('<div class="it-box"></div>');
                var sales = $('<div class="it-section"></div>').append($('<h5></h5>').text('Sales invoice (source warehouse)'));
                sales.append(itPair('Invoice', '#' + h.salesId + (h.invoiceNo ? ' (' + h.invoiceNo + ')' : '')))
                    .append(itPair('Date', h.date)).append(itPair('Source', h.source)).append(itPair('Target', h.targetWarehouse))
                    .append(itPair('Customer', h.customer)).append(itPair('GST', d.gstType));
                sales.append(itItems(d.salesItems, d.salesTotals));
                sales.append($('<a class="btn btn-primary btn-xs"></a>').attr('href', 'manageorders.aspx?orderId=' + h.salesId).html('<i class="fa fa-eye"></i> View Invoice'));
                var pur = $('<div class="it-section"></div>').append($('<h5></h5>').text('Associated purchase (target warehouse)'));
                if (h.purchaseId > 0) {
                    pur.append(itPair('Purchase', '#' + h.purchaseId)).append(itPair('Vendor', h.vendor)).append(itPair('Warehouse', h.purchaseWarehouse))
                        .append(itPair('Status', h.purchaseStatus === 'cancelled' ? 'Cancelled' : 'Completed'));
                    pur.append(itItems(d.purchaseItems, d.purchaseTotals));
                    pur.append($('<a class="btn btn-primary btn-xs"></a>').attr('href', '../web_purchase/managepurchase.aspx?purchaseId=' + h.purchaseId).html('<i class="fa fa-eye"></i> View Purchase'));
                } else {
                    pur.append($('<p class="text-muted"></p>').text('The purchase entry has not been created yet. Use Create Purchase to generate it.'));
                }
                return box.append(sales).append(pur);
            }

            $('#transferList').on('click', '.it-toggle', function () {
                var row = $(this).closest('tr.it-row'), detail = row.next('.it-detail'), cell = detail.children('td');
                if (detail.is(':visible')) { detail.hide(); return; }
                detail.show();
                if (detail.data('loaded') || detail.data('loading')) return;
                detail.data('loading', true);
                cell.text('Loading details...');
                $.ajax({
                    type: 'POST',
                    url: 'view_sales_order.aspx/LoadTransferDetail',
                    data: JSON.stringify({ smoId: parseInt($('#tabInterstock').attr('data-order-id'), 10), smId: parseInt(row.attr('data-sm'), 10) }),
                    contentType: 'application/json; charset=utf-8',
                    dataType: 'json',
                    success: function (response) {
                        var d = response.d;
                        if (!d || !d.ok) { cell.text(d && d.message ? d.message : 'Unable to load the transfer details.'); return; }
                        cell.empty().append(itRender(d));
                        detail.data('loaded', true);
                    },
                    error: function () { cell.text('Unable to load the transfer details. Please try again.'); },
                    complete: function () { detail.data('loading', false); }
                });
            });

            var retrying = false;
            $('#transferList').on('click', '.it-retry', function () {
                if (retrying) return;
                var btn = $(this), smId = parseInt(btn.closest('tr.it-row').attr('data-sm'), 10), smoId = parseInt($('#tabInterstock').attr('data-order-id'), 10);
                retrying = true;
                btn.prop('disabled', true);
                $.ajax({
                    type: 'POST',
                    url: 'view_sales_order.aspx/RetryTransferPurchase',
                    data: JSON.stringify({ smoId: smoId, smId: smId }),
                    contentType: 'application/json; charset=utf-8',
                    dataType: 'json',
                    success: function (response) {
                        var r = response.d;
                        if (r && r.ok) {
                            location.href = 'view_sales_order.aspx?smoId=' + smoId + '&done=purchasecreated&invoiceId=' + smId + '&purchaseId=' + r.purchaseId + '#tabInterstock';
                            return;
                        }
                        retrying = false;
                        btn.prop('disabled', false);
                        $('#transferResult').html($('<div class="alert alert-danger"></div>').text(r && r.message ? r.message : 'The purchase could not be generated.'));
                    },
                    error: function () {
                        retrying = false;
                        btn.prop('disabled', false);
                        $('#transferResult').html($('<div class="alert alert-danger"></div>').text('The purchase could not be generated. Please refresh the list before trying again.'));
                    }
                });
            });

            if (location.hash === '#tabReserved' || location.hash === '#tabProduction' || location.hash === '#tabInvoices' || location.hash === '#tabInterstock') {
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
                                    <div class="info-row"><span class="k">Sales Order Status</span><span class="v"><% if (StatusText != "") { %><span class="status so-status <%= StatusCss %>"><%= StatusText %></span><% } else { %><span class="text-muted">Not available</span><% } %></span></div>
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
                            <div class="so-overview ov-loading" id="soOverview" data-order-id="<%= Enc(Order["smo_id"]) %>" role="region" aria-label="Sales order overview">
                                <div class="ov-item ov-metric" id="ovOverall">
                                    <span class="ov-ico"><i class="fa fa-tachometer"></i></span>
                                    <span class="ov-body">
                                        <span class="ov-label">Overall</span>
                                        <span class="ov-skel"></span>
                                        <span class="ov-real"><span class="ov-value"><span class="ov-pct" id="ovOverallText">0%</span><small>Complete</small></span><span class="ov-bar"><span id="ovOverallBar"></span></span></span>
                                    </span>
                                </div>
                                <div class="ov-item ov-metric" id="ovDelivery">
                                    <span class="ov-ico"><i class="fa fa-truck"></i></span>
                                    <span class="ov-body">
                                        <span class="ov-label">Delivery</span>
                                        <span class="ov-skel"></span>
                                        <span class="ov-real"><span class="ov-value"><span class="ov-pct" id="ovDeliveryText">0%</span><small>Delivered</small></span><span class="ov-bar"><span id="ovDeliveryBar"></span></span></span>
                                    </span>
                                </div>
                                <a class="ov-item" id="ovInvoices" href="#tabInvoices" data-tab="#tabInvoices">
                                    <span class="ov-ico"><i class="fa fa-file-text-o"></i></span>
                                    <span class="ov-body"><span class="ov-label">Invoices</span><span class="ov-skel"></span><span class="ov-value ov-real">&mdash;</span></span>
                                </a>
                                <a class="ov-item" id="ovProduction" href="#tabProduction" data-tab="#tabProduction">
                                    <span class="ov-ico"><i class="fa fa-cogs"></i></span>
                                    <span class="ov-body"><span class="ov-label">Production</span><span class="ov-skel"></span><span class="ov-value ov-real">&mdash;</span></span>
                                </a>
                                <a class="ov-item" id="ovTransfers" href="#tabInterstock" data-tab="#tabInterstock">
                                    <span class="ov-ico"><i class="fa fa-exchange"></i></span>
                                    <span class="ov-body"><span class="ov-label">Transfers</span><span class="ov-skel"></span><span class="ov-value ov-real">&mdash;</span></span>
                                </a>
                                <a class="ov-item" id="ovReserved" href="#tabReserved" data-tab="#tabReserved">
                                    <span class="ov-ico"><i class="fa fa-cubes"></i></span>
                                    <span class="ov-body"><span class="ov-label">Reserved</span><span class="ov-skel"></span><span class="ov-value ov-real">&mdash;</span></span>
                                </a>
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
                                            <li><a href="#tabInterstock">Interstock Transfer Invoices</a></li>
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
                                                            <th>Length</th>
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
                                                                    <td style="text-align: right;"><%# Money(Eval("sio_discount_amount")) %> (<%# Pct(Eval("sio_discount_rate")) %>%)</td>
                                                                    <td style="text-align: right;"><%# Money(Eval("sio_tax_amount")) %> (<%# Pct(Eval("sio_item_tax")) %>%)</td>
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
                                                            <th rowspan="2">Reserve</th>
                                                            <th rowspan="2">Produce</th>
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
                                                                <th>Warehouse</th>
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
                                                <% if (InvoiceHint != "") { %><span class="text-muted" style="line-height: 34px;"><%= Enc(InvoiceHint) %></span><% } %>
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
                                        <div class="tab-pane" id="tabInterstock" data-order-id="<%= Enc(Order["smo_id"]) %>">
                                            <% if (TransferMessage != "") { %><div class="<%= TransferMessageCss %>"><%= Enc(TransferMessage) %></div><% } %>
                                            <div id="transferResult"></div>
                                            <div style="margin-bottom: 10px; overflow: hidden;">
                                                <% if (CanCreateTransfer) { %>
                                                <a href="sales_order_interstock_transfer.aspx?smoId=<%= Enc(Order["smo_id"]) %>" class="btn btn-success pull-right"><i class="fa fa-plus"></i> Create New Transfer</a>
                                                <% } else { %>
                                                <span class="btn btn-success pull-right disabled" title="<%= Enc(TransferHint) %>"><i class="fa fa-plus"></i> Create New Transfer</span>
                                                <% } %>
                                                <% if (Transfers.Count > 0) { %>
                                                <div class="it-toolbar">
                                                    <div class="input-group input-group-sm" style="width: 280px;">
                                                        <span class="input-group-addon"><i class="fa fa-search"></i></span>
                                                        <input type="text" id="transferSearch" class="form-control" placeholder="Search invoice, purchase, warehouse, customer..." autocomplete="off" />
                                                        <span class="input-group-btn"><button type="button" id="transferSearchClear" class="btn btn-default" title="Clear search" style="display: none;"><i class="fa fa-times"></i></button></span>
                                                    </div>
                                                    <span id="transferCount" class="text-muted"></span>
                                                </div>
                                                <% } %>
                                                <% if (TransferHint != "") { %><span class="text-muted" style="line-height: 34px; margin-left: 8px;"><%= Enc(TransferHint) %></span><% } %>
                                            </div>
                                            <% if (Transfers.Count == 0) { %>
                                            <div class="tab-empty">No stock transfers have been made for this sales order.</div>
                                            <% } else { %>
                                            <div style="overflow-x: auto;">
                                                <table class="table table-striped jambo_table table-bordered" id="transferList">
                                                    <thead style="background-color: #f1eeee; color: #525252">
                                                        <tr>
                                                            <th>Invoice</th>
                                                            <th>Source &rarr; Target Warehouse</th>
                                                            <th class="text-right">Items / Qty</th>
                                                            <th class="text-right">Invoice Amount</th>
                                                            <th>Purchase</th>
                                                            <th>Action</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody>
                                                        <% foreach (var t in Transfers) { %>
                                                        <tr class="it-row" data-sm="<%= t.salesId %>">
                                                            <td>
                                                                <strong>#<%= t.salesId %></strong><% if (t.invoiceNo != "") { %> (<%= Enc(t.invoiceNo) %>)<% } %>
                                                                <span class="sub-note"><%= Enc(t.date) %></span>
                                                            </td>
                                                            <td>
                                                                <%= Enc(t.source) %> &rarr; <%= Enc(t.targetWarehouse) %>
                                                                <span class="sub-note">Customer: <%= Enc(t.customer) %></span>
                                                            </td>
                                                            <td class="text-right"><%= t.itemCount %> item(s)<span class="sub-note">Qty <%= t.totalQty.ToString("0.####") %></span></td>
                                                            <td class="text-right"><%= Money(t.amount) %></td>
                                                            <td>
                                                                <% if (t.purchaseId > 0) { %><strong>#<%= t.purchaseId %></strong><% } else { %><span class="text-muted">Not created</span><% } %>
                                                                <span class="sub-note"><span class="status <%= TransferStatusCss(t.purchaseStatus) %>"><%= TransferStatusText(t.purchaseStatus) %></span></span>
                                                            </td>
                                                            <td class="it-actions">
                                                                <button type="button" class="btn btn-primary btn-xs it-toggle"><i class="fa fa-chevron-down"></i> Details</button>
                                                                <% if (t.purchaseStatus == "pending") { %><button type="button" class="btn btn-warning btn-xs it-retry"><i class="fa fa-plus"></i> Create Purchase</button><% } %>
                                                            </td>
                                                        </tr>
                                                        <tr class="it-detail" style="display: none;"><td colspan="6"></td></tr>
                                                        <% } %>
                                                        <tr class="it-empty" style="display: none;"><td colspan="6" class="text-center text-muted">No transfers match your search.</td></tr>
                                                    </tbody>
                                                </table>
                                            </div>
                                            <p class="text-muted" style="font-size: 11px;">Only invoices created through Inter Stock Transfer are listed here. A transfer's purchase entry is created separately: "Purchase Pending" means the invoice is saved and the purchase has not been created yet (use Create Purchase).</p>
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
                                        <% if (StatusText != "") { %><span class="status so-status <%= StatusCss %>" style="font-size: 14px;"><%= StatusText %></span><% } else { %><span class="text-muted">Not available</span><% } %>
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
                                        <asp:LinkButton ID="btnApprove" runat="server" CssClass="btn btn-success" OnClick="btnApprove_Click" OnClientClick="return confirmStatusChange('Approve this sales order? It will become eligible for stock reservation.');"><i class="fa fa-check"></i> Approve</asp:LinkButton>
                                        <asp:LinkButton ID="btnHold" runat="server" CssClass="btn btn-info" OnClick="btnHold_Click" OnClientClick="return confirmStatusChange('Put this sales order on hold? No further stock can be reserved or invoiced until it is approved again. Existing reservations are kept.');"><i class="fa fa-pause"></i> Put on Hold</asp:LinkButton>
                                        <asp:LinkButton ID="btnCancelCustomer" runat="server" CssClass="btn btn-warning" OnClick="btnCancelCustomer_Click" OnClientClick="return confirmStatusChange('Cancel this sales order as cancelled by the customer? All of its stock reservations will be released. This cannot be undone.');"><i class="fa fa-times"></i> Cancel (Customer)</asp:LinkButton>
                                        <asp:LinkButton ID="btnCancelCompany" runat="server" CssClass="btn btn-danger" OnClick="btnCancelCompany_Click" OnClientClick="return confirmStatusChange('Cancel this sales order as cancelled by the company? All of its stock reservations will be released. This cannot be undone.');"><i class="fa fa-ban"></i> Cancel (Company)</asp:LinkButton>
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
                    <div class="modal fade" id="produceModal" tabindex="-1" role="dialog" aria-labelledby="produceModalTitle" data-backdrop="static">
                        <div class="modal-dialog modal-lg" role="document">
                            <div class="modal-content">
                                <div class="modal-header">
                                    <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                                    <h4 class="modal-title" id="produceModalTitle"><i class="fa fa-cogs"></i> Produce Finished Goods</h4>
                                    <div class="modal-subtitle" id="produceModalSubtitle"></div>
                                </div>
                                <div class="modal-body">
                                    <div id="produceModalMessage" role="status" aria-live="polite"></div>
                                    <div class="pc-qty-box">
                                        <label for="produceQtyInput">Planned quantity <small class="text-muted" style="font-weight: 400;">(decides how much raw material is needed)</small></label>
                                        <span class="pc-qty-input"><input type="number" id="produceQtyInput" class="form-control" min="0" step="any" /> <strong id="produceQtyUom"></strong></span>
                                        <span class="pc-qty-hint" id="produceQtyHint"></span>
                                    </div>
                                    <div id="produceModalContent"></div>
                                </div>
                                <div class="modal-footer">
                                    <span class="pc-spinner" id="produceSpinner" style="display: none;"><i class="fa fa-spinner fa-spin"></i> Producing...</span>
                                    <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
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
                                    <h4 class="modal-title" id="batchModalTitle">Reserve Raw Material</h4>
                                    <div class="modal-subtitle" id="batchModalSubtitle"></div>
                                </div>
                                <div class="modal-body" id="batchModalBody"></div>
                                <div class="modal-footer">
                                    <div class="pick-totals"><span id="batchTotals"></span> <span id="batchSpinner" style="display: none;"><i class="fa fa-spinner fa-spin"></i> Processing...</span></div>
                                    <div class="pick-actions">
                                        <span id="batchFooterButtons" style="display: none;">
                                            <button type="button" class="btn btn-link" id="batchRelease" style="display: none;"><i class="fa fa-unlock"></i> Release existing reservation</button>
                                            <button type="button" class="btn btn-default" id="batchFifo"><i class="fa fa-sort-amount-asc"></i> Auto-fill (oldest first)</button>
                                            <button type="button" class="btn btn-default" id="batchClear"><i class="fa fa-eraser"></i> Clear</button>
                                            <button type="button" class="btn btn-primary" id="batchSubmit" disabled><i class="fa fa-lock"></i> Reserve Selected</button>
                                        </span>
                                        <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
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
</body>
</html>
