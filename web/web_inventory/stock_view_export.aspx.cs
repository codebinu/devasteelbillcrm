using commonfunction;
using OfficeOpenXml;
using OfficeOpenXml.Style;
using System;
using System.Collections.Generic;
using System.Data;
using System.Drawing;
using System.Web;

// Stock View export: every item that matches the warehouse, search and filters of the screen (not just the current page).
public partial class web_inventory_stock_view_export : System.Web.UI.Page
{
    static readonly Dictionary<string, string> StatusLabels = new Dictionary<string, string>
    {
        { "healthy", "Healthy" }, { "reserved", "Reserved" }, { "pending", "Pending Demand" },
        { "shortage", "Shortage" }, { "zero", "Zero Stock" }, { "negative", "Negative Stock" }
    };

    static readonly Dictionary<string, string> TypeLabels = new Dictionary<string, string>
    {
        { "finished", "Finished Goods" }, { "raw", "Raw Material" }, { "other", "Other" }
    };

    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication bill = new LoginAuthentication();
        bill.userAuthentication();
        bill.checkPageAcess(StockView.PageId);

        int staff = BatchTrace.AuthorizedStaffId(StockView.PageId);
        if (staff == 0)
        {
            Response.StatusCode = 403;
            Response.End();
            return;
        }

        var filters = new Dictionary<string, string>();
        foreach (string key in new[] { "wh", "search", "group", "brand", "type", "status", "min", "max" })
        {
            string v = Request.QueryString[key];
            if (!string.IsNullOrEmpty(v))
                filters[key] = v;
        }

        string warehouse;
        DataTable src = StockView.Export(staff, filters, Request.QueryString["sortBy"], Request.QueryString["sortDir"], out warehouse);
        if (src == null)
        {
            Response.StatusCode = 403;
            Response.End();
            return;
        }

        var tbl = new DataTable();
        foreach (string c in new[] { "Item Code", "Item Name", "Category", "Brand", "Item Type", "Unit", "Warehouse" })
            tbl.Columns.Add(c, typeof(string));
        foreach (string c in new[] { "Physical Stock", "Reserved Stock", "Free Stock", "Pending Reservation", "Projected Balance" })
            tbl.Columns.Add(c, typeof(decimal));
        tbl.Columns.Add("Stock Status", typeof(string));

        foreach (DataRow r in src.Rows)
        {
            string type = Convert.ToString(r["itype"]), status = Convert.ToString(r["status"]);
            tbl.Rows.Add(Convert.ToString(r["itm_code"]), Convert.ToString(r["itm_name"]), Convert.ToString(r["grp"]), Convert.ToString(r["brand"]),
                TypeLabels.ContainsKey(type) ? TypeLabels[type] : type, Convert.ToString(r["uom"]), warehouse,
                Math.Round(Convert.ToDecimal(r["phys"]), 3), Math.Round(Convert.ToDecimal(r["resv"]), 3), Math.Round(Convert.ToDecimal(r["free"]), 3),
                Math.Round(Convert.ToDecimal(r["pend"]), 3), Math.Round(Convert.ToDecimal(r["proj"]), 3),
                StatusLabels.ContainsKey(status) ? StatusLabels[status] : status);
        }

        using (ExcelPackage pck = new ExcelPackage())
        {
            ExcelWorksheet ws = pck.Workbook.Worksheets.Add("Stock View");
            ws.Cells["A1"].LoadFromDataTable(tbl, true);
            int cols = tbl.Columns.Count, rows = tbl.Rows.Count;

            using (ExcelRange rng = ws.Cells[1, 1, 1, cols])
            {
                rng.Style.Font.Bold = true;
                rng.Style.Fill.PatternType = ExcelFillStyle.Solid;
                rng.Style.Fill.BackgroundColor.SetColor(Color.FromArgb(79, 129, 189));
                rng.Style.Font.Color.SetColor(Color.White);
                rng.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
            }
            if (rows > 0)
                ws.Cells[2, 8, rows + 1, 12].Style.Numberformat.Format = "#,##0.000";
            ws.View.FreezePanes(2, 1);
            if (ws.Dimension != null)
                ws.Cells[ws.Dimension.Address].AutoFitColumns();

            Response.Clear();
            Response.ClearContent();
            Response.ClearHeaders();
            Response.Buffer = true;
            Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
            Response.AddHeader("content-disposition", "attachment; filename=\"Stock_View_" + DateTime.Now.ToString("yyyyMMdd_HHmm") + ".xlsx\"");
            Response.BinaryWrite(pck.GetAsByteArray());
            Response.Flush();
            Response.SuppressContent = true;
            HttpContext.Current.ApplicationInstance.CompleteRequest();
        }
    }
}
