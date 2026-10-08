-- Week 2 Activity: Data Exploration
-- Assumed loaded table name: work_orders_unf
-- Run each query separately in PostgreSQL.

-- 1. Confirm the number of loaded work orders.
SELECT COUNT(*) AS work_order_rows
FROM work_orders_unf;

-- 2. Count distinct major entities.
SELECT
    COUNT(DISTINCT work_order_no) AS work_orders,
    COUNT(DISTINCT truck_id) AS trucks,
    COUNT(DISTINCT depot_code) AS depots,
    COUNT(DISTINCT mechanic_id) AS mechanics
FROM work_orders_unf;

-- 3. Count distinct parts and suppliers across all four part slots.
WITH parts AS (
    SELECT part1_code AS part_code, part1_supplier_id AS supplier_id FROM work_orders_unf WHERE part1_code IS NOT NULL
    UNION ALL
    SELECT part2_code, part2_supplier_id FROM work_orders_unf WHERE part2_code IS NOT NULL
    UNION ALL
    SELECT part3_code, part3_supplier_id FROM work_orders_unf WHERE part3_code IS NOT NULL
    UNION ALL
    SELECT part4_code, part4_supplier_id FROM work_orders_unf WHERE part4_code IS NOT NULL
)
SELECT
    COUNT(DISTINCT part_code) AS distinct_parts,
    COUNT(DISTINCT supplier_id) AS distinct_suppliers
FROM parts;

-- 4. Show how often each numbered part slot is empty.
SELECT
    COUNT(*) FILTER (WHERE part1_code IS NULL) AS empty_part1_slots,
    COUNT(*) FILTER (WHERE part2_code IS NULL) AS empty_part2_slots,
    COUNT(*) FILTER (WHERE part3_code IS NULL) AS empty_part3_slots,
    COUNT(*) FILTER (WHERE part4_code IS NULL) AS empty_part4_slots
FROM work_orders_unf;

-- Optional sample rows for visual inspection.
SELECT *
FROM work_orders_unf
ORDER BY work_order_no
LIMIT 10;
