# Week 2 submission folder

Files generated from the uploaded `coralbay_work_orders_unf.csv`:

- `explore.sql`
- `dependencies.md`
- `fd_checks.sql`
- `design.md`
- `erd.png`
- `simulator_results.png` — PLACEHOLDER ONLY; replace with the actual Activity 2.2 screenshot.

Important: the SQL assumes the load script creates a table named `work_orders_unf`. If your instructor's load script uses a different table name, replace that table name in the SQL files.

Data finding: the source has 1,100 work orders, 2,258 non-empty part rows after flattening, 40 trucks, 4 depots, 18 mechanics, 24 distinct parts, and 4 suppliers. The only dependency conflict found is `DEP-FLL -> depot_phone`, caused by two work orders using `(954) 555-0181` instead of the majority `(954) 555-0118`.
