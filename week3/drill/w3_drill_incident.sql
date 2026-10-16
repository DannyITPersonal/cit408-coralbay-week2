-- CIT 408 Week 3: recovery drill, part 2 (the workload)
-- Run this ONLY after your base backup is finished:
--   psql -U postgres -d drill -f w3_drill_incident.sql
-- It plays back about ten minutes of normal dispatch work, one committed batch at a time.
-- Somewhere in that time, something goes wrong. Your job is to find out what, and when,
-- and to recover the database to the moment before it happened.
-- Leave this window open until you see "Workload finished".

\set ON_ERROR_STOP on
\set QUIET on
SET client_min_messages = warning;
\if :{?pace}
\else
  \set pace 1
\endif

SELECT 4 + floor(random() * 6)::int AS incident_after,
       floor(random() * 3)::int     AS incident_type \gset
SELECT :incident_type = 0 AS inc_delete,
       :incident_type = 1 AS inc_update,
       :incident_type = 2 AS inc_drop \gset

\echo 'Workload started. Do not interrupt it.'


-- batch 1
BEGIN;
INSERT INTO drill.dispatch (dispatch_id, customer_id, dispatch_date, freight_charge, batch_no)
SELECT m.max_id + g, 1 + floor(random() * 500)::int, current_date,
       round((150 + random() * 2200)::numeric, 2), 1
FROM (SELECT max(dispatch_id) AS max_id FROM drill.dispatch) m, generate_series(1, 150) g;
INSERT INTO drill.dispatch_line
SELECT d.dispatch_id, l, 'Batch 1 cargo', 1 + floor(random() * 12)::int
FROM drill.dispatch d CROSS JOIN LATERAL generate_series(1, 2) l
WHERE d.batch_no = 1;
INSERT INTO drill.activity (batch_no, dispatches, lines) VALUES (1, 150, 300);
COMMIT;
\echo 'Batch 1 of 14 committed'
SELECT :incident_after = 1 AS do_incident \gset
\if :do_incident
  SELECT pg_sleep((8 + random() * 12) * :pace) AS slept \gset
  \if :inc_delete
    DELETE FROM drill.dispatch_line;
  \elif :inc_update
    UPDATE drill.dispatch SET freight_charge = 0;
  \elif :inc_drop
    DROP TABLE drill.customer CASCADE;
  \endif
\endif
SELECT pg_sleep((25 + random() * 30) * :pace) AS slept \gset

-- batch 2
BEGIN;
INSERT INTO drill.dispatch (dispatch_id, customer_id, dispatch_date, freight_charge, batch_no)
SELECT m.max_id + g, 1 + floor(random() * 500)::int, current_date,
       round((150 + random() * 2200)::numeric, 2), 2
FROM (SELECT max(dispatch_id) AS max_id FROM drill.dispatch) m, generate_series(1, 150) g;
INSERT INTO drill.dispatch_line
SELECT d.dispatch_id, l, 'Batch 2 cargo', 1 + floor(random() * 12)::int
FROM drill.dispatch d CROSS JOIN LATERAL generate_series(1, 2) l
WHERE d.batch_no = 2;
INSERT INTO drill.activity (batch_no, dispatches, lines) VALUES (2, 150, 300);
COMMIT;
\echo 'Batch 2 of 14 committed'
SELECT :incident_after = 2 AS do_incident \gset
\if :do_incident
  SELECT pg_sleep((8 + random() * 12) * :pace) AS slept \gset
  \if :inc_delete
    DELETE FROM drill.dispatch_line;
  \elif :inc_update
    UPDATE drill.dispatch SET freight_charge = 0;
  \elif :inc_drop
    DROP TABLE drill.customer CASCADE;
  \endif
\endif
SELECT pg_sleep((25 + random() * 30) * :pace) AS slept \gset

-- batch 3
BEGIN;
INSERT INTO drill.dispatch (dispatch_id, customer_id, dispatch_date, freight_charge, batch_no)
SELECT m.max_id + g, 1 + floor(random() * 500)::int, current_date,
       round((150 + random() * 2200)::numeric, 2), 3
