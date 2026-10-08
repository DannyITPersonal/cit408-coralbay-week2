-- Week 2 Functional Dependency Checks
-- Every check uses GROUP BY ... HAVING COUNT(DISTINCT ...) > 1.
-- Expected results are recorded below each query as SQL comments.
-- Assumed loaded table: work_orders_unf

-- ================================================================
-- CHECK 1: work_order_no -> open_date
-- Result: 0 rows.
SELECT work_order_no
FROM work_orders_unf
GROUP BY work_order_no
HAVING COUNT(DISTINCT open_date) > 1;

-- ================================================================
-- CHECK 2: work_order_no -> close_date
-- Result: 0 rows.
SELECT work_order_no
FROM work_orders_unf
GROUP BY work_order_no
HAVING COUNT(DISTINCT close_date) > 1;

-- ================================================================
-- CHECK 3: work_order_no -> truck_id
-- Result: 0 rows.
SELECT work_order_no
FROM work_orders_unf
GROUP BY work_order_no
HAVING COUNT(DISTINCT truck_id) > 1;

-- ================================================================
-- CHECK 4: work_order_no -> depot_code
-- Result: 0 rows.
SELECT work_order_no
FROM work_orders_unf
GROUP BY work_order_no
HAVING COUNT(DISTINCT depot_code) > 1;

-- ================================================================
-- CHECK 5: work_order_no -> mechanic_id
-- Result: 0 rows.
SELECT work_order_no
FROM work_orders_unf
GROUP BY work_order_no
HAVING COUNT(DISTINCT mechanic_id) > 1;

-- ================================================================
-- CHECK 6: work_order_no -> labor_hours
-- Result: 0 rows.
SELECT work_order_no
FROM work_orders_unf
GROUP BY work_order_no
HAVING COUNT(DISTINCT labor_hours) > 1;

-- ================================================================
-- CHECK 7: work_order_no -> problem_description
-- Result: 0 rows.
SELECT work_order_no
FROM work_orders_unf
GROUP BY work_order_no
HAVING COUNT(DISTINCT problem_description) > 1;

-- ================================================================
-- CHECK 8: truck_id -> truck_vin
-- Result: 0 rows.
SELECT truck_id
FROM work_orders_unf
GROUP BY truck_id
HAVING COUNT(DISTINCT truck_vin) > 1;

-- ================================================================
-- CHECK 9: truck_id -> truck_make
-- Result: 0 rows.
SELECT truck_id
FROM work_orders_unf
GROUP BY truck_id
HAVING COUNT(DISTINCT truck_make) > 1;

-- ================================================================
-- CHECK 10: truck_id -> truck_model
-- Result: 0 rows.
SELECT truck_id
FROM work_orders_unf
GROUP BY truck_id
HAVING COUNT(DISTINCT truck_model) > 1;

-- ================================================================
-- CHECK 11: truck_id -> truck_year
-- Result: 0 rows.
SELECT truck_id
FROM work_orders_unf
GROUP BY truck_id
HAVING COUNT(DISTINCT truck_year) > 1;

-- ================================================================
-- CHECK 12: depot_code -> depot_name
-- Result: 0 rows.
SELECT depot_code
FROM work_orders_unf
GROUP BY depot_code
HAVING COUNT(DISTINCT depot_name) > 1;

-- ================================================================
-- CHECK 13: depot_code -> depot_city
-- Result: 0 rows.
SELECT depot_code
FROM work_orders_unf
GROUP BY depot_code
HAVING COUNT(DISTINCT depot_city) > 1;

-- ================================================================
-- CHECK 14: depot_code -> depot_phone
-- Result: 1 row: DEP-FLL.
SELECT depot_code
FROM work_orders_unf
GROUP BY depot_code
HAVING COUNT(DISTINCT depot_phone) > 1;

-- Expected result:
-- depot_code
-- DEP-FLL

-- Detail for the one conflict:
SELECT work_order_no, depot_code, depot_phone
FROM work_orders_unf
WHERE depot_code = 'DEP-FLL'
  AND depot_phone = '(954) 555-0181'
ORDER BY work_order_no;

-- Expected result:
-- WO-50041 | DEP-FLL | (954) 555-0181
-- WO-50047 | DEP-FLL | (954) 555-0181

-- Resolution rule:
-- Use (954) 555-0118 as the authoritative DEP-FLL phone because it
-- is the consistent majority value. Correct the two outlier work orders
-- before loading the normalized DEPOT table.

-- ================================================================
-- CHECK 15: mechanic_id -> mechanic_name
-- Result: 0 rows.
SELECT mechanic_id
FROM work_orders_unf
GROUP BY mechanic_id
HAVING COUNT(DISTINCT mechanic_name) > 1;

-- ================================================================
-- CHECK 16: mechanic_id -> mechanic_cert_level
-- Result: 0 rows.
SELECT mechanic_id
FROM work_orders_unf
GROUP BY mechanic_id
HAVING COUNT(DISTINCT mechanic_cert_level) > 1;

