DROP TABLE IF EXISTS staging.stg_orders;
DROP TABLE IF EXISTS staging.stg_order_items;
DROP TABLE IF EXISTS staging.stg_products;
DROP TABLE IF EXISTS staging.stg_customers;
DROP TABLE IF EXISTS staging.stg_sellers;
DROP TABLE IF EXISTS staging.stg_payments;
DROP TABLE IF EXISTS staging.stg_category_translation;

CREATE TABLE staging.stg_orders AS
SELECT DISTINCT
    order_id,
    customer_id,
    order_status,
    NULLIF(order_purchase_timestamp, '')::timestamp AS order_purchase_timestamp,
    NULLIF(order_approved_at, '')::timestamp AS order_approved_at,
    NULLIF(order_delivered_carrier_date, '')::timestamp AS order_delivered_carrier_date,
    NULLIF(order_delivered_customer_date, '')::timestamp AS order_delivered_customer_date,
    NULLIF(order_estimated_delivery_date, '')::timestamp AS order_estimated_delivery_date
FROM raw.orders;

CREATE TABLE staging.stg_order_items AS
SELECT DISTINCT 
    order_id,
    NULLIF(order_item_id, '')::integer AS order_item_id,
    product_id,
    seller_id,
    NULLIF(shipping_limit_date, '')::timestamp AS shipping_limit_date,
    NULLIF(price, '')::numeric(10, 2) AS price,
    NULLIF(freight_value, '')::numeric(10, 2) AS freight_value
FROM raw.order_items;

CREATE TABLE staging.stg_products AS
SELECT DISTINCT 
    product_id,
    NULLIF(product_category_name, '') AS product_category_name,
    NULLIF(product_name_lenght, '')::numeric::integer AS product_name_length,
    NULLIF(product_description_lenght, '')::numeric::integer AS product_description_length,
    NULLIF(product_photos_qty, '')::numeric::integer AS product_photos_qty,
    NULLIF(product_weight_g, '')::numeric::integer AS product_weight_g,
    NULLIF(product_length_cm, '')::numeric::integer AS product_length_cm,
    NULLIF(product_height_cm, '')::numeric::integer AS product_height_cm,
    NULLIF(product_width_cm, '')::numeric::integer AS product_width_cm
FROM raw.products;

CREATE TABLE staging.stg_customers AS
SELECT DISTINCT 
    customer_id,
    customer_unique_id,
    NULLIF(customer_zip_code_prefix, '')::integer AS customer_zip_code_prefix,
    customer_city,
    customer_state
FROM raw.customers;

CREATE TABLE staging.stg_sellers AS
SELECT DISTINCT 
    seller_id,
    NULLIF(seller_zip_code_prefix, '')::integer AS seller_zip_code_prefix,
    seller_city,
    seller_state
FROM raw.sellers;

CREATE TABLE staging.stg_payments AS
SELECT DISTINCT 
    order_id,
    NULLIF(payment_sequential, '')::integer AS payment_sequential,
    payment_type,
    NULLIF(payment_installments, '')::integer AS payment_installments,
    NULLIF(payment_value, '')::numeric(10, 2) AS payment_value
FROM raw.payments;

CREATE TABLE staging.stg_category_translation AS
SELECT DISTINCT 
    product_category_name,
    product_category_name_english
FROM raw.category_translation;

CREATE INDEX idx_stg_orders_order_id
ON staging.stg_orders(order_id);

CREATE INDEX idx_stg_orders_customer_id
ON staging.stg_orders(customer_id);

CREATE INDEX idx_stg_order_items_order_id
ON staging.stg_order_items(order_id);

CREATE INDEX idx_stg_order_items_product_id
ON staging.stg_order_items(product_id);

CREATE INDEX idx_stg_order_items_seller_id
ON staging.stg_order_items(seller_id);

CREATE INDEX idx_stg_products_product_id
ON staging.stg_products(product_id);

CREATE INDEX idx_stg_customers_customer_id
ON staging.stg_customers(customer_id);

CREATE INDEX idx_stg_sellers_seller_id
ON staging.stg_sellers(seller_id);

CREATE INDEX idx_stg_payments_order_id
ON staging.stg_payments(order_id);