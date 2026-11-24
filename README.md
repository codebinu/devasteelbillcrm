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

The page maps `smo_delivery_status` as follows (single definition: [`web/App_Code/SalesOrderStatus.cs`](web/App_Code/SalesOrderStatus.cs)):

| Value | Meaning |
|---:|---|
| 0 | Draft (saved with **Save as Draft**, not yet approved) |
| 1 | New, shown as "To be confirmed" (saved with **Save Order**, not yet approved) |
| 2 | Approved |
| 3 | Processed (a valid reservation exists) |
| 9 | Partially Delivered |
| 10 | Fully Delivered |
| 11 | Cancelled by Company |
| 12 | Cancelled by Customer |
| 13 | On Hold |

**Save as Draft** on `new_sales_order.aspx` stores status 0 and **Save Order** stores status 1 (orders created by the app sync are also saved as New); both are unapproved and behave identically, and approving is a separate action on the view page. Orders created before this model use the old values (0 New, 1 Approved, 2 Fully Delivered, 3 Partially Delivered, 4 Pending, 5 Customer Cancelled, 6 Company Cancelled, 7 Processed); run [`sales-order-status-migration.sql`](sales-order-status-migration.sql) once, with the application stopped, to convert them, then [`sales-order-status-new-onhold-migration.sql`](sales-order-status-new-onhold-migration.sql) once to move On Hold from 1 to 13 (1 now means New).

Two separate mechanisms change the status ([`SalesOrderStatus.cs`](web/App_Code/SalesOrderStatus.cs) holds the rules, [`SalesOrderStatusStore.cs`](web/App_Code/SalesOrderStatusStore.cs) the stored-data operations):

- **Manual actions** (`ChangeSalesOrderStatus`): Approve (from Draft, New or On Hold), Put On Hold (from Draft, New, Approved, Processed or Partially Delivered, never from Fully Delivered) and Cancel by customer / company (from every non-cancelled status). A cancelled order accepts no further change. The transition, the branch scope and the user's permission (salesmen, user type 2, cannot change statuses) are validated on the server against the locked order row, and the update is guarded by the status that was read. Cancelling releases the order's reservations and does not touch its invoices. Approving an On Hold order resumes it and recalculates the operational status.
- **Automatic calculation** (`UpdateSalesOrderStatus`): the single place that derives Approved / Processed / Partially Delivered / Fully Delivered. It recalculates from the current records every time, in this priority: cancelled and On Hold keep their status, Draft and New are never approved automatically, then Fully Delivered (every ordered quantity is invoiced and every invoiced quantity is delivered, judged per order line), Partially Delivered (a valid invoice has `sm_delivery_status = 2`), Processed (a reservation row with a quantity exists), Approved. Valid invoices are the order's invoices (`sm_refid = smo_id`, not inter-stock transfers) that are not cancelled (`sm_delivery_status = 4`) or rejected (5). The status moves backward as well as forward. It runs after reservation create / release / production, invoice creation, invoice cancel / delivery / reversal / edit (web and the `app_*` endpoints), inter-stock transfers, order edits, resuming an On Hold order, and when the order is opened. A delivered order with no linked invoice at all (delivered before invoices were linked to orders) is left unchanged.

A partially delivered order stays open for reservations, production, transfers and invoicing, so its remaining quantity can be delivered. The recalculation is not part of the main operation's success: inside a transaction a failed recalculation is logged and corrected by the next recalculation.

The page allows editing in Draft, New, On Hold, Approved and Processed (when no invoice exists). Status updates include the previous status and the user's branch membership in the `UPDATE` predicate to avoid applying a stale or out-of-scope transition. These codes and transitions are application behavior; verify all other clients and workflows before changing them. `app_Retailer.aspx.cs` still lists `tbl_sales_master_order` rows with the stored values for its legacy quote flow, so its client sees the new numbers after the migration.

The live database contains `sp_save_sales_order_json`. The local [`sales-order-procedure.inspected.sql`](sales-order-procedure.inspected.sql) file documents an inspected definition for it, but it is not a complete schema baseline or migration history. Compare it with the live routine before relying on it or deploying it.

### Bulk Production

[`web/web_production/bulk_production.aspx`](web/web_production/bulk_production.aspx) (server side: `ProductionPageService.SearchBulkGroups` / `ProduceLine`) produces the same item for several sales orders in one run. It follows the sales order status rules above rather than having its own:

