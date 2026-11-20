using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Globalization;
using System.Linq;
using System.Text;
using MySql.Data.MySqlClient;
using Newtonsoft.Json;

// Read-only, item-level stock overview (Stock View). Nothing here writes to the database.
//
// All quantities are expressed in the item's sales UOM, the unit the sales-order screens use (SalesOrderStock.Compute does the same).
// The rules below mirror the existing workflows (verified against the live schema):
//  - Physical stock: tbl_itembranch_stock.itbs_stock per warehouse (tbl_branch). It is the balance every stock workflow updates and the figure
//    the sales-order screens validate against; the sales-order invoice flow deducts it when the invoice is created, so invoiced quantity is
//    already out of physical stock. Batches cover only part of it (opening and legacy stock has no batch), so tbl_item_batch is not used.
//    Stored in the purchase UOM, converted with the same factor SalesOrderStock uses.
//  - Reserved: SUM(tbl_item_batchstock_reserve.itbsr_qty), allocated to the warehouse of the stock row (batch -> tbl_itembranch_stock).
//    The application deletes a reservation when it is consumed or released, so every existing row is an active hold; consumed and released
//    quantities are not recorded. Reserving never changes itbs_stock, so Free = Physical - Reserved.
//  - Pending reservation: per order line of an active sales order (Approved, Processed or Partially Delivered, the statuses that may reserve):
//    max(0, ordered - invoiced) - reserved by the line on the same item, with the same rounding rule as SalesOrderStock.Compute. Invoices
//    count when they are not cancelled / rejected and not inter-stock transfers. It is attributed to the warehouse of the order, and
//    reservations held in other warehouses still count against the line, so nothing is counted twice when warehouses are added up.
//  - Projected balance = Physical - Reserved - Pending. In the all-warehouse view it is computed from the consolidated figures.
//  - Item type: Finished Goods when the item has a BOM (as the sales order logic defines it), Raw Material when it is a BOM component, otherwise Other.
public static class StockView
{
    // "Stock Management" permission, the same page permission as the warehouse stock list.
    public const int PageId = 13;

    const string Fmt = "'%Y-%m-%d %H:%i:%s'";
    const int InvoiceAction = 1, PurchaseAction = 2;
    const int HistoryPage = 50;

    static readonly string ActiveOrderStatuses = string.Join(",", new int[] { SalesOrderStatus.Approved, SalesOrderStatus.Processed, SalesOrderStatus.PartiallyDelivered }.Select(x => x.ToString(CultureInfo.InvariantCulture)).ToArray());

    // ---------- helpers ----------
    sealed class Bag
    {
        readonly List<KeyValuePair<string, object>> items = new List<KeyValuePair<string, object>>();

        public string Add(string name, object value)
        {
            items.Add(new KeyValuePair<string, object>(name, value));
            return "@" + name;
        }

        public MySqlParameter[] Ps()
        {
            return items.Select(kv => new MySqlParameter(kv.Key, kv.Value ?? DBNull.Value)).ToArray();
        }
    }

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
    static string S(object o) { return o == null || o == DBNull.Value ? "" : Convert.ToString(o, CultureInfo.InvariantCulture); }
    static string Dt(object o)
    {
        string s = S(o);
        return s == "" || s.StartsWith("0000") ? null : s;
    }

    static string EscapeLike(string s)
    {
        return s.Replace("\\", "\\\\").Replace("%", "\\%").Replace("_", "\\_");
    }

    static string InList(Bag bag, string prefix, IEnumerable<int> ids)
    {
        int n = 0;
        var names = new List<string>();
        foreach (int id in ids)
            names.Add(bag.Add(prefix + n++, id));
        return names.Count == 0 ? "null" : string.Join(",", names);
    }

    static string OrderNo(int smoId, string invoiceNo) { return "#" + smoId + (invoiceNo == "" ? "" : " (" + invoiceNo + ")"); }
    static string OrderUrl(int smoId) { return "../web_sales/view_sales_order.aspx?smoId=" + smoId; }
    static string InvoiceUrl(int smId) { return "../web_sales/manageorders.aspx?orderId=" + smId; }
    static string PurchaseUrl(int pmId) { return "../web_purchase/managepurchase.aspx?purchaseId=" + pmId; }

    // Conversion factor between two UOM aliases (same rule as SalesOrderStock.Conv: same UOM type, otherwise no conversion).
    static string Factor(string from, string to)
    {
        return "if(" + from + ".tum_type_id=" + to + ".tum_type_id and " + from + ".tum_convertion_fac>0 and " + to + ".tum_convertion_fac>0,"
            + from + ".tum_convertion_fac/" + to + ".tum_convertion_fac,1)";
    }

