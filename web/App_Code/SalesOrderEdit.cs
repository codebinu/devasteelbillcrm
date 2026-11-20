using commonfunction;
using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Data;
using System.Security.Cryptography;
using System.Text;

// Editing an existing sales order (edit_sales_order.aspx): header fields (payment type, order type, notes) and the lines
// (quantity, size, UOM, price, discount of existing lines; lines can be added and removed, but at least one must remain).
//  - Allowed in New, On Hold, Approved and Processed orders that have no invoice, no reservation and no production entry.
//  - Final quantity, line amounts and order totals are recalculated here; the client preview is never trusted.
//  - Tax rates of an existing line are kept as saved (sio_item_tax / sio_item_cess); only lines the user changed are rewritten.
//    A new line takes its tax, price class and sales unit from the item master, like new_sales_order.aspx.
//  - After saving, the order status is recalculated (SalesOrderStatus.TryUpdateSalesOrderStatus).

public class SalesOrderEditLine
{
    // sioId > 0: an existing line. sioId <= 0: a new line for item itbsId. Existing lines that are not submitted are removed.
    public int sioId;
    public int itbsId;
    public decimal qty;
    public decimal length;
    public decimal width;
    public int tumIdCust;
    public decimal price;
    public decimal discountRate;
}

public class SalesOrderEditRequest
{
    public int smoId;
    public string token;
    public int paymentType;
    public int orderType;
    public string note;
    public List<SalesOrderEditLine> lines = new List<SalesOrderEditLine>();
}

public class SalesOrderEditResult
{
    public bool ok;
    public string message = "";
}

public sealed class SalesOrderEditItem
{
    public int itbsId;
    public string code;
    public string name;
    public decimal stock;
    public decimal tax;
    public decimal cess;
    public int uomId;
    public decimal price;
}

public sealed class EditUom
{
    public int TypeId;
    public decimal Factor;
    public string TypeName;
}

public sealed class EditLineBase
{
    public int TumCust;
    public decimal Qty, Length, Width;
}

public static class SalesOrderEdit
{
    public const int MaxNoteLength = 500;
    const decimal Tolerance = 0.00005m;

    sealed class EditException : Exception
    {
        public EditException(string message) : base(message) { }
    }

    static DataTable Sel(mySqlConnection db, bool tx, string sql, params MySqlParameter[] ps)
    {
        return tx ? db.SelectQueryForTransaction(sql, ps) : db.SelectQuery(sql, ps);
    }

    static string Scalar(mySqlConnection db, bool tx, string sql, params MySqlParameter[] ps)
    {
        return Convert.ToString(tx ? db.SelectScalarForTransaction(sql, ps) : db.SelectScalar(sql, ps));
    }

    static int I(object o) { int v; return o == null || o == DBNull.Value || !int.TryParse(Convert.ToString(o), out v) ? 0 : v; }
    static decimal D(object o) { decimal v; return o == null || o == DBNull.Value || !decimal.TryParse(Convert.ToString(o), out v) ? 0m : v; }
    static bool Same(decimal a, decimal b) { return Math.Abs(a - b) <= Tolerance; }
    static decimal Rnd(decimal v, int acc) { return Math.Round(v, acc, MidpointRounding.AwayFromZero); }

    public static bool IsEditableStatus(int status)
    {
        return status == SalesOrderStatus.New || status == SalesOrderStatus.OnHold
            || status == SalesOrderStatus.Approved || status == SalesOrderStatus.Processed;
    }

    public static Dictionary<int, EditUom> LoadUoms(mySqlConnection db, bool tx)
    {
        var uoms = new Dictionary<int, EditUom>();
        foreach (DataRow r in Sel(db, tx, "select u.tum_id,u.tum_type_id,u.tum_convertion_fac,t.tumt_name from tbl_item_uom u left join tbl_item_uom_type t on t.tumt_id=u.tum_type_id").Rows)
            uoms[I(r["tum_id"])] = new EditUom { TypeId = I(r["tum_type_id"]), Factor = D(r["tum_convertion_fac"]), TypeName = Convert.ToString(r["tumt_name"]) };
        return uoms;
    }

    static bool NeedsLength(EditUom u)
    {
        return u != null && (string.Equals(u.TypeName, "Length", StringComparison.OrdinalIgnoreCase) || string.Equals(u.TypeName, "Area", StringComparison.OrdinalIgnoreCase));
    }

