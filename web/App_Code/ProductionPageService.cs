using commonfunction;
using MySql.Data.MySqlClient;
using Newtonsoft.Json;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.Caching;

public sealed class ProductionOrderAccess
{
    public int StaffId;
    public string StaffType;
    public int BranchId;
    public int Status;
    public string DocBase;
}

// Server side of the Production > Production Queue and Production History pages. Order access follows the sales order screens
// (user branches; salesmen type 2 are limited to their own orders and cannot enter production). The production rules themselves
// stay in SalesOrderStock / ProductionService; nothing here writes production records directly.
public static class ProductionPageService
{
    const string EmptyResult = "{\"count\":\"0\",\"data\":[]}";

    static string Cookie(string name)
    {
        HttpCookie c = HttpContext.Current.Request.Cookies[name];
        return c != null ? c.Value : "";
    }

    public static bool IsSalesman()
    {
        return Cookie("invntrystaffTypeID") == "2";
    }

    static int StaffId()
    {
        int id;
        if (!int.TryParse(Cookie("invntrystaffId"), out id) || id <= 0)
            throw new HttpException(401, "Please sign in again.");
        return id;
    }

    public static ProductionOrderAccess OpenOrder(int smoId)
    {
        var context = HttpContext.Current;
        var access = new ProductionOrderAccess { StaffId = StaffId(), StaffType = Cookie("invntrystaffTypeID") };
        if (smoId <= 0 || context.Request.Cookies["invntrystaffBranchId"] == null || context.Request.Cookies["invntrystaffCountryId"] == null)
            throw new HttpException(401, "Please sign in again.");

        var authentication = new LoginAuthentication();
        authentication.userAuthentication();
        authentication.checkPageAcess(7);

        string sql = "select smo.branch_id,smo.smo_delivery_status,smo.smo_invoice_no from tbl_sales_master_order smo where smo.smo_id=@id"
            + " and smo.branch_id in (select branch_id from tbl_user_branches where user_id=@u)";
        var ps = new List<MySqlParameter> { new MySqlParameter("@id", smoId), new MySqlParameter("@u", access.StaffId) };
        if (access.StaffType == "2")
        {
            sql += " and smo.smo_userid=@owner";
            ps.Add(new MySqlParameter("@owner", access.StaffId));
        }
        DataTable dt = new mySqlConnection().SelectQuery(sql, ps.ToArray());
        if (dt == null || dt.Rows.Count == 0)
            throw new HttpException(404, "Sales order not found.");
        access.BranchId = Convert.ToInt32(dt.Rows[0]["branch_id"]);
        int status;
        access.Status = int.TryParse(Convert.ToString(dt.Rows[0]["smo_delivery_status"]), out status) ? status : -1;
        access.DocBase = Convert.ToString(dt.Rows[0]["smo_invoice_no"]);
        if (string.IsNullOrWhiteSpace(access.DocBase))
            access.DocBase = "SO-" + smoId;
        return access;
    }

    static StockActionResult Denied(string message)
    {
        return new StockActionResult { ok = false, message = message };
    }

    const string NoReservePermission = "You do not have permission to reserve stock for this order.";

    // Reservation actions: same rules as the Reserved Items tab of the sales order (SalesOrderStock does the validation and locking).
    public static StockActionResult Reserve(int smoId, int sioId, decimal expectedQty, int compItmId)
    {
        ProductionOrderAccess a = OpenOrder(smoId);
        if (a.StaffType == "2")
            return Denied(NoReservePermission);
        try
        {
            return SalesOrderStock.Reserve(smoId, a.BranchId, a.Status, a.StaffId, sioId, expectedQty, compItmId);
        }
        finally
        {
            PatchBoards(smoId, a.BranchId);
        }
    }

    public static StockActionResult ReserveBatches(int smoId, int sioId, int compItmId, List<BatchQty> allocations)
    {
        ProductionOrderAccess a = OpenOrder(smoId);
        if (a.StaffType == "2")
            return Denied(NoReservePermission);
        try
        {
            return SalesOrderStock.ReserveBatches(smoId, a.BranchId, a.Status, a.StaffId, sioId, compItmId, allocations);
        }
        finally
        {
            PatchBoards(smoId, a.BranchId);
        }
    }

