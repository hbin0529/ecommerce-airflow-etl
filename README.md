# Brazilian E-Commerce Airflow ETL Pipeline

## 1. 프로젝트 개요

이 프로젝트는 Brazilian E-Commerce Public Dataset by Olist 데이터를 기반으로 구축한 데이터 엔지니어링 포트폴리오 프로젝트입니다.

CSV 원천 데이터를 PostgreSQL에 적재한 뒤, `raw → staging → mart` 계층으로 데이터를 정제하고 집계합니다. 이후 데이터 품질 검증을 수행하며, 전체 ETL 프로세스를 Apache Airflow DAG로 자동화했습니다.

이 프로젝트의 목적은 단순 데이터 분석이 아니라, 데이터 엔지니어링 관점에서 다음 흐름을 구현하는 것입니다.

```text
CSV Source Data
    ↓
Raw Layer
    ↓
Staging Layer
    ↓
Mart Layer
    ↓
Data Quality Check
    ↓
Airflow Orchestration
```

---

## 2. 프로젝트 목표

이 프로젝트는 다음 목표를 가지고 구현했습니다.

- Docker 기반 PostgreSQL 개발환경 구성
- CSV 원천 데이터를 PostgreSQL raw 테이블에 적재
- staging 계층에서 데이터 타입 변환 및 적재
- mart 계층에서 분석용 집계 테이블 생성
- 데이터 품질 검증 SQL 작성
- Apache Airflow DAG를 통한 ETL 파이프라인 자동화
- 로컬 환경에서 재실행 가능한 ETL 구조 설계

---

## 3. 기술 스택
| 구분 | 기술 |
|---|---|
| Language | Python, SQL |
| Database | PostgreSQL |
| Workflow Orchestration | Apache Airflow |
| Container | Docker, Docker Compose |
| Python Library | pandas, SQLAlchemy, psycopg2-binary, python-dotenv |
| Version Control | GitHub |

---

## 4. 데이터셋

사용 데이터셋은 olist의 브라질 이커머스 주문 데이터입니다. 

프로젝트에서는 아래 7개 CSV 파일을 사용했습니다. 
```text
olist_customers_dataset.csv
olist_order_items_dataset.csv
olist_order_payments_dataset.csv
olist_orders_dataset.csv
olist_products_dataset.csv
olist_sellers_dataset.csv
product_category_name_translation.csv
```

CSV 파일은 용량 및 라이선스 관리를 위해 Github repo에는 포함하지 않았습니다. 
실행 시 `data/` 디렉터리에 직접 추가해야 합니다.

---

## 5. 프로젝트 구조 

```text
ecommerce-airflow-etl/
│
├── dags/
│   └── ecommerce_etl_dag.py
│
├── data/
│   └── .gitkeep
│
├── scripts/
│   ├── db_connection.py
│   └── load_csv_to_raw.py
│
├── sql/
│   ├── 01_create_schema.sql
│   ├── 02_create_raw_tables.sql
│   ├── 03_create_staging_tables.sql
│   ├── 04_create_mart_tables.sql
│   └── 05_data_quality_check.sql
│
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
├── requirements-airflow.txt
├── .env.example
├── .gitignore
└── README.md
```

---

## 6. 데이터 파이프라인 구조

### 6.1 Raw Layer 

`raw` 계층은 CSV 원천 데이터를 거의 그대로 적재하는 영역입니다. 
CSV 적재 안정성을 위해 대부분의 컬럼을 `TEXT` 타입으로 저장했습니다. 

주요 테이블:

```text
raw.orders
raw.order_items
raw.products
raw.customers
raw.sellers
raw.payments
raw.category_translation
```

---

### 6.2 Staging Layer

`staging` 계층은 raw 데이터를 분석에 적합한 형태로 정제하는 영역입니다.

수행 작업:

- 문자열 날짜 컬럼을 `TIMESTAMP`로 변환
- 문자열 숫자 컬럼을 `INTEGER`, `NUMERIC`으로 변환
- 빈 문자열을 `NULL`로 처리
- 주요 JOIN 컬럼에 인덱스 생성

