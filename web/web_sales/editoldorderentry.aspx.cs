using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.Services;
using System.Data;
using System.Data.SqlClient;
using System.Text;
using commonfunction;
using Newtonsoft.Json;
using MySql.Data.MySqlClient;
using iTextSharp.text.html.simpleparser;
using iTextSharp.text.pdf;
using System.IO;

public partial class web_sales_editoldorderentry : System.Web.UI.Page
{
	protected void Page_Load(object sender, EventArgs e)
	{
		LoginAuthentication bill = new LoginAuthentication();
		bill.userAuthentication();
		bill.checkPageAcess(36);
	}

	public static string Get_Current_Date_Time(string TimeZoneName)
	{
		var CURR_TIME_ZONE = TimeZoneInfo.FindSystemTimeZoneById(TimeZoneName);
		var TimeNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, CURR_TIME_ZONE);
		var date_time_now = TimeNow.ToString("yyyy-MM-dd HH:mm:ss");
		return date_time_now;
	}

	[WebMethod]
	public static string selectOrderdata(string sm_id)
	{
		var result = "N";
		try
		{
			result = "{\"data\":" + JsonConvert.SerializeObject(new mySqlConnection().SelectQuery("SELECT sm.sm_id,sm.branch_id,sm.cust_id,si.itm_name,DATE_FORMAT(sm.sm_date, '%Y-%m-%d') as sm_date,sm.sm_netamount ,sm.sm_specialnote FROM tbl_sales_master sm  INNER JOIN tbl_sales_items si ON si.sm_id=sm.sm_id WHERE sm.sm_id='" + sm_id + "' and sm.sm_type='2'"), Formatting.Indented) + "}";
			return result;
		}
		catch (Exception ex)
		{
			var log = new LogClass("selectOrderdata");
			log.write(ex);
			result = "ERROR";
			return result;

		}

	}

	[WebMethod]
	public static string saveOldEntryToSalesMaster(Dictionary<string, string> editedorder)
	{
		string result = "";
		mySqlConnection db = new mySqlConnection();

		// check invoice id existance
		string oldinvoiceid = editedorder["invoice_id"] + "#OLD ORDER ITEMS";
		string qryOldInvoiceCheck = "SELECT SIM.sm_id FROM tbl_sales_items SIM inner join tbl_sales_master SM on SM.sm_id=SIM.sm_id WHERE SM.branch_id=" + editedorder["order_branch_id"] + " AND SIM.itm_name='" + oldinvoiceid + "' AND SM.sm_id!='" + editedorder["sm_id"] + "'";
		string existId = db.SelectScalar(qryOldInvoiceCheck);
		if (!string.IsNullOrWhiteSpace(existId))
		{ // existing so , skipped
			result = "REPEAT";
			result = "{\"result\":\"" + result + "\"}";
		}
		else
		{

			try
			{

				string edit_time = Get_Current_Date_Time(editedorder["time_zone"]);

				db.BeginTransaction();

				// fetch old values

				Int32 branch_id = 0;
				string cust_id = "";
				double old_netamount = 0.00;
				double sm_netamount = Convert.ToDouble(editedorder["sm_netamount"]);

				string branchQry = "select branch_id,cust_id,sm_netamount from tbl_sales_master where sm_id='" + editedorder["sm_id"] + "'";
				DataTable dt_branchDetail = db.SelectQueryForTransaction(branchQry);
				if (dt_branchDetail != null)
				{
					branch_id = Convert.ToInt32(dt_branchDetail.Rows[0]["branch_id"]);
					cust_id = Convert.ToString(dt_branchDetail.Rows[0]["cust_id"]);
					old_netamount = Convert.ToDouble(dt_branchDetail.Rows[0]["sm_netamount"]);
				}
				else
				{
					result = "FAILED";
					return result;
				}

				string update_salesmaster_qry = "UPDATE tbl_sales_master SET sm_total='" + editedorder["sm_netamount"] + "',sm_netamount='" + editedorder["sm_netamount"] + "',sm_date='" + editedorder["sm_date"] + "',sm_specialnote='" + editedorder["sm_specialnote"] + "' WHERE sm_id='" + editedorder["sm_id"] + "'";
				db.ExecuteQueryForTransaction(update_salesmaster_qry);

				string update_sl_items_qry = "UPDATE tbl_sales_items SET itm_name='" + oldinvoiceid + "',si_org_price='" + editedorder["sm_netamount"] + "',si_price='" + editedorder["sm_netamount"] + "',si_total='" + editedorder["sm_netamount"] + "',si_net_amount='" + editedorder["sm_netamount"] + "' WHERE sm_id='" + editedorder["sm_id"] + "'";
				db.ExecuteQueryForTransaction(update_sl_items_qry);

				string edited_date = Get_Current_Date_Time(editedorder["time_zone"]);
				//start updation in transactions
				if (sm_netamount > old_netamount)
				{
					//inserting order debit entry
					MySqlCommand cmdInsDr = new MySqlCommand();
					cmdInsDr.CommandText = "INSERT INTO `tbl_transactions` " +
						" ( `action_type`, `action_ref_id`, `partner_id`,`partner_type`,`branch_id`, `user_id`, `narration`, `dr`,  `date`,`is_reconciliation`,`closing_balance`)" +
						" select @action_type, @action_ref_id, @partner_id,@partner_type,@branch_id, @user_id, @narration, @dr, @date, @is_reconciliation,(ifnull(sum(dr)-sum(cr),0)+@dr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type and branch_id=@branch_id  ";

					cmdInsDr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.SALES);
					cmdInsDr.Parameters.AddWithValue("@action_ref_id", editedorder["sm_id"]);
					cmdInsDr.Parameters.AddWithValue("@partner_id", cust_id);
					cmdInsDr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.CUSTOMER);
					cmdInsDr.Parameters.AddWithValue("@branch_id", branch_id);
					cmdInsDr.Parameters.AddWithValue("@user_id", editedorder["user_id"]);
					cmdInsDr.Parameters.AddWithValue("@narration", "Reconciliation of Old Order #" + editedorder["sm_id"] + " after an edit by debiting the amount " + (sm_netamount - old_netamount));
					cmdInsDr.Parameters.AddWithValue("@dr", (sm_netamount - old_netamount));
					cmdInsDr.Parameters.AddWithValue("@date", edited_date);
					cmdInsDr.Parameters.AddWithValue("@is_reconciliation", "1");
					db.ExecuteQueryForTransaction(cmdInsDr);

				}
				else if (sm_netamount < old_netamount)
				{
					//inserting order credit entry
					MySqlCommand cmdInsCr = new MySqlCommand();
					cmdInsCr.CommandText = "INSERT INTO `tbl_transactions` " +
						" ( `action_type`, `action_ref_id`, `partner_id`,`partner_type`,`branch_id`, `user_id`, `narration`, `cr`,  `date`,`is_reconciliation`,`closing_balance`)" +
						" select @action_type, @action_ref_id, @partner_id,@partner_type,@branch_id, @user_id, @narration, @cr, @date, @is_reconciliation,(ifnull(sum(dr)-sum(cr),0)-@cr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type and branch_id=@branch_id  ";

					cmdInsCr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.SALES);
					cmdInsCr.Parameters.AddWithValue("@action_ref_id", editedorder["sm_id"]);
					cmdInsCr.Parameters.AddWithValue("@partner_id", cust_id);
					cmdInsCr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.CUSTOMER);
					cmdInsCr.Parameters.AddWithValue("@branch_id", branch_id);
					cmdInsCr.Parameters.AddWithValue("@user_id", editedorder["user_id"]);
					cmdInsCr.Parameters.AddWithValue("@narration", "Reconciliation of Old Order #" + editedorder["sm_id"] + " after an edit by crediting the amount " + (old_netamount - sm_netamount));
					cmdInsCr.Parameters.AddWithValue("@cr", (old_netamount - sm_netamount));
					cmdInsCr.Parameters.AddWithValue("@date", edited_date);
					cmdInsCr.Parameters.AddWithValue("@is_reconciliation", "1");
					db.ExecuteQueryForTransaction(cmdInsCr);
				}
				//end updation in transactions

				string update_tbl_cust_amounts = "UPDATE tbl_customer SET cust_last_updated_date='" + edit_time + "',cust_amount=(select (sum(dr)-sum(cr)) from tbl_transactions where partner_id='" + cust_id + "' and partner_type=" + (int)Constants.PartnerType.CUSTOMER + ") where cust_id=" + cust_id + "; SELECT cust_amount from tbl_customer WHERE cust_id='" + cust_id + "'";
				string newcust_amount = db.SelectScalarForTransaction(update_tbl_cust_amounts);
				//Entering to EDIT HISTORY

				//***************************************** edit history

				db.CommitTransaction();
				result = "SUCCESS";
				result = "{\"result\":\"" + result + "\"}";

			}
			catch (Exception ex)
			{
				try // IF TRANSACTION FAILES
				{
					result = "FAILED";
					result = "{\"result\":\"" + result + "\"}";
					db.RollBackTransaction();
					LogClass log = new LogClass("update_old_oustanding_order");
					log.write(ex);
					return result;
				}
				catch
				{
				}
			}
		}

		return result;
	}

	[WebMethod]
	public static string selectOrders(string billno)
	{
		mySqlConnection db = new mySqlConnection();
		DataTable dtItems = new DataTable();
		DataTable dtOrder = new DataTable();
		StringBuilder sb = new StringBuilder();
		sb.Append("{");		
		String paymentQry = "select tr.id,DATE_FORMAT(`date`, '%d-%b-%Y %h:%i %p') as date,narration,concat(tu.first_name,' ',tu.last_name) as user_name,cash_amt,card_amt,card_no,cheque_amt,cheque_no,"
		   + " cheque_bank,DATE_FORMAT(`cheque_date`, '%d-%m-%Y') as cheque_date,wallet_amt,dr,cr,is_reconciliation ,IFNULL(voucher_no,'-') voucher_no ,IFNULL(po_number,'-') po_number from tbl_transactions tr "
		   + " inner join tbl_user_details tu on tu.user_id=tr.user_id "
		   + " where action_ref_id='" + billno + "' and action_type=" + (int)Constants.ActionType.SALES;
		DataTable dtPay = db.SelectQuery(paymentQry);
		sb.Append("\"payments\":");
		sb.Append(JsonConvert.SerializeObject(dtPay, Formatting.Indented));
		sb.Append("}");

		return sb.ToString();
	}
}