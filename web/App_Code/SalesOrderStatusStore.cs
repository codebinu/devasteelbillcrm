using commonfunction;
using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Data;

// Stored-data side of the sales order status model (rules are in SalesOrderStatus.cs).
//
//   UpdateSalesOrderStatus(smoId)           automatic calculation: the single place that derives Approved / Processed / Partially Delivered /
//                                           Fully Delivered from the current valid reservations, invoices and deliveries.
//   ChangeSalesOrderStatus(smoId, ...)      manual transitions: Approve, Put On Hold, Cancel (customer / company).
//
// Concurrency: every flow that changes reservations, invoices or the status takes the order row lock (select ... for update) before
// its first ordinary read, so the quantities read here are never older than the last committed change of another order operation.
// The status update is guarded by the status that was read under that lock, so a concurrent hold or cancel cannot be overwritten.
public static partial class SalesOrderStatus
{
    const int MySqlDeadlock = 1213;

    static int Int(object value)
    {
        int v;
        return value != null && value != DBNull.Value && int.TryParse(Convert.ToString(value), out v) ? v : 0;
    }

    static decimal Dec(object value)
    {
        decimal v;
        return value != null && value != DBNull.Value && decimal.TryParse(Convert.ToString(value), out v) ? v : 0m;
    }

    static DataTable Query(mySqlConnection db, bool tx, string sql, int smoId)
    {
        var ps = new MySqlParameter[] { new MySqlParameter("@o", smoId) };
        return tx ? db.SelectQueryForTransaction(sql, ps) : db.SelectQuery(sql, ps);
    }

    static int Count(mySqlConnection db, bool tx, string sql, int smoId)
    {
        DataTable dt = Query(db, tx, sql, smoId);
        return dt != null && dt.Rows.Count > 0 ? Int(dt.Rows[0][0]) : 0;
    }

    // Locks the order row for the rest of the transaction and returns its current status (-1 when the order does not exist).
    public static int LockStatus(mySqlConnection db, int smoId)
    {
        string value = db.SelectScalarForTransaction("select smo_delivery_status from tbl_sales_master_order where smo_id=@o for update",
            new MySqlParameter[] { new MySqlParameter("@o", smoId) });
        int status;
        return int.TryParse(value, out status) ? status : -1;
    }

    // Current status outside a transaction (-1 when missing).
    public static int Read(int smoId)
    {
        string value = new mySqlConnection().SelectScalar("select smo_delivery_status from tbl_sales_master_order where smo_id=@o",
            new MySqlParameter[] { new MySqlParameter("@o", smoId) });
        int status;
        return int.TryParse(value, out status) ? status : -1;
    }

    // Quantities come from the invoices of the order (sm_refid = smo_id, not inter-stock transfers) that are neither cancelled nor
    // rejected; delivered quantity is the part of those on delivered invoices. Every order line is counted once, so several invoices,
    // partial invoicing and partial deliveries add up without double counting. The invoice totals are grouped once for the order
    // instead of being looked up per order line.
    static List<LineQuantity> ReadLines(mySqlConnection db, bool tx, int smoId)
    {
        string grouped = "(select si.sio_id,sum(si.si_qty) as q from tbl_sales_items si inner join tbl_sales_master sm on sm.sm_id=si.sm_id "
            + "where sm.sm_refid=@o and sm.sm_is_inter_stock_transfer_invoice=0 and " + ValidInvoiceSql;
        DataTable dt = Query(db, tx, "select sio.sio_finalqty as ordered,ifnull(i.q,0) as invoiced,ifnull(d.q,0) as delivered "
            + "from tbl_sales_items_order sio "
            + "left join " + grouped + " group by si.sio_id) i on i.sio_id=sio.sio_id "
            + "left join " + grouped + " and sm.sm_delivery_status=" + InvoiceDelivered + " group by si.sio_id) d on d.sio_id=sio.sio_id "
            + "where sio.smo_id=@o", smoId);
        var lines = new List<LineQuantity>();
        foreach (DataRow r in dt.Rows)
            lines.Add(new LineQuantity { Ordered = Dec(r["ordered"]), Invoiced = Dec(r["invoiced"]), Delivered = Dec(r["delivered"]) });
        return lines;
    }

