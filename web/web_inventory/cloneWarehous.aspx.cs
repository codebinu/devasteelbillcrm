using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Text;
using System.Web.Services;
using System.Data;
using commonfunction;
using Newtonsoft.Json;

public partial class opcenter_cloneWarehous : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {

        /*
        if (Request.Cookies["invntrystaffId"] != null && Request.Cookies["invntrystaffBranchId"] != null && Request.Cookies["invntrystaffCountryId"] != null)
        {
            string userid = Request.Cookies["invntrystaffTypeID"].Value;
            mySqlConnection db = new mySqlConnection();
            DataTable dt = new DataTable();
            string query = "SELECT COUNT(*) FROM tbl_user_permissions WHERE user_type='" + userid + "' and page_id='22' and read_action='1' ";
            double numrows = Convert.ToInt32(db.SelectScalar(query));
            if (numrows == 0)
            {
                Response.Redirect("../dashboard.aspx");
            }
        }
        else if (Request.Cookies["invntrystaffId"] == null && Request.Cookies["invntrystaffBranchId"] == null && Request.Cookies["invntrystaffCountryId"] == null)
        {
            Response.Redirect("../dashboard.aspx");
        }
        else
        {
            Response.Redirect("../login.aspx");
        }

        */
    }

    #region Basic Page Loading Operations

    #region load warehouse
    [WebMethod]
    public static string showBranches()
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        StringBuilder sb = new StringBuilder();
        string query = "SELECT branch_id,branch_name,branch_countryid FROM tbl_branch order by branch_id ";
        dt = db.SelectQuery(query);
        if (dt != null)
        {
            if (dt.Rows.Count > 0)
            {
                if (dt.Rows[0]["branch_id"] is DBNull)
                {
                    sb.Append("<option value='0' >--All Warehouse--</option>");
                }
                else
                {
                    sb.Append("<option value='0' >--All Warehouse--</option>");
                    for (int i = 0; i < dt.Rows.Count; i++)
                    {
                        sb.Append("<option value='" + dt.Rows[i]["branch_id"] + "'>" + dt.Rows[i]["branch_name"] + "</option>");
                    }
                }
            }
            else
            {
                sb.Append("<option value='0' >--All Warehouse--</option>");
            }
        }

        return sb.ToString();

    }

    #endregion

    #region load Brands
    [WebMethod]
    public static string showBrands()
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        StringBuilder sb = new StringBuilder();
        string query = "SELECT brand_id, brand_name FROM tbl_item_brand ORDER BY brand_id ASC";
        dt = db.SelectQuery(query);
        if (dt != null)
        {
            if (dt.Rows.Count > 0)
            {
                if (dt.Rows[0]["brand_id"] is DBNull)
                {
                    sb.Append("<option value='-1' selected='selected'>--Brand--</option>");
                }
                else
                {
                    sb.Append("<option value='-1' selected='selected'>--Brand--</option>");
                    for (int i = 0; i < dt.Rows.Count; i++)
                    {
                        sb.Append("<option value='" + dt.Rows[i]["brand_id"] + "'>" + dt.Rows[i]["brand_name"] + "</option>");
                    }
                }
            }
            else
            {
                sb.Append("<option value='-1' selected='selected'>--Brand--</option>");   
            }
        }

        return sb.ToString();
    }
    #endregion

    #region load Category
    [WebMethod]
    public static string showCategoryTypes()
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        StringBuilder sb = new StringBuilder();
        string query = "SELECT cat_id, cat_name FROM tbl_item_category ORDER BY cat_id ASC";
        dt = db.SelectQuery(query);
        if (dt != null)
        {
            if (dt.Rows.Count > 0)
            {
                if (dt.Rows[0]["cat_id"] is DBNull)
                {
                    sb.Append("<option value='-1' selected='selected'>--Category--</option>");
                }
                else
                {
                    sb.Append("<option value='-1' selected='selected'>--Category--</option>");
                    for (int i = 0; i < dt.Rows.Count; i++)
                    {
                        sb.Append("<option value='" + dt.Rows[i]["cat_id"] + "'>" + dt.Rows[i]["cat_name"] + "</option>");
                    }
                }
            }
            else
            {
              sb.Append("<option value='-1' selected='selected'>--Category--</option>");
            }
        }

        return sb.ToString();
    }
    #endregion

    #endregion

    #region  searchCloneItems Based on Warehouse 
    [WebMethod]
    public static string searchCloneItems(int page, Dictionary<string, string> commissionfilters, int perpage)
    {
        try
        {
            string query_condition = "";
            if (commissionfilters.Count > 0)
            {
                query_condition = " where 1=1";
                if (commissionfilters.ContainsKey("itm_code"))
                {
                    query_condition += " and itm_code LIKE '" + commissionfilters["itm_code"] + "%'";
                }
                if (commissionfilters.ContainsKey("itm_name"))
                {
                    query_condition += " and itm_name LIKE '" + commissionfilters["itm_name"] + "%'";
                }
                
                if (commissionfilters.ContainsKey("itm_commision"))
                {
                    query_condition += " and itm_commision LIKE '" + commissionfilters["itm_commision"] + "%'";
                }
              
                if (commissionfilters.ContainsKey("warehouseid"))
                {
                    query_condition += " and (branch_id='" + commissionfilters["warehouseid"] + "')";
                }
                if (commissionfilters.ContainsKey("brandid"))
                {
                    query_condition += " and (itm_brand_id='" + commissionfilters["brandid"] + "')";
                }
                if (commissionfilters.ContainsKey("categoryid"))
                {
                    query_condition += " and (itm_category_id='" + commissionfilters["categoryid"] + "')";
                }
            }
            mySqlConnection db = new mySqlConnection();
            DataTable dt = new DataTable();
            StringBuilder sb = new StringBuilder();
            double per_page = perpage;
            double offset = (page - 1) * per_page;
            string innerqry = "";
            double numrows = 0;
            string countQry = " select Count(*) ";
            countQry = countQry + " from tbl_itembranch_stock ";
            countQry = countQry + " " + query_condition;
            numrows = Convert.ToInt32(db.SelectScalar(countQry));
            if (numrows == 0)
            {
                return "N";
            }
            int total_pages = Convert.ToInt32(Math.Ceiling(numrows / per_page));
            if (perpage == 0)
            {
                per_page = numrows;
            }
            innerqry = "SELECT itbs_id,itm_code,itm_name,itm_commision,brand_name,cat_name from tbl_itembranch_stock tis inner join tbl_item_brand tb on tb.brand_id=tis.itm_brand_id inner join tbl_item_category tc on tc.cat_id=tis.itm_category_id ";
            innerqry = innerqry + query_condition;
            innerqry = innerqry + "order by itbs_id  LIMIT " + offset.ToString() + " ," + per_page;
            dt = db.SelectQuery(innerqry);
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

            return jsonResponse;
        }
        catch (Exception ex)
        {
            return ex.ToString();
        }
    }
   
    #endregion

    #region clone Warehouse Operations
    [WebMethod]
    public static string cloneWarehouse(string branchid, string resultString, int rowValue)
    {
       
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        DataTable dt1 = new DataTable();
        StringBuilder sb = new StringBuilder();
        string resultStatus = "N";
        string insquery = "";
        bool queryStatus;
        string branch_timezone = "";
        bool priceresult = false;
        string getTimeZone = "SELECT branch_timezone from tbl_branch where branch_id='" + branchid + "'";
        DataTable cTimeZone = db.SelectQueryForTransaction(getTimeZone);
        if (cTimeZone != null)
        {
            branch_timezone = Convert.ToString(cTimeZone.Rows[0]["branch_timezone"]);
        }
        TimeZoneInfo CurrentZone = TimeZoneInfo.FindSystemTimeZoneById(branch_timezone);
        DateTime TimeNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, CurrentZone);
        string currentDate = DateTime.Parse(TimeNow.ToString()).ToString("yyyy-MM-dd HH:mm:ss");
        String[] rowsString = resultString.Split(new[] { "@#$" }, StringSplitOptions.RemoveEmptyEntries);
        int length = rowsString.Length;

        try
        {
            db.BeginTransaction();
            foreach (string data in rowsString)
            {
                string qry = "Select * from tbl_itembranch_stock where itbs_id='" + data + "'";
                dt = db.SelectQueryForTransaction(qry);
                DataTable priceDt = db.SelectQueryForTransaction("select tpm_id,tip_price from tbl_item_pricelist where itbs_id='" + data + "'");
                if (dt.Rows.Count > 0)
                {
                    
                        string selqry = "Select itbs_id from tbl_itembranch_stock where branch_id='" + branchid + "' and itm_id='" + dt.Rows[0]["itm_id"] + "'";
                        dt1 = db.SelectQueryForTransaction(selqry);
                        if (dt1.Rows.Count > 0)
                        {
                            // item exist
                        }
                        else
                        {
                            insquery = "INSERT INTO tbl_itembranch_stock (branch_id, itm_id, itbs_stock, itbs_reorder, itbs_available, itm_code, itm_name,itm_brand_id,itm_category_id,itm_subcategory_id,itm_mrp,itm_commision,itm_target,tp_tax_code,itbs_duration,itm_last_update_date,itm_rating,itbs_purchase_price,itbs_purchase_status)";
                            insquery = insquery + "VALUES ('" + branchid + "','" + dt.Rows[0]["itm_id"] + "','" + dt.Rows[0]["itbs_stock"] + "','" + dt.Rows[0]["itbs_reorder"] + "','" + dt.Rows[0]["itbs_available"] + "','" + dt.Rows[0]["itm_code"] + "','" + dt.Rows[0]["itm_name"] + "','" + dt.Rows[0]["itm_brand_id"] + "','" + dt.Rows[0]["itm_category_id"] + "','" + dt.Rows[0]["itm_subcategory_id"] + "','" + dt.Rows[0]["itm_mrp"] + "','" + dt.Rows[0]["itm_commision"] + "','" + dt.Rows[0]["itm_target"] + "','" + dt.Rows[0]["tp_tax_code"] + "','" + dt.Rows[0]["itbs_duration"] + "','" + currentDate + "','" + dt.Rows[0]["itm_rating"] + "','" + dt.Rows[0]["itbs_purchase_price"] + "','" + dt.Rows[0]["itbs_purchase_status"] + "');Select last_insert_id();";
                            var itbs_id = db.SelectScalarForTransaction(insquery);
                            string priceQry = "insert into tbl_item_pricelist(itbs_id,tpm_id,tip_price,tip_last_updated_date)values";
                            for (int i = 0; i < priceDt.Rows.Count; i++)
                            {
                                priceQry += "(" + itbs_id + "," + priceDt.Rows[i]["tpm_id"] + "," + priceDt.Rows[i]["tip_price"] + ",'" + currentDate + "'),";

                            }
                            priceQry = priceQry.Remove(priceQry.Trim().Length - 1);
                            priceresult = db.ExecuteQueryForTransaction(priceQry);
                           
                        }

                    
                }


            }//foreach
            if (priceresult)
            {
                resultStatus = "Y";
            }
            else
            {
                resultStatus = "N";
            }
            db.CommitTransaction();
            return resultStatus;
        }
        catch (Exception ex)
        {
            LogClass log = new LogClass("item_clone");
            log.write(ex);
            db.RollBackTransaction();
            return ex.ToString();
           
        }
        

    }
    #endregion

}