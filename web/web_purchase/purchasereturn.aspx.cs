using commonfunction;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;
using MySql.Data.MySqlClient;
using System.Text;

public partial class web_purchase_purchasereturn : System.Web.UI.Page
{
    public string branchDetails;
    protected void Page_Load(object sender, EventArgs e)
    {
        mySqlConnection db = new mySqlConnection();
        LoginAuthentication bill = new LoginAuthentication();
        bill.userAuthentication();
        bill.checkPageAcess(38);
        string qry = "SELECT branch_tax_method,branch_tax_inclusive from tbl_branch where branch_id='" + HttpContext.Current.Request.Cookies["invntrystaffBranchId"].Value + "' ";
        DataTable branchDt = db.SelectQuery(qry);
        branchDetails = JsonConvert.SerializeObject(branchDt, Formatting.Indented);
    }

    [WebMethod]
    public static string showVendorDetails(string vendorId)
    {
        mySqlConnection db = new mySqlConnection();
        StringBuilder sb = new StringBuilder();
        string vendorDetailQry = "select tv.vn_name as name,tv.vn_city,tv.vn_phone1,tv.vn_email,tv.vn_balance as outstanding from tbl_vendor tv where vn_id=" + vendorId + " ";
        DataTable dt = new DataTable();
        dt = db.SelectQuery(vendorDetailQry);
        sb.Append("{");
        if (dt.Rows.Count > 0)
        {
            sb.Append("\"vendor\":");
            sb.Append(JsonConvert.SerializeObject(dt, Formatting.Indented));
            sb.Append(",");

        }

        String returnQry = "select prm_id,tr.prm_invoice_no,DATE_FORMAT(`prm_date`, '%d-%b-%Y %h:%i %p') as date,"
        + " prm_description as narration,concat(tu.first_name,' ',tu.last_name) as user_name,prm_status,prm_amount as amount"
        + " from tbl_purchase_return_master tr  inner join tbl_user_details tu on tu.user_id=tr.prm_userid"
        + " where tr.vendor_id=" + vendorId;
        DataTable dtReturn = db.SelectQuery(returnQry);
        sb.Append("\"return_details\":");
        sb.Append(JsonConvert.SerializeObject(dtReturn, Formatting.Indented));
        sb.Append("}");
        return sb.ToString();
    }

    [WebMethod]
    public static string showReturnDetails(string returnId)
    {
        mySqlConnection db = new mySqlConnection();
        string returnQry = "select pri_id as id,itm_code as code,itm_name as name,pi_price as price,pri_qty as qty,prm.prm_invoice_no,"
            + "pri_total as total,pri_type as type,tpi.pm_id,tpi.prm_id,pri_tax_percentage as tax,pri_cess as cess,itbs_id,tb.branch_tax_method,tb.branch_tax_inclusive,pri_tax_amount as tax_amount,tb.branch_id  from tbl_purchase_return_items tpi left join tbl_purchase_master tpm on tpm.pm_id=tpi.pm_id inner join tbl_purchase_return_master prm on prm.prm_id=tpi.prm_id inner join tbl_branch tb on tb.branch_id=prm.branch_id where tpi.prm_id=" + returnId;
        DataTable returnDt = db.SelectQuery(returnQry);
        return JsonConvert.SerializeObject(returnDt, Formatting.Indented);

    }

    [WebMethod]
    public static string searchOrderitems(Dictionary<string, string> filters)
    {
        mySqlConnection db = new mySqlConnection();
        string qry_condition = " where 1 ";
        if (filters.Count > 0)
        {
            if (filters["brand"] != "-1")
            {
                qry_condition += " and itb.itm_brand_id='" + filters["brand"] + "' ";
            }
            if (filters["category"] != "-1")
            {
                qry_condition += " and itb.itm_category_id='" + filters["category"] + "' ";
            }
            if (filters["searchCod"] != "")
            {
                qry_condition += " and itb.itm_code like '%" + filters["searchCod"] + "%'";
            }
            if (filters["searchName"] != "")
            {
                qry_condition += " and itb.itm_name like '%" + filters["searchName"] + "%'";
            }
            if (filters["searchInvoiceNum"] != "")
            {
                qry_condition += " and pm.pm_invoice_no like '%" + filters["searchInvoiceNum"] + "%'";
            }
        }
        string itemqry = "select pm.pm_invoice_no,pm.pm_id,pi.itbs_id as itbs_id,pi_id as ItemId,pi.itm_name,"
            + " pi.itm_code,pi.pi_qty,(pi.pi_qty) as total_qty,"
            + " pi.pi_discount_rate,DATE_FORMAT(pm.pm_date, '%d %M %Y') as pm_date,"
            + " pm.vn_id ,pi.pi_price,IFNULL(sum(CASE WHEN (pr.pri_qty)"
            + " THEN pr.pri_qty ELSE 0 END),0) as returned ,"
            + " (pi.pi_net_amount/pi.pi_qty) as return_price,pi.pi_item_cess,pi.pi_item_tax"
            + " from tbl_purchase_master pm join tbl_purchase_items pi on pi.pm_id=pm.pm_id"
            + " join tbl_itembranch_stock itb on itb.itbs_id=pi.itbs_id "
            + " left join tbl_purchase_return_items pr on (pr.itbs_id=itb.itbs_id and pm.pm_id=pr.pm_id ) "
            + " " + qry_condition + ""
            + " and pm.pm_status=1 and pm.vn_id='" + filters["vendorId"] + "'"
            + " group by pi_id having total_qty>returned order by pm.pm_date desc";
        // string itemqry = "select itbs_id as uniqueid,itm_code,itm_name,pi_price,(pi.pi_qty-IFNULL((select sum(pri_qty) from tbl_purchase_return_items sr where pr.pm_id=" + orderid + " and pr.itbs_id=pi.itbs_id),0)) as totalqty,(pi_net_amount/pi_qty) as price,pi_net_amount from tbl_purchase_items si " + qry_condition;
        DataTable dt = new DataTable();
        dt = db.SelectQuery(itemqry);
        string jsonresponse = "";
        if (dt.Rows.Count > 0)
        {
            jsonresponse = JsonConvert.SerializeObject(dt, Formatting.Indented);
        }
        else
        {
            jsonresponse = "N";
        }
        return jsonresponse;
    }


