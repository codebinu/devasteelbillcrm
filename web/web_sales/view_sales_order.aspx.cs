using commonfunction;
using System;
using System.Collections.Generic;
using System.Data;
using System.Web;
using System.Web.Services;
using System.Web.UI.WebControls;
using MySql.Data.MySqlClient;

public partial class web_sales_view_sales_order : System.Web.UI.Page
{
    protected DataRow Order;
    protected string ErrorMessage = "";
    protected string StatusText = "";
    protected string StatusCss = "label label-default";
    protected decimal ItemsTotal, ItemsDiscount, ItemsTax, ItemsNet, ItemsQty;

    protected void Page_Load(object sender, EventArgs e)
    {
        LoginAuthentication bill = new LoginAuthentication();
        bill.userAuthentication();
        bill.checkPageAcess(7);

        int smoId;
        if (!int.TryParse(Request.QueryString["smoId"], out smoId) || smoId <= 0)
        {
            ErrorMessage = "Invalid sales order id.";
            return;
        }
        try
        {
            int staffId;
            var c = Request.Cookies["invntrystaffId"];
            if (c == null || !int.TryParse(c.Value, out staffId))
            {
                ErrorMessage = "Session expired. Please login again.";
                return;
            }
            var t = Request.Cookies["invntrystaffTypeID"];
            string staffType = t != null ? t.Value : "";

            string sql = "select smo.smo_id,smo.smo_invoice_no,smo.cust_id,tc.cust_name,tc.cust_tax_reg_id,"
                + "tc.cust_phone,tc.cust_phone1,tc.cust_address,tc.cust_email,tc.cust_city,"
                + "tb.branch_name,smo.smo_total,smo.smo_discount_amount,smo.smo_tax_amount,smo.smo_tax_excluded_amt,smo.smo_netamount,smo.smo_roundoff,"
                + "smo.smo_delivery_status,smo.smo_payment_type,smo.smo_order_type,"
                + "DATE_FORMAT(smo.smo_date,'%d-%b-%Y %H:%i') as orderDate,concat(ifnull(ud.first_name,''),' ',ifnull(ud.last_name,'')) as seller_name,"
                + "smo.smo_approved_id,smo.smo_processed_id,smo.smo_packed_id,smo.smo_delivered_id,smo.smo_cancelled_id,"
                + "DATE_FORMAT(smo.smo_approved_date,'%Y-%m-%d %H:%i') as approved_date,"
                + "DATE_FORMAT(smo.smo_processed_date,'%Y-%m-%d %H:%i') as processed_date,"
                + "DATE_FORMAT(smo.smo_packed_date,'%Y-%m-%d %H:%i') as packed_date,"
                + "DATE_FORMAT(smo.smo_delivered_date,'%Y-%m-%d %H:%i') as delivered_date,"
                + "DATE_FORMAT(smo.smo_cancelled_date,'%Y-%m-%d %H:%i') as cancelled_date,"
                + "trim(concat_ws(' ',approved.first_name,approved.last_name)) as approved_user,"
                + "trim(concat_ws(' ',processed.first_name,processed.last_name)) as processed_user,"
                + "trim(concat_ws(' ',packed.first_name,packed.last_name)) as packed_user,"
                + "trim(concat_ws(' ',delivered.first_name,delivered.last_name)) as delivered_user,"
                + "trim(concat_ws(' ',cancelled.first_name,cancelled.last_name)) as cancelled_user "
                + "from tbl_sales_master_order smo inner join tbl_customer tc on tc.cust_id=smo.cust_id "
                + "left join tbl_branch tb on tb.branch_id=smo.branch_id left join tbl_user_details ud on ud.user_id=smo.smo_userid "
                + "left join tbl_user_details approved on approved.user_id=smo.smo_approved_id "
                + "left join tbl_user_details processed on processed.user_id=smo.smo_processed_id "
                + "left join tbl_user_details packed on packed.user_id=smo.smo_packed_id "
                + "left join tbl_user_details delivered on delivered.user_id=smo.smo_delivered_id "
                + "left join tbl_user_details cancelled on cancelled.user_id=smo.smo_cancelled_id "
                + "where smo.smo_id=@id and smo.branch_id in (select branch_id from tbl_user_branches where user_id=@u)";
            var ps = new List<MySqlParameter> { new MySqlParameter("@id", smoId), new MySqlParameter("@u", staffId) };
            if (staffType == "2")
            {
                sql += " and smo.smo_userid=@u2";
                ps.Add(new MySqlParameter("@u2", staffId));
            }

            mySqlConnection db = new mySqlConnection();
            DataTable dt = db.SelectQuery(sql, ps.ToArray());
            if (dt == null || dt.Rows.Count == 0)
            {
                ErrorMessage = "Sales order not found.";
                return;
            }
            Order = dt.Rows[0];
            this.smoId = smoId;
            this.staffId = staffId;
            this.staffType = staffType;
            int st = -1;
            if (int.TryParse(Convert.ToString(Order["smo_delivery_status"]), out st) && SalesOrderStatus.Name(st) != "")
            {
                StatusText = SalesOrderStatus.Name(st);
                StatusCss = SalesOrderStatus.Css(st);
                currentStatus = st;
            }
            BindStatusActions();

            // Salesmen (type 2) can view their own orders but cannot change the status.
            bool canAct = staffType != "2";
            btnApprove.Visible = canAct && st == SalesOrderStatus.New;
            btnResume.Visible = canAct && st == SalesOrderStatus.Pending;
            btnHold.Visible = canAct && SalesOrderStatus.CanHold(st);
            btnCancelCustomer.Visible = canAct && SalesOrderStatus.CanCancel(st);
            btnCancelCompany.Visible = btnCancelCustomer.Visible;
            btnReopen.Visible = canAct && SalesOrderStatus.CanReopen(st);
            HasActions = btnApprove.Visible || btnResume.Visible || btnHold.Visible || btnCancelCustomer.Visible || btnReopen.Visible;
            if (!canAct)
                ActionHint = "You do not have permission to change the status of this order.";
            else if (!HasActions)
                ActionHint = "No further actions are available for this order status.";
            else if (st == SalesOrderStatus.Pending)
                ActionHint = "This order is on hold. Stock cannot be reserved until it is resumed.";

            switch (Request.QueryString["done"])
            {
                case "approved": ActionMessage = "Sales order approved. It is now eligible for stock reservation."; break;
                case "resumed": ActionMessage = "Sales order resumed and approved. Stock is not reserved automatically."; break;
                case "hold": ActionMessage = "Sales order put on hold (Pending). Existing reservations were kept; no further reservations are allowed until it is resumed."; break;
                case "cancelled": ActionMessage = "Sales order cancelled. Its stock reservations were released."; break;
                case "reopened": ActionMessage = "Sales order reopened."; break;
                case "failed": ActionMessage = "The status could not be changed because the order was modified or is not in a valid state."; break;
            }

            DataTable items = db.SelectQuery("select sio.*,"
                + "(select tis.itm_code from tbl_itembranch_stock tis where tis.itbs_id=sio.itbs_id limit 1) as itm_code,"
                + "(select u.tum_name from tbl_item_uom u where u.tum_id=sio.tum_id limit 1) as uom "
                + "from tbl_sales_items_order sio where sio.smo_id=@id order by sio.row_no",
                new MySqlParameter[] { new MySqlParameter("@id", smoId) });
            int sl = 1;
            items.Columns.Add("sl", typeof(int));
            items.Columns.Add("cust_qty", typeof(string));
            items.Columns.Add("cust_size", typeof(string));
            items.Columns.Add("cust_uom", typeof(string));
            Dictionary<int, string> uomNames = new Dictionary<int, string>();
            foreach (DataRow ur in db.SelectQuery("select tum_id,tum_name from tbl_item_uom").Rows)
                uomNames[Convert.ToInt32(ur["tum_id"])] = Convert.ToString(ur["tum_name"]);
            bool hasCustUom = items.Columns.Contains("tum_id_cust"), hasPiece = items.Columns.Contains("sio_no_piece");
            bool hasCustLen = items.Columns.Contains("sio_length_cust_fraction"), hasCustWid = items.Columns.Contains("sio_width_cust_fraction");
            foreach (DataRow r in items.Rows)
            {
                r["sl"] = sl++;
                // customer-entered values: pieces, length x width and the UOM those dimensions were typed in
                if (hasPiece && r["sio_no_piece"] != DBNull.Value && Dec(r["sio_no_piece"]) > 0)
                    r["cust_qty"] = Dec(r["sio_no_piece"]).ToString("0.##");
                decimal custLen = hasCustLen ? Dec(r["sio_length_cust_fraction"]) : 0, custWid = hasCustWid ? Dec(r["sio_width_cust_fraction"]) : 0;
                r["cust_size"] = custLen > 0 ? custLen.ToString("0.####") + (custWid > 0 ? " x " + custWid.ToString("0.####") : "") : "";
                string cu;
                if (hasCustUom && r["tum_id_cust"] != DBNull.Value && uomNames.TryGetValue(Convert.ToInt32(r["tum_id_cust"]), out cu))
                    r["cust_uom"] = cu;
                ItemsQty += Dec(r["sio_finalqty"]);
                ItemsTotal += Dec(r["sio_total"]);
                ItemsDiscount += Dec(r["sio_discount_amount"]);
                ItemsTax += Dec(r["sio_tax_amount"]);
                ItemsNet += Dec(r["sio_net_amount"]);
            }
            rptItems.DataSource = items;
            rptItems.DataBind();
            ItemCount = items.Rows.Count;
            LoadInvoices(smoId, staffId, staffType);
            LoadTransfers(smoId);
        }
        catch (Exception ex)
        {
            Order = null;
            new LogClass("salesordererror").write(ex);
            ErrorMessage = "Unable to load the sales order. Please try again.";
        }
    }

