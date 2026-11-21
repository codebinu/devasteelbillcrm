using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using MySql.Data.MySqlClient;
using Newtonsoft.Json;

// Read-only batch traceability (Track Batch). Nothing here writes to the database.
//
// How a batch is linked to other records (verified against the live schema and the existing workflows):
//  - Origin, purchase:   tbl_purchase_items.itbh_id -> tbl_purchase_master (sp_save_purchase_entry sets itbh_created_doc_id = pi_id).
//  - Origin, production: tbl_item_pro_items (itpi_inputoutput = 2) -> tbl_item_pro_master (itbh_created_doc_id = itpm_id).
//    Both workflows write itbh_created_doc_type = 2, so the type is never used to tell them apart.
//  - Reservations:       tbl_item_batchstock_reserve.itbh_id -> sio_id -> tbl_sales_items_order -> tbl_sales_master_order.
//    The application deletes a reservation when it is consumed or released and keeps no history of it.
//  - Invoices:           tbl_stock_transactions (action_type 1, itbh_id, action_ref_id = sm_id, dr_qty in the batch UOM) written by the
//    sales-order invoice flow; legacy / inter-stock invoices carry tbl_sales_items.itbh_id instead (quantity in the invoice line UOM).
//  - Inter-stock:        invoice with sm_is_inter_stock_transfer_invoice = 1 (transfer out) and the purchase with
//    pm_is_inter_stock_transfer_invoice = 1 that receives it (transfer in); the receiving purchase creates its own batch.
//  - Production use:     tbl_item_pro_items (itpi_inputoutput = 1) = raw material consumed.
//  - Stock ledger:       tbl_stock_transactions.itbh_id; rows not explained by the records above are listed as "other".
public static class BatchTrace
{
    const string Fmt = "'%Y-%m-%d %H:%i:%s'";
    const int InvoiceAction = 1, PurchaseAction = 2, ProductionAction = 12;

    // A batch is "customer" when a batch id was typed in; the purchase / production procedures store PUR-<id>-<row> or
    // PRO-<id>-<line> when none was given.
    const string SystemBatchSql = "(ifnull(trim(b.itbh_custbatchid),'')='' or b.itbh_custbatchid regexp '^(PUR|PRO)-[0-9]+-[0-9]+$')";

    static readonly Regex ProCustBatch = new Regex(@"^PRO-(\d+)-(\d+)$", RegexOptions.Compiled);

    // ---------- access ----------
    public const int PageId = 4; // "Purchase Lists" permission: the batch history exposes purchase data

    // Page methods bypass Page_Load, so they re-check the login cookies and the page permission against the database.
    // Returns the user id, or 0 when the caller is not allowed.
    public static int AuthorizedStaffId()
    {
        return AuthorizedStaffId(PageId);
    }

    // Same check for another page permission (used by Stock View).
    public static int AuthorizedStaffId(int pageId)
    {
        HttpContext ctx = HttpContext.Current;
        HttpCookie n = ctx == null ? null : ctx.Request.Cookies["invntrystaffName"], p = ctx == null ? null : ctx.Request.Cookies["invntrystaffPassword"];
        if (n == null || p == null)
            return 0;
        string user = HttpUtility.UrlDecode(n.Value), pass = HttpUtility.UrlDecode(p.Value);
        if (string.IsNullOrEmpty(user) || string.IsNullOrEmpty(pass))
            return 0;
        DataTable dt = Q("select user_id,user_type from tbl_user_details where user_name=@n and password=@p limit 1", P("@n", user), P("@p", pass));
        if (dt.Rows.Count == 0)
            return 0;
        int allowed = I(Q("select count(*) from tbl_user_permissions where user_type=@t and page_id=@pg and read_action='1'",
            P("@t", dt.Rows[0]["user_type"]), P("@pg", pageId)).Rows[0][0]);
        return allowed == 0 ? 0 : I(dt.Rows[0]["user_id"]);
    }

    // ---------- helpers ----------
    static MySqlParameter P(string n, object v) { return new MySqlParameter(n, v ?? DBNull.Value); }

    // Unlike mySqlConnection.SelectQuery this throws, so the page can show an error instead of an empty result.
    static DataTable Q(string sql, params MySqlParameter[] ps)
    {
        using (var con = new MySqlConnection(ConfigurationManager.AppSettings["db_connect_mysql"]))
        using (var cmd = new MySqlCommand(sql, con))
        {
            cmd.CommandTimeout = 60;
            if (ps != null && ps.Length > 0)
                cmd.Parameters.AddRange(ps);
            con.Open();
            var dt = new DataTable();
            using (var da = new MySqlDataAdapter(cmd))
                da.Fill(dt);
            return dt;
        }
    }

    static int I(object o) { return o == null || o == DBNull.Value ? 0 : Convert.ToInt32(o, CultureInfo.InvariantCulture); }
    static decimal D(object o) { return o == null || o == DBNull.Value ? 0m : Convert.ToDecimal(o, CultureInfo.InvariantCulture); }
    static decimal? DN(object o) { return o == null || o == DBNull.Value ? (decimal?)null : Convert.ToDecimal(o, CultureInfo.InvariantCulture); }
    static string S(object o) { return o == null || o == DBNull.Value ? "" : Convert.ToString(o, CultureInfo.InvariantCulture); }
    static string Dt(object o)
    {
        string s = S(o);
        return s == "" || s.StartsWith("0000") ? null : s;
    }

    static string InList(string prefix, IEnumerable<int> ids, List<MySqlParameter> ps)
    {
        int n = 0;
        var names = new List<string>();
        foreach (int id in ids)
        {
            string name = "@" + prefix + n++;
            names.Add(name);
            ps.Add(P(name, id));
        }
        return string.Join(",", names);
    }

    static string EscapeLike(string s)
    {
        return s.Replace("\\", "\\\\").Replace("%", "\\%").Replace("_", "\\_");
    }

    static string Name(object first, object last) { return (S(first) + " " + S(last)).Trim(); }

    static string BranchScope(string alias) { return alias + ".branch_id in (select ub.branch_id from tbl_user_branches ub where ub.user_id=@staff)"; }

    // ---------- origin ----------
    class OriginRef
    {
        public string Kind = "none"; // purchase | production | none
        public int PiId, ItpmId;
    }