    public static ReserveOptionsResult LoadReserveOptions(int smoId, int sioId, int compItmId)
    {
        ProductionOrderAccess a = OpenOrder(smoId);
        try
        {
            if (a.StaffType == "2")
                return new ReserveOptionsResult { ok = false, message = NoReservePermission };
            return SalesOrderStock.LoadOptions(smoId, a.BranchId, a.StaffId, sioId, compItmId);
        }
        catch (Exception ex)
        {
            new LogClass("salesorderstockerror").write(ex);
            return new ReserveOptionsResult { ok = false, message = "Unable to load warehouse stock. Please try again." };
        }
    }

    public static StockActionResult Unreserve(int smoId, int sioId, int compItmId)
    {
        ProductionOrderAccess a = OpenOrder(smoId);
        if (a.StaffType == "2")
            return Denied("You do not have permission to release reservations for this order.");
        try
        {
            return SalesOrderStock.Unreserve(smoId, a.BranchId, a.Status, sioId, compItmId);
        }
        finally
        {
            PatchBoards(smoId, a.BranchId);
        }
    }

    public static StockActionResult UnreserveBatch(int smoId, int sioId, int batchId)
    {
        ProductionOrderAccess a = OpenOrder(smoId);
        if (a.StaffType == "2")
            return Denied("You do not have permission to release reservations for this order.");
        try
        {
            return SalesOrderStock.UnreserveBatch(smoId, sioId, batchId);
        }
        finally
        {
            PatchBoards(smoId, a.BranchId);
        }
    }

    public static ProductionEntryOptions LoadEntry(int smoId, int sioId)
    {
        ProductionOrderAccess a = OpenOrder(smoId);
        try
        {
            if (a.StaffType == "2")
                return new ProductionEntryOptions { ok = false, message = "You do not have permission to enter production for this order." };
            return SalesOrderStock.LoadProductionEntry(smoId, a.BranchId, a.Status, a.DocBase, sioId);
        }
        catch (Exception ex)
        {
            new LogClass("salesorderstockerror").write(ex);
            return new ProductionEntryOptions { ok = false, message = "Unable to load the production entry. Please try again." };
        }
    }

    public static ProductionSaveResult Save(int smoId, int sioId, int reservationId, decimal expectedOutput)
    {
        ProductionOrderAccess a = OpenOrder(smoId);
        if (a.StaffType == "2")
            return new ProductionSaveResult { ok = false, message = "You do not have permission to enter production for this order." };
        try
        {
            return SalesOrderStock.SaveProduction(smoId, a.BranchId, a.Status, a.StaffId, a.DocBase, sioId, reservationId, expectedOutput);
        }
        finally
        {
            PatchBoards(smoId, a.BranchId);
        }
    }

    public static ProductionJobDetail LoadJob(int smoId, int itpmId)
    {
        ProductionOrderAccess a = OpenOrder(smoId);
        try
        {
            return SalesOrderStock.LoadProductionDetail(smoId, a.BranchId, a.DocBase, itpmId);
        }
        catch (Exception ex)
        {
            new LogClass("salesorderstockerror").write(ex);
            return new ProductionJobDetail { ok = false, message = "Unable to load the production job details. Please try again." };
        }
    }

    public static string GetBranches()
    {
        DataTable dt = new mySqlConnection().SelectQuery("select tb.branch_id,tb.branch_name from tbl_branch tb inner join tbl_user_branches ub on ub.branch_id=tb.branch_id where ub.user_id=@u",
            new MySqlParameter[] { new MySqlParameter("@u", StaffId()) });
        return JsonConvert.SerializeObject(dt);
    }

