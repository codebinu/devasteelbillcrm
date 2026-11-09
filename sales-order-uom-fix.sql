-- One-off data fix: sales order lines were saved with the UOM typed in by the user, while sio_finalqty is always in the item's sales UOM.
-- Back up tbl_sales_items_order first. Step 1 lists the affected lines; review it before running step 2.
-- Only lines created through new_sales_order.aspx are expected to be affected; if older lines stored sio_finalqty in another UOM, exclude them.

-- 1. Preview
select sio.sio_id, sio.smo_id, sio.itm_id, sio.tum_id as stored_tum_id, im.itsv_uom_sales as sales_tum_id, sio.sio_finalqty
from tbl_sales_items_order sio
inner join tbl_item_master im on im.itm_id = sio.itm_id
where im.itsv_uom_sales is not null and im.itsv_uom_sales > 0
  and ifnull(sio.tum_id, 0) <> im.itsv_uom_sales;

-- 2. Fix
update tbl_sales_items_order sio
inner join tbl_item_master im on im.itm_id = sio.itm_id
set sio.tum_id = im.itsv_uom_sales
where im.itsv_uom_sales is not null and im.itsv_uom_sales > 0
  and ifnull(sio.tum_id, 0) <> im.itsv_uom_sales;
