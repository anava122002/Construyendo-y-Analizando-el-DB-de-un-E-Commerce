import pandas as pd
import numpy as np
from faker import Faker
from datetime import datetime, timedelta



# ------- Functions to modify data ------- #

def cut_df(df: pd.DataFrame, start: int, end: int):

    """
    Returns a slice from DataFrame.
    """

    return df[start:end]



def create_dict(df: pd.DataFrame, in_df: bool, values: str, keys = None):

    """
    Defines a dictionary from df columns. 
    If in_df == False, the function creates a new list of keys.
    """

    if in_df:
        new_dict = df.set_index(keys)[values].to_dict()

    else:
        if keys == None:
            raise ValueError("Invalid or null prefix.")

        new_values = df[values].drop_duplicates().dropna()
        new_keys = [f"{keys}{i:05d}" for i in range(1, len(new_values)+1)]

        new_dict = dict(zip(new_keys, new_values))

    
    return new_dict



def create_df(base_dict: dict, columns: list):

    """
    Creates DataFrame from dictionary.
    """

    new_df = pd.DataFrame({columns[0]: list(base_dict.keys()), 
                        columns[1]: list(base_dict.values())})
    
    return new_df



# ------- Functions to randomly create data ------- #

def create_email(x, y, z):

    """
    Creates 5 types of fake emails randomly.
    """

    rng = np.random.default_rng()

    prob = rng.random()

    year = z.year
    month = z.month
    day = z.day

    small_num = rng.integers(1, 100)
    letter = np.random.choice(['A', 'E', 'I', 'O', 'U'], size = 1)[0]


    if prob >= 0.8:
        return f"{x}{letter}{y}{day}{month}{year}@gmail.com"
    elif prob >= 0.5:
        return f"{x}{y[:4]}{month}{year}@gmail.com"
    elif prob >= 0.3:
        return f"{x} {letter}. {y} {day}{month}{year} {small_num}@gmail.com"
    elif prob >= 0.1:
        return f"{x}_{y}_{small_num}@gmail.com"
    elif prob >= 0.05:
        return f"{x}{y}_odyssey_{small_num}{year}@gmail.com"
    elif prob >= 0.01:
        return f"{x}{y[:3]}'sfakemail{year + 15}@gmail.com"
    else:
        return f"{x}{year}jedetmail{small_num}@gmail.com"
    


def next_restock(today, stock):

    """
    Generates fake restock dates based on product's total stock.
    """

    if stock >= 30000:
        days = np.random.randint(1, 4)
    elif stock >= 15000:
        days = np.random.randint(3, 7)
    elif stock >= 5000:
        days = np.random.randint(7, 15)
    else:
        days = np.random.randint(15, 30)
    
    return today - timedelta(days = days)



def choose_worker(data: pd.DataFrame, worker_country_dict: dict, worker_date_dict: dict):

    """
    Selects randomly among eligible workers in the same country whose hire date precedes the order date.
    """

    result = []

    for d, c in zip(data['order_date'], data['country']):

        candidates = [
            w for w in worker_country_dict[c]
            if worker_date_dict[w] <= d
        ]

        result.append(np.random.choice(candidates))

    return result