    // The status the order should have right now according to its current valid records.
    static int Evaluate(mySqlConnection db, bool tx, int smoId, int current)
    {
        if (!IsOperational(current))
            return current;
        // One query for every invoice linked to the order, whatever its status: it gives the delivered flag and tells whether any exists.
        DataTable inv = Query(db, tx, "select count(*) as any_invoice,ifnull(sum(sm.sm_delivery_status=" + InvoiceDelivered + "),0) as delivered "
            + "from tbl_sales_master sm where sm.sm_refid=@o and sm.sm_is_inter_stock_transfer_invoice=0", smoId);
        bool anyInvoice = inv.Rows.Count > 0 && Int(inv.Rows[0]["any_invoice"]) > 0;
        bool delivered = anyInvoice && Int(inv.Rows[0]["delivered"]) > 0;

        // A delivered order with no linked invoice at all (cancelled ones count as linked) was delivered before invoices were linked to
        // orders; there is nothing to recalculate it from, so it keeps its status.
        if ((current == PartiallyDelivered || current == FullyDelivered) && !anyInvoice)
            return current;

        // Without any invoice nothing can be delivered, so the quantity lookup is skipped.
        List<LineQuantity> lines = anyInvoice ? ReadLines(db, tx, smoId) : new List<LineQuantity>();
        bool reserved = Count(db, tx, "select count(*) from tbl_item_batchstock_reserve r inner join tbl_sales_items_order sio on sio.sio_id=r.sio_id "
            + "where sio.smo_id=@o and r.itbsr_qty>0", smoId) > 0;
        return Calculate(current, lines, delivered, reserved);
    }

    // Recalculates inside the caller's open transaction, after the caller's own change succeeded. Locks the order row, recalculates from
    // the current records and writes only when the status changes. Returns the resulting status (-1 when the order does not exist).
    // A recalculated Processed or delivered status records the user and date like the earlier manual steps did (staffId 0 = no user known).
    public static int UpdateSalesOrderStatus(mySqlConnection db, int smoId, int staffId)
    {
        int current = LockStatus(db, smoId);
        if (current < 0)
            return -1;
        int next = Evaluate(db, true, smoId, current);
        if (next == current)
            return current;

        string set = "smo_delivery_status=@n";
        var ps = new List<MySqlParameter> { new MySqlParameter("@n", next), new MySqlParameter("@o", smoId), new MySqlParameter("@old", current) };
        bool delivered = next == PartiallyDelivered || next == FullyDelivered;
        bool wasDelivered = current == PartiallyDelivered || current == FullyDelivered;
        if (staffId > 0 && (next == Processed || (delivered && !wasDelivered)))
        {
            ps.Add(new MySqlParameter("@u", staffId));
            ps.Add(new MySqlParameter("@now", BranchClock.NowForSalesOrderInTransaction(db, smoId)));
            if (next == Processed)
                set += ",smo_processed_id=@u,smo_processed_date=@now";
            else
                set += ",smo_delivered_id=@u,smo_delivered_date=@now";
        }
        db.ExecuteQueryForTransaction("update tbl_sales_master_order set " + set + " where smo_id=@o and smo_delivery_status=@old", ps.ToArray());
        if (db.SelectScalarForTransaction("select row_count()") != "1")
            throw new InvalidOperationException("Sales order status update did not apply.");
        return next;
    }

