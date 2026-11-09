using commonfunction;
using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;

public class ReservedBomComponent
{
    public string code;
    public string name;
    public string uom;
    public decimal perUnit;
    public decimal required;
    public decimal free;
    public bool enough;
    public string issue;
    public int itmId;
    public decimal reserved;
    public decimal remaining;
    public decimal available;
    public bool canReserve;
    public bool canUnreserve;
    public bool canPick;
    public decimal shortage;
    public decimal surplus;
    public List<ReservedAllocation> allocations = new List<ReservedAllocation>();
}

// One reservation row group (per batch) held for a sales order line or one of its BOM components, in the item's sales UOM.
public class ReservedAllocation
{
    public int batchId;
    public int branchId;
    public string warehouse;
    public string batchNo;
    public decimal qty;
    public string uom;
    public string status;
    public int priority;
}

public class BatchQty
{
    public int batchId;
    public decimal qty;
}

public class StockBatchOption
{
    public int batchId;
    public string batchNo;
    public string batchDate;
    public decimal physical;
    public decimal reserved;
    public decimal available;
    public decimal mine;
}

public class WarehouseOption
{
    public int branchId;
    public string name;
    public bool isHome;
    public decimal physical;
    public decimal reserved;
    public decimal available;
    public List<StockBatchOption> batches = new List<StockBatchOption>();
}

public class ReserveOptionsResult
{
    public bool ok;
    public string message;
    public bool isComponent;
    public string itemName;
    public string itemCode;
    public string parentName;
    public string uom;
    public decimal required;
    public decimal reservedThis;
    public decimal remaining;
    public List<WarehouseOption> warehouses = new List<WarehouseOption>();
}

public class ReservedItemRow
{
    public int sioId;
    public int itmId;
    public bool canPick;
    public string bomNote;
    public List<ReservedAllocation> allocations = new List<ReservedAllocation>();
    public int sl;
    public string itemName;
    public string itemCode;
    public string uom;
    public decimal ordered;
    public decimal delivered;
    public decimal required;
    public decimal physical;
    public decimal branchStock;
    public decimal reservedOthers;
    public decimal reservedThis;
    public decimal free;
    public decimal remaining;
    public decimal available;
    public decimal needsProduction;
    public bool hasBom;
    public List<ReservedBomComponent> bom = new List<ReservedBomComponent>();
    public bool canReserve;
    public bool canUnreserve;
    public bool canProduce;
    public string message;
    public string productionMessage;
}

public class ReservedItemsResult
{
    public bool ok;
    public string message;
    public bool canAct;
    public List<ReservedItemRow> rows = new List<ReservedItemRow>();
}

public class StockActionResult
{
    public bool ok;
    public string message;
}

// Reserve / unreserve / produce logic for a sales order. Accounting model (verified against the live schema):
//  - tbl_item_batch.itbh_currentqty is physical stock per batch, expressed in the item's purchase UOM.
//  - tbl_item_batchstock_reserve rows are allocations against that physical stock. Reserving never changes
//    itbh_currentqty or tbl_itembranch_stock.itbs_stock; free stock = itbh_currentqty - SUM(reserved).
//  - Production physically consumes raw-material batches and creates a finished batch (mirrors sp_save_production_entry).
public static partial class SalesOrderStock
{
    const decimal Tolerance = 0.001m;
    const int RawMaterialUomOthers = 7;
    const int ProductionActionType = 12;

    sealed class StockException : Exception
    {
        public StockException(string message) : base(message) { }
    }

    sealed class Uom { public int Id; public int TypeId; public decimal Fac; public string Name; }

    sealed class Batch
    {
        public int Id;
        public int ItbsId;
        public int BranchId;
        public string BranchName;
        public string No;
        public decimal Qty;
        public decimal Cost;
        public string Created;
        public decimal Reserved;
        public decimal Free { get { decimal f = Qty - Reserved; return f > 0 ? f : 0m; } }
    }

    sealed class ResRow { public int BatchId; public int ItbsId; public int SioId; public decimal Qty; }

    // Reservation held by one sales order line on one batch (any warehouse), in the batch's purchase UOM.
    sealed class OwnRes { public Batch B; public int ItmId; public int SioId; public decimal Qty; public int Priority; }

    // The item a reservation applies to: the order line itself, or one of its BOM components.
    sealed class Target
    {
        public int ItmId, ItbsId;
        public string Name, UomName;
        public decimal F, Remaining, Free;
        public bool IsComponent;
    }

    sealed class Line
    {
        public int SioId, ItmId, ItbsId, LineTum, SalesTum, PurchaseTum;
        public decimal FinalQty, Invoiced, ProducedBatch, BranchStock;
        public string Name, Code;
        public bool BomEnabled, StockRowOk;
    }

    sealed class BomRow
    {
        public int InputItm, BomTum, InputItbsId, InputSalesTum, InputPurchaseTum;
        public decimal Qty;
        public string Name, Code;
    }

    sealed class Comp
    {
        public int ItmId, ItbsId;
        public string Name, Code, UomName, Issue;
        public decimal PerUnit, Required, Free, F, Reserved;
        public bool Enough;
        public List<Batch> Batches = new List<Batch>();
    }

    sealed class Calc
    {
        public Line L;
        public string Error, ProduceIssue, FinishedFirst, ProducedCap;
        // Ordered is the full order line quantity; Required is what is still to be delivered (ordered less invoiced), both in the sales UOM.
        // Produced is everything already produced for the line.
        public decimal F, Ordered, Required, Produced, Physical, Other, This, Free, Remaining, Reservable, Needs;
        public bool HasBom;
        public List<Comp> Comps = new List<Comp>();
        public string UomName;
    }

    sealed class Snapshot
    {
        public Dictionary<int, Uom> Uoms = new Dictionary<int, Uom>();
        public List<Line> Lines = new List<Line>();
        public Dictionary<int, List<BomRow>> Bom = new Dictionary<int, List<BomRow>>();
        public Dictionary<int, List<Batch>> Batches = new Dictionary<int, List<Batch>>();
        public List<ResRow> Reservations = new List<ResRow>();
        public List<OwnRes> Own = new List<OwnRes>();

        public IEnumerable<OwnRes> OwnOnItem(int itmId, int sioId)
        {
            return Own.Where(r => r.ItmId == itmId && r.SioId == sioId);
        }

        public decimal OwnQty(int itmId, int sioId)
        {
            return OwnOnItem(itmId, sioId).Sum(r => r.Qty);
        }

        public List<Batch> BatchesOf(int itbsId)
        {
            List<Batch> list;
            return Batches.TryGetValue(itbsId, out list) ? list : new List<Batch>();
        }

        public decimal ReservedBy(int batchId, int sioId)
        {
            return Reservations.Where(r => r.BatchId == batchId && r.SioId == sioId).Sum(r => r.Qty);
        }
    }

    public static ReservedItemsResult Load(int smoId, int branchId, int status, bool canAct)
    {
        var result = new ReservedItemsResult();
        var db = new mySqlConnection();
        try
        {
            Snapshot s = LoadSnapshot(db, smoId, branchId, 0, false);
            bool open = canAct && IsOpenStatus(status);
            bool canRelease = canAct && IsReleaseStatus(status);
            int sl = 1;
            foreach (Line l in s.Lines)
                result.rows.Add(ToRow(s, l, sl++, open, canRelease, status));
            result.canAct = canAct;
            result.ok = true;
        }
        finally
        {
            Close(db);
        }
        return result;
    }

