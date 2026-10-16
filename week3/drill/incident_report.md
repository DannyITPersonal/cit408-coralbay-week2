# Coral Bay Dispatch — Point-in-Time Recovery Incident Report

**To:** Coral Bay IT Manager  
**Course:** CIT 408 — Module 3, Assignment 3.2  
**Incident date:** October 15, 2026  
**System:** Dedicated PostgreSQL 18 `coralbay-drill` recovery-test container, database `drill`  
**Time zone:** All timestamps below include UTC offset `+00:00`.

## Executive summary

During a scheduled dispatch workload, a destructive database transaction deleted **52,700 dispatch-line records**, including 50,000 original records and 2,700 lines created by Batches 1–9. The dispatch header and customer tables remained present. PostgreSQL Write-Ahead Log (WAL) records identified the damaging transaction as **XID 825**, committed at **2026-10-15 20:25:33.643789+00:00**. Recovery from a previously verified base backup, replaying archived WAL up to but *excluding* XID 825, restored all 52,700 lines and retained all legitimate Batches 1–9. Batches 10–14 were intentionally excluded and must be re-entered.

Recovery was verified while paused, finalized, cleaned of recovery-specific settings, and followed by a fresh, verified base backup. The original damaged cluster was retained separately.

## Incident and recovery timeline

| Event | Observed time (+00:00) | Evidence |
|---|---|---|
| Initial base backup started | 2026-10-15 20:14:57+00:00 | `evidence/base_backup_started.txt` |
| Initial base backup finished | 2026-10-15 20:16:53+00:00 | `evidence/base_backup_finished.txt`, `evidence/backup_verification.txt` |
| Dispatch workload started | 2026-10-15 20:19:44+00:00 | `evidence/workload_started.txt` |
| Last safe batch (9) logged | 2026-10-15 20:25:16.336487+00:00 | `evidence/activity_before.txt` |
| Batch 9 transaction committed (WAL) | 2026-10-15 20:25:16.336621+00:00 | `evidence/incident_wal_candidates.txt` |
| **Damaging transaction XID 825 committed** | **2026-10-15 20:25:33.643789+00:00** | `evidence/incident_wal_candidates.txt`, `evidence/incident_wal_detail.txt` |
| First subsequently lost batch (10) logged | 2026-10-15 20:26:21.957960+00:00 | `evidence/activity_before.txt` |
| Last subsequently lost batch (14) logged | 2026-10-15 20:29:01.545174+00:00 | `evidence/activity_before.txt` |
| Workload finished; investigation initiated | 2026-10-15 20:29:42+00:00 | `evidence/workload_finished.txt`; exact first detection time was not separately captured |
| Original damaged cluster preserved | 2026-10-15 20:38:22+00:00 | `evidence/damaged_directory_name.txt` |
| Recovery operation started | 2026-10-15 20:42:03+00:00 | `evidence/recovery_started.txt` |
| Replay paused before damaging commit | 2026-10-15 20:42:13.096+00:00 | `evidence/recovery_log.txt` |
| Paused recovery verified | 2026-10-15 20:43:52+00:00 | `evidence/recovery_verified_at.txt`, `evidence/recovered_counts.txt` |
| Service available on new timeline | 2026-10-15 20:44:27.235+00:00 | `evidence/recovery_log_final.txt` |
| Recovery completion recorded | 2026-10-15 20:44:43+00:00 | `evidence/recovery_completed.txt` |
| Final base backup started | 2026-10-15 20:48:48+00:00 | `evidence/final_backup_started.txt` |
| Final base backup finished | 2026-10-15 20:49:38+00:00 | `evidence/final_backup_finished.txt`, `evidence/final_backup_verification.txt` |

## What happened and how it was identified

Before the workload, the `drill` schema contained 500 customers, 20,000 dispatches, and 50,000 dispatch lines. The script committed 14 batches, each adding 150 dispatches and 300 lines. Investigation after the workload found 22,100 dispatches but only 1,500 lines; all three operational tables still existed, and zero freight charges were not observed. This matched the script's mass-delete incident variant.

After Batch 9, the system should have contained **52,700** lines (50,000 + 9 × 300). The 1,500 lines remaining after the workload represent lines inserted in Batches 10–14, after the deletion. The activity log and WAL place the deletion between Batch 9 and Batch 10.

Specific forensic evidence:

- `evidence/incident_wal_candidates.txt` shows **XID 824** committing at **20:25:16.336621+00:00**, **XID 825** at **20:25:33.643789+00:00**, and **XID 826** at **20:26:21.958241+00:00**.
- `evidence/incident_wal_detail.txt` contains Heap records with **`tx: 825`** and **`desc: DELETE xmax: 825`**. Together with the workload script and table counts, these identify XID 825 as the mass deletion.
- `evidence/recovery_log.txt` confirms: **`recovery stopping before commit of transaction 825, time 2026-10-15 20:25:33.643789+00`**, followed by **`pausing at the end of recovery`**.

