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

public partial class web_reports_itemsOverView : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        loadDatas();
    }

    public void loadDatas()
    {
        mySqlConnection db = new mySqlConnection();
        

        DataTable userDt = db.SelectQuery("SELECT CM.sm_userid,CONCAT(UD.first_name,' ',UD.last_name) AS username FROM tbl_sales_master CM INNER JOIN tbl_user_details UD ON UD.user_id=CM.sm_userid INNER JOIN tbl_user_branches UB ON UB.branch_id=CM.branch_id WHERE UB.user_id='" + HttpContext.Current.Request.Cookies["invntrystaffId"].Value + "' GROUP BY CM.sm_userid ORDER BY username ASC");
        selUsers.Items.Add(new ListItem("All Users", "-1"));

        foreach (DataRow userRow in userDt.Rows)
        {
            selUsers.Items.Add(new ListItem(userRow["username"].ToString(), userRow["sm_userid"].ToString()));

        }

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

       

            if (filters.ContainsKey("user"))
            {
                qry_condition += " and tbl_sales_master.sm_userid ='" + filters["user"] + "'";
            }
            if (filters.ContainsKey("Invoiceororder"))
            {


                if (filters["Invoiceororder"] == "1")
                {

                    if (filters.ContainsKey("from_date"))
                    {
                        qry_condition += " and date(sm_date)>=STR_TO_DATE('" + filters["from_date"].Replace("-", "/") + "','%d/%m/%Y')";
                    }

                    if (filters.ContainsKey("to_date"))
                    {
                        qry_condition += " and date(sm_date)<=STR_TO_DATE('" + filters["to_date"].Replace("-", "/") + "','%d/%m/%Y')";
                    }

                    qry_condition += " AND tbl_sales_master.sm_invoice_no IS   null ";
                }
                else if (filters["Invoiceororder"] == "2")
                {

                    if (filters.ContainsKey("from_date"))
                    {
                        qry_condition += " and date(sm_processed_date)>=STR_TO_DATE('" + filters["from_date"].Replace("-", "/") + "','%d/%m/%Y')";
                    }

                    if (filters.ContainsKey("to_date"))
                    {
                        qry_condition += " and date(sm_processed_date)<=STR_TO_DATE('" + filters["to_date"].Replace("-", "/") + "','%d/%m/%Y')";
                    }

                    qry_condition += " AND tbl_sales_master.sm_invoice_no IS not  null ";
                }
                else if (filters["Invoiceororder"] == "-1")
                {
                   if (filters.ContainsKey("from_date"))
                    {
                        qry_condition += " and date(sm_date)>=STR_TO_DATE('" + filters["from_date"].Replace("-", "/") + "','%d/%m/%Y')";
                    }

                    if (filters.ContainsKey("to_date"))
                    {
                        qry_condition += " and date(sm_date)<=STR_TO_DATE('" + filters["to_date"].Replace("-", "/") + "','%d/%m/%Y')";
                    }

                }
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
 INNER JOIN tbl_user_details tu ON tu.user_id = tbl_sales_master.sm_userid " + qry_condition + " and tbl_sales_master.sm_delivery_status IN(0,1,2) and tsi.si_itm_type<>'1' group by tbl_itembranch_stock.itm_id";
        DataTable countDt = db.SelectQuery(stockCountQuery);
        double numrows = Convert.ToInt32(countDt.Rows.Count);
        if (numrows == 0)
        {
            return "N"; ;
        }

        string stockReviewQry = @" SELECT tsi.itm_name AS Item_Name,tsi.itm_code, sum(tsi.si_org_price * tsi.si_qty) AS originalCost, SUM( tsi.si_net_amount ) AS billNetamount,
 SUM( tsi.si_qty ) AS totalQty,(sum(tsi.si_org_price * tsi.si_qty)-SUM( tsi.si_net_amount )) as totaldiff
 FROM tbl_sales_items tsi 
 INNER JOIN tbl_sales_master ON tsi.sm_id = tbl_sales_master.sm_id 
 INNER JOIN tbl_itembranch_stock ON tsi.itbs_id = tbl_itembranch_stock.itbs_id 
 INNER JOIN tbl_user_details tu ON tu.user_id = tbl_sales_master.sm_userid " + qry_condition + " and tbl_sales_master.sm_delivery_status IN(0,1,2) and tsi.si_itm_type<>'1' group by tbl_itembranch_stock.itm_id LIMIT " + offset.ToString() + " ," + per_page + "";

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

            if (filters.ContainsKey("user"))
            {
                qry_condition += " and tbl_sales_master.sm_userid ='" + filters["user"] + "'";
            }

            if (filters.ContainsKey("Invoiceororder"))
            {


                if (filters["Invoiceororder"] == "1")
                {

                    if (filters.ContainsKey("from_date"))
                    {
                        qry_condition += " and date(sm_date)>=STR_TO_DATE('" + filters["from_date"].Replace("-", "/") + "','%d/%m/%Y')";
                    }

                    if (filters.ContainsKey("to_date"))
                    {
                        qry_condition += " and date(sm_date)<=STR_TO_DATE('" + filters["to_date"].Replace("-", "/") + "','%d/%m/%Y')";
                    }

                    qry_condition += " AND tbl_sales_master.sm_invoice_no IS   null ";
                }
                else if (filters["Invoiceororder"] == "2")
                {

                    if (filters.ContainsKey("from_date"))
                    {
                        qry_condition += " and date(sm_processed_date)>=STR_TO_DATE('" + filters["sm_processed_date"].Replace("-", "/") + "','%d/%m/%Y')";
                    }

                    if (filters.ContainsKey("to_date"))
                    {
                        qry_condition += " and date(sm_processed_date)<=STR_TO_DATE('" + filters["sm_processed_date"].Replace("-", "/") + "','%d/%m/%Y')";
                    }

                    qry_condition += " AND tbl_sales_master.sm_invoice_no IS not  null ";
                }
                else
                {
                    if (filters.ContainsKey("from_date"))
                    {
                        qry_condition += " and date(sm_date)>=STR_TO_DATE('" + filters["from_date"].Replace("-", "/") + "','%d/%m/%Y')";
                    }

                    if (filters.ContainsKey("to_date"))
                    {
                        qry_condition += " and date(sm_date)<=STR_TO_DATE('" + filters["to_date"].Replace("-", "/") + "','%d/%m/%Y')";
                    }

                }
            }

        }
        string itemReviewQry = @" SELECT tsi.itm_code as ItemCode,tsi.itm_name AS ItemName, sum(tsi.si_org_price * tsi.si_qty) AS OriginalCost, SUM( tsi.si_net_amount ) AS BillNetamount,
 SUM( tsi.si_qty ) AS TotalQty,(SUM( tsi.si_net_amount )-sum(tsi.si_org_price * tsi.si_qty)) as TotalDifference
 FROM tbl_sales_items tsi 
 INNER JOIN tbl_sales_master ON tsi.sm_id = tbl_sales_master.sm_id 
 INNER JOIN tbl_itembranch_stock ON tsi.itbs_id = tbl_itembranch_stock.itbs_id 
 INNER JOIN tbl_user_details tu ON tu.user_id = tbl_sales_master.sm_userid " + qry_condition + " and tbl_sales_master.sm_delivery_status IN(0,1,2) and tsi.si_itm_type<>'1' group by tbl_itembranch_stock.itm_id";

        HttpContext.Current.Session["downloadqry"] = itemReviewQry;
        return "Y";
    }
    //Stop: Download reports
}