using commonfunction;
using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;

// Batch stock of a sales order invoice (tbl_sales_master.sm_refid > 0, not an inter-stock transfer) when the invoice is cancelled, rejected or brought back.
// SalesOrderStock.CreateInvoice writes one tbl_stock_transactions row per batch (action_type = SALES, itbh_id, dr_qty in the batch UOM, narration 'Sold ...').
// Cancelling credits the net quantity of every batch back to tbl_item_batch.itbh_currentqty (and tbl_itembranch_stock.itbs_stock, in the same batch UOM)
// with a cr_qty ledger row; bringing a rejected invoice back debits the same quantity again with a dr_qty row. Reservations are not recreated.
// All methods run inside the caller's open transaction.
public static class InvoiceBatchStock
{
    const int SalesAction = (int)Constants.ActionType.SALES;
    const decimal Epsilon = 0.0000005m;

    sealed class BatchRow
    {
        public int BatchId, ItbsId, BranchId;
        public string BatchNo;
        public decimal Dr, Cr, Reactivated, Cost;
    }

    static decimal D(object o) { return o == null || o == DBNull.Value ? 0m : Convert.ToDecimal(o, CultureInfo.InvariantCulture); }
    static int I(object o) { return o == null || o == DBNull.Value ? 0 : Convert.ToInt32(o, CultureInfo.InvariantCulture); }

    static List<BatchRow> Load(mySqlConnection db, int smId)
    {
        var rows = new List<BatchRow>();
        DataTable dt = db.SelectQueryForTransaction("select st.itbh_id,max(st.itbs_id) as itbs_id,max(st.branch_id) as branch_id,max(b.itbh_no) as itbh_no,max(st.Cost) as cost,"
            + "ifnull(sum(st.dr_qty),0) as dr,ifnull(sum(st.cr_qty),0) as cr,"
            + "ifnull(sum(case when st.narration like 'Sold %' then 0 else st.dr_qty end),0) as redr "
            + "from tbl_stock_transactions st inner join tbl_sales_master sm on sm.sm_id=st.action_ref_id "
            + "inner join tbl_item_batch b on b.itbh_id=st.itbh_id "
            + "where st.action_type=@a and st.action_ref_id=@s and st.itbh_id>0 and ifnull(sm.sm_refid,0)>0 and ifnull(sm.sm_is_inter_stock_transfer_invoice,0)=0 "
            + "group by st.itbh_id order by st.itbh_id",
            new MySqlParameter[] { new MySqlParameter("@a", SalesAction), new MySqlParameter("@s", smId) });
        foreach (DataRow r in dt.Rows)
            rows.Add(new BatchRow
            {
                BatchId = I(r["itbh_id"]), ItbsId = I(r["itbs_id"]), BranchId = I(r["branch_id"]), BatchNo = Convert.ToString(r["itbh_no"]),
                Cost = D(r["cost"]), Dr = D(r["dr"]), Cr = D(r["cr"]), Reactivated = D(r["redr"])
            });
        return rows;
    }

    static int Exec(mySqlConnection db, string sql, params MySqlParameter[] ps)
    {
        db.ExecuteQueryForTransaction(sql, ps);
        return Convert.ToInt32(db.SelectScalarForTransaction("select row_count()"));
    }

    static void Ledger(mySqlConnection db, BatchRow r, int smId, int userId, string date, string narration, decimal dr, decimal cr)
    {
        if (narration.Length > 150)
            narration = narration.Substring(0, 150);
        db.ExecuteQueryForTransaction("insert into tbl_stock_transactions (itbs_id,action_type,action_ref_id,user_id,narration,dr_qty,cr_qty,closing_stock,date,is_reconciliation,Cost,itbh_id,branch_id) "
            + "values (@i,@a,@r,@u,@n,@dr,@cr,(select itbs_stock from tbl_itembranch_stock where itbs_id=@i),@t,0,@c,@b,@br)",
            new MySqlParameter[] { new MySqlParameter("@i", r.ItbsId), new MySqlParameter("@a", SalesAction), new MySqlParameter("@r", smId),
                new MySqlParameter("@u", userId), new MySqlParameter("@n", narration), new MySqlParameter("@dr", dr), new MySqlParameter("@cr", cr),
                new MySqlParameter("@t", date), new MySqlParameter("@c", r.Cost), new MySqlParameter("@b", r.BatchId), new MySqlParameter("@br", r.BranchId) });
    }

    // Credits the quantity the invoice still holds on every batch back. Returns the number of batches credited (0: not a batch invoice, or nothing to credit).
    public static int Restore(mySqlConnection db, int smId, int userId, string date, string reason)
    {
        int count = 0;
        foreach (BatchRow r in Load(db, smId))
        {
            decimal net = Math.Round(r.Dr - r.Cr, 6);
            if (net <= Epsilon)
                continue;
            if (Exec(db, "update tbl_item_batch set itbh_currentqty=itbh_currentqty+@q where itbh_id=@b",
                new MySqlParameter("@q", net), new MySqlParameter("@b", r.BatchId)) != 1)
                throw new InvalidOperationException("Batch " + r.BatchNo + " could not be updated.");
            db.ExecuteQueryForTransaction("update tbl_itembranch_stock set itbs_stock=coalesce(itbs_stock,0)+@d,itm_last_update_date=@t where itbs_id=@i",
                new MySqlParameter[] { new MySqlParameter("@d", net), new MySqlParameter("@t", date), new MySqlParameter("@i", r.ItbsId) });
            Ledger(db, r, smId, userId, date, "Credited " + net.ToString("0.######", CultureInfo.InvariantCulture) + " back to batch " + r.BatchNo + " of order #" + smId + ": " + reason, 0m, net);
            count++;
        }
        return count;
    }

    // Takes back what Restore credited (a rejected invoice that is made active again). Returns the number of batches debited (0: nothing was credited to batches).
    // Throws InvalidOperationException when a batch no longer holds the quantity.
    public static int Reapply(mySqlConnection db, int smId, int userId, string date, string reason)
    {
        int count = 0;
        foreach (BatchRow r in Load(db, smId))
        {
            decimal amount = Math.Round(r.Cr - r.Reactivated, 6);
            if (amount <= Epsilon)
                continue;
            if (Exec(db, "update tbl_item_batch set itbh_currentqty=itbh_currentqty-@q where itbh_id=@b and itbh_currentqty>=@q",
                new MySqlParameter("@q", amount), new MySqlParameter("@b", r.BatchId)) != 1)
                throw new InvalidOperationException("Batch " + r.BatchNo + " no longer has " + amount.ToString("0.######", CultureInfo.InvariantCulture) + " in stock, so this invoice cannot be made active again.");
            db.ExecuteQueryForTransaction("update tbl_itembranch_stock set itbs_stock=coalesce(itbs_stock,0)-@d,itm_last_update_date=@t where itbs_id=@i",
                new MySqlParameter[] { new MySqlParameter("@d", amount), new MySqlParameter("@t", date), new MySqlParameter("@i", r.ItbsId) });
            Ledger(db, r, smId, userId, date, "Debited " + amount.ToString("0.######", CultureInfo.InvariantCulture) + " from batch " + r.BatchNo + " of order #" + smId + ": " + reason, amount, 0m);
            count++;
        }
        return count;
    }
}
