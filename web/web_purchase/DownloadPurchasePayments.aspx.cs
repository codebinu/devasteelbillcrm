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

public partial class web_purchase_DownloadPurchasePayments : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        string qry = Session["downloadqry"].ToString();
        int type = Convert.ToInt32(Session["downloadtype"]);

        dt = db.SelectQuery(qry);
        if (dt != null)
        {
            if (dt.Rows.Count > 0)
            {

                DumpExcel(dt, type);
            }

        }
    }

    public void DumpExcel(DataTable dt_base, int type)
    {

        int columlength = 0;
        columlength = dt_base.Rows.Count;
        //   Session.Remove("downloadqry");
        //   Session.Remove("rp_fieldvalues");
        using (ExcelPackage pck = new ExcelPackage())
        {
            //Create the worksheet
            ExcelWorksheet ws = pck.Workbook.Worksheets.Add("Purchase-Payments-Report");

            DataTable tmpTable = new DataTable();
            DataColumn column;

            ws.Cells["A1"].LoadFromDataTable(dt_base, true);

            //  ws.Cells["A" + colnum1].LoadFromDataTable(summaytitle2, true);
            //   ws.Cells["A" + colnum2].LoadFromDataTable(summayTable1, true);
            //Format the header for column 1-3
            using (ExcelRange rng = ws.Cells["A1:O1"])
            {
                rng.Style.Font.Bold = true;
                rng.Style.Fill.PatternType = ExcelFillStyle.Solid;                      //Set Pattern for the background to Solid
                rng.Style.Fill.BackgroundColor.SetColor(Color.FromArgb(79, 129, 189));  //Set color to dark blue
                rng.Style.Font.Color.SetColor(Color.White);
            }

            //int rangeMaxRows = ws.Dimension.End.Row;

            //using (ExcelRange rng = ws.Cells["A" + rangeMaxRows + ":S" + rangeMaxRows + ""])
            //{
            //    rng.Style.Font.Bold = true;
            //    rng.Style.Fill.PatternType = ExcelFillStyle.Solid;                      //Set Pattern for the background to Solid
            //    rng.Style.Fill.BackgroundColor.SetColor(Color.FromArgb(79, 129, 189));  //Set color to dark blue
            //    rng.Style.Font.Color.SetColor(Color.White);
            //}

            ws.Cells[ws.Dimension.Address].AutoFitColumns();

            // DateTime dttt = DateTime.UtcNow;
            string newFileName = "";
            if (type == 1) { newFileName = "Purchase_Payments_Report"; }

            //Write it back to the client
            Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
            Response.AddHeader("content-disposition", "attachment;  filename=" + newFileName + ".xlsx");
            Response.BinaryWrite(pck.GetAsByteArray());

        }
    }
}