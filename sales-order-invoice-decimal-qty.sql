-- Schema change for decimal invoice quantities (sales_order_invoice.aspx): tbl_sales_items.si_qty was an integer column.
-- Run once, before deploying the application. Existing whole-number rows keep their values.
-- Check the current definition first and keep the column's NULL / DEFAULT settings when they differ from below.

show columns from tbl_sales_items like 'si_qty';

alter table tbl_sales_items modify column si_qty decimal(18,3) not null default 0;