    // Staff who share a warehouse with the signed-in user, for the "Produced by" filter.
    public static string GetStaff()
    {
        DataTable dt = new mySqlConnection().SelectQuery("select distinct ud.user_id,trim(concat_ws(' ',ud.first_name,ud.last_name)) as name from tbl_user_details ud "
            + "inner join tbl_user_branches ub on ub.user_id=ud.user_id where ub.branch_id in (select branch_id from tbl_user_branches where user_id=@u) order by name",
            new MySqlParameter[] { new MySqlParameter("@u", StaffId()) });
        return JsonConvert.SerializeObject(dt);
    }

    static bool ParseDate(Dictionary<string, string> filters, string key, out DateTime date)
    {
        string v;
        date = DateTime.MinValue;
        return filters.TryGetValue(key, out v) && DateTime.TryParseExact((v ?? "").Replace("/", "-"), "dd-MM-yyyy", CultureInfo.InvariantCulture, DateTimeStyles.None, out date);
    }

    static MySqlParameter[] Clone(List<MySqlParameter> source)
    {
        var copy = new MySqlParameter[source.Count];
        for (int i = 0; i < source.Count; i++)
            copy[i] = new MySqlParameter(source[i].ParameterName, source[i].Value);
        return copy;
    }

    static string Page(mySqlConnection db, string select, string from, string where, string order, List<MySqlParameter> ps, int page, int perpage)
    {
        if (page < 1) page = 1;
        if (perpage != 50 && perpage != 100 && perpage != 250 && perpage != 500) perpage = 50;
        string scalar = db.SelectScalar("select count(*) " + from + where, Clone(ps));
        int count = string.IsNullOrEmpty(scalar) ? 0 : Convert.ToInt32(scalar);
        if (count == 0)
            return EmptyResult;
        DataTable dt = db.SelectQuery(select + from + where + order + " limit " + ((page - 1) * perpage) + "," + perpage, Clone(ps));
        return "{\"count\":\"" + count + "\",\"data\":" + JsonConvert.SerializeObject(dt) + "}";
    }

    static void AddBranchScope(Dictionary<string, string> filters, int staffId, List<MySqlParameter> ps, ref string where)
    {
        string v;
        int n;
        if (filters.TryGetValue("branch", out v) && int.TryParse(v, out n) && n > 0)
        {
            where += " and smo.branch_id=@branch";
            ps.Add(new MySqlParameter("@branch", n));
        }
        where += " and smo.branch_id in (select branch_id from tbl_user_branches where user_id=@bu)";
        ps.Add(new MySqlParameter("@bu", staffId));
    }

    const int MaxBoardOrders = 150;

    sealed class BoardData
    {
        public List<ProductionBoardRow> All;
        public bool Truncated;
    }

    const int BoardCacheSeconds = 60;
    const int BoardParallelism = 6;
    static readonly ConcurrentDictionary<string, bool> BoardKeys = new ConcurrentDictionary<string, bool>();

    // After a reservation or production change only the affected order is recalculated, in every cached board that lists it
    // (reloading the whole board costs several database round trips per order). Boards that cannot be patched are dropped.
    static void PatchBoards(int smoId, int branchId)
    {
        foreach (string key in BoardKeys.Keys)
        {
            var data = HttpRuntime.Cache[key] as BoardData;
            if (data == null)
            {
                bool ignore;
                BoardKeys.TryRemove(key, out ignore);
                continue;
            }
            try
            {
                List<ProductionBoardRow> old = data.All;
                ProductionBoardRow sample = old.FirstOrDefault(r => r.smoId == smoId);
                if (sample == null)
                    continue;
                int status = SalesOrderStatus.Read(smoId);
                var sios = new HashSet<int>(old.Where(r => r.smoId == smoId).Select(r => r.sioId));
                List<ProductionBoardRow> fresh = SalesOrderStock.LoadProductionBoard(smoId, branchId, status, true, sios);
                foreach (ProductionBoardRow r in fresh)
                {
                    r.orderRef = sample.orderRef;
                    r.customer = sample.customer;
                    r.warehouse = sample.warehouse;
                    r.orderDate = sample.orderDate;
                    r.orderStatus = status;
                    r.orderStatusText = SalesOrderStatus.Name(status);
                }
                var merged = new List<ProductionBoardRow>();
                bool placed = false;
                foreach (ProductionBoardRow r in old)
                {
                    if (r.smoId != smoId)
                    {
                        merged.Add(r);
                    }
                    else if (!placed)
                    {
                        merged.AddRange(fresh);
                        placed = true;
                    }
                }
                data.All = merged;
            }
            catch (Exception ex)
            {
                new LogClass("salesorderstockerror").write(ex);
                HttpRuntime.Cache.Remove(key);
            }
        }
    }