- Only Approved, Processed and Partially Delivered orders are listed (`SalesOrderStatus.CanReserve`, the same rule as reserving stock and the production entry). Draft, To be confirmed, On Hold, cancelled and Fully Delivered orders are not, and a note counts the Draft / To be confirmed / On Hold orders that were held back. The order status is shown with the shared label and colour (`SalesOrderStatus.Name` / `Css`), the order number links to `view_sales_order.aspx`, and the filters (product, order, customer, warehouse, order status, order dates) work like the sales order list.
- The list is rebuilt from the database on every load. The Production Queue board cache is also dropped when any order on it has a different status than the one it was built with.
- A line is selectable only when the production entry itself would accept it (`EntryIssue`, plus exactly one usable reservation that yields the pending quantity, `SalesOrderStock.BulkIssue`). One production entry is saved per sales order, so only the first producible line of an order is offered; the reason is shown on the others.
- Each order is re-validated when produced (status read under the order row lock, `ProductionService.CheckOwnership`). Hold and cancel are refused while a production entry of that order is being saved, because the stored procedure commits on its own connection. After producing, the order status is recalculated (`UpdateSalesOrderStatus`, for example Approved becomes Processed) and shown in the run log.

### Batch-based raw-material consumption

A BOM raw material received by length or area (its batch UOM is a Length or Area unit, e.g. a coil) is consumed from the actual reserved batch; all other raw materials keep their fixed BOM quantity. No setting or migration is needed. Producing from **Reserved Items** calculates the raw material for each reserved batch from its own weight and length in `tbl_item_batch` (`itbh_kg / (itbh_length x itbh_no_piece)`) and the finished item's `Spec Width`, shows it per batch before the production is confirmed, and deducts exactly that from each batch. The engine is [`BomConsumption.cs`](web/App_Code/BomConsumption.cs); formulas, the validation of the reference workbook and the assumptions are in [`production_workflow_reference.md`](production_workflow_reference.md) section 12a.

### Sales-order overview row

A one-row overview sits between the order header and the tabs of `view_sales_order.aspx`. It is requested by one `LoadOverview` page method after the page has finished loading (skeleton placeholders until then) and again only after a reserve / release / produce / undo action; switching tabs does not refetch. The figures come from [`web/App_Code/SalesOrderOverview.cs`](web/App_Code/SalesOrderOverview.cs) with aggregate queries only:

- **Delivery completion** = delivered quantity / ordered quantity, per order line and capped at the ordered quantity, so it never exceeds 100% and is rounded down to one decimal. Delivered quantity is the quantity on delivered (`sm_delivery_status = 2`) invoices that are not cancelled or rejected, so cancelled invoices and reversed deliveries no longer count; each invoice line is counted once. Lines with no quantity are ignored.
- **Overall completion** is a separate, weighted measure of how far every ordered unit has progressed, not an average of counts and not derived from the status number. Each line moves through up to four stages with these weights: Reservation 20, Production 20, Invoicing 25, Delivery 35. Per line and stage the progress is the quantity done / ordered quantity (capped at 1); a line's progress is the weighted sum divided by the weights of the stages that apply to it, and the order's value is the lines' progress weighted by their ordered quantity. A unit counts once in each stage with that stage's share of the weight, so quantities are not counted twice. Stages that do not apply are left out and the remaining weights scale up, so they never lower the result:
  - *Reservation* (stock items only): reserved now + invoiced. Invoicing consumes the reservation, so an invoiced unit was reserved; cancelled invoices and released reservations stop counting.
  - *Production* (stock items with an active BOM only): produced / (produced + shortfall), where the shortfall is what no reservation, invoice or production covers. A BOM item served entirely from stock, with nothing produced, has no production stage.
  - *Invoicing*: quantity on valid (not cancelled or rejected) invoices.
  - *Delivery*: quantity on valid delivered invoices.
  Service lines have no reservation or production stage. Example: an order fully invoiced with 60% of it delivered shows Overall 82.5% and Delivery 60%.
