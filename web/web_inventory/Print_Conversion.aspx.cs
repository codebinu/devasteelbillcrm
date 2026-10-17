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

public partial class web_inventory_Print_Conversion : System.Web.UI.Page
{
    public string conversionDatas;
    public string ConvId;

    protected void Page_Load(object sender, EventArgs e)
    {

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

  
}