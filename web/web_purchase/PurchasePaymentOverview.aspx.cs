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

public partial class web_purchase_PurchasePaymentOverview : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        //loadRoutes();
        loadWarehouse();
        loadUsers();
    }


    [WebMethod(EnableSession = true)]
    public static string GetAutoCompleteVendorData(string variable)
    {
        StringBuilder sb = new StringBuilder();
        //List<string> custNames = new List<string>();
        mySqlConnection db = new mySqlConnection();
        var resultStatus = "";
        string sqlQuery = "";
        //string sqlQuery = "SELECT cust_name,cust_id from tbl_customer where 1 and branch_id=" + warehouse + " and cust_name like '%" + variable + "%' limit 0,20";
        if (variable == " ")
        {
            sqlQuery = "SELECT vn_id,vn_name from tbl_vendor limit 0,20";
        }
        //string sqlQuery = "SELECT cust_name,cust_id from tbl_customer where 1 and branch_id=" + warehouse + " and cust_name like '%" + variable + "%' limit 0,20";
        else
        {
            sqlQuery = "SELECT vn_id,vn_name from tbl_vendor where vn_name like '%" + variable + "%' limit 0,20";
        }
        DataTable QryTable = db.SelectQuery(sqlQuery);
        if (QryTable.Rows.Count > 0)
        {
            sb.Append("[");
            foreach (DataRow row in QryTable.Rows)
            {
                sb.Append("{\"id\":\"" + Convert.ToString(row["vn_id"]) + "\",");
                sb.Append("\"label\":\"" + Convert.ToString(row["vn_name"]) + "\",");
                sb.Append("\"value\":\"" + Convert.ToString(row["vn_name"]) + "\"}");

                //sb.Append("'name':'" + Convert.ToString(row["cust_name"]) + "'}");
                sb.Append(",");
            }
            sb.Remove(sb.Length - 1, 1);
            sb.Append("]");
        }
        else
        {
            sb.Append("[{\"id\":\"-1\",\"label\":\"No Data Found\",\"value\":\"No Data Found\"}]");
        }


        //var a = "[{\"label\":\"Avacado Supermarket\",\"value\":\"2\"}]";
        return sb.ToString();

    }

    public void loadWarehouse()
    {
        mySqlConnection db = new mySqlConnection();
        //load suppliers
        DataTable vendorDt = db.SelectQuery("select branch_id,branch_name from tbl_branch");
        selWarehouse.Items.Add(new ListItem("All Warehouses", "-1"));
        foreach (DataRow vendorRow in vendorDt.Rows)
        {
            selWarehouse.Items.Add(new ListItem(vendorRow["branch_name"].ToString(), vendorRow["branch_id"].ToString()));
        }

    }

    public void loadUsers()
    {
        mySqlConnection db = new mySqlConnection();
        //load suppliers
        DataTable vendorDt = db.SelectQuery("select user_id,CONCAT(first_name,' ',last_name)as name from tbl_user_details order by user_id");
        comboSalesInReport.Items.Add(new ListItem("All Users", "-1"));
        foreach (DataRow vendorRow in vendorDt.Rows)
        {
            comboSalesInReport.Items.Add(new ListItem(vendorRow["name"].ToString(), vendorRow["user_id"].ToString()));
        }

    }


    [WebMethod]
    public static string showsalespersons()
    {

        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        StringBuilder sb = new StringBuilder();
        string query = "select user_id,first_name,last_name from tbl_user_details order by user_id";
        dt = db.SelectQuery(query);
        return JsonConvert.SerializeObject(dt, Formatting.Indented);

    }

    [WebMethod]
    public static string showCollections(int page, int perpage, Dictionary<string, string> filters)
    {
        var result = "";
        string qry_condition = "";
        string pay_srmquery = "";

        mySqlConnection db = new mySqlConnection();

        if (filters.Count > 0)
        {
            if (filters.ContainsKey("salesmanId"))
            {
                qry_condition += " and ud.user_id= '" + filters["salesmanId"] + "'";
            }


            if (filters.ContainsKey("warehouse"))
            {               
                pay_srmquery += " and sm.branch_id= '" + filters["warehouse"] + "'";
            }


            if (filters.ContainsKey("customer_id"))
            {
                qry_condition += " and cu.vn_id= '" + filters["customer_id"] + "'";
            }
            

        }

      

        var qry4 = @"SELECT DATE_FORMAT(`date`, '%d.%m.%Y') AS trans_date,IFNULL(sm.pm_invoice_no,'Invoice Number Unavailable') AS invoice,sm.pm_netamount AS netAmt,DATE_FORMAT(sm.pm_date, '%d-%b-%Y') AS bill_date,
action_ref_id AS sm_id,cu.vn_id as cust_id,cu.vn_name as cust_name,cu.vn_address as cust_address,cu.vn_city as cust_city,
CONCAT(tu.first_name,' ',tu.last_name) AS user,tr.cash_amt,tr.wallet_amt,tr.cheque_amt,tr.cheque_no,tr.cheque_bank,
DATE_FORMAT(tr.cheque_date, '%d.%m.%Y') AS cheque_date, tr.dr,
(SELECT IFNULL((SUM(dr) - SUM(cr)), 0) FROM tbl_transactions
WHERE action_ref_id = tr.action_ref_id AND tr.action_type = 1) AS balance
FROM tbl_transactions tr
INNER JOIN tbl_user_details tu ON tu.user_id = tr.user_id
LEFT JOIN tbl_vendor cu ON cu.vn_id = tr.partner_id
INNER JOIN tbl_purchase_master sm ON sm.pm_id = tr.action_ref_id
WHERE 1 = 1 and tr.dr!= 0 AND action_type = 2 AND sm.pm_status!=0 AND is_reconciliation=0 AND tr.partner_type=2 
AND date(date)>='" + filters["from_date"] + "' and date(date)<='" + filters["to_date"] + "' " + qry_condition + pay_srmquery + " ORDER BY tr.date";


        var dt_payment = db.SelectQuery(qry4);
        var payment_data = "0";

        if (dt_payment.Rows.Count > 0)
        {
            payment_data = JsonConvert.SerializeObject(dt_payment, Formatting.Indented);
        }

        StringBuilder sb = new StringBuilder();
        sb.Append("{");
        sb.Append("\"payment_count\":" + JsonConvert.SerializeObject(dt_payment.Rows.Count, Formatting.Indented));
        sb.Append(",\"payment_data\":" + payment_data);
        sb.Append("}");
        result = sb.ToString();

        return result;
    }

    [WebMethod]
    public static string DownloadExcel(int type, Dictionary<string, string> filters)
    {
        var result = "";
        string qry_condition = "";
        string nrmqry_condition = "";
        string srmqry_condition = "";
        string pay_srmquery = "";
        HttpContext.Current.Session["downloadtype"] = type;

        mySqlConnection db = new mySqlConnection();

        if (filters.Count > 0)
        {
            if (filters.ContainsKey("salesmanId"))
            {
                qry_condition += " and ud.user_id= '" + filters["salesmanId"] + "'";
            }


            if (filters.ContainsKey("warehouse"))
            {
                nrmqry_condition += " and tr.branch_id= '" + filters["warehouse"] + "'";
                srmqry_condition += " and srm.branch_id= '" + filters["warehouse"] + "'";
                pay_srmquery += " and sm.branch_id= '" + filters["warehouse"] + "'";
            }


            if (filters.ContainsKey("customer_id"))
            {
                qry_condition += " and cu.vn_id= '" + filters["customer_id"] + "'";
            }


        }
        

        if (type == 1)
        {
            
            var qry4 = @"SELECT cu.vn_name AS 'CUSTOMER NAME',cu.vn_address AS 'ADDRESS',cu.vn_city AS 'CITY',DATE_FORMAT(`date`, '%d.%m.%Y') AS 'DATE',IFNULL(pm_invoice_no,'Invoice Number Unavailable') AS 'INVOICE NO',pm_netamount AS 'BILL AMOUNT',DATE_FORMAT(sm.pm_date, '%d-%b-%Y') AS 'INVOICE DATE',
CONCAT(tu.first_name,' ',tu.last_name) AS 'USER',tr.cash_amt AS 'CASH',tr.wallet_amt AS 'WALLET',tr.cheque_amt AS 'CHEQUE AMOUNT',tr.cheque_no AS 'CHEQUE NO',tr.cheque_bank AS 'BANK',
DATE_FORMAT(tr.cheque_date, '%d.%m.%Y') AS 'CHEQUE DATE', dr AS 'NET PAYMENT' 

FROM tbl_transactions tr
INNER JOIN tbl_user_details tu ON tu.user_id = tr.user_id
LEFT JOIN tbl_vendor cu ON cu.vn_id = tr.partner_id
INNER JOIN tbl_purchase_master sm ON sm.pm_id = tr.action_ref_id
WHERE 1 = 1 and tr.dr!= 0 AND action_type = 2 AND sm.pm_status!=0 AND is_reconciliation=0 AND tr.partner_type=2 
AND date(date)>='" + filters["from_date"] + "' and date(date)<='" + filters["to_date"] + "' " + qry_condition + pay_srmquery + "  ORDER BY tr.date";


            var dt_payment = db.SelectQuery(qry4);
            if (dt_payment.Rows.Count > 0)
            {
                HttpContext.Current.Session["downloadqry"] = qry4;
                result = "Y";
            }
            else
            {
                result = "N";
            }
        }


        return result;
    }
}