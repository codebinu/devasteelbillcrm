using commonfunction;
using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;

// Figures for the one-row overview on view_sales_order.aspx. Loaded by a separate request after the page is shown, so it never delays the page.
// Every figure comes from the relationships the existing tabs already use:
//   Invoices   tbl_sales_master.sm_refid = smo_id, not inter-stock transfers, cancelled (4) and rejected (5) excluded; delivered = sm_delivery_status 2.
//   Production the order's production jobs (finished batch PRO-<itpm_id>-<sio_id>, as in the Production Details tab). A job is completed when its
//              stock movements were applied (tbl_stock_transactions, action type 12, action_ref_id = itpm_id) and pending while they are not.
//   Transfers  invoices with sm_refid = smo_id and sm_is_inter_stock_transfer_invoice = 1; completed = its purchase exists and is not cancelled,
//              pending = the purchase has not been created yet.
//
// Three independent percentages, all quantity based, calculated per order line and capped per line so nothing exceeds 100%:
//   Delivery completion     = delivered quantity / ordered quantity. Delivered = quantity on delivered valid invoices; cancelled invoices and
//                             reversed deliveries are not delivered any more, so they do not count.
//   Reservation completion  = active reserved quantity of the line's own item (converted to the line UOM) / ordered quantity of the stock lines.
//                             The uncapped reserved quantity is returned too; only the percentage is capped.
//   Overall completion      = weighted progress of every ordered unit through the stages below (see OverallLineProgress).
public sealed class SalesOrderOverviewResult
{
    public bool ok;
    public string message;
    public decimal orderedQty, deliveredQty, deliveryPct, overallPct;
    public int invoiceTotal, invoiceDelivered, invoicePending;
    public int productionTotal, productionCompleted, productionPending;
    public int transferTotal, transferCompleted, transferPending, transferCancelled;
    public decimal reservableQty, reservedQty, reservedActualQty, unreservedQty, reservedPct;
}

// Quantities of one sales order line in the line's own UOM.
public sealed class OverviewLine
{
    public decimal Ordered, Delivered, Invoiced, Reserved, Produced;
    public bool IsStockItem, HasBom;
}

public static partial class SalesOrderStock
{
    // Stage weights of the overall completion. They add up to 100 for a line that goes through every stage; a stage that does not apply to a line
    // is left out and the remaining weights are scaled up, so an order without production never looks less complete because of it.
    public const decimal WeightReservation = 20m, WeightProduction = 20m, WeightInvoicing = 25m, WeightDelivery = 35m;

    // Progress of one line between 0 and 1. Each unit moves through Reservation -> Production -> Invoicing -> Delivery and counts once per stage,
    // with that stage's share of the weight, so a unit is never counted twice. Per stage, quantity done / ordered quantity:
    //   Reservation  stock items only: reserved now + invoiced (invoicing consumes the reservation, so an invoiced unit was reserved).
    //                A cancelled invoice or reservation therefore stops counting.
    //   Production   only for a stock item with an active BOM that still has to be, or has been, produced: produced / (produced + shortfall), where
    //                the shortfall is what neither a reservation, an invoice nor a production covers. No shortfall and nothing produced = not applicable.
    //   Invoicing    quantity on valid (not cancelled / rejected) invoices.
    //   Delivery     quantity on valid delivered invoices.
    public static decimal OverallLineProgress(OverviewLine l)
    {
        if (l == null || l.Ordered <= 0m)
            return 0m;
        decimal o = l.Ordered;
        decimal delivered = Math.Min(Math.Max(0m, l.Delivered), o);
        decimal invoiced = Math.Min(Math.Max(Math.Max(0m, l.Invoiced), delivered), o);
        decimal reservedNow = Math.Max(0m, l.Reserved);
        decimal produced = Math.Max(0m, l.Produced);

        decimal weight = WeightInvoicing + WeightDelivery;
        decimal done = WeightInvoicing * invoiced / o + WeightDelivery * delivered / o;
        if (l.IsStockItem)
        {
            weight += WeightReservation;
            done += WeightReservation * Math.Min(o, reservedNow + invoiced) / o;
            if (l.HasBom)
            {
                decimal shortfall = Math.Max(0m, o - Math.Max(reservedNow + invoiced, produced));
                decimal target = produced + shortfall;
                if (target > 0.0005m)
                {
                    weight += WeightProduction;
                    done += WeightProduction * Math.Min(1m, produced / target);
                }
            }
        }
        return Math.Min(1m, done / weight);
    }

    // Quantity weighted over the lines (a line counts by its ordered quantity).
    public static decimal OverallPercent(IEnumerable<OverviewLine> lines)
    {
        decimal whole = 0m, part = 0m;
        foreach (OverviewLine l in lines)
        {
            if (l == null || l.Ordered <= 0m)
                continue;
            whole += l.Ordered;
            part += l.Ordered * OverallLineProgress(l);
        }
        return Percent(part, whole);
    }

