using commonfunction;
using MySql.Data.MySqlClient;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.Linq;
using System.Web;

// Inter-warehouse stock transfer against a sales order (sales_order_interstock_transfer.aspx).
//  - The source warehouse (tbl_branch) issues a sales invoice through sp_save_sales_entry1.1: branch_id = source warehouse, cust_id = the customer
//    account mapped to the target warehouse (tbl_branch.cust_id), sm_is_inter_stock_transfer_invoice = 1. The procedure takes the stock, the batch and
//    the order line's reservation of every row (itbs_id / itbh_id / sio_id) from the source warehouse and uses the customer state against the source
//    warehouse state for CGST/SGST or IGST.
//  - Saving the invoice does not create the purchase. The user later runs Create Purchase on the invoice (RetryInterStockPurchase), which calls
//    sp_create_purchase_from_sales: it creates the purchase in the target warehouse (the branch whose cust_id is the invoice customer) against the
//    vendor account of the source warehouse (tbl_branch.vn_id). Its items carry the same sio_id, so the received batch is reserved for the same order line.
//  - Both procedures commit on their own, so the two documents cannot share one database transaction. A failed purchase leaves the invoice as
//    "Purchase pending" and can be retried. Creation runs under the order lock and a purchase already linked to the invoice is never created twice.
public class InterStockSource
{
    public int branchId;
    public string name;
    public int custId;
    public int vnId;
}

public class InterStockTarget
{
    public int custId;
    public string custName;
    public int branchId;
    public string branchName;
}

public class InterStockTargetsResult
{
    public bool ok;
    public string message;
    public List<InterStockTarget> targets = new List<InterStockTarget>();
}

public class InterStockTargetDetail
{
    public bool ok;
    public string message;
    public int custId;
    public int branchId;
    public string branchName;
    public string name, phone, phone2, email, address, city, taxRegId;
    public decimal balance;
    public bool interState;
}

public class InterStockBatch
{
    public int itbhId;
    public int itbsId;
    public string batchNo;
    public decimal reserved;
    public decimal physical;
    public decimal max;
}

public class InterStockLine
{
    public int sioId, itmId;
    public string name, code, uom, lineUom, note;
    public decimal ordered, price, orgPrice, discountRate, taxPercent, cessPercent;
    public List<InterStockBatch> batches = new List<InterStockBatch>();
}

public class InterStockItemsResult
{
    public bool ok;
    public string message;
    public int taxMethod, taxInclusive;
    public List<InterStockLine> lines = new List<InterStockLine>();
}

public class InterStockRequest
{
    public int smoId { get; set; }
    public int sourceBranchId { get; set; }
    public int targetCustId { get; set; }
    public string sessionId { get; set; }
    public List<InterStockRequestLine> lines { get; set; }
}

public class InterStockRequestLine
{
    public int sioId { get; set; }
    public int itbhId { get; set; }
    public decimal qty { get; set; }
    public decimal? price { get; set; }
}

public class InterStockResult
{
    public bool ok;
    public bool salesDone;
    public int salesId;
    public int purchaseId;
    public string message;
}

// One transfer: the invoice of the source warehouse together with its purchase. purchaseStatus is "completed" (purchase created), "pending"
// (no purchase yet, it can be retried) or "cancelled" (the purchase was cancelled afterwards).
public class InterStockTransferRow
{
    public int salesId, purchaseId, itemCount;
    public string invoiceNo, date, source, targetWarehouse, customer, purchaseStatus, vendor, purchaseWarehouse;
    public decimal amount, totalQty, purchaseAmount;
}

public class InterStockDetailItem
{
    public string name, code, batchNo, uom;
    public decimal qty, price, discountRate, taxPercent, cgst, sgst, igst, taxAmount, netAmount;
}

public class InterStockDetailTotals
{
    public decimal total, discount, tax, net;
}

public class InterStockTransferDetail
{
    public bool ok;
    public string message;
    public InterStockTransferRow header;
    public string gstType;
    public InterStockDetailTotals salesTotals = new InterStockDetailTotals();
    public InterStockDetailTotals purchaseTotals = new InterStockDetailTotals();
    public List<InterStockDetailItem> salesItems = new List<InterStockDetailItem>();
    public List<InterStockDetailItem> purchaseItems = new List<InterStockDetailItem>();
}

public static partial class SalesOrderStock
{
    sealed class TransferParty
    {
        public int BranchId, CustId, VnId, StateId, TaxMethod, TaxInclusive, CustState;
        public string BranchName, CustName, TimeZone;
    }

    // Procedure error codes 30001-30016 carry messages written for users; any other error is a database error that is logged, not shown.
    static string ProcedureMessage(JObject o, string procedure, string fallback)
    {
        int code = 0;
        JToken c = o == null ? null : o["error_code"];
        if (c != null && c.Type != JTokenType.Null)
            int.TryParse(Convert.ToString((object)c), out code);
        string message = o == null || o["message"] == null ? "" : Convert.ToString((object)o["message"]);
        if (code == 30008 && procedure == "sp_save_sales_entry1.1")
            return "This transfer was already submitted. Please reload the page.";
        if (code >= 30001 && code <= 30016 && message != "")
            return message;
        new LogClass("salesorderinterstockerror").write(new Exception(procedure + " failed: " + (o == null ? "no result" : o.ToString(Formatting.None))));
        return fallback;
    }

    static MySqlConnection OpenProcedureConnection()
    {
        // The procedures are called with CALL and read back through user variables, which Connector/NET only allows on request.
        var b = new MySqlConnectionStringBuilder(System.Configuration.ConfigurationManager.AppSettings["db_connect_mysql"]) { AllowUserVariables = true };
        var con = new MySqlConnection(b.ConnectionString);
        con.Open();
        return con;
    }

