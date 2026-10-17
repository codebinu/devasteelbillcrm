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

public partial class web_reports_PurchaseReturnReport : System.Web.UI.Page
{
	protected void Page_Load(object sender, EventArgs e)
	{
		LoginAuthentication reports = new LoginAuthentication();
		reports.userAuthentication();
		reports.checkPageAcess(31);
	}


	[WebMethod]// start warehouse showing
	public static string showBranches(string userid)
	{
		mySqlConnection db = new mySqlConnection();
		DataTable dt = new DataTable();
		StringBuilder sb = new StringBuilder();
		string query = "select branch_id,branch_name from tbl_branch";
		query = query + " order by branch_id";
		dt = db.SelectQuery(query);
		return JsonConvert.SerializeObject(dt, Formatting.Indented);
	}// end warehouse show



	[WebMethod]// start customers showing
	public static string showCustomersInReports()
	{
		mySqlConnection db = new mySqlConnection();
		DataTable dt = new DataTable();
		StringBuilder sb = new StringBuilder();
		string query = "select vn_id,vn_name from tbl_vendor order by vn_name";
		dt = db.SelectQuery(query);
		return JsonConvert.SerializeObject(dt, Formatting.Indented);
	}// end customers show

	[WebMethod]
	public static string showsalespersons()
	{

		mySqlConnection db = new mySqlConnection();
		DataTable dt = new DataTable();
		StringBuilder sb = new StringBuilder();
		string query = "select user_id,first_name,last_name from tbl_user_details where user_id IN (SELECT DISTINCT tprm.prm_userid FROM tbl_purchase_return_master tprm) order by first_name";
		dt = db.SelectQuery(query);
		return JsonConvert.SerializeObject(dt, Formatting.Indented);

	}
	//stop: Listing salesperson in Reports page

	//Start:Show Reports in reports.aspx
	[WebMethod]
	public static string showDailyReports(double page, string searchResult, double perpage, string BranchId, string reportfromdate, string reporttodate, string BranchName)
	{
		mySqlConnection db = new mySqlConnection();
		DataTable dt = new DataTable();
		DataTable dt1 = new DataTable();
		StringBuilder sb = new StringBuilder();
		DateTime myDateTime = DateTime.Now;

		string searchResults = searchResult.Replace("*", "'");
		double per_page = perpage;
		double offset = (page - 1) * per_page;
		string innerqry = "";
		string countQry = "";
		int numrows = 0;
		double total_pages = 0;
		string qry = "";
		string summaryRepport = "";
		/* countQry = "SELECT  * FROM tbl_salesreturn_master LEFT JOIN tbl_salesreturn_items ON tbl_salesreturn_master.srm_id = tbl_salesreturn_items.srm_id ";
         countQry = countQry + " inner join  tbl_sales_master  on  tbl_salesreturn_master.cust_id=tbl_sales_master.cust_id " ;
         countQry = countQry + " inner join  tbl_user_details on tbl_user_details.user_id=tbl_sales_master.sm_userid " + searchResults;*/



		countQry = @"select prm.prm_id from tbl_purchase_return_items pri
INNER JOIN tbl_purchase_return_master prm ON pri.prm_id = prm.prm_id
INNER JOIN tbl_user_details ud ON ud.user_id = prm.prm_userid
LEFT OUTER JOIN tbl_purchase_master pm ON pri.pm_id = pm.pm_id  " + searchResults;
		countQry = countQry + " group by prm.prm_id ";

		DataTable dtcount = new DataTable();
		dtcount = db.SelectQuery(countQry);
		numrows = dtcount.Rows.Count;
		if (perpage == 0)
		{
			per_page = numrows;
		}
		if (numrows == 0)
		{
			return "N";
		}

		total_pages = Math.Ceiling(numrows / per_page);

		// Arun code 4-01-17

		innerqry = @"SELECT pri.prm_id,IFNULL(pri.pm_id,'Nil') as pm_id,IFNULL(pri.pm_id,'Nil') as pm_refno, pri.pri_id,pm.pm_invoice_no,prm.prm_invoice_no,
pri.itm_code,REPLACE(DATE_FORMAT(prm.prm_date,'%d/%m/%Y'),'/','-') AS BillDate, 
pri.itm_name ,pri.pi_price ,pri.pi_discount_rate ,pri.pri_tax_amount,prm.prm_status,
pri.pri_discount_amount , pri.pri_qty ,pri.pri_total,pri.pri_type,
ud.first_name, ud.last_name,prm.vendor_id ,tv.vn_name,prm.pm_id  
FROM tbl_purchase_return_items pri

INNER JOIN tbl_purchase_return_master prm ON pri.prm_id = prm.prm_id
LEFT OUTER JOIN tbl_purchase_master pm ON pm.pm_id=pri.pm_id 
INNER JOIN tbl_vendor tv ON tv.vn_id=prm.vendor_id 
INNER JOIN tbl_user_details ud ON ud.user_id = prm.prm_userid  " + searchResults + " order by prm.prm_id LIMIT " + offset.ToString() + " ," + per_page;
		string jsonResponse = "";
		dt = db.SelectQuery(innerqry);
		summaryRepport = showSummaryReport(numrows, BranchId, searchResults, reportfromdate, reporttodate, BranchName);
		if (dt.Rows.Count > 0)
		{
			string jsonData = JsonConvert.SerializeObject(dt, Formatting.Indented);
			jsonResponse = "{\"count\":\"" + numrows + "\",\"data\":" + jsonData + "";
		}
		else
		{
			jsonResponse = "N";
		}
		jsonResponse = jsonResponse + summaryRepport;
		return jsonResponse;
		// return "Y";
	}