    // For use inside a transaction: a recalculation that fails (other than by deadlock, which has already rolled the transaction back)
    // is logged and does not undo the main operation. The status is corrected by the next recalculation: any later reservation, invoice
    // or delivery change on the order, or opening the order (UpdateSalesOrderStatus(smoId)).
    public static void TryUpdateSalesOrderStatus(mySqlConnection db, int smoId, int staffId)
    {
        try
        {
            UpdateSalesOrderStatus(db, smoId, staffId);
        }
        catch (MySqlException ex)
        {
            if (ex.Number == MySqlDeadlock)
                throw;
            new LogClass("salesordererror").write(ex);
        }
        catch (Exception ex)
        {
            new LogClass("salesordererror").write(ex);
        }
    }

    public static int UpdateSalesOrderStatus(int smoId)
    {
        return UpdateSalesOrderStatus(smoId, 0);
    }

    // Standalone recalculation for operations that were already committed (stored procedures, legacy endpoints) and for self-healing when
    // an order is opened. An unchanged status is detected without taking the lock; otherwise it runs in its own transaction, retried once.
    // Returns the status afterwards, or -1 when the order is missing or the recalculation failed (logged).
    public static int UpdateSalesOrderStatus(int smoId, int staffId)
    {
        if (smoId <= 0)
            return -1;
        for (int attempt = 0; attempt < 2; attempt++)
        {
            var db = new mySqlConnection();
            bool started = false;
            try
            {
                string stored = db.SelectScalar("select smo_delivery_status from tbl_sales_master_order where smo_id=@o",
                    new MySqlParameter[] { new MySqlParameter("@o", smoId) });
                int current;
                if (!int.TryParse(stored, out current))
                    return -1;
                if (!IsOperational(current) || Evaluate(db, false, smoId, current) == current)
                    return current;

                db.BeginTransaction();
                started = true;
                int result = UpdateSalesOrderStatus(db, smoId, staffId);
                db.CommitTransaction();
                started = false;
                return result;
            }
            catch (Exception ex)
            {
                if (started)
                {
                    try { db.RollBackTransaction(); }
                    catch (Exception) { }
                }
                new LogClass("salesordererror").write(ex);
            }
            finally
            {
                try { db.CloseConnection(); }
                catch (Exception) { }
            }
        }
        return -1;
    }

    // Sales order an invoice belongs to (tbl_sales_master.sm_refid), 0 for a normal bill.
    public static int OrderOfInvoice(mySqlConnection db, bool tx, int smId)
    {
        var ps = new MySqlParameter[] { new MySqlParameter("@s", smId) };
        string sql = "select ifnull(sm_refid,0) from tbl_sales_master where sm_id=@s and sm_is_inter_stock_transfer_invoice=0";
        string value = tx ? db.SelectScalarForTransaction(sql, ps) : db.SelectScalar(sql, ps);
        int smoId;
        return int.TryParse(value, out smoId) && smoId > 0 ? smoId : 0;
    }