    [WebMethod]
    public static string LoadRemarks(int smoId)
    {
        int staffId;
        string staffType;
        ValidateRemarkRequest(smoId, out staffId, out staffType);
        return ReadSalesOrderRemark(smoId, staffId, staffType);
    }

    [WebMethod]
    public static bool SaveRemarks(int smoId, string remark)
    {
        int staffId;
        string staffType;
        ValidateRemarkRequest(smoId, out staffId, out staffType);
        remark = remark ?? "";

        ReadSalesOrderRemark(smoId, staffId, staffType);

        string scope = " and branch_id in (select branch_id from tbl_user_branches where user_id=@u)";
        var parameters = new List<MySqlParameter> {
            new MySqlParameter("@remark", remark),
            new MySqlParameter("@id", smoId),
            new MySqlParameter("@u", staffId)
        };
        if (staffType == "2")
        {
            scope += " and smo_userid=@owner";
            parameters.Add(new MySqlParameter("@owner", staffId));
        }

        var db = new mySqlConnection();
        if (!db.ExecuteQuery("update tbl_sales_master_order set smo_specialnote=@remark where smo_id=@id" + scope, parameters.ToArray()))
            throw new HttpException(500, "Unable to save notes and remarks.");

        return ReadSalesOrderRemark(smoId, staffId, staffType) == remark;
    }

