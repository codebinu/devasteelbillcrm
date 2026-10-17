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

public partial class web_purchase_manage_purchasereturns : System.Web.UI.Page
{
    mySqlConnection db = new mySqlConnection();
    public string settings;
    protected void Page_Load(object sender, EventArgs e)
    {

        LoginAuthentication bill = new LoginAuthentication();
        bill.userAuthentication();
     //   bill.checkPageAcess(112);
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
        selectvar2 = selectvar2 + " pri.itm_code,";
        selectvar2 = selectvar2 + " pri.itm_name , pri.pri_qty, pri.pi_price,pri.pri_discount_amount,concat(tu.first_name,\" \",tu.last_name) as approver,concat(tur.first_name,\" \",tur.last_name) as receiver,DATE_FORMAT(pri_approved_date,'%d-%b-%Y %h:%i %p') AS approveddate,DATE_FORMAT(pri_recieved_date,'%d-%b-%Y %h:%i %p') AS receivededdate, pri.pri_total,pri.pri_tax_amount,pri.pri_type  ";
        qry = "select " + selectvar2 + " from tbl_purchase_return_items pri LEFT JOIN tbl_purchase_master tpm ON tpm.pm_id=pri.pm_id left join tbl_user_details"
 + " tu on tu.user_id=pri.pri_approved_id left join tbl_user_details tur on tur.user_id=pri.pri_recieved_id where pri.prm_id='" + ReturnNo + "'  order by pri.row_no";
        dtItems = db.SelectQuery(qry);
        sb.Append("\"items\":");
        sb.Append(JsonConvert.SerializeObject(dtItems, Formatting.Indented));
        sb.Append(",");
        string basicDataqry = "select prm_id,IFNULL(prm_invoice_no,'NOT INVOICED') as prm_invoice_no,prm.vendor_id,tv.vn_name,prm.prm_status as status,prm.branch_id,prm_amount as total_amount, DATE_FORMAT(prm_date, '%d-%b-%Y %h:%i %p') AS DATE,prm_description, tv.vn_balance as outstanding_amt,concat(tu.first_name, \" \", tu.last_name) as approver_name from tbl_purchase_return_master prm";
        basicDataqry+= " inner join tbl_vendor tv on tv.vn_id = prm.vendor_id left join tbl_user_details tu on tu.user_id = prm.prm_userid where prm_id =" + ReturnNo;
        dtOrder = db.SelectQuery(basicDataqry);
        sb.Append("\"return\":");
        sb.Append(JsonConvert.SerializeObject(dtOrder, Formatting.Indented));

        sb.Append("}");

        return sb.ToString();
    }
    //Stop: Show Details of Selected  Bill...


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
            string update_pri = "";
            string reception_id = "";
            db.BeginTransaction();

            reception_id = item["user_id"].ToString();


            if (item["return_status"].ToString() == "2")
            {
                Int32 update_type = 0;

                DataTable dt_item_status = db.SelectQueryForTransaction("SELECT pri_id,pri_type,pri_recieved_id,itbs_id,pri_qty,pm_id,itm_name,prm_id FROM tbl_purchase_return_items pri WHERE pri.prm_id='" + item["prm_id"] + "'");
                for (int i = 0; i < dt_item_status.Rows.Count; i++)
                {
                    string existing_received_id = dt_item_status.Rows[i]["pri_recieved_id"].ToString();
                       
                    if (existing_received_id == "0")
                    {
                        if (dt_item_status.Rows[i]["pri_type"].ToString() == "2" && reception_id != "0")
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
                        if (reception_id == "0" && dt_item_status.Rows[i]["pri_type"].ToString() == "2")
                        {
                            update_type = 2;
                        }
                        else
                        {
                            update_type = 0;
                        }
                    }


                    // end handle stock

                    update_pri = "UPDATE tbl_purchase_return_items SET pri_recieved_id='" + reception_id + "',pri_recieved_date='" + action_date + "' WHERE pri_id='" + dt_item_status.Rows[i]["pri_id"] + "';";
                    db.ExecuteQueryForTransaction(update_pri);

                    db.ExecuteQueryForTransaction("UPDATE tbl_purchase_return_master srm  SET srm.prm_status=2 WHERE srm.prm_status!=3 AND srm.prm_id='" + item["prm_id"] + "'");
                }
            }

