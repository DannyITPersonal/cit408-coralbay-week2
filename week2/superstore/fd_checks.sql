-- Functional dependency proof queries: execute each separately or save full results.
-- GROUP BY/HAVING returns the violating determinants (zero rows = no observed conflict).
-- Initial key tests
SELECT COUNT(*) AS rows_total, COUNT(DISTINCT row_id) AS unique_row_ids,
       COUNT(DISTINCT order_id) AS unique_order_ids,
       COUNT(DISTINCT customer_id) AS unique_customer_ids,
       COUNT(DISTINCT product_id) AS unique_product_ids
FROM public.staging_superstore;
SELECT row_id, COUNT(*) AS occurrences FROM public.staging_superstore GROUP BY row_id HAVING COUNT(*)>1;
SELECT COUNT(*) AS missing_row_id FROM public.staging_superstore WHERE row_id IS NULL OR TRIM(row_id)='';
-- Customer dependencies
SELECT customer_id,COUNT(DISTINCT customer_name) AS values_found FROM public.staging_superstore GROUP BY customer_id HAVING COUNT(DISTINCT customer_name)>1;
SELECT customer_id,COUNT(DISTINCT segment) AS values_found FROM public.staging_superstore GROUP BY customer_id HAVING COUNT(DISTINCT segment)>1;
-- Order dependencies: one test per dependent column
SELECT order_id,COUNT(DISTINCT order_date) AS n FROM public.staging_superstore GROUP BY order_id HAVING COUNT(DISTINCT order_date)>1;
SELECT order_id,COUNT(DISTINCT ship_date) AS n FROM public.staging_superstore GROUP BY order_id HAVING COUNT(DISTINCT ship_date)>1;
SELECT order_id,COUNT(DISTINCT ship_mode) AS n FROM public.staging_superstore GROUP BY order_id HAVING COUNT(DISTINCT ship_mode)>1;
SELECT order_id,COUNT(DISTINCT customer_id) AS n FROM public.staging_superstore GROUP BY order_id HAVING COUNT(DISTINCT customer_id)>1;
SELECT order_id,COUNT(DISTINCT country) AS n FROM public.staging_superstore GROUP BY order_id HAVING COUNT(DISTINCT country)>1;
SELECT order_id,COUNT(DISTINCT city) AS n FROM public.staging_superstore GROUP BY order_id HAVING COUNT(DISTINCT city)>1;
SELECT order_id,COUNT(DISTINCT state) AS n FROM public.staging_superstore GROUP BY order_id HAVING COUNT(DISTINCT state)>1;
SELECT order_id,COUNT(DISTINCT postal_code) AS n FROM public.staging_superstore GROUP BY order_id HAVING COUNT(DISTINCT postal_code)>1;
SELECT order_id,COUNT(DISTINCT region) AS n FROM public.staging_superstore GROUP BY order_id HAVING COUNT(DISTINCT region)>1;
-- Product dependencies
SELECT product_id,COUNT(DISTINCT product_name) AS different_names FROM public.staging_superstore GROUP BY product_id HAVING COUNT(DISTINCT product_name)>1;
SELECT product_id,product_name,COUNT(DISTINCT category) AS n FROM public.staging_superstore GROUP BY product_id,product_name HAVING COUNT(DISTINCT category)>1;
SELECT product_id,product_name,COUNT(DISTINCT sub_category) AS n FROM public.staging_superstore GROUP BY product_id,product_name HAVING COUNT(DISTINCT sub_category)>1;
-- Location and category dependencies
SELECT postal_code,COUNT(DISTINCT city) AS cities,COUNT(DISTINCT state) AS states FROM public.staging_superstore WHERE postal_code IS NOT NULL AND TRIM(postal_code)<>'' GROUP BY postal_code HAVING COUNT(DISTINCT city)>1 OR COUNT(DISTINCT state)>1;
SELECT DISTINCT postal_code,city,state,region,country FROM public.staging_superstore WHERE postal_code='92024' ORDER BY city;
SELECT state,COUNT(DISTINCT region) AS n FROM public.staging_superstore GROUP BY state HAVING COUNT(DISTINCT region)>1;
SELECT sub_category,COUNT(DISTINCT category) AS n FROM public.staging_superstore GROUP BY sub_category HAVING COUNT(DISTINCT category)>1;
-- Missing values necessary for key and NOT NULL interpretations
SELECT COUNT(*) FILTER (WHERE customer_id IS NULL OR TRIM(customer_id)='') AS missing_customer_id,
COUNT(*) FILTER (WHERE customer_name IS NULL OR TRIM(customer_name)='') AS missing_customer_name,
COUNT(*) FILTER (WHERE segment IS NULL OR TRIM(segment)='') AS missing_segment,
COUNT(*) FILTER (WHERE order_id IS NULL OR TRIM(order_id)='') AS missing_order_id,
COUNT(*) FILTER (WHERE product_id IS NULL OR TRIM(product_id)='') AS missing_product_id,
COUNT(*) FILTER (WHERE product_name IS NULL OR TRIM(product_name)='') AS missing_product_name,
COUNT(*) FILTER (WHERE postal_code IS NULL OR TRIM(postal_code)='') AS missing_postal_code,
COUNT(*) FILTER (WHERE sub_category IS NULL OR TRIM(sub_category)='') AS missing_subcategory,
COUNT(*) FILTER (WHERE category IS NULL OR TRIM(category)='') AS missing_category
FROM public.staging_superstore;
