using commonfunction;
using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;

public class ProductionUomTotal
{
    public string uom;
    public decimal required;
    public decimal produced;
    public decimal pending;
    public decimal reserved;
}

public class ProductionJobRow
{
    public int itpmId;
    public int sioId;
    public int sl;
    public string docNo;
    public string itemName;
    public string itemCode;
    public string uom;
    public decimal orderQty;
    public decimal produced;
    public decimal reserved;
    public decimal linePending;
    public int materialCount;
    public string materialSummary;
    public string batchNo;
    public string createdDate;
    public string status;
    public bool canUndo;
    public string undoMessage;
}

public class ProductionJobsResult
{
    public bool ok;
    public string message;
    public string orderRef;
    public bool canAct;
    public string entryDocNo;
    public bool entryExists;
    public string status;
    public int totalJobs;
    public List<ProductionUomTotal> totals = new List<ProductionUomTotal>();
    public List<ProductionLineRow> lines = new List<ProductionLineRow>();
    public List<ProductionJobRow> rows = new List<ProductionJobRow>();
}

// One manufactured order line: how much production the order needs, has had and still needs.
public class ProductionLineRow
{
    public int sioId;
    public int sl;
    public string itemName;
    public string itemCode;
    public string uom;
    public decimal orderQty;
    public decimal required;
    public decimal produced;
    public decimal reserved;
    public decimal pending;
    public string status;
    public string statusClass;
    public bool canProduce;
    public string produceMessage;
    public List<string> references = new List<string>();
}

// Data for the production entry modal.
public class ProductionEntryInput
{
    public int reservationId;
    public int batchId;
    public string batchNo;
    public string warehouse;
    public string itemName;
    public decimal reservedQty;
    public decimal reservedQtySales;
    public string uom;
    public decimal outputQty;
    public decimal outputBatchQty;
    public string issue;
}

public class ProductionEntryOptions
{
    public bool ok;
    public string message;
    public int sioId;
    public string orderRef;
    public string docNo;
    public string itemName;
    public string itemCode;
    public string uom;
    public decimal orderQty;
    public decimal finishedReserved;
    public decimal pending;
    public string componentName;
    public string componentCode;
    public string componentUom;
    public decimal perUnit;
    public decimal requiredRaw;
    public string blocker;
    public bool canSubmit;
    public List<ProductionEntryInput> inputs = new List<ProductionEntryInput>();
}

public class ProductionSaveResult
{
    public bool ok;
    public string message;
    public string docNo;
    public int itpmId;
    public string batchNo;
    public decimal outputQty;
    public string uom;
}

public class ProductionMaterial
{
    public string name;
    public string code;
    public string uom;
    public decimal quantity;
    public string batchNo;
    public int batchId;
}

public class ProductionEvent
{
    public string when;
    public string text;
    public string by;
}

public class ProductionJobDetail
{
    public bool ok;
    public string message;
    public int itpmId;
    public string docNo;
    public string orderRef;
    public string itemName;
    public string itemCode;
    public string uom;
    public string branch;
    public decimal orderQty;
    public decimal produced;
    public decimal reserved;
    public decimal unreserved;
    public string batchNo;
    public int batchId;
    public int itbsId;
    public string createdDate;
    public string createdBy;
    public string status;
    public string docDate;
    public string movementNote;
    public List<ProductionItemRecord> items = new List<ProductionItemRecord>();
    public List<ProductionMaterial> materials = new List<ProductionMaterial>();
    public List<ProductionEvent> events = new List<ProductionEvent>();
}

// Read-only production overview. The schema persists only tbl_item_pro_master / tbl_item_pro_items for production.
// A job is tied to a sales order line through its finished batch (itbh_created_doc_id = itpm_id and
// itbh_custbatchid = 'PRO-<itpm_id>-<sio_id>'), which both sp_save_production_entry and the Reserved Items tab write.
public static partial class SalesOrderStock
{
    const string JobStatusText = "Produced";

    sealed class JobRaw
    {
        public int ItpmId, SioId, BatchId, ItbsId, ItmId, LineTum, BranchId;
        public string DocNo, Created, CreatedBy, BatchNo, BatchCreated, BranchName;
        public decimal OutQty, BatchQty, FinalQty;
    }

