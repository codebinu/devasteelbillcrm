using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.Services;
using commonfunction;
using Newtonsoft.Json;
using MySql.Data.MySqlClient;

public partial class web_sales_new_sales_order : System.Web.UI.Page
{
    mySqlConnection db = new mySqlConnection();
    public string settings;

    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication bill = new LoginAuthentication();
        bill.userAuthentication();
        bill.checkPageAcess(7);
        DataTable dtSettings = db.SelectQuery("select ss_decimal_accuracy,ss_allow_zero_stock_order from tbl_system_settings");
        settings = JsonConvert.SerializeObject(dtSettings, Formatting.Indented);
    }

    // Warehouses available to the logged in user (same source as Purchase Entry)
    [WebMethod]
    public static string loadWarehouses()
    {
        mySqlConnection db = new mySqlConnection();
        string query = "select tb.branch_id,branch_name,branch_tax_method,branch_tax_inclusive from tbl_branch tb inner join tbl_user_branches ub on ub.branch_id=tb.branch_id where user_id=" + Convert.ToInt32(HttpContext.Current.Request.Cookies["invntrystaffId"].Value);
        return JsonConvert.SerializeObject(db.SelectQuery(query), Formatting.Indented);
    }

    // Customer autocomplete (same source as neworder.aspx)
    [WebMethod(EnableSession = true)]
    public static string searchCustomers(string variable)
    {
        mySqlConnection db = new mySqlConnection();
        string sql = "SELECT cu.cust_id,cu.cust_name,cu.cust_type,cu.cust_phone,cu.cust_address,cu.cust_amount,cu.max_creditamt,cu.max_creditperiod,tpm.tpm_name as class from tbl_customer cu left join tbl_price_master tpm on tpm.tpm_id=cu.cust_type where cu.cust_name like @name GROUP BY cu.cust_id ORDER BY cu.cust_name limit 0,20";
        DataTable dt = db.SelectQuery(sql, new MySqlParameter[] {
            new MySqlParameter("@uid", Convert.ToInt32(HttpContext.Current.Request.Cookies["invntrystaffId"].Value)),
            new MySqlParameter("@name", "%" + (variable ?? "").Trim() + "%") });
        var list = new List<object>();
        foreach (DataRow r in dt.Rows)
            list.Add(new { id = Convert.ToString(r["cust_id"]), label = Convert.ToString(r["cust_name"]), value = Convert.ToString(r["cust_name"]), custType = Convert.ToString(r["cust_type"]), cls = Convert.ToString(r["class"]), cust_phone = Convert.ToString(r["cust_phone"]), cust_address = Convert.ToString(r["cust_address"]), creditAmt = Convert.ToString(r["max_creditamt"]), creditPeriod = Convert.ToString(r["max_creditperiod"]), balance = Convert.ToString(r["cust_amount"]) });
        if (list.Count == 0)
            list.Add(new { id = "-1", label = "No Data Found", value = "No Data Found", custType = "0" });
        return JsonConvert.SerializeObject(list);
    }

    // Paged customer list for the customer modal. Same customer scope as searchCustomers above (neworder.aspx's
    // searchOrderCustomers also joins tbl_user_locations, which matches no customers in this data).
    [WebMethod(EnableSession = true)]
    public static string searchCustomerList(int page, int perpage, string custId, string name, string phone)
    {
        try
        {
            if (page < 1) page = 1;
            if (perpage < 1 || perpage > 100) perpage = 25;
            Func<string, string> like = s => "%" + (s ?? "").Trim().Replace("\\", "\\\\").Replace("%", "\\%").Replace("_", "\\_") + "%";
            string where = " where 1=1";
            var p = new List<MySqlParameter>();
            if (!string.IsNullOrWhiteSpace(custId)) { where += " and cu.cust_id like @id"; p.Add(new MySqlParameter("@id", like(custId))); }
            if (!string.IsNullOrWhiteSpace(name)) { where += " and cu.cust_name like @name"; p.Add(new MySqlParameter("@name", like(name))); }
            if (!string.IsNullOrWhiteSpace(phone)) { where += " and (cu.cust_phone like @phone or cu.cust_phone1 like @phone)"; p.Add(new MySqlParameter("@phone", like(phone))); }

            mySqlConnection db = new mySqlConnection();
            int count = Convert.ToInt32(db.SelectScalar("select count(*) from tbl_customer cu" + where, p.ToArray()));
            if (count == 0) return "N";
            DataTable dt = db.SelectQuery("select cu.cust_id,cu.cust_name,cu.cust_address,cu.cust_phone,cu.cust_type,tpm.tpm_name as class,cu.cust_amount,cu.max_creditamt,cu.max_creditperiod,cu.new_custtype,cu.new_creditamt,cu.new_creditperiod "
                + "from tbl_customer cu left join tbl_price_master tpm on tpm.tpm_id=cu.cust_type" + where
                + " order by cu.cust_name asc, cu.cust_id asc limit " + ((page - 1) * perpage) + "," + perpage, p.ToArray());
            return JsonConvert.SerializeObject(new { count = count, data = dt });
        }
        catch (Exception)
        {
            HttpContext.Current.Response.StatusCode = 500;
            HttpContext.Current.Response.TrySkipIisCustomErrors = true;
            return "Unable to load customers.";
        }
    }

    // Item autocomplete with all values needed for item entry
    [WebMethod(EnableSession = true)]
    public static string searchItems(string variable, int branchId, int custType, int allowZeroStockOrder)
    {
        mySqlConnection db = new mySqlConnection();
        string sql = "SELECT tis.itbs_id,tis.itm_id,tis.itm_code,tis.itm_name,tis.itbs_stock,itm_mrp,tp.tp_tax_percentage,tp.tp_cess,tp.tp_tax_title,im.itsv_uom_sales,"
            + "(select tip_price from tbl_item_pricelist tip where tip.tpm_id=@tpm and tip.itbs_id=tis.itbs_id limit 1) as classPrice "
            + "from tbl_itembranch_stock tis inner join tbl_tax_profile tp on tp.tp_tax_code=tis.tp_tax_code inner join tbl_item_master im on im.itm_id=tis.itm_id "
            + "where tis.itm_name like @name and tis.branch_id=@branch and tis.itbs_available=1 and tis.itm_code not in ('1234567891234')"
            + (allowZeroStockOrder == 0 ? " and tis.itbs_stock>0" : "") + " ORDER BY itm_rating asc limit 0,20";
        DataTable dt = db.SelectQuery(sql, new MySqlParameter[] {
            new MySqlParameter("@tpm", custType),
            new MySqlParameter("@name", "%" + (variable ?? "").Trim() + "%"),
            new MySqlParameter("@branch", branchId) });
        var list = new List<object>();
        foreach (DataRow r in dt.Rows)
        {
            string name = Convert.ToString(r["itm_name"]);
            list.Add(new
            {
                id = Convert.ToString(r["itbs_id"]),
                label = name,
                value = name,
                itbs_id = Convert.ToInt32(r["itbs_id"]),
                itm_id = Convert.ToInt32(r["itm_id"]),
                itm_code = Convert.ToString(r["itm_code"]),
                hsn = Convert.ToString(r["tp_tax_title"]),
                stock = r["itbs_stock"] == DBNull.Value ? 0 : Convert.ToDecimal(r["itbs_stock"]),
                tax = r["tp_tax_percentage"] == DBNull.Value ? 0 : Convert.ToDecimal(r["tp_tax_percentage"]),
                cess = r["tp_cess"] == DBNull.Value ? 0 : Convert.ToDecimal(r["tp_cess"]),
                defUomId = r["itsv_uom_sales"] == DBNull.Value ? 0 : Convert.ToInt32(r["itsv_uom_sales"]),
                price = r["classPrice"] != DBNull.Value ? Convert.ToDecimal(r["classPrice"]) : (r["itm_mrp"] == DBNull.Value ? 0 : Convert.ToDecimal(r["itm_mrp"]))
            });
        }
        if (list.Count == 0)
            list.Add(new { id = "-1", label = "No Data Found", value = "No Data Found" });
        return JsonConvert.SerializeObject(list);
    }

    [WebMethod]
    public static string loadUomTypes()
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = db.SelectQuery("SELECT tumt_id, tumt_name, IFNULL(tum_id,0) AS tum_id FROM tbl_item_uom_type");
        return JsonConvert.SerializeObject(dt, Formatting.Indented);
    }

    [WebMethod]
    public static string loadUomData()
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = db.SelectQuery("SELECT tbl_item_uom.tum_id, tbl_item_uom.tum_name, tbl_item_uom.tum_type_id, tbl_item_uom.tum_convertion_fac, IFNULL(tbl_item_uom.tum_subunit_Id,0) AS tum_subunit_Id FROM tbl_item_uom");
        return JsonConvert.SerializeObject(dt, Formatting.Indented);
    }

    static object Fail(string message)
    {
        return new { status = false, message = message };
    }

    static decimal Rnd(decimal v, int acc)
    {
        return Math.Round(v, acc, MidpointRounding.AwayFromZero);
    }

    class UomInfo
    {
        public int TypeId;
        public decimal Factor;
        public string TypeName;
    }

    // Converts a customer-UOM length/width into the linear unit of the sales UOM (the unit is the UOM itself for Length,
    // and its square root-scaled linear unit for Area). Returns null when the sales UOM has no length/width (or width) dimension.
    static decimal? ToSalesLinear(decimal? value, UomInfo cust, UomInfo sales, bool isWidth)
    {
        if (value == null) return null;
        bool length = string.Equals(sales.TypeName, "Length", StringComparison.OrdinalIgnoreCase);
        bool area = string.Equals(sales.TypeName, "Area", StringComparison.OrdinalIgnoreCase);
        if (!length && !area) return null;
        if (length && isWidth) return null;
        decimal ratio = cust.Factor / sales.Factor;
        decimal linear = area ? (decimal)Math.Sqrt((double)ratio) : ratio;
        return Math.Round(value.Value * linear, 4, MidpointRounding.AwayFromZero);
    }

    // Saves the order through sp_save_sales_order_json. Amounts are recalculated here from DB tax/price data.
    [WebMethod(EnableSession = true)]
    public static string SaveSalesOrder(SalesOrderSaveRequest request)
    {
        try
        {
            if (request == null || request.master == null || request.items == null)
                return JsonConvert.SerializeObject(Fail("Invalid request."));
            SalesOrderMaster m = request.master;
            if (m.branch_id == null || m.branch_id <= 0)
                return JsonConvert.SerializeObject(Fail("Warehouse is required."));
            if (m.cust_id == null || m.cust_id <= 0)
                return JsonConvert.SerializeObject(Fail("Customer is required."));
            if (m.sm_sales_sessionid == null)
                return JsonConvert.SerializeObject(Fail("Session id is missing."));
            if (request.items.Count == 0)
                return JsonConvert.SerializeObject(Fail("At least one item is required."));
            foreach (SalesOrderItem it in request.items)
            {
                if (it == null || it.itbs_id == null || it.itbs_id <= 0)
                    return JsonConvert.SerializeObject(Fail("Each item needs a valid item selection."));
                if (it.tum_id_cust == null || it.tum_id_cust <= 0)
                    return JsonConvert.SerializeObject(Fail("Each item needs a unit of measure."));
                if (it.si_qty == null || it.si_qty <= 0)
                    return JsonConvert.SerializeObject(Fail("Each item needs a positive final quantity."));
                if (it.si_price == null || it.si_price < 0)
                    return JsonConvert.SerializeObject(Fail("Each item needs a valid price."));
                decimal dr = it.si_discount_rate ?? 0;
                if (dr < 0 || dr > 100)
                    return JsonConvert.SerializeObject(Fail("Discount must be between 0 and 100."));
            }
            if (request.items.Select(i => i.itbs_id).Distinct().Count() != request.items.Count)
                return JsonConvert.SerializeObject(Fail("The same item is added more than once."));

            mySqlConnection db = new mySqlConnection();
            int userId = Convert.ToInt32(HttpContext.Current.Request.Cookies["invntrystaffId"].Value);
            int acc = Convert.ToInt32(db.SelectScalar("select ss_decimal_accuracy from tbl_system_settings"));
            int allowZero = Convert.ToInt32(db.SelectScalar("select ss_allow_zero_stock_order from tbl_system_settings"));

            DataTable br = db.SelectQuery("select branch_tax_method,branch_tax_inclusive,branch_timezone,branch_state_id from tbl_branch tb inner join tbl_user_branches ub on ub.branch_id=tb.branch_id where ub.user_id=@u and tb.branch_id=@b",
                new MySqlParameter[] { new MySqlParameter("@u", userId), new MySqlParameter("@b", m.branch_id.Value) });
            if (br.Rows.Count == 0)
                return JsonConvert.SerializeObject(Fail("Selected warehouse is not available for this user."));
            int taxMethod = Convert.ToInt32(br.Rows[0]["branch_tax_method"]);
            int inclusive = Convert.ToInt32(br.Rows[0]["branch_tax_inclusive"]);

            DataTable cu = db.SelectQuery("select cust_type,cust_state from tbl_customer where cust_id=@c", new MySqlParameter[] { new MySqlParameter("@c", m.cust_id.Value) });
            if (cu.Rows.Count == 0)
                return JsonConvert.SerializeObject(Fail("Customer not found."));
            int custType = Convert.ToInt32(cu.Rows[0]["cust_type"]);
            bool sameState = Convert.ToString(br.Rows[0]["branch_state_id"]) == Convert.ToString(cu.Rows[0]["cust_state"]);

            string ids = string.Join(",", request.items.Select(i => i.itbs_id.Value.ToString()));
            DataTable dtItems = db.SelectQuery("select tis.itbs_id,tis.itm_id,tis.itm_name,tis.itbs_stock,tis.itm_commision,tp.tp_tax_percentage,            tp.tp_cess,im.itm_type,im.itsv_uom_sales,"
                + "(select tip_price from tbl_item_pricelist tip where tip.tpm_id=@tpm and tip.itbs_id=tis.itbs_id limit 1) as classPrice "
                + "from tbl_itembranch_stock tis inner join tbl_tax_profile tp on tp.tp_tax_code=tis.tp_tax_code inner join tbl_item_master im on im.itm_id=tis.itm_id "
                + "where tis.branch_id=@b and tis.itbs_id in (" + ids + ")",
                new MySqlParameter[] { new MySqlParameter("@tpm", custType), new MySqlParameter("@b", m.branch_id.Value) });

            Dictionary<int, UomInfo> uoms = new Dictionary<int, UomInfo>();
            foreach (DataRow ur in db.SelectQuery("select u.tum_id,u.tum_type_id,u.tum_convertion_fac,t.tumt_name from tbl_item_uom u left join tbl_item_uom_type t on t.tumt_id=u.tum_type_id").Rows)
                uoms[Convert.ToInt32(ur["tum_id"])] = new UomInfo
                {
                    TypeId = ur["tum_type_id"] == DBNull.Value ? 0 : Convert.ToInt32(ur["tum_type_id"]),
                    Factor = ur["tum_convertion_fac"] == DBNull.Value ? 0m : Convert.ToDecimal(ur["tum_convertion_fac"]),
                    TypeName = Convert.ToString(ur["tumt_name"])
                };

            decimal sTotal = 0, sDisc = 0, sNet = 0, sTaxable = 0, sTax = 0;
            int row = 0;
            foreach (SalesOrderItem it in request.items)
            {
                DataRow[] f = dtItems.Select("itbs_id=" + it.itbs_id.Value);
                if (f.Length == 0)
                    return JsonConvert.SerializeObject(Fail("An item is not available in the selected warehouse."));
                DataRow d = f[0];
                string nm = Convert.ToString(d["itm_name"]);
                if (allowZero == 0 && it.si_qty.Value > Convert.ToDecimal(d["itbs_stock"]))
                    return JsonConvert.SerializeObject(Fail("Insufficient stock for " + nm + "."));

                decimal tax = Convert.ToDecimal(d["tp_tax_percentage"]);
                decimal cess = Convert.ToDecimal(d["tp_cess"]);
                decimal comm = d["itm_commision"] == DBNull.Value ? 0 : Convert.ToDecimal(d["itm_commision"]);
                decimal qty = it.si_qty.Value;
                decimal price = it.si_price.Value;
                decimal rate = it.si_discount_rate ?? 0;
                decimal basePrice = price;
                if (taxMethod == 0) { tax = 0; cess = 0; }
                else if (inclusive == 1)
                {
                    if (cess > 0) basePrice = 10000m * price / (10000m + 100m * tax + tax * cess);
                    else basePrice = price / (tax / 100m + 1m);
                }
                decimal real = basePrice * qty;
                decimal disc = real * rate / 100m;
                decimal netBase = real - disc;
                decimal taxAmt = netBase * tax / 100m;
                taxAmt = taxAmt + taxAmt * cess / 100m;
                decimal netAmt = netBase + taxAmt;

                // final quantity is always in the item's sales UOM, so the line must be stored with that UOM, not the one entered
                int salesUom = d["itsv_uom_sales"] == DBNull.Value ? 0 : Convert.ToInt32(d["itsv_uom_sales"]);
                if (salesUom <= 0)
                    return JsonConvert.SerializeObject(Fail("Sales unit of measure is not configured for " + nm + "."));

                // length/width arrive in the customer's UOM; keep them as entered and store the sales-UOM equivalents in length/width
                UomInfo custU, salesU;
                if (!uoms.TryGetValue(it.tum_id_cust.Value, out custU) || custU.Factor <= 0)
                    return JsonConvert.SerializeObject(Fail("Selected unit of measure is invalid for " + nm + "."));
                if (!uoms.TryGetValue(salesUom, out salesU) || salesU.Factor <= 0)
                    return JsonConvert.SerializeObject(Fail("Sales unit of measure is invalid for " + nm + "."));
                if (custU.TypeId != salesU.TypeId)
                    return JsonConvert.SerializeObject(Fail("Selected unit of measure cannot be converted to the sales unit for " + nm + "."));
                decimal? custLen = it.length > 0 ? it.length : null, custWid = it.width > 0 ? it.width : null;
                it.sio_length_cust_fraction = custLen;
                it.sio_width_cust_fraction = custWid;
                it.length = ToSalesLinear(custLen, custU, salesU, false);
                it.width = ToSalesLinear(custWid, custU, salesU, true);

                it.row_no = row++;
                it.tum_id = salesUom;
                it.itm_id = Convert.ToInt32(d["itm_id"]);
                it.itm_name = nm;
                it.itm_type = Convert.ToInt32(d["itm_type"]);
                it.si_org_price = d["classPrice"] == DBNull.Value ? price : Convert.ToDecimal(d["classPrice"]);
                it.si_price = Rnd(price, acc);
                it.si_total = Rnd(real, acc);
                it.si_discount_rate = rate;
                it.si_discount_amount = Rnd(disc, acc);
                it.si_tax_amount = Rnd(taxAmt, acc);
                it.si_net_amount = Rnd(netAmt, acc);
                it.si_tax_excluded_total = it.si_net_amount - it.si_tax_amount;
                it.si_item_tax = tax;
                it.si_item_cess = cess;
                it.itm_commision = comm;
                it.itm_commisionamt = Rnd((taxMethod == 0 ? netBase : netAmt) * comm / 100m, acc);
                it.si_foc = 0;
                it.si_approval_status = 0;
                it.si_itm_type = 0;
                it.ofr_id = 0;
                it.ofritm_id = 0;
                if (taxMethod == 2)
                {
                    decimal half = Rnd(tax / 2m, acc);
                    it.si_item_cgst = sameState ? half : 0;
                    it.si_item_sgst = sameState ? half : 0;
                    it.si_item_igst = sameState ? 0 : tax;
                    it.si_item_utgst = 0;
                }
                sTotal += it.si_total.Value;
                sDisc += it.si_discount_amount.Value;
                sNet += it.si_net_amount.Value;
                sTaxable += it.si_tax_excluded_total.Value;
                sTax += it.si_tax_amount.Value;
            }

            string tzId = Convert.ToString(br.Rows[0]["branch_timezone"]);
            DateTime now;
            try { now = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById(tzId)); }
            catch (Exception) { now = DateTime.Now; }
            string nowStr = now.ToString("yyyy-MM-dd HH:mm:ss");

            m.sm_userid = userId;
            m.sm_date = nowStr;
            m.sm_last_updated_date = nowStr;
            m.sm_total = sTotal;
            m.sm_discount_rate = 0;
            m.sm_discount_amount = sDisc;
            m.sm_netamount = sNet;
            m.sm_tax_excluded_amt = sTaxable;
            m.sm_tax_amount = sTax;
            m.branch_tax_method = taxMethod.ToString();
            m.branch_tax_inclusive = inclusive.ToString();
            m.sm_price_class = custType;
            m.sm_type = 1;
            m.sm_delivery_status = SalesOrderStatus.New; // new orders always start as New; approval is a separate server-validated action
            m.sm_order_type = m.sm_order_type ?? 0;
            m.sm_payment_type = m.sm_payment_type ?? 0;
            m.sm_discount_rate = (sTaxable + sDisc) == 0 ? 0 : Rnd(sDisc * 100m / (sTaxable + sDisc), acc);
            m.smo_id = null; m.sm_id = null;

            // the SP prefers smo_/sio_ values, so drop any client-supplied ones to keep the server-calculated sm_/si_ values
            foreach (System.Reflection.PropertyInfo p in typeof(SalesOrderMaster).GetProperties())
                if (p.Name.StartsWith("smo_")) p.SetValue(m, null, null);
            foreach (SalesOrderItem it in request.items)
                foreach (System.Reflection.PropertyInfo p in typeof(SalesOrderItem).GetProperties())
                    if (p.Name.StartsWith("sio_") && !p.Name.EndsWith("_cust_fraction")) p.SetValue(it, null, null);

            JsonSerializerSettings js = new JsonSerializerSettings { NullValueHandling = NullValueHandling.Ignore };
            string orderJson = JsonConvert.SerializeObject(request, js);

            using (MySqlConnection con = new MySqlConnection(System.Configuration.ConfigurationManager.AppSettings["db_connect_mysql"]))
            using (MySqlCommand cmd = new MySqlCommand("sp_save_sales_order_json", con))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Add(new MySqlParameter("p_order_json", MySqlDbType.JSON) { Value = orderJson });
                cmd.Parameters.Add(new MySqlParameter("p_smo_id", MySqlDbType.Int32) { Direction = ParameterDirection.Output });
                cmd.Parameters.Add(new MySqlParameter("p_result", MySqlDbType.LongText) { Direction = ParameterDirection.Output });
                con.Open();
                cmd.ExecuteNonQuery();
                object res = cmd.Parameters["p_result"].Value;
                string resText = (res == null || res == DBNull.Value) ? null : Convert.ToString(res);
                if (string.IsNullOrEmpty(resText))
                    return JsonConvert.SerializeObject(Fail("Sales order could not be saved."));
                Newtonsoft.Json.Linq.JObject r = Newtonsoft.Json.Linq.JObject.Parse(resText);
                bool ok = r["success"] != null && (bool)r["success"];
                if (!ok)
                {
                    LogClass elog = new LogClass("salesordererror");
                    elog.write(new Exception(resText));
                    return JsonConvert.SerializeObject(Fail(Convert.ToString(r["message"] ?? "Sales order could not be saved.")));
                }
                return JsonConvert.SerializeObject(new { status = true, message = "Sales order saved.", smo_id = (int)r["smo_id"], net_amount = sNet });
            }
        }
        catch (Exception ex)
        {
            LogClass log = new LogClass("salesordererror");
            log.write(ex);
            return JsonConvert.SerializeObject(Fail("Unable to save sales order. Please try again."));
        }
    }
}
