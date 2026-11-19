using System;
using System.Data;
using System.Globalization;
using commonfunction;
using MySql.Data.MySqlClient;

// Current date/time of a branch, derived from tbl_branch.branch_timezone only (never the browser, cookie or server clock).
public static class BranchClock
{
    public const string StorageFormat = "yyyy-MM-dd HH:mm:ss";

    public static DateTime Now(mySqlConnection db, string branchId)
    {
        int id;
        if (!int.TryParse((branchId ?? "").Trim(), out id) || id <= 0)
            throw new InvalidOperationException("A valid branch is required to determine the branch time.");

        string tzId = db.SelectScalar("select branch_timezone from tbl_branch where branch_id=@b",
            new MySqlParameter[] { new MySqlParameter("@b", id) });
        return FromTimeZoneId(tzId, id);
    }

    // Same as Now, but for use inside an open transaction on the same connection.
    public static DateTime NowInTransaction(mySqlConnection db, string branchId)
    {
        int id;
        if (!int.TryParse((branchId ?? "").Trim(), out id) || id <= 0)
            throw new InvalidOperationException("A valid branch is required to determine the branch time.");

        string tzId = db.SelectScalarForTransaction("select branch_timezone from tbl_branch where branch_id=@b",
            new MySqlParameter[] { new MySqlParameter("@b", id) });
        return FromTimeZoneId(tzId, id);
    }

    public static DateTime NowForPurchase(mySqlConnection db, string purchaseId)
    {
        string branchId = db.SelectScalar("select branch_id from tbl_purchase_master where pm_id=@p",
            new MySqlParameter[] { new MySqlParameter("@p", ParsePurchaseId(purchaseId)) });
        return Now(db, branchId);
    }

    public static DateTime NowForPurchaseInTransaction(mySqlConnection db, string purchaseId)
    {
        string branchId = db.SelectScalarForTransaction("select branch_id from tbl_purchase_master where pm_id=@p",
            new MySqlParameter[] { new MySqlParameter("@p", ParsePurchaseId(purchaseId)) });
        return NowInTransaction(db, branchId);
    }

    public static DateTime NowForSalesOrder(mySqlConnection db, int smoId)
    {
        string branchId = db.SelectScalar("select branch_id from tbl_sales_master_order where smo_id=@o",
            new MySqlParameter[] { new MySqlParameter("@o", smoId) });
        return Now(db, branchId);
    }

    public static DateTime NowForSalesOrderInTransaction(mySqlConnection db, int smoId)
    {
        string branchId = db.SelectScalarForTransaction("select branch_id from tbl_sales_master_order where smo_id=@o",
            new MySqlParameter[] { new MySqlParameter("@o", smoId) });
        return NowInTransaction(db, branchId);
    }

    public static DateTime NowForSale(mySqlConnection db, string smId)
    {
        string branchId = db.SelectScalar("select branch_id from tbl_sales_master where sm_id=@s",
            new MySqlParameter[] { new MySqlParameter("@s", ParseDocumentId(smId, "invoice")) });
        return Now(db, branchId);
    }

    public static DateTime NowForSaleInTransaction(mySqlConnection db, string smId)
    {
        string branchId = db.SelectScalarForTransaction("select branch_id from tbl_sales_master where sm_id=@s",
            new MySqlParameter[] { new MySqlParameter("@s", ParseDocumentId(smId, "invoice")) });
        return NowInTransaction(db, branchId);
    }

    // For a time zone id already read from tbl_branch.branch_timezone.
    public static DateTime FromBranchTimeZone(string tzId, int branchId)
    {
        return FromTimeZoneId(tzId, branchId);
    }

    static int ParsePurchaseId(string purchaseId)
    {
        return ParseDocumentId(purchaseId, "purchase");
    }

    static int ParseDocumentId(string value, string what)
    {
        int id;
        if (!int.TryParse((value ?? "").Trim(), out id) || id <= 0)
            throw new InvalidOperationException("A valid " + what + " is required to determine the branch time.");
        return id;
    }

    static DateTime FromTimeZoneId(string tzId, int branchId)
    {
        if (string.IsNullOrWhiteSpace(tzId))
            throw new InvalidOperationException("Time zone is not configured for branch " + branchId + ".");
        try
        {
            return TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById(tzId.Trim()));
        }
        catch (TimeZoneNotFoundException)
        {
            throw new InvalidOperationException("Invalid time zone '" + tzId + "' configured for branch " + branchId + ".");
        }
        catch (InvalidTimeZoneException)
        {
            throw new InvalidOperationException("Invalid time zone '" + tzId + "' configured for branch " + branchId + ".");
        }
    }

    // The user picks only a date. The stored purchase datetime is that date plus the branch time of day.
    // When editing, an unchanged date keeps the originally stored datetime.
    public static string PurchaseDateTime(string selectedDate, DateTime branchNow, string existingDateTime)
    {
        DateTime selected;
        if (!TryParseDate(selectedDate, out selected))
            throw new InvalidOperationException("Invalid purchase date.");

        DateTime existing;
        if (!string.IsNullOrWhiteSpace(existingDateTime)
            && DateTime.TryParse(existingDateTime, CultureInfo.InvariantCulture, DateTimeStyles.None, out existing)
            && existing.Date == selected.Date)
            return existing.ToString(StorageFormat, CultureInfo.InvariantCulture);

        return selected.Date.Add(branchNow.TimeOfDay).ToString(StorageFormat, CultureInfo.InvariantCulture);
    }

    static bool TryParseDate(string value, out DateTime result)
    {
        string[] formats = { "yyyy-MM-dd", "yyyy-MM-dd HH:mm:ss", "yyyy-M-d", "yyyy/MM/dd", "dd-MM-yyyy" };
        return DateTime.TryParseExact((value ?? "").Trim(), formats, CultureInfo.InvariantCulture, DateTimeStyles.None, out result);
    }
}