    public static ProductionJobsResult LoadProduction(int smoId, int branchId, int status, string docBase, bool canAct)
    {
        var result = new ProductionJobsResult { orderRef = docBase, canAct = canAct, entryDocNo = docBase };
        var db = new mySqlConnection();
        try
        {
            Snapshot s = LoadSnapshot(db, smoId, branchId, 0, false);
            List<JobRaw> jobs = ReadJobs(db, smoId, branchId, 0);
            Dictionary<int, List<DataRow>> mats = ReadMaterials(db, jobs.Select(j => j.ItpmId));
            List<ResRow> res = ReadReservations(db, jobs.Select(j => j.BatchId));

            int sl = 1;
            var producedByLine = new Dictionary<int, decimal>();
            var refsByLine = new Dictionary<int, List<string>>();
            foreach (JobRaw j in jobs)
            {
                Line l = s.Lines.FirstOrDefault(x => x.SioId == j.SioId);
                if (l == null)
                    continue;
                Calc c = Compute(s, l);
                decimal? f = Conv(s, 1m, l.PurchaseTum > 0 ? l.PurchaseTum : l.SalesTum, l.SalesTum);
                string uom = UomName(s, l.SalesTum);
                bool convertible = f.HasValue && c.Error == null;

                decimal produced = convertible ? j.OutQty * f.Value : j.OutQty;
                decimal reserved = convertible ? res.Where(r => r.BatchId == j.BatchId && r.SioId == j.SioId).Sum(r => r.Qty) * f.Value : 0m;
                var row = new ProductionJobRow
                {
                    itpmId = j.ItpmId,
                    sioId = j.SioId,
                    sl = sl++,
                    docNo = j.DocNo,
                    itemName = l.Name,
                    itemCode = l.Code,
                    uom = convertible ? uom : "(UOM unverified)",
                    orderQty = convertible ? R4(c.Ordered) : 0m,
                    produced = R4(produced),
                    reserved = R4(reserved),
                    linePending = convertible ? R4(c.Needs) : 0m,
                    batchNo = j.BatchNo,
                    createdDate = j.Created,
                    status = JobStatusText
                };
                if (canAct && IsOpenStatus(status))
                {
                    if (j.BatchQty + Tolerance < j.OutQty)
                        row.undoMessage = "Part of the finished stock has already been invoiced or used.";
                    else if (res.Any(r => r.BatchId == j.BatchId && r.SioId != j.SioId))
                        row.undoMessage = "The finished stock is reserved for another order.";
                    else
                        row.canUndo = true;
                }

                List<DataRow> rawRows;
                mats.TryGetValue(j.ItpmId, out rawRows);
                rawRows = rawRows ?? new List<DataRow>();
                row.materialCount = rawRows.Count;
                row.materialSummary = rawRows.Count == 0
                    ? "No raw-material record"
                    : string.Join("; ", rawRows.Take(3).Select(r => S(r["itm_name"]) + " (batch " + S(r["itbh_no"]) + ")")) + (rawRows.Count > 3 ? "; +" + (rawRows.Count - 3) + " more" : "");
                result.rows.Add(row);

                if (convertible)
                {
                    decimal soFar;
                    producedByLine.TryGetValue(j.SioId, out soFar);
                    producedByLine[j.SioId] = soFar + produced;
                }
                List<string> refs;
                if (!refsByLine.TryGetValue(j.SioId, out refs))
                    refsByLine[j.SioId] = refs = new List<string>();
                refs.Add(j.DocNo);
            }

            var totals = new Dictionary<string, ProductionUomTotal>();
            int lineNo = 1;
            foreach (Line l in s.Lines)
            {
                Calc c = Compute(s, l);
                List<string> lineRefs;
                bool hasJobs = refsByLine.TryGetValue(l.SioId, out lineRefs);
                if (!c.HasBom && !hasJobs)
                    continue;
                decimal produced;
                producedByLine.TryGetValue(l.SioId, out produced);
                var lr = new ProductionLineRow { sioId = l.SioId, sl = lineNo++, itemName = l.Name, itemCode = l.Code, uom = c.UomName ?? "" };
                if (hasJobs)
                    lr.references = lineRefs;
                if (c.Error != null)
                {
                    lr.status = "Unavailable";
                    lr.statusClass = "label-default";
                    lr.produceMessage = c.Error;
                    result.lines.Add(lr);
                    continue;
                }
                lr.orderQty = R4(c.Ordered);
                lr.produced = R4(produced);
                lr.pending = R4(c.Needs);
                lr.required = R4(Math.Min(produced, c.Ordered) + c.Needs);
                lr.reserved = R4(c.This);
                if (produced > c.Ordered + Tolerance) { lr.status = "Over-produced"; lr.statusClass = "label-danger"; }
                else if (produced > 0 && c.Needs <= 0) { lr.status = "Produced"; lr.statusClass = "label-success"; }
                else if (produced > 0) { lr.status = "Partially produced"; lr.statusClass = "label-info"; }
                else if (c.Needs > 0) { lr.status = "Pending production"; lr.statusClass = "label-warning"; }
                else { lr.status = "No production required"; lr.statusClass = "label-default"; }

                if (c.Needs > 0)
                {
                    List<ProductionEntryInput> inputs;
                    ProductionPayloadContext ctx = ProductionService.LoadPayloadContext(smoId, l.SioId);
                    string issue = ctx.Ok ? EntryIssue(c, ctx, status, out inputs) : ctx.Message;
                    lr.canProduce = canAct && issue == null;
                    lr.produceMessage = issue;
                }
                result.lines.Add(lr);

                ProductionUomTotal t;
                if (!totals.TryGetValue(lr.uom, out t))
                    totals[lr.uom] = t = new ProductionUomTotal { uom = lr.uom };
                t.required += lr.required;
                t.produced += lr.produced;
                t.pending += lr.pending;
                t.reserved += lr.reserved;
            }
            result.totals.AddRange(totals.Values);
            result.totalJobs = result.rows.Count;
            bool anyPending = result.lines.Any(x => x.pending > 0), anyProduced = result.lines.Any(x => x.produced > 0);
            result.status = result.lines.Count == 0 ? "Not applicable"
                : result.lines.Any(x => x.status == "Over-produced") ? "Over-produced"
                : anyPending ? (anyProduced ? "Partially produced" : "Pending production")
                : anyProduced ? "Produced" : "No production required";
            result.entryExists = ProductionService.EntryExists(docBase);
            result.ok = true;
        }
        finally
        {
            Close(db);
        }
        return result;
    }