    // The status, sort and paging only slice the computed board, so they are not part of the key.
    static string BoardKey(Dictionary<string, string> filters, int staffId)
    {
        var parts = new List<string> { "pq", staffId.ToString() };
        foreach (KeyValuePair<string, string> kv in filters.OrderBy(x => x.Key, StringComparer.Ordinal))
            if (kv.Key != "status" && kv.Key != "refresh" && kv.Key != "sort")
                parts.Add(kv.Key + "=" + (kv.Value ?? "").Trim());
        return string.Join("|", parts);
    }

    static BoardData GetBoard(Dictionary<string, string> filters, int staffId)
    {
        string key = BoardKey(filters, staffId);
        string refresh;
        BoardData data = filters.TryGetValue("refresh", out refresh) && refresh == "1" ? null : HttpRuntime.Cache[key] as BoardData;
        if (data == null)
        {
            data = BuildBoard(filters, staffId);
            HttpRuntime.Cache.Insert(key, data, null, DateTime.UtcNow.AddSeconds(BoardCacheSeconds), Cache.NoSlidingExpiration);
            BoardKeys[key] = true;
        }
        return data;
    }

    // Bulk Production: every open Production Queue line, grouped by finished item and UOM so the same item across several
    // Approved / Processed orders can be produced together. Only lines that are ready can be selected. Oldest orders first.
    public static string SearchBulkGroups(Dictionary<string, string> filters)
    {
        const string Empty = "{\"count\":0,\"lines\":0,\"truncated\":false,\"groups\":[]}";
        try
        {
            if (filters == null) filters = new Dictionary<string, string>();
            if (IsSalesman())
                return Empty;
            BoardData data = GetBoard(filters, StaffId());
            var groups = data.All
                .Where(r => ProductionBoardStatus.IsOpen(r.statusKey))
                .GroupBy(r => new { r.itmId, uom = r.uom ?? "" })
                .OrderBy(g => g.First().itemName, StringComparer.OrdinalIgnoreCase)
                .Select(g => new
                {
                    itmId = g.Key.itmId,
                    itemName = g.First().itemName,
                    itemCode = g.First().itemCode,
                    uom = g.Key.uom,
                    totalPending = g.Sum(r => r.pending),
                    readyCount = g.Count(r => r.statusKey == ProductionBoardStatus.Ready && r.canProduce),
                    orders = g.OrderBy(r => r.smoId).ThenBy(r => r.sioId).Select(r => new
                    {
                        r.smoId,
                        r.sioId,
                        r.orderRef,
                        r.customer,
                        r.warehouse,
                        r.orderDate,
                        r.pending,
                        r.status,
                        r.statusClass,
                        r.message,
                        ready = r.statusKey == ProductionBoardStatus.Ready && r.canProduce,
                        raw = string.Join(", ", r.raw.Select(c => c.name + " " + Math.Round(c.reserved, 4) + " " + c.uom))
                    }).ToList()
                }).ToList();
            return JsonConvert.SerializeObject(new { count = groups.Count, lines = groups.Sum(g => g.orders.Count), truncated = data.Truncated, groups = groups });
        }
        catch (HttpException)
        {
            throw;
        }
        catch (Exception ex)
        {
            new LogClass("salesorderstockerror").write(ex);
            return "E";
        }
    }

