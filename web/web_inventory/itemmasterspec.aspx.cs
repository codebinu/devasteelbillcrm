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

public partial class web_inventory_itemmasterspec : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication itemMasterSpec = new LoginAuthentication();
        itemMasterSpec.userAuthentication();
        itemMasterSpec.checkPageAcess(12);
    }

    private static string GetSystemDateTime(mySqlConnection db)
    {
        try
        {
            string selectTimezonQuery = "SELECT ss_default_time_zone FROM tbl_system_settings";
            DataTable timezoneDt = db.SelectQuery(selectTimezonQuery);
            if (timezoneDt != null && timezoneDt.Rows.Count > 0 && timezoneDt.Rows[0]["ss_default_time_zone"] != DBNull.Value)
            {
                TimeZoneInfo CurrentZone = TimeZoneInfo.FindSystemTimeZoneById(timezoneDt.Rows[0]["ss_default_time_zone"].ToString());
                DateTime TimeNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, CurrentZone);
                return TimeNow.ToString("yyyy-MM-dd HH:mm:ss");
            }
        }
        catch
        {
        }
        return DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
    }

    // Loading specification types for form dropdown
    [WebMethod]
    public static string showSpecTypes()
    {
        mySqlConnection db = new mySqlConnection();
        StringBuilder sb = new StringBuilder();
        string query = "SELECT itst_id, itst_name FROM tbl_item_master_spe_type ORDER BY itst_name ASC";
        DataTable dt = db.SelectQuery(query);

        sb.Append("<option value='-1' selected='selected'>--Select Spec Type--</option>");
        if (dt != null && dt.Rows.Count > 0)
        {
            for (int i = 0; i < dt.Rows.Count; i++)
            {
                sb.Append("<option value='" + dt.Rows[i]["itst_id"] + "'>" + HttpUtility.HtmlEncode(dt.Rows[i]["itst_name"].ToString()) + "</option>");
            }
        }

        return sb.ToString();
    }

    // Loading specification types for search filter dropdown
    [WebMethod]
    public static string showSearchSpecTypes()
    {
        mySqlConnection db = new mySqlConnection();
        StringBuilder sb = new StringBuilder();
        string query = "SELECT itst_id, itst_name FROM tbl_item_master_spe_type ORDER BY itst_name ASC";
        DataTable dt = db.SelectQuery(query);

        sb.Append("<option value='-1' selected='selected'>--All Spec Types--</option>");
        if (dt != null && dt.Rows.Count > 0)
        {
            for (int i = 0; i < dt.Rows.Count; i++)
            {
                sb.Append("<option value='" + dt.Rows[i]["itst_id"] + "'>" + HttpUtility.HtmlEncode(dt.Rows[i]["itst_name"].ToString()) + "</option>");
            }
        }

        return sb.ToString();
    }

    // Get next sequence number for a given spec type
    [WebMethod]
    public static string getNextSeq(int typeId)
    {
        try
        {
            mySqlConnection db = new mySqlConnection();
            string query = "SELECT COALESCE(MAX(itsv_seq), 0) + 1 FROM tbl_item_master_spe_values WHERE itst_id = " + typeId;
            string nextSeq = db.SelectScalar(query);
            if (string.IsNullOrEmpty(nextSeq))
            {
                return "1";
            }
            return nextSeq;
        }
        catch
        {
            return "1";
        }
    }

    // Save (insert / update) specification value
    [WebMethod]
    public static string addSpecValue(string actionType, string specId, int typeId, int seq, string specValue)
    {
        try
        {
            if (typeId <= 0 || string.IsNullOrWhiteSpace(specValue))
            {
                return "VAL_ERR";
            }

            mySqlConnection db = new mySqlConnection();
            string updatedDate = GetSystemDateTime(db);
            string safeSpecValue = specValue.Trim().Replace("'", "''");

            // Fetch spec type name
            string typeQuery = "SELECT itst_name FROM tbl_item_master_spe_type WHERE itst_id = " + typeId;
            DataTable dtType = db.SelectQuery(typeQuery);
            if (dtType == null || dtType.Rows.Count == 0)
            {
                return "INVALID_TYPE";
            }
            string typeName = dtType.Rows[0]["itst_name"].ToString().Trim().Replace("'", "''");

            if (actionType == "insert")
            {
                // Check duplicate within same type
                string chkQry = "SELECT COUNT(*) FROM tbl_item_master_spe_values WHERE itst_id = " + typeId + " AND itsv_name = '" + safeSpecValue + "'";
                double count = Convert.ToDouble(db.SelectScalar(chkQry));
                if (count > 0)
                {
                    return "E"; // Exists
                }

                string insertQry = "INSERT INTO tbl_item_master_spe_values (itsv_id, itst_id, itst_name, itsv_seq, itsv_name, itsv_lastupdate_date) " +
                                  "VALUES (NULL, " + typeId + ", '" + typeName + "', " + seq + ", '" + safeSpecValue + "', '" + updatedDate + "')";

                if (db.ExecuteQuery(insertQry))
                {
                    return "Y";
                }
                return "N";
            }
            else if (actionType == "update")
            {
                if (string.IsNullOrWhiteSpace(specId))
                {
                    return "VAL_ERR";
                }

                // Check duplicate on other record within same type
                string chkQry = "SELECT COUNT(*) FROM tbl_item_master_spe_values WHERE itsv_id != " + specId + " AND itst_id = " + typeId + " AND itsv_name = '" + safeSpecValue + "'";
                double count = Convert.ToDouble(db.SelectScalar(chkQry));
                if (count > 0)
                {
                    return "E"; // Exists
                }

                string updateQry = "UPDATE tbl_item_master_spe_values SET " +
                                   "itst_id = " + typeId + ", " +
                                   "itst_name = '" + typeName + "', " +
                                   "itsv_seq = " + seq + ", " +
                                   "itsv_name = '" + safeSpecValue + "', " +
                                   "itsv_lastupdate_date = '" + updatedDate + "' " +
                                   "WHERE itsv_id = " + specId;

                if (db.ExecuteQuery(updateQry))
                {
                    return "Y";
                }
                return "N";
            }

            return "INVALID_ACTION";
        }
        catch (Exception ex)
        {
            return "ERR: " + ex.Message;
        }
    }

    // Search and list specification values with pagination
    [WebMethod]
    public static string searchSpecList(int page, Dictionary<string, string> filters, int perpage)
    {
        try
        {
            string query_condition = " WHERE 1=1 ";
            if (filters != null && filters.Count > 0)
            {
                if (filters.ContainsKey("typeId") && !string.IsNullOrEmpty(filters["typeId"]) && filters["typeId"] != "-1")
                {
                    query_condition += " AND v.itst_id = '" + filters["typeId"].Replace("'", "''") + "'";
                }

                if (filters.ContainsKey("search") && !string.IsNullOrEmpty(filters["search"]))
                {
                    string searchVal = filters["search"].Trim().Replace("'", "''");
                    query_condition += " AND (v.itsv_name LIKE '%" + searchVal + "%' OR v.itsv_seq LIKE '%" + searchVal + "%' OR v.itst_name LIKE '%" + searchVal + "%')";
                }
            }

            mySqlConnection db = new mySqlConnection();
            string countQry = "SELECT COUNT(*) FROM tbl_item_master_spe_values v " + query_condition;
            double numrows = Convert.ToDouble(db.SelectScalar(countQry));

            if (numrows == 0)
            {
                return "N";
            }

            int per_page = perpage > 0 ? perpage : 25;
            int offset = (page - 1) * per_page;

            string innerQry = "SELECT v.itsv_id, v.itst_id, v.itst_name, v.itsv_seq, v.itsv_name, " +
                              "DATE_FORMAT(v.itsv_lastupdate_date, '%d-%b-%Y %h:%i %p') AS last_update " +
                              "FROM tbl_item_master_spe_values v " +
                              query_condition +
                              " ORDER BY v.itst_name ASC, v.itsv_seq ASC, v.itsv_id ASC " +
                              " LIMIT " + offset + ", " + per_page;

            DataTable dt = db.SelectQuery(innerQry);
            if (dt != null && dt.Rows.Count > 0)
            {
                string jsonData = JsonConvert.SerializeObject(dt, Formatting.Indented);
                return "{\"count\":\"" + numrows + "\",\"data\":" + jsonData + "}";
            }

            return "N";
        }
        catch (Exception ex)
        {
            return "ERR: " + ex.Message;
        }
    }

    // Edit specification value details
    [WebMethod]
    public static string editSpecDetails(string specId)
    {
        try
        {
            mySqlConnection db = new mySqlConnection();
            string qry = "SELECT itsv_id, itst_id, itst_name, itsv_seq, itsv_name FROM tbl_item_master_spe_values WHERE itsv_id = '" + specId.Replace("'", "''") + "'";
            DataTable dt = db.SelectQuery(qry);
            return JsonConvert.SerializeObject(dt, Formatting.Indented);
        }
        catch (Exception ex)
        {
            return "ERR: " + ex.Message;
        }
    }

    // Delete specification value
    [WebMethod]
    public static string deleteSpecValue(string specId)
    {
        try
        {
            mySqlConnection db = new mySqlConnection();
            string qry = "DELETE FROM tbl_item_master_spe_values WHERE itsv_id = '" + specId.Replace("'", "''") + "'";
            if (db.ExecuteQuery(qry))
            {
                return "Y";
            }
            return "N";
        }
        catch (Exception ex)
        {
            return "ERR: " + ex.Message;
        }
    }

    // Get all specification types with their counts
    [WebMethod]
    public static string getSpecTypesList()
    {
        try
        {
            mySqlConnection db = new mySqlConnection();
            string qry = "SELECT t.itst_id, t.itst_name, COUNT(v.itsv_id) AS value_count, " +
                         "DATE_FORMAT(t.itst_lastupdate_date, '%d-%b-%Y %h:%i %p') AS last_update " +
                         "FROM tbl_item_master_spe_type t " +
                         "LEFT JOIN tbl_item_master_spe_values v ON t.itst_id = v.itst_id " +
                         "GROUP BY t.itst_id, t.itst_name " +
                         "ORDER BY t.itst_name ASC";
            DataTable dt = db.SelectQuery(qry);
            return JsonConvert.SerializeObject(dt, Formatting.Indented);
        }
        catch (Exception ex)
        {
            return "ERR: " + ex.Message;
        }
    }

    // Save specification type (Insert / Update)
    [WebMethod]
    public static string saveSpecType(string actionType, string typeId, string typeName)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(typeName))
            {
                return "VAL_ERR";
            }

            mySqlConnection db = new mySqlConnection();
            string updatedDate = GetSystemDateTime(db);
            string safeTypeName = typeName.Trim().Replace("'", "''");

            if (actionType == "insert")
            {
                string chkQry = "SELECT COUNT(*) FROM tbl_item_master_spe_type WHERE itst_name = '" + safeTypeName + "'";
                double count = Convert.ToDouble(db.SelectScalar(chkQry));
                if (count > 0)
                {
                    return "E"; // Exists
                }

                string insertQry = "INSERT INTO tbl_item_master_spe_type (itst_name, itst_lastupdate_date) VALUES ('" + safeTypeName + "', '" + updatedDate + "')";
                if (db.ExecuteQuery(insertQry))
                {
                    return "Y";
                }
                return "N";
            }
            else if (actionType == "update")
            {
                if (string.IsNullOrWhiteSpace(typeId))
                {
                    return "VAL_ERR";
                }

                string chkQry = "SELECT COUNT(*) FROM tbl_item_master_spe_type WHERE itst_id != " + typeId + " AND itst_name = '" + safeTypeName + "'";
                double count = Convert.ToDouble(db.SelectScalar(chkQry));
                if (count > 0)
                {
                    return "E"; // Exists
                }

                string updateQry = "UPDATE tbl_item_master_spe_type SET itst_name = '" + safeTypeName + "', itst_lastupdate_date = '" + updatedDate + "' WHERE itst_id = " + typeId;
                if (db.ExecuteQuery(updateQry))
                {
                    // Also synchronize the denormalized itst_name in tbl_item_master_spe_values
                    db.ExecuteQuery("UPDATE tbl_item_master_spe_values SET itst_name = '" + safeTypeName + "' WHERE itst_id = " + typeId);
                    return "Y";
                }
                return "N";
            }

            return "INVALID_ACTION";
        }
        catch (Exception ex)
        {
            return "ERR: " + ex.Message;
        }
    }

    // Delete specification type (only if no associated values exist)
    [WebMethod]
    public static string deleteSpecType(string typeId)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(typeId))
            {
                return "VAL_ERR";
            }

            mySqlConnection db = new mySqlConnection();
            string chkQry = "SELECT COUNT(*) FROM tbl_item_master_spe_values WHERE itst_id = " + typeId;
            double count = Convert.ToDouble(db.SelectScalar(chkQry));
            if (count > 0)
            {
                return "HAS_VALUES";
            }

            string delQry = "DELETE FROM tbl_item_master_spe_type WHERE itst_id = " + typeId;
            if (db.ExecuteQuery(delQry))
            {
                return "Y";
            }
            return "N";
        }
        catch (Exception ex)
        {
            return "ERR: " + ex.Message;
        }
    }
}
