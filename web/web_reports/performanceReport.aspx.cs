using commonfunction;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class web_reports_performanceReport : System.Web.UI.Page
{
  
    protected void Page_Load(object sender, EventArgs e)
    {
        loadWarehouse();
    }

    /// <summary>
    /// method for load warehouse
    /// </summary>
    public void loadWarehouse()
    {
        mySqlConnection db = new mySqlConnection();
        //load suppliers
        DataTable vendorDt = db.SelectQuery("select branch_id,branch_name from tbl_branch");
        selWarehouse.Items.Add(new ListItem("SELECT WAREHOUSE", "-1"));
        foreach (DataRow vendorRow in vendorDt.Rows)
        {
            selWarehouse.Items.Add(new ListItem(vendorRow["branch_name"].ToString(), vendorRow["branch_id"].ToString()));
        }

    }

    #region
    //webmethod for showing stock transcations based on search fields 
    #endregion
    [WebMethod]
    public static string showPerformance(int page, int perpage, Dictionary<string, string> filters)
    {
        mySqlConnection db = new mySqlConnection();
        string countQry = "";
        string qry_condition = " where 1=1 AND tsm.sm_delivery_status NOT IN (4,5) AND tsm.sm_invoice_no IS NOT NULL ";
        string innerqry = "";
        string summerQry = "";
        if (filters.Count > 0)
        {
            
            if (filters.ContainsKey("from_date"))
            {
                qry_condition += " and date(tsm.sm_processed_date)>=STR_TO_DATE('" + filters["from_date"].Replace("-", "/") + "','%d/%m/%Y')";
            }

            if (filters.ContainsKey("to_date"))
            {
                qry_condition += " and date(tsm.sm_processed_date)<=STR_TO_DATE('" + filters["to_date"].Replace("-", "/") + "','%d/%m/%Y')";
            }
            if (filters.ContainsKey("warehouse"))
            {
                qry_condition += " and tsm.branch_id=" + filters["warehouse"] + "";
            }
        

        }
        int per_page = perpage;
        int offset = (page - 1) * per_page;
        if (filters["searchType"] == "1")
        {
            countQry = @"select date(tsm.sm_processed_date) from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id " + qry_condition + " group by cast(tsm.sm_processed_date as DATE)";
        }
        else if (filters["searchType"] == "2")
        {
            countQry = @"select concat(tud.first_name,' ',tud.last_name) from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id inner join 
tbl_user_details tud on tud.user_id=tsm.sm_userid " + qry_condition + " group by tsm.sm_userid";
        }
        else if (filters["searchType"] == "3")
        {
            countQry = @"select tsi.itm_name from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id " + qry_condition + " group by tsi.itbs_id";
        }
        else if (filters["searchType"] == "4")
        {
            countQry = @"select tb.brand_name from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id inner join 
tbl_item_brand tb on tb.brand_id=tib.itm_brand_id " + qry_condition + " group by tib.itm_brand_id";
        }
        DataTable dtcount, dt,sumDt = new DataTable();
        dtcount = db.SelectQuery(countQry);
        double numrows = dtcount.Rows.Count;
        if (numrows == 0)
        {
            return "{\"count\":\"" + numrows + "\",\"data\":[]}"; ;
        }

        if (filters["searchType"] == "1")
        {
            innerqry = @"select DATE_FORMAT(tsm.sm_processed_date,'%d-%b-%Y') as Particulars,
sum(tsi.si_qty)as qty,
sum(tsi.si_total) as Amount,
sum(tsi.si_discount_amount) as Discount,sum(tsi.si_net_amount) as NetAmount,
sum(tsi.si_tax_amount) as TaxAmount,(sum(tsi.si_qty * tib.itbs_purchase_price)) as Cost,
(sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price)))) as profit,
((sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price))))/(sum(tsi.si_qty*tib.itbs_purchase_price)))*100 as profitperc 
from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id " + qry_condition + " group by cast(tsm.sm_processed_date as DATE) LIMIT " + offset.ToString() + " ," + per_page;

            summerQry = @"select IFNULL(sum(inner_res.qty),0) as totalQty,
