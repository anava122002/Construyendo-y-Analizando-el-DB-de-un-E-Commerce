/* ============================================================
   SQL PROJECT - Online Supermarket Dataset
   FILE 7 - 07_simulation_procedures.sql
   ============================================================ */


USE sql_project;


/* ----------- Function for updating indexes ----------- */

DELIMITER $$

CREATE FUNCTION fn_next_id(p_prefix VARCHAR(5), p_last_id VARCHAR(15))
RETURNS VARCHAR(15)
DETERMINISTIC
BEGIN
    DECLARE v_num INT;
    DECLARE v_next_num INT;
    DECLARE v_length INT;

    
    SET v_num = CAST(SUBSTRING(p_last_id, LENGTH(p_prefix) + 1) AS UNSIGNED);
    SET v_next_num = v_num + 1;

    
    SET v_length = LENGTH(p_last_id) - LENGTH(p_prefix);

    RETURN CONCAT(p_prefix, LPAD(v_next_num, v_length, '0'));
    
END$$

DELIMITER ;



/* ----------- Procedure for storing products from new orders ----------- */

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_adding_product_to_cart$$
CREATE PROCEDURE sp_adding_product_to_cart(IN p_product_id VARCHAR(10), p_quantity INT)
BEGIN
	
	DECLARE v_price DECIMAL(5, 2) DEFAULT 0;
	DECLARE v_total_price DECIMAL(10, 2) DEFAULT 0;
	
	IF (SELECT COUNT(product_id) FROM dim_products WHERE product_id = p_product_id) = 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'No hay productos que comprar.';	
	END IF;
	
	IF (SELECT is_active FROM dim_products WHERE product_id = p_product_id) = 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'El producto está descatalogado.';	
	END IF;
	
	IF p_quantity <= 0 THEN 
	SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT = 'La cantidad no es válida.';
	END IF;
	
	IF (SELECT stock FROM fct_inventory WHERE product_id = p_product_id) < p_quantity THEN 
	SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT = 'Stock insuficiente para este producto.';
	END IF;
	
	
	SELECT product_price INTO v_price
	FROM dim_products
	WHERE product_id = p_product_id;
	
	SET v_total_price = v_price * p_quantity;
	
	INSERT INTO tmp_order_items (product_id, quantity, price, total_price)
	VALUES (p_product_id, p_quantity, v_price, v_total_price);
	
	
END$$

DELIMITER ;



/* ----------- Trigger for recalculating stock ----------- */

DELIMITER $$

CREATE TRIGGER tr_update_stock
AFTER INSERT ON fct_order_details
FOR EACH ROW
BEGIN
    UPDATE fct_inventory
    SET stock = stock - NEW.quantity
    WHERE product_id = NEW.product_id;
END$$

DELIMITER ;



/* --------- New Orders Procedure --------- */

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_adding_new_order$$
CREATE PROCEDURE sp_adding_new_order(IN p_customer_id VARCHAR(10))
BEGIN
	
	DECLARE v_worker_id VARCHAR(15);
	DECLARE v_country VARCHAR(5);
	DECLARE v_order_date DATE DEFAULT CURDATE();
	DECLARE v_total_paid DECIMAL(10, 2) DEFAULT 0;
	DECLARE v_order_id VARCHAR(10);
	DECLARE v_last_id VARCHAR(15);
	DECLARE v_detail_id VARCHAR(15);
	
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error cargando compra.';
    END;
	
	IF (SELECT COUNT(*) FROM tmp_order_items) = 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'No hay productos que comprar.';	
	END IF;
	
	IF (SELECT COUNT(customer_id) FROM dim_customers WHERE customer_id = p_customer_id) = 0 THEN
	SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'El cliente no existe.';	
	END IF;
	
	SELECT country INTO v_country
	FROM dim_customers
	WHERE customer_id = p_customer_id;
	
	SELECT worker_id INTO v_worker_id
	FROM vw_workers_enriched
	WHERE country = v_country
	ORDER BY purchases_prepared ASC
	LIMIT 1;
	
	IF v_worker_id IS NULL THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'No hay trabajadores disponibles en ese país.';
	END IF;
	
	SELECT SUM(total_price) INTO v_total_paid
	FROM tmp_order_items;
	
	SELECT MAX(order_id) INTO v_last_id
	FROM fct_orders;
	
	SET v_order_id = fn_next_id('OR', v_last_id);
	
	START TRANSACTION;
	
	INSERT INTO fct_orders (order_id, customer_id, country, order_date, worker_id, total_paid)
	VALUES (v_order_id, p_customer_id, v_country, v_order_date, v_worker_id, v_total_paid);
	
	SAVEPOINT after_order_insert;
	
	SET @last_num = (SELECT CAST(SUBSTRING(MAX(detail_id), 3) AS UNSIGNED) FROM fct_order_details);

	INSERT INTO fct_order_details (detail_id, order_id, product_id, quantity, price_each, total_price)
	SELECT
	    CONCAT('DE', LPAD(@last_num + ROW_NUMBER() OVER (ORDER BY product_id), 8, '0')),
	    v_order_id,
	    product_id,
	    quantity,
	    price,
	    total_price
	FROM tmp_order_items;
	
	COMMIT;	
	
END$$

DELIMITER ;



/* ------------- Quick Example ------------- */

-- CREATE TEMPORARY TABLE tmp_order_items (
--     product_id  VARCHAR(10),
--     quantity INT,
--     price DECIMAL(5,2),
--     total_price DECIMAL(10,2)
-- );
--
-- CALL sp_adding_product_to_cart('PR00001', 2);
-- CALL sp_adding_product_to_cart('PR00003', 1);
-- CALL sp_adding_new_order('CU00001');

