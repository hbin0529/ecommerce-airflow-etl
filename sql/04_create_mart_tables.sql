DROP TABLE IF EXISTS mart.daily_sales;
DROP TABLE IF EXISTS mart.seller_order_summary;
DROP TABLE IF EXISTS mart.category_sales_summary;
DROP TABLE IF EXISTS mart.payment_type_summary;

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
  AND o.order_purchase_timestamp IS NOT NULL
GROUP BY DATE(o.order_purchase_timestamp)
ORDER BY order_date;

CREATE TABLE mart.seller_order_summary AS
SELECT
    oi.seller_id,
    COUNT(DISTINCT oi.order_id) AS order_count,
    COUNT(*) AS item_count,
    SUM(oi.price) AS total_sales,
    SUM(oi.freight_value) AS total_freight,
    ROUND(AVG(oi.price), 2) AS avg_item_price
FROM staging.stg_order_items oi
JOIN staging.stg_orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.seller_id
ORDER BY total_sales DESC;

CREATE TABLE mart.category_sales_summary AS
SELECT
    COALESCE(ct.product_category_name_english, p.product_category_name, 'unknown') AS product_category_name,
    COUNT(DISTINCT oi.order_id) AS order_count,
    COUNT(*) AS item_count,
    SUM(oi.price) AS total_sales,
    SUM(oi.freight_value) AS total_freight,
    ROUND(AVG(oi.price), 2) AS avg_item_price
FROM staging.stg_order_items oi
JOIN staging.stg_orders o
    ON oi.order_id = o.order_id
LEFT JOIN staging.stg_products p
    ON oi.product_id = p.product_id
LEFT JOIN staging.stg_category_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY COALESCE(ct.product_category_name_english, p.product_category_name, 'unknown')
ORDER BY total_sales DESC;

CREATE TABLE mart.payment_type_summary AS
SELECT
    p.payment_type,
    COUNT(DISTINCT p.order_id) AS order_count,
    COUNT(*) AS payment_count,
    SUM(p.payment_value) AS total_payment_value,
    ROUND(AVG(p.payment_value), 2) AS avg_payment_value
FROM staging.stg_payments p
JOIN staging.stg_orders o
    ON p.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.payment_type
ORDER BY total_payment_value DESC;

CREATE INDEX idx_mart_daily_sales_order_date
ON mart.daily_sales(order_date);

CREATE INDEX idx_mart_seller_order_summary_seller_id
ON mart.seller_order_summary(seller_id);

CREATE INDEX idx_mart_category_sales_summary_category
ON mart.category_sales_summary(product_category_name);

CREATE INDEX idx_mart_payment_type_summary_payment_type
ON mart.payment_type_summary(payment_type);