    // A cancelled or rejected invoice must not come back (New, Processed, Delivered, ...) when that would put the order over its limits:
    // the quantities of its lines plus those of the other valid invoices must stay within the ordered quantity of every order line, and the
    // sales order must not be cancelled. Returns null when the invoice may be reactivated, otherwise the reason. Call inside the transaction
    // that reactivates it, after the order row is locked, so no other invoice can be created in between.
    public static string InvoiceReactivationBlock(mySqlConnection db, bool tx, int smId)
    {
        int smoId = OrderOfInvoice(db, tx, smId);
        if (smoId <= 0)
            return null;
        // parameters are created per query: the transactional helpers leave them attached to their command
        Func<MySqlParameter[]> ps = delegate { return new MySqlParameter[] { new MySqlParameter("@o", smoId), new MySqlParameter("@s", smId) }; };
        string statusSql = "select smo_delivery_status from tbl_sales_master_order where smo_id=@o";
        string stored = tx ? db.SelectScalarForTransaction(statusSql, ps()) : db.SelectScalar(statusSql, ps());
        int status;
        if (int.TryParse(stored, out status) && IsCancelled(status))
            return "Sales order #" + smoId + " is cancelled, so this invoice cannot be reactivated.";

        string sql = "select sio.itm_name,sio.sio_finalqty as ordered,ifnull(o.q,0) as others,t.q as mine from tbl_sales_items_order sio "
            + "inner join (select si.sio_id,sum(si.si_qty) as q from tbl_sales_items si where si.sm_id=@s group by si.sio_id) t on t.sio_id=sio.sio_id "
            + "left join (select si.sio_id,sum(si.si_qty) as q from tbl_sales_items si inner join tbl_sales_master sm on sm.sm_id=si.sm_id "
            + "where sm.sm_refid=@o and sm.sm_is_inter_stock_transfer_invoice=0 and " + ValidInvoiceSql + " and sm.sm_id<>@s group by si.sio_id) o on o.sio_id=sio.sio_id "
            + "where sio.smo_id=@o";
        DataTable dt = tx ? db.SelectQueryForTransaction(sql, ps()) : db.SelectQuery(sql, ps());
        foreach (DataRow r in dt.Rows)
        {
            decimal ordered = Dec(r["ordered"]), others = Dec(r["others"]), mine = Dec(r["mine"]);
            if (others + mine > ordered + QtyTolerance)
                return "Cannot reactivate this invoice: " + Convert.ToString(r["itm_name"]) + " would be invoiced " + (others + mine).ToString("0.###")
                    + " against " + ordered.ToString("0.###") + " ordered in sales order #" + smoId + " (only " + Math.Max(0m, ordered - others).ToString("0.###")
                    + " can still be invoiced).";
        }
        return null;
    }

    // Same check for the legacy endpoints that change an invoice status outside a transaction of their own: applies only when the invoice
    // is cancelled (4) or rejected (5) now and the requested status is not. Returns the reason, or null when the change may go ahead.
    public static string InvoiceReactivationBlock(string smId, string newStatus)
    {
        int id;
        if (!int.TryParse(smId, out id) || id <= 0)
            return null;
        if (newStatus == InvoiceCancelled.ToString() || newStatus == InvoiceRejected.ToString())
            return null;
        try
        {
            var db = new mySqlConnection();
            string current = db.SelectScalar("select sm_delivery_status from tbl_sales_master where sm_id=@s", new MySqlParameter[] { new MySqlParameter("@s", id) });
            if (current != InvoiceCancelled.ToString() && current != InvoiceRejected.ToString())
                return null;
            return InvoiceReactivationBlock(db, false, id);
        }
        catch (Exception ex)
        {
            new LogClass("salesordererror").write(ex);
            return "The invoice could not be checked against its sales order. Please try again.";
        }
    }

    // An invoice was created, changed, delivered, reversed or cancelled inside the caller's open transaction: recalculate its order
    // (no-op for a bill that belongs to no order). Call after the change. Callers that change an existing invoice should first look the
    // order up with OrderOfInvoice before BeginTransaction and lock it with LockStatus as their first statement, so locks are always taken
    // order first, then invoice.
    public static void TryUpdateSalesOrderStatusForInvoice(mySqlConnection db, int smId, int staffId)
    {
        int smoId = OrderOfInvoice(db, true, smId);
        if (smoId > 0)
            TryUpdateSalesOrderStatus(db, smoId, staffId);
    }

    // Standalone variant for legacy endpoints that commit on their own: recalculates the order of the invoice if it has one. Never throws.
    public static void UpdateSalesOrderStatusForInvoice(string smId)
    {
        try
        {
            int id;
            if (!int.TryParse(smId, out id) || id <= 0)
                return;
            int smoId = OrderOfInvoice(new mySqlConnection(), false, id);
            if (smoId > 0)
                UpdateSalesOrderStatus(smoId, 0);
        }
        catch (Exception ex)
        {
            new LogClass("salesordererror").write(ex);
        }
    }

