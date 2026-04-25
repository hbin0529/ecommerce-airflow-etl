# Brazilian E-Commerce Airflow ETL Pipeline

## 1. Project Overview

This project builds a batch ETL pipeline using the Brazilian E-Commerce Public Dataset by Olist.

The goal is to process raw e-commerce CSV files into analytical mart tables using PostgreSQL, Python, Docker, and Apache Airflow.

## 2. Tech Stack

- Python
- PostgreSQL
- Docker
- Apache Airflow
- SQL
- Git / GitHub

## 3. Data Pipeline Architecture

```text
CSV Files
   ↓
raw schema
   ↓
staging schema
   ↓
mart schema
   ↓
analytics tables