-- CIT 408 Module 2 Assignment 2.3 — Superstore 3NF
-- Run while connected to the superstore database, after staging import.
CREATE TABLE public.customers (
    customer_id TEXT PRIMARY KEY,
    customer_name TEXT NOT NULL,
    segment TEXT NOT NULL
);
CREATE TABLE public.states (
    state TEXT PRIMARY KEY,
    region TEXT NOT NULL
);
CREATE TABLE public.locations (
    location_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country TEXT NOT NULL,
    state TEXT NOT NULL REFERENCES public.states(state),
    city TEXT NOT NULL,
    postal_code TEXT NOT NULL,
    UNIQUE (country, state, city, postal_code)
);
CREATE TABLE public.orders (
    order_id TEXT PRIMARY KEY,
    order_date DATE NOT NULL,
    ship_date DATE NOT NULL,
    ship_mode TEXT NOT NULL,
    customer_id TEXT NOT NULL REFERENCES public.customers(customer_id),
    location_id BIGINT NOT NULL REFERENCES public.locations(location_id),
    CHECK (ship_date >= order_date)
);
CREATE TABLE public.categories (
    category_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_name TEXT NOT NULL UNIQUE
);
CREATE TABLE public.subcategories (
    subcategory_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    subcategory_name TEXT NOT NULL UNIQUE,
    category_id BIGINT NOT NULL REFERENCES public.categories(category_id)
);
CREATE TABLE public.products (
    product_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id TEXT NOT NULL,
    product_name TEXT NOT NULL,
    subcategory_id BIGINT NOT NULL REFERENCES public.subcategories(subcategory_id),
    UNIQUE (product_id, product_name)
);
CREATE TABLE public.order_lines (
    row_id INTEGER PRIMARY KEY,
    order_id TEXT NOT NULL REFERENCES public.orders(order_id),
    product_key BIGINT NOT NULL REFERENCES public.products(product_key),
    sales NUMERIC(18,6) NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    discount NUMERIC(7,6) NOT NULL CHECK (discount BETWEEN 0 AND 1),
    profit NUMERIC(18,6) NOT NULL
);
