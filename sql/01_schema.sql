/* ============================================================
   SQL PROJECT - Online Supermarket Dataset
   FILE 1 - 01_schema.sql
   ============================================================ */


/* -------------- DB creation -------------- */

CREATE DATABASE IF NOT EXISTS sql_project;
USE sql_project;



/* ---------------- Staging ---------------- */

DROP TABLE IF EXISTS stg_categories_raw;
DROP TABLE IF EXISTS stg_brands_raw;
DROP TABLE IF EXISTS stg_products_raw;
DROP TABLE IF EXISTS stg_inventory_raw;
DROP TABLE IF EXISTS stg_customers_raw;
DROP TABLE IF EXISTS stg_workers_raw;
DROP TABLE IF EXISTS stg_orders_raw;
DROP TABLE IF EXISTS stg_order_details_raw;


CREATE TABLE stg_categories_raw(
	raw_category_id VARCHAR(10),
	raw_category VARCHAR(100)
);

CREATE TABLE stg_brands_raw(
	raw_brand_id VARCHAR(10),
	raw_brand VARCHAR(100)
);

CREATE TABLE stg_products_raw(
	raw_product_id VARCHAR(10),
	raw_product_name VARCHAR(150),
	raw_product_price VARCHAR(100),
	raw_category_id VARCHAR(10),
	raw_brand_id VARCHAR(10),
	raw_rating VARCHAR(10),
	raw_is_active VARCHAR(10)
);

CREATE TABLE stg_inventory_raw(
	raw_product_id VARCHAR(10),
	raw_product_name VARCHAR(150),
	raw_category_id VARCHAR(10),
	raw_brand_id VARCHAR(10),
	raw_stock VARCHAR(15),
	raw_last_restock TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE stg_customers_raw(
	raw_customer_id VARCHAR(100),
	raw_first_name VARCHAR(100),
	raw_last_name VARCHAR(100),
	raw_birthday DATE,
	raw_city VARCHAR(100),
	raw_country VARCHAR(5),
	raw_subscription_date DATE,
	raw_email VARCHAR(100)
);

CREATE TABLE stg_workers_raw(
	raw_worker_id VARCHAR(10),
	raw_first_name VARCHAR(20),
	raw_last_name VARCHAR(20),
	raw_birthday DATE,
	raw_hours_day VARCHAR(5),
	raw_country VARCHAR(5),
	raw_hired_date DATE,
	raw_salary_day VARCHAR(5),
	raw_email VARCHAR(100)
);

CREATE TABLE stg_orders_raw(
	raw_order_id VARCHAR(15),
	raw_customer_id VARCHAR(10),
	raw_country VARCHAR(5),
	raw_order_date DATE,
	raw_worker_id VARCHAR(10),
	raw_total_paid VARCHAR(100)
);

CREATE TABLE stg_order_details_raw(
	raw_detail_id VARCHAR(15),
	raw_order_id VARCHAR(15), 
	raw_product_id VARCHAR(10),
	raw_quantity VARCHAR(5),
	raw_price_each VARCHAR(50),
	raw_total_price VARCHAR(100)
);


/* ------------------ Core ------------------ */

DROP TABLE IF EXISTS dim_categories;
DROP TABLE IF EXISTS dim_brands;
DROP TABLE IF EXISTS dim_products;
DROP TABLE IF EXISTS fct_inventory;
DROP TABLE IF EXISTS dim_customers;
DROP TABLE IF EXISTS dim_workers;
DROP TABLE IF EXISTS fct_orders;
DROP TABLE IF EXISTS fct_order_details;


CREATE TABLE dim_categories(
	category_id VARCHAR(10) PRIMARY KEY,
	category VARCHAR(100) NOT NULL
);

CREATE TABLE dim_brands(
	brand_id VARCHAR(10) PRIMARY KEY,
	brand VARCHAR(100) NOT NULL
);

CREATE TABLE dim_products(
	product_id VARCHAR(10) PRIMARY KEY,
	product_name VARCHAR(150) NOT NULL,
	product_price DECIMAL(5, 2) NOT NULL,
	category_id VARCHAR(10),
	brand_id VARCHAR(10),
	rating DECIMAL(3, 2),
	is_active INT NOT NULL,
	FOREIGN KEY (category_id) REFERENCES dim_categories(category_id),
	FOREIGN KEY (brand_id) REFERENCES dim_brands(brand_id)
);

CREATE TABLE fct_inventory(
	product_id VARCHAR(10) PRIMARY KEY,
	product_name VARCHAR(150) NOT NULL,
	category_id VARCHAR(10),
	brand_id VARCHAR(10),
	stock BIGINT NOT NULL,
	last_restock TIMESTAMP,
	FOREIGN KEY (product_id) REFERENCES dim_products(product_id),
	FOREIGN KEY (category_id) REFERENCES dim_categories(category_id),
	FOREIGN KEY (brand_id) REFERENCES dim_brands(brand_id)
);

CREATE TABLE dim_customers(
	customer_id VARCHAR(10) PRIMARY KEY,
	first_name VARCHAR(100) NOT NULL,
	last_name VARCHAR(100),
	birthday DATE,
	city VARCHAR(20),
	country VARCHAR(5) NOT NULL,
	subscription_date DATE,
	email VARCHAR(50) NOT NULL
);

CREATE TABLE dim_workers(
	worker_id VARCHAR(10) PRIMARY KEY,
	first_name VARCHAR(100) NOT NULL,
	last_name VARCHAR(100),
	birthday DATE,
	hours_day VARCHAR(5) NOT NULL,
	country VARCHAR(5) NOT NULL,
	hired_date DATE,
	salary_day DECIMAL(5, 2) NOT NULL,
	email VARCHAR(50) NOT NULL
);

CREATE TABLE fct_orders(
	order_id VARCHAR(15) PRIMARY KEY,
	customer_id VARCHAR(10),
	country VARCHAR(5) NOT NULL,
	order_date DATE,
	worker_id VARCHAR(10),
	total_paid DECIMAL(10, 2) NOT NULL,
	FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id),
	FOREIGN KEY (worker_id) REFERENCES dim_workers(worker_id)
);

CREATE TABLE fct_order_details(
	detail_id VARCHAR(15) PRIMARY KEY,
	order_id VARCHAR(15), 
	product_id VARCHAR(10),
	quantity INT NOT NULL,
	price_each DECIMAL(5, 2) NOT NULL,
	total_price DECIMAL(10, 2) NOT NULL,
	FOREIGN KEY (order_id) REFERENCES fct_orders(order_id), 
	FOREIGN KEY (product_id) REFERENCES dim_products(product_id)
);