    // Produces one order line for Bulk Production through the same validated path as the Production Queue (LoadEntry / Save).
    // Only the unambiguous case is automated: one usable raw-material reservation that produces exactly the pending quantity,
    // because the procedure allows a single production entry per order and always consumes a whole reservation.
    public static ProductionSaveResult ProduceLine(int smoId, int sioId, decimal expectedPending)
    {
        ProductionEntryOptions o = LoadEntry(smoId, sioId);
        if (!o.ok)
            return new ProductionSaveResult { ok = false, message = o.message };
        if (!o.canSubmit)
            return new ProductionSaveResult { ok = false, message = o.blocker };
        List<ProductionEntryInput> usable = o.inputs.Where(x => x.issue == null).ToList();
        if (usable.Count != 1)
            return new ProductionSaveResult { ok = false, message = "Raw material is reserved in " + usable.Count + " batches. Produce this order from the Production Queue." };
        ProductionEntryInput input = usable[0];
        if (Math.Abs(o.pending - expectedPending) > 0.0005m)
            return new ProductionSaveResult { ok = false, message = "The pending quantity changed (now " + Math.Round(o.pending, 4) + " " + o.uom + "). Reload and try again." };
        if (Math.Abs(input.outputQty - o.pending) > 0.0005m)
            return new ProductionSaveResult { ok = false, message = "The reserved raw material produces " + Math.Round(input.outputQty, 4) + " " + o.uom + ", not the pending " + Math.Round(o.pending, 4) + ". Produce this order from the Production Queue." };
        return Save(smoId, sioId, input.reservationId, input.outputQty);
    }

    // Production Queue board: one row per manufactured line (item with a BOM) of Approved / Processed orders that is not fully delivered.
    // Order-level filters run in SQL; the production status is derived from the stock calculation, so it is filtered and paged here.
    // Computing the board costs several database round trips per order, so the result is cached briefly (filters["refresh"]="1" bypasses it).
    public static string SearchItemsToProduce(int page, Dictionary<string, string> filters, int perpage)
    {
        try
        {
            if (filters == null) filters = new Dictionary<string, string>();
            if (IsSalesman())
                return EmptyResult;
            if (page < 1) page = 1;
            if (perpage != 25 && perpage != 50 && perpage != 100) perpage = 25;
            BoardData data = GetBoard(filters, StaffId());
            List<ProductionBoardRow> all = data.All;

            var counts = new Dictionary<string, int>();
            foreach (ProductionBoardRow r in all)
            {
                int n;
                counts.TryGetValue(r.statusKey, out n);
                counts[r.statusKey] = n + 1;
            }
            string status;
            if (!filters.TryGetValue("status", out status) || string.IsNullOrEmpty(status))
                status = "open";
            IEnumerable<ProductionBoardRow> shown = all;
            if (status == "open")
                shown = all.Where(r => ProductionBoardStatus.IsOpen(r.statusKey));
            else if (status != "all")
                shown = all.Where(r => r.statusKey == status);
            List<ProductionBoardRow> list = shown.ToList();

            return JsonConvert.SerializeObject(new
            {
                count = list.Count,
                truncated = data.Truncated,
                counts = counts,
                data = list.Skip((page - 1) * perpage).Take(perpage)
            });
        }
        catch (HttpException)
        {
            throw;
        }
        catch (Exception ex)
        {
            new LogClass("salesorderstockerror").write(ex);
            return "E";
        }
    }

