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

public partial class web_sales_collection_report : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication reports = new LoginAuthentication();
        reports.userAuthentication();
        //reports.checkPageAcess(33);
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
        var totalbalance = 0.00;
        var cash = 0.00;
        var card = 0.00;
        var wallet = 0.00;
        var cheque = 0.00;
        var totalnetamt = 0.00;
        var totalpaid = 0.00;

        var dt_balance = db.SelectQuery(@"SELECT cu.cust_id, cu.cust_reg_id, cu.cust_name, cu.cust_address, cu.cust_city, (SUM(tr.dr) - SUM(tr.cr)) AS balance_to_clear, cu.cust_amount,
(CASE WHEN(SUM(tr.dr) - SUM(tr.cr)) > cu.cust_amount THEN ABS(cu.cust_amount - (SUM(tr.dr) - SUM(tr.cr)))  WHEN cu.cust_amount < 0 THEN ABS(cu.cust_amount)
 ELSE 0
 END) AS available_to_clear
 FROM tbl_transactions tr
JOIN tbl_sales_master sm ON(sm.sm_id = tr.action_ref_id AND tr.action_type = 1)
JOIN tbl_customer cu ON sm.cust_id = cu.cust_id
WHERE sm.sm_delivery_status NOT IN(4, 5) AND tr.partner_type = 1 GROUP BY tr.partner_id HAVING balance_to_clear > 0 and available_to_clear> 0 ");

        decimal unused_wallet = 0;
        if (dt_balance.Rows.Count > 0)
        {
            unused_wallet = dt_balance.AsEnumerable().Sum(x => x.Field<decimal>("available_to_clear"));
            unused_wallet = Math.Truncate(100 * unused_wallet) / 100;
        }
        else
        {
            unused_wallet = 0;
        }
        //  string qry_condition = " where 1=1 and cr!=0 and action_type=1 and sm_invoice_no!='' and sm_delivery_status not in (4,5)";
        string qry_condition = " where 1=1 and cr!=0 and action_type=" + (int)Constants.ActionType.SALES + " and sm_delivery_status not in (4,5) and is_reconciliation!=1 ";
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

            if (filters.ContainsKey("customer_id"))
            {
                qry_condition += " and tc.cust_id= '" + filters["customer_id"] + "'";
            }

        }
        int per_page = perpage;
        int offset = (page - 1) * per_page;
        string countQry = "select count(*) from tbl_transactions tr inner join tbl_sales_master sm on sm.sm_id=tr.action_ref_id left join tbl_customer tc on tc.cust_id=tr.partner_id " + qry_condition;
        //string countQry = "SELECT sm_id FROM tbl_sales_master " + qry_condition + ""+group_condition;

        DataTable dtcount, dt = new DataTable();
        dtcount = db.SelectQuery(countQry);
        double numrows = Convert.ToInt32(db.SelectScalar(countQry));
        if (numrows == 0)
        {
            return "{\"wallet_to_clear\":\"" + unused_wallet + "\",\"count\":\"" + numrows + "\",\"data\":[]}";
        }

        string innerqry = "select sm.sm_id,tr.id as transId,IFNULL(sm_invoice_no,'Not Invoiced') as invoice,sm_netamount as netAmt,DATE_FORMAT(`sm_date`, '%d-%b-%Y %h:%i %p') as bill_date,DATE_FORMAT(`date`, '%d-%b-%Y %h:%i %p') as trans_date,action_type"
            + " ,action_ref_id,tc.cust_id,cust_name,concat(tu.first_name,\" \",tu.last_name) as user,narration,cr,dr,(select IFNULL((sum(dr)-sum(cr)),0) from tbl_transactions where action_ref_id=tr.action_ref_id AND tr.action_type=1) as balance,IFNULL(voucher_no,'-') voucher_no ,IFNULL(po_number,'-') po_number "
			+ " from tbl_transactions tr inner join tbl_user_details tu on tu.user_id=tr.user_id left join tbl_customer tc on tc.cust_id=tr.partner_id inner join tbl_sales_master sm on sm.sm_id=tr.action_ref_id"
            + "  " + qry_condition + " order by tr.date desc LIMIT " + offset.ToString() + " ," + per_page;
        // +" order by str.id desc";
        string jsonResponse = "";
        dt = db.SelectQuery(innerqry);

        if (dt.Rows.Count > 0)
        {

            string jsonData = JsonConvert.SerializeObject(dt, Formatting.Indented);
            string transactionQry = "select IFNULL(sum(inner_res.totalBalance),0) as totalBalance,IFNULL(sum(inner_res.cash),0) as cash, IFNULL(sum(inner_res.card),0) as card"
        + ", IFNULL(sum(inner_res.wallet),0) as wallet,IFNULL(sum(inner_res.cheque),0) as cheque from(select IFNULL((sum(dr)-sum(cr)),0) as totalBalance, IFNULL(sum(cash_amt),0) as cash, "
        + " IFNULL(sum(card_amt),0) as card, IFNULL(sum(wallet_amt),0) as wallet,IFNULL(sum(cheque_amt),0) as cheque from tbl_transactions tr inner join tbl_sales_master sm on "
        + "sm.sm_id=tr.action_ref_id " + qry_condition + " group by action_ref_id,action_type) as inner_res";
            DataTable transactionDt = db.SelectQuery(transactionQry);

            if (transactionDt.Rows.Count > 0)
            {
               // totalnetamt = Convert.ToDouble(dt.Rows[0]["totalSale"]);
                totalbalance = Convert.ToDouble(transactionDt.Rows[0]["totalBalance"]);
              //  totalpaid = Math.Round((totalnetamt - totalbalance), 2);
                cash = Convert.ToDouble(transactionDt.Rows[0]["cash"]);
                card = Convert.ToDouble(transactionDt.Rows[0]["card"]);
                wallet = Convert.ToDouble(transactionDt.Rows[0]["wallet"]);
                cheque = Convert.ToDouble(transactionDt.Rows[0]["cheque"]);
            }

            jsonResponse = "{\"wallet_to_clear\":\"" + unused_wallet + "\",\"count\":\"" + numrows + "\",\"data\":" + jsonData + "";
            HttpContext.Current.Session["rp_fieldvalues"] = filters["from_date"] + "*" + filters["to_date"] +  "*" + numrows +  "*" + cash + "*" + card + "*" + cheque + "*" + totalnetamt + "*" + totalpaid + "*" + totalbalance;
            string summaryRepport = ",\"totalcashamt\":\"" + cash + "\",\"totalcardamt\":\"" + card + "\",\"totalcheqamt\":\"" + cheque + "\",\"totalwalletamt\":\"" + wallet + "\",\"totalnetamt\":\"" + totalnetamt + "\",\"totalbalance\":\"" + totalbalance + "\",\"totalpaid\":\"" + totalpaid + "\"}";
            jsonResponse = jsonResponse + summaryRepport;
         
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
        string qry_condition = " where 1=1 and cr!=0 and action_type=" + (int)Constants.ActionType.SALES + " and sm_delivery_status not in (4,5) and is_reconciliation!=1 ";
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

        string innerqry = "select sm_invoice_no as InvoiceNumber,DATE_FORMAT(`sm_date`, '%d-%b-%Y %h:%i %p') as BilledDate,tc.cust_id as customerid,cust_name as Customer,DATE_FORMAT(`date`, '%d-%b-%Y %h:%i %p') as ReceiptedDate,sm_netamount as NetAmt,"
			+ " cr as PaidAmount,(select IFNULL((sum(dr)-sum(cr)),0) from tbl_transactions where action_ref_id=tr.action_ref_id AND tr.action_type=1) as Balance,concat(tu.first_name,\" \",tu.last_name) as User,IFNULL(voucher_no,'-') 'Voucher No', IFNULL(po_number,'-') 'P.O Number' "
			+ " from tbl_transactions tr inner join tbl_user_details tu on tu.user_id=tr.user_id left join tbl_customer tc on tc.cust_id=tr.partner_id inner join tbl_sales_master sm on sm.sm_id=tr.action_ref_id"
            + "  " + qry_condition + " order by tr.date desc";
        // +" order by str.id desc";
        HttpContext.Current.Session["downloadReceiptqry"] = innerqry;
        return "Y";
    }//end
}