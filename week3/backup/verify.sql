-- Atlantis University | CIT 408 | Module 3 Assignment 3.1
-- Mohamed Salem Maidan | 2026-10-15
-- Execute separately against superstore AND superstore_restore.
-- This file does not modify database data.

SELECT 'categories' AS table_name, COUNT(*) AS row_count FROM public.categories
UNION ALL SELECT 'customers', COUNT(*) FROM public.customers
UNION ALL SELECT 'locations', COUNT(*) FROM public.locations
UNION ALL SELECT 'order_lines', COUNT(*) FROM public.order_lines
UNION ALL SELECT 'orders', COUNT(*) FROM public.orders
UNION ALL SELECT 'products', COUNT(*) FROM public.products
UNION ALL SELECT 'staging_superstore', COUNT(*) FROM public.staging_superstore
UNION ALL SELECT 'states', COUNT(*) FROM public.states
UNION ALL SELECT 'subcategories', COUNT(*) FROM public.subcategories
ORDER BY table_name;

SELECT COUNT(*) AS order_line_count,
       ROUND(SUM(sales)::numeric, 2) AS total_sales,
       ROUND(SUM(profit)::numeric, 2) AS total_profit
FROM public.order_lines;
