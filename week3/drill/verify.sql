-- CIT 408 Module 3 Assignment 3.2 — Post-Recovery Verification
SELECT pg_is_in_recovery() AS still_in_recovery;
SELECT
  (SELECT COUNT(*) FROM drill.customer) AS customers,
  (SELECT COUNT(*) FROM drill.dispatch) AS dispatches,
  (SELECT COUNT(*) FROM drill.dispatch_line) AS dispatch_lines,
  (SELECT COUNT(*) FROM drill.activity) AS recovered_batches;
SELECT batch_no, dispatches, lines, committed_at
FROM drill.activity ORDER BY batch_no;
SELECT
 (SELECT COUNT(*) FROM drill.dispatch_line) = 52700 AS deleted_lines_restored,
 (SELECT COUNT(*) FROM drill.activity) = 9 AS correct_batch_count,
 (SELECT COUNT(*) FROM drill.activity WHERE batch_no BETWEEN 10 AND 14) = 0 AS post_incident_batches_excluded,
 (SELECT COUNT(*) FROM drill.activity WHERE batch_no BETWEEN 1 AND 9) = 9 AS pre_incident_batches_preserved;