    sealed class OrderAccess
    {
        public int StaffId;
        public string StaffType;
        public int BranchId;
        public int Status;
        public string DocBase;
    }

    // Same cookie validation and branch / owner scoping as the notes tab.
    static OrderAccess OpenOrder(int smoId)
    {
        var access = new OrderAccess();
        ValidateRemarkRequest(smoId, out access.StaffId, out access.StaffType);

        string sql = "select smo.branch_id,smo.smo_delivery_status,smo.smo_invoice_no from tbl_sales_master_order smo where smo.smo_id=@id"
            + " and smo.branch_id in (select branch_id from tbl_user_branches where user_id=@u)";
        var parameters = new List<MySqlParameter> {
            new MySqlParameter("@id", smoId),
            new MySqlParameter("@u", access.StaffId)
        };
        if (access.StaffType == "2")
        {
            sql += " and smo.smo_userid=@owner";
            parameters.Add(new MySqlParameter("@owner", access.StaffId));
        }

        DataTable dt = new mySqlConnection().SelectQuery(sql, parameters.ToArray());
        if (dt == null || dt.Rows.Count == 0)
            throw new HttpException(404, "Sales order not found.");
        access.BranchId = Convert.ToInt32(dt.Rows[0]["branch_id"]);
        int status;
        access.Status = int.TryParse(Convert.ToString(dt.Rows[0]["smo_delivery_status"]), out status) ? status : -1;
        access.DocBase = Convert.ToString(dt.Rows[0]["smo_invoice_no"]);
        if (string.IsNullOrWhiteSpace(access.DocBase))
            access.DocBase = "SO-" + smoId;
        return access;
    }

    static StockActionResult Denied(string message)
    {
        return new StockActionResult { ok = false, message = message };
    }