    // User-initiated status change (Approve, Put On Hold, Cancel by customer / company). The order row is locked and branch scoped, the
    // staff member must be allowed to change statuses, the transition is validated against the locked status and the update is guarded by
    // that status. Cancelling releases every reservation of the order in the same transaction so no stock stays allocated (invoices are
    // not touched); putting an order on hold never releases anything. Approving an On Hold order resumes it: the operational status
    // (Approved, Processed, Partially Delivered or Fully Delivered) is recalculated from its records instead of being set blindly.
    // Returns null on success, otherwise the reason.
    public static string ChangeSalesOrderStatus(int smoId, int staffId, int newStatus)
    {
        var db = new mySqlConnection();
        bool started = false;
        try
        {
            db.BeginTransaction();
            started = true;

            string scope = db.SelectScalarForTransaction("select smo_delivery_status from tbl_sales_master_order where smo_id=@o "
                + "and branch_id in (select branch_id from tbl_user_branches where user_id=@u) for update",
                new MySqlParameter[] { new MySqlParameter("@o", smoId), new MySqlParameter("@u", staffId) });
            int current;
            if (!int.TryParse(scope, out current))
            {
                db.RollBackTransaction();
                started = false;
                return "The sales order was not found.";
            }
            // A production entry being saved cannot be undone by a status change; the order row is locked here, so a save that has
            // started is seen, and a save that starts later waits for this change and reads the new status.
            if ((newStatus == OnHold || IsCancelled(newStatus)) && ProductionService.IsSaving(smoId))
            {
                db.RollBackTransaction();
                started = false;
                return "A production entry is being saved for this order. Try again in a moment.";
            }
            // Salesmen (user type 2) can view their orders but not change their status.
            string userType = db.SelectScalarForTransaction("select user_type from tbl_user_details where user_id=@u",
                new MySqlParameter[] { new MySqlParameter("@u", staffId) });
            if (userType == "2")
            {
                db.RollBackTransaction();
                started = false;
                return "You do not have permission to change the status of this order.";
            }
            if (!CanTransition(current, newStatus))
            {
                db.RollBackTransaction();
                started = false;
                return "The order is now " + Name(current) + " and cannot be changed to " + Name(newStatus) + ".";
            }

            // Dates are stored in the order branch's configured time zone, not the database server's clock.
            string set = "smo_delivery_status=@new";
            switch (newStatus)
            {
                case Approved: set += ",smo_approved_id=@u,smo_approved_date=@now"; break;
                case CancelledByCustomer:
                case CancelledByCompany: set += ",smo_cancelled_id=@u,smo_cancelled_date=@now"; break;
            }
            db.ExecuteQueryForTransaction("update tbl_sales_master_order set " + set
                + " where smo_id=@o and smo_delivery_status=@old",
                new MySqlParameter[] { new MySqlParameter("@new", newStatus), new MySqlParameter("@u", staffId),
                    new MySqlParameter("@o", smoId), new MySqlParameter("@old", current),
                    new MySqlParameter("@now", BranchClock.NowForSalesOrderInTransaction(db, smoId)) });
            if (db.SelectScalarForTransaction("select row_count()") != "1")
                throw new InvalidOperationException("Sales order status update did not apply.");

            if (IsCancelled(newStatus))
                db.ExecuteQueryForTransaction("delete r from tbl_item_batchstock_reserve r "
                    + "inner join tbl_sales_items_order sio on sio.sio_id=r.sio_id where sio.smo_id=@o",
                    new MySqlParameter[] { new MySqlParameter("@o", smoId) });
            else if (newStatus == Approved)
                TryUpdateSalesOrderStatus(db, smoId, staffId);

            db.CommitTransaction();
            started = false;
            return null;
        }
        catch (Exception ex)
        {
            if (started)
            {
                try { db.RollBackTransaction(); }
                catch (Exception) { }
            }
            new LogClass("salesordererror").write(ex);
            return "The status could not be changed. No changes were made.";
        }
        finally
        {
            try { db.CloseConnection(); }
            catch (Exception) { }
        }
    }
}
