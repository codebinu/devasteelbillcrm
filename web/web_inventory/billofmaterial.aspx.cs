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

public partial class web_inventory_billofmaterial : System.Web.UI.Page
{
    public class BomComponentDto
    {
        public int itmbi_id { get; set; }
        public int itm_id_input { get; set; }
        public int itmbi_serialno { get; set; }
        public int itmbi_type { get; set; }
        public int tum_id { get; set; }
        public decimal itmbi_qty { get; set; }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication auth = new LoginAuthentication();
        auth.userAuthentication();
        auth.checkPageAcess(12);
    }

    // Load UOM options from tbl_item_uom
    [WebMethod]
    public static string loadUomOptions()
    {
        mySqlConnection db = new mySqlConnection();
        string qry = "SELECT tum_id, tum_name FROM tbl_item_uom ORDER BY tum_id ASC";
        DataTable dt = db.SelectQuery(qry);
        StringBuilder sb = new StringBuilder();
        sb.Append("<option value='-1'>--Select UOM--</option>");
        if (dt != null && dt.Rows.Count > 0)
        {
            foreach (DataRow r in dt.Rows)
            {
                sb.Append("<option value='" + r["tum_id"] + "'>" + HttpUtility.HtmlEncode(r["tum_name"].ToString()) + "</option>");
            }
        }
        return sb.ToString();
    }