    // ---------- warehouses and filters ----------
    sealed class Warehouse { public int Id; public string Name; }

    static List<Warehouse> Accessible(int staffId)
    {
        DataTable dt = Q("select tb.branch_id,tb.branch_name from tbl_branch tb where tb.branch_id in (select ub.branch_id from tbl_user_branches ub where ub.user_id=@staff) "
            + "order by tb.branch_name,tb.branch_id", new MySqlParameter("@staff", staffId));
        return dt.Rows.Cast<DataRow>().Select(r => new Warehouse { Id = I(r["branch_id"]), Name = S(r["branch_name"]) }).ToList();
    }

    // The warehouses a request covers: every accessible warehouse, or the selected one when the user has access to it (otherwise none).
    static List<Warehouse> Scope(List<Warehouse> accessible, string wh)
    {
        int id;
        if (string.IsNullOrEmpty(wh) || wh == "all")
            return accessible;
        if (int.TryParse(wh, out id))
            return accessible.Where(w => w.Id == id).ToList();
        return new List<Warehouse>();
    }

    public static string Options(int staffId)
    {
        var warehouses = Accessible(staffId).Select(w => new { id = w.Id, name = w.Name }).ToList();
        var groups = Q("select v.itsv_id,v.itsv_name from tbl_item_master_spe_values v where v.itsv_id in (select distinct m.itsv_stock_group from tbl_item_master m) order by v.itsv_name")
            .Rows.Cast<DataRow>().Select(r => new { id = I(r["itsv_id"]), name = S(r["itsv_name"]) }).ToList();
        var brands = Q("select v.itsv_id,v.itsv_name from tbl_item_master_spe_values v where v.itsv_id in (select distinct m.itsv_spec_brand from tbl_item_master m) order by v.itsv_name")
            .Rows.Cast<DataRow>().Select(r => new { id = I(r["itsv_id"]), name = S(r["itsv_name"]) }).ToList();
        return JsonConvert.SerializeObject(new { warehouses, groups, brands });
    }

    // ---------- shared SQL ----------
    // One row per item master record with its sales UOM, the purchase -> sales factor (fb) and its item type.
    static string ItemsSql(string where)
    {
        return "select im.itm_id,im.itm_code,im.itm_name,im.itm_description,im.itsv_printing_name as print_name,im.itsv_stock_group as grp_id,im.itsv_spec_brand as brand_id,"
            + "sg.itsv_name as grp,sb.itsv_name as brand,su.tum_name as uom,"
            + "case when im.itsv_bom_enabled=1 and exists(select 1 from tbl_item_master_bom bo where bo.itm_id_output=im.itm_id and bo.itmbi_type=1) then 'finished' "
            + "when exists(select 1 from tbl_item_master_bom bi where bi.itm_id_input=im.itm_id and bi.itmbi_type=1) then 'raw' else 'other' end as itype,"
            + Factor("pu", "su") + " as fb "
            + "from tbl_item_master im left join tbl_item_uom su on su.tum_id=im.itsv_uom_sales left join tbl_item_uom pu on pu.tum_id=im.itsv_uom_purchase "
            + "left join tbl_item_master_spe_values sg on sg.itsv_id=im.itsv_stock_group left join tbl_item_master_spe_values sb on sb.itsv_id=im.itsv_spec_brand "
            + "where " + where;
    }

