using commonfunction;
using System;
using System.Collections.Generic;
using System.Web.Services;

// Stock View: read-only, item-level stock overview. All queries live in App_Code\StockView.cs.
public partial class web_inventory_stock_view : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication bill = new LoginAuthentication();
        bill.userAuthentication();
        bill.checkPageAcess(StockView.PageId);
    }

    [WebMethod]
    public static string getOptions()
    {
        try
        {
            int staff = BatchTrace.AuthorizedStaffId(StockView.PageId);
            return staff == 0 ? "{\"warehouses\":[],\"groups\":[],\"brands\":[]}" : StockView.Options(staff);
        }
        catch (Exception ex)
        {
            new LogClass("stockviewerror").write(ex);
            return "E";
        }
    }

    [WebMethod]
    public static string searchStock(int page, Dictionary<string, string> filters, int perpage, string sortBy, string sortDir)
    {
        try
        {
            int staff = BatchTrace.AuthorizedStaffId(StockView.PageId);
            if (staff == 0)
                return "{\"count\":0,\"rows\":[],\"summary\":{\"items\":0,\"phys\":0,\"resv\":0,\"free\":0,\"pend\":0,\"shortage\":0}}";
            return StockView.Search(staff, page, perpage, filters, sortBy, sortDir);
        }
        catch (Exception ex)
        {
            new LogClass("stockviewerror").write(ex);
            return "E";
        }
    }
}