    public static ProductionJobDetail LoadProductionDetail(int smoId, int branchId, string orderRef, int itpmId)
    {
        var d = new ProductionJobDetail();
        var db = new mySqlConnection();
        try
        {
            JobRaw j = ReadJobs(db, smoId, branchId, itpmId).FirstOrDefault();
            if (j == null)
            {
                d.message = "This production job was not found for the sales order.";
                return d;
            }
            Snapshot s = LoadSnapshot(db, smoId, branchId, j.SioId, false);
            Line l = s.Lines.FirstOrDefault();
            if (l == null)
            {
                d.message = "The sales order item was not found.";
                return d;
            }
            Calc c = Compute(s, l);
            decimal? f = Conv(s, 1m, l.PurchaseTum > 0 ? l.PurchaseTum : l.SalesTum, l.SalesTum);
            if (!f.HasValue || c.Error != null)
            {
                d.message = "Quantities cannot be shown because the UOM conversion for this item is invalid.";
                return d;
            }

            List<ResRow> res = ReadReservations(db, new[] { j.BatchId });
            d.itpmId = j.ItpmId;
            d.docNo = j.DocNo;
            d.orderRef = orderRef;
            d.itemName = l.Name;
            d.itemCode = l.Code;
            d.uom = c.UomName;
            d.branch = j.BranchName;
            d.orderQty = R4(c.Ordered);
            d.produced = R4(j.OutQty * f.Value);
            d.reserved = R4(res.Where(r => r.SioId == j.SioId).Sum(r => r.Qty) * f.Value);
            d.unreserved = R4(Math.Max(0m, j.BatchQty - res.Sum(r => r.Qty)) * f.Value);
            d.batchNo = j.BatchNo;
            d.batchId = j.BatchId;
            d.itbsId = j.ItbsId;
            d.createdDate = j.Created;
            d.createdBy = j.CreatedBy;
            d.status = JobStatusText;

            List<DataRow> raw;
            ReadMaterials(db, new[] { j.ItpmId }).TryGetValue(j.ItpmId, out raw);
            var batchIds = new List<int> { j.BatchId };
            foreach (DataRow r in raw ?? new List<DataRow>())
            {
                int purchase = I(r["itsv_uom_purchase"]), sales = I(r["itsv_uom_sales"]);
                decimal? mf = Conv(s, 1m, purchase > 0 ? purchase : sales, sales);
                d.materials.Add(new ProductionMaterial
                {
                    name = S(r["itm_name"]),
                    code = S(r["itm_code"]),
                    uom = mf.HasValue ? UomName(s, sales) : "(UOM unverified)",
                    quantity = R4(D(r["itpi_quantity"]) * (mf ?? 1m)),
                    batchNo = S(r["itbh_no"]),
                    batchId = I(r["itbh_id"])
                });
                batchIds.Add(I(r["itbh_id"]));
            }

            d.events.Add(new ProductionEvent { when = j.Created, text = "Production job recorded (" + j.DocNo + ")", by = j.CreatedBy });
            var ps = new List<MySqlParameter> { new MySqlParameter("@j", j.ItpmId) };
            string inList = InList("b", batchIds.Distinct().OrderBy(x => x), ps);
            DataTable ledger = db.SelectQueryForTransaction("select date_format(t.date,'%Y-%m-%d %H:%i') as d,t.narration,"
                + "trim(concat_ws(' ',u.first_name,u.last_name)) as who from tbl_stock_transactions t left join tbl_user_details u on u.user_id=t.user_id "
                + "where t.action_type=12 and t.action_ref_id=@j and t.itbh_id in (" + inList + ") order by t.date,t.id", ps.ToArray());
            foreach (DataRow r in ledger.Rows)
                d.events.Add(new ProductionEvent { when = S(r["d"]), text = S(r["narration"]), by = S(r["who"]) });

            var rp = new List<MySqlParameter> { new MySqlParameter("@b", j.BatchId), new MySqlParameter("@s", j.SioId) };
            DataTable rsv = db.SelectQueryForTransaction("select date_format(r.itbrs_date,'%Y-%m-%d %H:%i') as d,r.itbsr_qty,"
                + "trim(concat_ws(' ',u.first_name,u.last_name)) as who from tbl_item_batchstock_reserve r left join tbl_user_details u on u.user_id=r.itbrs_by "
                + "where r.itbh_id=@b and r.sio_id=@s order by r.itbrs_date,r.itbsr_id", rp.ToArray());
            foreach (DataRow r in rsv.Rows)
                d.events.Add(new ProductionEvent { when = S(r["d"]).StartsWith("0000") ? "" : S(r["d"]), text = "Finished goods reserved for the sales order: " + Fmt(D(r["itbsr_qty"]) * f.Value) + " " + c.UomName, by = S(r["who"]) });
            DataTable its = db.SelectQueryForTransaction("select pi.itpi_id,pi.itpi_branch,pi.itpi_serial,pi.itbh_id,pi.itpi_inputoutput,pi.itpi_quantity,pi.itpi_cost,"
                + "b.itbh_no,b.itm_id,m.itm_code,m.itm_name from tbl_item_pro_items pi left join tbl_item_batch b on b.itbh_id=pi.itbh_id "
                + "left join tbl_item_master m on m.itm_id=b.itm_id where pi.itpm_id=@j order by pi.itpi_serial,pi.itpi_id",
                new MySqlParameter[] { new MySqlParameter("@j", j.ItpmId) });
            foreach (DataRow r in its.Rows)
                d.items.Add(new ProductionItemRecord
                {
                    ItpiId = I(r["itpi_id"]), BranchId = I(r["itpi_branch"]), ItpmId = j.ItpmId, Serial = I(r["itpi_serial"]), BatchId = I(r["itbh_id"]),
                    InputOutput = I(r["itpi_inputoutput"]), Quantity = D(r["itpi_quantity"]), Cost = D(r["itpi_cost"]),
                    BatchNo = S(r["itbh_no"]), ItemId = I(r["itm_id"]), ItemCode = S(r["itm_code"]), ItemName = S(r["itm_name"])
                });
            string docDate = db.SelectScalarForTransaction("select date_format(itpm_docdate,'%Y-%m-%d %H:%i') from tbl_item_pro_master where itpm_id=@j",
                new MySqlParameter[] { new MySqlParameter("@j", j.ItpmId) });
            d.docDate = S(docDate).StartsWith("0000") ? "" : S(docDate);
            if (ledger.Rows.Count == 0)
                d.movementNote = "No stock-ledger rows exist for this production: the raw-material and finished-stock movements were not recorded.";
            d.events = d.events.OrderBy(e => e.when, StringComparer.Ordinal).ToList();
            d.ok = true;
        }
        finally
        {
            Close(db);
        }
        return d;
    }

