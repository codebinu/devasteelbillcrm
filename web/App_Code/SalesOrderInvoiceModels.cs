using commonfunction;
using System.Collections.Generic;

// Links an invoice created by neworder.aspx.cs SaveInvoice to its sales order: SmoId is written to tbl_sales_master.sm_refid and
// SioIds[i] to tbl_sales_items.sio_id of the i-th invoice item.
public class SalesOrderInvoiceLink
{
    public int SmoId;
    public List<int> SioIds = new List<int>();
}

// The shared invoice saver (neworder.aspx.cs SaveInvoice). Returns the new sm_id as text; completed is false when it rolled back.
public delegate string SalesInvoiceSaver(mySqlConnection db, Dictionary<string, string> neworder, SalesOrderInvoiceLink link, out bool completed);

public class SalesOrderInvoiceRequest
{
    public int smoId { get; set; }
    public string sessionId { get; set; }
    public int paymentMode { get; set; }
    public decimal cashAmount { get; set; }
    public decimal chequeAmount { get; set; }
    public string chequeNo { get; set; }
    public string chequeDate { get; set; }
    public string chequeBank { get; set; }
    public string note { get; set; }
    public List<SalesOrderInvoiceLineRequest> lines { get; set; }
}

public class SalesOrderInvoiceLineRequest
{
    public int sioId { get; set; }
    public decimal qty { get; set; }
}

public class SalesOrderInvoiceResult
{
    public bool ok;
    public string message;
    public int invoiceId;
    public int taxMethod;
}

// One sales order line as shown on sales_order_invoice.aspx. Quantities are in the order line's UOM, the same unit as tbl_sales_items.si_qty.
public class SalesOrderInvoiceLine
{
    public int SioId, RowNo, ItmId, ItbsId;
    public string Name, Code, Uom;
    public decimal Ordered, Invoiced, Remaining, Reserved;
    public decimal Price, OrgPrice, DiscountRate, TaxPercent, CessPercent;
    public decimal MaxQty, InvoiceableQty;
    public bool IsProduct;
    public string Issue;
}

public class SalesOrderInvoiceHeader
{
    public int SmoId, BranchId, CustId, Status, TaxMethod, TaxInclusive;
    public string OrderNo, OrderDate, CustomerName, Phone, Phone2, Email, Address, City, TaxRegId, BranchName, StatusText, StatusCss;
    public decimal AccountBalance, CreditAmount, CreditPeriod;
}

public class SalesOrderInvoicePage
{
    public SalesOrderInvoiceHeader Header;
    public List<SalesOrderInvoiceLine> Lines = new List<SalesOrderInvoiceLine>();
    public string Message;
    public bool CanInvoice;
}

public class SalesOrderInvoiceRow
{
    public int SmId, ItemCount, Status, TaxMethod;
    public string InvoiceNo, Date, Customer, StatusText, StatusCss, PaymentText, PaymentCss;
    public decimal Amount, Paid;
}
