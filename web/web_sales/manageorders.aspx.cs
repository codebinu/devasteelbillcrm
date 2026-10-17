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
public partial class web_sales_manageorders : System.Web.UI.Page
{
    mySqlConnection db=new mySqlConnection();
    public string settings;
    protected void Page_Load(object sender, EventArgs e)
    {

        LoginAuthentication bill = new LoginAuthentication();
        bill.userAuthentication();
        bill.checkPageAcess(9);
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
    public static string selectOrders(string billno)
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dtItems = new DataTable();
        DataTable dtOrder = new DataTable();
        StringBuilder sb = new StringBuilder();
        sb.Append("{");
        string selectvar2 = "";
        string qry = "";
        selectvar2 = selectvar2 + " itm.itm_qty_per_carton,si.row_no, si.itm_code,";
        selectvar2 = selectvar2 + " si.itm_name , si.si_qty, si.si_org_price,si.si_price, si.si_discount_rate, si.si_discount_amount, si.si_net_amount,si.si_foc,(si.si_net_amount-si.si_tax_amount) as si_tax_excluded_total,si.si_tax_amount,si.si_total,si.si_itm_type  ";
        qry = "select " + selectvar2 + " from tbl_sales_items si INNER JOIN tbl_itembranch_stock itb ON itb.itbs_id=si.itbs_id INNER JOIN tbl_item_master itm ON itm.itm_id=itb.itm_id where si.sm_id='" + billno + "' and si.si_itm_type!=2 order by si.row_no";
        dtItems = db.SelectQuery(qry);
        sb.Append("\"items\":");
        sb.Append(JsonConvert.SerializeObject(dtItems,Formatting.Indented));
        sb.Append(",");
        string previouspaidqry = "select br.branch_type,tsm.cust_id,tc.cust_name,tsm.sm_type as type,tsm.branch_id,sm_netamount as total_amount,sm_refno,sm_delivery_status as"
 + " order_status,DATE_FORMAT(sm_processed_date,'%d-%b-%Y %h:%i %p') AS date,DATE_FORMAT(sm_processed_date,'%d-%m-%Y %h:%i %p') AS processedDate,DATE_FORMAT(sm_last_updated_date, '%Y-%m-%d %H:%i:%s') as lastUpdatedDate,sm_specialnote,cust_amount as outstanding_amt,concat(tu.first_name,\" \",tu.last_name)"
 + " as approver_name,cust_type,tsm.branch_tax_method,sm_invoice_no as invoiceNum,sum(dr)-sum(cr) as total_balance,sm_netamount-(sum(dr)-sum(cr))"
 + " as total_paid,(select sum(bill_bal) from (select (sum(dr)-sum(cr)) bill_bal from tbl_transactions where `action_type`=" + (int)Constants.ActionType.SALES + ""
 + " and `partner_id`=(select cust_id from tbl_sales_master where sm_id=" + billno + ") group by action_ref_id,action_type having"
 + " sum(dr)>sum(cr)) as bal_res ) as custBal,sm_roundoff as roundoff from tbl_sales_master tsm inner join tbl_customer tc on tc.cust_id=tsm.cust_id right join"
 + " tbl_transactions tr on (tr.action_ref_id=tsm.sm_id and tr.action_type=" + (int)Constants.ActionType.SALES + " ) left join tbl_user_details"
 + " tu on tu.user_id=tsm.sm_approved_id  INNER JOIN tbl_branch br ON br.branch_id= tsm.branch_id  where sm_id='" + billno + "' ";
        dtOrder = db.SelectQuery(previouspaidqry);
        sb.Append("\"order\":");
        sb.Append(JsonConvert.SerializeObject(dtOrder, Formatting.Indented));
        //fetching payment details
        //String paymentQry = "select sm_id as orderid,DATE_FORMAT(sm_date, '%d-%b-%Y %H:%i:%s') as date"
        //    + " ,IFNULL(sm_chq_amt,0) as chk_amt,IFNULL(sm_card_amt,0) as card_amt,IFNULL(sm_cash_amt,0) as cash_amt"
        //    + " ,IFNULL(sm_wallet_amt,0) as wlt_amt,sm_paid as paid,sm_balance as balance"
        //    + " from tbl_sales_master where sm_refno='" + dtOrder.Rows[0]["sm_refno"].ToString() + "'";
        String paymentQry = "select tr.id,DATE_FORMAT(`date`, '%d-%b-%Y %h:%i %p') as date,narration,concat(tu.first_name,' ',tu.last_name) as user_name,cash_amt,card_amt,card_no,cheque_amt,cheque_no,"
           + " cheque_bank,DATE_FORMAT(`cheque_date`, '%d-%b-%Y') as cheque_date,wallet_amt,dr,cr,closing_balance,IFNULL(voucher_no,'-') voucher_no ,IFNULL(po_number,'-') po_number from tbl_transactions tr "
		   + " inner join tbl_user_details tu on tu.user_id=tr.user_id "
           + " where action_ref_id='" + billno + "' and action_type=" + (int)Constants.ActionType.SALES;
        DataTable dtPay = db.SelectQuery(paymentQry);
        sb.Append(",");
        sb.Append("\"transaction_details\":");
        sb.Append(JsonConvert.SerializeObject(dtPay, Formatting.Indented));

        //done by anjana fetching waybilling details
        String waybillingQry = "select way.sm_id as orderid,DATE_FORMAT(way.wh_date, '%d-%b-%Y %H:%i:%s') as date"
           + " ,way.wh_description as note,user.user_name as username,way.wh_id as headerid,way.wh_userid as userid"
           + " from tbl_waying_header as way inner join tbl_user_details as user on way.wh_userid=user.user_id where sm_id='" + billno + "'";
        DataTable dtwaybill = db.SelectQuery(waybillingQry);
        List<dynamic> lstwaybill = new List<dynamic>();
        for (int i = 0; i < dtwaybill.Rows.Count; i++)
        {
            dynamic wayObj = new ExpandoObject();
            wayObj.id = dtwaybill.Rows[i]["orderid"];
            wayObj.date = dtwaybill.Rows[i]["date"];
            wayObj.headerid = dtwaybill.Rows[i]["headerid"];
            wayObj.note = dtwaybill.Rows[i]["note"];
            wayObj.username = dtwaybill.Rows[i]["username"];

            string qryWayItems = "SELECT `itm_code`, `itm_name`, `wi_stock` as stock"
                + " , wi.itbs_id as itemid "
                + " FROM `tbl_waying_items` as wi inner join tbl_sales_items as sales on wi.sm_id=sales.sm_id and wi.itbs_id=sales.itbs_id  WHERE wi.sm_id='" + billno + "' and wi.wh_id ='" + dtwaybill.Rows[i]["headerid"] + "'";
            DataTable dtWayItems = db.SelectQuery(qryWayItems);
            wayObj.items = dtWayItems;
            lstwaybill.Add(wayObj);
        }
        sb.Append(",");
        sb.Append("\"waybilling_details\":");
        sb.Append(JsonConvert.SerializeObject(lstwaybill, Formatting.Indented));
        //end done
        //fetching return details
        String retHeadQry = "SELECT `srm_id`, `sm_id`, DATE_FORMAT(`srm_date`, '%d-%b-%Y %h:%i %p') as date,`srm_amount` as amt "
            + " FROM `tbl_salesreturn_master` WHERE `sm_id`='" + dtOrder.Rows[0]["sm_refno"].ToString() + "'";
        DataTable dtRetHead = db.SelectQuery(retHeadQry);
        List<dynamic> lstReturn = new List<dynamic>();
        for (int i = 0; i < dtRetHead.Rows.Count; i++)
        {
            dynamic retObj = new ExpandoObject();
            retObj.id = dtRetHead.Rows[i]["srm_id"];
            retObj.date = dtRetHead.Rows[i]["date"];
            retObj.amount = dtRetHead.Rows[i]["amt"];
            string qryRetItems = "SELECT `itm_code`, `itm_name`, `si_price` as price"
                + " , `sri_qty` as qty, `sri_discount_amount` as discount, `sri_total` as total "
                + " FROM `tbl_salesreturn_items` WHERE srm_id='" + dtRetHead.Rows[i]["srm_id"] + "'";
            DataTable dtRetItems = db.SelectQuery(qryRetItems);
            retObj.items = dtRetItems;
            lstReturn.Add(retObj);
        }
        String statusQry = "SELECT  concat(app.first_name,' ',app.last_name) as approved_name," 
				+"concat(del.first_name,' ',del.last_name) as deliverd__name,"
				+"concat(canc.first_name,' ',canc.last_name) as canceld_name,"
				+"concat(sel.first_name,' ',sel.last_name) as sold_name,"
				+"concat(pro.first_name,' ',pro.last_name) as procesd_name,"
           		+"concat(veh.first_name,' ',veh.last_name) as vehicle_name,"
                +" tbl_sales_master.sm_vehicle_no,"
                + " DATE_FORMAT(tbl_sales_master.sm_date, '%d/%m/%Y %h:%i %p') as sm_sold_date,"
                +" DATE_FORMAT(tbl_sales_master.sm_processed_date, '%d/%m/%Y %h:%i %p') as sm_processed_date,"
                +" DATE_FORMAT(tbl_sales_master.sm_delivered_date, '%d/%m/%Y %h:%i %p') as sm_delivered_date, "
                +" DATE_FORMAT(tbl_sales_master.sm_cancelled_date, '%d/%m/%Y %h:%i %p') as sm_cancelled_date,"
                +" DATE_FORMAT(tbl_sales_master.sm_approved_date, '%d/%m/%Y %h:%i %p')  as sm_approved_date"
		        +" FROM  tbl_sales_master "
				+" LEFT OUTER JOIN tbl_user_details app ON tbl_sales_master.sm_approved_id = app.user_id "
				+" LEFT OUTER JOIN tbl_user_details AS del ON tbl_sales_master.sm_delivered_id = del.user_id "
				+" LEFT OUTER JOIN tbl_user_details AS canc ON tbl_sales_master.sm_cancelled_id = canc.user_id" 
				+" LEFT OUTER JOIN tbl_user_details AS pro ON tbl_sales_master.sm_processed_id = pro.user_id "
                +" LEFT OUTER JOIN tbl_user_details AS veh ON tbl_sales_master.sm_delivery_vehicle_id = veh.user_id "
				+" LEFT OUTER JOIN tbl_user_details AS sel ON tbl_sales_master.sm_userid = sel.user_id "
                + " where tbl_sales_master.sm_id='" + billno + "'";
        DataTable statusData = db.SelectQuery(statusQry);

        String approveQry = "select sm_id as 'order',oa_sales_id as 'sales_id',oa_account_id as 'account_id',oa_delivery_id as 'delivery_id',oa_sales_status as 'sales_status',oa_account_status as 'account_status',oa_delivery_status as 'delivery_status',DATE_FORMAT(`oa_sales_date`, '%Y-%m-%d') as 'salesDate',DATE_FORMAT(`oa_account_date`, '%Y-%m-%d') as 'accountDate',DATE_FORMAT(`oa_delivery_date`, '%Y-%m-%d') as 'deliveryDate',concat(tu.first_name,\" \",tu.last_name) as sales_head,concat(tu1.first_name,\" \",tu1.last_name) as account_head,concat(tu2.first_name,\" \",tu2.last_name) as delivery_head from tbl_order_approve ta left join tbl_user_details tu on tu.user_id=ta.oa_sales_id left join tbl_user_details tu1 on tu1.user_id=ta.oa_account_id left join tbl_user_details tu2 on tu2.user_id=ta.oa_delivery_id where sm_id=" + billno;
        DataTable approveData = db.SelectQuery(approveQry);
        sb.Append(",");
        sb.Append("\"statusdetails\":");
        sb.Append(JsonConvert.SerializeObject(statusData, Formatting.Indented));
        sb.Append(",");
        sb.Append("\"return_details\":");
        sb.Append(JsonConvert.SerializeObject(lstReturn, Formatting.Indented));
        sb.Append(",");
        sb.Append("\"approve_details\":");
        sb.Append(JsonConvert.SerializeObject(approveData, Formatting.Indented));
        sb.Append("}"); 

        return sb.ToString();
    }
    //Stop: Show Details of Selected  Bill...