    [WebMethod]
    public static string purchase_return(Dictionary<string, string> return_order)
    {
        string result = "";
        string debited_amount = "";
        string new_balance = "";
        mySqlConnection db = new mySqlConnection();
        try
        {
            // getting timezone from branch
            db.BeginTransaction();


            string branchQry = "select branch_timezone from tbl_branch where branch_id='" + return_order["branchid"] + "'";
            //  string branch_timezone = return_order["branch_time_zone"];
            DataTable cTimeZone = db.SelectQueryForTransaction(branchQry);
            string branch_timezone = Convert.ToString(cTimeZone.Rows[0]["branch_timezone"]);
            TimeZoneInfo CurrentZone = TimeZoneInfo.FindSystemTimeZoneById(branch_timezone);
            DateTime TimeNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, CurrentZone);
            string prm_date = TimeNow.ToString("yyyy/MM/dd HH:mm:ss");

            string branchPrefix = "";
            int branchStart = 0;
            string branchSuffix = "";

            string prefix = "";
            int returnStart = 0;
            string suffix = "";


            string getvalues = "SELECT branch_returnPrefixPur,branch_returnSuffixPur,branch_returnSINoPur from tbl_branch where branch_id='" + return_order["branchid"] + "'";
            DataTable dts = db.SelectQueryForTransaction(getvalues);

            branchPrefix = Convert.ToString(dts.Rows[0]["branch_returnPrefixPur"]);
            branchStart = Convert.ToInt32(dts.Rows[0]["branch_returnSINoPur"]);
            branchSuffix = Convert.ToString(dts.Rows[0]["branch_returnSuffixPur"]);

            prefix = branchPrefix;
            returnStart = branchStart;
            suffix = branchSuffix;

            string suffixQry = "SELECT IFNULL(max(prm_slno),0) FROM tbl_purchase_return_master where branch_id=" + return_order["branchid"] + "  and prm_prefix='" + prefix + "' and prm_suffix='" + suffix + "'";
            int invoiceSerialNo = Convert.ToInt32(db.SelectScalarForTransaction(suffixQry));
            if (invoiceSerialNo == 0)
            {
                if (returnStart != null)
                {
                    invoiceSerialNo = returnStart + 1;
                }
            }
            else
            {
                invoiceSerialNo = Math.Max(returnStart, invoiceSerialNo);
                invoiceSerialNo = invoiceSerialNo + 1;
            }
           


            // INSERTING TO PURCHASE RETURN MASTER
            string prm_insert_qry = "INSERT INTO `tbl_purchase_return_master` (`pm_id`, `vendor_id`,`prm_invoice_no`, `prm_userid`, `branch_id`, `prm_description`,`prm_date`,`prm_session_id`,`prm_status`,`prm_last_update_date`) VALUES('0','" + return_order["vn_id"] + "','','" + return_order["user_id"] + "','" + return_order["branchid"] + "','" + return_order["description"] + "','" + prm_date + "','" + return_order["session_id"] + "','" + return_order["status"] + "','" + prm_date + "');Select last_insert_id();";
            var last_id = db.SelectScalarForTransaction(prm_insert_qry);
            Int32 prm_id = Convert.ToInt32(last_id);

            

            // END OF INSERTING TO PURCHASE RETURN MASTER
            // getting returned items
            List<Dictionary<string, string>> return_Items = JsonConvert.DeserializeObject<List<Dictionary<string, string>>>(return_order["return_Items"]);
            dynamic return_data = JsonConvert.DeserializeObject(return_order["return_Items"]);
            string ret_items = "";
            for (int i = 0; i < Convert.ToInt32(return_order["item_count"]); i++)
            {
                if (i == 0)
                {
                    ret_items = return_data[i].itbs_id;
                }
                else
                {
                    ret_items = ret_items + "," + return_data[i].itbs_id;
                }

            }

            string batch_insert_items_header = "INSERT INTO `tbl_purchase_return_items` (`prm_id`, `pm_id`, `row_no`, `itbs_id`, `itm_code`, `itm_name`, `pi_price`, `pi_discount_rate`, `pri_qty`, `pri_discount_amount`,`pri_tax_percentage`,`pri_cess`,`pri_tax_amount`, `pri_total`, `pri_type`) VALUES";
            string batch_insert_items = "";
            decimal prm_amount = 0;

            for (int i = 0; i < Convert.ToInt32(return_order["item_count"]); i++)
            {

                if (i == 0)
                {
                    batch_insert_items = "('" + prm_id + "','" + return_data[i].pm_id + "','" + i + "','" + return_data[i].itbs_id + "','" + return_data[i].itm_code + "','" + return_data[i].itm_name + "','" + return_data[i].pi_price + "','" + return_data[i].pi_discount_rate + "','" + return_data[i].pri_qty + "','0','" + return_data[i].pri_tax_percentage + "','" + return_data[i].pri_cess + "','" + return_data[i].pri_tax_amount + "','" + return_data[i].pri_total + "','" + return_data[i].pri_type + "')";
                }
                else
                {
                    batch_insert_items = batch_insert_items + "," + "('" + prm_id + "','" + return_data[i].pm_id + "','" + i + "','" + return_data[i].itbs_id + "','" + return_data[i].itm_code + "','" + return_data[i].itm_name + "','" + return_data[i].pi_price + "','" + return_data[i].pi_discount_rate + "','" + return_data[i].pri_qty + "','0','" + return_data[i].pri_tax_percentage + "','" + return_data[i].pri_cess + "','" + return_data[i].pri_tax_amount + "','" + return_data[i].pri_total + "','" + return_data[i].pri_type + "')";
                }

                prm_amount = prm_amount + Convert.ToDecimal(return_data[i].pri_total);
                debited_amount = prm_amount.ToString();

                // decrease stock for ready to use items // UNUSED CODE - STOCK NOT UPDATING NOW
                //if (return_data[i].pri_type == "5")
                //{
                string new_stockQry = "UPDATE tbl_itembranch_stock SET itbs_stock= itbs_stock - " + return_data[i].pri_qty + ",itm_last_update_date='" + prm_date + "' where itbs_id='" + return_data[i].itbs_id + "'";
                db.SelectScalarForTransaction(new_stockQry);

                StringBuilder can_sb_bulk_stkTrQry = new StringBuilder();
                can_sb_bulk_stkTrQry.Append("INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`action_ref_id`,`user_id`,`narration`,`dr_qty`,`closing_stock`,`date`) VALUES ");
                // stock transaction
                can_sb_bulk_stkTrQry.Append("('" + Convert.ToString(return_data[i].itbs_id) + "','" + ((int)Constants.ActionType.PURCHASE_RETURN) + "','" + return_data[i].pm_id + "','" + return_order["user_id"] + "'");
                can_sb_bulk_stkTrQry.Append(",'PURCHASE RETURN: (stock decrease) " + return_data[i].pri_qty + " qty " + Convert.ToString(return_data[i].itm_name) + " from order #" + return_data[i].pm_id + "','" + return_data[i].pri_qty + "'");
                can_sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + Convert.ToString(return_data[i].itbs_id) + "')");
                can_sb_bulk_stkTrQry.Append(",'" + prm_date + "');");
                db.ExecuteQueryForTransaction(can_sb_bulk_stkTrQry.ToString());
                //}
            }

