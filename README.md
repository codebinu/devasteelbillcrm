# InvoiceMe

InvoiceMe is an ASP.NET Web Forms application targeting .NET Framework 4.8. The application database is MySQL-compatible and is accessed through the `MySql.Data` provider.

## Database at a glance

The active database configuration was tested read-only on 2026-10-29:

| Property | Verified value |
|---|---|
| Database | `u611891957_deva` |
| Server engine/version | MariaDB 11.8.9 |
| Schema objects | 74 InnoDB base tables, 854 columns, 5 stored procedures |
| Declared foreign keys | None |

These are observations of the configured database at the time of inspection, not a promise that another deployment has the same schema or server version. The inspection read schema metadata only; it did not read or change application records.

## Connection and configuration

- The web application reads the `db_connect_mysql` app setting in [`web/Web.config`](web/Web.config). [`commonfunction/mySqlConnection.cs`](commonfunction/mySqlConnection.cs) uses this setting to construct the MySQL connection.
- Keep connection secrets out of this README, source control, logs, and support tickets. Do not copy a full connection string into documentation. Use the deployment's approved secret/configuration mechanism and verify the effective setting in the target environment.
- [`web/Web.config`](web/Web.config) also defines `DefaultConnection` for ASP.NET session state using `(LocalDb)\MSSQLLocalDB`. This is not the application business database.
- [`commonfunction/dbConnection.cs`](commonfunction/dbConnection.cs) is a separate SQL Server helper that expects an app setting named `DB_CONNECT`. That setting is not present in the active web configuration inspected here; do not assume this helper points to the live application database.
- The project pins `MySql.Data` 9.2.0 in [`commonfunction/packages.config`](commonfunction/packages.config).

To confirm the target in a database client, use read-only metadata queries first:

```sql
SELECT DATABASE(), VERSION();

SELECT TABLE_NAME, TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = DATABASE()
ORDER BY TABLE_NAME;

SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_KEY
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
ORDER BY TABLE_NAME, ORDINAL_POSITION;
```

Do not run schema-changing or data-changing SQL against production as part of routine discovery.

## Schema map

The schema is a legacy, broadly denormalized design. Most entities use integer IDs, with header/detail tables joined by matching ID columns. The database declares no foreign-key constraints, so referential integrity and many relationship rules are enforced by application code and stored procedures. Names below were read from the configured database; the purpose groupings are based on names and application usage.

| Area | Tables |
|---|---|
| Organization and geography | `tbl_branch`, `tbl_country`, `tbl_currency_details`, `tbl_date_setting`, `tbl_district`, `tbl_location`, `tbl_state` |
| Users and access | `ac_action_type`, `tbl_button_permission`, `tbl_page_links`, `tbl_root_tracker`, `tbl_status`, `tbl_user_branches`, `tbl_user_buttons`, `tbl_user_details`, `tbl_user_locations`, `tbl_user_permissions`, `tbl_user_type` |
| Customers | `tbl_customer`, `tbl_customer_category`, `tbl_customer_packages`, `tbl_redeem_history` |
| Items, pricing, and tax | `tbl_coupon_master`, `tbl_item_brand`, `tbl_item_category`, `tbl_item_master`, `tbl_item_master_spe_type`, `tbl_item_master_spe_values`, `tbl_item_pricelist`, `tbl_item_uom`, `tbl_item_uom_type`, `tbl_offer_items`, `tbl_offer_master`, `tbl_price_master`, `tbl_tax_profile`, `tbl_itm_conversion_master`, `tbl_itm_converted_items` |
| Inventory and production | `deva_items_updated`, `tbl_central_stock`, `tbl_itembranch_stock`, `tbl_item_batch`, `tbl_item_batchbranch`, `tbl_item_batchstock_reserve`, `tbl_item_batch_master`, `tbl_item_batch_master_items`, `tbl_item_master_bom`, `tbl_item_master_bom_old`, `tbl_item_pro_items`, `tbl_item_pro_master`, `tbl_stock_transactions`, `tbl_stock_transfer_header`, `tbl_stock_transfer_history`, `tbl_stock_transfer_items` |
| Sales and sales orders | `tbl_sales_master`, `tbl_sales_items`, `tbl_sales_master_order`, `tbl_sales_items_order`, `tbl_salesreturn_master`, `tbl_salesreturn_items`, `tbl_order_approve`, `tbl_edit_history`, `tbl_pending`, `tbl_pending_new`, `tbl_print_info` |
| Purchasing | `tbl_vendor`, `tbl_purchase_master`, `tbl_purchase_items`, `tbl_purchase_return_master`, `tbl_purchase_return_items` |
| Finance | `tbl_transactions`, `tbl_incm_exps`, `tbl_incm_exps_category`, `tbl_payment_edits` |
| General settings | `tbl_system_settings` |

### Important relationships and data conventions