    [WebMethod]
    public static ReservedItemsResult LoadReserved(int smoId)
    {
        OrderAccess a = OpenOrder(smoId);
        try
        {
            return SalesOrderStock.Load(smoId, a.BranchId, a.Status, a.StaffType != "2");
        }
        catch (Exception ex)
        {
            new LogClass("salesorderstockerror").write(ex);
            return new ReservedItemsResult { ok = false, message = "Unable to load reserved items. Please try again." };
        }
    }

    [WebMethod]
    public static StockActionResult ReserveItem(int smoId, int sioId, decimal expectedQty, int compItmId)
    {
        OrderAccess a = OpenOrder(smoId);
        if (a.StaffType == "2")
            return Denied("You do not have permission to reserve stock for this order.");
        return SalesOrderStock.Reserve(smoId, a.BranchId, a.Status, a.StaffId, sioId, expectedQty, compItmId);
    }

    [WebMethod]
    public static StockActionResult ReserveBatches(int smoId, int sioId, int compItmId, List<BatchQty> allocations)
    {
        OrderAccess a = OpenOrder(smoId);
        if (a.StaffType == "2")
            return Denied("You do not have permission to reserve stock for this order.");
        return SalesOrderStock.ReserveBatches(smoId, a.BranchId, a.Status, a.StaffId, sioId, compItmId, allocations);
    }

    [WebMethod]
    public static ReserveOptionsResult LoadReserveOptions(int smoId, int sioId, int compItmId)
    {
        OrderAccess a = OpenOrder(smoId);
        try
        {
            if (a.StaffType == "2")
                return new ReserveOptionsResult { ok = false, message = "You do not have permission to reserve stock for this order." };
            return SalesOrderStock.LoadOptions(smoId, a.BranchId, a.StaffId, sioId, compItmId);
        }
        catch (Exception ex)
        {
            new LogClass("salesorderstockerror").write(ex);
            return new ReserveOptionsResult { ok = false, message = "Unable to load warehouse stock. Please try again." };
        }
    }

    [WebMethod]
    public static StockActionResult UnreserveItem(int smoId, int sioId, int compItmId)
    {
        OrderAccess a = OpenOrder(smoId);
        if (a.StaffType == "2")
            return Denied("You do not have permission to release reservations for this order.");
        return SalesOrderStock.Unreserve(smoId, a.BranchId, a.Status, sioId, compItmId);
    }

    [WebMethod]
    public static StockActionResult UnreserveBatch(int smoId, int sioId, int batchId)
    {
        OrderAccess a = OpenOrder(smoId);
        if (a.StaffType == "2")
            return Denied("You do not have permission to release reservations for this order.");
        return SalesOrderStock.UnreserveBatch(smoId, sioId, batchId);
    }

    [WebMethod]
    public static StockActionResult SetReservationPriority(int smoId, int sioId, int batchId, int priority)
    {
        OrderAccess a = OpenOrder(smoId);
        if (a.StaffType == "2")
            return Denied("You do not have permission to change reservations for this order.");
        return SalesOrderStock.SetPriority(smoId, sioId, batchId, priority);
    }

    [WebMethod]
    public static StockActionResult ProduceItem(int smoId, int sioId, decimal expectedQty)
    {
        OrderAccess a = OpenOrder(smoId);
        if (a.StaffType == "2")
            return Denied("You do not have permission to move items to production.");
        return SalesOrderStock.MoveToProduction(smoId, a.BranchId, a.Status, a.StaffId, a.DocBase, sioId, expectedQty);
    }

    [WebMethod]
    public static StockActionResult UndoProduction(int smoId, int itpmId)
    {
        OrderAccess a = OpenOrder(smoId);
        if (a.StaffType == "2")
            return Denied("You do not have permission to undo production for this order.");
        return SalesOrderStock.UndoProduction(smoId, a.BranchId, a.StaffId, itpmId);
    }

    [WebMethod]
    public static ProductionJobsResult LoadProduction(int smoId)
    {
        OrderAccess a = OpenOrder(smoId);
        try
        {
            return SalesOrderStock.LoadProduction(smoId, a.BranchId, a.Status, a.DocBase, a.StaffType != "2");
        }
        catch (Exception ex)
        {
            new LogClass("salesorderstockerror").write(ex);
            return new ProductionJobsResult { ok = false, message = "Unable to load production details. Please try again." };
        }
    }

