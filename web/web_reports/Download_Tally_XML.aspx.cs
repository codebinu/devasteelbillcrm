using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using commonfunction;
using System.Data;
using System.Drawing;
using OfficeOpenXml;
using OfficeOpenXml.Style;
using System.Text;

public partial class web_reports_Download_Tally_XML : System.Web.UI.Page
{

    public static string Get_Current_Date_Time(string TimeZoneName)
    {
        var CURR_TIME_ZONE = TimeZoneInfo.FindSystemTimeZoneById(TimeZoneName);
        var TimeNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, CURR_TIME_ZONE);
        var date_time_now = TimeNow.ToString("yyyy-MM-dd_HH:mm");
        return date_time_now;
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        mySqlConnection db = new mySqlConnection();
        
        string head_qry = Session["header_xml_qry"].ToString();
        string item_qry = Session["item_xml_qry"].ToString();

        var head_dt = db.SelectQuery(head_qry);

        // 2. Fetching Order Items
        var item_dt = db.SelectQuery(item_qry);

        // 3. Selecting Unique Customers as collection - to check existance in the Tally database.
        var unique_customers = head_dt.AsEnumerable()
                    .Select(row => new {
                        cust_name = row.Field<string>("cust_name"),
                    })
                    .Distinct();

        var unique_items = item_dt.AsEnumerable()
                    .Select(row => new {
                        itm_name = row.Field<string>("itm_name"),
                    })
                    .Distinct();

