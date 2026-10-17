using commonfunction;
using Newtonsoft.Json;
using OfficeOpenXml;
using OfficeOpenXml.Style;
using System;
using System.Collections.Generic;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;
using MySql.Data.MySqlClient;

public partial class web_inventory_warehousemanagement : System.Web.UI.Page
{
    public string priceMaster;
    mySqlConnection db = new mySqlConnection();
    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication warehouseManagement = new LoginAuthentication();
        warehouseManagement.userAuthentication();
        warehouseManagement.checkPageAcess(13);
        getPriceMasterData();
    }
    //method for taking price master data
    public void getPriceMasterData()
    {
        string qry = "select tpm_id,tpm_name from tbl_price_master";
        DataTable dtPriceMaster = db.SelectQuery(qry);
        priceMaster = JsonConvert.SerializeObject(dtPriceMaster);
    }
    //show branches
    [WebMethod]
    public static string showBranches()
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        StringBuilder sb = new StringBuilder();
        
        var staffIdCookie = HttpContext.Current.Request.Cookies["invntrystaffId"];
        string staffId = staffIdCookie != null ? staffIdCookie.Value : "";

        string query = "select tb.branch_id,branch_name,branch_tax_method from tbl_branch tb inner join tbl_user_branches ub on ub.branch_id=tb.branch_id where user_id=@userId";
        MySqlParameter[] p = { new MySqlParameter("@userId", staffId) };
        dt = db.SelectQuery(query, p);
        if (dt != null)
        {
            if (dt.Rows.Count > 0)
            {
                if (dt.Rows[0]["branch_id"] is DBNull)
                {
                    sb.Append("<option value='0' selected='selected' taxType='-1'>--Select Warehouse--</option>");
                }
                else
                {
                    sb.Append("<option value='0' selected='selected' taxType='-1'>--Select Warehouse--</option>");
                    for (int i = 0; i < dt.Rows.Count; i++)
                    {
                        sb.Append("<option value='" + dt.Rows[i]["branch_id"] + "' taxType=" + dt.Rows[i]["branch_tax_method"] + ">" + dt.Rows[i]["branch_name"] + "</option>");
                    }
                }
            }
            else
            {
                sb.Append("<option value='0' selected='selected' taxType='-1'>--Select Warehouse--</option>");
            }
        }
        return sb.ToString();
    }

    [WebMethod]
    public static string showItems(string searchText)
    {
        mySqlConnection db = new mySqlConnection();
        string query = "SELECT itm_id,itm_name FROM tbl_item_master where itm_name like @searchText ORDER BY itm_name ASC";
        MySqlParameter[] p = { new MySqlParameter("@searchText", "%" + searchText + "%") };
        DataTable dt = db.SelectQuery(query, p);
        if (dt.Rows.Count > 0)
        {
            var list = dt.AsEnumerable().Select(row => new
            {
                id = Convert.ToString(row["itm_id"]),
                label = Convert.ToString(row["itm_name"]),
                value = Convert.ToString(row["itm_name"])
            });
            return JsonConvert.SerializeObject(list);
        }
        else
        {
            return "[{\"id\":\"-1\",\"label\":\"No Data Found\",\"value\":\"No Data Found\"}]";
        }
    }

    //save and update item stock details
    [WebMethod]
    public static string addBranchStockDetails(string actionType, string itbsid, string branch, string item, int currentstock, string reorderlevel, string status, string itm_mrp, string taxcode, string duration, string priority, string sessionId, string actual_stock, int stockChange, string stockDifr, string purchasePrice, string purchaseMaintainStatus, string priceObj)
    {
        String resultStatus = "N";
        mySqlConnection db = new mySqlConnection();

        // CHECKING SESSION
        string getsessionexist = "select itbs_sessionId from tbl_itembranch_stock where itbs_sessionId=@sessionId";
        MySqlParameter[] pSession = { new MySqlParameter("@sessionId", sessionId) };
        DataTable dtsession = db.SelectQuery(getsessionexist, pSession);
        int sess_rows = dtsession.Rows.Count;

        if (sess_rows != 0)  // ALREADY SAVED CASE
        {
            db.RollBackTransaction();
            HttpContext.Current.Response.StatusCode = 401;
            HttpContext.Current.Response.TrySkipIisCustomErrors = true;
            return "{\"message\":\"Item saved already\"}";
        }

        string selectTimezonQuery = "select ss_default_time_zone from tbl_system_settings";
        DataTable timezoneDt = db.SelectQuery(selectTimezonQuery);
        TimeZoneInfo CurrentZone = TimeZoneInfo.FindSystemTimeZoneById(timezoneDt.Rows[0]["ss_default_time_zone"].ToString());
        DateTime TimeNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, CurrentZone);
        string updatedDate = DateTime.Parse(TimeNow.ToString()).ToString("yyyy-MM-dd HH:mm:ss");

        var staffIdCookie = HttpContext.Current.Request.Cookies["invntrystaffId"];
        string staffId = staffIdCookie != null ? staffIdCookie.Value : "";

        // Fetch item master details once
        DataTable dtItemMaster = db.SelectQuery(
            "select itm_code,itm_name,itm_brand_id,itm_category_id,itm_subcategory_id from tbl_item_master where itm_id=@itemId",
            new MySqlParameter[] { new MySqlParameter("@itemId", item) }
        );

        if (dtItemMaster == null || dtItemMaster.Rows.Count == 0)
        {
            return "N";
        }

        string itmCode = Convert.ToString(dtItemMaster.Rows[0]["itm_code"]);
        string itmName = Convert.ToString(dtItemMaster.Rows[0]["itm_name"]);
        string itmBrandId = Convert.ToString(dtItemMaster.Rows[0]["itm_brand_id"]);
        string itmCategoryId = Convert.ToString(dtItemMaster.Rows[0]["itm_category_id"]);
        string itmSubcategoryId = Convert.ToString(dtItemMaster.Rows[0]["itm_subcategory_id"]);

        string itbs_value = itbsid;

        if (actionType == "insert")
        {
            // check is unique?
            String chk_qry = "SELECT count(*) FROM tbl_itembranch_stock WHERE (branch_id = @branch and itm_id = @item)";
            MySqlParameter[] pUnique = {
                new MySqlParameter("@branch", branch),
                new MySqlParameter("@item", item)
            };
            double numrows = Convert.ToInt32(db.SelectScalar(chk_qry, pUnique));
            if (numrows > 0)
            {
                return "E";
            }

            string query = "INSERT INTO tbl_itembranch_stock (itbs_id, branch_id, itm_id, itbs_stock, itbs_reorder, itbs_available, itm_code, itm_name, itm_brand_id, itm_category_id, itm_subcategory_id, itm_mrp, itm_commision, itm_target, tp_tax_code, itbs_duration, itm_last_update_date, itm_rating, itbs_sessionId, itbs_purchase_price, itbs_purchase_status) "
                + "VALUES (null, @branch, @item, @actualStock, @reorderLevel, @status, @itmCode, @itmName, @itmBrandId, @itmCategoryId, @itmSubcategoryId, @itmMrp, 0, 0, @taxCode, @duration, @updatedDate, @priority, @sessionId, @purchasePrice, @purchaseMaintainStatus); SELECT LAST_INSERT_ID();";

            MySqlParameter[] pInsert = {
                new MySqlParameter("@branch", branch),
                new MySqlParameter("@item", item),
                new MySqlParameter("@actualStock", actual_stock),
                new MySqlParameter("@reorderLevel", reorderlevel),
                new MySqlParameter("@status", status),
                new MySqlParameter("@itmCode", itmCode),
                new MySqlParameter("@itmName", itmName),
                new MySqlParameter("@itmBrandId", itmBrandId),
                new MySqlParameter("@itmCategoryId", itmCategoryId),
                new MySqlParameter("@itmSubcategoryId", itmSubcategoryId),
                new MySqlParameter("@itmMrp", itm_mrp),
                new MySqlParameter("@taxCode", taxcode),
                new MySqlParameter("@duration", duration),
                new MySqlParameter("@updatedDate", updatedDate),
                new MySqlParameter("@priority", priority),
                new MySqlParameter("@sessionId", sessionId),
                new MySqlParameter("@purchasePrice", purchasePrice),
                new MySqlParameter("@purchaseMaintainStatus", purchaseMaintainStatus)
            };

            itbs_value = db.SelectScalar(query, pInsert);
            Int32 branchstockid = Convert.ToInt32(itbs_value);

            if (currentstock != 0)
            {
                string stockTransctnQry = "INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`user_id`,`narration`,`cr_qty`,`closing_stock`,`date`) VALUES (@itbsId, @actionType, @staffId, @narration, @crQty, @closingStock, @date)";
                MySqlParameter[] pTrans = {
                    new MySqlParameter("@itbsId", branchstockid),
                    new MySqlParameter("@actionType", (int)Constants.ActionType.MANUAL_ITEM_EDIT),
                    new MySqlParameter("@staffId", staffId),
                    new MySqlParameter("@narration", "Manually entered " + currentstock + " " + itmName),
                    new MySqlParameter("@crQty", currentstock),
                    new MySqlParameter("@closingStock", actual_stock),
                    new MySqlParameter("@date", updatedDate)
                };
                db.ExecuteQuery(stockTransctnQry, pTrans);
            }
        }

        if (actionType == "update")
        {
            // check is unique?
            String chk_qry = "SELECT count(*) FROM tbl_itembranch_stock WHERE (branch_id = @branch and itm_id = @item) and itbs_id != @itbsid";
            MySqlParameter[] pUnique = {
                new MySqlParameter("@branch", branch),
                new MySqlParameter("@item", item),
                new MySqlParameter("@itbsid", itbsid)
            };
            double numrows = Convert.ToInt32(db.SelectScalar(chk_qry, pUnique));
            if (numrows > 0)
            {
                return "E";
            }

            MySqlParameter[] pStock = { new MySqlParameter("@itbsid", itbsid) };
            string stock = db.SelectScalar(
                "SELECT IFNULL(SUM(si.si_qty+si.si_foc),0) AS total_qty FROM tbl_sales_items si INNER JOIN tbl_sales_master sm ON sm.sm_id=si.sm_id WHERE si.itbs_id=@itbsid AND sm.sm_delivery_status IN (0,3,6)",
                pStock
            );
            Int32 up_stock = Convert.ToInt32(actual_stock) - Convert.ToInt32(stock);

            string queryUpdate = "UPDATE tbl_itembranch_stock SET branch_id=@branch, itm_id=@item, itbs_stock=@upStock, itbs_purchase_price=@purchasePrice, itbs_reorder=@reorderLevel, itbs_available=@status, itm_mrp=@itmMrp, tp_tax_code=@taxCode, itbs_duration=@duration, itm_last_update_date=@updatedDate, itm_rating=@priority, itm_code=@itmCode, itm_name=@itmName, itm_brand_id=@itmBrandId, itm_category_id=@itmCategoryId, itm_subcategory_id=@itmSubcategoryId, itbs_purchase_status=@purchaseMaintainStatus WHERE itbs_id=@itbsid";
            
            MySqlParameter[] pUpdate = {
                new MySqlParameter("@branch", branch),
                new MySqlParameter("@item", item),
                new MySqlParameter("@upStock", up_stock),
                new MySqlParameter("@purchasePrice", purchasePrice),
                new MySqlParameter("@reorderLevel", reorderlevel),
                new MySqlParameter("@status", status),
                new MySqlParameter("@itmMrp", itm_mrp),
                new MySqlParameter("@taxCode", taxcode),
                new MySqlParameter("@duration", duration),
                new MySqlParameter("@updatedDate", updatedDate),
                new MySqlParameter("@priority", priority),
                new MySqlParameter("@itmCode", itmCode),
                new MySqlParameter("@itmName", itmName),
                new MySqlParameter("@itmBrandId", itmBrandId),
                new MySqlParameter("@itmCategoryId", itmCategoryId),
                new MySqlParameter("@itmSubcategoryId", itmSubcategoryId),
                new MySqlParameter("@purchaseMaintainStatus", purchaseMaintainStatus),
                new MySqlParameter("@itbsid", itbsid)
            };
            db.ExecuteQuery(queryUpdate, pUpdate);

            if (stockChange == 1)
            {
                if (Convert.ToInt32(stockDifr) >= 1)
                {
                    string stockTransctnQry = "INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`user_id`,`narration`,`cr_qty`,`closing_stock`,`date`) VALUES (@itbsid, @actionType, @staffId, @narration, @crQty, @closingStock, @date)";
                    MySqlParameter[] pTrans = {
                        new MySqlParameter("@itbsid", itbsid),
                        new MySqlParameter("@actionType", (int)Constants.ActionType.MANUAL_ITEM_EDIT),
                        new MySqlParameter("@staffId", staffId),
                        new MySqlParameter("@narration", "Add " + stockDifr + " extra stock to " + itmName),
                        new MySqlParameter("@crQty", stockDifr),
                        new MySqlParameter("@closingStock", up_stock),
                        new MySqlParameter("@date", updatedDate)
                    };
                    db.ExecuteQuery(stockTransctnQry, pTrans);
                }
                else
                {
                    int stockVal = -1 * Convert.ToInt32(stockDifr);
                    string stockTransctnQry = "INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`user_id`,`narration`,`dr_qty`,`closing_stock`,`date`) VALUES (@itbsid, @actionType, @staffId, @narration, @drQty, @closingStock, @date)";
                    MySqlParameter[] pTrans = {
                        new MySqlParameter("@itbsid", itbsid),
                        new MySqlParameter("@actionType", (int)Constants.ActionType.MANUAL_ITEM_EDIT),
                        new MySqlParameter("@staffId", staffId),
                        new MySqlParameter("@narration", "Reduce " + stockVal + " qty from current stock of " + itmName),
                        new MySqlParameter("@drQty", stockVal),
                        new MySqlParameter("@closingStock", up_stock),
                        new MySqlParameter("@date", updatedDate)
                    };
                    db.ExecuteQuery(stockTransctnQry, pTrans);
                }
            }
        }

        // insert price details to tbl_item_pricelist
        dynamic price_data = JsonConvert.DeserializeObject(priceObj);
        if (itbsid != "0")
        {
            db.ExecuteQuery("delete from tbl_item_pricelist where itbs_id=@itbsid", new MySqlParameter[] { new MySqlParameter("@itbsid", itbsid) });
        }

        List<MySqlParameter> priceParams = new List<MySqlParameter>();
        priceParams.Add(new MySqlParameter("@itbs_id", itbs_value));
        priceParams.Add(new MySqlParameter("@updatedDate", updatedDate));

        string insertQry = "insert into tbl_item_pricelist(itbs_id,tpm_id,tip_price,tip_last_updated_date) values";
        int idx = 0;
        foreach (var price in price_data)
        {
            string tpmIdParam = "@tpm_id_" + idx;
            string priceParam = "@tip_price_" + idx;
            insertQry += string.Format(" (@itbs_id, {0}, {1}, @updatedDate),", tpmIdParam, priceParam);
            priceParams.Add(new MySqlParameter(tpmIdParam, (string)price.id));
            priceParams.Add(new MySqlParameter(priceParam, (string)price.value));
            idx++;
        }
        insertQry = insertQry.TrimEnd(',');
        bool result = db.ExecuteQuery(insertQry, priceParams.ToArray());
        if (result)
        {
            resultStatus = "Y";
        }
        else
        {
            resultStatus = "N";
        }
        return resultStatus;
    }

    //search branchstock table
    [WebMethod]
    public static string searchBranchStock(int page, Dictionary<string, string> filters, int perpage)
    {
        try
        {
            List<MySqlParameter> parameters = new List<MySqlParameter>();
            string query_condition = "";

            var staffIdCookie = HttpContext.Current.Request.Cookies["invntrystaffId"];
            string staffId = staffIdCookie != null ? staffIdCookie.Value : "";

            if (filters.Count > 0)
            {
                query_condition = " where 1=1 ";

                if (filters.ContainsKey("itemval"))
                {
                    query_condition += " and (itbs.itm_name LIKE @itemval or itbs.itm_code like @itemval)";
                    parameters.Add(new MySqlParameter("@itemval", "%" + filters["itemval"] + "%"));
                }
                if (filters.ContainsKey("branch"))
                {
                    if (filters["branch"] == "0")
                    {
                        query_condition += " and itbs.branch_id in (select branch_id from tbl_user_branches where user_id = @staffId)";
                        parameters.Add(new MySqlParameter("@staffId", staffId));
                    }
                    else
                    {
                        query_condition += " and itbs.branch_id  = @branch";
                        parameters.Add(new MySqlParameter("@branch", filters["branch"]));
                    }
                }
                if (filters.ContainsKey("brand"))
                {
                    query_condition += " and itbs.itm_brand_id = @brand";
                    parameters.Add(new MySqlParameter("@brand", filters["brand"]));
                }
                if (filters.ContainsKey("category"))
                {
                    query_condition += " and itbs.itm_category_id  = @category";
                    parameters.Add(new MySqlParameter("@category", filters["category"]));
                }
                if (filters.ContainsKey("itmstock"))
                {
                    if (Convert.ToInt32(filters["itmstock"]) == 1)
                    {
                        query_condition += " and itbs.itbs_stock>=itbs.itbs_reorder";
                    }
                    else if (Convert.ToInt32(filters["itmstock"]) == 2)
                    {
                        query_condition += " and itbs.itbs_stock<itbs.itbs_reorder";
                    }
                }
            }
            int per_page = perpage;
            int offset = (page - 1) * per_page;

            mySqlConnection db = new mySqlConnection();
            DataTable dt = new DataTable();
            string innerqry = "";
            string countQry = "SELECT count(*) FROM tbl_itembranch_stock itbs" + query_condition;

            double numrows = Convert.ToInt32(db.SelectScalar(countQry, CloneParameters(parameters)));
            if (numrows == 0)
            {
                return "N";
            }

            innerqry = @"select itbs.itbs_id,itbs.itm_code,itbs.itm_name,branch_name,itbs_reorder,itbs_available,
(itbs_stock+ifnull( sum(si.si_qty+si.si_foc),0)) as itbs_stock,itm_rating,itbs_purchase_price  
from tbl_itembranch_stock itbs  
inner join tbl_branch br on br.branch_id=itbs.branch_id  
left join tbl_sales_items si 
inner join tbl_sales_master sm on sm.sm_id = si.sm_id 
on itbs.itbs_id = si.itbs_id  and sm.sm_delivery_status in (0,3,6) ";
            innerqry = innerqry + query_condition;
            innerqry = innerqry + " group by itbs.itbs_id order by itbs_available DESC, itm_rating asc  LIMIT " + offset.ToString() + " ," + per_page;

            dt = db.SelectQuery(innerqry, CloneParameters(parameters));
            string jsonResponse = "";
            if (dt.Rows.Count > 0)
            {
                string jsonData = JsonConvert.SerializeObject(dt);
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

    //edit branch stock data
    [WebMethod]
    public static string editBranchStockdetail(string itbsid)
    {
        mySqlConnection db = new mySqlConnection();
        MySqlParameter[] p = { new MySqlParameter("@itbsid", itbsid) };
        
        string qry = "SELECT * FROM tbl_itembranch_stock where itbs_id = @itbsid";
        DataTable dt = db.SelectQuery(qry, p);

        string stock_new = db.SelectScalar(
            "SELECT IFNULL(SUM(si.si_qty+si.si_foc),0) AS total_qty FROM tbl_sales_items si INNER JOIN tbl_sales_master sm ON sm.sm_id=si.sm_id WHERE si.itbs_id=@itbsid AND sm.sm_delivery_status IN (0,3,6)",
            p
        );

        string stock_processed = db.SelectScalar(
            "SELECT IFNULL(SUM(si.si_qty+si.si_foc),0) AS total_qty FROM tbl_sales_items si INNER JOIN tbl_sales_master sm ON sm.sm_id=si.sm_id WHERE si.itbs_id=@itbsid AND sm.sm_delivery_status=1",
            p
        );

        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < dt.Rows.Count; i++)
        {
            sb.Append("" + dt.Rows[i]["itbs_id"] + "@#$" + dt.Rows[i]["branch_id"] + "@#$" + dt.Rows[i]["itm_id"] + "@#$" + dt.Rows[i]["itbs_stock"] + "@#$" + dt.Rows[i]["itbs_reorder"] + "@#$" + dt.Rows[i]["itbs_available"] + "@#$" + dt.Rows[i]["itm_mrp"] + "@#$" + dt.Rows[i]["itm_mrp"] + "@#$" + dt.Rows[i]["itm_mrp"] + "@#$" + dt.Rows[i]["itm_mrp"] + "@#$" + dt.Rows[i]["itm_commision"] + "@#$" + dt.Rows[i]["itm_target"] + "@#$" + dt.Rows[i]["itm_name"] + "@#$" + dt.Rows[i]["tp_tax_code"] + "@#$" + dt.Rows[i]["itbs_duration"] + "@#$" + dt.Rows[i]["itm_rating"] + "@#$" + stock_new + "@#$" + stock_processed + "@#$" + dt.Rows[i]["itbs_purchase_price"] + "@#$" + dt.Rows[i]["itbs_purchase_status"]);
        }
        string priceqry = "select tpm_id,tip_price from tbl_item_pricelist where itbs_id=@itbsid";
        DataTable dtPriceMaster = db.SelectQuery(priceqry, p);
        string priceObj = JsonConvert.SerializeObject(dtPriceMaster);
        sb.Append("@#$" + priceObj + "");

        return sb.ToString();
    }

    [WebMethod]
    public static string showsearchBranches()
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        StringBuilder sb = new StringBuilder();

        var staffIdCookie = HttpContext.Current.Request.Cookies["invntrystaffId"];
        string staffId = staffIdCookie != null ? staffIdCookie.Value : "";

        string query = "select tb.branch_id,branch_name from tbl_branch tb inner join tbl_user_branches ub on ub.branch_id=tb.branch_id where user_id=@userId";
        MySqlParameter[] p = { new MySqlParameter("@userId", staffId) };
        dt = db.SelectQuery(query, p);
        if (dt != null)
        {
            if (dt.Rows.Count > 0)
            {
                if (dt.Rows[0]["branch_id"] is DBNull)
                {
                    sb.Append("<option value='0' selected='selected'>--All Warehouses--</option>");
                }
                else
                {
                    sb.Append("<option value='0' selected='selected'>--All Warehouses--</option>");
                    for (int i = 0; i < dt.Rows.Count; i++)
                    {
                        sb.Append("<option value='" + dt.Rows[i]["branch_id"] + "'>" + dt.Rows[i]["branch_name"] + "</option>");
                    }
                }
            }
            else
            {
                sb.Append("<option value='0' selected>--All Warehouses--</option>");
            }
        }
        return sb.ToString();
    }

    [WebMethod]
    public static string loadCategory()
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

    [WebMethod]
    public static string loadbrands()
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

    //start: Item Pos Search Details
    [WebMethod]
    public static string searchItem(int page, Dictionary<string, string> Itemfilters, int perpage)
    {
        try
        {
            List<MySqlParameter> parameters = new List<MySqlParameter>();
            string query_condition = "";
            if (Itemfilters.Count > 0)
            {
                query_condition = " where 1=1 and itm_id NOT IN(select itm_id from tbl_itembranch_stock where branch_id = @warehouse)";
                parameters.Add(new MySqlParameter("@warehouse", Itemfilters["warehouse"]));

                if (Itemfilters.ContainsKey("item_code"))
                {
                    query_condition += " and itm_code LIKE @itemCode";
                    parameters.Add(new MySqlParameter("@itemCode", "%" + Itemfilters["item_code"] + "%"));
                }
                if (Itemfilters.ContainsKey("item_name"))
                {
                    query_condition += " and itm_name LIKE @itemName";
                    parameters.Add(new MySqlParameter("@itemName", "%" + Itemfilters["item_name"] + "%"));
                }
            }
            int per_page = perpage;
            int offset = (page - 1) * per_page;
            mySqlConnection db = new mySqlConnection();
            string innerqry = "";
            string countQry = "SELECT count(*) FROM tbl_item_master " + query_condition;
            
            double numrows = Convert.ToInt32(db.SelectScalar(countQry, CloneParameters(parameters)));
            if (numrows == 0)
            {
                return "N";
            }

            innerqry = "SELECT itm_id,itm_code,itm_name FROM tbl_item_master " + query_condition;
            innerqry = innerqry + " order by itm_name LIMIT " + offset.ToString() + " ," + per_page;
            
            DataTable dt = db.SelectQuery(innerqry, CloneParameters(parameters));
            string jsonResponse = "";
            if (dt.Rows.Count > 0)
            {
                string jsonData = JsonConvert.SerializeObject(dt);
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
            string query = "SELECT tp_tax_code,tp_tax_title FROM tbl_tax_profile where tp_tax_type = @taxType ORDER BY tp_tax_code ASC";
            MySqlParameter[] p = { new MySqlParameter("@taxType", taxType) };
            dt = db.SelectQuery(query, p);
            if (dt != null)
            {
                if (dt.Rows.Count > 0)
                {
                    if (dt.Rows[0]["tp_tax_code"] is DBNull)
                    {
                        sb.Append("<option value='-1' selected='selected'>--Tax Code--</option>");
                    }
                    else
                    {
                        sb.Append("<option value='-1' selected='selected'>--Tax code--</option>");
                        for (int i = 0; i < dt.Rows.Count; i++)
                        {
                            sb.Append("<option value='" + dt.Rows[i]["tp_tax_code"] + "'>" + dt.Rows[i]["tp_tax_title"] + "</option>");
                        }
                    }
                }
                else
                {
                    sb.Append("<option value='-1' selected='selected'>--Tax Code--</option>");
                }
            }
        }
        return sb.ToString();
    }

    //search branchstock table
    [WebMethod]
    public static string DownloadItemDetails(Dictionary<string, string> filters)
    {
        try
        {
            List<MySqlParameter> parameters = new List<MySqlParameter>();
            string query_condition = "";
            string session_query_condition = ""; 

            var staffIdCookie = HttpContext.Current.Request.Cookies["invntrystaffId"];
            string staffId = staffIdCookie != null ? staffIdCookie.Value : "";

            if (filters.Count > 0)
            {
                query_condition = " where 1=1 ";
                session_query_condition = " where 1=1 ";

                if (filters.ContainsKey("itemval"))
                {
                    string itemvalEscaped = SanitizeSqlString(filters["itemval"]);
                    query_condition += " and (itbs.itm_name LIKE @itemval or itbs.itm_code like @itemval)";
                    session_query_condition += " and (itbs.itm_name LIKE '%" + itemvalEscaped + "%' or itbs.itm_code like '%" + itemvalEscaped + "%')";
                    parameters.Add(new MySqlParameter("@itemval", "%" + filters["itemval"] + "%"));
                }
                if (filters.ContainsKey("branch"))
                {
                    string branchEscaped = SanitizeSqlString(filters["branch"]);
                    if (filters["branch"] == "0")
                    {
                        query_condition += " and itbs.branch_id in (select branch_id from tbl_user_branches where user_id = @staffId)";
                        session_query_condition += " and itbs.branch_id in (select branch_id from tbl_user_branches where user_id=" + SanitizeSqlString(staffId) + ")";
                        parameters.Add(new MySqlParameter("@staffId", staffId));
                    }
                    else
                    {
                        query_condition += " and itbs.branch_id = @branch";
                        session_query_condition += " and itbs.branch_id = '" + branchEscaped + "'";
                        parameters.Add(new MySqlParameter("@branch", filters["branch"]));
                    }
                }
                if (filters.ContainsKey("brand"))
                {
                    string brandEscaped = SanitizeSqlString(filters["brand"]);
                    query_condition += " and itbs.itm_brand_id = @brand";
                    session_query_condition += " and itbs.itm_brand_id = '" + brandEscaped + "'";
                    parameters.Add(new MySqlParameter("@brand", filters["brand"]));
                }
                if (filters.ContainsKey("category"))
                {
                    string catEscaped = SanitizeSqlString(filters["category"]);
                    query_condition += " and itbs.itm_category_id = @category";
                    session_query_condition += " and itbs.itm_category_id = '" + catEscaped + "'";
                    parameters.Add(new MySqlParameter("@category", filters["category"]));
                }
                if (filters.ContainsKey("itmstock"))
                {
                    if (Convert.ToInt32(filters["itmstock"]) == 1)
                    {
                        query_condition += " and itbs.itbs_stock>=itbs.itbs_reorder";
                        session_query_condition += " and itbs.itbs_stock>=itbs.itbs_reorder";
                    }
                    else if (Convert.ToInt32(filters["itmstock"]) == 2)
                    {
                        query_condition += " and itbs.itbs_stock<itbs.itbs_reorder";
                        session_query_condition += " and itbs.itbs_stock<itbs.itbs_reorder";
                    }
                }
            }

            mySqlConnection db = new mySqlConnection();
            string countQry = "SELECT count(*) FROM tbl_itembranch_stock itbs" + query_condition;

            double numrows = Convert.ToInt32(db.SelectScalar(countQry, CloneParameters(parameters)));
            if (numrows == 0)
            {
                return "N";
            }

            string innerqry = @"select itbs.itbs_id as id,itbs.itm_code as 'Item Code',itbs.itm_name as 'Item Name',br.branch_name as 'Warehouse',ib.brand_name as Brand,ic.cat_name as Category,itbs.itbs_purchase_price as 'Purchase Price',
tp.tp_tax_title as 'HSN Code',tp.tp_tax_percentage as 'Tax Percentage',(itbs.itbs_stock+ifnull( sum(si.si_qty+si.si_foc),0)) as Total_stock, ifnull( sum(si.si_qty+si.si_foc),0) AS NewTobeConfirmedPendingOrder  ";
            innerqry += " from tbl_itembranch_stock itbs inner join tbl_tax_profile tp on tp.tp_tax_code=itbs.tp_tax_code inner join tbl_item_brand ib on ib.brand_id=itbs.itm_brand_id inner join tbl_item_category ic on ic.cat_id=itbs.itm_category_id inner join tbl_branch br on br.branch_id=itbs.branch_id left join tbl_sales_items si";
            innerqry += " inner join tbl_sales_master sm on sm.sm_id = si.sm_id on itbs.itbs_id = si.itbs_id and sm.sm_delivery_status in (0,3,6) ";
            innerqry = innerqry + session_query_condition;
            innerqry = innerqry + " group by itbs.itbs_id, itbs.itm_code, itbs.itm_name, br.branch_name, ib.brand_name, ic.cat_name, itbs.itbs_purchase_price, tp.tp_tax_title, tp.tp_tax_percentage, itbs.itbs_stock order by itbs.itbs_id";

            HttpContext.Current.Session["downloadqry"] = innerqry;
            return "Y";
        }
        catch (Exception ex)
        {
            return ex.ToString();
        }
    }

    private static MySqlParameter[] CloneParameters(List<MySqlParameter> source)
    {
        MySqlParameter[] copy = new MySqlParameter[source.Count];
        for (int i = 0; i < source.Count; i++)
        {
            copy[i] = new MySqlParameter(source[i].ParameterName, source[i].Value);
        }
        return copy;
    }

    private static string SanitizeSqlString(string input)
    {
        if (string.IsNullOrEmpty(input)) return "";
        return input.Replace("'", "''");
    }
}