    static string LockName(int smoId) { return "interstock_so_" + smoId.ToString(CultureInfo.InvariantCulture); }

    static bool AcquireLock(MySqlConnection con, int smoId)
    {
        using (var cmd = new MySqlCommand("select get_lock(@n,5)", con))
        {
            cmd.Parameters.AddWithValue("@n", LockName(smoId));
            return Convert.ToString(cmd.ExecuteScalar()) == "1";
        }
    }

    static void ReleaseLock(MySqlConnection con, int smoId)
    {
        try
        {
            using (var cmd = new MySqlCommand("select release_lock(@n)", con))
            {
                cmd.Parameters.AddWithValue("@n", LockName(smoId));
                cmd.ExecuteScalar();
            }
        }
        catch (Exception) { }
    }

    static DataRow LoadTransferOrder(mySqlConnection db, int smoId, int staffId, string staffType)
    {
        var ps = new List<MySqlParameter> { new MySqlParameter("@id", smoId) };
        string scope = OrderScope(staffId, staffType, ps);
        DataTable so = db.SelectQuery("select smo.smo_id,smo.cust_id,smo.branch_id,smo.smo_delivery_status,smo.smo_order_type from tbl_sales_master_order smo where smo.smo_id=@id" + scope, ps.ToArray());
        if (so == null || so.Rows.Count == 0)
            throw new StockException("Sales order not found.");
        if (!IsOpenStatus(I(so.Rows[0]["smo_delivery_status"])))
            throw new StockException("Stock can be transferred only for an Approved or Processed sales order.");
        return so.Rows[0];
    }

    // The source warehouse must be one of the staff member's warehouses and have both a customer and a vendor account.
    static TransferParty LoadTransferSource(mySqlConnection db, int sourceBranchId, int staffId)
    {
        DataTable dt = db.SelectQuery("select b.branch_id,b.branch_name,b.cust_id,b.vn_id,b.branch_state_id,b.branch_tax_method,b.branch_tax_inclusive,b.branch_timezone "
            + "from tbl_branch b where b.branch_id=@b and b.branch_id in (select branch_id from tbl_user_branches where user_id=@u)",
            new MySqlParameter[] { new MySqlParameter("@b", sourceBranchId), new MySqlParameter("@u", staffId) });
        if (dt == null || dt.Rows.Count == 0)
            throw new StockException("Select a valid source warehouse.");
        DataRow r = dt.Rows[0];
        var p = new TransferParty
        {
            BranchId = I(r["branch_id"]), BranchName = S(r["branch_name"]), CustId = I(r["cust_id"]), VnId = I(r["vn_id"]), StateId = I(r["branch_state_id"]),
            TaxMethod = I(r["branch_tax_method"]), TaxInclusive = I(r["branch_tax_inclusive"]), TimeZone = S(r["branch_timezone"])
        };
        if (p.CustId <= 0)
            throw new StockException("The source warehouse has no customer account. Link a customer to the warehouse first.");
        if (p.VnId <= 0)
            throw new StockException("The source warehouse has no vendor account. Link a vendor to the warehouse first.");
        return p;
    }

    // The target is the warehouse that owns the customer account (sp_create_purchase_from_sales requires exactly one such warehouse).
    // The customer's state decides CGST/SGST or IGST in the invoice, so it has to agree with the warehouse's state.
    static TransferParty LoadTransferTarget(mySqlConnection db, TransferParty source, int custId)
    {
        DataTable dt = db.SelectQuery("select b.branch_id,b.branch_name,b.cust_id,b.branch_state_id,c.cust_name,c.cust_state "
            + "from tbl_branch b inner join tbl_customer c on c.cust_id=b.cust_id where b.cust_id=@c",
            new MySqlParameter[] { new MySqlParameter("@c", custId) });
        if (dt == null || dt.Rows.Count == 0)
            throw new StockException("Select a valid target customer.");
        if (dt.Rows.Count > 1)
            throw new StockException("More than one warehouse is linked to the selected customer.");
        DataRow r = dt.Rows[0];
        var p = new TransferParty
        {
            BranchId = I(r["branch_id"]), BranchName = S(r["branch_name"]), CustId = I(r["cust_id"]), CustName = S(r["cust_name"]),
            StateId = I(r["branch_state_id"]), CustState = I(r["cust_state"])
        };
        if (p.BranchId == source.BranchId || p.CustId == source.CustId)
            throw new StockException("The target cannot be the source warehouse.");
        if (p.CustState != p.StateId)
            throw new StockException("The state of the customer account differs from the state of the warehouse " + p.BranchName + ", so the GST type of the invoice would be wrong. Correct the customer's state first.");
        return p;
    }

    public static List<InterStockSource> LoadInterStockSources()
    {
        int staffId;
        string staffType;
        RequireInvoiceStaff(out staffId, out staffType);
        var list = new List<InterStockSource>();
        var db = new mySqlConnection();
        try
        {
            foreach (DataRow r in db.SelectQuery("select distinct b.branch_id,b.branch_name,b.cust_id,b.vn_id from tbl_branch b inner join tbl_user_branches ub on ub.branch_id=b.branch_id "
                + "where ub.user_id=@u and ifnull(b.cust_id,0)>0 and ifnull(b.vn_id,0)>0 order by b.branch_name",
                new MySqlParameter[] { new MySqlParameter("@u", staffId) }).Rows)
                list.Add(new InterStockSource { branchId = I(r["branch_id"]), name = S(r["branch_name"]), custId = I(r["cust_id"]), vnId = I(r["vn_id"]) });
        }
        finally { Close(db); }
        return list;
    }