-- ================================================================
-- CHECK 17: mechanic_cert_level -> cert_hourly_rate
-- Result: 0 rows.
SELECT mechanic_cert_level
FROM work_orders_unf
GROUP BY mechanic_cert_level
HAVING COUNT(DISTINCT cert_hourly_rate) > 1;

-- ================================================================
-- CHECK 18: part_code -> part_name
-- The following four-slot CTE converts the repeated groups into 1NF rows.
-- Result: 0 rows.
WITH parts AS (
    SELECT part1_code AS part_code, part1_name AS part_name FROM work_orders_unf WHERE part1_code IS NOT NULL
    UNION ALL SELECT part2_code, part2_name FROM work_orders_unf WHERE part2_code IS NOT NULL
    UNION ALL SELECT part3_code, part3_name FROM work_orders_unf WHERE part3_code IS NOT NULL
    UNION ALL SELECT part4_code, part4_name FROM work_orders_unf WHERE part4_code IS NOT NULL
)
SELECT part_code
FROM parts
GROUP BY part_code
HAVING COUNT(DISTINCT part_name) > 1;

-- ================================================================
-- CHECK 19: part_code -> part_unit_cost
-- Result: 0 rows.
WITH parts AS (
    SELECT part1_code AS part_code, part1_unit_cost AS part_unit_cost FROM work_orders_unf WHERE part1_code IS NOT NULL
    UNION ALL SELECT part2_code, part2_unit_cost FROM work_orders_unf WHERE part2_code IS NOT NULL
    UNION ALL SELECT part3_code, part3_unit_cost FROM work_orders_unf WHERE part3_code IS NOT NULL
    UNION ALL SELECT part4_code, part4_unit_cost FROM work_orders_unf WHERE part4_code IS NOT NULL
)
SELECT part_code
FROM parts
GROUP BY part_code
HAVING COUNT(DISTINCT part_unit_cost) > 1;

-- ================================================================
-- CHECK 20: part_code -> supplier_id
-- Result: 0 rows.
WITH parts AS (
    SELECT part1_code AS part_code, part1_supplier_id AS supplier_id FROM work_orders_unf WHERE part1_code IS NOT NULL
    UNION ALL SELECT part2_code, part2_supplier_id FROM work_orders_unf WHERE part2_code IS NOT NULL
    UNION ALL SELECT part3_code, part3_supplier_id FROM work_orders_unf WHERE part3_code IS NOT NULL
    UNION ALL SELECT part4_code, part4_supplier_id FROM work_orders_unf WHERE part4_code IS NOT NULL
)
SELECT part_code
FROM parts
GROUP BY part_code
HAVING COUNT(DISTINCT supplier_id) > 1;

-- ================================================================
-- CHECK 21: supplier_id -> supplier_name
-- Result: 0 rows.
WITH suppliers AS (
    SELECT part1_supplier_id AS supplier_id, part1_supplier_name AS supplier_name FROM work_orders_unf WHERE part1_supplier_id IS NOT NULL
    UNION ALL SELECT part2_supplier_id, part2_supplier_name FROM work_orders_unf WHERE part2_supplier_id IS NOT NULL
    UNION ALL SELECT part3_supplier_id, part3_supplier_name FROM work_orders_unf WHERE part3_supplier_id IS NOT NULL
    UNION ALL SELECT part4_supplier_id, part4_supplier_name FROM work_orders_unf WHERE part4_supplier_id IS NOT NULL
)
SELECT supplier_id
FROM suppliers
GROUP BY supplier_id
HAVING COUNT(DISTINCT supplier_name) > 1;

-- ================================================================
-- CHECK 22: supplier_id -> supplier_phone
-- Result: 0 rows.
WITH suppliers AS (
    SELECT part1_supplier_id AS supplier_id, part1_supplier_phone AS supplier_phone FROM work_orders_unf WHERE part1_supplier_id IS NOT NULL
    UNION ALL SELECT part2_supplier_id, part2_supplier_phone FROM work_orders_unf WHERE part2_supplier_id IS NOT NULL
    UNION ALL SELECT part3_supplier_id, part3_supplier_phone FROM work_orders_unf WHERE part3_supplier_id IS NOT NULL
    UNION ALL SELECT part4_supplier_id, part4_supplier_phone FROM work_orders_unf WHERE part4_supplier_id IS NOT NULL
)
SELECT supplier_id
FROM suppliers
GROUP BY supplier_id
HAVING COUNT(DISTINCT supplier_phone) > 1;

-- ================================================================
-- CHECK 23: composite 1NF key uniqueness
-- Result: 0 rows (no duplicate key groups).
WITH parts AS (
    SELECT work_order_no, part1_code AS part_code FROM work_orders_unf WHERE part1_code IS NOT NULL
    UNION ALL SELECT work_order_no, part2_code FROM work_orders_unf WHERE part2_code IS NOT NULL
    UNION ALL SELECT work_order_no, part3_code FROM work_orders_unf WHERE part3_code IS NOT NULL
    UNION ALL SELECT work_order_no, part4_code FROM work_orders_unf WHERE part4_code IS NOT NULL
)
SELECT work_order_no, part_code
FROM parts
GROUP BY work_order_no, part_code
HAVING COUNT(*) > 1;
