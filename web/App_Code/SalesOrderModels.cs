using System.Collections.Generic;

public class SalesOrderSaveRequest
{
    public SalesOrderMaster master { get; set; }
    public List<SalesOrderItem> items { get; set; }
}

public class SalesOrderMaster
{
    public int? smo_id { get; set; }
    public int? sm_id { get; set; }
    public int? smo_refno { get; set; }
    public int? sm_refno { get; set; }

    public int? cust_id { get; set; }
    public int? branch_id { get; set; }

    public int? smo_userid { get; set; }
    public int? sm_userid { get; set; }
    public string smo_date { get; set; }
    public string sm_date { get; set; }

    public string smo_specialnote { get; set; }
    public string sm_specialnote { get; set; }

    public decimal? smo_sales_sessionid { get; set; }
    public decimal? sm_sales_sessionid { get; set; }

    public string smo_invoice_no { get; set; }
    public string sm_invoice_no { get; set; }

    public decimal? smo_total { get; set; }
    public decimal? sm_total { get; set; }
    public decimal? smo_discount_rate { get; set; }
    public decimal? sm_discount_rate { get; set; }
    public decimal? smo_discount_amount { get; set; }
    public decimal? sm_discount_amount { get; set; }
    public decimal? smo_netamount { get; set; }
    public decimal? sm_netamount { get; set; }

    public int? smo_delivery_status { get; set; }
    public int? sm_delivery_status { get; set; }

    public decimal? smo_latitude { get; set; }
    public decimal? sm_latitude { get; set; }
    public decimal? smo_longitude { get; set; }
    public decimal? sm_longitude { get; set; }

    public int? smo_approved_id { get; set; }
    public int? sm_approved_id { get; set; }
    public int? smo_processed_id { get; set; }
    public int? sm_processed_id { get; set; }
    public int? smo_delivered_id { get; set; }
    public int? sm_delivered_id { get; set; }
    public int? smo_cancelled_id { get; set; }
    public int? sm_cancelled_id { get; set; }

    public string smo_cancelled_date { get; set; }
    public string sm_cancelled_date { get; set; }
    public string smo_processed_date { get; set; }
    public string sm_processed_date { get; set; }
    public string smo_delivered_date { get; set; }
    public string sm_delivered_date { get; set; }
    public string smo_approved_date { get; set; }
    public string sm_approved_date { get; set; }

    public int? smo_packed { get; set; }
    public int? sm_packed { get; set; }
    public int? smo_packed_id { get; set; }
    public int? sm_packed_id { get; set; }
    public string smo_packed_date { get; set; }
    public string sm_packed_date { get; set; }

    public decimal? smo_delivery_latitude { get; set; }
    public decimal? sm_delivery_latitude { get; set; }
    public decimal? smo_delivery_longitude { get; set; }
    public decimal? sm_delivery_longitude { get; set; }

    public int? smo_delivery_vehicle_id { get; set; }
    public int? sm_delivery_vehicle_id { get; set; }
    public string smo_vehicle_no { get; set; }
    public string sm_vehicle_no { get; set; }

    public int? smo_order_type { get; set; }
    public int? sm_order_type { get; set; }
    public int? smo_payment_type { get; set; }
    public int? sm_payment_type { get; set; }

    public decimal? smo_tax_excluded_amt { get; set; }
    public decimal? sm_tax_excluded_amt { get; set; }
    public decimal? smo_tax_amount { get; set; }
    public decimal? sm_tax_amount { get; set; }

    public string branch_tax_method { get; set; }
    public string branch_tax_inclusive { get; set; }

    public string smo_prefix { get; set; }
    public string sm_prefix { get; set; }
    public string smo_serialNo { get; set; }
    public string sm_serialNo { get; set; }
    public string smo_suffix { get; set; }
    public string sm_suffix { get; set; }

    public int? smo_price_class { get; set; }
    public int? sm_price_class { get; set; }
    public int? smo_type { get; set; }
    public int? sm_type { get; set; }

    public string smo_last_updated_date { get; set; }
    public string sm_last_updated_date { get; set; }

    public decimal? smo_roundoff { get; set; }
    public decimal? sm_roundoff { get; set; }
}

public class SalesOrderItem
{
    public int? row_no { get; set; }
    public int? itbs_id { get; set; }
    public int? itm_id { get; set; }
    public string itm_name { get; set; }
    public string sio_itm_name { get; set; }
    public int? itm_type { get; set; }

    public int? tum_id { get; set; }

    public decimal? sio_no_piece { get; set; }
    public decimal? no_piece { get; set; }
    public decimal? sio_length { get; set; }
    public decimal? length { get; set; }
    public decimal? sio_width { get; set; }
    public decimal? width { get; set; }

    public decimal? sio_finalqty { get; set; }
    public decimal? si_qty { get; set; }

    public int? sio_status { get; set; }

    public decimal? sio_org_price { get; set; }
    public decimal? si_org_price { get; set; }

    public decimal? sio_price { get; set; }
    public decimal? si_price { get; set; }

    public decimal? sio_total { get; set; }
    public decimal? si_total { get; set; }

    public decimal? sio_discount_rate { get; set; }
    public decimal? si_discount_rate { get; set; }

    public decimal? sio_discount_amount { get; set; }
    public decimal? si_discount_amount { get; set; }

    public decimal? sio_net_amount { get; set; }
    public decimal? si_net_amount { get; set; }

    public int? sio_foc { get; set; }
    public int? si_foc { get; set; }

    public int? sio_approval_status { get; set; }
    public int? si_approval_status { get; set; }

    public decimal? itm_commision { get; set; }
    public decimal? itm_commisionamt { get; set; }

    public int? ofr_id { get; set; }
    public int? ofritm_id { get; set; }

    public int? sio_itm_type { get; set; }
    public int? si_itm_type { get; set; }

    public decimal? sio_item_tax { get; set; }
    public decimal? si_item_tax { get; set; }

    public decimal? sio_item_cgst { get; set; }
    public decimal? si_item_cgst { get; set; }

    public decimal? sio_item_sgst { get; set; }
    public decimal? si_item_sgst { get; set; }

    public decimal? sio_item_igst { get; set; }
    public decimal? si_item_igst { get; set; }

    public decimal? sio_item_utgst { get; set; }
    public decimal? si_item_utgst { get; set; }

    public decimal? sio_item_cess { get; set; }
    public decimal? si_item_cess { get; set; }

    public decimal? sio_tax_excluded_total { get; set; }
    public decimal? si_tax_excluded_total { get; set; }

    public decimal? sio_tax_amount { get; set; }
    public decimal? si_tax_amount { get; set; }
}
