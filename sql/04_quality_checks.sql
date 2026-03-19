/* ============================================================
   SQL PROJECT - Online Supermarket Dataset
   FILE 4 - 04_quality_checks.sql
   ============================================================ */


USE sql_project;


/* ------------- Null values ------------- */

-- Categories and Brands
SELECT
	'Categories' AS dimension,
	SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS null_names
FROM dim_categories
UNION ALL
SELECT 
	'Brands' AS dimension,
	SUM(CASE WHEN brand IS NULL THEN 1 ELSE 0 END) AS null_names
FROM dim_brands;

-- Products
SELECT 
	SUM(CASE WHEN product_price IS NULL THEN 1 ELSE 0 END) AS null_price,
	SUM(CASE WHEN category_id IS NULL THEN 1 ELSE 0 END) AS null_category,
	SUM(CASE WHEN brand_id IS NULL THEN 1 ELSE 0 END) AS null_brand
FROM dim_products;
-- 1 brand with null FK. This issue will be fixed later.

-- Inventory
SELECT
	SUM(CASE WHEN category_id IS NULL THEN 1 ELSE 0 END) AS null_category,
	SUM(CASE WHEN brand_id IS NULL THEN 1 ELSE 0 END) AS null_brand,
	SUM(CASE WHEN stock IS NULL THEN 1 ELSE 0 END) AS null_stock
FROM fct_inventory;
-- 1 brand with null FK. This issue will be fixed later.

-- Customers
SELECT
	SUM(CASE WHEN (first_name IS NULL) AND (last_name IS NULL) THEN 1 ELSE 0 END) AS null_full_name,
	SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS null_country,
	SUM(CASE WHEN subscription_date IS NULL THEN 1 ELSE 0 END) AS null_subscription_date
FROM dim_customers;

-- Workers
SELECT
	SUM(CASE WHEN (first_name IS NULL) AND (last_name IS NULL) THEN 1 ELSE 0 END) AS null_full_name,
	SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS null_country,
	SUM(CASE WHEN hired_date IS NULL THEN 1 ELSE 0 END) AS null_hired_date,
	SUM(CASE WHEN hours_day IS NULL THEN 1 ELSE 0 END) AS null_hours,
	SUM(CASE WHEN salary_day IS NULL THEN 1 ELSE 0 END) AS null_salary
FROM dim_workers;

-- Orders
SELECT 
	SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer,
	SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS null_country,
	SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS null_order_date,
	SUM(CASE WHEN total_paid IS NULL THEN 1 ELSE 0 END) AS null_amount
FROM fct_orders;

-- Order Details
SELECT
	SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order,
	SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product,
	SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS null_quantity,
	SUM(CASE WHEN price_each IS NULL THEN 1 ELSE 0 END) AS null_price
FROM fct_order_details;



/* ------------- Orphan FK ------------- */

-- Products
SELECT COUNT(*) AS orphan_category
FROM dim_products AS pr
LEFT JOIN dim_categories AS ca
	ON pr.category_id = ca.category_id
WHERE ca.category_id IS NULL;

SELECT COUNT(*) AS orphan_brand
FROM dim_products AS pr
LEFT JOIN dim_brands AS br
	ON pr.brand_id = br.brand_id
WHERE br.brand_id IS NULL;

-- Checking for missing brand
SELECT product_id, product_name, product_price, category_id FROM dim_products AS pr LEFT JOIN dim_brands AS br ON pr.brand_id = br.brand_id WHERE br.brand_id IS NULL;
-- Product (Food Package - Medium) with missing brand has product_id equal to 'PR09116' and category_id 'CA00003'. 
-- basket_products.csv does not contain any brand name for this product.
-- Changing id and name to 'UNKNOWN'

START TRANSACTION;

INSERT INTO dim_brands (brand_id, brand)
VALUES ('BR00000', 'UNKNOWN');

SAVEPOINT inventory_update;

UPDATE dim_products
SET brand_id = 'BR00000'
WHERE brand_id IS NULL
	AND product_id = 'PR09116'
	AND category_id = 'CA00003';

SAVEPOINT products_update;

UPDATE fct_inventory
SET brand_id = 'BR00000'
WHERE brand_id IS NULL
	AND product_id = 'PR09116'
	AND category_id = 'CA00003';

COMMIT;

-- Inventory 
SELECT COUNT(*) AS orphan_product
FROM fct_inventory AS i
LEFT JOIN dim_products AS pr
	ON i.product_id = pr.product_id
WHERE pr.product_id IS NULL;

