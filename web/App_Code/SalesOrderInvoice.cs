using commonfunction;
using MySql.Data.MySqlClient;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.Linq;
using System.Web;

// Invoicing against a sales order (sales_order_invoice.aspx and the Invoices tab of view_sales_order.aspx).
//  - An invoice is an ordinary tbl_sales_master / tbl_sales_items bill saved by the shared neworder.aspx.cs SaveInvoice, linked to the order
//    with sm_refid = smo_id, sm_is_inter_stock_transfer_invoice = 0 and tbl_sales_items.sio_id = the order line.
//  - Quantities are tracked in the order line's UOM (the unit of tbl_sales_items.si_qty): remaining = sio_finalqty - SUM(si_qty) of the linked invoices.
//  - Invoicing consumes the order line's own reservations: the reserved batches are reduced (batch UOM) and the reservation rows are
//    reduced or deleted, in the same transaction as the invoice.
public static partial class SalesOrderStock
{
    const decimal WholeTolerance = 0.000001m;
    const int SalesActionType = (int)Constants.ActionType.SALES;

    sealed class InvoiceRes
    {
        public int ResId, BatchId, SioId, ItbsId, BranchId, Priority;
        public decimal Qty, Cost;
        public string BatchNo, Created;
    }

    sealed class InvoiceLineStock
    {
        public SalesOrderInvoiceLine Line;
        public decimal Qty;
        public decimal NeedBatch;
    }

    static DataTable Sel(mySqlConnection db, bool tx, string sql, params MySqlParameter[] ps)
    {
        return tx ? db.SelectQueryForTransaction(sql, ps) : db.SelectQuery(sql, ps);
    }

    static void RequireInvoiceStaff(out int staffId, out string staffType)
    {
        staffId = 0;
        staffType = "";
        HttpContext context = HttpContext.Current;
        if (context == null
            || context.Request.Cookies["invntrystaffId"] == null
            || context.Request.Cookies["invntrystaffTypeID"] == null
            || context.Request.Cookies["invntrystaffBranchId"] == null
            || context.Request.Cookies["invntrystaffCountryId"] == null
            || !int.TryParse(context.Request.Cookies["invntrystaffId"].Value, out staffId)
            || staffId <= 0)
            throw new HttpException(401, "Please sign in again.");

        var authentication = new LoginAuthentication();
        authentication.userAuthentication();
        authentication.checkPageAcess(7);
        staffType = context.Request.Cookies["invntrystaffTypeID"].Value;
    }

    static string OrderScope(int staffId, string staffType, List<MySqlParameter> ps)
    {
        ps.Add(new MySqlParameter("@u", staffId));
        string scope = " and smo.branch_id in (select branch_id from tbl_user_branches where user_id=@u)";
        if (staffType == "2")
        {
            ps.Add(new MySqlParameter("@owner", staffId));
            scope += " and smo.smo_userid=@owner";
        }
        return scope;
    }

    static string InvoiceStatusText(int status)
    {
        switch (status)
        {
            case 0: return "New";
            case 1: return "Processed";
            case 2: return "Delivered";
            case 3: return "To be confirmed";
            case 4: return "Cancelled";
            case 5: return "Rejected";
            case 6: return "Pending";
            default: return "";
        }
    }

    static string InvoiceStatusCss(int status)
    {
        switch (status)
        {
            case 0: return "label label-warning";
            case 1: return "label label-primary";
            case 2: return "label label-success";
            case 3: return "label label-info";
            case 4:
            case 5: return "label label-danger";
            default: return "label label-default";
        }
    }

    static Snapshot LoadUomSnapshot(mySqlConnection db, bool tx)
    {
        var s = new Snapshot();
        foreach (DataRow r in Sel(db, tx, "select tum_id,tum_type_id,tum_convertion_fac,tum_name from tbl_item_uom").Rows)
            s.Uoms[I(r["tum_id"])] = new Uom { Id = I(r["tum_id"]), TypeId = I(r["tum_type_id"]), Fac = D(r["tum_convertion_fac"]), Name = S(r["tum_name"]) };
        return s;
    }