- **Reservation completion** = active reserved quantity of the lines' own item (converted to the line UOM) / ordered quantity of the stock lines, each line capped at its ordered quantity. The bar and percentage stop at 100%; the real (uncapped) reserved quantity is still returned and shown in the tooltip.- **Invoices**: valid invoices of the order (`sm_refid = smo_id`, not inter-stock transfers); delivered versus pending.
- **Production**: the order's production jobs, as in the Production Details tab. A job is completed once its stock movements were applied (`tbl_stock_transactions`, action type 12) and pending while they are not.
- **Transfers**: inter-stock transfer invoices of the order; completed = its purchase exists and is not cancelled, pending = the purchase is still to be created (cancelled purchases are shown in the tooltip).

Each figure links to the corresponding tab.

### Sales-order invoices

The **Invoices** tab of the order view lists the invoices created for the order, and **Create Invoice** opens [`web/web_sales/sales_order_invoice.aspx`](web/web_sales/sales_order_invoice.aspx) (`?smoId=`). The invoicing rules are implemented in [`web/App_Code/SalesOrderInvoice.cs`](web/App_Code/SalesOrderInvoice.cs) (a partial of `SalesOrderStock`).

- An invoice is an ordinary `tbl_sales_master` / `tbl_sales_items` bill saved by the same code as `neworder.aspx` (`web_sales_neworder.SaveInvoice`, which both pages call). It is linked with `tbl_sales_master.sm_refid = smo_id`, `sm_is_inter_stock_transfer_invoice = 0` and `tbl_sales_items.sio_id` = the order line. Only rows with both header values count as invoices of the order; normal bills (`sm_refid` NULL) and inter-stock-transfer invoices never do. Each product row also carries the batch it was taken from (`tbl_sales_items.itbh_id` and `itm_batchno`, both set to `tbl_item_batch.itbh_id`); an order line reserved across several batches is invoiced as one row per batch (for example 10 = 4 from batch A + 6 from batch B gives two rows with the same `sio_id`).
- Quantities are in the order line's UOM, the unit of `si_qty`: remaining = `sio_finalqty` - `SUM(si_qty)` of the linked invoices, recalculated from the database on every load and save. `si_qty` must be `decimal(18,3)` ([`sales-order-invoice-decimal-qty.sql`](sales-order-invoice-decimal-qty.sql), run once before deploying), so invoice quantities may have up to 3 decimal places.
- Orders in status Approved, Processed or Partially Delivered can be invoiced. Cancelled (`sm_delivery_status` 4) and rejected (5) invoices no longer count as invoiced, so their quantity can be invoiced again. Saving locks the order row, creates the invoice and then consumes the line's own reservations (oldest batch first, same item only): `tbl_item_batch.itbh_currentqty` and `tbl_itembranch_stock.itbs_stock` are reduced by the invoiced quantity converted to the batch UOM, reservation rows are reduced or deleted, and a batch-level `tbl_stock_transactions` row is written. Product lines can only be invoiced up to their reserved quantity. Everything runs in one transaction, which also recalculates the order status before it commits; the shared saver's `sm_sales_sessionid` check rejects a repeated submission.
- Cancelling or rejecting an invoice (`manageorders.aspx`, `editorder.aspx`) credits the invoice's batches back (`web\App_Code\InvoiceBatchStock.cs`): for every batch in its `tbl_stock_transactions` rows the net quantity (batch UOM) is added to `tbl_item_batch.itbh_currentqty` and `tbl_itembranch_stock.itbs_stock`, with a `cr_qty` ledger row per batch. Reservations are not recreated, so the quantity becomes free stock again and can be reserved and invoiced again. Making a rejected invoice active again debits the same batches (and is refused if a batch no longer holds the quantity). A cancelled invoice cannot be changed any more. Invoices that have no batch ledger rows (older or non-order invoices) keep the previous item-level `itbs_stock` credit only.
- Items and quantities of an invoice created from a sales order cannot be edited in `editorder.aspx` (cancel it and invoice again); prices, discounts and the note can, and the order line (`sio_id`) and batch (`itbh_id`, `itm_batchno`) of every row are kept.

### Inter-warehouse stock transfer

The **Interstock Transfer Invoices** tab of the order view (right after **Invoices**) lists the transfers of the order and its **Create New Transfer** button opens [`web/web_sales/sales_order_interstock_transfer.aspx`](web/web_sales/sales_order_interstock_transfer.aspx) (`?smoId=`); the logic is in [`web/App_Code/SalesOrderInterStock.cs`](web/App_Code/SalesOrderInterStock.cs) (a partial of `SalesOrderStock`). It moves stock reserved for the order in a source warehouse to another warehouse.