- **Branches and users:** `tbl_branch.branch_id` identifies a branch. `tbl_user_branches` maps users to branches and is used by sales-order queries to enforce branch visibility.
- **Customers:** `tbl_customer.cust_id` is the customer identifier referenced by sales, orders, and returns.
- **Items and branch stock:** `tbl_item_master.itm_id` is the catalog item ID. `tbl_itembranch_stock` associates item/stock data with a branch and exposes `itbs_id`, which detail records commonly use. Item codes/names are also copied into several transaction rows, so historical descriptions can be snapshots rather than live catalog values.
- **Sales invoices:** `tbl_sales_master` is the invoice/sale header; `tbl_sales_items` contains its item rows, joined by `sm_id`.
- **Sales orders:** `tbl_sales_master_order` is the order header; `tbl_sales_items_order` contains its item rows, joined by `smo_id`. The order lines include item, unit, quantity/dimension, price, discount, tax, and net-amount fields. The view page also joins the header to customer, branch, and user records.
- **Purchases:** `tbl_purchase_master` and `tbl_purchase_items` are joined by `pm_id`; vendor and branch IDs are stored on the header.
- **Returns:** sales and purchase returns each have separate master and item tables. Check the original document ID and status rules in the relevant workflow before changing return data.
- **Stock movement:** `tbl_stock_transactions` records quantity movement and references an item/branch stock ID; stock transfers use a header plus item rows. Batch and reservation tables represent additional inventory state.
- **Financial movements:** `tbl_transactions` stores payment/accounting movement fields (cash, wallet, card, cheque, debit/credit and balance); income/expense entries are stored separately.

The ID relationships above are application conventions, not enforced foreign keys. Confirm the exact join and deletion/update behavior in the calling workflow before modifying records.

## Sales-order details

The sales-order view is implemented in [`web/web_sales/view_sales_order.aspx.cs`](web/web_sales/view_sales_order.aspx.cs) and [`web/web_sales/view_sales_order.aspx`](web/web_sales/view_sales_order.aspx). It loads a single header from `tbl_sales_master_order`, loads lines from `tbl_sales_items_order`, and restricts visibility to branches in `tbl_user_branches`. Sales staff (user type `2`) are further restricted to their own orders and cannot change order status on this page.

The page maps `smo_delivery_status` as follows:

| Value | Meaning |
|---:|---|
| 0 | New |
| 1 | Processed |
| 2 | Fully Delivered |
| 3 | Partially Delivered |
| 4 | To be Confirmed |
| 5 | Customer Cancelled |
| 6 | Company Cancelled |

The page allows approval from status 0 or 4, cancellation from 0, 1, or 4, and reopening from 5 or 6. Status updates include the previous status and the user's branch membership in the `UPDATE` predicate to avoid applying a stale or out-of-scope transition. These codes and transitions are application behavior; verify all other clients and workflows before changing them.

The live database contains `sp_save_sales_order_json`. The local [`sales-order-procedure.inspected.sql`](sales-order-procedure.inspected.sql) file documents an inspected definition for it, but it is not a complete schema baseline or migration history. Compare it with the live routine before relying on it or deploying it.

### Sales-order invoices

The **Invoices** tab of the order view lists the invoices created for the order, and **Create Invoice** opens [`web/web_sales/sales_order_invoice.aspx`](web/web_sales/sales_order_invoice.aspx) (`?smoId=`). The invoicing rules are implemented in [`web/App_Code/SalesOrderInvoice.cs`](web/App_Code/SalesOrderInvoice.cs) (a partial of `SalesOrderStock`).

- An invoice is an ordinary `tbl_sales_master` / `tbl_sales_items` bill saved by the same code as `neworder.aspx` (`web_sales_neworder.SaveInvoice`, which both pages call). It is linked with `tbl_sales_master.sm_refid = smo_id`, `sm_is_inter_stock_transfer_invoice = 0` and `tbl_sales_items.sio_id` = the order line. Only rows with both header values count as invoices of the order; normal bills (`sm_refid` NULL) and inter-stock-transfer invoices never do.
- Quantities are in the order line's UOM, the unit of `si_qty`: remaining = `sio_finalqty` - `SUM(si_qty)` of the linked invoices, recalculated from the database on every load and save. `si_qty` is an `int`, so invoice quantities are whole numbers.
- Orders in status Approved or Processed can be invoiced. Saving locks the order row, creates the invoice and then consumes the line's own reservations (oldest batch first, same item only): `tbl_item_batch.itbh_currentqty` and `tbl_itembranch_stock.itbs_stock` are reduced by the invoiced quantity converted to the batch UOM, reservation rows are reduced or deleted, and a batch-level `tbl_stock_transactions` row is written. Product lines can only be invoiced up to their reserved quantity. Everything runs in one transaction; the shared saver's `sm_sales_sessionid` check rejects a repeated submission.
- Cancelling or rejecting an invoice through `manageorders.aspx` still restores only `itbs_stock`; batch quantities and reservations are not restored.


## Stored procedures

The configured database currently exposes these procedures:

- `sp_save_production_entry`
- `sp_save_purchase_entry`
- `sp_save_purchase_entry1.0`
- `sp_save_purchase_json`
- `sp_save_sales_order_json`

Stored procedures can own business rules and transaction boundaries. Inspect their live definitions and callers before changing table writes or reproducing their behavior in application code.

## Working safely with the database

1. Confirm the target database and server version before investigating or making changes.
2. Start with `INFORMATION_SCHEMA` and read-only `SELECT` queries. Avoid selecting personal, customer, or financial record data unless the task specifically requires it.
3. Use parameterized commands. The MySQL helper provides parameter overloads; avoid concatenating user input into SQL.
4. Prefer the existing application workflow or the owning stored procedure for writes. Preserve its transaction, validation, status, tax, and stock rules.
5. Because the database has no declared foreign keys, verify related rows and the effects on stock, transactions, returns, and reports before deleting or changing IDs.
6. There is no complete schema dump or migration history in the repository. Treat live metadata as environment-specific; capture and review explicit schema changes before deployment, and do not assume the inspected sales-order procedure is a full database backup.
7. The MySQL helper catches provider errors and can return `null`, an empty result, or `false`. Check these results at call sites and consult application logs rather than interpreting an empty result as proof that no matching data exists.
