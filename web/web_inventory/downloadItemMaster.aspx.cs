using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using commonfunction;
using System.Data;
using System.Drawing;
using OfficeOpenXml;
using OfficeOpenXml.Style;

public partial class web_inventory_downloadItemMaster : System.Web.UI.Page
{
    private static readonly string DefaultExportQuery = @"SELECT 
        im.itm_id AS 'Item ID',
        im.itm_code AS 'Item Code',
        im.itm_name AS 'Item Name',
        COALESCE(im.itsv_printing_name, '') AS 'Printing Name',
        COALESCE(im.itsv_part_no, '') AS 'Part No',
        COALESCE(im.itm_description, '') AS 'Description',
        COALESCE(b.brand_name, '') AS 'Brand',
        COALESCE(c.cat_name, '') AS 'Category',
        COALESCE(sc.cat_name, '') AS 'Subcategory',
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
    LEFT JOIN tbl_item_brand b ON b.brand_id = im.itm_brand_id
    LEFT JOIN tbl_item_category c ON c.cat_id = im.itm_category_id
    LEFT JOIN tbl_item_category sc ON sc.cat_id = im.itm_subcategory_id
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
    LEFT JOIN tbl_item_master_spe_values sp_mach ON sp_mach.itsv_id = im.itsv_spec_machine
    ORDER BY im.itm_id DESC";

    protected void Page_Load(object sender, EventArgs e)
    {
        try
        {
            string qry = DefaultExportQuery;
            if (Session["itemmaster_downloadqry"] != null && !string.IsNullOrWhiteSpace(Session["itemmaster_downloadqry"].ToString()))
            {
                qry = Session["itemmaster_downloadqry"].ToString();
            }

            mySqlConnection db = new mySqlConnection();
            DataTable dt = db.SelectQuery(qry);

            if (dt != null && dt.Rows.Count > 0)
            {
                DumpExcel(dt);
            }
            else
            {
                Response.Clear();
                Response.ContentType = "text/html";
                Response.Write("<script>alert('No records found to download.'); window.close();</script>");
                Response.Flush();
                Response.SuppressContent = true;
                HttpContext.Current.ApplicationInstance.CompleteRequest();
            }
        }
        catch (System.Threading.ThreadAbortException)
        {
            // Normal termination when response stream completes
        }
        catch (Exception ex)
        {
            Response.Clear();
            Response.ContentType = "text/html";
            Response.Write("<script>alert('Error generating Excel: " + ex.Message.Replace("'", "\\'") + "'); window.close();</script>");
            Response.Flush();
            Response.SuppressContent = true;
            HttpContext.Current.ApplicationInstance.CompleteRequest();
        }
    }

    public void DumpExcel(DataTable tbl)
    {
        using (ExcelPackage pck = new ExcelPackage())
        {
            ExcelWorksheet ws = pck.Workbook.Worksheets.Add("Item Master Details");

            // Load DataTable into Excel starting from A1 including column headers
            ws.Cells["A1"].LoadFromDataTable(tbl, true);

            int totalCols = tbl.Columns.Count;
            int totalRows = tbl.Rows.Count;

            // Format Header Row
            using (ExcelRange rng = ws.Cells[1, 1, 1, totalCols])
            {
                rng.Style.Font.Bold = true;
                rng.Style.Fill.PatternType = ExcelFillStyle.Solid;
                rng.Style.Fill.BackgroundColor.SetColor(Color.FromArgb(42, 63, 84)); // Gentellela brand navy
                rng.Style.Font.Color.SetColor(Color.White);
                rng.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                rng.Style.VerticalAlignment = ExcelVerticalAlignment.Center;
                rng.Style.Font.Size = 11;
            }
            ws.Row(1).Height = 25;

            // Format data rows if any
            if (totalRows > 0)
            {
                // Center-align ID, Item Code, Part No, Qty Per Carton, BOM Enabled, HSN/SAC
                using (ExcelRange col = ws.Cells[2, 1, 1 + totalRows, 1])
                {
                    col.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                }
                using (ExcelRange col = ws.Cells[2, 2, 1 + totalRows, 2])
                {
                    col.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                }
                using (ExcelRange col = ws.Cells[2, 5, 1 + totalRows, 5])
                {
                    col.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                }
                using (ExcelRange col = ws.Cells[2, 12, 1 + totalRows, 12])
                {
                    col.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                }
                using (ExcelRange col = ws.Cells[2, 22, 1 + totalRows, 22])
                {
                    col.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                }
                using (ExcelRange col = ws.Cells[2, 23, 1 + totalRows, 23])
                {
                    col.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                }
            }

            // Auto-fit all columns
            if (ws.Dimension != null)
            {
                ws.Cells[ws.Dimension.Address].AutoFitColumns();
            }

            string newFileName = "Item_Master_Details_" + DateTime.Now.ToString("yyyyMMdd_HHmmss");

            // Binary streaming compatible with Office Excel
            Response.Clear();
            Response.ClearContent();
            Response.ClearHeaders();
            Response.Buffer = true;
            Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
            Response.AddHeader("content-disposition", "attachment; filename=\"" + newFileName + ".xlsx\"");

            byte[] reportBytes = pck.GetAsByteArray();
            Response.BinaryWrite(reportBytes);
            Response.Flush();
            Response.SuppressContent = true;
            HttpContext.Current.ApplicationInstance.CompleteRequest();
        }
    }
}
