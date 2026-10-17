using commonfunction;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;
using Newtonsoft.Json;
using System.Dynamic;
using MySql.Data.MySqlClient;


public partial class web_sales_editSalesReturn : System.Web.UI.Page
{
    mySqlConnection db = new mySqlConnection();
    public string settings;
    protected void Page_Load(object sender, EventArgs e)
    {

        LoginAuthentication bill = new LoginAuthentication();
        bill.userAuthentication();
        getSystemSettingsData();
    }

    /// <summary>
    /// method to get system settings and set it in javascript object
    /// </summary>
    public void getSystemSettingsData()
    {
        string qry = "select ss_decimal_accuracy from tbl_system_settings";
        DataTable dtSetings = db.SelectQuery(qry);
        settings = JsonConvert.SerializeObject(dtSetings, Formatting.Indented);
    }
    //Start: show  Bill Details...
    [WebMethod]
    public static string selectReturns(string ReturnNo)
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dtItems = new DataTable();
        DataTable dtOrder = new DataTable();
        StringBuilder sb = new StringBuilder();
        sb.Append("{");
        string selectvar2 = "";
        string qry = "";
        selectvar2 = selectvar2 + " sri.row_no, sri.itm_code,";
        selectvar2 = selectvar2 + " sri.itm_name , sri.sri_id,sri.sri_qty, sri.si_price,sri.sri_discount_amount,concat(tu.first_name,\" \",tu.last_name) as approver,concat(tur.first_name,\" \",tur.last_name) as receiver,DATE_FORMAT(sri_approved_date,'%d-%b-%Y %h:%i %p') AS approveddate,DATE_FORMAT(sri_recieved_date,'%d-%b-%Y %h:%i %p') AS receivededdate, sri.sri_total,sri.sri_tax_amount,sri.sri_type,sri_tax_percentage as tax,sri_cess as cess  ";
        qry = "select " + selectvar2 + " from tbl_salesreturn_items sri LEFT JOIN tbl_sales_master tsm ON tsm.sm_id=sri.sm_id left join tbl_user_details"
 + " tu on tu.user_id=sri.sri_approved_id left join tbl_user_details tur on tur.user_id=sri.sri_recieved_id where sri.srm_id='" + ReturnNo + "'  order by sri.row_no";
        dtItems = db.SelectQuery(qry);
        sb.Append("\"items\":");
        sb.Append(JsonConvert.SerializeObject(dtItems, Formatting.Indented));
        sb.Append(",");
        string basicDataqry = "select srm_id,srm.srm_refInvoiceNo,srm.cust_id,tc.cust_name,srm.srm_status as status,srm.branch_id,srm_amount as total_amount,"
 + " DATE_FORMAT(srm_date,'%d-%b-%Y %h:%i %p') AS date,srm_description,cust_amount as outstanding_amt,concat(tu.first_name,\" \",tu.last_name)"
 + "  as approver_name,tb.branch_tax_method,tb.branch_tax_inclusive from tbl_salesreturn_master srm inner join tbl_customer tc on tc.cust_id=srm.cust_id left join tbl_user_details"
 + "  tu on tu.user_id=srm.srm_userid inner join tbl_branch tb on tb.branch_id=srm.branch_id where srm_id='" + ReturnNo + "' ";
        dtOrder = db.SelectQuery(basicDataqry);
        sb.Append("\"return\":");
        sb.Append(JsonConvert.SerializeObject(dtOrder, Formatting.Indented));

        sb.Append("}");

