import numpy as np
import pandas as pd
from faker import Faker
from datetime import datetime, timedelta



# ------- Basic exploration ------- #

def quality_check(data: pd.DataFrame):

    """
    Basic Quality Check. Returns DataFrame with columns, types 
    and unique, missing and duplicate elements plus their ratios.
    Complement/extension of .info() function.
    """

    n = len(data)

    summary = []
    for column in data:
        col_type = type(data[column].iloc[0])
        elements = data[column].count()
        unique = data[column].nunique(dropna = True)
        rate_unique = round(unique / n * 100, 2)
        missing = data[column].isna().sum() 
        rate_missing = round(missing / n * 100, 2)
        duplicated = data[column].duplicated().sum()
        
        summary.append((column, col_type, elements, unique, rate_unique, missing, rate_missing, duplicated))
    
    return pd.DataFrame(summary, columns = ['column', 'type', 'elements', 'unique', 'rate_unique', 'missing', 'rate_missing', 'duplicated'])



# ------- Sanity Checks ------- #

def check_duplicates(data: pd.DataFrame, unique_columns: list):

    """
    Counts unique values within a column.
    """

    print(f"Length: {len(data)}")
    for column in unique_columns:
        print(f"Unique {column}: {data[column].nunique()}")


def check_orphan_fk(data: pd.DataFrame, fk_columns: list, pk_list: list):

    """
    Searches for orphan FK within a FK column.
    """

    for pk_column, fk_column in zip(pk_list, fk_columns):
        print(f"Orphan FK ({fk_column}): {len(data[~data[fk_column].isin(pk_column)])}")


def check_dates(data: pd.DataFrame, date_columns: list):

    """
    Searches for null dates. 
    Prints first date to check if it matches with the country's first year of activity.
    """

    for column in date_columns:
        print(f"Null dates: {data[column].isnull().sum()}")
        print(f"{column} for the UK (2015): {min(data[data['country'] == 'UK'][column])}")
        print(f"{column} for the IR (2017): {min(data[data['country'] == 'IR'][column])}")
        print(f"{column} for the CA (2020): {min(data[data['country'] == 'CA'][column])}")



def check_metrics(data: pd.DataFrame, metric_columns: list):

    """
    Checks for invalid metrics.
    """

    for column in metric_columns:
        print(f"Null / zero prices: {len(data[data[column].isna()]) + len(data[data[column] == 0])}")



# ------- Full check ------- #

def full_check(data, unique_columns = None,  key_columns = None, date_columns = None, metric_columns = None):
    
    if unique_columns != None:
        check_duplicates(data, unique_columns)

    if key_columns != None:
        check_orphan_fk(data, key_columns['fk_columns'], key_columns['pk_list'])

    if date_columns != None:
        check_dates(data, date_columns)

    if metric_columns != None:
        check_metrics(data, metric_columns)
