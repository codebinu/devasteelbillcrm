using commonfunction;
using Newtonsoft.Json;
using System;
using System.Activities.Statements;
using System.Collections.Generic;
using System.Data;
using System.Device.Location;
using System.Linq;
using System.Runtime.Serialization.Formatters;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.DynamicData;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class web_opcenter_trackUsers : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication root = new LoginAuthentication();
        root.userAuthentication();
        root.checkPageAcess(25);
        loadUsers();
        loadLocations();
        loadDistricts();
        loadStates();
    }

    ///<summary>
    ///method to load users in user selection box
    ///</summary>
    private void loadUsers()
    {
        mySqlConnection db = new mySqlConnection();
        string qry = "select distinct tu.user_id,CONCAT(first_name,' ',last_name) as name from tbl_user_locations ul inner join tbl_user_details tu"
            + " on tu.user_id=ul.user_id where location_id in(select location_id from tbl_user_locations where user_id=" + Request.Cookies["invntrystaffId"].Value + ") and user_type in(2,3) order by first_name ";
        DataTable dt = db.SelectQuery(qry);
        foreach (DataRow row in dt.Rows)
        {
            selUsers.Items.Add(new ListItem(row[1].ToString(), row[0].ToString()));
        }

    }

    ///<summary>
    ///method to load locations in location selection box
    ///</summary>
    private void loadLocations()
    {
        mySqlConnection db = new mySqlConnection();
        string qry = "select distinct tl.location_id,location_name from tbl_user_locations ul inner join tbl_location tl on tl.location_id=ul.location_id"
            + " where tl.location_id in(select location_id from tbl_user_locations where user_id=" + Request.Cookies["invntrystaffId"].Value + ") order by location_name  ";
        DataTable dt = db.SelectQuery(qry);
        foreach (DataRow row in dt.Rows)
        {
            SelLocations.Items.Add(new ListItem(row[1].ToString(), row[0].ToString()));
        }
    }

    ///<summary>
    ///method to load districts in district selection box
    ///</summary>
    private void loadDistricts()
    {
        mySqlConnection db = new mySqlConnection();
        string qry = "select distinct td.dis_id,dis_name from tbl_user_locations ul inner join tbl_location tl"
            + " on tl.location_id=ul.location_id inner join tbl_district td on td.dis_id=tl.dist_id  where"
            + " ul.location_id in(select location_id from tbl_user_locations where user_id=" + Request.Cookies["invntrystaffId"].Value + ") order by dis_name ";
        DataTable dt = db.SelectQuery(qry);
        foreach (DataRow row in dt.Rows)
        {
            selDistricts.Items.Add(new ListItem(row[1].ToString(), row[0].ToString()));
        }
    }

    ///<summary>
    ///method to load districts in district selection box
    ///</summary>
    private void loadStates()
    {
        mySqlConnection db = new mySqlConnection();
        string qry = "select distinct ts.state_id,state_name from tbl_user_locations ul inner join tbl_location tl on"
            + " tl.location_id = ul.location_id inner join tbl_district td on td.dis_id = tl.dist_id inner join"
            + " tbl_state ts on ts.state_id = td.state_id where ul.location_id in(select location_id from tbl_user_locations where user_id=" + Request.Cookies["invntrystaffId"].Value + ")";
        DataTable dt = db.SelectQuery(qry);
        foreach (DataRow row in dt.Rows)
        {
            selState.Items.Add(new ListItem(row[1].ToString(), row[0].ToString()));
        }
    }

    /// <summary>
    /// method to get tracking details
    /// </summary>
    /// <param name="state_id">state id if state selected otherwise 0</param>
    /// <param name="district_id">district id if district selected otherwise 0</param>
    /// <param name="location_id">location id if location selected otherwise 0</param>
    /// <param name="user_id">user's id if user selected otherwise 0</param>
    /// <param name="dateFrom"></param>
    /// <param name="dateTo"></param>
    /// <returns></returns>
    [WebMethod]
    public static string getTrackingDetails(int location_id, int dis_id, int user_id,int state_id, string dateFrom, string dateTo)
    {
        mySqlConnection db = new mySqlConnection();
        DataTable orderDt, remainDt, checkinDt = new DataTable();
        string loc_qry_condition = "";
        string dis_qry_condition = "";
        string state_qry_condition = "";
        string order_qry_condition = "";
        string checkIn_qry_condition = "";
        if (location_id != 0)
        {
            loc_qry_condition= " and tl.location_id="+location_id+"";
        }
        if (dis_id != 0)
        {
            dis_qry_condition = " and td.dis_id=" + dis_id + "";
        }
        if (state_id != 0)
        {
            state_qry_condition = " and ts.state_id=" + state_id + "";
        }
        if (user_id != 0)
        {
            order_qry_condition = " and sm_userid =" + user_id + "";
            checkIn_qry_condition = " and rt_user_id =" + user_id + "";
        }
        if (dateFrom != "")
        {
            order_qry_condition += " and date(sm_date) >= '" + dateFrom + "'";
            checkIn_qry_condition += " and date(rt_datetime) >= '" + dateFrom + "'";
        }
        if (dateTo != "")
        {
            order_qry_condition += " and date(sm_date) <= '" + dateTo + "'";
            checkIn_qry_condition += " and date(rt_datetime) <= '" + dateTo + "'";
        }
        string orderQuery = "select count(sm.cust_id) as custCount,CONCAT(first_name,' ',last_name) as user,sm.cust_id,tc.cust_name as name,DATE_FORMAT(sm.sm_date,'%d/%m/%Y %H:%i') as checkDate,tc.cust_address as address,"
                            + " tc.cust_city,tc.cust_latitude as latitude,tc.cust_longitude as longitude"
                            + " from tbl_sales_master sm inner join tbl_customer tc on tc.cust_id = sm.cust_id"
                            + " inner join tbl_user_details tu on tu.user_id = sm.sm_userid"
                            + " where tc.location_id in (select distinct ul.location_id from tbl_user_locations ul"
                            +" inner join tbl_location tl on tl.location_id = ul.location_id "+loc_qry_condition+""
                            +" inner join tbl_district td on td.dis_id = tl.dist_id "+dis_qry_condition+""
                            +" inner join tbl_state ts on ts.state_id = td.state_id "+state_qry_condition+""
                            +" where ul.location_id in(select location_id from tbl_user_locations where user_id = " + HttpContext.Current.Request.Cookies["invntrystaffId"].Value + ") ) "+order_qry_condition+""
                            +" and sm.branch_id in (select branch_id from tbl_user_branches where user_id = " + HttpContext.Current.Request.Cookies["invntrystaffId"].Value + ")"
                            +" group by cust_id order by sm_date asc";

        orderDt = db.SelectQuery(orderQuery);
        string remainingCustomersQuery= "select cu.cust_id,cu.cust_name as name,cu.cust_address as address,cu.cust_city,cu.cust_latitude as latitude,cu.cust_longitude as longitude from tbl_customer cu"
                                        + " where cu.location_id in"
                                        +" (select distinct ul.location_id from tbl_user_locations ul"
                                        +" inner join tbl_location tl on tl.location_id = ul.location_id "+loc_qry_condition+""
                                        + " inner join tbl_district td on td.dis_id = tl.dist_id" + dis_qry_condition + ""
                                        + " inner join tbl_state ts on ts.state_id = td.state_id" + state_qry_condition + ""
                                        + " where ul.location_id in(select location_id from tbl_user_locations where user_id =  " + HttpContext.Current.Request.Cookies["invntrystaffId"].Value + "))"
                                        + " and cu.cust_id not in (select cust_id from tbl_root_tracker where 1 "+checkIn_qry_condition+" and cust_id != 0)"
                                        + " and cu.cust_id not in (select cust_id from tbl_sales_master where 1 " + order_qry_condition + " and branch_id in "
                                        + " (select branch_id from tbl_user_branches where user_id = " + HttpContext.Current.Request.Cookies["invntrystaffId"].Value + "))"
                                        + " and cu.cust_status != 2 and cu.cust_latitude != 0"
                                        +" group by cust_id order by cust_id";
        remainDt = db.SelectQuery(remainingCustomersQuery);

        string checkInQueryCondition= "select count(rt.cust_id) as chkCount,CONCAT(first_name,' ',last_name) as user,tc.cust_id,tc.cust_name as name,tc.cust_address as address,tc.cust_city,tc.cust_latitude as latitude,tc.cust_longitude as longitude,DATE_FORMAT(rt_datetime,'%d/%m/%Y %H:%i') as checkDate"
                                    + " from tbl_root_tracker rt inner"
                                    + " join"
                                    + " tbl_customer tc"
                                    + " on tc.cust_id = rt.cust_id"
                                    + " inner join tbl_user_details tu on tu.user_id = rt.rt_user_id"
                                    + " where tc.location_id in"
                                    + " (select distinct ul.location_id from tbl_user_locations ul"
                                    + " inner join tbl_location tl on tl.location_id = ul.location_id " + loc_qry_condition + ""
                                    + " inner join tbl_district td on td.dis_id = tl.dist_id" + dis_qry_condition + ""
                                    + " inner join tbl_state ts on ts.state_id = td.state_id" + state_qry_condition + ""
                                    + " where ul.location_id in(select location_id from tbl_user_locations where user_id = " + HttpContext.Current.Request.Cookies["invntrystaffId"].Value + ")) "+checkIn_qry_condition+""
                                    + " and rt.cust_id != 0 " + "" 
                                    //+ " and rt.cust_id not in(select cust_id from tbl_sales_master where 1 " +order_qry_condition+" )"
                                    + " group by cust_id order by rt_datetime asc";
        checkinDt = db.SelectQuery(checkInQueryCondition);

        string result = "{\"order_data\":" + JsonConvert.SerializeObject(orderDt, Formatting.Indented) + ",\"checkin_data\":" + JsonConvert.SerializeObject(checkinDt, Formatting.Indented) + ",\"remain_data\":" + JsonConvert.SerializeObject(remainDt, Formatting.Indented)+ "}";
        return result;
        
    }
    [WebMethod]
    public static string downloadReport(Dictionary<string, string> filters)	
    {	
         //string outputval = "okkkkkkkkkkk";	
		//return "y";

        
        try	
        {
            //dynamic filters = JsonConvert.DeserializeObject(filter_string);	
            string query_condition = " where 1=1 and tbl_root_tracker.cust_id != 0 and tbl_root_tracker.rt_visit_status=1";
            if (filters.Count > 0)
            {
				
				 if (filters.ContainsKey("selUsers"))
                {
                    query_condition += " and tbl_root_tracker.rt_user_id = '" + filters["selUsers"] + "'";
                }
                if (filters.ContainsKey("from_date"))
                {
                    query_condition += " and date(tbl_root_tracker.rt_datetime) >= '" + filters["from_date"] + "'";
                }
                if (filters.ContainsKey("to_date"))
                {
                    query_condition += " and date(tbl_root_tracker.rt_datetime) <= '" + filters["to_date"] + "'";
                }
            }
            mySqlConnection db = new mySqlConnection();
            string innerqry = "";

            // innerqry = "SELECT *, ROW_NUMBER() OVER (order by BillDate Desc) as row FROM billheader " + searchResult;	
            /*innerqry = "select concat(tu.first_name,' ',tu.last_name) as 'User Name',sum(rt.rt_visit_status) as 'Total checkIn',"
                    + " rt.rt_datetime as 'First CheckIn',(select max(rt_datetime) from tbl_root_tracker " + query_condition + " and rt_user_id=rt.rt_user_id)as 'Last CheckIn' from"
                    + " tbl_root_tracker rt inner join tbl_user_details tu on tu.user_id=rt.rt_user_id"
                    + query_condition + " group by rt.rt_user_id order by rt.rt_datetime"; */

            innerqry = "SELECT tbl_user_details.first_name AS User, tbl_customer.cust_name AS 'Customer Name',tbl_customer.cust_address AS 'Customer Address', tbl_location.location_name AS Location,tbl_root_tracker.rt_datetime AS 'Check-in Time',tbl_customer.cust_note AS Remarks FROM  tbl_root_tracker INNER JOIN tbl_customer ON tbl_root_tracker.cust_id = tbl_customer.cust_id INNER JOIN  tbl_user_details ON tbl_root_tracker.rt_user_id = tbl_user_details.user_id INNER JOIN tbl_location ON tbl_customer.location_id = tbl_location.location_id";

            innerqry = innerqry + query_condition + "order BY tbl_user_details.user_id, tbl_root_tracker.rt_datetime desc";
            DataTable dt = db.SelectQuery(innerqry);
            if (dt.Rows.Count == 0)
            {
                return "N";
            }
            else
            {
                HttpContext.Current.Session["downloadqry"] = innerqry;
                return "Y";
            }



            /*
            //dynamic filters = JsonConvert.DeserializeObject(filter_string);	
            string query_condition = " where 1=1 and cust_id != 0 and rt_visit_status=1";	
            if (filters.Count > 0)	
            {	
                if (filters.ContainsKey("from_date"))	
                {	
                    query_condition += " and date(rt_datetime) >= '" + filters["from_date"] + "'";	
                }	
                if (filters.ContainsKey("to_date"))	
                {	
                    query_condition += " and date(rt_datetime) <= '" + filters["to_date"] + "'";	
                }	
            }	
            mySqlConnection db = new mySqlConnection();	
            string innerqry = "";	
            	
            // innerqry = "SELECT *, ROW_NUMBER() OVER (order by BillDate Desc) as row FROM billheader " + searchResult;	
            innerqry = "select concat(tu.first_name,' ',tu.last_name) as 'User Name',sum(rt.rt_visit_status) as 'Total checkIn',"	
                    + " rt.rt_datetime as 'First CheckIn',(select max(rt_datetime) from tbl_root_tracker "+query_condition+" and rt_user_id=rt.rt_user_id)as 'Last CheckIn' from"	
                    +" tbl_root_tracker rt inner join tbl_user_details tu on tu.user_id=rt.rt_user_id"	
                    +query_condition+" group by rt.rt_user_id order by rt.rt_datetime";	
            DataTable dt = db.SelectQuery(innerqry);	
            if (dt.Rows.Count == 0)	
            {	
                return "N";	
            }	
            else	
            {	
                HttpContext.Current.Session["downloadqry"] = innerqry;	
                return "Y";	
            }	

            */
        }	
        catch (Exception ex)	
        {	
            return ex.ToString();	
        }
        
    }

    [WebMethod]
    public static string downloadAllReport(Dictionary<string, string> filters)
    {
        try
        {            
            mySqlConnection db = new mySqlConnection();
            string customerQry = @"SELECT cu.cust_id,cu.cust_name, cu.cust_address,cu.cust_city, lc.location_name FROM tbl_customer cu 
INNER JOIN tbl_location lc on lc.location_id = cu.location_id
INNER JOIN tbl_user_locations ul ON cu.location_id=ul.location_id WHERE ul.user_id='" + filters["selUsers"] + "' GROUP BY cu.cust_id ORDER BY cu.cust_name ASC ";

            DataTable dt = db.SelectQuery(customerQry);
            if (dt.Rows.Count == 0)
            {
                return "N";
            }
            else
            {
                var checkinQry = @"SELECT rt.cust_id, DATE_FORMAT(rt.rt_datetime, '%Y-%m-%d %H:%i:%s') as checkin FROM tbl_root_tracker rt 
WHERE rt.rt_user_id='" + filters["selUsers"] + "' AND DATE(rt.rt_datetime)>='" + filters["from_date"] + "' AND DATE(rt.rt_datetime)<='" + filters["to_date"] + "' AND rt.cust_id!=0 ORDER BY rt.rt_datetime ASC ";
                DataTable dtCheckin = db.SelectQuery(checkinQry);

                // process customer table with custom 
                DataTable finalDt = new DataTable();
                finalDt.Columns.Add("CUSTOMER");
                finalDt.Columns.Add("ADDRESS");
                finalDt.Columns.Add("CITY");
                finalDt.Columns.Add("LOCATION");
                finalDt.Columns.Add("COUNT");
                finalDt.Columns.Add("VISITED ON");

                var isFirstRow = false;
                for(int i = 0; i < dt.Rows.Count; i++)
                {
                    var qry = dtCheckin.AsEnumerable().Where(x => x.Field<int>("cust_id") == Convert.ToInt32(dt.Rows[i]["cust_id"])).ToList();
                    if (qry.Count > 0)
                    {
                        int j = 0;
                        for (j = 0; j < qry.Count; j++)
                        {
                            if (j == 0)
                            {
                                isFirstRow = true;
                            }
                            else
                            {
                                isFirstRow = false;
                            }

                            if (isFirstRow)
                            {
                                DataRow row = finalDt.NewRow();
                                row["CUSTOMER"] = dt.Rows[i]["cust_name"].ToString();
                                row["ADDRESS"] = dt.Rows[i]["cust_address"].ToString();
                                row["CITY"] = dt.Rows[i]["cust_city"].ToString();
                                row["LOCATION"] = dt.Rows[i]["location_name"].ToString();
                                row["COUNT"] = qry.Count;
                                row["VISITED ON"] = qry[j]["checkin"];
                                finalDt.Rows.Add(row);
                            }
                            else{

                                DataRow row = finalDt.NewRow();
                                row["CUSTOMER"] = "-";
                                row["ADDRESS"] = "-";
                                row["CITY"] = "-";
                                row["LOCATION"] = "-";
                                row["COUNT"] = "-";
                                row["VISITED ON"] = qry[j]["checkin"];
                                finalDt.Rows.Add(row);
                            }


                        }
                    }
                    else
                    {
                        DataRow row = finalDt.NewRow();
                        row["CUSTOMER"] = dt.Rows[i]["cust_name"].ToString();
                        row["ADDRESS"] = dt.Rows[i]["cust_address"].ToString();
                        row["CITY"] = dt.Rows[i]["cust_city"].ToString();
                        row["LOCATION"] = dt.Rows[i]["location_name"].ToString();
                        row["COUNT"] = 0;
                        row["VISITED ON"] = "-";
                        finalDt.Rows.Add(row);
                    }
                }

                HttpContext.Current.Session["finalDt"] = finalDt;
                HttpContext.Current.Session["vr_name"] = filters["userName"];
                HttpContext.Current.Session["vr_dtfrom"] = filters["from_date"];
                HttpContext.Current.Session["vr_dtto"] = filters["to_date"];
                return "Y";
            }


        }
        catch (Exception ex)
        {
            return ex.ToString();
        }

    }


}