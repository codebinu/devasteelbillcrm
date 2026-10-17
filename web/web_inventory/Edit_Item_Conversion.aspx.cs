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

public partial class web_inventory_Edit_Item_Conversion : System.Web.UI.Page
{
    public string conversionDatas;
    public string ConvId;

    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication warehouse = new LoginAuthentication();
        warehouse.userAuthentication();
        warehouse.checkPageAcess(73);

        Int32 id = Convert.ToInt32(this.Request.Params["convid"]);
        if (id != 0) { Get_Conversion_Details(id); }
    }

   

    public void Get_Conversion_Details(Int32 id)
    {
        mySqlConnection db = new mySqlConnection();
        string dataQry = @"SELECT cm.conv_id,cm.branch_id,br.branch_name,DATE_FORMAT(cm.conv_date,'%d-%M-%Y') as conv_date,
cm.user_id,CONCAT(ud.first_name,'',ud.last_name) AS username 
FROM tbl_itm_conversion_master cm 
INNER JOIN tbl_branch br ON br.branch_id=cm.branch_id 
INNER JOIN tbl_user_details ud ON ud.user_id=cm.user_id 
WHERE cm.conv_id=" + id;

        StringBuilder sb = new StringBuilder();
        sb.Append("{");
        DataTable dtData = db.SelectQuery(dataQry);
        sb.Append("\"basedata\":");
        sb.Append(JsonConvert.SerializeObject(dtData, Formatting.Indented));
        sb.Append(",");
        string poitemQry = @"SELECT itc.itbs_id,itc.conv_qty,itc.conv_itm_type,itb.itm_name  
FROM tbl_itm_converted_items itc 
INNER JOIN tbl_itembranch_stock itb ON itb.itbs_id=itc.itbs_id 
WHERE itc.conv_id=" + id;

        DataTable itemData = db.SelectQuery(poitemQry);
        sb.Append("\"itemdata\":");
        sb.Append(JsonConvert.SerializeObject(itemData, Formatting.Indented));

        sb.Append(",");
        string strQry = @"SELECT st.id,DATE_FORMAT(st.date, '%d-%M-%Y %h:%i %p') as conv_date,st.narration,st.dr_qty,st.cr_qty,CONCAT(ud.first_name,' ',ud.last_name) AS username FROM tbl_stock_transactions st 
INNER JOIN tbl_user_details ud ON ud.user_id=st.user_id 
WHERE st.action_type=12 AND st.action_ref_id=" + id + " ORDER BY st.id DESC";

        DataTable trData = db.SelectQuery(strQry);
        sb.Append("\"strdata\":");
        sb.Append(JsonConvert.SerializeObject(trData, Formatting.Indented));
        

        sb.Append("}");
        conversionDatas = sb.ToString();
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

            string time_zone = db.SelectScalar("SELECT ss_default_time_zone FROM tbl_system_settings");
            // 2.CREATE HEADER ROW & GET ID
            
            var conv_id = convert_data["conv_id"];

            // HANDLE EXISTING DATA - NEED TO NORMALIZE
            var dt_olditem = db.SelectQuery("SELECT it.itbs_id,it.conv_qty,it.conv_itm_type,itb.itm_name FROM tbl_itm_converted_items it INNER JOIN tbl_itembranch_stock itb ON itb.itbs_id=it.itbs_id WHERE it.conv_id='" + convert_data["conv_id"] + "'");

            db.BeginTransaction();

            foreach (DataRow itRow in dt_olditem.Rows)
            {
                if (itRow["conv_itm_type"].ToString() == "1")
                {
                    db.ExecuteQueryForTransaction("UPDATE tbl_itembranch_stock SET itbs_stock=(itbs_stock+" + itRow["conv_qty"] + ") WHERE itbs_id='" + itRow["itbs_id"] + "'");

                    // stock transaction
                    StringBuilder can_sb_bulk_stkTrQry = new StringBuilder();
                    can_sb_bulk_stkTrQry.Append("INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`action_ref_id`,`user_id`,`narration`,`cr_qty`,`closing_stock`,`date`) VALUES ");
                    // stock transaction
                    can_sb_bulk_stkTrQry.Append("('" + Convert.ToString(itRow["itbs_id"] + "','" + (int)Constants.ActionType.ITEM_CONVERSION) + "','" + conv_id + "','" + convert_data["user_id"] + "'");
                    can_sb_bulk_stkTrQry.Append(",'Stock Increased by " + itRow["conv_qty"] + " qty of " + itRow["itm_name"] + " during Item Conversion Updation with Ref #" + conv_id + "','" + itRow["conv_qty"] + "'");
                    can_sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + itRow["itbs_id"] + "')");
                    can_sb_bulk_stkTrQry.Append(",'" + Get_Current_Date_Time(time_zone) + "');");
                    db.ExecuteQueryForTransaction(can_sb_bulk_stkTrQry.ToString());
                }

                if (itRow["conv_itm_type"].ToString() == "2")
                {
                    db.ExecuteQueryForTransaction("UPDATE tbl_itembranch_stock SET itbs_stock=(itbs_stock-" + itRow["conv_qty"] + ") WHERE itbs_id='" + itRow["itbs_id"] + "'");

                    // stock transaction
                    StringBuilder can_sb_bulk_stkTrQry = new StringBuilder();
                    can_sb_bulk_stkTrQry.Append("INSERT INTO `tbl_stock_transactions` (`itbs_id`,`action_type`,`action_ref_id`,`user_id`,`narration`,`dr_qty`,`closing_stock`,`date`) VALUES ");
                    // stock transaction
                    can_sb_bulk_stkTrQry.Append("('" + Convert.ToString(itRow["itbs_id"] + "','" + (int)Constants.ActionType.ITEM_CONVERSION) + "','" + conv_id + "','" + convert_data["user_id"] + "'");
                    can_sb_bulk_stkTrQry.Append(",'Stock Decreased by " + itRow["conv_qty"] + " qty of " + itRow["itm_name"] + " during Item Conversion Updation with Ref #" + conv_id + "','" + itRow["conv_qty"] + "'");
                    can_sb_bulk_stkTrQry.Append(",(select itbs_stock from tbl_itembranch_stock where itbs_id='" + itRow["itbs_id"] + "')");
                    can_sb_bulk_stkTrQry.Append(",'" + Get_Current_Date_Time(time_zone) + "');");
                    db.ExecuteQueryForTransaction(can_sb_bulk_stkTrQry.ToString());
                }

            }


            db.ExecuteQueryForTransaction("DELETE FROM tbl_itm_converted_items WHERE conv_id='" + convert_data["conv_id"] + "'");

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

            result = "{\"result\":\"" + result + "\"}";
            return result;
        }
        catch (Exception ex)
        {
            db.RollBackTransaction();
            var log = new LogClass("Edit_Convert_Items");
            log.write(ex);
            result = "ERROR";
            result = "{\"result\":\"" + result + "\"}";
            return result;

        }

    }

}