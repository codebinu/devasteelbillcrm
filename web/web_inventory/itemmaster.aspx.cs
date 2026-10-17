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

public partial class web_inventory_itemmaster : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication itemMaster = new LoginAuthentication();
        itemMaster.userAuthentication();
        itemMaster.checkPageAcess(12);
    }
    /*
    ////loading brand
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
                    //sb.Append("<select id='comboBrandtype' style='width:200px;margin-top:6px;' class='normaltextbg'>");
                    sb.Append("<option value='-1' selected='selected'>--Brand--</option>");
                    //sb.Append("</select>");
                }
                else
                {
                    //sb.Append("<select id='comboBrandtype' style='width:255px; height:24px;' class='normaltextbg'>");
                    sb.Append("<option value='-1' selected='selected'>--Brand--</option>");
                    for (int i = 0; i < dt.Rows.Count; i++)
                    {

                        sb.Append("<option value='" + dt.Rows[i]["brand_id"] + "'>" + dt.Rows[i]["brand_name"] + "</option>");

                    }
                    //sb.Append("</select>");
                }
            }
            else
            {
                sb.Append("<option value='-1' selected='selected'>--Brand--</option>");
                //sb.Append("<select id='comboBrandtype'>");
               // sb.Append("</select>");
            }
        }

        return sb.ToString();
    }
    */

    ////loading supplier list
    [WebMethod]
    public static string showsupplierlist()
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        StringBuilder sb = new StringBuilder();
        string query = "SELECT vendor_id, name FROM tbl_vendor ORDER BY vendor_id ASC";
        dt = db.SelectQuery(query);
        if (dt != null)
        {
            if (dt.Rows.Count > 0)
            {
                if (dt.Rows[0]["vendor_id"] is DBNull)
                {
                    sb.Append("<select id='combovendorlist' style='width:255px; height:24px; margin-left:10px;' class='normaltextbg'>");
                    sb.Append("<option value='0' selected='selected'>Select</option>");
                    sb.Append("</select>");
                }
                else
                {
                    sb.Append("<select id='combovendorlist' style='width:255px; height:24px;margin-left:10px;' class='normaltextbg'>");
                    sb.Append("<option value='0' selected='selected'>Select</option>");
                    for (int i = 0; i < dt.Rows.Count; i++)
                    {

                        sb.Append("<option value='" + dt.Rows[i]["vendor_id"] + "'>" + dt.Rows[i]["name"] + "</option>");

                    }
                    sb.Append("</select>");
                }
            }
            else
            {
                sb.Append("<select id='combovendorlist' style='width:200px;margin-top:6px;margin-left:10px;' class='normaltextbg'>");
                sb.Append("</select>");
            }
        }


        return sb.ToString();
    }

    ////loading categorytypes
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
                    //sb.Append("<select id='combocategory' style='width:255px; height:24px;' class='normaltextbg' onchange='javascript:loadsubcategory(0);'>");
                    sb.Append("<option value='-1' selected='selected'>--Category--</option>");
                   // sb.Append("</select>");
                }
                else
                {
                    //sb.Append("<select id='combocategory' style='width:255px; height:24px;' class='normaltextbg' onchange='javascript:loadsubcategory(0);'>");
                    sb.Append("<option value='-1' selected='selected'>--Category--</option>");
                    for (int i = 0; i < dt.Rows.Count; i++)
                    {

                        sb.Append("<option value='" + dt.Rows[i]["cat_id"] + "'>" + dt.Rows[i]["cat_name"] + "</option>");

                    }
                   // sb.Append("</select>");
                }
            }
            else
            {
               // sb.Append("<select id='combocategory' style='width:200px;margin-top:6px;' class='normaltextbg' onchange='javascript:loadsubcategory(0);'>");
                sb.Append("<option value='-1' selected='selected'>--Category--</option>");
               // sb.Append("</select>");
            }
        }

        return sb.ToString();
    }

    // Helper methods for SQL value formatting
    private static string SqlInt(string val)
    {
        if (string.IsNullOrWhiteSpace(val) || val == "-1" || val == "0") return "NULL";
        int num;
        if (int.TryParse(val.Trim(), out num))
        {
            if (num <= 0) return "NULL";
            return num.ToString();
        }
        return "NULL";
    }

    private static string SqlIntZeroDefault(string val, int defaultVal)
    {
        if (string.IsNullOrWhiteSpace(val)) return defaultVal.ToString();
        int num;
        if (int.TryParse(val.Trim(), out num))
        {
            return num.ToString();
        }
        return defaultVal.ToString();
    }

    private static string SqlHsn(string val)
    {
        if (string.IsNullOrWhiteSpace(val)) return "NULL";
        long num;
        if (long.TryParse(val.Trim(), out num))
        {
            return num.ToString();
        }
        return "NULL";
    }

    private static string SqlString(string val)
    {
        if (string.IsNullOrWhiteSpace(val)) return "NULL";
        return "'" + val.Trim().Replace("'", "''") + "'";
    }

    private static string GetSpecVal(Dictionary<string, string> dict, string key)
    {
        if (dict != null && dict.ContainsKey(key) && !string.IsNullOrWhiteSpace(dict[key]))
        {
            return dict[key].Trim();
        }
        return "";
    }

    // Loading all specification values grouped for dropdowns
    [WebMethod]
    public static string loadAllSpecDropdowns()
    {
        try
        {
            mySqlConnection db = new mySqlConnection();
            string query = "SELECT itsv_id, itst_id, itst_name, itsv_seq, itsv_name " +
                           "FROM tbl_item_master_spe_values " +
                           "ORDER BY itst_id ASC, itsv_seq ASC, itsv_name ASC";
            DataTable dt = db.SelectQuery(query);
            Dictionary<string, StringBuilder> dict = new Dictionary<string, StringBuilder>();

            dict["stockGroups"] = new StringBuilder("<option value='-1'>--Select Stock Group--</option>");
            dict["stockCategories"] = new StringBuilder("<option value='-1'>--Select Stock Category--</option>");
            dict["specItem"] = new StringBuilder("<option value='-1'>--Select Spec Item--</option>");
            dict["specBrand"] = new StringBuilder("<option value='-1'>--Select Spec Brand--</option>");
            dict["specThickness"] = new StringBuilder("<option value='-1'>--Select Thickness--</option>");
            dict["specColour"] = new StringBuilder("<option value='-1'>--Select Colour--</option>");
            dict["specCoating"] = new StringBuilder("<option value='-1'>--Select Coating--</option>");
            dict["specPitch"] = new StringBuilder("<option value='-1'>--Select Pitch--</option>");
            dict["specCrust"] = new StringBuilder("<option value='-1'>--Select Crust--</option>");
            dict["specWidth"] = new StringBuilder("<option value='-1'>--Select Width--</option>");
            dict["specYieldStrength"] = new StringBuilder("<option value='-1'>--Select Yield Strength--</option>");
            dict["specMachine"] = new StringBuilder("<option value='-1'>--Select Machine--</option>");

            // 4 UOM dropdowns loaded from tbl_item_uom (tum_id, tum_name)
            StringBuilder uomPurchaseSb = new StringBuilder("<option value='-1'>--Select Purchase UOM--</option>");
            StringBuilder uomSalesSb = new StringBuilder("<option value='-1'>--Select Sales UOM--</option>");
            StringBuilder altUnitsSb = new StringBuilder("<option value='-1'>--Select Alternate Unit--</option>");
            StringBuilder repUomSb = new StringBuilder("<option value='-1'>--Select Reporting UOM--</option>");

            string uomQuery = "SELECT tum_id, tum_name FROM tbl_item_uom ORDER BY tum_id ASC";
            DataTable dtUom = db.SelectQuery(uomQuery);
            if (dtUom != null && dtUom.Rows.Count > 0)
            {
                foreach (DataRow uRow in dtUom.Rows)
                {
                    string tumId = uRow["tum_id"].ToString();
                    string tumName = HttpUtility.HtmlEncode(uRow["tum_name"].ToString());
                    string opt = "<option value='" + tumId + "'>" + tumName + "</option>";
                    uomPurchaseSb.Append(opt);
                    uomSalesSb.Append(opt);
                    altUnitsSb.Append(opt);
                    repUomSb.Append(opt);
                }
            }
            dict["uomPurchase"] = uomPurchaseSb;
            dict["uomSales"] = uomSalesSb;
            dict["alternateUnits"] = altUnitsSb;
            dict["reportingUoms"] = repUomSb;
            dict["units"] = uomPurchaseSb;

            if (dt != null && dt.Rows.Count > 0)
            {
                foreach (DataRow row in dt.Rows)
                {
                    int typeId = Convert.ToInt32(row["itst_id"]);
                    string valId = row["itsv_id"].ToString();
                    string valName = HttpUtility.HtmlEncode(row["itsv_name"].ToString());
                    string opt = "<option value='" + valId + "'>" + valName + "</option>";

                    switch (typeId)
                    {
                        case 3: // brand
                            dict["specBrand"].Append(opt);
                            break;
                        case 4: // coating
                            dict["specCoating"].Append(opt);
                            break;
                        case 5: // colour
                            dict["specColour"].Append(opt);
                            break;
                        case 7: // crust
                            dict["specCrust"].Append(opt);
                            break;
                        case 9: // item
                            dict["specItem"].Append(opt);
                            break;
                        case 10: // machine
                            dict["specMachine"].Append(opt);
                            break;
                        case 11: // pitch
                            dict["specPitch"].Append(opt);
                            break;
                        case 13: // stockCategories
                            dict["stockCategories"].Append(opt);
                            break;
                        case 14: // stockGroups
                            dict["stockGroups"].Append(opt);
                            break;
                        case 15: // thickness
                            dict["specThickness"].Append(opt);
                            break;
                        case 19: // width
                            dict["specWidth"].Append(opt);
                            break;
                        case 20: // yieldStrength
                            dict["specYieldStrength"].Append(opt);
                            break;
                    }
                }
            }

            Dictionary<string, string> result = new Dictionary<string, string>();
            foreach (var kvp in dict)
            {
                result[kvp.Key] = kvp.Value.ToString();
            }
            return JsonConvert.SerializeObject(result);
        }
        catch (Exception ex)
        {
            return JsonConvert.SerializeObject(new { error = ex.Message });
        }
    }

    //save and update itemdetails
    [WebMethod]
    public static string Additemmasters(string actionType, string itemid, string itemcode, string itemname, string itemdesc, string itmbrand, string itmcatgry, string itmsubcategory, string supplier, int itemType, int couponItemId, int quantity, int itm_qty_per_carton, Dictionary<string, string> specData)
    {
        String resultStatus = "N";
        bool queryStatus;
        string query = "";

        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        Int32 itemId1 = 0;

        string selectTimezonQuery = "select ss_default_time_zone from tbl_system_settings";
        DataTable timezoneDt = db.SelectQuery(selectTimezonQuery);
        TimeZoneInfo CurrentZone = TimeZoneInfo.FindSystemTimeZoneById(timezoneDt.Rows[0]["ss_default_time_zone"].ToString());
        DateTime TimeNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, CurrentZone);
        string updatedDate = DateTime.Parse(TimeNow.ToString()).ToString("yyyy-MM-dd HH:mm:ss");

        string brandVal = (string.IsNullOrWhiteSpace(itmbrand) || itmbrand == "-1") ? "0" : itmbrand;
        string catVal = (string.IsNullOrWhiteSpace(itmcatgry) || itmcatgry == "-1") ? "0" : itmcatgry;
        string subCatVal = (string.IsNullOrWhiteSpace(itmsubcategory) || itmsubcategory == "-1") ? "0" : itmsubcategory;
        string supplierVal = (string.IsNullOrWhiteSpace(supplier)) ? "0" : supplier;

        // Process all 23 additional specification & Tally columns
        string partNoSql = SqlInt(GetSpecVal(specData, "itsv_part_no"));
        string stockGroupSql = SqlInt(GetSpecVal(specData, "itsv_stock_group"));
        string stockCatSql = SqlInt(GetSpecVal(specData, "itsv_category"));
        string itsvDescSql = SqlInt(GetSpecVal(specData, "itsv_description"));
        string uomPurchaseSql = SqlInt(GetSpecVal(specData, "itsv_uom_purchase"));
        string uomSalesSql = SqlInt(GetSpecVal(specData, "itsv_uom_sales"));
        string altUnitsSql = SqlInt(GetSpecVal(specData, "itsv_alternate_units"));
        string repUomSql = SqlInt(GetSpecVal(specData, "itsv_reporting_uom"));
        string convValSql = SqlIntZeroDefault(GetSpecVal(specData, "itsv_conversion_value"), 0);
        string denomSql = SqlIntZeroDefault(GetSpecVal(specData, "itsv_denominator"), 1);
        string bomSql = (GetSpecVal(specData, "itsv_bom_enabled") == "1") ? "1" : "0";
        string hsnSql = SqlHsn(GetSpecVal(specData, "itsv_hsn_sac"));
        string printingNameSql = SqlString(GetSpecVal(specData, "itsv_printing_name"));
        string specItemSql = SqlInt(GetSpecVal(specData, "itsv_spec_item"));
        string specPitchSql = SqlInt(GetSpecVal(specData, "itsv_spec_pitch"));
        string specCrustSql = SqlInt(GetSpecVal(specData, "itsv_spec_crust"));
        string specBrandSql = SqlInt(GetSpecVal(specData, "itsv_spec_brand"));
        string specThickSql = SqlInt(GetSpecVal(specData, "itsv_spec_thickness"));
        string specColourSql = SqlInt(GetSpecVal(specData, "itsv_spec_colour"));
        string specCoatingSql = SqlInt(GetSpecVal(specData, "itsv_spec_coating"));
        string specYieldSql = SqlInt(GetSpecVal(specData, "itsv_spec_yield_strength"));
        string specWidthSql = SqlInt(GetSpecVal(specData, "itsv_spec_width"));
        string specMachineSql = SqlInt(GetSpecVal(specData, "itsv_spec_machine"));

        string safeCode = itemcode.Trim().Replace("'", "''");
        string safeName = itemname.Trim().Replace("'", "''");
        string safeDesc = (itemdesc ?? "").Replace("'", "''");

        if (actionType == "insert")
        {
            string qry = "select MAX(itm_id) as itm_id from tbl_item_master";
            dt = db.SelectQuery(qry);

            if (dt != null && dt.Rows.Count > 0 && !(dt.Rows[0][0] is DBNull))
            {
                itemId1 = Convert.ToInt32(dt.Rows[0][0]) + 1;
            }
            else
            {
                itemId1 = 1;
            }

            String chk_qry = "SELECT count(*) FROM tbl_item_master WHERE (itm_code = '" + safeCode + "' OR itm_name = '" + safeName + "')";
            double numrows = Convert.ToInt32(db.SelectScalar(chk_qry));
            if (numrows > 0)
            {
                return "E";
            }
            else
            {
                query = "INSERT INTO tbl_item_master (itm_id, itm_code, itm_name, itm_description,  itm_supplierid, itm_type, itm_qty_per_carton, " +
                        "itsv_part_no, itsv_stock_group, itsv_category, itsv_description, itsv_uom_purchase, itsv_uom_sales, itsv_alternate_units, itsv_reporting_uom, itsv_conversion_value, itsv_denominator, itsv_bom_enabled, itsv_hsn_sac, itsv_printing_name, " +
                        "itsv_spec_item, itsv_spec_pitch, itsv_spec_crust, itsv_spec_brand, itsv_spec_thickness, itsv_spec_colour, itsv_spec_coating, itsv_spec_yield_strength, itsv_spec_width, itsv_spec_machine) " +
                        "VALUES (null, '" + safeCode + "', '" + safeName + "', '" + safeDesc + "', " + supplierVal + ", " + itemType + ", " + itm_qty_per_carton + ", " +
                        partNoSql + ", " + stockGroupSql + ", " + stockCatSql + ", " + itsvDescSql + ", " + uomPurchaseSql + ", " + uomSalesSql + ", " + altUnitsSql + ", " + repUomSql + ", " + convValSql + ", " + denomSql + ", " + bomSql + ", " + hsnSql + ", " + printingNameSql + ", " +
                        specItemSql + ", " + specPitchSql + ", " + specCrustSql + ", " + specBrandSql + ", " + specThickSql + ", " + specColourSql + ", " + specCoatingSql + ", " + specYieldSql + ", " + specWidthSql + ", " + specMachineSql + ")";
                
                if (db.ExecuteQuery(query))
                {
                    if (itemType == 1 && couponItemId > 0)
                    {
                        if ((db.ExecuteQuery("INSERT INTO tbl_coupon_master(cpn_id,cpn_itm_id,cpn_qty,itm_id) VALUES(NULL," + itemId1 + "," + quantity + "," + couponItemId + ")") == true))
                        {
                            resultStatus = "Y";
                        }
                        else
                        {
                            return "E";
                        }
                    }
                    resultStatus = "Y";
                }
            }
        }

        if (actionType == "update")
        {
            string safeItemId = itemid.Replace("'", "''");
            String chk_qry = "SELECT count(*) FROM tbl_item_master WHERE itm_id = '" + safeItemId + "'";
            double numrows = Convert.ToInt32(db.SelectScalar(chk_qry));
            if (numrows <= 0)
            {
                return "E";
            }
            else
            {
                String updatechk_qry = "SELECT count(*) FROM tbl_item_master WHERE (itm_id!='" + safeItemId + "' and (itm_code = '" + safeCode + "' OR itm_name = '" + safeName + "' ))";
                double checknumrows = Convert.ToInt32(db.SelectScalar(updatechk_qry));
                if (checknumrows > 0)
                {
                    return "E";
                }
                query = "UPDATE tbl_item_master SET " +
                        "itm_code='" + safeCode + "', itm_name='" + safeName + "', itm_description='" + safeDesc + "', " +
                        "itm_supplierid=" + supplierVal + ", " +
                        "itm_type=" + itemType + ", itm_qty_per_carton=" + itm_qty_per_carton + ", " +
                        "itsv_part_no=" + partNoSql + ", " +
                        "itsv_stock_group=" + stockGroupSql + ", " +
                        "itsv_category=" + stockCatSql + ", " +
                        "itsv_description=" + itsvDescSql + ", " +
                        "itsv_uom_purchase=" + uomPurchaseSql + ", " +
                        "itsv_uom_sales=" + uomSalesSql + ", " +
                        "itsv_alternate_units=" + altUnitsSql + ", " +
                        "itsv_reporting_uom=" + repUomSql + ", " +
                        "itsv_conversion_value=" + convValSql + ", " +
                        "itsv_denominator=" + denomSql + ", " +
                        "itsv_bom_enabled=" + bomSql + ", " +
                        "itsv_hsn_sac=" + hsnSql + ", " +
                        "itsv_printing_name=" + printingNameSql + ", " +
                        "itsv_spec_item=" + specItemSql + ", " +
                        "itsv_spec_pitch=" + specPitchSql + ", " +
                        "itsv_spec_crust=" + specCrustSql + ", " +
                        "itsv_spec_brand=" + specBrandSql + ", " +
                        "itsv_spec_thickness=" + specThickSql + ", " +
                        "itsv_spec_colour=" + specColourSql + ", " +
                        "itsv_spec_coating=" + specCoatingSql + ", " +
                        "itsv_spec_yield_strength=" + specYieldSql + ", " +
                        "itsv_spec_width=" + specWidthSql + ", " +
                        "itsv_spec_machine=" + specMachineSql + " " +
                        "WHERE itm_id='" + safeItemId + "'";
                queryStatus = db.ExecuteQuery(query);
                if (queryStatus)
                {
                    db.ExecuteQuery("update tbl_itembranch_stock set itm_last_update_date='" + updatedDate + "' where itm_id=" + safeItemId);
                    db.ExecuteQuery("UPDATE tbl_itembranch_stock SET itm_code='" + safeCode + "',itm_name='" + safeName + "',itm_brand_id=1,itm_category_id=1 WHERE itm_id=" + safeItemId);
                    if (itemType == 1 && couponItemId > 0)
                    {
                        if ((db.ExecuteQuery("UPDATE tbl_coupon_master SET itm_id='" + couponItemId + "',cpn_qty='" + quantity + "' WHERE cpn_itm_id='" + safeItemId + "'") == true))
                        {
                            resultStatus = "Y";
                        }
                        else
                        {
                            return "E";
                        }
                    }
                    resultStatus = "Y";
                }
            }
        }

        return resultStatus;
    }

    //search function and itemlisting
    [WebMethod]
    public static string searchItemList(int page, Dictionary<string, string> filters, int perpage)
    {
        try
        {
            string query_condition = " where 1=1";
            if (filters != null && filters.Count > 0)
            {
                // 1. Item Name / Printing Name / Item Code
                if (filters.ContainsKey("itemName") && !string.IsNullOrWhiteSpace(filters["itemName"]))
                {
                    string safeName = filters["itemName"].Trim().Replace("'", "''");
                    query_condition += " and (im.itm_name LIKE '%" + safeName + "%' or im.itsv_printing_name LIKE '%" + safeName + "%' or im.itm_code LIKE '%" + safeName + "%')";
                }
                else if (filters.ContainsKey("search") && !string.IsNullOrWhiteSpace(filters["search"]))
                {
                    string safeSearch = filters["search"].Trim().Replace("'", "''");
                    query_condition += " and (im.itm_name LIKE '%" + safeSearch + "%' or im.itsv_printing_name LIKE '%" + safeSearch + "%' or im.itm_code LIKE '%" + safeSearch + "%' or CAST(im.itsv_part_no AS CHAR) LIKE '%" + safeSearch + "%' or CAST(im.itsv_hsn_sac AS CHAR) LIKE '%" + safeSearch + "%')";
                }

                // 2. Part No
                if (filters.ContainsKey("partNo") && !string.IsNullOrWhiteSpace(filters["partNo"]))
                {
                    string safePart = filters["partNo"].Trim().Replace("'", "''");
                    query_condition += " and CAST(im.itsv_part_no AS CHAR) LIKE '%" + safePart + "%'";
                }

                // 3. Item Technical Specifications (Spec Item)
                if (filters.ContainsKey("specItem") && filters["specItem"] != "-1" && !string.IsNullOrWhiteSpace(filters["specItem"]))
                {
                    query_condition += " and (im.itsv_spec_item='" + filters["specItem"].Trim().Replace("'", "''") + "')";
                }

                // Additional Technical Specifications (Optional filters)
                if (filters.ContainsKey("specBrand") && filters["specBrand"] != "-1" && !string.IsNullOrWhiteSpace(filters["specBrand"]))
                {
                    query_condition += " and (im.itsv_spec_brand='" + filters["specBrand"].Trim().Replace("'", "''") + "')";
                }
                if (filters.ContainsKey("specThickness") && filters["specThickness"] != "-1" && !string.IsNullOrWhiteSpace(filters["specThickness"]))
                {
                    query_condition += " and (im.itsv_spec_thickness='" + filters["specThickness"].Trim().Replace("'", "''") + "')";
                }
                if (filters.ContainsKey("specColour") && filters["specColour"] != "-1" && !string.IsNullOrWhiteSpace(filters["specColour"]))
                {
                    query_condition += " and (im.itsv_spec_colour='" + filters["specColour"].Trim().Replace("'", "''") + "')";
                }
                if (filters.ContainsKey("specMachine") && filters["specMachine"] != "-1" && !string.IsNullOrWhiteSpace(filters["specMachine"]))
                {
                    query_condition += " and (im.itsv_spec_machine='" + filters["specMachine"].Trim().Replace("'", "''") + "')";
                }

                // UOM Filter
                if (filters.ContainsKey("uom") && filters["uom"] != "-1" && !string.IsNullOrWhiteSpace(filters["uom"]))
                {
                    string safeUom = filters["uom"].Trim().Replace("'", "''");
                    query_condition += " and (im.itsv_uom_sales='" + safeUom + "' or im.itsv_uom_purchase='" + safeUom + "' or im.itsv_reporting_uom='" + safeUom + "')";
                }
            }
            mySqlConnection db = new mySqlConnection();
            double per_page = perpage > 0 ? perpage : 25;
            double offset = (page - 1) * per_page;
            string countQry = "SELECT COUNT(*) FROM tbl_item_master im " + query_condition;
            double numrows = Convert.ToInt32(db.SelectScalar(countQry));
            if (numrows == 0)
            {
                return "N";
            }
            string innerqry = "SELECT im.itm_id, im.itm_code, im.itm_name,  im.itm_qty_per_carton, " +
                              "im.itsv_part_no, im.itsv_printing_name, im.itsv_hsn_sac, " +
                              "COALESCE(sg.itsv_name, '') AS stock_group_name, " +
                              "COALESCE(spi.itsv_name, '') AS spec_item_name, " +
                              "COALESCE(u_pur.tum_name, '') AS uom_purchase_name, " +
                              "COALESCE(u_sal.tum_name, '') AS uom_sales_name, " +
                              "COALESCE(u_alt.tum_name, '') AS uom_alt_name, " +
                              "COALESCE(u_rep.tum_name, '') AS uom_rep_name " +
                              "FROM tbl_item_master im " +
                              "LEFT JOIN tbl_item_master_spe_values sg on sg.itsv_id=im.itsv_stock_group " +
                              "LEFT JOIN tbl_item_master_spe_values spi on spi.itsv_id=im.itsv_spec_item " +
                              "LEFT JOIN tbl_item_uom u_pur on u_pur.tum_id=im.itsv_uom_purchase " +
                              "LEFT JOIN tbl_item_uom u_sal on u_sal.tum_id=im.itsv_uom_sales " +
                              "LEFT JOIN tbl_item_uom u_alt on u_alt.tum_id=im.itsv_alternate_units " +
                              "LEFT JOIN tbl_item_uom u_rep on u_rep.tum_id=im.itsv_reporting_uom " +
                              query_condition + " " +
                              "ORDER BY im.itm_id DESC LIMIT " + offset.ToString() + ", " + per_page;
            DataTable dt = db.SelectQuery(innerqry);
            string jsonResponse = "";
            if (dt != null && dt.Rows.Count > 0)
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

    // Export all items details (all columns) to Excel with active search filters
    [WebMethod(EnableSession = true)]
    public static string prepareItemMasterExport(Dictionary<string, string> filters)
    {
        try
        {
            string query_condition = " where 1=1";
            if (filters != null && filters.Count > 0)
            {
                // 1. Item Name / Printing Name / Item Code
                if (filters.ContainsKey("itemName") && !string.IsNullOrWhiteSpace(filters["itemName"]))
                {
                    string safeName = filters["itemName"].Trim().Replace("'", "''");
                    query_condition += " and (im.itm_name LIKE '%" + safeName + "%' or im.itsv_printing_name LIKE '%" + safeName + "%' or im.itm_code LIKE '%" + safeName + "%')";
                }
                else if (filters.ContainsKey("search") && !string.IsNullOrWhiteSpace(filters["search"]))
                {
                    string safeSearch = filters["search"].Trim().Replace("'", "''");
                    query_condition += " and (im.itm_name LIKE '%" + safeSearch + "%' or im.itsv_printing_name LIKE '%" + safeSearch + "%' or im.itm_code LIKE '%" + safeSearch + "%' or CAST(im.itsv_part_no AS CHAR) LIKE '%" + safeSearch + "%' or CAST(im.itsv_hsn_sac AS CHAR) LIKE '%" + safeSearch + "%')";
                }

                // 2. Part No
                if (filters.ContainsKey("partNo") && !string.IsNullOrWhiteSpace(filters["partNo"]))
                {
                    string safePart = filters["partNo"].Trim().Replace("'", "''");
                    query_condition += " and CAST(im.itsv_part_no AS CHAR) LIKE '%" + safePart + "%'";
                }

                // 3. Item Technical Specifications (Spec Item)
                if (filters.ContainsKey("specItem") && filters["specItem"] != "-1" && !string.IsNullOrWhiteSpace(filters["specItem"]))
                {
                    query_condition += " and (im.itsv_spec_item='" + filters["specItem"].Trim().Replace("'", "''") + "')";
                }

                // Additional Technical Specifications (Optional filters)
                if (filters.ContainsKey("specBrand") && filters["specBrand"] != "-1" && !string.IsNullOrWhiteSpace(filters["specBrand"]))
                {
                    query_condition += " and (im.itsv_spec_brand='" + filters["specBrand"].Trim().Replace("'", "''") + "')";
                }
                if (filters.ContainsKey("specThickness") && filters["specThickness"] != "-1" && !string.IsNullOrWhiteSpace(filters["specThickness"]))
                {
                    query_condition += " and (im.itsv_spec_thickness='" + filters["specThickness"].Trim().Replace("'", "''") + "')";
                }
                if (filters.ContainsKey("specColour") && filters["specColour"] != "-1" && !string.IsNullOrWhiteSpace(filters["specColour"]))
                {
                    query_condition += " and (im.itsv_spec_colour='" + filters["specColour"].Trim().Replace("'", "''") + "')";
                }
                if (filters.ContainsKey("specMachine") && filters["specMachine"] != "-1" && !string.IsNullOrWhiteSpace(filters["specMachine"]))
                {
                    query_condition += " and (im.itsv_spec_machine='" + filters["specMachine"].Trim().Replace("'", "''") + "')";
                }

                // UOM Filter
                if (filters.ContainsKey("uom") && filters["uom"] != "-1" && !string.IsNullOrWhiteSpace(filters["uom"]))
                {
                    string safeUom = filters["uom"].Trim().Replace("'", "''");
                    query_condition += " and (im.itsv_uom_sales='" + safeUom + "' or im.itsv_uom_purchase='" + safeUom + "' or im.itsv_reporting_uom='" + safeUom + "')";
                }
            }

            mySqlConnection db = new mySqlConnection();
            string countQry = "SELECT COUNT(*) FROM tbl_item_master im " + query_condition;
            double numrows = Convert.ToInt32(db.SelectScalar(countQry));
            if (numrows == 0)
            {
                return "N";
            }

            string exportQry = @"SELECT 
                im.itm_id AS 'Item ID',
                im.itm_code AS 'Item Code',
                im.itm_name AS 'Item Name',
                COALESCE(im.itsv_printing_name, '') AS 'Printing Name',
                COALESCE(im.itsv_part_no, '') AS 'Part No',
                COALESCE(im.itm_description, '') AS 'Description',
                COALESCE(v.vn_name, '') AS 'Supplier',
                CASE im.itm_type 
                    WHEN 1 THEN 'Product' 
                    WHEN 2 THEN 'Service' 
                    WHEN 3 THEN 'Package' 
                    ELSE '' 
                END AS 'Item Type',
                COALESCE(im.itm_qty_per_carton, 1) AS 'Qty Per Carton',
                COALESCE(sg.itsv_name, '') AS 'Stock Group',
                COALESCE(scat.itsv_name, '') AS 'Stock Category',
                COALESCE(im.itsv_description, '') AS 'Spec Description ID',
                COALESCE(u_pur.tum_name, '') AS 'Purchase UOM',
                COALESCE(u_sal.tum_name, '') AS 'Sales UOM',
                COALESCE(u_alt.tum_name, '') AS 'Alternate Units',
                COALESCE(u_rep.tum_name, '') AS 'Reporting UOM',
                COALESCE(im.itsv_conversion_value, 0) AS 'Conversion Value',
                COALESCE(im.itsv_denominator, 1) AS 'Denominator',
                CASE im.itsv_bom_enabled WHEN 1 THEN 'Yes' ELSE 'No' END AS 'BOM Enabled',
                COALESCE(im.itsv_hsn_sac, '') AS 'HSN / SAC',
                COALESCE(sp_item.itsv_name, '') AS 'Spec Item',
                COALESCE(sp_brand.itsv_name, '') AS 'Spec Brand',
                COALESCE(sp_thick.itsv_name, '') AS 'Spec Thickness',
                COALESCE(sp_colour.itsv_name, '') AS 'Spec Colour',
                COALESCE(sp_coat.itsv_name, '') AS 'Spec Coating',
                COALESCE(sp_pitch.itsv_name, '') AS 'Spec Pitch',
                COALESCE(sp_crust.itsv_name, '') AS 'Spec Crust',
                COALESCE(sp_width.itsv_name, '') AS 'Spec Width',
                COALESCE(sp_yield.itsv_name, '') AS 'Spec Yield Strength',
                COALESCE(sp_mach.itsv_name, '') AS 'Spec Machine',
                COALESCE(im.itsv_spec_weight_kg, '') AS 'Spec Weight KG'
            FROM tbl_item_master im
            LEFT JOIN tbl_vendor v ON v.vn_id = im.itm_supplierid
            LEFT JOIN tbl_item_master_spe_values sg ON sg.itsv_id = im.itsv_stock_group
            LEFT JOIN tbl_item_master_spe_values scat ON scat.itsv_id = im.itsv_category
            LEFT JOIN tbl_item_uom u_pur ON u_pur.tum_id = im.itsv_uom_purchase
            LEFT JOIN tbl_item_uom u_sal ON u_sal.tum_id = im.itsv_uom_sales
            LEFT JOIN tbl_item_uom u_alt ON u_alt.tum_id = im.itsv_alternate_units
            LEFT JOIN tbl_item_uom u_rep ON u_rep.tum_id = im.itsv_reporting_uom
            LEFT JOIN tbl_item_master_spe_values sp_item ON sp_item.itsv_id = im.itsv_spec_item
            LEFT JOIN tbl_item_master_spe_values sp_brand ON sp_brand.itsv_id = im.itsv_spec_brand
            LEFT JOIN tbl_item_master_spe_values sp_thick ON sp_thick.itsv_id = im.itsv_spec_thickness
            LEFT JOIN tbl_item_master_spe_values sp_colour ON sp_colour.itsv_id = im.itsv_spec_colour
            LEFT JOIN tbl_item_master_spe_values sp_coat ON sp_coat.itsv_id = im.itsv_spec_coating
            LEFT JOIN tbl_item_master_spe_values sp_pitch ON sp_pitch.itsv_id = im.itsv_spec_pitch
            LEFT JOIN tbl_item_master_spe_values sp_crust ON sp_crust.itsv_id = im.itsv_spec_crust
            LEFT JOIN tbl_item_master_spe_values sp_width ON sp_width.itsv_id = im.itsv_spec_width
            LEFT JOIN tbl_item_master_spe_values sp_yield ON sp_yield.itsv_id = im.itsv_spec_yield_strength
            LEFT JOIN tbl_item_master_spe_values sp_mach ON sp_mach.itsv_id = im.itsv_spec_machine " +
            query_condition + " ORDER BY im.itm_id DESC";

            HttpContext.Current.Session["itemmaster_downloadqry"] = exportQry;
            return "Y";
        }
        catch (Exception ex)
        {
            return ex.ToString();
        }
    }

    //edit item details
    [WebMethod]
    public static string editItemDetails(string itmid)
    {
        mySqlConnection db = new mySqlConnection();
        string safeId = itmid.Replace("'", "''");
        string qry = "SELECT im.*, cm.itm_id as couponItemId, cm.cpn_qty as quantity, t2.itm_name as copnItem " +
                     "FROM `tbl_item_master` im " +
                     "LEFT JOIN tbl_coupon_master cm on cm.cpn_itm_id=im.itm_id " +
                     "LEFT JOIN tbl_item_master t2 on t2.itm_id = cm.itm_id " +
                     "WHERE im.itm_id='" + safeId + "'";
        DataTable dt = db.SelectQuery(qry);
        return JsonConvert.SerializeObject(dt, Formatting.Indented);
    }
    /*
    //load brands for search
    [WebMethod]
    public static string showsearchbrands()
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
                    //sb.Append("<select id='combobranddiv' style='width:200px;margin-top:0px; margin-left:2px;' class='normaltextbg'>");
                    sb.Append("<option value='-1' selected='selected'>--Brand--</option>");
                   // sb.Append("</select>");
                }
                else
                {
                   // sb.Append("<select id='combobranddiv' style='width:200px;margin-top:0px; margin-left:2px;' class='normaltextbg'>");
                    sb.Append("<option value='-1' selected='selected'>--Brand--</option>");
                    for (int i = 0; i < dt.Rows.Count; i++)
                    {

                        sb.Append("<option value='" + dt.Rows[i]["brand_id"] + "'>" + dt.Rows[i]["brand_name"] + "</option>");

                    }
                   // sb.Append("</select>");
                }
            }
            else
            {
                sb.Append("<option value='-1' selected='selected'>--Brand--</option>");
                //sb.Append("<select id='combobranddiv'>");
               // sb.Append("</select>");
            }
        }

        return sb.ToString();
    }


    ////loading serach categorytypes
    [WebMethod]
    public static string loadsearchcategory()
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
                    //sb.Append("<select id='combosearchcategory' style='width:200px;margin-top:0px; margin-left:2px;' class='normaltextbg'>");
                    sb.Append("<option value='-1' selected='selected'>--Category--</option>");
                    //sb.Append("</select>");
                }
                else
                {
                   // sb.Append("<select id='combosearchcategory' style='width:200px;margin-top:0px; margin-left:2px;' class='normaltextbg'>");
                    sb.Append("<option value='-1' selected='selected'>--Category--</option>");
                    for (int i = 0; i < dt.Rows.Count; i++)
                    {

                        sb.Append("<option value='" + dt.Rows[i]["cat_id"] + "'>" + dt.Rows[i]["cat_name"] + "</option>");

                    }
                   // sb.Append("</select>");
                }
            }
            else
            {
                //sb.Append("<select id='combosearchcategory' style='width:110px;margin-top:0px;' class='normaltextbg'>");
                sb.Append("<option value='-1' selected='selected'>--Category--</option>");
                //sb.Append("</select>");
            }
        }

        return sb.ToString();
    }



    ////loading subcategorytypes
    [WebMethod]
    public static string showSubCategoryTypes(string categoryVal)
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        StringBuilder sb = new StringBuilder();
        string query = "SELECT cat_id, cat_name FROM tbl_item_category where parent_id=" + categoryVal + " ORDER BY cat_id ASC";
        dt = db.SelectQuery(query);
        if (dt != null)
        {
            if (dt.Rows.Count > 0)
            {
                if (dt.Rows[0]["cat_id"] is DBNull)
                {
                    //sb.Append("<select id='combosubcategory' style='width:200px;margin-top:6px;' class='normaltextbg'>");
                    sb.Append("<option value='-1' selected='selected'>--Subcategory--</option>");
                    //  sb.Append("</select>");
                }
                else
                {
                    // sb.Append("<select id='combosubcategory' style='width:200px;margin-top:6px;' class='normaltextbg'>");
                    sb.Append("<option value='-1' selected='selected'>--Subcategory--</option>");
                    for (int i = 0; i < dt.Rows.Count; i++)
                    {

                        sb.Append("<option value='" + dt.Rows[i]["cat_id"] + "'>" + dt.Rows[i]["cat_name"] + "</option>");

                    }
                    // sb.Append("</select>");
                }
            }
            else
            {
                // sb.Append("<select id='combosubcategory' style='width:200px;margin-top:6px;' class='normaltextbg'>");
                sb.Append("<option value='-1' selected='selected'>--Subcategory--</option>");
                //  sb.Append("</select>");
            }
        }

        return sb.ToString();
    }
    */

    //start: Item Pos Search Details
    [WebMethod]
    public static string searchOrderitem(int page, Dictionary<string, string> filters, int perpage)
    {
        try
        {
            string query_condition = " where 1=1 ";
            if (filters.Count > 0)
            {
                
                if (filters.ContainsKey("itemname"))
                {
                    query_condition += " and itm_name  LIKE '%" + filters["itemname"] + "%'";
                }
                if (filters.ContainsKey("itemcode"))
                {
                    query_condition += " and itm_code  LIKE '%" + filters["itemcode"] + "%'";
                }
            }
            int per_page = perpage;
            int offset = (page - 1) * per_page;
            mySqlConnection db = new mySqlConnection();
            string innerqry = "";
            string countQry = "";
           
            countQry = "SELECT count(*) FROM tbl_item_master " + query_condition;


            double numrows = Convert.ToInt32(db.SelectScalar(countQry));
            if (numrows == 0)
            {
                return "N";
            }
            int total_pages = Convert.ToInt32(Math.Ceiling(numrows / per_page));

            innerqry = "SELECT itm_id,itm_code,itm_name from tbl_item_master";
            innerqry = innerqry + query_condition + " ";
            innerqry = innerqry + " order by itm_id LIMIT " + offset.ToString() + " ," + per_page;
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
    //stop: Item Pos Search Details

    [WebMethod(EnableSession = true)]
    public static string GetAutoCompleteItemData(string variable)
    {
        StringBuilder sb = new StringBuilder();
        //List<string> custNames = new List<string>();
        mySqlConnection db = new mySqlConnection();
        string sqlQuery = "SELECT itm_name,itm_id from tbl_item_master where 1  and itm_name like '%" + variable + "%' limit 0,20";
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

}