주요 테이블:
```text
staging.stg_orders
staging.stg_order_items
staging.stg_products
staging.stg_customers
staging.stg_sellers
staging.stg_payments
staging.stg_category_translation
```

예시:
```sql
NULLIF(order_purchase_timestamp, '')::timestamp AS order_purchase_timestamp
```

```sql
NULLIF(price, '')::numeric(10, 2) AS price
```

상품 데이터의 일부 숫자 컬럼은 `"40.0"`과 같이 소수 형태의 문자열로 들어오는 경우가 있어 다음과 같이 처리했습니다. 

```sql
NULLIF(product_weight_g, '')::numeric::integer AS product_weight_g
```

---

### 6.3 Mart Layer 

`mart` 계층은 분석이나 리포트에서 바로 사용할 수 있는 집계 테이블입니다.

생성한 mart 테이블:
| 테이블 | 설명 | 
|---|---|
| `mart.daily_sales` | 일별 매출 요약 |
| `mart.seller_order_summary` | 판매자별 주문 및 매출 요약 |
| `mart.category_sales_summary` | 상품 카테고리별 매출 요약 |
| `mart.payment_type_summary` | 결제수단별 결제 금액 요약 |

매출 집계는 주문 상태가 `delivered`인 주문 대상으로만 했습니다.

```sql
WHERE o.order_status = 'delivered'
```

---

### 6.4 Quality Layer

데이터 품질 검증 결과는 `quality.data_quality_results` 테이블에 저장됩니다. 

검증 항목:

- raw 테이블 row count 검증
- raw와 staging row count 비교
- 주요 key 컬럼 NULL 검증
- key 중복 검증
- 참조 무결성 검증
- 음수 금액 검증
- mart 테이블 row count 검증
- staging 총매출과 mart 총매출 정합성 검증

검증 결과는 `PASS` 또는 `FAIL` 상태로 저장됩니다.

--- 

## 7. Airflow DAG 구조

Airflow DAG는 전체 ETL 프로세스를 아래 순서로 실행합니다.

```text
create_schema
    ↓
create_raw_tables
    ↓
load_csv_to_raw
    ↓
create_staging_tables
    ↓
create_mart_tables
    ↓
run_data_quality_check
```

DAG ID:

```text
ecommerce_etl_pipeline
```

각 task의 역할:

| Task | 설명 |
|---|---|
| `create_schema` | raw, staging, mart, quality 스키마 생성 |
| `create_raw_tables` | raw 테이블 생성 |
| `load_csv_to_raw` | CSV 파일을 raw 테이블에 적재 |
| `create_staging_tables` | staging 테이블 생성 및 타입 변환 |
| `create_mart_tables` | mart 집계 테이블 생성 |
| `run_data_quality_check` | 데이터 품질 검증 실행 |

---

## 8. 실행 방법

### 8.1 저장소 클롬
```bash
git clone https://github.com/hbin0529/ecommerce_airflow_etl.git
cd ecommerce-airflow-etl
```

---

### 8.2 환경변수 파일 생성

`.env.example`을 참고하여 `.env` 파일을 생성합니다.

```env
POSTGRES_USER=ecommerce_admin01
POSTGRES_PASSWORD=admin
POSTGRES_DB=ecommerce
POSTGRES_HOST=127.0.0.1
POSTGRES_PORT=15433
```

이 프로젝트에서는 로컬 POstgreSQL 포트 충돌을 피하기 위해 호스트 포트 `15433`을 사용합니다.

Docker 컨테이너 내부 PostgreSQL 포트는 기본값인 `5432` 입니다.

```text
Local PC: 127.0.0.1:15433
Docker Container: postgres:5432
```

---

### 8.3 CSV 데이터 추가

아래 CSV 파일들을 `data/` 디렉터리에 추가합니다.

