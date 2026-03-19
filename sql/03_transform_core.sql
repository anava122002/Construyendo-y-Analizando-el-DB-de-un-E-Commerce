/* ============================================================
   SQL PROJECT - Online Supermarket Dataset
   FILE 3 - 03_transform_core.sql
   ============================================================ */


USE student_project_sql;


/* -------- Populating Tables Using Procedures --------- */

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_refresh_core$$
CREATE PROCEDURE sp_refresh_core()
BEGIN
	
	DECLARE v_dim_categories_rows BIGINT DEFAULT 0;
	DECLARE v_dim_brands_rows BIGINT DEFAULT 0;
	DECLARE v_dim_products_rows BIGINT DEFAULT 0;
	DECLARE v_fct_inventory_rows BIGINT DEFAULT 0;
	DECLARE v_dim_customers_rows BIGINT DEFAULT 0;
	DECLARE v_dim_workers_rows BIGINT DEFAULT 0;
	DECLARE v_fct_orders_rows BIGINT DEFAULT 0;
	DECLARE v_fct_order_details_rows BIGINT DEFAULT 0;
	
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error en sp_refresh_core';
    END;
	
	START TRANSACTION;
	
	SET FOREIGN_KEY_CHECKS = 0;
	TRUNCATE TABLE fct_order_details;
	TRUNCATE TABLE fct_orders;
	TRUNCATE TABLE dim_workers;
	TRUNCATE TABLE dim_customers;
	TRUNCATE TABLE fct_inventory;
	TRUNCATE TABLE dim_products;
	TRUNCATE TABLE dim_brands;
	TRUNCATE TABLE dim_categories;
	SET FOREIGN_KEY_CHECKS = 1;
	
	SAVEPOINT after_truncate;
	
	-- Categories
	INSERT INTO dim_categories (category_id, category)
	SELECT DISTINCT
		TRIM(ca.raw_category_id) AS category_id,
		NULLIF(TRIM(ca.raw_category), '') AS category
	FROM stg_categories_raw AS ca
	WHERE TRIM(ca.raw_category_id) REGEXP '^CA[0-9]{5}$';
	
	SET v_dim_categories_rows = (SELECT COUNT(*) FROM dim_categories);
	
	SAVEPOINT after_categories;
	
	-- Brands
	INSERT INTO dim_brands (brand_id, brand)
	SELECT DISTINCT
		TRIM(br.raw_brand_id) AS brand_id,
		NULLIF(TRIM(br.raw_brand), '') AS brand
	FROM stg_brands_raw AS br
	WHERE TRIM(br.raw_brand_id) REGEXP '^BR[0-9]{5}$';
	
	SET v_dim_brands_rows = (SELECT COUNT(*) FROM dim_brands);
	
	SAVEPOINT after_brands;
	
	-- Products
	INSERT INTO dim_products (product_id, product_name, product_price, category_id, brand_id, rating, is_active)
	SELECT DISTINCT
		TRIM(pr.raw_product_id) AS product_id,
		NULLIF(TRIM(pr.raw_product_name), '') AS product_name,
		CAST(NULLIF(TRIM(pr.raw_product_price), '') AS DECIMAL(5, 2)) AS product_price,
		TRIM(pr.raw_category_id) AS category_id,
		NULLIF(TRIM(pr.raw_brand_id), '') AS brand_id,
		CAST(NULLIF(TRIM(pr.raw_rating), '') AS DECIMAL(3, 2)) AS rating,
		CAST(TRIM(pr.raw_is_active) AS UNSIGNED) AS is_active
	FROM stg_products_raw AS pr
	WHERE TRIM(pr.raw_product_id) REGEXP '^PR[0-9]{5,6}$';
	
	SET v_dim_products_rows = (SELECT COUNT(*) FROM dim_products);
	
	SAVEPOINT after_products;
	
	-- Inventory
	INSERT INTO fct_inventory (product_id, product_name, category_id, brand_id, stock, last_restock)
	SELECT DISTINCT
		TRIM(i.raw_product_id) AS product_id,
		NULLIF(TRIM(i.raw_product_name), '') AS product_name,
		TRIM(i.raw_category_id) AS category_id,
		NULLIF(TRIM(i.raw_brand_id), '') AS brand_id,
		CAST(TRIM(i.raw_stock) AS UNSIGNED) AS stock,
		STR_TO_DATE(TRIM(i.raw_last_restock), '%Y-%m-%d %H:%i:%s') AS last_restock
	FROM stg_inventory_raw AS i
	WHERE TRIM(i.raw_product_id) REGEXP '^PR[0-9]{5,6}$';
	
	SET v_fct_inventory_rows = (SELECT COUNT(*) FROM fct_inventory);
	
	SAVEPOINT after_inventory;
	
	-- Customers
	INSERT INTO dim_customers (customer_id, first_name, last_name, birthday, city, country, subscription_date, email)
	SELECT DISTINCT
		TRIM(cu.raw_customer_id) AS customer_id,
		NULLIF(TRIM(cu.raw_first_name), '') AS first_name,
		TRIM(cu.raw_last_name) AS last_name,
		STR_TO_DATE(TRIM(cu.raw_birthday), '%Y-%m-%d') AS birthday,
		TRIM(cu.raw_city) AS city,
		NULLIF(TRIM(cu.raw_country), '') AS country,
		STR_TO_DATE(TRIM(cu.raw_subscription_date), '%Y-%m-%d') AS subscription_date,
		NULLIF(REPLACE(REPLACE(REPLACE(cu.raw_email, ' ', ''), '.', ''), "'", ''), '') AS email
	FROM stg_customers_raw AS cu
	WHERE TRIM(cu.raw_customer_id) REGEXP '^CU[0-9]{5}$';
	
	SET v_dim_customers_rows = (SELECT COUNT(*) FROM dim_customers);
	
	SAVEPOINT after_customers;
	
	-- Workers
	INSERT INTO dim_workers (worker_id, first_name, last_name, birthday, hours_day, country, hired_date, salary_day, email)
	SELECT DISTINCT
		TRIM(wo.raw_worker_id) AS worker_id,
		NULLIF(TRIM(wo.raw_first_name), '') AS first_name,
		TRIM(wo.raw_last_name) AS last_name,
		STR_TO_DATE(TRIM(wo.raw_birthday), '%Y-%m-%d') AS birthday,
		CAST(TRIM(wo.raw_hours_day) AS UNSIGNED) AS hours_day,
		NULLIF(TRIM(wo.raw_country), '') AS country,
		STR_TO_DATE(TRIM(wo.raw_hired_date), '%Y-%m-%d') AS hired_date,
		CAST(TRIM(wo.raw_salary_day) AS UNSIGNED) AS salary_day,
		NULLIF(REPLACE(REPLACE(REPLACE(wo.raw_email, ' ', ''), '.', ''), "'", ''), '') AS email
	FROM stg_workers_raw AS wo
	WHERE TRIM(wo.raw_worker_id) REGEXP 'WO[0-9]{5}$';
	
	SET v_dim_workers_rows = (SELECT COUNT(*) FROM dim_workers);
	
	SAVEPOINT after_workers;
	
	-- Orders
	INSERT INTO fct_orders (order_id, customer_id, country, order_date, worker_id, total_paid)
	SELECT DISTINCT
		TRIM(o.raw_order_id) AS order_id,
		TRIM(o.raw_customer_id) AS customer_id,
		NULLIF(TRIM(o.raw_country), '') AS country,
		STR_TO_DATE(TRIM(o.raw_order_date), '%Y-%m-%d') AS order_date,
		TRIM(o.raw_worker_id) AS worker_id,
		CAST(TRIM(o.raw_total_paid) AS DECIMAL(10, 2)) AS total_paid
	FROM stg_orders_raw AS o
	WHERE TRIM(o.raw_order_id) REGEXP 'OR[0-9]{7}$';
	
	SET v_fct_orders_rows = (SELECT COUNT(*) FROM fct_orders);
	
	SAVEPOINT after_orders;
	
	-- Order Details
	INSERT INTO fct_order_details (detail_id, order_id, product_id, quantity, price_each, total_price)
	SELECT
		TRIM(de.raw_detail_id) AS detail_id,
		TRIM(de.raw_order_id) AS order_id,
		TRIM(de.raw_product_id) AS product_id,
		CAST(TRIM(de.raw_quantity) AS UNSIGNED) AS quantity,
		CAST(TRIM(de.raw_price_each) AS DECIMAL(5, 2)) AS price_each,
		CAST(TRIM(de.raw_total_price) AS DECIMAL(10, 2)) AS total_price
	FROM stg_order_details_raw AS de
	WHERE TRIM(de.raw_detail_id) REGEXP '^DE[0-9]{8}$';
	
	SET v_fct_order_details_rows = (SELECT COUNT(*) FROM fct_order_details);
	
	SAVEPOINT after_details;
	
	COMMIT;
	
	SELECT 
		v_dim_categories_rows AS total_categories_after_refreshment,
	 	v_dim_brands_rows AS total_brands_after_refreshment,
		v_dim_products_rows AS total_products_after_refreshment,
		v_fct_inventory_rows AS total_inventory_after_refreshment,
		v_dim_customers_rows AS total_customers_after_refreshment,
		v_dim_workers_rows AS total_workers_after_refreshment,
		v_fct_orders_rows AS total_orders_after_refreshment,
		v_fct_order_details_rows AS total_details_after_refreshment;
	
END$$

DELIMITER;
