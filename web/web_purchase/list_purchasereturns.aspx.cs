using commonfunction;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;
using MySql.Data.MySqlClient;
using System.Text;


public partial class web_purchase_list_purchasereturns : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication bill = new LoginAuthentication();
        bill.userAuthentication();
        //   bill.checkPageAcess(111);
    }
    //show Purchase person
    [WebMethod]
    public static string showpurchasepersons()
    {

        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();
        StringBuilder sb = new StringBuilder();
        string query = "";
        if (HttpContext.Current.Request.Cookies["invntrystaffTypeID"].Value == "2")
        {
            query = "select user_id,first_name,last_name  from tbl_user_details where user_id =" + HttpContext.Current.Request.Cookies["invntrystaffId"].Value;
        }
        //  string query = "SELECT Branch.Id,Branch.Name FROM Branch INNER JOIN user_branches ON Branch.Id = user_branches.branch_id WHERE user_branches.user_id='" + userid + "' and user_branches.status='1' order by Branch.Id";
        else
        {
            query = "select user_id,first_name,last_name  from tbl_user_details order by user_id";
        }
        dt = db.SelectQuery(query);
        if (dt != null)
        {
            if (dt.Rows.Count > 0)
            {
                if (dt.Rows[0]["user_id"] is DBNull)
                {
                    sb.Append("<option value='0' >Select Purchase Person</option>");
                }
                else
                {
                    sb.Append("<option value='0' >Select Purchase Person</option>");
                    for (int i = 0; i < dt.Rows.Count; i++)
                    {
                        sb.Append("<option value='" + dt.Rows[i]["user_id"] + "'>" + dt.Rows[i]["first_name"] + "&nbsp" + dt.Rows[i]["last_name"] + "</option>");
                    }
                }
            }
            else
            {
                sb.Append("<option value='0' >Select Purchase Person</option>");
            }
        }

        return sb.ToString();
    }//end


    [WebMethod]
    public static string searchReturns(int page, Dictionary<string, string> filters, int perpage)
    {

        // string outputval = "okkkkkkkkkkk";
        try
        {
            //dynamic filters = JsonConvert.DeserializeObject(filter_string);
            string query_condition = "";
            if (HttpContext.Current.Request.Cookies["invntrystaffTypeID"].Value == "2")
            {
                query_condition = " where 1=1 and prm_userid=" + HttpContext.Current.Request.Cookies["invntrystaffId"].Value;
            }
            else
            {
                query_condition = " where 1=1";
            }

            string group_condition = " having 1=1 ";

            if (filters.Count > 0)
            {


                if (filters.ContainsKey("PurPersonId"))
                {
                    if (filters["PurPersonId"] != "0")
                    {
                        query_condition += " and prm.prm_userid='" + filters["PurPersonId"] + "'";
                    }
                }

                if (filters.ContainsKey("vendSearch"))
                {
                    query_condition += " and (tv.vn_name like '%" + filters["vendSearch"] + "%' or prm.vendor_id ='" + filters["vendSearch"] + "')";
                }
                if (filters.ContainsKey("branch"))
                {
                    if (filters["branch"] == "-1")
                    {
                        query_condition += " and prm.branch_id in (select branch_id from tbl_user_branches where user_id=" + HttpContext.Current.Request.Cookies["invntrystaffId"].Value + ")";
                    }
                    else
                    {
                        query_condition += " and prm.branch_id  = '" + filters["branch"] + "'";
                    }
                }

                if (filters.ContainsKey("return_status"))
                {

                    query_condition += " and prm.prm_status='" + filters["return_status"] + "'";


                }

                if (filters.ContainsKey("from_date"))
                {
                    query_condition += " and date(prm.prm_date)>=PTR_TO_DATE('" + filters["from_date"].Replace("-", "/") + "','%d/%m/%Y')";

                }
                if (filters.ContainsKey("to_date"))
                {

                    query_condition += " and date(prm.prm_date)<=PTR_TO_DATE('" + filters["to_date"].Replace("-", "/") + "','%d/%m/%Y')";

                }

            }

            int per_page = perpage;
            int offset = (page - 1) * per_page;

            mySqlConnection db = new mySqlConnection();
            string innerqry = "";
            string countQry = "";
            // double numrows = 0;

            DataTable dt1 = new DataTable();
            countQry = "select count(*)  as Count from ( " +
                "select prm.prm_id from  tbl_purchase_return_master prm inner join tbl_vendor tv on tv.vn_id=prm.vendor_id inner join tbl_transactions tr on prm.prm_id=tr.action_ref_id and tr.action_type=" + (int)Constants.ActionType.PURCHASE_RETURN + " " +
                  query_condition +
                " group by tr.action_ref_id,tr.action_type " + group_condition
                + ") result";

            double numrows = Convert.ToInt32(db.SelectScalar(countQry));

            if (numrows == 0)
            {
                return "{\"count\":\"" + numrows + "\",\"data\":[]}"; ;
            }

            innerqry = "select prm.prm_id,IFNULL(prm.prm_invoice_no,'<small>NOT RETURNED</small>') as invoiceNum,prm.vendor_id,tv.vn_name,prm.prm_amount as net_amount,sum(cr)-sum(dr) as total_balance,prm.prm_amount-(sum(cr)-sum(dr)) as total_paid"
               + ",DATE_FORMAT(prm.prm_date,'%d-%b-%Y %H:%i') AS returnDate"
               + ",prm.prm_status as return_status, concat(ud.first_name,' ',ud.last_name) as seller_name"
               + " from tbl_purchase_return_master prm "
               + " inner join tbl_branch tb on prm.branch_id=tb.branch_id"
               + " inner join tbl_user_details ud on prm.prm_userid=ud.user_id inner join tbl_vendor tv on tv.vn_id=prm.vendor_id "
               + " inner join tbl_transactions tr on (tr.action_ref_id=prm.prm_id and tr.action_type=" + (int)Constants.ActionType.PURCHASE_RETURN + ")" + query_condition;
            innerqry = innerqry + " group by action_ref_id,action_type " + group_condition + " order by prm_date desc LIMIT " + offset.ToString() + " ," + per_page;

            int total_pages = Convert.ToInt32(Math.Ceiling(numrows / per_page));

            DataTable dt = db.SelectQuery(innerqry);

            string jsonResponse = "";
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
        //string query = "SELECT Id, Name,CountryId FROM Branch ORDER BY Name ASC";
        //  string query = "select branch_id,branch_name from tbl_branch";
        string query = "select tb.branch_id,branch_name from tbl_branch tb inner join tbl_user_branches ub on ub.branch_id=tb.branch_id where user_id=" + HttpContext.Current.Request.Cookies["invntrystaffId"].Value;
        //   query = query + " order by tbl_branch.branch_id";
        dt = db.SelectQuery(query);
        return JsonConvert.SerializeObject(dt, Formatting.Indented);
    }
}