using System;
using System.Collections.Generic;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Web.UI;
using OfficeOpenXml;
using OfficeOpenXml.Style;
using commonfunction;
using System.ComponentModel;

public partial class web_reports_downloadreport : System.Web.UI.Page
{
	protected void Page_Load(object sender, EventArgs e)
	{
		if (Session["downloadqry"] == null)
			return;

		try
		{
			mySqlConnection db = new mySqlConnection();
			string qry = Session["downloadqry"].ToString();

			DataTable orders = db.SelectQuery(qry);

			if (orders != null && orders.Rows.Count > 0)
			{
				GenerateExcel(orders);
			}
		}
		catch (Exception ex)
		{
			Response.Write("Error generating report : " + ex.Message);
		}
	}

	private void GenerateExcel(DataTable orders)
	{
		//ExcelPackage.LicenseContext = LicenseContext.NonCommercial;

		ReportSummary summary = ReadSummary();

		Dictionary<string, List<DataRow>> itemDictionary = LoadItems(orders);

		BuildItemColumn(orders, itemDictionary);

		using (ExcelPackage package = new ExcelPackage())
		{
			ExcelWorksheet ws = package.Workbook.Worksheets.Add("SalesReport");

			int rowPointer = 1;

			#region Title

			ws.Cells[rowPointer, 1].Value =
				string.Format("Report in Warehouse: {0}  Date Range: ({1} to {2})",
				summary.BranchName, summary.FromDate, summary.ToDate);

			ws.Cells[rowPointer, 1, rowPointer, orders.Columns.Count].Merge = true;
			ws.Cells[rowPointer, 1].Style.Font.Size = 16;
			ws.Cells[rowPointer, 1].Style.Font.Bold = true;

			rowPointer += 2;

			#endregion

			#region Orders Table

			ws.Cells[rowPointer, 1].LoadFromDataTable(orders, true);

			using (ExcelRange header = ws.Cells[rowPointer, 1, rowPointer, orders.Columns.Count])
			{
				header.Style.Font.Bold = true;
				header.Style.Fill.PatternType = ExcelFillStyle.Solid;
				header.Style.Fill.BackgroundColor.SetColor(Color.FromArgb(79, 129, 189));
				header.Style.Font.Color.SetColor(Color.White);
			}

			rowPointer += orders.Rows.Count + 3;

			#endregion

			#region Summary Title

			ws.Cells[rowPointer, 1].Value =
				string.Format("Collection Summary Report in Warehouse: {0}  Date Range: ({1} to {2})",
				summary.BranchName, summary.FromDate, summary.ToDate);

			ws.Cells[rowPointer, 1].Style.Font.Bold = true;
			ws.Cells[rowPointer, 1].Style.Font.Size = 14;

			rowPointer++;

			#endregion

			#region Summary Table

			DataTable summaryTable = new DataTable();

			summaryTable.Columns.Add("Total Records");
			summaryTable.Columns.Add("Total Net Amount");
			summaryTable.Columns.Add("Total Paid");
			summaryTable.Columns.Add("Cash Amount");
			summaryTable.Columns.Add("Card Amount");
			summaryTable.Columns.Add("Cheque Amount");
			summaryTable.Columns.Add("Total Balance");

			summaryTable.Rows.Add(
				summary.TotalRecords,
				summary.NetAmount,
				summary.PaidAmount,
				summary.CashAmount,
				summary.CardAmount,
				summary.ChequeAmount,
				summary.BalanceAmount
			);

			ws.Cells[rowPointer, 1].LoadFromDataTable(summaryTable, true);

			using (ExcelRange header = ws.Cells[rowPointer, 1, rowPointer, summaryTable.Columns.Count])
			{
				header.Style.Font.Bold = true;
				header.Style.Fill.PatternType = ExcelFillStyle.Solid;
				header.Style.Fill.BackgroundColor.SetColor(Color.FromArgb(79, 129, 189));
				header.Style.Font.Color.SetColor(Color.White);
			}

			#endregion

			ws.Cells[ws.Dimension.Address].AutoFitColumns();

			DownloadExcel(package);

			ClearSession();
		}
	}

