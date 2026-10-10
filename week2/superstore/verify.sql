-- CIT 408 Module 2 Assignment 2.3 — Evidence queries
-- Run against superstore after load_data.sql.

-- 1. Counts of each table
SELECT 'staging_superstore' AS table_name, COUNT(*) AS row_count FROM public.staging_superstore
UNION ALL SELECT 'customers', COUNT(*) FROM public.customers
UNION ALL SELECT 'states', COUNT(*) FROM public.states
UNION ALL SELECT 'locations', COUNT(*) FROM public.locations
UNION ALL SELECT 'orders', COUNT(*) FROM public.orders
UNION ALL SELECT 'categories', COUNT(*) FROM public.categories
UNION ALL SELECT 'subcategories', COUNT(*) FROM public.subcategories
UNION ALL SELECT 'products', COUNT(*) FROM public.products
UNION ALL SELECT 'order_lines', COUNT(*) FROM public.order_lines
ORDER BY table_name;

-- 2. All eight normalized tables joined back together: one row per order line
-- This query also compares the stage and normalized sales totals.
WITH joined_data AS (
    SELECT ol.row_id, ol.sales
    FROM public.order_lines ol
    JOIN public.orders o ON ol.order_id=o.order_id
    JOIN public.customers cu ON o.customer_id=cu.customer_id
    JOIN public.locations l ON o.location_id=l.location_id
    JOIN public.states st ON l.state=st.state
    JOIN public.products p ON ol.product_key=p.product_key
    JOIN public.subcategories sc ON p.subcategory_id=sc.subcategory_id
    JOIN public.categories ca ON sc.category_id=ca.category_id
)
SELECT
    (SELECT COUNT(*) FROM public.staging_superstore) AS staging_rows,
    (SELECT COUNT(*) FROM joined_data) AS joined_rows,
    (SELECT COUNT(DISTINCT row_id) FROM joined_data) AS distinct_joined_row_ids,
    (SELECT SUM(sales::NUMERIC) FROM public.staging_superstore) AS staging_sales,
    (SELECT SUM(sales) FROM joined_data) AS normalized_sales,
    (SELECT SUM(sales::NUMERIC) FROM public.staging_superstore) -
       (SELECT SUM(sales) FROM joined_data) AS sales_difference;
-- Observed prior query: staging_rows=9994, joined_rows=9994,
-- staging_sales=2297200.8603, normalized_sales=2297200.860300.

-- 3. Foreign-key rejection test. Run this portion as a SEPARATE selection.
-- The INSERT is expected to FAIL with SQLSTATE 23503.
-- If the transaction aborts, execute ROLLBACK separately afterward.
BEGIN;
INSERT INTO public.order_lines (row_id,order_id,product_key,sales,quantity,discount,profit)
VALUES (999999, (SELECT order_id FROM public.orders LIMIT 1),
        -999999, 100.00, 1, 0.00, 20.00);
-- Expected / observed on user server:
-- ERROR: insert or update on table "order_lines" violates foreign key constraint
-- "order_lines_product_key_fkey"
-- Key (product_key)=(-999999) is not present in table "products".
-- SQL state: 23503
-- After ERROR, execute this separately:
ROLLBACK;
-- Confirm no added record:
SELECT COUNT(*) AS order_line_count_after_rejected_insert FROM public.order_lines;
