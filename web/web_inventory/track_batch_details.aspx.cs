using commonfunction;
using System;
using System.Web.Services;

// Track Batch: read-only batch traceability details. All queries live in App_Code\BatchTrace.cs.
public partial class web_inventory_track_batch_details : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication bill = new LoginAuthentication();
        bill.userAuthentication();
        bill.checkPageAcess(BatchTrace.PageId);
    }

    [WebMethod]
    public static string getOverview(int batchId)
    {
        try
        {
            int staff = BatchTrace.AuthorizedStaffId();
            return staff == 0 ? "{\"notFound\":true}" : BatchTrace.Overview(staff, batchId);
        }
        catch (Exception ex)
        {
            new LogClass("trackbatcherror").write(ex);
            return "E";
        }
    }

    [WebMethod]
    public static string getHistory(int batchId)
    {
        try
        {
            int staff = BatchTrace.AuthorizedStaffId();
            return staff == 0 ? "{\"notFound\":true}" : BatchTrace.History(staff, batchId);
        }
        catch (Exception ex)
        {
            new LogClass("trackbatcherror").write(ex);
            return "E";
        }
    }
}
