# CIT 408 — Week 2: Coral Bay Work Orders Normalization

**Student:** Daniel Zayas
**Course:** CIT 408 — Database Design
**Assignment** Coral Bay Fleet Maintenance Work Orders
**Repository:** `cit408-coralbay`
**Folder:** `week2/`

## Project Overview

This assignment focuses on normalizing a work-order spreadsheet used by Coral Bay's fleet maintenance team.

The original file, `coralbay_work_orders_unf.csv`, contains 1,100 work orders. Each record includes information about the work order, truck, depot, mechanic, and parts used during the repair.

The original file also has repeating groups for up to four parts. For example, the file contains columns such as:

```text
part1_code
part1_description
part1_supplier
part1_supplier_phone
```

with similar columns for parts 2, 3, and 4.

The goal of this assignment is to take the original structure through **1NF, 2NF, and 3NF** by using the actual data and functional dependencies to determine where each piece of information belongs.

## Activity 2.2

I completed Activity 2.2 before starting the normalization work.

The screenshot of the results is saved as:

```text
simulator_results.png
```

## Loading the Data

The CSV file and the provided SQL load script were copied into the PostgreSQL container using:

```bash
docker cp ~/coralbay/week2/coralbay_work_orders_unf.csv pg18:/tmp/

docker cp ~/coralbay/week2/w2_assignment_load_work_orders.sql pg18:/tmp/

docker exec -it pg18 psql -U postgres -d coralbay -f /tmp/w2_assignment_load_work_orders.sql
```

The assignment requires the final output to show:

```text
1100
```

This confirms that the expected number of work orders was loaded.

## Exploring the Data

I explored the original data before deciding on the final database structure.

The queries are saved in:

```text
explore.sql
```

The queries examine different parts of the data, including distinct values, sample records, and empty part slots.

This step helped me understand the actual relationships in the data before selecting keys and designing the normalized tables.

# 1NF — First Normal Form

The main problem with the original file is the repeating part groups.

Parts are stored in separate numbered column groups instead of being represented as individual records. This makes the original structure difficult to expand and creates unnecessary repetition.

For 1NF, the repeating part groups are converted into rows so that each work-order/part combination can be represented individually.

The 1NF key was selected after checking the data for uniqueness.

The 1NF structure and key are documented in `design.md`.

# Functional Dependencies

The functional dependencies identified from the data are documented in:

```text
dependencies.md
```

Each dependency is classified as:

* **Full**
* **Partial**
* **Transitive**

The classification is based on the selected 1NF key.

The dependencies were determined by testing the actual data rather than assuming that every ID column was automatically unique.

# Dependency Checks

The SQL checks for the dependencies are stored in:

```text
fd_checks.sql
```

Each dependency is tested using a `GROUP BY` query with:

```sql
HAVING COUNT(DISTINCT ...) > 1
```

A dependency that returns zero rows is consistent with the data.

The results of the checks are included as comments underneath the corresponding queries.

# 2NF Design

After establishing the 1NF structure, I removed the partial dependencies.

The 2NF design separates information that depends on only part of the composite key.

The tables at this stage are documented in `design.md`.

The main entities identified during the normalization process include:

### `work_order`

Contains information that belongs to the work order itself.

### `part`

Contains information that describes a specific part.

### `work_order_part`

Connects the work orders to the parts used during each repair.

### `truck`

Contains information that belongs to the truck.

### `depot`

Contains information that belongs to the depot.

### `mechanic`

Contains information that belongs to the mechanic.

The exact columns and keys for each table are listed in `design.md`.

# 3NF Design

After reaching 2NF, I checked the tables for transitive dependencies.

The final 3NF design separates information that depends on another non-key attribute into its appropriate table.

The final design uses the following main tables:

```text
work_order
truck
depot
mechanic
part
supplier
work_order_part
```

### `work_order`

Stores information specific to each work order.

**Primary key:** `work_order_id`

Foreign keys connect the work order to the appropriate truck, depot, and mechanic.

### `truck`

Stores information that describes each truck.

**Primary key:** `truck_id`

### `depot`

Stores information that describes each depot.

**Primary key:** `depot_id`

### `mechanic`

Stores information that describes each mechanic.

**Primary key:** `mechanic_id`

### `part`

Stores information that describes each part.

**Primary key:** `part_code`

The supplier relationship is represented through a foreign key rather than repeating supplier information for every part.

### `supplier`

Stores information about each supplier.

**Primary key:** `supplier_id`

Supplier information is separated from the part information to avoid a transitive dependency.

### `work_order_part`

Connects a work order to the parts used on that work order.

The table uses the appropriate work-order and part identifiers as foreign keys.

The exact columns, primary keys, and foreign keys are documented in `design.md`.

# Data Conflict

One of the functional dependency checks returns a result instead of zero rows.

The assignment specifies that there is exactly one conflicting value in the source data.

I investigated the affected records and documented:

* The dependency that failed
* The conflicting value
* The affected work orders
* The rule used to resolve the conflict
* The reason for choosing that rule

This information is included in the dependency documentation.

---

# Final 3NF Relationships

The final design can be summarized as:

```text
             ┌──────────┐
             │  truck   │
             └────┬─────┘
                  │
                  │
             ┌────▼─────┐
             │work_order│
             └────┬─────┘
                  │
                  │
          ┌───────▼────────┐
          │ work_order_part│
          └───────┬────────┘
                  │
                  │
             ┌────▼─────┐
             │   part   │
             └────┬─────┘
                  │
                  │
             ┌────▼─────┐
             │ supplier │
             └──────────┘

        work_order also
        connects to:

          ┌─────────┐
          │  depot  │
          └─────────┘

          ┌─────────┐
          │ mechanic│
          └─────────┘
```

The actual ERD is saved as:

```text
erd.png
```

# ERD

The final entity relationship diagram represents the 3NF design.

It includes:

* `work_order`
* `truck`
* `depot`
* `mechanic`
* `part`
* `supplier`
* `work_order_part`

The ERD shows the primary keys, foreign keys, and relationships between the tables.

# Files Included

| File                    | Purpose                                     |
| ----------------------- | ------------------------------------------- |
| `simulator_results.png` | Activity 2.2 results screenshot             |
| `explore.sql`           | Data exploration queries                    |
| `dependencies.md`       | Functional dependencies and classifications |
| `fd_checks.sql`         | Dependency proof queries and results        |
| `design.md`             | 1NF, 2NF, and 3NF designs                   |
| `erd.png`               | Final 3NF ERD                               |


# Normalization Process

The overall process for the assignment was:

```text
Original UNF File
       ↓
Explore the Data
       ↓
Identify the Repeating Groups
       ↓
1NF
       ↓
Remove Partial Dependencies
       ↓
2NF
       ↓
Remove Transitive Dependencies
       ↓
3NF
       ↓
Create the Final ERD
```

The final design is based on the functional dependencies found in the source data.

**Student:** Daniel Zayas
**Course:** CIT 408 — Database Design
https://github.com/DannyITPersonal/cit408-coralbay-week2/tree/main/week2
