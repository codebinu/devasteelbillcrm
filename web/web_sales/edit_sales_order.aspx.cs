using commonfunction;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Data;
using System.Text;
using System.Web;
using System.Web.Services;
using MySql.Data.MySqlClient;

// Edits an existing sales order: header fields and the values of its existing lines. See SalesOrderEdit for the rules.
public partial class web_sales_edit_sales_order : System.Web.UI.Page
{
    protected DataRow Order;
    protected new DataTable Items;
    protected string ErrorMessage = "";
    protected string StatusText = "";
    protected string StatusCss = "label label-default";
    protected string EditHint = "";
    protected string SavedMessage = "";
    protected int SmoId;
    protected bool CanEdit;
    protected string Token = "";
    protected int Accuracy = 2, TaxMethod, TaxInclusive;
    protected string UomJson = "[]", TypeJson = "[]";
    protected decimal ItemsQty;
    DataTable uomTable;

    protected string Disabled { get { return CanEdit ? "" : " disabled=\"disabled\""; } }
    protected string ReadOnly { get { return CanEdit ? "" : " readonly=\"readonly\""; } }

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

            string sql = "select smo.smo_id,smo.smo_invoice_no,smo.cust_id,smo.branch_id,tc.cust_name,tc.cust_tax_reg_id,"
                + "tc.cust_phone,tc.cust_phone1,tc.cust_address,tc.cust_email,tc.cust_city,"
                + "tb.branch_name,smo.smo_total,smo.smo_discount_amount,smo.smo_tax_amount,smo.smo_tax_excluded_amt,smo.smo_netamount,smo.smo_roundoff,"
                + "smo.smo_delivery_status,smo.smo_payment_type,smo.smo_order_type,smo.smo_specialnote,"
                + "DATE_FORMAT(smo.smo_date,'%d-%b-%Y %H:%i') as orderDate,concat(ifnull(ud.first_name,''),' ',ifnull(ud.last_name,'')) as seller_name "
                + "from tbl_sales_master_order smo inner join tbl_customer tc on tc.cust_id=smo.cust_id "
                + "left join tbl_branch tb on tb.branch_id=smo.branch_id left join tbl_user_details ud on ud.user_id=smo.smo_userid "
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
            SmoId = smoId;

            int st;
            if (int.TryParse(Convert.ToString(Order["smo_delivery_status"]), out st) && SalesOrderStatus.Name(st) != "")
            {
                StatusText = SalesOrderStatus.Name(st);
                StatusCss = SalesOrderStatus.Css(st);
            }
            else
            {
                st = -1;
            }

            if (staffType == "2")
                EditHint = "You do not have permission to edit this sales order.";
            else
                EditHint = SalesOrderEdit.EditBlock(db, false, smoId, st, Convert.ToString(Order["smo_invoice_no"]));
            CanEdit = EditHint == "";
            Token = SalesOrderEdit.Token(db, false, smoId);

            int acc;
            if (int.TryParse(db.SelectScalar("select ss_decimal_accuracy from tbl_system_settings"), out acc) && acc > 0)
                Accuracy = acc;
            DataTable br = db.SelectQuery("select branch_tax_method,branch_tax_inclusive from tbl_branch where branch_id=@b",
                new MySqlParameter[] { new MySqlParameter("@b", Convert.ToInt32(Order["branch_id"])) });
            if (br.Rows.Count > 0)
            {
                TaxMethod = Convert.ToInt32(br.Rows[0]["branch_tax_method"]);
                TaxInclusive = Convert.ToInt32(br.Rows[0]["branch_tax_inclusive"]);
            }

            uomTable = db.SelectQuery("select tum_id,tum_name,tum_type_id,tum_convertion_fac from tbl_item_uom");
            UomJson = Script(JsonConvert.SerializeObject(uomTable));
            TypeJson = Script(JsonConvert.SerializeObject(db.SelectQuery("select tumt_id,tumt_name,ifnull(tum_id,0) as tum_id from tbl_item_uom_type")));