IFNULL(sum(inner_res.Amount),0) as totalAmount,
IFNULL(sum(inner_res.Discount),0) as totalDiscount,
IFNULL(sum(inner_res.TaxAmount),0) as totalTaxAmount,
IFNULL(sum(inner_res.NetAmount),0) as totalNetAmount,
IFNULL(sum(inner_res.Cost),0) as totalCost,
IFNULL(sum(inner_res.profit),0) as totalprofit
 from(select sum(tsi.si_qty)as qty,sum(tsi.si_total) as Amount,
sum(tsi.si_discount_amount) as Discount,sum(tsi.si_net_amount) as NetAmount,
sum(tsi.si_tax_amount) as TaxAmount,(sum(tsi.si_qty * tib.itbs_purchase_price)) as Cost,
(sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price)))) as profit,
((sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price))))/(sum(tsi.si_qty*tib.itbs_purchase_price)))*100 as profitperc 
from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id " + qry_condition + " group by cast(tsm.sm_processed_date as DATE))as inner_res";
        }
        else if (filters["searchType"] == "2")
        {
            innerqry = @"select concat(tud.first_name,' ',tud.last_name) as Particulars,sum(tsi.si_qty)as qty,
sum(tsi.si_total) as Amount,
sum(tsi.si_discount_amount) as Discount,sum(tsi.si_net_amount) as NetAmount,
sum(tsi.si_tax_amount) as TaxAmount,(sum(tsi.si_qty * tib.itbs_purchase_price)) as Cost,
(sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price)))) as profit,
((sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price))))/(sum(tsi.si_qty*tib.itbs_purchase_price)))*100 as profitperc 
from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id inner join 
tbl_user_details tud on tud.user_id=tsm.sm_userid " + qry_condition + " group by tsm.sm_userid LIMIT " + offset.ToString() + " ," + per_page;

            summerQry = @"select IFNULL(sum(inner_res.qty),0) as totalQty,
IFNULL(sum(inner_res.Amount),0) as totalAmount,
IFNULL(sum(inner_res.Discount),0) as totalDiscount,
IFNULL(sum(inner_res.TaxAmount),0) as totalTaxAmount,
IFNULL(sum(inner_res.NetAmount),0) as totalNetAmount,
IFNULL(sum(inner_res.Cost),0) as totalCost,
IFNULL(sum(inner_res.profit),0) as totalprofit
 from(select sum(tsi.si_qty)as qty,
sum(tsi.si_total) as Amount,
sum(tsi.si_discount_amount) as Discount,sum(tsi.si_net_amount) as NetAmount,
sum(tsi.si_tax_amount) as TaxAmount,(sum(tsi.si_qty * tib.itbs_purchase_price)) as Cost,
(sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price)))) as profit,
((sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price))))/(sum(tsi.si_qty*tib.itbs_purchase_price)))*100 as profitperc 
from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id inner join 
tbl_user_details tud on tud.user_id=tsm.sm_userid " + qry_condition + " group by tsm.sm_userid)as inner_res";
        }
        else if (filters["searchType"] == "3")
        {
            innerqry = @"select  tsi.itm_name as Particulars,sum(tsi.si_qty)as qty,
sum(tsi.si_total) as Amount,
sum(tsi.si_discount_amount) as Discount,sum(tsi.si_net_amount) as NetAmount,
sum(tsi.si_tax_amount) as TaxAmount,(sum(tsi.si_qty * tib.itbs_purchase_price)) as Cost,
(sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price)))) as profit,
((sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price))))/(sum(tsi.si_qty*tib.itbs_purchase_price)))*100 as profitperc 
from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id " + qry_condition + " group by tsi.itbs_id LIMIT " + offset.ToString() + " ," + per_page;
            summerQry = @"select IFNULL(sum(inner_res.qty),0) as totalQty,
