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

public partial class web_inventory_Manage_Conversions : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication warehouse = new LoginAuthentication();
        warehouse.userAuthentication();
        warehouse.checkPageAcess(74);

        loadDatas();
    }

    public void loadDatas()
    {
        mySqlConnection db = new mySqlConnection();
        DataTable brDt = db.SelectQuery("SELECT br.branch_name,br.branch_id FROM tbl_branch br INNER JOIN tbl_user_branches ub ON ub.branch_id=br.branch_id WHERE ub.user_id='" + HttpContext.Current.Request.Cookies["invntrystaffId"].Value + "' ORDER BY br.branch_name");
        Select_Warehouse.Items.Add(new ListItem("All Warehouses", "-1"));        
        foreach (DataRow brRow in brDt.Rows)
        {
            Select_Warehouse.Items.Add(new ListItem(brRow["branch_name"].ToString(), brRow["branch_id"].ToString()));            
        }

        DataTable userDt = db.SelectQuery("SELECT CM.user_id,CONCAT(UD.first_name,' ',UD.last_name) AS username FROM tbl_itm_conversion_master CM INNER JOIN tbl_user_details UD ON UD.user_id=CM.user_id INNER JOIN tbl_user_branches UB ON UB.branch_id=CM.branch_id WHERE UB.user_id='" + HttpContext.Current.Request.Cookies["invntrystaffId"].Value + "' GROUP BY CM.user_id ORDER BY username ASC");
        Select_user.Items.Add(new ListItem("All Users", "-1"));
        
        foreach (DataRow userRow in userDt.Rows)
        {
            Select_user.Items.Add(new ListItem(userRow["username"].ToString(), userRow["user_id"].ToString()));
            
        }

    }

    [WebMethod]
    public static string Get_Conversions(int page, int perpage, Dictionary<string, string> filters)
    {
        mySqlConnection db = new mySqlConnection();
        string conv_report_cond = " WHERE 1=1";

        if (filters.Count > 0)
        {
            if (filters.ContainsKey("branch_id"))
            {
                conv_report_cond += " AND CM.branch_id='" + filters["branch_id"] + "'";
            }

            if (filters.ContainsKey("user_id"))
            {
                conv_report_cond += " AND CM.user_id='" + filters["user_id"] + "'";
            }

            if (filters.ContainsKey("date_from"))
            {
                conv_report_cond += " AND DATE(CM.conv_date)>='" + filters["date_from"] + "'";
            }

            if (filters.ContainsKey("date_to"))
            {
                conv_report_cond += " AND DATE(CM.conv_date)<='" + filters["date_to"] + "'";
            }

        }

        int per_page = perpage;
        int offset = (page - 1) * per_page;
        string CountQuery = @"SELECT CM.conv_id FROM 
(SELECT itb.itm_name,itc.conv_id,itc.itbs_id,itc.conv_itm_type,itc.conv_qty,itc.conv_itm_id FROM tbl_itm_converted_items itc INNER JOIN tbl_itembranch_stock itb ON itb.itbs_id=itc.itbs_id) T1 
INNER JOIN tbl_itm_conversion_master CM ON CM.conv_id=T1.conv_id 
INNER JOIN tbl_user_details ud ON ud.user_id=CM.user_id 
INNER JOIN tbl_branch br ON br.branch_id=CM.branch_id  " + conv_report_cond + " GROUP BY CM.conv_id ORDER BY T1.conv_itm_id ASC ";
        var dtcount = db.SelectQuery(CountQuery);
        int numrows = dtcount.Rows.Count;
        if (numrows == 0)
        {
            return "N"; ;
        }

        string Qry = @"SELECT CM.conv_id,DATE_FORMAT(CM.conv_date, '%d-%M-%Y') as conv_date,DATE_FORMAT(CM.conv_date, '%h:%i %p') as conv_time,br.branch_name,CONCAT(ud.first_name,' ',ud.last_name) AS username,GROUP_CONCAT(IF(T1.conv_itm_type=1 , CONCAT(T1.itm_name , ' : <strong>' , T1.conv_qty ,' Qty</strong>' ) , NULL) SEPARATOR '<br />') AS input_items, GROUP_CONCAT(IF(T1.conv_itm_type=2, CONCAT(T1.itm_name , ' : <strong>' , T1.conv_qty ,' Qty</strong>' ) ,NULL) SEPARATOR '<br />') AS output_items 
FROM 
(SELECT itb.itm_name,itc.conv_id,itc.itbs_id,itc.conv_itm_type,itc.conv_qty,itc.conv_itm_id FROM tbl_itm_converted_items itc INNER JOIN tbl_itembranch_stock itb ON itb.itbs_id=itc.itbs_id) T1 
INNER JOIN tbl_itm_conversion_master CM ON CM.conv_id=T1.conv_id 
INNER JOIN tbl_user_details ud ON ud.user_id=CM.user_id 
INNER JOIN tbl_branch br ON br.branch_id=CM.branch_id " + conv_report_cond + " GROUP BY CM.conv_id ORDER BY T1.conv_itm_id ASC LIMIT " + offset.ToString() + " ," + per_page + "";

        string jsonResponse = "";

        DataTable dt = db.SelectQuery(Qry);

        if (dt.Rows.Count > 0)
        {
            string jsonData = JsonConvert.SerializeObject(dt, Formatting.Indented);
            jsonResponse = "{\"count\":\"" + numrows + "\",\"data\":" + jsonData + "}";
        }
        else
        {
            jsonResponse = "N";
        }

        return jsonResponse;
    }


}