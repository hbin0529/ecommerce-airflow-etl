CREATE SCHEMA IF NOT EXISTS quality;

DROP TABLE IF EXISTS quality.data_quality_results;

CREATE TABLE quality.data_quality_results AS

-- 1. raw 테이블 row count 검증
SELECT
    'raw.orders_not_empty' AS check_name,
    CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END::numeric AS failed_count,
    COUNT(*)::text AS actual_value,
    'raw.orders row count > 0' AS expected_condition
FROM raw.orders

UNION ALL
SELECT
    'raw.order_items_not_empty',
    CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END::numeric,
    COUNT(*)::text,
    'raw.order_items row count > 0'
FROM raw.order_items

UNION ALL
SELECT
    'raw.products_not_empty',
    CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END::numeric,
    COUNT(*)::text,
    'raw.products row count > 0'
FROM raw.products

UNION ALL
SELECT
    'raw.customers_not_empty',
    CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END::numeric,
    COUNT(*)::text,
    'raw.customers row count > 0'
FROM raw.customers

UNION ALL
SELECT
    'raw.sellers_not_empty',
    CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END::numeric,
    COUNT(*)::text,
    'raw.sellers row count > 0'
FROM raw.sellers

UNION ALL
SELECT
    'raw.payments_not_empty',
    CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END::numeric,
    COUNT(*)::text,
    'raw.payments row count > 0'
FROM raw.payments

UNION ALL
SELECT
    'raw.category_translation_not_empty',
    CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END::numeric,
    COUNT(*)::text,
    'raw.category_translation row count > 0'
FROM raw.category_translation


-- 2. raw ↔ staging row count 검증
UNION ALL
SELECT
    'row_count.raw_orders_vs_staging_orders',
    ABS(
        (SELECT COUNT(*) FROM raw.orders)
        -
        (SELECT COUNT(*) FROM staging.stg_orders)
    )::numeric,
    CONCAT(
        'raw=', (SELECT COUNT(*) FROM raw.orders),
        ', staging=', (SELECT COUNT(*) FROM staging.stg_orders)
    ),
    'raw.orders count = staging.stg_orders count'

UNION ALL
SELECT
    'row_count.raw_order_items_vs_staging_order_items',
    ABS(
        (SELECT COUNT(*) FROM raw.order_items)
        -
        (SELECT COUNT(*) FROM staging.stg_order_items)
    )::numeric,
    CONCAT(
        'raw=', (SELECT COUNT(*) FROM raw.order_items),
        ', staging=', (SELECT COUNT(*) FROM staging.stg_order_items)
    ),
    'raw.order_items count = staging.stg_order_items count'

UNION ALL
SELECT
    'row_count.raw_products_vs_staging_products',
    ABS(
        (SELECT COUNT(*) FROM raw.products)
        -
        (SELECT COUNT(*) FROM staging.stg_products)
    )::numeric,
    CONCAT(
        'raw=', (SELECT COUNT(*) FROM raw.products),
        ', staging=', (SELECT COUNT(*) FROM staging.stg_products)
    ),
    'raw.products count = staging.stg_products count'

UNION ALL
SELECT
    'row_count.raw_customers_vs_staging_customers',
    ABS(
        (SELECT COUNT(*) FROM raw.customers)
        -
        (SELECT COUNT(*) FROM staging.stg_customers)
    )::numeric,
    CONCAT(
        'raw=', (SELECT COUNT(*) FROM raw.customers),
        ', staging=', (SELECT COUNT(*) FROM staging.stg_customers)
    ),
    'raw.customers count = staging.stg_customers count'

UNION ALL
SELECT
    'row_count.raw_sellers_vs_staging_sellers',
    ABS(
        (SELECT COUNT(*) FROM raw.sellers)
        -
        (SELECT COUNT(*) FROM staging.stg_sellers)
    )::numeric,
    CONCAT(
        'raw=', (SELECT COUNT(*) FROM raw.sellers),
        ', staging=', (SELECT COUNT(*) FROM staging.stg_sellers)
    ),
    'raw.sellers count = staging.stg_sellers count'

UNION ALL
SELECT
    'row_count.raw_payments_vs_staging_payments',
    ABS(
        (SELECT COUNT(*) FROM raw.payments)
        -
        (SELECT COUNT(*) FROM staging.stg_payments)
    )::numeric,
    CONCAT(
        'raw=', (SELECT COUNT(*) FROM raw.payments),
        ', staging=', (SELECT COUNT(*) FROM staging.stg_payments)
    ),
    'raw.payments count = staging.stg_payments count'

