/* ============================================================
   SQL PROJECT - Online Supermarket Dataset
   FILE 2 - 02_load_staging.sql
   ============================================================ */


/* -------- Selection DB & Importing Data  -------- */

USE sql_project;

-- Importing data with Wizard...



/* ----------------- Volume Check ----------------- */

SELECT 'Categories' AS table_name, COUNT(*) AS n_rows FROM stg_categories_raw
UNION ALL
SELECT 'Brands' AS table_name, COUNT(*) AS n_rows FROM stg_brands_raw
UNION ALL
SELECT 'Products' AS table_name, COUNT(raw_product_id) AS n_rows FROM stg_products_raw
UNION ALL
SELECT 'Inventory' AS table_name, COUNT(raw_product_id) AS n_rows FROM stg_inventory_raw
UNION ALL
SELECT 'Customers' AS table_name, COUNT(raw_customer_id) AS n_rows FROM stg_customers_raw
UNION ALL
SELECT 'Workers' AS table_name, COUNT(raw_worker_id) AS n_rows FROM stg_workers_raw
UNION ALL
SELECT 'Orders' AS table_name, COUNT(raw_order_id) AS n_rows FROM stg_orders_raw
UNION ALL
SELECT 'Details' AS table_name, COUNT(raw_detail_id) AS n_rows FROM stg_order_details_raw;



/* ----------------- First 5 Rows ----------------- */

SELECT * FROM stg_categories_raw LIMIT 5;
SELECT * FROM stg_brands_raw LIMIT 5;
SELECT * FROM stg_products_raw LIMIT 5;
SELECT * FROM stg_inventory_raw LIMIT 5;
SELECT * FROM stg_customers_raw LIMIT 5;
SELECT * FROM stg_workers_raw LIMIT 5;
SELECT * FROM stg_orders_raw LIMIT 5;
SELECT * FROM stg_order_details_raw LIMIT 5;



/* ----------------- Parsability Check ----------------- */

-- Categories
SELECT 
	SUM(CASE WHEN raw_category_id NOT REGEXP '^CA[0-9]{5}$' THEN 1 ELSE 0 END) AS bad_category_ids
FROM stg_categories_raw;

-- Brands
SELECT 
	SUM(CASE WHEN raw_brand_id NOT REGEXP '^BR[0-9]{5}$' THEN 1 ELSE 0 END) AS bad_brand_ids
FROM stg_brands_raw;

-- Products
SELECT
	SUM(CASE WHEN raw_product_id NOT REGEXP '^PR[0-9]{5}$' THEN 1 ELSE 0 END) AS bad_product_ids,
	SUM(CASE WHEN raw_category_id NOT REGEXP '^CA[0-9]{5}$' THEN 1 ELSE 0 END) AS bad_category_ids,
	SUM(CASE WHEN raw_brand_id NOT REGEXP '^BR[0-9]{5}$' THEN 1 ELSE 0 END) AS bad_brand_ids,
	SUM(CASE WHEN raw_product_price NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$' THEN 1 ELSE 0 END) AS bad_product_prices,
	SUM(CASE WHEN (raw_rating NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$') AND (raw_rating IS NULL) THEN 1 ELSE 0 END) AS bad_ratings,
	SUM(CASE WHEN raw_is_active NOT IN ('0', '1') THEN 1 ELSE 0 END) AS bad_product_ids
FROM stg_products_raw;

-- Inventory
SELECT
	SUM(CASE WHEN raw_product_id NOT REGEXP '^PR[0-9]{5}$' THEN 1 ELSE 0 END) AS bad_product_ids,
	SUM(CASE WHEN raw_category_id NOT REGEXP '^CA[0-9]{5}$' THEN 1 ELSE 0 END) AS bad_category_ids,
	SUM(CASE WHEN raw_brand_id NOT REGEXP '^BR[0-9]{5}$' THEN 1 ELSE 0 END) AS bad_brand_ids,
	SUM(CASE WHEN raw_stock NOT REGEXP '[0-9]' THEN 1 ELSE 0 END) AS bad_stock_nums,
	SUM(CASE WHEN STR_TO_DATE(raw_last_restock, '%Y-%m-%d %H:%i:%s') IS NULL THEN 1 ELSE 0 END) AS bad_restock_dates
FROM stg_inventory_raw;

-- Customers
SELECT
	SUM(CASE WHEN raw_customer_id NOT REGEXP 'CU[0-9]{5,6}' THEN 1 ELSE 0 END) AS bad_customer_ids,
	SUM(CASE WHEN STR_TO_DATE(raw_birthday, '%Y-%m-%d') IS NULL THEN 1 ELSE 0 END) AS bad_birthdays,
	SUM(CASE WHEN STR_TO_DATE(raw_subscription_date, '%Y-%m-%d') IS NULL THEN 1 ELSE 0 END) AS bad_subscriptions
FROM stg_customers_raw;

-- Workers
SELECT
	SUM(CASE WHEN raw_worker_id NOT REGEXP '^WO[0-9]{5}$' THEN 1 ELSE 0 END) AS bad_worker_ids,
	SUM(CASE WHEN STR_TO_DATE(raw_birthday, '%Y-%m-%d') IS NULL THEN 1 ELSE 0 END) AS bad_birthdays,
	SUM(CASE WHEN raw_hours_day NOT REGEXP '^[0-9]$' THEN 1 ELSE 0 END) AS bad_hours,
	SUM(CASE WHEN STR_TO_DATE(raw_hired_date, '%Y-%m-%d') IS NULL THEN 1 ELSE 0 END) AS bad_hire_dates,
	SUM(CASE WHEN (raw_salary_day NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$') THEN 1 ELSE 0 END) AS bad_salaries
FROM stg_workers_raw;

-- Orders
SELECT
	SUM(CASE WHEN raw_order_id NOT REGEXP '^OR[0-9]{7}$' THEN 1 ELSE 0 END) AS bad_order_ids,
	SUM(CASE WHEN raw_customer_id NOT REGEXP '^CU[0-9]{5,6}$' THEN 1 ELSE 0 END) AS bad_customer_ids,
	SUM(CASE WHEN STR_TO_DATE(raw_order_date, '%Y-%m-%d') IS NULL THEN 1 ELSE 0 END) AS bad_order_dates,
	SUM(CASE WHEN raw_worker_id NOT REGEXP '^WO[0-9]{5}$' THEN 1 ELSE 0 END) AS bad_worker_ids,
	SUM(CASE WHEN (raw_total_paid NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$') THEN 1 ELSE 0 END) AS bad_totals
FROM stg_orders_raw;

-- Order Details
SELECT
	SUM(CASE WHEN raw_detail_id NOT REGEXP '^DE[0-9]{8}$' THEN 1 ELSE 0 END) AS bad_detail_ids,
	SUM(CASE WHEN raw_order_id NOT REGEXP '^OR[0-9]{7}$' THEN 1 ELSE 0 END) AS bad_order_ids,
	SUM(CASE WHEN raw_product_id NOT REGEXP '^PR[0-9]{5}$' THEN 1 ELSE 0 END) AS bad_product_ids,
	SUM(CASE WHEN raw_quantity NOT REGEXP '^[0-9]$' THEN 1 ELSE 0 END) AS bad_quantities,
	SUM(CASE WHEN (raw_price_each NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$') THEN 1 ELSE 0 END) AS bad_prices,
	SUM(CASE WHEN (raw_total_price NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$') THEN 1 ELSE 0 END) AS bad_totals
FROM stg_order_details_raw;