    [WebMethod]
    public static ProductionEntryOptions LoadProductionEntry(int smoId, int sioId)
    {
        OrderAccess a = OpenOrder(smoId);
        try
        {
            if (a.StaffType == "2")
                return new ProductionEntryOptions { ok = false, message = "You do not have permission to enter production for this order." };
            return SalesOrderStock.LoadProductionEntry(smoId, a.BranchId, a.Status, a.DocBase, sioId);
        }
        catch (Exception ex)
        {
            new LogClass("salesorderstockerror").write(ex);
            return new ProductionEntryOptions { ok = false, message = "Unable to load the production entry. Please try again." };
        }
    }

    [WebMethod]
    public static ProductionSaveResult SaveProduction(int smoId, int sioId, int reservationId, decimal expectedOutput)
    {
        OrderAccess a = OpenOrder(smoId);
        if (a.StaffType == "2")
            return new ProductionSaveResult { ok = false, message = "You do not have permission to enter production for this order." };
        return SalesOrderStock.SaveProduction(smoId, a.BranchId, a.Status, a.StaffId, a.DocBase, sioId, reservationId, expectedOutput);
    }

    [WebMethod]
    public static ProductionJobDetail LoadProductionJob(int smoId, int itpmId)
    {
        OrderAccess a = OpenOrder(smoId);
        try
        {
            return SalesOrderStock.LoadProductionDetail(smoId, a.BranchId, a.DocBase, itpmId);
        }
        catch (Exception ex)
        {
            new LogClass("salesorderstockerror").write(ex);
            return new ProductionJobDetail { ok = false, message = "Unable to load the production job details. Please try again." };
        }
    }

    static void ValidateRemarkRequest(int smoId, out int staffId, out string staffType)
    {
        staffId = 0;
        staffType = "";
        var context = HttpContext.Current;
        if (smoId <= 0 || context == null
            || context.Request.Cookies["invntrystaffId"] == null
            || context.Request.Cookies["invntrystaffTypeID"] == null
            || context.Request.Cookies["invntrystaffBranchId"] == null
            || context.Request.Cookies["invntrystaffCountryId"] == null
            || !int.TryParse(context.Request.Cookies["invntrystaffId"].Value, out staffId)
            || staffId <= 0)
            throw new HttpException(401, "Please sign in again.");

        var authentication = new LoginAuthentication();
        authentication.userAuthentication();
        authentication.checkPageAcess(7);
        staffType = context.Request.Cookies["invntrystaffTypeID"].Value;
    }

    static string ReadSalesOrderRemark(int smoId, int staffId, string staffType)
    {
        string sql = "select smo.smo_specialnote from tbl_sales_master_order smo where smo.smo_id=@id"
            + " and smo.branch_id in (select branch_id from tbl_user_branches where user_id=@u)";
        var parameters = new List<MySqlParameter> {
            new MySqlParameter("@id", smoId),
            new MySqlParameter("@u", staffId)
        };
        if (staffType == "2")
        {
            sql += " and smo.smo_userid=@owner";
            parameters.Add(new MySqlParameter("@owner", staffId));
        }

        DataTable dt = new mySqlConnection().SelectQuery(sql, parameters.ToArray());
        if (dt == null || dt.Rows.Count == 0)
            throw new HttpException(404, "Sales order not found.");
        return Convert.ToString(dt.Rows[0]["smo_specialnote"]);
    }

    protected int ItemCount;
    protected List<SalesOrderInvoiceRow> Invoices = new List<SalesOrderInvoiceRow>();
    protected bool CanCreateInvoice;
    protected string InvoiceHint = "";
    protected string InvoiceMessage = "";

    // Invoices linked to this order (sm_refid = smo_id, not inter-stock-transfer) and whether quantities remain to be invoiced.
    void LoadInvoices(int smoId, int staffId, string staffType)
    {
        try
        {
            Invoices = SalesOrderStock.LoadInvoices(smoId);
            SalesOrderInvoicePage invoicing = SalesOrderStock.LoadInvoicePage(smoId, staffId, staffType);
            CanCreateInvoice = invoicing.CanInvoice;
            InvoiceHint = invoicing.CanInvoice ? "" : (invoicing.Message ?? "");
            if (Request.QueryString["done"] == "invoiced")
                InvoiceMessage = "Invoice created. The reserved stock and batch quantities of the invoiced items were reduced.";
        }
        catch (Exception ex)
        {
            new LogClass("salesordererror").write(ex);
            InvoiceHint = "Unable to load the invoices of this sales order. Please try again.";
        }
    }