    public static SalesOrderOverviewResult LoadOverview(int smoId, int branchId)
    {
        var result = new SalesOrderOverviewResult();
        var db = new mySqlConnection();
        try
        {
            var o = new MySqlParameter[] {
                new MySqlParameter("@o", smoId), new MySqlParameter("@br", branchId),
                // @pc is boxed on purpose: a constant 0 would otherwise bind to the (name, MySqlDbType) overload and leave the parameter without a value
                new MySqlParameter("@pa", ProductionActionType), new MySqlParameter("@pc", (object)(int)Constants.PurchaseStatus.Cancel) };

            // Counts of invoices, production jobs and transfers in one round trip; every part is an aggregate, no record is loaded.
            DataTable c = db.SelectQuery("select inv.total as inv_total,inv.delivered as inv_delivered,pr.total as pr_total,pr.done as pr_done,"
                + "tr.total as tr_total,tr.done as tr_done,tr.cancelled as tr_cancelled from "
                + "(select count(*) as total,ifnull(sum(sm.sm_delivery_status=" + SalesOrderStatus.InvoiceDelivered + "),0) as delivered from tbl_sales_master sm "
                + "where sm.sm_refid=@o and sm.sm_is_inter_stock_transfer_invoice=0 and " + SalesOrderStatus.ValidInvoiceSql + ") inv,"
                + "(select count(*) as total,ifnull(sum(j.moved),0) as done from (select b.itbh_id,"
                + "max(exists(select 1 from tbl_stock_transactions st where st.action_type=@pa and st.action_ref_id=pm.itpm_id)) as moved "
                + "from tbl_sales_items_order sio "
                + "inner join tbl_item_batch b on b.itbh_custbatchid=concat('PRO-',b.itbh_created_doc_id,'-',sio.sio_id) and b.itbs_id=sio.itbs_id and b.branch_id=@br "
                + "inner join tbl_item_pro_master pm on pm.itpm_id=b.itbh_created_doc_id "
                + "inner join tbl_item_pro_items pi on pi.itpm_id=pm.itpm_id and pi.itbh_id=b.itbh_id and pi.itpi_inputoutput=2 "
                + "where sio.smo_id=@o group by b.itbh_id) j) pr,"
                + "(select count(*) as total,ifnull(sum(p.pm_id is not null and p.pm_status<>@pc),0) as done,ifnull(sum(p.pm_id is not null and p.pm_status=@pc),0) as cancelled from "
                + "(select s.sm_id,(select ifnull(min(q.pm_id),0) from tbl_purchase_master q where q.sm_id=s.sm_id or (q.pm_ref_no=s.sm_id "
                + "and q.vn_id=(select x.vn_id from tbl_branch x where x.branch_id=s.branch_id) and q.branch_id=(select min(y.branch_id) from tbl_branch y where y.cust_id=s.cust_id))) as pm_pick "
                + "from tbl_sales_master s where s.sm_refid=@o and s.sm_is_inter_stock_transfer_invoice=1) t "
                + "left join tbl_purchase_master p on p.pm_id=t.pm_pick) tr", o);
            if (c == null || c.Rows.Count == 0)
                throw new InvalidOperationException("Overview counts could not be read.");
            DataRow r = c.Rows[0];
            result.invoiceTotal = I(r["inv_total"]);
            result.invoiceDelivered = I(r["inv_delivered"]);
            result.invoicePending = Math.Max(0, result.invoiceTotal - result.invoiceDelivered);
            result.productionTotal = I(r["pr_total"]);
            result.productionCompleted = I(r["pr_done"]);
            result.productionPending = Math.Max(0, result.productionTotal - result.productionCompleted);
            result.transferTotal = I(r["tr_total"]);
            result.transferCompleted = I(r["tr_done"]);
            result.transferCancelled = I(r["tr_cancelled"]);
            result.transferPending = Math.Max(0, result.transferTotal - result.transferCompleted - result.transferCancelled);

            // Ordered, invoiced, delivered, reserved and produced quantities per order line. Each aggregate is a derived table restricted to this
            // order, so it is computed once for the order and an invoice line is counted once however many invoices exist.
            string validInvoiceItems = "from tbl_sales_items si inner join tbl_sales_master sm on sm.sm_id=si.sm_id "
                + "where sm.sm_refid=@o and sm.sm_is_inter_stock_transfer_invoice=0 and " + SalesOrderStatus.ValidInvoiceSql;
            DataTable lines = db.SelectQuery("select sio.sio_id,sio.tum_id,sio.sio_finalqty,m.itm_type,m.itsv_uom_purchase,m.itsv_uom_sales,"
                + "(m.itsv_bom_enabled=1 and exists(select 1 from tbl_item_master_bom bom where bom.itm_id_output=sio.itm_id and bom.itmbi_type=1)) as has_bom,"
                + "ifnull(i.q,0) as invoiced,ifnull(d.q,0) as delivered,ifnull(rs.q,0) as reserved_batch,ifnull(pr.q,0) as produced_batch "
                + "from tbl_sales_items_order sio left join tbl_item_master m on m.itm_id=sio.itm_id "
                + "left join (select si.sio_id,sum(si.si_qty) as q " + validInvoiceItems + " group by si.sio_id) i on i.sio_id=sio.sio_id "
                + "left join (select si.sio_id,sum(si.si_qty) as q " + validInvoiceItems
                + " and sm.sm_delivery_status=" + SalesOrderStatus.InvoiceDelivered + " group by si.sio_id) d on d.sio_id=sio.sio_id "
                + "left join (select r.sio_id,sum(r.itbsr_qty) as q from tbl_item_batchstock_reserve r "
                + "inner join tbl_sales_items_order s2 on s2.sio_id=r.sio_id and s2.smo_id=@o "
                + "inner join tbl_item_batch b on b.itbh_id=r.itbh_id inner join tbl_itembranch_stock bs on bs.itbs_id=b.itbs_id and bs.itm_id=s2.itm_id "
                + "where r.itbsr_qty>0 group by r.sio_id) rs on rs.sio_id=sio.sio_id "
                + "left join (select x.sio_id,sum(x.q) as q from (select sp.sio_id,b.itbh_id,max(pi.itpi_quantity) as q from tbl_sales_items_order sp "
                + "inner join tbl_item_batch b on b.itbh_custbatchid=concat('PRO-',b.itbh_created_doc_id,'-',sp.sio_id) and b.itbs_id=sp.itbs_id and b.branch_id=@br "
                + "inner join tbl_item_pro_master pm on pm.itpm_id=b.itbh_created_doc_id "
                + "inner join tbl_item_pro_items pi on pi.itpm_id=pm.itpm_id and pi.itbh_id=b.itbh_id and pi.itpi_inputoutput=2 "
                + "where sp.smo_id=@o group by sp.sio_id,b.itbh_id) x group by x.sio_id) pr on pr.sio_id=sio.sio_id "
                + "where sio.smo_id=@o", CloneParameters(o));

            Snapshot uoms = LoadUomSnapshot(db, false);
            decimal ordered = 0m, delivered = 0m, reservable = 0m, reserved = 0m, reservedActual = 0m;
            var overview = new List<OverviewLine>();
            foreach (DataRow l in lines.Rows)
            {
                decimal qty = D(l["sio_finalqty"]);
                if (qty <= 0m)
                    continue;
                var line = new OverviewLine
                {
                    Ordered = qty,
                    Invoiced = D(l["invoiced"]),
                    Delivered = D(l["delivered"]),
                    IsStockItem = I(l["itm_type"]) == 1,
                    HasBom = I(l["has_bom"]) == 1
                };
                ordered += qty;
                delivered += Math.Min(Math.Max(0m, line.Delivered), qty);

                if (line.IsStockItem)
                {
                    reservable += qty;
                    int lineTum = I(l["tum_id"]), salesTum = I(l["itsv_uom_sales"]), purchaseTum = I(l["itsv_uom_purchase"]);
                    decimal? lineToSales = Conv(uoms, 1m, lineTum > 0 ? lineTum : salesTum, salesTum);
                    decimal? f = Conv(uoms, 1m, purchaseTum > 0 ? purchaseTum : salesTum, salesTum);
                    if (salesTum > 0 && lineToSales.HasValue && f.HasValue && lineToSales.Value > 0 && f.Value > 0)
                    {
                        // batch UOM -> line UOM, the same conversion the invoice screen uses
                        decimal toLine = f.Value / lineToSales.Value;
                        line.Reserved = Math.Max(0m, D(l["reserved_batch"]) * toLine);
                        line.Produced = Math.Max(0m, D(l["produced_batch"]) * toLine);
                        reservedActual += line.Reserved;
                        reserved += Math.Min(line.Reserved, qty);
                    }
                }
                overview.Add(line);
            }

            result.orderedQty = Round6(ordered);
            result.deliveredQty = Round6(delivered);
            result.deliveryPct = Percent(delivered, ordered);
            result.overallPct = OverallPercent(overview);
            result.reservableQty = Round6(reservable);
            result.reservedQty = Round6(reserved);
            result.reservedActualQty = Round6(reservedActual);
            result.unreservedQty = Round6(Math.Max(0m, reservable - reserved));
            result.reservedPct = Percent(reserved, reservable);
            result.ok = true;
        }
        catch (Exception ex)
        {
            new LogClass("salesorderstockerror").write(ex);
            result.ok = false;
            result.message = "Unable to load the overview.";
        }
        finally
        {
            Close(db);
        }
        return result;
    }

    // SelectQuery detaches its parameters after use, but a fresh copy keeps the second query independent of the first.
    static MySqlParameter[] CloneParameters(MySqlParameter[] source)
    {
        return source.Select(p => new MySqlParameter(p.ParameterName, p.Value)).ToArray();
    }

    // Percentage rounded down to one decimal so that 99.96% is never shown as 100%; 100 only when nothing (beyond rounding) is left.
    static decimal Percent(decimal part, decimal whole)
    {
        if (whole <= 0m)
            return 0m;
        if (whole - part < 0.0005m)
            return 100m;
        decimal pct = Math.Max(0m, part) * 100m / whole;
        return Math.Floor(pct * 10m) / 10m;
    }
}
