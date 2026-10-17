using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.Services;
using System.Data;
using System.Data.SqlTypes;
using System.Data.SqlClient;
using System.Text;
using commonfunction;
using Newtonsoft.Json;

public partial class web_reports_Item_LedgerReport : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication warehouse = new LoginAuthentication();
        warehouse.userAuthentication();
        warehouse.checkPageAcess(72);

    }

    [WebMethod]
    public static string showItems(string searchText, string type_id)
    {
        StringBuilder sb = new StringBuilder();


        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();

        string query = "";

        if (type_id == "1") { query = "SELECT cust_id as id,cust_name as label,cust_name as value FROM tbl_customer where cust_name like '%" + searchText + "%'  ORDER BY cust_name ASC"; }
        else { query = "SELECT vn_id as id,vn_name as label,vn_name as value FROM tbl_vendor where vn_name like '%" + searchText + "%'  ORDER BY vn_name ASC"; }


        dt = db.SelectQuery(query);
        if (dt.Rows.Count > 0)
        {
            //sb.Append("[");
            //foreach (DataRow row in dt.Rows)
            //{
            //    sb.Append("{\"id\":\"" + Convert.ToString(row["itbs_id"]) + "\",");
            //    sb.Append("\"label\":\"" + Convert.ToString(row["itm_name"]) + "\",");
            //    sb.Append("\"value\":\"" + Convert.ToString(row["itm_name"]) + "\"}");

            //    sb.Append(",");
            //}
            //sb.Remove(sb.Length - 1, 1);
            //sb.Append("]");
            string jsonData = JsonConvert.SerializeObject(dt, Formatting.Indented);
            sb.Append(jsonData);
        }
        else
        {
            sb.Append("[{\"id\":\"-1\",\"label\":\"No Customers Found\",\"value\":\"No Customers Found\"}]");
        }

        return sb.ToString();

    }

    [WebMethod]
    public static string showSelectedEntity(string type_id, string id)
    {
        StringBuilder sb = new StringBuilder();


        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();

        string query = "";

        if (type_id == "1") { query = @"SELECT tc.cust_id, tc.cust_name, tc.cust_address, tc.cust_city, tc.cust_reg_id, 
tc.cust_tax_reg_id, tc.cust_phone, tc.cust_phone1, tc.cust_email,ts.state_name,tl.location_name FROM tbl_customer tc
JOIN tbl_state ts ON ts.state_id=tc.cust_state
JOIN tbl_location tl ON tl.location_id=tc.location_id WHERE tc.cust_id='" + id + "';"; }
        else { query = "SELECT tv.vn_id, tv.vn_name, tv.vn_address, tv.vn_city, tv.vn_phone1, tv.vn_phone2, tv.vn_gst, tv.vn_state FROM tbl_vendor tv WHERE tv.vn_id='" + id + "'"; }


        dt = db.SelectQuery(query);
        if (dt.Rows.Count > 0)
        {
            string jsonData = JsonConvert.SerializeObject(dt, Formatting.Indented);
            sb.Append(jsonData);
        }
        else
        {
            sb.Append("[{\"id\":\"-1\",\"label\":\"No Customers Found\",\"value\":\"No Customers Found\"}]");
        }

        return sb.ToString();

    }

    public static string Get_Current_Date_Time(string TimeZoneName)
    {
        var CURR_TIME_ZONE = TimeZoneInfo.FindSystemTimeZoneById(TimeZoneName);
        var TimeNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, CURR_TIME_ZONE);
        var date_time_now = TimeNow.ToString("yyyy-MM-dd HH:mm:ss");
        return date_time_now;
    }

    [WebMethod]
    public static string Get_Transactions(int page, int perpage, Dictionary<string, string> filters)
    {
        mySqlConnection db = new mySqlConnection();
        string conv_report_cond = " WHERE 1=1";

        if (filters.Count > 0)
        {
            if (filters.ContainsKey("report_id")) // 1 -customer , 2- supplier
            {
                conv_report_cond += " AND t.action_type IN '" + filters["branch_id"] + "'";
            }

        }

        int per_page = perpage;
        int offset = (page - 1) * per_page;
        string CountQuery = @"SELECT COUNT(t.id) AS `count`
FROM tbl_transactions t
WHERE
    t.partner_type = " + filters["partner_type"] + " AND t.partner_id = " + filters["partner_id"] + " AND t.date BETWEEN '" + filters["date_from"] + "' AND '" + filters["date_to"] + "' AND t.action_type IN(" + filters["action_type"] + ")  ";
        var dtcount = Convert.ToInt32(db.SelectScalar(CountQuery));
		int numrows = dtcount;
        if (numrows == 0)
        {
            return "N"; ;
        }

        string Qry = @"SELECT
   DATE_FORMAT(t.date, '%d/%m/%Y') AS `Date`,
    t.id AS `Ref_ID`,
    CASE t.action_type
        WHEN 1 THEN 'Sales'
        WHEN 2 THEN 'Purchase'
        WHEN 3 THEN 'Sales Return'
        WHEN 4 THEN 'Purchase Return'
        WHEN 5 THEN 'Withdrawal'
        WHEN 6 THEN 'Deposit'
        WHEN 7 THEN 'Debit Note'
        WHEN 8 THEN 'Stock Transfer'
        WHEN 9 THEN 'Income'
        WHEN 10 THEN 'Expense'
        WHEN 11 THEN 'Manual Item Edit'
        WHEN 12 THEN 'Item Conversion'
        ELSE 'Unknown'
    END AS `Transaction_Type`,
    IFNULL(t.voucher_no, '-') AS `Voucher_No`,
IFNULL(t.po_number, '-') AS `PO_Number`,
t.narration AS 'Description',
    t.dr AS `Debit`,
    t.cr AS `Credit`
FROM tbl_transactions t
WHERE
    t.partner_type = " + filters["partner_type"] + " AND t.partner_id = " + filters["partner_id"] + " AND t.date BETWEEN '" + filters["date_from"] + "' AND '" + filters["date_to"] + "' AND t.action_type IN(" + filters["action_type"] + ")  ORDER BY t.date LIMIT " + offset.ToString() + " ," + per_page + "";

        string jsonResponse = "";

        DataTable dt = db.SelectQuery(Qry);

        if (dt.Rows.Count > 0)
        {
            string jsonData = JsonConvert.SerializeObject(dt, Formatting.Indented);
            jsonResponse = "{\"count\":\"" + dtcount + "\",\"data\":" + jsonData + "}";
        }
        else
        {
            jsonResponse = "N";
        }

        return jsonResponse;
    }

	[WebMethod]
	public static string Download_Transactions(int page, int perpage, Dictionary<string, string> filters)
	{
		mySqlConnection db = new mySqlConnection();
		string conv_report_cond = " WHERE 1=1";

		if (filters.Count > 0)
		{
			if (filters.ContainsKey("report_id")) // 1 -customer , 2- supplier
			{
				conv_report_cond += " AND t.action_type IN '" + filters["branch_id"] + "'";
			}

		}

		int per_page = perpage;
		int offset = (page - 1) * per_page;
		string CountQuery = @"SELECT COUNT(t.id) AS `count`
FROM tbl_transactions t
WHERE
    t.partner_type = " + filters["partner_type"] + " AND t.partner_id = " + filters["partner_id"] + " AND t.date BETWEEN '" + filters["date_from"] + "' AND '" + filters["date_to"] + "' AND t.action_type IN(" + filters["action_type"] + ")  ORDER BY t.date, t.id ";
		var dtcount = Convert.ToInt32(db.SelectScalar(CountQuery));
		int numrows = dtcount;
		if (numrows == 0)
		{
			return "N"; ;
		}

		string Qry = @"SELECT
   DATE_FORMAT(t.date, '%d/%m/%Y') AS `Date`,
    t.id AS `Ref.ID`,
    CASE t.action_type
        WHEN 1 THEN 'Sales'
        WHEN 2 THEN 'Purchase'
        WHEN 3 THEN 'Sales Return'
        WHEN 4 THEN 'Purchase Return'
        WHEN 5 THEN 'Withdrawal'
        WHEN 6 THEN 'Deposit'
        WHEN 7 THEN 'Debit Note'
        WHEN 8 THEN 'Stock Transfer'
        WHEN 9 THEN 'Income'
        WHEN 10 THEN 'Expense'
        WHEN 11 THEN 'Manual Item Edit'
        WHEN 12 THEN 'Item Conversion'
        ELSE 'Unknown'
    END AS `Transaction Type`,
    IFNULL(t.voucher_no, '-') AS `Voucher No`,
IFNULL(t.po_number, '-') AS `PO Number`,
t.narration AS 'Description',
    t.dr AS `Debit`,
    t.cr AS `Credit`
FROM tbl_transactions t
WHERE
    t.partner_type = " + filters["partner_type"] + " AND t.partner_id = " + filters["partner_id"] + " AND t.date BETWEEN '" + filters["date_from"] + "' AND '" + filters["date_to"] + "' AND t.action_type IN(" + filters["action_type"] + ")  ORDER BY t.date";

		string jsonResponse = "";

		var dt_base = db.SelectQuery(CountQuery);
		if (dt_base.Rows.Count == 0)
		{
			jsonResponse = "{\"count\":\"" + dt_base.Rows.Count + "\"}";
			return jsonResponse;
		}

		HttpContext.Current.Session["downloadqry"] = Qry;

		jsonResponse = "{\"count\":\"" + dt_base.Rows.Count + "\"}";
		return jsonResponse;
	}

}