FROM (SELECT max(dispatch_id) AS max_id FROM drill.dispatch) m, generate_series(1, 150) g;
INSERT INTO drill.dispatch_line
SELECT d.dispatch_id, l, 'Batch 3 cargo', 1 + floor(random() * 12)::int
FROM drill.dispatch d CROSS JOIN LATERAL generate_series(1, 2) l
WHERE d.batch_no = 3;
INSERT INTO drill.activity (batch_no, dispatches, lines) VALUES (3, 150, 300);
COMMIT;
\echo 'Batch 3 of 14 committed'
SELECT :incident_after = 3 AS do_incident \gset
\if :do_incident
  SELECT pg_sleep((8 + random() * 12) * :pace) AS slept \gset
  \if :inc_delete
    DELETE FROM drill.dispatch_line;
  \elif :inc_update
    UPDATE drill.dispatch SET freight_charge = 0;
  \elif :inc_drop
    DROP TABLE drill.customer CASCADE;
  \endif
\endif
SELECT pg_sleep((25 + random() * 30) * :pace) AS slept \gset

-- batch 4
BEGIN;
INSERT INTO drill.dispatch (dispatch_id, customer_id, dispatch_date, freight_charge, batch_no)
SELECT m.max_id + g, 1 + floor(random() * 500)::int, current_date,
       round((150 + random() * 2200)::numeric, 2), 4
FROM (SELECT max(dispatch_id) AS max_id FROM drill.dispatch) m, generate_series(1, 150) g;
INSERT INTO drill.dispatch_line
SELECT d.dispatch_id, l, 'Batch 4 cargo', 1 + floor(random() * 12)::int
FROM drill.dispatch d CROSS JOIN LATERAL generate_series(1, 2) l
WHERE d.batch_no = 4;
INSERT INTO drill.activity (batch_no, dispatches, lines) VALUES (4, 150, 300);
COMMIT;
\echo 'Batch 4 of 14 committed'
SELECT :incident_after = 4 AS do_incident \gset
\if :do_incident
  SELECT pg_sleep((8 + random() * 12) * :pace) AS slept \gset
  \if :inc_delete
    DELETE FROM drill.dispatch_line;
  \elif :inc_update
    UPDATE drill.dispatch SET freight_charge = 0;
  \elif :inc_drop
    DROP TABLE drill.customer CASCADE;
  \endif
\endif
SELECT pg_sleep((25 + random() * 30) * :pace) AS slept \gset

-- batch 5
BEGIN;
INSERT INTO drill.dispatch (dispatch_id, customer_id, dispatch_date, freight_charge, batch_no)
SELECT m.max_id + g, 1 + floor(random() * 500)::int, current_date,
       round((150 + random() * 2200)::numeric, 2), 5
FROM (SELECT max(dispatch_id) AS max_id FROM drill.dispatch) m, generate_series(1, 150) g;
INSERT INTO drill.dispatch_line
SELECT d.dispatch_id, l, 'Batch 5 cargo', 1 + floor(random() * 12)::int
FROM drill.dispatch d CROSS JOIN LATERAL generate_series(1, 2) l
WHERE d.batch_no = 5;
INSERT INTO drill.activity (batch_no, dispatches, lines) VALUES (5, 150, 300);
COMMIT;
\echo 'Batch 5 of 14 committed'
SELECT :incident_after = 5 AS do_incident \gset
\if :do_incident
  SELECT pg_sleep((8 + random() * 12) * :pace) AS slept \gset
  \if :inc_delete
    DELETE FROM drill.dispatch_line;
  \elif :inc_update
    UPDATE drill.dispatch SET freight_charge = 0;
  \elif :inc_drop
    DROP TABLE drill.customer CASCADE;
  \endif
\endif
SELECT pg_sleep((25 + random() * 30) * :pace) AS slept \gset

-- batch 6
BEGIN;
INSERT INTO drill.dispatch (dispatch_id, customer_id, dispatch_date, freight_charge, batch_no)
SELECT m.max_id + g, 1 + floor(random() * 500)::int, current_date,
       round((150 + random() * 2200)::numeric, 2), 6
