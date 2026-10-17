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

public partial class web_inventory_downloadBatchMaster : System.Web.UI.Page
{
    private static readonly string DefaultExportQuery = @"SELECT 
        bm.itbm_id AS 'Batch Master ID',
        COALESCE(bm.itbm_prefix, '') AS 'Prefix',
        COALESCE(bm.itbm_serl, 0) AS 'Current Serial',
        COALESCE(bm.itbm_suffix, '') AS 'Suffix',
        CONCAT(COALESCE(bm.itbm_prefix, ''), COALESCE(bm.itbm_serl, 0), COALESCE(bm.itbm_suffix, '')) AS 'Sample Batch Number',
        COUNT(bmi.itbmi_id) AS 'Total Assigned Items'
    FROM tbl_item_batch_master bm
    LEFT JOIN tbl_item_batch_master_items bmi ON bmi.itbm_id = bm.itbm_id
    GROUP BY bm.itbm_id, bm.itbm_prefix, bm.itbm_suffix, bm.itbm_serl
    ORDER BY bm.itbm_id DESC";

    protected void Page_Load(object sender, EventArgs e)
    {
        try
        {
            string qry = DefaultExportQuery;
            if (Session["batchmaster_downloadqry"] != null && !string.IsNullOrWhiteSpace(Session["batchmaster_downloadqry"].ToString()))
            {
                qry = Session["batchmaster_downloadqry"].ToString();
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
                Response.Write("<script>alert('No Batch Master records found to download!'); window.close();</script>");
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
            ExcelWorksheet ws = pck.Workbook.Worksheets.Add("Batch Master Details");

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
                // Align IDs, Serials, Sample Batch center
                using (ExcelRange col = ws.Cells[2, 1, 1 + totalRows, 1])
                {
                    col.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                }
                using (ExcelRange col = ws.Cells[2, 3, 1 + totalRows, 3])
                {
                    col.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                }
                using (ExcelRange col = ws.Cells[2, 5, 1 + totalRows, 5])
                {
                    col.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                }
                using (ExcelRange col = ws.Cells[2, 6, 1 + totalRows, 6])
                {
                    col.Style.HorizontalAlignment = ExcelHorizontalAlignment.Right;
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

            string newFileName = "Batch_Master_Details_" + DateTime.Now.ToString("yyyyMMdd_HHmmss");

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
