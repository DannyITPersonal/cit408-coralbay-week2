# CIT 408 – Module 2 – Assignment 2.3
## Superstore Database Normalization to Third Normal Form (3NF)

**Student:** Daniel Zayas  
**Course:** CIT 408  
**Assignment:** Module 2 – Assignment 2.3  
**Topic:** Superstore Database Design and Normalization

## 1. Source Data, Staging, and Import

For this assignment, I used the original Superstore CSV file, which contains 9,994 order-line records and 21 columns. I worked with PostgreSQL through pgAdmin and Supabase to import the data, examine its structure, and build a normalized database.

My first attempt to import the CSV using UTF-8 encoding failed because the file contained a character that PostgreSQL could not read correctly on line 13. After changing the encoding to WIN1252 in pgAdmin's Import/Export settings, the import completed successfully.

I loaded the original data into `public.staging_superstore`. I kept the staging columns as TEXT so that the original values could be imported before converting them into the appropriate data types in the final tables. I then ran a record-count query and confirmed that all 9,994 rows had been imported.

## 2. First Normal Form (1NF) and Choosing the Primary Key

The first step was to determine whether the original data met the requirements of First Normal Form (1NF). Each record represents an individual order line, and each column contains a single value. This means the data follows the basic structure required for 1NF.

Next, I checked whether `row_id` could be used as the primary key. My queries showed that all 9,994 records had unique row IDs, with no duplicates or missing values. Based on these results, I selected `row_id` as the primary key for the `order_lines` table.

I also checked the number of distinct order IDs. The dataset contained 5,009 unique orders, meaning some orders included multiple products. Because of this, `order_id` could not serve as the primary key for individual order lines.

## 3. Functional Dependency Checks

Before creating the final tables, I tested the relationships between different columns to determine which attributes belonged together. I saved the SQL statements used for these checks in `fd_checks.sql`.

I used GROUP BY and HAVING COUNT(DISTINCT ...) queries to identify cases where one value was associated with more than one value in another column. I also checked for missing values separately because COUNT(DISTINCT ...) does not count SQL NULL values.

The following table summarizes the results and the design decisions I made.

| Functional dependency tested | Result from the dataset | Design decision |
|---|---|---|
| `customer_id → customer_name` | No conflicting customer names were found. | Store customer names in `customers`. |
| `customer_id → segment` | No conflicting customer segments were found. | Store customer segments in `customers`. |
| `order_id → order_date, ship_date, ship_mode, customer_id` | No conflicting orders were found in the combined check. | Store order-level information in `orders`. |
| `order_id → country, city, state, postal_code, region` | No conflicting locations were found for the same order in the combined check. | Reference locations from `orders`. |
| `product_id → product_name` | 32 product IDs were associated with two different product names each. | Do not make `product_id` unique by itself. |
| `(product_id, product_name) → category, sub_category` | No conflicting category or subcategory combinations were found. | Use the product ID and product name together as an alternate key. |
| `postal_code → city` | Postal code 92024 appeared with both Encinitas and San Diego, California. | Use a combination of location attributes instead of postal code alone. |
| `state → region` | No conflicting regions were found for the same state. | Store the region in `states`. |
| `sub_category → category` | No conflicting category relationships were found. | Connect `subcategories` to `categories`. |

One important finding involved the product records. The source file contained 1,862 distinct product IDs but 1,894 distinct combinations of product ID and product name. This showed that 32 product IDs were associated with two different names each.

To preserve the original records, I did not assume that each product ID represented only one unique product description. Instead, I used a database-generated `product_key` as the primary key and added a UNIQUE constraint on `(product_id, product_name)`. This approach allowed me to preserve all product combinations without losing any sales records.

I also found that postal code 92024 was associated with both Encinitas and San Diego. Because of this, I used the complete combination of country, state, city, and postal code to identify each location. The dataset contained 632 unique combinations. This design avoids incorrectly treating a postal code as a unique location identifier.

These findings describe the supplied dataset. They should not automatically be treated as universal rules for every retail database.

## 4. Second Normal Form (2NF)

Second Normal Form requires a table to be in 1NF and to have no partial dependencies on part of a composite candidate key.

The `order_lines` table uses `row_id` as a single-column primary key, so it does not have a composite primary key that would create partial dependencies. The sales amount, quantity, discount, and profit are stored with the individual order line they describe.

I also separated customer information, order details, product descriptions, and location information into their own tables. This reduces repeated information and makes the database easier to maintain.

For products, I used the surrogate key `product_key` while retaining the unique `(product_id, product_name)` combination as an alternate candidate key.

## 5. Third Normal Form (3NF)

Third Normal Form requires the tables to be in 2NF and prevents non-key attributes from depending on other non-key attributes instead of the table's key.

To meet this requirement, I organized the database so that each table stores information about one main subject:

- `customers` stores customer names and segments.
- `orders` stores order dates, shipping details, customer references, and location references.
- `states` stores the region associated with each state.
- `locations` stores country, state, city, and postal code combinations.
- `categories` stores product category names.
- `subcategories` connects each subcategory to its category.
- `products` stores product IDs, product names, and subcategory references.
- `order_lines` stores the individual sales transactions and their numeric measures.

With this structure, the order-line table no longer needs to repeat customer names, shipping details, product descriptions, or location information for every item purchased.

I also added primary keys, foreign keys, UNIQUE constraints, NOT NULL constraints, and CHECK constraints where appropriate. These constraints help keep the database consistent and prevent invalid data from being entered.

## 6. Final Database Tables

The final normalized design contains eight tables.