    // Default allocation: oldest batches first from the order's own warehouse. compItmId = 0 targets the order line itself,
    // otherwise one of its BOM components (raw material held for production).
    public static StockActionResult Reserve(int smoId, int branchId, int status, int staffId, int sioId, decimal expectedQty, int compItmId)
    {
        return Run(delegate(mySqlConnection db, DateTime now)
        {
            RequireOpenLocked(db, smoId);
            LockLine(db, smoId, sioId);
            Snapshot s = LoadSnapshot(db, smoId, branchId, sioId, true);
            Line l = RequireLine(s);
            Calc c = Compute(s, l);
            if (c.Error != null)
                throw new StockException(c.Error);
            Target t = ResolveTarget(c, compItmId);
            decimal reservable = Floor3(Math.Min(t.Remaining, t.Free));
            if (reservable <= 0)
                throw new StockException(Floor3(t.Remaining) <= 0
                    ? "This item is already fully reserved for the order."
                    : "No unreserved stock is available to reserve for this item.");
            if (Math.Abs(reservable - Floor3(expectedQty)) > Tolerance)
                throw new StockException("Stock changed since the page was loaded. The grid has been refreshed; please review and try again.");

            decimal needBatch = reservable / t.F;
            int batchCount = 0;
            foreach (Batch b in Fifo(s.BatchesOf(t.ItbsId)))
            {
                if (needBatch <= Tolerance)
                    break;
                decimal take = Floor3(Math.Min(b.Free, needBatch));
                if (take <= 0)
                    continue;
                InsertReservation(db, b.Id, take, sioId, now, staffId);
                needBatch -= take;
                batchCount++;
            }
            if (needBatch > Tolerance)
                throw new StockException("Unable to allocate the full quantity from the available batches.");

            SalesOrderStatus.MarkProcessedInTransaction(db, smoId, staffId);
            return "Reserved " + Fmt(reservable) + " " + t.UomName + " of " + t.Name + " from " + batchCount + " batch(es), oldest first.";
                    });
    }

    // Manual allocation: the user picks batches (in any warehouse they can access) and quantities, expressed in the item's sales UOM.
    // Everything is re-validated against locked batch rows inside the transaction; any failure rolls back all rows.
    public static StockActionResult ReserveBatches(int smoId, int branchId, int status, int staffId, int sioId, int compItmId, List<BatchQty> allocations)
    {
        return Run(delegate(mySqlConnection db, DateTime now)
        {
            RequireOpenLocked(db, smoId);
            var wanted = new SortedDictionary<int, decimal>();
            foreach (BatchQty a in allocations ?? new List<BatchQty>())
            {
                if (a == null || a.qty <= 0)
                    continue;
                if (a.batchId <= 0 || Floor3(a.qty) <= 0)
                    throw new StockException("Enter a valid quantity for each selected batch.");
                decimal prev;
                wanted[a.batchId] = (wanted.TryGetValue(a.batchId, out prev) ? prev : 0m) + a.qty;
            }
            if (wanted.Count == 0)
                throw new StockException("Enter a quantity to reserve against at least one batch.");

            LockLine(db, smoId, sioId);
            Snapshot s = LoadSnapshot(db, smoId, branchId, sioId, true);
            Line l = RequireLine(s);
            Calc c = Compute(s, l);
            if (c.Error != null)
                throw new StockException(c.Error);
            Target t = ResolveTarget(c, compItmId);

            decimal total = wanted.Values.Sum();
            if (total > t.Remaining + Tolerance)
                throw new StockException("The selected quantity (" + Fmt(total) + " " + t.UomName + ") exceeds the remaining requirement ("
                    + Fmt(Math.Max(0m, t.Remaining)) + " " + t.UomName + ") for " + t.Name + ".");

            var ps = new List<MySqlParameter>();
            string inList = InList("b", wanted.Keys, ps);
            DataTable locked = db.SelectQueryForTransaction("select b.itbh_id,b.itbs_id,b.itbh_no,b.itbh_currentqty,b.branch_id,ifnull(b.itbh_status,1) as st "
                + "from tbl_item_batch b where b.itbh_id in (" + inList + ") order by b.itbh_id for update", ps.ToArray());
            var ip = new List<MySqlParameter> { new MySqlParameter("@m", t.ItmId) };
            var ofItem = new HashSet<int>();
            foreach (DataRow r in db.SelectQueryForTransaction("select b.itbh_id from tbl_item_batch b inner join tbl_itembranch_stock tis on tis.itbs_id=b.itbs_id "
                + "where tis.itm_id=@m and b.itbh_id in (" + InList("k", wanted.Keys, ip) + ")", ip.ToArray()).Rows)
                ofItem.Add(I(r["itbh_id"]));
            var rp = new List<MySqlParameter>();
            DataTable reserved = db.SelectQueryForTransaction("select r.itbh_id,sum(r.itbsr_qty) as q from tbl_item_batchstock_reserve r "
                + "where r.itbh_id in (" + InList("r", wanted.Keys, rp) + ") group by r.itbh_id for update", rp.ToArray());
            var reservedBy = new Dictionary<int, decimal>();
            foreach (DataRow r in reserved.Rows)
                reservedBy[I(r["itbh_id"])] = D(r["q"]);
            var accessible = new HashSet<int>();
            foreach (DataRow r in db.SelectQueryForTransaction("select branch_id from tbl_user_branches where user_id=@u",
                new MySqlParameter[] { new MySqlParameter("@u", staffId) }).Rows)
                accessible.Add(I(r["branch_id"]));

            var plan = new List<KeyValuePair<int, decimal>>();
            foreach (DataRow r in locked.Rows)
            {
                int id = I(r["itbh_id"]);
                string no = S(r["itbh_no"]);
                if (!ofItem.Contains(id) || I(r["st"]) != 1)
                    throw new StockException("Batch " + no + " is not an active batch of " + t.Name + ".");
                if (!accessible.Contains(I(r["branch_id"])))
                    throw new StockException("You do not have access to the warehouse holding batch " + no + ".");
                decimal rs;
                decimal free = Math.Max(0m, D(r["itbh_currentqty"]) - (reservedBy.TryGetValue(id, out rs) ? rs : 0m));
                decimal asked = wanted[id];
                if (asked > free * t.F + Tolerance)
                    throw new StockException("Batch " + no + " has only " + Fmt(free * t.F) + " " + t.UomName + " available, but " + Fmt(asked) + " was requested.");
                decimal take = Math.Min(Floor3(asked / t.F), free);
                if (take <= 0)
                    throw new StockException("The quantity entered for batch " + no + " is too small to reserve.");
                plan.Add(new KeyValuePair<int, decimal>(id, take));
            }
            if (plan.Count != wanted.Count)
                throw new StockException("One or more selected batches no longer exist.");

            foreach (KeyValuePair<int, decimal> p in plan)
                InsertReservation(db, p.Key, p.Value, sioId, now, staffId);

            SalesOrderStatus.MarkProcessedInTransaction(db, smoId, staffId);
            return "Reserved " + Fmt(total) + " " + t.UomName + " of " + t.Name + " from " + plan.Count + " selected batch(es).";
        });
    }