FROM (SELECT max(dispatch_id) AS max_id FROM drill.dispatch) m, generate_series(1, 150) g;
INSERT INTO drill.dispatch_line
SELECT d.dispatch_id, l, 'Batch 6 cargo', 1 + floor(random() * 12)::int
FROM drill.dispatch d CROSS JOIN LATERAL generate_series(1, 2) l
WHERE d.batch_no = 6;
INSERT INTO drill.activity (batch_no, dispatches, lines) VALUES (6, 150, 300);
COMMIT;
\echo 'Batch 6 of 14 committed'
SELECT :incident_after = 6 AS do_incident \gset
\if :do_incident
  SELECT pg_sleep((8 + random() * 12) * :pace) AS slept \gset
  \if :inc_delete
    DELETE FROM drill.dispatch_line;
  \elif :inc_update
    UPDATE drill.dispatch SET freight_charge = 0;
  \elif :inc_drop
    DROP TABLE drill.customer CASCADE;
  \endif
\endif
SELECT pg_sleep((25 + random() * 30) * :pace) AS slept \gset

-- batch 7
BEGIN;
INSERT INTO drill.dispatch (dispatch_id, customer_id, dispatch_date, freight_charge, batch_no)
SELECT m.max_id + g, 1 + floor(random() * 500)::int, current_date,
       round((150 + random() * 2200)::numeric, 2), 7
FROM (SELECT max(dispatch_id) AS max_id FROM drill.dispatch) m, generate_series(1, 150) g;
INSERT INTO drill.dispatch_line
SELECT d.dispatch_id, l, 'Batch 7 cargo', 1 + floor(random() * 12)::int
FROM drill.dispatch d CROSS JOIN LATERAL generate_series(1, 2) l
WHERE d.batch_no = 7;
INSERT INTO drill.activity (batch_no, dispatches, lines) VALUES (7, 150, 300);
COMMIT;
\echo 'Batch 7 of 14 committed'
SELECT :incident_after = 7 AS do_incident \gset
\if :do_incident
  SELECT pg_sleep((8 + random() * 12) * :pace) AS slept \gset
  \if :inc_delete
    DELETE FROM drill.dispatch_line;
  \elif :inc_update
    UPDATE drill.dispatch SET freight_charge = 0;
  \elif :inc_drop
    DROP TABLE drill.customer CASCADE;
  \endif
\endif
SELECT pg_sleep((25 + random() * 30) * :pace) AS slept \gset

-- batch 8
BEGIN;
INSERT INTO drill.dispatch (dispatch_id, customer_id, dispatch_date, freight_charge, batch_no)
SELECT m.max_id + g, 1 + floor(random() * 500)::int, current_date,
       round((150 + random() * 2200)::numeric, 2), 8
FROM (SELECT max(dispatch_id) AS max_id FROM drill.dispatch) m, generate_series(1, 150) g;
INSERT INTO drill.dispatch_line
SELECT d.dispatch_id, l, 'Batch 8 cargo', 1 + floor(random() * 12)::int
FROM drill.dispatch d CROSS JOIN LATERAL generate_series(1, 2) l
WHERE d.batch_no = 8;
INSERT INTO drill.activity (batch_no, dispatches, lines) VALUES (8, 150, 300);
COMMIT;
\echo 'Batch 8 of 14 committed'
SELECT :incident_after = 8 AS do_incident \gset
\if :do_incident
  SELECT pg_sleep((8 + random() * 12) * :pace) AS slept \gset
  \if :inc_delete
    DELETE FROM drill.dispatch_line;
  \elif :inc_update
    UPDATE drill.dispatch SET freight_charge = 0;
  \elif :inc_drop
    DROP TABLE drill.customer CASCADE;
  \endif
\endif
SELECT pg_sleep((25 + random() * 30) * :pace) AS slept \gset

-- batch 9
BEGIN;
INSERT INTO drill.dispatch (dispatch_id, customer_id, dispatch_date, freight_charge, batch_no)
SELECT m.max_id + g, 1 + floor(random() * 500)::int, current_date,
       round((150 + random() * 2200)::numeric, 2), 9