    // Order lines with ordered, already invoiced and reserved quantities. The invoiced quantity counts every invoice linked to the order
    // (sm_refid = smo_id, sm_is_inter_stock_transfer_invoice = 0).
    static List<SalesOrderInvoiceLine> ReadInvoiceLines(mySqlConnection db, bool tx, int smoId, int branchId, out Dictionary<int, decimal[]> factors)
    {
        Snapshot uoms = LoadUomSnapshot(db, tx);
        factors = new Dictionary<int, decimal[]>();
        DataTable dt = Sel(db, tx, "select sio.sio_id,sio.row_no,sio.itbs_id,sio.itm_id,sio.itm_name as sio_name,sio.tum_id,sio.sio_finalqty,sio.sio_org_price,sio.sio_price,sio.sio_discount_rate,"
            + "tis.branch_id as tis_branch,tis.itm_id as tis_itm,tis.itm_code,tp.tp_tax_percentage,tp.tp_cess,"
            + "m.itm_name,m.itm_type,m.itsv_uom_purchase,m.itsv_uom_sales,"
            + "ifnull((select sum(si.si_qty) from tbl_sales_items si inner join tbl_sales_master sm on sm.sm_id=si.sm_id "
            + "where si.sio_id=sio.sio_id and sm.sm_refid=sio.smo_id and sm.sm_is_inter_stock_transfer_invoice=0),0) as invoiced,"
            + "ifnull((select sum(r.itbsr_qty) from tbl_item_batchstock_reserve r inner join tbl_item_batch b on b.itbh_id=r.itbh_id "
            + "inner join tbl_itembranch_stock bs on bs.itbs_id=b.itbs_id where r.sio_id=sio.sio_id and bs.itm_id=sio.itm_id),0) as reserved_batch "
            + "from tbl_sales_items_order sio left join tbl_itembranch_stock tis on tis.itbs_id=sio.itbs_id "
            + "left join tbl_item_master m on m.itm_id=sio.itm_id left join tbl_tax_profile tp on tp.tp_tax_code=tis.tp_tax_code "
            + "where sio.smo_id=@o order by sio.row_no,sio.sio_id",
            new MySqlParameter("@o", smoId));

        var lines = new List<SalesOrderInvoiceLine>();
        foreach (DataRow r in dt.Rows)
        {
            int lineTum = I(r["tum_id"]), salesTum = I(r["itsv_uom_sales"]), purchaseTum = I(r["itsv_uom_purchase"]);
            var l = new SalesOrderInvoiceLine
            {
                SioId = I(r["sio_id"]),
                RowNo = I(r["row_no"]),
                ItmId = I(r["itm_id"]),
                ItbsId = I(r["itbs_id"]),
                Name = S(r["itm_name"]) != "" ? S(r["itm_name"]) : S(r["sio_name"]),
                Code = S(r["itm_code"]),
                IsProduct = I(r["itm_type"]) == 1,
                Ordered = D(r["sio_finalqty"]),
                Invoiced = D(r["invoiced"]),
                Price = D(r["sio_price"]),
                OrgPrice = r["sio_org_price"] == DBNull.Value ? D(r["sio_price"]) : D(r["sio_org_price"]),
                DiscountRate = D(r["sio_discount_rate"]),
                TaxPercent = D(r["tp_tax_percentage"]),
                CessPercent = D(r["tp_cess"])
            };
            l.Remaining = Math.Max(0m, l.Ordered - l.Invoiced);
            l.Uom = UomName(uoms, lineTum > 0 ? lineTum : salesTum);
            l.InvoiceableQty = Floor3(l.Remaining + WholeTolerance);
            l.MaxQty = l.InvoiceableQty;

            if (l.ItmId <= 0 || l.ItbsId <= 0)
                l.Issue = "This order item is not linked to an item master record.";
            else if (I(r["tis_branch"]) != branchId || I(r["tis_itm"]) != l.ItmId)
                l.Issue = "This item is not stocked in the order's warehouse.";
            else if (r["tp_tax_percentage"] == DBNull.Value)
                l.Issue = "The item has no tax profile.";
            else if (l.IsProduct)
            {
                decimal? lineToSales = Conv(uoms, 1m, lineTum > 0 ? lineTum : salesTum, salesTum);
                decimal? f = Conv(uoms, 1m, purchaseTum > 0 ? purchaseTum : salesTum, salesTum);
                if (salesTum <= 0 || !lineToSales.HasValue || !f.HasValue || lineToSales.Value <= 0 || f.Value <= 0)
                    l.Issue = "Invalid UOM conversion between the order line and the item's stock UOM.";
                else
                {
                    factors[l.SioId] = new decimal[] { lineToSales.Value, f.Value };
                    l.Reserved = Round6(D(r["reserved_batch"]) * f.Value / lineToSales.Value);
                    l.MaxQty = Math.Min(l.MaxQty, Floor3(l.Reserved + WholeTolerance));
                }
            }
            if (l.Issue != null)
                l.MaxQty = 0;
            lines.Add(l);
        }
        return lines;
    }

