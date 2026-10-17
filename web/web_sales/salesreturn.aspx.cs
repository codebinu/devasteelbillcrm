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

public partial class web_sales_salesreturn : System.Web.UI.Page
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

        loadBranches();

	}

	public void loadBranches()
	{
		mySqlConnection db = new mySqlConnection();
		//load suppliers
		DataTable vendorDt = db.SelectQuery("select branch_id,branch_name from tbl_branch");
		//selBranch.Items.Add(new ListItem("ALL WAREHOUSES", "-1"));
		foreach (DataRow vendorRow in vendorDt.Rows)
		{
			selBranch.Items.Add(new ListItem(vendorRow["branch_name"].ToString(), vendorRow["branch_id"].ToString()));
		}

        selBranch.Value = HttpContext.Current.Request.Cookies["invntrystaffBranchId"].Value;

	}

	[WebMethod]
    public static string showCustomerDetails(string custId)
    {
        mySqlConnection db = new mySqlConnection();
        StringBuilder sb = new StringBuilder();
        string custDetailQry = "select tc.cust_name as name,tc.cust_amount as outstanding,tc.cust_type as class from tbl_customer tc where cust_id=" + custId + " ";
        DataTable dt = new DataTable();
        dt = db.SelectQuery(custDetailQry);
        sb.Append("{");
        if (dt.Rows.Count > 0)
        {
            sb.Append("\"customer\":");
            sb.Append(JsonConvert.SerializeObject(dt, Formatting.Indented));
            sb.Append(",");

        }

        String returnQry = "select srm_id,DATE_FORMAT(`srm_date`, '%d-%b-%Y %h:%i %p') as date,"
        + " srm_description as narration,concat(tu.first_name,' ',tu.last_name) as user_name,srm_status,srm_amount as amount"
        + " from tbl_salesreturn_master tr  inner join tbl_user_details tu on tu.user_id=tr.srm_userid"
        + " where cust_id=" + custId;
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
        string returnQry = "select sri_id as id,itm_code as code,itm_name as name,si_price as price,sri_qty as qty,sm_invoice_no,"
            + "sri_total as total,sri_type as type,tsi.sm_id,tsi.srm_id,sri_tax_percentage as tax,sri_cess as cess,itbs_id,tb.branch_tax_method,tb.branch_tax_inclusive,sri_tax_amount as tax_amount,tb.branch_id  from tbl_salesreturn_items tsi left join tbl_sales_master tsm on tsm.sm_id=tsi.sm_id inner join tbl_salesreturn_master srm on srm.srm_id=tsi.srm_id inner join tbl_branch tb on tb.branch_id=srm.branch_id where tsi.srm_id=" + returnId;
        DataTable returnDt = db.SelectQuery(returnQry);
        return JsonConvert.SerializeObject(returnDt, Formatting.Indented);

    }

    [WebMethod]
    public static string searchOrderitems(Dictionary<string, string> filters)
    {
        mySqlConnection db = new mySqlConnection();
        string qry_condition = " where 1 and sm.sm_type=1 and si.itm_type=1 ";
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
            if (filters["searchCod"]!="")
            {
                qry_condition += " and itb.itm_code like '%" + filters["searchCod"] + "%'";
            }
            if (filters["searchName"] != "")
            {
                qry_condition += " and itb.itm_name like '%" + filters["searchName"] + "%'";
            }
            if (filters["searchInvoiceNum"] != "")
            {
                qry_condition += " and sm.sm_invoice_no like '%" + filters["searchInvoiceNum"] + "%'";
            }
        }
        string itemqry = "select sm.sm_invoice_no,sm.sm_id,si.itbs_id as itbs_id,si_id as ItemId,si.itm_name,"
            + " si.itm_code,si.si_qty,si.si_foc,(si.si_qty+si.si_foc) as total_qty,"
            +" si.si_discount_rate,DATE_FORMAT(sm.sm_date, '%d %M %Y') as sm_date,"
            +" sm.cust_id ,si.si_price,IFNULL(sum(CASE WHEN (sr.sri_qty) "
            +" THEN sr.sri_qty ELSE 0 END),0) as returned ,"
            + " (si.si_net_amount/(si.si_qty+si.si_foc)) as return_price,si.si_item_cess,si.si_item_tax"
            +" from tbl_sales_master sm join tbl_sales_items si on si.sm_id=sm.sm_id"
            +" join tbl_itembranch_stock itb on itb.itbs_id=si.itbs_id "
            +" left join tbl_salesreturn_items sr on (sr.itbs_id=itb.itbs_id and sm.sm_id=sr.sm_id ) "
            +" " + qry_condition + ""
            +" and sm.sm_delivery_status=2 and sm.cust_id='" + filters["custid"] + "' "
            +" group by si_id having total_qty>returned order by sm.sm_date desc";
       // string itemqry = "select itbs_id as uniqueid,itm_code,itm_name,si_price,(si.si_qty-IFNULL((select sum(sri_qty) from tbl_salesreturn_items sr where sr.sm_id=" + orderid + " and sr.itbs_id=si.itbs_id),0)) as totalqty,(si_net_amount/si_qty) as price,si_net_amount from tbl_sales_items si " + qry_condition;
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
    public static string sales_return(Dictionary<string, string> return_order)
    {
        string result = "";
        string credited_amount = "";
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
            string srm_date = TimeNow.ToString("yyyy/MM/dd HH:mm:ss");


            //start check query for invoice number already exist
          
                string branchPrefix = "";
                int branchStart = 0;
                string branchSuffix = "";
                string prefix = "";
                int orderStart = 0;
                string suffix = "";

                string getTimeZone = "SELECT branch_timezone,branch_returnPrefix,branch_returnSlNo,branch_returnSuffix from tbl_branch where branch_id='" + return_order["branchid"] + "'";
                DataTable invoiceDt = db.SelectQueryForTransaction(getTimeZone);

                if (invoiceDt != null)
                {
                    branchPrefix = Convert.ToString(invoiceDt.Rows[0]["branch_returnPrefix"]);
                    branchStart = Convert.ToInt32(invoiceDt.Rows[0]["branch_returnSlNo"]);
                    branchSuffix = Convert.ToString(invoiceDt.Rows[0]["branch_returnSuffix"]);

                }

                    prefix = branchPrefix;
                    orderStart = branchStart;
                    suffix = branchSuffix;


                    string suffixQry = "SELECT IFNULL(max(srm_serialNo),0) FROM tbl_salesreturn_master where branch_id=" + return_order["branchid"] + "  and srm_prefix='" + prefix + "' and srm_suffix='" + suffix + "'";
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
               
            // INSERTING TO SALES RETURN MASTER

            string srm_insert_qry = "INSERT INTO `tbl_salesreturn_master` (`sm_id`, `cust_id`, `srm_userid`, `branch_id`,"
                + " `srm_date`,`srm_session_id`,srm_description,srm_prefix,srm_serialNo,srm_suffix,srm_invoice_no,srm_refInvoiceNo)"
            +" VALUES('0','" + return_order["cust_id"] + "','" + return_order["user_id"] + "',"
            +" '" + return_order["branchid"] + "','" + srm_date + "','" + return_order["session_id"] + "',"
            + " '" + return_order["description"] + "','" + prefix + "','" + invoiceSerialNo + "','" + suffix + "',concat(srm_prefix,srm_serialNo,srm_suffix),'" + return_order["invoiceNo"] + "');Select last_insert_id();";
            var last_id = db.SelectScalarForTransaction(srm_insert_qry);
            Int32 srm_id = Convert.ToInt32(last_id);

            // END OF INSERTING TO SALES RETURN MASTER
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

            string batch_insert_items_header = "INSERT INTO `tbl_salesreturn_items` (`srm_id`, `sm_id`, `row_no`, `itbs_id`, `itm_code`, `itm_name`, `si_price`, `si_discount_rate`, `sri_qty`, `sri_discount_amount`,`sri_tax_percentage`,`sri_cess`,`sri_tax_amount`, `sri_total`, `sri_type`) VALUES";
            string batch_insert_items = "";
            decimal srm_amount = 0;



            for (int i = 0; i < Convert.ToInt32(return_order["item_count"]); i++)
            {

                if (i == 0)
                {
                    batch_insert_items = "('" + srm_id + "','" + return_data[i].sm_id + "','" + i + "','" + return_data[i].itbs_id + "','" + return_data[i].itm_code + "','" + return_data[i].itm_name + "','" + return_data[i].si_price + "','" + return_data[i].si_discount_rate + "','" + return_data[i].sri_qty + "','0','" + return_data[i].sri_tax_percentage + "','" + return_data[i].sri_cess + "','" + return_data[i].sri_tax_amount + "','" + return_data[i].sri_total + "','" + return_data[i].sri_type + "')";

                }
                else
                {
                    batch_insert_items = batch_insert_items + "," + "('" + srm_id + "','" + return_data[i].sm_id + "','" + i + "','" + return_data[i].itbs_id + "','" + return_data[i].itm_code + "','" + return_data[i].itm_name + "','" + return_data[i].si_price + "','" + return_data[i].si_discount_rate + "','" + return_data[i].sri_qty + "','0','" + return_data[i].sri_tax_percentage + "','" + return_data[i].sri_cess + "','" + return_data[i].sri_tax_amount + "','" + return_data[i].sri_total + "','" + return_data[i].sri_type + "')";
                }

                srm_amount = srm_amount + Convert.ToDecimal(return_data[i].sri_total);
                credited_amount = srm_amount.ToString();

                // increase stock for ready to use items // UNUSED CODE - STOCK NOT UPDATING NOW
                if (return_data[i].sri_type == "5")
                {
                    string new_stockQry = "UPDATE tbl_itembranch_stock SET itbs_stock=(itbs_stock + " + return_data[i].sri_qty + "),itm_last_update_date='" + srm_date + "' where itbs_id='" + return_data[i].itbs_id + "'";
                    db.ExecuteQueryForTransaction(new_stockQry);

                    StringBuilder can_sb_bulk_stkTrQry = new StringBuilder();
                    can_sb_bulk_stkTrQry.Append("INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`action_ref_id`,`user_id`,`narration`,`cr_qty`,`closing_stock`,`date`) VALUES ");
                    // stock transaction
                    can_sb_bulk_stkTrQry.Append("('" + Convert.ToString(return_data[i].itbs_id) + "','" + ((int)Constants.ActionType.SALES) + "','" + return_data[i].sm_id + "','" + return_order["user_id"] + "'");
                    can_sb_bulk_stkTrQry.Append(",'SALES RETURN: (stock increase) " + return_data[i].sri_qty + " qty " + Convert.ToString(return_data[i].itm_name) + " from order #" + return_data[i].sm_id + "','" + return_data[i].sri_qty + "'");
                    can_sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + Convert.ToString(return_data[i].itbs_id) + "')");
                    can_sb_bulk_stkTrQry.Append(",'" + srm_date + "');");
                    db.ExecuteQueryForTransaction(can_sb_bulk_stkTrQry.ToString());
                }
            }

            string saveToSalesReturnItemsasBatch = batch_insert_items_header + batch_insert_items;
            bool batch_result = db.ExecuteQueryForTransaction(saveToSalesReturnItemsasBatch);



            if (batch_result)
            {
                // updating sales return master
                string update_sales_return = "UPDATE tbl_salesreturn_master SET srm_amount='" + srm_amount + "' where srm_id='" + srm_id + "'";
                bool sm_result = db.ExecuteQueryForTransaction(update_sales_return);

                //inserts to transaction table
                //inserting order credit entry
                MySqlCommand cmdInsCr = new MySqlCommand();
                cmdInsCr.CommandText = "INSERT INTO `tbl_transactions` " +
                    " (`session_id`,`action_type`, `action_ref_id`, `partner_id`,`partner_type`,`branch_id`, `user_id`, `narration`, `cr`,  `date`,`closing_balance`)" +
                    " select @session_id,@action_type, @action_ref_id, @partner_id,@partner_type,@branch_id, @user_id, @narration, @cr, @date,(ifnull(sum(dr)-sum(cr),0)-@cr) from tbl_transactions where partner_id=@partner_id and partner_type=@partner_type and branch_id=@branch_id  ";
                cmdInsCr.Parameters.AddWithValue("@session_id", return_order["session_id"]);
                cmdInsCr.Parameters.AddWithValue("@action_type", (int)Constants.ActionType.SALES_RETURN);
                cmdInsCr.Parameters.AddWithValue("@action_ref_id", srm_id);
                cmdInsCr.Parameters.AddWithValue("@partner_id", return_order["cust_id"]);
                cmdInsCr.Parameters.AddWithValue("@partner_type", (int)Constants.PartnerType.CUSTOMER);
                cmdInsCr.Parameters.AddWithValue("@branch_id", return_order["branchid"]);
                cmdInsCr.Parameters.AddWithValue("@user_id", return_order["user_id"]);
                cmdInsCr.Parameters.AddWithValue("@narration", "Return of items worth " + srm_amount);
                cmdInsCr.Parameters.AddWithValue("@cr", srm_amount);
                cmdInsCr.Parameters.AddWithValue("@date", srm_date);
                db.ExecuteQueryForTransaction(cmdInsCr);

                string update_tbl_customer = "UPDATE tbl_customer SET cust_last_updated_date='" + srm_date + "',cust_amount=(select (sum(dr)-sum(cr)) from tbl_transactions  where partner_id='" + return_order["cust_id"] + "' and partner_type=" + (int)Constants.PartnerType.CUSTOMER + ") where cust_id=" + return_order["cust_id"] + "; SELECT cust_amount FROM tbl_customer WHERE cust_id=" + return_order["cust_id"];
                new_balance = db.SelectScalarForTransaction(update_tbl_customer);
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
                LogClass log = new LogClass("sales_return");
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

        string qry = "SELECT itb.itbs_id,itb.itm_name,itb.itm_code,itb." + filters["cust_class"] + " as itm_price,tp.tp_tax_percentage,tp.tp_cess FROM  tbl_itembranch_stock itb INNER JOIN tbl_tax_profile tp ON tp.tp_tax_code=itb.tp_tax_code   where itb.branch_id='" + filters["branch_id"] + "' and itb.itm_name like '%" + filters["searchTerm"] + "%'" + brand_qry + category_qry + " LIMIT 5 ";
        DataTable dt = db.SelectQuery(qry);

        string qry2 = "select IFNULL(sm.sm_invoice_no,'NIL') AS sm_invoice_no,sm.sm_id,si.itbs_id,si.itm_name,si.itm_code,si.si_qty,si.si_foc,(si.si_qty+si.si_foc) as total_qty,si.si_discount_rate,DATE_FORMAT(sm.sm_date, '%d %M %Y') as sm_date,sm.cust_id ,si.si_price,IFNULL(sum(CASE WHEN (sr.sri_qty) THEN sr.sri_qty ELSE 0 END),0) as returned ,(si.si_net_amount/(si.si_qty+si.si_foc)) as return_price,si.si_item_cess,si.si_item_tax from tbl_sales_master sm join tbl_sales_items si on si.sm_id=sm.sm_id join tbl_itembranch_stock itb on itb.itbs_id=si.itbs_id left join tbl_salesreturn_items sr on (sr.itbs_id=itb.itbs_id and sm.sm_id=sr.sm_id ) where sm.branch_id='" + filters["branch_id"] + "' and si.itm_name like '%" + filters["searchTerm"] + "%'" + brand_qry + category_qry + " and sm.sm_delivery_status=2 and si.itm_type=1 and sm.sm_type='1' and sm.cust_id='" + filters["custid"] + "' group by si.si_id having total_qty>returned order by sm.sm_date desc";
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
        string qry = "SELECT itb.itbs_id,itb.itm_name,itb.itm_code,(select tip_price from tbl_item_pricelist tip where tip.itbs_id=itb.itbs_id and tpm_id=" + filters["cust_class"] + " ) as"
        +" itm_price,tp.tp_tax_percentage,tp.tp_cess FROM tbl_itembranch_stock itb INNER JOIN"
        +" tbl_tax_profile tp ON tp.tp_tax_code=itb.tp_tax_code "+qry_condition+" LIMIT " + offset.ToString() + " ," + per_page;
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

            if (Convert.ToInt32(current_itm_info.Rows[0]["sri_qty"]) != Convert.ToInt32(return_data["sri_qty"]) || Convert.ToDecimal(current_itm_info.Rows[0]["si_price"]) != Convert.ToDecimal(return_data["si_price"]))
            {


                try
                {
                    db.BeginTransaction();

                    //1. UPDATE SALES RETURN ITEMS
                    bool up_sri_qry = db.ExecuteQueryForTransaction("UPDATE tbl_salesreturn_items SET sri_qty='" + return_data["sri_qty"] + "',si_price='" + return_data["si_price"] + "',sri_tax_amount='" + return_data["sri_tax_amount"] + "',sri_total='" + return_data["sri_total"] + "' WHERE sri_id='" + return_data["sri_id"] + "' ");
                    if (up_sri_qry)
                    {
                        var new_srm_amount = db.SelectScalarForTransaction("SELECT SUM(sri_total) FROM tbl_salesreturn_items WHERE srm_id='" + return_data["srm_id"] + "'");

                        //2. UPDATE SALES RETURN MASTER
                        if (Convert.ToDecimal(new_srm_amount) != Convert.ToDecimal(current_itm_info.Rows[0]["srm_amount"]))
                        {
                            db.ExecuteQueryForTransaction("UPDATE tbl_salesreturn_master SET srm_amount='" + new_srm_amount + "'  WHERE srm_id='" + return_data["srm_id"] + "'");

                            Int32 stock_diff = 0;
                            //IF ITEM QUANTITY CHANGED & READY TO USE ITEM // update to stock transaction
                            if ((Convert.ToInt32(current_itm_info.Rows[0]["sri_qty"]) != Convert.ToInt32(return_data["sri_qty"])) && (Convert.ToInt32(current_itm_info.Rows[0]["sri_type"]) == 2))
                            {

                                // if current qty becomes higher -> Increase stock
                                if (Convert.ToInt32(current_itm_info.Rows[0]["sri_qty"]) < Convert.ToInt32(return_data["sri_qty"]))
                                {
                                    stock_diff = Convert.ToInt32(return_data["sri_qty"]) - Convert.ToInt32(current_itm_info.Rows[0]["sri_qty"]);

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
                                else
                                {
                                    stock_diff = Convert.ToInt32(current_itm_info.Rows[0]["sri_qty"]) - Convert.ToInt32(return_data["sri_qty"]);
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