    // Order lines of active sales orders with their outstanding requirement and pending reservation, in the item's sales UOM.
    // branchCond / itemCond use the aliases smo (the order) and sio (the order line).
    static string LineSql(string branchCond, string itemCond)
    {
        string inner = "select sio.sio_id,sio.smo_id,sio.itm_id,smo.branch_id,sio.sio_finalqty as fq,ifnull(inv.q,0) as invq,ifnull(own.q,0) as ownq,"
            + Factor("lu", "su") + " as lf," + Factor("pu", "su") + " as fb "
            + "from tbl_sales_items_order sio "
            + "inner join tbl_sales_master_order smo on smo.smo_id=sio.smo_id and smo.smo_delivery_status in (" + ActiveOrderStatuses + ") and " + branchCond + " "
            + "inner join tbl_item_master m on m.itm_id=sio.itm_id and m.itm_type=1 "
            + "left join tbl_item_uom su on su.tum_id=m.itsv_uom_sales left join tbl_item_uom pu on pu.tum_id=m.itsv_uom_purchase "
            + "left join tbl_item_uom lu on lu.tum_id=if(ifnull(sio.tum_id,0)>0,sio.tum_id,m.itsv_uom_sales) "
            // invoiced quantity of the line: every invoice of the order that is not cancelled / rejected and not an inter-stock transfer
            + "left join (select si.sio_id,sum(si.si_qty) as q from tbl_sales_items si inner join tbl_sales_master sm on sm.sm_id=si.sm_id "
            + "inner join tbl_sales_items_order s2 on s2.sio_id=si.sio_id and s2.smo_id=sm.sm_refid "
            + "inner join tbl_sales_master_order o2 on o2.smo_id=s2.smo_id and o2.smo_delivery_status in (" + ActiveOrderStatuses + ") "
            + "where sm.sm_is_inter_stock_transfer_invoice=0 and " + SalesOrderStatus.ValidInvoiceSql + " group by si.sio_id) inv on inv.sio_id=sio.sio_id "
            // reserved by the line on the item itself (component reservations for production do not cover the line)
            + "left join (select r2.sio_id,t2.itm_id,sum(r2.itbsr_qty) as q from tbl_item_batchstock_reserve r2 inner join tbl_item_batch b2 on b2.itbh_id=r2.itbh_id "
            + "inner join tbl_itembranch_stock t2 on t2.itbs_id=b2.itbs_id where r2.itbsr_qty>0 group by r2.sio_id,t2.itm_id) own on own.sio_id=sio.sio_id and own.itm_id=sio.itm_id "
            + "where " + itemCond;
        return "select z.*,if(greatest(0,z.req-z.own)<=0.001*z.fb,0,greatest(0,z.req-z.own)) as pend from ("
            + "select b.*,b.fq*b.lf as ordered,b.invq*b.lf as invoiced,greatest(0,b.fq-b.invq)*b.lf as req,b.ownq*b.fb as own from (" + inner + ") b) z";
    }

    // Reserved quantity (in the batch UOM) per item for the warehouses in w.
    static string ReservedSql(string w, string itemCond)
    {
        return "select tis.itm_id,tis.branch_id,sum(r.itbsr_qty) as q from tbl_item_batchstock_reserve r inner join tbl_item_batch b on b.itbh_id=r.itbh_id "
            + "inner join tbl_itembranch_stock tis on tis.itbs_id=b.itbs_id where r.itbsr_qty>0 and tis.branch_id in (" + w + ") and " + itemCond + " group by tis.itm_id,tis.branch_id";
    }

    const string StatusSql = "case when round(x.phys,3)<0 then 'negative' when round(x.phys-x.resv-x.pend,3)<0 then 'shortage' when round(x.phys,3)=0 then 'zero' "
        + "when round(x.pend,3)>0 then 'pending' when round(x.resv,3)>0 then 'reserved' else 'healthy' end";

    // Every item with physical, reserved, pending, free and projected quantities for the warehouses in w (alias y once wrapped).
    static string StockSql(string w)
    {
        return "select x.*,round(x.phys-x.resv,6) as free,round(x.phys-x.resv-x.pend,6) as proj," + StatusSql + " as status from ("
            + "select i.*,round(ifnull(p.q,0)*i.fb,6) as phys,round(ifnull(r.q,0)*i.fb,6) as resv,round(ifnull(d.q,0),6) as pend from (" + ItemsSql("1=1") + ") i "
            + "left join (select tis.itm_id,sum(tis.itbs_stock) as q from tbl_itembranch_stock tis where tis.branch_id in (" + w + ") group by tis.itm_id) p on p.itm_id=i.itm_id "
            + "left join (select a.itm_id,sum(a.q) as q from (" + ReservedSql(w, "1=1") + ") a group by a.itm_id) r on r.itm_id=i.itm_id "
            + "left join (select l.itm_id,sum(l.pend) as q from (" + LineSql("smo.branch_id in (" + w + ")", "1=1") + ") l group by l.itm_id) d on d.itm_id=i.itm_id) x";
    }

    // ---------- listing ----------
    sealed class Listing
    {
        public string Where, Order, WarehouseLabel;
        public Bag Bag = new Bag();
        public string From;
    }

    static bool TryDecimal(string s, out decimal d)
    {
        return decimal.TryParse((s ?? "").Trim(), NumberStyles.Number, CultureInfo.InvariantCulture, out d);
    }