    protected List<InterStockTransferRow> Transfers = new List<InterStockTransferRow>();
    protected bool CanCreateTransfer;
    protected string TransferHint = "";
    protected string TransferMessage = "";
    protected string TransferMessageCss = "alert alert-success";

    // Inter-warehouse transfers of this order (sm_refid = smo_id and sm_is_inter_stock_transfer_invoice = 1), each with its purchase.
    void LoadTransfers(int smoId)
    {
        try
        {
            Transfers = SalesOrderStock.LoadInterStockTransfers(smoId);
            CanCreateTransfer = SalesOrderStatus.CanReserve(Convert.ToInt32(Order["smo_delivery_status"]));
            if (!CanCreateTransfer)
                TransferHint = "Stock can be transferred only for an Approved or Processed sales order.";
            string invoiceId = Convert.ToString(Request.QueryString["invoiceId"]), purchaseId = Convert.ToString(Request.QueryString["purchaseId"]);
            int n;
            if (!int.TryParse(invoiceId, out n)) invoiceId = "";
            if (!int.TryParse(purchaseId, out n)) purchaseId = "";
            if (Request.QueryString["done"] == "transferred")
                TransferMessage = "Stock transfer completed: invoice #" + invoiceId + " and purchase #" + purchaseId + " were created.";
            else if (Request.QueryString["done"] == "transferpartial")
            {
                TransferMessage = "Invoice #" + invoiceId + " was created, but its purchase entry could not be generated. The transfer is incomplete: use Retry Purchase below.";
                TransferMessageCss = "alert alert-danger";
            }
        }
        catch (Exception ex)
        {
            new LogClass("salesordererror").write(ex);
            TransferHint = "Unable to load the stock transfers of this sales order. Please try again.";
        }
    }

    protected static string TransferStatusText(string status)
    {
        return status == "completed" ? "Purchase created" : (status == "cancelled" ? "Purchase cancelled" : "Purchase pending");
    }

    protected static string TransferStatusCss(string status)
    {
        return status == "completed" ? "label label-success" : (status == "cancelled" ? "label label-danger" : "label label-warning");
    }

    [WebMethod]
    public static InterStockTransferDetail LoadTransferDetail(int smoId, int smId)
    {
        try
        {
            return SalesOrderStock.LoadInterStockTransferDetail(smoId, smId);
        }
        catch (HttpException)
        {
            throw;
        }
        catch (Exception ex)
        {
            new LogClass("salesordererror").write(ex);
            return new InterStockTransferDetail { ok = false, message = "Unable to load the transfer details. Please try again." };
        }
    }

    [WebMethod]
    public static InterStockResult RetryTransferPurchase(int smoId, int smId)
    {
        return SalesOrderStock.RetryInterStockPurchase(smoId, smId);
    }
    protected bool HasActions;
    protected string ActionHint = "";
    protected string ActionMessage = "";
    protected readonly List<StatusAction> StatusActions = new List<StatusAction>();
    int smoId, staffId, currentStatus = -1;
    string staffType = "";

    protected sealed class StatusAction
    {
        public string Status;
        public string Css;
        public string User;
        public string Date;
    }

    void BindStatusActions()
    {
        StatusActions.Clear();
        StatusActions.Add(new StatusAction {
            Status = "New (Created)", Css = SalesOrderStatus.Css(SalesOrderStatus.New),
            User = DisplayRecordedValue(Order["seller_name"]),
            Date = DisplayRecordedValue(Order["orderDate"])
        });
        bool isDelivered = currentStatus == SalesOrderStatus.FullyDelivered || currentStatus == SalesOrderStatus.PartiallyDelivered;
        bool isCancelled = SalesOrderStatus.IsCancelled(currentStatus);
        if (currentStatus != SalesOrderStatus.New)
            AddStatusAction("approved", SalesOrderStatus.Name(SalesOrderStatus.Approved), SalesOrderStatus.Css(SalesOrderStatus.Approved), currentStatus == SalesOrderStatus.Approved);
        // Orders approved before the Processed status existed carry processed details too, so it is listed only once the order is really Processed.
        if (currentStatus == SalesOrderStatus.Processed || currentStatus == SalesOrderStatus.Pending || isDelivered || isCancelled)
            AddStatusAction("processed", SalesOrderStatus.Name(SalesOrderStatus.Processed), SalesOrderStatus.Css(SalesOrderStatus.Processed), currentStatus == SalesOrderStatus.Processed);
        if (isDelivered || isCancelled)
            AddStatusAction("packed", "Packed", "label label-info", false);
        if (isDelivered)
            AddStatusAction("delivered", SalesOrderStatus.Name(currentStatus), SalesOrderStatus.Css(currentStatus), true);
        if (currentStatus == SalesOrderStatus.Pending)
        {
            StatusActions.Add(new StatusAction {
                Status = SalesOrderStatus.Name(currentStatus), Css = SalesOrderStatus.Css(currentStatus), User = "Not recorded", Date = "Not recorded"
            });
        }
        if (isCancelled)
            AddStatusAction("cancelled", SalesOrderStatus.Name(currentStatus), SalesOrderStatus.Css(currentStatus), true);
    }