UNION ALL
SELECT
    'row_count.raw_category_translation_vs_staging_category_translation',
    ABS(
        (SELECT COUNT(*) FROM raw.category_translation)
        -
        (SELECT COUNT(*) FROM staging.stg_category_translation)
    )::numeric,
    CONCAT(
        'raw=', (SELECT COUNT(*) FROM raw.category_translation),
        ', staging=', (SELECT COUNT(*) FROM staging.stg_category_translation)
    ),
    'raw.category_translation count = staging.stg_category_translation count'


-- 3. 주요 key NULL 검증
UNION ALL
SELECT
    'null_check.stg_orders_order_id',
    COUNT(*)::numeric,
    COUNT(*)::text,
    'staging.stg_orders.order_id IS NOT NULL'
FROM staging.stg_orders
WHERE order_id IS NULL

UNION ALL
SELECT
    'null_check.stg_order_items_order_id',
    COUNT(*)::numeric,
    COUNT(*)::text,
    'staging.stg_order_items.order_id IS NOT NULL'
FROM staging.stg_order_items
WHERE order_id IS NULL

UNION ALL
SELECT
    'null_check.stg_order_items_product_id',
    COUNT(*)::numeric,
    COUNT(*)::text,
    'staging.stg_order_items.product_id IS NOT NULL'
FROM staging.stg_order_items
WHERE product_id IS NULL

UNION ALL
SELECT
    'null_check.stg_order_items_seller_id',
    COUNT(*)::numeric,
    COUNT(*)::text,
    'staging.stg_order_items.seller_id IS NOT NULL'
FROM staging.stg_order_items
WHERE seller_id IS NULL

UNION ALL
SELECT
    'null_check.stg_products_product_id',
    COUNT(*)::numeric,
    COUNT(*)::text,
    'staging.stg_products.product_id IS NOT NULL'
FROM staging.stg_products
WHERE product_id IS NULL

UNION ALL
SELECT
    'null_check.stg_customers_customer_id',
    COUNT(*)::numeric,
    COUNT(*)::text,
    'staging.stg_customers.customer_id IS NOT NULL'
FROM staging.stg_customers
WHERE customer_id IS NULL

UNION ALL
SELECT
    'null_check.stg_sellers_seller_id',
    COUNT(*)::numeric,
    COUNT(*)::text,
    'staging.stg_sellers.seller_id IS NOT NULL'
FROM staging.stg_sellers
WHERE seller_id IS NULL


-- 4. 중복 key 검증
UNION ALL
SELECT
    'duplicate_check.stg_orders_order_id',
    (
        COUNT(*)
        -
        COUNT(DISTINCT order_id)
    )::numeric,
    CONCAT(
        'total=', COUNT(*),
        ', distinct=', COUNT(DISTINCT order_id)
    ),
    'order_id should be unique in staging.stg_orders'
FROM staging.stg_orders

UNION ALL
SELECT
    'duplicate_check.stg_customers_customer_id',
    (
        COUNT(*)
        -
        COUNT(DISTINCT customer_id)
    )::numeric,
    CONCAT(
        'total=', COUNT(*),
        ', distinct=', COUNT(DISTINCT customer_id)
    ),
    'customer_id should be unique in staging.stg_customers'
FROM staging.stg_customers

UNION ALL
SELECT
    'duplicate_check.stg_products_product_id',
    (
        COUNT(*)
        -
        COUNT(DISTINCT product_id)
    )::numeric,
    CONCAT(
        'total=', COUNT(*),
        ', distinct=', COUNT(DISTINCT product_id)
    ),
    'product_id should be unique in staging.stg_products'
FROM staging.stg_products

UNION ALL
SELECT
    'duplicate_check.stg_sellers_seller_id',
    (
        COUNT(*)
        -
        COUNT(DISTINCT seller_id)
    )::numeric,
    CONCAT(
        'total=', COUNT(*),
        ', distinct=', COUNT(DISTINCT seller_id)
    ),
    'seller_id should be unique in staging.stg_sellers'
FROM staging.stg_sellers

UNION ALL
SELECT
    'duplicate_check.stg_order_items_order_item_key',
    (
        COUNT(*)
        -
        COUNT(DISTINCT (order_id, order_item_id))
    )::numeric,
    CONCAT(
        'total=', COUNT(*),
        ', distinct=', COUNT(DISTINCT (order_id, order_item_id))
    ),
    'order_id + order_item_id should be unique in staging.stg_order_items'
FROM staging.stg_order_items