- Listing: one row per invoice with `sm_refid = smo_id` and `sm_is_inter_stock_transfer_invoice = 1` (the only rows that qualify; ordinary invoices have the flag 0), joined to its purchase by a scalar subquery so no invoice is listed twice. The purchase status is *created* (purchase exists), *pending* (no purchase yet, **Retry Purchase** is offered) or *cancelled* (`pm_status = 0`). A failed purchase attempt is not stored, so it shows as pending. **Details** loads both documents' lines (batch, quantity, CGST/SGST/IGST) and links to the existing `manageorders.aspx` and `managepurchase.aspx` views. After a save the transfer page returns to this tab.

- Flow: source warehouse (one of the user's `tbl_user_branches` that has both `tbl_branch.cust_id` and `tbl_branch.vn_id`) -> target customer (the `cust_id` of every other warehouse that is linked to exactly one warehouse) -> reserved batches of the order in the source warehouse -> whole-number transfer quantities per batch. The target customer's state must equal its warehouse's state, because the invoice procedure decides CGST/SGST or IGST by comparing the customer's state with the source warehouse's state.
- `sp_save_sales_entry1.1` saves the invoice with `branch_id` = source warehouse, `cust_id` = the target customer, `sm_is_inter_stock_transfer_invoice = 1` and per row `itbs_id` / `itbh_id` / `sio_id` of the source warehouse. It reduces `itbs_stock`, the batch and the order line's reservation, but does not check that the reservation covers the quantity, so the page limits each row to `MIN(reservation row, batch quantity, itbs_stock)`. The page then sets `sm_refid = smo_id`; transfer invoices are not counted as invoices of the order (`sm_is_inter_stock_transfer_invoice = 1`).
- `sp_create_purchase_from_sales1.0` creates the purchase in the target warehouse (the single `tbl_branch` with `cust_id` = the invoice customer) against the source warehouse's `vn_id`, with `pm_ref_no` = the invoice id and the same `sio_id`, so the received batch is reserved for the same order line. The page then sets `tbl_purchase_master.sm_id` and `pm_is_inter_stock_transfer_invoice = 1`.
- Both procedures commit internally, so the invoice and the purchase cannot share a transaction. The invoice is saved first; if the purchase fails, the invoice stays, the page reports an incomplete transfer, and **Retry Purchase** calls the purchase procedure again. A purchase already linked to the invoice (by `sm_id`, or by `pm_ref_no`, vendor and warehouse) is never created twice. A named MySQL lock per order serialises concurrent transfers.


## Track Batch

The **Track Batch** menu item (above **Purchase**) opens [`web/web_inventory/track_batch.aspx`](web/web_inventory/track_batch.aspx), a read-only list of `tbl_item_batch`, and [`track_batch_details.aspx`](web/web_inventory/track_batch_details.aspx) (`?batchId=`), the batch's origin, reservations, invoices, inter-stock transfers, production use and timeline. All queries are in [`web/App_Code/BatchTrace.cs`](web/App_Code/BatchTrace.cs); nothing writes to the database. Access follows the **Purchase Lists** permission (`tbl_page_links` page 4), the page methods re-check it, and batches are limited to the user's `tbl_user_branches`. [`track-batch-indexes.sql`](track-batch-indexes.sql) holds optional indexes.

How a batch is linked (verified against the live schema and the workflows above):

- **Origin:** a purchase line (`tbl_purchase_items.itbh_id`) or a production output row (`tbl_item_pro_items.itbh_id`, `itpi_inputoutput = 2`). `itbh_created_doc_type` is `2` for both and `itbh_created_doc_id` is the `pi_id` for a purchase but the `itpm_id` for production, so neither is used to tell them apart; a batch with no or ambiguous references shows "Origin Not Identified". A production batch is tied to its sales order the way production history does it (`itbh_custbatchid = PRO-<itpm_id>-<sio_id>`).
- **Customer vs system batch:** `itbh_custbatchid` is a customer batch unless it is empty or the `PUR-<id>-<row>` / `PRO-<id>-<line>` default stored by the purchase / production procedures.
- **Reservations:** `tbl_item_batchstock_reserve` rows (`itbsr_qty` in the batch UOM) through `sio_id`. A reservation is deleted when consumed or released and no history is kept, so only active reservations are listed; consumption is taken from invoices, transfers and production.
- **Invoices:** `tbl_stock_transactions` rows with `action_type = 1`, `itbh_id` and `action_ref_id = sm_id` (batch UOM), plus invoices whose `tbl_sales_items.itbh_id` points at the batch (legacy and inter-stock invoices; their quantity is in the invoice line UOM and is only added to a total when it equals the batch UOM). Cancelled (4) and rejected (5) invoices are listed but not counted in Total invoiced; their stock is credited back to the batch by a `cr_qty` ledger row.
- **Inter-stock transfers:** an invoice with `sm_is_inter_stock_transfer_invoice = 1` (out) and the purchase with `pm_is_inter_stock_transfer_invoice = 1` that receives it (in, `sm_id` / `pm_ref_no` = invoice id). The receiving purchase creates its own batch, so a transfer links two different batches.
- **Production use:** `tbl_item_pro_items` rows with `itpi_inputoutput = 1`.
- **Current quantity:** `itbh_currentqty`, as everywhere else in the application (reservations do not reduce it; free stock is current minus reserved). It is never rebuilt from the other quantities.
- **Other transactions:** `tbl_stock_transactions` rows for the batch that none of the records above explain.

## Stock View

The **Stock View** menu item (above **Track Batch**) opens [`web/web_inventory/stock_view.aspx`](web/web_inventory/stock_view.aspx), an item-level (not batch-level) stock overview per warehouse or for all warehouses, with item details in [`stock_view_details.aspx`](web/web_inventory/stock_view_details.aspx) (`?itemId=&wh=`) and an Excel export of everything that matches the filters ([`stock_view_export.aspx`](web/web_inventory/stock_view_export.aspx)). All queries are in [`web/App_Code/StockView.cs`](web/App_Code/StockView.cs); nothing writes to the database. Access follows the **Stock Management** permission (`tbl_page_links` page 13), the page methods re-check it, and warehouses are limited to the user's `tbl_user_branches`. [`stock-view-indexes.sql`](stock-view-indexes.sql) holds optional indexes.

Quantities are shown in the item's sales UOM and follow the existing workflows (verified against the live schema):

- **Physical stock:** `tbl_itembranch_stock.itbs_stock` per warehouse (`tbl_branch`). Batches cover only part of it (opening / legacy stock has no batch), so `tbl_item_batch` is not used. The invoice flow deducts it when the invoice is created, so invoiced quantity is already out.
- **Reserved:** `SUM(tbl_item_batchstock_reserve.itbsr_qty)`, in the warehouse of the reserved batch's stock row. Reservations are deleted when consumed or released, so every row is an active hold; consumed / released quantities are not recorded (the details page shows the invoiced quantity of the order line as "consumed"). **Free = Physical - Reserved.**
- **Pending reservation:** per line of an **Approved, Processed or Partially Delivered** order (the statuses that may reserve), `max(0, ordered - invoiced) - reserved by the line on the item`, with the rounding rule of `SalesOrderStock.Compute`. Invoices count unless cancelled / rejected or inter-stock transfers. It belongs to the warehouse of the order; reservations in other warehouses still count against the line, so nothing is counted twice across warehouses. **Projected = Free - Pending** (for all warehouses, from the consolidated totals, never by adding warehouse shortages).
- **Status:** Negative, Shortage (projected < 0), Zero, Pending Demand, Reserved, otherwise Healthy.
- **Item type** (no raw / finished flag exists): Finished Goods when the item has a BOM, Raw Material when it is a BOM component, otherwise Other. **Category** is the item's stock group and **Brand** its spec brand (`tbl_item_master_spe_values`); there is no barcode column.
- Orders still on the pre-migration status values (see `sales-order-status-migration.sql`) are not counted as active.

## Stored procedures

The configured database currently exposes these procedures:

- `sp_create_purchase_from_sales1.0`
- `sp_save_production_entry`
- `sp_save_production_entry1.1`
- `sp_save_purchase_entry`
- `sp_save_purchase_entry1.1`
- `sp_save_purchase_json`
- `sp_save_sales_entry1.0`
- `sp_save_sales_entry1.1`
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
