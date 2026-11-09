using commonfunction;
using System;
using System.Globalization;
using System.Web;

public partial class web_sales_sales_order_invoice : System.Web.UI.Page
{
    protected SalesOrderInvoicePage Data;
    protected string ErrorMessage = "";
    protected string SessionToken = "";
    protected int SmoId;
    protected int Accuracy = 2;

    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication bill = new LoginAuthentication();
        bill.userAuthentication();
        bill.checkPageAcess(7);

        if (!int.TryParse(Request.QueryString["smoId"], out SmoId) || SmoId <= 0)
        {
            ErrorMessage = "Invalid sales order id.";
            return;
        }
        try
        {
            int staffId;
            var c = Request.Cookies["invntrystaffId"];
            if (c == null || !int.TryParse(c.Value, out staffId) || staffId <= 0)
            {
                ErrorMessage = "Session expired. Please login again.";
                return;
            }
            var t = Request.Cookies["invntrystaffTypeID"];
            Data = SalesOrderStock.LoadInvoicePage(SmoId, staffId, t != null ? t.Value : "");
            if (Data.Header == null)
            {
                ErrorMessage = Data.Message;
                return;
            }
            int acc;
            if (int.TryParse(new mySqlConnection().SelectScalar("select ss_decimal_accuracy from tbl_system_settings"), out acc) && acc >= 0 && acc <= 6)
                Accuracy = acc;

            // One token per page load: saving the same token twice is rejected by tbl_sales_master.sm_sales_sessionid (decimal(20,0)).
            SessionToken = DateTime.Now.ToString("yyyyMMddHHmmss", CultureInfo.InvariantCulture)
                + new Random(Guid.NewGuid().GetHashCode()).Next(0, 1000000).ToString("000000", CultureInfo.InvariantCulture);
        }
        catch (Exception ex)
        {
            Data = null;
            new LogClass("salesorderinvoiceerror").write(ex);
            ErrorMessage = "Unable to load the sales order. Please try again.";
        }
    }

    protected string Enc(object o)
    {
        return o == null || o == DBNull.Value ? "" : HttpUtility.HtmlEncode(Convert.ToString(o));
    }

    protected string Num(decimal d)
    {
        return d.ToString("0.####", CultureInfo.InvariantCulture);
    }

    protected string Inv(decimal d)
    {
        return d.ToString("0.########", CultureInfo.InvariantCulture);
    }

    protected string Money(decimal d)
    {
        return d.ToString("0.00", CultureInfo.InvariantCulture);
    }

    protected string RowNote(SalesOrderInvoiceLine l)
    {
        if (l.Issue != null)
            return l.Issue;
        if (l.InvoiceableQty <= 0)
            return l.Remaining > 0 ? "Remaining quantity is less than one unit." : "Fully invoiced.";
        if (l.MaxQty <= 0)
            return "No reserved stock. Reserve stock in the Reserved Items tab.";
        if (l.MaxQty < l.InvoiceableQty)
            return "Only " + l.MaxQty + " " + l.Uom + " reserved.";
        return "";
    }
}