IFNULL(sum(inner_res.Amount),0) as totalAmount,
IFNULL(sum(inner_res.Discount),0) as totalDiscount,
IFNULL(sum(inner_res.TaxAmount),0) as totalTaxAmount,
IFNULL(sum(inner_res.NetAmount),0) as totalNetAmount,
IFNULL(sum(inner_res.Cost),0) as totalCost,
IFNULL(sum(inner_res.profit),0) as totalprofit
 from(select sum(tsi.si_qty)as qty,
sum(tsi.si_total) as Amount,
sum(tsi.si_discount_amount) as Discount,sum(tsi.si_net_amount) as NetAmount,
sum(tsi.si_tax_amount) as TaxAmount,(sum(tsi.si_qty * tib.itbs_purchase_price)) as Cost,
(sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price)))) as profit,
((sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price))))/(sum(tsi.si_qty*tib.itbs_purchase_price)))*100 as profitperc 
from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id " + qry_condition + " group by tsi.itbs_id )as inner_res";
        }
        else if (filters["searchType"] == "4")
        {
            innerqry = @"select tb.brand_name as Particulars,sum(tsi.si_qty)as qty,
sum(tsi.si_total) as Amount,
sum(tsi.si_discount_amount) as Discount,sum(tsi.si_net_amount) as NetAmount,
sum(tsi.si_tax_amount) as TaxAmount,(sum(tsi.si_qty * tib.itbs_purchase_price)) as Cost,
(sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price)))) as profit,
((sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price))))/(sum(tsi.si_qty*tib.itbs_purchase_price)))*100 as profitperc 
from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id 
inner join 
tbl_item_brand tb on tb.brand_id=tib.itm_brand_id " + qry_condition + " group by tib.itm_brand_id LIMIT " + offset.ToString() + " ," + per_page;

            summerQry = @"select IFNULL(sum(inner_res.qty),0) as totalQty,
