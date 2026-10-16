-- CIT 408 Week 3: recovery drill, part 1 (setup)
-- Run this against an empty database named drill:
--   psql -U postgres -d drill -f w3_drill_setup.sql
-- It builds a small Coral Bay dispatch system and fills it with data.

\set ON_ERROR_STOP on
SET client_min_messages = warning;
SELECT setseed(0.408) AS seeded \gset

DROP SCHEMA IF EXISTS drill CASCADE;
CREATE SCHEMA drill;

CREATE TABLE drill.customer (
    customer_id   integer      PRIMARY KEY,
    customer_name varchar(60)  NOT NULL,
    city          varchar(40)  NOT NULL
);

CREATE TABLE drill.dispatch (
    dispatch_id    integer       PRIMARY KEY,
    customer_id    integer       NOT NULL REFERENCES drill.customer,
    dispatch_date  date          NOT NULL,
    freight_charge numeric(10,2) NOT NULL CHECK (freight_charge >= 0),
    batch_no       integer       NOT NULL DEFAULT 0
);

CREATE TABLE drill.dispatch_line (
    dispatch_id    integer      NOT NULL REFERENCES drill.dispatch,
    line_no        smallint     NOT NULL,
    commodity      varchar(40)  NOT NULL,
    quantity       integer      NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (dispatch_id, line_no)
);

-- One row per batch of work the dispatch office commits during the drill
CREATE TABLE drill.activity (
    batch_no       integer      PRIMARY KEY,
    dispatches     integer      NOT NULL,
    lines          integer      NOT NULL,
    committed_at   timestamptz  NOT NULL DEFAULT clock_timestamp()
);

INSERT INTO drill.customer
SELECT g,
       (ARRAY['Bayfront','Sunrise','Coastal','Palmetto','Biscayne','Atlantic','Harbor','Citrus','Tropic','Mangrove'])[1 + (g % 10)]
       || ' ' ||
       (ARRAY['Builders Supply','Hardware','Marine Supply','Wholesale Foods','Pool Supply','Medical Supply','Electrical','Home Center'])[1 + (g % 8)]
       || ' #' || g,
       (ARRAY['Miami','Doral','Hialeah','Fort Lauderdale','Hollywood','West Palm Beach','Homestead','Naples','Tampa','Orlando'])[1 + (g % 10)]
FROM generate_series(1, 500) g;

INSERT INTO drill.dispatch (dispatch_id, customer_id, dispatch_date, freight_charge)
SELECT g,
       1 + floor(random() * 500)::int,
       date '2026-01-02' + (g / 80),
       round((150 + random() * 2200)::numeric, 2)
FROM generate_series(1, 20000) g;

INSERT INTO drill.dispatch_line
SELECT d.dispatch_id, l,
       (ARRAY['Ceramic tile pallet','Drywall bundle','PVC pipe bundle','Pool chlorine drum','Frozen seafood pallet',
              'Lumber bundle','Paint bucket pallet','Air conditioner unit','Copper wire spool','Canned goods pallet'])[1 + floor(random() * 10)::int],
       1 + floor(random() * 12)::int
FROM drill.dispatch d
CROSS JOIN LATERAL generate_series(1, 1 + (d.dispatch_id % 4)) l;

ANALYZE;

SELECT (SELECT count(*) FROM drill.customer)      AS customers,       -- 500
       (SELECT count(*) FROM drill.dispatch)      AS dispatches,      -- 20000
       (SELECT count(*) FROM drill.dispatch_line) AS dispatch_lines,  -- 50000
       (SELECT sum(freight_charge) FROM drill.dispatch) AS total_freight;

\echo 'Setup complete. Take your base backup now, before you run w3_drill_incident.sql.'