        return sb.ToString();
    }
    //Stop: Show Details of Selected  Bill...

    [WebMethod]
    public static string update_invoice_ref(string srm_id, string ref_id)
    {
        var result = "N";
        
        try
        {
            var query = @"UPDATE tbl_salesreturn_master SET srm_refInvoiceNo='"+ ref_id +"' WHERE srm_id='"+ srm_id +"'";
            mySqlConnection db = new mySqlConnection();
            db.ExecuteQuery(query);
            result = "Y";
            return result;
        }
        catch (Exception ex)
        {           
            return result;

        }

    }

	[WebMethod]
	public static string update_salesreturn_Date(string srm_id, string srm_date)
	{
		var result = "N";

		try
		{
			var query = @"UPDATE tbl_salesreturn_master SET srm_date='" + srm_date + "' WHERE srm_id='" + srm_id + "'";
			mySqlConnection db = new mySqlConnection();
			db.ExecuteQuery(query);
			result = "Y";
			return result;
		}
		catch (Exception ex)
		{
			return result;

		}

	}

	[WebMethod]
    public static string updateReturnOrderStatus(Dictionary<string, string> item)
    {
        string result = "";
        mySqlConnection db = new mySqlConnection();
        try
        {
            TimeZoneInfo CurrentZone = TimeZoneInfo.FindSystemTimeZoneById(item["time_zone"]);
            DateTime TimeNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, CurrentZone);
            string action_date = DateTime.Parse(TimeNow.ToString()).ToString("yyyy-MM-dd HH:mm:ss");
            // packing only
            string update_sri = "";
            string reception_id = "";
            db.BeginTransaction();

            reception_id = item["user_id"].ToString();


            if (item["return_status"].ToString() == "2")
            {
                Int32 update_type = 0;

                DataTable dt_item_status = db.SelectQueryForTransaction("SELECT sri_id,sri_type,sri_recieved_id,itbs_id,sri_qty,sm_id,itm_name,srm_id FROM tbl_salesreturn_items sri WHERE sri.srm_id='" + item["srm_id"] + "'");
                for (int i = 0; i < dt_item_status.Rows.Count; i++)
                {
                    string existing_received_id = dt_item_status.Rows[i]["sri_recieved_id"].ToString();

                    if (existing_received_id == "0")
                    {
                        if (dt_item_status.Rows[i]["sri_type"].ToString() == "2" && reception_id != "0")
                        {
                            update_type = 1;
                        }
                        else
                        {
                            update_type = 0;
                        }
                    }
                    else
                    {
                        if (reception_id == "0" && dt_item_status.Rows[i]["sri_type"].ToString() == "2")
                        {
                            update_type = 2;
                        }
                        else
                        {
                            update_type = 0;
                        }
                    }


                    if (update_type != 0)
                    {
                        if (update_type == 1)
                        {
                            // increse stock here
                            string new_stockQry = "UPDATE tbl_itembranch_stock SET itbs_stock=(itbs_stock + " + dt_item_status.Rows[i]["sri_qty"].ToString() + "),itm_last_update_date='" + action_date + "' where itbs_id='" + dt_item_status.Rows[i]["itbs_id"].ToString() + "'";
                            db.ExecuteQueryForTransaction(new_stockQry);

                            StringBuilder can_sb_bulk_stkTrQry = new StringBuilder();
                            can_sb_bulk_stkTrQry.Append("INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`action_ref_id`,`user_id`,`narration`,`cr_qty`,`closing_stock`,`date`) VALUES ");
                            // stock transaction
                            can_sb_bulk_stkTrQry.Append("('" + Convert.ToString(dt_item_status.Rows[i]["itbs_id"].ToString() + "','" + (int)Constants.ActionType.SALES_RETURN) + "','" + dt_item_status.Rows[i]["srm_id"].ToString() + "','" + item["user_id"].ToString() + "'");
                            can_sb_bulk_stkTrQry.Append(",'SALES RETURN: stock increase by " + dt_item_status.Rows[i]["sri_qty"].ToString() + " qty of " + dt_item_status.Rows[i]["itm_name"].ToString() + " during return status change with Return Ref #" + dt_item_status.Rows[i]["srm_id"].ToString() + "','" + dt_item_status.Rows[i]["sri_qty"].ToString() + "'");
                            can_sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + dt_item_status.Rows[i]["itbs_id"].ToString() + "')");
                            can_sb_bulk_stkTrQry.Append(",'" + action_date + "');");
                            db.ExecuteQueryForTransaction(can_sb_bulk_stkTrQry.ToString());
                        }
                        else if (update_type == 2)
                        {
                            // decrease stock here
                            string new_stockQry = "UPDATE tbl_itembranch_stock SET itbs_stock=(itbs_stock - " + dt_item_status.Rows[i]["sri_qty"].ToString() + "),itm_last_update_date='" + action_date + "' where itbs_id='" + dt_item_status.Rows[i]["itbs_id"].ToString() + "'";
                            db.ExecuteQueryForTransaction(new_stockQry);

                            StringBuilder can_sb_bulk_stkTrQry = new StringBuilder();
                            can_sb_bulk_stkTrQry.Append("INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`action_ref_id`,`user_id`,`narration`,`dr_qty`,`closing_stock`,`date`) VALUES ");
                            // stock transaction
                            can_sb_bulk_stkTrQry.Append("('" + Convert.ToString(dt_item_status.Rows[i]["itbs_id"].ToString() + "','" + (int)Constants.ActionType.SALES_RETURN) + "','" + dt_item_status.Rows[i]["srm_id"].ToString() + "','" + item["user_id"].ToString() + "'");
                            can_sb_bulk_stkTrQry.Append(",'SALES RETURN: (stock decreased by " + dt_item_status.Rows[i]["sri_qty"].ToString() + " qty of " + dt_item_status.Rows[i]["itm_name"].ToString() + " during return status change with Return Ref #" + dt_item_status.Rows[i]["srm_id"].ToString() + "','" + dt_item_status.Rows[i]["sri_qty"].ToString() + "'");
                            can_sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + dt_item_status.Rows[i]["itbs_id"].ToString() + "')");
                            can_sb_bulk_stkTrQry.Append(",'" + action_date + "');");
                            db.ExecuteQueryForTransaction(can_sb_bulk_stkTrQry.ToString());
                        }
                        else
                        {
                            // do nothing
                        }
                    }


                    // end handle stock

                    update_sri = "UPDATE tbl_salesreturn_items SET sri_recieved_id='" + reception_id + "',sri_recieved_date='" + action_date + "' WHERE sri_id='" + dt_item_status.Rows[i]["sri_id"] + "';";
                    db.ExecuteQueryForTransaction(update_sri);

                    // update sales return master status as received if all items has ben recieved.
                    var dt = db.SelectQueryForTransaction("SELECT sri.sri_id FROM tbl_salesreturn_items sri WHERE sri.srm_id='" + item["srm_id"] + "' AND sri.sri_recieved_id=0 ");
                    if (dt.Rows.Count > 0)
                    {

                        db.ExecuteQueryForTransaction("UPDATE tbl_salesreturn_master srm  SET srm.srm_status=1 WHERE srm.srm_status!=3 AND srm.srm_id='" + item["srm_id"] + "'");
                    }
                    else
                    {
                        db.ExecuteQueryForTransaction("UPDATE tbl_salesreturn_master srm  SET srm.srm_status=2 WHERE srm.srm_status!=3 AND srm.srm_id='" + item["srm_id"] + "'");
                    }
                }
            }

            //approve status
            if (item["return_status"].ToString() == "3")
            {
                update_sri = "UPDATE tbl_salesreturn_items SET sri_approved_id='" + reception_id + "',sri_approved_date='" + action_date + "' WHERE srm_id='" + item["srm_id"] + "';";
                db.ExecuteQueryForTransaction(update_sri);

                var dt1 = db.SelectQueryForTransaction("SELECT sri.sri_id FROM tbl_salesreturn_items sri WHERE sri.srm_id='" + item["srm_id"] + "' AND sri.sri_approved_id=0 ");
                if (dt1.Rows.Count > 0)
                {

                    db.ExecuteQueryForTransaction("UPDATE tbl_salesreturn_master srm  SET srm.srm_status=2 WHERE srm.srm_status!=4 AND srm.srm_id='" + item["srm_id"] + "'");

                }
                else
                {
                    db.ExecuteQueryForTransaction("UPDATE tbl_salesreturn_master srm  SET srm.srm_status=3 WHERE srm.srm_status!=4 AND srm.srm_id='" + item["srm_id"] + "'");

                }
            }
            //cancel status
            if (item["return_status"].ToString() == "4")
            {
                var current_status = db.SelectScalarForTransaction("SELECT srm_status FROM tbl_salesreturn_master WHERE tbl_salesreturn_master.srm_id='" + item["srm_id"] + "'");
                if (current_status.ToString() == "4")
                {
                    result = "CANCEL";
                }
                else
                {
                    var current_itm_info = db.SelectQueryForTransaction("SELECT sri.sri_qty,sri.si_price,srm.srm_amount,sri.sri_type,srm.cust_id,sri.itbs_id,sri.sm_id,srm.branch_id,srm.srm_id,sri.itm_name FROM tbl_salesreturn_items sri INNER JOIN tbl_salesreturn_master srm ON srm.srm_id=sri.srm_id WHERE sri.srm_id='" + item["srm_id"] + "' AND sri.sri_type=2");
                    var dt_rt_info = db.SelectQueryForTransaction("SELECT srm.cust_id,srm.branch_id FROM tbl_salesreturn_master srm WHERE srm.srm_id='" + item["srm_id"] + "'");


                    if (current_itm_info.Rows.Count > 0)
                    {
                        // HANDLE STOCK FOR - READY TO USE ITEMS
                        for (int i = 0; i < current_itm_info.Rows.Count; i++)
                        {
                            // decrease stock here
                            db.ExecuteQueryForTransaction("UPDATE tbl_itembranch_stock SET itbs_stock=(itbs_stock - " + current_itm_info.Rows[i]["sri_qty"].ToString() + "),itm_last_update_date='" + action_date + "' where itbs_id='" + current_itm_info.Rows[i]["itbs_id"].ToString() + "'");

                            StringBuilder can_sb_bulk_stkTrQry = new StringBuilder();
                            can_sb_bulk_stkTrQry.Append("INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`action_ref_id`,`user_id`,`narration`,`dr_qty`,`closing_stock`,`date`) VALUES ");
                            // stock transaction
                            can_sb_bulk_stkTrQry.Append("('" + Convert.ToString(current_itm_info.Rows[i]["itbs_id"].ToString() + "','" + (int)Constants.ActionType.SALES_RETURN) + "','" + current_itm_info.Rows[i]["srm_id"].ToString() + "','" + item["user_id"].ToString() + "'");
                            can_sb_bulk_stkTrQry.Append(",'SALES RETURN: (stock decreased by " + current_itm_info.Rows[i]["sri_qty"].ToString() + " qty of " + current_itm_info.Rows[i]["itm_name"].ToString() + " during Sales Return Editing with Ref. ID #" + current_itm_info.Rows[i]["srm_id"].ToString() + "','" + current_itm_info.Rows[i]["sri_qty"].ToString() + "'");
                            can_sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + current_itm_info.Rows[i]["itbs_id"].ToString() + "')");
                            can_sb_bulk_stkTrQry.Append(",'" + action_date + "');");
                            db.ExecuteQueryForTransaction(can_sb_bulk_stkTrQry.ToString());
                        }

                    }

                    //1. UPDATE SALES RETURN ITEMS
                    var srm_amount = db.SelectScalarForTransaction("SELECT SUM(sri_total) FROM tbl_salesreturn_items WHERE srm_id='" + item["srm_id"] + "'");
                    db.ExecuteQueryForTransaction("UPDATE tbl_salesreturn_master SET srm_status='4' WHERE srm_id='" + item["srm_id"] + "'");
                    //2. UPDATE SALES RETURN MASTER

                    MySqlCommand cmdInsCr = new MySqlCommand();
                    cmdInsCr.CommandText = "INSERT INTO `tbl_transactions` " +
                        " (`action_type`, `action_ref_id`, `partner_id`,`partner_type`,`branch_id`, `user_id`, `narration`, `dr`,  `date`,`closing_balance`)" +
                        " select @action_type, @action_ref_id, @partner_id,@partner_type,@branch_id, @user_id, @narration, @dr, @date,(ifnull(sum(dr)-sum(cr),0)+@dr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type and branch_id=@branch_id  ";
                    //cmdInsCr.Parameters.AddWithValue("@session_id", return_order["session_id"]);
                    cmdInsCr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.SALES_RETURN);
                    cmdInsCr.Parameters.AddWithValue("@action_ref_id", item["srm_id"]);
                    cmdInsCr.Parameters.AddWithValue("@partner_id", dt_rt_info.Rows[0]["cust_id"].ToString());
                    cmdInsCr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.CUSTOMER);
                    cmdInsCr.Parameters.AddWithValue("@branch_id", dt_rt_info.Rows[0]["branch_id"].ToString());
                    cmdInsCr.Parameters.AddWithValue("@user_id", item["user_id"]);
                    cmdInsCr.Parameters.AddWithValue("@narration", "Amount debited due to Cancellation of Return worth: " + srm_amount);
                    cmdInsCr.Parameters.AddWithValue("@dr", srm_amount);
                    cmdInsCr.Parameters.AddWithValue("@date", action_date);
                    db.ExecuteQueryForTransaction(cmdInsCr);

                    // UPDATE CUSTOMER BALANCE IN CUSTOMER TABLE
                    db.ExecuteQueryForTransaction("UPDATE tbl_customer SET cust_last_updated_date='" + action_date + "',cust_amount=(select (sum(dr)-sum(cr)) from tbl_transactions  where partner_id='" + dt_rt_info.Rows[0]["cust_id"].ToString() + "' and partner_type=" + (int)Constants.PartnerType.CUSTOMER + ") where cust_id=" + dt_rt_info.Rows[0]["cust_id"].ToString() + "");

                }
            }

            db.CommitTransaction();
            result = "SUCCESS";

        }
        catch (Exception ex)
        {
            db.RollBackTransaction();
            result = "FAILED";
            result = "{\"result\":\"" + result + "\"}";
            LogClass log_cust = new LogClass("update_return_status");
            log_cust.write(ex);
            return result;

        }

        return result;

    }


    #region
    //start adding payment details to transaction table
    [WebMethod]
    public static string savePayment(Dictionary<string, string> filters)
    {
        string resultStatus = "N";
        TimeZoneInfo CurrentZone = TimeZoneInfo.FindSystemTimeZoneById(filters["timezone"]);
        DateTime TimeNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, CurrentZone);
        string currdatetime = TimeNow.ToString("yyyy/MM/dd HH:mm:ss");
        mySqlConnection db = new mySqlConnection();
        try
        {
            db.BeginTransaction();
            DataTable dt = new DataTable();
            //start check for refreshment page
            string checkEntryChanged = "select sm_id,branch_id from tbl_sales_master where sm_last_updated_date=DATE_FORMAT('" + filters["lastUpdatedDate"] + "','%Y-%m-%d %H:%i:%s') and sm_id=" + filters["OrderId"];
            DataTable changeCount = db.SelectQueryForTransaction(checkEntryChanged);
            if (changeCount.Rows.Count == 0)
            {
                return "E";
            }

            //end check for refreshment page
            if (filters.ContainsKey("SpecialNote"))
            {
                db.ExecuteQueryForTransaction("UPDATE tbl_sales_master set sm_specialnote  ='" + filters["SpecialNote"] + "' where sm_id=" + filters["OrderId"]);
            }

            //inserting order - when amount paid from customer wallet
            if (Convert.ToDouble(filters["walletamt"]) != 0)
            {

                MySqlCommand cmdInsWallet = new MySqlCommand();
                cmdInsWallet.CommandText = "INSERT INTO `tbl_transactions` " +
                    " ( `session_id`, `action_type`,  `partner_id`,`partner_type`, `branch_id`, `user_id`, `narration`, `dr`,  `date`,`closing_balance`)" +
                    " select @session_id, @action_type, @partner_id,@partner_type,@branch_id, @user_id, @narration, @dr, @date,(ifnull(sum(dr)-sum(cr),0)+@dr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type and branch_id=@branch_id ";
                cmdInsWallet.Parameters.AddWithValue("@session_id", filters["sessionId"]);
                cmdInsWallet.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.WITHDRAWAL);
                cmdInsWallet.Parameters.AddWithValue("@partner_id", filters["cust_id"]);
                cmdInsWallet.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.CUSTOMER);
                cmdInsWallet.Parameters.AddWithValue("@branch_id", changeCount.Rows[0]["branch_id"]);
                cmdInsWallet.Parameters.AddWithValue("@user_id", HttpContext.Current.Request.Cookies["invntrystaffId"].Value);
                cmdInsWallet.Parameters.AddWithValue("@narration", "Withdrawn " + filters["walletamt"] + " from Wallet for clearing the Order #" + filters["OrderId"]);
                cmdInsWallet.Parameters.AddWithValue("@dr", filters["walletamt"]);
                cmdInsWallet.Parameters.AddWithValue("@date", currdatetime);
                db.ExecuteQueryForTransaction(cmdInsWallet);
            }
            //check is cash paid
            if (Convert.ToDouble(filters["sm_paid"]) > 0)
            {
                //inserting order credit entry
                MySqlCommand cmdInsCr = new MySqlCommand();
                cmdInsCr.CommandText = "INSERT INTO `tbl_transactions` " +
                    " ( `session_id`, `action_type`, `action_ref_id`, `partner_id`,`partner_type`, `branch_id`, `user_id`, `narration`,cash_amt,wallet_amt " +
                    (Convert.ToDouble(filters["ChequeAmount"]) != 0 ? ", `cheque_amt`, `cheque_no`, `cheque_date`, `cheque_bank`" : "") +
                    (Convert.ToDouble(filters["CardAmount"]) != 0 ? ", `card_amt`, `card_no`" : "") +
                    ", `cr`, `date`,`closing_balance`)" +
                    " select @session_id, @action_type, @action_ref_id, @partner_id,@partner_type,@branch_id, @user_id, @narration,@cash_amt,@wallet_amt" +
                    (Convert.ToDouble(filters["ChequeAmount"]) != 0 ? ", @cheque_amt, @cheque_no, @cheque_date, @cheque_bank" : "") +
                    (Convert.ToDouble(filters["CardAmount"]) != 0 ? ", @card_amt, @card_no" : "") +
                    ", @cr, @date,(ifnull(sum(dr)-sum(cr),0)-@cr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type and branch_id=@branch_id ";
                cmdInsCr.Parameters.AddWithValue("@session_id", filters["sessionId"]);
                cmdInsCr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.SALES);
                cmdInsCr.Parameters.AddWithValue("@action_ref_id", filters["OrderId"]);
                cmdInsCr.Parameters.AddWithValue("@partner_id", filters["cust_id"]);
                cmdInsCr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.CUSTOMER);
                cmdInsCr.Parameters.AddWithValue("@branch_id", changeCount.Rows[0]["branch_id"]);
                cmdInsCr.Parameters.AddWithValue("@user_id", HttpContext.Current.Request.Cookies["invntrystaffId"].Value);
                cmdInsCr.Parameters.AddWithValue("@narration", "Paid " + filters["sm_paid"] + " for Order #" + filters["OrderId"]);
                cmdInsCr.Parameters.AddWithValue("@cash_amt", Convert.ToDecimal(filters["CashAmount"]));
                cmdInsCr.Parameters.AddWithValue("@wallet_amt", Convert.ToDecimal(filters["walletamt"]));
                //cmdInsDr.Parameters.AddWithValue("@card_amt", neworder["sessionId"]);
                //cmdInsDr.Parameters.AddWithValue("@card_no", neworder["sessionId"]);
                if (Convert.ToDouble(filters["ChequeAmount"]) != 0)
                {
                    cmdInsCr.Parameters.AddWithValue("@cheque_amt", filters["ChequeAmount"]);
                    cmdInsCr.Parameters.AddWithValue("@cheque_no", filters["ChequeNo"]);
                    cmdInsCr.Parameters.AddWithValue("@cheque_date", filters["ChequeDate"]);
                    cmdInsCr.Parameters.AddWithValue("@cheque_bank", filters["ChequeBank"]);
                }
                if (Convert.ToDouble(filters["CardAmount"]) != 0)
                {
                    cmdInsCr.Parameters.AddWithValue("@card_amt", filters["CardAmount"]);
                    cmdInsCr.Parameters.AddWithValue("@card_no", filters["CardNo"]);
                }
                cmdInsCr.Parameters.AddWithValue("@cr", filters["sm_paid"]);
                cmdInsCr.Parameters.AddWithValue("@date", currdatetime);
                db.ExecuteQueryForTransaction(cmdInsCr);
            }

            string update_cust_qry = "UPDATE tbl_customer SET cust_last_updated_date='" + currdatetime + "',cust_amount=(select (sum(dr)-sum(cr)) from tbl_transactions where partner_id='" + filters["cust_id"] + "' and partner_type=" + (int)Constants.PartnerType.CUSTOMER + ") WHERE cust_id='" + filters["cust_id"] + "'";
            bool upcust_result = db.ExecuteQueryForTransaction(update_cust_qry);
            if (upcust_result)
            {
                db.ExecuteQueryForTransaction("UPDATE tbl_sales_master set sm_last_updated_date  ='" + currdatetime + "' where sm_id=" + filters["OrderId"]);
                db.ExecuteQueryForTransaction("update tbl_transactions set last_updated_date='" + currdatetime + "' where action_type=1 and action_ref_id=" + filters["OrderId"] + "");
                resultStatus = "Y";
            }
            db.CommitTransaction();
        }
        catch (Exception ex)
        {
            try
            {
                resultStatus = "N";
                db.RollBackTransaction();
                LogClass log = new LogClass("manageorder");
                log.write(ex);
            }
            catch
            {
            }
        }
        return resultStatus;
    }
    //end adding payment details to transaction table
    #endregion

    [WebMethod]
    public static string Edit_Sales_Return_Item(Dictionary<string, string> return_data)
    {
        string result = "N";
        mySqlConnection db = new mySqlConnection();
        string branchQry = "select branch_timezone from tbl_branch where branch_id='" + return_data["branchid"] + "'";
        //  string branch_timezone = return_order["branch_time_zone"];
        DataTable cTimeZone = db.SelectQuery(branchQry);
        string branch_timezone = Convert.ToString(cTimeZone.Rows[0]["branch_timezone"]);
        TimeZoneInfo CurrentZone = TimeZoneInfo.FindSystemTimeZoneById(branch_timezone);
        DateTime TimeNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, CurrentZone);
        string current_date = TimeNow.ToString("yyyy/MM/dd HH:mm:ss");
        // 1.Get Current Item Details - Quantity , Return Status ( for stock updation) , tax details etc.


        // CHECK WHEATHER THE RETURN IS CANCELLED 
        var current_status = db.SelectScalar("SELECT srm_status FROM tbl_salesreturn_master WHERE tbl_salesreturn_master.srm_id='" + return_data["srm_id"] + "'");
        if (current_status.ToString() == "4")
        {
            result = "CANCEL";
        }
        else
        {
            var current_itm_info = db.SelectQuery("SELECT sri.sri_qty,sri.si_price,srm.srm_amount,sri.sri_type,srm.cust_id,sri.itbs_id,sri.sm_id,srm.branch_id,srm.srm_id,sri.itm_name FROM tbl_salesreturn_items sri INNER JOIN tbl_salesreturn_master srm ON srm.srm_id=sri.srm_id WHERE sri.sri_id='" + return_data["sri_id"] + "'");
            if (current_itm_info.Rows.Count == 0)
            {
                result = "ONEITEM";
                return result;
            }

            // Check for any changes in Quantity
            if (Convert.ToInt32(current_itm_info.Rows[0]["sri_qty"]) != Convert.ToInt32(return_data["sri_qty"]) || Convert.ToDecimal(current_itm_info.Rows[0]["si_price"]) != Convert.ToDecimal(return_data["si_price"]) || Convert.ToInt32(current_itm_info.Rows[0]["sri_type"])!=Convert.ToInt32(return_data["sri_type"]))
            {

                try
                {
                    db.BeginTransaction();

                    //1. UPDATE SALES RETURN ITEMS
                    bool up_sri_qry = db.ExecuteQueryForTransaction("UPDATE tbl_salesreturn_items SET sri_qty='" + return_data["sri_qty"] + "',si_price='" + return_data["si_price"] + "',sri_tax_amount='" + return_data["sri_tax_amount"] + "',sri_total='" + return_data["sri_total"] + "',sri_type="+return_data["sri_type"]+" WHERE sri_id='" + return_data["sri_id"] + "' ");
                    if (up_sri_qry)
                    {
                        Int32 stock_diff = 0;
                        
                        if (current_status.ToString() == "2" || current_status.ToString() == "3")
                        {                          
                            var old_item_condition = Convert.ToInt32(current_itm_info.Rows[0]["sri_type"]);
                            var new_item_condition = Convert.ToInt32(return_data["sri_type"]);
                            var old_qty = Convert.ToInt32(current_itm_info.Rows[0]["sri_qty"]);
                            var new_qty = Convert.ToInt32(return_data["sri_qty"]);

                            if (old_item_condition == 2)
                            {
                                stock_diff = old_qty;
                                // decrease stock here
                                db.ExecuteQueryForTransaction("UPDATE tbl_itembranch_stock SET itbs_stock=(itbs_stock - " + stock_diff + "),itm_last_update_date='" + current_date + "' where itbs_id='" + current_itm_info.Rows[0]["itbs_id"].ToString() + "'");

                                StringBuilder can_sb_bulk_stkTrQry = new StringBuilder();
                                can_sb_bulk_stkTrQry.Append("INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`action_ref_id`,`user_id`,`narration`,`dr_qty`,`closing_stock`,`date`) VALUES ");
                                // stock transaction
                                can_sb_bulk_stkTrQry.Append("('" + Convert.ToString(current_itm_info.Rows[0]["itbs_id"].ToString() + "','" + (int)Constants.ActionType.SALES_RETURN) + "','" + current_itm_info.Rows[0]["srm_id"].ToString() + "','" + return_data["user_id"].ToString() + "'");
                                can_sb_bulk_stkTrQry.Append(",'SALES RETURN: (stock decreased by " + stock_diff + " qty of " + current_itm_info.Rows[0]["itm_name"].ToString() + " during Sales Return Editing with Ref. ID #" + current_itm_info.Rows[0]["srm_id"].ToString() + "','" + stock_diff + "'");
                                can_sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + current_itm_info.Rows[0]["itbs_id"].ToString() + "')");
                                can_sb_bulk_stkTrQry.Append(",'" + current_date + "');");
                                db.ExecuteQueryForTransaction(can_sb_bulk_stkTrQry.ToString());
                            }

                            if (new_item_condition == 2)
                            {
                                stock_diff = new_qty;

                                db.ExecuteQueryForTransaction("UPDATE tbl_itembranch_stock SET itbs_stock=(itbs_stock + " + stock_diff + "),itm_last_update_date='" + current_date + "' where itbs_id='" + current_itm_info.Rows[0]["itbs_id"].ToString() + "'");

                                StringBuilder can_sb_bulk_stkTrQry = new StringBuilder();
                                can_sb_bulk_stkTrQry.Append("INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`action_ref_id`,`user_id`,`narration`,`cr_qty`,`closing_stock`,`date`) VALUES ");
                                // stock transaction
                                can_sb_bulk_stkTrQry.Append("('" + Convert.ToString(current_itm_info.Rows[0]["itbs_id"].ToString() + "','" + (int)Constants.ActionType.SALES_RETURN) + "','" + current_itm_info.Rows[0]["srm_id"].ToString() + "','" + return_data["user_id"].ToString() + "'");
                                can_sb_bulk_stkTrQry.Append(",'SALES RETURN: stock increase by " + stock_diff + " qty of " + current_itm_info.Rows[0]["itm_name"].ToString() + " during Sales Return Editing with Ref. ID #" + current_itm_info.Rows[0]["srm_id"].ToString() + "','" + stock_diff + "'");
                                can_sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + current_itm_info.Rows[0]["itbs_id"].ToString() + "')");
                                can_sb_bulk_stkTrQry.Append(",'" + current_date + "');");
                                db.ExecuteQueryForTransaction(can_sb_bulk_stkTrQry.ToString());

                            }

                        }


                        decimal current_amt = 0;
                            var new_srm_amount = db.SelectScalarForTransaction("SELECT SUM(sri_total) FROM tbl_salesreturn_items WHERE srm_id='" + return_data["srm_id"] + "'");

                        //2. UPDATE SALES RETURN MASTER
                        if (Convert.ToDecimal(new_srm_amount) != Convert.ToDecimal(current_itm_info.Rows[0]["srm_amount"]))
                        {
                            db.ExecuteQueryForTransaction("UPDATE tbl_salesreturn_master SET srm_amount='" + new_srm_amount + "'  WHERE srm_id='" + return_data["srm_id"] + "'");

                            // if amount return increased - credit to customer as CREDIT ENTRY
                            if (Convert.ToDecimal(new_srm_amount) > Convert.ToDecimal(current_itm_info.Rows[0]["srm_amount"]))
                            {
                                current_amt = Convert.ToDecimal(new_srm_amount) - Convert.ToDecimal(current_itm_info.Rows[0]["srm_amount"]);
                                MySqlCommand cmdInsCr = new MySqlCommand();
                                cmdInsCr.CommandText = "INSERT INTO `tbl_transactions` " +
                                    " (`action_type`, `action_ref_id`, `partner_id`,`partner_type`,`branch_id`, `user_id`, `narration`, `cr`,  `date`,`closing_balance`)" +
                                    " select @action_type, @action_ref_id, @partner_id,@partner_type,@branch_id, @user_id, @narration, @cr, @date,(ifnull(sum(dr)-sum(cr),0)-@cr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type and branch_id=@branch_id  ";
                                //cmdInsCr.Parameters.AddWithValue("@session_id", return_order["session_id"]);
                                cmdInsCr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.SALES_RETURN);
                                cmdInsCr.Parameters.AddWithValue("@action_ref_id", return_data["srm_id"]);
                                cmdInsCr.Parameters.AddWithValue("@partner_id", current_itm_info.Rows[0]["cust_id"].ToString());
                                cmdInsCr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.CUSTOMER);
                                cmdInsCr.Parameters.AddWithValue("@branch_id", current_itm_info.Rows[0]["branch_id"].ToString());
                                cmdInsCr.Parameters.AddWithValue("@user_id", return_data["user_id"]);
                                cmdInsCr.Parameters.AddWithValue("@narration", "Amount credited due to Return Edit worth: " + current_amt);
                                cmdInsCr.Parameters.AddWithValue("@cr", current_amt);
                                cmdInsCr.Parameters.AddWithValue("@date", current_date);
                                db.ExecuteQueryForTransaction(cmdInsCr);

                            }
                            else
                            {
                                current_amt = Convert.ToDecimal(current_itm_info.Rows[0]["srm_amount"]) - Convert.ToDecimal(new_srm_amount);
                                MySqlCommand cmdInsCr = new MySqlCommand();
                                cmdInsCr.CommandText = "INSERT INTO `tbl_transactions` " +
                                    " (`action_type`, `action_ref_id`, `partner_id`,`partner_type`,`branch_id`, `user_id`, `narration`, `dr`,  `date`,`closing_balance`)" +
                                    " select @action_type, @action_ref_id, @partner_id,@partner_type,@branch_id, @user_id, @narration, @dr, @date,(ifnull(sum(dr)-sum(cr),0)+@dr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type and branch_id=@branch_id  ";
                                //cmdInsCr.Parameters.AddWithValue("@session_id", return_order["session_id"]);
                                cmdInsCr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.SALES_RETURN);
                                cmdInsCr.Parameters.AddWithValue("@action_ref_id", return_data["srm_id"]);
                                cmdInsCr.Parameters.AddWithValue("@partner_id", current_itm_info.Rows[0]["cust_id"].ToString());
                                cmdInsCr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.CUSTOMER);
                                cmdInsCr.Parameters.AddWithValue("@branch_id", current_itm_info.Rows[0]["branch_id"].ToString());
                                cmdInsCr.Parameters.AddWithValue("@user_id", return_data["user_id"]);
                                cmdInsCr.Parameters.AddWithValue("@narration", "Amount debited due to Return Edit worth: " + current_amt);
                                cmdInsCr.Parameters.AddWithValue("@dr", current_amt);
                                cmdInsCr.Parameters.AddWithValue("@date", current_date);
                                db.ExecuteQueryForTransaction(cmdInsCr);
                            }

                            // UPDATE CUSTOMER BALANCE IN CUSTOMER TABLE
                            db.ExecuteQueryForTransaction("UPDATE tbl_customer SET cust_last_updated_date='" + current_date + "',cust_amount=(select (sum(dr)-sum(cr)) from tbl_transactions  where partner_id='" + current_itm_info.Rows[0]["cust_id"].ToString() + "' and partner_type=" + (int)Constants.PartnerType.CUSTOMER + ") where cust_id=" + current_itm_info.Rows[0]["cust_id"].ToString() + "");

                        }

                    }
                    db.CommitTransaction();
                    result = "Y";
                }
                catch (Exception ex)
                {
                    db.RollBackTransaction();
                    var log = new LogClass("Edit_Sales_Return_Item");
                    log.write(ex);
                    result = "ERROR";
                    return result;
                }

            }
            else
            {
                //No change in quantity & price - halt
                result = "Y";
            }

        }

        return result;
    }

    [WebMethod]
    public static string Remove_Sales_Return_Item(Dictionary<string, string> return_data)
    {
        string result = "N";

        // 1.Get Current Item Details - Quantity , Return Status ( for stock updation) , tax details etc.
        mySqlConnection db = new mySqlConnection();
        string branchQry = "select branch_timezone from tbl_branch where branch_id='" + return_data["branchid"] + "'";
        //  string branch_timezone = return_order["branch_time_zone"];
        DataTable cTimeZone = db.SelectQuery(branchQry);
        string branch_timezone = Convert.ToString(cTimeZone.Rows[0]["branch_timezone"]);
        TimeZoneInfo CurrentZone = TimeZoneInfo.FindSystemTimeZoneById(branch_timezone);
        DateTime TimeNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, CurrentZone);
        string current_date = TimeNow.ToString("yyyy/MM/dd HH:mm:ss");
        // CHECK WHEATHER THE RETURN IS CANCELLED 
        var current_status = db.SelectScalar("SELECT srm_status FROM tbl_salesreturn_master WHERE tbl_salesreturn_master.srm_id='" + return_data["srm_id"] + "'");
        if (current_status.ToString() == "4")
        {
            result = "CANCEL";
        }
        else
        {
            var current_itm_info = db.SelectQuery("SELECT sri.sri_qty,sri.si_price,srm.srm_amount,sri.sri_type,srm.cust_id,sri.itbs_id,sri.sm_id,srm.branch_id,srm.srm_id,sri.itm_name FROM tbl_salesreturn_items sri INNER JOIN tbl_salesreturn_master srm ON srm.srm_id=sri.srm_id WHERE sri.sri_id='" + return_data["sri_id"] + "'");
            if (current_itm_info.Rows.Count > 0)
            {
                var item_dt = db.SelectQuery("SELECT sri_id FROM tbl_salesreturn_items WHERE srm_id='" + return_data["srm_id"] + "'");
                if (item_dt.Rows.Count == 1)
                {
                    result = "ONEITEM";
                    return result;
                }

                try
                {
                    db.BeginTransaction();

                    //1. UPDATE SALES RETURN ITEMS
                    bool up_sri_qry = db.ExecuteQueryForTransaction("DELETE FROM tbl_salesreturn_items  WHERE sri_id='" + return_data["sri_id"] + "' ");
                    if (up_sri_qry)
                    {
                        var new_srm_amount = db.SelectScalarForTransaction("SELECT SUM(sri_total) FROM tbl_salesreturn_items WHERE srm_id='" + return_data["srm_id"] + "'");

                        //2. UPDATE SALES RETURN MASTER
                        if (Convert.ToDecimal(new_srm_amount) != Convert.ToDecimal(current_itm_info.Rows[0]["srm_amount"]))
                        {
                            db.ExecuteQueryForTransaction("UPDATE tbl_salesreturn_master SET srm_amount='" + new_srm_amount + "' WHERE srm_id='" + return_data["srm_id"] + "'");

                            Int32 stock_diff = 0;

                            // ENTRY TO STOCK TRANSFER
                            if (Convert.ToInt32(current_itm_info.Rows[0]["sri_type"]) == 2)
                            {

                                stock_diff = Convert.ToInt32(current_itm_info.Rows[0]["sri_qty"]);
                                // decrease stock here
                                db.ExecuteQueryForTransaction("UPDATE tbl_itembranch_stock SET itbs_stock=(itbs_stock - " + stock_diff + "),itm_last_update_date='" + current_date + "' where itbs_id='" + current_itm_info.Rows[0]["itbs_id"].ToString() + "'");

                                StringBuilder can_sb_bulk_stkTrQry = new StringBuilder();
                                can_sb_bulk_stkTrQry.Append("INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`action_ref_id`,`user_id`,`narration`,`dr_qty`,`closing_stock`,`date`) VALUES ");
                                // stock transaction
                                can_sb_bulk_stkTrQry.Append("('" + Convert.ToString(current_itm_info.Rows[0]["itbs_id"].ToString() + "','" + (int)Constants.ActionType.SALES_RETURN) + "','" + current_itm_info.Rows[0]["srm_id"].ToString() + "','" + return_data["user_id"].ToString() + "'");
                                can_sb_bulk_stkTrQry.Append(",'SALES RETURN: (stock decreased by " + stock_diff + " qty of " + current_itm_info.Rows[0]["itm_name"].ToString() + " during removal from Sales Return with Ref. ID #" + current_itm_info.Rows[0]["srm_id"].ToString() + "','" + stock_diff + "'");
                                can_sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + current_itm_info.Rows[0]["itbs_id"].ToString() + "')");
                                can_sb_bulk_stkTrQry.Append(",'" + current_date + "');");
                                db.ExecuteQueryForTransaction(can_sb_bulk_stkTrQry.ToString());

                            }

                            decimal current_amt = 0;

                            // if amount return increased - credit to customer as CREDIT ENTRY
                            if (Convert.ToDecimal(new_srm_amount) > Convert.ToDecimal(current_itm_info.Rows[0]["srm_amount"]))
                            {
                                current_amt = Convert.ToDecimal(new_srm_amount) - Convert.ToDecimal(current_itm_info.Rows[0]["srm_amount"]);
                                MySqlCommand cmdInsCr = new MySqlCommand();
                                cmdInsCr.CommandText = "INSERT INTO `tbl_transactions` " +
                                    " (`action_type`, `action_ref_id`, `partner_id`,`partner_type`,`branch_id`, `user_id`, `narration`, `cr`,  `date`,`closing_balance`)" +
                                    " select @action_type, @action_ref_id, @partner_id,@partner_type,@branch_id, @user_id, @narration, @cr, @date,(ifnull(sum(dr)-sum(cr),0)-@cr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type and branch_id=@branch_id  ";
                                //cmdInsCr.Parameters.AddWithValue("@session_id", return_order["session_id"]);
                                cmdInsCr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.SALES_RETURN);
                                cmdInsCr.Parameters.AddWithValue("@action_ref_id", return_data["srm_id"]);
                                cmdInsCr.Parameters.AddWithValue("@partner_id", current_itm_info.Rows[0]["cust_id"].ToString());
                                cmdInsCr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.CUSTOMER);
                                cmdInsCr.Parameters.AddWithValue("@branch_id", current_itm_info.Rows[0]["branch_id"].ToString());
                                cmdInsCr.Parameters.AddWithValue("@user_id", return_data["user_id"]);
                                cmdInsCr.Parameters.AddWithValue("@narration", "Amount credited due to Return Edit worth: " + current_amt);
                                cmdInsCr.Parameters.AddWithValue("@cr", current_amt);
                                cmdInsCr.Parameters.AddWithValue("@date", current_date);
                                db.ExecuteQueryForTransaction(cmdInsCr);

                            }
                            else
                            {
                                current_amt = Convert.ToDecimal(current_itm_info.Rows[0]["srm_amount"]) - Convert.ToDecimal(new_srm_amount);
                                MySqlCommand cmdInsCr = new MySqlCommand();
                                cmdInsCr.CommandText = "INSERT INTO `tbl_transactions` " +
                                    " (`action_type`, `action_ref_id`, `partner_id`,`partner_type`,`branch_id`, `user_id`, `narration`, `dr`,  `date`,`closing_balance`)" +
                                    " select @action_type, @action_ref_id, @partner_id,@partner_type,@branch_id, @user_id, @narration, @dr, @date,(ifnull(sum(dr)-sum(cr),0)+@dr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type and branch_id=@branch_id  ";
                                //cmdInsCr.Parameters.AddWithValue("@session_id", return_order["session_id"]);
                                cmdInsCr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.SALES_RETURN);
                                cmdInsCr.Parameters.AddWithValue("@action_ref_id", return_data["srm_id"]);
                                cmdInsCr.Parameters.AddWithValue("@partner_id", current_itm_info.Rows[0]["cust_id"].ToString());
                                cmdInsCr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.CUSTOMER);
                                cmdInsCr.Parameters.AddWithValue("@branch_id", current_itm_info.Rows[0]["branch_id"].ToString());
                                cmdInsCr.Parameters.AddWithValue("@user_id", return_data["user_id"]);
                                cmdInsCr.Parameters.AddWithValue("@narration", "Amount debited due to Return Edit worth: " + current_amt);
                                cmdInsCr.Parameters.AddWithValue("@dr", current_amt);
                                cmdInsCr.Parameters.AddWithValue("@date", current_date);
                                db.ExecuteQueryForTransaction(cmdInsCr);
                            }

                            // UPDATE CUSTOMER BALANCE IN CUSTOMER TABLE
                            db.ExecuteQueryForTransaction("UPDATE tbl_customer SET cust_last_updated_date='" + current_date + "',cust_amount=(select (sum(dr)-sum(cr)) from tbl_transactions  where partner_id='" + current_itm_info.Rows[0]["cust_id"].ToString() + "' and partner_type=" + (int)Constants.PartnerType.CUSTOMER + ") where cust_id=" + current_itm_info.Rows[0]["cust_id"].ToString() + "");

                            // UPDATE AS RECIEVED IF ALL ITEMS ARE RECIEVED
                            var dt = db.SelectQueryForTransaction("SELECT sri.sri_id FROM tbl_salesreturn_items sri WHERE sri.srm_id='" + return_data["srm_id"] + "' AND sri.sri_recieved_id=0 ");
                            if (dt.Rows.Count > 0)
                            {
                                db.ExecuteQueryForTransaction("UPDATE tbl_salesreturn_master srm  SET srm.srm_status=1 WHERE srm.srm_id='" + return_data["srm_id"] + "'");
                            }
                            else
                            {
                                db.ExecuteQueryForTransaction("UPDATE tbl_salesreturn_master srm  SET srm.srm_status=2 WHERE srm.srm_id='" + return_data["srm_id"] + "'");

                                // UPDATE AS APPROVED IF ALL ITEMS APPROVED
                                var dt1 = db.SelectQueryForTransaction("SELECT sri.sri_id FROM tbl_salesreturn_items sri WHERE sri.srm_id='" + return_data["srm_id"] + "' AND sri.sri_approved_id=0 ");
                                if (dt1.Rows.Count > 0) { }
                                else
                                {
                                    db.ExecuteQueryForTransaction("UPDATE tbl_salesreturn_master srm  SET srm.srm_status=3 WHERE  srm.srm_id='" + return_data["srm_id"] + "'");
                                }
                            }

                        }

                    }
                    db.CommitTransaction();
                    result = "Y";
                }
                catch (Exception ex)
                {
                    db.RollBackTransaction();
                    var log = new LogClass("Remove_Sales_Return_Item");
                    log.write(ex);
                    result = "ERROR";
                    return result;
                }

            }
            else
            {
                //No change in quantity & price - halt
                result = "Y";
            }

        }




        return result;
    }
}