using commonfunction;
using MySql.Data.MySqlClient;
using System;
using System.Data;

// Single definition of the sales order (tbl_sales_master_order.smo_delivery_status) statuses, labels and transitions.
// Existing database values are kept: 0 New, 1 Approved (previously labelled "Processed" and set by approval), 4 Pending
// (previously "To be Confirmed"), 5/6 Cancelled. Processed (first successful reservation) is the only new value, 7.
public static class SalesOrderStatus
{
    public const int New = 0;
    public const int Approved = 1;
    public const int FullyDelivered = 2;
    public const int PartiallyDelivered = 3;
    public const int Pending = 4;
    public const int CancelledByCustomer = 5;
    public const int CancelledByCompany = 6;
    public const int Processed = 7;

    // Last status value; used to validate list filters.
    public const int MaxValue = Processed;

    public static string Name(int status)
    {
        switch (status)
        {
            case New: return "New";
            case Approved: return "Approved";
            case FullyDelivered: return "Fully Delivered";
            case PartiallyDelivered: return "Partially Delivered";
            case Pending: return "Pending";
            case CancelledByCustomer: return "Customer Cancelled";
            case CancelledByCompany: return "Company Cancelled";
            case Processed: return "Processed";
            default: return "";
        }
    }

    public static string Css(int status)
    {
        switch (status)
        {
            case New: return "label label-warning";
            case Approved: return "label label-success";
            case FullyDelivered: return "label label-success";
            case PartiallyDelivered: return "label label-info";
            case Pending: return "label label-info";
            case Processed: return "label label-primary";
            case CancelledByCustomer:
            case CancelledByCompany: return "label label-default";
            default: return "label label-default";
        }
    }

    public static bool IsCancelled(int status) { return status == CancelledByCustomer || status == CancelledByCompany; }

    // Stock may be reserved, allocated or produced against the order only in these statuses.
    public static bool CanReserve(int status) { return status == Approved || status == Processed; }

    // Reservations may be released in every status except a delivered order.
    public static bool CanRelease(int status)
    {
        return status == New || status == Approved || status == Pending || status == Processed || IsCancelled(status);
    }

    public static bool CanApprove(int status) { return status == New || status == Pending; }
    public static bool CanHold(int status) { return status == New || status == Approved || status == Processed; }
    public static bool CanCancel(int status) { return status == New || status == Approved || status == Pending || status == Processed; }
    public static bool CanReopen(int status) { return IsCancelled(status); }

    public static bool CanTransition(int from, int to)
    {
        switch (to)
        {
            case Approved: return CanApprove(from);
            case Pending: return CanHold(from);
            case CancelledByCustomer:
            case CancelledByCompany: return CanCancel(from);
            case New: return CanReopen(from);
            case Processed: return from == Approved;
            default: return false;
        }
    }

    // Moves Approved to Processed inside the caller's open transaction. Call only after a new reservation row was inserted
    // in that same transaction. The order row must already be locked by LockStatus, so a concurrent hold or cancel cannot interleave.
    public static void MarkProcessedInTransaction(mySqlConnection db, int smoId, int staffId)
    {
        db.ExecuteQueryForTransaction("update tbl_sales_master_order set smo_delivery_status=@p,smo_processed_id=@u,smo_processed_date=now() "
            + "where smo_id=@o and smo_delivery_status=@a",
            new MySqlParameter[] { new MySqlParameter("@p", Processed), new MySqlParameter("@u", staffId),
                new MySqlParameter("@o", smoId), new MySqlParameter("@a", Approved) });
    }

    // Standalone variant for reservations committed outside our transaction (sp_save_production_entry). Failures are logged only,
    // because the reservation has already been committed and must still be reported to the user.
    public static void MarkProcessed(int smoId, int staffId)
    {
        var db = new mySqlConnection();
        try
        {
            db.ExecuteQuery("update tbl_sales_master_order set smo_delivery_status=@p,smo_processed_id=@u,smo_processed_date=now() "
                + "where smo_id=@o and smo_delivery_status=@a",
                new MySqlParameter[] { new MySqlParameter("@p", Processed), new MySqlParameter("@u", staffId),
                    new MySqlParameter("@o", smoId), new MySqlParameter("@a", Approved) });
        }
        catch (Exception ex)
        {
            new LogClass("salesordererror").write(ex);
        }
    }

    // Locks the order row for the rest of the transaction and returns its current status (-1 when the order does not exist).
    public static int LockStatus(mySqlConnection db, int smoId)
    {
        string value = db.SelectScalarForTransaction("select smo_delivery_status from tbl_sales_master_order where smo_id=@o for update",
            new MySqlParameter[] { new MySqlParameter("@o", smoId) });
        int status;
        return int.TryParse(value, out status) ? status : -1;
    }

    // Current status outside a transaction (-1 when missing); used by integrations that cannot join the reservation transaction.
    public static int Read(int smoId)
    {
        string value = new mySqlConnection().SelectScalar("select smo_delivery_status from tbl_sales_master_order where smo_id=@o",
            new MySqlParameter[] { new MySqlParameter("@o", smoId) });
        int status;
        return int.TryParse(value, out status) ? status : -1;
    }

    // Validated status change. The order row is locked, the transition is checked against the locked status, and the update is
    // guarded by the expected old status. Cancelling releases every reservation of the order in the same transaction so that no stock
    // stays allocated; holding an order never releases reservations. Returns null on success, otherwise the reason.
    public static string Change(int smoId, int staffId, int newStatus)
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
            if (!CanTransition(current, newStatus))
            {
                db.RollBackTransaction();
                started = false;
                return "The order is now " + Name(current) + " and cannot be changed to " + Name(newStatus) + ".";
            }

            string set = "smo_delivery_status=@new";
            switch (newStatus)
            {
                case Approved: set += ",smo_approved_id=@u,smo_approved_date=now()"; break;
                case CancelledByCustomer:
                case CancelledByCompany: set += ",smo_cancelled_id=@u,smo_cancelled_date=now()"; break;
                case New: set += ",smo_cancelled_id=null,smo_cancelled_date=null"; break;
            }
            db.ExecuteQueryForTransaction("update tbl_sales_master_order set " + set
                + " where smo_id=@o and smo_delivery_status=@old",
                new MySqlParameter[] { new MySqlParameter("@new", newStatus), new MySqlParameter("@u", staffId),
                    new MySqlParameter("@o", smoId), new MySqlParameter("@old", current) });
            if (db.SelectScalarForTransaction("select row_count()") != "1")
                throw new InvalidOperationException("Sales order status update did not apply.");

            if (IsCancelled(newStatus))
                db.ExecuteQueryForTransaction("delete r from tbl_item_batchstock_reserve r "
                    + "inner join tbl_sales_items_order sio on sio.sio_id=r.sio_id where sio.smo_id=@o",
                    new MySqlParameter[] { new MySqlParameter("@o", smoId) });

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