    // Why a production entry cannot be created for this line through sp_save_production_entry (null when it can).
    // The procedure takes one reservation row and one entry per sales order, so those limits are enforced here.
    static string EntryIssue(Calc c, ProductionPayloadContext ctx, int status, out List<ProductionEntryInput> inputs)
    {
        inputs = new List<ProductionEntryInput>();
        if (!IsOpenStatus(status))
            return status == SalesOrderStatus.Pending ? "This order is on hold (Pending). Resume it to enter production."
                : "Production cannot be entered for an order in this status.";
        if (c.Error != null)
            return c.Error;
        // Rules shared with "Produce" in the Reserved Items tab come from the same calculation so both show the same wording.
        if (!c.HasBom || c.Needs <= 0 || c.FinishedFirst != null || c.ProducedCap != null)
            return c.ProduceIssue;
        if (c.Comps.Count != 1)
            return "This screen can produce from one raw material only, but this BOM has " + c.Comps.Count + " components. Use Produce in the Reserved Items tab.";
        Comp cp = c.Comps[0];
        if (cp.Issue != null)
            return cp.Name + ": " + cp.Issue + ".";
        if (ctx.ProductionExists)
            return "This screen allows one production per sales order and " + ctx.DocNo + " already exists. Use Produce in the Reserved Items tab for the rest.";
        inputs = BuildInputs(c, cp, ctx);
        if (inputs.Count == 0)
            return "Reserve " + Fmt(cp.Required) + " " + cp.UomName + " of " + cp.Name + " for this order in the Reserved Items tab first.";
        if (!inputs.Any(x => x.issue == null))
            return "The reserved raw material cannot be used: " + inputs[0].issue;
        return null;
    }