IFNULL(sum(inner_res.Amount),0) as totalAmount,
IFNULL(sum(inner_res.Discount),0) as totalDiscount,
IFNULL(sum(inner_res.TaxAmount),0) as totalTaxAmount,
IFNULL(sum(inner_res.NetAmount),0) as totalNetAmount,
IFNULL(sum(inner_res.Cost),0) as totalCost,
IFNULL(sum(inner_res.profit),0) as totalprofit
 from(select sum(tsi.si_qty)as qty,
sum(tsi.si_total) as Amount,
sum(tsi.si_discount_amount) as Discount,sum(tsi.si_net_amount) as NetAmount,
sum(tsi.si_tax_amount) as TaxAmount,(sum(tsi.si_qty * tib.itbs_purchase_price)) as Cost,
(sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price)))) as profit,
((sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price))))/(sum(tsi.si_qty*tib.itbs_purchase_price)))*100 as profitperc 
from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id 
inner join 
tbl_item_brand tb on tb.brand_id=tib.itm_brand_id " + qry_condition + " group by tib.itm_brand_id )as inner_res";
        }

        string jsonResponse = "";
        dt = db.SelectQuery(innerqry);
        sumDt = db.SelectQuery(summerQry);
        if (dt.Rows.Count > 0)
        {
           
            string jsonData = JsonConvert.SerializeObject(dt, Formatting.Indented);
            string jsonsumData = JsonConvert.SerializeObject(sumDt, Formatting.Indented);
            jsonResponse = "{\"count\":\"" + numrows + "\",\"data\":" + jsonData + ",\"summaryData\":" + jsonsumData + "}";
        }
        else
        {
            jsonResponse = "N";
        }

        return jsonResponse;
    }//end

    #region
    //webmethod for showing stock transcations based on search fields 
    #endregion
    [WebMethod]
    public static string DownloadReport(Dictionary<string, string> filters)
    {
        mySqlConnection db = new mySqlConnection();
        string countQry = "";
        string qry_condition = " where 1=1 AND tsm.sm_delivery_status NOT IN (4,5) AND tsm.sm_invoice_no IS NOT NULL ";
        string innerqry = "";
        string summerQry = "";
        int totalQty = 0;
        double totalAmount = 0.00;
        double totalDiscount = 0.00;
        double totalTaxAmount = 0.00;
        double totalCost = 0.00;
        double totalprofit = 0.00;
        double totalNetamount = 0.00;

        if (filters.Count > 0)
        {

            if (filters.ContainsKey("from_date"))
            {
                qry_condition += " and date(tsm.sm_processed_date)>=STR_TO_DATE('" + filters["from_date"].Replace("-", "/") + "','%d/%m/%Y')";
            }

            if (filters.ContainsKey("to_date"))
            {
                qry_condition += " and date(tsm.sm_processed_date)<=STR_TO_DATE('" + filters["to_date"].Replace("-", "/") + "','%d/%m/%Y')";
            }
            if (filters.ContainsKey("warehouse"))
            {
                qry_condition += " and tsm.branch_id=" + filters["warehouse"] + "";
            }


        }

        if (filters["searchType"] == "1")
        {
            countQry = @"select date(tsm.sm_processed_date) from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id " + qry_condition + " group by cast(tsm.sm_processed_date as DATE)";
        }
        else if (filters["searchType"] == "2")
        {
            countQry = @"select concat(tud.first_name,' ',tud.last_name) from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id inner join 
tbl_user_details tud on tud.user_id=tsm.sm_userid " + qry_condition + " group by tsm.sm_userid";
        }
        else if (filters["searchType"] == "3")
        {
            countQry = @"select tsi.itm_name from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id " + qry_condition + " group by tsi.itbs_id";
        }
        else if (filters["searchType"] == "4")
        {
            countQry = @"select tb.brand_name from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id inner join 
tbl_item_brand tb on tb.brand_id=tib.itm_brand_id " + qry_condition + " group by tib.itm_brand_id";
        }
        DataTable dtcount, dt, sumDt = new DataTable();
        dtcount = db.SelectQuery(countQry);
        double numrows = dtcount.Rows.Count;
        if (numrows == 0)
        {
            return "{\"count\":\"" + numrows + "\",\"data\":[]}"; ;
        }

        if (filters["searchType"] == "1")
        {
            innerqry = @"select DATE_FORMAT(tsm.sm_processed_date,'%d-%b-%Y') as Particulars,
sum(tsi.si_qty)as qty,
sum(tsi.si_total) as Amount,
sum(tsi.si_discount_amount) as Discount,sum(tsi.si_net_amount) as NetAmount,
sum(tsi.si_tax_amount) as TaxAmount,(sum(tsi.si_qty * tib.itbs_purchase_price)) as Cost,
(sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price)))) as profit,
((sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price))))/(sum(tsi.si_qty*tib.itbs_purchase_price)))*100 as profitperc 
from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id " + qry_condition + " group by cast(tsm.sm_processed_date as DATE) ";

            summerQry = @"select IFNULL(sum(inner_res.qty),0) as totalQty,
