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
public partial class web_reports_CustomeritemsOverView : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {

    }



    [WebMethod]// start warehouse showing
    public static string showBranches(string userid)
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        StringBuilder sb = new StringBuilder();
        //string query = "SELECT tbl_branch.branch_id,tbl_branch.branch_name,tbl_branch.branch_countryid,tbl_branch.branch_timezone FROM tbl_branch INNER JOIN tbl_user_branches ON tbl_branch.branch_id = tbl_user_branches.branch_id WHERE tbl_user_branches.user_id='" + userid + "' and tbl_user_branches.status='1' ";
        //query = query + " order by tbl_branch.branch_id";
        //dt = db.SelectQuery(query);
        string query = "SELECT branch_id,branch_name FROM tbl_branch";
        query = query + " order by branch_id";
        dt = db.SelectQuery(query);
        return JsonConvert.SerializeObject(dt, Formatting.Indented);
    }// end warehouse show

    // show item brands

    [WebMethod]
    public static string ShowItemBrands()
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        StringBuilder sb = new StringBuilder();
        string query = "SELECT brand_id,brand_name FROM tbl_item_brand order by brand_id ";
        dt = db.SelectQuery(query);
        return JsonConvert.SerializeObject(dt, Formatting.Indented);
    }//end show itemname

    // Show Category 
    [WebMethod]
    public static string ShowItemCategry()
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        StringBuilder sb = new StringBuilder();
        string query = "SELECT cat_id,cat_name FROM tbl_item_category order by cat_id ";
        dt = db.SelectQuery(query);
        return JsonConvert.SerializeObject(dt, Formatting.Indented);
    }// end category






    [WebMethod]
    public static string showItemOverView(int page, int perpage, Dictionary<string, string> filters)
    {

        mySqlConnection db = new mySqlConnection();
        StringBuilder sb = new StringBuilder();
        string qry_condition = " where 1=1";
        string status_qry = "";

        if (filters.Count > 0)
        {

            if (filters.ContainsKey("brand"))
            {
                qry_condition += " and tbl_itembranch_stock.itm_brand_id='" + filters["brand"] + "'";
            }
            if (filters.ContainsKey("category"))
            {
                qry_condition += " and tbl_itembranch_stock.itm_category_id='" + filters["category"] + "'";
            }
            if (filters.ContainsKey("warehouse"))
            {
                if (filters["warehouse"] == "0")
                {
                    qry_condition += " and (tbl_sales_master.branch_id IN(select branch_id from tbl_user_branches where user_id=" + HttpContext.Current.Request.Cookies["invntrystaffId"].Value + "))";
                }
                else
                {
                    qry_condition += " and tbl_sales_master.branch_id ='" + filters["warehouse"] + "'";
                }

            }
            if (filters.ContainsKey("searchItem"))
            {
                qry_condition += " and (tsi.itm_code like '%" + filters["searchItem"] + "%' or tsi.itm_name like '%" + filters["searchItem"] + "%')";
            }

            if (filters.ContainsKey("from_date"))
            {
                qry_condition += " and date(sm_date)>=STR_TO_DATE('" + filters["from_date"].Replace("-", "/") + "','%d/%m/%Y')";
            }
            if (filters.ContainsKey("to_date"))
            {
                qry_condition += " and date(sm_date)<=STR_TO_DATE('" + filters["to_date"].Replace("-", "/") + "','%d/%m/%Y')";
            }

        }

        int per_page = perpage;
        int offset = (page - 1) * per_page;
        //string stockCountQuery = @"SELECT count(*) FROM tbl_itembranch_stock itbs " + qry_condition;
        //double numrows = Convert.ToInt32(db.SelectScalar(stockCountQuery));
        //if (numrows == 0)
        //{
        //    return "N"; ;
        //}

        string stockCountQuery = @" SELECT tsi.itm_name AS Item_Name,tsi.itm_code, sum(tsi.si_org_price * tsi.si_qty) AS originalCost, SUM( tsi.si_net_amount ) AS billNetamount,
 SUM( tsi.si_qty ) AS totalQty,(sum(tsi.si_org_price * tsi.si_qty)-SUM( tsi.si_net_amount )) as totaldiff
 FROM tbl_sales_items tsi 
 INNER JOIN tbl_sales_master ON tsi.sm_id = tbl_sales_master.sm_id 
 INNER JOIN tbl_itembranch_stock ON tsi.itbs_id = tbl_itembranch_stock.itbs_id 
 INNER JOIN tbl_customer tcu ON tcu.cust_id = tbl_sales_master.cust_id
 INNER JOIN tbl_location tlo ON tlo.location_id = tcu.location_id
 INNER JOIN tbl_user_details tu ON tu.user_id = tbl_sales_master.sm_userid " + qry_condition + " and tbl_sales_master.sm_delivery_status IN(0,1,2) and tsi.si_itm_type<>'1' group by tbl_itembranch_stock.itm_id,tcu.cust_id ";
        DataTable countDt = db.SelectQuery(stockCountQuery);
        double numrows = Convert.ToInt32(countDt.Rows.Count);
        if (numrows == 0)
        {
            return "N"; ;
        }

        string stockReviewQry = @" SELECT  tcu.cust_name as customer,tlo.location_name AS location  ,tsi.itm_name AS Item_Name,tsi.itm_code, SUM( tsi.si_net_amount ) AS billNetamount,
 SUM( tsi.si_qty ) AS totalQty
 FROM tbl_sales_items tsi 
 INNER JOIN tbl_sales_master ON tsi.sm_id = tbl_sales_master.sm_id 
 INNER JOIN tbl_itembranch_stock ON tsi.itbs_id = tbl_itembranch_stock.itbs_id 
 INNER JOIN tbl_customer tcu ON tcu.cust_id = tbl_sales_master.cust_id
 INNER JOIN tbl_location tlo ON tlo.location_id = tcu.location_id
 INNER JOIN tbl_user_details tu ON tu.user_id = tbl_sales_master.sm_userid " + qry_condition + " and tbl_sales_master.sm_delivery_status IN(0,1,2) and tsi.si_itm_type<>'1' group by tbl_itembranch_stock.itm_id,tcu.cust_id   ORDER BY tcu.cust_id LIMIT  " + offset.ToString() + " ," + per_page + "";


        string jsonResponse = "";

        DataTable dt = db.SelectQuery(stockReviewQry);

        if (dt.Rows.Count > 0)
        {
            string jsonData = JsonConvert.SerializeObject(dt, Formatting.Indented);
            jsonResponse = "{\"count\":\"" + numrows + "\",\"data\":" + jsonData + "}";
        }
        else
        {
            jsonResponse = "N";
        }
        return jsonResponse;
    }

    //Start:For download service reports
    [WebMethod]
    public static string downloaditemoverview(Dictionary<string, string> filters)
    {
        mySqlConnection db = new mySqlConnection();
        StringBuilder sb = new StringBuilder();
        string qry_condition = " where 1=1";
        string status_qry = "";

        if (filters.Count > 0)
        {

            if (filters.ContainsKey("brand"))
            {
               qry_condition += " and tbl_itembranch_stock.itm_brand_id='" + filters["brand"] + "'";
            }
            if (filters.ContainsKey("category"))
            {
                qry_condition += " and tbl_itembranch_stock.itm_category_id='" + filters["category"] + "'";
            }
            if (filters.ContainsKey("warehouse"))
            {
                if (filters["warehouse"] == "0")
                {
                    qry_condition += " and (tbl_sales_master.branch_id IN(select branch_id from tbl_user_branches where user_id=" + HttpContext.Current.Request.Cookies["invntrystaffId"].Value + "))";
                }
                else
                {
                    qry_condition += " and tbl_sales_master.branch_id ='" + filters["warehouse"] + "'";
                }

            }
            if (filters.ContainsKey("searchItem"))
            {
                qry_condition += " and (tsi.itm_code like '%" + filters["searchItem"] + "%' or tsi.itm_name like '%" + filters["searchItem"] + "%')";
            }

            if (filters.ContainsKey("from_date"))
            {
                qry_condition += " and date(sm_date)>=STR_TO_DATE('" + filters["from_date"].Replace("-", "/") + "','%d/%m/%Y')";
            }
            if (filters.ContainsKey("to_date"))
            {
                qry_condition += " and date(sm_date)<=STR_TO_DATE('" + filters["to_date"].Replace("-", "/") + "','%d/%m/%Y')";
            }

        }
        string itemReviewQry = @" SELECT  tu.first_name AS OrderCreatedSalesPerson, tuuc.first_name AS CustomerCreatedSalesPerson,tcu.cust_name as CustomerName, tpm.tpm_name AS CustomerPriceGroup,tcm.cust_cat_name AS CustomerCategory,tlo.location_name AS location , tsi.itm_code as ItemCode,tsi.itm_name AS ItemName, tbl_sales_master.sm_invoice_no AS InvoiceNo,REPLACE(DATE_FORMAT(tbl_sales_master.sm_date,'%d/%m/%Y'),'/','-') as BillDate,timb.brand_name AS BrandName, timc.cat_name AS CategoryName,((tbl_itembranch_stock.itbs_purchase_price) )AS PurchasedPrice,(tsi.si_org_price) AS OrginalPrice, tsi.si_price AS SoledPrice ,tsi.si_discount_amount AS discountAount, tsi.si_tax_amount AS TaxAmount,SUM( tsi.si_qty ) AS TotalQty,  SUM( tsi.si_foc ) AS TotalFOC,(Sum(tsi.si_total) - Sum(tsi.si_discount_amount)) AS BilledTotalAmount,SUM( tsi.si_net_amount ) AS BillNetamount,CASE WHEN tbl_sales_master.sm_delivery_status = '0'  THEN 'New' WHEN tbl_sales_master.sm_delivery_status = '1'  THEN 'Processed' WHEN tbl_sales_master.sm_delivery_status = '2' THEN 'Delivered' WHEN tbl_sales_master.sm_delivery_status = '3'  THEN 'To be confirmed'WHEN tbl_sales_master.sm_delivery_status = '4'  THEN 'Canceled' WHEN tbl_sales_master.sm_delivery_status = '5'  THEN 'Rejected' WHEN tbl_sales_master.sm_delivery_status = '6'  THEN 'Pending' END AS OrderStaus FROM tbl_sales_items tsi INNER JOIN tbl_sales_master ON tsi.sm_id = tbl_sales_master.sm_id INNER JOIN tbl_itembranch_stock ON tsi.itbs_id = tbl_itembranch_stock.itbs_id  INNER JOIN tbl_customer tcu ON tcu.cust_id = tbl_sales_master.cust_id INNER JOIN tbl_location tlo ON tlo.location_id = tcu.location_id INNER JOIN tbl_user_details tu ON tu.user_id = tbl_sales_master.sm_userid INNER JOIN tbl_price_master tpm ON tpm.tpm_id = tcu.cust_type INNER JOIN tbl_item_master tim ON tim.itm_id = tbl_itembranch_stock.itm_id INNER JOIN tbl_item_brand timb ON timb.brand_id = tim.itm_brand_id INNER JOIN tbl_item_category timc ON timc.cat_id = tim.itm_category_id   INNER JOIN tbl_customer_category tcm ON tcm.cust_cat_id = tcu.cust_cat_id    INNER JOIN tbl_user_details tuuc ON tuuc.user_id = tcu.user_id "
								 + qry_condition + " and tbl_sales_master.sm_delivery_status IN(0,1,2) and tsi.si_itm_type<>'1' group by tbl_itembranch_stock.itm_id,tcu.cust_id,tbl_sales_master.sm_id  ORDER BY tcu.cust_id ";

        HttpContext.Current.Session["downloadqry"] = itemReviewQry;
        return "Y";
    }
    //Stop: Download reports
}