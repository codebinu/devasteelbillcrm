using commonfunction;
using System;
using System.Collections.Generic;
using System.Web.Services;

public partial class web_production_production_history : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication bill = new LoginAuthentication();
        bill.userAuthentication();
        bill.checkPageAcess(7);
    }

    [WebMethod]
    public static string getBranches()
    {
        return ProductionPageService.GetBranches();
    }

    [WebMethod]
    public static string getStaff()
    {
        return ProductionPageService.GetStaff();
    }

    [WebMethod]
    public static string searchHistory(int page, Dictionary<string, string> filters, int perpage)
    {
        return ProductionPageService.SearchHistory(page, filters, perpage);
    }

    [WebMethod]
    public static ProductionJobDetail LoadProductionJob(int smoId, int itpmId)
    {
        return ProductionPageService.LoadJob(smoId, itpmId);
    }
}
