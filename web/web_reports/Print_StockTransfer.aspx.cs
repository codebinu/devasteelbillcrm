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

public partial class web_reports_Print_StockTransfer : System.Web.UI.Page
{
    public string stDatas;
    public string StId;

    protected void Page_Load(object sender, EventArgs e)
    {
        Int32 id = Convert.ToInt32(this.Request.Params["StId"]);
        if (id != 0) { Get_StockTransfer_Details(id); }
    }

    public void Get_StockTransfer_Details(Int32 id)
    {
        mySqlConnection db = new mySqlConnection();
        string dataQry = @"SELECT ST.st_id,br.branch_name AS sr_branch,br1.branch_name AS dr_branch,DATE_FORMAT(ST.st_date,'%d-%M-%Y') AS st_date,
CONCAT(ud.first_name,' ',ud.last_name) AS username 
FROM tbl_stock_transfer_header ST 
INNER JOIN tbl_user_details ud ON ud.user_id=ST.user_id 
LEFT OUTER JOIN tbl_branch br ON br.branch_id=ST.st_from_branch_id
LEFT OUTER JOIN tbl_branch br1 ON br1.branch_id=ST.st_to_branch_id 
WHERE ST.st_id=" + id + " GROUP BY ST.st_id ";

        StringBuilder sb = new StringBuilder();
        sb.Append("{");
        DataTable dtData = db.SelectQuery(dataQry);
        sb.Append("\"basedata\":");
        sb.Append(JsonConvert.SerializeObject(dtData, Formatting.Indented));
        sb.Append(",");
        string poitemQry = @"SELECT sti.itm_id , itm.itm_name ,sti.sti_quantity 
FROM tbl_stock_transfer_items sti 
INNER JOIN tbl_item_master itm ON itm.itm_id=sti.itm_id 
WHERE sti.st_id=" + id;

        DataTable itemData = db.SelectQuery(poitemQry);
        sb.Append("\"itemdata\":");
        sb.Append(JsonConvert.SerializeObject(itemData, Formatting.Indented));
        

        sb.Append("}");
        stDatas = sb.ToString();
    }

}