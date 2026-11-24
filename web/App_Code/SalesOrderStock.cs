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
    // Calculation method name when the quantity is worked out from the batch weight/length instead of a fixed BOM quantity (empty otherwise).
    public string method;
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
    // True when this reservation can no longer be released by hand (raw material of a line that already has production).
    public bool locked;
    // Batch-calculated consumption only: this batch's own kg per metre, the raw material (kg) it needs per finished unit and how many finished units it can make.
    public decimal kgPerMetre;
    public decimal kgPerUnit;
    public decimal makes;
}

public class BatchQty
{
    public int batchId;
    public decimal qty;
}

// Production quantity the user chose for an order line (sales UOM).
public class PlanQty
{
    public int sioId;
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
    public bool canRelease = true;
    public string itemName;
    public string itemCode;
    public string parentName;
    public string uom;
    public decimal required;
    public decimal reservedThis;
    public decimal remaining;
    public List<WarehouseOption> warehouses = new List<WarehouseOption>();
}

// One BOM raw material as reserved in a single warehouse (sales UOM). supports is how many finished units that reservation alone can make.
public class WarehouseProductionMaterial
{
    public int itmId;
    public string name;
    public string code;
    public string uom;
    public decimal perUnit;
    public decimal reserved;
    public decimal supports;
    public string method;
    public List<ReservedAllocation> batches = new List<ReservedAllocation>();
}

// Raw material one production run would consume from one reserved batch, shown before the run is confirmed. Quantities are in the raw material's sales UOM.
public class ProductionPreviewBatch
{
    public int batchId;
    public string batchNo;
    public decimal qty;
    // Batch-calculated consumption only.
    public decimal kg;
    public decimal metres;
    public decimal kgPerMetre;
    public decimal kgPerUnit;
    public decimal finished;
}

public class ProductionPreviewMaterial
{
    public int itmId;
    public string name;
    public string code;
    public string uom;
    public string method;
    public decimal required;
    public decimal kg;
    public decimal metres;
    public List<ProductionPreviewBatch> batches = new List<ProductionPreviewBatch>();
}

public class ProductionPreview
{
    public bool ok;
    public string message;
    public string uom;
    public string warehouse;
    public decimal qty;
    public List<ProductionPreviewMaterial> materials = new List<ProductionPreviewMaterial>();
}

// Production position of one order line in one warehouse. Production always happens in the warehouse that holds the reserved raw material,
// consuming only that warehouse's reservations and adding the finished goods to that warehouse.
public class WarehouseProduction
{
    public int branchId;
    public string warehouse;
    public bool isHome;
    public decimal maxQty;
    public decimal suggestedQty;
    public decimal produced;
    public bool canProduce;
    public string message;
    public List<WarehouseProductionMaterial> materials = new List<WarehouseProductionMaterial>();
}

public class ReservedItemRow
{
    public decimal producedPct;
    public List<WarehouseProduction> warehouses = new List<WarehouseProduction>();
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
    public decimal produceQty;
    public decimal produced;
    public decimal planQty;
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
    // Sales order status after the operation (-1 when unknown), with its label and css class, so the page can update the status badges in place.
    public int status = -1;
    public string statusText = "";
    public string statusCss = "";
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

    // tbl_item_uom_type: the UOM category (Length, Area, ...) and its default UOM, the unit the batch-based calculation works in.
    sealed class UomCategory { public int Id; public string Name; public int DefaultUomId; }

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
        // Batch properties from tbl_item_batch used by the batch-based consumption calculation (zero = not recorded).
        public decimal Kg, Length, Pieces, StartQty;
        public decimal Free { get { decimal f = Qty - Reserved; return f > 0 ? f : 0m; } }

