using System.Collections.Generic;
using Newtonsoft.Json;

public class PurchasePayment
{
    public decimal? paid_amount { get; set; }
    public decimal? cash_amount { get; set; }
    public decimal? cheque_amount { get; set; }
    public string cheque_no { get; set; }
    public string cheque_date { get; set; }
    public string cheque_bank { get; set; }
}

public class PurchaseFilters
{
    public int? pm_id { get; set; }
    public string pm_ref_no { get; set; }
    public string invoiceno { get; set; }
    public string vendorId { get; set; }
    public string userid { get; set; }
    public string purchasedate { get; set; }
    public string note { get; set; }
    public string warehouse { get; set; }
    public int? pm_status { get; set; }
    public string pm_cancelled_date { get; set; }
    public string branch_tax_method { get; set; }
    public string branch_tax_inclusive { get; set; }
    public string pm_sessionid { get; set; }
    public PurchasePayment payment { get; set; }
}

public class PurchaseItem
{
    public int? row_no { get; set; }
    public int? itm_id { get; set; }
    public string itm_code { get; set; }
    public string itm_name { get; set; }
    public decimal? pi_org_price { get; set; }
    public decimal? pi_price { get; set; }
    public decimal? pi_qty { get; set; }
    public decimal? pi_discount_rate { get; set; }
    public decimal? pi_item_tax { get; set; }
    public decimal? pi_item_cess { get; set; }
    public decimal? pi_carton_count { get; set; }
    public decimal? pi_item_per_carton { get; set; }
    public string itbh_custbatchid { get; set; }
    public int? tum_id { get; set; }
    public decimal? itbh_no_piece { get; set; }
    public decimal? itbh_length { get; set; }
    public decimal? itbh_width { get; set; }
    public decimal? itbh_kg { get; set; }
    public decimal? itbh_kgmeter { get; set; }
    public decimal? itbh_sqmt { get; set; }
    public int? itbh_status { get; set; }
    public decimal? itbh_cost { get; set; }
    public decimal? itbh_costwithinvoice { get; set; }
    public decimal? itbh_costwithoutinvoice { get; set; }
    public decimal? itbh_costotal { get; set; }
    public string itbh_createddate { get; set; }
    public string itbh_createduser { get; set; }
}

public class PurchaseSaveRequest
{
    public PurchaseFilters purchase_filters { get; set; }
    public List<PurchaseItem> purchase_items { get; set; }
    public string time_zone { get; set; }
}