    // purchases: (pi_id) of every purchase line that references the batch; productions: itpm_id of every output row of the batch.
    static OriginRef ResolveOrigin(int createdDocId, List<int> purchaseLines, List<int> productionIds)
    {
        var none = new OriginRef();
        productionIds = productionIds.Distinct().ToList();
        bool hasP = purchaseLines.Count > 0, hasR = productionIds.Count > 0;
        if (hasP && !hasR)
        {
            if (purchaseLines.Count == 1)
                return new OriginRef { Kind = "purchase", PiId = purchaseLines[0] };
            return purchaseLines.Contains(createdDocId) ? new OriginRef { Kind = "purchase", PiId = createdDocId } : none;
        }
        if (!hasP && hasR)
        {
            if (productionIds.Count == 1)
                return new OriginRef { Kind = "production", ItpmId = productionIds[0] };
            return productionIds.Contains(createdDocId) ? new OriginRef { Kind = "production", ItpmId = createdDocId } : none;
        }
        if (hasP)
        {
            bool p = purchaseLines.Contains(createdDocId), r = productionIds.Contains(createdDocId);
            if (p && !r) return new OriginRef { Kind = "purchase", PiId = createdDocId };
            if (r && !p) return new OriginRef { Kind = "production", ItpmId = createdDocId };
        }
        return none;
    }

    static string OriginLabel(OriginRef o) { return o.Kind == "purchase" ? "Purchase" : o.Kind == "production" ? "Production" : "Not Identified"; }

    // ---------- listing ----------
    public static string Items(int staffId)
    {
        DataTable dt = Q("select distinct b.itm_id,im.itm_name,im.itm_code from tbl_item_batch b inner join tbl_item_master im on im.itm_id=b.itm_id where "
            + BranchScope("b") + " order by im.itm_name,im.itm_code", P("@staff", staffId));
        var list = dt.Rows.Cast<DataRow>().Select(r => new { id = I(r["itm_id"]), name = S(r["itm_name"]), code = S(r["itm_code"]) });
        return JsonConvert.SerializeObject(list);
    }

    // Warehouses (branches) of the user that hold at least one batch.
    public static string Branches(int staffId)
    {
        DataTable dt = Q("select tb.branch_id,tb.branch_name from tbl_branch tb where tb.branch_id in (select ub.branch_id from tbl_user_branches ub where ub.user_id=@staff) "
            + "order by tb.branch_name,tb.branch_id", P("@staff", staffId));
        return JsonConvert.SerializeObject(dt.Rows.Cast<DataRow>().Select(r => new { id = I(r["branch_id"]), name = S(r["branch_name"]) }));
    }

    public static string Search(int staffId, int page, int perpage, Dictionary<string, string> filters, string sortBy, string sortDir)
    {
        if (filters == null) filters = new Dictionary<string, string>();
        if (page < 1) page = 1;
        if (perpage != 25 && perpage != 50 && perpage != 100) perpage = 25;

        var ps = new List<MySqlParameter> { P("@staff", staffId) };
        string cond = " where " + BranchScope("b");
        string v;
        if (filters.TryGetValue("search", out v) && v.Trim() != "")
        {
            v = v.Trim();
            cond += " and (im.itm_name like @s or im.itm_code like @s or b.itbh_no like @s or b.itbh_custbatchid like @s or cast(b.itbh_id as char)=@sx)";
            ps.Add(P("@s", "%" + EscapeLike(v) + "%"));
            ps.Add(P("@sx", v));
        }
        int n;
        if (filters.TryGetValue("item", out v) && int.TryParse(v, out n) && n > 0)
        {
            cond += " and b.itm_id=@item";
            ps.Add(P("@item", n));
        }
        if (filters.TryGetValue("branch", out v) && int.TryParse(v, out n) && n > 0)
        {
            cond += " and b.branch_id=@branch";
            ps.Add(P("@branch", n));
        }
        if (filters.TryGetValue("type", out v) && v == "customer")
            cond += " and not " + SystemBatchSql;
        else if (v == "system")
            cond += " and " + SystemBatchSql;
        DateTime d;
        if (filters.TryGetValue("from_date", out v) && TryDate(v, out d))
        {
            cond += " and b.itbh_createddate >= @from";
            ps.Add(P("@from", d.Date));
        }
        if (filters.TryGetValue("to_date", out v) && TryDate(v, out d))
        {
            cond += " and b.itbh_createddate < @to";
            ps.Add(P("@to", d.Date.AddDays(1)));
        }

        string from = " from tbl_item_batch b left join tbl_item_master im on im.itm_id=b.itm_id";
        int count = I(Q("select count(*)" + from + cond, Clone(ps)).Rows[0][0]);
        if (count == 0)
            return JsonConvert.SerializeObject(new { count = 0, rows = new object[0] });

        string key;
        switch (sortBy)
        {
            case "batch": key = "b.itbh_no"; break;
            case "item": key = "im.itm_name"; break;
            default: key = "b.itbh_createddate"; break;
        }
        string dir = (sortDir ?? "").ToLower() == "asc" ? "asc" : "desc";
        int offset = (page - 1) * perpage;

        // Page the ids first, then enrich only those rows.
        string sql = "select b.itbh_id,b.itbh_no,b.itbh_custbatchid,b.itbh_created_doc_id,b.itbh_startqty,b.itbh_currentqty,"
            + "date_format(b.itbh_createddate," + Fmt + ") as created,im.itm_name,im.itm_code,um.tum_name,br.branch_name,"
            + "case when " + SystemBatchSql + " then 'system' else 'customer' end as btype "
            + "from (select b.itbh_id,(" + key + ") as k from tbl_item_batch b left join tbl_item_master im on im.itm_id=b.itm_id" + cond
            + " order by (" + key + ") is null," + "k " + dir + ",b.itbh_id " + dir + " limit " + offset + "," + perpage + ") pg "
            + "inner join tbl_item_batch b on b.itbh_id=pg.itbh_id left join tbl_item_master im on im.itm_id=b.itm_id "
            + "left join tbl_item_uom um on um.tum_id=coalesce(nullif(b.tum_id,0),im.itsv_uom_purchase) left join tbl_branch br on br.branch_id=b.branch_id "
            + "order by pg.k is null,pg.k " + dir + ",b.itbh_id " + dir;
        DataTable rows = Q(sql, Clone(ps));
        if (rows.Rows.Count == 0)
            return JsonConvert.SerializeObject(new { count = count, rows = new object[0] });

        var ids = rows.Rows.Cast<DataRow>().Select(r => I(r["itbh_id"])).ToList();
        var pp = new List<MySqlParameter>();
        string inP = InList("p", ids, pp);
        var purchases = Q("select itbh_id,pi_id from tbl_purchase_items where itbh_id in (" + inP + ")", pp.ToArray()).Rows.Cast<DataRow>()
            .GroupBy(r => I(r["itbh_id"])).ToDictionary(g => g.Key, g => g.Select(r => I(r["pi_id"])).ToList());
        var pr = new List<MySqlParameter>();
        string inR = InList("r", ids, pr);
        var productions = Q("select itbh_id,itpm_id from tbl_item_pro_items where itpi_inputoutput=2 and itbh_id in (" + inR + ")", pr.ToArray()).Rows.Cast<DataRow>()
            .GroupBy(r => I(r["itbh_id"])).ToDictionary(g => g.Key, g => g.Select(r => I(r["itpm_id"])).ToList());
        var pv = new List<MySqlParameter>();
        string inV = InList("v", ids, pv);
        var reserved = Q("select itbh_id,sum(itbsr_qty) as q from tbl_item_batchstock_reserve where itbh_id in (" + inV + ") group by itbh_id", pv.ToArray()).Rows.Cast<DataRow>()
            .ToDictionary(r => I(r["itbh_id"]), r => D(r["q"]));

        var result = rows.Rows.Cast<DataRow>().Select(r =>
        {
            int id = I(r["itbh_id"]);
            List<int> pl, rl;
            decimal res;
            purchases.TryGetValue(id, out pl);
            productions.TryGetValue(id, out rl);
            reserved.TryGetValue(id, out res);
            OriginRef o = ResolveOrigin(I(r["itbh_created_doc_id"]), pl ?? new List<int>(), rl ?? new List<int>());
            return new
            {
                id,
                no = S(r["itbh_no"]),
                cust = S(r["itbh_custbatchid"]),
                type = S(r["btype"]),
                created = Dt(r["created"]),
                item = S(r["itm_name"]),
                code = S(r["itm_code"]),
                branch = S(r["branch_name"]),
                uom = S(r["tum_name"]),
                origin = o.Kind,
                originLabel = OriginLabel(o),
                current = D(r["itbh_currentqty"]),
                reserved = res,
                free = D(r["itbh_currentqty"]) - res
            };
        });
        return JsonConvert.SerializeObject(new { count = count, rows = result });
    }

