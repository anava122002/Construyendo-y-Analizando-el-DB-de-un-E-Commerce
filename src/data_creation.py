import pandas as pd
import numpy as np
from faker import Faker
from datetime import datetime, timedelta
from io import load_csv
from utils import cut_df, create_dict, create_email, next_restock, create_df, choose_worker



# ------- Building product-related data ------- #

def create_product_tables(n_prod: int):

    """
    Generates product-related tables (categories, brands, products, inventory)
    from a base dataset, ensuring consistent relationships between entities 
    (e.g., product-category, product-brand) and realistic stock distribution.
    """

    # --- Importing data

    df_products = load_csv('..//data//base_data//basket_products.csv')
    df_products = cut_df(df_products, 0, n_prod)


    # --- Dictionaries for mapping

    # Products
    products_dict = create_dict(df_products, False, 'product', 'PR')

    # Categories
    categories_dict = create_dict(df_products, False, 'category', 'CA')

    # Brands
    brands_dict = create_dict(df_products, False, 'brand', 'BR')

    # Prices
    prices_dict = create_dict(df_products, True, 'prices', 'product')

    # Ratings
    ratings_dict = create_dict(df_products, True, 'rating', 'product')

    # Product - Category
    prod_category_dict = create_dict(df_products, True, 'category', 'product')

    # Product - Brand
    prod_brand_dict = create_dict(df_products, True, 'brand', 'product')

    # Category - Stock
    category_stock_dict = dict(zip(list(categories_dict.keys()), 
     [(5000, 18000), (2000, 12000), (6000, 20000), (1000, 6000), (8000, 25000), (10000, 30000), (10000, 35000), (12000, 40000), (2000, 10000), (15000, 50000), (4000, 15000)]))


    # --- Table creation

    today = datetime.today()
    name_to_id = lambda x: {v: k for k, v in x.items()}

    # Categories DataFrame
    ca_data = create_df(categories_dict, ['category_id', 'category'])

    # Brands DataFrame
    br_data = create_df(brands_dict, ['brand_id', 'brand'])

    # Products DataFrame
    pr_data = create_df(products_dict, ['product_id', 'product'])
    pr_data['product_price'] = pr_data['product_name'].map(prices_dict) / 100
    pr_data['category_id'] = pr_data['product_name'].map(prod_category_dict).map(name_to_id(categories_dict))
    pr_data['brand_id'] = pr_data['product_name'].map(prod_brand_dict).map(name_to_id(brands_dict))
    pr_data['rating'] = pr_data['product_name'].map(ratings_dict)
    pr_data['is_active'] = np.ones(len(pr_data)).astype(int)

    # Inventory DataFrame
    in_data = create_df(products_dict, ['product_id', 'product'])
    in_data['category_id'] = in_data['product_name'].map(prod_category_dict).map(name_to_id(categories_dict))
    in_data['brand_id'] = in_data['product_name'].map(prod_brand_dict).map(name_to_id(brands_dict))
    in_data['stock'] = list(map(lambda x: np.random.randint(x[0], x[1]),
                                in_data['category_id'].map(category_stock_dict)))
    in_data['last_restock'] = in_data['stock'].map(next_restock).dt.strftime('%Y-%m-%d %H:%M:%S')

    return ca_data, br_data, pr_data, in_data 




# ------- Building people-related data ------- #