FROM (SELECT max(dispatch_id) AS max_id FROM drill.dispatch) m, generate_series(1, 150) g;
INSERT INTO drill.dispatch_line
SELECT d.dispatch_id, l, 'Batch 9 cargo', 1 + floor(random() * 12)::int
FROM drill.dispatch d CROSS JOIN LATERAL generate_series(1, 2) l
WHERE d.batch_no = 9;
INSERT INTO drill.activity (batch_no, dispatches, lines) VALUES (9, 150, 300);
COMMIT;
\echo 'Batch 9 of 14 committed'
SELECT :incident_after = 9 AS do_incident \gset
\if :do_incident
  SELECT pg_sleep((8 + random() * 12) * :pace) AS slept \gset
  \if :inc_delete
    DELETE FROM drill.dispatch_line;
  \elif :inc_update
    UPDATE drill.dispatch SET freight_charge = 0;
  \elif :inc_drop
    DROP TABLE drill.customer CASCADE;
  \endif
\endif
SELECT pg_sleep((25 + random() * 30) * :pace) AS slept \gset

-- batch 10
BEGIN;
INSERT INTO drill.dispatch (dispatch_id, customer_id, dispatch_date, freight_charge, batch_no)
SELECT m.max_id + g, 1 + floor(random() * 500)::int, current_date,
       round((150 + random() * 2200)::numeric, 2), 10
FROM (SELECT max(dispatch_id) AS max_id FROM drill.dispatch) m, generate_series(1, 150) g;
INSERT INTO drill.dispatch_line
SELECT d.dispatch_id, l, 'Batch 10 cargo', 1 + floor(random() * 12)::int
FROM drill.dispatch d CROSS JOIN LATERAL generate_series(1, 2) l
WHERE d.batch_no = 10;
INSERT INTO drill.activity (batch_no, dispatches, lines) VALUES (10, 150, 300);
COMMIT;
\echo 'Batch 10 of 14 committed'
SELECT :incident_after = 10 AS do_incident \gset
\if :do_incident
  SELECT pg_sleep((8 + random() * 12) * :pace) AS slept \gset
  \if :inc_delete
    DELETE FROM drill.dispatch_line;
  \elif :inc_update
    UPDATE drill.dispatch SET freight_charge = 0;
  \elif :inc_drop
    DROP TABLE drill.customer CASCADE;
  \endif
\endif
SELECT pg_sleep((25 + random() * 30) * :pace) AS slept \gset

-- batch 11
BEGIN;
INSERT INTO drill.dispatch (dispatch_id, customer_id, dispatch_date, freight_charge, batch_no)
SELECT m.max_id + g, 1 + floor(random() * 500)::int, current_date,
       round((150 + random() * 2200)::numeric, 2), 11
FROM (SELECT max(dispatch_id) AS max_id FROM drill.dispatch) m, generate_series(1, 150) g;
INSERT INTO drill.dispatch_line
SELECT d.dispatch_id, l, 'Batch 11 cargo', 1 + floor(random() * 12)::int
FROM drill.dispatch d CROSS JOIN LATERAL generate_series(1, 2) l
WHERE d.batch_no = 11;
INSERT INTO drill.activity (batch_no, dispatches, lines) VALUES (11, 150, 300);
COMMIT;
\echo 'Batch 11 of 14 committed'
SELECT :incident_after = 11 AS do_incident \gset
\if :do_incident
  SELECT pg_sleep((8 + random() * 12) * :pace) AS slept \gset
  \if :inc_delete
    DELETE FROM drill.dispatch_line;
  \elif :inc_update
    UPDATE drill.dispatch SET freight_charge = 0;
  \elif :inc_drop
    DROP TABLE drill.customer CASCADE;
  \endif
\endif
SELECT pg_sleep((25 + random() * 30) * :pace) AS slept \gset