    static bool TryDate(string v, out DateTime d)
    {
        return DateTime.TryParseExact((v ?? "").Replace("/", "-"), "dd-MM-yyyy", CultureInfo.InvariantCulture, DateTimeStyles.None, out d);
    }

    static MySqlParameter[] Clone(List<MySqlParameter> source)
    {
        return source.Select(p => new MySqlParameter(p.ParameterName, p.Value)).ToArray();
    }

    // ---------- batch header ----------
    class Batch
    {
        public int Id, ItmId, BranchId, TumId, DocId;
        public string No, Cust, Item, Code, Uom, Branch, Created, CreatedBy, Type;
        public decimal Start, Current;
    }

    static Batch LoadBatch(int staffId, int batchId)
    {
        DataTable dt = Q("select b.itbh_id,b.itbh_no,b.itbh_custbatchid,b.itm_id,b.branch_id,coalesce(nullif(b.tum_id,0),im.itsv_uom_purchase) as tum_id,b.itbh_created_doc_id,b.itbh_startqty,b.itbh_currentqty,"
            + "date_format(b.itbh_createddate," + Fmt + ") as created,im.itm_name,im.itm_code,um.tum_name,br.branch_name,ud.first_name,ud.last_name,"
            + "case when " + SystemBatchSql + " then 'system' else 'customer' end as btype "
            + "from tbl_item_batch b left join tbl_item_master im on im.itm_id=b.itm_id left join tbl_item_uom um on um.tum_id=coalesce(nullif(b.tum_id,0),im.itsv_uom_purchase) "
            + "left join tbl_branch br on br.branch_id=b.branch_id left join tbl_user_details ud on ud.user_id=b.itbh_createduser "
            + "where b.itbh_id=@b and " + BranchScope("b"), P("@b", batchId), P("@staff", staffId));
        if (dt.Rows.Count == 0)
            return null;
        DataRow r = dt.Rows[0];
        return new Batch
        {
            Id = I(r["itbh_id"]), ItmId = I(r["itm_id"]), BranchId = I(r["branch_id"]), TumId = I(r["tum_id"]), DocId = I(r["itbh_created_doc_id"]),
            No = S(r["itbh_no"]), Cust = S(r["itbh_custbatchid"]), Item = S(r["itm_name"]), Code = S(r["itm_code"]), Uom = S(r["tum_name"]),
            Branch = S(r["branch_name"]), Created = Dt(r["created"]), CreatedBy = Name(r["first_name"], r["last_name"]), Type = S(r["btype"]),
            Start = D(r["itbh_startqty"]), Current = D(r["itbh_currentqty"])
        };
    }

    // ---------- links and labels ----------
    static string PurchaseUrl(int pmId) { return "../web_purchase/managepurchase.aspx?purchaseId=" + pmId; }
    static string InvoiceUrl(int smId) { return "../web_sales/manageorders.aspx?orderId=" + smId; }
    static string OrderUrl(int smoId, string tab) { return "../web_sales/view_sales_order.aspx?smoId=" + smoId + (tab == null ? "" : "#" + tab); }
    static string BatchUrl(int batchId) { return "track_batch_details.aspx?batchId=" + batchId; }

    static string[] InvoiceStatus(int s)
    {
        switch (s)
        {
            case 0: return new[] { "New", "label label-warning" };
            case 1: return new[] { "Processed", "label label-primary" };
            case 2: return new[] { "Delivered", "label label-success" };
            case 3: return new[] { "To be confirmed", "label label-info" };
            case 4: return new[] { "Cancelled", "label label-default" };
            case 5: return new[] { "Rejected", "label label-default" };
            case 6: return new[] { "Pending", "label label-default" };
            default: return new[] { "Status " + s, "label label-default" };
        }
    }

    static string[] PurchaseStatus(int s)
    {
        return s == 1 ? new[] { "Completed", "label label-success" } : new[] { "Cancelled", "label label-default" };
    }

    static string[] OrderStatus(int s)
    {
        string n = SalesOrderStatus.Name(s);
        return new[] { n == "" ? "Status " + s : n, SalesOrderStatus.Css(s) };
    }

    static bool ValidInvoice(int status) { return status != 4 && status != 5; }

    static string OrderNo(int smoId, string invoiceNo) { return "#" + smoId + (invoiceNo == "" ? "" : " (" + invoiceNo + ")"); }