    public static SalesOrderInvoicePage LoadInvoicePage(int smoId, int staffId, string staffType)
    {
        var page = new SalesOrderInvoicePage();
        var db = new mySqlConnection();
        try
        {
            var ps = new List<MySqlParameter> { new MySqlParameter("@id", smoId) };
            string scope = OrderScope(staffId, staffType, ps);
            DataTable dt = db.SelectQuery("select smo.smo_id,smo.smo_invoice_no,smo.cust_id,smo.branch_id,smo.smo_delivery_status,smo.branch_tax_method,smo.branch_tax_inclusive,"
                + "DATE_FORMAT(smo.smo_date,'%d-%b-%Y %H:%i') as orderDate,tc.cust_name,tc.cust_phone,tc.cust_phone1,tc.cust_email,tc.cust_address,tc.cust_city,tc.cust_tax_reg_id,"
                + "tc.cust_amount,tc.max_creditamt,tc.max_creditperiod,tb.branch_name "
                + "from tbl_sales_master_order smo inner join tbl_customer tc on tc.cust_id=smo.cust_id left join tbl_branch tb on tb.branch_id=smo.branch_id "
                + "where smo.smo_id=@id" + scope, ps.ToArray());
            if (dt == null || dt.Rows.Count == 0)
            {
                page.Message = "Sales order not found.";
                return page;
            }
            DataRow r = dt.Rows[0];
            int status = I(r["smo_delivery_status"]);
            var h = new SalesOrderInvoiceHeader
            {
                SmoId = I(r["smo_id"]),
                BranchId = I(r["branch_id"]),
                CustId = I(r["cust_id"]),
                Status = status,
                TaxMethod = I(r["branch_tax_method"]),
                TaxInclusive = I(r["branch_tax_inclusive"]),
                OrderNo = "#" + I(r["smo_id"]) + (S(r["smo_invoice_no"]) != "" ? " (" + S(r["smo_invoice_no"]) + ")" : ""),
                OrderDate = S(r["orderDate"]),
                CustomerName = S(r["cust_name"]),
                Phone = S(r["cust_phone"]),
                Phone2 = S(r["cust_phone1"]),
                Email = S(r["cust_email"]),
                Address = S(r["cust_address"]),
                City = S(r["cust_city"]),
                TaxRegId = S(r["cust_tax_reg_id"]),
                BranchName = S(r["branch_name"]),
                StatusText = SalesOrderStatus.Name(status),
                StatusCss = SalesOrderStatus.Css(status),
                AccountBalance = D(r["cust_amount"]),
                CreditAmount = D(r["max_creditamt"]),
                CreditPeriod = D(r["max_creditperiod"])
            };
            page.Header = h;
            Dictionary<int, decimal[]> factors;
            page.Lines = ReadInvoiceLines(db, false, smoId, h.BranchId, out factors);
            bool anyRemaining = page.Lines.Any(x => x.InvoiceableQty > 0);
            page.CanInvoice = IsOpenStatus(status) && anyRemaining;
            if (!IsOpenStatus(status))
                page.Message = "Invoices can be created only for an Approved or Processed sales order.";
            else if (!anyRemaining)
                page.Message = "All quantities of this sales order have been invoiced.";
        }
        finally
        {
            Close(db);
        }
        return page;
    }