     //approve status
            if (item["return_status"].ToString() == "3")
            {
                update_pri = "UPDATE tbl_purchase_return_items SET pri_approved_id='" + reception_id + "',pri_approved_date='" + action_date + "' WHERE prm_id='" + item["prm_id"] + "';";
                db.ExecuteQueryForTransaction(update_pri);

                db.ExecuteQueryForTransaction("UPDATE tbl_purchase_return_master srm  SET srm.prm_status=3 WHERE srm.prm_status!=4 AND srm.prm_id='" + item["prm_id"] + "'");
            }
            //cancel status
            if (item["return_status"].ToString() == "4")
            {
                var current_status = db.SelectScalarForTransaction("SELECT prm_status FROM tbl_purchase_return_master WHERE tbl_purchase_return_master.prm_id='" + item["prm_id"] + "'");
                if (current_status.ToString() == "4")
                {
                    result = "CANCEL";
                }
                else
                {
                    var current_itm_info = db.SelectQueryForTransaction("SELECT pri.pri_qty,pri.pi_price,prm.prm_amount,pri.pri_type,prm.vendor_id,pri.itbs_id,pri.pm_id,prm.branch_id,prm.prm_id,pri.itm_name FROM tbl_purchase_return_items pri INNER JOIN tbl_purchase_return_master prm ON prm.prm_id=pri.prm_id WHERE pri.prm_id='" + item["prm_id"] + "' AND pri.pri_type=2");
                    var dt_rt_info = db.SelectQueryForTransaction("SELECT prm.vendor_id,prm.branch_id FROM tbl_purchase_return_master prm WHERE prm.prm_id='" + item["prm_id"] + "'");


                    if (current_itm_info.Rows.Count > 0)
                    {
                        // HANDLE STOCK FOR - READY TO USE ITEMS
                        for (int i = 0; i < current_itm_info.Rows.Count; i++)
                        {
                            // increase stock here
                            db.ExecuteQueryForTransaction("UPDATE tbl_itembranch_stock SET itbs_stock=(itbs_stock + " + current_itm_info.Rows[i]["pri_qty"].ToString() + "),itm_last_update_date='" + action_date+ "' where itbs_id='" + current_itm_info.Rows[i]["itbs_id"].ToString() + "'");

                            StringBuilder can_sb_bulk_stkTrQry = new StringBuilder();
                            can_sb_bulk_stkTrQry.Append("INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`action_ref_id`,`user_id`,`narration`,`dr_qty`,`closing_stock`,`date`) VALUES ");
                            // stock transaction
                            can_sb_bulk_stkTrQry.Append("('" + Convert.ToString(current_itm_info.Rows[i]["itbs_id"].ToString() + "','" + (int)Constants.ActionType.PURCHASE_RETURN) + "','" + current_itm_info.Rows[i]["prm_id"].ToString() + "','" + item["user_id"].ToString() + "'");
                            can_sb_bulk_stkTrQry.Append(",'PURCHASE RETURN: (stock decreased by " + current_itm_info.Rows[i]["pri_qty"].ToString() + " qty of " + current_itm_info.Rows[i]["itm_name"].ToString() + " during Purchase Return Editing with Ref. ID #" + current_itm_info.Rows[i]["prm_id"].ToString() + "','" + current_itm_info.Rows[i]["pri_qty"].ToString() + "'");
                            can_sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + current_itm_info.Rows[i]["itbs_id"].ToString() + "')");
                            can_sb_bulk_stkTrQry.Append(",'" + action_date+ "');");
                            db.ExecuteQueryForTransaction(can_sb_bulk_stkTrQry.ToString());
                        }

                    }

                    //1. UPDATE PURCHASE RETURN ITEMS
                    var prm_amount = db.SelectScalarForTransaction("SELECT SUM(pri_total) FROM tbl_purchase_return_items WHERE prm_id='" + item["prm_id"] + "'");
                    db.ExecuteQueryForTransaction("UPDATE tbl_purchase_return_master SET prm_status='4' WHERE prm_id='" + item["prm_id"] + "'");
                    //2. UPDATE PURCHASE RETURN MASTER

                    MySqlCommand cmdInsCr = new MySqlCommand();
                    cmdInsCr.CommandText = "INSERT INTO `tbl_transactions` " +
                        " (`action_type`, `action_ref_id`, `partner_id`,`partner_type`,`branch_id`, `user_id`, `narration`, `dr`,  `date`,`closing_balance`)" +
                        " select @action_type, @action_ref_id, @partner_id,@partner_type,@branch_id, @user_id, @narration, @dr, @date,(ifnull(sum(dr)-sum(cr),0)+@dr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type and branch_id=@branch_id  ";
                    //cmdInsCr.Parameters.AddWithValue("@session_id", return_order["session_id"]);
                    cmdInsCr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.PURCHASE_RETURN);
                    cmdInsCr.Parameters.AddWithValue("@action_ref_id", item["prm_id"]);
                    cmdInsCr.Parameters.AddWithValue("@partner_id", dt_rt_info.Rows[0]["vendor_id"].ToString());
                    cmdInsCr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.VENDOR);
                    cmdInsCr.Parameters.AddWithValue("@branch_id", dt_rt_info.Rows[0]["branch_id"].ToString());
                    cmdInsCr.Parameters.AddWithValue("@user_id", item["user_id"]);
                    cmdInsCr.Parameters.AddWithValue("@narration", "Amount debited due to Cancellation of Return worth: " + prm_amount);
                    cmdInsCr.Parameters.AddWithValue("@dr", prm_amount);
                    cmdInsCr.Parameters.AddWithValue("@date", action_date);
                    db.ExecuteQueryForTransaction(cmdInsCr);

                    // UPDATE Vendor BALANCE IN vendor TABLE
                    db.ExecuteQueryForTransaction("UPDATE tbl_vendor SET vn_balance=(select (sum(cr)-sum(dr)) from tbl_transactions  where partner_id='" + dt_rt_info.Rows[0]["vendor_id"].ToString() + "' and partner_type=" + (int)Constants.PartnerType.VENDOR + ") where vn_id=" + dt_rt_info.Rows[0]["vendor_id"].ToString() + "");

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
            string checkEntryChanged = "select pm_id,branch_id from tbl_purchase_master where pm_last_updated_date=DATE_FORMAT('" + filters["lastUpdatedDate"] + "','%Y-%m-%d %H:%i:%s') and pm_id=" + filters["OrderId"];
            DataTable changeCount = db.SelectQueryForTransaction(checkEntryChanged);
            if (changeCount.Rows.Count == 0)
            {
                return "E";
            }

            //end check for refreshment page
            if (filters.ContainsKey("SpecialNote"))
            {
                db.ExecuteQueryForTransaction("UPDATE tbl_purchase_master set pm_specialnote  ='" + filters["SpecialNote"] + "' where pm_id=" + filters["OrderId"]);
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
                cmdInsWallet.Parameters.AddWithValue("@partner_id", filters["vendor_id"]);
                cmdInsWallet.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.VENDOR);
                cmdInsWallet.Parameters.AddWithValue("@branch_id", changeCount.Rows[0]["branch_id"]);
                cmdInsWallet.Parameters.AddWithValue("@user_id", HttpContext.Current.Request.Cookies["invntrystaffId"].Value);
                cmdInsWallet.Parameters.AddWithValue("@narration", "Withdrawn " + filters["walletamt"] + " from Wallet for clearing the Order #" + filters["OrderId"]);
                cmdInsWallet.Parameters.AddWithValue("@dr", filters["walletamt"]);
                cmdInsWallet.Parameters.AddWithValue("@date", currdatetime);
                db.ExecuteQueryForTransaction(cmdInsWallet);
            }
            //check is cash paid
            if (Convert.ToDouble(filters["pm_paid"]) > 0)
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
                cmdInsCr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.PURCHASE);
                cmdInsCr.Parameters.AddWithValue("@action_ref_id", filters["OrderId"]);
                cmdInsCr.Parameters.AddWithValue("@partner_id", filters["vendor_id"]);
                cmdInsCr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.VENDOR);
                cmdInsCr.Parameters.AddWithValue("@branch_id", changeCount.Rows[0]["branch_id"]);
                cmdInsCr.Parameters.AddWithValue("@user_id", HttpContext.Current.Request.Cookies["invntrystaffId"].Value);
                cmdInsCr.Parameters.AddWithValue("@narration", "Paid " + filters["pm_paid"] + " for Order #" + filters["OrderId"]);
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
                cmdInsCr.Parameters.AddWithValue("@cr", filters["pm_paid"]);
                cmdInsCr.Parameters.AddWithValue("@date", currdatetime);
                db.ExecuteQueryForTransaction(cmdInsCr);
            }

            string update_vend_qry = "UPDATE tbl_vendor SET vn_balance=(select (sum(dr)-sum(cr)) from tbl_transactions where partner_id='" + filters["vendor_id"] + "' and partner_type=" + (int)Constants.PartnerType.VENDOR + ") WHERE vn_id='" + filters["vendor_id"] + "'";
            bool upvend_result = db.ExecuteQueryForTransaction(update_vend_qry);
            if (upvend_result)
            {
                db.ExecuteQueryForTransaction("UPDATE tbl_purchase_master set pm_last_updated_date  ='" + currdatetime + "' where pm_id=" + filters["OrderId"]);
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
}