    // ---------- overview ----------
    public static string Overview(int staffId, int batchId)
    {
        Batch b = LoadBatch(staffId, batchId);
        if (b == null)
            return "{\"notFound\":true}";

        var pur = Q("select pi.pi_id,pi.pm_id,pi.pi_qty,pi.sio_id,pm.pm_invoice_no,pm.pm_status,ifnull(pm.pm_is_inter_stock_transfer_invoice,0) as ist,pm.sm_id,pm.pm_ref_no,"
            + "date_format(pm.pm_date," + Fmt + ") as pm_date,v.vn_name,br.branch_name,um.tum_name "
            + "from tbl_purchase_items pi inner join tbl_purchase_master pm on pm.pm_id=pi.pm_id left join tbl_vendor v on v.vn_id=pm.vn_id "
            + "left join tbl_branch br on br.branch_id=pm.branch_id left join tbl_item_uom um on um.tum_id=pi.itsv_uom_purchase where pi.itbh_id=@b order by pi.pi_id", P("@b", batchId));
        var pro = Q("select pi.itpm_id,pi.itpi_quantity,pm.itpm_doc_no,date_format(pm.itpm_docdate," + Fmt + ") as docdate,date_format(pm.itpm_createddate," + Fmt + ") as created "
            + "from tbl_item_pro_items pi inner join tbl_item_pro_master pm on pm.itpm_id=pi.itpm_id where pi.itbh_id=@b and pi.itpi_inputoutput=2 order by pi.itpi_id", P("@b", batchId));

        OriginRef o = ResolveOrigin(b.DocId, pur.Rows.Cast<DataRow>().Select(r => I(r["pi_id"])).ToList(), pro.Rows.Cast<DataRow>().Select(r => I(r["itpm_id"])).ToList());
        object origin;
        if (o.Kind == "purchase")
        {
            DataRow r = pur.Rows.Cast<DataRow>().First(x => I(x["pi_id"]) == o.PiId);
            origin = new
            {
                kind = "purchase",
                title = "Purchase Entry",
                entryId = I(r["pm_id"]),
                number = S(r["pm_invoice_no"]) != "" ? S(r["pm_invoice_no"]) : "#" + I(r["pm_id"]),
                party = S(r["vn_name"]),
                partyLabel = I(r["ist"]) == 1 ? "Source Warehouse" : "Supplier",
                date = Dt(r["pm_date"]),
                qty = D(r["pi_qty"]),
                uom = S(r["tum_name"]),
                item = b.Item,
                code = b.Code,
                status = PurchaseStatus(I(r["pm_status"])),
                interstock = I(r["ist"]) == 1,
                url = PurchaseUrl(I(r["pm_id"])),
                linkLabel = "Open Purchase Entry"
            };
        }
        else if (o.Kind == "production")
        {
            DataRow r = pro.Rows.Cast<DataRow>().First(x => I(x["itpm_id"]) == o.ItpmId);
            string orderUrl = null, orderNo = null;
            Match m = ProCustBatch.Match(b.Cust);
            if (m.Success && int.Parse(m.Groups[1].Value) == o.ItpmId)
            {
                DataTable so = Q("select smo.smo_id,smo.smo_invoice_no from tbl_sales_items_order sio inner join tbl_sales_master_order smo on smo.smo_id=sio.smo_id "
                    + "where sio.sio_id=@s and sio.itbs_id=(select itbs_id from tbl_item_batch where itbh_id=@b) and smo.branch_id=@br",
                    P("@s", int.Parse(m.Groups[2].Value)), P("@b", batchId), P("@br", b.BranchId));
                if (so.Rows.Count > 0)
                {
                    orderUrl = OrderUrl(I(so.Rows[0]["smo_id"]), "tabProduction");
                    orderNo = OrderNo(I(so.Rows[0]["smo_id"]), S(so.Rows[0]["smo_invoice_no"]));
                }
            }
            origin = new
            {
                kind = "production",
                title = "Production Entry",
                entryId = I(r["itpm_id"]),
                number = S(r["itpm_doc_no"]),
                party = (string)null,
                partyLabel = (string)null,
                date = Dt(r["created"]) ?? Dt(r["docdate"]),
                qty = D(r["itpi_quantity"]),
                uom = b.Uom,
                item = b.Item,
                code = b.Code,
                status = new[] { "Completed", "label label-success" },
                interstock = false,
                url = orderUrl,
                linkLabel = orderNo == null ? null : "Open Sales Order " + orderNo + " (Production tab)"
            };
        }
        else
        {
            origin = new { kind = "none", title = "Origin Not Identified" };
        }

        return JsonConvert.SerializeObject(new
        {
            notFound = false,
            batch = new
            {
                id = b.Id, no = b.No, cust = b.Cust, item = b.Item, code = b.Code, type = b.Type, created = b.Created, createdBy = b.CreatedBy,
                branch = b.Branch, uom = b.Uom, original = b.Start, current = b.Current, originLabel = OriginLabel(o)
            },
            origin
        });
    }

    // ---------- history ----------
    class Ev
    {
        public string Ts, Type, Title, Ref, Url, Uom, StatusText, StatusCss, Note;
        public decimal? Qty;
        public int Seq;
    }

