from __future__ import annotations

import os 
import sys
from datetime import datetime, timedelta
from pathlib import Path

from airflow import DAG
from airflow.operators.python import PythonOperator
from sqlalchemy import text

PROJECT_ROOT = Path("/opt/airflow")
SQL_DIR = PROJECT_ROOT / "sql"
SCRIPTS_DIR = PROJECT_ROOT / "scripts"

sys.path.append(str(SCRIPTS_DIR))

from db_connection import get_engine # noqa: E402
from load_csv_to_raw import load_csv_to_raw # noqa: E402


def run_sql_file(file_name: str) -> None:
    sql_path = SQL_DIR / file_name

    if not sql_path.exists():
        raise FileNotFoundError(f"SQL file not found: {sql_path}")
    
    sql = sql_path.read_text(encoding="utf-8")
    engine = get_engine()

    with engine.begin() as conn:
        conn.execute(text(sql))

default_args = {
    "owner": "hbin",
    "retries": 1,
    "retry_delay": timedelta(minutes=1),
}


with DAG(
    dag_id = "ecommerce_etl_pipline",
    description = "Brazilian e-commerce ETL pipline: raw, staging, mart, quality check",
    default_args = default_args,
    start_date = datetime(2026, 1, 1),
    schedule = None,
    catchup = False,
    tags = ["portfolio", "etl", "ecommerce"]
) as dag:
    
    create_schema = PythonOperator(
        task_id = "create_schema",
        python_callable = run_sql_file,
        op_kwargs = {"file_name": "01_create_schema.sql"},
    )

    create_raw_tables = PythonOperator(
        task_id = "create_raw_tables",
        python_callable = run_sql_file,
        op_kwargs = {"file_name": "02_create_raw_tables.sql"},
    )

    load_raw_csv = PythonOperator(
        task_id = "load_csv_to_raw",
        python_callable = load_csv_to_raw,
    )

    create_staging_tables = PythonOperator(
        task_id = "create_staging_tables",
        python_callable = run_sql_file,
        op_kwargs = {"file_name": "03_create_staging_tables.sql"},
    )

    create_mart_tables = PythonOperator(
        task_id = "create_mart_tables",
        python_callable = run_sql_file,
        op_kwargs = {"file_name": "04_create_mart_tables.sql"},
    )

    run_data_quality_check = PythonOperator(
        task_id = "data_quality_check",
        python_callable = run_sql_file,
        op_kwargs = {"file_name": "05_data_quality_check.sql"},
    )

    (
        create_schema
        >> create_raw_tables
        >> load_raw_csv
        >> create_staging_tables
        >> create_mart_tables
        >> run_data_quality_check
    )