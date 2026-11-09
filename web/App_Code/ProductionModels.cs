using System.Collections.Generic;

// Models for sp_save_production_entry (verified definition: see production_workflow_reference.md).
// The procedure accepts one reservation row id, an output quantity and a user id; everything else is derived by the database.

// Request payload. SmoId / SioId are NOT procedure parameters: they are used only by ProductionService to verify that
// the reservation row really belongs to the sales order the user is working on.
public class ProductionEntryRequest
{
    public int SmoId { get; set; }
    public int SioId { get; set; }

    // p_itbsr_id: tbl_item_batchstock_reserve.itbsr_id of the input (raw-material) reservation to consume.
    public int ReservationId { get; set; }

    // p_output_qty: DECIMAL(10,6), stored as the finished batch quantity without UOM conversion.
    public decimal OutputQty { get; set; }

    // p_user_id
    public int UserId { get; set; }
}

// Procedure result (the p_result JSON plus the p_itpm_id OUT parameter).
public class ProductionEntryResult
{
    public bool Success { get; set; }
    public int ErrorCode { get; set; }
    public string SqlState { get; set; }
    public string Message { get; set; }

    // Raw database message for logging / support only; never display it to users.
    public string Detail { get; set; }
    public int ItpmId { get; set; }
    public int SmoId { get; set; }
    public int ReservationId { get; set; }
    public decimal OutputQty { get; set; }
    public int OutputBatchId { get; set; }
    public int OutputReservationId { get; set; }
    public string DocNo { get; set; }
    public int InputCount { get; set; }
}

// tbl_item_pro_master
public class ProductionMaster
{
    public int ItpmId { get; set; }
    public string DocNo { get; set; }
    public string DocDate { get; set; }
    public int CreatedById { get; set; }
    public string CreatedBy { get; set; }
    public string CreatedDate { get; set; }
}

// tbl_item_pro_items (InputOutput: 1 = input / consumed, 2 = output / produced)
public class ProductionItemRecord
{
    public const int Input = 1;
    public const int Output = 2;

    public int ItpiId { get; set; }
    public int BranchId { get; set; }
    public int ItpmId { get; set; }
    public int Serial { get; set; }
    public int BatchId { get; set; }
    public int InputOutput { get; set; }
    public decimal Quantity { get; set; }
    public decimal Cost { get; set; }
    public string BatchNo { get; set; }
    public int ItemId { get; set; }
    public string ItemCode { get; set; }
    public string ItemName { get; set; }
}

// An input (raw-material) reservation of a sales order line that sp_save_production_entry can consume.
public class ProductionInputReservation
{
    public int ReservationId { get; set; }
    public int SioId { get; set; }
    public int BatchId { get; set; }
    public string BatchNo { get; set; }
    public int BatchBranchId { get; set; }
    public string Warehouse { get; set; }
    public int ItemId { get; set; }
    public string ItemCode { get; set; }
    public string ItemName { get; set; }
    public decimal Quantity { get; set; }
    public decimal BatchCost { get; set; }
    public bool IsBomComponent { get; set; }
}

// Everything the screen needs to prepare a request for one sales order line.
public class ProductionPayloadContext
{
    public bool Ok { get; set; }
    public string Message { get; set; }
    public int SmoId { get; set; }
    public int SioId { get; set; }
    public int BranchId { get; set; }
    public int OrderStatus { get; set; }
    public string DocNo { get; set; }
    public bool ProductionExists { get; set; }
    public List<ProductionInputReservation> Inputs { get; set; }

    public ProductionPayloadContext()
    {
        Inputs = new List<ProductionInputReservation>();
    }
}