IFNULL(sum(inner_res.Amount),0) as totalAmount,
IFNULL(sum(inner_res.Discount),0) as totalDiscount,
IFNULL(sum(inner_res.TaxAmount),0) as totalTaxAmount,
IFNULL(sum(inner_res.NetAmount),0) as totalNetAmount,
IFNULL(sum(inner_res.Cost),0) as totalCost,
IFNULL(sum(inner_res.profit),0) as totalprofit
 from(select sum(tsi.si_qty)as qty,sum(tsi.si_total) as Amount,
sum(tsi.si_discount_amount) as Discount,sum(tsi.si_net_amount) as NetAmount,
sum(tsi.si_tax_amount) as TaxAmount,(sum(tsi.si_qty * tib.itbs_purchase_price)) as Cost,
(sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price)))) as profit,
((sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price))))/(sum(tsi.si_qty*tib.itbs_purchase_price)))*100 as profitperc 
from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id " + qry_condition + " group by cast(tsm.sm_processed_date as DATE))as inner_res";
        }
        else if (filters["searchType"] == "2")
        {
            innerqry = @"select concat(tud.first_name,' ',tud.last_name) as Particulars,sum(tsi.si_qty)as qty,
sum(tsi.si_total) as Amount,
sum(tsi.si_discount_amount) as Discount,sum(tsi.si_net_amount) as NetAmount,
sum(tsi.si_tax_amount) as TaxAmount,(sum(tsi.si_qty * tib.itbs_purchase_price)) as Cost,
(sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price)))) as profit,
((sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price))))/(sum(tsi.si_qty*tib.itbs_purchase_price)))*100 as profitperc 
from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id inner join 
tbl_user_details tud on tud.user_id=tsm.sm_userid " + qry_condition + " group by tsm.sm_userid ";

            summerQry = @"select IFNULL(sum(inner_res.qty),0) as totalQty,
IFNULL(sum(inner_res.Amount),0) as totalAmount,
IFNULL(sum(inner_res.Discount),0) as totalDiscount,
IFNULL(sum(inner_res.TaxAmount),0) as totalTaxAmount,
IFNULL(sum(inner_res.NetAmount),0) as totalNetAmount,
IFNULL(sum(inner_res.Cost),0) as totalCost,
IFNULL(sum(inner_res.profit),0) as totalprofit
 from(select sum(tsi.si_qty)as qty,
sum(tsi.si_total) as Amount,
sum(tsi.si_discount_amount) as Discount,sum(tsi.si_net_amount) as NetAmount,
sum(tsi.si_tax_amount) as TaxAmount,(sum(tsi.si_qty * tib.itbs_purchase_price)) as Cost,
(sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price)))) as profit,
((sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price))))/(sum(tsi.si_qty*tib.itbs_purchase_price)))*100 as profitperc 
from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id inner join 
tbl_user_details tud on tud.user_id=tsm.sm_userid " + qry_condition + " group by tsm.sm_userid)as inner_res";
        }
        else if (filters["searchType"] == "3")
        {
            innerqry = @"select  tsi.itm_name as Particulars,sum(tsi.si_qty)as qty,
sum(tsi.si_total) as Amount,
sum(tsi.si_discount_amount) as Discount,sum(tsi.si_net_amount) as NetAmount,
sum(tsi.si_tax_amount) as TaxAmount,(sum(tsi.si_qty * tib.itbs_purchase_price)) as Cost,
(sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price)))) as profit,
((sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price))))/(sum(tsi.si_qty*tib.itbs_purchase_price)))*100 as profitperc 
from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id " + qry_condition + " group by tsi.itbs_id ";
            summerQry = @"select IFNULL(sum(inner_res.qty),0) as totalQty,