            Items = db.SelectQuery("select sio.*,"
                + "(select tis.itm_code from tbl_itembranch_stock tis where tis.itbs_id=sio.itbs_id limit 1) as itm_code,"
                + "(select u.tum_name from tbl_item_uom u where u.tum_id=sio.tum_id limit 1) as uom "
                + "from tbl_sales_items_order sio where sio.smo_id=@id order by sio.row_no",
                new MySqlParameter[] { new MySqlParameter("@id", smoId) });
            string[] extra = { "sl", "edit_qty", "edit_length", "edit_width", "edit_uom", "edit_taxable", "edit_reserved" };
            foreach (string col in extra)
                Items.Columns.Add(col, typeof(string));

            Dictionary<int, EditUom> uoms = SalesOrderEdit.LoadUoms(db, false);
            Dictionary<int, int> reserved = SalesOrderEdit.ReservationCounts(db, false, smoId);
            bool hasTaxable = Items.Columns.Contains("sio_tax_excluded_total");
            int sl = 1;
            foreach (DataRow r in Items.Rows)
            {
                r["sl"] = (sl++).ToString();
                EditLineBase b = SalesOrderEdit.BaseOf(r, Items, uoms);
                r["edit_qty"] = b.Qty > 0 ? Num(b.Qty) : "";
                r["edit_length"] = b.Length > 0 ? Num(b.Length) : "";
                r["edit_width"] = b.Width > 0 ? Num(b.Width) : "";
                r["edit_uom"] = b.TumCust.ToString();
                r["edit_taxable"] = Num(hasTaxable ? Dec(r["sio_tax_excluded_total"]) : Dec(r["sio_net_amount"]) - Dec(r["sio_tax_amount"]));
                int count;
                r["edit_reserved"] = reserved.TryGetValue(Convert.ToInt32(r["sio_id"]), out count) ? count.ToString() : "0";
                ItemsQty += Dec(r["sio_finalqty"]);
            }

            if (Request.QueryString["done"] == "saved")
                SavedMessage = "Sales order updated.";
        }
        catch (Exception ex)
        {
            Order = null;
            new LogClass("salesordererror").write(ex);
            ErrorMessage = "Unable to load the sales order. Please try again.";
        }
    }

    [WebMethod]
    public static SalesOrderEditResult SaveEdit(SalesOrderEditRequest request)
    {
        var context = HttpContext.Current;
        int staffId = 0;
        if (request == null || request.smoId <= 0 || context == null
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
        return SalesOrderEdit.Save(staffId, context.Request.Cookies["invntrystaffTypeID"].Value, request);
    }

    // Keeps a JSON literal safe inside an inline script block.
    static string Script(string json)
    {
        return json.Replace("<", "\\u003c").Replace(">", "\\u003e").Replace("&", "\\u0026");
    }

    // Unit options for a line: the units that convert into the line's own unit.
    protected string UomOptions(object lineUomId, object selectedId)
    {
        int line, selected;
        int.TryParse(Convert.ToString(lineUomId), out line);
        int.TryParse(Convert.ToString(selectedId), out selected);
        string typeId = "";
        foreach (DataRow u in uomTable.Rows)
            if (Convert.ToString(u["tum_id"]) == line.ToString())
                typeId = Convert.ToString(u["tum_type_id"]);

        var sb = new StringBuilder();
        foreach (DataRow u in uomTable.Rows)
        {
            if (Convert.ToString(u["tum_type_id"]) != typeId || Dec(u["tum_convertion_fac"]) <= 0)
                continue;
            int id = Convert.ToInt32(u["tum_id"]);
            sb.Append("<option value=\"").Append(id).Append("\"").Append(id == selected ? " selected=\"selected\"" : "").Append(">")
                .Append(Enc(u["tum_name"])).Append("</option>");
        }
        return sb.ToString();
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

    protected string NumCol(DataRow r, string col)
    {
        return Items.Columns.Contains(col) ? Num(r[col]) : "0";
    }

    protected string Enc(object o)
    {
        return o == null || o == DBNull.Value ? "" : HttpUtility.HtmlEncode(Convert.ToString(o));
    }

    protected bool Has(string col)
    {
        return Order != null && Order[col] != DBNull.Value && Convert.ToString(Order[col]).Trim() != "";
    }

    protected string Selected(string col, string value)
    {
        string current = Convert.ToString(Order[col]).Trim();
        if (current == "") current = "0";
        return current == value ? " selected=\"selected\"" : "";
    }
}
