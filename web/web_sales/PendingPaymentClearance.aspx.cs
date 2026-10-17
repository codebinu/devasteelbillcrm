using commonfunction;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;


public partial class web_sales_PendingPaymentClearance : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication reports = new LoginAuthentication();
        reports.userAuthentication();
        loadLocations();
    }

    public void loadLocations()
    {
        mySqlConnection db = new mySqlConnection();
        //load suppliers
        DataTable vendorDt = db.SelectQuery("select location_id,location_name from tbl_location");
        selLocations.Items.Add(new ListItem("ALL LOCATIONS", "-1"));
        foreach (DataRow vendorRow in vendorDt.Rows)
        {
            selLocations.Items.Add(new ListItem(vendorRow["location_name"].ToString(), vendorRow["location_id"].ToString()));
        }

    }

   
    [WebMethod]
    public static string getCustomerswithBalance(Dictionary<string, string> filters)
    {

        var result = "";
        

        try
        {
            var qry_condition = "";
            if (filters.ContainsKey("location_id"))
            {
                qry_condition += " and cu.location_id  = '" + filters["location_id"] + "' ";
            }

            var perPage = 100;
            var totalRows = 0;
            var lowerBound = ((Convert.ToInt32(filters["page"]) - 1) * perPage);
            var upperBound = perPage + lowerBound - 1;
            var count_qry = @"SELECT cu.cust_id,(SUM(tr.dr)-SUM(tr.cr)) AS balance_to_clear,cu.cust_amount,
(CASE 
 WHEN (SUM(tr.dr)-SUM(tr.cr)) > cu.cust_amount THEN ABS(cu.cust_amount-(SUM(tr.dr)-SUM(tr.cr))) 
 WHEN cu.cust_amount < 0  THEN ABS(cu.cust_amount) 
 ELSE 0 
 END) AS available_to_clear 
 
FROM tbl_transactions tr 
JOIN tbl_sales_master sm ON (sm.sm_id=tr.action_ref_id AND tr.action_type=1) 
JOIN tbl_customer cu ON sm.cust_id=cu.cust_id 
WHERE sm.sm_delivery_status NOT IN (4,5) AND tr.partner_type=1 "+ qry_condition + " GROUP BY tr.partner_id HAVING balance_to_clear>0 and available_to_clear>0";
            var dt_count = new mySqlConnection().SelectQuery(count_qry);
            totalRows = dt_count.Rows.Count;

            var main_qry = @"SELECT cu.cust_id,cu.cust_reg_id,cu.cust_name,cu.cust_address,cu.cust_city,(SUM(tr.dr)-SUM(tr.cr)) AS balance_to_clear,cu.cust_amount,
(CASE 
 WHEN (SUM(tr.dr)-SUM(tr.cr)) > cu.cust_amount THEN ABS(cu.cust_amount-(SUM(tr.dr)-SUM(tr.cr))) 
 WHEN cu.cust_amount < 0  THEN ABS(cu.cust_amount) 
 ELSE 0 
 END) AS available_to_clear 
 
FROM tbl_transactions tr 
JOIN tbl_sales_master sm ON (sm.sm_id=tr.action_ref_id AND tr.action_type=1) 
JOIN tbl_customer cu ON sm.cust_id=cu.cust_id 
WHERE sm.sm_delivery_status NOT IN (4,5) AND tr.partner_type=1 " + qry_condition + " GROUP BY tr.partner_id HAVING balance_to_clear>0 and available_to_clear>0 LIMIT " + perPage + " OFFSET " + lowerBound + "";

            result = "{\"totalRows\":\"" + totalRows + "\",\"perPage\":\"" + perPage + "\",\"customer_list\":" + JsonConvert.SerializeObject(new mySqlConnection().SelectQuery(main_qry), Formatting.Indented) + "}";
            return result;
        }
        catch (Exception ex)
        {
            var log = new LogClass("getCustomerswithBalance");
            log.write(ex);
            result = "ERROR";
            return result;
        }
    }
}