        public BatchProfile Profile()
        {
            return new BatchProfile { BatchId = Id, BatchNo = No, WeightKg = Kg, LengthPerUnit = Length, Pieces = Pieces, StartQty = StartQty };
        }
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
        public string Name, Code, WidthText;
        public bool BomEnabled, StockRowOk;
        // Finished quantity (batch UOM) already produced for this line, by the warehouse that produced it.
        public Dictionary<int, decimal> ProducedByBranch = new Dictionary<int, decimal>();
    }

    sealed class BomRow
    {
        public int InputItm, BomTum, InputItbsId, InputSalesTum, InputPurchaseTum;
        public decimal Qty;
        public string Name, Code, Method;
    }

    sealed class Comp
    {
        public int ItmId, ItbsId;
        public string Name, Code, UomName, Issue;
        public decimal PerUnit, Required, Free, F, Reserved;
        public bool Enough;
        // Dynamic (batch-calculated) component: Method is the BOM consumption method and Multiplier the summed BOM quantity (raw-material layers per unit).
        public string Method;
        public decimal Multiplier;
        public bool HasFixedLine;
        public bool Dynamic { get { return BomConsumption.IsDynamic(Method); } }
        public List<Batch> Batches = new List<Batch>();
    }

    sealed class Calc
    {
        public Line L;
        public string Error, ProduceIssue, FinishedFirst, ProducedCap;
        // Ordered is the full order line quantity; Required is what is still to be delivered (ordered less invoiced), both in the sales UOM.
        // Produced is everything already produced for the line.
        public decimal F, Ordered, Required, Produced, Physical, Other, This, Free, Remaining, Reservable, Needs;
        // Quantity a production run would make: the finished-stock shortfall, or the whole remaining quantity when finished stock already covers it.
        public decimal ProduceQty;
        public bool HasBom;
        public List<Comp> Comps = new List<Comp>();
        public string UomName;
    }

    sealed class Snapshot
    {
        public int BranchId;
        public Dictionary<int, string> BranchNames = new Dictionary<int, string>();
        public Dictionary<int, Uom> Uoms = new Dictionary<int, Uom>();
        public Dictionary<int, UomCategory> UomCategories = new Dictionary<int, UomCategory>();
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

    public static ReservedItemsResult Load(int smoId, int branchId, int status, bool canAct, Dictionary<int, decimal> plans)
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
            {
                decimal plan;
                if (plans == null || !plans.TryGetValue(l.SioId, out plan))
                    plan = 0m;
                result.rows.Add(ToRow(s, l, sl++, open, canRelease, status, plan));
            }
            result.canAct = canAct;
            result.ok = true;
        }
        finally
        {
            Close(db);
        }
        return result;
    }

    public static StockActionResult Reserve(int smoId, int branchId, int status, int staffId, int sioId, decimal expectedQty, int compItmId)
    {
        return Reserve(smoId, branchId, status, staffId, sioId, expectedQty, compItmId, 0m);
    }

    public static StockActionResult ReserveBatches(int smoId, int branchId, int status, int staffId, int sioId, int compItmId, List<BatchQty> allocations)
    {
        return ReserveBatches(smoId, branchId, status, staffId, sioId, compItmId, allocations, 0m);
    }

    public static ReserveOptionsResult LoadOptions(int smoId, int branchId, int staffId, int sioId, int compItmId)
    {
        return LoadOptions(smoId, branchId, staffId, sioId, compItmId, 0m);
    }

    // Default allocation: oldest batches first from the order's own warehouse. compItmId = 0 targets the order line itself,
    // otherwise one of its BOM components (raw material held for production). planQty is the production quantity the user chose (0 = default).
    public static StockActionResult Reserve(int smoId, int branchId, int status, int staffId, int sioId, decimal expectedQty, int compItmId, decimal planQty)
    {
        return Run(smoId, delegate(mySqlConnection db, DateTime now)
        {
            RequireOpenLocked(db, smoId);
            LockLine(db, smoId, sioId);
            Snapshot s = LoadSnapshot(db, smoId, branchId, sioId, true);
            Line l = RequireLine(s);
            Calc c = Compute(s, l, planQty);
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

            SalesOrderStatus.TryUpdateSalesOrderStatus(db, smoId, staffId);
            return "Reserved " + Fmt(reservable) + " " + t.UomName + " of " + t.Name + " from " + batchCount + " batch(es), oldest first.";
                    });
    }

    // Manual allocation: the user picks batches (in any warehouse they can access) and quantities, expressed in the item's sales UOM.
    // Everything is re-validated against locked batch rows inside the transaction; any failure rolls back all rows.
    public static StockActionResult ReserveBatches(int smoId, int branchId, int status, int staffId, int sioId, int compItmId, List<BatchQty> allocations, decimal planQty)
    {
        return Run(smoId, delegate(mySqlConnection db, DateTime now)
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
            Calc c = Compute(s, l, planQty);
            if (c.Error != null)
                throw new StockException(c.Error);
            Target t = ResolveTarget(c, compItmId);

            decimal total = wanted.Values.Sum();
            // Reserving more than the remaining requirement is allowed as long as every selected batch has enough free stock (validated below).
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

            SalesOrderStatus.TryUpdateSalesOrderStatus(db, smoId, staffId);
            return "Reserved " + Fmt(total) + " " + t.UomName + " of " + t.Name + " from " + plan.Count + " selected batch(es).";
        });
    }

    public static ReserveOptionsResult LoadOptions(int smoId, int branchId, int staffId, int sioId, int compItmId, decimal planQty)
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
            Calc c = Compute(s, l, planQty);
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
            result.canRelease = !(t.IsComponent && l.ProducedByBranch.Count > 0);
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
        return Run(smoId, delegate(mySqlConnection db, DateTime now)
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
                if (LineHasProduction(db, sioId))
                    throw new StockException(RawReleaseLocked);
                target = compItmId;
            }

            int released = ReleaseItemReservations(db, sioId, target);
            if (released <= 0)
                throw new StockException("There is no active reservation for this item.");
            SalesOrderStatus.TryUpdateSalesOrderStatus(db, smoId, 0);
            return "Released " + released + " reservation allocation(s) for this " + (compItmId > 0 ? "component" : "item") + ". Physical stock was not changed.";
        });
    }

    public const int MaxPriority = 999;

    const string RawReleaseLocked = "Raw material cannot be released once finished goods have been produced for this item. Undo the production first if it has to be released.";

    static bool LineHasProduction(mySqlConnection db, int sioId)
    {
        return db.SelectScalarForTransaction("select count(*) from tbl_item_pro_items pi inner join tbl_item_batch pb on pb.itbh_id=pi.itbh_id "
            + "where pi.itpi_inputoutput=2 and pb.itbh_custbatchid=concat('PRO-',pi.itpm_id,'-',@s)",
            new MySqlParameter[] { new MySqlParameter("@s", sioId) }) != "0";
    }

    // Releases this order line's reservation on one batch (any warehouse); physical stock is never changed.
    public static StockActionResult UnreserveBatch(int smoId, int sioId, int batchId)
    {
        return Run(smoId, delegate(mySqlConnection db, DateTime now)
        {
            if (!IsReleaseStatus(SalesOrderStatus.LockStatus(db, smoId)))
                throw new StockException("Reservations cannot be changed for an order in this status.");
            LockLine(db, smoId, sioId);
            string lineItem = db.SelectScalarForTransaction("select itm_id from tbl_sales_items_order where sio_id=@s", new MySqlParameter[] { new MySqlParameter("@s", sioId) });
            string batchItem = db.SelectScalarForTransaction("select tis.itm_id from tbl_item_batch b inner join tbl_itembranch_stock tis on tis.itbs_id=b.itbs_id where b.itbh_id=@b",
                new MySqlParameter[] { new MySqlParameter("@b", batchId) });
            if (batchItem != lineItem && LineHasProduction(db, sioId))
                throw new StockException(RawReleaseLocked);
            string batchNo = db.SelectScalarForTransaction("select itbh_no from tbl_item_batch where itbh_id=@b",
                new MySqlParameter[] { new MySqlParameter("@b", batchId) });
            if (Exec(db, "delete from tbl_item_batchstock_reserve where sio_id=@s and itbh_id=@b",
                new MySqlParameter("@s", sioId), new MySqlParameter("@b", batchId)) <= 0)
                throw new StockException("This reservation no longer exists. Please reload the page.");
            SalesOrderStatus.TryUpdateSalesOrderStatus(db, smoId, 0);
            return "Released the reservation on batch " + batchNo + ". Physical stock was not changed.";
        });
    }

    // Higher priority reservations are consumed first (invoice, production); equal priority falls back to oldest batch first.
    // Applies to every reservation row the order line holds on that batch.
    public static StockActionResult SetPriority(int smoId, int sioId, int batchId, int priority)
    {
        return Run(smoId, delegate(mySqlConnection db, DateTime now)
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
        if (c.ProduceQty <= 0)
            throw new StockException("No production is required for this item, so raw material cannot be reserved.");
        return new Target { ItmId = cp.ItmId, ItbsId = cp.ItbsId, Name = cp.Name, UomName = cp.UomName, F = cp.F, Remaining = Math.Max(0m, cp.Required - cp.Reserved), Free = cp.Free, IsComponent = true };
    }

    sealed class LockedReservation
    {
        public int ResId, BatchId, ItbsId, Priority;
        public decimal Qty, Cost;
        public string BatchNo;
        public BatchProfile Profile;
    }

    // What one raw-material batch gives up in a production run: take is in the batch's stock UOM; the rest describes the calculation (batch-calculated components only).
    sealed class Take
    {
        public LockedReservation Row;
        public decimal Qty;
        public ConsumptionFactor Factor;
        public decimal Finished, Kg, Metres;
    }

    sealed class ComponentPlan
    {
        public Comp C;
        public decimal Need;
        public List<LockedReservation> Rows;
        public List<Take> Takes = new List<Take>();
    }

    // The reservation rows an order line holds on one raw material in ONE warehouse, locked for the rest of the transaction.
    // Production is only ever allowed to consume rows returned here, which is what keeps it from touching another warehouse's stock.
    // The batch properties are read from tbl_item_batch together with the reservation, so every row carries its own batch's weight and length.
    static List<LockedReservation> LockWarehouseReservations(mySqlConnection db, int sioId, int itmId, int warehouseId, bool forUpdate)
    {
        var rows = new List<LockedReservation>();
        foreach (DataRow r in db.SelectQueryForTransaction("select r.itbsr_id,r.itbh_id,r.itbsr_qty,r.itbrs_priority,b.itbs_id,b.itbh_cost,b.itbh_no,"
            + "b.itbh_kg,b.itbh_length,b.itbh_no_piece,b.itbh_startqty "
            + "from tbl_item_batchstock_reserve r inner join tbl_item_batch b on b.itbh_id=r.itbh_id "
            + "inner join tbl_itembranch_stock tis on tis.itbs_id=b.itbs_id "
            + "where r.sio_id=@s and tis.itm_id=@m and tis.branch_id=@w and b.branch_id=@w and r.itbsr_qty>0 "
            + "order by r.itbrs_priority desc,(b.itbh_createddate is null),b.itbh_createddate,b.itbh_id,r.itbsr_id" + (forUpdate ? " for update" : ""),
            new MySqlParameter[] { new MySqlParameter("@s", sioId), new MySqlParameter("@m", itmId), new MySqlParameter("@w", warehouseId) }).Rows)
            rows.Add(new LockedReservation
            {
                ResId = I(r["itbsr_id"]), BatchId = I(r["itbh_id"]), ItbsId = I(r["itbs_id"]), Priority = I(r["itbrs_priority"]),
                Qty = D(r["itbsr_qty"]), Cost = D(r["itbh_cost"]), BatchNo = S(r["itbh_no"]),
                Profile = new BatchProfile
                {
                    BatchId = I(r["itbh_id"]), BatchNo = S(r["itbh_no"]), WeightKg = D(r["itbh_kg"]), LengthPerUnit = D(r["itbh_length"]),
                    Pieces = D(r["itbh_no_piece"]), StartQty = D(r["itbh_startqty"])
                }
            });
        return rows;
    }

    // Raw material (batch UOM) a component needs for qty finished units (sales UOM). Rounded up to the 3 decimals a reservation row can hold,
    // so the reservation that is left is exact and the batch quantity is reduced by exactly what the reservation gives up.
    static decimal ComponentNeed(Comp cp, decimal qty)
    {
        return Ceil3(cp.PerUnit * qty / cp.F);
    }

    // Finished quantity (sales UOM) already produced for the line in one warehouse.
    static decimal ProducedIn(Line l, decimal f, int warehouseId)
    {
        decimal q;
        return l.ProducedByBranch.TryGetValue(warehouseId, out q) ? q * f : 0m;
    }

    // Produces qty (sales UOM) of the order line in ONE warehouse. The raw material is taken only from the reservations the line holds in that
    // warehouse and the finished goods are created in (and reserved from) that same warehouse; every other warehouse is left untouched.
    // expectedProduced is the quantity already produced there as shown on the page, so a repeated or stale request cannot consume twice.
    public static StockActionResult ProduceInWarehouse(int smoId, int branchId, int status, int staffId, string docBase, int sioId, int warehouseId, decimal qty, decimal expectedProduced)
    {
        return Run(smoId, delegate(mySqlConnection db, DateTime now)
        {
            RequireOpenLocked(db, smoId);
            if (warehouseId <= 0)
                throw new StockException("Select the warehouse to produce in.");
            if (qty <= 0)
                throw new StockException("Enter a quantity to produce greater than zero.");
            if (Math.Round(qty, 3) != qty)
                throw new StockException("The quantity to produce can have at most 3 decimals.");
            LockLine(db, smoId, sioId);
            Snapshot s = LoadSnapshot(db, smoId, branchId, sioId, true);
            Line l = RequireLine(s);
            Calc c = Compute(s, l);
            if (c.Error != null)
                throw new StockException(c.Error);
            if (!c.HasBom)
                throw new StockException("No BOM is defined for this item.");
            if (Math.Abs(R6(ProducedIn(l, c.F, warehouseId)) - expectedProduced) > 0.0000005m)
                throw new StockException("Production in this warehouse changed since the page was loaded. The grid has been refreshed; please review and try again.");

            string warehouse = db.SelectScalarForTransaction("select branch_name from tbl_branch where branch_id=@w", new MySqlParameter[] { new MySqlParameter("@w", warehouseId) });
            if (warehouse == "")
                throw new StockException("The warehouse was not found.");
            if (warehouseId != branchId && db.SelectScalarForTransaction("select count(*) from tbl_user_branches where user_id=@u and branch_id=@w",
                new MySqlParameter[] { new MySqlParameter("@u", staffId), new MySqlParameter("@w", warehouseId) }) == "0")
                throw new StockException("You do not have access to the " + warehouse + " warehouse.");
            int finishedItbs;
            if (!int.TryParse(db.SelectScalarForTransaction("select itbs_id from tbl_itembranch_stock where itm_id=@m and branch_id=@w order by itbs_id limit 1",
                new MySqlParameter[] { new MySqlParameter("@m", l.ItmId), new MySqlParameter("@w", warehouseId) }), out finishedItbs) || finishedItbs <= 0)
                throw new StockException(l.Name + " is not stocked in the " + warehouse + " warehouse, so it cannot be produced there.");

            // Every BOM raw material must be reserved for this line in this warehouse, in the quantity qty needs; nothing is borrowed from elsewhere.
            // Batch-calculated materials are worked out here from the reserved batches themselves (their own weight and length).
            List<ComponentPlan> plans = BuildProductionPlans(db, s, l, c, sioId, warehouseId, warehouse, qty, true);
            decimal outQty = Round6(qty / c.F);
            if (Floor3(outQty) <= 0)
                throw new StockException("The quantity to produce is too small.");
            // Only what the order still needs is held for it; any extra production stays as free finished stock.
            decimal reserveQty = Floor3(Math.Min(outQty, c.Remaining / c.F));

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
            foreach (ComponentPlan plan in plans)
            {
                decimal left = plan.Need;
                var used = new List<Take>();
                foreach (Take t in plan.Takes)
                {
                    LockedReservation row = t.Row;
                    decimal take = t.Qty;
                    if (Exec(db, "update tbl_item_batch set itbh_currentqty=itbh_currentqty-@q where itbh_id=@b and itbh_currentqty>=@q",
                        new MySqlParameter("@q", take), new MySqlParameter("@b", row.BatchId)) != 1)
                        throw new StockException("Raw material stock changed during production. No changes were made.");
                    // The reservation is reduced by what is consumed (not released), so the rest stays reserved for later production.
                    int changed = row.Qty - take <= 0
                        ? Exec(db, "delete from tbl_item_batchstock_reserve where itbsr_id=@r and itbsr_qty=@q", new MySqlParameter("@r", row.ResId), new MySqlParameter("@q", row.Qty))
                        : Exec(db, "update tbl_item_batchstock_reserve set itbsr_qty=itbsr_qty-@q where itbsr_id=@r and itbsr_qty>=@q", new MySqlParameter("@q", take), new MySqlParameter("@r", row.ResId));
                    if (changed != 1)
                        throw new StockException("The raw-material reservation changed during production. No changes were made.");
                    InsertProItem(db, warehouseId, itpmId, serial++, row.BatchId, 1, take, row.Cost);
                    totalCost += take * row.Cost;
                    left -= take;
                    used.Add(t);
                }
                if (left > 0)
                    throw new StockException("Insufficient reserved raw material: " + plan.C.Name + ".");
                foreach (var byStock in used.GroupBy(u => u.Row.ItbsId))
                    AdjustBranchStock(db, byStock.Key, -byStock.Sum(u => u.Qty));
                foreach (Take u in used)
                    InsertLedger(db, now, staffId, u.Row.ItbsId, itpmId, warehouseId, u.Row.BatchId, u.Qty, 0m, u.Row.Cost,
                        "Raw material consumed for production #" + docNo + " (sales order #" + smoId + ")"
                        + (u.Factor != null ? ": " + Fmt(u.Kg) + " kg at " + Fmt(u.Factor.KgPerMetre) + " kg/m" : ""));
            }

            decimal unitCost = outQty > 0 ? totalCost / outQty : 0m;
            int newBatchId = CreateFinishedBatch(db, now, staffId, warehouseId, finishedItbs, l, itpmId, outQty, unitCost, totalCost);
            InsertProItem(db, warehouseId, itpmId, serial, newBatchId, 2, outQty, unitCost);
            AdjustBranchStock(db, finishedItbs, outQty);
            InsertLedger(db, now, staffId, finishedItbs, itpmId, warehouseId, newBatchId, 0m, outQty, unitCost,
                "Produced for sales order #" + smoId + " (production #" + docNo + ")");
            if (reserveQty > 0)
                InsertReservation(db, newBatchId, reserveQty, sioId, now, staffId);
            SalesOrderStatus.TryUpdateSalesOrderStatus(db, smoId, staffId);

            string usage = string.Join("; ", plans.Where(p => p.Takes.Any(t => t.Factor != null)).Select(p => p.C.Name + " " + Fmt(p.Takes.Sum(t => t.Kg)) + " kg ("
                + string.Join(", ", p.Takes.Select(t => "batch " + t.Row.BatchNo + " " + Fmt(t.Kg) + " kg")) + ")"));

            return "Produced " + Fmt(qty) + " " + c.UomName + " of " + l.Name + " in the " + warehouse + " warehouse (production #" + docNo + ")"
                + (reserveQty > 0 ? " and reserved " + Fmt(reserveQty * c.F) + " " + c.UomName + " for this order." : "; it was added to finished stock.")
                + (usage.Length > 0 ? " Raw material used: " + usage + "." : "");
        });
    }

    // Raw material one production run of qty (sales UOM) takes from the line's reservations in one warehouse, batch by batch. Fixed BOM lines use the BOM
    // quantity; batch-calculated lines use each reserved batch's own weight and length. Throws a StockException with a readable message when anything
    // needed is missing or too small. forUpdate locks the reservation rows (production); a preview reads them without locking.
    static List<ComponentPlan> BuildProductionPlans(mySqlConnection db, Snapshot s, Line l, Calc c, int sioId, int warehouseId, string warehouse, decimal qty, bool forUpdate)
    {
        var plans = new List<ComponentPlan>();
        foreach (Comp cp in c.Comps)
        {
            if (cp.Issue != null)
                throw new StockException(cp.Name + ": " + cp.Issue + ".");
            var plan = new ComponentPlan { C = cp, Rows = LockWarehouseReservations(db, sioId, cp.ItmId, warehouseId, forUpdate) };
            decimal reserved = plan.Rows.Sum(x => x.Qty);
            if (cp.Dynamic)
                PlanDynamic(s, l, c, plan, qty, warehouse);
            else
            {
                if (cp.PerUnit <= 0)
                    throw new StockException(cp.Name + ": the BOM quantity is not valid.");
                plan.Need = ComponentNeed(cp, qty);
                if (plan.Need > reserved)
                    throw new StockException(reserved <= 0
                        ? cp.Name + " is not reserved for this order in the " + warehouse + " warehouse."
                        : "Only " + Fmt(reserved * cp.F) + " " + cp.UomName + " of " + cp.Name + " is reserved in the " + warehouse + " warehouse, but " + Fmt(plan.Need * cp.F) + " " + cp.UomName + " is needed to produce " + Fmt(qty) + " " + c.UomName + ".");
                decimal left = plan.Need;
                foreach (LockedReservation row in plan.Rows)
                {
                    if (left <= 0)
                        break;
                    decimal take = Math.Min(left, row.Qty);
                    plan.Takes.Add(new Take { Row = row, Qty = take });
                    left -= take;
                }
            }
            plans.Add(plan);
        }
        if (plans.Count == 0)
            throw new StockException("No BOM is defined for this item.");
        return plans;
    }

    // Calculates the take from each reserved batch on its own weight and length, so batches of the same material with different weight-to-length
    // ratios are each charged correctly and the consumption is booked against the batch it came from.
    static void PlanDynamic(Snapshot s, Line l, Calc c, ComponentPlan plan, decimal qty, string warehouse)
    {
        Comp cp = plan.C;
        FinishedBasis fb = FinishedBasisOf(s, l);
        if (fb.Error != null)
            throw new StockException(cp.Name + ": " + fb.Error + ".");
        if (cp.Multiplier <= 0)
            throw new StockException(cp.Name + ": the BOM quantity is not valid.");
        decimal? baseQty = Conv(s, qty, l.SalesTum, fb.BaseTum);
        if (!baseQty.HasValue)
            throw new StockException("Invalid UOM conversion between the quantity to produce and the calculation unit.");
        if (plan.Rows.Count == 0)
            throw new StockException(cp.Name + " is not reserved for this order in the " + warehouse + " warehouse.");

        AllocationResult a = BomConsumption.Allocate(cp.Method, DynamicInput(l, cp, fb), ReservationSlices(plan.Rows), baseQty.Value, 3);
        if (a.Errors.Count > 0)
            throw new StockException(string.Join(" ", a.Errors));
        if (a.Shortfall > 0)
        {
            decimal madeBase = baseQty.Value - a.Shortfall;
            decimal? made = Conv(s, madeBase, fb.BaseTum, l.SalesTum);
            throw new StockException("The " + cp.Name + " reserved in the " + warehouse + " warehouse is enough for only " + Fmt(made ?? 0m) + " " + c.UomName
                + " (calculated from the weight and length of each reserved batch), but " + Fmt(qty) + " " + c.UomName + " is to be produced.");
        }
        plan.Need = a.TotalBatchQty;
        foreach (BatchAllocation row in a.Rows)
        {
            decimal? finished = Conv(s, row.FinishedUnits, fb.BaseTum, l.SalesTum);
            plan.Takes.Add(new Take
            {
                Row = (LockedReservation)row.Slice.Tag, Qty = row.BatchQty, Factor = row.Factor,
                Finished = finished ?? 0m, Kg = row.Kg, Metres = row.Metres
            });
        }
    }

    // Read-only calculation of what producing qty in one warehouse would consume, for display before the production is confirmed.
    public static ProductionPreview PreviewProduction(int smoId, int branchId, int staffId, int sioId, int warehouseId, decimal qty)
    {
        var result = new ProductionPreview();
        var db = new mySqlConnection();
        try
        {
            if (warehouseId <= 0)
                throw new StockException("Select the warehouse to produce in.");
            if (qty <= 0)
                throw new StockException("Enter a quantity to produce greater than zero.");
            if (Math.Round(qty, 3) != qty)
                throw new StockException("The quantity to produce can have at most 3 decimals.");
            Snapshot s = LoadSnapshot(db, smoId, branchId, sioId, false);
            Line l = RequireLine(s);
            Calc c = Compute(s, l);
            if (c.Error != null)
                throw new StockException(c.Error);
            if (!c.HasBom)
                throw new StockException("No BOM is defined for this item.");
            string warehouse = db.SelectScalarForTransaction("select branch_name from tbl_branch where branch_id=@w", new MySqlParameter[] { new MySqlParameter("@w", warehouseId) });
            if (warehouse == "")
                throw new StockException("The warehouse was not found.");
            if (warehouseId != branchId && db.SelectScalarForTransaction("select count(*) from tbl_user_branches where user_id=@u and branch_id=@w",
                new MySqlParameter[] { new MySqlParameter("@u", staffId), new MySqlParameter("@w", warehouseId) }) == "0")
                throw new StockException("You do not have access to the " + warehouse + " warehouse.");

            List<ComponentPlan> plans = BuildProductionPlans(db, s, l, c, sioId, warehouseId, warehouse, qty, false);
            result.uom = c.UomName;
            result.warehouse = warehouse;
            result.qty = qty;
            foreach (ComponentPlan p in plans)
            {
                var m = new ProductionPreviewMaterial
                {
                    itmId = p.C.ItmId, name = p.C.Name, code = p.C.Code, uom = p.C.UomName,
                    method = p.C.Dynamic ? BomConsumption.Describe(p.C.Method) : "",
                    required = R4(p.Takes.Sum(t => t.Qty) * p.C.F),
                    kg = R4(p.Takes.Sum(t => t.Kg)),
                    metres = R4(p.Takes.Sum(t => t.Metres))
                };
                foreach (Take t in p.Takes)
                    m.batches.Add(new ProductionPreviewBatch
                    {
                        batchId = t.Row.BatchId, batchNo = t.Row.BatchNo, qty = R4(t.Qty * p.C.F),
                        kg = R4(t.Kg), metres = R4(t.Metres), finished = R4(t.Finished),
                        kgPerMetre = t.Factor != null ? R4(t.Factor.KgPerMetre) : 0m,
                        kgPerUnit = t.Factor != null ? R4(t.Factor.KgPerUnit) : 0m
                    });
                result.materials.Add(m);
            }
            result.ok = true;
        }
        catch (StockException ex)
        {
            result.message = ex.Message;
        }
        catch (Exception ex)
        {
            new LogClass("salesorderstockerror").write(ex);
            result.message = "The raw-material requirement could not be calculated. Please try again.";
        }
        finally
        {
            Close(db);
        }
        return result;
    }

    static StockActionResult Run(int smoId, Func<mySqlConnection, DateTime, string> work)
    {
        var result = new StockActionResult();
        var db = new mySqlConnection();
        bool started = false;
        try
        {
            DateTime now;
            try { now = BranchClock.NowForSalesOrder(db, smoId); }
            catch (InvalidOperationException ex) { throw new StockException(ex.Message); }
            db.BeginTransaction();
            started = true;
            string message = work(db, now);
            db.CommitTransaction();
            started = false;
            result.ok = true;
            result.message = message;
            try
            {
                result.status = SalesOrderStatus.Read(smoId);
                result.statusText = SalesOrderStatus.Name(result.status);
                result.statusCss = SalesOrderStatus.Css(result.status);
            }
            catch (Exception ex) { new LogClass("salesorderstockerror").write(ex); }
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

    static bool IsOpenStatus(int status) { return SalesOrderStatus.CanReserve(status); }
    static bool IsReleaseStatus(int status) { return SalesOrderStatus.CanRelease(status); }

    static void RequireOpen(int status)
    {
        if (IsOpenStatus(status))
            return;
        if (status == SalesOrderStatus.OnHold)
            throw new StockException("This order is on hold. Approve it to resume and reserve or produce stock.");
        if (SalesOrderStatus.IsUnapproved(status))
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
        // The stock/batch quantity columns are DECIMAL(10,6). A value with more decimals is rounded by the database with a warning,
        // which makes row_count() return -1 even though the row was updated, so quantities are rounded here first.
        foreach (MySqlParameter p in ps)
            if (p.Value is decimal)
                p.Value = Round6((decimal)p.Value);
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
    static decimal R6(decimal d) { return Math.Round(d, 6, MidpointRounding.AwayFromZero); }
    static string Fmt(decimal d) { return Math.Round(d, 3, MidpointRounding.AwayFromZero).ToString("0.###"); }

    static IEnumerable<Batch> Fifo(IEnumerable<Batch> batches)
    {
        return batches.OrderBy(b => b.Created == null ? 1 : 0).ThenBy(b => b.Created, StringComparer.Ordinal).ThenBy(b => b.Id).ToList();
    }

    static Snapshot LoadSnapshot(mySqlConnection db, int smoId, int branchId, int onlySio, bool lockBatches)
    {
        var s = new Snapshot { BranchId = branchId };

        foreach (DataRow r in db.SelectQueryForTransaction("select tum_id,tum_type_id,tum_convertion_fac,tum_name from tbl_item_uom").Rows)
            s.Uoms[I(r["tum_id"])] = new Uom { Id = I(r["tum_id"]), TypeId = I(r["tum_type_id"]), Fac = D(r["tum_convertion_fac"]), Name = S(r["tum_name"]) };

        foreach (DataRow r in db.SelectQueryForTransaction("select tumt_id,tumt_name,ifnull(tum_id,0) as tum_id from tbl_item_uom_type").Rows)
            s.UomCategories[I(r["tumt_id"])] = new UomCategory { Id = I(r["tumt_id"]), Name = S(r["tumt_name"]), DefaultUomId = I(r["tum_id"]) };

        DataTable lines = db.SelectQueryForTransaction("select sio.sio_id,sio.itm_id,sio.itbs_id,sio.tum_id,sio.sio_finalqty,sio.itm_name as sio_name,"
            + "m.itm_code,m.itm_name,m.itsv_uom_purchase,m.itsv_uom_sales,m.itsv_bom_enabled,spw.itsv_name as width_text,"
            + "ifnull((select sum(si.si_qty) from tbl_sales_items si inner join tbl_sales_master sm on sm.sm_id=si.sm_id "
            + "where si.sio_id=sio.sio_id and sm.sm_refid=sio.smo_id and sm.sm_is_inter_stock_transfer_invoice=0 and " + SalesOrderStatus.ValidInvoiceSql + "),0) as invoiced,"
            + "ifnull((select sum(pi.itpi_quantity) from tbl_item_pro_items pi inner join tbl_item_batch pb on pb.itbh_id=pi.itbh_id "
            + "where pi.itpi_inputoutput=2 and pb.itbh_custbatchid=concat('PRO-',pi.itpm_id,'-',sio.sio_id)),0) as produced,"
            + "tis.branch_id as tis_branch,tis.itm_id as tis_itm,tis.itbs_stock "
            + "from tbl_sales_items_order sio left join tbl_item_master m on m.itm_id=sio.itm_id "
            + "left join tbl_item_master_spe_values spw on spw.itsv_id=m.itsv_spec_width "
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
                WidthText = S(r["width_text"]),
                BomEnabled = I(r["itsv_bom_enabled"]) == 1
            };
            l.StockRowOk = l.ItbsId > 0 && I(r["tis_branch"]) == branchId && I(r["tis_itm"]) == l.ItmId;
            s.Lines.Add(l);
        }

        // Finished goods already produced for these lines, per producing warehouse (the batch's own warehouse, not the order's).
        foreach (DataRow r in db.SelectQueryForTransaction("select sio.sio_id,pb.branch_id,tb.branch_name,sum(pi.itpi_quantity) as q "
            + "from tbl_item_pro_items pi inner join tbl_item_batch pb on pb.itbh_id=pi.itbh_id "
            + "inner join tbl_sales_items_order sio on pb.itbh_custbatchid=concat('PRO-',pi.itpm_id,'-',sio.sio_id) "
            + "left join tbl_branch tb on tb.branch_id=pb.branch_id "
            + "where pi.itpi_inputoutput=2 and sio.smo_id=@o and (@s=0 or sio.sio_id=@s) group by sio.sio_id,pb.branch_id,tb.branch_name",
            new MySqlParameter[] { new MySqlParameter("@o", smoId), new MySqlParameter("@s", onlySio) }).Rows)
        {
            Line pl = s.Lines.FirstOrDefault(x => x.SioId == I(r["sio_id"]));
            if (pl == null)
                continue;
            pl.ProducedByBranch[I(r["branch_id"])] = D(r["q"]);
            s.BranchNames[I(r["branch_id"])] = S(r["branch_name"]);
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
                    Method = "",
                    Name = S(r["itm_name"]),
                    Code = S(r["itm_code"]),
                    InputSalesTum = I(r["itsv_uom_sales"]),
                    InputPurchaseTum = I(r["itsv_uom_purchase"]),
                    InputItbsId = I(r["itbs_id"])
                };
                Line fin = s.Lines.FirstOrDefault(x => x.ItmId == output);
                row.Method = ConsumptionMethodFor(s, row, fin == null ? 0 : fin.SalesTum);
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
                + "b.itbh_kg,b.itbh_length,b.itbh_no_piece,b.itbh_startqty,"
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
                    Kg = D(r["itbh_kg"]),
                    Length = D(r["itbh_length"]),
                    Pieces = D(r["itbh_no_piece"]),
                    StartQty = D(r["itbh_startqty"]),
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
                + "b.itbh_kg,b.itbh_length,b.itbh_no_piece,b.itbh_startqty,"
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
                        Kg = D(r["itbh_kg"]),
                        Length = D(r["itbh_length"]),
                        Pieces = D(r["itbh_no_piece"]),
                        StartQty = D(r["itbh_startqty"]),
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
        return Compute(s, l, 0m);
    }

    // planQty > 0 is the production quantity the user chose (sales UOM); it replaces the default (the finished-stock shortfall, or the remaining quantity).
    static Calc Compute(Snapshot s, Line l, decimal planQty)
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
        c.Needs = Ceil6(Math.Max(0m, c.Remaining - c.Free));
        c.ProduceQty = planQty > 0 ? Ceil6(planQty) : (c.Needs > 0 ? c.Needs : Ceil6(c.Remaining));

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

    // The warehouses this order line can produce in, one entry per warehouse. A warehouse is listed when raw material of the BOM is reserved
    // for the line in it, or when finished goods were already produced there. Each entry is self-contained: the producible quantity comes only
    // from that warehouse's own reservations, because production never combines raw material from different warehouses.
    static List<WarehouseProduction> BuildWarehouses(Snapshot s, Calc c, Line l, bool open, out string issue)
    {
        var list = new List<WarehouseProduction>();
        issue = null;
        if (!c.HasBom)
        {
            issue = "No BOM is defined for this item.";
            return list;
        }
        var names = new Dictionary<int, string>(s.BranchNames);
        var branchIds = new HashSet<int>(l.ProducedByBranch.Keys);
        foreach (Comp cp in c.Comps.Where(x => x.Issue == null))
            foreach (OwnRes o in s.OwnOnItem(cp.ItmId, l.SioId).Where(x => x.Qty > 0))
            {
                branchIds.Add(o.B.BranchId);
                if (!string.IsNullOrEmpty(o.B.BranchName))
                    names[o.B.BranchId] = o.B.BranchName;
            }

        foreach (int br in branchIds)
        {
            string name;
            var wp = new WarehouseProduction { branchId = br, warehouse = names.TryGetValue(br, out name) ? name : "Warehouse " + br, isHome = br == s.BranchId, produced = R6(ProducedIn(l, c.F, br)) };
            decimal? max = null;
            var missing = new List<string>();
            foreach (Comp cp in c.Comps)
            {
                if (cp.Issue != null)
                {
                    missing.Add(cp.Name + ": " + cp.Issue);
                    max = 0m;
                    continue;
                }
                List<OwnRes> rows = s.OwnOnItem(cp.ItmId, l.SioId).Where(o => o.B.BranchId == br && o.Qty > 0)
                    .OrderByDescending(o => o.Priority).ThenBy(o => o.B.Created == null ? 1 : 0).ThenBy(o => o.B.Created, StringComparer.Ordinal).ThenBy(o => o.B.Id).ToList();
                decimal reservedSales = rows.Sum(o => o.Qty) * cp.F;
                var batchRows = rows.Select(o => new ReservedAllocation { batchId = o.B.Id, branchId = o.B.BranchId, warehouse = wp.warehouse, batchNo = o.B.No, qty = R4(o.Qty * cp.F), uom = cp.UomName, status = "Reserved", priority = o.Priority }).ToList();
                decimal supports;
                if (cp.Dynamic)
                {
                    // What the reserved batches can make is the sum of what each one can make on its own weight-to-length ratio.
                    supports = 0m;
                    FinishedBasis fb = FinishedBasisOf(s, l);
                    decimal? baseUnit = fb.Error == null ? Conv(s, 1m, l.SalesTum, fb.BaseTum) : null;
                    if (baseUnit.HasValue && baseUnit.Value > 0)
                    {
                        ConsumptionInput tpl = DynamicInput(l, cp, fb);
                        for (int i = 0; i < rows.Count; i++)
                        {
                            ConsumptionFactor f = BomConsumption.Calculate(cp.Method, BomConsumption.ForBatch(tpl, rows[i].B.Profile()));
                            if (!f.Ok)
                            {
                                foreach (string e in f.Errors)
                                    if (!missing.Contains(e))
                                        missing.Add(e);
                                continue;
                            }
                            decimal makes = BomConsumption.Capacity(f, rows[i].Qty) / baseUnit.Value;
                            batchRows[i].kgPerMetre = R4(f.KgPerMetre);
                            batchRows[i].kgPerUnit = R4(f.KgPerUnit * baseUnit.Value);
                            batchRows[i].makes = R4(makes);
                            supports += makes;
                        }
                    }
                }
                else
                    supports = cp.PerUnit > 0 ? reservedSales / cp.PerUnit : 0m;
                wp.materials.Add(new WarehouseProductionMaterial
                {
                    itmId = cp.ItmId, name = cp.Name, code = cp.Code, uom = cp.UomName, perUnit = R4(cp.PerUnit),
                    reserved = R4(reservedSales), supports = R4(supports),
                    method = cp.Dynamic ? BomConsumption.Describe(cp.Method) : "",
                    batches = batchRows
                });
                if (reservedSales <= 0)
                    missing.Add(cp.Name + " is not reserved");
                max = max.HasValue ? Math.Min(max.Value, supports) : supports;
            }
            wp.maxQty = Floor3(max ?? 0m);
            wp.canProduce = open && wp.maxQty > 0;
            if (wp.maxQty <= 0 && wp.materials.Any(m => m.reserved > 0))
                wp.message = missing.Count > 0
                    ? "Cannot produce here: " + string.Join("; ", missing) + " in this warehouse. Production uses only the raw material reserved in the same warehouse."
                    : "The reserved raw material in this warehouse is too small to produce a unit.";
            list.Add(wp);
        }

        list = list.OrderByDescending(x => x.isHome).ThenBy(x => x.warehouse, StringComparer.Ordinal).ToList();
        decimal target = c.ProduceQty;
        foreach (WarehouseProduction wp in list)
        {
            wp.suggestedQty = Floor3(Math.Max(0m, Math.Min(wp.maxQty, target)));
            target -= wp.suggestedQty;
        }

        if (!list.Any(x => x.canProduce))
            issue = !list.Any(x => x.materials.Any(m => m.reserved > 0))
                ? "Reserve the raw material for this item first. It is produced in the warehouse where the raw material is reserved."
                : string.Join(" ", list.Where(x => x.message != null).Select(x => x.warehouse + ": " + x.message));
        return list;
    }

    // No per-line setting is needed: a raw material that is received by length or area (coils, sheets - its batch UOM is a Length or Area unit) is
    // consumed from the actual batch's weight and length. A raw material received by weight (KG coil) uses the same calculation only when the finished
    // good is a Length or Area item (the width converts it); a finished good sold by weight keeps the fixed BOM quantity. Anything else is fixed too.
    static string ConsumptionMethodFor(Snapshot s, BomRow b, int finishedTum)
    {
        Uom u;
        UomCategory cat;
        int tum = b.InputPurchaseTum > 0 ? b.InputPurchaseTum : b.InputSalesTum;
        if (tum <= 0 || !s.Uoms.TryGetValue(tum, out u) || !s.UomCategories.TryGetValue(u.TypeId, out cat))
            return "";
        if (BomConsumption.BasisOf(cat.Name) != ConsumptionBasis.Unsupported)
            return BomConsumption.MethodBatchWeightPerMetre;
        if (BomConsumption.IsBatchMeasured(cat.Name))
        {
            Uom fu;
            UomCategory fcat;
            if (finishedTum > 0 && s.Uoms.TryGetValue(finishedTum, out fu) && s.UomCategories.TryGetValue(fu.TypeId, out fcat)
                && BomConsumption.BasisOf(fcat.Name) != ConsumptionBasis.Unsupported)
                return BomConsumption.MethodBatchWeightPerMetre;
        }
        return "";
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
            if (BomConsumption.IsDynamic(b.Method))
            {
                if (cp.HasFixedLine)
                    cp.Issue = "The BOM lists this raw material with a fixed quantity and with a calculated quantity; use one method per raw material";
                else if (cp.Dynamic && !string.Equals(cp.Method, b.Method, StringComparison.OrdinalIgnoreCase))
                    cp.Issue = "The BOM lists this raw material with different calculation methods; use one method per raw material";
                else
                {
                    cp.Method = b.Method;
                    cp.Multiplier += 1m;
                }
                continue;
            }
            if (cp.Dynamic)
            {
                cp.Issue = "The BOM lists this raw material with a fixed quantity and with a calculated quantity; use one method per raw material";
                continue;
            }
            cp.HasFixedLine = true;
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
            if (cp.Dynamic)
            {
                ApplyDynamic(s, c, cp);
                if (cp.Issue != null)
                    continue;
            }
            else
                cp.Required = cp.PerUnit * c.ProduceQty;
            cp.Enough = Ceil6(cp.Required) <= cp.Free + cp.Reserved;
        }
    }

    // ---- Batch-based consumption (see BomConsumption) ----

    // What the finished good's sales UOM measures (Length / Area), the unit the calculation runs in and the Item Master width, resolved once per line.
    sealed class FinishedBasis
    {
        public ConsumptionBasis Basis;
        public decimal? Width;
        public int BaseTum;
        public string Error;
    }

    static FinishedBasis FinishedBasisOf(Snapshot s, Line l)
    {
        var fb = new FinishedBasis();
        Uom u;
        if (l.SalesTum <= 0 || !s.Uoms.TryGetValue(l.SalesTum, out u))
        {
            fb.Error = "The sales UOM of " + l.Name + " is not defined, so its raw-material consumption cannot be calculated";
            return fb;
        }
        UomCategory cat;
        if (!s.UomCategories.TryGetValue(u.TypeId, out cat))
        {
            fb.Error = "The category of the sales UOM " + u.Name + " is not configured";
            return fb;
        }
        fb.Basis = BomConsumption.BasisOf(cat.Name);
        if (fb.Basis == ConsumptionBasis.Unsupported)
        {
            fb.Error = "The sales UOM of " + l.Name + " (" + u.Name + ") is a " + cat.Name + " unit; the batch-based calculation needs a Length or Area unit";
            return fb;
        }
        Uom def;
        if (cat.DefaultUomId <= 0 || !s.Uoms.TryGetValue(cat.DefaultUomId, out def))
        {
            fb.Error = "No default UOM is configured for the " + cat.Name + " category";
            return fb;
        }
        string unitIssue = BomConsumption.CheckBaseUnit(fb.Basis, def.Name);
        if (unitIssue != null)
        {
            fb.Error = unitIssue.TrimEnd('.');
            return fb;
        }
        fb.BaseTum = def.Id;
        if (fb.Basis == ConsumptionBasis.Area)
        {
            decimal width;
            string why;
            if (string.IsNullOrWhiteSpace(l.WidthText))
                fb.Error = "The width of " + l.Name + " is not configured in the Item Master (Spec Width); it is needed to convert square metres to raw-material length";
            else if (!BomConsumption.TryParseMetres(l.WidthText, out width, out why))
                fb.Error = "The Spec Width of " + l.Name + " in the Item Master is invalid: " + why;
            else
                fb.Width = width;
        }
        return fb;
    }

    static ConsumptionInput DynamicInput(Line l, Comp cp, FinishedBasis fb)
    {
        return new ConsumptionInput { FinishedName = l.Name, MaterialName = cp.Name, Basis = fb.Basis, FinishedWidthMetres = fb.Width, Multiplier = cp.Multiplier };
    }

    // The batches a requirement estimate is spread over: what the line already holds reserved (in its priority order), then free stock first-in-first-out.
    static List<BatchSlice> EstimateSlices(Snapshot s, Line l, Comp cp)
    {
        var list = new List<BatchSlice>();
        foreach (OwnRes o in s.OwnOnItem(cp.ItmId, l.SioId).Where(x => x.Qty > 0)
            .OrderByDescending(x => x.Priority).ThenBy(x => x.B.Created == null ? 1 : 0).ThenBy(x => x.B.Created, StringComparer.Ordinal).ThenBy(x => x.B.Id))
            list.Add(new BatchSlice { Batch = o.B.Profile(), AvailableQty = o.Qty, Tag = o.B });
        foreach (Batch b in Fifo(cp.Batches))
            if (b.Free > 0)
                list.Add(new BatchSlice { Batch = b.Profile(), AvailableQty = b.Free, Tag = b });
        return list;
    }

    // Requirement of a batch-calculated component for the production quantity, taken batch by batch. It is an estimate until the raw material is
    // reserved: the real figures are recalculated from the batches actually reserved when production runs.
    static void ApplyDynamic(Snapshot s, Calc c, Comp cp)
    {
        FinishedBasis fb = FinishedBasisOf(s, c.L);
        if (fb.Error != null)
        {
            cp.Issue = fb.Error;
            return;
        }
        if (cp.Multiplier <= 0)
        {
            cp.Issue = "The BOM quantity must be greater than zero";
            return;
        }
        decimal? baseQty = Conv(s, c.ProduceQty, c.L.SalesTum, fb.BaseTum);
        decimal? baseUnit = Conv(s, 1m, c.L.SalesTum, fb.BaseTum);
        if (!baseQty.HasValue || !baseUnit.HasValue)
        {
            cp.Issue = "Invalid UOM conversion for the finished item";
            return;
        }
        List<BatchSlice> slices = EstimateSlices(s, c.L, cp);
        if (slices.Count == 0)
        {
            cp.Issue = "No batch of " + cp.Name + " has stock, so the requirement cannot be calculated from batch weight and length";
            return;
        }
        ConsumptionInput tpl = DynamicInput(c.L, cp, fb);
        AllocationResult alloc = BomConsumption.Allocate(cp.Method, tpl, slices, baseQty.Value, 3);
        ConsumptionFactor reference = alloc.Rows.Count > 0 ? alloc.Rows[0].Factor : null;
        if (reference == null)
        {
            // Nothing is needed (zero quantity) or nothing could be calculated: use the first usable batch to show the rate.
            var errors = new List<string>(alloc.Errors);
            foreach (BatchSlice sl in slices)
            {
                ConsumptionFactor f = BomConsumption.Calculate(cp.Method, BomConsumption.ForBatch(tpl, sl.Batch));
                if (f.Ok)
                {
                    reference = f;
                    break;
                }
                foreach (string e in f.Errors)
                    if (!errors.Contains(e))
                        errors.Add(e);
            }
            if (reference == null)
            {
                cp.Issue = string.Join(" ", errors);
                return;
            }
        }
        // Batches that cannot be calculated are skipped here (they are reported when production is previewed or run), so one batch without a
        // recorded weight does not block planning from the others.
        cp.PerUnit = reference.BatchQtyPerUnit * baseUnit.Value * cp.F;
        cp.Required = (alloc.TotalBatchQty + alloc.Shortfall * reference.BatchQtyPerUnit) * cp.F;
    }

    static List<BatchSlice> ReservationSlices(IEnumerable<LockedReservation> rows)
    {
        return rows.Select(r => new BatchSlice { Batch = r.Profile, AvailableQty = r.Qty, Tag = r }).ToList();
    }

    static int UomType(Snapshot s, int id)
    {
        Uom u;
        return s.Uoms.TryGetValue(id, out u) ? u.TypeId : 0;
    }

    static ReservedItemRow ToRow(Snapshot s, Line l, int sl, bool open, bool canRelease, int status)
    {
        return ToRow(s, l, sl, open, canRelease, status, 0m);
    }

    static ReservedItemRow ToRow(Snapshot s, Line l, int sl, bool open, bool canRelease, int status, decimal planQty)
    {
        Calc c = Compute(s, l, planQty);
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
        row.produceQty = R6(c.ProduceQty);
        row.produced = R6(c.Produced);
        row.producedPct = c.Ordered > 0 ? R4(Math.Min(100m, c.Produced / c.Ordered * 100m)) : 0m;
        row.planQty = R6(planQty);
        row.hasBom = c.HasBom;
        row.allocations = Allocations(s, l.ItmId, l.SioId, c.F, c.UomName);
        // Once any finished goods were produced for the line, its raw-material reservations are no longer released by hand: what was used is gone,
        // and what is left is held for the rest of the production. Undoing the production lifts this.
        bool rawLocked = l.ProducedByBranch.Count > 0;
        foreach (Comp cp in c.Comps)
        {
            decimal compRemaining = Math.Max(0m, cp.Required - cp.Reserved);
            bool usable = cp.Issue == null && c.ProduceQty > 0;
            decimal compReservable = Floor3(Math.Min(compRemaining, cp.Free));
            var comp = new ReservedBomComponent
            {
                code = cp.Code, name = cp.Name, uom = cp.UomName, perUnit = R4(cp.PerUnit),
                required = R4(cp.Required), free = R4(cp.Free), enough = cp.Enough, issue = cp.Issue,
                itmId = cp.ItmId, reserved = R4(cp.Reserved), remaining = R4(compRemaining), available = R4(compReservable),
                method = cp.Dynamic ? BomConsumption.Describe(cp.Method) : "",
                shortage = cp.Issue == null ? R4(Math.Max(0m, cp.Required - cp.Reserved - cp.Free)) : 0m,
                surplus = cp.Issue == null && cp.Reserved - cp.Required > Tolerance ? R4(cp.Reserved - cp.Required) : 0m,
                canReserve = open && usable && compReservable > 0,
                canPick = open && usable,
                canUnreserve = canRelease && !rawLocked && cp.Issue == null && cp.Reserved > 0
            };
            if (cp.Issue == null)
            {
                comp.allocations = Allocations(s, cp.ItmId, l.SioId, cp.F, cp.UomName);
                foreach (ReservedAllocation a in comp.allocations)
                    a.locked = rawLocked;
            }
            row.bom.Add(comp);
        }
        row.bomNote = c.Needs > 0 ? c.FinishedFirst : null;

        row.canReserve = open && c.Reservable > 0;
        // Extra stock beyond the requirement can still be reserved by hand, so picking stays available once the requirement is covered.
        row.canPick = open && c.Required > Tolerance;
        row.canUnreserve = canRelease && c.This > 0;
        string produceIssue;
        row.warehouses = BuildWarehouses(s, c, l, open, out produceIssue);
        row.canProduce = row.warehouses.Any(x => x.canProduce);
        if (!open && (c.Reservable > 0 || c.Needs > 0))
            row.message = status == SalesOrderStatus.OnHold ? "Order is on hold. Approve it to resume and reserve stock."
                : SalesOrderStatus.IsUnapproved(status) ? "Approve the order to reserve stock."
                : SalesOrderStatus.IsCancelled(status) ? "Order is cancelled. Stock cannot be reserved."
                : "Stock actions are not available for an order in this status.";
        else if (c.Remaining > 0 && c.Free <= 0)
            row.message = "No unreserved stock available in the order's warehouse.";
        if (c.HasBom && produceIssue != null)
            row.productionMessage = produceIssue;
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

    // itbs_stock is DECIMAL(10,6) (max 9999.999999). In non-strict SQL mode an out-of-range update is silently clamped and
    // row_count() returns -1, so a negative count means the new balance does not fit the column. The row is read first so the
    // message names the item, warehouse and figures instead of a generic range error.
    static void AdjustBranchStock(mySqlConnection db, int itbsId, decimal delta)
    {
        DataTable cur = db.SelectQueryForTransaction("select ifnull(s.itbs_stock,0) as q,m.itm_name,tb.branch_name from tbl_itembranch_stock s "
            + "left join tbl_item_master m on m.itm_id=s.itm_id left join tbl_branch tb on tb.branch_id=s.branch_id where s.itbs_id=@i for update",
            new MySqlParameter[] { new MySqlParameter("@i", itbsId) });
        if (cur.Rows.Count == 0)
            throw new StockException("The branch stock record for this item was not found. No changes were saved.");
        decimal current = D(cur.Rows[0]["q"]);
        string what = S(cur.Rows[0]["itm_name"]) + " in the " + S(cur.Rows[0]["branch_name"]) + " warehouse";
        decimal next = current + delta;
        if (next > 9999.999999m)
            throw new StockException("Unable to update branch stock of " + what + ": " + Fmt(current) + " + " + Fmt(delta) + " exceeds the maximum the stock column can hold (9999.999999). No changes were saved.");
        if (Exec(db, "update tbl_itembranch_stock set itbs_stock=coalesce(itbs_stock,0)+@d where itbs_id=@i",
            new MySqlParameter("@d", delta), new MySqlParameter("@i", itbsId)) < 0)
            throw new StockException(next < 0
                ? "Unable to update branch stock of " + what + ": the stock is " + Fmt(current) + " but " + Fmt(-delta) + " is being consumed, which would make it negative. Correct the stock of this item first. No changes were saved."
                : "Unable to update branch stock of " + what + ": the resulting quantity " + Fmt(next) + " is outside the range of tbl_itembranch_stock.itbs_stock. No changes were saved.");
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
    static int CreateFinishedBatch(mySqlConnection db, DateTime now, int staffId, int branchId, int itbsId, Line l, int itpmId, decimal qty, decimal unitCost, decimal totalCost)
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
                new MySqlParameter("@i", itbsId), new MySqlParameter("@m", l.ItmId), new MySqlParameter("@tum", l.SalesTum),
                new MySqlParameter("@q", qty), new MySqlParameter("@len", length), new MySqlParameter("@wid", width),
                new MySqlParameter("@c", unitCost), new MySqlParameter("@ct", totalCost), new MySqlParameter("@doc", itpmId),
                new MySqlParameter("@t", now), new MySqlParameter("@u", staffId) });
        return int.Parse(id);
    }
}
