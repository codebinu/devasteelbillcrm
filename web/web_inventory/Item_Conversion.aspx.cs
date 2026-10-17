using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.Services;
using System.Data;
using System.Data.SqlTypes;
using System.Data.SqlClient;
using System.Text;
using commonfunction;
using Newtonsoft.Json;

public partial class web_incomExpense_Item_Conversion : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication warehouse = new LoginAuthentication();
        warehouse.userAuthentication();
        warehouse.checkPageAcess(72);

        loadDatas();
    }

    public void loadDatas()
    {
        mySqlConnection db = new mySqlConnection();
        DataTable brDt = db.SelectQuery("SELECT br.branch_name,br.branch_id FROM tbl_branch br INNER JOIN tbl_user_branches ub ON ub.branch_id=br.branch_id WHERE ub.user_id='" + HttpContext.Current.Request.Cookies["invntrystaffId"].Value + "' ORDER BY br.branch_name");
        select_src_warehouse.Items.Add(new ListItem("Select Warehouse", "-1"));
        //select_dest_warehouse.Items.Add(new ListItem("Select Destination Warehouse", "-1"));
        foreach (DataRow brRow in brDt.Rows)
        {
            select_src_warehouse.Items.Add(new ListItem(brRow["branch_name"].ToString(), brRow["branch_id"].ToString()));
            //select_dest_warehouse.Items.Add(new ListItem(brRow["branch_name"].ToString(), brRow["branch_id"].ToString()));
        }
    }

    [WebMethod]
    public static string showItems(string searchText,string branch_id)
    {
        StringBuilder sb = new StringBuilder();

        if (branch_id == "-1" || branch_id == "undefined")
        {
            sb.Append("[{\"id\":\"-1\",\"label\":\"Please Choose Warehouse & Try again\",\"value\":\"No Data Found\"}]");
            return sb.ToString();
        }

        mySqlConnection db = new mySqlConnection();
        DataTable dt = new DataTable();

        string query = "SELECT itbs_id as id,itm_name as label,itm_name as value FROM tbl_itembranch_stock where itm_name like '%" + searchText + "%' AND branch_id='" + branch_id + "'  ORDER BY itm_name ASC";
        dt = db.SelectQuery(query);
        if (dt.Rows.Count > 0)
        {
            //sb.Append("[");
            //foreach (DataRow row in dt.Rows)
            //{
            //    sb.Append("{\"id\":\"" + Convert.ToString(row["itbs_id"]) + "\",");
            //    sb.Append("\"label\":\"" + Convert.ToString(row["itm_name"]) + "\",");
            //    sb.Append("\"value\":\"" + Convert.ToString(row["itm_name"]) + "\"}");

            //    sb.Append(",");
            //}
            //sb.Remove(sb.Length - 1, 1);
            //sb.Append("]");
            string jsonData = JsonConvert.SerializeObject(dt, Formatting.Indented);
            sb.Append(jsonData);
        }
        else
        {
            sb.Append("[{\"id\":\"-1\",\"label\":\"No Data Found\",\"value\":\"No Data Found\"}]");
        }

        return sb.ToString();

    }

    [WebMethod]
    public static string Get_Item_Stock(string itbs_id)
    {

        var result = "";
        try
        {
            result = "{\"data\":" + JsonConvert.SerializeObject(new mySqlConnection().SelectQuery("select itbs.itbs_id,(itbs_stock+ifnull( sum(si.si_qty+si.si_foc),0)) as stock from tbl_itembranch_stock itbs inner join tbl_item_brand brd on brd.brand_id=itbs.itm_brand_id inner join tbl_item_category cat on cat.cat_id=itbs.itm_category_id inner join tbl_branch br on br.branch_id=itbs.branch_id left join tbl_sales_items si inner join tbl_sales_master sm on sm.sm_id = si.sm_id on itbs.itbs_id = si.itbs_id  and sm.sm_delivery_status in (0,3,6)  where 1=1  AND itbs.itbs_id='" + itbs_id + "' group by itbs.itbs_id "), Formatting.Indented) + "}";
            return result;
        }
        catch (Exception ex)
        {
            var log = new LogClass("customer_read_error");
            log.write(ex);
            result = "ERROR";
            return result;

        }

    }

    public static string Get_Current_Date_Time(string TimeZoneName)
    {
        var CURR_TIME_ZONE = TimeZoneInfo.FindSystemTimeZoneById(TimeZoneName);
        var TimeNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, CURR_TIME_ZONE);
        var date_time_now = TimeNow.ToString("yyyy-MM-dd HH:mm:ss");
        return date_time_now;
    }

    [WebMethod]
    public static string Convert_Items(Dictionary<string, string> convert_data)
    {

        var result = "";
        mySqlConnection db = new mySqlConnection();

        try
        {
            // 1.CHECK SESSION ID            
            var check_dt = db.SelectQuery("SELECT cm.conv_id FROM tbl_itm_conversion_master cm WHERE cm.conv_session_id='"+ convert_data["conv_session_id"] +"'");
            if (check_dt.Rows.Count > 0)
            {
                result = "REPEAT";
            }
            else
            {
                string time_zone = db.SelectScalar("SELECT ss_default_time_zone FROM tbl_system_settings");
                // 2.CREATE HEADER ROW & GET ID
                db.BeginTransaction();
                var conv_id = db.SelectScalarForTransaction("INSERT INTO `tbl_itm_conversion_master` ( `branch_id`, `user_id`, `conv_date`, `conv_session_id`) VALUES ('" + convert_data["branch_id"] + "', '" + convert_data["user_id"] + "', '" + Get_Current_Date_Time(time_zone) + "', '" + convert_data["conv_session_id"] + "');SELECT LAST_INSERT_ID();");

                // 3.INSERT TO CONVERSION ITEM DETAILS
                StringBuilder sb = new StringBuilder();
                sb.Append("INSERT INTO `tbl_itm_converted_items` (`conv_id`, `itbs_id`, `conv_qty`, `conv_itm_type`) VALUES ");

                // A. Input Items                
                dynamic input_items = JsonConvert.DeserializeObject(convert_data["input_items"]);

                foreach (var items in input_items)
                {
                    sb.Append(" ('" + conv_id.ToString() + "','" + items.itbs_id + "','" + items.itm_qty + "','1'),");

                    db.ExecuteQueryForTransaction("UPDATE tbl_itembranch_stock SET itbs_stock=(itbs_stock-" + items.itm_qty + ") WHERE itbs_id='" + items.itbs_id + "'");

                    // stock transaction
                    StringBuilder can_sb_bulk_stkTrQry = new StringBuilder();
                    can_sb_bulk_stkTrQry.Append("INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`action_ref_id`,`user_id`,`narration`,`dr_qty`,`closing_stock`,`date`) VALUES ");
                    // stock transaction
                    can_sb_bulk_stkTrQry.Append("('" + Convert.ToString(items.itbs_id + "','" + (int)Constants.ActionType.ITEM_CONVERSION) + "','" + conv_id + "','" + convert_data["user_id"] + "'");
                    can_sb_bulk_stkTrQry.Append(",'Stock Decreased by " + items.itm_qty + " qty of " + items.itm_name + " during Item Conversion with Ref #" + conv_id + "','" + items.itm_qty + "'");
                    can_sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + items.itbs_id + "')");
                    can_sb_bulk_stkTrQry.Append(",'" + Get_Current_Date_Time(time_zone) + "');");
                    db.ExecuteQueryForTransaction(can_sb_bulk_stkTrQry.ToString());

                }

                sb.Length--;                
                db.ExecuteQueryForTransaction(sb.ToString());

                StringBuilder sb1 = new StringBuilder();
                sb1.Append("INSERT INTO `tbl_itm_converted_items` (`conv_id`, `itbs_id`, `conv_qty`, `conv_itm_type`) VALUES ");

                // B. Output Items
                
                dynamic output_items = JsonConvert.DeserializeObject(convert_data["output_items"]);
                foreach (var oitems in output_items)
                {
                    sb1.Append(" ('" + conv_id.ToString() + "','" + oitems.itbs_id + "','" + oitems.itm_qty + "','2'),");

                    db.ExecuteQueryForTransaction("UPDATE tbl_itembranch_stock SET itbs_stock=(itbs_stock+" + oitems.itm_qty + ") WHERE itbs_id='" + oitems.itbs_id + "'");

                    // stock transaction
                    StringBuilder can_sb_bulk_stkTrQry = new StringBuilder();
                    can_sb_bulk_stkTrQry.Append("INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`action_ref_id`,`user_id`,`narration`,`cr_qty`,`closing_stock`,`date`) VALUES ");
                    // stock transaction
                    can_sb_bulk_stkTrQry.Append("('" + Convert.ToString(oitems.itbs_id + "','" + (int)Constants.ActionType.ITEM_CONVERSION) + "','" + conv_id + "','" + convert_data["user_id"] + "'");
                    can_sb_bulk_stkTrQry.Append(",'Stock Increased by " + oitems.itm_qty + " qty of " + oitems.itm_name + " during Item Conversion with Ref #" + conv_id + "','" + oitems.itm_qty + "'");
                    can_sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + oitems.itbs_id + "')");
                    can_sb_bulk_stkTrQry.Append(",'" + Get_Current_Date_Time(time_zone) + "');");
                    db.ExecuteQueryForTransaction(can_sb_bulk_stkTrQry.ToString());

                }

                sb1.Length--;
                db.ExecuteQueryForTransaction(sb1.ToString());

                
                db.CommitTransaction();
                result = "SUCCESS";

            }

            result = "{\"result\":\"" + result + "\"}";
            return result;
        }
        catch (Exception ex)
        {
            db.RollBackTransaction();
            var log = new LogClass("Item_Convert_Items");
            log.write(ex);
            result = "ERROR";
            result = "{\"result\":\"" + result + "\"}";
            return result;

        }

    }
    
}