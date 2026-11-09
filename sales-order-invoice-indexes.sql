-- Optional: indexes for sales-order invoicing (not required for correctness).
-- The remaining-quantity and invoice-list queries filter tbl_sales_items by sio_id and tbl_sales_master by sm_refid,
-- neither of which is indexed. Run once on the live database after reviewing existing indexes; both statements are online-safe on InnoDB.
create index idx_sales_items_sio_id on tbl_sales_items (sio_id);
create index idx_sales_master_refid on tbl_sales_master (sm_refid);