	private Dictionary<string, List<DataRow>> LoadItems(DataTable orders)
	{
		mySqlConnection db = new mySqlConnection();

		List<string> orderIds = orders.AsEnumerable()
			.Select(r => r["OrderNo"].ToString())
			.Distinct()
			.ToList();

		if (orderIds.Count == 0)
			return new Dictionary<string, List<DataRow>>();

		string idList = "'" + string.Join("','", orderIds.ToArray()) + "'";

		string qry =
		"SELECT sm_id,itm_code,itm_name,si_price,si_qty,si_discount_amount,si_net_amount " +
		"FROM tbl_sales_items WHERE sm_id IN (" + idList + ")";

		DataTable itemsTable = db.SelectQuery(qry);

		Dictionary<string, List<DataRow>> dict =
			itemsTable.AsEnumerable()
			.GroupBy(r => r["sm_id"].ToString())
			.ToDictionary(g => g.Key, g => g.ToList());

		return dict;
	}

	private void BuildItemColumn(DataTable orders, Dictionary<string, List<DataRow>> itemDict)
	{
		foreach (DataRow row in orders.Rows)
		{
			string orderNo = row["OrderNo"].ToString();

			if (!itemDict.ContainsKey(orderNo))
				continue;

			StringBuilder items = new StringBuilder();
			int index = 1;

			foreach (DataRow item in itemDict[orderNo])
			{
				items.Append(index);
				items.Append(")");
				items.Append(item["itm_code"]);
				items.Append("-");
				items.Append(item["itm_name"]);
				items.Append("((");
				items.Append(item["si_qty"]);
				items.Append(" * ");
				items.Append(item["si_price"]);
				items.Append(")-");
				items.Append(item["si_discount_amount"]);
				items.Append("=");
				items.Append(item["si_net_amount"]);
				items.Append("), ");

				index++;
			}

			row["Item"] = items.ToString().TrimEnd(',', ' ');
		}
	}

	private ReportSummary ReadSummary()
	{
		string[] rp = Convert.ToString(Session["rp_fieldvalues"]).Split('*');

		ReportSummary summary = new ReportSummary();

		if (rp.Length > 0) summary.FromDate = rp[0];
		if (rp.Length > 1) summary.ToDate = rp[1];
		if (rp.Length > 2) summary.BranchName = rp[2];
		if (rp.Length > 3) summary.TotalRecords = rp[3];
		if (rp.Length > 5) summary.CashAmount = rp[5];
		if (rp.Length > 6) summary.CardAmount = rp[6];
		if (rp.Length > 7) summary.ChequeAmount = rp[7];
		if (rp.Length > 8) summary.NetAmount = rp[8];
		if (rp.Length > 9) summary.PaidAmount = rp[9];
		if (rp.Length > 10) summary.BalanceAmount = rp[10];

		return summary;
	}

	private void DownloadExcel(ExcelPackage package)
	{
		Response.Clear();
		Response.ContentType =
		"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";

		Response.AddHeader("content-disposition",
		"attachment; filename=SalesReport.xlsx");

		Response.BinaryWrite(package.GetAsByteArray());
		Response.End();
	}

	private void ClearSession()
	{
		Session.Remove("downloadqry");
		Session.Remove("rp_fieldvalues");
	}
}

public class ReportSummary
{
	public string FromDate { get; set; }
	public string ToDate { get; set; }
	public string BranchName { get; set; }
	public string TotalRecords { get; set; }
	public string CashAmount { get; set; }
	public string CardAmount { get; set; }
	public string ChequeAmount { get; set; }
	public string NetAmount { get; set; }
	public string PaidAmount { get; set; }
	public string BalanceAmount { get; set; }
}