-- One-time data migration for the New sales order status (tbl_sales_master_order.smo_delivery_status). No schema change.
--
-- Status 1 used to be On Hold; it now means New (an order saved with "Save Order"), and On Hold moves to 13:
--
--   old value        -> new value
--   1 On Hold        -> 13 On Hold
--   0 Draft          -> 0 Draft   (unchanged)
--
-- Run it ONCE, after sales-order-status-migration.sql and after the previous application version is stopped, before the new one
-- starts: after the new version has been used, 1 means New and running it would turn those orders into On Hold. Step 2 refuses to run
-- when an order is already On Hold (13). Take a backup of tbl_sales_master_order first.

-- 1. Preview: orders per current status
select smo_delivery_status, count(*) as orders
from tbl_sales_master_order
group by smo_delivery_status
order by smo_delivery_status;

-- 2. Move On Hold from 1 to 13 (does nothing when value 13 already exists)
update tbl_sales_master_order
set smo_delivery_status = 13
where smo_delivery_status = 1
  and (select count(*) from (select smo_id from tbl_sales_master_order where smo_delivery_status = 13) migrated) = 0;

-- 3. Verify: 0 Draft, 1 New (none yet), 2 Approved, 3 Processed, 9 Partially Delivered, 10 Fully Delivered, 11/12 Cancelled, 13 On Hold
select smo_delivery_status, count(*) as orders
from tbl_sales_master_order
group by smo_delivery_status
order by smo_delivery_status;