    // Customers of every other warehouse; a customer that is linked to more than one warehouse cannot be used by the purchase procedure.
    public static InterStockTargetsResult LoadInterStockTargets(int smoId, int sourceBranchId)
    {
        var result = new InterStockTargetsResult();
        int staffId;
        string staffType;
        RequireInvoiceStaff(out staffId, out staffType);
        var db = new mySqlConnection();
        try
        {
            LoadTransferOrder(db, smoId, staffId, staffType);
            TransferParty source = LoadTransferSource(db, sourceBranchId, staffId);
            foreach (DataRow r in db.SelectQuery("select b.branch_id,b.branch_name,b.cust_id,c.cust_name from tbl_branch b inner join tbl_customer c on c.cust_id=b.cust_id "
                + "where b.branch_id<>@s and ifnull(b.cust_id,0)>0 and b.cust_id<>@sc and (select count(*) from tbl_branch x where x.cust_id=b.cust_id)=1 order by c.cust_name",
                new MySqlParameter[] { new MySqlParameter("@s", source.BranchId), new MySqlParameter("@sc", source.CustId) }).Rows)
                result.targets.Add(new InterStockTarget { custId = I(r["cust_id"]), custName = S(r["cust_name"]), branchId = I(r["branch_id"]), branchName = S(r["branch_name"]) });
            result.ok = true;
            if (result.targets.Count == 0)
                result.message = "No other warehouse has a customer account that can receive stock.";
        }
        catch (StockException ex) { result.message = ex.Message; }
        finally { Close(db); }
        return result;
    }

    public static InterStockTargetDetail LoadInterStockTarget(int smoId, int sourceBranchId, int custId)
    {
        var result = new InterStockTargetDetail();
        int staffId;
        string staffType;
        RequireInvoiceStaff(out staffId, out staffType);
        var db = new mySqlConnection();
        try
        {
            LoadTransferOrder(db, smoId, staffId, staffType);
            TransferParty source = LoadTransferSource(db, sourceBranchId, staffId);
            TransferParty target = LoadTransferTarget(db, source, custId);
            DataTable dt = db.SelectQuery("select tc.cust_name,tc.cust_phone,tc.cust_phone1,tc.cust_email,tc.cust_address,tc.cust_city,tc.cust_tax_reg_id,tc.cust_amount from tbl_customer tc where tc.cust_id=@c",
                new MySqlParameter[] { new MySqlParameter("@c", custId) });
            if (dt.Rows.Count == 0)
                throw new StockException("Select a valid target customer.");
            DataRow r = dt.Rows[0];
            result.custId = target.CustId;
            result.branchId = target.BranchId;
            result.branchName = target.BranchName;
            result.name = S(r["cust_name"]);
            result.phone = S(r["cust_phone"]);
            result.phone2 = S(r["cust_phone1"]);
            result.email = S(r["cust_email"]);
            result.address = S(r["cust_address"]);
            result.city = S(r["cust_city"]);
            result.taxRegId = S(r["cust_tax_reg_id"]);
            result.balance = D(r["cust_amount"]);
            result.interState = target.CustState != source.StateId;
            result.ok = true;
        }
        catch (StockException ex) { result.message = ex.Message; }
        finally { Close(db); }
        return result;
    }