    // Quantities follow the Reserved Items tab: reservation / batch quantities are in the item's purchase UOM, order quantities in the sales UOM.
    // The procedure consumes the whole reservation, so the output it can create is fixed by the reserved quantity and the BOM.
    static List<ProductionEntryInput> BuildInputs(Calc c, Comp cp, ProductionPayloadContext ctx)
    {
        var list = new List<ProductionEntryInput>();
        foreach (ProductionInputReservation r in ctx.Inputs)
        {
            if (!r.IsBomComponent || r.ItemId != cp.ItmId)
                continue;
            decimal qtySales = r.Quantity * cp.F;
            decimal implied = cp.PerUnit > 0 ? qtySales / cp.PerUnit : 0m;
            decimal outBatch = Round6(implied / c.F);
            var row = new ProductionEntryInput
            {
                reservationId = r.ReservationId,
                batchId = r.BatchId,
                batchNo = r.BatchNo,
                warehouse = r.Warehouse,
                itemName = r.ItemName,
                reservedQty = R4(r.Quantity),
                reservedQtySales = R4(qtySales),
                uom = cp.UomName,
                outputQty = R4(implied),
                outputBatchQty = outBatch
            };
            if (r.BatchBranchId != 0 && r.BatchBranchId != ctx.BranchId)
                row.issue = "Reserved in another warehouse; the production procedure requires the order's warehouse.";
            else if (implied <= 0)
                row.issue = "The BOM quantity for this component is not valid.";
            else if (implied - c.Needs > Tolerance)
                row.issue = "This reservation would produce " + Fmt(implied) + " " + c.UomName + ", more than the " + Fmt(c.Needs) + " " + c.UomName + " pending. Release the surplus in the Reserved Items tab.";
            else if (Math.Round(outBatch, 3) != outBatch)
                row.issue = "The resulting quantity cannot be stored: finished-stock reservations hold at most 3 decimals.";
            list.Add(row);
        }
        return list;
    }

    public static ProductionEntryOptions LoadProductionEntry(int smoId, int branchId, int status, string docBase, int sioId)
    {
        var o = new ProductionEntryOptions { sioId = sioId, orderRef = docBase, docNo = docBase };
        var db = new mySqlConnection();
        try
        {
            Snapshot s = LoadSnapshot(db, smoId, branchId, sioId, false);
            Line l = s.Lines.FirstOrDefault();
            if (l == null)
            {
                o.message = "The sales order item was not found.";
                return o;
            }
            Calc c = Compute(s, l);
            ProductionPayloadContext ctx = ProductionService.LoadPayloadContext(smoId, sioId);
            if (!ctx.Ok)
            {
                o.message = ctx.Message;
                return o;
            }
            o.docNo = ctx.DocNo;
            o.itemName = l.Name;
            o.itemCode = l.Code;
            if (c.Error == null)
            {
                o.uom = c.UomName;
                o.orderQty = R4(c.Ordered);
                o.finishedReserved = R4(c.This);
                o.pending = R4(c.Needs);
                if (c.Comps.Count > 0)
                {
                    Comp cp = c.Comps[0];
                    o.componentName = cp.Name;
                    o.componentCode = cp.Code;
                    o.componentUom = cp.UomName;
                    o.perUnit = R4(cp.PerUnit);
                    o.requiredRaw = R4(cp.Required);
                }
            }
            List<ProductionEntryInput> inputs;
            o.blocker = EntryIssue(c, ctx, status, out inputs);
            o.inputs = inputs;
            o.canSubmit = o.blocker == null;
            o.ok = true;
        }
        finally
        {
            Close(db);
        }
        return o;
    }