-- batch 12
BEGIN;
INSERT INTO drill.dispatch (dispatch_id, customer_id, dispatch_date, freight_charge, batch_no)
SELECT m.max_id + g, 1 + floor(random() * 500)::int, current_date,
       round((150 + random() * 2200)::numeric, 2), 12
FROM (SELECT max(dispatch_id) AS max_id FROM drill.dispatch) m, generate_series(1, 150) g;
INSERT INTO drill.dispatch_line
SELECT d.dispatch_id, l, 'Batch 12 cargo', 1 + floor(random() * 12)::int
FROM drill.dispatch d CROSS JOIN LATERAL generate_series(1, 2) l
WHERE d.batch_no = 12;
INSERT INTO drill.activity (batch_no, dispatches, lines) VALUES (12, 150, 300);
COMMIT;
\echo 'Batch 12 of 14 committed'
SELECT :incident_after = 12 AS do_incident \gset
\if :do_incident
  SELECT pg_sleep((8 + random() * 12) * :pace) AS slept \gset
  \if :inc_delete
    DELETE FROM drill.dispatch_line;
  \elif :inc_update
    UPDATE drill.dispatch SET freight_charge = 0;
  \elif :inc_drop
    DROP TABLE drill.customer CASCADE;
  \endif
\endif
SELECT pg_sleep((25 + random() * 30) * :pace) AS slept \gset

-- batch 13
BEGIN;
INSERT INTO drill.dispatch (dispatch_id, customer_id, dispatch_date, freight_charge, batch_no)
SELECT m.max_id + g, 1 + floor(random() * 500)::int, current_date,
       round((150 + random() * 2200)::numeric, 2), 13
FROM (SELECT max(dispatch_id) AS max_id FROM drill.dispatch) m, generate_series(1, 150) g;
INSERT INTO drill.dispatch_line
SELECT d.dispatch_id, l, 'Batch 13 cargo', 1 + floor(random() * 12)::int
FROM drill.dispatch d CROSS JOIN LATERAL generate_series(1, 2) l
WHERE d.batch_no = 13;
INSERT INTO drill.activity (batch_no, dispatches, lines) VALUES (13, 150, 300);
COMMIT;
\echo 'Batch 13 of 14 committed'
SELECT :incident_after = 13 AS do_incident \gset
\if :do_incident
  SELECT pg_sleep((8 + random() * 12) * :pace) AS slept \gset
  \if :inc_delete
    DELETE FROM drill.dispatch_line;
  \elif :inc_update
    UPDATE drill.dispatch SET freight_charge = 0;
  \elif :inc_drop
    DROP TABLE drill.customer CASCADE;
  \endif
\endif
SELECT pg_sleep((25 + random() * 30) * :pace) AS slept \gset

-- batch 14
BEGIN;
INSERT INTO drill.dispatch (dispatch_id, customer_id, dispatch_date, freight_charge, batch_no)
SELECT m.max_id + g, 1 + floor(random() * 500)::int, current_date,
       round((150 + random() * 2200)::numeric, 2), 14
FROM (SELECT max(dispatch_id) AS max_id FROM drill.dispatch) m, generate_series(1, 150) g;
INSERT INTO drill.dispatch_line
SELECT d.dispatch_id, l, 'Batch 14 cargo', 1 + floor(random() * 12)::int
FROM drill.dispatch d CROSS JOIN LATERAL generate_series(1, 2) l
WHERE d.batch_no = 14;
INSERT INTO drill.activity (batch_no, dispatches, lines) VALUES (14, 150, 300);
COMMIT;
\echo 'Batch 14 of 14 committed'
SELECT :incident_after = 14 AS do_incident \gset
\if :do_incident
  SELECT pg_sleep((8 + random() * 12) * :pace) AS slept \gset
  \if :inc_delete
    DELETE FROM drill.dispatch_line;
  \elif :inc_update
    UPDATE drill.dispatch SET freight_charge = 0;
  \elif :inc_drop
    DROP TABLE drill.customer CASCADE;
  \endif
\endif
SELECT pg_sleep((25 + random() * 30) * :pace) AS slept \gset

\echo 'Workload finished. Investigate before you change anything.'