	public static string showSummaryReport(double numrows, string branchid, string searchResult, string reportfromdate, string reporttodate, string BranchName)
	{
		mySqlConnection db = new mySqlConnection();
		DataTable dt1, dt2, dt3, dt4 = new DataTable();
		StringBuilder sb = new StringBuilder();

		string searchResults = searchResult;
		string totalnetamt = "0.00";
		string totalpaidamt = "0.00";
		string totaloutstand_paid = "0.00";
		string totaloutstand = "0.00";
		Decimal totalsales = 0;
		string totalcashamt = "0.00";
		string totalcardamt = "0.00";
		string totalcheqamt = "0.00";

		// we edited
		string qry_totalnet_paid_searchResults = searchResults.Replace("WHERE", "");


		string qry_totalnet_paid = "select sum(pri_total) as totalnetamt from tbl_purchase_return_items ";
		//qry_totalnet_paid = qry_totalnet_paid + " INNER JOIN tbl_sales_master on tbl_sales_master.sm_id=tbl_salesreturn_items.sm_id ";
		qry_totalnet_paid = qry_totalnet_paid + " INNER JOIN  tbl_user_details on tbl_user_details.user_id=tbl_salesreturn_master.srm_userid ";
		qry_totalnet_paid = qry_totalnet_paid + " INNER JOIN tbl_purchase_return_master on tbl_purchase_return_master.prm_id=tbl_purchase_return_items.prm_id  where 1 and " + qry_totalnet_paid_searchResults;

		dt1 = db.SelectQuery(qry_totalnet_paid);
		if (dt1 != null)
		{
			if (dt1.Rows.Count > 0)
			{
				if (dt1.Rows[0]["totalnetamt"] is DBNull)
				{
				}
				else
				{
					totalnetamt = dt1.Rows[0]["totalnetamt"].ToString();

				}
			}
		}


		string currencyqry = "SELECT currency_name FROM tbl_currency_details INNER JOIN tbl_branch ON tbl_branch.branch_currency_id = tbl_currency_details.currency_id where tbl_branch.branch_id ='" + branchid + "'";
		DataTable ddtt = new DataTable();
		ddtt = db.SelectQuery(currencyqry);
		string currency = "";
		if (ddtt != null)
		{
			if (ddtt.Rows.Count > 0)
			{
				if (ddtt.Rows[0]["currency_name"] is DBNull)
				{
				}
				else
				{
					currency = ddtt.Rows[0]["currency_name"].ToString();
				}
			}
		}
		totalsales = Convert.ToDecimal(totalpaidamt) - Convert.ToDecimal(totaloutstand_paid);
		decimal totalcollection = Convert.ToDecimal(totalpaidamt);
		HttpContext.Current.Session["rp_fieldPermanent"] = reportfromdate + "*" + reporttodate + "*" + BranchName + "*" + totalnetamt;
		// HttpContext.Current.Session["rp_fieldPermanent"] = reportfromdate + "*" + reporttodate + "*" + BranchName + "*" + numrows + "*" + currency + "*" + totalcashamt + "*" + totalcardamt + "*" + totalcheqamt + "*" + totalnetamt + "*" + totalpaidamt + "*" + totaloutstand_paid + "*" + totaloutstand + "*" + totalsales + "*" + totalcollection;
		string jsonresponse = "";
		// string jsonData = JsonConvert.SerializeObject(Formatting.Indented);
		jsonresponse = ",\"currency\":\"" + currency + "\",\"totalcashamt\":\"" + totalcashamt + "\",\"totalcardamt\":\"" + totalcardamt + "\",\"totalcheqamt\":\"" + totalcheqamt + "\",\"totalcollection\":\"" + totalcollection + "\",\"totalsales\":\"" + totalsales + "\",\"totaloutstand_paid\":\"" + totaloutstand_paid + "\",\"totalnetamt\":\"" + totalnetamt + "\",\"totaloutstand\":\"" + totaloutstand + "\"}";
		return jsonresponse;
	}
	//Stop: Show Reports in reports.aspx
	//Start:Show Reports in reports.aspx

