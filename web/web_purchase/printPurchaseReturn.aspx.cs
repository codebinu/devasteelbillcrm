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

public partial class web_purchase_printPurchaseReturn : System.Web.UI.Page
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
            String orderQry = @"SELECT cu.vn_id, srm.prm_id, cu.vn_name,concat(ud.first_name,' ',ud.last_name) as staff_name
, cu.vn_address as address,cu.vn_city as city,cu.vn_country as country,cu.vn_gst as gst
,cu.vn_phone1 as phone,cu.vn_email as email
                ,DATE_FORMAT(srm.prm_date, '%d-%b-%Y') as srm_date,srm.prm_amount as net_amount,srm.prm_tax_amount as tax
                ,srm.branch_id,IFNULL(cu.vn_balance, 0) as outstanding_amt,srm.prm_invoice_no as invoiceNum
                 FROM tbl_purchase_return_master srm inner join tbl_vendor cu on cu.vn_id = srm.vendor_id
                left join tbl_user_details ud on ud.user_id = srm.prm_userid WHERE srm.prm_id='" + returnNo + "' ";
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
            String qryItems = @"SELECT sri.itm_code,sri.itm_name,sri.pri_qty as qty,(sri.pi_price/((sri.pri_tax_percentage/100)+ 1)) as price ,((sri.pi_price/((sri.pri_tax_percentage/100)+ 1)) *sri.pri_qty) as pri_total,0 as dis_rate
, 0 as dis_amount,itm_mrp
            ,pri_total as net_amount,((((sri.pi_price/((sri.pri_tax_percentage/100)+ 1)) * sri.pri_qty) * sri.pri_tax_percentage) / 100) as tax 
               FROM tbl_purchase_return_items sri inner join tbl_itembranch_stock tis on tis.itbs_id = sri.itbs_id WHERE sri.prm_id = '" + returnNo + "'";
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