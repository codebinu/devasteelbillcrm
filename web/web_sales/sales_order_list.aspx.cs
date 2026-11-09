using commonfunction;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Data;
using System.Web;
using System.Web.Services;
using MySql.Data.MySqlClient;

public partial class web_sales_sales_order_list : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication bill = new LoginAuthentication();
        bill.userAuthentication();
        bill.checkPageAcess(7);
    }

    static string Cookie(string name)
    {
        var c = HttpContext.Current.Request.Cookies[name];
        return c != null ? c.Value : "";
    }

    static string StatusNameCaseSql()
    {
        var sb = new System.Text.StringBuilder();
        for (int i = 0; i <= SalesOrderStatus.MaxValue; i++)
            if (SalesOrderStatus.Name(i) != "")
                sb.Append("when ").Append(i).Append(" then '").Append(SalesOrderStatus.Name(i)).Append("' ");
        return sb.ToString();
    }

    [WebMethod]
    public static string getBranches()
    {
        mySqlConnection db = new mySqlConnection();
        string query = "select tb.branch_id,branch_name from tbl_branch tb inner join tbl_user_branches ub on ub.branch_id=tb.branch_id where user_id = @userId";
        DataTable dt = db.SelectQuery(query, new MySqlParameter[] { new MySqlParameter("@userId", Cookie("invntrystaffId")) });
        return JsonConvert.SerializeObject(dt);
    }

    [WebMethod]
    public static string searchSalesOrders(int page, Dictionary<string, string> filters, int perpage, string sortBy, string sortDir)
    {
        try
        {
            if (filters == null) filters = new Dictionary<string, string>();
            if (page < 1) page = 1;
            if (perpage != 50 && perpage != 100 && perpage != 250 && perpage != 500) perpage = 50;

            string staffTypeId = Cookie("invntrystaffTypeID");
            string staffId = Cookie("invntrystaffId");
            int staffIdNum;
            if (!int.TryParse(staffId, out staffIdNum))
                return "{\"count\":\"0\",\"data\":[]}";

            List<MySqlParameter> ps = new List<MySqlParameter>();
            string cond = " where 1=1";

            if (staffTypeId == "2")
            {
                cond += " and smo.smo_userid = @staffId";
                ps.Add(new MySqlParameter("@staffId", staffIdNum));
            }

            string v;
            if (filters.TryGetValue("search", out v) && v.Trim() != "")
            {
                v = v.Trim();
                cond += " and (cast(smo.smo_id as char) like @s or smo.smo_invoice_no like @s or tc.cust_name like @s or cast(smo.cust_id as char) like @s"
                    + " or (case smo.smo_delivery_status " + StatusNameCaseSql() + " else '' end) like @s)";
                ps.Add(new MySqlParameter("@s", "%" + v + "%"));
            }
            if (filters.TryGetValue("custSearch", out v) && v.Trim() != "")
            {
                cond += " and (tc.cust_name like @cs or cast(smo.cust_id as char) = @csExact)";
                ps.Add(new MySqlParameter("@cs", "%" + v.Trim() + "%"));
                ps.Add(new MySqlParameter("@csExact", v.Trim()));
            }
            int n;
            if (filters.TryGetValue("branch", out v) && int.TryParse(v, out n) && n > 0)
            {
                cond += " and smo.branch_id = @branch and smo.branch_id in (select branch_id from tbl_user_branches where user_id = @bu)";
                ps.Add(new MySqlParameter("@branch", n));
                ps.Add(new MySqlParameter("@bu", staffIdNum));
            }
            else
            {
                cond += " and smo.branch_id in (select branch_id from tbl_user_branches where user_id = @bu)";
                ps.Add(new MySqlParameter("@bu", staffIdNum));
            }
            if (filters.TryGetValue("order_status", out v) && int.TryParse(v, out n) && n >= 0 && n <= SalesOrderStatus.MaxValue)
            {
                cond += " and smo.smo_delivery_status = @status";
                ps.Add(new MySqlParameter("@status", n));
            }
            if (filters.TryGetValue("seller_id", out v) && int.TryParse(v, out n) && n > 0)
            {
                cond += " and smo.smo_userid = @seller";
                ps.Add(new MySqlParameter("@seller", n));
            }
            DateTime d;
            if (filters.TryGetValue("from_date", out v) && DateTime.TryParseExact(v.Replace("/", "-"), "dd-MM-yyyy", System.Globalization.CultureInfo.InvariantCulture, System.Globalization.DateTimeStyles.None, out d))
            {
                cond += " and smo.smo_date >= @fromDate";
                ps.Add(new MySqlParameter("@fromDate", d.Date));
            }
            if (filters.TryGetValue("to_date", out v) && DateTime.TryParseExact(v.Replace("/", "-"), "dd-MM-yyyy", System.Globalization.CultureInfo.InvariantCulture, System.Globalization.DateTimeStyles.None, out d))
            {
                cond += " and smo.smo_date < @toDate";
                ps.Add(new MySqlParameter("@toDate", d.Date.AddDays(1)));
            }

            string from = " from tbl_sales_master_order smo inner join tbl_customer tc on tc.cust_id=smo.cust_id"
                + " left join tbl_price_master tpm on tpm.tpm_id=tc.cust_type"
                + " left join tbl_branch tb on tb.branch_id=smo.branch_id"
                + " left join tbl_user_details ud on ud.user_id=smo.smo_userid";

            mySqlConnection db = new mySqlConnection();
            string scalar = db.SelectScalar("select count(*) " + from + cond, Clone(ps));
            int count = string.IsNullOrEmpty(scalar) ? 0 : Convert.ToInt32(scalar);
            if (count == 0)
                return "{\"count\":\"0\",\"data\":[]}";

            string orderCol;
            switch (sortBy)
            {
                case "number": orderCol = "smo.smo_id"; break;
                case "customer": orderCol = "tc.cust_name"; break;
                case "total": orderCol = "smo.smo_netamount"; break;
                case "status": orderCol = "smo.smo_delivery_status"; break;
                case "warehouse": orderCol = "tb.branch_name"; break;
                default: orderCol = "smo.smo_date"; break;
            }
            string dir = (sortDir ?? "").ToLower() == "asc" ? "asc" : "desc";
            int offset = (page - 1) * perpage;

            string sql = "select smo.smo_id,smo.smo_invoice_no,smo.cust_id,tc.cust_name,tb.branch_name,tpm.tpm_name as class,tc.cust_phone,tc.cust_email,tc.cust_city,tc.cust_tax_reg_id,tc.cust_amount,tc.max_creditamt,smo.smo_total,smo.smo_discount_amount,smo.smo_tax_amount,smo.smo_payment_type,smo.smo_order_type,smo.smo_netamount as net_amount,smo.smo_delivery_status as order_status,"
                + "DATE_FORMAT(smo.smo_date,'%d-%b-%Y %H:%i') as orderDate,concat(ifnull(ud.first_name,''),' ',ifnull(ud.last_name,'')) as seller_name"
                + from + cond + " order by " + orderCol + " " + dir + ", smo.smo_id desc LIMIT " + offset + "," + perpage;

            DataTable dt = db.SelectQuery(sql, Clone(ps));
            return "{\"count\":\"" + count + "\",\"data\":" + JsonConvert.SerializeObject(dt) + "}";
        }
        catch (Exception ex)
        {
            LogClass log = new LogClass("salesordererror");
            log.write(ex);
            return "E";
        }
    }

    private static MySqlParameter[] Clone(List<MySqlParameter> source)
    {
        MySqlParameter[] copy = new MySqlParameter[source.Count];
        for (int i = 0; i < source.Count; i++)
            copy[i] = new MySqlParameter(source[i].ParameterName, source[i].Value);
        return copy;
    }
}
