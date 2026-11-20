-- One-time data migration to the sales order status model (tbl_sales_master_order.smo_delivery_status). No schema change.
--
--   old value                      -> new value
--   0 New                          -> 0 Draft
--   1 Approved                     -> 2 Approved   (3 Processed when it holds a reservation, see step 3)
--   2 Fully Delivered              -> 10 Fully Delivered
--   3 Partially Delivered          -> 9 Partially Delivered
--   4 Pending (on hold)            -> 1 On Hold
--   5 Customer Cancelled           -> 12 Cancelled by Customer
--   6 Company Cancelled            -> 11 Cancelled by Company
--   7 Processed                    -> 3 Processed
--
-- Run it ONCE, after the previous application version is stopped and before the new one starts: the old and new meanings of
-- 1, 2 and 3 overlap, so running it twice (or running it after the new version has been used) would corrupt the statuses.
-- Step 2 refuses to run when a value that only exists in the new model (9 to 12) is already present.
-- Take a backup of tbl_sales_master_order first. After the migration, statuses of Approved / Processed / Delivered orders are
-- recalculated from their reservations and invoices whenever the order is opened or changed, so no further clean-up is needed.

-- 1. Preview: orders per current status
select smo_delivery_status, count(*) as orders
from tbl_sales_master_order
group by smo_delivery_status
order by smo_delivery_status;

-- 2. Remap the values in a single statement (a CASE is evaluated per row, so the overlapping values cannot chain into each other)
update tbl_sales_master_order
set smo_delivery_status = case smo_delivery_status
        when 0 then 0
        when 1 then 2
        when 2 then 10
        when 3 then 9
        when 4 then 1
        when 5 then 12
        when 6 then 11
        when 7 then 3
        else smo_delivery_status end
where smo_delivery_status in (0, 1, 2, 3, 4, 5, 6, 7)
  and (select count(*) from (select distinct smo_id from tbl_sales_master_order where smo_delivery_status >= 8) migrated) = 0;

-- 3. Orders approved before the Processed status existed that already hold a reservation become Processed
update tbl_sales_master_order smo
set smo.smo_delivery_status = 3
where smo.smo_delivery_status = 2
  and exists (select 1 from tbl_sales_items_order sio
              inner join tbl_item_batchstock_reserve r on r.sio_id = sio.sio_id
              where sio.smo_id = smo.smo_id and r.itbsr_qty > 0);

-- 4. Verify: orders per new status (0 Draft, 1 On Hold, 2 Approved, 3 Processed, 9 Partially Delivered, 10 Fully Delivered, 11/12 Cancelled)
select smo_delivery_status, count(*) as orders
from tbl_sales_master_order
group by smo_delivery_status
order by smo_delivery_status;
