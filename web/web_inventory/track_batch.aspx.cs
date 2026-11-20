using commonfunction;
using System;
using System.Collections.Generic;
using System.Web.Services;

// Track Batch: read-only batch listing. All queries live in App_Code\BatchTrace.cs.
public partial class web_inventory_track_batch : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication bill = new LoginAuthentication();
        bill.userAuthentication();
        bill.checkPageAcess(BatchTrace.PageId);
    }

    [WebMethod]
    public static string getItems()
    {
        try
        {
            int staff = BatchTrace.AuthorizedStaffId();
            return staff == 0 ? "[]" : BatchTrace.Items(staff);
        }
        catch (Exception ex)
        {
            new LogClass("trackbatcherror").write(ex);
            return "E";
        }
    }

    [WebMethod]
    public static string searchBatches(int page, Dictionary<string, string> filters, int perpage, string sortBy, string sortDir)
    {
        try
        {
            int staff = BatchTrace.AuthorizedStaffId();
            if (staff == 0)
                return "{\"count\":0,\"rows\":[]}";
            return BatchTrace.Search(staff, page, perpage, filters, sortBy, sortDir);
        }
        catch (Exception ex)
        {
            new LogClass("trackbatcherror").write(ex);
            return "E";
        }
    }
}
