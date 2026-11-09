using commonfunction;
using System;
using System.Collections.Generic;
using System.Web.Services;

public partial class web_production_bulk_production : System.Web.UI.Page
{
    protected bool CanProduce;

    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication bill = new LoginAuthentication();
        bill.userAuthentication();
        bill.checkPageAcess(7);
        CanProduce = !ProductionPageService.IsSalesman();
    }

    [WebMethod]
    public static string getBranches()
    {
        return ProductionPageService.GetBranches();
    }

    [WebMethod]
    public static string searchGroups(Dictionary<string, string> filters)
    {
        return ProductionPageService.SearchBulkGroups(filters);
    }

    [WebMethod]
    public static ProductionSaveResult ProduceLine(int smoId, int sioId, decimal expectedPending)
    {
        return ProductionPageService.ProduceLine(smoId, sioId, expectedPending);
    }
}
