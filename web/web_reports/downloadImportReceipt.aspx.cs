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

public partial class web_reports_downloadImportReceipt : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        string qry = Session["downloadReceiptqry"].ToString();
        dt = db.SelectQuery(qry);

        if (dt != null)
        {
            if (dt.Rows.Count > 0)
            {

                DumpExcel(dt);
            }

        }
    }

    //start: Creating XLSX from Data Table
    public void DumpExcel(DataTable tbl)
    {

   

        int columlength = 0;
        columlength = tbl.Rows.Count;
        //   Session.Remove("downloadqry");
        //   Session.Remove("rp_fieldvalues");
        using (ExcelPackage pck = new ExcelPackage())
        {


            //Create the worksheet
            ExcelWorksheet ws = pck.Workbook.Worksheets.Add("Receipts");


            DataTable tmpTable = new DataTable();
            DataColumn column;
     
            ws.Cells["A1"].LoadFromDataTable(tbl, true);
            //  ws.Cells["A" + colnum1].LoadFromDataTable(summaytitle2, true);
            //   ws.Cells["A" + colnum2].LoadFromDataTable(summayTable1, true);
            //Format the header for column 1-3
            using (ExcelRange rng = ws.Cells["A1:H1"])
            {
                rng.Style.Font.Bold = true;
                rng.Style.Fill.PatternType = ExcelFillStyle.Solid;                      //Set Pattern for the background to Solid
                rng.Style.Fill.BackgroundColor.SetColor(Color.FromArgb(79, 129, 189));  //Set color to dark blue
                rng.Style.Font.Color.SetColor(Color.White);
            }




     

            using (ExcelRange rng = ws.Cells["A" + columlength + ":A" + columlength])
            {
                rng.Style.Font.Bold = true;
                rng.Style.Font.Size = 15;
                //  rng.Style.Fill.PatternType = ExcelFillStyle.Solid;                      //Set Pattern for the background to Solid
                // rng.Style.Fill.BackgroundColor.SetColor(Color.FromArgb(72,209,204));  //Set color to dark blue
                //  rng.Style.Font.Color.SetColor(Color.White);
                rng.Merge.ToString();
            }


          

            //Example how to Format Column 1 as numeric 
            for (int i = 1; i <= 17; i++)
            {
                using (ExcelRange col = ws.Cells[2, i, 2 + tbl.Rows.Count, i])
                {
                    //col.Style.Numberformat.Format = "#,##0.00";
                    col.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                }
            }
            ws.Cells[ws.Dimension.Address].AutoFitColumns();
            // DateTime dttt = DateTime.UtcNow;
            string newFileName = "Receipts";


            //Write it back to the client
            Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
            Response.AddHeader("content-disposition", "attachment;  filename=" + newFileName + ".xlsx");
            Response.BinaryWrite(pck.GetAsByteArray());

        }
    }
}