    // Reserved order stock of the source warehouse. The sales procedure consumes the order line's reservation of the batch it is given, so only reserved
    // batches of that warehouse can be transferred, in whole units of the batch UOM (the procedure's quantity is an integer), never above the reservation
    // row it reduces, the batch's physical quantity or the warehouse stock.
    static List<InterStockLine> ReadTransferLines(mySqlConnection db, int smoId, int sourceBranchId)
    {
        Snapshot uoms = LoadUomSnapshot(db, false);
        DataTable lines = db.SelectQuery("select sio.sio_id,sio.row_no,sio.itm_id,sio.itm_name as sio_name,sio.tum_id,sio.sio_finalqty,sio.sio_org_price,sio.sio_price,sio.sio_discount_rate,"
            + "m.itm_name,m.itm_type,m.itsv_uom_purchase,m.itsv_uom_sales from tbl_sales_items_order sio left join tbl_item_master m on m.itm_id=sio.itm_id "
            + "where sio.smo_id=@o order by sio.row_no,sio.sio_id", new MySqlParameter[] { new MySqlParameter("@o", smoId) });
        DataTable stock = db.SelectQuery("select r.itbsr_id,r.sio_id,r.itbh_id,r.itbsr_qty,b.itbh_no,b.itbh_currentqty,b.itbs_id,tis.itm_id,tis.itm_code,tis.itbs_stock,tp.tp_tax_percentage,tp.tp_cess "
            + "from tbl_item_batchstock_reserve r inner join tbl_item_batch b on b.itbh_id=r.itbh_id inner join tbl_itembranch_stock tis on tis.itbs_id=b.itbs_id "
            + "left join tbl_tax_profile tp on tp.tp_tax_code=tis.tp_tax_code "
            + "where r.sio_id in (select sio_id from tbl_sales_items_order where smo_id=@o) and b.branch_id=@s and tis.branch_id=@s and ifnull(b.itbh_status,1)=1 "
            + "order by r.sio_id,r.itbsr_id",
            new MySqlParameter[] { new MySqlParameter("@o", smoId), new MySqlParameter("@s", sourceBranchId) });

        var result = new List<InterStockLine>();
        foreach (DataRow r in lines.Rows)
        {
            if (I(r["itm_type"]) != 1 || I(r["itm_id"]) <= 0)
                continue;
            int sioId = I(r["sio_id"]), itmId = I(r["itm_id"]);
            int lineTum = I(r["tum_id"]), salesTum = I(r["itsv_uom_sales"]), purchaseTum = I(r["itsv_uom_purchase"]);
            var l = new InterStockLine
            {
                sioId = sioId,
                itmId = itmId,
                name = S(r["itm_name"]) != "" ? S(r["itm_name"]) : S(r["sio_name"]),
                ordered = D(r["sio_finalqty"]),
                discountRate = D(r["sio_discount_rate"]),
                uom = UomName(uoms, purchaseTum > 0 ? purchaseTum : salesTum),
                lineUom = UomName(uoms, lineTum > 0 ? lineTum : salesTum)
            };
            decimal? lineToSales = Conv(uoms, 1m, lineTum > 0 ? lineTum : salesTum, salesTum);
            decimal? f = Conv(uoms, 1m, purchaseTum > 0 ? purchaseTum : salesTum, salesTum);
            bool uomOk = salesTum > 0 && lineToSales.HasValue && f.HasValue && lineToSales.Value > 0 && f.Value > 0;
            // The invoice quantity is in batch units, so the order line's price (per line unit) is converted to a price per batch unit.
            decimal factor = uomOk ? f.Value / lineToSales.Value : 1m;
            decimal linePrice = D(r["sio_price"]);
            l.price = Math.Round(linePrice * factor, 2, MidpointRounding.AwayFromZero);
            l.orgPrice = Math.Round((r["sio_org_price"] == DBNull.Value ? linePrice : D(r["sio_org_price"])) * factor, 2, MidpointRounding.AwayFromZero);

            var seen = new HashSet<int>();
            bool taxMissing = false;
            foreach (DataRow s in stock.Rows)
            {
                if (I(s["sio_id"]) != sioId || I(s["itm_id"]) != itmId)
                    continue;
                // The procedure reduces the first reservation row of the batch only.
                if (!seen.Add(I(s["itbh_id"])))
                    continue;
                if (s["tp_tax_percentage"] == DBNull.Value)
                {
                    taxMissing = true;
                    continue;
                }
                l.code = S(s["itm_code"]);
                l.taxPercent = D(s["tp_tax_percentage"]);
                l.cessPercent = D(s["tp_cess"]);
                decimal physical = D(s["itbh_currentqty"]), reserved = D(s["itbsr_qty"]);
                decimal max = Math.Floor(Math.Min(Math.Min(reserved, physical), Math.Max(0m, D(s["itbs_stock"]))));
                l.batches.Add(new InterStockBatch { itbhId = I(s["itbh_id"]), itbsId = I(s["itbs_id"]), batchNo = S(s["itbh_no"]), reserved = reserved, physical = physical, max = Math.Max(0m, max) });
            }
            if (!uomOk)
            {
                l.note = "Invalid UOM conversion between the order line and the item's stock UOM.";
                l.batches.Clear();
            }
            else if (taxMissing && l.batches.Count == 0)
                l.note = "The item has no tax profile.";
            else if (l.batches.Count == 0)
                l.note = "No stock is reserved for this order item in the source warehouse. Reserve stock from this warehouse in the Reserved Items tab first.";
            else if (l.batches.All(b => b.max <= 0))
                l.note = "The reserved quantity in the source warehouse is less than one whole unit.";
            result.Add(l);
        }
        return result;
    }

    public static InterStockItemsResult LoadInterStockItems(int smoId, int sourceBranchId)
    {
        var result = new InterStockItemsResult();
        int staffId;
        string staffType;
        RequireInvoiceStaff(out staffId, out staffType);
        var db = new mySqlConnection();
        try
        {
            LoadTransferOrder(db, smoId, staffId, staffType);
            TransferParty source = LoadTransferSource(db, sourceBranchId, staffId);
            result.taxMethod = source.TaxMethod;
            result.taxInclusive = source.TaxInclusive;
            result.lines = ReadTransferLines(db, smoId, source.BranchId);
            result.ok = true;
        }
        catch (StockException ex) { result.message = ex.Message; }
        finally { Close(db); }
        return result;
    }

    static string Plain(decimal d) { return d.ToString("0.########", CultureInfo.InvariantCulture); }

