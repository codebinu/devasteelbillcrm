-- Fixes MySQL error 1267 ("Illegal mix of collations (utf8mb4_general_ci,IMPLICIT) and (utf8mb4_unicode_ci,IMPLICIT)")
-- raised by sp_save_production_entry when producing from the Production Details tab of a sales order.
--
-- Only change from the live definition: the duplicate-document check now compares with an explicit
-- COLLATE utf8mb4_general_ci (the collation of tbl_item_pro_master.itpm_doc_no).
--
-- Run once against the application database (MariaDB 11.x: CREATE OR REPLACE is atomic).
-- If your SQL client does not support DELIMITER, run only the CREATE ... END block as a single statement.

DELIMITER $$

CREATE OR REPLACE PROCEDURE `sp_save_production_entry`(
    IN p_itbsr_id INT,
    IN p_output_qty DECIMAL(10, 6),
    IN p_user_id INT,
    OUT p_itpm_id INT,
    OUT p_result LONGTEXT
)
    MODIFIES SQL DATA
    SQL SECURITY INVOKER
BEGIN
    DECLARE v_sqlstate CHAR(5);
    DECLARE v_errno INT;
    DECLARE v_message TEXT;
    DECLARE v_found_smo_id INT DEFAULT NULL;
    DECLARE v_invoice_no VARCHAR(50);
    DECLARE v_doc_no VARCHAR(50);
    DECLARE v_branch_id INT;
    DECLARE v_smo_id INT DEFAULT NULL;
    DECLARE v_reservation_smo_id INT DEFAULT NULL;
    DECLARE v_sio_id INT DEFAULT NULL;
    DECLARE v_reservation_qty DECIMAL(10, 6) DEFAULT NULL;
    DECLARE v_reservation_itbh_id INT DEFAULT NULL;
    DECLARE v_batch_id INT DEFAULT NULL;
    DECLARE v_batch_branch_id INT DEFAULT NULL;
    DECLARE v_batch_cost DECIMAL(10, 6) DEFAULT NULL;
    DECLARE v_output_itbs_id INT DEFAULT NULL;
    DECLARE v_output_itm_id INT DEFAULT NULL;
    DECLARE v_output_tum_id INT DEFAULT NULL;
    DECLARE v_output_length DECIMAL(10, 6) DEFAULT NULL;
    DECLARE v_output_width DECIMAL(10, 6) DEFAULT NULL;
    DECLARE v_itbm_prefix VARCHAR(30);
    DECLARE v_itbm_suffix VARCHAR(30);
    DECLARE v_itbm_serl INT;
    DECLARE v_batch_serial_no INT;
    DECLARE v_output_itbh_id INT;
    DECLARE v_output_itbsr_id INT;
    DECLARE v_output_cost DECIMAL(10, 6);
    DECLARE v_current_datetime DATETIME;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            v_sqlstate = RETURNED_SQLSTATE,
            v_errno = MYSQL_ERRNO,
            v_message = MESSAGE_TEXT;
        SET p_itpm_id = NULL;
        SET p_result = JSON_OBJECT(
            'success', FALSE,
            'error_code', COALESCE(v_errno, 50000),
            'sql_state', COALESCE(v_sqlstate, '45000'),
            'message', COALESCE(v_message, 'Production entry could not be saved'),
            'itpm_id', NULL
        );
    END;

    SET p_itpm_id = NULL;
    SET p_result = NULL;

    IF p_itbsr_id IS NULL
       OR p_itbsr_id <= 0
       OR p_output_qty IS NULL
       OR p_output_qty <= 0
       OR p_user_id IS NULL
       OR p_user_id <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MYSQL_ERRNO = 30001,
                MESSAGE_TEXT = 'Reservation row id, positive output quantity, and production user are required';
    END IF;

    START TRANSACTION;

    SELECT oi.smo_id
    INTO v_smo_id
    FROM tbl_item_batchstock_reserve AS rs
    INNER JOIN tbl_sales_items_order AS oi
        ON oi.sio_id = rs.sio_id
    WHERE rs.itbsr_id = p_itbsr_id;

    IF v_smo_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MYSQL_ERRNO = 30005,
                MESSAGE_TEXT = 'Reservation row does not exist';
    END IF;

    SELECT smo_id, smo_invoice_no, branch_id
    INTO v_found_smo_id, v_invoice_no, v_branch_id
    FROM tbl_sales_master_order
    WHERE smo_id = v_smo_id
    FOR UPDATE;

    IF v_found_smo_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MYSQL_ERRNO = 30002,
                MESSAGE_TEXT = 'Sales order does not exist';
    END IF;

    IF v_branch_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MYSQL_ERRNO = 30003,
                MESSAGE_TEXT = 'Sales order does not have a branch';
    END IF;

    SET v_doc_no = COALESCE(
        NULLIF(v_invoice_no, ''),
        CONCAT('SO-', v_smo_id));

    IF EXISTS (
        SELECT 1
        FROM tbl_item_pro_master
        WHERE itpm_doc_no = v_doc_no COLLATE utf8mb4_general_ci
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MYSQL_ERRNO = 30004,
                MESSAGE_TEXT = 'A production entry already exists for this sales order number';
    END IF;

    SELECT
        oi.smo_id,
        oi.sio_id,
        oi.itbs_id,
        oi.itm_id,
        oi.tum_id,
        oi.sio_length,
        oi.sio_width,
        rs.itbsr_qty,
        rs.itbh_id,
        bt.itbh_id,
        bt.branch_id,
        bt.itbh_cost
    INTO
        v_reservation_smo_id,
        v_sio_id,
        v_output_itbs_id,
        v_output_itm_id,
        v_output_tum_id,
        v_output_length,
        v_output_width,
        v_reservation_qty,
        v_reservation_itbh_id,
        v_batch_id,
        v_batch_branch_id,
        v_batch_cost
    FROM tbl_item_batchstock_reserve AS rs
    INNER JOIN tbl_sales_items_order AS oi
        ON oi.sio_id = rs.sio_id
    LEFT JOIN tbl_item_batch AS bt
        ON bt.itbh_id = rs.itbh_id
    WHERE rs.itbsr_id = p_itbsr_id
      AND oi.smo_id = v_smo_id
    FOR UPDATE;

    IF v_reservation_smo_id IS NULL
       OR v_reservation_smo_id <> v_smo_id THEN
        SIGNAL SQLSTATE '45000'
            SET MYSQL_ERRNO = 30005,
                MESSAGE_TEXT = 'Reservation row does not belong to a valid sales order';
    END IF;

    IF v_reservation_qty IS NULL
       OR v_reservation_qty <= 0
       OR v_reservation_itbh_id IS NULL
       OR v_batch_id IS NULL
       OR (v_batch_branch_id IS NOT NULL
           AND v_batch_branch_id <> v_branch_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MYSQL_ERRNO = 30006,
                MESSAGE_TEXT = 'Selected reservation contains an invalid quantity or batch';
    END IF;

    IF v_output_itbs_id IS NULL OR v_output_itm_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MYSQL_ERRNO = 30007,
                MESSAGE_TEXT = 'Sales order item must identify the finished item stock and item';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM tbl_itembranch_stock AS st
        WHERE st.itbs_id = v_output_itbs_id
          AND st.itm_id = v_output_itm_id
          AND st.branch_id = v_branch_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MYSQL_ERRNO = 30008,
                MESSAGE_TEXT = 'Finished item stock does not exist in the sales order branch';
    END IF;

    SET v_current_datetime = CURRENT_TIMESTAMP;
    SET v_output_cost =
        (v_reservation_qty * COALESCE(v_batch_cost, 0.000000))
        / p_output_qty;

    INSERT INTO tbl_item_pro_master (
        itpm_doc_no,
        itpm_docdate,
        itpm_createdby,
        itpm_createddate
    ) VALUES (
        v_doc_no,
        v_current_datetime,
        p_user_id,
        v_current_datetime
    );

    SET p_itpm_id = LAST_INSERT_ID();

    SET v_itbm_prefix = NULL;
    SET v_itbm_suffix = NULL;
    SET v_itbm_serl = NULL;
    SET v_batch_serial_no = NULL;
    SELECT bm.itbm_prefix, bm.itbm_suffix, bm.itbm_serl
    INTO v_itbm_prefix, v_itbm_suffix, v_itbm_serl
    FROM tbl_item_batch_master_items AS batch_item
    INNER JOIN tbl_item_batch_master AS bm
        ON bm.itbm_id = batch_item.itbm_id
    WHERE batch_item.itm_id = v_output_itm_id
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
        itbh_startqty,
        itbh_currentqty,
        itbh_status,
        itbh_created_doc_type,
        itbh_cost,
        itbh_costotal,
        itbh_created_doc_id,
        itbh_createddate,
        itbh_createduser
    ) VALUES (
        CONCAT('PRO-', p_itpm_id, '-', v_sio_id),
        v_itbm_prefix,
        v_itbm_suffix,
        v_batch_serial_no,
        CONCAT(v_itbm_prefix, v_batch_serial_no, v_itbm_suffix),
        v_branch_id,
        v_output_itbs_id,
        v_output_itm_id,
        v_output_tum_id,
        p_output_qty,
        v_output_length,
        v_output_width,
        p_output_qty,
        p_output_qty,
        1,
        2,
        v_output_cost,
        v_reservation_qty * COALESCE(v_batch_cost, 0.000000),
        p_itpm_id,
        v_current_datetime,
        p_user_id
    );

    SET v_output_itbh_id = LAST_INSERT_ID();

    INSERT INTO tbl_item_pro_items (
        itpi_branch,
        itpm_id,
        itpi_serial,
        itbh_id,
        itpi_inputoutput,
        itpi_quantity,
        itpi_cost
    )
    VALUES (
        v_branch_id,
        p_itpm_id,
        1,
        v_reservation_itbh_id,
        1,
        v_reservation_qty,
        COALESCE(v_batch_cost, 0.000000)
    );

    INSERT INTO tbl_item_pro_items (
        itpi_branch,
        itpm_id,
        itpi_serial,
        itbh_id,
        itpi_inputoutput,
        itpi_quantity,
        itpi_cost
    )
    VALUES (
        v_branch_id,
        p_itpm_id,
        2,
        v_output_itbh_id,
        2,
        p_output_qty,
        v_output_cost
    );

    UPDATE tbl_item_batchstock_reserve
    SET itbsr_qty = itbsr_qty - v_reservation_qty
    WHERE itbsr_id = p_itbsr_id
      AND itbsr_qty >= v_reservation_qty;

    IF ROW_COUNT() <> 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MYSQL_ERRNO = 30009,
                MESSAGE_TEXT = 'Input reservation quantity could not be reduced';
    END IF;

    DELETE FROM tbl_item_batchstock_reserve
    WHERE itbsr_id = p_itbsr_id
      AND itbsr_qty = 0;

    INSERT INTO tbl_item_batchstock_reserve (
        sio_id,
        itbh_id,
        itbsr_qty
    ) VALUES (
        v_sio_id,
        v_output_itbh_id,
        p_output_qty
    );

    SET v_output_itbsr_id = LAST_INSERT_ID();

    COMMIT;

    SET p_result = JSON_OBJECT(
        'success', TRUE,
        'error_code', 0,
        'message', 'Production entry created successfully',
        'itpm_id', p_itpm_id,
        'smo_id', v_smo_id,
        'itbsr_id', p_itbsr_id,
        'output_qty', p_output_qty,
        'output_itbh_id', v_output_itbh_id,
        'output_itbsr_id', v_output_itbsr_id,
        'doc_no', v_doc_no,
        'input_count', 1
    );
END$$

DELIMITER ;
