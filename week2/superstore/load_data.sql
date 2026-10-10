-- CIT 408 Module 2 Assignment 2.3 — Populate normalized tables
-- Run once, after create_tables.sql, against empty destination tables.
BEGIN;
INSERT INTO public.customers (customer_id,customer_name,segment)
SELECT DISTINCT customer_id,customer_name,segment FROM public.staging_superstore;
INSERT INTO public.states (state,region)
SELECT DISTINCT state,region FROM public.staging_superstore;
INSERT INTO public.locations (country,state,city,postal_code)
SELECT DISTINCT country,state,city,postal_code FROM public.staging_superstore;
INSERT INTO public.categories (category_name)
SELECT DISTINCT category FROM public.staging_superstore;
INSERT INTO public.subcategories (subcategory_name,category_id)
SELECT DISTINCT s.sub_category,c.category_id
FROM public.staging_superstore s
JOIN public.categories c ON c.category_name=s.category;
INSERT INTO public.products (product_id,product_name,subcategory_id)
SELECT DISTINCT s.product_id,s.product_name,sc.subcategory_id
FROM public.staging_superstore s
JOIN public.subcategories sc ON sc.subcategory_name=s.sub_category;
INSERT INTO public.orders (order_id,order_date,ship_date,ship_mode,customer_id,location_id)
SELECT DISTINCT s.order_id,TO_DATE(s.order_date,'MM/DD/YYYY'),
    TO_DATE(s.ship_date,'MM/DD/YYYY'),s.ship_mode,s.customer_id,l.location_id
FROM public.staging_superstore s
JOIN public.locations l ON l.country=s.country AND l.state=s.state
    AND l.city=s.city AND l.postal_code=s.postal_code;
INSERT INTO public.order_lines (row_id,order_id,product_key,sales,quantity,discount,profit)
SELECT s.row_id::INTEGER,s.order_id,p.product_key,
    s.sales::NUMERIC(18,6),s.quantity::INTEGER,
    s.discount::NUMERIC(7,6),s.profit::NUMERIC(18,6)
FROM public.staging_superstore s
JOIN public.products p ON p.product_id=s.product_id AND p.product_name=s.product_name;
COMMIT;
