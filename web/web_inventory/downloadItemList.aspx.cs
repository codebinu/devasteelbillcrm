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

public partial class web_inventory_downloadItemList : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        try
        {
            if (Session["downloadqry"] == null)
            {
                Response.Clear();
                Response.ContentType = "text/html";
                Response.Write("<script>alert('No search query found. Please search and try again.'); window.close();</script>");
                Response.Flush();
                Response.SuppressContent = true;
                HttpContext.Current.ApplicationInstance.CompleteRequest();
                return;
            }

            mySqlConnection db = new mySqlConnection();
            DataTable dt = new DataTable();
            string qry = Session["downloadqry"].ToString();
            dt = db.SelectQuery(qry);

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
            // Normal when Response is completed
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
        mySqlConnection db = new mySqlConnection();
        using (ExcelPackage pck = new ExcelPackage())
        {
            // Create the worksheet
            ExcelWorksheet ws = pck.Workbook.Worksheets.Add("Item Details");

            string pricelistquery = "select itbs_id,tip_price,(select tpm_name from tbl_price_master where tpm_id=tip.tpm_id) as classPrice from tbl_item_pricelist tip order by itbs_id";
            DataTable priceDt = db.SelectQuery(pricelistquery);
            string priceMasterQuery = "select tpm_name as classPrice from tbl_price_master";
            DataTable priceHeaderDt = db.SelectQuery(priceMasterQuery);

            if (priceHeaderDt != null && priceHeaderDt.Rows.Count > 0)
            {
                foreach (DataRow dr2 in priceHeaderDt.Rows)
                {
                    string colName = dr2["classPrice"].ToString();
                    if (!tbl.Columns.Contains(colName))
                    {
                        DataColumn newCol = new DataColumn(colName, typeof(string));
                        newCol.AllowDBNull = true;
                        tbl.Columns.Add(newCol);
                    }
                }
            }

            if (priceDt != null && priceDt.Rows.Count > 0)
            {
                Dictionary<string, string> priceMap = new Dictionary<string, string>();
                foreach (DataRow pRow in priceDt.Rows)
                {
                    string key = pRow["itbs_id"].ToString() + "_" + pRow["classPrice"].ToString();
                    if (!priceMap.ContainsKey(key))
                    {
                        priceMap[key] = pRow["tip_price"].ToString();
                    }
                }

                foreach (DataRow dr in tbl.Rows)
                {
                    string itbsId = dr["id"].ToString();
                    if (priceHeaderDt != null)
                    {
                        foreach (DataRow dr2 in priceHeaderDt.Rows)
                        {
                            string priceClass = dr2["classPrice"].ToString();
                            string key = itbsId + "_" + priceClass;
                            if (priceMap.ContainsKey(key) && tbl.Columns.Contains(priceClass))
                            {
                                dr[priceClass] = priceMap[key];
                            }
                        }
                    }
                }
            }

            // Load DataTable into Excel starting from A1
            ws.Cells["A1"].LoadFromDataTable(tbl, true);

            int totalCols = tbl.Columns.Count;
            int totalRows = tbl.Rows.Count;

            // Format Header Row
            using (ExcelRange rng = ws.Cells[1, 1, 1, totalCols])
            {
                rng.Style.Font.Bold = true;
                rng.Style.Fill.PatternType = ExcelFillStyle.Solid;
                rng.Style.Fill.BackgroundColor.SetColor(Color.FromArgb(79, 129, 189));
                rng.Style.Font.Color.SetColor(Color.White);
                rng.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
            }

            // Format ID and Item Code columns to center alignment
            if (totalRows > 0)
            {
                using (ExcelRange col = ws.Cells[2, 1, 1 + totalRows, 1])
                {
                    col.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                }
                using (ExcelRange col = ws.Cells[2, 2, 1 + totalRows, 2])
                {
                    col.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                }
            }

            // Auto-fit all columns
            if (ws.Dimension != null)
            {
                ws.Cells[ws.Dimension.Address].AutoFitColumns();
            }

            string newFileName = "Item_Details";

            // Cleanly output binary Excel stream without trailing HTML corruption
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