    public static ReserveOptionsResult LoadOptions(int smoId, int branchId, int staffId, int sioId, int compItmId)
    {
        var result = new ReserveOptionsResult();
        var db = new mySqlConnection();
        try
        {
            Snapshot s = LoadSnapshot(db, smoId, branchId, sioId, false);
            Line l = s.Lines.FirstOrDefault();
            if (l == null)
            {
                result.message = "The sales order item was not found.";
                return result;
            }
            Calc c = Compute(s, l);
            Target t;
            try
            {
                if (c.Error != null)
                    throw new StockException(c.Error);
                t = ResolveTarget(c, compItmId);
            }
            catch (StockException ex)
            {
                result.message = ex.Message;
                return result;
            }

            result.isComponent = t.IsComponent;
            result.itemName = t.Name;
            result.parentName = l.Name;
            result.uom = t.UomName;
            result.itemCode = t.IsComponent ? c.Comps.First(x => x.ItmId == t.ItmId).Code : l.Code;
            result.reservedThis = R4(t.IsComponent ? c.Comps.First(x => x.ItmId == t.ItmId).Reserved : c.This);
            result.remaining = R4(Math.Max(0m, t.Remaining));
            result.required = R4(result.reservedThis + result.remaining);

            var byBranch = new Dictionary<int, WarehouseOption>();
            foreach (DataRow r in db.SelectQueryForTransaction("select distinct tis.branch_id,tb.branch_name from tbl_itembranch_stock tis "
                + "inner join tbl_branch tb on tb.branch_id=tis.branch_id where tis.itm_id=@m "
                + "and tis.branch_id in (select branch_id from tbl_user_branches where user_id=@u) order by tis.branch_id",
                new MySqlParameter[] { new MySqlParameter("@m", t.ItmId), new MySqlParameter("@u", staffId) }).Rows)
            {
                var w = new WarehouseOption { branchId = I(r["branch_id"]), name = S(r["branch_name"]), isHome = I(r["branch_id"]) == branchId };
                byBranch[w.branchId] = w;
                result.warehouses.Add(w);
            }

            DataTable batches = db.SelectQueryForTransaction("select b.itbh_id,b.branch_id,b.itbh_no,b.itbh_currentqty,"
                + "date_format(b.itbh_createddate,'%Y-%m-%d') as created,"
                + "ifnull((select sum(r.itbsr_qty) from tbl_item_batchstock_reserve r where r.itbh_id=b.itbh_id),0) as res,"
                + "ifnull((select sum(r.itbsr_qty) from tbl_item_batchstock_reserve r where r.itbh_id=b.itbh_id and r.sio_id=@s),0) as mine "
                + "from tbl_item_batch b inner join tbl_itembranch_stock tis on tis.itbs_id=b.itbs_id and tis.itm_id=@m "
                + "where ifnull(b.itbh_status,1)=1 and b.itbh_currentqty>0 "
                + "and b.branch_id in (select branch_id from tbl_user_branches where user_id=@u) "
                + "order by b.branch_id,(b.itbh_createddate is null),b.itbh_createddate,b.itbh_id",
                new MySqlParameter[] { new MySqlParameter("@m", t.ItmId), new MySqlParameter("@u", staffId), new MySqlParameter("@s", sioId) });
            foreach (DataRow r in batches.Rows)
            {
                WarehouseOption w;
                if (!byBranch.TryGetValue(I(r["branch_id"]), out w))
                    continue;
                string created = S(r["created"]);
                decimal physical = D(r["itbh_currentqty"]) * t.F, res = D(r["res"]) * t.F;
                var b = new StockBatchOption
                {
                    batchId = I(r["itbh_id"]),
                    batchNo = S(r["itbh_no"]),
                    batchDate = created == "" || created.StartsWith("0000") ? "" : created,
                    physical = R4(physical),
                    reserved = R4(res),
                    available = R4(Math.Max(0m, physical - res)),
                    mine = R4(D(r["mine"]) * t.F)
                };
                w.batches.Add(b);
                w.physical += b.physical;
                w.reserved += b.reserved;
                w.available += b.available;
            }
            foreach (WarehouseOption w in result.warehouses)
            {
                w.physical = R4(w.physical);
                w.reserved = R4(w.reserved);
                w.available = R4(w.available);
            }
            result.ok = true;
        }
        finally
        {
            Close(db);
        }
        return result;
    }

    // compItmId = 0 releases every reservation of the order line itself (all warehouses); otherwise the raw-material reservations of that BOM component.
    public static StockActionResult Unreserve(int smoId, int branchId, int status, int sioId, int compItmId)
    {
        return Run(delegate(mySqlConnection db, DateTime now)
        {
            if (!IsReleaseStatus(SalesOrderStatus.LockStatus(db, smoId)))
                throw new StockException("Reservations cannot be changed for an order in this status.");
            LockLine(db, smoId, sioId);
            string itm = db.SelectScalarForTransaction("select itm_id from tbl_sales_items_order where sio_id=@s and smo_id=@o",
                new MySqlParameter[] { new MySqlParameter("@s", sioId), new MySqlParameter("@o", smoId) });
            int itmId;
            if (!int.TryParse(itm, out itmId) || itmId <= 0)
                throw new StockException("The order item is not linked to an item master record.");
            int target = itmId;
            if (compItmId > 0)
            {
                string isBom = db.SelectScalarForTransaction("select count(*) from tbl_item_master_bom where itmbi_type=1 and itm_id_output=@o and itm_id_input=@i",
                    new MySqlParameter[] { new MySqlParameter("@o", itmId), new MySqlParameter("@i", compItmId) });
                if (compItmId == itmId || isBom == "0")
                    throw new StockException("The BOM component was not found for this item.");
                target = compItmId;
            }

            int released = ReleaseItemReservations(db, sioId, target);
            if (released <= 0)
                throw new StockException("There is no active reservation for this item.");
            return "Released " + released + " reservation allocation(s) for this " + (compItmId > 0 ? "component" : "item") + ". Physical stock was not changed.";
        });
    }

    public const int MaxPriority = 999;

    // Releases this order line's reservation on one batch (any warehouse); physical stock is never changed.
    public static StockActionResult UnreserveBatch(int smoId, int sioId, int batchId)
    {
        return Run(delegate(mySqlConnection db, DateTime now)
        {
            if (!IsReleaseStatus(SalesOrderStatus.LockStatus(db, smoId)))
                throw new StockException("Reservations cannot be changed for an order in this status.");
            LockLine(db, smoId, sioId);
            string batchNo = db.SelectScalarForTransaction("select itbh_no from tbl_item_batch where itbh_id=@b",
                new MySqlParameter[] { new MySqlParameter("@b", batchId) });
            if (Exec(db, "delete from tbl_item_batchstock_reserve where sio_id=@s and itbh_id=@b",
                new MySqlParameter("@s", sioId), new MySqlParameter("@b", batchId)) <= 0)
                throw new StockException("This reservation no longer exists. Please reload the page.");
            return "Released the reservation on batch " + batchNo + ". Physical stock was not changed.";
        });
    }

    // Higher priority reservations are consumed first (invoice, production); equal priority falls back to oldest batch first.
    // Applies to every reservation row the order line holds on that batch.
    public static StockActionResult SetPriority(int smoId, int sioId, int batchId, int priority)
    {
        return Run(delegate(mySqlConnection db, DateTime now)
        {
            if (priority < 0 || priority > MaxPriority)
                throw new StockException("Priority must be between 0 and " + MaxPriority + ".");
            if (!IsReleaseStatus(SalesOrderStatus.LockStatus(db, smoId)))
                throw new StockException("Reservations cannot be changed for an order in this status.");
            LockLine(db, smoId, sioId);
            string found = db.SelectScalarForTransaction("select count(*) from tbl_item_batchstock_reserve where sio_id=@s and itbh_id=@b",
                new MySqlParameter[] { new MySqlParameter("@s", sioId), new MySqlParameter("@b", batchId) });
            if (found == "0")
                throw new StockException("This reservation no longer exists. Please reload the page.");
            db.ExecuteQueryForTransaction("update tbl_item_batchstock_reserve set itbrs_priority=@p where sio_id=@s and itbh_id=@b",
                new MySqlParameter[] { new MySqlParameter("@p", priority), new MySqlParameter("@s", sioId), new MySqlParameter("@b", batchId) });
            return "Reservation priority set to " + priority + ".";
        });
    }

    static int ReleaseItemReservations(mySqlConnection db, int sioId, int itmId)
    {
        return Exec(db, "delete r from tbl_item_batchstock_reserve r inner join tbl_item_batch b on b.itbh_id=r.itbh_id "
            + "inner join tbl_itembranch_stock tis on tis.itbs_id=b.itbs_id where r.sio_id=@s and tis.itm_id=@m",
            new MySqlParameter("@s", sioId), new MySqlParameter("@m", itmId));
    }

    static Target ResolveTarget(Calc c, int compItmId)
    {
        if (compItmId <= 0)
            return new Target { ItmId = c.L.ItmId, ItbsId = c.L.ItbsId, Name = c.L.Name, UomName = c.UomName, F = c.F, Remaining = c.Remaining, Free = c.Free };
        if (!c.HasBom)
            throw new StockException("This item has no BOM components.");
        Comp cp = c.Comps.FirstOrDefault(x => x.ItmId == compItmId);
        if (cp == null)
            throw new StockException("The BOM component was not found for this item.");
        if (cp.Issue != null)
            throw new StockException(cp.Name + ": " + cp.Issue + ".");
        if (c.Needs <= 0)
            throw new StockException("No production is required for this item, so raw material cannot be reserved.");
        if (c.FinishedFirst != null)
            throw new StockException(c.FinishedFirst);
        return new Target { ItmId = cp.ItmId, ItbsId = cp.ItbsId, Name = cp.Name, UomName = cp.UomName, F = cp.F, Remaining = Math.Max(0m, cp.Required - cp.Reserved), Free = cp.Free, IsComponent = true };
    }

