using commonfunction;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Web;
using System.Web.Services;

public partial class web_sales_sales_order_interstock_transfer : System.Web.UI.Page
{
    protected SalesOrderInvoicePage Data;
    protected List<InterStockSource> Sources = new List<InterStockSource>();
    protected string ErrorMessage = "";
    protected string SessionToken = "";
    protected int SmoId;
    protected int Accuracy = 2;
    protected bool CanTransfer;

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
            CanTransfer = SalesOrderStatus.CanReserve(Data.Header.Status);
            Sources = SalesOrderStock.LoadInterStockSources();
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
            new LogClass("salesorderinterstockerror").write(ex);
            ErrorMessage = "Unable to load the sales order. Please try again.";
        }
    }

    protected string Enc(object o)
    {
        return o == null || o == DBNull.Value ? "" : HttpUtility.HtmlEncode(Convert.ToString(o));
    }

    protected string Money(decimal d)
    {
        return d.ToString("0.00", CultureInfo.InvariantCulture);
    }

    [WebMethod]
    public static string getTargets(int smoId, int sourceBranchId)
    {
        return JsonConvert.SerializeObject(SalesOrderStock.LoadInterStockTargets(smoId, sourceBranchId));
    }

    [WebMethod]
    public static string getTarget(int smoId, int sourceBranchId, int custId)
    {
        return JsonConvert.SerializeObject(SalesOrderStock.LoadInterStockTarget(smoId, sourceBranchId, custId));
    }

    [WebMethod]
    public static string getItems(int smoId, int sourceBranchId)
    {
        return JsonConvert.SerializeObject(SalesOrderStock.LoadInterStockItems(smoId, sourceBranchId));
    }

    [WebMethod]
    public static string getTransfers(int smoId)
    {
        return JsonConvert.SerializeObject(SalesOrderStock.LoadInterStockTransfers(smoId));
    }

    [WebMethod]
    public static string saveTransfer(InterStockRequest request)
    {
        return JsonConvert.SerializeObject(SalesOrderStock.CreateInterStockTransfer(request));
    }

    [WebMethod]
    public static string retryPurchase(int smoId, int smId)
    {
        return JsonConvert.SerializeObject(SalesOrderStock.RetryInterStockPurchase(smoId, smId));
    }
}