    static BoardData BuildBoard(Dictionary<string, string> filters, int staffId)
    {
        {
            var ps = new List<MySqlParameter>();
            string where = " where smo.smo_delivery_status in (" + SalesOrderStatus.Approved + "," + SalesOrderStatus.Processed + ")"
                + " and m.itsv_bom_enabled=1"
                + " and exists (select 1 from tbl_item_master_bom bom where bom.itm_id_output=sio.itm_id and bom.itmbi_type=1)";
            AddBranchScope(filters, staffId, ps, ref where);

            string v;
            if (filters.TryGetValue("order", out v) && v.Trim() != "")
            {
                where += " and (cast(smo.smo_id as char) like @o or smo.smo_invoice_no like @o)";
                ps.Add(new MySqlParameter("@o", "%" + v.Trim() + "%"));
            }
            if (filters.TryGetValue("customer", out v) && v.Trim() != "")
            {
                where += " and (tc.cust_name like @c or cast(smo.cust_id as char)=@cExact)";
                ps.Add(new MySqlParameter("@c", "%" + v.Trim() + "%"));
                ps.Add(new MySqlParameter("@cExact", v.Trim()));
            }
            if (filters.TryGetValue("product", out v) && v.Trim() != "")
            {
                where += " and (m.itm_name like @p or m.itm_code like @p or sio.itm_name like @p)";
                ps.Add(new MySqlParameter("@p", "%" + v.Trim() + "%"));
            }
            int actor;
            if (filters.TryGetValue("actor", out v) && int.TryParse(v, out actor) && actor > 0)
            {
                // Actions on a line: stock reserved by the user, or production entered by the user (finished batch PRO-<itpm_id>-<sio_id>).
                where += " and (exists (select 1 from tbl_item_batchstock_reserve ar where ar.sio_id=sio.sio_id and ar.itbrs_by=@actor)"
                    + " or exists (select 1 from tbl_item_batch ab inner join tbl_item_pro_master apm on apm.itpm_id=ab.itbh_created_doc_id"
                    + " where ab.itbs_id=sio.itbs_id and ab.itbh_custbatchid=concat('PRO-',ab.itbh_created_doc_id,'-',sio.sio_id) and apm.itpm_createdby=@actor))";
                ps.Add(new MySqlParameter("@actor", actor));
            }
            DateTime d;
            if (ParseDate(filters, "from_date", out d))
            {
                where += " and smo.smo_date >= @fromDate";
                ps.Add(new MySqlParameter("@fromDate", d.Date));
            }
            if (ParseDate(filters, "to_date", out d))
            {
                where += " and smo.smo_date < @toDate";
                ps.Add(new MySqlParameter("@toDate", d.Date.AddDays(1)));
            }

            DataTable candidates = new mySqlConnection().SelectQuery("select smo.smo_id,smo.branch_id,smo.smo_delivery_status as st,smo.smo_invoice_no,tc.cust_name,tb.branch_name,"
                + "DATE_FORMAT(smo.smo_date,'%d-%b-%Y') as od,sio.sio_id "
                + "from tbl_sales_items_order sio inner join tbl_sales_master_order smo on smo.smo_id=sio.smo_id "
                + "inner join tbl_customer tc on tc.cust_id=smo.cust_id left join tbl_branch tb on tb.branch_id=smo.branch_id "
                + "inner join tbl_item_master m on m.itm_id=sio.itm_id" + where
                + " order by smo.smo_date desc,smo.smo_id desc,sio.row_no,sio.sio_id", ps.ToArray());

            var orders = new List<DataRow>();
            var sios = new Dictionary<int, HashSet<int>>();
            bool truncated = false;
            foreach (DataRow r in candidates.Rows)
            {
                int smoId = Convert.ToInt32(r["smo_id"]);
                HashSet<int> set;
                if (!sios.TryGetValue(smoId, out set))
                {
                    if (orders.Count >= MaxBoardOrders)
                    {
                        truncated = true;
                        continue;
                    }
                    sios[smoId] = set = new HashSet<int>();
                    orders.Add(r);
                }
                set.Add(Convert.ToInt32(r["sio_id"]));
            }

            var perOrder = new List<ProductionBoardRow>[orders.Count];
            var failures = new Exception[orders.Count];
            Parallel.For(0, orders.Count, new ParallelOptions { MaxDegreeOfParallelism = BoardParallelism }, i =>
            {
                DataRow o = orders[i];
                int smoId = Convert.ToInt32(o["smo_id"]);
                try
                {
                    perOrder[i] = SalesOrderStock.LoadProductionBoard(smoId, Convert.ToInt32(o["branch_id"]), Convert.ToInt32(o["st"]), true, sios[smoId]);
                }
                catch (Exception ex)
                {
                    failures[i] = ex;
                }
            });

            var all = new List<ProductionBoardRow>();
            for (int i = 0; i < orders.Count; i++)
            {
                if (failures[i] != null)
                {
                    new LogClass("salesorderstockerror").write(failures[i]);
                    continue;
                }
                DataRow o = orders[i];
                int smoId = Convert.ToInt32(o["smo_id"]);
                int st = Convert.ToInt32(o["st"]);
                string invoice = Convert.ToString(o["smo_invoice_no"]);
                foreach (ProductionBoardRow r in perOrder[i])
                {
                    r.orderRef = string.IsNullOrWhiteSpace(invoice) ? "SO-" + smoId : invoice;
                    r.customer = Convert.ToString(o["cust_name"]);
                    r.warehouse = Convert.ToString(o["branch_name"]);
                    r.orderDate = Convert.ToString(o["od"]);
                    r.orderStatus = st;
                    r.orderStatusText = SalesOrderStatus.Name(st);
                    all.Add(r);
                }
            }
            return new BoardData { All = all, Truncated = truncated };
        }
    }