        if (head_dt != null)
        {
            if (head_dt.Rows.Count > 0)
            {
                string resultXML = GenerateXMLString(head_dt, item_dt, unique_customers, unique_items);
                string newFileName = "Tally_XML_";
                var tZone = HttpUtility.UrlDecode(HttpContext.Current.Request.Cookies["invntryTimeZone"].Value);
                newFileName = newFileName + Get_Current_Date_Time(tZone);

                byte[] bytes = Encoding.ASCII.GetBytes(resultXML);

                Response.Clear();
                Response.Buffer = true;
                Response.ContentType = "application/octet-stream";
                Response.AppendHeader("Content-Disposition", "attachment; filename=" + newFileName + ".XML");
                Response.BinaryWrite(bytes);
                Response.End();
            }

        }
    }

    private static string GenerateXMLString(DataTable head_dt, DataTable item_dt, IEnumerable<object> unique_customers, IEnumerable<object> unique_items)
    {
        StringBuilder XMLString = new StringBuilder();
        try
        {
            // XML Generation Begins - XMLString.AppendLine("");
            XMLString.AppendLine("<ENVELOPE>");

            #region <HEADER>
            XMLString.AppendLine("<HEADER>");
            XMLString.AppendLine("<TALLYREQUEST> Import Data </TALLYREQUEST>");
            XMLString.AppendLine("</HEADER>");
            #endregion

            #region <BODY>
            XMLString.AppendLine("<BODY>");
            XMLString.AppendLine("<IMPORTDATA>");

            #region <REQUESTDESC>
            XMLString.AppendLine("<REQUESTDESC>");
            XMLString.AppendLine("<REPORTNAME>All Masters</REPORTNAME>");
            XMLString.AppendLine("<STATICVARIABLES>");
            XMLString.AppendLine("<SVCURRENTCOMPANY>Jupiter Ventures -(2019-20) NEW</SVCURRENTCOMPANY>");
            XMLString.AppendLine("<ImportDups>@@DupIgnore</ImportDups>");
            XMLString.AppendLine("</STATICVARIABLES>");
            XMLString.AppendLine("</REQUESTDESC>");
            #endregion

            #region <REQUESTDATA>
            XMLString.AppendLine("<REQUESTDATA>");

            #region TALLYMESSAGE 1
            XMLString.AppendLine("<TALLYMESSAGE xmlns:UDF=\"TallyUDF\">");

            #region CHECK CUSTOMER EXISTANCE
            foreach (dynamic items in unique_customers)
            {
                XMLString.AppendLine("<LEDGER NAME=\"" + items.cust_name + "\" >");
                XMLString.AppendLine("<NAME.LIST>");
                XMLString.AppendLine("<NAME>" + items.cust_name + "</NAME>");
                XMLString.AppendLine("</NAME.LIST>");
                //XMLString.AppendLine("<PARENT>Sundry Debtors</PARENT>");
                XMLString.AppendLine("<IsBillWiseOn>YES</IsBillWiseOn>");
                XMLString.AppendLine("</LEDGER>");
            }
            #endregion

            #region CHECK ITEM EXISTANCE
            foreach (dynamic items in unique_items)
            {
                XMLString.AppendLine("<STOCKITEM NAME=\"" + items.itm_name + "\">");
                XMLString.AppendLine("<NAME.LIST>");
                XMLString.AppendLine("<NAME>" + items.itm_name + "</NAME>");
                XMLString.AppendLine("</NAME.LIST>");
                //XMLString.AppendLine("<BASEUNITS>nos</BASEUNITS>");
                XMLString.AppendLine("</STOCKITEM>");
            }

            #endregion
            // XMLString.AppendLine("");

            XMLString.AppendLine("</TALLYMESSAGE>");
            #endregion

            #region TALLYMESSAGE 2
            XMLString.AppendLine("<TALLYMESSAGE xmlns:UDF=\"TallyUDF\">");

            //Looping through the Order headers
            var count = head_dt.Rows.Count;
            for (int i = 0; i < count; i++)
            {
                StringBuilder head_xml = new StringBuilder();
                StringBuilder item_xml = new StringBuilder();

                var order_id = head_dt.Rows[i]["sm_id"].ToString();
                DataTable item_data = new DataTable();
                item_data = item_dt.Clone();
                DataRow[] rowsToCopy;
                rowsToCopy = item_dt.Select("sm_id='" + order_id + "'");

                foreach (DataRow temp in rowsToCopy)
                {
                    item_data.ImportRow(temp);
                }

                var item_count = item_data.Rows.Count;
                decimal item_total = 0;
                item_total = item_data.AsEnumerable().Sum(x => x.Field<decimal>("si_net_amount"));
                var total_tax = Convert.ToDecimal(head_dt.Rows[i]["sm_tax_amount"].ToString());
                var cgst = total_tax / 2;
                var sgst = cgst;
                var roundOff = Convert.ToDecimal(head_dt.Rows[i]["sm_roundoff"].ToString());
                var netamt = Convert.ToDecimal(head_dt.Rows[i]["sm_netamount"].ToString());

                var effective_netamt = item_total + total_tax + roundOff;
                decimal difference = 0;

                if (effective_netamt != netamt)
                {
                    // need to be adjusted
                    difference = effective_netamt - netamt;
                }

                //roundOff = roundOff - difference;
                // looping through the items

                // XML GENERATION BASED ON ORDER - 

                XMLString.AppendLine("<VOUCHER REMOTEID=\"" + order_id + "\" VCHTYPE=\"" + head_dt.Rows[i]["username"].ToString() + "\" ACTION=\"Create\" OBJVIEW=\"Invoice Voucher View\">");
                //XMLString.AppendLine("<VOUCHER VCHTYPE=\"" + head_dt.Rows[i]["username"].ToString() + "\" ACTION=\"Create\" OBJVIEW=\"Invoice Voucher View\">");

                XMLString.AppendLine("<ADDRESS.LIST TYPE=\"String\">");
                XMLString.AppendLine("<ADDRESS>" + head_dt.Rows[i]["cust_address"].ToString() + "</ADDRESS>");
                XMLString.AppendLine("<ADDRESS>" + head_dt.Rows[i]["cust_city"].ToString() + "</ADDRESS>");
                XMLString.AppendLine("</ADDRESS.LIST>");

                XMLString.AppendLine("<BASICBUYERADDRESS.LIST TYPE=\"String\">");
                XMLString.AppendLine("<BASICBUYERADDRESS>" + head_dt.Rows[i]["cust_address"].ToString() + "</BASICBUYERADDRESS>");
                XMLString.AppendLine("<BASICBUYERADDRESS>" + head_dt.Rows[i]["cust_city"].ToString() + "</BASICBUYERADDRESS>");
                XMLString.AppendLine("</BASICBUYERADDRESS.LIST>");

                XMLString.AppendLine("<OLDAUDITENTRYIDS.LIST TYPE=\"Number\">");
                XMLString.AppendLine("<OLDAUDITENTRYIDS>-1</OLDAUDITENTRYIDS>");
                XMLString.AppendLine("</OLDAUDITENTRYIDS.LIST>");

                XMLString.AppendLine("<DATE>" + head_dt.Rows[i]["n_date"].ToString() + "</DATE>");
                XMLString.AppendLine("<GUID>" + order_id + "</GUID>");
                XMLString.AppendLine("<STATENAME>" + head_dt.Rows[i]["cust_state"].ToString() + "</STATENAME>");
                XMLString.AppendLine("<PRICELEVEL>" + head_dt.Rows[i]["tpm_name"].ToString() + "</PRICELEVEL>");
                XMLString.AppendLine("<COUNTRYOFRESIDENCE>India</COUNTRYOFRESIDENCE>");
                XMLString.AppendLine("<PARTYNAME>" + head_dt.Rows[i]["cust_name"].ToString() + "</PARTYNAME>");
                XMLString.AppendLine("<VOUCHERTYPENAME>" + head_dt.Rows[i]["username"].ToString() + "</VOUCHERTYPENAME>");
                XMLString.AppendLine("<VOUCHERNUMBER>" + head_dt.Rows[i]["sm_invoice_no"].ToString() + "</VOUCHERNUMBER>");
                XMLString.AppendLine("<PARTYLEDGERNAME>" + head_dt.Rows[i]["cust_name"].ToString() + "</PARTYLEDGERNAME>");
                XMLString.AppendLine("<BASICBASEPARTYNAME>" + head_dt.Rows[i]["cust_name"].ToString() + "</BASICBASEPARTYNAME>");
                XMLString.AppendLine("<CSTFORMISSUETYPE/>");
                XMLString.AppendLine("<CSTFORMRECVTYPE/>");
                XMLString.AppendLine("<FBTPAYMENTTYPE>Default</FBTPAYMENTTYPE>");
                XMLString.AppendLine("<PERSISTEDVIEW>Invoice Voucher View</PERSISTEDVIEW>");
                XMLString.AppendLine("<PLACEOFSUPPLY>" + head_dt.Rows[i]["ord_state"].ToString() + "</PLACEOFSUPPLY>");
                XMLString.AppendLine("<BASICBUYERNAME>" + head_dt.Rows[i]["cust_name"].ToString() + "</BASICBUYERNAME>");
                XMLString.AppendLine("<BASICDUEDATEOFPYMT>" + head_dt.Rows[i]["max_creditperiod"].ToString() + "</BASICDUEDATEOFPYMT>");
                XMLString.AppendLine("<BASICDATETIMEOFINVOICE>" + head_dt.Rows[i]["f_date"].ToString() + "</BASICDATETIMEOFINVOICE>");
                XMLString.AppendLine("<BASICDATETIMEOFREMOVAL>" + head_dt.Rows[i]["f_date"].ToString() + "</BASICDATETIMEOFREMOVAL>");
                XMLString.AppendLine("<VCHGSTCLASS/>");
                XMLString.AppendLine("<CONSIGNEESTATENAME>" + head_dt.Rows[i]["ord_state"].ToString() + "</CONSIGNEESTATENAME>");
                XMLString.AppendLine("<ENTEREDBY>jv</ENTEREDBY>");

                XMLString.AppendLine("<DIFFACTUALQTY>No</DIFFACTUALQTY>");
                XMLString.AppendLine("<ISMSTFROMSYNC>No</ISMSTFROMSYNC>");
                XMLString.AppendLine("<ASORIGINAL>No</ASORIGINAL>");
                XMLString.AppendLine("<AUDITED>No</AUDITED>");
                XMLString.AppendLine("<FORJOBCOSTING>No</FORJOBCOSTING>");
                XMLString.AppendLine("<ISOPTIONAL>No</ISOPTIONAL>");
                XMLString.AppendLine("<EFFECTIVEDATE>" + head_dt.Rows[i]["n_date"].ToString() + "</EFFECTIVEDATE>");
                XMLString.AppendLine("<USEFOREXCISE>No</USEFOREXCISE>");
                XMLString.AppendLine("<ISFORJOBWORKIN>No</ISFORJOBWORKIN>");
                XMLString.AppendLine("<ALLOWCONSUMPTION>No</ALLOWCONSUMPTION>");
                XMLString.AppendLine("<USEFORINTEREST>No</USEFORINTEREST>");
                XMLString.AppendLine("<USEFORGAINLOSS>No</USEFORGAINLOSS>");
                XMLString.AppendLine("<USEFORGODOWNTRANSFER>No</USEFORGODOWNTRANSFER>");
                XMLString.AppendLine("<USEFORCOMPOUND>No</USEFORCOMPOUND>");
                XMLString.AppendLine("<USEFORSERVICETAX>No</USEFORSERVICETAX>");
                XMLString.AppendLine("<ISEXCISEVOUCHER>No</ISEXCISEVOUCHER>");
                XMLString.AppendLine("<EXCISETAXOVERRIDE>No</EXCISETAXOVERRIDE>");
                XMLString.AppendLine("<USEFORTAXUNITTRANSFER>No</USEFORTAXUNITTRANSFER>");
                XMLString.AppendLine("<IGNOREPOSVALIDATION>No</IGNOREPOSVALIDATION>");
                XMLString.AppendLine("<EXCISEOPENING>No</EXCISEOPENING>");
                XMLString.AppendLine("<USEFORFINALPRODUCTION>No</USEFORFINALPRODUCTION>");
                XMLString.AppendLine("<ISTDSOVERRIDDEN>No</ISTDSOVERRIDDEN>");
                XMLString.AppendLine("<ISTCSOVERRIDDEN>No</ISTCSOVERRIDDEN>");
                XMLString.AppendLine("<ISTDSTCSCASHVCH>No</ISTDSTCSCASHVCH>");
                XMLString.AppendLine("<INCLUDEADVPYMTVCH>No</INCLUDEADVPYMTVCH>");
                XMLString.AppendLine("<ISSUBWORKSCONTRACT>No</ISSUBWORKSCONTRACT>");
                XMLString.AppendLine("<ISVATOVERRIDDEN>No</ISVATOVERRIDDEN>");
                XMLString.AppendLine("<IGNOREORIGVCHDATE>No</IGNOREORIGVCHDATE>");
                XMLString.AppendLine("<ISVATPAIDATCUSTOMS>No</ISVATPAIDATCUSTOMS>");
                XMLString.AppendLine("<ISDECLAREDTOCUSTOMS>No</ISDECLAREDTOCUSTOMS>");
                XMLString.AppendLine("<ISSERVICETAXOVERRIDDEN>No</ISSERVICETAXOVERRIDDEN>");
                XMLString.AppendLine("<ISISDVOUCHER>No</ISISDVOUCHER>");
                XMLString.AppendLine("<ISEXCISEOVERRIDDEN>No</ISEXCISEOVERRIDDEN>");
                XMLString.AppendLine("<ISEXCISESUPPLYVCH>No</ISEXCISESUPPLYVCH>");
                XMLString.AppendLine("<ISGSTOVERRIDDEN>No</ISGSTOVERRIDDEN>");
                XMLString.AppendLine("<GSTNOTEXPORTED>No</GSTNOTEXPORTED>");
                XMLString.AppendLine("<IGNOREGSTINVALIDATION>No</IGNOREGSTINVALIDATION>");
                XMLString.AppendLine("<ISVATPRINCIPALACCOUNT>No</ISVATPRINCIPALACCOUNT>");
                XMLString.AppendLine("<ISBOENOTAPPLICABLE>No</ISBOENOTAPPLICABLE>");
                XMLString.AppendLine("<ISSHIPPINGWITHINSTATE>No</ISSHIPPINGWITHINSTATE>");
                XMLString.AppendLine("<ISOVERSEASTOURISTTRANS>No</ISOVERSEASTOURISTTRANS>");
                XMLString.AppendLine("<ISDESIGNATEDZONEPARTY>No</ISDESIGNATEDZONEPARTY>");
                XMLString.AppendLine("<ISCANCELLED>No</ISCANCELLED>");
                XMLString.AppendLine("<HASCASHFLOW>No</HASCASHFLOW>");
                XMLString.AppendLine("<ISPOSTDATED>No</ISPOSTDATED>");
                XMLString.AppendLine("<USETRACKINGNUMBER>No</USETRACKINGNUMBER>");
                XMLString.AppendLine("<ISINVOICE>Yes</ISINVOICE>");
                XMLString.AppendLine("<MFGJOURNAL>No</MFGJOURNAL>");
                XMLString.AppendLine("<HASDISCOUNTS>No</HASDISCOUNTS>");
                XMLString.AppendLine("<ASPAYSLIP>No</ASPAYSLIP>");
                XMLString.AppendLine("<ISCOSTCENTRE>No</ISCOSTCENTRE>");
                XMLString.AppendLine("<ISSTXNONREALIZEDVCH>No</ISSTXNONREALIZEDVCH>");
                XMLString.AppendLine("<ISEXCISEMANUFACTURERON>No</ISEXCISEMANUFACTURERON>");
                XMLString.AppendLine("<ISBLANKCHEQUE>No</ISBLANKCHEQUE>");
                XMLString.AppendLine("<ISVOID>No</ISVOID>");
                XMLString.AppendLine("<ISONHOLD>No</ISONHOLD>");
                XMLString.AppendLine("<ORDERLINESTATUS>No</ORDERLINESTATUS>");
                XMLString.AppendLine("<VATISAGNSTCANCSALES>No</VATISAGNSTCANCSALES>");
                XMLString.AppendLine("<VATISPURCEXEMPTED>No</VATISPURCEXEMPTED>");
                XMLString.AppendLine("<ISVATRESTAXINVOICE>No</ISVATRESTAXINVOICE>");
                XMLString.AppendLine("<VATISASSESABLECALCVCH>No</VATISASSESABLECALCVCH>");
                XMLString.AppendLine("<ISVATDUTYPAID>Yes</ISVATDUTYPAID>");
                XMLString.AppendLine("<ISDELIVERYSAMEASCONSIGNEE>No</ISDELIVERYSAMEASCONSIGNEE>");
                XMLString.AppendLine("<ISDISPATCHSAMEASCONSIGNOR>No</ISDISPATCHSAMEASCONSIGNOR>");
                XMLString.AppendLine("<ISDELETED>No</ISDELETED>");
                XMLString.AppendLine("<CHANGEVCHMODE>No</CHANGEVCHMODE>");

                XMLString.AppendLine("<ALTERID> " + order_id + "</ALTERID>");
                XMLString.AppendLine("<MASTERID> " + order_id + "</MASTERID>");
                XMLString.AppendLine("<VOUCHERKEY>" + order_id + "</VOUCHERKEY>");

                XMLString.AppendLine("<LEDGERENTRIES.LIST>");

                XMLString.AppendLine("<OLDAUDITENTRYIDS.LIST TYPE=\"Number\">");
                XMLString.AppendLine("<OLDAUDITENTRYIDS>-1</OLDAUDITENTRYIDS>");
                XMLString.AppendLine("</OLDAUDITENTRYIDS.LIST>");

                XMLString.AppendLine("<LEDGERNAME>" + head_dt.Rows[i]["cust_name"].ToString() + "</LEDGERNAME>");
                XMLString.AppendLine("<GSTCLASS/>");
                XMLString.AppendLine("<ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>");
                XMLString.AppendLine("<LEDGERFROMITEM>No</LEDGERFROMITEM>");
                XMLString.AppendLine("<REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>");
                XMLString.AppendLine("<ISPARTYLEDGER>Yes</ISPARTYLEDGER>");
                XMLString.AppendLine("<ISLASTDEEMEDPOSITIVE>Yes</ISLASTDEEMEDPOSITIVE>");
                XMLString.AppendLine("<ISCAPVATTAXALTERED>No</ISCAPVATTAXALTERED>");
                XMLString.AppendLine("<ISCAPVATNOTCLAIMED>No</ISCAPVATNOTCLAIMED>");
                XMLString.AppendLine("<AMOUNT>-" + head_dt.Rows[i]["sm_netamount"].ToString() + "</AMOUNT>");
                XMLString.AppendLine("<SERVICETAXDETAILS.LIST>       </SERVICETAXDETAILS.LIST>");
                XMLString.AppendLine("<BANKALLOCATIONS.LIST>       </BANKALLOCATIONS.LIST>");

                XMLString.AppendLine("<BILLALLOCATIONS.LIST>");
                XMLString.AppendLine("<NAME>" + head_dt.Rows[i]["sm_invoice_no"].ToString() + "</NAME>");
                XMLString.AppendLine("<BILLCREDITPERIOD JD=\"43555\" P=\"" + head_dt.Rows[i]["max_creditperiod"].ToString() + "\">" + head_dt.Rows[i]["max_creditperiod"].ToString() + "</BILLCREDITPERIOD>");
                XMLString.AppendLine("<BILLTYPE>New Ref</BILLTYPE>");
                XMLString.AppendLine("<TDSDEDUCTEEISSPECIALRATE>No</TDSDEDUCTEEISSPECIALRATE>");
                XMLString.AppendLine("<AMOUNT>-" + head_dt.Rows[i]["sm_netamount"].ToString() + "</AMOUNT>");
                XMLString.AppendLine("</BILLALLOCATIONS.LIST>");
                XMLString.AppendLine("</LEDGERENTRIES.LIST>");

                //roundOff = roundOff * -1;

                XMLString.AppendLine("<LEDGERENTRIES.LIST>");
                XMLString.AppendLine("<OLDAUDITENTRYIDS.LIST TYPE=\"Number\">");
                XMLString.AppendLine("<OLDAUDITENTRYIDS>-1</OLDAUDITENTRYIDS>");
                XMLString.AppendLine("</OLDAUDITENTRYIDS.LIST>");
                XMLString.AppendLine("<ROUNDTYPE/>");
                XMLString.AppendLine("<LEDGERNAME>CGST</LEDGERNAME>");
                XMLString.AppendLine("<GSTCLASS/>");
                XMLString.AppendLine("<ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>");
                XMLString.AppendLine("<LEDGERFROMITEM>No</LEDGERFROMITEM>");
                XMLString.AppendLine("<REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>");
                XMLString.AppendLine("<ISPARTYLEDGER>No</ISPARTYLEDGER>");
                XMLString.AppendLine("<ISLASTDEEMEDPOSITIVE>No</ISLASTDEEMEDPOSITIVE>");
                XMLString.AppendLine("<ISCAPVATTAXALTERED>No</ISCAPVATTAXALTERED>");
                XMLString.AppendLine("<ISCAPVATNOTCLAIMED>No</ISCAPVATNOTCLAIMED>");
                XMLString.AppendLine("<AMOUNT>" + cgst + "</AMOUNT>");
                XMLString.AppendLine("<VATEXPAMOUNT>" + cgst + "</VATEXPAMOUNT>");
                XMLString.AppendLine("</LEDGERENTRIES.LIST>");

                XMLString.AppendLine("<LEDGERENTRIES.LIST>");
                XMLString.AppendLine("<OLDAUDITENTRYIDS.LIST TYPE=\"Number\">");
                XMLString.AppendLine("<OLDAUDITENTRYIDS>-1</OLDAUDITENTRYIDS>");
                XMLString.AppendLine("</OLDAUDITENTRYIDS.LIST>");
                XMLString.AppendLine("<ROUNDTYPE/>");
                XMLString.AppendLine("<LEDGERNAME>SGST</LEDGERNAME>");
                XMLString.AppendLine("<GSTCLASS/>");
                XMLString.AppendLine("<ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>");
                XMLString.AppendLine("<LEDGERFROMITEM>No</LEDGERFROMITEM>");
                XMLString.AppendLine("<REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>");
                XMLString.AppendLine("<ISPARTYLEDGER>No</ISPARTYLEDGER>");
                XMLString.AppendLine("<ISLASTDEEMEDPOSITIVE>No</ISLASTDEEMEDPOSITIVE>");
                XMLString.AppendLine("<ISCAPVATTAXALTERED>No</ISCAPVATTAXALTERED>");
                XMLString.AppendLine("<ISCAPVATNOTCLAIMED>No</ISCAPVATNOTCLAIMED>");
                XMLString.AppendLine("<AMOUNT>" + sgst + "</AMOUNT>");
                XMLString.AppendLine("<VATEXPAMOUNT>" + sgst + "</VATEXPAMOUNT>");
                XMLString.AppendLine("</LEDGERENTRIES.LIST>");

                XMLString.AppendLine("<LEDGERENTRIES.LIST>");
                XMLString.AppendLine("<OLDAUDITENTRYIDS.LIST TYPE=\"Number\">");
                XMLString.AppendLine("<OLDAUDITENTRYIDS>-1</OLDAUDITENTRYIDS>");
                XMLString.AppendLine("</OLDAUDITENTRYIDS.LIST>");
                XMLString.AppendLine("<ROUNDTYPE>Normal Rounding</ROUNDTYPE>");
                XMLString.AppendLine("<LEDGERNAME>Round Off</LEDGERNAME>");
                XMLString.AppendLine("<GSTCLASS/>");
                XMLString.AppendLine("<ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>");
                XMLString.AppendLine("<LEDGERFROMITEM>No</LEDGERFROMITEM>");
                XMLString.AppendLine("<REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>");
                XMLString.AppendLine("<ISPARTYLEDGER>No</ISPARTYLEDGER>");
                XMLString.AppendLine("<ISLASTDEEMEDPOSITIVE>No</ISLASTDEEMEDPOSITIVE>");
                XMLString.AppendLine("<ISCAPVATTAXALTERED>No</ISCAPVATTAXALTERED>");
                XMLString.AppendLine("<ISCAPVATNOTCLAIMED>No</ISCAPVATNOTCLAIMED>");
                XMLString.AppendLine("<ROUNDLIMIT> 1</ROUNDLIMIT>");
                XMLString.AppendLine("<AMOUNT>" + roundOff + "</AMOUNT>");
                XMLString.AppendLine("<VATEXPAMOUNT>" + roundOff + "</VATEXPAMOUNT>");
                XMLString.AppendLine("</LEDGERENTRIES.LIST>");

                // ITEM LIST LOOP HERE 
                for (int j = 0; j < item_count; j++)
                {
                    XMLString.AppendLine("<ALLINVENTORYENTRIES.LIST>");
                    XMLString.AppendLine("<STOCKITEMNAME>" + item_data.Rows[j]["itm_name"] + "</STOCKITEMNAME>");
                    XMLString.AppendLine("<ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>");
                    XMLString.AppendLine("<ISLASTDEEMEDPOSITIVE>No</ISLASTDEEMEDPOSITIVE>");
                    XMLString.AppendLine("<ISAUTONEGATE>No</ISAUTONEGATE>");
                    XMLString.AppendLine("<ISCUSTOMSCLEARANCE>No</ISCUSTOMSCLEARANCE>");
                    XMLString.AppendLine("<ISTRACKCOMPONENT>No</ISTRACKCOMPONENT>");
                    XMLString.AppendLine("<ISTRACKPRODUCTION>No</ISTRACKPRODUCTION>");
                    XMLString.AppendLine("<ISPRIMARYITEM>No</ISPRIMARYITEM>");
                    XMLString.AppendLine("<ISSCRAP>No</ISSCRAP>");
                    XMLString.AppendLine("<RATE>" + item_data.Rows[j]["si_price"] + "</RATE>");

                    // round of adjustment in one item
                    decimal item_tax_excluded = Convert.ToDecimal(item_data.Rows[j]["si_net_amount"]);
                    //if (j == 0) { item_tax_excluded = item_tax_excluded - difference; }

                    XMLString.AppendLine("<AMOUNT>" + item_tax_excluded + "</AMOUNT>");

                    XMLString.AppendLine("<ACTUALQTY>" + item_data.Rows[j]["actual_qty"] + "</ACTUALQTY>");
                    XMLString.AppendLine("<BILLEDQTY>" + item_data.Rows[j]["billed_qty"] + "</BILLEDQTY>");
                    XMLString.AppendLine("<BATCHALLOCATIONS.LIST>");
                    XMLString.AppendLine("<GODOWNNAME>Main Location</GODOWNNAME>");
                    XMLString.AppendLine("<BATCHNAME>Primary Batch</BATCHNAME>");
                    XMLString.AppendLine("<DESTINATIONGODOWNNAME>Main Location</DESTINATIONGODOWNNAME>");
                    XMLString.AppendLine("<INDENTNO/>");
                    XMLString.AppendLine("<ORDERNO/>");
                    XMLString.AppendLine("<TRACKINGNUMBER/>");
                    XMLString.AppendLine("<DYNAMICCSTISCLEARED>No</DYNAMICCSTISCLEARED>");
                    XMLString.AppendLine("<AMOUNT>" + item_tax_excluded + "</AMOUNT>");
                    XMLString.AppendLine("<ACTUALQTY>" + item_data.Rows[j]["actual_qty"] + "</ACTUALQTY>");
                    XMLString.AppendLine("<BILLEDQTY>" + item_data.Rows[j]["billed_qty"] + "</BILLEDQTY>");
                    XMLString.AppendLine("</BATCHALLOCATIONS.LIST>");
                    XMLString.AppendLine("<ACCOUNTINGALLOCATIONS.LIST>");
                    XMLString.AppendLine("<OLDAUDITENTRYIDS.LIST TYPE=\"Number\">");
                    XMLString.AppendLine("<OLDAUDITENTRYIDS>-1</OLDAUDITENTRYIDS>");
                    XMLString.AppendLine("</OLDAUDITENTRYIDS.LIST>");
                    XMLString.AppendLine("<LEDGERNAME>SALES GST</LEDGERNAME>");
                    XMLString.AppendLine("<GSTCLASS/>");
                    XMLString.AppendLine("<ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>");
                    XMLString.AppendLine("<LEDGERFROMITEM>No</LEDGERFROMITEM>");
                    XMLString.AppendLine("<REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>");
                    XMLString.AppendLine("<ISPARTYLEDGER>No</ISPARTYLEDGER>");
                    XMLString.AppendLine("<ISLASTDEEMEDPOSITIVE>No</ISLASTDEEMEDPOSITIVE>");
                    XMLString.AppendLine("<ISCAPVATTAXALTERED>No</ISCAPVATTAXALTERED>");
                    XMLString.AppendLine("<ISCAPVATNOTCLAIMED>No</ISCAPVATNOTCLAIMED>");
                    XMLString.AppendLine("<AMOUNT>" + item_tax_excluded + "</AMOUNT>");

                    XMLString.AppendLine("<RATEDETAILS.LIST>");
                    XMLString.AppendLine("<GSTRATEDUTYHEAD>Integrated Tax</GSTRATEDUTYHEAD>");
                    XMLString.AppendLine("</RATEDETAILS.LIST>");

                    XMLString.AppendLine("<RATEDETAILS.LIST>");
                    XMLString.AppendLine("<GSTRATEDUTYHEAD>Central Tax</GSTRATEDUTYHEAD>");
                    XMLString.AppendLine("</RATEDETAILS.LIST>");

                    XMLString.AppendLine("<RATEDETAILS.LIST>");
                    XMLString.AppendLine("<GSTRATEDUTYHEAD>State Tax</GSTRATEDUTYHEAD>");
                    XMLString.AppendLine("</RATEDETAILS.LIST>");

                    XMLString.AppendLine("<RATEDETAILS.LIST>");
                    XMLString.AppendLine("<GSTRATEDUTYHEAD>Cess</GSTRATEDUTYHEAD>");
                    XMLString.AppendLine("</RATEDETAILS.LIST>");

                    XMLString.AppendLine("</ACCOUNTINGALLOCATIONS.LIST>");
                    XMLString.AppendLine("</ALLINVENTORYENTRIES.LIST>");
                }

                XMLString.AppendLine("</VOUCHER>");


            }

            XMLString.AppendLine("</TALLYMESSAGE>");
            #endregion

            XMLString.AppendLine("</REQUESTDATA>");
            #endregion

            XMLString.AppendLine("</IMPORTDATA>");
            XMLString.AppendLine("</BODY>");
            #endregion

            XMLString.AppendLine("</ENVELOPE>");
        }
        catch (Exception ex)
        {
            var log = new LogClass("GenerateXMLString");
            log.write(ex);
        }

        return XMLString.ToString();
    }

}