```text
data/
├── olist_orders_dataset.csv
├── olist_order_items_dataset.csv
├── olist_products_dataset.csv
├── olist_customers_dataset.csv
├── olist_sellers_dataset.csv
├── olist_order_payments_dataset.csv
└── product_category_name_translation.csv
```

### 8.4 Docker 컨테이너 실행

```bash
docker compose build
docker compose up airflow-init
docker compose up -d
```

컨테이너 상태 확인:

```bash
docker ps
```

정상적으로 실행되면 다음 컨테이너들이 실행됩니다.

```text
ecommerce_postgres
airflow_metadata_postgres
airflow_webserver
airflow_scheduler
```

---

### 8.5 Airflow UI 접속

브라우저에서 접속합니다. (저는 크롬을 사용했습니다.)

```text
http://localhost:8080
```

기본 로그인 정보:
```text
ID: airflow
PW: airflow
```

Airflow UI에서 `ecommerce_etl_pipeline` DAG를 활성화한 후 수동 실행합니다.

```text
Unpause → Trigger DAG
```

---

## 9. PostgreSQL 접속

Docker 컨테이너 내부 PostgreSQL에 접속합니다.

```bash
docker exec -it ecommerce_postgres psql -U ecommerce_admin01 -d ecommerce
```

테이블 확인:
```sql
\dt raw.*
\dt staging.*
\dt mart.*
\dt quality.*
```

---

## 10. 데이터 품질 검증 결과 확인

품질 검증 요약:

```sql
SELECT
      status
     , COUNT(*) AS check_count
  FROM quality.data_quality_results
 GROUP BY status
 ORDER BY status;
```

실패 항목 확인: 

```sql
SELECT
       check_name
     , failed_count
     , actual_value
     , expected_condition
  FROM quality.data_quality_results
 WHERE status = 'FAIL'
 ORDER BY check_name;
```

전체 검증 결과 확인:

```sql
SELECT
       check_name
     , status
     , failed_count
     , actual_value
     , expected_condition
  FROM quality.data_quality_results
 ORDER BY
  CASE WHEN status = 'FAIL' THEN 0 ELSE 1 END,
  check_name;
```

---

## 11. 주요 구현 내용

### 11.1 Docker 기반 로컬 개발환경 구성

PostgreSQL과 Airflow를 Docker Compose로 구성했습니다.

로컬PC에 PostgreSQL이 이미 설치되어 있는 경우 `5432` 포트 충돌이 발생할 수 있어, PostgreSQL 호스트 포트를 `15433`으로 매핑했습니다.

```yaml
ports:
   - "15433:5432"
```

---

### 11.2 Raw 데이터 적재

Python의 pandas와 SQLAlchemy를 사용해 CSV 파일을 PostgreSQL raw 테이블에 적재했습니다.

```python
df.to_sql(
    name=table_name,
    con=engine,
    schema="raw",
    if_exists="append",
    index=False,
    method="multi",
    chunksize=1000,
)
```

---

### 11.3 Staging 데이터 정제

raw 계층의 문자열 데이터를 staging 계층에서 적절한 타입으로 변환했습니다.

예시:

```sql
NULLIF(payment_value, '')::numeric(10, 2) AS payment_value
```

```sql
NULLIF(order_purchase_timestamp, '')::timestamp AS order_purchase_timestamp
```

---

### 11.4 Mart 집계 테이블 생성

분석에 바로 사용할 수 있는 집계 테이블을 생성했습니다.

예시: 일별 매출 집계

```sql
CREATE TABLE mart.daily_sales AS
SELECT
    DATE(o.order_purchase_timestamp) AS order_date,
    COUNT(DISTINCT o.order_id) AS order_count,
    COUNT(oi.order_item_id) AS item_count,
    SUM(oi.price) AS total_sales,
    SUM(oi.freight_value) AS total_freight,
    ROUND(AVG(oi.price), 2) AS avg_item_price
FROM staging.stg_orders o
JOIN staging.stg_order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE(o.order_purchase_timestamp);
```