    [WebMethod]
    public static string updateOrderStatus(Dictionary<string, string> order)
    {
        string result = "";
        mySqlConnection db = new mySqlConnection();
        try
        {
            db.BeginTransaction();
            TimeZoneInfo CurrentZone = TimeZoneInfo.FindSystemTimeZoneById(order["time_zone"]);
            DateTime TimeNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, CurrentZone);
            string action_date = DateTime.Parse(TimeNow.ToString()).ToString("yyyy-MM-dd HH:mm:ss");
            //start check for refreshment page
            string checkEntryChanged = "select count(sm_id) from tbl_sales_master where sm_last_updated_date=DATE_FORMAT('" + order["lastUpdatedDate"] + "','%Y-%m-%d %H:%i:%s') and sm_id=" + order["sm_id"];
            int changeCount = Convert.ToInt32(db.SelectScalarForTransaction(checkEntryChanged));
            if (changeCount == 0)
            {
                return "E";
            }

            //end check for refreshment page
            // checking the current status        
            string check_status_qry = "SELECT sm.sm_delivery_status,sm.cust_id,sm.sm_netamount,cu.cust_amount,sm.branch_id,cust_tax_reg_id FROM tbl_sales_master sm JOIN tbl_customer cu ON sm.cust_id=cu.cust_id WHERE sm.sm_id='" + order["sm_id"] + "'";
            DataTable dt_sm = db.SelectQueryForTransaction(check_status_qry);
            string registrtionNo = Convert.ToString(dt_sm.Rows[0]["cust_tax_reg_id"]);

            if (dt_sm.Rows[0]["sm_delivery_status"].ToString() == order["order_status"].ToString())
            {
                result = "SUCCESS";
                return result;
            }
            else
            {
                // previous status is cancelled & changing to new order or delivered
                // Increase Stock - insert to transaction - change status - update cust_amount with date
                if (dt_sm.Rows[0]["sm_delivery_status"].ToString() == "4" || dt_sm.Rows[0]["sm_delivery_status"].ToString() == "5")
                {
                   
                    string qry = "select itbs_id,si_qty,si_foc,si_itm_type,itm_type,itm_name from tbl_sales_items where sm_id='" + order["sm_id"] + "' and ( si_itm_type='0' or si_itm_type='2') and itm_type='1'";
                    DataTable dt = db.SelectQueryForTransaction(qry);
                    int numrows = dt.Rows.Count;
                    if (numrows > 0)
                    {
                        Int32 oldqty = 0;
                        Int32 oldfoc = 0;
                        Int32 oldtotoalqty = 0;
                        string olditbs = "";

                        StringBuilder can_sb_bulk_stkTrQry = new StringBuilder();
                        StringBuilder can_sb_bulk_items = new StringBuilder();
                        can_sb_bulk_stkTrQry.Append("INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`action_ref_id`,`user_id`,`narration`,`dr_qty`,`closing_stock`,`date`) VALUES ");

                        int i_c = 0;


                        string itbsidString = "";
                        string oldupstockQry = "UPDATE tbl_itembranch_stock SET itbs_stock=CASE itbs_id";
                        foreach (DataRow row in dt.Rows)
                        {
                            oldqty = Convert.ToInt32(row["si_qty"]);
                            oldfoc = Convert.ToInt32(row["si_foc"]);
                            oldtotoalqty = oldfoc + oldqty;
                            olditbs = Convert.ToString(row["itbs_id"]);
                            itbsidString = itbsidString + "," + olditbs;
                            oldupstockQry += " WHEN '" + olditbs + "' THEN itbs_stock - " + oldtotoalqty + "";

                            // stock transaction
                            can_sb_bulk_items.Append("('" + Convert.ToString(row["itbs_id"]) + "','" + ((int)Constants.ActionType.SALES) + "','" + order["sm_id"] + "','" + order["user_id"] + "'");
                            can_sb_bulk_items.Append(",'Status Change from Cancelled/Rejected. debited " + oldtotoalqty + " " + Convert.ToString(row["itm_name"]) + " in order #" + order["sm_id"] + "','" + oldtotoalqty + "'");
                            can_sb_bulk_items.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + Convert.ToString(row["itbs_id"]) + "')");
                            can_sb_bulk_items.Append(",'" + action_date + "')" + (i_c != numrows - 1 ? "," : ";"));
                            i_c = i_c + 1;
                        }

                        itbsidString = itbsidString.Trim().TrimStart(',');
                        oldupstockQry += " ELSE itbs_stock END ,itm_last_update_date='" + action_date + "' WHERE itbs_id IN (" + itbsidString + ")";
                        db.ExecuteQueryForTransaction(oldupstockQry);

                        if (can_sb_bulk_items.ToString() != "")
                        {
                            can_sb_bulk_stkTrQry.Append(can_sb_bulk_items.ToString());
                            db.ExecuteQueryForTransaction(can_sb_bulk_stkTrQry.ToString());
                        }

                    }

                    string update_sales_mstr = "";
                    string status_string = "";
                    if (order["order_status"].ToString() == "2")
                    {
                        update_sales_mstr = "UPDATE tbl_sales_master SET sm_delivery_status='2',sm_delivered_id='" + order["user_id"] + "',sm_delivered_date='" + action_date + "',sm_cancelled_id='0',sm_cancelled_date='0' where sm_id='" + order["sm_id"] + "'";
                        status_string = "Status change from Cancelled/Rejected to Delivered.";

                    }
                    else if (order["order_status"].ToString() == "0")
                    {
                        update_sales_mstr = "UPDATE tbl_sales_master SET sm_delivery_status='0',sm_delivered_id='0',sm_delivered_date='0',sm_cancelled_id='0',sm_cancelled_date='0',sm_packed_id='0',sm_packed_date='0',sm_packed='0' where sm_id='" + order["sm_id"] + "'";
                        status_string = "Status change from Cancelled/Rejected to New order";

                    }
                    else if (order["order_status"].ToString() == "3")
                    {
                        update_sales_mstr = "UPDATE tbl_sales_master SET sm_delivery_status='3',sm_delivered_id='0',sm_delivered_date='0',sm_cancelled_id='0',sm_cancelled_date='0',sm_packed_id='0',sm_packed_date='0',sm_packed='0' where sm_id='" + order["sm_id"] + "'";
                        status_string = "Status change from Cancelled/Rejected to To be confirmed ";

                    }
                    else
                    {

                    }
                    db.ExecuteQueryForTransaction(update_sales_mstr);

                    //inserts to transaction table
                    MySqlCommand cmdInsCr = new MySqlCommand();
                    cmdInsCr.CommandText = "INSERT INTO `tbl_transactions` " +
                        " (`action_type`, `action_ref_id`, `partner_id`,`partner_type`,`branch_id`, `user_id`, `narration`, `dr`,`date`,`is_reconciliation`,`closing_balance`)" +
                        " select @action_type, @action_ref_id, @partner_id,@partner_type,@branch_id, @user_id, @narration, @dr, @date,@is_reconciliation,(ifnull(sum(dr)-sum(cr),0)+@dr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type and branch_id=@branch_id  ";
                    cmdInsCr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.SALES);
                    cmdInsCr.Parameters.AddWithValue("@action_ref_id", order["sm_id"]);
                    cmdInsCr.Parameters.AddWithValue("@partner_id", dt_sm.Rows[0]["cust_id"].ToString());
                    cmdInsCr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.CUSTOMER);
                    cmdInsCr.Parameters.AddWithValue("@branch_id", dt_sm.Rows[0]["branch_id"].ToString());
                    cmdInsCr.Parameters.AddWithValue("@user_id", order["user_id"]);
                    cmdInsCr.Parameters.AddWithValue("@narration", status_string);
                    cmdInsCr.Parameters.AddWithValue("@dr", dt_sm.Rows[0]["sm_netamount"].ToString());
                    cmdInsCr.Parameters.AddWithValue("@date", action_date);
                    cmdInsCr.Parameters.AddWithValue("@is_reconciliation", "1");
                    db.ExecuteQueryForTransaction(cmdInsCr);