    public static StockActionResult MoveToProduction(int smoId, int branchId, int status, int staffId, string docBase, int sioId, decimal expectedQty)
    {
        return Run(delegate(mySqlConnection db, DateTime now)
        {
            RequireOpenLocked(db, smoId);
            LockLine(db, smoId, sioId);
            Snapshot s = LoadSnapshot(db, smoId, branchId, sioId, true);
            Line l = RequireLine(s);
            Calc c = Compute(s, l);
            if (c.Error != null)
                throw new StockException(c.Error);
            if (c.ProduceIssue != null)
                throw new StockException(c.ProduceIssue);
            if (Math.Abs(c.Needs - Ceil3(expectedQty)) > Tolerance)
                throw new StockException("Stock changed since the page was loaded. The grid has been refreshed; please review and try again.");

            decimal outQty = Round6(c.Needs / c.F);
            decimal reserveQty = Floor3(outQty);
            if (reserveQty <= 0)
                throw new StockException("The quantity to produce is too small.");

            string masterId = db.SelectScalarForTransaction("select itbm_id from tbl_item_batch_master_items where itm_id=@i order by itbmi_id desc limit 1",
                new MySqlParameter[] { new MySqlParameter("@i", l.ItmId) });
            int masterIdValue;
            if (int.TryParse(masterId, out masterIdValue))
                db.SelectScalarForTransaction("select itbm_id from tbl_item_batch_master where itbm_id=@m for update",
                    new MySqlParameter[] { new MySqlParameter("@m", masterIdValue) });

            string docNo = NextDocNo(db, docBase, sioId);
            string itpm = db.SelectScalarForTransaction("insert into tbl_item_pro_master (itpm_doc_no,itpm_docdate,itpm_createdby,itpm_createddate) "
                + "values (@d,@t,@u,@t);select last_insert_id();",
                new MySqlParameter[] { new MySqlParameter("@d", docNo), new MySqlParameter("@t", now), new MySqlParameter("@u", staffId) });
            int itpmId = int.Parse(itpm);

            int serial = 1;
            decimal totalCost = 0m;
            foreach (Comp cp in c.Comps)
            {
                decimal need = Ceil6(cp.Required / cp.F);
                decimal consumed = 0m;
                var used = new List<KeyValuePair<Batch, decimal>>();

                // Batches already reserved for this order line are consumed first (in any warehouse), then free stock from the order's warehouse, oldest first.
                var candidates = new List<KeyValuePair<Batch, decimal>>();
                foreach (OwnRes o in s.OwnOnItem(cp.ItmId, sioId).OrderByDescending(x => x.Priority).ThenBy(x => x.B.Created == null ? 1 : 0).ThenBy(x => x.B.Created, StringComparer.Ordinal).ThenBy(x => x.B.Id))
                    candidates.Add(new KeyValuePair<Batch, decimal>(o.B, Math.Min(o.Qty, o.B.Qty)));
                foreach (Batch b in Fifo(cp.Batches))
                    candidates.Add(new KeyValuePair<Batch, decimal>(b, b.Free));

                foreach (KeyValuePair<Batch, decimal> cand in candidates)
                {
                    Batch b = cand.Key;
                    if (need - consumed <= 0)
                        break;
                    decimal take = Math.Min(cand.Value, need - consumed);
                    if (take <= 0)
                        continue;
                    if (Exec(db, "update tbl_item_batch set itbh_currentqty=itbh_currentqty-@q where itbh_id=@b and itbh_currentqty>=@q",
                        new MySqlParameter("@q", take), new MySqlParameter("@b", b.Id)) != 1)
                        throw new StockException("Raw material stock changed during production. No changes were made.");
                    InsertProItem(db, b.BranchId, itpmId, serial++, b.Id, 1, take, b.Cost);
                    totalCost += take * b.Cost;
                    consumed += take;
                    used.Add(new KeyValuePair<Batch, decimal>(b, take));
                }
                if (need - consumed > 0)
                    throw new StockException("Insufficient raw material: " + cp.Name + ".");
                foreach (var byStock in used.GroupBy(u => u.Key.ItbsId))
                    AdjustBranchStock(db, byStock.Key, -byStock.Sum(u => u.Value));
                foreach (KeyValuePair<Batch, decimal> u in used)
                    InsertLedger(db, now, staffId, u.Key.ItbsId, itpmId, u.Key.BranchId, u.Key.Id, u.Value, 0m, u.Key.Cost,
                        "Raw material consumed for production #" + docNo + " (sales order #" + smoId + ")");
                // The raw material is now physically consumed, so this line's holds on the component are released to avoid double deduction.
                ReleaseItemReservations(db, sioId, cp.ItmId);
            }

            decimal unitCost = outQty > 0 ? totalCost / outQty : 0m;
            int newBatchId = CreateFinishedBatch(db, now, staffId, branchId, l, itpmId, outQty, unitCost, totalCost);
            InsertProItem(db, branchId, itpmId, serial, newBatchId, 2, outQty, unitCost);
            AdjustBranchStock(db, l.ItbsId, outQty);
            InsertLedger(db, now, staffId, l.ItbsId, itpmId, branchId, newBatchId, 0m, outQty, unitCost,
                "Produced for sales order #" + smoId + " (production #" + docNo + ")");
            InsertReservation(db, newBatchId, reserveQty, sioId, now, staffId);
            SalesOrderStatus.MarkProcessedInTransaction(db, smoId, staffId);

            return "Produced " + Fmt(c.Needs) + " " + c.UomName + " of " + l.Name + " (production #" + docNo + ") and reserved it for this order.";
                    });
    }

    static StockActionResult Run(Func<mySqlConnection, DateTime, string> work)
    {
        var result = new StockActionResult();
        var db = new mySqlConnection();
        bool started = false;
        try
        {
            DateTime now = Now(db);
            db.BeginTransaction();
            started = true;
            string message = work(db, now);
            db.CommitTransaction();
            started = false;
            result.ok = true;
            result.message = message;
        }
        catch (StockException ex)
        {
            Rollback(db, started);
            result.message = ex.Message;
        }
        catch (Exception ex)
        {
            Rollback(db, started);
            new LogClass("salesorderstockerror").write(ex);
            result.message = "The stock operation failed and no changes were saved. Please try again.";
        }
        finally
        {
            Close(db);
        }
        return result;
    }

    static void Rollback(mySqlConnection db, bool started)
    {
        if (!started)
            return;
        try { db.RollBackTransaction(); }
        catch (Exception ex) { new LogClass("salesorderstockerror").write(ex); }
    }

    static void Close(mySqlConnection db)
    {
        try { db.CloseConnection(); }
        catch (Exception) { }
    }