    public static List<SalesOrderInvoiceRow> LoadInvoices(int smoId)
    {
        var rows = new List<SalesOrderInvoiceRow>();
        var db = new mySqlConnection();
        try
        {
            DataTable dt = db.SelectQuery("select sm.sm_id,sm.sm_invoice_no,DATE_FORMAT(sm.sm_date,'%d-%b-%Y %H:%i') as invoiceDate,tc.cust_name,sm.sm_netamount,sm.sm_delivery_status,sm.branch_tax_method,"
                + "(select count(*) from tbl_sales_items si where si.sm_id=sm.sm_id) as item_count,"
                + "(select ifnull(sum(tr.cr),0) from tbl_transactions tr where tr.action_ref_id=sm.sm_id and tr.action_type=@a and tr.partner_type=@p) as paid "
                + "from tbl_sales_master sm inner join tbl_customer tc on tc.cust_id=sm.cust_id "
                + "where sm.sm_is_inter_stock_transfer_invoice=0 and sm.sm_refid=@o order by sm.sm_id desc",
                new MySqlParameter[] { new MySqlParameter("@o", smoId), new MySqlParameter("@a", SalesActionType), new MySqlParameter("@p", (int)Constants.PartnerType.CUSTOMER) });
            foreach (DataRow r in dt.Rows)
            {
                var row = new SalesOrderInvoiceRow
                {
                    SmId = I(r["sm_id"]),
                    InvoiceNo = S(r["sm_invoice_no"]),
                    Date = S(r["invoiceDate"]),
                    Customer = S(r["cust_name"]),
                    Amount = D(r["sm_netamount"]),
                    Status = I(r["sm_delivery_status"]),
                    TaxMethod = I(r["branch_tax_method"]),
                    ItemCount = I(r["item_count"]),
                    Paid = D(r["paid"])
                };
                row.StatusText = InvoiceStatusText(row.Status);
                row.StatusCss = InvoiceStatusCss(row.Status);
                if (row.Paid >= row.Amount - 0.005m)
                {
                    row.PaymentText = "Paid";
                    row.PaymentCss = "label label-success";
                }
                else if (row.Paid > 0)
                {
                    row.PaymentText = "Partially paid";
                    row.PaymentCss = "label label-info";
                }
                else
                {
                    row.PaymentText = "Unpaid";
                    row.PaymentCss = "label label-warning";
                }
                rows.Add(row);
            }
        }
        finally
        {
            Close(db);
        }
        return rows;
    }

    static string Inv(decimal d)
    {
        return d.ToString("0.##########", CultureInfo.InvariantCulture);
    }

    static void ValidateInvoiceRequest(SalesOrderInvoiceRequest rq)
    {
        if (rq == null || rq.smoId <= 0)
            throw new StockException("Invalid sales order.");
        decimal token;
        if (string.IsNullOrWhiteSpace(rq.sessionId) || rq.sessionId.Length < 10 || rq.sessionId.Length > 20
            || !rq.sessionId.All(c => c >= '0' && c <= '9') || !decimal.TryParse(rq.sessionId, NumberStyles.None, CultureInfo.InvariantCulture, out token))
            throw new StockException("The invoice session is invalid. Please reload the page.");
        if (rq.lines == null || rq.lines.Count == 0)
            throw new StockException("Select at least one item to invoice.");
        if (rq.lines.Any(x => x == null || x.sioId <= 0))
            throw new StockException("Invalid item selected.");
        if (rq.lines.Select(x => x.sioId).Distinct().Count() != rq.lines.Count)
            throw new StockException("The same item is selected more than once.");
        if (rq.lines.Any(x => x.qty <= 0))
            throw new StockException("The quantity of every selected item must be greater than zero.");
        if (rq.lines.Any(x => Math.Round(x.qty, 3, MidpointRounding.AwayFromZero) != x.qty))
            throw new StockException("The quantity can have at most 3 decimal places.");
        if (rq.paymentMode < 1 || rq.paymentMode > 3)
            throw new StockException("Select a payment mode.");
        if (rq.cashAmount < 0 || rq.chequeAmount < 0 || rq.cashAmount > 9999999999m || rq.chequeAmount > 9999999999m)
            throw new StockException("Enter valid payment amounts.");
        if (rq.chequeAmount > 0)
        {
            DateTime d;
            if (string.IsNullOrWhiteSpace(rq.chequeNo) || string.IsNullOrWhiteSpace(rq.chequeBank) || string.IsNullOrWhiteSpace(rq.chequeDate)
                || !DateTime.TryParse(rq.chequeDate, CultureInfo.InvariantCulture, DateTimeStyles.None, out d))
                throw new StockException("Enter the cheque number, date and bank.");
        }
    }