    static DateTime TransferNow(mySqlConnection db, string timeZone)
    {
        if (!string.IsNullOrEmpty(timeZone))
        {
            try { return TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById(timeZone)); }
            catch (TimeZoneNotFoundException) { }
            catch (InvalidTimeZoneException) { }
        }
        return Now(db);
    }

    static void ValidateTransferRequest(InterStockRequest rq)
    {
        if (rq == null || rq.smoId <= 0)
            throw new StockException("Invalid sales order.");
        if (rq.sourceBranchId <= 0)
            throw new StockException("Select the source warehouse.");
        if (rq.targetCustId <= 0)
            throw new StockException("Select the target customer.");
        decimal token;
        if (string.IsNullOrWhiteSpace(rq.sessionId) || rq.sessionId.Length < 10 || rq.sessionId.Length > 20
            || !rq.sessionId.All(c => c >= '0' && c <= '9') || !decimal.TryParse(rq.sessionId, NumberStyles.None, CultureInfo.InvariantCulture, out token))
            throw new StockException("The transfer session is invalid. Please reload the page.");
        if (rq.lines == null || rq.lines.Count == 0)
            throw new StockException("Enter a transfer quantity for at least one item.");
        if (rq.lines.Any(x => x == null || x.sioId <= 0 || x.itbhId <= 0))
            throw new StockException("Invalid item selected.");
        if (rq.lines.Select(x => x.sioId + ":" + x.itbhId).Distinct().Count() != rq.lines.Count)
            throw new StockException("The same batch is selected more than once.");
        if (rq.lines.Any(x => x.qty < 1 || x.qty != Math.Floor(x.qty) || x.qty > 999999999m))
            throw new StockException("The transfer quantity must be a whole number greater than zero.");
        if (rq.lines.Any(x => x.price.HasValue && (x.price.Value < 0m || x.price.Value > 999999999m)))
            throw new StockException("The unit price must be zero or more.");
    }

    // Saves the transfer invoice, then the purchase. The order lock serialises transfers of one order (also across browser tabs), and the quantities are
    // validated again under it because the procedures themselves do not check that the reservation covers the quantity.
    public static InterStockResult CreateInterStockTransfer(InterStockRequest rq)
    {
        var result = new InterStockResult();
        var db = new mySqlConnection();
        MySqlConnection con = null;
        bool locked = false;
        try
        {
            int staffId;
            string staffType;
            RequireInvoiceStaff(out staffId, out staffType);
            ValidateTransferRequest(rq);

            DataRow order = LoadTransferOrder(db, rq.smoId, staffId, staffType);
            TransferParty source = LoadTransferSource(db, rq.sourceBranchId, staffId);
            TransferParty target = LoadTransferTarget(db, source, rq.targetCustId);

            con = OpenProcedureConnection();
            locked = AcquireLock(con, rq.smoId);
            if (!locked)
                throw new StockException("Another transfer for this sales order is in progress. Please try again in a moment.");

            if (db.SelectScalar("select count(*) from tbl_sales_master where sm_sales_sessionid=@t", new MySqlParameter[] { new MySqlParameter("@t", rq.sessionId) }) != "0")
                throw new StockException("This transfer was already submitted. Please reload the page.");

            List<InterStockLine> available = ReadTransferLines(db, rq.smoId, source.BranchId);
            var items = new JArray();
            int row = 0;
            foreach (InterStockRequestLine q in rq.lines)
            {
                InterStockLine line = available.FirstOrDefault(x => x.sioId == q.sioId);
                if (line == null)
                    throw new StockException("An item does not belong to this sales order.");
                InterStockBatch batch = line.batches.FirstOrDefault(x => x.itbhId == q.itbhId);
                if (batch == null)
                    throw new StockException(line.name + ": the batch is not reserved for this order in the source warehouse.");
                if (q.qty > batch.max)
                    throw new StockException(line.name + " (batch " + batch.batchNo + "): only " + Fmt(batch.max) + " " + line.uom + " can be transferred from the source warehouse.");
                items.Add(new JObject
                {
                    { "row_no", row++ },
                    { "itbs_id", batch.itbsId },
                    { "itbh_id", batch.itbhId },
                    { "sio_id", line.sioId },
                    { "si_qty", q.qty },
                    { "si_foc", 0 },
                    { "si_org_price", line.orgPrice },
                    { "si_price", q.price.HasValue ? Math.Round(q.price.Value, 2, MidpointRounding.AwayFromZero) : line.price },
                    { "si_discount_rate", line.discountRate },
                    { "si_approval_status", 0 },
                    { "si_itm_type", 0 }
                });
            }

            DateTime now = TransferNow(db, source.TimeZone);
            var filters = new JObject
            {
                { "cust_id", target.CustId },
                { "branch", source.BranchId },
                { "sm_userid", staffId },
                { "sessionId", rq.sessionId },
                { "sm_delivery_status", 0 },
                { "sm_order_type", order["smo_order_type"] == DBNull.Value ? 1 : I(order["smo_order_type"]) },
                { "sm_payment_type", 2 },
                { "sm_is_inter_stock_transfer_invoice", 1 },
                { "sm_latitude", 0 },
                { "sm_longitude", 0 },
                { "sm_specialnote", "Inter stock transfer against sales order #" + rq.smoId },
                { "branch_tax_method", source.TaxMethod },
                { "branch_tax_inclusive", source.TaxInclusive },
                { "acknowledgement", new JObject { { "salesTick", 1 }, { "accountTick", 0 }, { "deliveryTick", 0 } } }
            };

            int smId = CallSalesProcedure(con, filters, items, now, out result.message);
            if (smId <= 0)
            {
                result.ok = false;
                return result;
            }
            result.salesDone = true;
            result.salesId = smId;
            LinkTransferInvoice(db, smId, rq.smoId);

            // The purchase is created later by the user (Create Purchase in the Interstock Transfer Invoices list).
            result.ok = true;
            result.message = "Transfer invoice #" + smId + " was created in " + source.BranchName + ". Use Create Purchase in the Interstock Transfer Invoices list to generate the purchase entry for " + target.BranchName + ".";
        }
        catch (StockException ex)
        {
            result.message = ex.Message;
        }
        catch (HttpException)
        {
            throw;
        }
        catch (Exception ex)
        {
            new LogClass("salesorderinterstockerror").write(ex);
            result.message = result.salesDone
                ? "Invoice #" + result.salesId + " was created, but the transfer could not be completed. Check the transfers list below."
                : "The transfer could not be saved. Please check the transfers list before trying again.";
        }
        finally
        {
            if (con != null)
            {
                if (locked)
                    ReleaseLock(con, rq.smoId);
                con.Dispose();
            }
            Close(db);
        }
        return result;
    }

    // Returns the new sm_id, or 0 with a message. The procedure rolls back by itself and reports the error in p_result.
    static int CallSalesProcedure(MySqlConnection con, JObject filters, JArray items, DateTime now, out string message)
    {
        message = null;
        using (var cmd = new MySqlCommand("CALL `sp_save_sales_entry1.1`(@pf,@pi,@pn,@osm,@ores)", con))
        {
            cmd.Parameters.Add(new MySqlParameter("@pf", MySqlDbType.LongText) { Value = filters.ToString(Formatting.None) });
            cmd.Parameters.Add(new MySqlParameter("@pi", MySqlDbType.LongText) { Value = items.ToString(Formatting.None) });
            cmd.Parameters.Add(new MySqlParameter("@pn", MySqlDbType.DateTime) { Value = now });
            cmd.ExecuteNonQuery();
        }
        JObject o;
        int smId = ReadProcedureOutput(con, "@osm", "@ores", out o);
        if (smId > 0 && o != null && o["success"] != null && (bool)o["success"])
            return smId;
        message = ProcedureMessage(o, "sp_save_sales_entry1.1", "The invoice could not be saved and no changes were made. Please try again.");
        return 0;
    }

    static int ReadProcedureOutput(MySqlConnection con, string idVar, string resultVar, out JObject result)
    {
        result = null;
        using (var cmd = new MySqlCommand("select " + idVar + "," + resultVar, con))
        using (MySqlDataReader rd = cmd.ExecuteReader())
        {
            if (!rd.Read())
                return 0;
            object raw = rd.IsDBNull(1) ? null : rd.GetValue(1);
            string json = raw == null ? null : (raw is byte[] ? System.Text.Encoding.UTF8.GetString((byte[])raw) : Convert.ToString(raw));
            if (!string.IsNullOrEmpty(json))
            {
                try { result = JObject.Parse(json); }
                catch (JsonException) { result = null; }
            }
            return rd.IsDBNull(0) ? 0 : Convert.ToInt32(rd.GetValue(0));
        }
    }

    // The procedure does not link the invoice to the order; sm_refid does it without counting it as an ordinary invoice of the order.
    static void LinkTransferInvoice(mySqlConnection db, int smId, int smoId)
    {
        for (int attempt = 0; attempt < 2; attempt++)
        {
            if (db.ExecuteQuery("update tbl_sales_master set sm_refid=@o where sm_id=@s and sm_is_inter_stock_transfer_invoice=1",
                new MySqlParameter[] { new MySqlParameter("@o", smoId), new MySqlParameter("@s", smId) }))
                return;
        }
        new LogClass("salesorderinterstockerror").write(new Exception("Invoice #" + smId + " could not be linked to sales order #" + smoId));
    }

    // A purchase already created for the invoice is found through its sm_id, or through the reference, vendor and warehouse that
    // sp_create_purchase_from_sales writes (the first covers a purchase whose link update failed).
    static int ExistingTransferPurchase(mySqlConnection db, int smId, TransferParty source, TransferParty target)
    {
        string id = db.SelectScalar("select ifnull(min(pm_id),0) from tbl_purchase_master where sm_id=@s or (pm_ref_no=@s and vn_id=@v and branch_id=@b)",
            new MySqlParameter[] { new MySqlParameter("@s", smId), new MySqlParameter("@v", source.VnId), new MySqlParameter("@b", target.BranchId) });
        int pm;
        return int.TryParse(id, out pm) ? pm : 0;
    }

    static bool CreateTransferPurchase(mySqlConnection db, MySqlConnection con, int smId, TransferParty source, TransferParty target, out int pmId, out string error)
    {
        error = null;
        pmId = ExistingTransferPurchase(db, smId, source, target);
        if (pmId > 0)
            return true;

        try
        {
            using (var cmd = new MySqlCommand("CALL `sp_create_purchase_from_sales`(@psm,@opm,@opres)", con))
            {
                cmd.Parameters.Add(new MySqlParameter("@psm", MySqlDbType.Int32) { Value = smId });
                cmd.ExecuteNonQuery();
            }
        }
        catch (MySqlException ex)
        {
            new LogClass("salesorderinterstockerror").write(ex);
            error = "a database error occurred";
            return false;
        }
        JObject o;
        int created = ReadProcedureOutput(con, "@opm", "@opres", out o);
        if (created <= 0 || o == null || o["success"] == null || !(bool)o["success"])
        {
            error = ProcedureMessage(o, "sp_create_purchase_from_sales", "a database error occurred");
            return false;
        }
        pmId = created;
        // Marks the purchase as the receiving side of the transfer and keeps the link to the invoice.
        if (!db.ExecuteQuery("update tbl_purchase_master set sm_id=@s,pm_is_inter_stock_transfer_invoice=1 where pm_id=@p",
            new MySqlParameter[] { new MySqlParameter("@s", smId), new MySqlParameter("@p", pmId) }))
            new LogClass("salesorderinterstockerror").write(new Exception("Purchase #" + pmId + " could not be linked to invoice #" + smId));
        return true;
    }

    // Creates the purchase of a saved transfer invoice (Create Purchase), or reports the one that already exists.
    public static InterStockResult RetryInterStockPurchase(int smoId, int smId)
    {
        var result = new InterStockResult { salesId = smId, salesDone = true };
        var db = new mySqlConnection();
        MySqlConnection con = null;
        bool locked = false;
        try
        {
            int staffId;
            string staffType;
            RequireInvoiceStaff(out staffId, out staffType);
            if (smoId <= 0 || smId <= 0)
                throw new StockException("Invalid transfer.");
            var ps = new List<MySqlParameter> { new MySqlParameter("@id", smoId) };
            string scope = OrderScope(staffId, staffType, ps);
            if (db.SelectQuery("select smo.smo_id from tbl_sales_master_order smo where smo.smo_id=@id" + scope, ps.ToArray()).Rows.Count == 0)
                throw new StockException("Sales order not found.");

            DataTable sm = db.SelectQuery("select sm.branch_id,sm.cust_id from tbl_sales_master sm where sm.sm_id=@s and sm.sm_refid=@o and sm.sm_is_inter_stock_transfer_invoice=1",
                new MySqlParameter[] { new MySqlParameter("@s", smId), new MySqlParameter("@o", smoId) });
            if (sm.Rows.Count == 0)
                throw new StockException("The transfer invoice does not belong to this sales order.");
            TransferParty source = LoadTransferSource(db, I(sm.Rows[0]["branch_id"]), staffId);
            DataTable tb = db.SelectQuery("select b.branch_id,b.branch_name from tbl_branch b where b.cust_id=@c",
                new MySqlParameter[] { new MySqlParameter("@c", I(sm.Rows[0]["cust_id"])) });
            if (tb.Rows.Count != 1)
                throw new StockException("Exactly one warehouse must be linked to the invoice customer.");
            var target = new TransferParty { BranchId = I(tb.Rows[0]["branch_id"]), BranchName = S(tb.Rows[0]["branch_name"]) };

            con = OpenProcedureConnection();
            locked = AcquireLock(con, smoId);
            if (!locked)
                throw new StockException("Another transfer for this sales order is in progress. Please try again in a moment.");

            int pmId;
            string error;
            if (!CreateTransferPurchase(db, con, smId, source, target, out pmId, out error))
            {
                result.message = "The purchase entry could not be generated" + (string.IsNullOrEmpty(error) ? "" : ": " + error) + ". The invoice remains Purchase Pending; you can try Create Purchase again.";
                return result;
            }
            result.purchaseId = pmId;
            result.ok = true;
            result.message = "Purchase #" + pmId + " is linked to invoice #" + smId + ".";
        }
        catch (StockException ex)
        {
            result.message = ex.Message;
        }
        catch (HttpException)
        {
            throw;
        }
        catch (Exception ex)
        {
            new LogClass("salesorderinterstockerror").write(ex);
            result.message = "The purchase entry could not be generated. The invoice remains Purchase Pending; you can try Create Purchase again.";
        }
        finally
        {
            if (con != null)
            {
                if (locked)
                    ReleaseLock(con, smoId);
                con.Dispose();
            }
            Close(db);
        }
        return result;
    }

    // The transfers of an order are the invoices that carry both sm_refid = smo_id and sm_is_inter_stock_transfer_invoice = 1 (ordinary invoices of the
    // order have the flag 0). The purchase is picked by a scalar subquery, so every invoice appears exactly once.
    static List<InterStockTransferRow> ReadTransferRows(mySqlConnection db, int smoId, int smId)
    {
        var rows = new List<InterStockTransferRow>();
        foreach (DataRow r in db.SelectQuery("select sm.sm_id,sm.sm_invoice_no,DATE_FORMAT(sm.sm_date,'%d-%b-%Y %H:%i') as d,sm.sm_netamount,tb.branch_name as src,tc.cust_name,tt.branch_name as target_wh,"
            + "(select count(*) from tbl_sales_items si where si.sm_id=sm.sm_id) as item_count,"
            + "(select ifnull(sum(si.si_qty+ifnull(si.si_foc,0)),0) from tbl_sales_items si where si.sm_id=sm.sm_id) as qty,"
            + "pm.pm_id,pm.pm_status,pm.pm_netamount,tv.vn_name,pb.branch_name as pur_wh "
            + "from (select s.*,"
            + "(select ifnull(min(p.pm_id),0) from tbl_purchase_master p where p.sm_id=s.sm_id or (p.pm_ref_no=s.sm_id "
            + "and p.vn_id=(select x.vn_id from tbl_branch x where x.branch_id=s.branch_id) and p.branch_id=(select min(y.branch_id) from tbl_branch y where y.cust_id=s.cust_id))) as pm_pick,"
            + "(select min(y.branch_id) from tbl_branch y where y.cust_id=s.cust_id) as target_branch "
            + "from tbl_sales_master s where s.sm_refid=@o and s.sm_is_inter_stock_transfer_invoice=1" + (smId > 0 ? " and s.sm_id=@s" : "") + ") sm "
            + "inner join tbl_customer tc on tc.cust_id=sm.cust_id left join tbl_branch tb on tb.branch_id=sm.branch_id left join tbl_branch tt on tt.branch_id=sm.target_branch "
            + "left join tbl_purchase_master pm on pm.pm_id=sm.pm_pick left join tbl_vendor tv on tv.vn_id=pm.vn_id left join tbl_branch pb on pb.branch_id=pm.branch_id "
            + "order by sm.sm_id desc",
            new MySqlParameter[] { new MySqlParameter("@o", smoId), new MySqlParameter("@s", smId) }).Rows)
        {
            int pmId = I(r["pm_id"]);
            rows.Add(new InterStockTransferRow
            {
                salesId = I(r["sm_id"]), invoiceNo = S(r["sm_invoice_no"]), date = S(r["d"]), source = S(r["src"]),                 targetWarehouse = S(r["target_wh"]),
                customer = S(r["cust_name"]), amount = D(r["sm_netamount"]), itemCount = I(r["item_count"]), totalQty = D(r["qty"]),
                purchaseId = pmId, purchaseStatus = pmId <= 0 ? "pending" : (I(r["pm_status"]) == (int)Constants.PurchaseStatus.Cancel ? "cancelled" : "completed"),
                vendor = S(r["vn_name"]), purchaseWarehouse = S(r["pur_wh"]), purchaseAmount = D(r["pm_netamount"])
            });
        }
        return rows;
    }

    // Transfers of the order, newest first; purchaseStatus "pending" marks a transfer whose purchase is still missing.
    public static List<InterStockTransferRow> LoadInterStockTransfers(int smoId)
    {
        int staffId;
        string staffType;
        RequireInvoiceStaff(out staffId, out staffType);
        var rows = new List<InterStockTransferRow>();
        var db = new mySqlConnection();
        try
        {
            var ps = new List<MySqlParameter> { new MySqlParameter("@id", smoId) };
            string scope = OrderScope(staffId, staffType, ps);
            if (db.SelectQuery("select smo.smo_id from tbl_sales_master_order smo where smo.smo_id=@id" + scope, ps.ToArray()).Rows.Count == 0)
                return rows;
            rows = ReadTransferRows(db, smoId, 0);
        }
        finally { Close(db); }
        return rows;
    }

    static string UomOfStockSql(string stockColumn)
    {
        return "(select u.tum_name from tbl_itembranch_stock tis inner join tbl_item_master m on m.itm_id=tis.itm_id inner join tbl_item_uom u on u.tum_id=m.itsv_uom_purchase where tis.itbs_id=" + stockColumn + " limit 1)";
    }

    // The invoice and purchase lines of one transfer (batch, quantity and GST of both sides). Opening the existing invoice and purchase screens is left to the page.
    public static InterStockTransferDetail LoadInterStockTransferDetail(int smoId, int smId)
    {
        var result = new InterStockTransferDetail();
        int staffId;
        string staffType;
        RequireInvoiceStaff(out staffId, out staffType);
        var db = new mySqlConnection();
        try
        {
            var ps = new List<MySqlParameter> { new MySqlParameter("@id", smoId) };
            string scope = OrderScope(staffId, staffType, ps);
            if (db.SelectQuery("select smo.smo_id from tbl_sales_master_order smo where smo.smo_id=@id" + scope, ps.ToArray()).Rows.Count == 0)
                throw new StockException("Sales order not found.");
            List<InterStockTransferRow> rows = ReadTransferRows(db, smoId, smId);
            if (rows.Count == 0)
                throw new StockException("The transfer does not belong to this sales order.");
            result.header = rows[0];

            DataTable sm = db.SelectQuery("select sm_total,sm_discount_amount,sm_tax_amount,sm_netamount from tbl_sales_master where sm_id=@s", new MySqlParameter[] { new MySqlParameter("@s", smId) });
            if (sm.Rows.Count > 0)
                result.salesTotals = new InterStockDetailTotals { total = D(sm.Rows[0]["sm_total"]), discount = D(sm.Rows[0]["sm_discount_amount"]), tax = D(sm.Rows[0]["sm_tax_amount"]), net = D(sm.Rows[0]["sm_netamount"]) };
            foreach (DataRow r in db.SelectQuery("select si.itm_name,si.itm_code,b.itbh_no,si.si_qty+ifnull(si.si_foc,0) as qty,si.si_price,si.si_discount_rate,si.si_item_tax,si.si_item_cgst,si.si_item_sgst,si.si_item_igst,"
                + "si.si_tax_amount,si.si_net_amount," + UomOfStockSql("si.itbs_id") + " as uom from tbl_sales_items si left join tbl_item_batch b on b.itbh_id=si.itbh_id where si.sm_id=@s order by si.row_no,si.si_id",
                new MySqlParameter[] { new MySqlParameter("@s", smId) }).Rows)
                result.salesItems.Add(new InterStockDetailItem
                {
                    name = S(r["itm_name"]), code = S(r["itm_code"]), batchNo = S(r["itbh_no"]), uom = S(r["uom"]), qty = D(r["qty"]), price = D(r["si_price"]), discountRate = D(r["si_discount_rate"]),
                    taxPercent = D(r["si_item_tax"]), cgst = D(r["si_item_cgst"]), sgst = D(r["si_item_sgst"]), igst = D(r["si_item_igst"]), taxAmount = D(r["si_tax_amount"]), netAmount = D(r["si_net_amount"])
                });
            bool igst = result.salesItems.Any(x => x.igst > 0), gst = result.salesItems.Any(x => x.cgst > 0 || x.sgst > 0);
            result.gstType = igst ? "IGST (interstate)" : (gst ? "CGST + SGST" : "No GST");

            if (result.header.purchaseId > 0)
            {
                var pp = new MySqlParameter[] { new MySqlParameter("@p", result.header.purchaseId) };
                DataTable pm = db.SelectQuery("select pm_total,pm_discount_amount,pm_tax_amount,pm_netamount from tbl_purchase_master where pm_id=@p", pp);
                if (pm.Rows.Count > 0)
                    result.purchaseTotals = new InterStockDetailTotals { total = D(pm.Rows[0]["pm_total"]), discount = D(pm.Rows[0]["pm_discount_amount"]), tax = D(pm.Rows[0]["pm_tax_amount"]), net = D(pm.Rows[0]["pm_netamount"]) };
                foreach (DataRow r in db.SelectQuery("select pi.itm_name,pi.itm_code,b.itbh_no,pi.pi_qty,pi.pi_price,pi.pi_discount_rate,pi.pi_item_tax,pi.pi_item_cgst,pi.pi_item_sgst,pi.pi_item_igst,"
                    + "pi.pi_tax_amount,pi.pi_net_amount," + UomOfStockSql("pi.itbs_id") + " as uom from tbl_purchase_items pi left join tbl_item_batch b on b.itbh_id=pi.itbh_id where pi.pm_id=@p order by pi.row_no,pi.pi_id", pp).Rows)
                    result.purchaseItems.Add(new InterStockDetailItem
                    {
                        name = S(r["itm_name"]), code = S(r["itm_code"]), batchNo = S(r["itbh_no"]), uom = S(r["uom"]), qty = D(r["pi_qty"]), price = D(r["pi_price"]), discountRate = D(r["pi_discount_rate"]),
                        taxPercent = D(r["pi_item_tax"]), cgst = D(r["pi_item_cgst"]), sgst = D(r["pi_item_sgst"]), igst = D(r["pi_item_igst"]), taxAmount = D(r["pi_tax_amount"]), netAmount = D(r["pi_net_amount"])
                    });
            }
            result.ok = true;
        }
        catch (StockException ex) { result.message = ex.Message; }
        finally { Close(db); }
        return result;
    }
}