IFNULL(sum(inner_res.Amount),0) as totalAmount,
IFNULL(sum(inner_res.Discount),0) as totalDiscount,
IFNULL(sum(inner_res.TaxAmount),0) as totalTaxAmount,
IFNULL(sum(inner_res.NetAmount),0) as totalNetAmount,
IFNULL(sum(inner_res.Cost),0) as totalCost,
IFNULL(sum(inner_res.profit),0) as totalprofit
 from(select sum(tsi.si_qty)as qty,
sum(tsi.si_total) as Amount,
sum(tsi.si_discount_amount) as Discount,sum(tsi.si_net_amount) as NetAmount,
sum(tsi.si_tax_amount) as TaxAmount,(sum(tsi.si_qty * tib.itbs_purchase_price)) as Cost,
(sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price)))) as profit,
((sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price))))/(sum(tsi.si_qty*tib.itbs_purchase_price)))*100 as profitperc 
from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id " + qry_condition + " group by tsi.itbs_id )as inner_res";
        }
        else if (filters["searchType"] == "4")
        {
            innerqry = @"select tb.brand_name as Particulars,sum(tsi.si_qty)as qty,
sum(tsi.si_total) as Amount,
sum(tsi.si_discount_amount) as Discount,sum(tsi.si_net_amount) as NetAmount,
sum(tsi.si_tax_amount) as TaxAmount,(sum(tsi.si_qty * tib.itbs_purchase_price)) as Cost,
(sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price)))) as profit,
((sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price))))/(sum(tsi.si_qty*tib.itbs_purchase_price)))*100 as profitperc 
from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id 
inner join 
tbl_item_brand tb on tb.brand_id=tib.itm_brand_id " + qry_condition + " group by tib.itm_brand_id ";

            summerQry = @"select IFNULL(sum(inner_res.qty),0) as totalQty,
IFNULL(sum(inner_res.Amount),0) as totalAmount,
IFNULL(sum(inner_res.Discount),0) as totalDiscount,
IFNULL(sum(inner_res.TaxAmount),0) as totalTaxAmount,
IFNULL(sum(inner_res.NetAmount),0) as totalNetAmount,
IFNULL(sum(inner_res.Cost),0) as totalCost,
IFNULL(sum(inner_res.profit),0) as totalprofit
 from(select sum(tsi.si_qty)as qty,
sum(tsi.si_total) as Amount,
sum(tsi.si_discount_amount) as Discount,sum(tsi.si_net_amount) as NetAmount,
sum(tsi.si_tax_amount) as TaxAmount,(sum(tsi.si_qty * tib.itbs_purchase_price)) as Cost,
(sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price)))) as profit,
((sum(tsi.si_net_amount)-((sum(tsi.si_qty*tib.itbs_purchase_price))))/(sum(tsi.si_qty*tib.itbs_purchase_price)))*100 as profitperc 
from tbl_sales_master tsm inner join tbl_sales_items tsi on tsi.sm_id=tsm.sm_id
inner join tbl_itembranch_stock tib on tib.itbs_id=tsi.itbs_id 
inner join 
tbl_item_brand tb on tb.brand_id=tib.itm_brand_id " + qry_condition + " group by tib.itm_brand_id )as inner_res";
        }

        string jsonResponse = "";
        dt = db.SelectQuery(innerqry);
        sumDt = db.SelectQuery(summerQry);
        if (dt.Rows.Count > 0)
        {
            if (sumDt.Rows.Count > 0)
            {
                totalQty = Convert.ToInt32(sumDt.Rows[0]["totalQty"]);
                totalAmount = Convert.ToDouble(sumDt.Rows[0]["totalAmount"]);
                totalDiscount = Convert.ToDouble(sumDt.Rows[0]["totalDiscount"]);
                totalNetamount = Convert.ToDouble(sumDt.Rows[0]["totalNetAmount"]);
                totalTaxAmount = Convert.ToDouble(sumDt.Rows[0]["totalTaxAmount"]);
                totalCost = Convert.ToDouble(sumDt.Rows[0]["totalCost"]);
                totalprofit = Convert.ToDouble(sumDt.Rows[0]["totalprofit"]);
            }

            HttpContext.Current.Session["rp_fieldvalues"] = totalQty + "*" + totalAmount + "*" + totalDiscount + "*" + "*" + totalNetamount + "*" + totalTaxAmount + "*" + totalCost + "*" + totalprofit;
            HttpContext.Current.Session["downloadqry"] = innerqry;
            jsonResponse = "Y";
        }
        else
        {
            jsonResponse = "N";
        }

        return jsonResponse;
    }//end
}