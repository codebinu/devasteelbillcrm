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
using MySql.Data.MySqlClient;
using System.Collections;
public partial class web_purchase_editPurchase : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication purchase = new LoginAuthentication();
        purchase.userAuthentication();
        purchase.checkPageAcess(6);
    }

    [WebMethod(EnableSession = true)]
    public static string GetAutoCompleteItemData(string variable)
    {
        StringBuilder sb = new StringBuilder();
        //List<string> custNames = new List<string>();
        mySqlConnection db = new mySqlConnection();
        string sqlQuery = "SELECT itm_name,itm_id from tbl_item_master where 1 and itm_name like '%" + variable + "%' ";
        DataTable QryTable = db.SelectQuery(sqlQuery);
        if (QryTable.Rows.Count > 0)
        {
            sb.Append("[");
            foreach (DataRow row in QryTable.Rows)
            {
                sb.Append("{\"id\":\"" + Convert.ToString(row["itm_id"]) + "\",");
                sb.Append("\"label\":\"" + Convert.ToString(row["itm_name"]) + "\",");
                sb.Append("\"value\":\"" + Convert.ToString(row["itm_name"]) + "\"}");

                //sb.Append("'name':'" + Convert.ToString(row["cust_name"]) + "'}");
                sb.Append(",");
            }
            sb.Remove(sb.Length - 1, 1);
            sb.Append("]");
        }
        else
        {
            sb.Append("N");
        }


        //var a = "[{\"label\":\"Avacado Supermarket\",\"value\":\"2\"}]";
        return sb.ToString();

    }

    [WebMethod]
    public static string retrieveData(string purchaseId)
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dtItems = new DataTable();
        DataTable dtOrder = new DataTable();
        StringBuilder sb = new StringBuilder();
        sb.Append("{");
        string selectvar2 = "";
        string qry = "";
        selectvar2 = selectvar2 + " row_no, ibs.itm_code,";
        selectvar2 = selectvar2 + " ibs.itm_name ,pi.itbs_id as itm_id, pi_qty, pi_price,pi_total, pi_discount_rate, pi_discount_amount, pi_net_amount,pi_tax_amount,pi_id,pi_tax_excluded_total,pi_item_tax,pi_item_cess ";
        qry = "select " + selectvar2 + " from tbl_purchase_items pi inner join tbl_itembranch_stock ibs on ibs.itbs_id=pi.itbs_id  where pm_id='" + purchaseId + "' order by row_no";
        dtItems = db.SelectQuery(qry);
        sb.Append("\"items\":");
        sb.Append(JsonConvert.SerializeObject(dtItems, Formatting.Indented));
        sb.Append(",");
        string previouspaidqry = "select tv.vn_name,pm.vn_id,vn_balance,branch_name,pm_invoice_no,concat(tu.first_name,' ',tu.last_name) as user,"
        +" pm_netamount as net_amount,sum(cr)-sum(dr) as pm_balance,pm_netamount-(sum(cr)-sum(dr)) as pm_paidamount,"
        +" pm_tax_amount as tax_amount,pm_ref_no,DATE_FORMAT(pm_date,'%Y-%m-%d') AS date,pm_note,"
        + " pm_total,pm_discount_rate,pm_discount_amount,pm_roundoff as roundOff,pm.branch_id,pm.branch_tax_method,pm_tax_excluded_amt,pm.branch_tax_inclusive"
        +" from tbl_purchase_master pm inner join tbl_vendor tv on tv.vn_id=pm.vn_id"
        + " inner join tbl_user_details tu on tu.user_id=pm.pm_userid"
        +" inner join tbl_branch tb on tb.branch_id=pm.branch_id inner join tbl_transactions tr"
        +" on (tr.action_ref_id=pm.pm_id and tr.action_type=" + (int)Constants.ActionType.PURCHASE + ")"
        +" where pm_id='" + purchaseId + "' ";
        dtOrder = db.SelectQuery(previouspaidqry);
        sb.Append("\"entry\":");
        sb.Append(JsonConvert.SerializeObject(dtOrder, Formatting.Indented));
        String paymentQry = "select tr.id,DATE_FORMAT(`date`, '%d-%b-%Y %h:%i %p') as date,narration,concat(tu.first_name,' ',tu.last_name) as user_name,cash_amt,card_amt,card_no,cheque_amt,cheque_no,"
        + " cheque_bank,DATE_FORMAT(`cheque_date`, '%d-%m-%Y') as cheque_date,wallet_amt,dr,cr,is_reconciliation from tbl_transactions tr "
        + " inner join tbl_user_details tu on tu.user_id=tr.user_id "
        + " where action_ref_id='" + purchaseId + "' and action_type=" + (int)Constants.ActionType.PURCHASE;

        DataTable dtPay = db.SelectQuery(paymentQry);
        sb.Append(",");
        sb.Append("\"transaction_details\":");
        sb.Append(JsonConvert.SerializeObject(dtPay, Formatting.Indented));
        sb.Append("}");

        return sb.ToString();
    }


    [WebMethod]
    public static string searchOrderitems(int page, Dictionary<string, string> filters, int perpage)
    {

        // string outputval = "okkkkkkkkkkk";


        try
        {

            string query_condition = " where 1=1 ";
            if (filters.Count > 0)
            {
                if (filters.ContainsKey("itemname"))
                {
                    query_condition += " and tim.itm_name  LIKE '%" + filters["itemname"] + "%'";
                }
                if (filters.ContainsKey("itemcode"))
                {
                    query_condition += " and tim.itm_code  LIKE '%" + filters["itemcode"] + "%'";
                }
            }
            int per_page = perpage;
            int offset = (page - 1) * per_page;
            mySqlConnection db = new mySqlConnection();
            string innerqry = "";
            string countQry = "SELECT count(*) FROM tbl_item_master tim " + query_condition;
            double numrows = Convert.ToInt32(db.SelectScalar(countQry));
            if (numrows == 0)
            {
                return "N";
            }
            int total_pages = Convert.ToInt32(Math.Ceiling(numrows / per_page));

            innerqry = "SELECT tim.itm_id,tim.itm_code,tim.itm_name,IFNULL(itbs_stock,0) as stock,IFNULL(itbs_id,0) as itbsId from tbl_item_master tim left join tbl_itembranch_stock tis on tis.itm_id=tim.itm_id and branch_id=" + filters["warehouse"] + " ";
            innerqry = innerqry + query_condition + "   order by itm_id LIMIT " + offset.ToString() + " ," + per_page;
            DataTable dt = db.SelectQuery(innerqry);
            string jsonResponse = "";
            if (dt.Rows.Count > 0)
            {
                string jsonData = JsonConvert.SerializeObject(dt, Formatting.Indented);
                jsonResponse = "{\"count\":\"" + numrows + "\",\"data\":" + jsonData + "}";
            }
            else
            {
                jsonResponse = "N";
            }
            //if (numrows > per_page)
            //{
            //    Pagination pg1 = new Pagination();
            //    sb.Append(pg1.paginateGCSearch(page, total_pages, adjacents));

            //}

            //return sb.ToString();
            return jsonResponse;

        }
        catch (Exception ex)
        {
            return ex.ToString();
        }
    }

    [WebMethod]
    public static string updatePurchaseEntry(Dictionary<string, string> filters, string tableString)
    {
        string checkstatus = "N";
        mySqlConnection db = new mySqlConnection();
        try
        {

            DataTable itemsBefrEditDt, dt1 = new DataTable();
            TimeZoneInfo CurrentZone = TimeZoneInfo.FindSystemTimeZoneById(filters["TimeZone"]);
            DateTime TimeNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, CurrentZone);
            string currdatetime = TimeNow.ToString("yyyy/MM/dd HH:mm:ss");
            //  string jsonData = JsonConvert.SerializeObject(tableString);
            dynamic Itemsdata = JsonConvert.DeserializeObject(tableString);

            //store old purchased items data to itemsbefrEditDt
            string selectPurchaseItemQuery = "select pi.itbs_id,pi_qty,itm_name,pm_netamount as old_netamount,pi_id as purchaseItemId from tbl_purchase_items pi inner join tbl_purchase_master pm on pm.pm_id=pi.pm_id inner join tbl_itembranch_stock ibs on ibs.itbs_id=pi.itbs_id where pi.pm_id=" + filters["purchaseId"];
            itemsBefrEditDt = db.SelectQuery(selectPurchaseItemQuery);
            double old_netamount = Convert.ToDouble(itemsBefrEditDt.Rows[0]["old_netamount"]);
            

            db.BeginTransaction();
            Int32 oldqty = 0;
            Int32 oldtotoalqty = 0;
            string olditbs = "";
            string oldUniqueItemId = "";
            string itbsidString = "";
           

            foreach (DataRow row in itemsBefrEditDt.Rows)
            {
                oldqty = Convert.ToInt32(row["pi_qty"]);
                olditbs = Convert.ToString(row["itbs_id"]);
                itbsidString = itbsidString + "," + olditbs;
                oldUniqueItemId = Convert.ToString(row["purchaseItemId"]);
                db.ExecuteQueryForTransaction("UPDATE tbl_itembranch_stock SET itbs_stock=itbs_stock - " + oldqty + " where itbs_id=" + olditbs);
               
            }
 

            string deleteItemsQry = "delete from tbl_purchase_items where pm_id=" + filters["purchaseId"];
            if (db.ExecuteQueryForTransaction(deleteItemsQry))
            {
                string updatePurchaseMasterQry = "UPDATE tbl_purchase_master set ";
                updatePurchaseMasterQry = updatePurchaseMasterQry + "pm_userid = '" + filters["userid"] + "',pm_date = '" + currdatetime + "',pm_total = '" + filters["TotalAmount"] + "',pm_invoice_no = '" + filters["invoicenum"] + "', ";
                updatePurchaseMasterQry = updatePurchaseMasterQry + "pm_discount_rate  ='" + filters["TotalDiscountRate"] + "',pm_discount_amount  ='" + filters["TotalDiscountAmount"] + "', ";
                updatePurchaseMasterQry = updatePurchaseMasterQry + "pm_netamount  ='" + filters["TotalNetAmount"] + "',pm_tax_amount  ='" + filters["totalTaxamt"] + "' ";
                updatePurchaseMasterQry = updatePurchaseMasterQry + " WHERE pm_id= '" + filters["purchaseId"] + "' ";
                if (db.ExecuteQueryForTransaction(updatePurchaseMasterQry))
                {
                    string qry1 = "INSERT INTO tbl_purchase_items (pm_id,row_no,itbs_id,pi_price,pi_qty,pi_total,pi_discount_rate,pi_discount_amt,pi_netamount,pi_carton_count,pi_item_per_carton,pi_tax_amount)";
                    qry1 = qry1 + "VALUES ";
                    int row = 0;
                    foreach (var item in Itemsdata)
                    {
                        string qry_main = qry1 + "('" + filters["purchaseId"] + "'," + row + ",'" + item.itbs_id + "', '" + item.purchasePrice + "', '" + item.quantity + "',";
                        qry_main = qry_main + "'" + item.amount + "','" + item.dispercent + "','" + item.disamount + "','" + item.netamount + "',0,0,'" + item.taxamt + "')";
                        string purchaseMaintainStatus = db.SelectScalarForTransaction("select itbs_purchase_status from tbl_itembranch_stock tis where itbs_id=" + item.itbs_id + "");
                        if (purchaseMaintainStatus == "1")
                        {
                            var purchaseprice = Convert.ToDouble(item.netamount) / Convert.ToDouble(item.quantity);
                            db.ExecuteQueryForTransaction("update tbl_itembranch_stock set itbs_purchase_price=" + purchaseprice + " where itbs_id=" + item.itbs_id);
                        }
                        if (db.ExecuteQueryForTransaction(qry_main))
                        {
                            string upstockQry = "UPDATE tbl_itembranch_stock SET itbs_stock=(itbs_stock + " + item.quantity + ") where itbs_id='" + item.itbs_id + "'";
                            bool upstockresult = db.ExecuteQueryForTransaction(upstockQry);
                        }

                        row = row + 1;
                    }

                    //start stock transaction update
                    StringBuilder sb_bulk_stkTrQry = new StringBuilder();
                    bool isStockChanged = false;
                    sb_bulk_stkTrQry.Append("INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`action_ref_id`,`user_id`,`narration`,`dr_qty`,`cr_qty`,`closing_stock`,`date`,`is_reconciliation`) VALUES ");
                    foreach (DataRow itemrow in itemsBefrEditDt.Rows)
                    {
                        oldqty = Convert.ToInt32(itemrow["pi_qty"]);
                        olditbs = Convert.ToString(itemrow["itbs_id"]);
                        oldUniqueItemId = Convert.ToString(itemrow["purchaseItemId"]);

                        dynamic itemAftrEdit = ((IEnumerable)Itemsdata).Cast<dynamic>().Where(a => a.purchaseItemId == oldUniqueItemId).FirstOrDefault();
                        //checking if item deleted

                        if (itemAftrEdit == null)
                        {
                            //crediting if deleted
                            sb_bulk_stkTrQry.Append("('" + olditbs + "','" + ((int)Constants.ActionType.PURCHASE) + "','" + filters["purchaseId"] + "','" + filters["userid"] + "'");
                            sb_bulk_stkTrQry.Append(",'Debiting " + itemrow["itm_name"] + " of quantity " + oldqty + " back on delete from purchase entry #" + filters["purchaseId"] + "','" + oldqty + "','0'");
                            sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + olditbs + "')");
                            sb_bulk_stkTrQry.Append(",'" + currdatetime + "','1'),");
                            isStockChanged = true;
                        }
                        else
                        {
                            //recording change in quantity
                            int newTotalQty = Convert.ToInt32(itemAftrEdit.quantity);
                           
                            if (oldqty > newTotalQty)
                            {
                                sb_bulk_stkTrQry.Append("('" + olditbs + "','" + ((int)Constants.ActionType.PURCHASE) + "','" + filters["purchaseId"] + "','" + filters["userid"] + "'");
                                sb_bulk_stkTrQry.Append(",'Debiting " + itemrow["itm_name"] + " of quantity " + (oldqty - newTotalQty) + " back on edit of entry #" + filters["purchaseId"] + "','" + (oldqty - newTotalQty) + "','0'");
                                sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + olditbs + "')");
                                sb_bulk_stkTrQry.Append(",'" + currdatetime + "','1'),");
                                isStockChanged = true;
                            }
                            else if (oldqty < newTotalQty)
                            {
                                sb_bulk_stkTrQry.Append("('" + olditbs + "','" + ((int)Constants.ActionType.PURCHASE) + "','" + filters["purchaseId"] + "','" + filters["userid"] + "'");
                                sb_bulk_stkTrQry.Append(",'Crediting " + itemrow["itm_name"] + " of quantity " + (newTotalQty - oldqty) + " on edit of order #" + filters["purchaseId"] + "','0','" + (newTotalQty - oldqty) + "'");
                                sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + olditbs + "')");
                                sb_bulk_stkTrQry.Append(",'" + currdatetime + "','1'),");
                                isStockChanged = true;
                            }

                        }


                    }
                    // crediting new items
                    dynamic newItemsList = ((IEnumerable)Itemsdata).Cast<dynamic>()
                        .Where(a =>
                        !itemsBefrEditDt.AsEnumerable().Any(b =>
                            b.Field<int>("itbs_id") == Convert.ToInt32(a.itbs_id))
                        ).ToList();
                    foreach (var item in newItemsList)
                    {
                        int newTotalQty = Convert.ToInt32(item.quantity);
                        sb_bulk_stkTrQry.Append("('" + item.itbs_id + "','" + ((int)Constants.ActionType.PURCHASE) + "','" + filters["purchaseId"] + "','" + filters["userid"] + "'");
                        sb_bulk_stkTrQry.Append(",CONCAT('Purchased " + newTotalQty + "', (select itm_name from tbl_itembranch_stock where itbs_id='" + item.itbs_id + "'),' in entry #" + filters["purchaseId"] + "'),'0','" + newTotalQty + "'");
                        sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + item.itbs_id + "')");
                        sb_bulk_stkTrQry.Append(",'" + currdatetime + "','0'),");
                        isStockChanged = true; 
                    }
                    //end stock transaction update


                    // bulk insert stock transactions
                    if (isStockChanged)
                    {
                        sb_bulk_stkTrQry.Length--;
                        db.ExecuteQueryForTransaction(sb_bulk_stkTrQry.ToString());

                    }



                    //start updation in transactions
                    if (Convert.ToDouble(filters["TotalNetAmount"]) > old_netamount)
                    {
                        //inserting order debit entry
                        MySqlCommand cmdInsCr = new MySqlCommand();
                        cmdInsCr.CommandText = "INSERT INTO `tbl_transactions` " +
                            " ( `action_type`, `action_ref_id`, `partner_id`,`partner_type`, `user_id`, `narration`, `cr`,  `date`,`is_reconciliation`,`closing_balance`)" +
                            " select @action_type, @action_ref_id, @partner_id,@partner_type, @user_id, @narration, @cr, @date, @is_reconciliation,(ifnull(sum(dr)-sum(cr),0)-@cr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type ";

                        cmdInsCr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.PURCHASE);
                        cmdInsCr.Parameters.AddWithValue("@action_ref_id", filters["purchaseId"]);
                        cmdInsCr.Parameters.AddWithValue("@partner_id", filters["vendorId"]);
                        cmdInsCr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.VENDOR);
                        cmdInsCr.Parameters.AddWithValue("@user_id", filters["userid"]);
                        cmdInsCr.Parameters.AddWithValue("@narration", "Reconciliation of Purchase entry #" + filters["invoicenum"] + " after an edit by crediting the amount " + (Convert.ToDouble(filters["TotalNetAmount"]) - old_netamount));
                        cmdInsCr.Parameters.AddWithValue("@cr", (Convert.ToDouble(filters["TotalNetAmount"]) - old_netamount));
                        cmdInsCr.Parameters.AddWithValue("@date", currdatetime);
                        cmdInsCr.Parameters.AddWithValue("@is_reconciliation", "1");
                        db.ExecuteQueryForTransaction(cmdInsCr);

                    }
                    else if (Convert.ToDouble(filters["TotalNetAmount"]) < old_netamount)
                    {
                        //inserting order credit entry
                        MySqlCommand cmdInsDr = new MySqlCommand();
                        cmdInsDr.CommandText = "INSERT INTO `tbl_transactions` " +
                            " ( `action_type`, `action_ref_id`, `partner_id`,`partner_type`, `user_id`, `narration`, `dr`,  `date`,`is_reconciliation`,`closing_balance`)" +
                            " SELECT @action_type, @action_ref_id, @partner_id,@partner_type, @user_id, @narration, @dr, @date, @is_reconciliation,(ifnull(sum(dr)-sum(cr),0)+@dr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type ";

                        cmdInsDr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.PURCHASE);
                        cmdInsDr.Parameters.AddWithValue("@action_ref_id", filters["purchaseId"]);
                        cmdInsDr.Parameters.AddWithValue("@partner_id", filters["vendorId"]);
                        cmdInsDr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.VENDOR);
                        cmdInsDr.Parameters.AddWithValue("@user_id", filters["userid"]);
                        cmdInsDr.Parameters.AddWithValue("@narration", "Reconciliation of Purchase entry #" + filters["invoicenum"] + " after an edit by debiting the amount " + (old_netamount - Convert.ToDouble(filters["TotalNetAmount"])));
                        cmdInsDr.Parameters.AddWithValue("@dr", (old_netamount - Convert.ToDouble(filters["TotalNetAmount"])));
                        cmdInsDr.Parameters.AddWithValue("@date", currdatetime);
                        cmdInsDr.Parameters.AddWithValue("@is_reconciliation", "1");
                        db.ExecuteQueryForTransaction(cmdInsDr);
                    }
                    //end updation in transactions
                    string update_vendor_qry = "UPDATE tbl_vendor SET vn_balance=(select (sum(cr)-sum(dr)) from tbl_transactions where partner_id='" + filters["vendorId"] + "' and partner_type="+ (int)Constants.PartnerType.VENDOR + ") WHERE vn_id='" + filters["vendorId"] + "'";
                    bool upvndr_result = db.ExecuteQueryForTransaction(update_vendor_qry);
                    if (upvndr_result)
                    {
                        checkstatus = "Y";
                    }
                }
                else
                {
                    checkstatus = "N";
                }
            }
            else
            {
                checkstatus = "N";
            }


           
            db.CommitTransaction();

        }
        catch (Exception ex)
        {
            try
            {
                checkstatus = "N";
                db.RollBackTransaction();
                LogClass log = new LogClass("purchaseEntry");
                log.write(ex);
            }
            catch
            {
            }
        }
        return checkstatus;


        //change code
    }

    [WebMethod]
    public static string editPurchaseEntry(Dictionary<string, string> filters, string tableString)
    {
        string result = "";
        string checkstatus = "N";
        string message = "";

        mySqlConnection db = new mySqlConnection();
        try
        {
            db.BeginTransaction();
            // FOR purchase_MASTER
            string vendor_name = "";
            double pm_discount_rate = 0;
            double pm_discount_amount = 0;
            double pm_netamount = 0;
            double pm_total = 0;
            double pm_balance = 0;
            double pm_tax_excluded_amt = 0;
            double pm_tax_amount = 0;
  

            // FOR purchase ITEMS
            string itm_code = "";
            string itm_name = "";
            double pi_org_price;
            double pi_total;
            double pi_discount_amount;
            double pi_net_amount;
            double pi_item_tax;
            double pi_item_cgst = 0, pi_item_sgst = 0, pi_item_igst = 0, pi_item_utgst = 0;
            double pi_item_cess;
            double pi_tax_amount;

            Int32 branch_id;

            string branch_timezone = "";
            string insert_to_purchase_items = "";
            //check invoice exist already
            DataTable dt = new DataTable();
            TimeZoneInfo CurrentZone = TimeZoneInfo.FindSystemTimeZoneById(filters["TimeZone"]);
            DateTime TimeNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, CurrentZone);
            string edited_date = TimeNow.ToString("yyyy/MM/dd HH:mm:ss");
            //  string jsonData = JsonConvert.SerializeObject(tableString);
            List<Dictionary<string, string>> items_after_edit = JsonConvert.DeserializeObject<List<Dictionary<string, string>>>(tableString);
            dynamic data = JsonConvert.DeserializeObject(tableString);
            Int32 branch_tax_method = Convert.ToInt32(filters["branch_tax_method"]);
            Int32 branch_tax_inclusive = Convert.ToInt32(filters["branch_tax_inclusive"]);
             string selectPurchaseItemQuery = "select pi.itbs_id,pi_qty,pm_netamount as old_netamount,pi.itm_name,pi_id as purchaseItemId from tbl_purchase_items pi inner join tbl_purchase_master pm on pm.pm_id=pi.pm_id inner join tbl_itembranch_stock ibs on ibs.itbs_id=pi.itbs_id where pi.pm_id=" + filters["purchaseId"];
           
            DataTable itemsBefrEditDt = db.SelectQueryForTransaction(selectPurchaseItemQuery);
              double old_netamount = Convert.ToDouble(itemsBefrEditDt.Rows[0]["old_netamount"]);
            int numrows = itemsBefrEditDt.Rows.Count;
            Int32 oldqty = 0;
            Int32 oldfoc = 0;
            Int32 oldtotoalqty = 0;
            string olditbs = "";
            string oldUniqueItemId = "";
            string itbsidString = "";
            //start changed by deepika for bulk updation
   
            string itbsidStockString = "";
            string oldupstockQry = "UPDATE tbl_itembranch_stock SET itbs_stock=CASE itbs_id";

            foreach (DataRow row in itemsBefrEditDt.Rows)
            {
                oldqty = Convert.ToInt32(row["pi_qty"]);
                oldtotoalqty = oldfoc + oldqty;
                olditbs = Convert.ToString(row["itbs_id"]);
                itbsidString = itbsidString + "," + olditbs;

                oldupstockQry += " WHEN '" + olditbs + "' THEN itbs_stock - " + oldtotoalqty + "";

            }
            itbsidString = itbsidString.Trim().TrimStart(',');
            oldupstockQry += " ELSE itbs_stock END,itm_last_update_date='" + edited_date + "'  WHERE itbs_id IN (" + itbsidString + ")";
            bool oldupstockresult = db.ExecuteQueryForTransaction(oldupstockQry);
            //end changed by deepika for bulk updation

            string delQry = "DELETE from tbl_purchase_items  WHERE pm_id='" + filters["purchaseId"] + "'";
            bool dresult = db.ExecuteQueryForTransaction(delQry);
            Int32 cust_state = 0;

            double realtotal = 0;
            double nettotal = 0;
            double discount_amt = 0;
            double tax_amount = 0;
            double tax_included_nettotal = 0;
            double cessAmount = 0;

            double pi_qty = 0;
            double pi_price = 0;
            double pi_foc = 0;
            double pi_discount_rate = 0;
            int itemId = 0;
            // PROCESSING ITEMS
            Int32 row_no = 0;
            //start changed by deepika
            // fetch item details from item_branch_stock and tbl_tax_profile
            insert_to_purchase_items = "INSERT INTO tbl_purchase_items(pm_id,row_no,itbs_id,itm_code,itm_name,pi_org_price,"
            +" pi_price,pi_qty,pi_total,pi_discount_rate,pi_discount_amount,pi_net_amount,pi_item_tax,"
            +" pi_item_cgst,pi_item_sgst,pi_item_igst,pi_item_utgst,pi_item_cess,pi_tax_excluded_total,"
            + " pi_tax_amount,pi_carton_count,pi_item_per_carton) VALUES";
            DataTable dt_itemDetail = new DataTable();
            foreach (var items in data)
            {
                
                    itbsidStockString = itbsidStockString + "," + items.itbs_id;
                
            }

            itbsidStockString = itbsidStockString.Trim().TrimStart(',');
            if (itbsidString != "")
            {
                string item_fetch_qry = "select itb.itm_id,itm_type,itb.itbs_id,tax.tp_tax_percentage,tax.tp_cess,itb.itm_name,itb.itm_code,itb.itm_commision from tbl_itembranch_stock itb inner join tbl_item_master tim on tim.itm_id=itb.itm_id join tbl_tax_profile tax on itb.tp_tax_code=tax.tp_tax_code where itb.itbs_id in (" + itbsidStockString + ")  ORDER BY FIELD(itb.itbs_id, " + itbsidStockString + ")";
                dt_itemDetail = db.SelectQueryForTransaction(item_fetch_qry);
            }

            int size = items_after_edit.Count;
            int j = 0;

            for (int i = 0; i < size; i++)
            {// BASE VALUES
                pi_qty = data[i].pi_qty;
                pi_price = data[i].pi_price;
                pi_discount_rate = data[i].pi_discount_rate;
                pi_org_price = 0.00;

                pi_item_tax = Convert.ToDouble(data[i].pi_taxperc);
                pi_item_cess = Convert.ToDouble(dt_itemDetail.Rows[j]["tp_cess"]);
                itm_name = Convert.ToString(dt_itemDetail.Rows[j]["itm_name"]);
                itm_code = Convert.ToString(dt_itemDetail.Rows[j]["itm_code"]);
                itemId = Convert.ToInt32(dt_itemDetail.Rows[j]["itm_id"]);
                j = j + 1;
                // CALCULATIONS
                if (branch_tax_method == 0) // no tax
                {
                    realtotal = pi_price * pi_qty; // price without discount
                    realtotal = Math.Round(realtotal, 2);
                    discount_amt = ((realtotal * pi_discount_rate) / 100);
                    nettotal = realtotal - ((realtotal * pi_discount_rate) / 100);
                    tax_included_nettotal = Math.Round(nettotal, 2);
                    tax_amount = 0; // not tax used
                    cessAmount = 0;

                }
                else if (branch_tax_method == 1) // VAT CALCULATION
                {
                    if (branch_tax_inclusive == 1)  // tax is included with the price
                    {
                        if (pi_item_cess > 0)
                        {
                            double denominator = 10000 * pi_price;
                            double baseval = 10000 + (100 * pi_item_tax) + (pi_item_tax * pi_item_cess);
                            pi_price = denominator / baseval;
                        }
                        else
                        {
                            double constant = (pi_item_tax / 100) + 1; // equation for the dividing constant
                            pi_price = pi_price / constant;
                        }

                    }

                    realtotal = pi_price * pi_qty; // price without discount
                    discount_amt = ((realtotal * pi_discount_rate) / 100);
                    nettotal = realtotal - ((realtotal * pi_discount_rate) / 100);

                    tax_amount = ((nettotal * pi_item_tax) / 100);
                    cessAmount = ((tax_amount * pi_item_cess) / 100);
                    tax_amount = cessAmount + tax_amount;
                    tax_included_nettotal = nettotal + tax_amount;
                    // VAT ENDS
                }
                else if (branch_tax_method == 2) // GST CALCULATION
                {
                    if (branch_tax_inclusive == 1)  // tax is included with the price
                    {
                        if (pi_item_cess > 0)
                        {
                            double denominator = 10000 * pi_price;
                            double baseval = 10000 + (100 * pi_item_tax) + (pi_item_tax * pi_item_cess);
                            pi_price = denominator / baseval;
                        }
                        else
                        {
                            double constant = (pi_item_tax / 100) + 1; // equation for the dividing constant
                            pi_price = pi_price / constant;
                            pi_item_cess = 0;

                        }
                    }

                    realtotal = pi_price * pi_qty; // price without discount
                    discount_amt = ((realtotal * pi_discount_rate) / 100);
                    nettotal = realtotal - ((realtotal * pi_discount_rate) / 100);

                    tax_amount = ((nettotal * pi_item_tax) / 100);
                    cessAmount = ((tax_amount * pi_item_cess) / 100);
                    tax_amount = cessAmount + tax_amount;
                    tax_included_nettotal = nettotal + tax_amount;
                    // CHECKING CUSTOMER STATE FOR IGST - DETERINATION

                    // default state , No IGST

                    double splitted_GST_rate = pi_item_tax / 2;
                    splitted_GST_rate = Math.Round(splitted_GST_rate, 2);

                    pi_item_cgst = splitted_GST_rate;
                    pi_item_sgst = splitted_GST_rate;
                    pi_item_igst = 0;
                    pi_item_utgst = 0;


                }
                pi_total = realtotal;
                pi_discount_amount = discount_amt;
                pi_net_amount = tax_included_nettotal;
                pi_tax_amount = tax_amount;

                // INSERTING INTO TBL_SALES_ITEMS

                insert_to_purchase_items += " (" + "'" + filters["purchaseId"] + "','" + row_no + "', '" + data[i].itbs_id + "', '" + itm_code + "', '" + itm_name + "',  '" + pi_org_price + "', '" + data[i].pi_price + "',"
                + " '" + pi_qty + "', '" + pi_total + "', '" + pi_discount_rate + "', '" + pi_discount_amount + "',"
                + " '" + pi_net_amount + "','" + pi_item_tax + "', '" + pi_item_cgst + "', '" + pi_item_sgst + "',"
                + " '" + pi_item_igst + "', '" + pi_item_utgst + "', '" + pi_item_cess + "',"
                + " '" + (pi_net_amount - tax_amount) + "', '" + tax_amount + "',0,0),";

                //  }

                row_no++;

                // calculation for sm - values

                pm_tax_excluded_amt = pm_tax_excluded_amt + (pi_net_amount - pi_tax_amount);
                pm_discount_amount = pm_discount_amount + pi_discount_amount;
                pm_netamount = pm_netamount + pi_net_amount;
                //if (neworder["roundoffval"] != "0.00")
                //{
                //    sm_netamount = math.round(sm_netamount);
                //}
                pm_tax_amount = pm_tax_amount + pi_tax_amount;
                pm_total = pm_total + pi_total;

                string purchaseMaintainStatus = db.SelectScalarForTransaction("select itbs_purchase_status from tbl_itembranch_stock tis where itbs_id=" + data[i].itbs_id);
                if (purchaseMaintainStatus == "1")
                {
                    var purchaseprice = Convert.ToDouble(pi_net_amount) / Convert.ToDouble(pi_qty);
                    db.ExecuteQueryForTransaction("update tbl_itembranch_stock set itbs_purchase_price=" + purchaseprice + " where itbs_id=" + data[i].itbs_id);
                }
                // HANDLE STOCK

                Int32 item_total_qty = Convert.ToInt32(pi_foc) + Convert.ToInt32(pi_qty);

                string upstockQry = "UPDATE tbl_itembranch_stock SET itbs_stock=(itbs_stock + " + item_total_qty + ") where itbs_id='" + data[i].itbs_id + "'";
                bool upstockresult = db.ExecuteQueryForTransaction(upstockQry);
                

                //end for loop  
            }
            var grandTotal = Convert.ToDecimal(pm_netamount);
            pm_netamount = Convert.ToDouble(Math.Round(grandTotal, MidpointRounding.AwayFromZero));
            double roundOffVal = pm_netamount - Convert.ToDouble(grandTotal);
            insert_to_purchase_items = insert_to_purchase_items.Remove(insert_to_purchase_items.Trim().Length - 1);
            bool Itemresult = db.ExecuteQueryForTransaction(insert_to_purchase_items);

            // calculating discount rate
            double divider = pm_tax_excluded_amt + pm_discount_amount;
            double divident = pm_discount_amount * 100;
            pm_discount_rate = divident / divider;
            pm_discount_rate = Math.Round(pm_discount_rate, 2);
            string update_salesmaster_qry = "UPDATE tbl_purchase_master SET pm_total='" + pm_total + "',pm_discount_rate='" + pm_discount_rate + "',pm_discount_amount='" + pm_discount_amount + "',pm_netamount='" + pm_netamount + "',pm_tax_excluded_amt='" + pm_tax_excluded_amt + "',pm_tax_amount='" + pm_tax_amount + "',pm_ref_no='" + filters["purchaseId"] + "',pm_roundoff=" + roundOffVal + ",pm_invoice_no = '" + filters["invoicenum"] + "',pm_date = '" + filters["purchaseDate"] + "' WHERE pm_id='" + filters["purchaseId"] + "'";
            bool update_sales_result = db.ExecuteQueryForTransaction(update_salesmaster_qry);

             //start stock transaction update
                    StringBuilder sb_bulk_stkTrQry = new StringBuilder();
                    bool isStockChanged = false;
                    sb_bulk_stkTrQry.Append("INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`action_ref_id`,`user_id`,`narration`,`dr_qty`,`cr_qty`,`closing_stock`,`date`,`is_reconciliation`) VALUES ");
                    foreach (DataRow itemrow in itemsBefrEditDt.Rows)
                    {
                        oldqty = Convert.ToInt32(itemrow["pi_qty"]);
                        olditbs = Convert.ToString(itemrow["itbs_id"]);
                        oldUniqueItemId = Convert.ToString(itemrow["purchaseItemId"]);

                        dynamic itemAftrEdit = ((IEnumerable)data).Cast<dynamic>().Where(a => a.purchaseItemId == oldUniqueItemId).FirstOrDefault();
                        //checking if item deleted

                        if (itemAftrEdit == null)
                        {
                            //crediting if deleted
                            sb_bulk_stkTrQry.Append("('" + olditbs + "','" + ((int)Constants.ActionType.PURCHASE) + "','" + filters["purchaseId"] + "','" + filters["userid"] + "'");
                            sb_bulk_stkTrQry.Append(",'Debiting " + itemrow["itm_name"] + " of quantity " + oldqty + " back on delete from purchase entry #" + filters["purchaseId"] + "','" + oldqty + "','0'");
                            sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + olditbs + "')");
                            sb_bulk_stkTrQry.Append(",'" + edited_date + "','1'),");
                            isStockChanged = true;
                        }
                        else
                        {
                            //recording change in quantity
                            int newTotalQty = Convert.ToInt32(itemAftrEdit.quantity);
                           
                            if (oldqty > newTotalQty)
                            {
                                sb_bulk_stkTrQry.Append("('" + olditbs + "','" + ((int)Constants.ActionType.PURCHASE) + "','" + filters["purchaseId"] + "','" + filters["userid"] + "'");
                                sb_bulk_stkTrQry.Append(",'Debiting " + itemrow["itm_name"] + " of quantity " + (oldqty - newTotalQty) + " back on edit of entry #" + filters["purchaseId"] + "','" + (oldqty - newTotalQty) + "','0'");
                                sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + olditbs + "')");
                                sb_bulk_stkTrQry.Append(",'" + edited_date + "','1'),");
                                isStockChanged = true;
                            }
                            else if (oldqty < newTotalQty)
                            {
                                sb_bulk_stkTrQry.Append("('" + olditbs + "','" + ((int)Constants.ActionType.PURCHASE) + "','" + filters["purchaseId"] + "','" + filters["userid"] + "'");
                                sb_bulk_stkTrQry.Append(",'Crediting " + itemrow["itm_name"] + " of quantity " + (newTotalQty - oldqty) + " on edit of order #" + filters["purchaseId"] + "','0','" + (newTotalQty - oldqty) + "'");
                                sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + olditbs + "')");
                                sb_bulk_stkTrQry.Append(",'" + edited_date + "','1'),");
                                isStockChanged = true;
                            }

                        }


                    }
                    // crediting new items
                    dynamic newItemsList = ((IEnumerable)data).Cast<dynamic>()
                        .Where(a =>
                        !itemsBefrEditDt.AsEnumerable().Any(b =>
                            b.Field<int>("itbs_id") == Convert.ToInt32(a.itbs_id))
                        ).ToList();
                    foreach (var item in newItemsList)
                    {
                        int newTotalQty = Convert.ToInt32(item.quantity);
                        sb_bulk_stkTrQry.Append("('" + item.itbs_id + "','" + ((int)Constants.ActionType.PURCHASE) + "','" + filters["purchaseId"] + "','" + filters["userid"] + "'");
                        sb_bulk_stkTrQry.Append(",CONCAT('Purchased " + newTotalQty + "', (select itm_name from tbl_itembranch_stock where itbs_id='" + item.itbs_id + "'),' in entry #" + filters["purchaseId"] + "'),'0','" + newTotalQty + "'");
                        sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + item.itbs_id + "')");
                        sb_bulk_stkTrQry.Append(",'" + edited_date + "','0'),");
                        isStockChanged = true; 
                    }
                    //end stock transaction update


                    // bulk insert stock transactions
                    if (isStockChanged)
                    {
                        sb_bulk_stkTrQry.Length--;
                        db.ExecuteQueryForTransaction(sb_bulk_stkTrQry.ToString());

                    }



                    //start updation in transactions
                    if (Convert.ToDouble(filters["TotalNetAmount"]) > old_netamount)
                    {
                        //inserting order debit entry
                        MySqlCommand cmdInsCr = new MySqlCommand();
                        cmdInsCr.CommandText = "INSERT INTO `tbl_transactions` " +
                            " ( `action_type`, `action_ref_id`, `partner_id`,`partner_type`, `user_id`, `narration`, `cr`,  `date`,`is_reconciliation`,`closing_balance`)" +
                            " select @action_type, @action_ref_id, @partner_id,@partner_type, @user_id, @narration, @cr, @date, @is_reconciliation,(ifnull(sum(dr)-sum(cr),0)-@cr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type ";

                        cmdInsCr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.PURCHASE);
                        cmdInsCr.Parameters.AddWithValue("@action_ref_id", filters["purchaseId"]);
                        cmdInsCr.Parameters.AddWithValue("@partner_id", filters["vendorId"]);
                        cmdInsCr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.VENDOR);
                        cmdInsCr.Parameters.AddWithValue("@user_id", filters["userid"]);
                        cmdInsCr.Parameters.AddWithValue("@narration", "Reconciliation of Purchase entry #" + filters["invoicenum"] + " after an edit by crediting the amount " + (Convert.ToDouble(pm_netamount) - old_netamount));
                        cmdInsCr.Parameters.AddWithValue("@cr", (Convert.ToDouble(pm_netamount) - old_netamount));
                        cmdInsCr.Parameters.AddWithValue("@date", edited_date);
                        cmdInsCr.Parameters.AddWithValue("@is_reconciliation", "1");
                        db.ExecuteQueryForTransaction(cmdInsCr);

                    }
                    else if (Convert.ToDouble(filters["TotalNetAmount"]) < old_netamount)
                    {
                        //inserting order credit entry
                        MySqlCommand cmdInsDr = new MySqlCommand();
                        cmdInsDr.CommandText = "INSERT INTO `tbl_transactions` " +
                            " ( `action_type`, `action_ref_id`, `partner_id`,`partner_type`, `user_id`, `narration`, `dr`,  `date`,`is_reconciliation`,`closing_balance`)" +
                            " SELECT @action_type, @action_ref_id, @partner_id,@partner_type, @user_id, @narration, @dr, @date, @is_reconciliation,(ifnull(sum(dr)-sum(cr),0)+@dr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type ";

                        cmdInsDr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.PURCHASE);
                        cmdInsDr.Parameters.AddWithValue("@action_ref_id", filters["purchaseId"]);
                        cmdInsDr.Parameters.AddWithValue("@partner_id", filters["vendorId"]);
                        cmdInsDr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.VENDOR);
                        cmdInsDr.Parameters.AddWithValue("@user_id", filters["userid"]);
                        cmdInsDr.Parameters.AddWithValue("@narration", "Reconciliation of Purchase entry #" + filters["invoicenum"] + " after an edit by debiting the amount " + (old_netamount - Convert.ToDouble(pm_netamount)));
                        cmdInsDr.Parameters.AddWithValue("@dr", (old_netamount - Convert.ToDouble(pm_netamount)));
                        cmdInsDr.Parameters.AddWithValue("@date", edited_date);
                        cmdInsDr.Parameters.AddWithValue("@is_reconciliation", "1");
                        db.ExecuteQueryForTransaction(cmdInsDr);
                    }
                    //end updation in transactions
                    string update_vendor_qry = "UPDATE tbl_vendor SET vn_balance=(select (sum(cr)-sum(dr)) from tbl_transactions where partner_id='" + filters["vendorId"] + "' and partner_type="+ (int)Constants.PartnerType.VENDOR + ") WHERE vn_id='" + filters["vendorId"] + "'";
                    bool upvndr_result = db.ExecuteQueryForTransaction(update_vendor_qry);
                    if (upvndr_result)
                    {
                        checkstatus = "Y";
                    }
           
           
            db.CommitTransaction();
        }
        catch (Exception ex)
        {
            try // IF TRANSACTION FAILES
            {
                result = "FAILED";
                result = "{\"result\":\"" + result + "\"}";
                db.RollBackTransaction();
                LogClass log = new LogClass("editPurchase");
                log.write(ex);
                return result;
            }
            catch
            {
            }
        }
        return checkstatus;
    }
    
    [WebMethod]
    public static void savePaymentEdit(int trans_id, double cash_amt, double cheque_amt,string cheque_no, string cheque_date, string cheque_bank)
    {
        mySqlConnection db = new mySqlConnection();
        try
        {
            db.BeginTransaction();
            //getting date
            TimeZoneInfo CurrentZone = TimeZoneInfo.FindSystemTimeZoneById(HttpUtility.UrlDecode(HttpContext.Current.Request.Cookies["invntryTimeZone"].Value));
            DateTime TimeNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, CurrentZone);
            string edited_date = TimeNow.ToString("yyyy/MM/dd HH:mm:ss");
            //get previous transaction details
            DataTable dt = db.SelectQueryForTransaction("select action_ref_id,partner_id,cash_amt,wallet_amt,cheque_amt,dr from tbl_transactions where id='" + trans_id + "'");
            if (dt.Rows.Count <= 0)
            {
                HttpContext.Current.Response.StatusCode = 401;
                HttpContext.Current.Response.Write("Transaction not found");
                HttpContext.Current.Response.TrySkipIisCustomErrors = true;
                db.RollBackTransaction();
                return;
            }

            double prev_total = Convert.ToDouble(dt.Rows[0]["dr"]);
            double prev_cash_amt = Convert.ToDouble(dt.Rows[0]["cash_amt"]);
            double prev_wallet_amt = Convert.ToDouble(dt.Rows[0]["wallet_amt"]);
            double prev_cheque_amt = Convert.ToDouble(dt.Rows[0]["cheque_amt"]);

            //calculating new total
            double new_total = cash_amt + prev_wallet_amt + cheque_amt;

            var narration = "";
            if (new_total != 0)
            {
                narration = "Payment Done worth " + new_total + " [EDITED]";
            }
            else
            {
                narration = "Payment Cancelled Worth " + prev_total + " !";
            }

            if (prev_cash_amt != cash_amt || prev_cheque_amt != cheque_amt)
            {
                db.ExecuteQueryForTransaction("INSERT INTO `tbl_payment_edits` (`transaction_id`, `edit_type`, `ref_id`, `tpe_date`, `user_id`, `tpe_prev_cashamt`, `tpe_new_cashamt`, `tpe_prev_chequeamt`, `tpe_new_chequeamt`, `tpe_prev_walletamt`, `tpe_new_walletamt`) VALUES ('" + trans_id + "','2', '" + dt.Rows[0]["action_ref_id"].ToString() + "', '" + edited_date + "', '" + HttpContext.Current.Request.Cookies["invntrystaffId"].Value + "', '" + prev_cash_amt + "', '" + cash_amt + "', '" + prev_cheque_amt + "', '" + cheque_amt + "', '0', '0');");
            }

            //update transaction
            db.ExecuteQueryForTransaction("UPDATE tbl_transactions tr SET tr.cash_amt='" + cash_amt + "',tr.cheque_amt='" + cheque_amt + "',tr.dr='" + new_total + "',tr.narration='" + narration + "' WHERE tr.id='" + trans_id + "'");
            var closing_bal = db.SelectScalarForTransaction("select (sum(tt.cr)-sum(tt.dr)) from tbl_transactions tt where tt.partner_id='" + dt.Rows[0]["partner_id"].ToString() + "' and tt.partner_type=" + (int)Constants.PartnerType.VENDOR + ";");
            db.ExecuteQueryForTransaction("UPDATE tbl_transactions tr SET tr.closing_balance='" + closing_bal + "' WHERE tr.id='" + trans_id + "'");

            // update cheque fields if cheque amount exists
            if (cheque_amt > 0)
            {
                db.ExecuteQueryForTransaction("UPDATE tbl_transactions tr SET tr.cheque_no='" + cheque_no + "',tr.cheque_date='" + cheque_date + "',tr.cheque_bank='" + cheque_bank + "' WHERE tr.id='" + trans_id + "'");
            }

            // UPDATING CUSTOMER DETAILS
            string update_vendor_qry = "UPDATE tbl_vendor SET vn_balance=(select (sum(cr)-sum(dr)) from tbl_transactions where partner_id='" + dt.Rows[0]["partner_id"].ToString() + "' and partner_type="+ (int)Constants.PartnerType.VENDOR + ") WHERE vn_id='" + dt.Rows[0]["partner_id"].ToString() + "'";
            bool upvndr_result = db.ExecuteQueryForTransaction(update_vendor_qry);
            db.ExecuteQueryForTransaction("update tbl_transactions set last_updated_date='" + edited_date + "' where action_type=2 and action_ref_id=" + dt.Rows[0]["action_ref_id"].ToString() + "");

            db.CommitTransaction();
        }
        catch (Exception e)
        {
            HttpContext.Current.Response.StatusCode = 401;
            HttpContext.Current.Response.Write(e.ToString());
            HttpContext.Current.Response.TrySkipIisCustomErrors = true;
            db.RollBackTransaction();
        }
    }

    [WebMethod]
    public static string loadTaxes(int taxType)
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        StringBuilder sb = new StringBuilder();
        if (taxType == -1)
        {
            sb.Append("<option value='-1' selected='selected'>--Tax Code--</option>");
        }
        else
        {
            string query = "SELECT tp_tax_code FROM tbl_tax_profile where tp_tax_type=" + taxType + " ORDER BY tp_id ASC";
            dt = db.SelectQuery(query);
            if (dt != null)
            {
                if (dt.Rows.Count > 0)
                {
                    if (dt.Rows[0]["tp_tax_code"] is DBNull)
                    {
                        // sb.Append("<select id='combobranddiv' class='form-control' style='text-indent:25px;'>");
                        sb.Append("<option value='-1' selected='selected'>--Tax Code--</option>");
                        // sb.Append("</select>");
                    }
                    else
                    {
                        // sb.Append("<select id='combobranddiv' class='form-control' style='text-indent:25px;'>");
                        sb.Append("<option value='-1' selected='selected'>--Tax code--</option>");
                        for (int i = 0; i < dt.Rows.Count; i++)
                        {

                            sb.Append("<option value='" + dt.Rows[i]["tp_tax_code"] + "'>" + dt.Rows[i]["tp_tax_code"] + "</option>");

                        }
                        // sb.Append("</select>");
                    }
                }
                else
                {
                    sb.Append("<option value='-1' selected='selected'>--Tax Code--</option>");
                    //sb.Append("<select id='combobranddiv'>");
                    //sb.Append("</select>");
                }
            }
        }
        return sb.ToString();
    }

    [WebMethod]
    public static string addBranchStockDetails(string branch, string item, string pricegroup_one, string pricegroup_two, string pricegroup_three, string taxcode)
    {

        String resultStatus;
        resultStatus = "N";
        mySqlConnection db = new mySqlConnection();

        bool queryStatus;
        string query = "";


        //check is unique?
        String chk_qry = "SELECT count(*) FROM  tbl_itembranch_stock WHERE (branch_id = '" + branch + "' and itm_id  = '" + item + "')";
        double numrows = Convert.ToInt32(db.SelectScalar(chk_qry));
        if (numrows > 0)
        {
            return "E";
        }
        ////

        string qry = "select MAX(itbs_id) as id from tbl_itembranch_stock";
        DataTable dt = new DataTable();
        dt = db.SelectQuery(qry);
        Int32 branchstockid = 0;
        if (dt != null)
        {

            if (dt.Rows[0][0] is DBNull)
            {
                branchstockid = ++branchstockid;
            }
            else
            {
                branchstockid = Convert.ToInt32(dt.Rows[0][0]);
                branchstockid = ++branchstockid;
            }


        }
        else
        {
            branchstockid = ++branchstockid;
        }
        DataTable dt1 = new DataTable();
        dt1 = db.SelectQuery("select itm_code,itm_name,itm_brand_id,itm_category_id,itm_subcategory_id from tbl_item_master where itm_id='" + item + "'");
        query = "INSERT INTO tbl_itembranch_stock (itbs_id,branch_id, itm_id, itbs_stock, itbs_reorder, itbs_available, itm_code, itm_name,itm_brand_id,itm_category_id,itm_subcategory_id,itm_mrp,itm_commision,itm_target,tp_tax_code)";
        query = query + "VALUES ('" + branchstockid + "','" + branch + "','" + item + "','0','0','1','" + dt1.Rows[0]["itm_code"] + "','" + dt1.Rows[0]["itm_name"] + "','" + dt1.Rows[0]["itm_brand_id"] + "','" + dt1.Rows[0]["itm_category_id"] + "','" + dt1.Rows[0]["itm_subcategory_id"] + "','0','0','0','" + taxcode + "')";

        queryStatus = db.ExecuteQuery(query);
        if (queryStatus)
        {
            resultStatus = "Y";
        }
        // Response.Redirect("~/ManagePatientsAlertAndSurvey.aspx?id="+ViewState["patientId"].ToString()+"");
        return resultStatus;
    }

    [WebMethod]
    public static void cancelFunctn(int userId,int purchaseId)
    {
        mySqlConnection db = new mySqlConnection();
        try
        {
            var branch_timezone = "";
            db.BeginTransaction();
            string purchaseDetailQry = "SELECT vn_id,pm_netamount as currentAmt,branch_id from tbl_purchase_master where pm_id='" + purchaseId + "'";
            DataTable dtPurchaseData = db.SelectQueryForTransaction(purchaseDetailQry);
            string getTimeZone = "SELECT branch_timezone from tbl_branch where branch_id='" + dtPurchaseData.Rows[0]["branch_id"] + "'";
            DataTable cTimeZone = db.SelectQueryForTransaction(getTimeZone);
            if (cTimeZone != null)
            {
                branch_timezone = Convert.ToString(cTimeZone.Rows[0]["branch_timezone"]);
            
            }
            TimeZoneInfo CurrentZone = TimeZoneInfo.FindSystemTimeZoneById(branch_timezone);
            DateTime TimeNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, CurrentZone);
            string currentdate = TimeNow.ToString("yyyy/MM/dd HH:mm:ss");
            db.ExecuteQueryForTransaction("UPDATE tbl_purchase_master SET pm_status='" + ((int)Constants.PurchaseStatus.Cancel) + "',pm_userid='" + userId + "',pm_cancelled_date='" + currentdate + "' where pm_id='" + purchaseId + "'");

            string qry = "select pi.itbs_id,pi_qty,pi.itm_name from tbl_purchase_items pi left join tbl_itembranch_stock tis on tis.itbs_id=pi.itbs_id where pm_id='" + purchaseId + "'";
            DataTable dt = db.SelectQueryForTransaction(qry);
            int numrows = dt.Rows.Count;

            Int32 oldqty = 0;
            Int32 oldtotoalqty = 0;
            string olditbs = "";
            StringBuilder sb_bulk_stkTrQry = new StringBuilder();
            sb_bulk_stkTrQry.Append("INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`action_ref_id`,`user_id`,`narration`,`dr_qty`,`closing_stock`,`date`) VALUES ");

            foreach (DataRow row in dt.Rows)
            {
                oldqty = Convert.ToInt32(row["pi_qty"]);
                oldtotoalqty = oldqty;
                olditbs = Convert.ToString(row["itbs_id"]);
                db.ExecuteQueryForTransaction("UPDATE tbl_itembranch_stock SET itbs_stock=itbs_stock - " + oldqty + " where itbs_id=" + olditbs);
                // code to record stock transaction by deepika
                sb_bulk_stkTrQry.Append("('" + olditbs + "','" + ((int)Constants.ActionType.PURCHASE) + "','" + purchaseId + "','" + userId + "'");
                sb_bulk_stkTrQry.Append(",'Debited " + oldtotoalqty + " " + row["itm_name"] + " in canceled purchase #" + purchaseId + "','" + oldtotoalqty + "'");
                sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + olditbs + "')");
                sb_bulk_stkTrQry.Append(",'" + currentdate + "'),");

                // code to record stock transaction end
            }

            // bulk insert stock transactions
            sb_bulk_stkTrQry.Length--;
            db.ExecuteQueryForTransaction(sb_bulk_stkTrQry.ToString());

            MySqlCommand cmdInsCr = new MySqlCommand();
            cmdInsCr.CommandText = "INSERT INTO `tbl_transactions` " +
                " (`action_type`, `action_ref_id`, `partner_id`,`partner_type`, `user_id`, `narration`, `dr`,  `date`,`is_reconciliation`,`closing_balance`)" +
                " select @action_type, @action_ref_id, @partner_id,@partner_type, @user_id, @narration, @dr, @date,@is_reconciliation,(ifnull(sum(dr)-sum(cr),0)+@dr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type ";
            cmdInsCr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.PURCHASE);
            cmdInsCr.Parameters.AddWithValue("@action_ref_id", purchaseId);
            cmdInsCr.Parameters.AddWithValue("@partner_id", dtPurchaseData.Rows[0]["vn_id"]);
            cmdInsCr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.VENDOR);
            cmdInsCr.Parameters.AddWithValue("@user_id",userId);
            cmdInsCr.Parameters.AddWithValue("@narration", "Cancellation of Order #" + purchaseId + " with net amount " + dtPurchaseData.Rows[0]["currentAmt"]);
            cmdInsCr.Parameters.AddWithValue("@dr", dtPurchaseData.Rows[0]["currentAmt"]);
            cmdInsCr.Parameters.AddWithValue("@date", currentdate);
            cmdInsCr.Parameters.AddWithValue("@is_reconciliation", 1);
            db.ExecuteQueryForTransaction(cmdInsCr);
            // UPDATING CUSTOMER DETAILS

            string update_vendor_qry = "UPDATE tbl_vendor SET vn_balance=(select (sum(cr)-sum(dr)) from tbl_transactions where partner_id='" + dtPurchaseData.Rows[0]["vn_id"] + "' and partner_type=" + (int)Constants.PartnerType.VENDOR + ") WHERE vn_id='" + dtPurchaseData.Rows[0]["vn_id"] + "'";
            bool upvndr_result = db.ExecuteQueryForTransaction(update_vendor_qry);
            db.CommitTransaction();
        }
        catch (Exception ex)
        {
            try
            {
                db.RollBackTransaction();
                LogClass log = new LogClass("editpurchase");
                log.write(ex);
            }
            catch
            {
            }
        }
    }

    [WebMethod]
    public static string selectOrderItem(string itemId)
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        string query = "select itm_code,itm_name,tp_tax_percentage,tp_cess,itbs_purchase_price from tbl_itembranch_stock tis inner join"
            + " tbl_tax_profile tp on tp.tp_tax_code=tis.tp_tax_code"
        + "  where itbs_id=" + itemId + "";
        //    query = query + " order by tbl_branch.branch_id";
        dt = db.SelectQuery(query);
        return JsonConvert.SerializeObject(dt, Formatting.Indented);
    }
    [WebMethod(EnableSession = true)]
    public static string GetAutoCompleteItemData(string variable, string BranchId)
    {
        StringBuilder sb = new StringBuilder();
        //List<string> custNames = new List<string>();
        mySqlConnection db = new mySqlConnection();
        string sqlQuery = "SELECT itm_name,itbs_id from tbl_itembranch_stock where 1 and itm_name like '%" + variable + "%' and itm_code not in ('1234567891234') and branch_id='" + BranchId + "'";
        DataTable QryTable = db.SelectQuery(sqlQuery);
        if (QryTable.Rows.Count > 0)
        {
            sb.Append("[");
            foreach (DataRow row in QryTable.Rows)
            {
                sb.Append("{\"id\":\"" + Convert.ToString(row["itbs_id"]) + "\",");
                sb.Append("\"label\":\"" + Convert.ToString(row["itm_name"]) + "\",");
                sb.Append("\"value\":\"" + Convert.ToString(row["itm_name"]) + "\"}");

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
}