using commonfunction;
using System;
using System.Web.Services;

// Stock View: read-only item details. All queries live in App_Code\StockView.cs.
public partial class web_inventory_stock_view_details : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication bill = new LoginAuthentication();
        bill.userAuthentication();
        bill.checkPageAcess(StockView.PageId);
    }

    [WebMethod]
    public static string getOverview(int itemId, string wh)
    {
        try
        {
            int staff = BatchTrace.AuthorizedStaffId(StockView.PageId);
            return staff == 0 ? "{\"notFound\":true}" : StockView.Overview(staff, itemId, wh);
        }
        catch (Exception ex)
        {
            new LogClass("stockviewerror").write(ex);
            return "E";
        }
    }

    [WebMethod]
    public static string getDemand(int itemId, string wh)
    {
        try
        {
            int staff = BatchTrace.AuthorizedStaffId(StockView.PageId);
            return staff == 0 ? "{\"rows\":[],\"total\":0,\"uom\":\"\"}" : StockView.Demand(staff, itemId, wh);
        }
        catch (Exception ex)
        {
            new LogClass("stockviewerror").write(ex);
            return "E";
        }
    }

    [WebMethod]
    public static string getReservations(int itemId, string wh)
    {
        try
        {
            int staff = BatchTrace.AuthorizedStaffId(StockView.PageId);
            return staff == 0 ? "{\"rows\":[],\"total\":0,\"uom\":\"\"}" : StockView.Reservations(staff, itemId, wh);
        }
        catch (Exception ex)
        {
            new LogClass("stockviewerror").write(ex);
            return "E";
        }
    }

    [WebMethod]
    public static string getMovements(int itemId, string wh, int page)
    {
        try
        {
            int staff = BatchTrace.AuthorizedStaffId(StockView.PageId);
            return staff == 0 ? "{\"count\":0,\"rows\":[],\"uom\":\"\"}" : StockView.Movements(staff, itemId, wh, page);
        }
        catch (Exception ex)
        {
            new LogClass("stockviewerror").write(ex);
            return "E";
        }
    }
}
