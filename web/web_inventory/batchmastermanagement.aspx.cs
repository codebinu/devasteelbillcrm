using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.Services;
using System.Data;
using System.Text;
using commonfunction;
using Newtonsoft.Json;

public partial class web_inventory_batchmastermanagement : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication auth = new LoginAuthentication();
        auth.userAuthentication();
        auth.checkPageAcess(12);
    }

    // Load Spec Brand dropdown options for modal filters
    [WebMethod]
    public static string loadFilterDropdowns()
    {
        try
        {
            mySqlConnection db = new mySqlConnection();
            DataTable dtSpecBrands = db.SelectQuery("SELECT itsv_id, itsv_name FROM tbl_item_master_spe_values WHERE itst_id = 3 ORDER BY itsv_name ASC");
            StringBuilder sbSpecBrands = new StringBuilder("<option value='-1'>--All Spec Brands--</option>");
            if (dtSpecBrands != null && dtSpecBrands.Rows.Count > 0)
            {
                foreach (DataRow r in dtSpecBrands.Rows)
                {
                    sbSpecBrands.Append("<option value='" + r["itsv_id"] + "'>" + HttpUtility.HtmlEncode(r["itsv_name"].ToString()) + "</option>");
                }
            }

            var result = new
            {
                specBrands = sbSpecBrands.ToString()
            };
            return JsonConvert.SerializeObject(result);
        }
        catch (Exception ex)
        {
            return JsonConvert.SerializeObject(new { error = ex.Message });
        }
    }

    // Fast Autocomplete for adding items
    [WebMethod]
    public static string searchItemsAutocomplete(string term)
    {
        try
        {
            mySqlConnection db = new mySqlConnection();
            string safeTerm = (term ?? "").Trim().Replace("'", "''");
            string qry = @"SELECT 
                im.itm_id, 
                im.itm_code, 
                im.itm_name, 
                COALESCE(im.itsv_printing_name, '') AS itsv_printing_name, 
                COALESCE(im.itsv_spec_brand, '') AS itsv_spec_brand,
                COALESCE(sp_brand.itsv_name, '') AS spec_brand_name
            FROM tbl_item_master im
            LEFT JOIN tbl_item_master_spe_values sp_brand ON sp_brand.itsv_id = im.itsv_spec_brand
            WHERE (im.itm_code LIKE '%" + safeTerm + @"%' 
               OR im.itm_name LIKE '%" + safeTerm + @"%' 
               OR im.itsv_printing_name LIKE '%" + safeTerm + @"%'
               OR sp_brand.itsv_name LIKE '%" + safeTerm + @"%')
            ORDER BY im.itm_id DESC LIMIT 20";

            DataTable dt = db.SelectQuery(qry);
            if (dt != null && dt.Rows.Count > 0)
            {
                var list = new List<object>();
                foreach (DataRow r in dt.Rows)
                {
                    string code = r["itm_code"].ToString();
                    string name = r["itm_name"].ToString();
                    string printName = r["itsv_printing_name"].ToString();
                    string specBrand = r["spec_brand_name"].ToString();
                    string label = code + " - " + name + (!string.IsNullOrWhiteSpace(specBrand) ? " [" + specBrand + "]" : "");
                    list.Add(new
                    {
                        id = Convert.ToInt32(r["itm_id"]),
                        code = code,
                        name = name,
                        printingName = printName,
                        specBrand = specBrand,
                        label = label,
                        value = label
                    });
                }
                return JsonConvert.SerializeObject(list);
            }
            return "[]";
        }
        catch (Exception ex)
        {
            return JsonConvert.SerializeObject(new { error = ex.Message });
        }
    }

    // Search and paginate Catalog Items for the "Select Items Modal" using itsv_spec_brand
    [WebMethod]
    public static string searchCatalogItems(int page, string search, string specBrand, int perpage)
    {
        try
        {
            mySqlConnection db = new mySqlConnection();
            string cond = " WHERE 1=1";

            if (!string.IsNullOrWhiteSpace(search))
            {
                string safe = search.Trim().Replace("'", "''");
                cond += " AND (im.itm_code LIKE '%" + safe + "%' OR im.itm_name LIKE '%" + safe + "%' OR im.itsv_printing_name LIKE '%" + safe + "%' OR sp_brand.itsv_name LIKE '%" + safe + "%')";
            }

            if (!string.IsNullOrWhiteSpace(specBrand) && specBrand != "-1")
            {
                string safeBrand = specBrand.Trim().Replace("'", "''");
                cond += " AND im.itsv_spec_brand = '" + safeBrand + "'";
            }

            string countQry = @"SELECT COUNT(*) 
                               FROM tbl_item_master im 
                               LEFT JOIN tbl_item_master_spe_values sp_brand ON sp_brand.itsv_id = im.itsv_spec_brand " + cond;
            double numrows = Convert.ToInt32(db.SelectScalar(countQry));
            if (numrows == 0) return "N";

            double per_page = perpage > 0 ? perpage : 25;
            double offset = (page - 1) * per_page;

            string pageQry = @"SELECT 
                im.itm_id,
                im.itm_code,
                im.itm_name,
                COALESCE(im.itsv_printing_name, '') AS itsv_printing_name,
                COALESCE(im.itsv_spec_brand, '') AS itsv_spec_brand,
                COALESCE(sp_brand.itsv_name, '') AS spec_brand_name,
                COALESCE(u.tum_name, '') AS uom_name
            FROM tbl_item_master im
            LEFT JOIN tbl_item_master_spe_values sp_brand ON sp_brand.itsv_id = im.itsv_spec_brand
            LEFT JOIN tbl_item_uom u ON u.tum_id = im.itsv_uom_sales "
            + cond + @"
            ORDER BY im.itm_id DESC
            LIMIT " + offset.ToString() + ", " + per_page.ToString();

            DataTable dt = db.SelectQuery(pageQry);
            if (dt != null && dt.Rows.Count > 0)
            {
                string jsonData = JsonConvert.SerializeObject(dt, Formatting.Indented);
                return "{\"count\":\"" + numrows + "\",\"data\":" + jsonData + "}";
            }
            return "N";
        }
        catch (Exception ex)
        {
            return JsonConvert.SerializeObject(new { error = ex.Message });
        }
    }

    // Search and list Batch Masters
    [WebMethod]
    public static string searchBatchMasterList(int page, Dictionary<string, string> filters, int perpage)
    {
        try
        {
            mySqlConnection db = new mySqlConnection();
            string query_condition = " WHERE 1=1";

            if (filters != null && filters.Count > 0)
            {
                if (filters.ContainsKey("search") && !string.IsNullOrWhiteSpace(filters["search"]))
                {
                    string safe = filters["search"].Trim().Replace("'", "''");
                    query_condition += " AND (bm.itbm_prefix LIKE '%" + safe + "%' OR bm.itbm_suffix LIKE '%" + safe + "%' OR CONCAT(COALESCE(bm.itbm_prefix, ''), COALESCE(bm.itbm_serl, 0), COALESCE(bm.itbm_suffix, '')) LIKE '%" + safe + "%')";
                }

                if (filters.ContainsKey("item") && !string.IsNullOrWhiteSpace(filters["item"]))
                {
                    string safeItem = filters["item"].Trim().Replace("'", "''");
                    query_condition += " AND EXISTS (SELECT 1 FROM tbl_item_batch_master_items bmi2 JOIN tbl_item_master im2 ON im2.itm_id = bmi2.itm_id WHERE bmi2.itbm_id = bm.itbm_id AND (im2.itm_code LIKE '%" + safeItem + "%' OR im2.itm_name LIKE '%" + safeItem + "%' OR im2.itsv_printing_name LIKE '%" + safeItem + "%'))";
                }
            }

            string countQry = "SELECT COUNT(DISTINCT bm.itbm_id) FROM tbl_item_batch_master bm LEFT JOIN tbl_item_batch_master_items bmi ON bmi.itbm_id = bm.itbm_id " + query_condition;
            double numrows = Convert.ToInt32(db.SelectScalar(countQry));
            if (numrows == 0)
            {
                return "N";
            }

            double per_page = perpage > 0 ? perpage : 25;
            double offset = (page - 1) * per_page;

            string pageQry = @"SELECT 
                bm.itbm_id,
                COALESCE(bm.itbm_prefix, '') AS itbm_prefix,
                COALESCE(bm.itbm_suffix, '') AS itbm_suffix,
                COALESCE(bm.itbm_serl, 0) AS itbm_serl,
                CONCAT(COALESCE(bm.itbm_prefix, ''), COALESCE(bm.itbm_serl, 0), COALESCE(bm.itbm_suffix, '')) AS sample_batch,
                COUNT(bmi.itbmi_id) AS total_items
            FROM tbl_item_batch_master bm
            LEFT JOIN tbl_item_batch_master_items bmi ON bmi.itbm_id = bm.itbm_id "
            + query_condition + @"
            GROUP BY bm.itbm_id, bm.itbm_prefix, bm.itbm_suffix, bm.itbm_serl
            ORDER BY bm.itbm_id DESC
            LIMIT " + offset.ToString() + ", " + per_page.ToString();

            DataTable dt = db.SelectQuery(pageQry);
            if (dt != null && dt.Rows.Count > 0)
            {
                string jsonData = JsonConvert.SerializeObject(dt, Formatting.Indented);
                return "{\"count\":\"" + numrows + "\",\"data\":" + jsonData + "}";
            }
            return "N";
        }
        catch (Exception ex)
        {
            return JsonConvert.SerializeObject(new { error = ex.Message });
        }
    }

    // Get Batch Master Details for Edit
    [WebMethod]
    public static string getBatchMasterDetails(int batchId)
    {
        try
        {
            mySqlConnection db = new mySqlConnection();
            string headQry = "SELECT itbm_id, itbm_prefix, itbm_suffix, itbm_serl FROM tbl_item_batch_master WHERE itbm_id = " + batchId;
            DataTable dtHead = db.SelectQuery(headQry);
            if (dtHead == null || dtHead.Rows.Count == 0) return "N";

            int totalAssigned = Convert.ToInt32(db.SelectScalar("SELECT COUNT(*) FROM tbl_item_batch_master_items WHERE itbm_id = " + batchId));
            int totalMasterItems = Convert.ToInt32(db.SelectScalar("SELECT COUNT(*) FROM tbl_item_master"));
            bool isAll = (totalAssigned > 0 && totalAssigned >= totalMasterItems);

            // Fetch sample/top 100 assigned items for display if specific
            string itemsQry = @"SELECT 
                bmi.itm_id,
                im.itm_code,
                im.itm_name,
                COALESCE(im.itsv_printing_name, '') AS itsv_printing_name,
                COALESCE(im.itsv_spec_brand, '') AS itsv_spec_brand,
                COALESCE(sp_brand.itsv_name, '') AS spec_brand_name
            FROM tbl_item_batch_master_items bmi
            JOIN tbl_item_master im ON im.itm_id = bmi.itm_id
            LEFT JOIN tbl_item_master_spe_values sp_brand ON sp_brand.itsv_id = im.itsv_spec_brand
            WHERE bmi.itbm_id = " + batchId + @"
            ORDER BY im.itm_id ASC LIMIT 200";
            DataTable dtItems = db.SelectQuery(itemsQry);

            var result = new
            {
                header = dtHead.Rows[0].Table,
                totalAssigned = totalAssigned,
                totalMasterItems = totalMasterItems,
                isAllItems = isAll,
                sampleItems = dtItems
            };
            return JsonConvert.SerializeObject(result, Formatting.Indented);
        }
        catch (Exception ex)
        {
            return JsonConvert.SerializeObject(new { error = ex.Message });
        }
    }

    // Get assigned items for the "View Assigned Items Modal"
    [WebMethod]
    public static string getAssignedItems(int batchId, int page, string search, string specBrand, int perpage)
    {
        try
        {
            mySqlConnection db = new mySqlConnection();
            string cond = " WHERE bmi.itbm_id = " + batchId;

            if (!string.IsNullOrWhiteSpace(search))
            {
                string safe = search.Trim().Replace("'", "''");
                cond += " AND (im.itm_code LIKE '%" + safe + "%' OR im.itm_name LIKE '%" + safe + "%' OR im.itsv_printing_name LIKE '%" + safe + "%' OR sp_brand.itsv_name LIKE '%" + safe + "%')";
            }

            if (!string.IsNullOrWhiteSpace(specBrand) && specBrand != "-1")
            {
                string safeBrand = specBrand.Trim().Replace("'", "''");
                cond += " AND im.itsv_spec_brand = '" + safeBrand + "'";
            }

            string countQry = @"SELECT COUNT(*) 
                               FROM tbl_item_batch_master_items bmi 
                               JOIN tbl_item_master im ON im.itm_id = bmi.itm_id 
                               LEFT JOIN tbl_item_master_spe_values sp_brand ON sp_brand.itsv_id = im.itsv_spec_brand " + cond;
            double numrows = Convert.ToInt32(db.SelectScalar(countQry));
            if (numrows == 0) return "N";

            double per_page = perpage > 0 ? perpage : 25;
            double offset = (page - 1) * per_page;

            string pageQry = @"SELECT 
                bmi.itbmi_id,
                im.itm_id,
                im.itm_code,
                im.itm_name,
                COALESCE(im.itsv_printing_name, '') AS itsv_printing_name,
                COALESCE(im.itsv_spec_brand, '') AS itsv_spec_brand,
                COALESCE(sp_brand.itsv_name, '') AS spec_brand_name,
                COALESCE(u.tum_name, '') AS uom_name
            FROM tbl_item_batch_master_items bmi
            JOIN tbl_item_master im ON im.itm_id = bmi.itm_id
            LEFT JOIN tbl_item_master_spe_values sp_brand ON sp_brand.itsv_id = im.itsv_spec_brand
            LEFT JOIN tbl_item_uom u ON u.tum_id = im.itsv_uom_sales "
            + cond + @"
            ORDER BY im.itm_id ASC
            LIMIT " + offset.ToString() + ", " + per_page.ToString();

            DataTable dt = db.SelectQuery(pageQry);
            if (dt != null && dt.Rows.Count > 0)
            {
                string jsonData = JsonConvert.SerializeObject(dt, Formatting.Indented);
                return "{\"count\":\"" + numrows + "\",\"data\":" + jsonData + "}";
            }
            return "N";
        }
        catch (Exception ex)
        {
            return JsonConvert.SerializeObject(new { error = ex.Message });
        }
    }

    // Save or Update Batch Master
    [WebMethod]
    public static string saveBatchMaster(string actionType, int batchId, string prefix, string suffix, int serialNo, string assignMode, List<int> itemIds)
    {
        try
        {
            prefix = (prefix ?? "").Trim();
            suffix = (suffix ?? "").Trim();
            if (serialNo < 0) serialNo = 0;

            if (string.IsNullOrWhiteSpace(prefix) && string.IsNullOrWhiteSpace(suffix))
            {
                return "Please enter a valid Prefix or Suffix for the Batch Master format.";
            }

            mySqlConnection db = new mySqlConnection();
            string safePrefix = prefix.Replace("'", "''");
            string safeSuffix = suffix.Replace("'", "''");

            int targetBatchId = batchId;

            if (actionType == "insert")
            {
                string insertQry = string.Format(
                    "INSERT INTO tbl_item_batch_master (itbm_prefix, itbm_suffix, itbm_serl) VALUES ('{0}', '{1}', {2})",
                    safePrefix, safeSuffix, serialNo
                );

                if (!db.ExecuteQuery(insertQry))
                {
                    return "Error inserting Batch Master.";
                }

                targetBatchId = Convert.ToInt32(db.SelectScalar("SELECT LAST_INSERT_ID()"));
                if (targetBatchId <= 0)
                {
                    targetBatchId = Convert.ToInt32(db.SelectScalar("SELECT MAX(itbm_id) FROM tbl_item_batch_master"));
                }
            }
            else if (actionType == "update")
            {
                if (targetBatchId <= 0) return "Invalid Batch Master ID.";

                string updateQry = string.Format(
                    "UPDATE tbl_item_batch_master SET itbm_prefix = '{0}', itbm_suffix = '{1}', itbm_serl = {2} WHERE itbm_id = {3}",
                    safePrefix, safeSuffix, serialNo, targetBatchId
                );

                if (!db.ExecuteQuery(updateQry))
                {
                    return "Error updating Batch Master.";
                }
            }

            // Handle Item Assignments
            if (assignMode == "ALL")
            {
                db.ExecuteQuery("DELETE FROM tbl_item_batch_master_items WHERE itbm_id = " + targetBatchId);
                string bulkAssign = "INSERT INTO tbl_item_batch_master_items (itbm_id, itm_id) SELECT " + targetBatchId + ", itm_id FROM tbl_item_master";
                db.ExecuteQuery(bulkAssign);
            }
            else if (assignMode == "SPECIFIC")
            {
                db.ExecuteQuery("DELETE FROM tbl_item_batch_master_items WHERE itbm_id = " + targetBatchId);
                if (itemIds != null && itemIds.Count > 0)
                {
                    var distinctIds = itemIds.Distinct().Where(id => id > 0).ToList();
                    int batchChunkSize = 500;
                    for (int i = 0; i < distinctIds.Count; i += batchChunkSize)
                    {
                        var chunk = distinctIds.Skip(i).Take(batchChunkSize);
                        StringBuilder sb = new StringBuilder("INSERT INTO tbl_item_batch_master_items (itbm_id, itm_id) VALUES ");
                        bool first = true;
                        foreach (int id in chunk)
                        {
                            if (!first) sb.Append(",");
                            sb.Append("(" + targetBatchId + "," + id + ")");
                            first = false;
                        }
                        db.ExecuteQuery(sb.ToString());
                    }
                }
            }
            else if (assignMode == "NONE")
            {
                db.ExecuteQuery("DELETE FROM tbl_item_batch_master_items WHERE itbm_id = " + targetBatchId);
            }
            // If assignMode == "KEEP", we don't alter tbl_item_batch_master_items

            return "Y";
        }
        catch (Exception ex)
        {
            return "Error: " + ex.Message;
        }
    }

    // Unlink items from tbl_item_batch_master_items
    [WebMethod]
    public static string unlinkBatchItems(int batchId, List<int> itemIds, bool unlinkAll)
    {
        try
        {
            if (batchId <= 0) return "Invalid Batch Master ID.";
            mySqlConnection db = new mySqlConnection();

            if (unlinkAll)
            {
                string delAllQry = "DELETE FROM tbl_item_batch_master_items WHERE itbm_id = " + batchId;
                if (db.ExecuteQuery(delAllQry))
                {
                    return "Y";
                }
                return "Error unlinking all items.";
            }

            if (itemIds == null || itemIds.Count == 0)
            {
                return "Please select at least one item to unlink.";
            }

            var distinctIds = itemIds.Distinct().Where(id => id > 0).ToList();
            int chunkSize = 1000;
            for (int i = 0; i < distinctIds.Count; i += chunkSize)
            {
                var chunk = distinctIds.Skip(i).Take(chunkSize);
                string idList = string.Join(",", chunk);
                string delQry = "DELETE FROM tbl_item_batch_master_items WHERE itbm_id = " + batchId + " AND itm_id IN (" + idList + ")";
                db.ExecuteQuery(delQry);
            }

            return "Y";
        }
        catch (Exception ex)
        {
            return "Error: " + ex.Message;
        }
    }

    // Delete Batch Master
    [WebMethod]
    public static string deleteBatchMaster(int batchId)
    {
        try
        {
            if (batchId <= 0) return "Invalid ID.";
            mySqlConnection db = new mySqlConnection();
            db.ExecuteQuery("DELETE FROM tbl_item_batch_master_items WHERE itbm_id = " + batchId);
            if (db.ExecuteQuery("DELETE FROM tbl_item_batch_master WHERE itbm_id = " + batchId))
            {
                return "Y";
            }
            return "Error deleting Batch Master.";
        }
        catch (Exception ex)
        {
            return "Error: " + ex.Message;
        }
    }

    // Prepare Batch Master Export Query for Excel
    [WebMethod(EnableSession = true)]
    public static string prepareBatchMasterExport(Dictionary<string, string> filters)
    {
        try
        {
            string query_condition = " WHERE 1=1";
            if (filters != null && filters.Count > 0)
            {
                if (filters.ContainsKey("search") && !string.IsNullOrWhiteSpace(filters["search"]))
                {
                    string safe = filters["search"].Trim().Replace("'", "''");
                    query_condition += " AND (bm.itbm_prefix LIKE '%" + safe + "%' OR bm.itbm_suffix LIKE '%" + safe + "%' OR CONCAT(COALESCE(bm.itbm_prefix, ''), COALESCE(bm.itbm_serl, 0), COALESCE(bm.itbm_suffix, '')) LIKE '%" + safe + "%')";
                }

                if (filters.ContainsKey("item") && !string.IsNullOrWhiteSpace(filters["item"]))
                {
                    string safeItem = filters["item"].Trim().Replace("'", "''");
                    query_condition += " AND EXISTS (SELECT 1 FROM tbl_item_batch_master_items bmi2 JOIN tbl_item_master im2 ON im2.itm_id = bmi2.itm_id WHERE bmi2.itbm_id = bm.itbm_id AND (im2.itm_code LIKE '%" + safeItem + "%' OR im2.itm_name LIKE '%" + safeItem + "%' OR im2.itsv_printing_name LIKE '%" + safeItem + "%'))";
                }
            }

            mySqlConnection db = new mySqlConnection();
            string countQry = "SELECT COUNT(DISTINCT bm.itbm_id) FROM tbl_item_batch_master bm LEFT JOIN tbl_item_batch_master_items bmi ON bmi.itbm_id = bm.itbm_id " + query_condition;
            double numrows = Convert.ToInt32(db.SelectScalar(countQry));
            if (numrows == 0) return "N";

            string exportQry = @"SELECT 
                bm.itbm_id AS 'Batch Master ID',
                COALESCE(bm.itbm_prefix, '') AS 'Prefix',
                COALESCE(bm.itbm_serl, 0) AS 'Current Serial',
                COALESCE(bm.itbm_suffix, '') AS 'Suffix',
                CONCAT(COALESCE(bm.itbm_prefix, ''), COALESCE(bm.itbm_serl, 0), COALESCE(bm.itbm_suffix, '')) AS 'Sample Batch Number',
                COUNT(bmi.itbmi_id) AS 'Total Assigned Items'
            FROM tbl_item_batch_master bm
            LEFT JOIN tbl_item_batch_master_items bmi ON bmi.itbm_id = bm.itbm_id "
            + query_condition + @"
            GROUP BY bm.itbm_id, bm.itbm_prefix, bm.itbm_suffix, bm.itbm_serl
            ORDER BY bm.itbm_id DESC";

            HttpContext.Current.Session["batchmaster_downloadqry"] = exportQry;
            return "Y";
        }
        catch (Exception ex)
        {
            return ex.Message;
        }
    }
}