def create_people_tables(n_ppl: int):

    """
    Generates customer and worker tables using real-world-like data, enriching them 
    with demographic, geographic, and temporal attributes (e.g., country, dates, salary) 
    while maintaining logical consistency across countries.
    """


    # --- Importing data

    df_people = load_csv('..//data//base_data//nyc_marathon_results.csv')
    df_customers = df_people[0:n_ppl]
    df_workers = df_people[n_ppl : n_ppl + 500]


    # --- Dictionaries for mapping

    # Customers
    customers_dict = create_dict(df_customers, False, 'Name', 'CU')

    # Workers
    workers_dict = create_dict(df_workers, False, 'Name', 'WO')

    # City - Country
    cities_dict = {
    'London': 'UK',
    'Birmingham': 'UK',
    'Manchester': 'UK',
    'Leeds': 'UK',
    'Glasgow': 'UK',
    'Dublin': 'IR',
    'Cork': 'IR',
    'Toronto': 'CA',
    'Vancouver': 'CA',
    'Montreal': 'CA',
    'Calgary': 'CA',
    'Otawa': 'CA'
    }

    # Country - Start Date
    country_start_dict = {
    'UK': pd.to_datetime('2015-01-01 00:00:00', format = '%Y-%m-%d %H:%M:%S'),
    'IR': pd.to_datetime('2017-05-15 00:00:00', format = '%Y-%m-%d %H:%M:%S'),
    'CA': pd.to_datetime('2020-10-01 00:00:00', format = '%Y-%m-%d %H:%M:%S')
    }

    # Country - Base Salary
    base_salary_dict = {
    'UK': 12,
    'IR': 15,
    'CA': 19
    }


    # --- Table Creation

    fake = Faker()

    # Customers
    cu_data = create_df(customers_dict, ['customer_id', 'first_name'])
    cu_data['first_name'] = [name.split()[0] for name in customers_dict.values()]
    cu_data['last_name'] = [name.split()[-1] for name in customers_dict.values()]
    cu_data['birthday'] = pd.to_datetime([fake.date_between(start_date = '-80y', end_date = '-18y') for _ in range(len(customers_dict))])
    cu_data['city'] = np.random.choice(list(cities_dict.keys()), size = len(customers_dict))
    cu_data['country'] = cu_data['city'].map(cities_dict)
    cu_data['subscription_date'] = cu_data['country'].apply(
        lambda c: fake.date_between(
            start_date = country_start_dict[c] + timedelta(days = 30), 
            end_date='today'
        )
    )
    cu_data['email'] = list(map(create_email, cu_data['first_name'], cu_data['last_name'], cu_data['birthday']))

    # Workers
    wo_data = create_df(workers_dict, ['worker_id', 'first_name'])
    wo_data['first_name'] = [name.split()[0] for name in workers_dict.values()]
    wo_data['last_name'] = [name.split()[-1] for name in workers_dict.values()]
    wo_data['birthday'] = pd.to_datetime([fake.date_between(start_date = '-65y', end_date = '-18y') for _ in range(len(workers_dict))])
    wo_data['hours_day'] = np.random.randint(6, 8)
    wo_data['country'] = np.random.choice(['UK', 'IR', 'CA'], size = len(workers_dict))
    wo_data['hired_date'] = wo_data['country'].apply(
        lambda c: fake.date_between(
            start_date = country_start_dict[c],  
            end_date='today'
        )
    )
    wo_data['salary_day'] = wo_data['country'].map(base_salary_dict)
    wo_data['email'] = list(map(create_email, wo_data['first_name'], wo_data['last_name'], wo_data['birthday']))

    # Dropping duplicates
    cu_data = cu_data.drop_duplicates(subset = 'email')
    wo_data = wo_data.drop_duplicates(subset = 'email')

    
    return cu_data, wo_data 




# ------- Building orders & details data ------- #

def create_orders_tables(n_prod: int, n_ord: int):

    """
    Simulates orders and order details by linking products, customers, and workers, 
    generating realistic purchase behavior (dates, quantities, totals) and ensuring 
    referential integrity across all transactional data.
    """

    # --- Importing data
    ca_data, br_data , pr_data, in_data = create_product_tables(n_prod)
    cu_data, wo_data = create_people_tables(9000)


    # --- Dictionaries for mapping
    n_details = np.random.randint(3, 15, size = n_ord)

    # Person - Country
    customer_country_dict = create_dict(cu_data, True, 'country', 'customer_id')
    worker_country_dict = wo_data.groupby('country')['worker_id'].apply(list).to_dict()

    # Person - Date
    customer_date_dict = create_dict(cu_data, True, 'subscription_date', 'customer_id')
    worker_date_dict = create_dict(wo_data, True, 'hired_date', 'customer_id')

    # Stock 
    stock_dict = create_dict(in_data, True, 'stock', 'product_id')

    # Product ID - Price
    prices_with_id_dict = create_dict(pr_data, True, 'product_price', 'product_id')


    # --- Table Creation

    fake = Faker()

    # Orders
    or_data = pd.DataFrame({})
    or_data['order_id'] = [f"OR{i:07d}" for i in range(1, n_ord + 1)]
    or_data['customer_id'] = np.random.choice(cu_data['customer_id'], size = n_ord)
    or_data['country'] = or_data['customer_id'].map(customer_country_dict)
    or_data['order_date'] = or_data['customer_id'].apply(
        lambda c: fake.date_between(
            start_date = customer_date_dict[c],  
            end_date='today'
        )
    )
    or_data['worker_id'] = choose_worker(or_data)

    # Order Details
    de_data = pd.DataFrame({})
    de_data['detail_id'] = [f"DE{i:08d}" for i in range(1, sum(n_details) + 1)]
    de_data['order_id'] = np.repeat(or_data['order_id'], n_details)
    de_data['product_id'] = np.random.choice(pr_data['product_id'], size = sum(n_details))

    stock = de_data['product_id'].map(stock_dict)

    de_data['quantity'] = [np.random.randint(max(1, int(i * 0.0001)), max(3, int(i * 0.0002))) for i in stock]
    de_data['price_each'] = de_data['product_id'].map(prices_with_id_dict)
    de_data['total_price'] = de_data['quantity'] * de_data['price_each']

    or_data['total_paid'] = or_data['order_id'].map(
        de_data.groupby('order_id')['total_price'].sum()
    )


    return or_data, de_data 