                    string update_tbl_customer = "UPDATE tbl_customer SET cust_last_updated_date='" + action_date + "',cust_amount=(select (sum(dr)-sum(cr)) from tbl_transactions where partner_id='" + dt_sm.Rows[0]["cust_id"].ToString() + "' and partner_type=" + (int)Constants.PartnerType.CUSTOMER + ") where cust_id=" + dt_sm.Rows[0]["cust_id"].ToString() + ";SELECT cust_amount FROM tbl_customer WHERE cust_id=" + dt_sm.Rows[0]["cust_id"].ToString() + "";
                    string cust_amount = db.SelectScalarForTransaction(update_tbl_customer);
                    result = "SUCCESS";
                  //  db.CommitTransaction();
                }
                else
                {
                    // ORDER CANCELLATION
                    if (order["order_status"].ToString() == "4")
                    {

                        string qry = "select itbs_id,si_qty,si_foc,si_itm_type,itm_type,itm_name from tbl_sales_items where sm_id='" + order["sm_id"] + "' and ( si_itm_type='0' or si_itm_type='2') and itm_type='1'";
                        DataTable dt = db.SelectQueryForTransaction(qry);
                        int numrows = dt.Rows.Count;
                        if (numrows > 0)
                        {
                            Int32 oldqty = 0;
                            Int32 oldfoc = 0;
                            Int32 oldtotoalqty = 0;
                            string olditbs = "";

                            StringBuilder can_sb_bulk_stkTrQry = new StringBuilder();
                            StringBuilder can_sb_bulk_items = new StringBuilder();
                            can_sb_bulk_stkTrQry.Append("INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`action_ref_id`,`user_id`,`narration`,`cr_qty`,`closing_stock`,`date`) VALUES ");

                            int i_c = 0;

                            string itbsidString = "";
                            string oldupstockQry = "UPDATE tbl_itembranch_stock SET itbs_stock=CASE itbs_id";
                            foreach (DataRow row in dt.Rows)
                            {
                                oldqty = Convert.ToInt32(row["si_qty"]);
                                oldfoc = Convert.ToInt32(row["si_foc"]);
                                oldtotoalqty = oldfoc + oldqty;
                                olditbs = Convert.ToString(row["itbs_id"]);
                                itbsidString = itbsidString + "," + olditbs;
                                oldupstockQry += " WHEN '" + olditbs + "' THEN itbs_stock + " + oldtotoalqty + "";

                                // stock transaction
                                can_sb_bulk_items.Append("('" + Convert.ToString(row["itbs_id"]) + "','" + ((int)Constants.ActionType.SALES) + "','" + order["sm_id"] + "','" + order["user_id"] + "'");
                                can_sb_bulk_items.Append(",'Order Cancelled! " + oldtotoalqty + " " + Convert.ToString(row["itm_name"]) + " in order #" + order["sm_id"] + "','" + oldtotoalqty + "'");
                                can_sb_bulk_items.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + Convert.ToString(row["itbs_id"]) + "')");
                                can_sb_bulk_items.Append(",'" + action_date + "')" + (i_c != numrows - 1 ? "," : ";"));
                                i_c = i_c + 1;
                            }

                            itbsidString = itbsidString.Trim().TrimStart(',');
                            oldupstockQry += " ELSE itbs_stock END ,itm_last_update_date='" + action_date + "' WHERE itbs_id IN (" + itbsidString + ")";
                            db.ExecuteQueryForTransaction(oldupstockQry);

                            if (can_sb_bulk_items.ToString() != "")
                            {
                                can_sb_bulk_stkTrQry.Append(can_sb_bulk_items.ToString());
                                db.ExecuteQueryForTransaction(can_sb_bulk_stkTrQry.ToString());
                            }

                        }

                        string update_sales_mstr = "";
                        string status_string = "Cancellation of order #" + order["sm_id"].ToString() + " worth " + dt_sm.Rows[0]["sm_netamount"].ToString() + "";

                        update_sales_mstr = "UPDATE tbl_sales_master SET sm_delivery_status='4',sm_cancelled_id='" + order["user_id"] + "',sm_cancelled_date='" + action_date + "',sm_packed='0',sm_packed_id='0',sm_packed_date='0',sm_delivered_id='0',sm_delivered_date='0',sm_processed_id='0',sm_delivery_vehicle_id='0',sm_vehicle_no='0' where sm_id='" + order["sm_id"] + "'";
                        db.ExecuteQueryForTransaction(update_sales_mstr);

                        //inserts to transaction table
                        MySqlCommand cmdInsCr = new MySqlCommand();
                        cmdInsCr.CommandText = "INSERT INTO `tbl_transactions` " +
                            " (`action_type`, `action_ref_id`, `partner_id`,`partner_type`,`branch_id`, `user_id`, `narration`, `cr`,  `date`,`is_reconciliation`,`closing_balance`)" +
                            " select @action_type, @action_ref_id, @partner_id,@partner_type,@branch_id, @user_id, @narration, @cr, @date,@is_reconciliation,(ifnull(sum(dr)-sum(cr),0)-@cr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type and branch_id=@branch_id  ";
                        cmdInsCr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.SALES);
                        cmdInsCr.Parameters.AddWithValue("@action_ref_id", order["sm_id"]);
                        cmdInsCr.Parameters.AddWithValue("@partner_id", dt_sm.Rows[0]["cust_id"].ToString());
                        cmdInsCr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.CUSTOMER);
                        cmdInsCr.Parameters.AddWithValue("@branch_id", dt_sm.Rows[0]["branch_id"].ToString());
                        cmdInsCr.Parameters.AddWithValue("@user_id", order["user_id"]);
                        cmdInsCr.Parameters.AddWithValue("@narration", status_string);
                        cmdInsCr.Parameters.AddWithValue("@cr", dt_sm.Rows[0]["sm_netamount"].ToString());
                        cmdInsCr.Parameters.AddWithValue("@date", action_date);
                        cmdInsCr.Parameters.AddWithValue("@is_reconciliation", "1");
                        db.ExecuteQueryForTransaction(cmdInsCr);

                        string update_tbl_customer = "UPDATE tbl_customer SET cust_last_updated_date='" + action_date + "',cust_amount=(select (sum(dr)-sum(cr)) from tbl_transactions where partner_id='" + dt_sm.Rows[0]["cust_id"].ToString() + "' and partner_type=" + (int)Constants.PartnerType.CUSTOMER + ") where cust_id=" + dt_sm.Rows[0]["cust_id"].ToString() + ";SELECT cust_amount FROM tbl_customer WHERE cust_id=" + dt_sm.Rows[0]["cust_id"].ToString() + "";
                        string cust_amount = db.SelectScalarForTransaction(update_tbl_customer);
                        result = "SUCCESS";

                      

                    }
                    else if (order["order_status"].ToString() == "2")
                    {
                        string update_sales_mstr = "";
                        update_sales_mstr = "UPDATE tbl_sales_master SET sm_delivery_status='2',sm_delivered_id='" + order["user_id"] + "',sm_delivered_date='" + action_date + "' where sm_id='" + order["sm_id"] + "'";
                        db.ExecuteQueryForTransaction(update_sales_mstr);
                        string update_tbl_customer = "SELECT cust_amount FROM tbl_customer WHERE cust_id=" + dt_sm.Rows[0]["cust_id"].ToString() + "";
                        string cust_amount = db.SelectScalarForTransaction(update_tbl_customer);
                        result = "SUCCESS";

                    }
                    else if (order["order_status"].ToString() == "1")
                    {
                        string processedDateTime = order["processedDate"] + " " + order["processedTime"];
                        string vehicle_qry = "";
                        if (order["vehicle_type"].ToString() == "1")
                        {
                            vehicle_qry = "sm_delivery_vehicle_id='" + order["vehicle_id"] + "'";
                        }
                        else
                        {
                            vehicle_qry = "sm_vehicle_no='" + order["vehicle_no"] + "'";
                        }


                        //start cod forcreate unique invoice number: done by deepika
                        //start check query for invoice number already exist
                        string checkInvoiceQry = "select sm_invoice_no from tbl_sales_master where sm_id=" + order["sm_id"];
                        DataTable checkDt = db.SelectQueryForTransaction(checkInvoiceQry);
                        if (checkDt.Rows[0]["sm_invoice_no"].ToString() == "")
                        {
                            string branchPrefix = "";
                            int branchStart = 0;
                            string branchSuffix = "";

                            string branchUnRegPrefix = "";
                            int branchUnRegStart = 0;
                            string branchUnRegSuffix = "";

                            string prefix = "";
                            int orderStart = 0;
                            string suffix = "";

                            string getTimeZone = "SELECT branch_timezone,branch_orderPrefix,branch_orderSerial,branch_orderSuffix,branch_unRegOrderPrefix,branch_unRegOrderSerial,branch_unRegOrderSuffix from tbl_branch where branch_id='" + dt_sm.Rows[0]["branch_id"] + "'";
                            DataTable cTimeZone = db.SelectQueryForTransaction(getTimeZone);

                            if (cTimeZone != null)
                            {
                                branchPrefix = Convert.ToString(cTimeZone.Rows[0]["branch_orderPrefix"]);
                                branchStart = Convert.ToInt32(cTimeZone.Rows[0]["branch_orderSerial"]);
                                branchSuffix = Convert.ToString(cTimeZone.Rows[0]["branch_orderSuffix"]);

                                branchUnRegPrefix = Convert.ToString(cTimeZone.Rows[0]["branch_unRegOrderPrefix"]);
                                branchUnRegStart = Convert.ToInt32(cTimeZone.Rows[0]["branch_unRegOrderSerial"]);
                                branchUnRegSuffix = Convert.ToString(cTimeZone.Rows[0]["branch_unRegOrderSuffix"]);
                            }


                            if (registrtionNo != "" && registrtionNo.ToString() != "null")
                            {
                                prefix = branchPrefix;
                                orderStart = branchStart;
                                suffix = branchSuffix;
                            }
                            else
                            {
                                if (branchUnRegPrefix != "")
                                {
                                    prefix = branchUnRegPrefix;
                                    orderStart = branchUnRegStart;
                                    suffix = branchUnRegSuffix;
                                }
                                else
                                {
                                    prefix = branchPrefix;
                                    orderStart = branchStart;
                                    suffix = branchSuffix;
                                }
                            }

                            string suffixQry = "SELECT IFNULL(max(sm_serialNo),0) FROM tbl_sales_master where branch_id=" + dt_sm.Rows[0]["branch_id"] + "  and sm_prefix='" + prefix + "' and sm_suffix='" + suffix + "'";
                            int invoiceSerialNo = Convert.ToInt32(db.SelectScalarForTransaction(suffixQry));
                            if (invoiceSerialNo == 0)
                            {
                                if (orderStart != null)
                                {
                                    invoiceSerialNo = orderStart + 1;
                                }
                            }
                            else
                            {
                                invoiceSerialNo = Math.Max(orderStart, invoiceSerialNo);
                                invoiceSerialNo = invoiceSerialNo + 1;
                            }
                            vehicle_qry += ",sm_prefix='" + prefix + "',sm_serialNo=" + invoiceSerialNo + ",sm_suffix='" + suffix + "',sm_invoice_no=concat(sm_prefix,sm_serialNo,sm_suffix),sm_processed_date='" + processedDateTime + "'";
                        }
                        else
                        {
                            vehicle_qry += ",sm_processed_date='" + processedDateTime + "'";
                        }
                                         
                        //end cod forcreate unique invoice number: done by deepika

                        string update_sales_mstr = "";
                        if (order["current_packing_status"].ToString() == "1")
                        {
                            update_sales_mstr = "UPDATE tbl_sales_master SET " + vehicle_qry + ",sm_processed_id='" + order["user_id"] + "',sm_delivery_status='1',sm_delivered_id='" + order["delivery_man"] + "',sm_delivered_date='0' where sm_id='" + order["sm_id"] + "'";
                        }
                        else
                        {
                            update_sales_mstr = "UPDATE tbl_sales_master SET " + vehicle_qry + ",sm_packed='1',sm_packed_id='" + order["user_id"] + "',sm_packed_date='" + action_date + "',sm_processed_id='" + order["user_id"] + "',sm_delivery_status='1',sm_delivered_id='" + order["delivery_man"] + "',sm_delivered_date='0' where sm_id='" + order["sm_id"] + "'";
                        }
                        db.ExecuteQueryForTransaction(update_sales_mstr);
                        result = "SUCCESS";
                    }
                    else if (order["order_status"].ToString() == "0")
                    {
                        string update_sales_mstr = "";
                        update_sales_mstr = "UPDATE tbl_sales_master SET sm_delivery_status='0',sm_delivered_id='0',sm_delivered_date='0',sm_cancelled_id='0',sm_cancelled_date='0',sm_processed_id='0',sm_packed_id='0',sm_packed_date='0',sm_packed='0' where sm_id='" + order["sm_id"] + "'";
                        db.ExecuteQueryForTransaction(update_sales_mstr);
                        string update_tbl_customer = "SELECT cust_amount FROM tbl_customer WHERE cust_id=" + dt_sm.Rows[0]["cust_id"].ToString() + "";
                        string cust_amount = db.SelectScalarForTransaction(update_tbl_customer);
                        result = "SUCCESS";

                    }
                    else if (order["order_status"].ToString() == "6")//pending
                    {
                        string update_sales_mstr = "";
                        update_sales_mstr = "UPDATE tbl_sales_master SET sm_delivery_status='6',sm_processed_id='" + order["user_id"] + "',sm_processed_date='" + action_date + "' where sm_id='" + order["sm_id"] + "'";
                        db.ExecuteQueryForTransaction(update_sales_mstr);
                        result = "SUCCESS";
                       // return result;
                    }
                    else if (order["order_status"].ToString() == "7")//approve order
                    {
                        string update_sales_mstr = "";
                        update_sales_mstr = "UPDATE tbl_sales_master SET sm_delivery_status='0',sm_approved_id='" + order["user_id"] + "',sm_approved_date='" + action_date + "' WHERE sm_id='" + order["sm_id"] + "'";
                        db.ExecuteQueryForTransaction(update_sales_mstr);
                        result = "SUCCESS";
                       // return result;
                    }
                    else if (order["order_status"].ToString() == "5")//reject order
                    {

                       // db.BeginTransaction();

                        string update_sales_mstr = "";
                        update_sales_mstr = "UPDATE tbl_sales_master SET sm_delivery_status='5',sm_approved_id='" + order["user_id"] + "',sm_approved_date='" + action_date + "' WHERE sm_id='" + order["sm_id"] + "'";
                        db.ExecuteQueryForTransaction(update_sales_mstr);

                        string qry = "select itbs_id,si_qty,si_foc,si_itm_type,itm_type,itm_name from tbl_sales_items where sm_id='" + order["sm_id"] + "' and ( si_itm_type='0' or si_itm_type='2') and itm_type='1'";
                        DataTable dt = db.SelectQueryForTransaction(qry);
                        int numrows = dt.Rows.Count;
                        if (numrows > 0)
                        {
                            Int32 oldqty = 0;
                            Int32 oldfoc = 0;
                            Int32 oldtotoalqty = 0;
                            string olditbs = "";

                            StringBuilder can_sb_bulk_stkTrQry = new StringBuilder();
                            StringBuilder can_sb_bulk_items = new StringBuilder();
                            can_sb_bulk_stkTrQry.Append("INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`action_ref_id`,`user_id`,`narration`,`cr_qty`,`closing_stock`,`date`) VALUES ");

                            int i_c = 0;


                            string itbsidString = "";
                            string oldupstockQry = "UPDATE tbl_itembranch_stock SET itbs_stock=CASE itbs_id";
                            foreach (DataRow row in dt.Rows)
                            {
                                oldqty = Convert.ToInt32(row["si_qty"]);
                                oldfoc = Convert.ToInt32(row["si_foc"]);
                                oldtotoalqty = oldfoc + oldqty;
                                olditbs = Convert.ToString(row["itbs_id"]);
                                itbsidString = itbsidString + "," + olditbs;
                                oldupstockQry += " WHEN '" + olditbs + "' THEN itbs_stock + " + oldtotoalqty + "";

                                // stock transaction
                                can_sb_bulk_items.Append("('" + Convert.ToString(row["itbs_id"]) + "','" + ((int)Constants.ActionType.SALES) + "','" + order["sm_id"] + "','" + order["user_id"] + "'");
                                can_sb_bulk_items.Append(",'Credited " + oldtotoalqty + " of " + Convert.ToString(row["itm_name"]) + " in order #" + order["sm_id"] + " : Reason-Order rejected','" + oldtotoalqty + "'");
                                can_sb_bulk_items.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + Convert.ToString(row["itbs_id"]) + "')");
                                can_sb_bulk_items.Append(",'" + action_date + "')" + (i_c != numrows - 1 ? "," : ";"));
                                i_c = i_c + 1;
                            }

                            itbsidString = itbsidString.Trim().TrimStart(',');
                            oldupstockQry += " ELSE itbs_stock END ,itm_last_update_date='" + action_date + "' WHERE itbs_id IN (" + itbsidString + ")";
                            db.ExecuteQueryForTransaction(oldupstockQry);

                            if (can_sb_bulk_items.ToString() != "")
                            {
                                can_sb_bulk_stkTrQry.Append(can_sb_bulk_items.ToString());
                                db.ExecuteQueryForTransaction(can_sb_bulk_stkTrQry.ToString());
                            }

                        }

                        string status_string = "Rejection of order #" + order["sm_id"] + " worth " + dt_sm.Rows[0]["sm_netamount"].ToString() + "";

                        //inserts to transaction table
                        MySqlCommand cmdInsCr = new MySqlCommand();
                        cmdInsCr.CommandText = "INSERT INTO `tbl_transactions` " +
                            " (`action_type`, `action_ref_id`, `partner_id`,`partner_type`,`branch_id`, `user_id`, `narration`, `cr`,  `date`,`is_reconciliation`,`closing_balance`)" +
                            " select @action_type, @action_ref_id, @partner_id,@partner_type,@branch_id, @user_id, @narration, @cr, @date,@is_reconciliation,(ifnull(sum(dr)-sum(cr),0)-@cr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type and branch_id=@branch_id  ";
                        cmdInsCr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.SALES);
                        cmdInsCr.Parameters.AddWithValue("@action_ref_id", order["sm_id"]);
                        cmdInsCr.Parameters.AddWithValue("@partner_id", dt_sm.Rows[0]["cust_id"].ToString());
                        cmdInsCr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.CUSTOMER);
                        cmdInsCr.Parameters.AddWithValue("@branch_id", dt_sm.Rows[0]["branch_id"].ToString());
                        cmdInsCr.Parameters.AddWithValue("@user_id", order["user_id"]);
                        cmdInsCr.Parameters.AddWithValue("@narration", status_string);
                        cmdInsCr.Parameters.AddWithValue("@cr", dt_sm.Rows[0]["sm_netamount"].ToString());
                        cmdInsCr.Parameters.AddWithValue("@date", action_date);
                        cmdInsCr.Parameters.AddWithValue("@is_reconciliation", "1");
                        db.ExecuteQueryForTransaction(cmdInsCr);

                        string update_tbl_customer = "UPDATE tbl_customer SET cust_last_updated_date='" + action_date + "',cust_amount=(select (sum(dr)-sum(cr)) from tbl_transactions where partner_id='" + dt_sm.Rows[0]["cust_id"].ToString() + "' and partner_type=" + (int)Constants.PartnerType.CUSTOMER + ") where cust_id=" + dt_sm.Rows[0]["cust_id"].ToString() + ";SELECT cust_amount FROM tbl_customer WHERE cust_id=" + dt_sm.Rows[0]["cust_id"].ToString() + "";
                        string cust_amount = db.SelectScalarForTransaction(update_tbl_customer);
                        
                    }

                }
            }
            db.ExecuteQueryForTransaction("UPDATE tbl_sales_master SET sm_last_updated_date='" + action_date + "' where sm_id =" + order["sm_id"]);
            db.ExecuteQueryForTransaction("update tbl_transactions set last_updated_date='" + action_date + "' where action_type=1 and action_ref_id=" + order["sm_id"] + "");
            db.CommitTransaction();
            result = "SUCCESS";
           
        }
        catch (Exception ex)
        {
            db.RollBackTransaction();
            result = "FAILED";
            LogClass log_cust = new LogClass("order_cancellation_error");
            log_cust.write(ex);
            return result;

        }

        return result;

    }

    [WebMethod]// users show
    public static string loadAssignPersons(string warehouse)
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        //string query = "SELECT Id, Name,CountryId FROM Branch ORDER BY Name ASC";
        string query = "select user_id,concat(first_name,\" \",last_name) as name from tbl_user_details where user_type IN ('2','3')";
        //    query = query + " order by tbl_branch.branch_id";
        dt = db.SelectQuery(query);
        return JsonConvert.SerializeObject(dt, Formatting.Indented);
    }//end

    [WebMethod]// branches show
    public static string loadBranches()
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        //string query = "SELECT Id, Name,CountryId FROM Branch ORDER BY Name ASC";
       // string query = "select branch_id,branch_name from tbl_branch";
        string query = "select tb.branch_id,branch_name from tbl_branch tb inner join tbl_user_branches ub on ub.branch_id=tb.branch_id where user_id=" + HttpContext.Current.Request.Cookies["invntrystaffId"].Value;
        //    query = query + " order by tbl_branch.branch_id";
        dt = db.SelectQuery(query);
        return JsonConvert.SerializeObject(dt, Formatting.Indented);
    }//end

    //start: Enable/Disable Buttons in  page
    [WebMethod]
    public static string showUserButtons(string userTypeId)
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dtButtons,dt = new DataTable();
        StringBuilder sb = new StringBuilder();
        Int32 disableButtonCount = 0;

        string btnQry = "select ub_id,ub_button_id FROM tbl_user_buttons WHERE page_id='9' ";
        dtButtons = db.SelectQuery(btnQry);
        if (dtButtons != null)
        {
            if (dtButtons.Rows.Count > 0)
            {
                if (dtButtons.Rows[0]["ub_button_id"] is DBNull)
                {
                }
                else
                {
                    for (int i = 0; i < dtButtons.Rows.Count; i++)
                    {
                        string query = "SELECT count(*) FROM tbl_button_permission WHERE user_type='" + userTypeId + "' and ub_id='" + dtButtons.Rows[i]["ub_id"] + "' and page_id='9' ";
                        Int32 qryCount = Convert.ToInt32(db.SelectScalar(query));
                        if (qryCount == 0)
                        {
                            sb.Append(dtButtons.Rows[i]["ub_button_id"] + "@#$");
                            disableButtonCount++;
                        }
                        else
                        {
                        }
                    }
                }
            }
        }

        return disableButtonCount + "@#$" + sb.ToString();
    }
    //stop: Enable/Disable Buttons in  page

    [WebMethod]// users show
    public static string loadVehicles()
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        //string query = "SELECT Id, Name,CountryId FROM Branch ORDER BY Name ASC";
        string query = "select user_id,concat(first_name,\" \",last_name) as name from tbl_user_details where user_type IN ('6')";
        //    query = query + " order by tbl_branch.branch_id";
        dt = db.SelectQuery(query);
        return JsonConvert.SerializeObject(dt, Formatting.Indented);
    }//end

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
					", `cr`, `date`,`voucher_no`,`po_number`,`closing_balance`)" +
                    " select @session_id, @action_type, @action_ref_id, @partner_id,@partner_type,@branch_id, @user_id, @narration,@cash_amt,@wallet_amt" +
                    (Convert.ToDouble(filters["ChequeAmount"]) != 0 ? ", @cheque_amt, @cheque_no, @cheque_date, @cheque_bank" : "") +
                    (Convert.ToDouble(filters["CardAmount"]) != 0 ? ", @card_amt, @card_no" : "") +
					", @cr, STR_TO_DATE(CONCAT('" + filters["transDate"] + "', ' ', DATE_FORMAT('"+ currdatetime +"', '%H:%i:%s')), '%Y-%m-%d %H:%i:%s'), @voucher_no, @po_number,(ifnull(sum(dr)-sum(cr),0)-@cr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type and branch_id=@branch_id ";
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
				cmdInsCr.Parameters.AddWithValue("@voucher_no", filters["voucher_no"]);
				cmdInsCr.Parameters.AddWithValue("@po_number", filters["po_number"]);
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
                //cmdInsCr.Parameters.AddWithValue("@date", currdatetime);
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


    [WebMethod]// users show
    public static string load_payment_edits(string sm_id)
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        
        string query = @"SELECT pe.transaction_id,CONCAT(ud.first_name,' ',ud.last_name)  AS username,pe.ref_id,DATE_FORMAT(pe.tpe_date,'%d %M %Y %H:%i:%s') AS tpe_date ,pe.tpe_prev_cashamt,pe.tpe_new_cashamt,pe.tpe_prev_chequeamt,pe.tpe_new_chequeamt,pe.tpe_prev_walletamt,pe.tpe_new_walletamt 
