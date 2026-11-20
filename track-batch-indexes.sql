-- Optional: indexes for the Track Batch module (web/web_inventory/track_batch.aspx). Not required for correctness.
-- Track Batch is read-only; these only speed up its lookups. None of the batch link columns is indexed today
-- (tbl_item_batch has only its primary key). Run once on the live database after reviewing existing indexes and skip
-- any statement whose index (or an equivalent one on the same column) already exists; every statement is online-safe on InnoDB.
-- The unified search uses LIKE '%text%', which no index can serve; it is limited by the branch filter and paged on the server.

-- batch listing: created-date filter / default sort, item filter
create index idx_item_batch_created on tbl_item_batch (itbh_createddate);
create index idx_item_batch_itm on tbl_item_batch (itm_id);

-- batch detail: every table below is read by itbh_id
create index idx_batchstock_reserve_itbh on tbl_item_batchstock_reserve (itbh_id);
create index idx_pro_items_itbh on tbl_item_pro_items (itbh_id);
create index idx_pro_items_itpm on tbl_item_pro_items (itpm_id);
create index idx_purchase_items_itbh on tbl_purchase_items (itbh_id);
create index idx_sales_items_itbh on tbl_sales_items (itbh_id);
create index idx_stock_transactions_itbh on tbl_stock_transactions (itbh_id, action_type);

-- inter-stock: the purchase that received a transfer invoice is found by sm_id
create index idx_purchase_master_sm_id on tbl_purchase_master (sm_id);