    // The production entry is created only by sp_save_production_entry (via ProductionService). Everything is re-validated here
    // against fresh data, because the procedure does not check the BOM, the finished-stock-first rule or the order's status.
    public static ProductionSaveResult SaveProduction(int smoId, int branchId, int status, int staffId, string docBase, int sioId, int reservationId, decimal expectedOutput)
    {
        var result = new ProductionSaveResult();
        var db = new mySqlConnection();
        try
        {
            // The procedure commits on its own connection, so the status is re-read here and checked again right before the call
            // (ProductionService.CheckOwnership) rather than trusting the status the page loaded with.
            status = SalesOrderStatus.Read(smoId);
            RequireOpen(status);
            Snapshot s = LoadSnapshot(db, smoId, branchId, sioId, false);
            Line l = RequireLine(s);
            Calc c = Compute(s, l);
            ProductionPayloadContext ctx = ProductionService.LoadPayloadContext(smoId, sioId);
            if (!ctx.Ok)
                throw new StockException(ctx.Message);
            List<ProductionEntryInput> inputs;
            string issue = EntryIssue(c, ctx, status, out inputs);
            if (issue != null)
                throw new StockException(issue);
            ProductionEntryInput input = inputs.FirstOrDefault(x => x.reservationId == reservationId);
            if (input == null)
                throw new StockException("The selected raw-material reservation is no longer available. The entry has been refreshed; please review and try again.");
            if (input.issue != null)
                throw new StockException(input.issue);
            if (Math.Abs(input.outputQty - R4(expectedOutput)) > Tolerance)
                throw new StockException("Stock changed since the page was loaded. The entry has been refreshed; please review and try again.");

            ProductionEntryResult r = ProductionService.SaveProductionEntry(new ProductionEntryRequest
            {
                SmoId = smoId,
                SioId = sioId,
                ReservationId = reservationId,
                OutputQty = input.outputBatchQty,
                UserId = staffId
            });
            result.ok = r.Success;
            if (!r.Success)
            {
                result.message = r.Message;
                return result;
            }
            result.docNo = r.DocNo;
            // The procedure saved a new finished-stock reservation on its own connection; record it on the order (no-op unless Approved).
            SalesOrderStatus.MarkProcessed(smoId, staffId);
            result.itpmId = r.ItpmId;
            result.outputQty = input.outputQty;
            result.uom = c.UomName;
            result.batchNo = S(db.SelectScalarForTransaction("select itbh_no from tbl_item_batch where itbh_id=@b",
                new MySqlParameter[] { new MySqlParameter("@b", r.OutputBatchId) }));
            result.message = "Produced " + Fmt(input.outputQty) + " " + c.UomName + " of " + l.Name + " (production #" + r.DocNo + ")"
                + (result.batchNo != "" ? ", batch " + result.batchNo + "," : "") + " and reserved it for this order.";
            string stockWarning = ApplyProductionStock(r.ItpmId, staffId, r.DocNo, smoId);
            if (stockWarning != null)
                result.message += " " + stockWarning;
        }
        catch (StockException ex)
        {
            result.message = ex.Message;
        }
        catch (Exception ex)
        {
            new LogClass("salesorderstockerror").write(ex);
            result.message = "The production entry could not be saved. No changes were made. Please try again.";
        }
        finally
        {
            Close(db);
        }
        return result;
    }

    // Reverses one production job: the finished batch is retired (quantity 0, inactive), its reservation is removed, the raw material is
    // returned to its batches (stock and ledger reversed when the job moved stock) and re-reserved for the order line, and the production
    // records are deleted. Refused once any finished stock has been invoiced or used, or reserved by another order.
    public static StockActionResult UndoProduction(int smoId, int branchId, int staffId, int itpmId)
    {
        return Run(delegate(mySqlConnection db, DateTime now)
        {
            RequireOpenLocked(db, smoId);
            JobRaw j = ReadJobs(db, smoId, branchId, itpmId).FirstOrDefault();
            if (j == null)
                throw new StockException("This production entry was not found for the sales order. It may already have been undone; please reload the page.");
            LockLine(db, smoId, j.SioId);
            var jp = new MySqlParameter[] { new MySqlParameter("@j", itpmId) };
            var bp = new MySqlParameter[] { new MySqlParameter("@b", j.BatchId) };

            DataTable pm = db.SelectQueryForTransaction("select itpm_id from tbl_item_pro_master where itpm_id=@j for update", jp);
            if (pm.Rows.Count == 0)
                throw new StockException("This production entry no longer exists. Please reload the page.");
            DataTable batch = db.SelectQueryForTransaction("select itbh_currentqty from tbl_item_batch where itbh_id=@b for update", bp);
            if (batch.Rows.Count == 0 || D(batch.Rows[0]["itbh_currentqty"]) + Tolerance < j.OutQty)
                throw new StockException("Part of the finished stock has already been invoiced or used, so this production cannot be undone.");
            foreach (DataRow r in db.SelectQueryForTransaction("select sio_id from tbl_item_batchstock_reserve where itbh_id=@b for update", bp).Rows)
                if (I(r["sio_id"]) != j.SioId)
                    throw new StockException("The finished stock is reserved for another order, so this production cannot be undone.");

            DataTable items = db.SelectQueryForTransaction("select pi.itpi_branch,pi.itbh_id,pi.itpi_inputoutput,pi.itpi_quantity,pi.itpi_cost,b.itbs_id "
                + "from tbl_item_pro_items pi inner join tbl_item_batch b on b.itbh_id=pi.itbh_id where pi.itpm_id=@j order by pi.itpi_serial,pi.itpi_id for update", jp);
            bool moved = db.SelectScalarForTransaction("select count(*) from tbl_stock_transactions where action_type=" + ProductionActionType + " and action_ref_id=@j", jp) != "0";
            string docNo = j.DocNo;

            int returned = 0;
            foreach (DataRow r in items.Rows)
            {
                int batchId = I(r["itbh_id"]), itbsId = I(r["itbs_id"]), rowBranch = I(r["itpi_branch"]);
                decimal qty = D(r["itpi_quantity"]), cost = D(r["itpi_cost"]);
                if (I(r["itpi_inputoutput"]) == 1)
                {
                    if (moved)
                    {
                        if (Exec(db, "update tbl_item_batch set itbh_currentqty=itbh_currentqty+@q where itbh_id=@b",
                            new MySqlParameter("@q", qty), new MySqlParameter("@b", batchId)) != 1)
                            throw new StockException("A raw-material batch of this production no longer exists, so it cannot be undone.");
                        AdjustBranchStock(db, itbsId, qty);
                        InsertLedger(db, now, staffId, itbsId, itpmId, rowBranch, batchId, 0m, qty, cost,
                            "Raw material returned: production #" + docNo + " undone (sales order #" + smoId + ")");
                    }
                    decimal reserve = Floor3(qty);
                    if (reserve > 0)
                        InsertReservation(db, batchId, reserve, j.SioId, now, staffId);
                    returned++;
                }
                else if (moved && batchId == j.BatchId)
                {
                    AdjustBranchStock(db, itbsId, -qty);
                    InsertLedger(db, now, staffId, itbsId, itpmId, rowBranch, batchId, qty, 0m, cost,
                        "Finished stock removed: production #" + docNo + " undone (sales order #" + smoId + ")");
                }
            }

            Exec(db, "delete from tbl_item_batchstock_reserve where itbh_id=@b and sio_id=@s", new MySqlParameter("@b", j.BatchId), new MySqlParameter("@s", j.SioId));
            if (Exec(db, "update tbl_item_batch set itbh_currentqty=0,itbh_status=0 where itbh_id=@b", new MySqlParameter("@b", j.BatchId)) != 1)
                throw new StockException("The finished batch could not be retired. No changes were made.");
            Exec(db, "delete from tbl_item_pro_items where itpm_id=@j", new MySqlParameter("@j", itpmId));
            if (Exec(db, "delete from tbl_item_pro_master where itpm_id=@j", new MySqlParameter("@j", itpmId)) != 1)
                throw new StockException("The production record could not be removed. No changes were made.");

            return "Production " + docNo + " was undone: " + Fmt(j.OutQty) + " of finished stock removed and " + returned
                + " raw-material allocation(s) returned and reserved for this order again.";
        });
    }