FROM tbl_payment_edits pe
INNER JOIN tbl_user_details ud ON ud.user_id = pe.user_id
WHERE pe.edit_type = 1 AND pe.ref_id = '"+ sm_id +"'";
        //    query = query + " order by tbl_branch.branch_id";
        dt = db.SelectQuery(query);
        if (dt.Rows.Count > 0)
        {
            return JsonConvert.SerializeObject(dt, Formatting.Indented);
        }
        else
        {
            return "N";
        }
    }//end

    [WebMethod]
    public static string DownloadXMLFile(string order_id)
    {
        string result = "N";
        mySqlConnection db = new mySqlConnection();

        try
        {

            // filters["order_id"]

            // 1. Fetching the Order Headers
            var query = @"SELECT sm.sm_id,sm.sm_invoice_no,DATE_FORMAT(sm.sm_processed_date, '%Y%m%d') as n_date,DATE_FORMAT(sm.sm_processed_date, '%d-%b-%Y at %H:%i') as f_date,REPLACE( cu.cust_name, '&', '&amp;' ) as cust_name,REPLACE( cu.cust_address, '&', '&amp;' ) as cust_address,REPLACE( cu.cust_city, '&', '&amp;' ) as cust_city,CONCAT (cu.max_creditperiod,' Days') AS max_creditperiod,
pm.tpm_name,s1.state_name AS cust_state,s2.state_name AS ord_state, CONCAT(ud.first_name,' ',ud.last_name) AS username,sm.sm_roundoff,sm.sm_netamount,sm.sm_tax_amount   
FROM tbl_sales_master sm 
INNER JOIN tbl_customer cu ON cu.cust_id=sm.cust_id 
INNER JOIN tbl_branch br ON br.branch_id=sm.branch_id 
INNER JOIN tbl_user_details ud ON ud.user_id=sm.sm_userid 
INNER JOIN tbl_price_master pm ON pm.tpm_id=sm.sm_price_class 
LEFT OUTER JOIN tbl_state s1 ON s1.state_id=cu.cust_state 
LEFT OUTER JOIN tbl_state s2 ON s2.state_id=br.branch_state_id WHERE sm.sm_id=" + order_id + " ";

            var head_dt = db.SelectQuery(query);

            var item_qry = @"SELECT si.sm_id,si.itm_name,si.si_price,(si.si_qty + si.si_foc) AS actual_qty, si.si_qty AS billed_qty,(si.si_net_amount-si.si_tax_amount) as si_net_amount,si.si_item_tax,si.si_item_cgst,si.si_item_sgst,si.si_item_igst,si.si_item_cess FROM tbl_sales_items si
INNER JOIN tbl_sales_master sm ON sm.sm_id = si.sm_id WHERE sm.sm_id=" + order_id + " ";

            if (head_dt.Rows.Count == 0)
            {
                return "N"; ;
            }
            else
            {
                HttpContext.Current.Session["header_xml_qry"] = query;
                HttpContext.Current.Session["item_xml_qry"] = item_qry;
                return "Y";
            }

        }
        catch (Exception ex)
        {
            //db.RollBackTransaction();
            var log = new LogClass("DownloadXMLFile");
            log.write(ex);
            result = "N";
            return result;
        }


    }

}