            string saveToPurchaseReturnItemsasBatch = batch_insert_items_header + batch_insert_items;
            bool batch_result = db.ExecuteQueryForTransaction(saveToPurchaseReturnItemsasBatch);

            if (batch_result)
            {
                // updating Purchase return master
                string update_Purchase_return = "UPDATE tbl_purchase_return_master SET prm_amount='" + prm_amount + "' where prm_id='" + prm_id + "'";
                bool pm_result = db.ExecuteQueryForTransaction(update_Purchase_return);

                //inserts to transaction table
                //inserting order debit entry
                MySqlCommand cmdInsDr = new MySqlCommand();
                cmdInsDr.CommandText = "INSERT INTO `tbl_transactions` " +
                    " (`session_id`,`action_type`, `action_ref_id`, `partner_id`,`partner_type`,`branch_id`, `user_id`, `narration`, `dr`,  `date`,`closing_balance`)" +
                    " select @session_id,@action_type, @action_ref_id, @partner_id,@partner_type,@branch_id, @user_id, @narration, @dr, @date,(ifnull(sum(dr)-sum(cr),0)-@dr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type and branch_id=@branch_id  ";
                cmdInsDr.Parameters.AddWithValue("@session_id", return_order["session_id"]);
                cmdInsDr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.PURCHASE_RETURN);
                cmdInsDr.Parameters.AddWithValue("@action_ref_id", prm_id);
                cmdInsDr.Parameters.AddWithValue("@partner_id", return_order["vn_id"]);
                cmdInsDr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.VENDOR);
                cmdInsDr.Parameters.AddWithValue("@branch_id", return_order["branchid"]);
                cmdInsDr.Parameters.AddWithValue("@user_id", return_order["user_id"]);
                cmdInsDr.Parameters.AddWithValue("@narration", "Return of items worth " + prm_amount);
                cmdInsDr.Parameters.AddWithValue("@dr", prm_amount);
                cmdInsDr.Parameters.AddWithValue("@date", prm_date);
                db.ExecuteQueryForTransaction(cmdInsDr);

                string update_tbl_vendor = "UPDATE tbl_vendor SET vn_balance=(select (sum(cr)-sum(dr)) from tbl_transactions  where partner_id='" + return_order["vn_id"] + "' and partner_type=" + (int)Constants.PartnerType.VENDOR + ") where vn_id=" + return_order["vn_id"] + "; SELECT vn_balance FROM tbl_vendor WHERE vn_id=" + return_order["vn_id"];
                new_balance = db.SelectScalarForTransaction(update_tbl_vendor);
                string upd_pur_master = "UPDATE tbl_purchase_return_master SET " + "prm_prefix='" + prefix + "',prm_slno=" + invoiceSerialNo + ",prm_suffix='" + suffix + "',prm_invoice_no=concat(prm_prefix,prm_slno,prm_suffix),prm_status='1' where prm_id='" + prm_id + "'";
                db.ExecuteQueryForTransaction(upd_pur_master);
                result = "SUCCESS";

            }
            else
            {
                result = "FAILED";
                db.RollBackTransaction();
                return result;
            }

            db.CommitTransaction();
            result = "SUCCESS";

        }
        catch (Exception ex)
        {
            try // IF TRANSACTION FAILES
            {
                result = "FAILED";
                db.RollBackTransaction();
                LogClass log = new LogClass("Purchase_return");
                log.write(ex);
                return result;
            }
            catch
            {
            }
        }
        return result;
    }

    [WebMethod]
    public static string getBrands()
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        //string query = "SELECT Id, Name,CountryId FROM Branch ORDER BY Name ASC";
        string query = "select brand_id,brand_name from tbl_item_brand";

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
        dt = db.SelectQuery(query);
        return JsonConvert.SerializeObject(dt, Formatting.Indented);
    }

    [WebMethod]
    public static string search_return_item(Dictionary<string, string> filters)
    {
        string result = "";
        mySqlConnection db = new mySqlConnection();
        string brand_qry = "";
        string category_qry = "";

        if (filters.Count > 0)
        {
            if (filters["brand"] != "x")
            {
                brand_qry = " and itb.itm_brand_id='" + filters["brand"] + "' ";
            }
            else
            {
                brand_qry = " ";
            }

            if (filters["category"] != "x")
            {
                category_qry = " and itb.itm_category_id='" + filters["category"] + "' ";
            }
            else
            {
                category_qry = " ";
            }
        }

        string qry = "SELECT itb.itbs_id,itb.itm_name,itb.itm_code,tp.tp_tax_percentage,tp.tp_cess FROM  tbl_itembranch_stock itb INNER JOIN tbl_tax_profile tp ON tp.tp_tax_code=itb.tp_tax_code   where itb.branch_id='" + filters["branch_id"] + "' and itb.itm_name like '%" + filters["searchTerm"] + "%'" + brand_qry + category_qry + " LIMIT 5 ";
        DataTable dt = db.SelectQuery(qry);

        string qry2 = "select IFNULL(pm.pm_invoice_no,'NIL') AS pm_invoice_no,pm.pm_id,pi.itbs_id,pi.itm_name,pi.itm_code,pi.pi_qty as total_qty,pi.pi_discount_rate,DATE_FORMAT(pm.pm_date, '%d %M %Y') as pm_date,pm.vn_id ,pi.pi_price,IFNULL(sum(CASE WHEN (pr.pri_qty) THEN pr.pri_qty ELSE 0 END),0) as returned ,(pi.pi_net_amount/pi.pi_qty) as return_price,pi.pi_item_cess,pi.pi_item_tax from tbl_purchase_master pm join tbl_purchase_items si on pi.pm_id=pm.pm_id join tbl_itembranch_stock itb on itb.itbs_id=pi.itbs_id left join tbl_purchase_return_items sr on (pr.itbs_id=itb.itbs_id and pm.pm_id=pr.pm_id ) where pm.branch_id='" + filters["branch_id"] + "' and pi.itm_name like '%" + filters["searchTerm"] + "%'" + brand_qry + category_qry + " and pm.pm_status=1  and pm.vn_id='" + filters["vendorid"] + "' group by pi.pi_id having total_qty>returned order by pm.pm_date desc";
        DataTable dt2 = db.SelectQuery(qry2);

        StringBuilder sb = new StringBuilder();
        sb.Append("{");

        sb.Append("\"dl_count\":\"" + dt2.Rows.Count + "\"");
        sb.Append(",");
        sb.Append("\"data_count\":\"" + dt.Rows.Count + "\"");

        if (dt.Rows.Count > 0)
        {
            sb.Append(",");
            sb.Append("\"data\":");
            sb.Append(JsonConvert.SerializeObject(dt, Formatting.Indented));
        }
        if (dt2.Rows.Count > 0)
        {
            sb.Append(",");
            sb.Append("\"dl_data\":");
            sb.Append(JsonConvert.SerializeObject(dt2, Formatting.Indented));
        }

        sb.Append("}");

        return sb.ToString();

    }

    [WebMethod]
    public static string searchBasicItems(Dictionary<string, string> filters)
    {
        mySqlConnection db = new mySqlConnection();
        string qry_condition = " where 1 and itb.branch_id='" + HttpContext.Current.Request.Cookies["invntrystaffBranchId"].Value + "' ";
        if (filters.Count > 0)
        {
            if (filters["brand"] != "-1")
            {
                qry_condition += " and itb.itm_brand_id='" + filters["brand"] + "' ";
            }
            if (filters["category"] != "-1")
            {
                qry_condition += " and itb.itm_category_id='" + filters["category"] + "' ";
            }
            if (filters["searchCod"] != "")
            {
                qry_condition += " and itb.itm_code like '%" + filters["searchCod"] + "%'";
            }
            if (filters["searchName"] != "")
            {
                qry_condition += " and itb.itm_name like '%" + filters["searchName"] + "%'";
            }
        }
        int per_page = Convert.ToInt32(filters["perPage"]);
        int offset = (Convert.ToInt32(filters["page"]) - 1) * per_page;
        string countQry = "SELECT count(itb.itbs_id) FROM tbl_itembranch_stock itb INNER JOIN"
        + " tbl_tax_profile tp ON tp.tp_tax_code=itb.tp_tax_code " + qry_condition;

        double numrows = Convert.ToInt32(db.SelectScalar(countQry));
        string qry = "SELECT itb.itbs_id,itb.itm_name,itb.itm_code,itb.itbs_purchase_price as itm_price,"//and tpm_id=" + filters["cust_class"] + " ) as"
        + " tp.tp_tax_percentage,tp.tp_cess FROM tbl_itembranch_stock itb INNER JOIN"
        + " tbl_tax_profile tp ON tp.tp_tax_code=itb.tp_tax_code INNER JOIN tbl_item_pricelist tip ON tip.itbs_id=itb.itbs_id " + qry_condition + " GROUP BY itb.itbs_id LIMIT " + offset.ToString() + " ," + per_page;
        DataTable dt = db.SelectQuery(qry);

        string jsonresponse = "";
        if (dt.Rows.Count > 0)
        {
            string jsonData = JsonConvert.SerializeObject(dt, Formatting.Indented);
            jsonresponse = "{\"count\":\"" + numrows + "\",\"data\":" + jsonData + "}";
        }
        else
        {
            jsonresponse = "N";
        }
        return jsonresponse;

    }


    [WebMethod]
    public static string Edit_purchase_Return_Item(Dictionary<string, string> return_data)
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
        var current_status = db.SelectScalar("SELECT prm_status FROM tbl_purchase_return_master WHERE tbl_purchase_return_master.prm_id='" + return_data["prm_id"] + "'");
        if (current_status.ToString() == "4")
        {
            result = "CANCEL";
        }
        else
        {
            var current_itm_info = db.SelectQuery("SELECT pri.pri_qty,pri.pi_price,prm.prm_amount,pri.pri_type,prm.vendor_id,pri.itbs_id,pri.pm_id,prm.branch_id,prm.prm_id,pri.itm_name FROM tbl_purchase_return_items pri INNER JOIN tbl_purchase_return_master prm ON prm.prm_id=pri.prm_id WHERE pri.pri_id='" + return_data["pri_id"] + "'");
            if (current_itm_info.Rows.Count == 0)
            {
                result = "ONEITEM";
                return result;
            }

            if (Convert.ToInt32(current_itm_info.Rows[0]["pri_qty"]) != Convert.ToInt32(return_data["pri_qty"]) || Convert.ToDecimal(current_itm_info.Rows[0]["pi_price"]) != Convert.ToDecimal(return_data["pi_price"]))
            {


                try
                {
                    db.BeginTransaction();

                    //1. UPDATE PURCHASE RETURN ITEMS
                    bool up_pri_qry = db.ExecuteQueryForTransaction("UPDATE tbl_purchase_return_items SET pri_qty='" + return_data["pri_qty"] + "',pi_price='" + return_data["pi_price"] + "',pri_tax_amount='" + return_data["pri_tax_amount"] + "',pri_total='" + return_data["pri_total"] + "' WHERE pri_id='" + return_data["pri_id"] + "' ");
                    if (up_pri_qry)
                    {
                        var new_prm_amount = db.SelectScalarForTransaction("SELECT SUM(pri_total) FROM tbl_purchase_return_items WHERE prm_id='" + return_data["prm_id"] + "'");

                        //2. UPDATE PURCHASE RETURN MASTER
                        if (Convert.ToDecimal(new_prm_amount) != Convert.ToDecimal(current_itm_info.Rows[0]["prm_amount"]))
                        {
                            db.ExecuteQueryForTransaction("UPDATE tbl_purchase_return_master SET prm_amount='" + new_prm_amount + "'  WHERE prm_id='" + return_data["prm_id"] + "'");

                            Int32 stock_diff = 0;
                            //IF ITEM QUANTITY CHANGED & READY TO USE ITEM // update to stock transaction
                            if ((Convert.ToInt32(current_itm_info.Rows[0]["pri_qty"]) != Convert.ToInt32(return_data["pri_qty"])) && (Convert.ToInt32(current_itm_info.Rows[0]["pri_type"]) == 2))
                            {

                                // if current qty becomes higher -> decrease stock
                                if (Convert.ToInt32(current_itm_info.Rows[0]["pri_qty"]) < Convert.ToInt32(return_data["pri_qty"]))
                                {
                                    stock_diff = Convert.ToInt32(return_data["pri_qty"]) - Convert.ToInt32(current_itm_info.Rows[0]["pri_qty"]);

                                    db.ExecuteQueryForTransaction("UPDATE tbl_itembranch_stock SET itbs_stock=(itbs_stock - " + stock_diff + "),itm_last_update_date='" + current_date + "' where itbs_id='" + current_itm_info.Rows[0]["itbs_id"].ToString() + "'");

                                    StringBuilder can_sb_bulk_stkTrQry = new StringBuilder();
                                    can_sb_bulk_stkTrQry.Append("INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`action_ref_id`,`user_id`,`narration`,`dr_qty`,`closing_stock`,`date`) VALUES ");
                                    // stock transaction
                                    can_sb_bulk_stkTrQry.Append("('" + Convert.ToString(current_itm_info.Rows[0]["itbs_id"].ToString() + "','" + (int)Constants.ActionType.PURCHASE_RETURN) + "','" + current_itm_info.Rows[0]["prm_id"].ToString() + "','" + return_data["user_id"].ToString() + "'");
                                    can_sb_bulk_stkTrQry.Append(",'PURCHASE RETURN: stock decrease by " + stock_diff + " qty of " + current_itm_info.Rows[0]["itm_name"].ToString() + " during Purchase Return Editing with Ref. ID #" + current_itm_info.Rows[0]["prm_id"].ToString() + "','" + stock_diff + "'");
                                    can_sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + current_itm_info.Rows[0]["itbs_id"].ToString() + "')");
                                    can_sb_bulk_stkTrQry.Append(",'" + current_date + "');");
                                    db.ExecuteQueryForTransaction(can_sb_bulk_stkTrQry.ToString());
                                }
                                else
                                {
                                    stock_diff = Convert.ToInt32(current_itm_info.Rows[0]["pri_qty"]) - Convert.ToInt32(return_data["pri_qty"]);
                                    // decrease stock here
                                    db.ExecuteQueryForTransaction("UPDATE tbl_itembranch_stock SET itbs_stock=(itbs_stock - " + stock_diff + "),itm_last_update_date='" + current_date + "' where itbs_id='" + current_itm_info.Rows[0]["itbs_id"].ToString() + "'");

                                    StringBuilder can_sb_bulk_stkTrQry = new StringBuilder();
                                    can_sb_bulk_stkTrQry.Append("INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`action_ref_id`,`user_id`,`narration`,`dr_qty`,`closing_stock`,`date`) VALUES ");
                                    // stock transaction
                                    can_sb_bulk_stkTrQry.Append("('" + Convert.ToString(current_itm_info.Rows[0]["itbs_id"].ToString() + "','" + (int)Constants.ActionType.PURCHASE_RETURN) + "','" + current_itm_info.Rows[0]["prm_id"].ToString() + "','" + return_data["user_id"].ToString() + "'");
                                    can_sb_bulk_stkTrQry.Append(",'PURCHASE RETURN: (stock decreased by " + stock_diff + " qty of " + current_itm_info.Rows[0]["itm_name"].ToString() + " during Purchase Return Editing with Ref. ID #" + current_itm_info.Rows[0]["prm_id"].ToString() + "','" + stock_diff + "'");
                                    can_sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + current_itm_info.Rows[0]["itbs_id"].ToString() + "')");
                                    can_sb_bulk_stkTrQry.Append(",'" + current_date + "');");
                                    db.ExecuteQueryForTransaction(can_sb_bulk_stkTrQry.ToString());
                                }
                            }

                            decimal current_amt = 0;

                            // if amount return decreased - debit to vendor as DEBIT ENTRY
                            if (Convert.ToDecimal(new_prm_amount) > Convert.ToDecimal(current_itm_info.Rows[0]["prm_amount"]))
                            {
                                current_amt = Convert.ToDecimal(new_prm_amount) - Convert.ToDecimal(current_itm_info.Rows[0]["prm_amount"]);
                                MySqlCommand cmdInsDr = new MySqlCommand();
                                cmdInsDr.CommandText = "INSERT INTO `tbl_transactions` " +
                                    " (`action_type`, `action_ref_id`, `partner_id`,`partner_type`,`branch_id`, `user_id`, `narration`, `dr`,  `date`,`closing_balance`)" +
                                    " select @action_type, @action_ref_id, @partner_id,@partner_type,@branch_id, @user_id, @narration, @dr, @date,(ifnull(sum(dr)-sum(cr),0)-@dr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type and branch_id=@branch_id  ";
                                //cmdInsDr.Parameters.AddWithValue("@session_id", return_order["session_id"]);
                                cmdInsDr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.PURCHASE_RETURN);
                                cmdInsDr.Parameters.AddWithValue("@action_ref_id", return_data["prm_id"]);
                                cmdInsDr.Parameters.AddWithValue("@partner_id", current_itm_info.Rows[0]["vendor_id"].ToString());
                                cmdInsDr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.VENDOR);
                                cmdInsDr.Parameters.AddWithValue("@branch_id", current_itm_info.Rows[0]["branch_id"].ToString());
                                cmdInsDr.Parameters.AddWithValue("@user_id", return_data["user_id"]);
                                cmdInsDr.Parameters.AddWithValue("@narration", "Amount debited due to Return Edit worth: " + current_amt);
                                cmdInsDr.Parameters.AddWithValue("@dr", current_amt);
                                cmdInsDr.Parameters.AddWithValue("@date", current_date);
                                db.ExecuteQueryForTransaction(cmdInsDr);

                            }
                            else
                            {
                                current_amt = Convert.ToDecimal(current_itm_info.Rows[0]["prm_amount"]) - Convert.ToDecimal(new_prm_amount);
                                MySqlCommand cmdInsDr = new MySqlCommand();
                                cmdInsDr.CommandText = "INSERT INTO `tbl_transactions` " +
                                    " (`action_type`, `action_ref_id`, `partner_id`,`partner_type`,`branch_id`, `user_id`, `narration`, `cr`,  `date`,`closing_balance`)" +
                                    " select @action_type, @action_ref_id, @partner_id,@partner_type,@branch_id, @user_id, @narration, @cr, @date,(ifnull(sum(dr)-sum(cr),0)-@cr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type and branch_id=@branch_id  ";
                                //cmdInsDr.Parameters.AddWithValue("@session_id", return_order["session_id"]);
                                cmdInsDr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.PURCHASE_RETURN);
                                cmdInsDr.Parameters.AddWithValue("@action_ref_id", return_data["prm_id"]);
                                cmdInsDr.Parameters.AddWithValue("@partner_id", current_itm_info.Rows[0]["vendor_id"].ToString());
                                cmdInsDr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.VENDOR);
                                cmdInsDr.Parameters.AddWithValue("@branch_id", current_itm_info.Rows[0]["branch_id"].ToString());
                                cmdInsDr.Parameters.AddWithValue("@user_id", return_data["user_id"]);
                                cmdInsDr.Parameters.AddWithValue("@narration", "Amount credited due to Return Edit worth: " + current_amt);
                                cmdInsDr.Parameters.AddWithValue("@cr", current_amt);
                                cmdInsDr.Parameters.AddWithValue("@date", current_date);
                                db.ExecuteQueryForTransaction(cmdInsDr);
                            }

                            //UPDATE VENDOR BALANCE IN VENDOR TABLE
                            db.ExecuteQueryForTransaction("UPDATE tbl_vendor SET vn_balance=(select (sum(cr)-sum(dr)) from tbl_transactions  where partner_id='" + current_itm_info.Rows[0]["vendor_id"].ToString() + "' and partner_type=" + (int)Constants.PartnerType.VENDOR + ") where vn_id=" + current_itm_info.Rows[0]["vendor_id"].ToString() + "");

                        }

                    }
                    db.CommitTransaction();
                    result = "Y";
                }
                catch (Exception ex)
                {
                    db.RollBackTransaction();
                    var log = new LogClass("Edit_purchase_Return_Item");
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
    public static string Remove_purchase_Return_Item(Dictionary<string, string> return_data)
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
        var current_status = db.SelectScalar("SELECT prm_status FROM tbl_purchase_return_master WHERE tbl_purchase_return_master.prm_id='" + return_data["prm_id"] + "'");
        if (current_status.ToString() == "4")
        {
            result = "CANCEL";
        }
        else
        {
            var current_itm_info = db.SelectQuery("SELECT pri.pri_qty,pri.pi_price,prm.prm_amount,pri.pri_type,prm.vendor_id,pri.itbs_id,pri.pm_id,prm.branch_id,prm.prm_id,pri.itm_name FROM tbl_purchase_return_items pri INNER JOIN tbl_purchase_return_master prm ON prm.prm_id=pri.prm_id WHERE pri.pri_id='" + return_data["pri_id"] + "'");
            if (current_itm_info.Rows.Count > 0)
            {
                var item_dt = db.SelectQuery("SELECT pri_id FROM tbl_purchase_return_items WHERE prm_id='" + return_data["prm_id"] + "'");
                if (item_dt.Rows.Count == 1)
                {
                    result = "ONEITEM";
                    return result;
                }

                try
                {
                    db.BeginTransaction();

                    //1. UPDATE PURCHASE RETURN ITEMS
                    bool up_pri_qry = db.ExecuteQueryForTransaction("DELETE FROM tbl_purchase_return_items  WHERE pri_id='" + return_data["pri_id"] + "' ");
                    if (up_pri_qry)
                    {
                        var new_prm_amount = db.SelectScalarForTransaction("SELECT SUM(pri_total) FROM tbl_purchase_return_items WHERE prm_id='" + return_data["prm_id"] + "'");

                        //2. UPDATE PURCHASE RETURN MASTER
                        if (Convert.ToDecimal(new_prm_amount) != Convert.ToDecimal(current_itm_info.Rows[0]["prm_amount"]))
                        {
                            db.ExecuteQueryForTransaction("UPDATE tbl_purchase_return_master SET prm_amount='" + new_prm_amount + "' WHERE prm_id='" + return_data["prm_id"] + "'");

                            Int32 stock_diff = 0;

                            // ENTRY TO STOCK TRANSFER
                            if (Convert.ToInt32(current_itm_info.Rows[0]["pri_type"]) == 2)
                            {

                                stock_diff = Convert.ToInt32(current_itm_info.Rows[0]["pri_qty"]);
                                // decrease stock here
                                db.ExecuteQueryForTransaction("UPDATE tbl_itembranch_stock SET itbs_stock=(itbs_stock - " + stock_diff + "),itm_last_update_date='" + current_date + "' where itbs_id='" + current_itm_info.Rows[0]["itbs_id"].ToString() + "'");

                                StringBuilder can_sb_bulk_stkTrQry = new StringBuilder();
                                can_sb_bulk_stkTrQry.Append("INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`action_ref_id`,`user_id`,`narration`,`dr_qty`,`closing_stock`,`date`) VALUES ");
                                // stock transaction
                                can_sb_bulk_stkTrQry.Append("('" + Convert.ToString(current_itm_info.Rows[0]["itbs_id"].ToString() + "','" + (int)Constants.ActionType.PURCHASE_RETURN) + "','" + current_itm_info.Rows[0]["prm_id"].ToString() + "','" + return_data["user_id"].ToString() + "'");
                                can_sb_bulk_stkTrQry.Append(",'PURCHASE RETURN: (stock decreased by " + stock_diff + " qty of " + current_itm_info.Rows[0]["itm_name"].ToString() + " during removal from Purchase Return with Ref. ID #" + current_itm_info.Rows[0]["prm_id"].ToString() + "','" + stock_diff + "'");
                                can_sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + current_itm_info.Rows[0]["itbs_id"].ToString() + "')");
                                can_sb_bulk_stkTrQry.Append(",'" + current_date + "');");
                                db.ExecuteQueryForTransaction(can_sb_bulk_stkTrQry.ToString());

                            }

                            decimal current_amt = 0;

                            // if amount return decreased - debit to vendor as DEBIT ENTRY
                            if (Convert.ToDecimal(new_prm_amount) > Convert.ToDecimal(current_itm_info.Rows[0]["prm_amount"]))
                            {
                                current_amt = Convert.ToDecimal(new_prm_amount) - Convert.ToDecimal(current_itm_info.Rows[0]["prm_amount"]);
                                MySqlCommand cmdInsDr = new MySqlCommand();
                                cmdInsDr.CommandText = "INSERT INTO `tbl_transactions` " +
                                    " (`action_type`, `action_ref_id`, `partner_id`,`partner_type`,`branch_id`, `user_id`, `narration`, `dr`,  `date`,`closing_balance`)" +
                                    " select @action_type, @action_ref_id, @partner_id,@partner_type,@branch_id, @user_id, @narration, @dr, @date,(ifnull(sum(dr)-sum(cr),0)-@dr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type and branch_id=@branch_id  ";
                                //cmdInsDr.Parameters.AddWithValue("@session_id", return_order["session_id"]);
                                cmdInsDr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.PURCHASE_RETURN);
                                cmdInsDr.Parameters.AddWithValue("@action_ref_id", return_data["prm_id"]);
                                cmdInsDr.Parameters.AddWithValue("@partner_id", current_itm_info.Rows[0]["vendor_id"].ToString());
                                cmdInsDr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.VENDOR);
                                cmdInsDr.Parameters.AddWithValue("@branch_id", current_itm_info.Rows[0]["branch_id"].ToString());
                                cmdInsDr.Parameters.AddWithValue("@user_id", return_data["user_id"]);
                                cmdInsDr.Parameters.AddWithValue("@narration", "Amount debited due to Return Edit worth: " + current_amt);
                                cmdInsDr.Parameters.AddWithValue("@dr", current_amt);
                                cmdInsDr.Parameters.AddWithValue("@date", current_date);
                                db.ExecuteQueryForTransaction(cmdInsDr);

                            }
                            else
                            {
                                current_amt = Convert.ToDecimal(current_itm_info.Rows[0]["prm_amount"]) - Convert.ToDecimal(new_prm_amount);
                                MySqlCommand cmdInsDr = new MySqlCommand();
                                cmdInsDr.CommandText = "INSERT INTO `tbl_transactions` " +
                                    " (`action_type`, `action_ref_id`, `partner_id`,`partner_type`,`branch_id`, `user_id`, `narration`, `dr`,  `date`,`closing_balance`)" +
                                    " select @action_type, @action_ref_id, @partner_id,@partner_type,@branch_id, @user_id, @narration, @dr, @date,(ifnull(sum(dr)-sum(cr),0)+@dr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type and branch_id=@branch_id  ";
                                //cmdInsDr.Parameters.AddWithValue("@session_id", return_order["session_id"]);
                                cmdInsDr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.PURCHASE_RETURN);
                                cmdInsDr.Parameters.AddWithValue("@action_ref_id", return_data["prm_id"]);
                                cmdInsDr.Parameters.AddWithValue("@partner_id", current_itm_info.Rows[0]["vendor_id"].ToString());
                                cmdInsDr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.VENDOR);
                                cmdInsDr.Parameters.AddWithValue("@branch_id", current_itm_info.Rows[0]["branch_id"].ToString());
                                cmdInsDr.Parameters.AddWithValue("@user_id", return_data["user_id"]);
                                cmdInsDr.Parameters.AddWithValue("@narration", "Amount debited due to Return Edit worth: " + current_amt);
                                cmdInsDr.Parameters.AddWithValue("@dr", current_amt);
                                cmdInsDr.Parameters.AddWithValue("@date", current_date);
                                db.ExecuteQueryForTransaction(cmdInsDr);
                            }

                            //UPDATE VENDOR BALANCE IN VENDOR TABLE
                            db.ExecuteQueryForTransaction("UPDATE tbl_vendor SET vn_balance=(select (sum(cr)-sum(dr)) from tbl_transactions  where partner_id='" + current_itm_info.Rows[0]["vendor_id"].ToString() + "' and partner_type=" + (int)Constants.PartnerType.VENDOR + ") where vn_id=" + current_itm_info.Rows[0]["vendor_id"].ToString() + "");

                            // UPDATE AS RECIEVED IF ALL ITEMS ARE RECIEVED
                            var dt = db.SelectQueryForTransaction("SELECT pri.pri_id FROM tbl_purchase_return_items pri WHERE pri.prm_id='" + return_data["prm_id"] + "' AND pri.pri_recieved_id=0 ");
                            if (dt.Rows.Count > 0)
                            {
                                db.ExecuteQueryForTransaction("UPDATE tbl_purchase_return_master prm  SET prm.prm_status=1 WHERE prm.prm_id='" + return_data["prm_id"] + "'");
                            }
                            else
                            {
                                db.ExecuteQueryForTransaction("UPDATE tbl_purchase_return_master prm  SET prm.prm_status=2 WHERE prm.prm_id='" + return_data["prm_id"] + "'");

                                // UPDATE AS APPROVED IF ALL ITEMS APPROVED
                                var dt1 = db.SelectQueryForTransaction("SELECT pri.pri_id FROM tbl_purchase_return_items pri WHERE pri.prm_id='" + return_data["prm_id"] + "' AND pri.pri_approved_id=0 ");
                                if (dt1.Rows.Count > 0) { }
                                else
                                {
                                    db.ExecuteQueryForTransaction("UPDATE tbl_purchase_return_master prm  SET prm.prm_status=3 WHERE  prm.prm_id='" + return_data["prm_id"] + "'");
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
                    var log = new LogClass("Remove_purchase_Return_Item");
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