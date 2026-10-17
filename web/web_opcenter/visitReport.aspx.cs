using OfficeOpenXml.Style;
using OfficeOpenXml;
using System;
using System.Collections.Generic;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class web_opcenter_visitReport : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        DataTable finalDt = HttpContext.Current.Session["finalDt"] as DataTable;
        string vr_name = HttpContext.Current.Session["vr_name"] as string;
        string vr_dtfrom = HttpContext.Current.Session["vr_dtfrom"] as string;
        string vr_dtto = HttpContext.Current.Session["vr_dtto"] as string;
        DumpExcel(finalDt, vr_name, vr_dtto, vr_dtfrom);
    }

    public void DumpExcel(DataTable tbl, string userName, string dateto, string datefrom)
    {        
        using (ExcelPackage pck = new ExcelPackage())
        {
            //Create the worksheet
            ExcelWorksheet ws = pck.Workbook.Worksheets.Add("Customer Visit Report");
            DataTable tmpTable = new DataTable();

            ws.Cells["A1"].Value = "CUSTOMER VISIT REPORT";
            ws.Cells["A2"].Value = "Saleman : ";
            ws.Cells["A3"].Value = "Date From : ";
            ws.Cells["A4"].Value = "Date Till : ";

            ws.Cells["B2"].Value = userName;
            ws.Cells["B3"].Value = datefrom;
            ws.Cells["B4"].Value = dateto;

            ws.Cells["A5"].LoadFromDataTable(tbl, true);
            using (ExcelRange rng = ws.Cells["A5:F5"])
            {
                rng.Style.Font.Bold = true;
                rng.Style.Fill.PatternType = ExcelFillStyle.Solid;                      //Set Pattern for the background to Solid
                rng.Style.Fill.BackgroundColor.SetColor(Color.FromArgb(79, 129, 189));  //Set color to dark blue
                rng.Style.Font.Color.SetColor(Color.White);
                rng.Merge.ToString();
            }

            ws.Cells[ws.Dimension.Address].AutoFitColumns();
            string newFileName = "Customer Visit Report - " + userName + " ("+ datefrom + "-"+ dateto + ")";

            Response.ClearHeaders();
            Response.Clear();
            Response.Buffer = true;

            //set the correct contenttype
            Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";

            //set the correct length of the data being send
            // Response.AddHeader("content-length", bin.Length.ToString());



            //set the filename for the excel package
            //Response.AddHeader("content-disposition", "attachment;  filename=" + newFileName + ".xlsx");
            Response.Headers["Content-Disposition"] = "attachment;filename=" + newFileName + ".xlsx";
            //send the byte array to the browser
            Response.BinaryWrite(pck.GetAsByteArray());
            //cleanup
            Response.Flush();
            HttpContext.Current.ApplicationInstance.CompleteRequest();
            Response.End();

        }
    }
}