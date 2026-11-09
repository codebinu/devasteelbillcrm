<%@ Page Language="C#" AutoEventWireup="true" CodeFile="production_history.aspx.cs" Inherits="web_production_production_history" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <title>Production History | Invoice Me</title>
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
    </style>

    <script type="text/javascript">
        function esc(s) {
            return $("<div/>").text(s == null ? "" : String(s)).html();
        }

        function num(value) {
            return String(Math.round((Number(value) || 0) * 10000) / 10000);
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
            $("#txtSearch, #txtRef, #txtOrder, #txtCustomer, #txtProduct, #txtMaterial, #txtBatch, #txtQtyFrom, #txtQtyTo").keypress(function (e) {
                if (e.which == 13) { searchHistory(1); return false; }
            });
            getStaff();
            getBranches();
        });

        function getStaff() {
            $.ajax({
                type: "POST", url: "production_history.aspx/getStaff", data: "{}",
                contentType: "application/json; charset=utf-8", dataType: "json",
                success: function (msg) {
                    var htm = '<option value="-1" selected="selected">--All Users--</option>';
                    $.each(JSON.parse(msg.d), function (i, row) {
                        htm += '<option value="' + esc(row.user_id) + '">' + esc(row.name) + '</option>';
                    });
                    $("#slUser").html(htm);
                },
                error: function () { $("#slUser").html('<option value="-1">--All Users--</option>'); }
            });
        }

        function getBranches() {
            loading();
            $.ajax({
                type: "POST", url: "production_history.aspx/getBranches", data: "{}",
                contentType: "application/json; charset=utf-8", dataType: "json",
                success: function (msg) {
                    var obj = JSON.parse(msg.d);
                    var htm = '<option value="-1" selected="selected">--All Warehouses--</option>';
                    $.each(obj, function (i, row) {
                        htm += '<option value="' + esc(row.branch_id) + '">' + esc(row.branch_name) + '</option>';
                    });
                    $("#slBranch").html(htm);
                    Unloading();
                    searchHistory(1);
                },
                error: function () { Unloading(); alert("Internet Problem..!"); }
            });
        }

        function searchHistory(page) {
            var filters = {};
            var perpage = $("#slPerpage").val();
            if ($.trim($("#txtSearch").val()) != "") filters.search = $.trim($("#txtSearch").val());
            if ($("#slBranch").val() && $("#slBranch").val() != "-1") filters.branch = $("#slBranch").val();
            if ($("#txtSearchFromDate").val() != "") filters.from_date = $("#txtSearchFromDate").val();
            if ($("#txtSearchToDate").val() != "") filters.to_date = $("#txtSearchToDate").val();
            var text = { ref: '#txtRef', order: '#txtOrder', customer: '#txtCustomer', product: '#txtProduct', material: '#txtMaterial', batch: '#txtBatch', qty_from: '#txtQtyFrom', qty_to: '#txtQtyTo' };
            $.each(text, function (key, selector) {
                var v = $.trim($(selector).val());
                if (v !== "") filters[key] = v;
            });
            if ($("#slUser").val() && $("#slUser").val() != "-1") filters.user = $("#slUser").val();
            filters.sort = $("#slSort").val();
            $.ajax({
                type: "POST",
                url: "production_history.aspx/searchHistory",
                data: JSON.stringify({ page: page, filters: filters, perpage: parseInt(perpage, 10) }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (msg) {
                    Unloading();
                    if (msg.d == "E") {
                        $('#tblHistory > tbody').html('<tr><td colspan="8" style="text-align:center;color:red">Unable to load production history. Please try again.</td></tr>');
                        $("#txttotalcount").text(0);
                        $('#divPagination').html("");
                        return;
                    }
                    var obj = JSON.parse(msg.d);
                    var htm = "";
                    $("#txttotalcount").text(obj.count);
                    if (obj.count == 0) {
                        htm = '<tr><td colspan="8" style="text-align:center"><label>No production entries found.</label></td></tr>';
                    }
                    $.each(obj.data, function (i, row) {
                        htm += '<tr>';
                        htm += '<td><strong>' + esc(row.itpm_doc_no) + '</strong><span class="sub-note">Production #' + esc(row.itpm_id) + '</span></td>';
                        htm += '<td>' + esc(row.created) + (row.created_by ? '<span class="sub-note">' + esc(row.created_by) + '</span>' : '') + '</td>';
                        htm += '<td>#' + esc(row.smo_id) + (row.smo_invoice_no ? '<span class="sub-note">' + esc(row.smo_invoice_no) + '</span>' : '') + '</td>';
                        htm += '<td>' + esc(row.cust_name) + '</td>';
                        htm += '<td><strong>' + esc(row.itm_name) + '</strong>' + (row.itm_code ? '<span class="sub-note">' + esc(row.itm_code) + '</span>' : '') + '</td>';
                        htm += '<td style="text-align:right;white-space:nowrap;">' + num(row.itpi_quantity) + (row.uom ? ' ' + esc(row.uom) : '') + '</td>';
                        htm += '<td>' + (row.itbh_no ? esc(row.itbh_no) : '<span class="text-muted">-</span>') + '<span class="sub-note">' + esc(row.branch_name) + '</span></td>';
                        htm += '<td style="text-align:center;white-space:nowrap;">'
                            + '<button type="button" class="btn btn-xs btn-default job-view-btn" data-order="' + esc(row.smo_id) + '" data-job="' + esc(row.itpm_id) + '"><i class="fa fa-eye"></i> Details</button> '
                            + '<a class="btn btn-xs btn-default" target="_blank" href="../web_sales/view_sales_order.aspx?smoId=' + encodeURIComponent(row.smo_id) + '#tabProduction" title="Open the sales order production tab"><i class="fa fa-external-link"></i></a>'
                            + '</td>';
                        htm += '</tr>';
                    });
                    $('#tblHistory > tbody').html(htm);
                    $('#divPagination').html(obj.count > 0 ? paginate(obj.count, perpage, page, "searchHistory") : "");
                },
                error: function () { Unloading(); alert("Internet Problem..!"); }
            });
        }

        function resetFilters() {
            $("#txtSearch, #txtSearchFromDate, #txtSearchToDate, #txtRef, #txtOrder, #txtCustomer, #txtProduct, #txtMaterial, #txtBatch, #txtQtyFrom, #txtQtyTo").val("");
            $("#slBranch, #slUser").val("-1");
            $("#slSort").val("newest");
            $("#slPerpage").val("50");
            searchHistory(1);
        }

        function jobDetailHtml(d, smoId) {
            var uom = ' ' + esc(d.uom);
            function row(k, v) { return '<div class="info-row"><span class="k">' + esc(k) + '</span><span class="v">' + v + '</span></div>'; }
            function notRecorded() { return '<span class="text-muted">Not recorded</span>'; }
            var html = '<h5><strong>Production Information</strong></h5>'
                + row('Production job', esc(d.docNo) + ' (#' + d.itpmId + ')')
                + row('Sales order', '#' + esc(smoId) + ' (' + esc(d.orderRef) + ')')
                + row('Finished item', esc(d.itemName) + (d.itemCode ? ' (' + esc(d.itemCode) + ')' : ''))
                + row('Warehouse', d.branch ? esc(d.branch) : notRecorded())
                + row('Actual produced quantity', num(d.produced) + uom)
                + row('Reserved for this order', num(d.reserved) + uom)
                + row('Created', (d.createdDate ? esc(d.createdDate) : notRecorded()) + (d.createdBy ? ' by ' + esc(d.createdBy) : ''))
                + row('Document date', d.docDate ? esc(d.docDate) : notRecorded())
                + row('Status', '<span class="label label-success">' + esc(d.status) + '</span>');

            html += '<h5 style="margin-top: 15px;"><strong>Raw Materials Consumed</strong></h5>';
            if (!d.materials.length) {
                html += '<p class="text-muted">No raw-material record exists for this job.</p>';
            } else {
                html += '<div style="overflow-x: auto;"><table class="table table-striped jambo_table table-bordered"><thead style="background-color: #f1eeee; color: #525252"><tr>'
                    + '<th>Item</th><th style="text-align: right;">Quantity</th><th>UOM</th><th>Source batch</th></tr></thead><tbody>'
                    + $.map(d.materials, function (m) {
                        return '<tr><td>' + esc(m.name) + (m.code ? ' (' + esc(m.code) + ')' : '') + '</td><td style="text-align: right;">' + num(m.quantity)
                            + '</td><td>' + esc(m.uom) + '</td><td>' + esc(m.batchNo) + '</td></tr>';
                    }).join('') + '</tbody></table></div>';
            }

            html += '<h5 style="margin-top: 15px;"><strong>Finished Goods</strong></h5>'
                + row('Finished batch', d.batchNo ? esc(d.batchNo) + ' (batch #' + d.batchId + ')' : notRecorded())
                + row('Reserved for this order', num(d.reserved) + uom)
                + row('Remaining unreserved in batch', num(d.unreserved) + uom);

            html += '<h5 style="margin-top: 15px;"><strong>Events</strong></h5>'
                + '<ul style="padding-left: 18px; font-size: 13px;">' + $.map(d.events, function (e) {
                    return '<li>' + (e.when ? esc(e.when) : 'Date not recorded') + ' &mdash; ' + esc(e.text) + (e.by ? ' (' + esc(e.by) + ')' : '') + '</li>';
                }).join('') + '</ul>'
                + (d.movementNote ? '<p class="text-muted" style="font-size: 11px;">' + esc(d.movementNote) + '</p>' : '');
            return html;
        }

        $(document).on('click', '.job-view-btn', function () {
            var button = $(this);
            if (button.prop('disabled')) {
                return;
            }
            var smoId = parseInt(button.attr('data-order'), 10);
            button.prop('disabled', true);
            $('#jobModalBody').html('<div class="tab-empty"><i class="fa fa-spinner fa-spin"></i> Loading job details...</div>');
            $('#jobModal').modal('show');
            $.ajax({
                type: 'POST',
                url: 'production_history.aspx/LoadProductionJob',
                data: JSON.stringify({ smoId: smoId, itpmId: parseInt(button.attr('data-job'), 10) }),
                contentType: 'application/json; charset=utf-8',
                dataType: 'json',
                success: function (response) {
                    var d = response.d;
                    $('#jobModalBody').html(d && d.ok ? jobDetailHtml(d, smoId) : '<p class="text-danger">' + esc((d && d.message) || 'Unable to load the production job details.') + '</p>');
                },
                error: function () {
                    $('#jobModalBody').html('<p class="text-danger">Unable to load the production job details. Please try again.</p>');
                },
                complete: function () {
                    button.prop('disabled', false);
                }
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
                                    <label style="font-weight: bold; font-size: 16px;">Production History</label>
                                </div>
                                <div class="col-md-6 col-xs-5">
                                    <a href="start_production.aspx">
                                        <div class="btn btn-primary btn-xs pull-right" style="margin-top: 5px"><label style="color: #fff; margin-right: 5px; font-size: 14px;" class="fa fa-cogs"></label>Production Queue</div>
                                    </a>
                                </div>
                            </div>
                        </nav>
                    </div>
                </div>

                <div class="right_col" role="main">
                    <div class="">
                        <div class="clearfix"></div>
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
                                                <label>Production Ref</label>
                                                <input type="text" class="form-control has-feedback-left" id="txtRef" placeholder="Production reference / no" />
                                                <span class="fa fa-cogs form-control-feedback left" aria-hidden="true"></span>
                                            </div>
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
                                                <label>Finished Product</label>
                                                <input type="text" class="form-control has-feedback-left" id="txtProduct" placeholder="Item name / code" />
                                                <span class="fa fa-cube form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Raw Material Used</label>
                                                <input type="text" class="form-control has-feedback-left" id="txtMaterial" placeholder="Raw material name / code" />
                                                <span class="fa fa-flask form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Finished Batch</label>
                                                <input type="text" class="form-control has-feedback-left" id="txtBatch" placeholder="Batch no" />
                                                <span class="fa fa-barcode form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Action By</label>
                                                <select class="form-control" style="text-indent: 25px;" id="slUser" onchange="searchHistory(1);"></select>
                                                <span class="fa fa-user-circle form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Warehouse</label>
                                                <select class="form-control" style="text-indent: 25px;" id="slBranch" onchange="searchHistory(1);"></select>
                                                <span class="fa fa-map-marker form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Produced from</label>
                                                <input type="text" class="form-control has-feedback-left" style="background-color: #fff" id="txtSearchFromDate" placeholder="From Date" />
                                                <span class="fa fa-calendar form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Produced upto</label>
                                                <input type="text" class="form-control has-feedback-left" style="background-color: #fff" id="txtSearchToDate" placeholder="To Date" />
                                                <span class="fa fa-calendar form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Quantity from</label>
                                                <input type="number" min="0" step="any" class="form-control has-feedback-left" id="txtQtyFrom" placeholder="Min produced qty" />
                                                <span class="fa fa-sort-numeric-asc form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Quantity upto</label>
                                                <input type="number" min="0" step="any" class="form-control has-feedback-left" id="txtQtyTo" placeholder="Max produced qty" />
                                                <span class="fa fa-sort-numeric-desc form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-6 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Search</label>
                                                <input type="text" class="form-control has-feedback-left" id="txtSearch" placeholder="Production ref / Order no / Customer / Item / Batch" />
                                                <span class="fa fa-search form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-3 col-sm-6 col-xs-12 form-group has-feedback">
                                                <label>Sort by</label>
                                                <select class="form-control" style="text-indent: 25px;" id="slSort" onchange="searchHistory(1);">
                                                    <option value="newest" selected="selected">Newest first</option>
                                                    <option value="oldest">Oldest first</option>
                                                    <option value="qty_desc">Largest quantity</option>
                                                    <option value="order">Sales order (latest)</option>
                                                </select>
                                                <span class="fa fa-sort form-control-feedback left" aria-hidden="true"></span>
                                            </div>
                                            <div class="col-md-12 col-sm-12 col-xs-12">
                                                <div class="btn btn-success mybtnstyl" onclick="searchHistory(1);" style="float: right">
                                                    <li class="fa fa-search" style="margin-right: 5px;"></li>
                                                    Search
                                                </div>
                                                <div class="btn btn-primary mybtnstyl" onclick="resetFilters();" style="float: right">
                                                    <li class="fa fa-refresh" style="margin-right: 5px;"></li>
                                                    Reset
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
                                        <div class="col-md-6 col-sm-12 col-xs-12">
                                            <label>Production Entries</label><span class="badge" style="color: #fff; margin-left: 5px; background: #d00101; padding-left: 5px; padding-right: 5px;" id="txttotalcount"></span>
                                        </div>
                                        <div class="col-md-6 col-sm-12 col-xs-12">
                                            <ul class="nav navbar-right panel_toolbox">
                                                <li>
                                                    <select id="slPerpage" onchange="searchHistory(1);" class="input-sm">
                                                        <option value="50">50</option>
                                                        <option value="100">100</option>
                                                        <option value="250">250</option>
                                                        <option value="500">500</option>
                                                    </select></li>
                                            </ul>
                                        </div>
                                        <div class="clearfix"></div>
                                    </div>
                                    <div class="col-md-12 col-sm-12 col-xs-12" style="overflow-x: auto;">
                                        <div class="x_content">
                                            <table id="tblHistory" class="table table-striped jambo_table bulk_action" style="table-layout: auto;">
                                                <thead style="background-color: #f1eeee; color: #525252">
                                                    <tr>
                                                        <th>Production</th>
                                                        <th>Created</th>
                                                        <th>Sales Order</th>
                                                        <th>Customer</th>
                                                        <th>Finished Item</th>
                                                        <th style="text-align: right;">Produced (stock UOM)</th>
                                                        <th>Finished Batch</th>
                                                        <th style="text-align: center;">Action</th>
                                                    </tr>
                                                </thead>
                                                <tbody></tbody>
                                            </table>
                                            <div id="divPagination"></div>
                                        </div>
                                    </div>
                                    <div class="clearfix"></div>
                                </div>
                            </div>
                        </div>

                        <div class="modal fade" id="jobModal" tabindex="-1" role="dialog" aria-labelledby="jobModalTitle">
                            <div class="modal-dialog modal-lg" role="document">
                                <div class="modal-content">
                                    <div class="modal-header">
                                        <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                                        <h4 class="modal-title" id="jobModalTitle">Production Job Details</h4>
                                    </div>
                                    <div class="modal-body" id="jobModalBody"></div>
                                    <div class="modal-footer"><button type="button" class="btn btn-default" data-dismiss="modal">Close</button></div>
                                </div>
                            </div>
                        </div>
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
