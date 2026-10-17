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

public partial class web_purchase_purchaseentry : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication purchase = new LoginAuthentication();
        purchase.userAuthentication();
        purchase.checkPageAcess(3);
    }

   

    [WebMethod(EnableSession = true)]
    public static string GetAutoCompleteVendorData(string variable)
    {
        StringBuilder sb = new StringBuilder();
        //List<string> custNames = new List<string>();
        mySqlConnection db = new mySqlConnection();
        string sqlQuery = "SELECT vn_name,vn_id from tbl_vendor where 1 and vn_name like '%" + variable + "%' ";
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

    [WebMethod]
    public static string selectVendorData(string vendorId)
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        string query = "select vn_name,vn_city,vn_phone1,vn_email from tbl_vendor where vn_id=" + vendorId + "";
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

    [WebMethod]
    public static string selectOrderItem(string itemId)
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        string query = "select itm_code,itm_name,tp_tax_percentage,tp_cess,itbs_purchase_price from tbl_itembranch_stock tis inner join"
            +" tbl_tax_profile tp on tp.tp_tax_code=tis.tp_tax_code"
        +"  where itbs_id=" + itemId + "";
        //    query = query + " order by tbl_branch.branch_id";
        dt = db.SelectQuery(query);
        return JsonConvert.SerializeObject(dt, Formatting.Indented);
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
                if (filters.ContainsKey("itemBrand"))
                {
                    query_condition += " and tim.itm_brand_id  = " + filters["itemBrand"] + "";
                }
                if (filters.ContainsKey("itemCategory"))
                {
                    query_condition += " and tim.itm_category_id  = " + filters["itemCategory"] + "";
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

            innerqry = "SELECT tim.itm_id,brand_name,cat_name,tim.itm_code,tim.itm_name,IFNULL(itbs_stock,0) as stock,IFNULL(itbs_id,0) as itbsId from tbl_item_master tim left join tbl_itembranch_stock tis on tis.itm_id=tim.itm_id and branch_id=" + filters["warehouse"] + " inner join tbl_item_brand ib on ib.brand_id=tim.itm_brand_id inner join tbl_item_category ic on ic.cat_id=tim.itm_category_id";
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
    public static string savePurchaseEntry(Dictionary<string, string> filters,string tableString)
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


            //check invoice exist already
            DataTable dt = new DataTable();
            TimeZoneInfo CurrentZone = TimeZoneInfo.FindSystemTimeZoneById(filters["TimeZone"]);
            DateTime TimeNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, CurrentZone);
            string currdatetime = TimeNow.ToString("yyyy/MM/dd HH:mm:ss");
            //  string jsonData = JsonConvert.SerializeObject(tableString);
            
            string invoiceCheckQry = "SELECT pm_id FROM tbl_purchase_master WHERE  pm_invoice_no ='" + filters["invoiceno"] + "'";
            string existId = db.SelectScalarForTransaction(invoiceCheckQry);
            if (!string.IsNullOrWhiteSpace(existId))
            {
                HttpContext.Current.Response.StatusCode = 401;
                HttpContext.Current.Response.TrySkipIisCustomErrors = true;
                return "{\"message\":\" already existing old invoice \"}";
            }
            List<Dictionary<string, string>> item_details = JsonConvert.DeserializeObject<List<Dictionary<string, string>>>(tableString);
            dynamic data = JsonConvert.DeserializeObject(tableString);
            Int32 branch_tax_method = Convert.ToInt32(filters["branch_tax_method"]);
            Int32 branch_tax_inclusive = Convert.ToInt32(filters["branch_tax_inclusive"]);

            double realtotal = 0;
            double nettotal = 0;
            double discount_amt = 0;
            double tax_amount = 0;
            double tax_included_nettotal = 0;
            double cessAmount = 0;
            int itemId = 0;
            double pi_qty = 0;
            double pi_price = 0;
            double pi_foc = 0;
            double pi_discount_rate = 0;
            int itm_type = 0;
            string insert_to_salsesQry = "INSERT INTO tbl_purchase_master (pm_invoice_no,vn_id,pm_userid,pm_date,";
            insert_to_salsesQry = insert_to_salsesQry + "pm_note,branch_id,pm_status,branch_tax_method,branch_tax_inclusive)";
            insert_to_salsesQry = insert_to_salsesQry + "VALUES ('" + filters["invoiceno"] + "','" + filters["vendorId"] + "','" + filters["userid"] + "','" + filters["purchasedate"] + "',";
            insert_to_salsesQry = insert_to_salsesQry + "'" + filters["note"] + "','" + filters["warehouse"] + "',1,"+filters["branch_tax_method"]+","+filters["branch_tax_inclusive"]+");Select last_insert_id()";
            var last_id = db.SelectScalarForTransaction(insert_to_salsesQry);
            result = last_id;
            Int32 pm_id = Convert.ToInt32(last_id);

            // PROCESSING ITEMS
            Int32 row_no = 0;
            string insert_to_purchase_items = "INSERT INTO tbl_purchase_items(pm_id,row_no,itbs_id,itm_code,"
            +" itm_name,pi_org_price,pi_price,pi_qty,pi_total,pi_discount_rate,pi_discount_amount,"
            + " pi_net_amount,pi_item_tax,pi_item_cgst,pi_item_sgst,pi_item_igst,pi_item_utgst,"
            + " pi_item_cess,pi_tax_excluded_total,pi_tax_amount,pi_carton_count,pi_item_per_carton) VALUES ";
            string itbsidString = "";

            foreach (var items in data)
            {
                    itbsidString = itbsidString + "," + items.itbs_id;              
            }
            itbsidString = itbsidString.Trim().TrimStart(',');

            // fetch item details from item_branch_stock and tbl_tax_profile
            DataTable dt_itemDetail = new DataTable();

            if (itbsidString != "")
            {
                string item_fetch_qry = "select itm_type,itb.itm_id,itb.itbs_id,tax.tp_tax_percentage,tax.tp_cess,itb.itm_name,itb.itm_code from tbl_itembranch_stock itb inner join tbl_item_master tim on tim.itm_id=itb.itm_id join tbl_tax_profile tax on itb.tp_tax_code=tax.tp_tax_code where itb.itbs_id in (" + itbsidString + ")  ORDER BY FIELD(itb.itbs_id, " + itbsidString + ")";
                dt_itemDetail = db.SelectQueryForTransaction(item_fetch_qry);
            }
            int size = item_details.Count;
            int j = 0;
            StringBuilder sb_bulk_stkTrQry = new StringBuilder();
            sb_bulk_stkTrQry.Append("INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`action_ref_id`,`user_id`,`narration`,`cr_qty`,`closing_stock`,`date`) VALUES ");
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
                    itm_type = Convert.ToInt32(dt_itemDetail.Rows[j]["itm_type"]);
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
               
                insert_to_purchase_items += " (" + "'" + pm_id + "','" + row_no + "', '" + data[i].itbs_id + "', '" + itm_code + "', '" + itm_name + "',  '" + pi_org_price + "', '" + data[i].pi_price + "',"
                +" '" + pi_qty + "', '" + pi_total + "', '" + pi_discount_rate + "', '" + pi_discount_amount + "',"
                +" '" + pi_net_amount + "','" + pi_item_tax + "', '" + pi_item_cgst + "', '" + pi_item_sgst + "',"
                +" '" + pi_item_igst + "', '" + pi_item_utgst + "', '" + pi_item_cess + "',"
                +" '" + (pi_net_amount - tax_amount) + "', '" + tax_amount + "',0,0),";

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
                        // code to record stock transaction by deepika
                        sb_bulk_stkTrQry.Append("('" + data[i].itbs_id + "','" + ((int)Constants.ActionType.PURCHASE) + "','" + pm_id + "','" + filters["userid"] + "'");
                        sb_bulk_stkTrQry.Append(",CONCAT('Purchased " + item_total_qty + "' , (select itm_name from tbl_itembranch_stock where itbs_id='" + data[i].itbs_id + "'), ' in purchase entry #" + pm_id + "') ,'" + item_total_qty + "'");
                        sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + data[i].itbs_id + "')");
                        sb_bulk_stkTrQry.Append(",'" + currdatetime + "')" + (i != size - 1 ? "," : ";"));

                //end for loop  
            }

                var grandTotal = Convert.ToDecimal(pm_netamount);
                pm_netamount = Convert.ToDouble(Math.Round(grandTotal, MidpointRounding.AwayFromZero));
                double roundOffVal = pm_netamount - Convert.ToDouble(grandTotal);
                insert_to_purchase_items = insert_to_purchase_items.Remove(insert_to_purchase_items.Trim().Length - 1);
                bool Itemresult = db.ExecuteQueryForTransaction(insert_to_purchase_items);


                // bulk insert stock transactions
                if (sb_bulk_stkTrQry.ToString() != "")
                {

                   // sb_bulk_stkTrQry.Append(sb_bulk_stkTrQry.ToString());
                    db.ExecuteQueryForTransaction(sb_bulk_stkTrQry.ToString());
                }
                // calculating discount rate
                double divider = pm_tax_excluded_amt + pm_discount_amount;
                double divident = pm_discount_amount * 100;
                pm_discount_rate = divident / divider;
                pm_discount_rate = Math.Round(pm_discount_rate, 2);
                string update_salesmaster_qry = "UPDATE tbl_purchase_master SET pm_total='" + pm_total + "',pm_discount_rate='" + pm_discount_rate + "',pm_discount_amount='" + pm_discount_amount + "',pm_netamount='" + pm_netamount + "',pm_tax_excluded_amt='" + pm_tax_excluded_amt + "',pm_tax_amount='" + pm_tax_amount + "',pm_ref_no='" + pm_id + "',pm_roundoff=" + roundOffVal + " WHERE pm_id='" + pm_id + "'";
                bool update_sales_result = db.ExecuteQueryForTransaction(update_salesmaster_qry);
            //inserts to transaction table
                //inserting order debit entry
                MySqlCommand cmdInsCr = new MySqlCommand();
                cmdInsCr.CommandText = "INSERT INTO `tbl_transactions` " +
                    " (`action_type`, `action_ref_id`, `partner_id`,`partner_type`, `user_id`, `narration`, `cr`,  `date`,`closing_balance`)" +
                    " select @action_type, @action_ref_id, @partner_id,@partner_type, @user_id, @narration, @cr, @date,(ifnull(sum(dr)-sum(cr),0)-@cr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type ";
                cmdInsCr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.PURCHASE);
                cmdInsCr.Parameters.AddWithValue("@action_ref_id", pm_id);
                cmdInsCr.Parameters.AddWithValue("@partner_id", filters["vendorId"]);
                cmdInsCr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.VENDOR);
                cmdInsCr.Parameters.AddWithValue("@user_id", filters["userid"]);
                cmdInsCr.Parameters.AddWithValue("@narration", "Purchase entry #" + filters["invoiceno"] + " is purchased with net amount " + pm_netamount);
                cmdInsCr.Parameters.AddWithValue("@cr", pm_netamount);
                cmdInsCr.Parameters.AddWithValue("@date", currdatetime);
                db.ExecuteQueryForTransaction(cmdInsCr);

                //check is cash paid
                if (Convert.ToDouble(filters["PaidAmount"]) > 0)
                {
                    //inserting order credit entry
                    MySqlCommand cmdInsDr = new MySqlCommand();
                    cmdInsDr.CommandText = "INSERT INTO `tbl_transactions` " +
                        " (`action_type`, `action_ref_id`, `partner_id`,`partner_type`, `user_id`, `narration`,cash_amt " +
                        (Convert.ToDouble(filters["ChequeAmount"]) != 0 ? ", `cheque_amt`, `cheque_no`, `cheque_date`, `cheque_bank`" : "") +
                        ", `dr`, `date`,`closing_balance`)" +
                        " select @action_type, @action_ref_id, @partner_id,@partner_type, @user_id, @narration,@cash_amt " +
                        (Convert.ToDouble(filters["ChequeAmount"]) != 0 ? ", @cheque_amt, @cheque_no, @cheque_date, @cheque_bank" : "") +
                        ", @dr, @date,(ifnull(sum(dr)-sum(cr),0)+@dr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type ";
                    cmdInsDr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.PURCHASE);
                    cmdInsDr.Parameters.AddWithValue("@action_ref_id", pm_id);
                    cmdInsDr.Parameters.AddWithValue("@partner_id", filters["vendorId"]);
                    cmdInsDr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.VENDOR);
                    cmdInsDr.Parameters.AddWithValue("@user_id", filters["userid"]);
                    cmdInsDr.Parameters.AddWithValue("@narration", "Paid " + filters["PaidAmount"] + " for Purchase entry #" + filters["invoiceno"]);
                    cmdInsDr.Parameters.AddWithValue("@cash_amt", Convert.ToDecimal(filters["CashAmount"]));
                    //cmdInsDr.Parameters.AddWithValue("@card_amt", neworder["sessionId"]);
                    //cmdInsDr.Parameters.AddWithValue("@card_no", neworder["sessionId"]);
                    if (Convert.ToDouble(filters["CashAmount"]) != 0)
                    {
                        cmdInsDr.Parameters.AddWithValue("@cheque_amt", filters["ChequeAmount"]);
                        cmdInsDr.Parameters.AddWithValue("@cheque_no", filters["ChequeNo"]);
                        cmdInsDr.Parameters.AddWithValue("@cheque_date", filters["ChequeDate"]);
                        cmdInsDr.Parameters.AddWithValue("@cheque_bank", filters["BankName"]);
                    }

                    cmdInsDr.Parameters.AddWithValue("@dr", filters["PaidAmount"]);
                    cmdInsDr.Parameters.AddWithValue("@date", currdatetime);
                    db.ExecuteQueryForTransaction(cmdInsDr);
                }

                string update_vendor_qry = "UPDATE tbl_vendor SET vn_balance=(select (sum(cr)-sum(dr)) from tbl_transactions where partner_id='" + filters["vendorId"] + "' and partner_type=" + (int)Constants.PartnerType.VENDOR + ") WHERE vn_id='" + filters["vendorId"] + "'";
                bool upvndr_result = db.ExecuteQueryForTransaction(update_vendor_qry);

               if(upvndr_result){
                   checkstatus = "Y";
               }
                db.CommitTransaction();
        }
        catch (Exception ex)
        {
            try // IF TRANSACTION FAILES
            {
                result = "FAILED";
                db.RollBackTransaction();
                LogClass log = new LogClass("purchseOrder");
                log.write(ex);
                return result;
            }
            catch
            {
            }

            throw ex;
        }
        return checkstatus;
    }

    [WebMethod]
    public static string searchVendors(int page, Dictionary<string, string> filters, int perpage)
    {

        // string outputval = "okkkkkkkkkkk";


        try
        {

            string query_condition = " where 1=1 ";
            if (filters.Count > 0)
            {
                if (filters.ContainsKey("vendorname"))
                {
                    query_condition += " and vn_name  LIKE '%" + filters["vendorname"] + "%'";
                }
                if (filters.ContainsKey("vendorid"))
                {
                    query_condition += " and vn_id  LIKE '%" + filters["vendorid"] + "%'";
                }
            }
            int per_page = perpage;
            int offset = (page - 1) * per_page;
            mySqlConnection db = new mySqlConnection();
            string innerqry = "";
            string countQry = "SELECT count(*) FROM tbl_vendor" + query_condition;
            double numrows = Convert.ToInt32(db.SelectScalar(countQry));
            if (numrows == 0)
            {
                return "N";
            }
            int total_pages = Convert.ToInt32(Math.Ceiling(numrows / per_page));

            innerqry = "SELECT vn_id,vn_name,vn_phone1 from tbl_vendor ";
            innerqry = innerqry + query_condition + " order by vn_id LIMIT " + offset.ToString() + " ," + per_page;
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

    //show branches
    [WebMethod]
    public static string showBranches()
    {

        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        StringBuilder sb = new StringBuilder();

        string query = "select tb.branch_id,branch_name,branch_tax_method,branch_tax_inclusive from tbl_branch tb inner join tbl_user_branches ub on ub.branch_id=tb.branch_id where user_id=" + HttpContext.Current.Request.Cookies["invntrystaffId"].Value;
        // string query = "SELECT branch_id,branch_name,branch_tax_method FROM tbl_branch ORDER BY branch_id ASC";
        dt = db.SelectQuery(query);
        if (dt != null)
        {
            if (dt.Rows.Count > 0)
            {
                if (dt.Rows[0]["branch_id"] is DBNull)
                {
                    // sb.Append("<select id='combobranchtype' class='form-control' onchange=''>");
                    sb.Append("<option value='0' selected='selected' taxType='-1' inclusiveStatus='-1'>--Warehouse--</option>");
                    //sb.Append("</select>");
                }
                else
                {
                    // sb.Append("<select id='combobranchtype' class='form-control'  onchange=''>");
                    sb.Append("<option value='0' selected='selected' taxType='-1' inclusiveStatus='-1'>--Warehouse--</option>");
                    for (int i = 0; i < dt.Rows.Count; i++)
                    {

                        sb.Append("<option value='" + dt.Rows[i]["branch_id"] + "' taxType=" + dt.Rows[i]["branch_tax_method"] + " inclusiveStatus=" + dt.Rows[i]["branch_tax_inclusive"] + ">" + dt.Rows[i]["branch_name"] + "</option>");

                    }
                    // sb.Append("</select>");
                }
            }
            else
            {
                sb.Append("<option value='0' selected='selected' taxType='-1'>--Warehouse--</option>");
                // sb.Append("<select id='combobranchtype'>");
                //sb.Append("</select>");
            }
        }
        return sb.ToString();
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
            string query = "SELECT tp_tax_title,tp_tax_code FROM tbl_tax_profile where tp_tax_type=" + taxType + " ORDER BY tp_tax_code ASC";
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

                            sb.Append("<option value='" + dt.Rows[i]["tp_tax_code"] + "'>" + dt.Rows[i]["tp_tax_title"] + "</option>");

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
    public static string addBranchStockDetails(string branch, string item, string pricegroup_one, string pricegroup_two, string pricegroup_three, string taxcode, string purchasePrice)
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
            query = "INSERT INTO tbl_itembranch_stock (itbs_id,branch_id, itm_id, itbs_stock, itbs_reorder, itbs_available, itm_code, itm_name,itm_brand_id,itm_category_id,itm_subcategory_id,itm_mrp,itm_commision,itm_target,tp_tax_code,itbs_purchase_price)";
            query = query + "VALUES ('" + branchstockid + "','" + branch + "','" + item + "','0','0','1','" + dt1.Rows[0]["itm_code"] + "','" + dt1.Rows[0]["itm_name"] + "','" + dt1.Rows[0]["itm_brand_id"] + "','" + dt1.Rows[0]["itm_category_id"] + "','" + dt1.Rows[0]["itm_subcategory_id"] + "','0','0','0','" + taxcode + "','"+purchasePrice+"')";
        
        queryStatus = db.ExecuteQuery(query);
        if (queryStatus)
        {
            resultStatus = "Y";
        }
        // Response.Redirect("~/ManagePatientsAlertAndSurvey.aspx?id="+ViewState["patientId"].ToString()+"");
        return resultStatus;
    }

    [WebMethod]
    public static string getBrands()
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        //string query = "SELECT Id, Name,CountryId FROM Branch ORDER BY Name ASC";
        string query = "select brand_id,brand_name from tbl_item_brand";
        //string query = "select tb.branch_id,branch_name from tbl_branch tb inner join tbl_user_branches ub on ub.branch_id=tb.branch_id where user_id=" + HttpContext.Current.Request.Cookies["invntrystaffId"].Value;
        //    query = query + " order by tbl_branch.branch_id";
        dt = db.SelectQuery(query);
        return JsonConvert.SerializeObject(dt, Formatting.Indented);
    }

    [WebMethod]
    public static string getCategories()
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        //string query = "SELECT Id, Name,CountryId FROM Branch ORDER BY Name ASC";
        string query = "select cat_id,cat_name from tbl_item_category";
        //string query = "select tb.branch_id,branch_name from tbl_branch tb inner join tbl_user_branches ub on ub.branch_id=tb.branch_id where user_id=" + HttpContext.Current.Request.Cookies["invntrystaffId"].Value;
        //    query = query + " order by tbl_branch.branch_id";
        dt = db.SelectQuery(query);
        return JsonConvert.SerializeObject(dt, Formatting.Indented);
    }
}