    // Search items from tbl_item_master for Autocomplete
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
                COALESCE(im.itsv_uom_sales, 1) AS uom_id, 
                COALESCE(u.tum_name, '') AS uom_name,
                COALESCE(b.brand_name, '') AS brand_name,
                COALESCE(c.cat_name, '') AS cat_name
            FROM tbl_item_master im
            LEFT JOIN tbl_item_uom u ON u.tum_id = im.itsv_uom_sales
            LEFT JOIN tbl_item_brand b ON b.brand_id = im.itm_brand_id
            LEFT JOIN tbl_item_category c ON c.cat_id = im.itm_category_id
            WHERE (im.itm_code LIKE '%" + safeTerm + @"%' 
               OR im.itm_name LIKE '%" + safeTerm + @"%' 
               OR im.itsv_printing_name LIKE '%" + safeTerm + @"%')
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
                    string label = code + " - " + name + (!string.IsNullOrWhiteSpace(printName) && printName != name ? " (" + printName + ")" : "");
                    list.Add(new
                    {
                        id = Convert.ToInt32(r["itm_id"]),
                        code = code,
                        name = name,
                        printingName = printName,
                        uomId = Convert.ToInt32(r["uom_id"]),
                        uomName = r["uom_name"].ToString(),
                        brandName = r["brand_name"].ToString(),
                        catName = r["cat_name"].ToString(),
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

    // Search and list BOM records with pagination
    [WebMethod]
    public static string searchBomList(int page, Dictionary<string, string> filters, int perpage)
    {
        try
        {
            mySqlConnection db = new mySqlConnection();
            string query_condition = " WHERE 1=1";

            if (filters != null && filters.Count > 0)
            {
                // Filter by Output Item
                if (filters.ContainsKey("outputItem") && !string.IsNullOrWhiteSpace(filters["outputItem"]))
                {
                    string safeOut = filters["outputItem"].Trim().Replace("'", "''");
                    query_condition += " AND (out_m.itm_code LIKE '%" + safeOut + "%' OR out_m.itm_name LIKE '%" + safeOut + "%' OR out_m.itsv_printing_name LIKE '%" + safeOut + "%')";
                }

                // Filter by Component Item
                if (filters.ContainsKey("componentItem") && !string.IsNullOrWhiteSpace(filters["componentItem"]))
                {
                    string safeComp = filters["componentItem"].Trim().Replace("'", "''");
                    query_condition += " AND EXISTS (SELECT 1 FROM tbl_item_master_bom b2 JOIN tbl_item_master in2 ON in2.itm_id = b2.itm_id_input WHERE b2.itm_id_output = b.itm_id_output AND (in2.itm_code LIKE '%" + safeComp + "%' OR in2.itm_name LIKE '%" + safeComp + "%' OR in2.itsv_printing_name LIKE '%" + safeComp + "%'))";
                }

                // Filter by Component UOM
                if (filters.ContainsKey("uom") && !string.IsNullOrWhiteSpace(filters["uom"]) && filters["uom"] != "-1")
                {
                    string safeUom = filters["uom"].Trim().Replace("'", "''");
                    query_condition += " AND EXISTS (SELECT 1 FROM tbl_item_master_bom b3 WHERE b3.itm_id_output = b.itm_id_output AND b3.tum_id = '" + safeUom + "')";
                }
            }

            string countQry = "SELECT COUNT(DISTINCT b.itm_id_output) FROM tbl_item_master_bom b JOIN tbl_item_master out_m ON out_m.itm_id = b.itm_id_output " + query_condition;
            double numrows = Convert.ToInt32(db.SelectScalar(countQry));
            if (numrows == 0)
            {
                return "N";
            }

            double per_page = perpage > 0 ? perpage : 25;
            double offset = (page - 1) * per_page;

            string pageQry = @"SELECT 
                b.itm_id_output,
                out_m.itm_code AS output_code,
                out_m.itm_name AS output_name,
                COALESCE(out_m.itsv_printing_name, '') AS output_printing_name,
                COALESCE(MAX(b_out.brand_name), '') AS output_brand,
                COALESCE(MAX(c_out.cat_name), '') AS output_category,
                COUNT(b.itmbi_id) AS component_count,
                GROUP_CONCAT(CONCAT(in_m.itm_name, ' (', CAST(ROUND(b.itmbi_qty, 3) AS CHAR), ' ', COALESCE(u.tum_name, ''), ')') ORDER BY b.itmbi_serialno SEPARATOR ' || ') AS components_summary
            FROM tbl_item_master_bom b
            JOIN tbl_item_master out_m ON out_m.itm_id = b.itm_id_output
            LEFT JOIN tbl_item_brand b_out ON b_out.brand_id = out_m.itm_brand_id
            LEFT JOIN tbl_item_category c_out ON c_out.cat_id = out_m.itm_category_id
            LEFT JOIN tbl_item_master in_m ON in_m.itm_id = b.itm_id_input
            LEFT JOIN tbl_item_uom u ON u.tum_id = b.tum_id "
            + query_condition + @"
            GROUP BY b.itm_id_output, out_m.itm_code, out_m.itm_name, out_m.itsv_printing_name
            ORDER BY b.itm_id_output DESC
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

    // Get single BOM details including Output Item and all Components
    [WebMethod]
    public static string getBomDetails(int outputItemId)
    {
        try
        {
            mySqlConnection db = new mySqlConnection();
            string outQry = @"SELECT 
                out_m.itm_id,
                out_m.itm_code,
                out_m.itm_name,
                COALESCE(out_m.itsv_printing_name, '') AS itsv_printing_name,
                COALESCE(b_out.brand_name, '') AS brand_name,
                COALESCE(c_out.cat_name, '') AS cat_name,
                COALESCE(u_out.tum_name, '') AS uom_name
            FROM tbl_item_master out_m
            LEFT JOIN tbl_item_brand b_out ON b_out.brand_id = out_m.itm_brand_id
            LEFT JOIN tbl_item_category c_out ON c_out.cat_id = out_m.itm_category_id
            LEFT JOIN tbl_item_uom u_out ON u_out.tum_id = out_m.itsv_uom_sales
            WHERE out_m.itm_id = " + outputItemId;
            DataTable dtOut = db.SelectQuery(outQry);

            string compQry = @"SELECT 
                b.itmbi_id,
                b.itmbi_serialno,
                b.itmbi_type,
                b.itm_id_input,
                in_m.itm_code AS input_code,
                in_m.itm_name AS input_name,
                COALESCE(in_m.itsv_printing_name, '') AS input_printing_name,
                b.tum_id,
                COALESCE(u.tum_name, '') AS uom_name,
                b.itmbi_qty
            FROM tbl_item_master_bom b
            JOIN tbl_item_master in_m ON in_m.itm_id = b.itm_id_input
            LEFT JOIN tbl_item_uom u ON u.tum_id = b.tum_id
            WHERE b.itm_id_output = " + outputItemId + @"
            ORDER BY b.itmbi_serialno ASC";
            DataTable dtComp = db.SelectQuery(compQry);

            var result = new
            {
                output = (dtOut != null && dtOut.Rows.Count > 0) ? dtOut : null,
                components = dtComp
            };
            return JsonConvert.SerializeObject(result, Formatting.Indented);
        }
        catch (Exception ex)
        {
            return JsonConvert.SerializeObject(new { error = ex.Message });
        }
    }

    // Save or Update BOM
    [WebMethod]
    public static string saveBomDetails(string actionType, int outputItemId, string componentsJson)
    {
        try
        {
            if (outputItemId <= 0) return "Please select a valid Finished Good / Output Item.";

            List<BomComponentDto> components = JsonConvert.DeserializeObject<List<BomComponentDto>>(componentsJson);
            if (components == null || components.Count == 0) return "Please add at least one Component / Raw Material.";

            for (int i = 0; i < components.Count; i++)
            {
                if (components[i].itm_id_input <= 0) return "Row " + (i + 1) + ": Please select a valid Component item.";
                if (components[i].itmbi_qty <= 0) return "Row " + (i + 1) + ": Quantity must be greater than zero.";
                if (components[i].tum_id <= 0) components[i].tum_id = 1;
                if (components[i].itmbi_type <= 0) components[i].itmbi_type = 1;
            }

            mySqlConnection db = new mySqlConnection();

            if (actionType == "insert")
            {
                string checkExisting = "SELECT COUNT(*) FROM tbl_item_master_bom WHERE itm_id_output = " + outputItemId;
                int existingCount = Convert.ToInt32(db.SelectScalar(checkExisting));
                if (existingCount > 0)
                {
                    return "E_EXISTS";
                }
            }

            // Remove existing components for this output item
            string deleteQry = "DELETE FROM tbl_item_master_bom WHERE itm_id_output = " + outputItemId;
            db.ExecuteQuery(deleteQry);

            // Insert updated/new components
            int serialNo = 1;
            foreach (var comp in components)
            {
                string insertQry = string.Format(
                    System.Globalization.CultureInfo.InvariantCulture,
                    "INSERT INTO tbl_item_master_bom (itm_id_output, itm_id_input, itmbi_serialno, itmbi_type, tum_id, itmbi_qty) VALUES ({0}, {1}, {2}, {3}, {4}, {5})",
                    outputItemId,
                    comp.itm_id_input,
                    serialNo,
                    comp.itmbi_type,
                    comp.tum_id,
                    comp.itmbi_qty
                );
                db.ExecuteQuery(insertQry);
                serialNo++;
            }

            // Enable BOM flag in tbl_item_master
            string updateMasterQry = "UPDATE tbl_item_master SET itsv_bom_enabled = 1 WHERE itm_id = " + outputItemId;
            db.ExecuteQuery(updateMasterQry);

            return "Y";
        }
        catch (Exception ex)
        {
            return "Error: " + ex.Message;
        }
    }

    // Delete BOM
    [WebMethod]
    public static string deleteBom(int outputItemId)
    {
        try
        {
            if (outputItemId <= 0) return "Invalid item.";
            mySqlConnection db = new mySqlConnection();
            string delQry = "DELETE FROM tbl_item_master_bom WHERE itm_id_output = " + outputItemId;
            if (db.ExecuteQuery(delQry))
            {
                string updateMaster = "UPDATE tbl_item_master SET itsv_bom_enabled = 0 WHERE itm_id = " + outputItemId;
                db.ExecuteQuery(updateMaster);
                return "Y";
            }
            return "N";
        }
        catch (Exception ex)
        {
            return "Error: " + ex.Message;
        }
    }

    // Prepare BOM Export Query for Excel Download
    [WebMethod(EnableSession = true)]
    public static string prepareBomExport(Dictionary<string, string> filters)
    {
        try
        {
            string query_condition = " WHERE 1=1";
            if (filters != null && filters.Count > 0)
            {
                if (filters.ContainsKey("outputItem") && !string.IsNullOrWhiteSpace(filters["outputItem"]))
                {
                    string safeOut = filters["outputItem"].Trim().Replace("'", "''");
                    query_condition += " AND (out_m.itm_code LIKE '%" + safeOut + "%' OR out_m.itm_name LIKE '%" + safeOut + "%' OR out_m.itsv_printing_name LIKE '%" + safeOut + "%')";
                }
                if (filters.ContainsKey("componentItem") && !string.IsNullOrWhiteSpace(filters["componentItem"]))
                {
                    string safeComp = filters["componentItem"].Trim().Replace("'", "''");
                    query_condition += " AND EXISTS (SELECT 1 FROM tbl_item_master_bom b2 JOIN tbl_item_master in2 ON in2.itm_id = b2.itm_id_input WHERE b2.itm_id_output = b.itm_id_output AND (in2.itm_code LIKE '%" + safeComp + "%' OR in2.itm_name LIKE '%" + safeComp + "%' OR in2.itsv_printing_name LIKE '%" + safeComp + "%'))";
                }
                if (filters.ContainsKey("uom") && !string.IsNullOrWhiteSpace(filters["uom"]) && filters["uom"] != "-1")
                {
                    string safeUom = filters["uom"].Trim().Replace("'", "''");
                    query_condition += " AND EXISTS (SELECT 1 FROM tbl_item_master_bom b3 WHERE b3.itm_id_output = b.itm_id_output AND b3.tum_id = '" + safeUom + "')";
                }
            }

            mySqlConnection db = new mySqlConnection();
            string countQry = "SELECT COUNT(DISTINCT b.itm_id_output) FROM tbl_item_master_bom b JOIN tbl_item_master out_m ON out_m.itm_id = b.itm_id_output " + query_condition;
            double numrows = Convert.ToInt32(db.SelectScalar(countQry));
            if (numrows == 0) return "N";

            string exportQry = @"SELECT 
                b.itmbi_id AS 'BOM Record ID',
                b.itm_id_output AS 'Output Item ID',
                out_m.itm_code AS 'Output Item Code',
                out_m.itm_name AS 'Output Item Name',
                COALESCE(out_m.itsv_printing_name, '') AS 'Output Printing Name',
                COALESCE(b_out.brand_name, '') AS 'Output Brand',
                COALESCE(c_out.cat_name, '') AS 'Output Category',
                b.itmbi_serialno AS 'Component S.No',
                b.itm_id_input AS 'Component Item ID',
                in_m.itm_code AS 'Component Item Code',
                in_m.itm_name AS 'Component Item Name',
                COALESCE(in_m.itsv_printing_name, '') AS 'Component Printing Name',
                ROUND(b.itmbi_qty, 4) AS 'Component Quantity',
                COALESCE(u.tum_name, '') AS 'Component UOM'
            FROM tbl_item_master_bom b
            JOIN tbl_item_master out_m ON out_m.itm_id = b.itm_id_output
            LEFT JOIN tbl_item_brand b_out ON b_out.brand_id = out_m.itm_brand_id
            LEFT JOIN tbl_item_category c_out ON c_out.cat_id = out_m.itm_category_id
            JOIN tbl_item_master in_m ON in_m.itm_id = b.itm_id_input
            LEFT JOIN tbl_item_uom u ON u.tum_id = b.tum_id "
            + query_condition + @"
            ORDER BY b.itm_id_output DESC, b.itmbi_serialno ASC";

            HttpContext.Current.Session["bom_downloadqry"] = exportQry;
            return "Y";
        }
        catch (Exception ex)
        {
            return ex.Message;
        }
    }
}