    static DateTime Now(mySqlConnection db)
    {
        string tz = db.SelectScalar("SELECT ss_default_time_zone FROM tbl_system_settings");
        if (!string.IsNullOrEmpty(tz))
        {
            try { return TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById(tz)); }
            catch (TimeZoneNotFoundException) { }
        }
        return DateTime.UtcNow;
    }

    static bool IsOpenStatus(int status) { return SalesOrderStatus.CanReserve(status); }
    static bool IsReleaseStatus(int status) { return SalesOrderStatus.CanRelease(status); }

    static void RequireOpen(int status)
    {
        if (IsOpenStatus(status))
            return;
        if (status == SalesOrderStatus.Pending)
            throw new StockException("This order is on hold (Pending). Resume it to reserve or produce stock.");
        if (status == SalesOrderStatus.New)
            throw new StockException("This order has not been approved yet. Approve it to reserve or produce stock.");
        if (SalesOrderStatus.IsCancelled(status))
            throw new StockException("This order is cancelled. Stock cannot be reserved or produced.");
        throw new StockException("Stock cannot be reserved or produced for an order in this status.");
    }

    // Locks the sales order row and validates its current status inside the transaction, so a concurrent hold, cancel or
    // approval cannot slip in between the check and the reservation. The status passed in by the page may be stale.
    static void RequireOpenLocked(mySqlConnection db, int smoId)
    {
        RequireOpen(SalesOrderStatus.LockStatus(db, smoId));
    }

    static Line RequireLine(Snapshot s)
    {
        Line l = s.Lines.FirstOrDefault();
        if (l == null)
            throw new StockException("The sales order item was not found.");
        return l;
    }

    static void LockLine(mySqlConnection db, int smoId, int sioId)
    {
        DataTable dt = db.SelectQueryForTransaction("select sio_id from tbl_sales_items_order where sio_id=@s and smo_id=@o for update",
            new MySqlParameter[] { new MySqlParameter("@s", sioId), new MySqlParameter("@o", smoId) });
        if (dt.Rows.Count == 0)
            throw new StockException("The sales order item was not found.");
    }

    static int Exec(mySqlConnection db, string sql, params MySqlParameter[] ps)
    {
        db.ExecuteQueryForTransaction(sql, ps);
        return Convert.ToInt32(db.SelectScalarForTransaction("select row_count()"));
    }

    static string InList(string prefix, IEnumerable<int> ids, List<MySqlParameter> ps)
    {
        var names = new List<string>();
        int i = 0;
        foreach (int id in ids)
        {
            string n = "@" + prefix + i++;
            ps.Add(new MySqlParameter(n, id));
            names.Add(n);
        }
        return names.Count == 0 ? "null" : string.Join(",", names);
    }

    static int I(object o) { return o == null || o == DBNull.Value ? 0 : Convert.ToInt32(o); }
    static decimal D(object o) { return o == null || o == DBNull.Value ? 0m : Convert.ToDecimal(o); }
    static string S(object o) { return o == null || o == DBNull.Value ? "" : Convert.ToString(o); }

    static decimal Floor3(decimal d) { return Math.Floor(d * 1000m) / 1000m; }
    static decimal Ceil3(decimal d) { return Math.Ceiling(d * 1000m) / 1000m; }
    static decimal Round6(decimal d) { return Math.Round(d, 6, MidpointRounding.AwayFromZero); }
    static decimal Ceil6(decimal d) { return Math.Ceiling(d * 1000000m) / 1000000m; }
    static decimal R4(decimal d) { return Math.Round(d, 4, MidpointRounding.AwayFromZero); }
    static string Fmt(decimal d) { return R4(d).ToString("0.####"); }

    static IEnumerable<Batch> Fifo(IEnumerable<Batch> batches)
    {
        return batches.OrderBy(b => b.Created == null ? 1 : 0).ThenBy(b => b.Created, StringComparer.Ordinal).ThenBy(b => b.Id).ToList();
    }

    static Snapshot LoadSnapshot(mySqlConnection db, int smoId, int branchId, int onlySio, bool lockBatches)
    {
        var s = new Snapshot();

        foreach (DataRow r in db.SelectQueryForTransaction("select tum_id,tum_type_id,tum_convertion_fac,tum_name from tbl_item_uom").Rows)
            s.Uoms[I(r["tum_id"])] = new Uom { Id = I(r["tum_id"]), TypeId = I(r["tum_type_id"]), Fac = D(r["tum_convertion_fac"]), Name = S(r["tum_name"]) };

        DataTable lines = db.SelectQueryForTransaction("select sio.sio_id,sio.itm_id,sio.itbs_id,sio.tum_id,sio.sio_finalqty,sio.itm_name as sio_name,"
            + "m.itm_code,m.itm_name,m.itsv_uom_purchase,m.itsv_uom_sales,m.itsv_bom_enabled,"
            + "ifnull((select sum(si.si_qty) from tbl_sales_items si inner join tbl_sales_master sm on sm.sm_id=si.sm_id "
            + "where si.sio_id=sio.sio_id and sm.sm_refid=sio.smo_id and sm.sm_is_inter_stock_transfer_invoice=0),0) as invoiced,"
            + "ifnull((select sum(pi.itpi_quantity) from tbl_item_pro_items pi inner join tbl_item_batch pb on pb.itbh_id=pi.itbh_id "
            + "where pi.itpi_inputoutput=2 and pb.itbh_custbatchid=concat('PRO-',pi.itpm_id,'-',sio.sio_id)),0) as produced,"
            + "tis.branch_id as tis_branch,tis.itm_id as tis_itm,tis.itbs_stock "
            + "from tbl_sales_items_order sio left join tbl_item_master m on m.itm_id=sio.itm_id "
            + "left join tbl_itembranch_stock tis on tis.itbs_id=sio.itbs_id "
            + "where sio.smo_id=@o and (@s=0 or sio.sio_id=@s) order by sio.row_no,sio.sio_id",
            new MySqlParameter[] { new MySqlParameter("@o", smoId), new MySqlParameter("@s", onlySio) });
        foreach (DataRow r in lines.Rows)
        {
            var l = new Line
            {
                SioId = I(r["sio_id"]),
                ItmId = I(r["itm_id"]),
                ItbsId = I(r["itbs_id"]),
                LineTum = I(r["tum_id"]),
                SalesTum = I(r["itsv_uom_sales"]),
                PurchaseTum = I(r["itsv_uom_purchase"]),
                FinalQty = D(r["sio_finalqty"]),
                Invoiced = D(r["invoiced"]),
                ProducedBatch = D(r["produced"]),
                BranchStock = D(r["itbs_stock"]),
                Name = S(r["itm_name"]) != "" ? S(r["itm_name"]) : S(r["sio_name"]),
                Code = S(r["itm_code"]),
                BomEnabled = I(r["itsv_bom_enabled"]) == 1
            };
            l.StockRowOk = l.ItbsId > 0 && I(r["tis_branch"]) == branchId && I(r["tis_itm"]) == l.ItmId;
            s.Lines.Add(l);
        }

        var itbsIds = new HashSet<int>(s.Lines.Where(x => x.StockRowOk).Select(x => x.ItbsId));
        IEnumerable<int> bomItems = s.Lines.Where(x => x.BomEnabled && x.StockRowOk).Select(x => x.ItmId).Distinct().ToList();
        if (bomItems.Any())
        {
            var ps = new List<MySqlParameter> { new MySqlParameter("@br", branchId) };
            string inList = InList("o", bomItems, ps);
            DataTable bom = db.SelectQueryForTransaction("select b.itm_id_output,b.itm_id_input,b.tum_id,b.itmbi_qty,m.itm_code,m.itm_name,"
                + "m.itsv_uom_purchase,m.itsv_uom_sales,tis.itbs_id "
                + "from tbl_item_master_bom b left join tbl_item_master m on m.itm_id=b.itm_id_input "
                + "left join tbl_itembranch_stock tis on tis.itm_id=b.itm_id_input and tis.branch_id=@br "
                + "where b.itmbi_type=1 and b.itm_id_output in (" + inList + ") order by b.itm_id_output,b.itmbi_serialno,b.itmbi_id", ps.ToArray());
            foreach (DataRow r in bom.Rows)
            {
                int output = I(r["itm_id_output"]);
                List<BomRow> list;
                if (!s.Bom.TryGetValue(output, out list))
                    s.Bom[output] = list = new List<BomRow>();
                var row = new BomRow
                {
                    InputItm = I(r["itm_id_input"]),
                    BomTum = I(r["tum_id"]),
                    Qty = D(r["itmbi_qty"]),
                    Name = S(r["itm_name"]),
                    Code = S(r["itm_code"]),
                    InputSalesTum = I(r["itsv_uom_sales"]),
                    InputPurchaseTum = I(r["itsv_uom_purchase"]),
                    InputItbsId = I(r["itbs_id"])
                };
                list.Add(row);
                if (row.InputItbsId > 0)
                    itbsIds.Add(row.InputItbsId);
            }
        }

        if (itbsIds.Count > 0)
        {
            var ps = new List<MySqlParameter> { new MySqlParameter("@br", branchId) };
            string inList = InList("i", itbsIds.OrderBy(x => x), ps);
            DataTable batches = db.SelectQueryForTransaction("select b.itbh_id,b.itbs_id,b.branch_id,b.itbh_no,b.itbh_currentqty,b.itbh_cost,"
                + "date_format(b.itbh_createddate,'%Y-%m-%d %H:%i:%s') as created "
                + "from tbl_item_batch b where b.itbs_id in (" + inList + ") and b.branch_id=@br and ifnull(b.itbh_status,1)=1 and b.itbh_currentqty>0 "
                + "order by b.itbh_id" + (lockBatches ? " for update" : ""), ps.ToArray());
            foreach (DataRow r in batches.Rows)
            {
                string created = S(r["created"]);
                var b = new Batch
                {
                    Id = I(r["itbh_id"]),
                    ItbsId = I(r["itbs_id"]),
                    BranchId = I(r["branch_id"]),
                    No = S(r["itbh_no"]),
                    Qty = D(r["itbh_currentqty"]),
                    Cost = D(r["itbh_cost"]),
                    Created = created == "" || created.StartsWith("0000") ? null : created
                };
                List<Batch> list;
                if (!s.Batches.TryGetValue(b.ItbsId, out list))
                    s.Batches[b.ItbsId] = list = new List<Batch>();
                list.Add(b);
            }

            var rp = new List<MySqlParameter>();
            string rIn = InList("r", itbsIds.OrderBy(x => x), rp);
            DataTable res = db.SelectQueryForTransaction("select r.itbh_id,b.itbs_id,r.sio_id,sum(r.itbsr_qty) as q "
                + "from tbl_item_batchstock_reserve r inner join tbl_item_batch b on b.itbh_id=r.itbh_id "
                + "where b.itbs_id in (" + rIn + ") group by r.itbh_id,b.itbs_id,r.sio_id" + (lockBatches ? " for update" : ""), rp.ToArray());
            foreach (DataRow r in res.Rows)
                s.Reservations.Add(new ResRow { BatchId = I(r["itbh_id"]), ItbsId = I(r["itbs_id"]), SioId = I(r["sio_id"]), Qty = D(r["q"]) });
            foreach (List<Batch> list in s.Batches.Values)
                foreach (Batch b in list)
                    b.Reserved = s.Reservations.Where(x => x.BatchId == b.Id).Sum(x => x.Qty);
        }

        // Reservations held by these order lines on any batch, in any warehouse (a line can be supplied from several warehouses).
        if (s.Lines.Count > 0)
        {
            var op = new List<MySqlParameter>();
            string sioIn = InList("w", s.Lines.Select(x => x.SioId).Distinct().ToList(), op);
            DataTable own = db.SelectQueryForTransaction("select x.itbh_id,x.sio_id,x.q,x.pr,b.itbs_id,b.branch_id,tb.branch_name,b.itbh_no,b.itbh_currentqty,b.itbh_cost,tis.itm_id,"
                + "date_format(b.itbh_createddate,'%Y-%m-%d %H:%i:%s') as created "
                + "from (select r.itbh_id,r.sio_id,sum(r.itbsr_qty) as q,max(r.itbrs_priority) as pr from tbl_item_batchstock_reserve r where r.sio_id in (" + sioIn + ") group by r.itbh_id,r.sio_id) x "
                + "inner join tbl_item_batch b on b.itbh_id=x.itbh_id inner join tbl_itembranch_stock tis on tis.itbs_id=b.itbs_id "
                + "left join tbl_branch tb on tb.branch_id=b.branch_id order by x.itbh_id", op.ToArray());
            var known = new Dictionary<int, Batch>();
            foreach (List<Batch> list in s.Batches.Values)
                foreach (Batch b in list)
                    known[b.Id] = b;
            foreach (DataRow r in own.Rows)
            {
                int batchId = I(r["itbh_id"]);
                Batch b;
                if (!known.TryGetValue(batchId, out b))
                {
                    string created = S(r["created"]);
                    b = new Batch
                    {
                        Id = batchId,
                        ItbsId = I(r["itbs_id"]),
                        BranchId = I(r["branch_id"]),
                        No = S(r["itbh_no"]),
                        Qty = D(r["itbh_currentqty"]),
                        Cost = D(r["itbh_cost"]),
                        Created = created == "" || created.StartsWith("0000") ? null : created
                    };
                    known[batchId] = b;
                }
                b.BranchName = S(r["branch_name"]);
                s.Own.Add(new OwnRes { B = b, ItmId = I(r["itm_id"]), SioId = I(r["sio_id"]), Qty = D(r["q"]), Priority = I(r["pr"]) });
            }

            // Lock the foreign-warehouse batches and read their current quantity, so production consumes up-to-date stock.
            var foreign = s.Own.Select(x => x.B).Where(x => !s.Batches.ContainsKey(x.ItbsId) || !s.Batches[x.ItbsId].Contains(x)).Distinct().ToList();
            if (lockBatches && foreign.Count > 0)
            {
                var lp = new List<MySqlParameter>();
                DataTable locked = db.SelectQueryForTransaction("select itbh_id,itbh_currentqty,itbh_cost from tbl_item_batch where itbh_id in ("
                    + InList("l", foreign.Select(x => x.Id).OrderBy(x => x).ToList(), lp) + ") order by itbh_id for update", lp.ToArray());
                foreach (DataRow r in locked.Rows)
                {
                    Batch b = foreign.First(x => x.Id == I(r["itbh_id"]));
                    b.Qty = D(r["itbh_currentqty"]);
                    b.Cost = D(r["itbh_cost"]);
                }
            }
        }
        return s;
    }

    // Conversion within one UOM type: qty x fromFactor / toFactor (same rule as web/js/uom-conversion.js).
    static decimal? Conv(Snapshot s, decimal qty, int from, int to)
    {
        if (from <= 0 || to <= 0)
            return null;
        if (from == to)
            return qty;
        Uom a, b;
        if (!s.Uoms.TryGetValue(from, out a) || !s.Uoms.TryGetValue(to, out b))
            return null;
        if (a.TypeId != b.TypeId || a.Fac <= 0 || b.Fac <= 0)
            return null;
        return qty * a.Fac / b.Fac;
    }

    static string UomName(Snapshot s, int id)
    {
        Uom u;
        return s.Uoms.TryGetValue(id, out u) ? u.Name : "";
    }

    static Calc Compute(Snapshot s, Line l)
    {
        var c = new Calc { L = l };
        if (!l.StockRowOk)
        {
            c.Error = "This item is not stocked in the order's warehouse.";
            return c;
        }
        if (l.SalesTum <= 0)
        {
            c.Error = "The sales UOM is not defined for this item.";
            return c;
        }
        c.UomName = UomName(s, l.SalesTum);
        decimal? f = Conv(s, 1m, l.PurchaseTum > 0 ? l.PurchaseTum : l.SalesTum, l.SalesTum);
        int lineUom = l.LineTum > 0 ? l.LineTum : l.SalesTum;
        decimal? ordered = Conv(s, l.FinalQty, lineUom, l.SalesTum);
        decimal? required = Conv(s, Math.Max(0m, l.FinalQty - l.Invoiced), lineUom, l.SalesTum);
        if (!f.HasValue || !ordered.HasValue || !required.HasValue)
        {
            c.Error = "Invalid UOM conversion between the order line and the item's sales UOM.";
            return c;
        }
        c.F = f.Value;
        c.Ordered = ordered.Value;
        // Invoiced stock has left the warehouse, so it is no longer required: otherwise invoicing a reservation would re-open the whole line.
        c.Required = required.Value;
        c.Produced = l.ProducedBatch * (f ?? 1m);

        foreach (Batch b in s.BatchesOf(l.ItbsId))
        {
            c.Physical += b.Qty * c.F;
            c.Free += b.Free * c.F;
            c.Other += (b.Reserved - s.ReservedBy(b.Id, l.SioId)) * c.F;
        }
        c.This = s.OwnQty(l.ItmId, l.SioId) * c.F;
        // Less than one reservable unit (0.001 of the batch UOM) cannot be reserved, so it is not a real requirement.
        c.Remaining = Math.Max(0m, c.Required - c.This);
        if (c.Remaining <= Tolerance * c.F)
            c.Remaining = 0m;
        c.Reservable = Floor3(Math.Min(c.Remaining, c.Free));
        c.Needs = Ceil3(Math.Max(0m, c.Remaining - c.Free));

        List<BomRow> rows;
        s.Bom.TryGetValue(l.ItmId, out rows);
        c.HasBom = l.BomEnabled && rows != null && rows.Count > 0;
        if (c.Needs > 0 && c.Reservable > 0)
            c.FinishedFirst = "Reserve the " + Fmt(c.Reservable) + " " + c.UomName + " of finished stock first; only the remaining "
                + Fmt(c.Needs) + " " + c.UomName + " needs production.";
        if (!c.HasBom)
        {
            c.ProduceIssue = "No BOM is defined for this item.";
            return c;
        }
        BuildComponents(s, c, rows);

        if (c.Needs <= 0)
        {
            c.ProduceIssue = "No production is required.";
            return c;
        }
        if (c.FinishedFirst != null)
        {
            c.ProduceIssue = c.FinishedFirst;
            return c;
        }
        if (c.Produced + c.Needs > c.Ordered + Tolerance)
        {
            c.ProducedCap = "Production would exceed the order quantity: " + Fmt(c.Produced) + " " + c.UomName + " has already been produced for this item and only "
                + Fmt(c.Ordered) + " " + c.UomName + " was ordered.";
            c.ProduceIssue = c.ProducedCap;
            return c;
        }
        var issues = new List<string>();
        foreach (Comp cp in c.Comps)
        {
            if (cp.Issue != null)
                issues.Add(cp.Name + ": " + cp.Issue);
            else if (!cp.Enough)
                issues.Add(cp.Name + " short by " + Fmt(cp.Required - cp.Free - cp.Reserved) + " " + cp.UomName);
        }
        if (issues.Count > 0)
            c.ProduceIssue = "Insufficient raw material - " + string.Join("; ", issues) + ".";
        return c;
    }

    static void BuildComponents(Snapshot s, Calc c, List<BomRow> rows)
    {
        var byItem = new Dictionary<int, Comp>();
        foreach (BomRow b in rows)
        {
            Comp cp;
            if (b.InputItm <= 0)
            {
                c.Comps.Add(new Comp { Name = "(missing component)", Code = "", UomName = "", Issue = "BOM component is not defined" });
                continue;
            }
            if (!byItem.TryGetValue(b.InputItm, out cp))
            {
                cp = new Comp { ItmId = b.InputItm, ItbsId = b.InputItbsId, Name = b.Name, Code = b.Code, UomName = UomName(s, b.InputSalesTum) };
                byItem[b.InputItm] = cp;
                c.Comps.Add(cp);
                decimal? f = Conv(s, 1m, b.InputPurchaseTum > 0 ? b.InputPurchaseTum : b.InputSalesTum, b.InputSalesTum);
                if (b.InputSalesTum <= 0 || !f.HasValue)
                    cp.Issue = "Invalid UOM conversion for the component";
                else
                    cp.F = f.Value;
                if (cp.Issue == null && b.InputItbsId <= 0)
                    cp.Issue = "Not stocked in this warehouse";
            }
            if (cp.Issue != null)
                continue;
            decimal? perUnit = b.BomTum > 0 && UomType(s, b.BomTum) != RawMaterialUomOthers
                ? Conv(s, b.Qty, b.BomTum, b.InputSalesTum)
                : (decimal?)b.Qty;
            if (!perUnit.HasValue)
                cp.Issue = "Invalid UOM conversion in the BOM";
            else
                cp.PerUnit += perUnit.Value;
        }
        foreach (Comp cp in c.Comps)
        {
            if (cp.Issue != null)
                continue;
            cp.Batches = s.BatchesOf(cp.ItbsId);
            cp.Free = cp.Batches.Sum(x => x.Free) * cp.F;
            cp.Reserved = s.OwnQty(cp.ItmId, c.L.SioId) * cp.F;
            cp.Required = cp.PerUnit * c.Needs;
            cp.Enough = Ceil6(cp.Required) <= cp.Free + cp.Reserved;
        }
    }

    static int UomType(Snapshot s, int id)
    {
        Uom u;
        return s.Uoms.TryGetValue(id, out u) ? u.TypeId : 0;
    }

    static ReservedItemRow ToRow(Snapshot s, Line l, int sl, bool open, bool canRelease, int status)
    {
        Calc c = Compute(s, l);
        var row = new ReservedItemRow
        {
            sioId = l.SioId,
            sl = sl,
            itemName = l.Name,
            itemCode = l.Code,
            uom = c.UomName ?? "",
            branchStock = R4(l.BranchStock)
        };
        if (c.Error != null)
        {
            decimal held = s.OwnQty(l.ItmId, l.SioId);
            row.itmId = l.ItmId;
            row.message = c.Error;
            row.canUnreserve = canRelease && held > 0;
            row.reservedThis = R4(held);
            return row;
        }
        row.itmId = l.ItmId;
        row.ordered = R4(c.Ordered);
        row.delivered = R4(Math.Max(0m, c.Ordered - c.Required));
        row.required = R4(c.Required);
        row.physical = R4(c.Physical);
        row.reservedOthers = R4(c.Other);
        row.reservedThis = R4(c.This);
        row.free = R4(c.Free);
        row.remaining = R4(c.Remaining);
        row.available = R4(c.Reservable);
        row.needsProduction = R4(c.Needs);
        row.hasBom = c.HasBom;
        row.allocations = Allocations(s, l.ItmId, l.SioId, c.F, c.UomName);
        foreach (Comp cp in c.Comps)
        {
            decimal compRemaining = Math.Max(0m, cp.Required - cp.Reserved);
            bool usable = cp.Issue == null && c.Needs > 0 && c.FinishedFirst == null;
            decimal compReservable = Floor3(Math.Min(compRemaining, cp.Free));
            var comp = new ReservedBomComponent
            {
                code = cp.Code, name = cp.Name, uom = cp.UomName, perUnit = R4(cp.PerUnit),
                required = R4(cp.Required), free = R4(cp.Free), enough = cp.Enough, issue = cp.Issue,
                itmId = cp.ItmId, reserved = R4(cp.Reserved), remaining = R4(compRemaining), available = R4(compReservable),
                shortage = cp.Issue == null ? R4(Math.Max(0m, cp.Required - cp.Reserved - cp.Free)) : 0m,
                surplus = cp.Issue == null && cp.Reserved - cp.Required > Tolerance ? R4(cp.Reserved - cp.Required) : 0m,
                canReserve = open && usable && compReservable > 0,
                canPick = open && usable && Floor3(compRemaining) > 0,
                canUnreserve = canRelease && cp.Issue == null && cp.Reserved > 0
            };
            if (cp.Issue == null)
                comp.allocations = Allocations(s, cp.ItmId, l.SioId, cp.F, cp.UomName);
            row.bom.Add(comp);
        }
        row.bomNote = c.Needs > 0 ? c.FinishedFirst : null;

        row.canReserve = open && c.Reservable > 0;
        row.canPick = open && Floor3(c.Remaining) > 0;
        row.canUnreserve = canRelease && c.This > 0;
        row.canProduce = open && c.ProduceIssue == null;
        if (!open && (c.Reservable > 0 || c.Needs > 0))
            row.message = status == SalesOrderStatus.Pending ? "Order is on hold (Pending). Resume it to reserve stock."
                : status == SalesOrderStatus.New ? "Approve the order to reserve stock."
                : SalesOrderStatus.IsCancelled(status) ? "Order is cancelled. Stock cannot be reserved."
                : "Stock actions are not available for an order in this status.";
        else if (c.Remaining > 0 && c.Free <= 0)
            row.message = "No unreserved stock available in the order's warehouse.";
        if (c.Needs > 0 && c.ProduceIssue != null)
            row.productionMessage = c.ProduceIssue;
        return row;
    }

    // Reservations are stored per batch in the batch UOM; they are shown in the item's sales UOM like the rest of the grid.
    static List<ReservedAllocation> Allocations(Snapshot s, int itmId, int sioId, decimal f, string uom)
    {
        return s.OwnOnItem(itmId, sioId)
            .OrderByDescending(o => o.Priority).ThenBy(o => o.B.BranchName, StringComparer.Ordinal).ThenBy(o => o.B.Created == null ? 1 : 0).ThenBy(o => o.B.Created, StringComparer.Ordinal).ThenBy(o => o.B.Id)
            .Select(o => new ReservedAllocation
            {
                batchId = o.B.Id, branchId = o.B.BranchId, warehouse = o.B.BranchName ?? "", batchNo = o.B.No,
                qty = R4(o.Qty * f), uom = uom, status = "Reserved", priority = o.Priority
            }).ToList();
    }

    static void InsertReservation(mySqlConnection db, int batchId, decimal qty, int sioId, DateTime now, int staffId)
    {
        db.ExecuteQueryForTransaction("insert into tbl_item_batchstock_reserve (itbh_id,itbsr_qty,sio_id,itbrs_date,itbrs_by,itbrs_priority) "
            + "values (@b,@q,@s,@d,@u,0)",
            new MySqlParameter[] { new MySqlParameter("@b", batchId), new MySqlParameter("@q", qty), new MySqlParameter("@s", sioId),
                new MySqlParameter("@d", now), new MySqlParameter("@u", staffId) });
    }

    static void InsertProItem(mySqlConnection db, int branchId, int itpmId, int serial, int batchId, int inputOutput, decimal qty, decimal cost)
    {
        db.ExecuteQueryForTransaction("insert into tbl_item_pro_items (itpi_branch,itpm_id,itpi_serial,itbh_id,itpi_inputoutput,itpi_quantity,itpi_cost) "
            + "values (@br,@m,@sr,@b,@io,@q,@c)",
            new MySqlParameter[] { new MySqlParameter("@br", branchId), new MySqlParameter("@m", itpmId), new MySqlParameter("@sr", serial),
                new MySqlParameter("@b", batchId), new MySqlParameter("@io", inputOutput), new MySqlParameter("@q", qty), new MySqlParameter("@c", cost) });
    }

    // Branch stock is an INT column, so fractional movements are rounded by the database.
    static void AdjustBranchStock(mySqlConnection db, int itbsId, decimal delta)
    {
        if (Exec(db, "update tbl_itembranch_stock set itbs_stock=coalesce(itbs_stock,0)+@d where itbs_id=@i",
            new MySqlParameter("@d", delta), new MySqlParameter("@i", itbsId)) < 0)
            throw new StockException("Unable to update branch stock.");
    }

    static void InsertLedger(mySqlConnection db, DateTime now, int staffId, int itbsId, int refId, int branchId, int batchId,
        decimal outQty, decimal inQty, decimal cost, string narration)
    {
        if (narration.Length > 150)
            narration = narration.Substring(0, 150);
        db.ExecuteQueryForTransaction("insert into tbl_stock_transactions (itbs_id,action_type,action_ref_id,user_id,narration,dr_qty,cr_qty,closing_stock,"
            + "date,is_reconciliation,Cost,itbh_id,branch_id) "
            + "values (@i,@a,@r,@u,@n,@dr,@cr,(select itbs_stock from tbl_itembranch_stock where itbs_id=@i),@t,0,@c,@b,@br)",
            new MySqlParameter[] { new MySqlParameter("@i", itbsId), new MySqlParameter("@a", ProductionActionType), new MySqlParameter("@r", refId),
                new MySqlParameter("@u", staffId), new MySqlParameter("@n", narration), new MySqlParameter("@dr", outQty), new MySqlParameter("@cr", inQty),
                new MySqlParameter("@t", now), new MySqlParameter("@c", cost), new MySqlParameter("@b", batchId), new MySqlParameter("@br", branchId) });
    }

    static string NextDocNo(mySqlConnection db, string docBase, int sioId)
    {
        string baseNo = (string.IsNullOrWhiteSpace(docBase) ? "SO" : docBase.Trim()) + "/L" + sioId;
        string docNo = baseNo;
        for (int n = 2; n < 100; n++)
        {
            if (db.SelectScalarForTransaction("select count(*) from tbl_item_pro_master where itpm_doc_no=@d",
                new MySqlParameter[] { new MySqlParameter("@d", docNo) }) == "0")
                return docNo;
            docNo = baseNo + "/" + n;
        }
        throw new StockException("Unable to allocate a production document number.");
    }

    // Same batch-numbering rule as sp_save_production_entry / sp_save_purchase_entry.
    static int CreateFinishedBatch(mySqlConnection db, DateTime now, int staffId, int branchId, Line l, int itpmId, decimal qty, decimal unitCost, decimal totalCost)
    {
        string prefix = "", suffix = "";
        decimal masterSerial = 0m;
        DataTable bm = db.SelectQueryForTransaction("select bm.itbm_prefix,bm.itbm_suffix,bm.itbm_serl from tbl_item_batch_master_items bi "
            + "inner join tbl_item_batch_master bm on bm.itbm_id=bi.itbm_id where bi.itm_id=@i order by bi.itbmi_id desc limit 1",
            new MySqlParameter[] { new MySqlParameter("@i", l.ItmId) });
        if (bm.Rows.Count > 0)
        {
            prefix = S(bm.Rows[0]["itbm_prefix"]);
            suffix = S(bm.Rows[0]["itbm_suffix"]);
            masterSerial = D(bm.Rows[0]["itbm_serl"]);
        }
        decimal maxSerial = D(db.SelectScalarForTransaction("select coalesce(max(cast(itbm_serl as unsigned)),0) from tbl_item_batch "
            + "where convert(itbm_prefix using utf8mb4) collate utf8mb4_general_ci = convert(@p using utf8mb4) collate utf8mb4_general_ci "
            + "and convert(itbm_suffix using utf8mb4) collate utf8mb4_general_ci = convert(@x using utf8mb4) collate utf8mb4_general_ci",
            new MySqlParameter[] { new MySqlParameter("@p", prefix), new MySqlParameter("@x", suffix) }));
        long serial = (long)(masterSerial > maxSerial ? masterSerial + 1 : maxSerial + 1);
        string batchNo = prefix + serial + suffix;
        if (db.SelectScalarForTransaction("select count(*) from tbl_item_batch where itbh_no=@n", new MySqlParameter[] { new MySqlParameter("@n", batchNo) }) != "0")
            throw new StockException("The generated batch number already exists. Please try again.");

        DataTable line = db.SelectQueryForTransaction("select tum_id,sio_length,sio_width from tbl_sales_items_order where sio_id=@s",
            new MySqlParameter[] { new MySqlParameter("@s", l.SioId) });
        object length = line.Rows[0]["sio_length"], width = line.Rows[0]["sio_width"];
        string id = db.SelectScalarForTransaction("insert into tbl_item_batch (itbh_custbatchid,itbm_prefix,itbm_suffix,itbm_serl,itbh_no,branch_id,itbs_id,itm_id,tum_id,"
            + "itbh_no_piece,itbh_length,itbh_width,itbh_startqty,itbh_currentqty,itbh_status,itbh_created_doc_type,itbh_cost,itbh_costotal,"
            + "itbh_created_doc_id,itbh_createddate,itbh_createduser) "
            + "values (@cb,@p,@x,@sr,@no,@br,@i,@m,@tum,@q,@len,@wid,@q,@q,1,2,@c,@ct,@doc,@t,@u);select last_insert_id();",
            new MySqlParameter[] {
                new MySqlParameter("@cb", "PRO-" + itpmId + "-" + l.SioId), new MySqlParameter("@p", prefix), new MySqlParameter("@x", suffix),
                new MySqlParameter("@sr", serial.ToString()), new MySqlParameter("@no", batchNo), new MySqlParameter("@br", branchId),
                new MySqlParameter("@i", l.ItbsId), new MySqlParameter("@m", l.ItmId), new MySqlParameter("@tum", l.SalesTum),
                new MySqlParameter("@q", qty), new MySqlParameter("@len", length), new MySqlParameter("@wid", width),
                new MySqlParameter("@c", unitCost), new MySqlParameter("@ct", totalCost), new MySqlParameter("@doc", itpmId),
                new MySqlParameter("@t", now), new MySqlParameter("@u", staffId) });
        return int.Parse(id);
    }
}