    static Listing Prepare(int staffId, Dictionary<string, string> filters, string sortBy, string sortDir)
    {
        if (filters == null) filters = new Dictionary<string, string>();
        string wh;
        filters.TryGetValue("wh", out wh);
        List<Warehouse> accessible = Accessible(staffId);
        List<Warehouse> scope = Scope(accessible, wh);
        if (scope.Count == 0)
            return null;

        var l = new Listing();
        l.WarehouseLabel = string.IsNullOrEmpty(wh) || wh == "all" ? "All Warehouses" : scope[0].Name;
        string w = InList(l.Bag, "w", scope.Select(x => x.Id));
        l.From = "(" + StockSql(w) + ") y";

        var conds = new List<string> { "1=1" };
        string v;
        if (filters.TryGetValue("search", out v) && v.Trim() != "")
        {
            int n = 0;
            foreach (string tok in v.Trim().Split(new[] { ' ', '\t' }, StringSplitOptions.RemoveEmptyEntries).Take(6))
            {
                string p = l.Bag.Add("s" + n++, "%" + EscapeLike(tok) + "%");
                conds.Add("(y.itm_name like " + p + " or y.itm_code like " + p + " or y.itm_description like " + p + " or y.print_name like " + p + ")");
            }
        }
        int id;
        if (filters.TryGetValue("group", out v) && int.TryParse(v, out id) && id > 0)
            conds.Add("y.grp_id=" + l.Bag.Add("grp", id));
        if (filters.TryGetValue("brand", out v) && int.TryParse(v, out id) && id > 0)
            conds.Add("y.brand_id=" + l.Bag.Add("brand", id));
        if (filters.TryGetValue("type", out v) && (v == "finished" || v == "raw" || v == "other"))
            conds.Add("y.itype=" + l.Bag.Add("itype", v));
        if (filters.TryGetValue("status", out v))
        {
            switch (v)
            {
                case "instock": conds.Add("round(y.phys,3)>0"); break;
                case "zero": conds.Add("round(y.phys,3)=0"); break;
                case "negative": conds.Add("round(y.phys,3)<0"); break;
                case "reserved": conds.Add("round(y.resv,3)>0"); break;
                case "pending": conds.Add("round(y.pend,3)>0"); break;
                case "shortage": conds.Add("round(y.proj,3)<0"); break;
            }
        }
        decimal d;
        if (filters.TryGetValue("min", out v) && TryDecimal(v, out d))
            conds.Add("y.phys>=" + l.Bag.Add("min", d));
        if (filters.TryGetValue("max", out v) && TryDecimal(v, out d))
            conds.Add("y.phys<=" + l.Bag.Add("max", d));
        l.Where = string.Join(" and ", conds);

        string key;
        switch (sortBy)
        {
            case "code": key = "y.itm_code"; break;
            case "phys": key = "y.phys"; break;
            case "resv": key = "y.resv"; break;
            case "pend": key = "y.pend"; break;
            case "proj": key = "y.proj"; break;
            default: key = "y.itm_name"; break;
        }
        string dir = (sortDir ?? "").ToLower() == "desc" ? "desc" : "asc";
        l.Order = key + " " + dir + ",y.itm_id " + dir;
        return l;
    }

    static object Row(DataRow r)
    {
        return new
        {
            id = I(r["itm_id"]),
            code = S(r["itm_code"]),
            name = S(r["itm_name"]),
            group = S(r["grp"]),
            brand = S(r["brand"]),
            uom = S(r["uom"]),
            itype = S(r["itype"]),
            phys = D(r["phys"]),
            resv = D(r["resv"]),
            free = D(r["free"]),
            pend = D(r["pend"]),
            proj = D(r["proj"]),
            status = S(r["status"])
        };
    }

    public static string Search(int staffId, int page, int perpage, Dictionary<string, string> filters, string sortBy, string sortDir)
    {
        if (page < 1) page = 1;
        if (perpage != 25 && perpage != 50 && perpage != 100) perpage = 25;
        Listing l = Prepare(staffId, filters, sortBy, sortDir);
        if (l == null)
            return JsonConvert.SerializeObject(new { count = 0, rows = new object[0], summary = EmptySummary(), warehouse = "", asOf = Now() });

        // The window aggregates cover every matching item, not just the page, so one pass gives the page and the summary cards.
        string sql = "select y.*,count(*) over () as n_all,sum(y.phys) over () as s_phys,sum(y.resv) over () as s_resv,sum(y.free) over () as s_free,"
            + "sum(y.pend) over () as s_pend,sum(round(y.proj,3)<0) over () as s_short from " + l.From + " where " + l.Where
            + " order by " + l.Order + " limit ";
        DataTable dt = Q(sql + (page - 1) * perpage + "," + perpage, l.Bag.Ps());
        if (dt.Rows.Count == 0 && page > 1)
        {
            page = 1;
            dt = Q(sql + "0," + perpage, l.Bag.Ps());
        }
        if (dt.Rows.Count == 0)
            return JsonConvert.SerializeObject(new { count = 0, rows = new object[0], summary = EmptySummary(), warehouse = l.WarehouseLabel, asOf = Now() });

        DataRow f = dt.Rows[0];
        var summary = new
        {
            items = I(f["n_all"]),
            phys = D(f["s_phys"]),
            resv = D(f["s_resv"]),
            free = D(f["s_free"]),
            pend = D(f["s_pend"]),
            shortage = I(f["s_short"])
        };
        return JsonConvert.SerializeObject(new { count = summary.items, page, rows = dt.Rows.Cast<DataRow>().Select(r => Row(r)).ToList(), summary, warehouse = l.WarehouseLabel, asOf = Now() });
    }