	[WebMethod]
	public static string DownloadDailyReports(string searchResult, string reportfromdate, string reporttodate, string BranchName)
	{
		mySqlConnection db = new mySqlConnection();
		DataTable dt = new DataTable();
		DateTime myDateTime = DateTime.Now;

		string searchResults = searchResult.Replace("*", "'");
		string countQry = "";
		double numrows = 0;
		string innerqry = "";
		string query = "";
		countQry = "SELECT count(tbl_purchase_return_master.prm_id) from tbl_purchase_return_master INNER JOIN tbl_purchase_return_items pri ON pri.prm_id=tbl_purchase_return_master.prm_id  " + searchResults;
		numrows = Convert.ToInt32(db.SelectScalar(countQry));
		if (numrows == 0)
		{
			return "N";
		}

		query = @"SELECT 
		tv.vn_id AS 'VENDORID',
    tv.vn_name AS 'VENDOR',
    IFNULL(prm_invoice_no, 'NOT INVOICED') AS 'INVOICE NO',

    
    tbl_purchase_return_master.prm_id AS 'REF ID',

    REPLACE(DATE_FORMAT(tbl_purchase_return_master.prm_date,'%d/%m/%Y'),'/','-') AS 'RETURNED DATE',       

    (prm_amount-(SUM(tbl_purchase_return_items.pri_total)-SUM(tbl_purchase_return_items.pi_price * tbl_purchase_return_items.pri_qty))) AS 'RETURN TOTAL (WITHOUT TAX)',
    (SUM(tbl_purchase_return_items.pri_total)-SUM(tbl_purchase_return_items.pi_price * tbl_purchase_return_items.pri_qty)) AS 'TAX',
    prm_amount AS 'NET AMOUNT',
    CASE 
        WHEN tbl_purchase_return_master.prm_status = 1 THEN 'Initiated'
        WHEN tbl_purchase_return_master.prm_status = 2 THEN 'Received'
        WHEN tbl_purchase_return_master.prm_status = 3 THEN 'Approved'
        ELSE 'Cancelled'
    END AS 'STATUS',
    GROUP_CONCAT(
        CONCAT(
            tbl_purchase_return_items.itm_name, 
            ' (', tbl_purchase_return_items.pri_qty, ') - AED', 
            tbl_purchase_return_items.pri_total
        )
        SEPARATOR ' | '
    ) AS 'ITEMS'


FROM tbl_purchase_return_items

INNER JOIN tbl_purchase_return_master 
    ON tbl_purchase_return_master.prm_id = tbl_purchase_return_items.prm_id

INNER JOIN tbl_user_details 
    ON tbl_user_details.user_id = tbl_purchase_return_master.prm_userid  

INNER JOIN tbl_vendor tv  
    ON tv.vn_id = tbl_purchase_return_master.vendor_id  

  " + searchResults + " GROUP BY tbl_purchase_return_master.prm_id order by tbl_purchase_return_master.prm_id ";

		HttpContext.Current.Session["downloadqry"] = query;
		return "Y";
	}
}