WAL records describe physical changes; their evidence is correlated with the provided SQL script and table-count changes rather than treated as a literal reproduction of the original SQL statement.

## Recovery decision and method

A verified base backup taken before the workload was restored to the dedicated drill data directory. The damaged cluster was preserved at **`/home/azureuser/cit408-drill/damaged_20261015T203822Z`** and not deleted.

Recovery used archived WAL with:

```ini
restore_command = 'cp /archive/%f %p'
recovery_target_xid = '825'
recovery_target_inclusive = off
recovery_target_action = 'pause'
hot_standby = on
```

**Why this target?** XID 825 is the confirmed destructive transaction. `recovery_target_inclusive = off` excludes its commit while retaining the preceding Batch 9. PostgreSQL paused at the target for inspection before promotion.

While paused, `pg_is_in_recovery()` was true, the replay pause state was `paused`, the last replayed transaction timestamp was **20:25:16.336621+00:00**, and Batches 1–9 were present. Row counts were exactly 500 customers, 21,350 dispatches, 52,700 dispatch lines, and 9 activity batches. After the verification, recovery was resumed, PostgreSQL promoted to timeline 2, recovery settings were cleared, and a restart confirmed normal operation. A new base backup was taken and `pg_verifybackup` reported **`backup successfully verified`**.

## Business impact and work to re-enter

| Category | Before incident/workload finish | After correct recovery | Explanation |
|---|---:|---:|---|
| Customers | 500 | 500 | Unaffected |
| Dispatches | 22,100 | 21,350 | 750 valid dispatches from Batches 10–14 excluded |
| Dispatch lines | 1,500 remaining after deletion | 52,700 restored | 52,700 deleted lines repaired by PITR; 1,500 later legitimate lines omitted |
| Committed workload batches | 14 | 9 | Batches **10, 11, 12, 13, 14** omitted |

Each lost batch has 150 dispatches and 300 lines. Coral Bay should retrieve these five batches from independent dispatch manifests, dispatch-entry logs, or other external source records; reconcile batch IDs and dispatch IDs; re-enter each dispatch and its two lines; and validate totals and duplicates. These records must not be re-created from the recovered database alone because PITR excluded them.

## RPO and RTO measurements

The assignment did not state formal business RPO or RTO targets; therefore, this report gives achieved measurements rather than claiming compliance with a nonexistent target.

- **Post-incident data-loss interval:** From the damaging commit at **20:25:33.643789+00:00** to the last excluded batch's logged timestamp at **20:29:01.545174+00:00** = **3 minutes 27.901385 seconds (about 3m 28s)**. The precise business loss is five batches, 750 dispatches, and 1,500 lines.
- **Latest retained to latest excluded workload timestamp:** From Batch 9's activity timestamp **20:25:16.336487+00:00** to Batch 14's **20:29:01.545174+00:00** = **3 minutes 45.208687 seconds**. Activity timestamps are not identical to WAL commit times, so this is an approximate committed-work gap.
- **Recovery execution time:** **20:42:03+00:00 to 20:44:43+00:00 = 2 minutes 40 seconds**. Service became available on the new timeline at **20:44:27.235+00:00**, about **2 minutes 24 seconds** after recovery began. These timings exclude investigation and evidence collection. Measured end-to-end downtime cannot be established exactly because the service disruption/detection start was not separately logged.

## Prevention and earlier detection

1. **Restrict high-impact DELETE permissions:** Limit blanket table-wide deletes to approved administrative roles; use least-privilege application accounts and require review for potentially destructive statements.
2. **Alert on abnormal row deletion:** Monitor sudden large changes in dispatch-line counts and unusual transaction volume; trigger an immediate alert rather than waiting until the ten-minute workload finishes.
3. **Maintain restore readiness:** Continuously monitor `pg_stat_archiver`, alert when archive failures increase, verify base backups, retain WAL off-instance, and conduct periodic paused PITR tests.
4. **Reduce re-entry risk:** Preserve immutable, independently stored dispatch batch manifests or event records so batches committed after the restoration target can be re-entered reliably.

## Evidence and retention

The submission includes the SQL verification script and its output, pre-recovery activity exports, table investigations, transaction/WAL evidence, archived WAL statistics, base-backup verification logs, recovery logs, and screenshots. Large physical data directories and raw base backups remain on the Azure server rather than in GitHub. The incident and recovery-workload SQL files were not modified.