SELECT COUNT(*) AS orphan_category
FROM fct_inventory AS i
LEFT JOIN dim_categories AS ca
	ON i.category_id = ca.category_id
WHERE ca.category_id IS NULL;

SELECT COUNT(*) AS orphan_brand
FROM fct_inventory AS i
LEFT JOIN dim_brands AS br
	ON i.brand_id = br.brand_id
WHERE br.brand_id IS NULL;

-- Orders
SELECT COUNT(*) AS orphan_customer
FROM fct_orders AS o
LEFT JOIN dim_customers AS cu
	ON o.customer_id = cu.customer_id
WHERE cu.customer_id IS NULL;

SELECT COUNT(*) AS orphan_worker
FROM fct_orders AS o
LEFT JOIN dim_workers AS wo
	ON o.worker_id = wo.worker_id
WHERE wo.worker_id IS NULL;

-- Order Details
SELECT COUNT(*) AS orphan_order
FROM fct_order_details AS de
LEFT JOIN fct_orders AS o
	ON de.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS orphan_product
FROM fct_order_details AS de
LEFT JOIN dim_products AS pr
	ON de.product_id = pr.product_id
WHERE pr.product_id IS NULL;


	
/* ------------- Duplicates ------------- */

-- Inventory
SELECT
	product_id,
	product_name,
	category_id,
	brand_id,
	COUNT(*) AS row_copies
FROM fct_inventory
GROUP BY product_id, product_name, category_id, brand_id, stock, last_restock
HAVING row_copies > 1
ORDER BY row_copies DESC;

-- Orders
SELECT
	order_id,
	customer_id, 
	order_date,
	worker_id,
	COUNT(*) AS row_copies
FROM fct_orders 
GROUP BY order_id, customer_id, order_date, worker_id
HAVING row_copies > 1
ORDER BY row_copies DESC;

-- Order Details
SELECT
	detail_id,
	order_id,
	product_id, 
	quantity,
	COUNT(*) AS row_copies
FROM fct_order_details 
GROUP BY detail_id, order_id, product_id, quantity
HAVING row_copies > 1
ORDER BY row_copies DESC;



/* ------------- Date Ranges ------------- */

-- Subscription dates by country (firsts should be 2015, 2017, 2020)
SELECT 
	country,
	MIN(subscription_date) AS first_suscription,
	MAX(subscription_date) AS last_suscription
FROM dim_customers
GROUP BY country
ORDER BY country DESC;

-- Workers hired by country (firsts should be 2015, 2017, 2020 and before first customer)
SELECT
	country,
	MIN(hired_date) AS first_hired,
	MAX(hired_date) AS last_hired
FROM dim_workers
GROUP BY country
ORDER BY country DESC;

-- Orders by country
SELECT
	country,
	MIN(order_date) AS first_order,
	MAX(order_date) AS last_order
FROM fct_orders
GROUP BY country
ORDER BY country DESC;



/* ------------- Wrong Metrics ------------- */

SELECT
	SUM(CASE WHEN product_price <= 0 THEN 1 ELSE 0 END) AS bad_price,
	SUM(CASE WHEN rating < 0 THEN 1 ELSE 0 END) AS bad_rating,
	SUM(CASE WHEN is_active NOT IN (0, 1) THEN 1 ELSE 0 END) AS bad_status
FROM dim_products;

SELECT
	SUM(CASE WHEN stock < 0 THEN 1 ELSE 0 END) AS bad_stock
FROM fct_inventory;

SELECT
	SUM(CASE WHEN total_paid <= 0 THEN 1 ELSE 0 END) AS bad_total
FROM fct_orders;

SELECT
	SUM(CASE WHEN quantity <= 0 THEN 1 ELSE 0 END) AS bad_quantity,
	SUM(CASE WHEN price_each <= 0 THEN 1 ELSE 0 END) AS bad_price,
	SUM(CASE WHEN total_price <= 0 THEN 1 ELSE 0 END) AS bad_total
FROM fct_order_details;



/* ------------- Wrong Countries ------------- */

SELECT
	SUM(CASE WHEN country NOT IN ('UK', 'IR', 'CA') THEN 1 ELSE 0 END) AS bad_country
FROM dim_customers;

SELECT 
	SUM(CASE WHEN country NOT IN ('UK', 'IR', 'CA') THEN 1 ELSE 0 END) AS bad_country
FROM dim_workers;

SELECT
	SUM(CASE WHEN country NOT IN ('UK', 'IR', 'CA') THEN 1 ELSE 0 END) AS bad_country
FROM fct_orders;
