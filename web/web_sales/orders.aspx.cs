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
using MySql.Data.MySqlClient;

public partial class web_sales_orders : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication bill = new LoginAuthentication();
        bill.userAuthentication();
        bill.checkPageAcess(8);
    }
    //show Sales person
    [WebMethod]
    public static string showsalespersons()
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        StringBuilder sb = new StringBuilder();
        string query = "";

        var staffTypeCookie = HttpContext.Current.Request.Cookies["invntrystaffTypeID"];
        var staffIdCookie = HttpContext.Current.Request.Cookies["invntrystaffId"];
        string staffTypeId = staffTypeCookie != null ? staffTypeCookie.Value : "";
        string staffId = staffIdCookie != null ? staffIdCookie.Value : "";

        if (staffTypeId == "2")
        {
            query = "select user_id,first_name,last_name from tbl_user_details where user_id = @userId";
            MySqlParameter[] p = { new MySqlParameter("@userId", staffId) };
            dt = db.SelectQuery(query, p);
        }
        else
        {
            query = "select user_id,first_name,last_name from tbl_user_details order by user_id";
            dt = db.SelectQuery(query);
        }

        if (dt != null)
        {
            if (dt.Rows.Count > 0)
            {
                if (dt.Rows[0]["user_id"] is DBNull)
                {
                    sb.Append("<option value='0' >Select Sales Person</option>");
                }
                else
                {
                    sb.Append("<option value='0' >Select Sales Person</option>");
                    for (int i = 0; i < dt.Rows.Count; i++)
                    {
                        sb.Append("<option value='" + dt.Rows[i]["user_id"] + "'>" + dt.Rows[i]["first_name"] + "&nbsp" + dt.Rows[i]["last_name"] + "</option>");
                    }
                }
            }
            else
            {
                sb.Append("<option value='0' >Select Sales Person</option>");
            }
        }

        return sb.ToString();
    }//end


    [WebMethod]
    public static string searchOrders(int page, Dictionary<string, string> filters, int perpage)
    {
        try
        {
            List<MySqlParameter> parameters = new List<MySqlParameter>();
            string query_condition = "";

            var staffTypeCookie = HttpContext.Current.Request.Cookies["invntrystaffTypeID"];
            var staffIdCookie = HttpContext.Current.Request.Cookies["invntrystaffId"];
            string staffTypeId = staffTypeCookie != null ? staffTypeCookie.Value : "";
            string staffId = staffIdCookie != null ? staffIdCookie.Value : "";

            if (staffTypeId == "2")
            {
                query_condition = " where 1=1 and sm_userid = @staffId";
                parameters.Add(new MySqlParameter("@staffId", staffId));
            }
            else
            {
                query_condition = " where 1=1";
            }

            string group_condition = " having 1=1 ";
            string salesReturnQuery = " left join (select Distinct sm_id from tbl_salesreturn_master) as srm on sm.sm_id=srm.sm_id ";

            if (filters.Count > 0)
            {
                if (filters.ContainsKey("cus_id"))
                {
                    query_condition += " and sm.cust_id = @cus_id";
                    parameters.Add(new MySqlParameter("@cus_id", filters["cus_id"]));
                }
                if (filters.ContainsKey("seller_id"))
                {
                    if (filters["seller_id"] != "0")
                    {
                        query_condition += " and sm.sm_userid = @seller_id";
                        parameters.Add(new MySqlParameter("@seller_id", filters["seller_id"]));
                    }
                }
                if (filters.ContainsKey("search"))
                {
                    query_condition += " and (sm.sm_id = @search or sm.sm_invoice_no like @searchLike)";
                    parameters.Add(new MySqlParameter("@search", filters["search"]));
                    parameters.Add(new MySqlParameter("@searchLike", "%" + filters["search"] + "%"));
                }
                if (filters.ContainsKey("custSearch"))
                {
                    query_condition += " and (tc.cust_name like @custSearchLike or sm.cust_id = @custSearch)";
                    parameters.Add(new MySqlParameter("@custSearch", filters["custSearch"]));
                    parameters.Add(new MySqlParameter("@custSearchLike", "%" + filters["custSearch"] + "%"));
                }
                if (filters.ContainsKey("branch"))
                {
                    if (filters["branch"] == "-1")
                    {
                        query_condition += " and sm.branch_id in (select branch_id from tbl_user_branches where user_id = @branchStaffId)";
                        parameters.Add(new MySqlParameter("@branchStaffId", staffId));
                    }
                    else
                    {
                        query_condition += " and sm.branch_id = @branch";
                        parameters.Add(new MySqlParameter("@branch", filters["branch"]));
                    }
                }
                if (filters.ContainsKey("payment_status"))
                {
                    if (Convert.ToInt32(filters["payment_status"]) == 1)
                    {
                        group_condition += " and (sum(dr)-sum(cr))<=0";
                    }
                    else if (Convert.ToInt32(filters["payment_status"]) == 2)
                    {
                        group_condition += " and (sum(dr)-sum(cr))>0";
                    }
                }
                if (filters.ContainsKey("order_status"))
                {
                    if (filters["order_status"] == "6")
                    {
                        salesReturnQuery = " inner join tbl_salesreturn_master srm on sm.sm_id=srm.sm_id";
                    }
                    else
                    {
                        query_condition += " and sm.sm_delivery_status = @order_status";
                        parameters.Add(new MySqlParameter("@order_status", filters["order_status"]));
                    }
                }
                if (filters.ContainsKey("type"))
                {
                    if (filters["type"] == "0")
                    {
                        query_condition += " and sm.sm_invoice_no is null";
                    }
                    else if (filters["type"] == "1")
                    {
                        query_condition += " and sm.sm_invoice_no is not null";
                    }
                }
                if (filters.ContainsKey("from_date"))
                {
                    string fromDateVal = filters["from_date"].Replace("-", "/");
                    if (filters.ContainsKey("type") && filters["type"] == "1")
                    {
                        query_condition += " and sm.sm_processed_date >= STR_TO_DATE(@from_date, '%d/%m/%Y')";
                    }
                    else
                    {
                        query_condition += " and sm.sm_date >= STR_TO_DATE(@from_date, '%d/%m/%Y')";
                    }
                    parameters.Add(new MySqlParameter("@from_date", fromDateVal));
                }
                if (filters.ContainsKey("to_date"))
                {
                    string toDateVal = filters["to_date"].Replace("-", "/");
                    if (filters.ContainsKey("type") && filters["type"] == "1")
                    {
                        query_condition += " and sm.sm_processed_date < DATE_ADD(STR_TO_DATE(@to_date, '%d/%m/%Y'), INTERVAL 1 DAY)";
                    }
                    else
                    {
                        query_condition += " and sm.sm_date < DATE_ADD(STR_TO_DATE(@to_date, '%d/%m/%Y'), INTERVAL 1 DAY)";
                    }
                    parameters.Add(new MySqlParameter("@to_date", toDateVal));
                }
            }

            int per_page = perpage;
            int offset = (page - 1) * per_page;

            mySqlConnection db = new mySqlConnection();
            string innerqry = "";
            string countQry = "";

            if (group_condition.Trim() == "having 1=1")
            {
                countQry = "select count(distinct sm.sm_id) as Count from tbl_sales_master sm " +
                    "inner join tbl_customer tc on tc.cust_id=sm.cust_id " +
                    "inner join tbl_transactions tr on sm.sm_id=tr.action_ref_id and tr.action_type=" + (int)Constants.ActionType.SALES + " " +
                    salesReturnQuery + query_condition;
            }
            else
            {
                countQry = "select count(*) as Count from ( " +
                    "select sm.sm_id from tbl_sales_master sm " +
                    "inner join tbl_customer tc on tc.cust_id=sm.cust_id " +
                    "inner join tbl_transactions tr on sm.sm_id=tr.action_ref_id and tr.action_type=" + (int)Constants.ActionType.SALES + " " +
                    salesReturnQuery + query_condition +
                    " group by tr.action_ref_id, tr.action_type " + group_condition +
                    ") result";
            }

            string scalarVal = db.SelectScalar(countQry, CloneParameters(parameters));
            double numrows = string.IsNullOrEmpty(scalarVal) ? 0 : Convert.ToInt32(scalarVal);

            if (numrows == 0)
            {
                return "{\"count\":\"" + numrows + "\",\"data\":[]}";
            }

            innerqry = "select sm.sm_id,sm.sm_refno as ref_id,tpm_name as class,sm.cust_id,tc.cust_name,sm.sm_netamount as net_amount,sum(dr)-sum(cr) as total_balance,sm.sm_netamount-(sum(dr)-sum(cr)) as total_paid"
               + ",DATE_FORMAT(sm.sm_date,'%d-%b-%Y %H:%i') AS orderDate,DATE_FORMAT(sm.sm_processed_date,'%d-%b-%Y %H:%i') AS billedDate,branch_tax_method"
               + ",sm.sm_delivery_status as order_status, concat(ud.first_name,' ',ud.last_name) as seller_name,concat(udone.first_name,' ',udone.last_name) as billedBy,srm.sm_id as srm_smid,cust_type,sm_invoice_no as invoiceNum"
               + " from tbl_sales_master sm "
               + " inner join tbl_user_details ud on sm.sm_userid=ud.user_id left join tbl_user_details udone on sm.sm_processed_id=udone.user_id inner join tbl_customer tc on tc.cust_id=sm.cust_id inner join tbl_price_master tpm on tpm.tpm_id=tc.cust_type"
               + " inner join tbl_transactions tr on (tr.action_ref_id=sm.sm_id and tr.action_type=" + (int)Constants.ActionType.SALES + ")" + salesReturnQuery + query_condition;
            innerqry = innerqry + " group by action_ref_id,action_type " + group_condition + " order by sm_date desc LIMIT " + offset.ToString() + " ," + per_page;

            DataTable dt = db.SelectQuery(innerqry, CloneParameters(parameters));

            string jsonResponse = "";
            if (dt.Rows.Count > 0)
            {
                string jsonData = JsonConvert.SerializeObject(dt);
                jsonResponse = "{\"count\":\"" + numrows + "\",\"data\":" + jsonData + "}";
            }
            else
            {
                jsonResponse = "N";
            }
            return jsonResponse;

        }
        catch (Exception ex)
        {
            return ex.ToString();
        }
    }

    [WebMethod]
    public static string getBranches()
    {
        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();

        var staffIdCookie = HttpContext.Current.Request.Cookies["invntrystaffId"];
        string staffId = staffIdCookie != null ? staffIdCookie.Value : "";

        string query = "select tb.branch_id,branch_name from tbl_branch tb inner join tbl_user_branches ub on ub.branch_id=tb.branch_id where user_id = @userId";
        MySqlParameter[] p = { new MySqlParameter("@userId", staffId) };
        dt = db.SelectQuery(query, p);
        return JsonConvert.SerializeObject(dt);
    }

    private static MySqlParameter[] CloneParameters(List<MySqlParameter> source)
    {
        MySqlParameter[] copy = new MySqlParameter[source.Count];
        for (int i = 0; i < source.Count; i++)
        {
            copy[i] = new MySqlParameter(source[i].ParameterName, source[i].Value);
        }
        return copy;
    }
}