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

public partial class web_inventory_downloadBom : System.Web.UI.Page
{
    private static readonly string DefaultExportQuery = @"SELECT 
        b.itmbi_id AS 'BOM Record ID',
        b.itm_id_output AS 'Output Item ID',
        out_m.itm_code AS 'Output Item Code',
        out_m.itm_name AS 'Output Item Name',
        COALESCE(out_m.itsv_printing_name, '') AS 'Output Printing Name',
        b.itmbi_serialno AS 'Component S.No',
        b.itm_id_input AS 'Component Item ID',
        in_m.itm_code AS 'Component Item Code',
        in_m.itm_name AS 'Component Item Name',
        COALESCE(in_m.itsv_printing_name, '') AS 'Component Printing Name',
        ROUND(b.itmbi_qty, 4) AS 'Component Quantity',
        COALESCE(u.tum_name, '') AS 'Component UOM'
    FROM tbl_item_master_bom b
    JOIN tbl_item_master out_m ON out_m.itm_id = b.itm_id_output
    JOIN tbl_item_master in_m ON in_m.itm_id = b.itm_id_input
    LEFT JOIN tbl_item_uom u ON u.tum_id = b.tum_id
    ORDER BY b.itm_id_output DESC, b.itmbi_serialno ASC";

    protected void Page_Load(object sender, EventArgs e)
    {
        try
        {
            string qry = DefaultExportQuery;
            if (Session["bom_downloadqry"] != null && !string.IsNullOrWhiteSpace(Session["bom_downloadqry"].ToString()))
            {
                qry = Session["bom_downloadqry"].ToString();
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
                Response.Write("<script>alert('No BOM records found to download!'); window.close();</script>");
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
            ExcelWorksheet ws = pck.Workbook.Worksheets.Add("Bill of Material");

            // Load DataTable into Excel starting from A1 including column headers
            ws.Cells["A1"].LoadFromDataTable(tbl, true);

            int totalCols = tbl.Columns.Count;
            int totalRows = tbl.Rows.Count;

            // Format Header Row
            using (ExcelRange rng = ws.Cells[1, 1, 1, totalCols])
            {
                rng.Style.Font.Bold = true;
                rng.Style.Fill.PatternType = ExcelFillStyle.Solid;
                rng.Style.Fill.BackgroundColor.SetColor(Color.FromArgb(42, 63, 84)); // Gentelella brand navy
                rng.Style.Font.Color.SetColor(Color.White);
                rng.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                rng.Style.VerticalAlignment = ExcelVerticalAlignment.Center;
                rng.Style.Font.Size = 11;
            }
            ws.Row(1).Height = 25;

            // Format data rows
            if (totalRows > 0)
            {
                // Align IDs, S.No, Code, UOM center
                using (ExcelRange col = ws.Cells[2, 1, 1 + totalRows, 1])
                {
                    col.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                }
                using (ExcelRange col = ws.Cells[2, 2, 1 + totalRows, 2])
                {
                    col.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                }
                using (ExcelRange col = ws.Cells[2, 3, 1 + totalRows, 3])
                {
                    col.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                }
                using (ExcelRange col = ws.Cells[2, 8, 1 + totalRows, 8])
                {
                    col.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                }
                using (ExcelRange col = ws.Cells[2, 9, 1 + totalRows, 9])
                {
                    col.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                }
                using (ExcelRange col = ws.Cells[2, 10, 1 + totalRows, 10])
                {
                    col.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                }
                using (ExcelRange col = ws.Cells[2, 13, 1 + totalRows, 13])
                {
                    col.Style.HorizontalAlignment = ExcelHorizontalAlignment.Right;
                }
                using (ExcelRange col = ws.Cells[2, 14, 1 + totalRows, 14])
                {
                    col.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                }

                // Add subtle borders
                using (ExcelRange rng = ws.Cells[2, 1, 1 + totalRows, totalCols])
                {
                    rng.Style.Border.Top.Style = ExcelBorderStyle.Thin;
                    rng.Style.Border.Top.Color.SetColor(Color.FromArgb(220, 220, 220));
                    rng.Style.Border.Bottom.Style = ExcelBorderStyle.Thin;
                    rng.Style.Border.Bottom.Color.SetColor(Color.FromArgb(220, 220, 220));
                }
            }

            // Auto-fit all columns
            if (ws.Dimension != null)
            {
                ws.Cells[ws.Dimension.Address].AutoFitColumns();
            }

            string newFileName = "Bill_Of_Material_" + DateTime.Now.ToString("yyyyMMdd_HHmmss");

            // Binary streaming compatible with Office Excel
            Response.Clear();
            Response.ClearContent();
            Response.ClearHeaders();
            Response.Buffer = true;
            Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
            Response.AddHeader("content-disposition", "attachment; filename=\"" + newFileName + ".xlsx\"");

            byte[] fileBytes = pck.GetAsByteArray();
            Response.BinaryWrite(fileBytes);
            Response.Flush();
            Response.SuppressContent = true;
            HttpContext.Current.ApplicationInstance.CompleteRequest();
        }
    }
}