    // Production jobs across orders. A job belongs to a sales order line through its finished batch
    // (itbh_created_doc_id = itpm_id and itbh_custbatchid = 'PRO-<itpm_id>-<sio_id>'), exactly as SalesOrderStock.ReadJobs does.
    public static string SearchHistory(int page, Dictionary<string, string> filters, int perpage)
    {
        try
        {
            if (filters == null) filters = new Dictionary<string, string>();
            int staffId = StaffId();
            var ps = new List<MySqlParameter>();
            string where = " where pi.itpi_inputoutput=2";
            AddBranchScope(filters, staffId, ps, ref where);
            if (IsSalesman())
            {
                where += " and smo.smo_userid=@owner";
                ps.Add(new MySqlParameter("@owner", staffId));
            }

            string v;
            if (filters.TryGetValue("search", out v) && v.Trim() != "")
            {
                where += " and (pm.itpm_doc_no like @s or cast(smo.smo_id as char) like @s or smo.smo_invoice_no like @s or tc.cust_name like @s or m.itm_name like @s or m.itm_code like @s or b.itbh_no like @s)";
                ps.Add(new MySqlParameter("@s", "%" + v.Trim() + "%"));
            }
            DateTime d;
            if (ParseDate(filters, "from_date", out d))
            {
                where += " and pm.itpm_createddate >= @fromDate";
                ps.Add(new MySqlParameter("@fromDate", d.Date));
            }
            if (ParseDate(filters, "to_date", out d))
            {
                where += " and pm.itpm_createddate < @toDate";
                ps.Add(new MySqlParameter("@toDate", d.Date.AddDays(1)));
            }
            if (filters.TryGetValue("ref", out v) && v.Trim() != "")
            {
                where += " and (pm.itpm_doc_no like @ref or cast(pm.itpm_id as char)=@refExact)";
                ps.Add(new MySqlParameter("@ref", "%" + v.Trim() + "%"));
                ps.Add(new MySqlParameter("@refExact", v.Trim()));
            }
            if (filters.TryGetValue("order", out v) && v.Trim() != "")
            {
                where += " and (cast(smo.smo_id as char) like @ord or smo.smo_invoice_no like @ord)";
                ps.Add(new MySqlParameter("@ord", "%" + v.Trim() + "%"));
            }
            if (filters.TryGetValue("customer", out v) && v.Trim() != "")
            {
                where += " and (tc.cust_name like @cust or cast(smo.cust_id as char)=@custExact)";
                ps.Add(new MySqlParameter("@cust", "%" + v.Trim() + "%"));
                ps.Add(new MySqlParameter("@custExact", v.Trim()));
            }
            if (filters.TryGetValue("product", out v) && v.Trim() != "")
            {
                where += " and (m.itm_name like @prod or m.itm_code like @prod)";
                ps.Add(new MySqlParameter("@prod", "%" + v.Trim() + "%"));
            }
            if (filters.TryGetValue("material", out v) && v.Trim() != "")
            {
                where += " and exists (select 1 from tbl_item_pro_items xi inner join tbl_item_batch xb on xb.itbh_id=xi.itbh_id"
                    + " inner join tbl_item_master xm on xm.itm_id=xb.itm_id where xi.itpm_id=pm.itpm_id and xi.itpi_inputoutput=1 and (xm.itm_name like @mat or xm.itm_code like @mat))";
                ps.Add(new MySqlParameter("@mat", "%" + v.Trim() + "%"));
            }
            if (filters.TryGetValue("batch", out v) && v.Trim() != "")
            {
                where += " and b.itbh_no like @batch";
                ps.Add(new MySqlParameter("@batch", "%" + v.Trim() + "%"));
            }
            int n;
            if (filters.TryGetValue("user", out v) && int.TryParse(v, out n) && n > 0)
            {
                // Action by: entered the production, or reserved stock for the order line (the raw material or the finished item).
                where += " and (pm.itpm_createdby=@by or exists (select 1 from tbl_item_batchstock_reserve ur where ur.sio_id=sio.sio_id and ur.itbrs_by=@by))";
                ps.Add(new MySqlParameter("@by", n));
            }
            decimal q;
            if (filters.TryGetValue("qty_from", out v) && decimal.TryParse(v, NumberStyles.Number, CultureInfo.InvariantCulture, out q))
            {
                where += " and pi.itpi_quantity >= @qtyFrom";
                ps.Add(new MySqlParameter("@qtyFrom", q));
            }
            if (filters.TryGetValue("qty_to", out v) && decimal.TryParse(v, NumberStyles.Number, CultureInfo.InvariantCulture, out q))
            {
                where += " and pi.itpi_quantity <= @qtyTo";
                ps.Add(new MySqlParameter("@qtyTo", q));
            }

            string sort;
            filters.TryGetValue("sort", out sort);
            string order;
            switch (sort)
            {
                case "oldest": order = " order by pm.itpm_id asc"; break;
                case "qty_desc": order = " order by pi.itpi_quantity desc,pm.itpm_id desc"; break;
                case "order": order = " order by smo.smo_id desc,pm.itpm_id desc"; break;
                default: order = " order by pm.itpm_id desc"; break;
            }

            string select = "select pm.itpm_id,pm.itpm_doc_no,DATE_FORMAT(pm.itpm_createddate,'%d-%b-%Y %H:%i') as created,"
                + "trim(concat_ws(' ',cu.first_name,cu.last_name)) as created_by,smo.smo_id,smo.smo_invoice_no,tc.cust_name,tb.branch_name,"
                + "m.itm_name,m.itm_code,b.itbh_no,pi.itpi_quantity,pu.tum_name as uom,"
                + "(select count(*) from tbl_item_pro_items x where x.itpm_id=pm.itpm_id and x.itpi_inputoutput=1) as input_count ";
            string from = " from tbl_sales_items_order sio inner join tbl_sales_master_order smo on smo.smo_id=sio.smo_id"
                + " inner join tbl_customer tc on tc.cust_id=smo.cust_id"
                + " inner join tbl_item_batch b on b.itbh_custbatchid=concat('PRO-',b.itbh_created_doc_id,'-',sio.sio_id) and b.itbs_id=sio.itbs_id and b.branch_id=smo.branch_id"
                + " inner join tbl_item_pro_master pm on pm.itpm_id=b.itbh_created_doc_id"
                + " inner join tbl_item_pro_items pi on pi.itpm_id=pm.itpm_id and pi.itbh_id=b.itbh_id"
                + " left join tbl_item_master m on m.itm_id=sio.itm_id"
                + " left join tbl_item_uom pu on pu.tum_id=m.itsv_uom_purchase"
                + " left join tbl_user_details cu on cu.user_id=pm.itpm_createdby"
                + " left join tbl_branch tb on tb.branch_id=smo.branch_id";
            return Page(new mySqlConnection(), select, from, where, order, ps, page, perpage);
        }
        catch (HttpException)
        {
            throw;
        }
        catch (Exception ex)
        {
            new LogClass("salesorderstockerror").write(ex);
            return "E";
        }
    }
}
