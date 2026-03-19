from src.io import save_csv
from src.data_creation import create_product_tables, create_people_tables, create_orders_tables
from src.data_validation import full_check


def main():
    ca_data, br_data , pr_data, in_data = create_product_tables(500)
    cu_data, wo_data = create_people_tables(9000)
    or_data, de_data = create_orders_tables(500, 50000)

    print("\n--- Categories ---\n")
    full_check(ca_data, unique_columns = ['category_id', 'category'])

    print("\n--- Brands ---\n")
    full_check(br_data, unique_columns = ['brand_id', 'brand'])

    print("\n--- Products ---\n")
    full_check(pr_data, unique_columns = ['product_id'], 
               key_columns = {'fk_columns': ['product_id'], 'pk_columns': [ca_data['category_id'], br_data['brand_id']]},
               metric_columns = ['product_price'])
    
    print("\n--- Inventory ---\n")
    full_check(in_data, unique_columns = ['product_id'],
               key_columns = {'fk_columns': ['product_id'], 'pk_columns': [pr_data['product_id'], ca_data['category_id'], br_data['brand_id']]})
    
    print("\n--- Customers ---\n")
    full_check(cu_data, unique_columns = ['customer_id', 'email'],
               date_columns = ['subscription_date'])
    
    print("\n--- Workers ---\n")
    full_check(wo_data, unique_columns = ['worker_id', 'email'],
               date_columns = ['hired_date'],
               metric_columns = ['hours_day', 'salary_day'])
    
    print("\n--- Orders ---\n")
    full_check(or_data, unique_columns = ['order_id'], 
               key_columns = {'fk_columns': ['order_id'], 'pk_columns': [cu_data['customer_id'], wo_data['worker_id']]},
               date_columns = ['order_date'],
               metric_columns = ['total_paid'])
    
    print("\n--- Order Details ---\n")
    full_check(de_data, unique_columns = ['detail_id'],
               key_columns = {'fk_columns': ['detail_id'], 'pk_columns': [pr_data['product_id'], or_data['order_id']]},
               metric_columns = ['quantity', 'prices'])
    

    for df, name in zip([ca_data, br_data, pr_data, in_data, cu_data, wo_data, or_data, de_data],
                  ['ca_data', 'br_data', 'pr_data', 'in_data', 'cu_data', 'wo_data', 'or_data', 'de_data']):
        save_csv(df, f"..//data//raw_data//{name}.csv")



if __name__ == '__main__': 
    main()
