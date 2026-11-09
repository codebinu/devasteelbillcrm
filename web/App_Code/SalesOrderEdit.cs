using commonfunction;
using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Data;
using System.Security.Cryptography;
using System.Text;

// Editing an existing sales order (edit_sales_order.aspx): header fields (payment type, order type, notes) and the values of the
// existing lines (quantity, size, UOM, price, discount). Lines are never added or removed.
//  - Allowed in New, Pending, Approved and Processed orders that have no invoice and no production entry.
//  - A line whose final quantity changes loses its reservations (they are released in the same transaction); price/discount-only
//    changes keep them.
//  - Final quantity, line amounts and order totals are recalculated here; the client preview is never trusted.
//  - Tax rates of a line are kept as saved (sio_item_tax / sio_item_cess); only lines the user changed are rewritten.

public class SalesOrderEditLine
{
    public int sioId;
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
        return status == SalesOrderStatus.New || status == SalesOrderStatus.Pending
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
        string docNo = ProductionService.DocNoFor(smoId, invoiceNo);
        if (Scalar(db, tx, "select count(*) from tbl_item_pro_master where itpm_doc_no=@d1 or itpm_doc_no=@d2",
            new MySqlParameter("@d1", docNo), new MySqlParameter("@d2", "SO-" + smoId)) != "0")
            return "A production entry exists for this sales order, so it can no longer be edited.";
        return "";
    }

    // Number of reservation rows per order line.
    public static Dictionary<int, int> ReservationCounts(mySqlConnection db, bool tx, int smoId)
    {
        var map = new Dictionary<int, int>();
        foreach (DataRow r in Sel(db, tx, "select r.sio_id,count(*) as c from tbl_item_batchstock_reserve r "
            + "where r.itbsr_qty>0 and r.sio_id in (select sio_id from tbl_sales_items_order where smo_id=@o) group by r.sio_id",
            new MySqlParameter("@o", smoId)).Rows)
            map[I(r["sio_id"])] = I(r["c"]);
        return map;
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
            if (req.lines.Count != lines.Rows.Count)
                throw new EditException("The order lines have changed. Reload the page and try again.");
            var submitted = new Dictionary<int, SalesOrderEditLine>();
            foreach (SalesOrderEditLine sl in req.lines)
            {
                if (sl == null || submitted.ContainsKey(sl.sioId))
                    throw new EditException("Invalid order lines.");
                submitted[sl.sioId] = sl;
            }

            int acc = I(db.SelectScalarForTransaction("select ss_decimal_accuracy from tbl_system_settings"));
            if (acc <= 0) acc = 2;
            int allowZero = I(db.SelectScalarForTransaction("select ss_allow_zero_stock_order from tbl_system_settings"));
            DataTable br = db.SelectQueryForTransaction("select branch_tax_method,branch_tax_inclusive from tbl_branch where branch_id=@b",
                new MySqlParameter[] { new MySqlParameter("@b", I(m["branch_id"])) });
            int taxMethod = br.Rows.Count > 0 ? I(br.Rows[0]["branch_tax_method"]) : 0;
            int inclusive = br.Rows.Count > 0 ? I(br.Rows[0]["branch_tax_inclusive"]) : 0;
            Dictionary<int, EditUom> uoms = LoadUoms(db, true);

            decimal sTotal = 0, sDisc = 0, sNet = 0, sTaxable = 0, sTax = 0;
            bool anyLineChanged = false;
            int releasedLines = 0;
            var lineUpdates = new List<KeyValuePair<int, SetList>>();
            var release = new List<int>();

            foreach (DataRow r in lines.Rows)
            {
                int sioId = I(r["sio_id"]);
                SalesOrderEditLine s;
                if (!submitted.TryGetValue(sioId, out s))
                    throw new EditException("The order lines have changed. Reload the page and try again.");
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
                    bool finalChanged = !Same(final, oldFinal);
                    if (finalChanged && final > oldFinal && allowZero == 0)
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
                    if (finalChanged) release.Add(sioId);
                }

                sTotal += total; sDisc += disc; sTax += tax; sNet += net; sTaxable += taxable;
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
            head.Add("smo_last_updated_date", DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"));

            foreach (var u in lineUpdates)
            {
                var ps = new List<MySqlParameter>(u.Value.Params);
                ps.Add(new MySqlParameter("@sio", u.Key));
                ps.Add(new MySqlParameter("@smo", req.smoId));
                db.ExecuteQueryForTransaction("update tbl_sales_items_order set " + string.Join(",", u.Value.Sets) + " where sio_id=@sio and smo_id=@smo", ps.ToArray());
            }
            foreach (int sioId in release)
            {
                db.ExecuteQueryForTransaction("delete from tbl_item_batchstock_reserve where sio_id=@s", new MySqlParameter[] { new MySqlParameter("@s", sioId) });
                if (Convert.ToInt32(db.SelectScalarForTransaction("select row_count()")) > 0)
                    releasedLines++;
            }
            var hp = new List<MySqlParameter>(head.Params);
            hp.Add(new MySqlParameter("@smo", req.smoId));
            db.ExecuteQueryForTransaction("update tbl_sales_master_order set " + string.Join(",", head.Sets) + " where smo_id=@smo", hp.ToArray());

            db.CommitTransaction();
            started = false;
            result.ok = true;
            result.message = "Sales order updated."
                + (releasedLines > 0 ? " Reservations of " + releasedLines + " changed item(s) were released; reserve stock again if needed." : "");
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
