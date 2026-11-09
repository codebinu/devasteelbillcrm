using System;
using System.Collections.Generic;
using System.Linq;

// One manufactured sales order line on the Production Queue board.
public class ProductionBoardRow
{
    public int smoId;
    public int sioId;
    public int itmId;
    public string orderRef;
    public string customer;
    public string warehouse;
    public string orderDate;
    public int orderStatus;
    public string orderStatusText;

    public string itemName;
    public string itemCode;
    public string uom;
    public decimal ordered;
    public decimal delivered;
    public decimal required;
    public decimal produced;
    public decimal pending;
    public decimal reservedFinished;

    public string statusKey;
    public string status;
    public string statusClass;
    public string message;
    public bool canAct;
    public bool rawReady;
    public bool canProduce;

    // Reserving the finished item itself (stock that already exists must be reserved before anything is produced).
    public decimal availableFinished;
    public bool canReserveFinished;
    public bool canPickFinished;
    public bool canUnreserveFinished;

    public List<ReservedBomComponent> raw = new List<ReservedBomComponent>();
}

public static class ProductionBoardStatus
{
    public const string Awaiting = "awaiting";
    public const string Ready = "ready";
    public const string Partial = "partial";
    public const string Produced = "produced";
    public const string Covered = "covered";
    public const string Unavailable = "unavailable";

    public static string Text(string key)
    {
        switch (key)
        {
            case Awaiting: return "Awaiting raw material";
            case Ready: return "Ready to produce";
            case Partial: return "Partially produced";
            case Produced: return "Produced";
            case Covered: return "Covered by stock";
            default: return "Unavailable";
        }
    }

    public static string Css(string key)
    {
        switch (key)
        {
            case Awaiting: return "label-warning";
            case Ready: return "label-primary";
            case Partial: return "label-info";
            case Produced: return "label-success";
            default: return "label-default";
        }
    }

    // Statuses that still need somebody to act (the default view of the board).
    public static bool IsOpen(string key) { return key == Awaiting || key == Ready || key == Partial; }
}

public static partial class SalesOrderStock
{
    // Manufactured lines of one order that are not fully delivered, with the stock figures and the raw-material reservation state
    // from the same calculation as the Reserved Items tab (so both screens always agree). sios limits the lines (null = all).
    public static List<ProductionBoardRow> LoadProductionBoard(int smoId, int branchId, int status, bool canAct, HashSet<int> sios)
    {
        var rows = new List<ProductionBoardRow>();
        var db = new commonfunction.mySqlConnection();
        try
        {
            Snapshot s = LoadSnapshot(db, smoId, branchId, 0, false);
            bool open = canAct && IsOpenStatus(status);
            bool canRelease = canAct && IsReleaseStatus(status);
            foreach (Line l in s.Lines)
            {
                if (sios != null && !sios.Contains(l.SioId))
                    continue;
                Calc c = Compute(s, l);
                var row = new ProductionBoardRow { smoId = smoId, sioId = l.SioId, itmId = l.ItmId, itemName = l.Name, itemCode = l.Code, uom = c.UomName ?? "", canAct = canAct };
                if (c.Error != null)
                {
                    row.statusKey = ProductionBoardStatus.Unavailable;
                    row.message = c.Error;
                }
                else
                {
                    // Fully invoiced lines are delivered; lines without a BOM and without any production are not production work.
                    if (c.Required <= Tolerance || (!c.HasBom && l.ProducedBatch <= 0))
                        continue;
                    ReservedItemRow r = ToRow(s, l, 0, open, canRelease, status);
                    row.ordered = r.ordered;
                    row.delivered = r.delivered;
                    row.required = r.required;
                    row.produced = R4(c.Produced);
                    row.pending = r.needsProduction;
                    row.reservedFinished = r.reservedThis;
                    row.availableFinished = r.available;
                    row.canReserveFinished = r.canReserve;
                    row.canPickFinished = r.canPick;
                    row.canUnreserveFinished = r.canUnreserve;
                    row.raw = r.bom;
                    row.rawReady = r.bom.Count > 0 && r.bom.All(b => b.issue == null && b.reserved + 0.0005m >= b.required);
                    row.message = r.bomNote ?? r.message;

                    if (r.needsProduction <= 0)
                        row.statusKey = row.produced > 0 ? ProductionBoardStatus.Produced : ProductionBoardStatus.Covered;
                    else if (row.produced > 0)
                        row.statusKey = ProductionBoardStatus.Partial;
                    else
                        row.statusKey = row.rawReady && c.FinishedFirst == null ? ProductionBoardStatus.Ready : ProductionBoardStatus.Awaiting;
                    row.canProduce = open && r.needsProduction > 0 && row.rawReady && c.FinishedFirst == null;
                }
                row.status = ProductionBoardStatus.Text(row.statusKey);
                row.statusClass = ProductionBoardStatus.Css(row.statusKey);
                rows.Add(row);
            }
        }
        finally
        {
            Close(db);
        }
        return rows;
    }
}