    // sp_save_production_entry commits on its own connection and changes no stock. The movements "Move to production" records are applied here
    // in one transaction: raw material batch and branch stock reduced, finished branch stock increased, one ledger row per batch.
    // Returns null on success (or when already applied), otherwise a warning for the user; the entry itself stays saved either way.
    static string ApplyProductionStock(int itpmId, int staffId, string docNo, int smoId)
    {
        var db = new mySqlConnection();
        bool started = false;
        try
        {
            DateTime now = Now(db);
            db.BeginTransaction();
            started = true;
            var jp = new MySqlParameter[] { new MySqlParameter("@j", itpmId) };
            db.SelectScalarForTransaction("select itpm_id from tbl_item_pro_master where itpm_id=@j for update", jp);
            if (db.SelectScalarForTransaction("select count(*) from tbl_stock_transactions where action_type=" + ProductionActionType + " and action_ref_id=@j", jp) != "0")
            {
                db.CommitTransaction();
                return null;
            }
            DataTable items = db.SelectQueryForTransaction("select pi.itpi_branch,pi.itbh_id,pi.itpi_inputoutput,pi.itpi_quantity,pi.itpi_cost,b.itbs_id "
                + "from tbl_item_pro_items pi inner join tbl_item_batch b on b.itbh_id=pi.itbh_id where pi.itpm_id=@j order by pi.itpi_serial,pi.itpi_id", jp);
            foreach (DataRow r in items.Rows)
            {
                int batchId = I(r["itbh_id"]), itbsId = I(r["itbs_id"]), branchId = I(r["itpi_branch"]);
                decimal qty = D(r["itpi_quantity"]), cost = D(r["itpi_cost"]);
                if (I(r["itpi_inputoutput"]) == 1)
                {
                    if (Exec(db, "update tbl_item_batch set itbh_currentqty=itbh_currentqty-@q where itbh_id=@b and itbh_currentqty>=@q",
                        new MySqlParameter("@q", qty), new MySqlParameter("@b", batchId)) != 1)
                        throw new StockException("Raw material stock changed during production.");
                    AdjustBranchStock(db, itbsId, -qty);
                    InsertLedger(db, now, staffId, itbsId, itpmId, branchId, batchId, qty, 0m, cost,
                        "Raw material consumed for production #" + docNo + " (sales order #" + smoId + ")");
                }
                else
                {
                    AdjustBranchStock(db, itbsId, qty);
                    InsertLedger(db, now, staffId, itbsId, itpmId, branchId, batchId, 0m, qty, cost,
                        "Produced for sales order #" + smoId + " (production #" + docNo + ")");
                }
            }
            db.CommitTransaction();
            return null;
        }
        catch (Exception ex)
        {
            Rollback(db, started);
            new LogClass("salesorderstockerror").write(ex);
            return "Warning: the production entry was saved, but the raw-material and finished-stock quantities could not be updated. Please contact the administrator (production #" + itpmId + ").";
        }
        finally
        {
            Close(db);
        }
    }