---

### 11.5 Data Quality Check

ETL 결과를 검증하기 위해 별도의 quality 테이블을 생성했습니다.

검증 결과 예시:

```text
PASS / FAIL
failed_count
actual_value
expected_condition
```

이를 통해 단순 적재뿐 아니라 데이터 정합성까지 검증했습니다.

---

## 12. 트러블슈팅
### 12.1 PostgreSQL 5432 포트 충돌
문제: 
로컬 PC에 이미 POstgreSQL이 설치되어 있어 `5432` 포트 충돌이 발생하였습니다.

해결:
Docker Compose에서 호스트 포트를 `15433`으로 변경했습니다.

```yaml
ports:
   - "15433:5432"
```

`.env`에서도 로컬 접속 포트를 `15433`으로 설정했습니다.

```env
POSTGRES_PORT = 15433
```

Airflow 컨테이너 내부에서는 Docker 네트워크를 통해 `postgres:5432`로 접속합니다.

---

### 12.2 CSV 숫자 컬럼 타입 변환 오류
문제:
상품 데이터의 일부 컬럼이 `"40.0"`과 같은 문자열로 들어와 `integer`변환 ㅅ ㅣ 오류가 발생하였습니다. 

해결:
`numeric`으로 먼저 변환하여 `integer`로 변환하였습니다.

```sql
NULLIF(product_weight_g, '')::numeric::integer AS product_weight_g
```

---

### 12.3 Airflow DAG import 오류
문제:
Airflow DAG 작성 중 import 경로 오타로 Brocken DAG가 발생하였습니다.

오류 예시:

```python
from airflow.operator.python import PythonOperator
```

해결:
정확한 import 경로로 수정했습니다.

```python
from airflow.operators.python import PythonOperator
```

### 12.4 PythonOperator op_kwargs 오류
문제:
`run_sql_file()` 함수의 파라미터명은 `file_name`인데, DAG에서 `filename`으로 전달해 task 실행이 실패하였습니다.

해결:
`op_kwargs`의 key를 함수 파라미터명과 동일하게 수정하였습니다.

```python
op_kwargs = {"file_name": "01_create_schema.sql"},
```

---

## 13. 향후 개선 방향
현재 프로젝트는 로컬 개발환경 기반의 배치 ETL 파이프 라인입니다.
향후 다음 방향으로 확장할 수 있습니다.

- Airflow TaskFlow API 적용
- POstgreSQL Connection을 Airflow Connection으로 분리
- Great Expectations 기반 데이터 품질 검증 도입
- dbt를 활용한 staging/mart 모델 관리
- S3 또는 MinIO 기반 데이터 레이크 구조 추가
- Spark를 활용한 대용량 처리 구조 확장
- Github Actions를 활용한 SQL init 및 테스트 자동화
- BI 대시보드 연동

---

## 14. 프로젝트 실행 요약

```bash
# 1. Clone
git clone https://github.com/hbin0529/ecommerce-airflow-etl.git
cd ecommerce-airflow-etl

# 2. Create .env
cp .env.example .env

# 3. Add CSV files to data/

# 4. Build and run containers
docker compose build
docker compose up airflow-init
docker compose up -d

# 5. Open Airflow UI
# http://localhost:8080

# 6. Trigger DAG
# ecommerce_etl_pipeline → Unpause → Trigger DAG
```

---

## 15. 결과

이 프로젝트를 통해 다음과 같은 데이터 엔지니어링 흐름을 구현했습니다.

```text
Source CSV
    ↓
PostgreSQL Raw Layer
    ↓
PostgreSQL Staging Layer
    ↓
PostgreSQL Mart Layer
    ↓
Data Quality Validation
    ↓
Airflow DAG Orchestration
```

이를 통해 데이터 수집, 적재, 정제, 집계, 품질 검증, 워크플로우 자동화까지 포함한 End-to-End ETL 파이프라인을 구현했습니다.
