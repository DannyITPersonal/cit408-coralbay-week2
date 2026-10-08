# Coral Bay Logistics — Normalization Design

## 1. Why the source is not in 1NF

The source sheet is not in First Normal Form because each work-order row contains repeating groups for parts: `part1_*`, `part2_*`, `part3_*`, and `part4_*`. The same kind of fact is represented by multiple numbered column groups instead of one atomic part-line row. A work order can therefore contain zero to four part groups, and the design has to be changed so each part occurrence is represented as its own row.

To reach 1NF, the four part groups are flattened into one `part_code`, `part_name`, `part_unit_cost`, `part_qty`, `supplier_id`, `supplier_name`, and `supplier_phone` set per row.

### 1NF relation

`WORK_ORDER_PART_1NF`

| Column | Key/Role |
|---|---|
| work_order_no | PK part 1 |
| part_code | PK part 2 |
| open_date | attribute |
| close_date | attribute |
| truck_id | attribute |
| truck_vin | attribute |
| truck_make | attribute |
| truck_model | attribute |
| truck_year | attribute |
| depot_code | attribute |
| depot_name | attribute |
| depot_city | attribute |
| depot_phone | attribute |
| mechanic_id | attribute |
| mechanic_name | attribute |
| mechanic_cert_level | attribute |
| cert_hourly_rate | attribute |
| labor_hours | attribute |
| problem_description | attribute |
| part_name | attribute |
| part_unit_cost | attribute |
| part_qty | attribute |
| supplier_id | attribute |
| supplier_name | attribute |
| supplier_phone | attribute |

**Primary key:** `(work_order_no, part_code)`

The key is unique after the repeating groups are converted to rows. The proof query is included in `fd_checks.sql`.

## 2. Second Normal Form

2NF removes attributes that depend on only part of the composite 1NF key.

### WORK_ORDER_2NF
**PK:** `work_order_no`

Columns:
- work_order_no
- open_date
- close_date
- truck_id
- truck_vin
- truck_make
- truck_model
- truck_year
- depot_code
- depot_name
- depot_city
- depot_phone
- mechanic_id
- mechanic_name
- mechanic_cert_level
- cert_hourly_rate
- labor_hours
- problem_description

### PART_2NF
**PK:** `part_code`

Columns:
- part_code
- part_name
- part_unit_cost
- supplier_id
- supplier_name
- supplier_phone

### WORK_ORDER_PART_2NF
**PK:** `(work_order_no, part_code)`

**FK:** `work_order_no -> WORK_ORDER_2NF.work_order_no`
**FK:** `part_code -> PART_2NF.part_code`

Columns:
- work_order_no
- part_code
- part_qty

At this point, work-order attributes depend on `work_order_no`, part attributes depend on `part_code`, and quantity depends on the full composite key.

## 3. Third Normal Form

3NF removes transitive dependencies so non-key attributes depend on the key, the whole key, and nothing but the key.

### WORK_ORDER
**PK:** `work_order_no`

Columns:
- work_order_no
- open_date
- close_date
- truck_id
- depot_code
- mechanic_id
- labor_hours
- problem_description

**FKs:**
- `truck_id -> TRUCK.truck_id`
- `depot_code -> DEPOT.depot_code`
- `mechanic_id -> MECHANIC.mechanic_id`

### TRUCK
**PK:** `truck_id`

Columns:
- truck_id
- truck_vin
- truck_make
- truck_model
- truck_year

### DEPOT
**PK:** `depot_code`

Columns:
- depot_code
- depot_name
- depot_city
- depot_phone

### CERTIFICATION
**PK:** `cert_level`

Columns:
- cert_level
- cert_hourly_rate

### MECHANIC
**PK:** `mechanic_id`

Columns:
- mechanic_id
- mechanic_name
- cert_level

**FK:** `cert_level -> CERTIFICATION.cert_level`

### SUPPLIER
**PK:** `supplier_id`

Columns:
- supplier_id
- supplier_name
- supplier_phone

### PART
**PK:** `part_code`

Columns:
- part_code
- part_name
- part_unit_cost
- supplier_id

**FK:** `supplier_id -> SUPPLIER.supplier_id`

### WORK_ORDER_PART
**PK:** `(work_order_no, part_code)`

Columns:
- work_order_no
- part_code
- part_qty

**FKs:**
- `work_order_no -> WORK_ORDER.work_order_no`
- `part_code -> PART.part_code`

## Data conflict resolution

The source contains one dependency conflict for `depot_code -> depot_phone`. `DEP-FLL` appears with `(954) 555-0118` on the large majority of its work orders and `(954) 555-0181` on exactly two work orders: `WO-50041` and `WO-50047`.

The normalization rule is to treat the consistent majority depot-master value `(954) 555-0118` as authoritative and correct the two outlier rows before populating `DEPOT`. This makes `depot_code -> depot_phone` a valid dependency in the normalized design.

## Final 3NF relationships

- One `TRUCK` can have many `WORK_ORDER` records.
- One `DEPOT` can have many `WORK_ORDER` records.
- One `MECHANIC` can have many `WORK_ORDER` records.
- One `CERTIFICATION` can apply to many `MECHANIC` records.
- One `SUPPLIER` can supply many `PART` records.
- One `WORK_ORDER` can contain many `PART` records through `WORK_ORDER_PART`.
- One `PART` can appear on many `WORK_ORDER` records through `WORK_ORDER_PART`.

This design removes repeating groups, partial dependencies, and transitive dependencies while preserving the business facts in the source.