    static bool NeedsWidth(EditUom u)
    {
        return u != null && string.Equals(u.TypeName, "Area", StringComparison.OrdinalIgnoreCase);
    }

    // The customer-entered values of a saved line, as the edit form shows them. Lines saved without a customer UOM fall back to
    // the line's own UOM. Dimensions the UOM does not use are zero, so the form and the server compare like with like.
    public static EditLineBase BaseOf(DataRow r, DataTable cols, Dictionary<int, EditUom> uoms)
    {
        var b = new EditLineBase();
        int tum = I(r["tum_id"]);
        decimal piece = cols.Columns.Contains("sio_no_piece") ? D(r["sio_no_piece"]) : 0m;
        int cust = cols.Columns.Contains("tum_id_cust") ? I(r["tum_id_cust"]) : 0;
        EditUom u;
        if (cust > 0)
        {
            b.TumCust = cust;
            b.Qty = piece;
            b.Length = cols.Columns.Contains("sio_length_cust_fraction") ? D(r["sio_length_cust_fraction"]) : 0m;
            b.Width = cols.Columns.Contains("sio_width_cust_fraction") ? D(r["sio_width_cust_fraction"]) : 0m;
        }
        else
        {
            b.TumCust = tum;
            uoms.TryGetValue(tum, out u);
            b.Length = cols.Columns.Contains("sio_length") ? D(r["sio_length"]) : 0m;
            b.Width = cols.Columns.Contains("sio_width") ? D(r["sio_width"]) : 0m;
            b.Qty = piece > 0 ? piece : (NeedsLength(u) ? 0m : D(r["sio_finalqty"]));
        }
        uoms.TryGetValue(b.TumCust, out u);
        if (!NeedsLength(u)) b.Length = 0m;
        if (!NeedsWidth(u)) b.Width = 0m;
        return b;
    }

    // Returns an error text, or null when the final quantity (in the line's UOM) was calculated.
    public static string CalcFinal(Dictionary<int, EditUom> uoms, int custUom, int targetUom, decimal qty, decimal len, decimal wid, out decimal final)
    {
        final = 0m;
        EditUom c, t;
        if (!uoms.TryGetValue(custUom, out c) || c.Factor <= 0) return "Select a valid unit of measure.";
        if (!uoms.TryGetValue(targetUom, out t) || t.Factor <= 0) return "The unit of measure of the line is invalid.";
        if (c.TypeId != t.TypeId) return "The selected unit of measure cannot be converted to the unit of the line.";
        decimal mult = qty > 0 ? qty : 1m, bas;
        if (!NeedsLength(c))
        {
            if (qty <= 0) return "Enter a valid quantity.";
            bas = qty;
        }
        else
        {
            if (len <= 0) return "Length is required.";
            if (NeedsWidth(c) && wid <= 0) return "Width is required.";
            bas = NeedsWidth(c) ? len * wid * mult : len * mult;
        }
        final = Math.Round(bas * c.Factor / t.Factor, 4, MidpointRounding.AwayFromZero);
        return final > 0 ? null : "The final quantity must be greater than zero.";
    }

    // Length/width in the linear unit of the line's UOM, same rule as new_sales_order.aspx.cs.
    static decimal? ToSalesLinear(decimal value, EditUom cust, EditUom sales, bool isWidth)
    {
        if (value <= 0) return null;
        bool length = string.Equals(sales.TypeName, "Length", StringComparison.OrdinalIgnoreCase);
        bool area = string.Equals(sales.TypeName, "Area", StringComparison.OrdinalIgnoreCase);
        if (!length && !area) return null;
        if (length && isWidth) return null;
        decimal ratio = cust.Factor / sales.Factor;
        decimal linear = area ? (decimal)Math.Sqrt((double)ratio) : ratio;
        return Math.Round(value * linear, 4, MidpointRounding.AwayFromZero);
    }