    static object EmptySummary()
    {
        return new { items = 0, phys = 0m, resv = 0m, free = 0m, pend = 0m, shortage = 0 };
    }

    static string Now() { return DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture); }

    // Every matching item (no paging) for the Excel export; null when the user has no access to the selected warehouse.
    public static DataTable Export(int staffId, Dictionary<string, string> filters, string sortBy, string sortDir, out string warehouse)
    {
        warehouse = "";
        Listing l = Prepare(staffId, filters, sortBy, sortDir);
        if (l == null)
            return null;
        warehouse = l.WarehouseLabel;
        return Q("select y.* from " + l.From + " where " + l.Where + " order by " + l.Order, l.Bag.Ps());
    }

    // ---------- item details ----------
    static string TypeName(int t) { return t == 1 ? "Product" : t == 2 ? "Service" : t == 3 ? "Package" : ""; }
    static string RoleName(string r) { return r == "finished" ? "Finished Goods" : r == "raw" ? "Raw Material" : "Other"; }

    sealed class Item
    {
        public int Id;
        public string Code, Name, Uom;
        public decimal Fb;
    }

    static Item LoadItem(int itemId)
    {
        DataTable dt = Q("select i.itm_id,i.itm_code,i.itm_name,i.uom,i.fb from (" + ItemsSql("im.itm_id=@i") + ") i", new MySqlParameter("@i", itemId));
        if (dt.Rows.Count == 0)
            return null;
        DataRow r = dt.Rows[0];
        return new Item { Id = I(r["itm_id"]), Code = S(r["itm_code"]), Name = S(r["itm_name"]), Uom = S(r["uom"]), Fb = D(r["fb"]) };
    }

    sealed class Scoped
    {
        public Item Item;
        public List<Warehouse> Accessible, Selected;
        public string Wh;
    }

    static Scoped Load(int staffId, int itemId, string wh)
    {
        Item item = LoadItem(itemId);
        if (item == null)
            return null;
        List<Warehouse> acc = Accessible(staffId);
        return new Scoped { Item = item, Accessible = acc, Selected = Scope(acc, wh), Wh = string.IsNullOrEmpty(wh) ? "all" : wh };
    }

    public static string Overview(int staffId, int itemId, string wh)
    {
        Scoped s = Load(staffId, itemId, wh);
        if (s == null)
            return "{\"notFound\":true}";

        DataTable info = Q("select i.itm_id,i.itm_code,i.itm_name,i.itm_description,i.print_name,i.grp,i.brand,i.uom,i.itype,im.itm_type,im.itm_qty_per_carton,im.itsv_bom_enabled,"
            + "pu.tum_name as puom,sc.itsv_name as cat,hs.itsv_name as hsn from (" + ItemsSql("im.itm_id=@i") + ") i inner join tbl_item_master im on im.itm_id=i.itm_id "
            + "left join tbl_item_uom pu on pu.tum_id=im.itsv_uom_purchase left join tbl_item_master_spe_values sc on sc.itsv_id=im.itsv_category "
            + "left join tbl_item_master_spe_values hs on hs.itsv_id=im.itsv_hsn_sac", new MySqlParameter("@i", itemId));
        DataRow r = info.Rows[0];
        var item = new
        {
            id = s.Item.Id,
            code = s.Item.Code,
            name = s.Item.Name,
            description = S(r["itm_description"]),
            printingName = S(r["print_name"]),
            group = S(r["grp"]),
            category = S(r["cat"]),
            brand = S(r["brand"]),
            type = TypeName(I(r["itm_type"])),
            role = S(r["itype"]),
            roleLabel = RoleName(S(r["itype"])),
            uom = s.Item.Uom,
            purchaseUom = S(r["puom"]),
            hsn = S(r["hsn"]),
            qtyPerCarton = I(r["itm_qty_per_carton"]),
            bom = I(r["itsv_bom_enabled"]) == 1
        };

        // Per warehouse: physical, reserved and pending, each aggregated before they are joined.
        var bag = new Bag();
        string all = InList(bag, "a", s.Accessible.Select(x => x.Id));
        string itemP = bag.Add("i", itemId);
        DataTable wd = Q("select tb.branch_id,tb.branch_name,round(ifnull(p.q,0)*f.fb,6) as phys,round(ifnull(r.q,0)*f.fb,6) as resv,round(ifnull(d.q,0),6) as pend from tbl_branch tb "
            + "cross join (select " + Factor("pu", "su") + " as fb from tbl_item_master im left join tbl_item_uom su on su.tum_id=im.itsv_uom_sales "
            + "left join tbl_item_uom pu on pu.tum_id=im.itsv_uom_purchase where im.itm_id=" + itemP + ") f "
            + "left join (select tis.branch_id,sum(tis.itbs_stock) as q from tbl_itembranch_stock tis where tis.itm_id=" + itemP + " group by tis.branch_id) p on p.branch_id=tb.branch_id "
            + "left join (" + ReservedSql(all, "tis.itm_id=" + itemP) + ") r on r.branch_id=tb.branch_id "
            + "left join (select l.branch_id,sum(l.pend) as q from (" + LineSql("smo.branch_id in (" + all + ")", "sio.itm_id=" + itemP) + ") l group by l.branch_id) d on d.branch_id=tb.branch_id "
            + "where tb.branch_id in (" + all + ") order by tb.branch_name,tb.branch_id", bag.Ps());
        var rows = wd.Rows.Cast<DataRow>().Select(x => Figures(I(x["branch_id"]), S(x["branch_name"]), D(x["phys"]), D(x["resv"]), D(x["pend"]))).ToList();

        // Selected scope and the consolidated position: the shortage is judged on the totals, never by adding up warehouse shortages.
        var inScope = new HashSet<int>(s.Selected.Select(x => x.Id));
        var chosen = rows.Where(x => inScope.Contains(x.id)).ToList();
        var total = Figures(0, s.Selected.Count == 1 ? s.Selected[0].Name : "All Warehouses", chosen.Sum(x => x.phys), chosen.Sum(x => x.resv), chosen.Sum(x => x.pend));
        var consolidated = Figures(0, "All Warehouses", rows.Sum(x => x.phys), rows.Sum(x => x.resv), rows.Sum(x => x.pend));
        return JsonConvert.SerializeObject(new { item, warehouses = rows, total, consolidated, selected = s.Selected.Count == 1 ? (int?)s.Selected[0].Id : null, scoped = s.Selected.Count > 0, asOf = Now() });
    }

    sealed class Figure
    {
        public int id;
        public string name;
        public decimal phys, resv, free, pend, proj;
        public string status;
    }

    static Figure Figures(int id, string name, decimal phys, decimal resv, decimal pend)
    {
        decimal free = Math.Round(phys - resv, 6), proj = Math.Round(phys - resv - pend, 6);
        string status;
        if (Math.Round(phys, 3) < 0) status = "negative";
        else if (Math.Round(proj, 3) < 0) status = "shortage";
        else if (Math.Round(phys, 3) == 0) status = "zero";
        else if (Math.Round(pend, 3) > 0) status = "pending";
        else if (Math.Round(resv, 3) > 0) status = "reserved";
        else status = "healthy";
        return new Figure { id = id, name = name, phys = phys, resv = resv, free = free, pend = pend, proj = proj, status = status };
    }

    public static string Demand(int staffId, int itemId, string wh)
    {
        Scoped s = Load(staffId, itemId, wh);
        if (s == null || s.Selected.Count == 0)
            return JsonConvert.SerializeObject(new { rows = new object[0], total = 0m, uom = s == null ? "" : s.Item.Uom });
        var bag = new Bag();
        string w = InList(bag, "w", s.Selected.Select(x => x.Id));
        string itemP = bag.Add("i", itemId);
        DataTable dt = Q("select l.smo_id,l.branch_id,l.ordered,l.invoiced,l.req,l.own,l.pend,smo.smo_invoice_no,date_format(smo.smo_date," + Fmt + ") as smo_date,"
            + "smo.smo_delivery_status as st,c.cust_name,tb.branch_name from (" + LineSql("smo.branch_id in (" + w + ")", "sio.itm_id=" + itemP) + ") l "
            + "inner join tbl_sales_master_order smo on smo.smo_id=l.smo_id left join tbl_customer c on c.cust_id=smo.cust_id left join tbl_branch tb on tb.branch_id=l.branch_id "
            + "where round(l.pend,3)>0 order by smo.smo_date,l.smo_id,l.sio_id", bag.Ps());
        var rows = dt.Rows.Cast<DataRow>().Select(r => new
        {
            smoId = I(r["smo_id"]),
            no = OrderNo(I(r["smo_id"]), S(r["smo_invoice_no"])),
            url = OrderUrl(I(r["smo_id"])),
            customer = S(r["cust_name"]),
            date = Dt(r["smo_date"]),
            ordered = D(r["ordered"]),
            invoiced = D(r["invoiced"]),
            required = D(r["req"]),
            reserved = D(r["own"]),
            pending = D(r["pend"]),
            warehouse = S(r["branch_name"]),
            status = OrderStatus(I(r["st"]))
        }).ToList();
        return JsonConvert.SerializeObject(new { rows, total = rows.Sum(x => x.pending), uom = s.Item.Uom });
    }

    static string[] OrderStatus(int st) { return new[] { SalesOrderStatus.Name(st) == "" ? "Status " + st : SalesOrderStatus.Name(st), SalesOrderStatus.Css(st) }; }

    public static string Reservations(int staffId, int itemId, string wh)
    {
        Scoped s = Load(staffId, itemId, wh);
        if (s == null || s.Selected.Count == 0)
            return JsonConvert.SerializeObject(new { rows = new object[0], total = 0m, uom = s == null ? "" : s.Item.Uom });
        var bag = new Bag();
        string w = InList(bag, "w", s.Selected.Select(x => x.Id));
        string itemP = bag.Add("i", itemId);
        // One row per order line and warehouse. Consumed quantity is the invoiced quantity of the line (the reservation itself is deleted when consumed).
        DataTable dt = Q("select rr.sio_id,rr.branch_id,rr.q,rr.rdate,sio.smo_id,sio.itm_id as line_itm,smo.smo_invoice_no,smo.smo_delivery_status as st,c.cust_name,tb.branch_name,"
            + "ifnull((select sum(si.si_qty) from tbl_sales_items si inner join tbl_sales_master sm on sm.sm_id=si.sm_id where si.sio_id=sio.sio_id and sm.sm_refid=sio.smo_id "
            + "and sm.sm_is_inter_stock_transfer_invoice=0 and " + SalesOrderStatus.ValidInvoiceSql + "),0)*" + Factor("lu", "su") + " as consumed "
            + "from (select r.sio_id,tis.branch_id,sum(r.itbsr_qty) as q,date_format(min(r.itbrs_date)," + Fmt + ") as rdate from tbl_item_batchstock_reserve r inner join tbl_item_batch b on b.itbh_id=r.itbh_id "
            + "inner join tbl_itembranch_stock tis on tis.itbs_id=b.itbs_id where r.itbsr_qty>0 and tis.itm_id=" + itemP + " and tis.branch_id in (" + w + ") group by r.sio_id,tis.branch_id) rr "
            + "left join tbl_sales_items_order sio on sio.sio_id=rr.sio_id left join tbl_sales_master_order smo on smo.smo_id=sio.smo_id left join tbl_customer c on c.cust_id=smo.cust_id "
            + "left join tbl_branch tb on tb.branch_id=rr.branch_id left join tbl_item_master m on m.itm_id=sio.itm_id left join tbl_item_uom su on su.tum_id=m.itsv_uom_sales "
            + "left join tbl_item_uom lu on lu.tum_id=if(ifnull(sio.tum_id,0)>0,sio.tum_id,m.itsv_uom_sales) order by rr.rdate is null,rr.rdate,sio.smo_id,rr.sio_id", bag.Ps());
        decimal fb = s.Item.Fb;
        var rows = dt.Rows.Cast<DataRow>().Select(r =>
        {
            bool material = I(r["line_itm"]) != itemId; // raw material held for the production of another item's order line
            int smo = I(r["smo_id"]);
            return new
            {
                smoId = smo,
                no = smo > 0 ? OrderNo(smo, S(r["smo_invoice_no"])) : "",
                url = smo > 0 ? OrderUrl(smo) : null,
                customer = S(r["cust_name"]),
                warehouse = S(r["branch_name"]),
                reserved = D(r["q"]) * fb,
                date = Dt(r["rdate"]),
                consumed = material ? (decimal?)null : D(r["consumed"]),
                remaining = D(r["q"]) * fb,
                material,
                status = smo > 0 ? OrderStatus(I(r["st"])) : new string[] { "", "" }
            };
        }).ToList();
        return JsonConvert.SerializeObject(new { rows, total = rows.Sum(x => x.remaining), uom = s.Item.Uom });
    }

    static string MovementType(int action, bool interStock)
    {
        switch (action)
        {
            case 1: return interStock ? "Interstock Transfer Out" : "Sales Invoice";
            case 2: return interStock ? "Interstock Transfer In" : "Purchase Receipt";
            case 3: return "Sales Return";
            case 4: return "Purchase Return";
            case 8: return "Stock Transfer";
            case 11: return "Stock Adjustment";
            case 12: return "Production / Conversion";
            default: return "Other";
        }
    }

    // Chronological (newest first) stock ledger of the item for the selected warehouses, one page at a time.
    public static string Movements(int staffId, int itemId, string wh, int page)
    {
        Scoped s = Load(staffId, itemId, wh);
        if (s == null || s.Selected.Count == 0)
            return JsonConvert.SerializeObject(new { count = 0, rows = new object[0], uom = s == null ? "" : s.Item.Uom });
        if (page < 1) page = 1;
        var bag = new Bag();
        string w = InList(bag, "w", s.Selected.Select(x => x.Id));
        string itemP = bag.Add("i", itemId);
        string from = " from tbl_stock_transactions st inner join tbl_itembranch_stock tis on tis.itbs_id=st.itbs_id left join tbl_branch tb on tb.branch_id=tis.branch_id "
            + "where tis.itm_id=" + itemP + " and tis.branch_id in (" + w + ")";
        int count = I(Q("select count(*)" + from, bag.Ps()).Rows[0][0]);
        DataTable dt = Q("select st.id,st.action_type,st.action_ref_id,st.narration,st.dr_qty,st.cr_qty,st.closing_stock,date_format(st.date," + Fmt + ") as d,tis.branch_id,tb.branch_name"
            + from + " order by st.date desc,st.id desc limit " + (page - 1) * HistoryPage + "," + HistoryPage, bag.Ps());

        var invoices = new Dictionary<int, DataRow>();
        var purchases = new Dictionary<int, DataRow>();
        var smIds = dt.Rows.Cast<DataRow>().Where(r => I(r["action_type"]) == InvoiceAction).Select(r => I(r["action_ref_id"])).Distinct().ToList();
        var pmIds = dt.Rows.Cast<DataRow>().Where(r => I(r["action_type"]) == PurchaseAction).Select(r => I(r["action_ref_id"])).Distinct().ToList();
        if (smIds.Count > 0)
        {
            var b = new Bag();
            foreach (DataRow r in Q("select sm_id,sm_invoice_no,ifnull(sm_is_inter_stock_transfer_invoice,0) as ist from tbl_sales_master where sm_id in (" + InList(b, "m", smIds) + ")", b.Ps()).Rows)
                invoices[I(r["sm_id"])] = r;
        }
        if (pmIds.Count > 0)
        {
            var b = new Bag();
            foreach (DataRow r in Q("select pm_id,pm_invoice_no,ifnull(pm_is_inter_stock_transfer_invoice,0) as ist from tbl_purchase_master where pm_id in (" + InList(b, "p", pmIds) + ")", b.Ps()).Rows)
                purchases[I(r["pm_id"])] = r;
        }

        decimal fb = s.Item.Fb;
        var rows = dt.Rows.Cast<DataRow>().Select(r =>
        {
            int action = I(r["action_type"]), refId = I(r["action_ref_id"]);
            DataRow doc = null;
            bool inter = false;
            string reference = refId > 0 ? "#" + refId : "", url = null;
            if (action == InvoiceAction && invoices.TryGetValue(refId, out doc))
            {
                inter = I(doc["ist"]) == 1;
                reference = "Invoice " + (S(doc["sm_invoice_no"]) != "" ? S(doc["sm_invoice_no"]) : "#" + refId);
                url = InvoiceUrl(refId);
            }
            else if (action == PurchaseAction && purchases.TryGetValue(refId, out doc))
            {
                inter = I(doc["ist"]) == 1;
                reference = "Purchase " + (S(doc["pm_invoice_no"]) != "" ? S(doc["pm_invoice_no"]) : "#" + refId);
                url = PurchaseUrl(refId);
            }
            return new
            {
                date = Dt(r["d"]),
                warehouse = S(r["branch_name"]),
                type = MovementType(action, inter),
                reference,
                url,
                narration = S(r["narration"]),
                inQty = D(r["cr_qty"]) * fb,
                outQty = D(r["dr_qty"]) * fb,
                balance = D(r["closing_stock"]) * fb
            };
        }).ToList();
        return JsonConvert.SerializeObject(new { count, page, perpage = HistoryPage, rows, uom = s.Item.Uom });
    }
}
