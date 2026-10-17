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

public partial class web_sales_downloadCollectionReport : System.Web.UI.Page
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
        string reportfromdate = "";
        string reporttodate = "";
        string rp_totalrecords = "";
        string rp_cashamount = "";
        string rp_cardamount = "";
        string rp_chequeamount = "";
 

        string rp_fieldvalues = Convert.ToString(Session["rp_fieldvalues"]);
        String[] rp_splitarray = rp_fieldvalues.Split('*');

        reportfromdate = Convert.ToString(rp_splitarray[0]);
        reporttodate = Convert.ToString(rp_splitarray[1]);
        rp_totalrecords = Convert.ToString(rp_splitarray[2]);
        rp_cashamount = Convert.ToString(rp_splitarray[3]);
        rp_cardamount = Convert.ToString(rp_splitarray[4]);
        rp_chequeamount = Convert.ToString(rp_splitarray[5]);
        var totalpaid = Convert.ToDouble(rp_cashamount) + Convert.ToDouble(rp_cardamount) + Convert.ToDouble(rp_chequeamount);
        int columlength = 0;
        columlength = tbl.Rows.Count;
        using (ExcelPackage pck = new ExcelPackage())
        {


            //Create the worksheet
            ExcelWorksheet ws = pck.Workbook.Worksheets.Add("CollectionReport");


            DataTable tmpTable = new DataTable();
            DataColumn column;
            // DataRow row;
            column = new DataColumn();
            column.ColumnName = "Report in Date Range:(" + reportfromdate + " to " + reporttodate + ")";
            column.ReadOnly = true;
            column.Unique = true;
            tmpTable.Columns.Add(column);

            DataTable summaytitle1 = new DataTable();
            DataColumn column1;
            column1 = new DataColumn();
            column1.ColumnName = "Collection Summary Report in Date Range:(" + reportfromdate + " to " + reporttodate + ")";
            summaytitle1.Columns.Add(column1);


            DataTable summayTable = new DataTable();

            //   summayTable.Columns.AddRange(new DataColumn[9] { new DataColumn("Total Records", typeof(string)), new DataColumn("Cash Amount", typeof(string)), new DataColumn("Card Amount", typeof(string)), new DataColumn("Cheque Amount", typeof(string)), new DataColumn("Total Net Amount", typeof(string)), new DataColumn("Total Paid Amount", typeof(string)), new DataColumn("Total Oustanding Cleared Amount", typeof(string)), new DataColumn("Total Outstanding Amount", typeof(string)), new DataColumn("Total Sales Amount", typeof(string)) });

            //    summayTable.Rows.Add(rp_totalrecords, rp_cashamount, rp_cardamount, rp_chequeamount, rp_netamount, rp_paidamount, rp_outstad_clearedamount, rp_outstandamount, rp_total_salesamount);

            summayTable.Columns.AddRange(new DataColumn[5] { new DataColumn("Total Records", typeof(string)), new DataColumn("Total Paid", typeof(string)), new DataColumn("Cash Amount", typeof(string)), new DataColumn("Card Amount", typeof(string)), new DataColumn("Cheque Amount", typeof(string)) });

            summayTable.Rows.Add(rp_totalrecords,totalpaid, rp_cashamount, rp_cardamount, rp_chequeamount);


            columlength = columlength + 4;
            int colnum = columlength + 1;
            int colnum1 = columlength + 4;
            int colnum2 = columlength + 5;
            //Load the datatable into the sheet, starting from cell A1. Print the column names on row 1
            ws.Cells["A1"].LoadFromDataTable(tmpTable, true);
            ws.Cells["A2"].LoadFromDataTable(tbl, true);
            ws.Cells["A" + colnum].LoadFromDataTable(summayTable, true);
            //  ws.Cells["A" + colnum1].LoadFromDataTable(summaytitle2, true);
            //   ws.Cells["A" + colnum2].LoadFromDataTable(summayTable1, true);
            //Format the header for column 1-3
            using (ExcelRange rng = ws.Cells["A2:J2"])
            {
                rng.Style.Font.Bold = true;
                rng.Style.Fill.PatternType = ExcelFillStyle.Solid;                      //Set Pattern for the background to Solid
                rng.Style.Fill.BackgroundColor.SetColor(Color.FromArgb(79, 129, 189));  //Set color to dark blue
                rng.Style.Font.Color.SetColor(Color.White);
            }




            using (ExcelRange rng = ws.Cells["A1:M1"])
            {

                rng.Style.Font.Bold = true;
                rng.Style.Font.Size = 15;
                //   rng.Style.Fill.PatternType = ExcelFillStyle.Solid;                      //Set Pattern for the background to Solid
                //    rng.Style.Fill.BackgroundColor.SetColor(Color.FromArgb(72,209,204));  //Set color to dark blue
                //  rng.Style.Font.Color.SetColor(Color.White);
                rng.Merge.ToString();
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


            using (ExcelRange rng = ws.Cells["A" + colnum + ":I" + colnum])
            {
                rng.Style.Font.Bold = true;
                rng.Style.Fill.PatternType = ExcelFillStyle.Solid;                      //Set Pattern for the background to Solid
                rng.Style.Fill.BackgroundColor.SetColor(Color.FromArgb(79, 129, 189));  //Set color to dark blue
                rng.Style.Font.Color.SetColor(Color.White);
                rng.Merge.ToString();
            }


            using (ExcelRange rng = ws.Cells["A" + colnum1 + ":A" + colnum1])
            {
                rng.Style.Font.Bold = true;
                rng.Style.Font.Size = 15;
                // rng.Style.Fill.PatternType = ExcelFillStyle.Solid;                      //Set Pattern for the background to Solid
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
            // DateTime dttt = DateTime.UtcNow;
            string newFileName = "collectionReport";



            Session.Remove("rp_totalrecords");
            Session.Remove("rp_currency");
            Session.Remove("rp_cashamount");
            Session.Remove("rp_cardamount");
            Session.Remove("rp_chequeamount");
 

            //Session.Remove("rp_total_salesamount");

            //Write it back to the client
            Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
            Response.AddHeader("content-disposition", "attachment;  filename=" + newFileName + ".xlsx");
            Response.BinaryWrite(pck.GetAsByteArray());

        }
    }
}