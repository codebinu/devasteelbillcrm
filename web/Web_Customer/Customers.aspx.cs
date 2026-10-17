using commonfunction;
using MySql.Data.MySqlClient;
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

public partial class Web_Customer_Customers : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication customers = new LoginAuthentication();
        customers.userAuthentication();
        customers.checkPageAcess(2);
        if (!IsPostBack)
        {
            loadDatas();
            loadCustomerTypes();
        }
    }

    /// <summary>
    /// method for load customerType
    /// </summary>
    public void loadCustomerTypes()
    {
        try
        {
            mySqlConnection db = new mySqlConnection();
            slCustomertype.Items.Clear();
            DataTable custTypeDt = db.SelectQuery("select tpm_id,tpm_name from tbl_price_master order by tpm_name asc");
            slCustomertype.Items.Add(new System.Web.UI.WebControls.ListItem("SELECT", "-1"));

            if (custTypeDt != null && custTypeDt.Rows.Count > 0)
            {
                foreach (DataRow custTypeRow in custTypeDt.Rows)
                {
                    slCustomertype.Items.Add(new System.Web.UI.WebControls.ListItem(custTypeRow["tpm_name"].ToString(), custTypeRow["tpm_id"].ToString()));
                }
            }
        }
        catch (Exception)
        {
        }
    }

    /// <summary>
    /// method to get system settings and set it in javascript object
    /// </summary>
    public void loadDatas()
    {
        try
        {
            mySqlConnection db = new mySqlConnection();
            SelectLocation.Items.Clear();
            DataTable brDt = db.SelectQuery("SELECT l.location_id,l.location_name FROM tbl_location l order by l.location_name asc");
            SelectLocation.Items.Add(new ListItem("--All Locations--", "-1"));

            if (brDt != null && brDt.Rows.Count > 0)
            {
                foreach (DataRow brRow in brDt.Rows)
                {
                    SelectLocation.Items.Add(new ListItem(brRow["location_name"].ToString(), brRow["location_id"].ToString()));
                }
            }
        }
        catch (Exception)
        {
        }
    }

    [WebMethod]
    public static string getBranches()
    {
        try
        {
            mySqlConnection db = new mySqlConnection();
            DataTable dt = new DataTable();
            var staffIdCookie = HttpContext.Current.Request.Cookies["invntrystaffId"];
            string staffId = staffIdCookie != null ? staffIdCookie.Value : "0";
            if (string.IsNullOrEmpty(staffId)) staffId = "0";

            string query = "select tb.branch_id,branch_name from tbl_branch tb inner join tbl_user_branches ub on ub.branch_id=tb.branch_id where user_id=@userId";
            MySqlParameter[] p = { new MySqlParameter("@userId", staffId) };
            dt = db.SelectQuery(query, p);
            return JsonConvert.SerializeObject(dt, Formatting.None);
        }
        catch (Exception)
        {
            return "[]";
        }
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

    [WebMethod]
    public static string searchCustomers(int page, Dictionary<string, string> filters, int perpage)
    {
        try
        {
            string query_condition = " where 1=1";
            List<MySqlParameter> parameters = new List<MySqlParameter>();

            if (filters != null && filters.Count > 0)
            {
                if (filters.ContainsKey("location_id") && !string.IsNullOrEmpty(filters["location_id"]) && filters["location_id"] != "-1")
                {
                    query_condition += " and cu.location_id = @location_id";
                    parameters.Add(new MySqlParameter("@location_id", filters["location_id"]));
                }

                if (filters.ContainsKey("seller_id") && !string.IsNullOrEmpty(filters["seller_id"]) && filters["seller_id"] != "0")
                {
                    query_condition += " and cu.user_id = @seller_id";
                    parameters.Add(new MySqlParameter("@seller_id", filters["seller_id"]));
                }

                if (filters.ContainsKey("search") && !string.IsNullOrEmpty(filters["search"]))
                {
                    string searchVal = filters["search"].Trim();
                    query_condition += " and (cu.cust_id like @searchStart or cu.cust_name like @searchAny or cu.cust_phone like @searchStart or cu.cust_reg_id like @searchAny or cu.cust_address like @searchAny or cu.cust_city like @searchAny)";
                    parameters.Add(new MySqlParameter("@searchStart", searchVal + "%"));
                    parameters.Add(new MySqlParameter("@searchAny", "%" + searchVal + "%"));
                }

                if (filters.ContainsKey("istoConfirm") && filters["istoConfirm"] == "1")
                {
                    query_condition += " and (IFNULL(cu.new_custtype,'0') != '0' or IFNULL(cu.new_creditamt,0) != 0 or IFNULL(cu.new_creditperiod,0) != 0)";
                }

                if (filters.ContainsKey("account_status") && filters["account_status"] != "-1")
                {
                    if (filters["account_status"] == "0")
                    {
                        query_condition += " and IFNULL(cu.cust_amount, 0) <= 0";
                    }
                    else if (filters["account_status"] == "1")
                    {
                        query_condition += " and IFNULL(cu.cust_amount, 0) > 0";
                    }
                }

                if (filters.ContainsKey("cus_type") && !string.IsNullOrEmpty(filters["cus_type"]) && filters["cus_type"] != "-1")
                {
                    query_condition += " and cu.cust_type = @cus_type";
                    parameters.Add(new MySqlParameter("@cus_type", filters["cus_type"]));
                }
            }

            int per_page = perpage > 0 ? perpage : 50;
            int current_page = page > 0 ? page : 1;
            int offset = (current_page - 1) * per_page;

            mySqlConnection db = new mySqlConnection();

            string countQry = "SELECT count(*) FROM tbl_customer cu " + query_condition;
            string countResult = db.SelectScalar(countQry, CloneParameters(parameters));

            int numrows = 0;
            if (!string.IsNullOrEmpty(countResult))
            {
                int.TryParse(countResult, out numrows);
            }

            if (numrows == 0)
            {
                return "{\"count\":0,\"data\":[]}";
            }

            string innerqry = "SELECT cu.cust_id, cu.cust_name, IFNULL(tpm.tpm_name,'') as class, cu.cust_type, "
                + " IFNULL(cu.cust_phone,'') as cust_phone, IFNULL(cu.cust_address,'') as cust_address, "
                + " IFNULL(cu.cust_city,'') as cust_city, IFNULL(cu.cust_reg_id,'') as cust_reg_id, "
                + " IFNULL(cu.cust_amount,0) as outstanding_amount, "
                + " TRIM(CONCAT(IFNULL(ud.first_name,''),' ',IFNULL(ud.last_name,''))) as seller_name, "
                + " (IFNULL(cu.new_custtype,'0') != '0' or IFNULL(cu.new_creditamt,0) != 0 or IFNULL(cu.new_creditperiod,0) != 0) as is_to_confirm "
                + " FROM tbl_customer cu "
                + " LEFT JOIN tbl_price_master tpm on tpm.tpm_id = cu.cust_type "
                + " LEFT JOIN tbl_user_details ud on ud.user_id = cu.user_id "
                + query_condition
                + " ORDER BY cu.cust_name ASC LIMIT " + offset + " ," + per_page;

            DataTable dt = db.SelectQuery(innerqry, CloneParameters(parameters));

            if (dt != null && dt.Rows.Count > 0)
            {
                string jsonData = JsonConvert.SerializeObject(dt, Formatting.None);
                return "{\"count\":" + numrows + ",\"data\":" + jsonData + "}";
            }
            else
            {
                return "{\"count\":0,\"data\":[]}";
            }
        }
        catch (Exception ex)
        {
            return JsonConvert.SerializeObject(new { count = 0, data = new object[0], error = ex.Message });
        }
    }
}