    // Why the order cannot be edited ("" when it can).
    public static string EditBlock(mySqlConnection db, bool tx, int smoId, int status, string invoiceNo)
    {
        if (!IsEditableStatus(status))
            return "A sales order that is " + (SalesOrderStatus.Name(status) == "" ? "in this status" : SalesOrderStatus.Name(status)) + " cannot be edited.";
        var o = new MySqlParameter("@o", smoId);
        if (Scalar(db, tx, "select count(*) from tbl_sales_master where sm_refid=@o and sm_is_inter_stock_transfer_invoice=0", o) != "0")
            return "This sales order already has an invoice and can no longer be edited.";
        if (Scalar(db, tx, "select count(*) from tbl_item_batchstock_reserve r inner join tbl_sales_items_order sio on sio.sio_id=r.sio_id "
            + "where sio.smo_id=@o2 and r.itbsr_qty>0", new MySqlParameter("@o2", smoId)) != "0")
            return "Stock is reserved for this sales order. Release the reservations to edit it.";
        string docNo = ProductionService.DocNoFor(smoId, invoiceNo);
        if (Scalar(db, tx, "select count(*) from tbl_item_pro_master where itpm_doc_no=@d1 or itpm_doc_no=@d2",
            new MySqlParameter("@d1", docNo), new MySqlParameter("@d2", "SO-" + smoId)) != "0")
            return "A production entry exists for this sales order, so it can no longer be edited.";
        return "";
    }

    // Items that can be added to the order: available items of the order's warehouse (in stock unless zero-stock orders are allowed).
    public static List<SalesOrderEditItem> SearchItems(int staffId, string staffType, int smoId, string term)
    {
        var list = new List<SalesOrderEditItem>();
        if (staffType == "2" || smoId <= 0)
            return list;
        var db = new mySqlConnection();
        DataTable o = db.SelectQuery("select smo.* from tbl_sales_master_order smo "
            + "where smo.smo_id=@o and smo.branch_id in (select branch_id from tbl_user_branches where user_id=@u)",
            new MySqlParameter[] { new MySqlParameter("@o", smoId), new MySqlParameter("@u", staffId) });
        if (o.Rows.Count == 0)
            return list;
        if (EditBlock(db, false, smoId, I(o.Rows[0]["smo_delivery_status"]), Convert.ToString(o.Rows[0]["smo_invoice_no"])) != "")
            return list;
        int allowZero = I(db.SelectScalar("select ss_allow_zero_stock_order from tbl_system_settings"));
        int priceClass = PriceClass(db, false, o.Rows[0]);
        string like = "%" + (term ?? "").Trim().Replace("\\", "\\\\").Replace("%", "\\%").Replace("_", "\\_") + "%";
        DataTable dt = db.SelectQuery("select tis.itbs_id,tis.itm_code,tis.itm_name,tis.itbs_stock,tis.itm_mrp,tp.tp_tax_percentage,tp.tp_cess,im.itsv_uom_sales,"
            + "(select tip_price from tbl_item_pricelist tip where tip.tpm_id=@tpm and tip.itbs_id=tis.itbs_id limit 1) as classPrice "
            + "from tbl_itembranch_stock tis inner join tbl_tax_profile tp on tp.tp_tax_code=tis.tp_tax_code inner join tbl_item_master im on im.itm_id=tis.itm_id "
            + "where (tis.itm_name like @t or tis.itm_code like @t) and tis.branch_id=@b and tis.itbs_available=1 and tis.itm_code not in ('1234567891234')"
            + (allowZero == 0 ? " and tis.itbs_stock>0" : "") + " order by tis.itm_name limit 20",
            new MySqlParameter[] { new MySqlParameter("@tpm", priceClass), new MySqlParameter("@t", like), new MySqlParameter("@b", I(o.Rows[0]["branch_id"])) });
        foreach (DataRow r in dt.Rows)
            list.Add(new SalesOrderEditItem
            {
                itbsId = I(r["itbs_id"]), code = Convert.ToString(r["itm_code"]), name = Convert.ToString(r["itm_name"]),
                stock = D(r["itbs_stock"]), tax = D(r["tp_tax_percentage"]), cess = D(r["tp_cess"]), uomId = I(r["itsv_uom_sales"]),
                price = r["classPrice"] != DBNull.Value ? D(r["classPrice"]) : D(r["itm_mrp"])
            });
        return list;
    }

    // Price class of the order (saved with the order, otherwise the customer's current class).
    static int PriceClass(mySqlConnection db, bool tx, DataRow m)
    {
        int pc = m.Table.Columns.Contains("smo_price_class") ? I(m["smo_price_class"]) : 0;
        return pc > 0 ? pc : I(Scalar(db, tx, "select cust_type from tbl_customer where cust_id=@c", new MySqlParameter("@c", I(m["cust_id"]))));
    }

