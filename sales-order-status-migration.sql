-- One-time data migration for the sales order status model (tbl_sales_master_order.smo_delivery_status).
-- No schema change is required: the column keeps its existing values and one new value is introduced.
--   0 New | 1 Approved (was labelled "Processed") | 4 Pending (was "To be Confirmed") | 5/6 Cancelled | 2/3 Delivered (unchanged)
--   7 Processed (new): at least one successful stock reservation exists for the order.
-- Orders approved before this change are status 1. Those that already hold a reservation become Processed (7);
-- the rest stay Approved. Run once, after deploying the application and after reviewing the preview query.

-- Preview
select smo.smo_id, smo.smo_invoice_no
from tbl_sales_master_order smo
where smo.smo_delivery_status = 1
  and exists (select 1 from tbl_sales_items_order sio
              inner join tbl_item_batchstock_reserve r on r.sio_id = sio.sio_id
              where sio.smo_id = smo.smo_id and r.itbsr_qty > 0);

-- Apply
update tbl_sales_master_order smo
set smo.smo_delivery_status = 7
where smo.smo_delivery_status = 1
  and exists (select 1 from tbl_sales_items_order sio
              inner join tbl_item_batchstock_reserve r on r.sio_id = sio.sio_id
              where sio.smo_id = smo.smo_id and r.itbsr_qty > 0);
