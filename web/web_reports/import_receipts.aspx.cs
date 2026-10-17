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

public partial class web_reports_import_receipts : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication reports = new LoginAuthentication();
        reports.userAuthentication();
        loadWarehouse();
    }

    /// <summary>
    /// method for load warehouse
    /// </summary>
    public void loadWarehouse()
    {
        mySqlConnection db = new mySqlConnection();
        //load suppliers
        DataTable vendorDt = db.SelectQuery("select branch_id,branch_name from tbl_branch");
        selWarehouse.Items.Add(new ListItem("SELECT", "-1"));
        foreach (DataRow vendorRow in vendorDt.Rows)
        {
            selWarehouse.Items.Add(new ListItem(vendorRow["branch_name"].ToString(), vendorRow["branch_id"].ToString()));
        }

    }
   

    [WebMethod]
    public static string showsalespersons()
    {

        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        StringBuilder sb = new StringBuilder();
        string query = "select user_id,first_name,last_name  from tbl_user_details order by user_id";
        dt = db.SelectQuery(query);
        return JsonConvert.SerializeObject(dt, Formatting.Indented);

    }

    #region
    //webmethod for showing stock transcations based on search fields 
    #endregion
    [WebMethod]
    public static string showTransactions(int page, int perpage, Dictionary<string, string> filters)
    {
        mySqlConnection db = new mySqlConnection();
        string qry_condition = " where 1=1 and cr!=0 and action_type=1 and sm_invoice_no!='' and sm_delivery_status not in (4,5)";
        if (filters.Count > 0)
        {
            if (filters.ContainsKey("salesmanId"))
            {
                qry_condition += " and tr.user_id  = '" + filters["salesmanId"] + "'";
            }
            if (filters.ContainsKey("from_date"))
            {
                qry_condition += " and date(date)>=STR_TO_DATE('" + filters["from_date"].Replace("-", "/") + "','%d/%m/%Y')";
            }
            if (filters.ContainsKey("to_date"))
            {
                qry_condition += " and date(date)<=STR_TO_DATE('" + filters["to_date"].Replace("-", "/") + "','%d/%m/%Y')";
            }
            if (filters.ContainsKey("warehouse"))
            {
                qry_condition += " and sm.branch_id  = '" + filters["warehouse"] + "'";
            }

        }
        int per_page = perpage;
        int offset = (page - 1) * per_page;
        string countQry = "select count(*) from tbl_transactions tr inner join tbl_sales_master sm on sm.sm_id=tr.action_ref_id " + qry_condition;
        //string countQry = "SELECT sm_id FROM tbl_sales_master " + qry_condition + ""+group_condition;

        DataTable dtcount, dt = new DataTable();
        dtcount = db.SelectQuery(countQry);
        double numrows = Convert.ToInt32(db.SelectScalar(countQry));
        if (numrows == 0)
        {
            return "{\"count\":\"" + numrows + "\",\"data\":[]}"; 
        }

        string innerqry = "select tr.id as transId,sm_invoice_no as invoice,sm_netamount as netAmt,DATE_FORMAT(`sm_date`, '%d-%b-%Y %h:%i %p') as bill_date,DATE_FORMAT(`date`, '%d-%b-%Y %h:%i %p') as trans_date,action_type"
            + " ,action_ref_id,tc.cust_id,cust_name,concat(tu.first_name,\" \",tu.last_name) as user,narration,cr,dr,(select IFNULL((sum(dr)-sum(cr)),0) from tbl_transactions where action_ref_id=tr.action_ref_id) as balance"
            + " from tbl_transactions tr inner join tbl_user_details tu on tu.user_id=tr.user_id left join tbl_customer tc on tc.cust_id=tr.partner_id inner join tbl_sales_master sm on sm.sm_id=tr.action_ref_id"
            + "  " + qry_condition + " order by tr.date desc LIMIT " + offset.ToString() + " ," + per_page;
        // +" order by str.id desc";
        string jsonResponse = "";
        dt = db.SelectQuery(innerqry);

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
    }//end

    [WebMethod]
    public static string DownloadReport(Dictionary<string, string> filters)
    {
        mySqlConnection db = new mySqlConnection();
        string qry_condition = " where 1=1 and cr!=0 and action_type=1 and sm_invoice_no!='' and sm_delivery_status not in (4,5) ";
        if (filters.Count > 0)
        {
            if (filters.ContainsKey("salesmanId"))
            {
                qry_condition += " and tr.user_id  = '" + filters["salesmanId"] + "'";
            }
            if (filters.ContainsKey("from_date"))
            {
                qry_condition += " and date(date)>=STR_TO_DATE('" + filters["from_date"].Replace("-", "/") + "','%d/%m/%Y')";
            }
            if (filters.ContainsKey("to_date"))
            {
                qry_condition += " and date(date)<=STR_TO_DATE('" + filters["to_date"].Replace("-", "/") + "','%d/%m/%Y')";
            }
            if (filters.ContainsKey("warehouse"))
            {
                qry_condition += " and sm.branch_id  = '" + filters["warehouse"] + "'";
            }

        }
       
        string countQry = "select count(*) from tbl_transactions tr inner join tbl_sales_master sm on sm.sm_id=tr.action_ref_id " + qry_condition;
        //string countQry = "SELECT sm_id FROM tbl_sales_master " + qry_condition + ""+group_condition;

        DataTable dtcount, dt = new DataTable();
        dtcount = db.SelectQuery(countQry);
        double numrows = Convert.ToInt32(db.SelectScalar(countQry));
        if (numrows == 0)
        {
            return "N";
        }

        string innerqry = "select sm_invoice_no as InvoiceNumber,DATE_FORMAT(`sm_date`, '%d-%b-%Y %h:%i %p') as BilledDate,cust_name as Customer,DATE_FORMAT(`date`, '%d-%b-%Y %h:%i %p') as ReceiptedDate,sm_netamount as NetAmt,"
            + " cr as PaidAmount,(select IFNULL((sum(dr)-sum(cr)),0) from tbl_transactions where action_ref_id=tr.action_ref_id) as Balance,concat(tu.first_name,\" \",tu.last_name) as User"
            + " from tbl_transactions tr inner join tbl_user_details tu on tu.user_id=tr.user_id left join tbl_customer tc on tc.cust_id=tr.partner_id inner join tbl_sales_master sm on sm.sm_id=tr.action_ref_id"
            + "  " + qry_condition + " order by tr.date desc";
        // +" order by str.id desc";
        HttpContext.Current.Session["downloadReceiptqry"] = innerqry;
        return "Y";
    }//end
}