using commonfunction;
using MySql.Data.MySqlClient;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Data;

// Invokes sp_save_production_entry and nothing else writes production records.
// Database access is kept out of the UI; callers pass a ProductionEntryRequest and receive a ProductionEntryResult.
public static class ProductionService
{
    const string ProcedureName = "sp_save_production_entry";
    const decimal MaxOutputQty = 9999.999999m;

    // One in-flight production call per sales order inside this process; the procedure also locks the order row.
    static readonly ConcurrentDictionary<int, bool> InFlight = new ConcurrentDictionary<int, bool>();

    // Rows of the order line's reservations that sp_save_production_entry may consume, flagged when the reserved
    // batch belongs to a BOM component of the line item (tbl_item_master_bom, itmbi_type = 1).
    public static ProductionPayloadContext LoadPayloadContext(int smoId, int sioId)
    {
        var ctx = new ProductionPayloadContext { SmoId = smoId, SioId = sioId };
        if (smoId <= 0 || sioId <= 0)
        {
            ctx.Message = "Invalid sales order or order item.";
            return ctx;
        }
        var db = new mySqlConnection();
        DataTable head = db.SelectQuery("select smo.branch_id,smo.smo_invoice_no,oi.itm_id from tbl_sales_master_order smo "
            + "inner join tbl_sales_items_order oi on oi.smo_id=smo.smo_id where smo.smo_id=@o and oi.sio_id=@s",
            new MySqlParameter[] { new MySqlParameter("@o", smoId), new MySqlParameter("@s", sioId) });
        if (head == null || head.Rows.Count == 0)
        {
            ctx.Message = "The order item does not belong to this sales order.";
            return ctx;
        }
        ctx.BranchId = Int(head.Rows[0]["branch_id"]);
        ctx.OrderStatus = SalesOrderStatus.Read(smoId);
        ctx.DocNo = DocNoFor(smoId, Str(head.Rows[0]["smo_invoice_no"]));
        int lineItem = Int(head.Rows[0]["itm_id"]);

        ctx.ProductionExists = EntryExists(ctx.DocNo);

        DataTable rows = db.SelectQuery("select r.itbsr_id,r.sio_id,r.itbh_id,r.itbsr_qty,b.itbh_no,b.itbh_cost,b.itm_id,b.branch_id as batch_branch,tb.branch_name,m.itm_code,m.itm_name,"
            + "exists(select 1 from tbl_item_master_bom bom where bom.itm_id_output=@li and bom.itm_id_input=b.itm_id and bom.itmbi_type=1) as is_bom "
            + "from tbl_item_batchstock_reserve r inner join tbl_item_batch b on b.itbh_id=r.itbh_id "
            + "left join tbl_branch tb on tb.branch_id=b.branch_id "
            + "left join tbl_item_master m on m.itm_id=b.itm_id where r.sio_id=@s and r.itbsr_qty>0 order by r.itbrs_priority desc,r.itbsr_id",
            new MySqlParameter[] { new MySqlParameter("@li", lineItem), new MySqlParameter("@s", sioId) });
        foreach (DataRow r in rows.Rows)
            ctx.Inputs.Add(new ProductionInputReservation
            {
                ReservationId = Int(r["itbsr_id"]),
                SioId = Int(r["sio_id"]),
                BatchId = Int(r["itbh_id"]),
                BatchNo = Str(r["itbh_no"]),
                BatchBranchId = Int(r["batch_branch"]),
                Warehouse = Str(r["branch_name"]),
                ItemId = Int(r["itm_id"]),
                ItemCode = Str(r["itm_code"]),
                ItemName = Str(r["itm_name"]),
                Quantity = Dec(r["itbsr_qty"]),
                BatchCost = Dec(r["itbh_cost"]),
                IsBomComponent = Int(r["is_bom"]) == 1
            });
        ctx.Ok = true;
        return ctx;
    }

    public static ProductionEntryResult SaveProductionEntry(ProductionEntryRequest request)
    {
        string invalid = Validate(request);
        if (invalid != null)
            return Fail(0, invalid);

        if (!InFlight.TryAdd(request.SmoId, true))
            return Fail(0, "A production entry for this sales order is already being saved. Please wait.");
        try
        {
            string denied = CheckOwnership(request);
            if (denied != null)
                return Fail(0, denied);
            return Execute(request);
        }
        catch (Exception ex)
        {
            Log(ex);
            return Fail(0, "The production entry could not be saved. No changes were made. Please try again.");
        }
        finally
        {
            bool removed;
            InFlight.TryRemove(request.SmoId, out removed);
        }
    }

    static string Validate(ProductionEntryRequest r)
    {
        if (r == null)
            return "The production request is missing.";
        if (r.SmoId <= 0 || r.SioId <= 0)
            return "The sales order and order item are required.";
        if (r.ReservationId <= 0)
            return "Select the reserved raw material to produce from.";
        if (r.UserId <= 0)
            return "The production user is required.";
        if (r.OutputQty <= 0)
            return "Enter a production quantity greater than zero.";
        if (r.OutputQty > MaxOutputQty || Math.Round(r.OutputQty, 6) != r.OutputQty)
            return "The production quantity must be at most 9999.999999 with up to 6 decimals.";
        return null;
    }