    // Fingerprint of everything the edit can change; a stale form is rejected instead of overwriting someone else's change.
    public static string Token(mySqlConnection db, bool tx, int smoId)
    {
        DataTable m = Sel(db, tx, "select * from tbl_sales_master_order where smo_id=@o", new MySqlParameter("@o", smoId));
        DataTable l = Sel(db, tx, "select * from tbl_sales_items_order where smo_id=@o order by sio_id", new MySqlParameter("@o", smoId));
        var sb = new StringBuilder();
        if (m.Rows.Count > 0)
            foreach (string c in new[] { "smo_delivery_status", "smo_netamount", "smo_specialnote", "smo_payment_type", "smo_order_type" })
                if (m.Columns.Contains(c)) sb.Append(c).Append('=').Append(Convert.ToString(m.Rows[0][c])).Append('|');
        foreach (DataRow r in l.Rows)
            foreach (string c in new[] { "sio_id", "sio_finalqty", "sio_price", "sio_discount_rate", "sio_no_piece", "tum_id_cust", "sio_length_cust_fraction", "sio_width_cust_fraction" })
                if (l.Columns.Contains(c)) sb.Append(c).Append('=').Append(Convert.ToString(r[c])).Append('|');
        using (var sha = SHA1.Create())
            return BitConverter.ToString(sha.ComputeHash(Encoding.UTF8.GetBytes(sb.ToString()))).Replace("-", "");
    }

    sealed class SetList
    {
        readonly DataTable cols;
        public readonly List<string> Sets = new List<string>();
        public readonly List<MySqlParameter> Params = new List<MySqlParameter>();
        public SetList(DataTable cols) { this.cols = cols; }

        // Columns that do not exist in this database are skipped.
        public void Add(string col, object value)
        {
            if (!cols.Columns.Contains(col)) return;
            Sets.Add(col + "=@p" + Params.Count);
            Params.Add(new MySqlParameter("@p" + Params.Count, value ?? DBNull.Value));
        }
    }

    // A dimension the line no longer uses: stays NULL when it was NULL, otherwise 0.
    static object Unset(DataRow r, DataTable cols, string col)
    {
        return cols.Columns.Contains(col) && r[col] == DBNull.Value ? (object)DBNull.Value : 0m;
    }

    static string Norm(object o)
    {
        string s = Convert.ToString(o).Trim();
        return s == "" ? "0" : s;
    }

