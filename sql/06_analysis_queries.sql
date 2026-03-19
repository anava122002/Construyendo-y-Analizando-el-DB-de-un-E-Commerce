/* ============================================================
   SQL PROJECT - Online Supermarket Dataset
   FILE 6 - 06_analysis_queries.sql
   ============================================================ */


USE sql_project;


/* ----------- Ventas por país. Evolución y comportamiento ----------- */

-- Ventas generales
SELECT
	SUM(total_orders) AS total_orders,
	SUM(total_products_purchased) AS total_products_purchased,
	SUM(total_revenue) AS total_revenue,
	ROUND(SUM(total_revenue) / SUM(total_orders), 2) AS avg_revenue
FROM vw_countries_kpi;

-- ¿Qué países generan mayor volumen de ventas? ¿Cuál es su contribución al total?
SELECT 
	country,
	SUM(total_orders) AS total_orders,
	SUM(total_products_purchased) AS total_products_purchased,
	SUM(total_revenue) AS total_revenue,
	ROUND(SUM(total_orders) / SUM(SUM(total_orders)) OVER() * 100, 2) AS orders_pct
FROM vw_countries_kpi
GROUP BY country;

-- Teniendo en cuenta el año de inicio de las ventas en cada país, 
-- ¿cuál ha sido la ganancia media por año?
-- (UK: 2015; IR: 2017; CA: 2020)
SELECT
	country,
	MIN(year) AS first_year,
	MAX(year) AS current_year,
	ROUND(AVG(total_orders)) AS avg_orders,
	ROUND(AVG(total_revenue), 2) AS avg_revenue
FROM vw_countries_kpi
GROUP BY country
ORDER BY country DESC;

-- ¿Existen diferencias en el valor medio de los pedidos entre países?
SELECT
	country,
	MIN(avg_revenue_per_order) AS min_avg,
	MAX(avg_revenue_per_order) AS max_avg,
	ROUND(SUM(total_revenue) / SUM(total_orders), 2) AS avg_revenue_per_order,
	ROUND(STDDEV(avg_revenue_per_order), 2) AS variability
FROM vw_countries_kpi
GROUP BY country;



/* ----------- Productos por país. Aceptación del producto y consumo ----------- */

-- Productos más populares
SELECT 
	product_id, 
	product_name,
	product_price,
	total_purchases,
	total_revenue,
	rating
FROM vw_products_enriched
WHERE is_active = 1
ORDER BY total_purchases DESC
LIMIT 5;

-- ¿Qué categorías generan más ingresos? ¿Y marcas?
SELECT 
	ca.category_id,
	ca.category,
	ca.total_products_purchased,
	ca.total_revenue,
	MAX(pr.product_price) AS max_price,
	MIN(pr.product_price) AS min_price,
	ca.avg_price,
	ROUND(AVG(pr.rating), 2) AS avg_rating
FROM vw_categories_kpi AS ca
LEFT JOIN dim_products AS pr
	ON ca.category_id = pr.category_id
WHERE pr.is_active = 1
GROUP BY category_id
ORDER BY total_products_purchased DESC, total_revenue DESC;

SELECT 
	br.brand_id,
	br.brand,
	br.total_products_purchased,
	br.total_revenue,
	MAX(pr.product_price) AS max_price,
	MIN(pr.product_price) AS min_price,
	br.avg_price,
	ROUND(AVG(pr.rating), 2) AS avg_rating
FROM vw_brands_kpi AS br
LEFT JOIN dim_products AS pr
	ON br.brand_id = pr.brand_id
WHERE pr.is_active = 1
GROUP BY brand_id
ORDER BY total_products_purchased DESC, total_revenue DESC
LIMIT 5;

-- ¿Cambian las preferencias/popularidad de los productos según el país?
SELECT *
FROM (
	SELECT
		o.country,
		de.product_id,
		pr.product_name,
		pr.product_price,
		SUM(de.quantity) AS total_purchases,
		SUM(de.total_price) AS total_revenue,
		ROW_NUMBER() OVER (PARTITION BY o.country ORDER BY SUM(de.quantity) DESC) AS rn
	FROM fct_order_details AS de
	LEFT JOIN fct_orders AS o
		ON de.order_id = o.order_id
	LEFT JOIN dim_products AS pr
		ON de.product_id = pr.product_id
	GROUP BY o.country, de.product_id
) AS ranking
WHERE rn <= 5
ORDER BY country DESC, rn ASC;



/* ----------- Factor humano. Clientes y trabajadores ----------- */

-- Descripción general de los clientes por ciudad
SELECT 
	country,
	city,
	COUNT(city) AS total_customers_in_city,
	MIN(age) AS younger_customer,
	MAX(age) AS oldest_customer,
	ROUND(AVG(age), 0) AS avg_age,
	ROUND(AVG(YEAR(subscription_date))) AS avg_year_subscription,
	ROUND(AVG(total_purchases), 0) AS avg_purchases,
	SUM(total_purchases) AS total_purchases,
	ROUND(AVG(total_spent), 2) AS avg_spent,
	SUM(total_spent) AS total_spent
FROM vw_customers_enriched
GROUP BY country, city
ORDER BY country DESC, total_customers_in_city DESC;

-- ¿Cuál es la frecuencia de compra de los clientes?
SELECT
	country,
	MIN(days_between_orders) AS min_days_passed,
	MAX(days_between_orders) AS max_days_passed,
	ROUND(AVG(days_between_orders), 0) AS days_between_orders
FROM (
	SELECT
		country,
		order_date,
		LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS previous_order_date,
		DATEDIFF(order_date, LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)) AS days_between_orders
	FROM fct_orders
) AS dates
GROUP BY country
ORDER BY country DESC;

-- ¿Existen clientes con alto volumen de pedidos? (avg_purchase: 47 a 49)
SELECT
	customer_id,
	full_name,
	age,
	country,
	subscription_date,
	total_purchases,
	total_products_purchased,
	total_spent
FROM vw_customers_enriched
ORDER BY total_purchases DESC, total_spent DESC
LIMIT 10;

-- ¿Existen trabajadores con mayor carga de actividad?
SELECT 
	worker_id, 
	full_name,
	age,
	hired_date,
	country,
	salary,
	purchases_prepared,
	CASE
		WHEN 2026 - YEAR(hired_date) <= 0 THEN 0
		ELSE ROUND(purchases_prepared / (2026 - YEAR(hired_date)), 0)
	END AS purchases_per_year
FROM vw_workers_enriched
-- WHERE YEAR(hired_date) < 2024
ORDER BY purchases_per_year DESC
LIMIT 10;
