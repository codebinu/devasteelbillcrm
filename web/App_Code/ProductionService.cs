using commonfunction;
using MySql.Data.MySqlClient;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Data;

// Invokes sp_save_production_entry1.1 and nothing else writes production records.
// Database access is kept out of the UI; callers pass a ProductionEntryRequest and receive a ProductionEntryResult.
public static class ProductionService
{
    // The backticks are required: Connector/NET otherwise splits the name at the "." in "1.0" as schema.procedure.
    const string ProcedureName = "`sp_save_production_entry1.1`";
    const decimal MaxOutputQty = 9999.999999m;

    // One in-flight production call per sales order inside this process; the procedure also locks the order row.
    static readonly ConcurrentDictionary<int, bool> InFlight = new ConcurrentDictionary<int, bool>();

    // Rows of the order line's reservations that sp_save_production_entry1.1 may consume, flagged when the reserved
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

    // True while a production entry for the order is being saved by this process. Hold and cancel are refused meanwhile, because the
    // procedure commits on its own connection and cannot take part in the status change's transaction.
    public static bool IsSaving(int smoId)
    {
        return InFlight.ContainsKey(smoId);
    }

    // The procedure checks that the reservation belongs to a valid order but not to the order being worked on,
    // and does not check the BOM, so both are verified here before the call.
    static string CheckOwnership(ProductionEntryRequest r)
    {
        ProductionPayloadContext ctx = LoadPayloadContext(r.SmoId, r.SioId);
        if (!ctx.Ok)
            return ctx.Message;
        // Waits for a status change that holds the order row and reads its committed result; a later hold or cancel then finds this save in flight.
        ctx.OrderStatus = LockedStatus(r.SmoId);
        if (!SalesOrderStatus.CanReserve(ctx.OrderStatus))
            return "Production cannot be entered unless the sales order is Approved, Processed or Partially Delivered.";
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

    // The procedure takes one JSON document: a master object plus an items array (one or more inputs, exactly one output).
    // This screen consumes a single reservation, so the whole reserved quantity is sent as the one input, as before.
    static string BuildPayload(ProductionEntryRequest r)
    {
        var db = new mySqlConnection();
        DataTable line = db.SelectQuery("select itbs_id,itm_id,tum_id,sio_length,sio_width from tbl_sales_items_order where sio_id=@s and smo_id=@o",
            new MySqlParameter[] { new MySqlParameter("@s", r.SioId), new MySqlParameter("@o", r.SmoId) });
        if (line == null || line.Rows.Count == 0)
            throw new InvalidOperationException("The order item does not belong to this sales order.");
        DataTable rsv = db.SelectQuery("select itbh_id,itbsr_qty from tbl_item_batchstock_reserve where itbsr_id=@r and sio_id=@s",
            new MySqlParameter[] { new MySqlParameter("@r", r.ReservationId), new MySqlParameter("@s", r.SioId) });
        if (rsv == null || rsv.Rows.Count == 0)
            throw new InvalidOperationException("The selected reservation does not belong to this order item.");

        DataRow l = line.Rows[0];
        string now = Now(db).ToString("yyyy-MM-dd HH:mm:ss");
        var master = new JObject(
            new JProperty("itpm_docdate", now),
            new JProperty("itpm_createdby", r.UserId),
            new JProperty("itpm_createddate", now));
        var input = new JObject(
            new JProperty("itpi_inputoutput", ProductionItemRecord.Input),
            new JProperty("itbsr_id", r.ReservationId),
            new JProperty("itbh_id", Int(rsv.Rows[0]["itbh_id"])),
            new JProperty("itpi_quantity", Dec(rsv.Rows[0]["itbsr_qty"])));
        var output = new JObject(
            new JProperty("itpi_inputoutput", ProductionItemRecord.Output),
            new JProperty("itbs_id", Int(l["itbs_id"])),
            new JProperty("itm_id", Int(l["itm_id"])),
            new JProperty("tum_id", l["tum_id"] == DBNull.Value ? JValue.CreateNull() : new JValue(Int(l["tum_id"]))),
            new JProperty("itbh_length", l["sio_length"] == DBNull.Value ? JValue.CreateNull() : new JValue(Dec(l["sio_length"]))),
            new JProperty("itbh_width", l["sio_width"] == DBNull.Value ? JValue.CreateNull() : new JValue(Dec(l["sio_width"]))),
            new JProperty("itpi_quantity", r.OutputQty));
        var payload = new JObject(
            new JProperty("master", master),
            new JProperty("items", new JArray(input, output)));
        return payload.ToString(Newtonsoft.Json.Formatting.None);
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

    static ProductionEntryResult Execute(ProductionEntryRequest r)
    {
        string payload = BuildPayload(r);
        using (var con = new MySqlConnection(System.Configuration.ConfigurationManager.AppSettings["db_connect_mysql"]))
        using (var cmd = new MySqlCommand(ProcedureName, con))
        {
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.Add(new MySqlParameter("p_production_json", MySqlDbType.JSON) { Value = payload });
            cmd.Parameters.Add(new MySqlParameter("p_itpm_id", MySqlDbType.Int32) { Direction = ParameterDirection.Output });
            cmd.Parameters.Add(new MySqlParameter("p_result", MySqlDbType.LongText) { Direction = ParameterDirection.Output });
            // The procedure commits internally, so it is deliberately not wrapped in a caller transaction.
            con.Open();
            cmd.ExecuteNonQuery();
            object res = cmd.Parameters["p_result"].Value;
            object id = cmd.Parameters["p_itpm_id"].Value;
            return Parse(res == null || res == DBNull.Value ? null : Convert.ToString(res),
                id == null || id == DBNull.Value ? 0 : Convert.ToInt32(id), r.ReservationId);
        }
    }

    // p_result is the only authoritative outcome: the procedure's exit handler swallows errors and reports them there.
    static ProductionEntryResult Parse(string json, int itpmId, int reservationId)
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
            ReservationId = reservationId,
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
            if (result.ErrorCode < 30001 || result.ErrorCode > 30016)
            {
                result.Detail = result.Message;
                Log(new Exception(json));
                // 1267 is the collation conflict that currently makes the procedure fail (see production_workflow_reference.md).
                result.Message = result.ErrorCode == 1267
                    ? "The production procedure failed because of a database collation error (sp_save_production_entry1.1). No changes were made. Please contact the administrator."
                    : "The production entry could not be saved. No changes were made.";
            }
            result.ItpmId = 0;
        }
        return result;
    }

    // Reads the status under the order row lock in a transaction that ends at once, so it never overlaps the procedure's own transaction.
    static int LockedStatus(int smoId)
    {
        var db = new mySqlConnection();
        bool started = false;
        try
        {
            db.BeginTransaction();
            started = true;
            int status = SalesOrderStatus.LockStatus(db, smoId);
            db.CommitTransaction();
            started = false;
            return status;
        }
        finally
        {
            if (started)
            {
                try { db.RollBackTransaction(); }
                catch (Exception) { }
            }
            try { db.CloseConnection(); }
            catch (Exception) { }
        }
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