    public static SalesOrderEditResult Save(int staffId, string staffType, SalesOrderEditRequest req)
    {
        var result = new SalesOrderEditResult();
        var db = new mySqlConnection();
        bool started = false;
        try
        {
            if (req == null || req.smoId <= 0 || req.lines == null)
                throw new EditException("Invalid request.");
            if (staffType == "2")
                throw new EditException("You do not have permission to edit this sales order.");
            if (req.paymentType < 0 || req.paymentType > 3 || req.orderType < 0 || req.orderType > 3)
                throw new EditException("Invalid payment type or order type.");
            string note = req.note ?? "";

            db.BeginTransaction();
            started = true;
            var o = new MySqlParameter("@o", req.smoId);

            DataTable mt = db.SelectQueryForTransaction("select * from tbl_sales_master_order where smo_id=@o "
                + "and branch_id in (select branch_id from tbl_user_branches where user_id=@u) for update",
                new MySqlParameter[] { o, new MySqlParameter("@u", staffId) });
            if (mt.Rows.Count == 0)
                throw new EditException("The sales order was not found.");
            DataRow m = mt.Rows[0];

            string block = EditBlock(db, true, req.smoId, I(m["smo_delivery_status"]), Convert.ToString(m["smo_invoice_no"]));
            if (block != "")
                throw new EditException(block);
            if (Token(db, true, req.smoId) != (req.token ?? ""))
                throw new EditException("This sales order was changed by someone else. Reload the page and try again.");

            DataTable lines = db.SelectQueryForTransaction("select * from tbl_sales_items_order where smo_id=@o order by row_no,sio_id for update",
                new MySqlParameter[] { new MySqlParameter("@o", req.smoId) });
            var submitted = new Dictionary<int, SalesOrderEditLine>();
            var added = new List<SalesOrderEditLine>();
            foreach (SalesOrderEditLine sl in req.lines)
            {
                if (sl == null)
                    throw new EditException("Invalid order lines.");
                if (sl.sioId > 0)
                {
                    if (submitted.ContainsKey(sl.sioId))
                        throw new EditException("Invalid order lines.");
                    submitted[sl.sioId] = sl;
                }
                else
                {
                    if (sl.itbsId <= 0)
                        throw new EditException("Each new item needs a valid item selection.");
                    added.Add(sl);
                }
            }
            if (submitted.Count + added.Count == 0)
                throw new EditException("A sales order must have at least one item.");
            foreach (int id in submitted.Keys)
                if (lines.Select("sio_id=" + id).Length == 0)
                    throw new EditException("The order lines have changed. Reload the page and try again.");

            int acc = I(db.SelectScalarForTransaction("select ss_decimal_accuracy from tbl_system_settings"));
            if (acc <= 0) acc = 2;
            int allowZero = I(db.SelectScalarForTransaction("select ss_allow_zero_stock_order from tbl_system_settings"));
            DataTable br = db.SelectQueryForTransaction("select branch_tax_method,branch_tax_inclusive,branch_state_id from tbl_branch where branch_id=@b",
                new MySqlParameter[] { new MySqlParameter("@b", I(m["branch_id"])) });
            int taxMethod = br.Rows.Count > 0 ? I(br.Rows[0]["branch_tax_method"]) : 0;
            int inclusive = br.Rows.Count > 0 ? I(br.Rows[0]["branch_tax_inclusive"]) : 0;
            Dictionary<int, EditUom> uoms = LoadUoms(db, true);

            decimal sTotal = 0, sDisc = 0, sNet = 0, sTaxable = 0, sTax = 0;
            bool anyLineChanged = false;
            var lineUpdates = new List<KeyValuePair<int, SetList>>();
            var removed = new List<int>();
            var keptItems = new HashSet<int>();

            foreach (DataRow r in lines.Rows)
            {
                int sioId = I(r["sio_id"]);
                SalesOrderEditLine s;
                if (!submitted.TryGetValue(sioId, out s))
                {
                    removed.Add(sioId);
                    anyLineChanged = true;
                    continue;
                }
                keptItems.Add(I(r["itbs_id"]));
                string name = Convert.ToString(r["itm_name"]);
                int target = I(r["tum_id"]);

                decimal total = D(r["sio_total"]), disc = D(r["sio_discount_amount"]), tax = D(r["sio_tax_amount"]), net = D(r["sio_net_amount"]);
                decimal taxable = lines.Columns.Contains("sio_tax_excluded_total") ? D(r["sio_tax_excluded_total"]) : net - tax;

                EditLineBase b = BaseOf(r, lines, uoms);
                EditUom cu;
                uoms.TryGetValue(s.tumIdCust, out cu);
                decimal qty = s.qty, len = NeedsLength(cu) ? s.length : 0m, wid = NeedsWidth(cu) ? s.width : 0m;
                bool changed = s.tumIdCust != b.TumCust || !Same(qty, b.Qty) || !Same(len, b.Length) || !Same(wid, b.Width)
                    || !Same(s.price, D(r["sio_price"])) || !Same(s.discountRate, D(r["sio_discount_rate"]));

                if (changed)
                {
                    anyLineChanged = true;
                    if (s.price < 0)
                        throw new EditException(name + ": enter a valid price.");
                    if (s.discountRate < 0 || s.discountRate > 100)
                        throw new EditException(name + ": discount must be between 0 and 100.");
                    decimal final;
                    string err = CalcFinal(uoms, s.tumIdCust, target, qty, len, wid, out final);
                    if (err != null)
                        throw new EditException(name + ": " + err);

                    decimal oldFinal = D(r["sio_finalqty"]);
                    if (final > oldFinal && !Same(final, oldFinal) && allowZero == 0)
                    {
                        string stock = Scalar(db, true, "select itbs_stock from tbl_itembranch_stock where itbs_id=@i", new MySqlParameter("@i", I(r["itbs_id"])));
                        decimal avail;
                        if (!decimal.TryParse(stock, out avail)) avail = 0m;
                        if (final > avail)
                            throw new EditException("Insufficient stock for " + name + ".");
                    }

                    decimal rate = D(r["sio_item_tax"]);
                    decimal cess = lines.Columns.Contains("sio_item_cess") ? D(r["sio_item_cess"]) : 0m;
                    if (taxMethod == 0) { rate = 0; cess = 0; }
                    decimal basePrice = s.price;
                    if (taxMethod != 0 && inclusive == 1)
                    {
                        if (cess > 0) basePrice = 10000m * s.price / (10000m + 100m * rate + rate * cess);
                        else basePrice = s.price / (rate / 100m + 1m);
                    }
                    decimal real = basePrice * final;
                    decimal discAmt = real * s.discountRate / 100m;
                    decimal netBase = real - discAmt;
                    decimal taxAmt = netBase * rate / 100m;
                    taxAmt = taxAmt + taxAmt * cess / 100m;
                    decimal netAmt = netBase + taxAmt;

                    total = Rnd(real, acc);
                    disc = Rnd(discAmt, acc);
                    tax = Rnd(taxAmt, acc);
                    net = Rnd(netAmt, acc);
                    taxable = net - tax;

                    EditUom sales = uoms[target];
                    var set = new SetList(lines);
                    set.Add("sio_no_piece", qty);
                    set.Add("sio_length", ToSalesLinear(len, cu, sales, false) ?? Unset(r, lines, "sio_length"));
                    set.Add("sio_width", ToSalesLinear(wid, cu, sales, true) ?? Unset(r, lines, "sio_width"));
                    set.Add("tum_id_cust", s.tumIdCust);
                    set.Add("sio_length_cust_fraction", len > 0 ? (object)len : DBNull.Value);
                    set.Add("sio_width_cust_fraction", wid > 0 ? (object)wid : DBNull.Value);
                    set.Add("sio_finalqty", final);
                    set.Add("sio_price", Rnd(s.price, acc));
                    set.Add("sio_discount_rate", s.discountRate);
                    set.Add("sio_total", total);
                    set.Add("sio_discount_amount", disc);
                    set.Add("sio_tax_amount", tax);
                    set.Add("sio_net_amount", net);
                    set.Add("sio_tax_excluded_total", taxable);
                    lineUpdates.Add(new KeyValuePair<int, SetList>(sioId, set));
                }

                sTotal += total; sDisc += disc; sTax += tax; sNet += net; sTaxable += taxable;
            }

            var inserts = new List<Dictionary<string, object>>();
            DataRow template = lines.Rows.Count > 0 ? lines.Rows[0] : null;
            if (added.Count > 0)
            {
                anyLineChanged = true;
                DataTable cust = db.SelectQueryForTransaction("select cust_state from tbl_customer where cust_id=@c", new MySqlParameter[] { new MySqlParameter("@c", I(m["cust_id"])) });
                bool sameState = br.Rows.Count > 0 && cust.Rows.Count > 0 && Convert.ToString(br.Rows[0]["branch_state_id"]) == Convert.ToString(cust.Rows[0]["cust_state"]);
                int priceClass = PriceClass(db, true, m);
                int nextRow = 0;
                foreach (DataRow lr in lines.Rows)
                    nextRow = Math.Max(nextRow, I(lr["row_no"]) + 1);
                if (lines.Rows.Count == 0)
                    throw new EditException("The order lines have changed. Reload the page and try again.");

                foreach (SalesOrderEditLine s in added)
                {
                    if (!keptItems.Add(s.itbsId))
                        throw new EditException("The same item is added more than once.");
                    DataTable it = db.SelectQueryForTransaction("select tis.itbs_id,tis.itm_id,tis.itm_name,tis.itbs_stock,tis.itm_commision,tp.tp_tax_percentage,tp.tp_cess,im.itm_type,im.itsv_uom_sales,"
                        + "(select tip_price from tbl_item_pricelist tip where tip.tpm_id=@tpm and tip.itbs_id=tis.itbs_id limit 1) as classPrice "
                        + "from tbl_itembranch_stock tis inner join tbl_tax_profile tp on tp.tp_tax_code=tis.tp_tax_code inner join tbl_item_master im on im.itm_id=tis.itm_id "
                        + "where tis.branch_id=@b and tis.itbs_id=@i and tis.itbs_available=1",
                        new MySqlParameter[] { new MySqlParameter("@tpm", priceClass), new MySqlParameter("@b", I(m["branch_id"])), new MySqlParameter("@i", s.itbsId) });
                    if (it.Rows.Count == 0)
                        throw new EditException("An item is not available in the warehouse of this sales order.");
                    DataRow d = it.Rows[0];
                    string name = Convert.ToString(d["itm_name"]);

                    if (s.price < 0)
                        throw new EditException(name + ": enter a valid price.");
                    if (s.discountRate < 0 || s.discountRate > 100)
                        throw new EditException(name + ": discount must be between 0 and 100.");
                    int target = I(d["itsv_uom_sales"]);
                    if (target <= 0)
                        throw new EditException("Sales unit of measure is not configured for " + name + ".");
                    EditUom cu2, sales;
                    uoms.TryGetValue(s.tumIdCust, out cu2);
                    uoms.TryGetValue(target, out sales);
                    decimal qty = s.qty, len = NeedsLength(cu2) ? s.length : 0m, wid = NeedsWidth(cu2) ? s.width : 0m;
                    decimal final;
                    string err = CalcFinal(uoms, s.tumIdCust, target, qty, len, wid, out final);
                    if (err != null)
                        throw new EditException(name + ": " + err);
                    if (allowZero == 0 && final > D(d["itbs_stock"]))
                        throw new EditException("Insufficient stock for " + name + ".");

                    decimal rate = D(d["tp_tax_percentage"]);
                    decimal cess = D(d["tp_cess"]);
                    decimal comm = D(d["itm_commision"]);
                    if (taxMethod == 0) { rate = 0; cess = 0; }
                    decimal basePrice = s.price;
                    if (taxMethod != 0 && inclusive == 1)
                    {
                        if (cess > 0) basePrice = 10000m * s.price / (10000m + 100m * rate + rate * cess);
                        else basePrice = s.price / (rate / 100m + 1m);
                    }
                    decimal real = basePrice * final;
                    decimal discAmt = real * s.discountRate / 100m;
                    decimal netBase = real - discAmt;
                    decimal taxAmt = netBase * rate / 100m;
                    taxAmt = taxAmt + taxAmt * cess / 100m;
                    decimal netAmt = netBase + taxAmt;
                    decimal total = Rnd(real, acc), disc = Rnd(discAmt, acc), tax = Rnd(taxAmt, acc), net = Rnd(netAmt, acc);

                    // Columns that are not set here keep the values of an existing line of the order.
                    var v = new Dictionary<string, object>
                    {
                        { "smo_id", req.smoId }, { "row_no", nextRow++ }, { "itbs_id", s.itbsId }, { "itm_id", I(d["itm_id"]) }, { "itm_name", name },
                        { "itm_type", I(d["itm_type"]) }, { "tum_id", target }, { "sio_no_piece", qty },
                        { "sio_length", ToSalesLinear(len, cu2, sales, false) ?? Unset(template, lines, "sio_length") },
                        { "sio_width", ToSalesLinear(wid, cu2, sales, true) ?? Unset(template, lines, "sio_width") },
                        { "tum_id_cust", s.tumIdCust },
                        { "sio_length_cust_fraction", len > 0 ? (object)len : DBNull.Value },
                        { "sio_width_cust_fraction", wid > 0 ? (object)wid : DBNull.Value },
                        { "sio_finalqty", final },
                        { "sio_org_price", d["classPrice"] == DBNull.Value ? Rnd(s.price, acc) : Rnd(D(d["classPrice"]), acc) },
                        { "sio_price", Rnd(s.price, acc) }, { "sio_discount_rate", s.discountRate }, { "sio_total", total },
                        { "sio_discount_amount", disc }, { "sio_tax_amount", tax }, { "sio_net_amount", net },
                        { "sio_tax_excluded_total", net - tax }, { "sio_item_tax", rate }, { "sio_item_cess", cess },
                        { "sio_item_cgst", taxMethod == 2 && sameState ? Rnd(rate / 2m, acc) : 0m },
                        { "sio_item_sgst", taxMethod == 2 && sameState ? Rnd(rate / 2m, acc) : 0m },
                        { "sio_item_igst", taxMethod == 2 && !sameState ? rate : 0m },
                        { "sio_item_utgst", 0m },
                        { "itm_commision", comm }, { "itm_commisionamt", Rnd((taxMethod == 0 ? netBase : netAmt) * comm / 100m, acc) },
                        { "sio_foc", 0 }, { "sio_approval_status", 0 }, { "sio_itm_type", 0 }, { "ofr_id", 0 }, { "ofritm_id", 0 }
                    };
                    inserts.Add(v);
                    sTotal += total; sDisc += disc; sTax += tax; sNet += net; sTaxable += net - tax;
                }
            }

            var head = new SetList(mt);
            if (Norm(m["smo_payment_type"]) != req.paymentType.ToString()) head.Add("smo_payment_type", req.paymentType);
            if (Norm(m["smo_order_type"]) != req.orderType.ToString()) head.Add("smo_order_type", req.orderType);
            if (Convert.ToString(m["smo_specialnote"]).Replace("\r\n", "\n") != note.Replace("\r\n", "\n"))
            {
                if (note.Length > MaxNoteLength)
                    throw new EditException("Notes are limited to " + MaxNoteLength + " characters.");
                head.Add("smo_specialnote", note);
            }
            if (anyLineChanged)
            {
                head.Add("smo_total", sTotal);
                head.Add("smo_discount_amount", sDisc);
                head.Add("smo_netamount", sNet);
                head.Add("smo_tax_excluded_amt", sTaxable);
                head.Add("smo_tax_amount", sTax);
                head.Add("smo_roundoff", 0m);
                head.Add("smo_discount_rate", (sTaxable + sDisc) == 0 ? 0m : Rnd(sDisc * 100m / (sTaxable + sDisc), acc));
            }
            if (head.Sets.Count == 0 && lineUpdates.Count == 0)
            {
                db.RollBackTransaction();
                started = false;
                result.ok = true;
                result.message = "No changes to save.";
                return result;
            }
            head.Add("smo_last_updated_date", BranchClock.NowInTransaction(db, Convert.ToString(m["branch_id"])).ToString(BranchClock.StorageFormat));

            foreach (var u in lineUpdates)
            {
                var ps = new List<MySqlParameter>(u.Value.Params);
                ps.Add(new MySqlParameter("@sio", u.Key));
                ps.Add(new MySqlParameter("@smo", req.smoId));
                db.ExecuteQueryForTransaction("update tbl_sales_items_order set " + string.Join(",", u.Value.Sets) + " where sio_id=@sio and smo_id=@smo", ps.ToArray());
            }
            foreach (int sioId in removed)
            {
                // Reservation rows are already blocked by EditBlock; this only clears leftover empty rows so the line can be deleted.
                db.ExecuteQueryForTransaction("delete from tbl_item_batchstock_reserve where sio_id=@s", new MySqlParameter[] { new MySqlParameter("@s", sioId) });
                db.ExecuteQueryForTransaction("delete from tbl_sales_items_order where sio_id=@s and smo_id=@o", new MySqlParameter[] { new MySqlParameter("@s", sioId), new MySqlParameter("@o", req.smoId) });
            }
            foreach (Dictionary<string, object> v in inserts)
            {
                var names = new List<string>();
                var marks = new List<string>();
                var ips = new List<MySqlParameter>();
                foreach (DataColumn c in lines.Columns)
                {
                    if (c.ColumnName == "sio_id") continue;
                    object value;
                    if (!v.TryGetValue(c.ColumnName, out value))
                        value = template[c.ColumnName];
                    names.Add("`" + c.ColumnName + "`");
                    marks.Add("@c" + ips.Count);
                    ips.Add(new MySqlParameter("@c" + ips.Count, value ?? DBNull.Value));
                }
                db.ExecuteQueryForTransaction("insert into tbl_sales_items_order (" + string.Join(",", names) + ") values (" + string.Join(",", marks) + ")", ips.ToArray());
            }
            var hp = new List<MySqlParameter>(head.Params);
            hp.Add(new MySqlParameter("@smo", req.smoId));
            db.ExecuteQueryForTransaction("update tbl_sales_master_order set " + string.Join(",", head.Sets) + " where smo_id=@smo", hp.ToArray());
            // The status follows the saved order (for example a Processed order without reservations returns to Approved); New and On Hold stay as they are.
            SalesOrderStatus.TryUpdateSalesOrderStatus(db, req.smoId, staffId);

            db.CommitTransaction();
            started = false;
            result.ok = true;
            result.message = "Sales order updated.";
        }
        catch (EditException ex)
        {
            Rollback(db, started);
            result.message = ex.Message;
        }
        catch (Exception ex)
        {
            Rollback(db, started);
            new LogClass("salesordererror").write(ex);
            result.message = "Unable to save the sales order. No changes were saved. Please try again.";
        }
        finally
        {
            try { db.CloseConnection(); } catch (Exception) { }
        }
        return result;
    }

    static void Rollback(mySqlConnection db, bool started)
    {
        if (!started) return;
        try { db.RollBackTransaction(); }
        catch (Exception ex) { new LogClass("salesordererror").write(ex); }
    }
}