    // The procedure checks that the reservation belongs to a valid order but not to the order being worked on,
    // and does not check the BOM, so both are verified here before the call.
    static string CheckOwnership(ProductionEntryRequest r)
    {
        ProductionPayloadContext ctx = LoadPayloadContext(r.SmoId, r.SioId);
        if (!ctx.Ok)
            return ctx.Message;
        if (!SalesOrderStatus.CanReserve(ctx.OrderStatus))
            return "Production cannot be entered unless the sales order is Approved or Processed.";
        if (ctx.ProductionExists)
            return "A production entry already exists for this sales order (" + ctx.DocNo + ").";
        foreach (ProductionInputReservation i in ctx.Inputs)
        {
            if (i.ReservationId != r.ReservationId)
                continue;
            return i.IsBomComponent ? null : "The selected reservation is not a BOM component of this order item.";
        }
        return "The selected reservation does not belong to this order item.";
    }

    static ProductionEntryResult Execute(ProductionEntryRequest r)
    {
        using (var con = new MySqlConnection(System.Configuration.ConfigurationManager.AppSettings["db_connect_mysql"]))
        using (var cmd = new MySqlCommand(ProcedureName, con))
        {
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.Add(new MySqlParameter("p_itbsr_id", MySqlDbType.Int32) { Value = r.ReservationId });
            cmd.Parameters.Add(new MySqlParameter("p_output_qty", MySqlDbType.Decimal) { Value = r.OutputQty });
            cmd.Parameters.Add(new MySqlParameter("p_user_id", MySqlDbType.Int32) { Value = r.UserId });
            cmd.Parameters.Add(new MySqlParameter("p_itpm_id", MySqlDbType.Int32) { Direction = ParameterDirection.Output });
            cmd.Parameters.Add(new MySqlParameter("p_result", MySqlDbType.LongText) { Direction = ParameterDirection.Output });
            // The procedure commits internally, so it is deliberately not wrapped in a caller transaction.
            con.Open();
            cmd.ExecuteNonQuery();
            object res = cmd.Parameters["p_result"].Value;
            object id = cmd.Parameters["p_itpm_id"].Value;
            return Parse(res == null || res == DBNull.Value ? null : Convert.ToString(res),
                id == null || id == DBNull.Value ? 0 : Convert.ToInt32(id));
        }
    }

    // p_result is the only authoritative outcome: the procedure's exit handler swallows errors and reports them there.
    static ProductionEntryResult Parse(string json, int itpmId)
    {
        if (string.IsNullOrEmpty(json))
            return Fail(0, "The production entry could not be saved.");
        JObject o = JObject.Parse(json);
        var result = new ProductionEntryResult
        {
            Success = o["success"] != null && (bool)o["success"],
            ErrorCode = Tok(o, "error_code"),
            SqlState = Convert.ToString((object)o["sql_state"]),
            Message = Convert.ToString((object)o["message"]),
            ItpmId = Tok(o, "itpm_id") > 0 ? Tok(o, "itpm_id") : itpmId,
            SmoId = Tok(o, "smo_id"),
            ReservationId = Tok(o, "itbsr_id"),
            OutputBatchId = Tok(o, "output_itbh_id"),
            OutputReservationId = Tok(o, "output_itbsr_id"),
            DocNo = Convert.ToString((object)o["doc_no"]),
            InputCount = Tok(o, "input_count")
        };
        if (o["output_qty"] != null && o["output_qty"].Type != JTokenType.Null)
            result.OutputQty = (decimal)o["output_qty"];
        if (!result.Success)
        {
            // Custom 3000x errors are written for users; anything else is a database error that must not be shown.
            if (result.ErrorCode < 30001 || result.ErrorCode > 30009)
            {
                result.Detail = result.Message;
                Log(new Exception(json));
                // 1267 is the collation conflict that currently makes the procedure fail (see production_workflow_reference.md).
                result.Message = result.ErrorCode == 1267
                    ? "The production procedure failed because of a database collation error (sp_save_production_entry). No changes were made. Please contact the administrator."
                    : "The production entry could not be saved. No changes were made.";
            }
            result.ItpmId = 0;
        }
        return result;
    }

    public static bool EntryExists(string docNo)
    {
        return Str(new mySqlConnection().SelectScalar("select count(*) from tbl_item_pro_master where itpm_doc_no=@d",
            new MySqlParameter[] { new MySqlParameter("@d", docNo) })) != "0";
    }

    public static string DocNoFor(int smoId, string invoiceNo)
    {
        return string.IsNullOrEmpty(invoiceNo) ? "SO-" + smoId : invoiceNo;
    }

    static ProductionEntryResult Fail(int code, string message)
    {
        return new ProductionEntryResult { Success = false, ErrorCode = code, Message = message };
    }

    static void Log(Exception ex)
    {
        try { new LogClass("productionerror").write(ex); }
        catch (Exception) { }
    }

    static int Tok(JObject o, string name)
    {
        JToken t = o[name];
        return t == null || t.Type == JTokenType.Null ? 0 : (int)t;
    }

    static int Int(object o) { return o == null || o == DBNull.Value ? 0 : Convert.ToInt32(o); }
    static decimal Dec(object o) { return o == null || o == DBNull.Value ? 0m : Convert.ToDecimal(o); }
    static string Str(object o) { return o == null || o == DBNull.Value ? "" : Convert.ToString(o); }
}
