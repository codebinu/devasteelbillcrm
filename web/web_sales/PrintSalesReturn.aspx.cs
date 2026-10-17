using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.Services;
using System.Data;
using System.Text;
using commonfunction;
using Newtonsoft.Json;
using System.Dynamic;
using System.IO;
using iTextSharp.text;
using iTextSharp.text.html.simpleparser;
using iTextSharp.text.pdf;
using iTextSharp.text.xml;
using iTextSharp.text.html;

using System.Net;
using System.Net.Mail;
using iTextSharp.tool.xml;

public partial class web_sales_PrintSalesReturn : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {

    }
    [WebMethod]
    public static string showReturnReceipt(string returnNo)
    {
        mySqlConnection db = new mySqlConnection();
        StringBuilder sb = new StringBuilder();
        try
        {
            sb.Append("{");
            //fetching order details
            String orderQry = "SELECT cu.cust_id, srm.srm_id, cu.cust_name,concat(ud.first_name,' ',ud.last_name) as staff_name,cu.cust_address as address,cu.cust_city as city,cu.cust_country as country,cust_tax_reg_id as gst,cu.cust_state as state,cu.cust_phone as phone,cu.cust_email as email "
                + " ,DATE_FORMAT(srm.srm_date, '%d-%b-%Y %h:%i %p') as srm_date,srm.srm_amount as net_amount,srm_tax_amount as tax"
                + " ,srm.branch_id,IFNULL(cu.cust_amount,0) as outstanding_amt,srm_invoice_no as invoiceNum,state_name "
                + " FROM tbl_salesreturn_master srm inner join tbl_customer cu on cu.cust_id=srm.cust_id inner join tbl_state on tbl_state.state_id=cu.cust_state"
                + "  left join tbl_user_details ud on ud.user_id=srm.srm_userid inner join tbl_salesreturn_items sri on sri.srm_id=srm.srm_id WHERE srm.srm_id ='" + returnNo + "' ";
            DataTable dtOrder = db.SelectQuery(orderQry);
            sb.Append("\"order\":");
            sb.Append(JsonConvert.SerializeObject(dtOrder, Formatting.Indented));
            // fetching branch details
            string branchQry = "SELECT branch_id,branch_name,branch_countryid,branch_bill_disclosure,branch_bill_footer,branch_address,branch_country_name,branch_image,branch_reg_id,branch_email,branch_declaration,branch_invoice_address FROM tbl_branch WHERE branch_id='" + Convert.ToString(dtOrder.Rows[0]["branch_id"]) + "' ";
            DataTable dtBranches = db.SelectQuery(branchQry);
            sb.Append(",");
            sb.Append("\"branch\":");
            sb.Append(JsonConvert.SerializeObject(dtBranches, Formatting.Indented));
            //fetching order items
            String qryItems = "SELECT sri.itm_code,sri.itm_name,sri_qty as qty,si_price as price "
                + " ,sri_total,si_discount_rate as dis_rate,sri_discount_amount as dis_amount,itm_mrp"
                + " ,sri_total as net_amount,sri_tax_amount as tax"
                + " FROM tbl_salesreturn_items sri inner join tbl_itembranch_stock tis on tis.itbs_id=sri.itbs_id WHERE srm_id='" + dtOrder.Rows[0]["srm_id"].ToString() + "'";
            DataTable dtItems = db.SelectQuery(qryItems);
            sb.Append(",");
            sb.Append("\"items\":");
            sb.Append(JsonConvert.SerializeObject(dtItems, Formatting.Indented));
            sb.Append("}");
            return sb.ToString();
        }
        catch (Exception e)
        {
            HttpContext.Current.Response.StatusCode = 401;
            HttpContext.Current.Response.TrySkipIisCustomErrors = true;
            return "";
        }
    }

}