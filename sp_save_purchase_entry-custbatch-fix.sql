-- Fixes sp_save_purchase_entry not saving a changed Supplier Batch No. (itbh_custbatchid) when an existing purchase is edited.
--
-- Only change from the live definition: the edit branch's UPDATE tbl_item_batch now also sets itbh_custbatchid
-- (the insert branch already did). If the key is sent, a blank value falls back to the same 'PUR-<pm_id>-<row_no>'
-- default as the insert branch; if the key is not sent, the stored value is kept.
--
-- The parameter header below matches the live signature (checked in information_schema.PARAMETERS: JSON params are
-- stored as longtext on MariaDB, p_current_datetime is DATETIME). Keep the live DEFINER / characteristics if you use them.
-- Run once against the application database (MariaDB 11.x: CREATE OR REPLACE is atomic).
-- If your SQL client does not support DELIMITER, run only the CREATE ... END block as a single statement.

DELIMITER $$

CREATE OR REPLACE PROCEDURE `sp_save_purchase_entry1.1`(
    IN p_filters JSON,
    IN p_items JSON,
    IN p_current_datetime DATETIME,
    OUT p_pm_id INT,
    OUT p_result JSON
)
BEGIN
    DECLARE v_sqlstate CHAR(5);
    DECLARE v_errno INT;
    DECLARE v_message TEXT;
    DECLARE v_item_index INT DEFAULT 0;
    DECLARE v_item_count INT DEFAULT 0;
    DECLARE v_item_json JSON;
    DECLARE v_invoice_no VARCHAR(11);
    DECLARE v_input_pm_id INT;
    DECLARE v_existing_pm_id INT;
    DECLARE v_pm_ref_no INT;
    DECLARE v_master_action VARCHAR(10);
    DECLARE v_is_edit BOOLEAN DEFAULT FALSE;
    DECLARE v_old_vendor_id INT;
    DECLARE v_vendor_id INT;
    DECLARE v_user_id INT;
    DECLARE v_purchase_date DATETIME;
    DECLARE v_note VARCHAR(500);
    DECLARE v_branch_id INT;
    DECLARE v_branch_tax_method INT;
    DECLARE v_branch_tax_inclusive INT;
    DECLARE v_paid_amount DECIMAL(15, 4) DEFAULT 0.0000;
    DECLARE v_cash_amount DECIMAL(15, 4) DEFAULT 0.0000;
    DECLARE v_cheque_amount DECIMAL(15, 4) DEFAULT 0.0000;
    DECLARE v_cheque_no VARCHAR(20);
    DECLARE v_cheque_date DATETIME;
    DECLARE v_cheque_bank VARCHAR(45);
    DECLARE v_pm_status INT;
    DECLARE v_pm_cancelled_date DATETIME;
    DECLARE v_pm_sessionid DECIMAL(18, 0);
    DECLARE v_itbh_id INT;
    DECLARE v_existing_itbh_id INT;
    DECLARE v_old_pi_id INT;
    DECLARE v_old_pi_max INT DEFAULT 0;
    DECLARE v_itm_id INT;
    DECLARE v_sio_id INT;
    DECLARE v_itbm_prefix VARCHAR(30);
    DECLARE v_itbm_suffix VARCHAR(30);
    DECLARE v_itbm_serl INT;
    DECLARE v_batch_serial_no INT;
    DECLARE v_itbs_id INT;
    DECLARE v_row_no INT;
    DECLARE v_item_code VARCHAR(25);
    DECLARE v_item_name VARCHAR(150);
    DECLARE v_item_qty DECIMAL(10, 6);
    DECLARE v_item_price DECIMAL(18, 6);
    DECLARE v_item_tax_rate DECIMAL(5, 2);
    DECLARE v_item_cess_rate DECIMAL(5, 2);
    DECLARE v_item_discount_rate DECIMAL(5, 2);
    DECLARE v_calculated_price DECIMAL(18, 6);
    DECLARE v_item_total DECIMAL(18, 6);
    DECLARE v_line_discount_amount DECIMAL(18, 6);
    DECLARE v_line_tax_amount DECIMAL(18, 6);
    DECLARE v_line_tax_excluded DECIMAL(18, 6);
    DECLARE v_item_net_amount DECIMAL(18, 6);
    DECLARE v_line_cgst DECIMAL(5, 2);
    DECLARE v_line_sgst DECIMAL(5, 2);
    DECLARE v_line_igst DECIMAL(5, 2);
    DECLARE v_line_utgst DECIMAL(5, 2);
    DECLARE v_stock_qty DECIMAL(10, 6);
    DECLARE v_closing_stock DECIMAL(18, 6);
    DECLARE v_purchase_status INT;
    DECLARE v_sum_total DECIMAL(18, 6) DEFAULT 0.000000;
    DECLARE v_sum_discount DECIMAL(18, 6) DEFAULT 0.000000;
    DECLARE v_sum_tax_excluded DECIMAL(18, 6) DEFAULT 0.000000;
    DECLARE v_sum_tax DECIMAL(18, 6) DEFAULT 0.000000;
    DECLARE v_sum_net DECIMAL(18, 6) DEFAULT 0.000000;
    DECLARE v_pm_total DECIMAL(11, 2);
    DECLARE v_pm_discount_rate DECIMAL(5, 2);
    DECLARE v_pm_discount_amount DECIMAL(11, 2);
    DECLARE v_pm_tax_excluded_amt DECIMAL(11, 2);
    DECLARE v_pm_tax_amount DECIMAL(11, 2);
    DECLARE v_pm_netamount DECIMAL(11, 2);
    DECLARE v_pm_roundoff DECIMAL(10, 2);
    DECLARE v_pi_id INT;
    DECLARE v_found_vendor_id INT;
    DECLARE v_found_branch_id INT;
    DECLARE v_vendor_state VARCHAR(50);
    DECLARE v_branch_state INT;
    DECLARE v_branch_state_name VARCHAR(50);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            v_sqlstate = RETURNED_SQLSTATE,
            v_errno = MYSQL_ERRNO,
            v_message = MESSAGE_TEXT;
        DROP TEMPORARY TABLE IF EXISTS tmp_sp_save_purchase_edit_items;
        SET p_pm_id = NULL;
        SET p_result = JSON_OBJECT(
            'success', FALSE,
            'error_code', COALESCE(v_errno, 50000),
            'sql_state', COALESCE(v_sqlstate, '45000'),
            'message', COALESCE(v_message, 'Purchase entry could not be saved'),
            'pm_id', NULL
        );
    END;

    SET p_pm_id = NULL;
    SET p_result = NULL;

    IF p_filters IS NULL
       OR BINARY JSON_TYPE(p_filters) <> BINARY 'OBJECT'
       OR p_items IS NULL
       OR BINARY JSON_TYPE(p_items) <> BINARY 'ARRAY' THEN
        SIGNAL SQLSTATE '45000'
            SET MYSQL_ERRNO = 30001,
                MESSAGE_TEXT = 'Purchase filters must be an object and items must be an array';
    END IF;

    SET v_invoice_no = JSON_VALUE(p_filters, '$.invoiceno');
    SET v_input_pm_id = JSON_VALUE(p_filters, '$.pm_id');
    SET v_pm_ref_no = JSON_VALUE(p_filters, '$.pm_ref_no');
    SET v_vendor_id = JSON_VALUE(p_filters, '$.vendorId');
    SET v_user_id = JSON_VALUE(p_filters, '$.userid');
    SET v_purchase_date = JSON_VALUE(p_filters, '$.purchasedate');
    SET v_note = JSON_VALUE(p_filters, '$.note');
    SET v_branch_id = JSON_VALUE(p_filters, '$.warehouse');
    SET v_branch_tax_method = JSON_VALUE(p_filters, '$.branch_tax_method');
    SET v_branch_tax_inclusive = JSON_VALUE(p_filters, '$.branch_tax_inclusive');
    IF JSON_TYPE(JSON_EXTRACT(p_filters, '$.payment')) IS NOT NULL
       AND BINARY JSON_TYPE(JSON_EXTRACT(p_filters, '$.payment'))
           <> BINARY 'OBJECT' THEN
        SIGNAL SQLSTATE '45000'
            SET MYSQL_ERRNO = 30011,
                MESSAGE_TEXT = 'Purchase payment must be an object';
    END IF;

    SET v_paid_amount = COALESCE(
        JSON_VALUE(p_filters, '$.PaidAmount'),
        JSON_VALUE(p_filters, '$.payment.paid_amount'), 0.0000);
    SET v_cash_amount = COALESCE(
        JSON_VALUE(p_filters, '$.CashAmount'),
        JSON_VALUE(p_filters, '$.payment.cash_amount'), 0.0000);
    SET v_cheque_amount = COALESCE(
        JSON_VALUE(p_filters, '$.ChequeAmount'),
        JSON_VALUE(p_filters, '$.payment.cheque_amount'), 0.0000);
    SET v_cheque_no = COALESCE(
        JSON_VALUE(p_filters, '$.ChequeNo'),
        JSON_VALUE(p_filters, '$.payment.cheque_no'));
    SET v_cheque_date = COALESCE(
        JSON_VALUE(p_filters, '$.ChequeDate'),
        JSON_VALUE(p_filters, '$.payment.cheque_date'));
    SET v_cheque_bank = COALESCE(
        JSON_VALUE(p_filters, '$.BankName'),
        JSON_VALUE(p_filters, '$.payment.cheque_bank'));
    SET v_pm_status = COALESCE(JSON_VALUE(p_filters, '$.pm_status'), 1);
    SET v_pm_cancelled_date = JSON_VALUE(p_filters, '$.pm_cancelled_date');
    SET v_pm_sessionid = JSON_VALUE(p_filters, '$.pm_sessionid');
    SET v_item_count = JSON_LENGTH(p_items);

    IF v_invoice_no IS NULL
       OR v_vendor_id IS NULL
       OR v_user_id IS NULL
       OR v_purchase_date IS NULL
       OR v_branch_id IS NULL
       OR v_branch_tax_method IS NULL
       OR v_branch_tax_inclusive IS NULL
       OR p_current_datetime IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MYSQL_ERRNO = 30002,
                MESSAGE_TEXT = 'Required purchase fields and localized current datetime must be supplied';
    END IF;

    IF v_branch_tax_method NOT IN (0, 1, 2)
       OR v_branch_tax_inclusive NOT IN (0, 1) THEN
        SIGNAL SQLSTATE '45000'
            SET MYSQL_ERRNO = 30003,
                MESSAGE_TEXT = 'Unsupported branch tax configuration';
    END IF;

    IF v_item_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MYSQL_ERRNO = 30004,
                MESSAGE_TEXT = 'Purchase must contain at least one item';
    END IF;

    START TRANSACTION;

    SELECT vn_id, COALESCE(vn_state, '')
    INTO v_found_vendor_id, v_vendor_state
    FROM tbl_vendor
    WHERE vn_id = v_vendor_id
    FOR UPDATE;

    IF v_found_vendor_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MYSQL_ERRNO = 30013,
                MESSAGE_TEXT = 'Vendor does not exist';
    END IF;

    SELECT branch_id, branch_state_id
    INTO v_found_branch_id, v_branch_state
    FROM tbl_branch
    WHERE branch_id = v_branch_id
    FOR UPDATE;

    IF v_found_branch_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MYSQL_ERRNO = 30014,
                MESSAGE_TEXT = 'Branch does not exist';
    END IF;

    SET v_branch_state_name = (
        SELECT state_name
        FROM tbl_state
        WHERE state_id = v_branch_state
        LIMIT 1
    );

    IF v_pm_sessionid IS NOT NULL AND EXISTS (
        SELECT 1
        FROM tbl_purchase_master
        WHERE pm_id <> COALESCE(v_input_pm_id, 0)
          AND pm_sessionid = v_pm_sessionid
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MYSQL_ERRNO = 30008,
                MESSAGE_TEXT = 'Session id exists';
    END IF;
/*
    IF EXISTS (
        SELECT 1
        FROM tbl_purchase_master
        WHERE CONVERT(pm_invoice_no USING utf8mb4) COLLATE utf8mb4_general_ci
                  = CONVERT(v_invoice_no USING utf8mb4) COLLATE utf8mb4_general_ci
          AND pm_id <> COALESCE(v_input_pm_id, 0)
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MYSQL_ERRNO = 30005,
                MESSAGE_TEXT = 'Purchase invoice number already exists';
    END IF;
*/
    IF COALESCE(v_input_pm_id, 0) > 0 THEN
        SET v_existing_pm_id = NULL;
        SELECT pm_id, vn_id
        INTO v_existing_pm_id, v_old_vendor_id
        FROM tbl_purchase_master
        WHERE pm_id = v_input_pm_id
        FOR UPDATE;

        IF v_existing_pm_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MYSQL_ERRNO = 30012,
                    MESSAGE_TEXT = 'Purchase id does not exist';
        END IF;

        UPDATE tbl_purchase_master
        SET pm_ref_no = COALESCE(v_pm_ref_no, pm_ref_no),
            pm_invoice_no = v_invoice_no,
            vn_id = v_vendor_id,
            pm_userid = v_user_id,
            pm_date = v_purchase_date,
            pm_note = COALESCE(v_note, ''),
            branch_id = v_branch_id,
            pm_status = v_pm_status,
            pm_cancelled_date = v_pm_cancelled_date,
            branch_tax_method = v_branch_tax_method,
            branch_tax_inclusive = v_branch_tax_inclusive,
            pm_sessionid = v_pm_sessionid
        WHERE pm_id = v_input_pm_id;

        SET p_pm_id = v_input_pm_id;
        SET v_master_action = 'updated';
        SET v_is_edit = TRUE;
    ELSE
        INSERT INTO tbl_purchase_master (
            pm_ref_no,
            pm_invoice_no,
            vn_id,
            pm_userid,
            pm_date,
            pm_note,
            branch_id,
            pm_status,
            pm_cancelled_date,
            branch_tax_method,
            branch_tax_inclusive,
            pm_sessionid
        ) VALUES (
            COALESCE(v_pm_ref_no, 0),
            v_invoice_no,
            v_vendor_id,
            v_user_id,
            v_purchase_date,
            COALESCE(v_note, ''),
            v_branch_id,
            v_pm_status,
            v_pm_cancelled_date,
            v_branch_tax_method,
            v_branch_tax_inclusive,
            v_pm_sessionid
        );

        SET p_pm_id = LAST_INSERT_ID();
        SET v_master_action = 'inserted';
    END IF;

    IF v_is_edit THEN
        SELECT COALESCE(MAX(pi_id), 0)
        INTO v_old_pi_max
        FROM tbl_purchase_items
        WHERE pm_id = p_pm_id;

        DROP TEMPORARY TABLE IF EXISTS tmp_sp_save_purchase_edit_items;
        CREATE TEMPORARY TABLE tmp_sp_save_purchase_edit_items (
            pi_id INT NOT NULL PRIMARY KEY,
            row_no INT,
            itbs_id INT,
            itbh_id INT,
            pi_qty DECIMAL(10, 6),
            matched BOOLEAN NOT NULL DEFAULT FALSE
        ) ENGINE=MEMORY;

        INSERT INTO tmp_sp_save_purchase_edit_items (
            pi_id, row_no, itbs_id, itbh_id, pi_qty
        )
        SELECT pi_id, row_no, itbs_id, itbh_id, pi_qty
        FROM tbl_purchase_items
        WHERE pm_id = p_pm_id;

        UPDATE tbl_itembranch_stock AS stock
        INNER JOIN (
            SELECT itbs_id, SUM(cr_qty - dr_qty) AS net_qty
            FROM tbl_stock_transactions
            WHERE action_type = 2
              AND action_ref_id = p_pm_id
            GROUP BY itbs_id
        ) AS old_purchase
            ON old_purchase.itbs_id = stock.itbs_id
        SET stock.itbs_stock = COALESCE(stock.itbs_stock, 0) - old_purchase.net_qty;

        DELETE FROM tbl_stock_transactions
        WHERE action_type = 2
          AND action_ref_id = p_pm_id;

        DELETE FROM tbl_transactions
        WHERE action_type = 2
          AND action_ref_id = p_pm_id;

    END IF;

    WHILE v_item_index < v_item_count DO
        SET v_item_json = JSON_EXTRACT(p_items, CONCAT('$[', v_item_index, ']'));
        SET v_itbs_id = JSON_VALUE(v_item_json, '$.itbs_id');
        SET v_itm_id = JSON_VALUE(v_item_json, '$.itm_id');
        SET v_sio_id = JSON_VALUE(v_item_json, '$.sio_id');
        SET v_item_qty = JSON_VALUE(v_item_json, '$.pi_qty');
        SET v_item_price = JSON_VALUE(v_item_json, '$.pi_price');
        SET v_item_discount_rate = COALESCE(
            JSON_VALUE(v_item_json, '$.pi_discount_rate'), 0.00);
        SET v_item_tax_rate = COALESCE(
            JSON_VALUE(v_item_json, '$.pi_taxperc'),
            JSON_VALUE(v_item_json, '$.pi_item_tax'));
        SET v_item_cess_rate = JSON_VALUE(v_item_json, '$.pi_item_cess');
        SET v_item_code = JSON_VALUE(v_item_json, '$.itm_code');
        SET v_item_name = JSON_VALUE(v_item_json, '$.itm_name');
        SET v_line_cgst = 0.00;
        SET v_line_sgst = 0.00;
        SET v_line_igst = 0.00;
        SET v_line_utgst = 0.00;

        IF (v_itbs_id IS NULL AND v_itm_id IS NULL)
           OR v_item_qty IS NULL
           OR v_item_qty <= 0
           OR v_item_price IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MYSQL_ERRNO = 30006,
                    MESSAGE_TEXT = 'Each item requires itbs_id or itm_id, positive pi_qty, and pi_price';
        END IF;

        IF v_sio_id IS NOT NULL AND v_sio_id > 0
           AND NOT EXISTS (
               SELECT 1
               FROM tbl_sales_items_order
               WHERE sio_id = v_sio_id
                 AND itm_id = v_itm_id
           ) THEN
            SIGNAL SQLSTATE '45000'
                SET MYSQL_ERRNO = 30012,
                    MESSAGE_TEXT = 'Sales order item does not match the purchase item';
        END IF;

        IF v_itbs_id IS NULL THEN
            SET v_closing_stock = NULL;
            SELECT itbs_id, COALESCE(itbs_stock, 0)
            INTO v_itbs_id, v_closing_stock
            FROM tbl_itembranch_stock
            WHERE branch_id = v_branch_id
              AND itm_id = v_itm_id
            LIMIT 1
            FOR UPDATE;

            IF v_itbs_id IS NULL THEN
                INSERT INTO tbl_itembranch_stock (
                    branch_id,
                    itm_id,
                    itbs_stock,
                    itbs_reorder,
                    itbs_available,
                    itm_code,
                    itm_name,
                    itm_brand_id,
                    itm_category_id,
                    itm_subcategory_id,
                    itm_mrp,
                    itm_commision,
                    itm_target,
                    tp_tax_code,
                    itbs_duration,
                    itm_last_update_date,
                    itbs_purchase_price,
                    itbs_purchase_status
                )
                SELECT
                    v_branch_id,
                    item_master.itm_id,
                    0,
                    100,
                    1,
                    LEFT(COALESCE(NULLIF(v_item_code, ''), item_master.itm_code), 25),
                    LEFT(COALESCE(NULLIF(v_item_name, ''), item_master.itm_name), 150),
                    COALESCE(item_master.itm_brand_id, 0),
                    COALESCE(item_master.itm_category_id, 0),
                    item_master.itm_subcategory_id,
                    0.00,
                    0.00,
                    0.00,
                    '1',
                    0.00,
                    v_purchase_date,
                    v_item_price,
                    1
                FROM tbl_item_master AS item_master
                WHERE item_master.itm_id = v_itm_id;

                IF ROW_COUNT() = 0 THEN
                    SIGNAL SQLSTATE '45000'
                        SET MYSQL_ERRNO = 30009,
                            MESSAGE_TEXT = 'Item does not exist in the item master';
                END IF;

                SET v_itbs_id = LAST_INSERT_ID();
                SET v_closing_stock = 0;
            END IF;
        END IF;

        SET v_item_code = NULL;
        SET v_item_name = NULL;
        SET v_itm_id = NULL;
        SET v_closing_stock = NULL;
        SET v_purchase_status = NULL;
        SELECT
            stock.itm_code,
            stock.itm_name,
            stock.itm_id,
            COALESCE(stock.itbs_stock, 0),
            COALESCE(stock.itbs_purchase_status, 0),
            COALESCE(v_item_tax_rate, tax.tp_tax_percentage, 0.00),
            COALESCE(v_item_cess_rate, tax.tp_cess, 0.00)
        INTO
            v_item_code,
            v_item_name,
            v_itm_id,
            v_closing_stock,
            v_purchase_status,
            v_item_tax_rate,
            v_item_cess_rate
        FROM tbl_itembranch_stock AS stock
        LEFT JOIN tbl_tax_profile AS tax
            ON tax.tp_tax_code = stock.tp_tax_code
        WHERE stock.itbs_id = v_itbs_id
          AND stock.branch_id = v_branch_id
          AND (JSON_VALUE(v_item_json, '$.itm_id') IS NULL
               OR stock.itm_id = JSON_VALUE(v_item_json, '$.itm_id'))
        FOR UPDATE;

        IF v_itm_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MYSQL_ERRNO = 30007,
                    MESSAGE_TEXT = 'Item stock does not exist in the selected warehouse or does not match the item';
        END IF;

        IF v_item_tax_rate IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MYSQL_ERRNO = 30010,
                    MESSAGE_TEXT = 'Item tax rate could not be determined';
        END IF;

        SET v_row_no = COALESCE(
            JSON_VALUE(v_item_json, '$.row_no'), v_item_index);

        SET v_old_pi_id = NULL;
        SET v_existing_itbh_id = NULL;
        IF v_is_edit THEN
            SELECT pi.pi_id, pi.itbh_id
            INTO v_old_pi_id, v_existing_itbh_id
            FROM tmp_sp_save_purchase_edit_items AS pi
            WHERE pi.matched = FALSE
              AND (
                    (
                        COALESCE(
                            JSON_VALUE(v_item_json, '$.purchaseItemId'),
                            JSON_VALUE(v_item_json, '$.pi_id')
                        ) IS NOT NULL
                        AND pi.itbs_id = v_itbs_id
                        AND pi.pi_id = COALESCE(
                            JSON_VALUE(v_item_json, '$.purchaseItemId'),
                            JSON_VALUE(v_item_json, '$.pi_id')
                        )
                    )
                    OR (
                        JSON_VALUE(v_item_json, '$.itbh_id') IS NOT NULL
                        AND pi.itbs_id = v_itbs_id
                        AND pi.itbh_id = JSON_VALUE(v_item_json, '$.itbh_id')
                    )
                    OR (
                        COALESCE(
                            JSON_VALUE(v_item_json, '$.purchaseItemId'),
                            JSON_VALUE(v_item_json, '$.pi_id')
                        ) IS NULL
                        AND JSON_VALUE(v_item_json, '$.itbh_id') IS NULL
                        AND pi.row_no = v_row_no
                        AND pi.itbs_id = v_itbs_id
                    )
                  )
            ORDER BY pi.pi_id
            LIMIT 1;

            IF v_old_pi_id IS NOT NULL THEN
                UPDATE tmp_sp_save_purchase_edit_items
                SET matched = TRUE
                WHERE pi_id = v_old_pi_id;
            END IF;
        END IF;

        SET v_calculated_price = v_item_price;
        IF v_branch_tax_method IN (1, 2)
           AND v_branch_tax_inclusive = 1 THEN
            IF v_item_cess_rate > 0 THEN
                SET v_calculated_price =
                    (10000 * v_calculated_price)
                    / (10000 + (100 * v_item_tax_rate)
                              + (v_item_tax_rate * v_item_cess_rate));
            ELSE
                SET v_calculated_price =
                    v_calculated_price / (1 + (v_item_tax_rate / 100));
                IF v_branch_tax_method = 2 THEN
                    SET v_item_cess_rate = 0.00;
                END IF;
            END IF;
        END IF;

        SET v_item_total = v_calculated_price * v_item_qty;
        IF v_branch_tax_method = 0 THEN
            SET v_item_total = ROUND(v_item_total, 2);
        END IF;
        SET v_line_discount_amount =
            (v_item_total * v_item_discount_rate) / 100;

        IF v_branch_tax_method = 0 THEN
            SET v_line_tax_amount = 0.00;
            SET v_line_tax_excluded =
                ROUND(v_item_total - v_line_discount_amount, 2);
            SET v_item_net_amount = v_line_tax_excluded;
        ELSE
            SET v_line_tax_excluded =
                v_item_total - v_line_discount_amount;
            SET v_line_tax_amount =
                (v_line_tax_excluded * v_item_tax_rate / 100)
                * (1 + (v_item_cess_rate / 100));
            SET v_item_net_amount = v_line_tax_excluded + v_line_tax_amount;
        END IF;

        IF v_branch_tax_method = 2 THEN
            IF UPPER(TRIM(v_vendor_state))
               = UPPER(TRIM(v_branch_state_name)) THEN
                SET v_line_cgst = ROUND(v_item_tax_rate / 2, 2);
                SET v_line_sgst = ROUND(v_item_tax_rate / 2, 2);
            ELSE
                SET v_line_igst = v_item_tax_rate;
            END IF;
        END IF;

        IF v_existing_itbh_id IS NOT NULL THEN
            SET v_itbh_id = v_existing_itbh_id;
            UPDATE tbl_item_batch
            SET itbs_id = v_itbs_id,
                itm_id = v_itm_id,
                itbh_custbatchid = IF(
                    JSON_CONTAINS_PATH(v_item_json, 'one', '$.itbh_custbatchid'),
                    COALESCE(
                        JSON_VALUE(v_item_json, '$.itbh_custbatchid'),
                        CONCAT('PUR-', p_pm_id, '-', v_row_no)),
                    itbh_custbatchid),
                tum_id = COALESCE(JSON_VALUE(v_item_json, '$.tum_id'), tum_id),
                itbh_no_piece = COALESCE(
                    JSON_VALUE(v_item_json, '$.itbh_no_piece'), v_item_qty),
                itbh_length = JSON_VALUE(v_item_json, '$.itbh_length'),
                itbh_width = JSON_VALUE(v_item_json, '$.itbh_width'),
                itbh_kg = JSON_VALUE(v_item_json, '$.itbh_kg'),
                itbh_kgmeter = JSON_VALUE(v_item_json, '$.itbh_kgmeter'),
                itbh_sqmt = JSON_VALUE(v_item_json, '$.itbh_sqmt'),
                itbh_startqty = v_item_qty,
                itbh_status = COALESCE(
                    JSON_VALUE(v_item_json, '$.itbh_status'), itbh_status),
                itbh_cost = COALESCE(
                    JSON_VALUE(v_item_json, '$.itbh_cost'), v_item_price),
                itbh_costwithinvoice = COALESCE(
                    JSON_VALUE(v_item_json, '$.itbh_costwithinvoice'),
                    itbh_costwithinvoice),
                itbh_costwithoutinvoice = COALESCE(
                    JSON_VALUE(v_item_json, '$.itbh_costwithoutinvoice'),
                    itbh_costwithoutinvoice),
                itbh_costotal = COALESCE(
                    JSON_VALUE(v_item_json, '$.itbh_costotal'), v_item_total)
            WHERE itbh_id = v_itbh_id;
        ELSE
            SET v_itbm_prefix = NULL;
            SET v_itbm_suffix = NULL;
            SET v_itbm_serl = NULL;
            SET v_batch_serial_no = NULL;
            SELECT bm.itbm_prefix, bm.itbm_suffix, bm.itbm_serl
            INTO v_itbm_prefix, v_itbm_suffix, v_itbm_serl
            FROM tbl_item_batch_master_items AS batch_item
            INNER JOIN tbl_item_batch_master AS bm
                ON bm.itbm_id = batch_item.itbm_id
            WHERE batch_item.itm_id = v_itm_id
            ORDER BY batch_item.itbmi_id DESC
            LIMIT 1;

            SELECT COALESCE(MAX(CAST(itbm_serl AS UNSIGNED)), 0)
            INTO v_batch_serial_no
            FROM tbl_item_batch
            WHERE CONVERT(itbm_prefix USING utf8mb4) COLLATE utf8mb4_general_ci
                      = CONVERT(COALESCE(v_itbm_prefix, '') USING utf8mb4) COLLATE utf8mb4_general_ci
              AND CONVERT(itbm_suffix USING utf8mb4) COLLATE utf8mb4_general_ci
                      = CONVERT(COALESCE(v_itbm_suffix, '') USING utf8mb4) COLLATE utf8mb4_general_ci;

            SET v_itbm_prefix = COALESCE(v_itbm_prefix, '');
            SET v_itbm_suffix = COALESCE(v_itbm_suffix, '');
            IF COALESCE(v_itbm_serl, 0) > COALESCE(v_batch_serial_no, 0) THEN
                SET v_batch_serial_no = v_itbm_serl + 1;
            ELSE
                SET v_batch_serial_no = COALESCE(v_batch_serial_no, 0) + 1;
            END IF;

            INSERT INTO tbl_item_batch (
                itbh_custbatchid,
                itbm_prefix,
                itbm_suffix,
                itbm_serl,
                itbh_no,
                branch_id,
                itbs_id,
                itm_id,
                tum_id,
                itbh_no_piece,
                itbh_length,
                itbh_width,
                itbh_kg,
                itbh_kgmeter,
                itbh_sqmt,
                itbh_startqty,
                itbh_currentqty,
                itbh_status,
                itbh_created_doc_type,
                itbh_cost,
                itbh_costwithinvoice,
                itbh_costwithoutinvoice,
                itbh_costotal,
                itbh_created_doc_id,
                itbh_createddate,
                itbh_createduser
            ) VALUES (
                COALESCE(
                    JSON_VALUE(v_item_json, '$.itbh_custbatchid'),
                    CONCAT('PUR-', p_pm_id, '-', v_row_no)),
                v_itbm_prefix,
                v_itbm_suffix,
                v_batch_serial_no,
                CONCAT(v_itbm_prefix, v_batch_serial_no, v_itbm_suffix),
                v_branch_id,
                v_itbs_id,
                v_itm_id,
                JSON_VALUE(v_item_json, '$.tum_id'),
                COALESCE(JSON_VALUE(v_item_json, '$.itbh_no_piece'), v_item_qty),
                JSON_VALUE(v_item_json, '$.itbh_length'),
                JSON_VALUE(v_item_json, '$.itbh_width'),
                JSON_VALUE(v_item_json, '$.itbh_kg'),
                JSON_VALUE(v_item_json, '$.itbh_kgmeter'),
                JSON_VALUE(v_item_json, '$.itbh_sqmt'),
                v_item_qty,
                v_item_qty,
                COALESCE(JSON_VALUE(v_item_json, '$.itbh_status'), 1),
                2,
                COALESCE(JSON_VALUE(v_item_json, '$.itbh_cost'), v_item_price),
                JSON_VALUE(v_item_json, '$.itbh_costwithinvoice'),
                JSON_VALUE(v_item_json, '$.itbh_costwithoutinvoice'),
                COALESCE(JSON_VALUE(v_item_json, '$.itbh_costotal'), v_item_total),
                p_pm_id,
                COALESCE(JSON_VALUE(v_item_json, '$.itbh_createddate'), v_purchase_date),
                COALESCE(JSON_VALUE(v_item_json, '$.itbh_createduser'), v_user_id)
            );

            SET v_itbh_id = LAST_INSERT_ID();
        END IF;

        SET v_stock_qty = v_item_qty;
        SET v_closing_stock = v_closing_stock + v_item_qty;

        UPDATE tbl_itembranch_stock
        SET itbs_stock = v_closing_stock,
            itm_last_update_date = v_purchase_date,
            itbs_purchase_price = CASE
                WHEN v_purchase_status = 1 AND v_item_qty <> 0
                THEN v_item_net_amount / v_item_qty
                ELSE itbs_purchase_price
            END
        WHERE itbs_id = v_itbs_id;

        INSERT INTO tbl_stock_transactions (
            itbs_id,
            action_type,
            action_ref_id,
            user_id,
            narration,
            dr_qty,
            cr_qty,
            closing_stock,
            date,
            is_reconciliation,
            Cost,
            itbh_id,
            branch_id
        ) VALUES (
            v_itbs_id,
            2,
            p_pm_id,
            v_user_id,
            CONCAT('Purchased ', v_stock_qty, ' ', v_item_name,
                   ' in purchase entry #', p_pm_id),
            0,
            v_stock_qty,
            v_item_qty,
            p_current_datetime,
            0,
            v_item_price,
            v_itbh_id,
            v_branch_id
        );

        INSERT INTO tbl_purchase_items (
            pm_id,
            row_no,
            itbs_id,
            itbh_id,
            sio_id,
            itm_code,
            itm_name,
            pi_org_price,
            pi_price,
            pi_qty,
            pi_total,
            pi_discount_rate,
            pi_discount_amount,
            pi_net_amount,
            pi_item_tax,
            pi_item_cgst,
            pi_item_sgst,
            pi_item_igst,
            pi_item_utgst,
            pi_item_cess,
            pi_tax_excluded_total,
            pi_tax_amount,
            pi_carton_count,
            pi_item_per_carton,
            itsv_uom_purchase
        ) VALUES (
            p_pm_id,
            v_row_no,
            v_itbs_id,
            v_itbh_id,
            v_sio_id,
            v_item_code,
            v_item_name,
            COALESCE(JSON_VALUE(v_item_json, '$.pi_org_price'), 0.00),
            v_item_price,
            v_item_qty,
            v_item_total,
            v_item_discount_rate,
            v_line_discount_amount,
            v_item_net_amount,
            v_item_tax_rate,
            v_line_cgst,
            v_line_sgst,
            v_line_igst,
            0.00,
            v_item_cess_rate,
            v_line_tax_excluded,
            v_line_tax_amount,
            COALESCE(JSON_VALUE(v_item_json, '$.pi_carton_count'), 0),
            COALESCE(JSON_VALUE(v_item_json, '$.pi_item_per_carton'), 0),
            COALESCE(
                JSON_VALUE(v_item_json, '$.itsv_uom_purchase'),
                (
                    SELECT item_master.itsv_uom_purchase
                    FROM tbl_item_master AS item_master
                    WHERE item_master.itm_id = v_itm_id
                )
            )
        );
        
        SET v_pi_id = LAST_INSERT_ID(); 
        UPDATE tbl_item_batch SET itbh_created_doc_id = v_pi_id WHERE itbh_id = v_itbh_id;

        IF v_sio_id IS NOT NULL AND v_sio_id > 0 THEN
            INSERT INTO tbl_item_batchstock_reserve (
                sio_id,
                itbh_id,
                itbsr_qty
            ) VALUES (
                v_sio_id,
                v_itbh_id,
                v_item_qty
            );
        END IF;

        SET v_sum_total = v_sum_total + v_item_total;
        SET v_sum_discount = v_sum_discount + v_line_discount_amount;
        SET v_sum_tax_excluded = v_sum_tax_excluded + v_line_tax_excluded;
        SET v_sum_tax = v_sum_tax + v_line_tax_amount;
        SET v_sum_net = v_sum_net + v_item_net_amount;
        SET v_item_index = v_item_index + 1;
    END WHILE;

    IF v_is_edit THEN
        UPDATE tbl_item_batch AS batch
        INNER JOIN (
            SELECT
                old_batches.itbh_id,
                COALESCE(new_batches.new_qty, 0) - old_batches.old_qty AS qty_delta
            FROM (
                SELECT itbh_id, SUM(pi_qty) AS old_qty
                FROM tmp_sp_save_purchase_edit_items
                WHERE itbh_id IS NOT NULL
                GROUP BY itbh_id
            ) AS old_batches
            LEFT JOIN (
                SELECT itbh_id, SUM(pi_qty) AS new_qty
                FROM tbl_purchase_items
                WHERE pm_id = p_pm_id
                  AND pi_id > v_old_pi_max
                  AND itbh_id IS NOT NULL
                GROUP BY itbh_id
            ) AS new_batches
                ON new_batches.itbh_id = old_batches.itbh_id
        ) AS batch_changes
            ON batch_changes.itbh_id = batch.itbh_id
        SET batch.itbh_currentqty =
            COALESCE(batch.itbh_currentqty, 0) + batch_changes.qty_delta;

        DELETE FROM tbl_purchase_items
        WHERE pm_id = p_pm_id
          AND pi_id <= v_old_pi_max;

        DROP TEMPORARY TABLE IF EXISTS tmp_sp_save_purchase_edit_items;
    END IF;

    SET v_pm_total = v_sum_total;
    SET v_pm_discount_amount = v_sum_discount;
    SET v_pm_tax_excluded_amt = v_sum_tax_excluded;
    SET v_pm_tax_amount = v_sum_tax;
    SET v_pm_discount_rate = CASE
        WHEN v_sum_tax_excluded + v_sum_discount = 0 THEN 0
        ELSE ROUND(v_sum_discount * 100
                   / (v_sum_tax_excluded + v_sum_discount), 2)
    END;
    SET v_pm_netamount = ROUND(v_sum_net, 0);
    SET v_pm_roundoff = v_pm_netamount - v_sum_net;

    UPDATE tbl_purchase_master
    SET pm_ref_no = COALESCE(
            v_pm_ref_no,
        CASE WHEN NOT v_is_edit THEN p_pm_id ELSE pm_ref_no END),
        pm_total = v_pm_total,
        pm_discount_rate = v_pm_discount_rate,
        pm_discount_amount = v_pm_discount_amount,
        pm_netamount = v_pm_netamount,
        pm_tax_excluded_amt = v_pm_tax_excluded_amt,
        pm_tax_amount = v_pm_tax_amount,
        pm_roundoff = v_pm_roundoff
    WHERE pm_id = p_pm_id;

    INSERT INTO tbl_transactions (
        action_type,
        action_ref_id,
        partner_id,
        partner_type,
        branch_id,
        user_id,
        narration,
        cr,
        date,
        closing_balance,
        session_id
    )
    SELECT
        2,
        p_pm_id,
        v_vendor_id,
        2,
        v_branch_id,
        v_user_id,
        CONCAT('Purchase entry #', v_invoice_no,
               ' is purchased with net amount ', v_pm_netamount),
        v_pm_netamount,
        p_current_datetime,
        COALESCE(SUM(dr) - SUM(cr), 0) - v_pm_netamount,
        v_pm_sessionid
    FROM tbl_transactions
    WHERE partner_id = v_vendor_id
      AND partner_type = 2;

    IF v_paid_amount > 0 THEN
        INSERT INTO tbl_transactions (
            action_type,
            action_ref_id,
            partner_id,
            partner_type,
            branch_id,
            user_id,
            narration,
            cash_amt,
            cheque_amt,
            cheque_no,
            cheque_date,
            cheque_bank,
            dr,
            date,
            closing_balance,
            session_id
        )
        SELECT
            2,
            p_pm_id,
            v_vendor_id,
            2,
            v_branch_id,
            v_user_id,
            CONCAT('Paid ', v_paid_amount,
                   ' for Purchase entry #', v_invoice_no),
            v_cash_amount,
            v_cheque_amount,
            v_cheque_no,
            v_cheque_date,
            v_cheque_bank,
            v_paid_amount,
            p_current_datetime,
            COALESCE(SUM(dr) - SUM(cr), 0) + v_paid_amount,
            v_pm_sessionid
        FROM tbl_transactions
        WHERE partner_id = v_vendor_id
          AND partner_type = 2;
    END IF;

    IF v_old_vendor_id IS NOT NULL
       AND v_old_vendor_id <> v_vendor_id THEN
        UPDATE tbl_vendor
        SET vn_balance = COALESCE((
            SELECT SUM(cr) - SUM(dr)
            FROM tbl_transactions
            WHERE partner_id = v_old_vendor_id
              AND partner_type = 2
        ), 0)
        WHERE vn_id = v_old_vendor_id;
    END IF;

    UPDATE tbl_vendor
    SET vn_balance = COALESCE((
        SELECT SUM(cr) - SUM(dr)
        FROM tbl_transactions
        WHERE partner_id = v_vendor_id
          AND partner_type = 2
    ), 0)
    WHERE vn_id = v_vendor_id;

    COMMIT;

    SET p_result = JSON_OBJECT(
        'success', TRUE,
        'error_code', 0,
        'message', 'Purchase entry saved successfully',
        'master_action', v_master_action,
        'pm_id', p_pm_id,
        'item_count', v_item_count
    );
END$$

DELIMITER ;