-- 5. 참조 무결성 검증
UNION ALL
SELECT
    'referential_check.order_items_order_id_exists_in_orders',
    COUNT(*)::numeric,
    COUNT(*)::text,
    'Every order_items.order_id should exist in orders'
FROM staging.stg_order_items oi
LEFT JOIN staging.stg_orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL
SELECT
    'referential_check.order_items_product_id_exists_in_products',
    COUNT(*)::numeric,
    COUNT(*)::text,
    'Every order_items.product_id should exist in products'
FROM staging.stg_order_items oi
LEFT JOIN staging.stg_products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL
SELECT
    'referential_check.order_items_seller_id_exists_in_sellers',
    COUNT(*)::numeric,
    COUNT(*)::text,
    'Every order_items.seller_id should exist in sellers'
FROM staging.stg_order_items oi
LEFT JOIN staging.stg_sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL

UNION ALL
SELECT
    'referential_check.orders_customer_id_exists_in_customers',
    COUNT(*)::numeric,
    COUNT(*)::text,
    'Every orders.customer_id should exist in customers'
FROM staging.stg_orders o
LEFT JOIN staging.stg_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL
SELECT
    'referential_check.payments_order_id_exists_in_orders',
    COUNT(*)::numeric,
    COUNT(*)::text,
    'Every payments.order_id should exist in orders'
FROM staging.stg_payments p
LEFT JOIN staging.stg_orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL


-- 6. 음수 금액 검증
UNION ALL
SELECT
    'value_check.negative_order_item_price',
    COUNT(*)::numeric,
    COUNT(*)::text,
    'staging.stg_order_items.price >= 0'
FROM staging.stg_order_items
WHERE price < 0

UNION ALL
SELECT
    'value_check.negative_freight_value',
    COUNT(*)::numeric,
    COUNT(*)::text,
    'staging.stg_order_items.freight_value >= 0'
FROM staging.stg_order_items
WHERE freight_value < 0

UNION ALL
SELECT
    'value_check.negative_payment_value',
    COUNT(*)::numeric,
    COUNT(*)::text,
    'staging.stg_payments.payment_value >= 0'
FROM staging.stg_payments
WHERE payment_value < 0


-- 7. mart 테이블 row count 검증
UNION ALL
SELECT
    'mart.daily_sales_not_empty',
    CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END::numeric,
    COUNT(*)::text,
    'mart.daily_sales row count > 0'
FROM mart.daily_sales

UNION ALL
SELECT
    'mart.seller_order_summary_not_empty',
    CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END::numeric,
    COUNT(*)::text,
    'mart.seller_order_summary row count > 0'
FROM mart.seller_order_summary

UNION ALL
SELECT
    'mart.category_sales_summary_not_empty',
    CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END::numeric,
    COUNT(*)::text,
    'mart.category_sales_summary row count > 0'
FROM mart.category_sales_summary

UNION ALL
SELECT
    'mart.payment_type_summary_not_empty',
    CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END::numeric,
    COUNT(*)::text,
    'mart.payment_type_summary row count > 0'
FROM mart.payment_type_summary


-- 8. staging 총매출과 mart 일별 매출 총합 검증
UNION ALL
SELECT
    'reconciliation.staging_sales_vs_mart_daily_sales',
    CASE
        WHEN ABS(staging_total.total_sales - mart_total.total_sales) > 0.01 THEN 1
        ELSE 0
    END::numeric AS failed_count,
    CONCAT(
        'staging_total=', staging_total.total_sales,
        ', mart_total=', mart_total.total_sales
    ) AS actual_value,
    'Delivered order item sales total should match mart.daily_sales total_sales'
FROM
    (
        SELECT COALESCE(ROUND(SUM(oi.price), 2), 0) AS total_sales
        FROM staging.stg_order_items oi
        JOIN staging.stg_orders o
            ON oi.order_id = o.order_id
        WHERE o.order_status = 'delivered'
    ) staging_total
CROSS JOIN
    (
        SELECT COALESCE(ROUND(SUM(total_sales), 2), 0) AS total_sales
        FROM mart.daily_sales
    ) mart_total
;

ALTER TABLE quality.data_quality_results
ADD COLUMN status TEXT;

UPDATE quality.data_quality_results
SET status = CASE
    WHEN failed_count = 0 THEN 'PASS'
    ELSE 'FAIL'
END;

SELECT
    check_name,
    status,
    failed_count,
    actual_value,
    expected_condition
FROM quality.data_quality_results
ORDER BY
    CASE WHEN status = 'FAIL' THEN 0 ELSE 1 END,
    check_name;