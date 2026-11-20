using System;
using System.Collections.Generic;

// Single definition of the sales order (tbl_sales_master_order.smo_delivery_status) statuses, labels and transitions.
// This file is free of database access so the rules can be reviewed and tested on their own; the stored-data operations
// (automatic recalculation and manual status changes) are in SalesOrderStatusStore.cs.
//
//   0 Draft | 1 New | 2 Approved | 3 Processed | 9 Partially Delivered | 10 Fully Delivered | 11 Cancelled by Company | 12 Cancelled by Customer
//   13 On Hold
//
// Two separate responsibilities:
//   - Manual transitions (Approve, Put On Hold, Cancel) are user actions validated by CanTransition and applied by ChangeSalesOrderStatus.
//   - Operational statuses (2, 3, 9, 10) are always derived from the current reservations, invoices and deliveries by Calculate and
//     stored by UpdateSalesOrderStatus. Draft, New, On Hold and the cancelled statuses are never changed by that calculation.
// Draft (saved with "Save as Draft") and New (saved with "Save Order") are both unapproved orders and follow the same rules.
public static partial class SalesOrderStatus
{
    public const int Draft = 0;
    public const int New = 1;
    public const int Approved = 2;
    public const int Processed = 3;
    public const int PartiallyDelivered = 9;
    public const int FullyDelivered = 10;
    public const int CancelledByCompany = 11;
    public const int CancelledByCustomer = 12;
    public const int OnHold = 13;

    // Last status value; used to validate list filters.
    public const int MaxValue = OnHold;

    // Invoice (tbl_sales_master.sm_delivery_status) values that matter for the order status.
    public const int InvoiceDelivered = 2;
    public const int InvoiceCancelled = 4;
    public const int InvoiceRejected = 5;

    // SQL predicate for the invoices that count towards invoiced quantity: every invoice that is not cancelled or rejected.
    // "sm" is the tbl_sales_master alias.
    public const string ValidInvoiceSql = "ifnull(sm.sm_delivery_status,0) not in (4,5)";

    // Quantities are stored with 3 decimals.
    const decimal QtyTolerance = 0.0005m;

    public static string Name(int status)
    {
        switch (status)
        {
            case Draft: return "Draft";
            case New: return "To be confirmed";
            case OnHold: return "On Hold";
            case Approved: return "Approved";
            case Processed: return "Processed";
            case PartiallyDelivered: return "Partially Delivered";
            case FullyDelivered: return "Fully Delivered";
            case CancelledByCompany: return "Cancelled by Company";
            case CancelledByCustomer: return "Cancelled by Customer";
            default: return "";
        }
    }

    public static string Css(int status)
    {
        switch (status)
        {
            case Draft: return "label label-default";
            case New: return "label label-warning";
            case OnHold: return "label label-info";
            case Approved: return "label label-success";
            case Processed: return "label label-primary";
            case PartiallyDelivered: return "label label-info";
            case FullyDelivered: return "label label-success";
            default: return "label label-default";
        }
    }

    public static bool IsCancelled(int status) { return status == CancelledByCustomer || status == CancelledByCompany; }

    // Draft and New orders are not approved yet and are handled identically.
    public static bool IsUnapproved(int status) { return status == Draft || status == New; }

    // Statuses whose value is calculated from reservations, invoices and deliveries.
    public static bool IsOperational(int status)
    {
        return status == Approved || status == Processed || status == PartiallyDelivered || status == FullyDelivered;
    }

    // Stock may be reserved, allocated, produced or invoiced against the order only in these statuses. A partially delivered order
    // must stay open, otherwise its remaining quantity could never be invoiced.
    public static bool CanReserve(int status) { return status == Approved || status == Processed || status == PartiallyDelivered; }

    // Reservations may be released in every status except a fully delivered order.
    public static bool CanRelease(int status)
    {
        return IsUnapproved(status) || status == OnHold || CanReserve(status) || IsCancelled(status);
    }

    public static bool CanApprove(int status) { return IsUnapproved(status) || status == OnHold; }

    // A fully delivered order cannot be put on hold.
    public static bool CanHold(int status) { return IsUnapproved(status) || status == Approved || status == Processed || status == PartiallyDelivered; }

    public static bool CanCancel(int status)
    {
        return IsUnapproved(status) || status == OnHold || status == Approved || status == Processed
            || status == PartiallyDelivered || status == FullyDelivered;
    }

    // Manual (user-initiated) transitions only. Cancelled orders accept no further transition and no status can be set back to Draft or New.
    public static bool CanTransition(int from, int to)
    {
        switch (to)
        {
            case Approved: return CanApprove(from);
            case OnHold: return CanHold(from);
            case CancelledByCustomer:
            case CancelledByCompany: return CanCancel(from);
            default: return false;
        }
    }

    // Ordered, invoiced (valid invoices only) and delivered (valid invoices that are delivered) quantity of one order line.
    public sealed class LineQuantity
    {
        public decimal Ordered;
        public decimal Invoiced;
        public decimal Delivered;
    }

    // Fully delivered only when every ordered quantity is invoiced and every invoiced quantity is delivered. Lines are judged on their own
    // quantities, never on the number or status of invoices.
    public static bool IsFullyDelivered(IList<LineQuantity> lines)
    {
        bool any = false;
        if (lines == null)
            return false;
        foreach (LineQuantity l in lines)
        {
            if (l == null || l.Ordered <= 0m)
                continue;
            any = true;
            if (l.Invoiced + QtyTolerance < l.Ordered)
                return false;
            if (l.Delivered + QtyTolerance < l.Invoiced)
                return false;
        }
        return any;
    }

    // The status an order should have given its current stored status and its current valid records. It depends only on those inputs, so
    // repeated evaluation with unchanged data always gives the same result.
    //   Cancelled, On Hold, Draft and New keep their value (an unapproved order is never approved automatically); the same goes for any unknown value.
    //   Otherwise: Fully Delivered, Partially Delivered (a valid invoice is delivered), Processed (a valid reservation exists), Approved.
    //   Processed belongs to the sales order and depends only on its reservations, never on its invoices.
    public static int Calculate(int current, IList<LineQuantity> lines, bool hasDeliveredInvoice, bool hasValidReservation)
    {
        if (!IsOperational(current))
            return current;
        if (IsFullyDelivered(lines))
            return FullyDelivered;
        if (hasDeliveredInvoice)
            return PartiallyDelivered;
        if (hasValidReservation)
            return Processed;
        return Approved;
    }
}