    static List<JobRaw> ReadJobs(mySqlConnection db, int smoId, int branchId, int onlyJob)
    {
        DataTable dt = db.SelectQueryForTransaction("select pm.itpm_id,pm.itpm_doc_no,date_format(pm.itpm_createddate,'%Y-%m-%d %H:%i') as created,"
            + "trim(concat_ws(' ',cu.first_name,cu.last_name)) as created_by,sio.sio_id,sio.itm_id,sio.itbs_id,sio.tum_id,sio.sio_finalqty,"
            + "b.itbh_id,b.itbh_no,b.itbh_currentqty,b.branch_id,tb.branch_name,pi.itpi_quantity "
            + "from tbl_sales_items_order sio "
            + "inner join tbl_item_batch b on b.itbh_custbatchid=concat('PRO-',b.itbh_created_doc_id,'-',sio.sio_id) and b.itbs_id=sio.itbs_id and b.branch_id=@br "
            + "inner join tbl_item_pro_master pm on pm.itpm_id=b.itbh_created_doc_id "
            + "inner join tbl_item_pro_items pi on pi.itpm_id=pm.itpm_id and pi.itbh_id=b.itbh_id and pi.itpi_inputoutput=2 "
            + "left join tbl_user_details cu on cu.user_id=pm.itpm_createdby left join tbl_branch tb on tb.branch_id=b.branch_id "
            + "where sio.smo_id=@o and (@j=0 or pm.itpm_id=@j) order by pm.itpm_id,sio.sio_id",
            new MySqlParameter[] { new MySqlParameter("@o", smoId), new MySqlParameter("@br", branchId), new MySqlParameter("@j", onlyJob) });
        var list = new List<JobRaw>();
        var seen = new HashSet<int>();
        foreach (DataRow r in dt.Rows)
        {
            int batchId = I(r["itbh_id"]);
            if (!seen.Add(batchId))
                continue;
            string created = S(r["created"]);
            list.Add(new JobRaw
            {
                ItpmId = I(r["itpm_id"]),
                DocNo = S(r["itpm_doc_no"]),
                Created = created.StartsWith("0000") ? "" : created,
                CreatedBy = S(r["created_by"]),
                SioId = I(r["sio_id"]),
                ItmId = I(r["itm_id"]),
                ItbsId = I(r["itbs_id"]),
                LineTum = I(r["tum_id"]),
                FinalQty = D(r["sio_finalqty"]),
                BatchId = batchId,
                BatchNo = S(r["itbh_no"]),
                BatchQty = D(r["itbh_currentqty"]),
                BranchId = I(r["branch_id"]),
                BranchName = S(r["branch_name"]),
                OutQty = D(r["itpi_quantity"])
            });
        }
        return list;
    }

    static Dictionary<int, List<DataRow>> ReadMaterials(mySqlConnection db, IEnumerable<int> jobIds)
    {
        var map = new Dictionary<int, List<DataRow>>();
        var ps = new List<MySqlParameter>();
        string inList = InList("j", jobIds.Distinct().OrderBy(x => x), ps);
        DataTable dt = db.SelectQueryForTransaction("select pi.itpm_id,pi.itpi_quantity,b.itbh_id,b.itbh_no,m.itm_code,m.itm_name,m.itsv_uom_purchase,m.itsv_uom_sales "
            + "from tbl_item_pro_items pi inner join tbl_item_batch b on b.itbh_id=pi.itbh_id left join tbl_item_master m on m.itm_id=b.itm_id "
            + "where pi.itpi_inputoutput=1 and pi.itpm_id in (" + inList + ") order by pi.itpm_id,pi.itpi_serial", ps.ToArray());
        foreach (DataRow r in dt.Rows)
        {
            List<DataRow> list;
            int id = I(r["itpm_id"]);
            if (!map.TryGetValue(id, out list))
                map[id] = list = new List<DataRow>();
            list.Add(r);
        }
        return map;
    }

    static List<ResRow> ReadReservations(mySqlConnection db, IEnumerable<int> batchIds)
    {
        var ps = new List<MySqlParameter>();
        string inList = InList("b", batchIds.Distinct().OrderBy(x => x), ps);
        DataTable dt = db.SelectQueryForTransaction("select r.itbh_id,r.sio_id,sum(r.itbsr_qty) as q from tbl_item_batchstock_reserve r "
            + "where r.itbh_id in (" + inList + ") group by r.itbh_id,r.sio_id", ps.ToArray());
        var list = new List<ResRow>();
        foreach (DataRow r in dt.Rows)
            list.Add(new ResRow { BatchId = I(r["itbh_id"]), SioId = I(r["sio_id"]), Qty = D(r["q"]) });
        return list;
    }
}
