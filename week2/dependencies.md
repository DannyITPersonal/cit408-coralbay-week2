# Functional Dependencies

## 1NF relation and key

After converting the four numbered part groups into rows, the 1NF relation is:

`WORK_ORDER_PART_1NF(work_order_no, open_date, close_date, truck_id, truck_vin, truck_make, truck_model, truck_year, depot_code, depot_name, depot_city, depot_phone, mechanic_id, mechanic_name, mechanic_cert_level, cert_hourly_rate, labor_hours, problem_description, part_code, part_name, part_unit_cost, part_qty, supplier_id, supplier_name, supplier_phone)`

The chosen 1NF primary key is **(work_order_no, part_code)**. `work_order_no` identifies one repair work order, while `part_code` identifies which part line belongs to that work order. The uploaded data contains no duplicate `(work_order_no, part_code)` pairs.

## Dependencies relative to the composite 1NF key

### Full dependency

1. **(work_order_no, part_code) -> part_qty** — **full**.
   Quantity describes the occurrence of a particular part on a particular work order. Neither `work_order_no` nor `part_code` alone is sufficient to identify the quantity.

### Partial dependencies

2. **work_order_no -> open_date, close_date, truck_id, depot_code, mechanic_id, labor_hours, problem_description** — **partial**.
   These attributes describe the work order and depend only on part of the composite key.

3. **part_code -> part_name, part_unit_cost, supplier_id** — **partial**.
   These attributes describe the part and depend only on the part-code portion of the composite key.

### Transitive dependencies

4. **truck_id -> truck_vin, truck_make, truck_model, truck_year** — **transitive** relative to the 1NF key because `(work_order_no, part_code) -> truck_id -> truck attributes`.

5. **depot_code -> depot_name, depot_city, depot_phone** — **transitive after the single source-data conflict is resolved**. The file has one conflicting phone value for `DEP-FLL`; the majority value is the authoritative value selected for normalization.

6. **mechanic_id -> mechanic_name, mechanic_cert_level** — **transitive** relative to the 1NF key.

7. **mechanic_cert_level -> cert_hourly_rate** — **transitive** relative to the 1NF key through `mechanic_id`.

8. **supplier_id -> supplier_name, supplier_phone** — **transitive** relative to the 1NF key through `part_code`.

9. **part_code -> supplier_id** — already included in dependency 3; it creates the transitive path from the 1NF key to supplier details.

## Data-quality conflict

The dependency `depot_code -> depot_phone` is violated by exactly one determinant in the source data:

`DEP-FLL -> (954) 555-0118` and `(954) 555-0181`.

The `(954) 555-0181` value occurs on two work orders, while `(954) 555-0118` occurs on the remaining DEP-FLL work orders. The normalization rule is to use the **majority/consistent depot master value, (954) 555-0118**, and correct the two outlier work orders before loading the normalized DEPOT table. This preserves the intended business rule that one depot code identifies one depot phone.