    static string ParseSaverMessage(string result)
    {
        if (string.IsNullOrEmpty(result) || result == "FAILED")
            return "The invoice could not be saved and no changes were made. Please try again.";
        try
        {
            var m = JsonConvert.DeserializeObject<Dictionary<string, string>>(result);
            string text;
            if (m != null && m.TryGetValue("message", out text))
                return text == "Order saved already" ? "This invoice was already saved. Please reload the page." : text;
        }
        catch (JsonException) { }
        return "The invoice could not be saved and no changes were made. Please try again.";
    }

    // Validates the request against the database and creates the invoice, then consumes the reservations and batches of the invoiced items.
    // Everything runs in one transaction that starts by locking the sales order row (the same lock reserve / release use), so concurrent
    // invoices or stock actions on the order are serialized and the remaining quantities below cannot be stale.
    public static SalesOrderInvoiceResult CreateInvoice(SalesOrderInvoiceRequest rq, SalesInvoiceSaver saver)
    {
        var result = new SalesOrderInvoiceResult();
        var db = new mySqlConnection();
        bool started = false;
        try
        {
            int staffId;
            string staffType;
            RequireInvoiceStaff(out staffId, out staffType);
            ValidateInvoiceRequest(rq);

            db.BeginTransaction();
            started = true;

            var ps = new List<MySqlParameter> { new MySqlParameter("@id", rq.smoId) };
            string scope = OrderScope(staffId, staffType, ps);
            DataTable so = db.SelectQueryForTransaction("select smo.cust_id,smo.branch_id,smo.smo_delivery_status,smo.branch_tax_method,smo.branch_tax_inclusive,smo.smo_order_type "
                + "from tbl_sales_master_order smo where smo.smo_id=@id" + scope + " for update", ps.ToArray());
            if (so.Rows.Count == 0)
                throw new StockException("Sales order not found.");
            int status = I(so.Rows[0]["smo_delivery_status"]);
            if (!IsOpenStatus(status))
                throw new StockException("Invoices can be created only for an Approved or Processed sales order.");
            int branchId = I(so.Rows[0]["branch_id"]);

            Dictionary<int, decimal[]> factors;
            List<SalesOrderInvoiceLine> all = ReadInvoiceLines(db, true, rq.smoId, branchId, out factors);

            var picked = new List<InvoiceLineStock>();
            foreach (SalesOrderInvoiceLine l in all)
            {
                SalesOrderInvoiceLineRequest q = rq.lines.FirstOrDefault(x => x.sioId == l.SioId);
                if (q == null)
                    continue;
                if (l.Issue != null)
                    throw new StockException(l.Name + ": " + l.Issue);
                if (q.qty > l.InvoiceableQty)
                    throw new StockException(l.Name + ": only " + Fmt(l.InvoiceableQty) + " " + l.Uom + " remain to be invoiced.");
                if (q.qty > l.MaxQty)
                    throw new StockException(l.Name + ": only " + Fmt(l.Reserved) + " " + l.Uom + " are reserved for this order. Reserve more stock before invoicing " + Fmt(q.qty) + ".");
                var p = new InvoiceLineStock { Line = l, Qty = q.qty };
                if (l.IsProduct)
                {
                    decimal[] f = factors[l.SioId];
                    p.NeedBatch = Math.Round(q.qty * f[0] / f[1], 3, MidpointRounding.AwayFromZero);
                    if (p.NeedBatch <= 0)
                        throw new StockException(l.Name + ": the quantity is too small to invoice.");
                }
                picked.Add(p);
            }
            if (picked.Count != rq.lines.Count)
                throw new StockException("An invoice item does not belong to this sales order.");
            if (picked.Select(p => p.Line.ItbsId).Distinct().Count() != picked.Count)
                throw new StockException("The same item appears on more than one selected order line.");

            var link = new SalesOrderInvoiceLink { SmoId = rq.smoId };
            var items = new List<Dictionary<string, string>>();
            foreach (InvoiceLineStock p in picked)
            {
                link.SioIds.Add(p.Line.SioId);
                items.Add(new Dictionary<string, string>
                {
                    { "itbs_id", p.Line.ItbsId.ToString(CultureInfo.InvariantCulture) },
                    { "si_org_price", Inv(p.Line.OrgPrice) },
                    { "si_price", Inv(p.Line.Price) },
                    { "si_qty", p.Qty.ToString(CultureInfo.InvariantCulture) },
                    { "si_foc", "0" },
                    { "si_discount_rate", Inv(p.Line.DiscountRate) },
                    { "si_approval_status", "0" },
                    { "si_itm_type", "0" }
                });
            }

            string note = (rq.note ?? "").Trim();
            if (note.Length > 1000)
                note = note.Substring(0, 1000);
            string chequeDate = "";
            DateTime cd;
            if (rq.chequeAmount > 0 && DateTime.TryParse(rq.chequeDate, CultureInfo.InvariantCulture, DateTimeStyles.None, out cd))
                chequeDate = cd.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
            string orderType = so.Rows[0]["smo_order_type"] == DBNull.Value ? "1" : I(so.Rows[0]["smo_order_type"]).ToString(CultureInfo.InvariantCulture);

            // The shared saver concatenates the note into SQL, so it is escaped here. All other text fields reach it as parameters or numbers.
            var neworder = new Dictionary<string, string>
            {
                { "sessionId", rq.sessionId },
                { "sm_cash_amt", Inv(rq.cashAmount) },
                { "sm_wallet_amt", "0" },
                { "sm_chq_amt", Inv(rq.chequeAmount) },
                { "sm_chq_date", chequeDate },
                { "sm_bank", rq.chequeAmount > 0 ? rq.chequeBank.Trim() : "" },
                { "sm_chq_no", rq.chequeAmount > 0 ? rq.chequeNo.Trim() : "" },
                { "sm_card_amt", "0" },
                { "sm_card_no", "" },
                { "sm_card_type", "" },
                { "sm_card_bank", "" },
                { "branch_tax_method", I(so.Rows[0]["branch_tax_method"]).ToString(CultureInfo.InvariantCulture) },
                { "branch_tax_inclusive", I(so.Rows[0]["branch_tax_inclusive"]).ToString(CultureInfo.InvariantCulture) },
                { "branch", branchId.ToString(CultureInfo.InvariantCulture) },
                { "sm_userid", staffId.ToString(CultureInfo.InvariantCulture) },
                { "cust_id", I(so.Rows[0]["cust_id"]).ToString(CultureInfo.InvariantCulture) },
                { "sm_delivery_status", "0" },
                { "sm_specialnote", MySqlHelper.EscapeString(note) },
                { "sm_latitude", "0" },
                { "sm_longitude", "0" },
                { "sm_order_type", orderType },
                { "sm_payment_type", rq.paymentMode.ToString(CultureInfo.InvariantCulture) },
                { "item_details", JsonConvert.SerializeObject(items) },
                { "acknowledgement", "{\"salesTick\":1,\"accountTick\":0,\"deliveryTick\":0}" }
            };

            bool completed;
            string saved = saver(db, neworder, link, out completed);
            int smId;
            if (!completed || !int.TryParse(saved, out smId) || smId <= 0)
            {
                // The saver has already rolled the transaction back.
                started = false;
                if (HttpContext.Current != null)
                    HttpContext.Current.Response.StatusCode = 200;
                throw new StockException(ParseSaverMessage(saved));
            }

            VerifyInvoiceTotals(db, smId, rq, picked);
            DateTime invoiceDate = DateTime.ParseExact(db.SelectScalarForTransaction("select date_format(sm_date,'%Y-%m-%d %H:%i:%s') from tbl_sales_master where sm_id=@i",
                new MySqlParameter[] { new MySqlParameter("@i", smId) }), "yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture);
            ConsumeInvoiceStock(db, invoiceDate, staffId, smId, picked, factors);

            db.CommitTransaction();
            started = false;
            result.ok = true;
            result.invoiceId = smId;
            result.taxMethod = I(so.Rows[0]["branch_tax_method"]);
            result.message = "Invoice #" + smId + " created.";
        }
        catch (StockException ex)
        {
            Rollback(db, started);
            result.message = ex.Message;
        }
        catch (HttpException)
        {
            Rollback(db, started);
            throw;
        }
        catch (Exception ex)
        {
            Rollback(db, started);
            new LogClass("salesorderinvoiceerror").write(ex);
            result.message = "The invoice could not be saved and no changes were made. Please try again.";
        }
        finally
        {
            Close(db);
        }
        return result;
    }

    // Final checks on the saved rows: the linked invoices never exceed the ordered quantity and the payment does not exceed the invoice.
    static void VerifyInvoiceTotals(mySqlConnection db, int smId, SalesOrderInvoiceRequest rq, List<InvoiceLineStock> picked)
    {
        foreach (DataRow r in db.SelectQueryForTransaction("select sio.sio_id,sio.sio_finalqty,"
            + "(select ifnull(sum(si.si_qty),0) from tbl_sales_items si inner join tbl_sales_master sm on sm.sm_id=si.sm_id "
            + "where si.sio_id=sio.sio_id and sm.sm_refid=sio.smo_id and sm.sm_is_inter_stock_transfer_invoice=0) as invoiced "
            + "from tbl_sales_items_order sio where sio.smo_id=@o",
            new MySqlParameter[] { new MySqlParameter("@o", rq.smoId) }).Rows)
        {
            if (picked.Any(p => p.Line.SioId == I(r["sio_id"])) && D(r["invoiced"]) > D(r["sio_finalqty"]) + WholeTolerance)
                throw new StockException("The invoiced quantity would exceed the ordered quantity. Please reload the page.");
        }
        decimal net = D(db.SelectScalarForTransaction("select sm_netamount from tbl_sales_master where sm_id=@i",
            new MySqlParameter[] { new MySqlParameter("@i", smId) }));
        if (rq.cashAmount + rq.chequeAmount > net + 0.005m)
            throw new StockException("The paid amount cannot be greater than the invoice amount (" + net.ToString("0.00", CultureInfo.InvariantCulture) + ").");
    }

    // Takes the invoiced quantity from the order line's own reservations, oldest batch first: the batch quantity is reduced, the reservation
    // row is reduced (deleted when fully used), branch stock is reduced and a stock ledger row is written per batch. Reservations of other
    // orders and the reservations of BOM raw materials (other items) are never touched.
    static void ConsumeInvoiceStock(mySqlConnection db, DateTime date, int staffId, int smId, List<InvoiceLineStock> picked, Dictionary<int, decimal[]> factors)
    {
        List<InvoiceLineStock> products = picked.Where(p => p.Line.IsProduct).ToList();
        if (products.Count == 0)
            return;

        var ps = new List<MySqlParameter>();
        string inList = InList("s", products.Select(p => p.Line.SioId), ps);
        DataTable rows = db.SelectQueryForTransaction("select r.itbsr_id,r.itbh_id,r.sio_id,r.itbsr_qty,r.itbrs_priority,b.itbs_id,b.branch_id,b.itbh_no,b.itbh_cost,tis.itm_id,"
            + "date_format(b.itbh_createddate,'%Y-%m-%d %H:%i:%s') as created "
            + "from tbl_item_batchstock_reserve r inner join tbl_item_batch b on b.itbh_id=r.itbh_id "
            + "inner join tbl_itembranch_stock tis on tis.itbs_id=b.itbs_id "
            + "where r.sio_id in (" + inList + ") order by b.itbh_id,r.itbsr_id for update", ps.ToArray());

        var reservations = new List<InvoiceRes>();
        foreach (DataRow r in rows.Rows)
        {
            InvoiceLineStock owner = products.FirstOrDefault(p => p.Line.SioId == I(r["sio_id"]));
            if (owner == null || owner.Line.ItmId != I(r["itm_id"]))
                continue;
            string created = S(r["created"]);
            reservations.Add(new InvoiceRes
            {
                ResId = I(r["itbsr_id"]), BatchId = I(r["itbh_id"]), SioId = I(r["sio_id"]), ItbsId = I(r["itbs_id"]), BranchId = I(r["branch_id"]),
                Qty = D(r["itbsr_qty"]), Priority = I(r["itbrs_priority"]), Cost = D(r["itbh_cost"]), BatchNo = S(r["itbh_no"]),
                Created = created == "" || created.StartsWith("0000") ? null : created
            });
        }

        foreach (InvoiceLineStock p in products)
        {
            decimal need = p.NeedBatch;
            IEnumerable<InvoiceRes> candidates = reservations.Where(x => x.SioId == p.Line.SioId)
                            .OrderByDescending(x => x.Priority).ThenBy(x => x.Created == null ? 1 : 0).ThenBy(x => x.Created, StringComparer.Ordinal).ThenBy(x => x.BatchId).ThenBy(x => x.ResId);
            foreach (InvoiceRes res in candidates)
            {
                if (need <= 0)
                    break;
                decimal take = Math.Min(res.Qty, need);
                if (take <= 0)
                    continue;
                if (Exec(db, "update tbl_item_batch set itbh_currentqty=itbh_currentqty-@q where itbh_id=@b and itbh_currentqty>=@q",
                    new MySqlParameter("@q", take), new MySqlParameter("@b", res.BatchId)) != 1)
                    throw new StockException(p.Line.Name + ": batch " + res.BatchNo + " does not have enough stock. No changes were made.");
                if (res.Qty - take < 0.0005m)
                {
                    if (Exec(db, "delete from tbl_item_batchstock_reserve where itbsr_id=@r", new MySqlParameter("@r", res.ResId)) != 1)
                        throw new StockException(p.Line.Name + ": the reservation changed. Please reload the page.");
                }
                else if (Exec(db, "update tbl_item_batchstock_reserve set itbsr_qty=itbsr_qty-@q where itbsr_id=@r and itbsr_qty>=@q",
                    new MySqlParameter("@q", take), new MySqlParameter("@r", res.ResId)) != 1)
                    throw new StockException(p.Line.Name + ": the reservation changed. Please reload the page.");
                res.Qty -= take;
                need -= take;

                AdjustBranchStock(db, res.ItbsId, -take);
                InsertSalesLedger(db, date, staffId, res, smId, take, p.Line.Name);
            }
            if (need > Tolerance)
                throw new StockException(p.Line.Name + ": the reserved stock is less than the quantity being invoiced. No changes were made.");
        }
    }

    static void InsertSalesLedger(mySqlConnection db, DateTime date, int staffId, InvoiceRes res, int smId, decimal qty, string name)
    {
        string narration = "Sold " + Fmt(qty) + " " + name + " in order #" + smId + " (batch " + res.BatchNo + ")";
        if (narration.Length > 150)
            narration = narration.Substring(0, 150);
        db.ExecuteQueryForTransaction("insert into tbl_stock_transactions (itbs_id,action_type,action_ref_id,user_id,narration,dr_qty,cr_qty,closing_stock,date,is_reconciliation,Cost,itbh_id,branch_id) "
            + "values (@i,@a,@r,@u,@n,@dr,0,(select itbs_stock from tbl_itembranch_stock where itbs_id=@i),@t,0,@c,@b,@br)",
            new MySqlParameter[] { new MySqlParameter("@i", res.ItbsId), new MySqlParameter("@a", SalesActionType), new MySqlParameter("@r", smId),
                new MySqlParameter("@u", staffId), new MySqlParameter("@n", narration), new MySqlParameter("@dr", qty), new MySqlParameter("@t", date),
                new MySqlParameter("@c", res.Cost), new MySqlParameter("@b", res.BatchId), new MySqlParameter("@br", res.BranchId) });
    }
}
