import os
import pandas as pd
import numpy as np
from pathlib import Path
from db_connection import get_engine

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"

TABLE_MAPPING = {
    "olist_customers_dataset":"customers",
    "olist_order_items_dataset":"order_items",
    "olist_order_payments_dataset":"payments",
    "olist_orders_dataset":"orders",
    "olist_products_dataset":"products",
    "olist_sellers_dataset":"sellers",
    "product_category_name_translation":"category",
}

def load_csv_to_raw():
    engine = get_engine()

    for file_name, table_name in TABLE_MAPPING.items():
        file_path = DATA_DIR / file_name

        if not file_path.exists():
            raise FileNotFoundError(f"CSV file not found: {file_path}")
        
        print(f"loading {file_name} into raw.{table_name}...")

        df = pd.read_csv(file_path)

        df.to_sql(
            name = table_name,
            con = engine,
            schema = "raw",
            if_exists = "append",
            index = False,
            method = "multi",
            chunksize= 1000,
        )

        print(f"loaded {len(df)} rows into raw.{table_name}")

    print("ALL CSV files loaded successfully.")

if __name__ == "__main__":
    load_csv_to_raw()