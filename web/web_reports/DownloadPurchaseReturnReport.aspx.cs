using commonfunction;
using OfficeOpenXml;
using OfficeOpenXml.Style;
using System;
using System.Collections.Generic;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class web_reports_DownloadPurchaseReturnReport : System.Web.UI.Page
{
	protected void Page_Load(object sender, EventArgs e)
	{
		mySqlConnection db = new mySqlConnection();
		DataTable dt = new DataTable();
		string qry = Session["downloadqry"].ToString();
		dt = db.SelectQuery(qry);

		if (dt != null)
		{
			if (dt.Rows.Count > 0)
			{

				DumpExcel(dt);
			}

		}
	}

	public void DumpExcel(DataTable tbl)
	{

		//***
		int columlength = 0;
		columlength = tbl.Rows.Count;
		using (ExcelPackage pck = new ExcelPackage())
		{
			//Create the worksheet
			ExcelWorksheet ws = pck.Workbook.Worksheets.Add("PurchaseReturnItemReport");


			ws.Cells["A1"].LoadFromDataTable(tbl, true);
			using (ExcelRange rng = ws.Cells["A1:S1"])
			{
				rng.Style.Font.Bold = true;
				rng.Style.Fill.PatternType = ExcelFillStyle.Solid;                      //Set Pattern for the background to Solid
				rng.Style.Fill.BackgroundColor.SetColor(Color.FromArgb(79, 129, 189));  //Set color to dark blue
				rng.Style.Font.Color.SetColor(Color.White);
			}

			// DateTime dttt = DateTime.UtcNow;
			string newFileName = "Purchase Return Report";


			//Write it back to the client
			Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
			Response.AddHeader("content-disposition", "attachment;  filename=" + newFileName + ".xlsx");
			Response.BinaryWrite(pck.GetAsByteArray());

		}


	}
}