/* ============================================================
   SQL PROJECT - Online Supermarket Dataset
   FILE 5 - 05_semantic_views.sql
   ============================================================ */


USE sql_project;


/* ----------- Enrichment Views ----------- */

-- Products enrichment
CREATE OR REPLACE VIEW vw_products_enriched AS
SELECT
	pr.product_id, 
	pr.product_name,
	pr.product_price,
	pr.category_id,
	ca.category,
	pr.brand_id,
	br.brand,
	i.stock,
	i.last_restock,
	pr.rating,
	pr.is_active,
	COALESCE(SUM(de.quantity), 0) AS total_purchases,
	COALESCE(SUM(de.total_price), 0) AS total_revenue
FROM dim_products AS pr
LEFT JOIN dim_categories AS ca
	ON pr.category_id = ca.category_id
LEFT JOIN dim_brands AS br
	ON pr.brand_id = br.brand_id
LEFT JOIN fct_inventory AS i
	ON pr.product_id = i.product_id
LEFT JOIN fct_order_details AS de
	ON pr.product_id = de.product_id
GROUP BY pr.product_id;

-- Customers enrichment
CREATE OR REPLACE VIEW vw_customers_enriched AS
SELECT 
	cu.customer_id,
	CONCAT(cu.first_name, ' ', cu.last_name) AS full_name,
	cu.birthday,
	TIMESTAMPDIFF(YEAR, cu.birthday, CURDATE()) AS age,
	cu.subscription_date,
	cu.city,
	cu.country,
	cu.email,
	COUNT(o.order_id) AS total_purchases,
	SUM(o.total_paid) AS total_spent,
	SUM(de.quantity) AS total_products_purchased
FROM dim_customers AS cu
LEFT JOIN fct_orders AS o
	ON cu.customer_id = o.customer_id
JOIN fct_order_details AS de
	ON o.order_id = de.order_id
GROUP BY cu.customer_id;

-- Workers enrichment
CREATE OR REPLACE VIEW vw_workers_enriched AS
SELECT
	wo.worker_id,
	CONCAT(wo.first_name, ' ', wo.last_name) AS full_name,
	wo.birthday,
	TIMESTAMPDIFF(YEAR, wo.birthday, CURDATE()) AS age,
	wo.hired_date,
	wo.country,
	wo.hours_day,
	wo.salary_day,
	wo.hours_day * salary_day * 21 AS salary,
	wo.email,
	COUNT(o.order_id) AS purchases_prepared
FROM dim_workers AS wo
LEFT JOIN fct_orders AS o
	ON wo.worker_id = o.worker_id
GROUP BY wo.worker_id;

	
	
/* ----------------- KPIs ----------------- */	

-- Countries KPI
CREATE OR REPLACE VIEW vw_countries_kpi AS
SELECT 
	o.country,
	o.year,
	SUM(total_customers) OVER (PARTITION BY o.country ORDER BY o.year) AS total_customers,
	SUM(total_workers) OVER (PARTITION BY o.country ORDER BY o.year) AS total_workers,
	total_orders,
	total_products_purchased,
	total_revenue,
	ROUND(total_orders / total_customers, 2) AS avg_orders_per_customer,
	ROUND(total_products_purchased / total_orders, 2) AS avg_products_per_order,
	ROUND(total_revenue / total_orders, 2) AS avg_revenue_per_order
FROM (	
	SELECT
		o.country,
		YEAR(o.order_date) AS year,
		COUNT(o.order_id) AS total_orders,
		SUM(de.quantity) AS total_products_purchased,
		SUM(o.total_paid) AS total_revenue
	FROM fct_orders AS o
	LEFT JOIN fct_order_details AS de
		ON o.order_id = de.order_id
	GROUP BY country, year
) AS o
JOIN (
	SELECT 
		country,
		YEAR(subscription_date) AS year,
		COUNT(customer_id) AS total_customers
	FROM dim_customers
	GROUP BY country, year
) AS cu ON o.country = cu.country AND o.year = cu.year
JOIN(
	SELECT 
		country,
		YEAR(hired_date) AS year,
		COUNT(worker_id) AS total_workers
	FROM dim_workers
	GROUP BY country, year
) AS wo ON o.country = wo.country AND o.year = wo.year
GROUP BY o.country, o.year
ORDER BY o.country DESC, year ASC;

-- Categories KPI
CREATE OR REPLACE VIEW vw_categories_kpi AS
SELECT
	ca.category_id,
	ca.category,
	COUNT(DISTINCT pr.product_id) AS total_products,
	ROUND(AVG(pr.product_price), 2)  AS avg_price,
	ROUND(AVG(i.stock), 0) AS avg_stock,
	SUM(de.quantity) AS total_products_purchased,
	SUM(de.total_price) AS total_revenue
FROM dim_categories AS ca
LEFT JOIN dim_products AS pr
	ON ca.category_id = pr.category_id
JOIN fct_inventory AS i
	ON pr.product_id = i.product_id
JOIN fct_order_details AS de
	ON pr.product_id = de.product_id
GROUP BY ca.category_id
ORDER BY ca.category_id ASC;

-- Brands KPI 
CREATE OR REPLACE VIEW vw_brands_kpi AS
SELECT
	br.brand_id,
	br.brand,
	COUNT(DISTINCT pr.product_id) AS total_products,
	ROUND(AVG(pr.product_price), 2)  AS avg_price,
	ROUND(AVG(i.stock), 0) AS avg_stock,
	SUM(de.quantity) AS total_products_purchased,
	SUM(de.total_price) AS total_revenue
FROM dim_brands AS br
LEFT JOIN dim_products AS pr
	ON br.brand_id = pr.brand_id
JOIN fct_inventory AS i
	ON pr.product_id = i.product_id
JOIN fct_order_details AS de
	ON pr.product_id = de.product_id
GROUP BY br.brand_id
ORDER BY br.brand_id ASC;







