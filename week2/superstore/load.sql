-- CIT 408 Module 2 Assignment 2.3 — Stage raw CSV
-- Part A: Run the following statement connected to the existing 'postgres' database
-- (CREATE DATABASE cannot run in a transaction or from within superstore).
CREATE DATABASE superstore;

-- Part B: Switch pgAdmin Query Tool connection to superstore, then run:
-- (Do not run CREATE DATABASE again if the database already exists.)
CREATE TABLE public.staging_superstore (
    row_id TEXT, order_id TEXT, order_date TEXT, ship_date TEXT,
    ship_mode TEXT, customer_id TEXT, customer_name TEXT, segment TEXT,
    country TEXT, city TEXT, state TEXT, postal_code TEXT, region TEXT,
    product_id TEXT, category TEXT, sub_category TEXT, product_name TEXT,
    sales TEXT, quantity TEXT, discount TEXT, profit TEXT
);

-- Part C: CSV import via pgAdmin 4:
-- Right-click public.staging_superstore > Import/Export Data > Import.
-- Choose local Superstore.csv, format CSV, header Yes, delimiter comma,
-- quote double quote, encoding WIN1252, On Error stop.
-- The original CSV failed under UTF8 (byte 0xA0 at line 13);
-- re-import with WIN1252 succeeded.
-- Equivalent psql command (ONLY in psql, NOT standard pgAdmin Query Tool):
-- \copy public.staging_superstore FROM 'C:/path/to/Superstore.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'WIN1252');

-- Part D: Run after importing:
SELECT COUNT(*) AS staging_rows FROM public.staging_superstore;
-- Observed: 9994
