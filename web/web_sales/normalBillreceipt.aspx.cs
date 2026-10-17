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




public partial class sales_normalBillreceipt : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {

    }

    BaseFont f_cb = BaseFont.CreateFont(System.Web.Hosting.HostingEnvironment.MapPath("~/font/CALIBRIB.TTF"), BaseFont.CP1252, BaseFont.NOT_EMBEDDED);
    BaseFont f_cn = BaseFont.CreateFont(System.Web.Hosting.HostingEnvironment.MapPath("~/font/CALIBRI.TTF"), BaseFont.CP1252, BaseFont.NOT_EMBEDDED);

    [WebMethod]
    public static string showBillReceipt(string billno)
    {
        mySqlConnection db = new mySqlConnection();
        StringBuilder sb = new StringBuilder();
        try
        {
            sb.Append("{");
            //fetching order details
            String orderQry = "SELECT cu.cust_id, sm.sm_id,sm.sm_refno, cu.cust_name,concat(ud.first_name,' ',ud.last_name) as staff_name,cu.cust_address as address,cu.cust_city as city,cu.cust_country as country,cust_tax_reg_id as gst,cu.cust_state as state,cu.cust_phone as phone,cu.cust_email as email "
                + " ,DATE_FORMAT(sm.sm_processed_date, '%d-%b-%Y %h:%i %p') as sm_date,sm.sm_netamount as net_amount,sm_total as total,sm_tax_amount as tax,sm_discount_amount as discAmt,sm_tax_excluded_amt as taxExcluded,sm.sm_userid,sm_payment_type"
                + " ,sm.branch_id,IFNULL(cu.cust_amount,0) as outstanding_amt,sum(si_item_cgst) as totalCgst,sum(si_item_sgst) as totalSgst,sum(si_item_igst) as totalIgst,IFNULL(sm_invoice_no,'NOT YET BILLED') as invoiceNum "
                + " FROM tbl_sales_master sm inner join tbl_customer cu on cu.cust_id=sm.cust_id "
                + "  left join tbl_user_details ud on ud.user_id=sm.sm_userid inner join tbl_sales_items tsi on tsi.sm_id=sm.sm_id WHERE sm.sm_id ='" + billno + "' ";
            DataTable dtOrder = db.SelectQuery(orderQry);
            sb.Append("\"order\":");
            sb.Append(JsonConvert.SerializeObject(dtOrder, Formatting.Indented));
            // fetching branch details
            string branchQry = "SELECT branch_id,branch_name,branch_countryid,branch_bill_disclosure,branch_bill_footer,branch_address,branch_country_name,branch_image,branch_reg_id,branch_email,branch_declaration FROM tbl_branch WHERE branch_id='" + Convert.ToString(dtOrder.Rows[0]["branch_id"]) + "' ";
            DataTable dtBranches = db.SelectQuery(branchQry);
            sb.Append(",");
            sb.Append("\"branch\":");
            sb.Append(JsonConvert.SerializeObject(dtBranches, Formatting.Indented));
            //fetching order items
            String qryItems = "SELECT tsi.itm_code,tsi.itm_name,si_qty as qty,si_price as price,si_foc as foc "
                + " ,si_total,si_discount_rate as dis_rate,si_discount_amount as dis_amount"
                + " ,si_tax_excluded_total as taxableValue,si_net_amount as net_amount,tp_tax_code,si_item_cgst as cgst,si_item_sgst as sgst,si_item_igst as igst,si_tax_amount "
                + " FROM tbl_sales_items tsi inner join tbl_itembranch_stock tis on tis.itbs_id=tsi.itbs_id WHERE sm_id='" + dtOrder.Rows[0]["sm_refno"].ToString() + "' and si_itm_type!=2";
            DataTable dtItems = db.SelectQuery(qryItems);
            sb.Append(",");
            sb.Append("\"items\":");
            sb.Append(JsonConvert.SerializeObject(dtItems, Formatting.Indented));
            //fetching payment details
            String paymentQry = "select sm_id as orderid,DATE_FORMAT(sm_date, '%d-%b-%Y %H:%i:%s') as date"
                + " ,IFNULL(sm_chq_amt,0) as chk_amt,IFNULL(sm_card_amt,0) as card_amt,IFNULL(sm_cash_amt,0) as cash_amt"
                + " ,IFNULL(sm_wallet_amt,0) as wlt_amt,sm_paid as paid,sm_balance as balance "
                + " from tbl_sales_master where sm_refno='" + dtOrder.Rows[0]["sm_refno"].ToString() + "'";
            DataTable dtPay = db.SelectQuery(paymentQry);
            sb.Append(",");
            sb.Append("\"payment_details\":");
            sb.Append(JsonConvert.SerializeObject(dtPay, Formatting.Indented));
            //fetching return details
            String retHeadQry = "SELECT `srm_id`, `sm_id`, DATE_FORMAT(`srm_date`, '%d-%b-%Y %h:%i %p') as date,`srm_amount` as amt "
                + " FROM `tbl_salesreturn_master` WHERE `sm_id`='" + dtOrder.Rows[0]["sm_refno"].ToString() + "'";
            DataTable dtRetHead = db.SelectQuery(retHeadQry);
            List<dynamic> lstReturn = new List<dynamic>();
            for (int i = 0; i < dtRetHead.Rows.Count; i++)
            {
                dynamic retObj = new ExpandoObject();
                retObj.id = dtRetHead.Rows[i]["srm_id"];
                retObj.date = dtRetHead.Rows[i]["date"];
                retObj.amount = dtRetHead.Rows[i]["amt"];
                string qryRetItems = "SELECT `itm_code`, `itm_name`, `si_price` as price"
                    + " , `sri_qty` as qty, `sri_discount_amount` as discount, `sri_total` as total "
                    + " FROM `tbl_salesreturn_items` WHERE srm_id='" + dtRetHead.Rows[i]["srm_id"] + "'";
                DataTable dtRetItems = db.SelectQuery(qryRetItems);
                retObj.items = dtRetItems;
                lstReturn.Add(retObj);
            }
            sb.Append(",");
            sb.Append("\"return_details\":");
            sb.Append(JsonConvert.SerializeObject(lstReturn, Formatting.Indented));
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

    // This is the method writing text to the content byte
    private void writeText(PdfContentByte cb, string Text, int X, int Y, BaseFont font, int Size)
    {
        cb.SetFontAndSize(font, Size);
        cb.ShowTextAligned(PdfContentByte.ALIGN_LEFT, Text, X, Y, 0);
    }




    [WebMethod]
    public static string createInvoicePDF(string billno)
    {
        HttpContext.Current.Session["invoice_ref_number"] = billno;
        return "Y";
    }



    //[WebMethod]
    //public static string createInvoicePDF(string billno)
    //{
    //    mySqlConnection db = new mySqlConnection();
    //    string results = "N";
    //    try
    //    {

    //        //fetching order details
    //        String orderQry = "SELECT cu.cust_id, sm.sm_id,sm.sm_refno, cu.cust_name,concat(ud.first_name,' ',ud.last_name) as staff_name,cu.cust_address as address,cu.cust_city as city,cu.cust_country as country,cust_tax_reg_id as gst,cu.cust_state as state,cu.cust_phone as phone,cu.cust_email as email "
    //            + " ,DATE_FORMAT(sm.sm_date, '%d-%b-%Y') as sm_date,sm.sm_netamount as net_amount,sm_total as total,sm_tax_amount as tax,sm_discount_amount as discAmt,sm_tax_excluded_amt as taxExcluded,sm.total_paid,sm.total_balance,sm.sm_userid,sm_payment_type"
    //            + " ,sm.branch_id,IFNULL(cu.cust_amount,0) as outstanding_amt,cu.cust_wallet_amt as wallet_amt,sum(si_item_cgst) as totalCgst,sum(si_item_sgst) as totalSgst,sum(si_item_igst) as totalIgst,sm_invoice_no as invoiceNum "
    //            + " FROM tbl_sales_master sm inner join tbl_customer cu on cu.cust_id=sm.cust_id "
    //            + "  left join tbl_user_details ud on ud.user_id=sm.sm_userid inner join tbl_sales_items tsi on tsi.sm_id=sm.sm_id WHERE sm.sm_id ='" + billno + "' ";
    //        DataTable dtOrder = db.SelectQuery(orderQry);

    //        //fetching order items
    //        String qryItems = "SELECT tsi.itm_code,tsi.itm_name,si_qty as qty,si_price as price,si_foc as foc,si_item_tax "
    //            + " ,si_total,si_discount_rate as dis_rate,si_discount_amount as dis_amount"
    //            + " ,si_tax_excluded_total as taxableValue,si_net_amount as net_amount,tp_tax_code,si_item_cgst as cgst,si_item_sgst as sgst,si_item_igst as igst,si_tax_amount "
    //            + " FROM tbl_sales_items tsi inner join tbl_itembranch_stock tis on tis.itbs_id=tsi.itbs_id WHERE sm_id='" + dtOrder.Rows[0]["sm_refno"].ToString() + "' and si_itm_type!=2";
    //        DataTable dtItems = db.SelectQuery(qryItems);

    //        var obj = new sales_normalBillreceipt();
    //        results = obj.Generete_Invoice_PDF(dtOrder, dtItems);

    //        return "Y";
    //    }
    //    catch (Exception e)
    //    {
    //        HttpContext.Current.Response.StatusCode = 401;
    //        HttpContext.Current.Response.TrySkipIisCustomErrors = true;
    //        return "N";
    //    }
    //}

    //protected string Generete_Invoice_PDF(DataTable dtOrder, DataTable dtItems)
    //{
    //    try
    //    {
    //        using (System.IO.FileStream fs = new FileStream(Server.MapPath("invoices") + "\\" + "Invoice.pdf", FileMode.Create))
    //        {
    //            Document document = new Document(PageSize.A4, 25, 25, 30, 1);
    //            PdfWriter writer = PdfWriter.GetInstance(document, fs);

    //            // Open the document to enable you to write to the document
    //            document.Open();

    //            // Makes it possible to add text to a specific place in the document using a X & Y placement syntax.
    //            PdfContentByte cb = writer.DirectContent;

    //            // First we must activate writing
    //            cb.BeginText();

    //            int left_margin = 0;
    //            int top_margin = 720;
    //            int lastwriteposition = 230;

    //            // HEADER 
    //            left_margin = 8;

    //            writeText(cb, "", left_margin, top_margin - 12, f_cn, 10);
    //            writeText(cb, dtOrder.Rows[0]["cust_name"].ToString(), left_margin, 673, f_cn, 11);
    //            writeText(cb, dtOrder.Rows[0]["city"].ToString(), left_margin, 661, f_cn, 11);
    //            writeText(cb, "TRN " + dtOrder.Rows[0]["gst"].ToString(), left_margin, 649, f_cn, 11);
    //            writeText(cb, "Place of Supply : " + dtOrder.Rows[0]["city"].ToString(), left_margin, 637, f_cn, 10);

    //            writeText(cb, "CREDIT", 290, 620, f_cb, 12);

    //            writeText(cb, dtOrder.Rows[0]["invoiceNum"].ToString(), 455, 680, f_cb, 11);
    //            writeText(cb, dtOrder.Rows[0]["sm_date"].ToString(), 455, 660, f_cb, 11);
    //            writeText(cb, "CREDIT", 455, 640, f_cb, 11);
    //            writeText(cb, dtOrder.Rows[0]["staff_name"].ToString(), 455, 620, f_cb, 10);


    //            // First item line position starts here
    //            top_margin = 550;
    //            left_margin = 8;

    //            Int32 max_itm_name_lgth = 35;

    //            Int32 item_count = dtItems.Rows.Count;
    //            for (int i = 0; i < item_count; i++)
    //            {
    //                // This is the line spacing, if you change the font size, you might want to change this as well.
    //                top_margin -= 12;
    //                writeText(cb, (i + 1).ToString(), 0, top_margin, f_cn, 10);

    //                Int32 current_itmnamelngth = Convert.ToInt32((dtItems.Rows[i]["itm_name"].ToString()).Length.ToString());
    //                Int32 no_of_itmnamerows = (current_itmnamelngth - 1) / max_itm_name_lgth;
    //                string item_name = dtItems.Rows[i]["itm_name"].ToString();

    //                if (no_of_itmnamerows > 0) // MULTIPLE ROWS NEEDED
    //                {
    //                    // string sub = input.Substring(0, 3);
    //                    // str.Substring(10, str.Length-10) - remove
    //                    for (int j = 0; j <= no_of_itmnamerows; j++)
    //                    {
    //                        if (item_name.Length > max_itm_name_lgth)
    //                        {
    //                            var input_item_name = item_name.Substring(0, max_itm_name_lgth);
    //                            writeText(cb, input_item_name.ToString(), 18, top_margin, f_cn, 10);
    //                            if (j == 0)
    //                            {
    //                                writeText(cb, "PKT", 195, top_margin, f_cn, 10);
    //                                writeText(cb, dtItems.Rows[i]["qty"].ToString(), 230, top_margin, f_cn, 10);
    //                                writeText(cb, dtItems.Rows[i]["price"].ToString(), 270, top_margin, f_cn, 10);
    //                                writeText(cb, dtItems.Rows[i]["dis_rate"].ToString(), 315, top_margin, f_cn, 10);
    //                                writeText(cb, dtItems.Rows[i]["taxableValue"].ToString(), 348, top_margin, f_cn, 10);
    //                                writeText(cb, dtItems.Rows[i]["si_item_tax"].ToString(), 410, top_margin, f_cn, 10);
    //                                writeText(cb, dtItems.Rows[i]["si_tax_amount"].ToString(), 440, top_margin, f_cn, 10);
    //                                writeText(cb, dtItems.Rows[i]["net_amount"].ToString(), 485, top_margin, f_cn, 10);
    //                            }
    //                            item_name = item_name.Remove(0, max_itm_name_lgth);
    //                            if (j != no_of_itmnamerows)
    //                            {
    //                                top_margin -= 12;
    //                            }
    //                        }
    //                        else
    //                        {
    //                            writeText(cb, item_name.ToString(), 18, top_margin, f_cn, 10);
    //                            //top_margin -= 12;
    //                        }
    //                    }
    //                }
    //                else
    //                {
    //                    writeText(cb, dtItems.Rows[i]["itm_name"].ToString(), 18, top_margin, f_cn, 10);
    //                    writeText(cb, "PKT", 195, top_margin, f_cn, 10);
    //                    writeText(cb, dtItems.Rows[i]["qty"].ToString(), 230, top_margin, f_cn, 10);
    //                    writeText(cb, dtItems.Rows[i]["price"].ToString(), 270, top_margin, f_cn, 10);
    //                    writeText(cb, dtItems.Rows[i]["dis_rate"].ToString(), 315, top_margin, f_cn, 10);
    //                    writeText(cb, dtItems.Rows[i]["taxableValue"].ToString(), 348, top_margin, f_cn, 10);
    //                    writeText(cb, dtItems.Rows[i]["si_item_tax"].ToString(), 410, top_margin, f_cn, 10);
    //                    writeText(cb, dtItems.Rows[i]["si_tax_amount"].ToString(), 440, top_margin, f_cn, 10);
    //                    writeText(cb, dtItems.Rows[i]["net_amount"].ToString(), 485, top_margin, f_cn, 10);
    //                }

    //                // writeText(cb, dtItems.Rows[i]["itm_name"].ToString(), 40, top_margin, f_cn, 10);


    //                if (top_margin <= lastwriteposition)
    //                {
    //                    writeText(cb, "Continue", 485, top_margin - 12, f_cb, 12);
    //                    // We need to end the writing before we change the page
    //                    cb.EndText();
    //                    // Make the page break
    //                    document.NewPage();
    //                    // Start the writing again
    //                    cb.BeginText();
    //                    // Assign the new write location on page two!
    //                    // Here you might want to implement a new header function for the new page
    //                    top_margin = 720;

    //                    writeText(cb, "", left_margin, top_margin - 12, f_cn, 10);
    //                    writeText(cb, dtOrder.Rows[0]["cust_name"].ToString(), left_margin, 673, f_cn, 11);
    //                    writeText(cb, dtOrder.Rows[0]["city"].ToString(), left_margin, 661, f_cn, 11);
    //                    writeText(cb, "TRN " + dtOrder.Rows[0]["gst"].ToString(), left_margin, 649, f_cn, 11);
    //                    writeText(cb, "Place of Supply : " + dtOrder.Rows[0]["city"].ToString(), left_margin, 637, f_cn, 10);

    //                    writeText(cb, "CREDIT", 290, 620, f_cb, 12);

    //                    writeText(cb, dtOrder.Rows[0]["invoiceNum"].ToString(), 455, 680, f_cb, 11);
    //                    writeText(cb, dtOrder.Rows[0]["sm_date"].ToString(), 455, 660, f_cb, 11);
    //                    writeText(cb, "CREDIT", 455, 640, f_cb, 11);
    //                    writeText(cb, dtOrder.Rows[0]["staff_name"].ToString(), 455, 620, f_cb, 10);

    //                    top_margin = 550;
    //                    left_margin = 8;
    //                }


    //                if (i == item_count - 1)
    //                {
    //                    writeText(cb, dtOrder.Rows[0]["taxExcluded"].ToString(), 348, 185, f_cb, 10);
    //                    writeText(cb, dtOrder.Rows[0]["tax"].ToString(), 440, 185, f_cb, 10);
    //                    writeText(cb, dtOrder.Rows[0]["net_amount"].ToString(), 485, 185, f_cb, 12);
    //                }
    //            }

    //            // Close the document, the writer and the filestream!
    //            cb.EndText();
    //            document.Close();
    //            writer.Close();
    //            fs.Close();

    //            return "Y";
    //        }
    //    }
    //    catch (Exception e)
    //    {
    //        HttpContext.Current.Response.StatusCode = 401;
    //        HttpContext.Current.Response.TrySkipIisCustomErrors = true;
    //        return "N";
    //    }

    //}


}