    void AddStatusAction(string field, string status, string css, bool isCurrent)
    {
        string date = DisplayRecordedValue(Order[field + "_date"]);
        string userId = Convert.ToString(Order["smo_" + field + "_id"]).Trim();
        if (!isCurrent && (userId == "" || userId == "0") && date == "Not recorded")
            return;

        string user = DisplayRecordedValue(Order[field + "_user"]);
        if (user == "Not recorded" && userId != "" && userId != "0")
            user = "User #" + userId;
        StatusActions.Add(new StatusAction { Status = status, Css = css, User = user, Date = date });
    }

    static string DisplayRecordedValue(object value)
    {
        string text = Convert.ToString(value).Trim();
        return text == "" || text.StartsWith("0000-") || text.StartsWith("00-")
            ? "Not recorded" : text;
    }

    protected void btnApprove_Click(object sender, EventArgs e)
    {
        ChangeStatus(SalesOrderStatus.Approved, "approved");
    }

    protected void btnResume_Click(object sender, EventArgs e)
    {
        ChangeStatus(SalesOrderStatus.Approved, "resumed");
    }

    protected void btnHold_Click(object sender, EventArgs e)
    {
        ChangeStatus(SalesOrderStatus.Pending, "hold");
    }

    protected void btnCancelCustomer_Click(object sender, EventArgs e)
    {
        ChangeStatus(SalesOrderStatus.CancelledByCustomer, "cancelled");
    }

    protected void btnCancelCompany_Click(object sender, EventArgs e)
    {
        ChangeStatus(SalesOrderStatus.CancelledByCompany, "cancelled");
    }

    protected void btnReopen_Click(object sender, EventArgs e)
    {
        ChangeStatus(SalesOrderStatus.New, "reopened");
    }

    // SalesOrderStatus.Change validates the transition against the locked order row, so a stale page cannot apply an invalid change.
    void ChangeStatus(int newStatus, string doneKey)
    {
        bool ok = Order != null && staffType != "2" && SalesOrderStatus.CanTransition(currentStatus, newStatus)
            && SalesOrderStatus.Change(smoId, staffId, newStatus) == null;
        Response.Redirect("view_sales_order.aspx?smoId=" + smoId + "&done=" + (ok ? doneKey : "failed"));
    }

    static decimal Dec(object o)
    {
        decimal d;
        return o != null && o != DBNull.Value && decimal.TryParse(Convert.ToString(o), out d) ? d : 0m;
    }

    protected string Money(object o)
    {
        return Dec(o).ToString("0.00");
    }

    protected string Num(object o)
    {
        return Dec(o).ToString("0.####");
    }

    protected string Enc(object o)
    {
        return o == null || o == DBNull.Value ? "" : HttpUtility.HtmlEncode(Convert.ToString(o));
    }

    protected bool Has(string col)
    {
        return Order != null && Order[col] != DBNull.Value && Convert.ToString(Order[col]).Trim() != "";
    }

    protected string PaymentText()
    {
        switch (Convert.ToString(Order["smo_payment_type"]))
        {
            case "1": return "Cash";
            case "2": return "Credit";
            case "3": return "Bill to bill";
            default: return "";
        }
    }

    protected string OrderTypeText()
    {
        switch (Convert.ToString(Order["smo_order_type"]))
        {
            case "1": return "Direct visit";
            case "2": return "Telephonic";
            case "3": return "Mail";
            default: return "";
        }
    }
}