| Table | Main columns and data types | Primary key |
|---|---|---|
| `customers` | `customer_id TEXT`, `customer_name TEXT`, `segment TEXT` | `customer_id` |
| `states` | `state TEXT`, `region TEXT` | `state` |
| `locations` | `location_id BIGINT IDENTITY`, `country TEXT`, `state TEXT`, `city TEXT`, `postal_code TEXT` | `location_id` |
| `orders` | `order_id TEXT`, `order_date DATE`, `ship_date DATE`, `ship_mode TEXT`, `customer_id TEXT`, `location_id BIGINT` | `order_id` |
| `categories` | `category_id BIGINT IDENTITY`, `category_name TEXT` | `category_id` |
| `subcategories` | `subcategory_id BIGINT IDENTITY`, `subcategory_name TEXT`, `category_id BIGINT` | `subcategory_id` |
| `products` | `product_key BIGINT IDENTITY`, `product_id TEXT`, `product_name TEXT`, `subcategory_id BIGINT` | `product_key` |
| `order_lines` | `row_id INTEGER`, `order_id TEXT`, `product_key BIGINT`, `sales NUMERIC(18,6)`, `quantity INTEGER`, `discount NUMERIC(7,6)`, `profit NUMERIC(18,6)` | `row_id` |

### Relationships and constraints

The normalized database uses seven foreign-key relationships:

1. `locations.state` references `states.state`.
2. `orders.customer_id` references `customers.customer_id`.
3. `orders.location_id` references `locations.location_id`.
4. `subcategories.category_id` references `categories.category_id`.
5. `products.subcategory_id` references `subcategories.subcategory_id`.
6. `order_lines.order_id` references `orders.order_id`.
7. `order_lines.product_key` references `products.product_key`.

The foreign-key columns are defined as NOT NULL. The database also includes the following additional constraints:

- Category names must be unique.
- Subcategory names must be unique.
- The combination of product ID and product name must be unique.
- The combination of country, state, city, and postal code must be unique in `locations`.
- A shipping date cannot be earlier than an order date.
- Order-line quantity must be greater than zero.
- Discount must be between 0 and 1.

The `IDENTITY` columns generate surrogate IDs automatically. The original `staging_superstore` table remains available for importing and comparing the source data, but it is not part of the normalized ERD.

## 7. Loading and Validation Results

After creating the tables, I loaded the source data into the normalized structure and ran validation queries to check the results.

The source missing-value checks returned zero missing values for the tested fields, including order IDs, customer IDs, product IDs, product names, dates, sales, quantities, cities, states, regions, subcategories, shipping modes, discounts, profits, and postal codes.

I also checked the shipping dates and found no orders with shipping dates earlier than their order dates.

The final table counts were as follows:

| Table | Number of records |
|---|---:|
| `categories` | 3 |
| `customers` | 793 |
| `locations` | 632 |
| `order_lines` | 9,994 |
| `orders` | 5,009 |
| `products` | 1,894 |
| `staging_superstore` | 9,994 |
| `states` | 49 |
| `subcategories` | 17 |

I then joined the normalized tables to check whether the original order-line records could be reconstructed. The join across all eight normalized tables returned 9,994 lines, matching the number of records in the staging table.

I also compared the total sales from the original staging table with the total sales from the normalized join.

- **Staging sales total:** 2,297,200.8603
- **Normalized sales total:** 2,297,200.860300

The totals matched, confirming that the normalization and loading process preserved the sales amounts.

Finally, I tested the foreign-key constraints by attempting to insert an order line with a nonexistent `product_key` of `-999999`. PostgreSQL rejected the insert with SQLSTATE `23503`, which identifies a foreign-key violation. This confirmed that the database prevents an order line from referencing a product that does not exist.

## 8. Reproducing the Results in pgAdmin and Supabase

To reproduce my work, I followed this general sequence:

1. Connect pgAdmin to the correct Supabase PostgreSQL database.
2. Run the database creation and staging table statements from `load.sql`, making sure to connect to the intended database first.
3. Import the original Superstore CSV into `staging_superstore` using WIN1252 encoding.
4. Run `fd_checks.sql` and review the functional dependency results before finalizing the table design.
5. Run `create_tables.sql` against an empty normalized schema.
6. Run `load_data.sql` once to populate the normalized tables.
7. Run `verify.sql` to check table counts, relationships, and sales totals.
8. Execute the foreign-key failure test separately and save a screenshot showing PostgreSQL's expected `23503` error.

The table creation and loading scripts should be run in the intended order. The creation script is designed for an empty normalized schema, and the loading script should not be run repeatedly without first accounting for the existing data.

The failed foreign-key insert should also be executed separately from the other verification queries. After capturing the expected error, run `ROLLBACK` as appropriate for the transaction state before continuing.

## 9. Conclusion

This assignment gave me practical experience with database normalization, functional dependency testing, primary-key selection, foreign-key relationships, and data validation in PostgreSQL.

One of the biggest lessons from this project was that the original data needed to be examined before making assumptions about its structure. For example, the product ID conflicts showed why I could not safely use `product_id` alone as a unique product identifier. The postal-code results also demonstrated why a combination of location attributes was more appropriate for identifying locations in this dataset.

By separating customers, orders, locations, states, products, categories, subcategories, and order lines into their own tables, I created a structure that reduces unnecessary duplication and enforces data integrity.

The final checks confirmed that all 9,994 order lines were preserved, the normalized sales total matched the staging total, and the foreign-key constraints rejected invalid references. Overall, the completed design meets the assignment's normalization goals for the supplied Superstore dataset and provides a reproducible database structure for further querying and analysis.