    public static string History(int staffId, int batchId)
    {
        Batch b = LoadBatch(staffId, batchId);
        if (b == null)
            return "{\"notFound\":true}";
        var pb = P("@b", batchId);

        // one query per source; every one of them is keyed on itbh_id
        DataTable pur = Q("select pi.pi_id,pi.pm_id,pi.pi_qty,pi.sio_id,pi.itsv_uom_purchase as tum,pm.pm_invoice_no,pm.pm_status,ifnull(pm.pm_is_inter_stock_transfer_invoice,0) as ist,pm.sm_id,pm.pm_ref_no,pm.branch_id,"
            + "date_format(pm.pm_date," + Fmt + ") as pm_date,v.vn_name,br.branch_name,um.tum_name "
            + "from tbl_purchase_items pi inner join tbl_purchase_master pm on pm.pm_id=pi.pm_id left join tbl_vendor v on v.vn_id=pm.vn_id "
            + "left join tbl_branch br on br.branch_id=pm.branch_id left join tbl_item_uom um on um.tum_id=pi.itsv_uom_purchase where pi.itbh_id=@b order by pm.pm_id,pi.pi_id", pb);
        DataTable pro = Q("select pi.itpi_id,pi.itpm_id,pi.itpi_inputoutput as io,pi.itpi_quantity,pi.itpi_cost,pm.itpm_doc_no,date_format(pm.itpm_docdate," + Fmt + ") as docdate,"
            + "date_format(pm.itpm_createddate," + Fmt + ") as created,ud.first_name,ud.last_name "
            + "from tbl_item_pro_items pi inner join tbl_item_pro_master pm on pm.itpm_id=pi.itpm_id left join tbl_user_details ud on ud.user_id=pm.itpm_createdby "
            + "where pi.itbh_id=@b order by pi.itpm_id,pi.itpi_serial", pb);
        DataTable res = Q("select r.itbsr_id,r.sio_id,r.itbsr_qty,date_format(r.itbrs_date," + Fmt + ") as rdate,sio.smo_id,sio.itm_name as line_item "
            + "from tbl_item_batchstock_reserve r left join tbl_sales_items_order sio on sio.sio_id=r.sio_id where r.itbh_id=@b order by r.itbsr_id", pb);
        DataTable inv = Q("select sm.sm_id,sm.sm_invoice_no,date_format(sm.sm_date," + Fmt + ") as sm_date,ifnull(sm.sm_delivery_status,0) as st,sm.sm_refid,ifnull(sm.sm_is_inter_stock_transfer_invoice,0) as ist,"
            + "sm.cust_id,c.cust_name,sm.branch_id,br.branch_name,l.lq,date_format(l.ld," + Fmt + ") as ld,d.dq,d.dtum "
            + "from (select action_ref_id as sm_id from tbl_stock_transactions where itbh_id=@b and action_type=" + InvoiceAction
            + " union select sm_id from tbl_sales_items where itbh_id=@b) k "
            + "inner join tbl_sales_master sm on sm.sm_id=k.sm_id "
            + "left join (select action_ref_id as sm_id,cast(sum(dr_qty) as decimal(18,6)) as lq,max(date) as ld from tbl_stock_transactions where itbh_id=@b and action_type=" + InvoiceAction + " group by action_ref_id) l on l.sm_id=sm.sm_id "
            + "left join (select si.sm_id,sum(si.si_qty) as dq,min(sio.tum_id) as dtum from tbl_sales_items si left join tbl_sales_items_order sio on sio.sio_id=si.sio_id where si.itbh_id=@b group by si.sm_id) d on d.sm_id=sm.sm_id "
            + "left join tbl_customer c on c.cust_id=sm.cust_id left join tbl_branch br on br.branch_id=sm.branch_id order by sm.sm_id", pb);
        DataTable led = Q("select id,action_type,action_ref_id,narration,dr_qty,cr_qty,date_format(date," + Fmt + ") as d from tbl_stock_transactions where itbh_id=@b order by date,id", pb);

        var purchases = pur.Rows.Cast<DataRow>().ToList();
        var proRows = pro.Rows.Cast<DataRow>().ToList();
        OriginRef origin = ResolveOrigin(b.DocId, purchases.Select(r => I(r["pi_id"])).ToList(), proRows.Where(r => I(r["io"]) == 2).Select(r => I(r["itpm_id"])).ToList());

        // production peers: the other rows of each production, and the sales order a production was made for (same rule as production history)
        var itpmIds = proRows.Select(r => I(r["itpm_id"])).Distinct().ToList();
        var peers = new List<DataRow>();
        var prodOrder = new Dictionary<int, int>(); // itpm_id -> smo_id
        if (itpmIds.Count > 0)
        {
            var ps = new List<MySqlParameter>();
            string inIds = InList("m", itpmIds, ps);
            DataTable pt = Q("select o.itpm_id,o.itpi_inputoutput as io,o.itpi_quantity as q,o.itbh_id,ob.itbh_no,ob.itbh_custbatchid as cb,ob.itbs_id,ob.branch_id,im.itm_name,im.itm_code "
                + "from tbl_item_pro_items o inner join tbl_item_batch ob on ob.itbh_id=o.itbh_id left join tbl_item_master im on im.itm_id=ob.itm_id "
                + "where o.itpm_id in (" + inIds + ") order by o.itpm_id,o.itpi_serial", ps.ToArray());
            peers = pt.Rows.Cast<DataRow>().ToList();
            var sioByItpm = new Dictionary<int, Tuple<int, int, int>>(); // itpm -> (sio, itbs, branch)
            foreach (DataRow r in peers.Where(x => I(x["io"]) == 2))
            {
                Match m = ProCustBatch.Match(S(r["cb"]));
                if (m.Success && int.Parse(m.Groups[1].Value) == I(r["itpm_id"]))
                    sioByItpm[I(r["itpm_id"])] = Tuple.Create(int.Parse(m.Groups[2].Value), I(r["itbs_id"]), I(r["branch_id"]));
            }
            if (sioByItpm.Count > 0)
            {
                var sp = new List<MySqlParameter>();
                string inSio = InList("s", sioByItpm.Values.Select(x => x.Item1).Distinct(), sp);
                var sios = Q("select sio.sio_id,sio.itbs_id,smo.smo_id,smo.branch_id from tbl_sales_items_order sio inner join tbl_sales_master_order smo on smo.smo_id=sio.smo_id where sio.sio_id in (" + inSio + ")", sp.ToArray())
                    .Rows.Cast<DataRow>().ToDictionary(r => I(r["sio_id"]));
                foreach (var kv in sioByItpm)
                {
                    DataRow s;
                    if (sios.TryGetValue(kv.Value.Item1, out s) && I(s["itbs_id"]) == kv.Value.Item2 && I(s["branch_id"]) == kv.Value.Item3)
                        prodOrder[kv.Key] = I(s["smo_id"]);
                }
            }
        }

        // inter-stock: purchases that received an invoice (for transfer-out rows) and the source batches of a received purchase (transfer-in rows)
        var transferInvoices = inv.Rows.Cast<DataRow>().Where(r => I(r["ist"]) == 1).ToList();
        var destPurchases = new Dictionary<int, DataRow>();      // sm_id -> purchase header
        var destBatches = new Dictionary<int, List<DataRow>>();  // pm_id -> batches of the same item received by that purchase
        if (transferInvoices.Count > 0)
        {
            var ps = new List<MySqlParameter>();
            string inSm = InList("t", transferInvoices.Select(r => I(r["sm_id"])), ps);
            DataTable dp = Q("select pm.pm_id,pm.pm_invoice_no,pm.pm_status,pm.branch_id,pm.sm_id,pm.pm_ref_no,date_format(pm.pm_date," + Fmt + ") as pm_date,br.branch_name "
                + "from tbl_purchase_master pm left join tbl_branch br on br.branch_id=pm.branch_id "
                + "where pm.pm_is_inter_stock_transfer_invoice=1 and (pm.sm_id in (" + inSm + ") or pm.pm_ref_no in (" + inSm + ")) order by pm.pm_id", ps.ToArray());
            foreach (DataRow inv1 in transferInvoices)
            {
                int sm = I(inv1["sm_id"]);
                DataRow hit = dp.Rows.Cast<DataRow>().FirstOrDefault(p => I(p["sm_id"]) == sm) ?? dp.Rows.Cast<DataRow>().FirstOrDefault(p => I(p["sm_id"]) == 0 && I(p["pm_ref_no"]) == sm);
                if (hit != null)
                    destPurchases[sm] = hit;
            }
            if (destPurchases.Count > 0)
            {
                var bp = new List<MySqlParameter> { P("@itm", b.ItmId) };
                string inPm = InList("q", destPurchases.Values.Select(p => I(p["pm_id"])).Distinct(), bp);
                foreach (DataRow r in Q("select pi.pm_id,b2.itbh_id,b2.itbh_no from tbl_purchase_items pi inner join tbl_item_batch b2 on b2.itbh_id=pi.itbh_id "
                    + "where pi.pm_id in (" + inPm + ") and b2.itm_id=@itm order by pi.pm_id,pi.pi_id", bp.ToArray()).Rows)
                {
                    int pm = I(r["pm_id"]);
                    if (!destBatches.ContainsKey(pm)) destBatches[pm] = new List<DataRow>();
                    destBatches[pm].Add(r);
                }
            }
        }
        var sourceBatches = new Dictionary<int, List<DataRow>>(); // sm_id -> batches of the same item taken by the source invoice
        var receivedFrom = purchases.Where(r => I(r["ist"]) == 1).Select(r => I(r["sm_id"]) > 0 ? I(r["sm_id"]) : I(r["pm_ref_no"])).Where(x => x > 0).Distinct().ToList();
        if (receivedFrom.Count > 0)
        {
            var ps = new List<MySqlParameter> { P("@itm", b.ItmId), P("@self", batchId) };
            string inSm = InList("u", receivedFrom, ps);
            foreach (DataRow r in Q("select x.sm_id,b2.itbh_id,b2.itbh_no from (select sm_id,itbh_id from tbl_sales_items where itbh_id>0 and sm_id in (" + inSm + ") "
                + "union select action_ref_id,itbh_id from tbl_stock_transactions where action_type=" + InvoiceAction + " and itbh_id>0 and action_ref_id in (" + inSm + ")) x "
                + "inner join tbl_item_batch b2 on b2.itbh_id=x.itbh_id where b2.itm_id=@itm and b2.itbh_id<>@self order by x.sm_id,b2.itbh_id", ps.ToArray()).Rows)
            {
                int sm = I(r["sm_id"]);
                if (!sourceBatches.ContainsKey(sm)) sourceBatches[sm] = new List<DataRow>();
                sourceBatches[sm].Add(r);
            }
        }
        var invoiceHeaders = new Dictionary<int, DataRow>(); // sm_id -> invoice header for transfer-in source lookups
        if (receivedFrom.Count > 0)
        {
            var ps = new List<MySqlParameter>();
            string inSm = InList("h", receivedFrom, ps);
            foreach (DataRow r in Q("select sm.sm_id,sm.sm_invoice_no,sm.sm_refid,ifnull(sm.sm_delivery_status,0) as st,sm.branch_id,br.branch_name,date_format(sm.sm_date," + Fmt + ") as sm_date "
                + "from tbl_sales_master sm left join tbl_branch br on br.branch_id=sm.branch_id where sm.sm_id in (" + inSm + ")", ps.ToArray()).Rows)
                invoiceHeaders[I(r["sm_id"])] = r;
        }

        // sales orders connected through reservations, invoices (sm_refid) and production
        var smoIds = new HashSet<int>();
        foreach (DataRow r in res.Rows) if (I(r["smo_id"]) > 0) smoIds.Add(I(r["smo_id"]));
        foreach (DataRow r in inv.Rows) if (I(r["sm_refid"]) > 0) smoIds.Add(I(r["sm_refid"]));
        foreach (int smo in prodOrder.Values) smoIds.Add(smo);
        foreach (DataRow r in invoiceHeaders.Values) if (I(r["sm_refid"]) > 0) smoIds.Add(I(r["sm_refid"]));
        var orders = new Dictionary<int, DataRow>();
        if (smoIds.Count > 0)
        {
            var ps = new List<MySqlParameter>();
            string inSmo = InList("o", smoIds, ps);
            foreach (DataRow r in Q("select smo.smo_id,smo.smo_invoice_no,date_format(smo.smo_date," + Fmt + ") as smo_date,smo.smo_delivery_status as st,smo.cust_id,c.cust_name "
                + "from tbl_sales_master_order smo left join tbl_customer c on c.cust_id=smo.cust_id where smo.smo_id in (" + inSmo + ")", ps.ToArray()).Rows)
                orders[I(r["smo_id"])] = r;
        }

        var events = new List<Ev>();
        int seq = 0;
        Action<Ev> add = e => { e.Seq = seq++; events.Add(e); };

        // ----- origin / purchases -----
        var purchaseList = new List<object>();
        decimal transferredIn = 0m;
        bool partial = false;
        var transfers = new List<object>();
        foreach (DataRow r in purchases)
        {
            int pm = I(r["pm_id"]);
            bool ist = I(r["ist"]) == 1;
            bool isOrigin = origin.Kind == "purchase" && I(r["pi_id"]) == origin.PiId;
            string number = S(r["pm_invoice_no"]) != "" ? S(r["pm_invoice_no"]) : "#" + pm;
            string[] st = PurchaseStatus(I(r["pm_status"]));
            purchaseList.Add(new
            {
                id = pm, number, date = Dt(r["pm_date"]), party = S(r["vn_name"]), branch = S(r["branch_name"]), qty = D(r["pi_qty"]), uom = S(r["tum_name"]),
                status = st, role = isOrigin ? "Origin" : "Reference", interstock = ist, url = PurchaseUrl(pm)
            });
            if (ist)
            {
                int src = I(r["sm_id"]) > 0 ? I(r["sm_id"]) : I(r["pm_ref_no"]);
                DataRow ih;
                invoiceHeaders.TryGetValue(src, out ih);
                List<DataRow> sb;
                sourceBatches.TryGetValue(src, out sb);
                decimal? qtyBatch = I(r["tum"]) == b.TumId ? D(r["pi_qty"]) : (decimal?)null;
                if (qtyBatch.HasValue) { if (I(r["pm_status"]) == 1) transferredIn += qtyBatch.Value; }
                else partial = true;
                transfers.Add(new
                {
                    direction = "in",
                    id = pm,
                    number,
                    date = Dt(r["pm_date"]),
                    fromBranch = ih == null ? "" : S(ih["branch_name"]),
                    toBranch = S(r["branch_name"]),
                    qty = D(r["pi_qty"]),
                    uom = S(r["tum_name"]),
                    status = st,
                    related = ih == null ? null : "Invoice " + (S(ih["sm_invoice_no"]) != "" ? S(ih["sm_invoice_no"]) : "#" + src),
                    relatedUrl = ih == null ? null : InvoiceUrl(src),
                    batches = (sb ?? new List<DataRow>()).Select(x => new { id = I(x["itbh_id"]), no = S(x["itbh_no"]), url = BatchUrl(I(x["itbh_id"])) }).ToList(),
                    batchesLabel = "Source batch",
                    url = PurchaseUrl(pm),
                    urlLabel = "Purchase " + number
                });
                add(new Ev { Ts = Dt(r["pm_date"]), Type = "transfer_in", Title = "Interstock Transfer In", Ref = "Purchase " + number, Url = PurchaseUrl(pm), Qty = qtyBatch ?? D(r["pi_qty"]), Uom = S(r["tum_name"]), StatusText = st[0], StatusCss = st[1] });
            }
        }

        // ----- production -----
        var productionList = new List<object>();
        decimal usedInProduction = 0m;
        var prodUse = new Dictionary<int, decimal>(); // smo_id -> qty consumed in production
        foreach (DataRow r in proRows)
        {
            int itpm = I(r["itpm_id"]);
            bool output = I(r["io"]) == 2;
            decimal q = D(r["itpi_quantity"]);
            int smo;
            bool hasOrder = prodOrder.TryGetValue(itpm, out smo);
            var other = peers.Where(x => I(x["itpm_id"]) == itpm && I(x["io"]) == (output ? 1 : 2)).Select(x => new
            {
                id = I(x["itbh_id"]), no = S(x["itbh_no"]), item = S(x["itm_name"]), qty = D(x["q"]), url = BatchUrl(I(x["itbh_id"]))
            }).ToList();
            string created = Dt(r["created"]) ?? Dt(r["docdate"]);
            string url = hasOrder ? OrderUrl(smo, "tabProduction") : null;
            productionList.Add(new
            {
                id = itpm, number = S(r["itpm_doc_no"]), date = created, role = output ? (origin.Kind == "production" && origin.ItpmId == itpm ? "Produced (origin)" : "Produced") : "Raw material consumed",
                qty = q, uom = b.Uom, createdBy = Name(r["first_name"], r["last_name"]),
                relatedLabel = output ? "Raw materials used" : "Finished item produced", related = other, order = hasOrder && orders.ContainsKey(smo) ? OrderNo(smo, S(orders[smo]["smo_invoice_no"])) : null,
                url, status = new[] { "Completed", "label label-success" }
            });
            if (!output)
            {
                usedInProduction += q;
                if (hasOrder) prodUse[smo] = (prodUse.ContainsKey(smo) ? prodUse[smo] : 0m) + q;
            }
            add(new Ev { Ts = created, Type = "production", Title = output ? "Produced" : "Consumed in Production", Ref = S(r["itpm_doc_no"]), Url = url, Qty = q, Uom = b.Uom, StatusText = "Completed", StatusCss = "label label-success" });
        }

        // ----- invoices and transfer-out -----
        var invoiceList = new List<object>();
        decimal invoiced = 0m, transferredOut = 0m, cancelledConsumed = 0m;
        var connectedOrders = new HashSet<int>();
        var invUse = new Dictionary<int, decimal>();      // smo_id -> qty invoiced
        var transferUse = new Dictionary<int, decimal>(); // smo_id -> qty transferred
        foreach (DataRow r in inv.Rows)
        {
            int sm = I(r["sm_id"]);
            int status = I(r["st"]);
            bool ist = I(r["ist"]) == 1;
            string[] st = InvoiceStatus(status);
            // ledger quantity is in the batch UOM; a direct line quantity only when its UOM is the batch UOM
            decimal? qty = DN(r["lq"]);
            string uom = b.Uom;
            if (qty == null)
            {
                decimal? dq = DN(r["dq"]);
                if (dq.HasValue && I(r["dtum"]) == b.TumId) qty = dq;
                else { partial = true; uom = "invoice line unit"; qty = dq; }
            }
            bool exact = DN(r["lq"]) != null || I(r["dtum"]) == b.TumId;
            string number = S(r["sm_invoice_no"]) != "" ? S(r["sm_invoice_no"]) : "#" + sm;
            string date = Dt(r["ld"]) ?? Dt(r["sm_date"]);
            int smo = I(r["sm_refid"]);
            DataRow od = null;
            if (smo > 0) orders.TryGetValue(smo, out od);
            string orderRef = od == null ? null : OrderNo(smo, S(od["smo_invoice_no"]));
            if (smo > 0) connectedOrders.Add(smo);
            // cancelling an invoice does not give the stock back to the batch, so its quantity is reported separately
            if (!ValidInvoice(status) && exact && qty.HasValue) cancelledConsumed += qty.Value;
            if (!ist)
            {
                if (ValidInvoice(status) && exact && qty.HasValue)
                {
                    invoiced += qty.Value;
                    if (smo > 0) invUse[smo] = (invUse.ContainsKey(smo) ? invUse[smo] : 0m) + qty.Value;
                }
                invoiceList.Add(new
                {
                    id = sm, number, date = Dt(r["sm_date"]), customer = S(r["cust_name"]), order = orderRef, orderUrl = od == null ? null : OrderUrl(smo, "tabInvoices"),
                    qty, uom, status = st, url = InvoiceUrl(sm)
                });
                add(new Ev { Ts = date, Type = "invoice", Title = "Invoice Generated", Ref = number, Url = InvoiceUrl(sm), Qty = qty, Uom = uom, StatusText = st[0], StatusCss = st[1] });
            }
            else
            {
                DataRow dest;
                destPurchases.TryGetValue(sm, out dest);
                List<DataRow> db;
                if (ValidInvoice(status) && exact && qty.HasValue)
                {
                    transferredOut += qty.Value;
                    if (smo > 0) transferUse[smo] = (transferUse.ContainsKey(smo) ? transferUse[smo] : 0m) + qty.Value;
                }
                string[] tst = !ValidInvoice(status) ? InvoiceStatus(status) : dest == null ? new[] { "Pending", "label label-warning" } : PurchaseStatus(I(dest["pm_status"]));
                db = dest == null ? new List<DataRow>() : (destBatches.TryGetValue(I(dest["pm_id"]), out db) ? db : new List<DataRow>());
                transfers.Add(new
                {
                    direction = "out",
                    id = sm,
                    number,
                    date,
                    fromBranch = S(r["branch_name"]),
                    toBranch = dest == null ? "" : S(dest["branch_name"]),
                    qty,
                    uom,
                    status = tst,
                    related = dest == null ? null : "Purchase " + (S(dest["pm_invoice_no"]) != "" ? S(dest["pm_invoice_no"]) : "#" + I(dest["pm_id"])),
                    relatedUrl = dest == null ? null : PurchaseUrl(I(dest["pm_id"])),
                    batches = db.Select(x => new { id = I(x["itbh_id"]), no = S(x["itbh_no"]), url = BatchUrl(I(x["itbh_id"])) }).ToList(),
                    batchesLabel = "Received as batch",
                    url = InvoiceUrl(sm),
                    urlLabel = "Invoice " + number
                });
                add(new Ev { Ts = date, Type = "transfer_out", Title = "Interstock Transfer Out", Ref = "Invoice " + number, Url = InvoiceUrl(sm), Qty = qty, Uom = uom, StatusText = tst[0], StatusCss = tst[1] });
            }
        }

        // ----- reservations, grouped by sales order -----
        decimal reservedQty = 0m;
        var resByOrder = new Dictionary<int, List<DataRow>>();
        foreach (DataRow r in res.Rows)
        {
            reservedQty += D(r["itbsr_qty"]);
            int smo = I(r["smo_id"]);
            if (!resByOrder.ContainsKey(smo)) resByOrder[smo] = new List<DataRow>();
            resByOrder[smo].Add(r);
        }
        var orderKeys = new HashSet<int>(resByOrder.Keys.Where(k => k > 0));
        foreach (int k in invUse.Keys.Concat(transferUse.Keys).Concat(prodUse.Keys).Concat(connectedOrders)) orderKeys.Add(k);
        var reservationList = new List<object>();
        foreach (int smo in orderKeys.OrderBy(x => x))
        {
            DataRow od;
            orders.TryGetValue(smo, out od);
            List<DataRow> rr;
            resByOrder.TryGetValue(smo, out rr);
            decimal reservedNow = rr == null ? 0m : rr.Sum(x => D(x["itbsr_qty"]));
            decimal iq = invUse.ContainsKey(smo) ? invUse[smo] : 0m, tq = transferUse.ContainsKey(smo) ? transferUse[smo] : 0m, pq = prodUse.ContainsKey(smo) ? prodUse[smo] : 0m;
            string rdate = rr == null ? null : rr.Select(x => Dt(x["rdate"])).Where(x => x != null).OrderBy(x => x).FirstOrDefault();
            string[] ost = od == null ? new[] { "", "label label-default" } : OrderStatus(I(od["st"]));
            bool consumed = iq + tq + pq > 0;
            string[] rst = reservedNow > 0 ? new[] { "Reserved", "label label-info" } : consumed ? new[] { "Consumed", "label label-success" } : new[] { "No active reservation", "label label-default" };
            reservationList.Add(new
            {
                id = smo, number = od == null ? "#" + smo : OrderNo(smo, S(od["smo_invoice_no"])), customer = od == null ? "" : S(od["cust_name"]), date = od == null ? null : Dt(od["smo_date"]),
                reservedNow, reservationDate = rdate, invoiced = iq, transferred = tq, production = pq, orderStatus = ost, status = rst, rows = rr == null ? 0 : rr.Count,
                url = OrderUrl(smo, "tabReserved")
            });
            if (rr != null)
                foreach (DataRow x in rr)
                    add(new Ev { Ts = Dt(x["rdate"]), Type = "reservation", Title = "Reserved", Ref = od == null ? "Sales order #" + smo : "Sales order " + OrderNo(smo, S(od["smo_invoice_no"])), Url = OrderUrl(smo, "tabReserved"), Qty = D(x["itbsr_qty"]), Uom = b.Uom, StatusText = "Reserved", StatusCss = "label label-info", Note = Dt(x["rdate"]) == null ? "Reservation date not recorded" : null });
        }
        // reservations whose order line no longer resolves
        int orphan = resByOrder.ContainsKey(0) ? resByOrder[0].Count : 0;

        // ----- stock ledger: explain it with the records above, list the rest as "other" -----
        var coveredPurchases = new HashSet<int>(purchases.Select(r => I(r["pm_id"])));
        var coveredInvoices = new HashSet<int>(inv.Rows.Cast<DataRow>().Select(r => I(r["sm_id"])));
        var coveredProd = new HashSet<int>(itpmIds);
        var otherList = new List<object>();
        string[] otherNames = { "", "Sale", "Purchase", "Sales Return", "Purchase Return", "Withdrawal", "Deposit", "Debit Note", "Stock Transfer", "Income", "Expense", "Manual Item Edit", "Item Conversion" };
        foreach (DataRow r in led.Rows)
        {
            int type = I(r["action_type"]), refId = I(r["action_ref_id"]);
            decimal cr = D(r["cr_qty"]), dr = D(r["dr_qty"]);
            bool covered = (type == InvoiceAction && coveredInvoices.Contains(refId)) || (type == PurchaseAction && coveredPurchases.Contains(refId)) || (type == ProductionAction && coveredProd.Contains(refId));
            if (covered)
            {
                // the ledger confirms when stock actually arrived
                if (type == PurchaseAction && cr > 0 && !purchases.Any(p => I(p["pm_id"]) == refId && I(p["ist"]) == 1))
                    add(new Ev { Ts = Dt(r["d"]), Type = "received", Title = "Stock Received", Ref = "Purchase " + PurchaseNumber(purchases, refId), Url = PurchaseUrl(refId), Qty = cr, Uom = b.Uom, StatusText = "Posted", StatusCss = "label label-success" });
                continue;
            }
            string typeName = type > 0 && type < otherNames.Length ? otherNames[type] : "Action " + type;
            string url = type == InvoiceAction ? InvoiceUrl(refId) : type == PurchaseAction ? PurchaseUrl(refId) : null;
            decimal qty = cr > 0 ? cr : dr;
            otherList.Add(new { id = I(r["id"]), type = typeName, reference = "#" + refId, date = Dt(r["d"]), qty, direction = cr > 0 ? "in" : "out", uom = b.Uom, note = S(r["narration"]), status = new[] { "Posted", "label label-default" }, url });
            add(new Ev { Ts = Dt(r["d"]), Type = "other", Title = typeName + " (stock ledger)", Ref = "#" + refId, Url = url, Qty = qty, Uom = b.Uom, StatusText = "Posted", StatusCss = "label label-default" });
        }

        // batch creation event comes first
        string originRef = null, originUrl = null;
        if (origin.Kind == "purchase")
        {
            DataRow r = purchases.First(x => I(x["pi_id"]) == origin.PiId);
            originRef = "Purchase Entry " + PurchaseNumber(purchases, I(r["pm_id"]));
            originUrl = PurchaseUrl(I(r["pm_id"]));
        }
        else if (origin.Kind == "production")
        {
            DataRow r = proRows.First(x => I(x["itpm_id"]) == origin.ItpmId && I(x["io"]) == 2);
            originRef = "Production Entry " + S(r["itpm_doc_no"]);
            int smo;
            originUrl = prodOrder.TryGetValue(origin.ItpmId, out smo) ? OrderUrl(smo, "tabProduction") : null;
        }
        events.Insert(0, new Ev
        {
            Ts = b.Created, Type = "created", Title = "Batch Created", Ref = originRef ?? "Origin Not Identified", Url = originUrl, Qty = b.Start, Uom = b.Uom,
            StatusText = origin.Kind == "none" ? "Origin unknown" : "Created", StatusCss = origin.Kind == "none" ? "label label-warning" : "label label-success"
        });

        // chronological; events without a recorded date follow the creation event in the order they were found
        var ordered = events.OrderBy(e => e.Type == "created" ? 0 : 1).ThenBy(e => e.Type == "created" ? "" : (e.Ts ?? b.Created ?? "")).ThenBy(e => e.Seq)
            .Select(e => new { ts = e.Ts, type = e.Type, title = e.Title, reference = e.Ref, url = e.Url, qty = e.Qty, uom = e.Uom, status = e.StatusText, statusCss = e.StatusCss, note = e.Note }).ToList();

        var counts = new
        {
            purchases = purchaseList.Count,
            production = itpmIds.Count,
            salesOrders = reservationList.Count,
            reservations = res.Rows.Count,
            invoices = invoiceList.Count,
            transfers = transfers.Count,
            other = otherList.Count
        };
        var quantities = new
        {
            original = b.Start, current = b.Current, reserved = reservedQty, invoiced, transferredOut, transferredIn, usedInProduction, cancelledConsumed, uom = b.Uom, partial
        };

        return JsonConvert.SerializeObject(new
        {
            notFound = false, counts, quantities, timeline = ordered,
            purchases = purchaseList, production = productionList, reservations = reservationList, invoices = invoiceList, transfers, other = otherList,
            orphanReservations = orphan
        });
    }

    static string PurchaseNumber(List<DataRow> purchases, int pmId)
    {
        DataRow r = purchases.FirstOrDefault(x => I(x["pm_id"]) == pmId);
        string n = r == null ? "" : S(r["pm_invoice_no"]);
        return n != "" ? n : "#" + pmId;
    }
}
