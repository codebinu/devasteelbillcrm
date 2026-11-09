using commonfunction;
using System;
using System.Collections.Generic;
using System.Web.Services;

public partial class web_production_start_production : System.Web.UI.Page
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
    public static string getStaff()
    {
        return ProductionPageService.GetStaff();
    }

    [WebMethod]
    public static string searchItems(int page, Dictionary<string, string> filters, int perpage)
    {
        return ProductionPageService.SearchItemsToProduce(page, filters, perpage);
    }

    [WebMethod]
    public static ProductionEntryOptions LoadProductionEntry(int smoId, int sioId)
    {
        return ProductionPageService.LoadEntry(smoId, sioId);
    }

    [WebMethod]
    public static ProductionSaveResult SaveProduction(int smoId, int sioId, int reservationId, decimal expectedOutput)
    {
        return ProductionPageService.Save(smoId, sioId, reservationId, expectedOutput);
    }

    [WebMethod]
    public static StockActionResult ReserveItem(int smoId, int sioId, decimal expectedQty, int compItmId)
    {
        return ProductionPageService.Reserve(smoId, sioId, expectedQty, compItmId);
    }

    [WebMethod]
    public static StockActionResult ReserveBatches(int smoId, int sioId, int compItmId, List<BatchQty> allocations)
    {
        return ProductionPageService.ReserveBatches(smoId, sioId, compItmId, allocations);
    }

    [WebMethod]
    public static ReserveOptionsResult LoadReserveOptions(int smoId, int sioId, int compItmId)
    {
        return ProductionPageService.LoadReserveOptions(smoId, sioId, compItmId);
    }

    [WebMethod]
    public static StockActionResult UnreserveItem(int smoId, int sioId, int compItmId)
    {
        return ProductionPageService.Unreserve(smoId, sioId, compItmId);
    }

    [WebMethod]
    public static StockActionResult UnreserveBatch(int smoId, int sioId, int batchId)
    {
        return ProductionPageService.UnreserveBatch(smoId, sioId, batchId);
    }
}
