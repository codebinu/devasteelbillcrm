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

public partial class sales_DownloadInvoicePDF : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        string billno = Session["invoice_ref_number"].ToString();

        mySqlConnection db = new mySqlConnection();
        String orderQry = "SELECT cu.cust_id, sm.sm_id,sm.sm_refno, cu.cust_name,concat(ud.first_name,' ',ud.last_name) as staff_name,cu.cust_address as address,cu.cust_city as city,cu.cust_country as country,cust_tax_reg_id as gst,cu.cust_state as state,cu.cust_phone as phone,cu.cust_email as email "
                + " ,DATE_FORMAT(sm.sm_processed_date, '%d-%b-%Y') as sm_date,sm.sm_netamount as net_amount,sm_total as total,sm_tax_amount as tax,sm_discount_amount as discAmt,sm_tax_excluded_amt as taxExcluded,sm.sm_userid,sm_payment_type"
                + " ,sm.branch_id,IFNULL(cu.cust_amount,0) as outstanding_amt,sum(si_item_cgst) as totalCgst,sum(si_item_sgst) as totalSgst,sum(si_item_igst) as totalIgst,IFNULL(sm_invoice_no,'NOT YET BILLED') invoiceNum "
                + " FROM tbl_sales_master sm inner join tbl_customer cu on cu.cust_id=sm.cust_id "
                + "  left join tbl_user_details ud on ud.user_id=sm.sm_userid inner join tbl_sales_items tsi on tsi.sm_id=sm.sm_id WHERE sm.sm_id ='" + billno + "' ";
        DataTable dtOrder = db.SelectQuery(orderQry);

        //fetching order items
        String qryItems = "SELECT tsi.itm_code,tsi.itm_name,si_qty as qty,si_price as price,si_foc as foc,si_item_tax "
            + " ,si_total,si_discount_rate as dis_rate,si_discount_amount as dis_amount"
            + " ,si_tax_excluded_total as taxableValue,si_net_amount as net_amount,tp_tax_code,si_item_cgst as cgst,si_item_sgst as sgst,si_item_igst as igst,si_tax_amount "
            + " FROM tbl_sales_items tsi inner join tbl_itembranch_stock tis on tis.itbs_id=tsi.itbs_id WHERE sm_id='" + dtOrder.Rows[0]["sm_refno"].ToString() + "' and si_itm_type!=2";
        DataTable dtItems = db.SelectQuery(qryItems);

        Generete_Invoice_PDF(dtOrder, dtItems);
    }

    BaseFont f_cb = BaseFont.CreateFont(System.Web.Hosting.HostingEnvironment.MapPath("~/font/CALIBRIB.TTF"), BaseFont.CP1252, BaseFont.NOT_EMBEDDED);
    BaseFont f_cn = BaseFont.CreateFont(System.Web.Hosting.HostingEnvironment.MapPath("~/font/CALIBRI.TTF"), BaseFont.CP1252, BaseFont.NOT_EMBEDDED);

    // This is the method writing text to the content byte
    private void writeText(PdfContentByte cb, string Text, int X, int Y, BaseFont font, int Size)
    {
        cb.SetFontAndSize(font, Size);
        cb.ShowTextAligned(PdfContentByte.ALIGN_LEFT, Text, X, Y, 0);
    }

    public void Generete_Invoice_PDF(DataTable dtOrder, DataTable dtItems)
    {
              try
        {
            using (MemoryStream fs = new MemoryStream())
            {
                Document document = new Document(PageSize.A4, 25, 25, 30, 1);
                PdfWriter writer = PdfWriter.GetInstance(document, fs);

                // Open the document to enable you to write to the document
                document.Open();

                // Makes it possible to add text to a specific place in the document using a X & Y placement syntax.
                PdfContentByte cb = writer.DirectContent;

                // First we must activate writing
                cb.BeginText();

                int left_margin = 0;
                int top_margin = 715;
                int lastwriteposition = 240;

                // HEADER 
                left_margin = 22;

                string sm_payment_type = dtOrder.Rows[0]["sm_payment_type"].ToString();
                if (sm_payment_type == "1") { sm_payment_type = "CASH"; }
                else if (sm_payment_type == "2") { sm_payment_type = "CREDIT"; }
                else if (sm_payment_type == "3") { sm_payment_type = "BILL TO BILL"; }
                else { sm_payment_type = "UNAVAILABLE"; }

                writeText(cb, "", left_margin, top_margin - 12, f_cn, 10);
                writeText(cb, dtOrder.Rows[0]["cust_name"].ToString(), left_margin+40, 673, f_cn, 11);
                writeText(cb, dtOrder.Rows[0]["city"].ToString(), left_margin, 661, f_cn, 11);
                writeText(cb, "TRN " + dtOrder.Rows[0]["gst"].ToString(), left_margin, 649, f_cn, 11);
                writeText(cb, "Place of Supply : " + dtOrder.Rows[0]["city"].ToString(), left_margin, 637, f_cn, 10);

                writeText(cb, sm_payment_type, 290, 636, f_cb, 12);

                writeText(cb, dtOrder.Rows[0]["invoiceNum"].ToString(), 455, 680, f_cb, 11);
                writeText(cb, dtOrder.Rows[0]["sm_date"].ToString(), 455, 660, f_cb, 11);
                writeText(cb, sm_payment_type, 455, 640, f_cb, 11);
                writeText(cb, dtOrder.Rows[0]["staff_name"].ToString(), 455, 620, f_cb, 10);


                // First item line position starts here
                top_margin = 560;
                left_margin = 10;

                Int32 max_itm_name_lgth = 34;

                Int32 item_count = dtItems.Rows.Count;
                int sl = 0;
                for (int i = 0; i < item_count; i++)
                {
                    sl = sl + 1;
                    // This is the line spacing, if you change the font size, you might want to change this as well.
                    top_margin -= 12;
                    writeText(cb, (sl).ToString(), 22, top_margin, f_cn, 10);

                    Int32 current_itmnamelngth = Convert.ToInt32((dtItems.Rows[i]["itm_name"].ToString()).Length.ToString());
                    Int32 no_of_itmnamerows = (current_itmnamelngth - 1) / max_itm_name_lgth;
                    string item_name = dtItems.Rows[i]["itm_name"].ToString();

                    if (no_of_itmnamerows > 0) // MULTIPLE ROWS NEEDED
                    {
                        // string sub = input.Substring(0, 3);
                        // str.Substring(10, str.Length-10) - remove
                        for (int j = 0; j <= no_of_itmnamerows; j++)
                        {
                            if (item_name.Length > max_itm_name_lgth)
                            {
                                var input_item_name = item_name.Substring(0, max_itm_name_lgth);
                                writeText(cb, input_item_name.ToString(), 44, top_margin, f_cn, 10);
                                if (j == 0)
                                {
                                    writeText(cb, "PKT", 235, top_margin, f_cn, 10);
                                    writeText(cb, dtItems.Rows[i]["qty"].ToString(), 255, top_margin, f_cn, 10);
                                    writeText(cb, dtItems.Rows[i]["price"].ToString(), 275, top_margin, f_cn, 10);
                                    writeText(cb, dtItems.Rows[i]["dis_rate"].ToString(), 320, top_margin, f_cn, 10);
                                    writeText(cb, dtItems.Rows[i]["taxableValue"].ToString(), 353, top_margin, f_cn, 10);
                                    writeText(cb, dtItems.Rows[i]["si_item_tax"].ToString(), 405, top_margin, f_cn, 10);
                                    writeText(cb, dtItems.Rows[i]["si_tax_amount"].ToString(), 435, top_margin, f_cn, 10);
                                    writeText(cb, dtItems.Rows[i]["net_amount"].ToString(), 485, top_margin, f_cn, 10);
                                }
                                item_name = item_name.Remove(0, max_itm_name_lgth);
                                if (j != no_of_itmnamerows)
                                {
                                    top_margin -= 12;
                                }
                            }
                            else
                            {
                                writeText(cb, item_name.ToString(), 22, top_margin, f_cn, 10);
                                //top_margin -= 12;
                            }
                        }
                    }
                    else
                    {
                        writeText(cb, dtItems.Rows[i]["itm_name"].ToString(), 44, top_margin, f_cn, 10);
                        writeText(cb, "PKT", 235, top_margin, f_cn, 10);
                        writeText(cb, dtItems.Rows[i]["qty"].ToString(), 255, top_margin, f_cn, 10);
                        writeText(cb, dtItems.Rows[i]["price"].ToString(), 275, top_margin, f_cn, 10);
                        writeText(cb, dtItems.Rows[i]["dis_rate"].ToString(), 320, top_margin, f_cn, 10);
                        writeText(cb, dtItems.Rows[i]["taxableValue"].ToString(), 353, top_margin, f_cn, 10);
                        writeText(cb, dtItems.Rows[i]["si_item_tax"].ToString(), 405, top_margin, f_cn, 10);
                        writeText(cb, dtItems.Rows[i]["si_tax_amount"].ToString(), 435, top_margin, f_cn, 10);
                        writeText(cb, dtItems.Rows[i]["net_amount"].ToString(), 485, top_margin, f_cn, 10);
                    }

                    // writeText(cb, dtItems.Rows[i]["itm_name"].ToString(), 40, top_margin, f_cn, 10);


                    if (top_margin <= lastwriteposition)
                    {
                        writeText(cb, "Continue", 485, top_margin - 12, f_cb, 12);
                        // We need to end the writing before we change the page
                        cb.EndText();
                        // Make the page break
                        document.NewPage();
                        // Start the writing again
                        cb.BeginText();
                        // Assign the new write location on page two!
                        // Here you might want to implement a new header function for the new page
                        top_margin = 720;

                        writeText(cb, "", left_margin, top_margin - 12, f_cn, 10);
                        writeText(cb, dtOrder.Rows[0]["cust_name"].ToString(), left_margin+40, 673, f_cn, 11);
                        writeText(cb, dtOrder.Rows[0]["city"].ToString(), left_margin, 661, f_cn, 11);
                        writeText(cb, "TRN " + dtOrder.Rows[0]["gst"].ToString(), left_margin, 649, f_cn, 11);
                        writeText(cb, "Place of Supply : " + dtOrder.Rows[0]["city"].ToString(), left_margin, 637, f_cn, 10);

                        writeText(cb, sm_payment_type, 290, 636, f_cb, 12);

                        writeText(cb, dtOrder.Rows[0]["invoiceNum"].ToString(), 455, 680, f_cb, 11);
                        writeText(cb, dtOrder.Rows[0]["sm_date"].ToString(), 455, 660, f_cb, 11);
                        writeText(cb, sm_payment_type, 455, 640, f_cb, 11);
                        writeText(cb, dtOrder.Rows[0]["staff_name"].ToString(), 455, 620, f_cb, 10);

                        top_margin = 550;
                        left_margin = 8;
                    }


                    if (i == item_count - 1)
                    {
                        writeText(cb, dtOrder.Rows[0]["taxExcluded"].ToString(), 348, 203, f_cb, 10);
                        writeText(cb, dtOrder.Rows[0]["tax"].ToString(), 440, 203, f_cb, 10);
                        writeText(cb, dtOrder.Rows[0]["net_amount"].ToString(), 485, 203, f_cb, 12);
                        //NumtoText nb = new NumtoText();
                        //var word_text = nb.ConvertToWords(Convert.ToString(dtOrder.Rows[0]["net_amount"]));
                        //NumWords1 nw = new NumWords1();
                        //var words = ToWords(Convert.ToDecimal(dtOrder.Rows[0]["net_amount"].ToString()));
                        //writeText(cb, words, 18, 203, f_cb, 10);
                        // var words = ToWords(Convert.ToDecimal(dtOrder.Rows[0]["net_amount"].ToString()));
                        //var words_tax = ToWords(Convert.ToDecimal(dtOrder.Rows[0]["tax"].ToString()));
                        //writeText(cb, words, 110, 170, f_cb, 10);
                        //writeText(cb, words_tax, 110, 150, f_cb, 10);
                    }

                    // IF FOC AVAILABLE then REPEAT
                    if (Convert.ToInt32(dtItems.Rows[i]["foc"]) > 0)
                    {
                        // This is the line spacing, if you change the font size, you might want to change this as well.
                        sl = sl + 1;
                        top_margin -= 12;
                        writeText(cb, (sl).ToString(), 0, top_margin, f_cn, 10);

                        current_itmnamelngth = Convert.ToInt32((dtItems.Rows[i]["itm_name"].ToString()).Length.ToString());
                        no_of_itmnamerows = (current_itmnamelngth - 1) / max_itm_name_lgth;
                        item_name = dtItems.Rows[i]["itm_name"].ToString();

                        if (no_of_itmnamerows > 0) // MULTIPLE ROWS NEEDED
                        {
                            // string sub = input.Substring(0, 3);
                            // str.Substring(10, str.Length-10) - remove
                            for (int j = 0; j <= no_of_itmnamerows; j++)
                            {
                                if (item_name.Length > max_itm_name_lgth)
                                {
                                    var input_item_name = item_name.Substring(0, max_itm_name_lgth);
                                    writeText(cb, input_item_name.ToString(), 18, top_margin, f_cn, 10);
                                    if (j == 0)
                                    {
                                        writeText(cb, "PKT", 195, top_margin, f_cn, 10);
                                        writeText(cb, dtItems.Rows[i]["foc"].ToString(), 230, top_margin, f_cn, 10);
                                        writeText(cb, dtItems.Rows[i]["price"].ToString(), 270, top_margin, f_cn, 10);
                                        writeText(cb, "100%", 315, top_margin, f_cn, 10);
                                        writeText(cb, "", 348, top_margin, f_cn, 10);
                                        writeText(cb, dtItems.Rows[i]["si_item_tax"].ToString(), 410, top_margin, f_cn, 10);
                                        writeText(cb, "", 440, top_margin, f_cn, 10);
                                        writeText(cb, "", 485, top_margin, f_cn, 10);
                                    }
                                    item_name = item_name.Remove(0, max_itm_name_lgth);
                                    if (j != no_of_itmnamerows)
                                    {
                                        top_margin -= 12;
                                    }
                                }
                                else
                                {
                                    writeText(cb, item_name.ToString(), 22, top_margin, f_cn, 10);
                                    //top_margin -= 12;
                                }
                            }
                        }
                        else
                        {
                            writeText(cb, dtItems.Rows[i]["itm_name"].ToString(), 22, top_margin, f_cn, 10);
                            writeText(cb, "PKT", 195, top_margin, f_cn, 10);
                            writeText(cb, dtItems.Rows[i]["foc"].ToString(), 230, top_margin, f_cn, 10);
                            writeText(cb, dtItems.Rows[i]["price"].ToString(), 270, top_margin, f_cn, 10);
                            writeText(cb, "100%", 315, top_margin, f_cn, 10);
                            writeText(cb, "", 348, top_margin, f_cn, 10);
                            writeText(cb, dtItems.Rows[i]["si_item_tax"].ToString(), 410, top_margin, f_cn, 10);
                            writeText(cb, "", 440, top_margin, f_cn, 10);
                            writeText(cb, "", 485, top_margin, f_cn, 10);
                        }

                        // writeText(cb, dtItems.Rows[i]["itm_name"].ToString(), 40, top_margin, f_cn, 10);


                        if (top_margin <= lastwriteposition)
                        {
                            writeText(cb, "Continue", 485, top_margin - 12, f_cb, 12);
                            // We need to end the writing before we change the page
                            cb.EndText();
                            // Make the page break
                            document.NewPage();
                            // Start the writing again
                            cb.BeginText();
                            // Assign the new write location on page two!
                            // Here you might want to implement a new header function for the new page
                            top_margin = 720;

                            writeText(cb, "", left_margin, top_margin - 12, f_cn, 10);
                            writeText(cb, dtOrder.Rows[0]["cust_name"].ToString(), left_margin+40, 673, f_cn, 11);
                            writeText(cb, dtOrder.Rows[0]["city"].ToString(), left_margin, 661, f_cn, 11);
                            writeText(cb, "TRN " + dtOrder.Rows[0]["gst"].ToString(), left_margin, 649, f_cn, 11);
                            writeText(cb, "Place of Supply : " + dtOrder.Rows[0]["city"].ToString(), left_margin, 637, f_cn, 10);

                            writeText(cb, sm_payment_type, 290, 636, f_cb, 12);

                            writeText(cb, dtOrder.Rows[0]["invoiceNum"].ToString(), 455, 680, f_cb, 11);
                            writeText(cb, dtOrder.Rows[0]["sm_date"].ToString(), 455, 660, f_cb, 11);
                            writeText(cb, sm_payment_type, 455, 640, f_cb, 11);
                            writeText(cb, dtOrder.Rows[0]["staff_name"].ToString(), 455, 620, f_cb, 10);

                            top_margin = 550;
                            left_margin = 8;
                        }


                        if (i == item_count - 1)
                        {
                            writeText(cb, dtOrder.Rows[0]["taxExcluded"].ToString(), 348, 203, f_cb, 10);
                            writeText(cb, dtOrder.Rows[0]["tax"].ToString(), 440, 203, f_cb, 10);
                            writeText(cb, dtOrder.Rows[0]["net_amount"].ToString(), 485, 203, f_cb, 12);
                            //NumtoText nb = new NumtoText();
                            //var word_text = nb.ConvertToWords(Convert.ToString(dtOrder.Rows[0]["net_amount"]));
                            //NumWords1 nw = new NumWords1();
                            var words = ToWords(Convert.ToDecimal(dtOrder.Rows[0]["net_amount"].ToString()));
                            //var words_tax = ToWords(Convert.ToDecimal(dtOrder.Rows[0]["tax"].ToString()));
                            //writeText(cb, words, 110, 170, f_cb, 10);
                            //writeText(cb, words_tax, 110, 150, f_cb, 10);
                        }
                    }

                }

                // Close the document, the writer and the filestream!
                cb.EndText();
                document.Close();
                writer.Close();
                fs.Close();

                Response.ContentType = "pdf/application";
                Response.AddHeader("content-disposition", "attachment;filename=Invoice_" + dtOrder.Rows[0]["invoiceNum"].ToString() + ".pdf");
                Response.OutputStream.Write(fs.GetBuffer(), 0, fs.GetBuffer().Length);
            }
        }
        catch (Exception e)
        {

        }

    }

    public string ToWords(decimal value)
    {
        string decimals = "";
        string input = Math.Round(value, 2).ToString();

        if (input.Contains("."))
        {
            decimals = input.Substring(input.IndexOf(".") + 1);
            // remove decimal part from input
            input = input.Remove(input.IndexOf("."));
        }

        // Convert input into words. save it into strWords
        string strWords = GetWords(input) + " Dirhams";


        if (decimals.Length > 0)
        {
            // if there is any decimal part convert it to words and add it to strWords.
            strWords += " and " + GetWords(decimals) + " Fils Only";
        }
        else
        {

            strWords += " Only";
        }

        return strWords;
    }

    public string GetWords(string input)
    {
        // these are seperators for each 3 digit in numbers. you can add more if you want convert beigger numbers.
        string[] seperators = { "", " Thousand ", " Million ", " Billion " };

        // Counter is indexer for seperators. each 3 digit converted this will count.
        int i = 0;

        string strWords = "";

        while (input.Length > 0)
        {
            // get the 3 last numbers from input and store it. if there is not 3 numbers just use take it.
            string _3digits = input.Length < 3 ? input : input.Substring(input.Length - 3);
            // remove the 3 last digits from input. if there is not 3 numbers just remove it.
            input = input.Length < 3 ? "" : input.Remove(input.Length - 3);

            int no = int.Parse(_3digits);
            // Convert 3 digit number into words.
            _3digits = GetWord(no);

            // apply the seperator.
            _3digits += seperators[i];
            // since we are getting numbers from right to left then we must append resault to strWords like this.
            strWords = _3digits + strWords;

            // 3 digits converted. count and go for next 3 digits
            i++;
        }
        return strWords;
    }

    // your method just to convert 3digit number into words.
    public string GetWord(int no)
    {
        string[] Ones =
		{
			"One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven",
			"Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Ninteen"
		};

        string[] Tens = { "Ten", "Twenty", "Thirty", "Fourty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninty" };

        string word = "";

        if (no > 99 && no < 1000)
        {
            int i = no / 100;
            word = word + Ones[i - 1] + " Hundred ";
            no = no % 100;
        }

        if (no > 19 && no < 100)
        {
            int i = no / 10;
            word = word + Tens[i - 1] + " ";
            no = no % 10;
        }

        if (no > 0 && no < 20)
        {
            word = word + Ones[no - 1];
        }

        return word;
    }


}