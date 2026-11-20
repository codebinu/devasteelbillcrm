-- Optional: indexes for the Stock View module (web/web_inventory/stock_view.aspx). Not required for correctness.
-- Stock View is read-only; these only speed up its lookups. Run once on the live database after reviewing existing indexes and skip
-- any statement whose index (or an equivalent one on the same column) already exists; every statement is online-safe on InnoDB.
-- Already covered by sales-order-invoice-indexes.sql / track-batch-indexes.sql when those were applied:
--   tbl_sales_items (sio_id), tbl_sales_master (sm_refid), tbl_item_batchstock_reserve (sio_id / itbh_id).

-- physical stock per warehouse and item (the listing aggregates by item, the details by item and warehouse)
create index idx_itembranch_stock_itm_branch on tbl_itembranch_stock (itm_id, branch_id);

-- reservations are joined to their batch and then to the stock row
create index idx_item_batch_itbs on tbl_item_batch (itbs_id);
create index idx_batchstock_reserve_sio_id on tbl_item_batchstock_reserve (sio_id);
create index idx_batchstock_reserve_itbh on tbl_item_batchstock_reserve (itbh_id);

-- active order lines and their warehouse / status
create index idx_sales_master_order_status on tbl_sales_master_order (smo_delivery_status, branch_id);
create index idx_sales_items_order_itm on tbl_sales_items_order (itm_id);

-- item type (Finished Goods / Raw Material) is derived from the bill of materials
create index idx_item_master_bom_output on tbl_item_master_bom (itm_id_output);
create index idx_item_master_bom_input on tbl_item_master_bom (itm_id_input);

-- stock movement history of an item
create index idx_stock_transactions_itbs_date on tbl_stock_transactions (itbs_id, date);
