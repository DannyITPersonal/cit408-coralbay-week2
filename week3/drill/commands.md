# CIT 408 Module 3 Assignment 3.2 — Commands and execution record

This is a **reconstructed command log**, in execution order, based on terminal screenshots and saved output. The original terminal transcript was not uploaded in full. Files named under `evidence/` were captured directly on the Azure Linux host. Do **not rerun** the incident or recovery commands on the completed recovery cluster.

## 1. Inspect and protect existing server

```bash
whoami
hostname
date --iso-8601=seconds
sudo docker ps -a
sudo docker exec -u postgres pg18 psql -d postgres -c 'SHOW config_file;'
sudo docker exec -u postgres pg18 psql -d postgres -c '\l'
sudo docker exec -u postgres pg18 psql -d postgres -c "SELECT name,setting FROM pg_settings WHERE name IN ('archive_mode','archive_command','archive_timeout','wal_level');"
df -h
sudo docker system df
```

The pre-existing `pg18` container contained `coralbay`, `superstore`, and `superstore_restore`. A separate `coralbay-drill` container was created instead of modifying `pg18`.

## 2. Create dedicated PostgreSQL 18 drill environment

```bash
export LAB="$HOME/cit408-drill"
mkdir -p "$LAB"/{data,archive,backups,evidence,scripts}
sudo docker ps -a --filter name=coralbay-drill
read -s -p 'Create a drill PostgreSQL password: ' DRILL_PASSWORD; echo
sudo docker run -d \
 --name coralbay-drill --restart unless-stopped \
 -e POSTGRES_PASSWORD="$DRILL_PASSWORD" -e TZ=UTC \
 -p 127.0.0.1:55432:5432 \
 -v "$LAB/data:/var/lib/postgresql" \
 -v "$LAB/archive:/archive" \
 -v "$LAB/backups:/backups" \
 postgres:18 postgres \
 -c wal_level=replica -c archive_mode=on \
 -c archive_timeout=60s \
 -c 'archive_command=test ! -f /archive/%f && cp %p /archive/%f'
unset DRILL_PASSWORD
sudo docker exec -u postgres coralbay-drill pg_isready -U postgres
```

## 3. Repair initial WAL archive permissions and prove archiving

The first write test failed because `archive` belonged to the host user. Initial failed archive count reached 12. The issue was corrected and no additional failures occurred in subsequent tests.

```bash
sudo docker exec -u postgres coralbay-drill sh -c 'test -w /archive && echo "Archive writable"'
sudo docker exec coralbay-drill id postgres
sudo chown -R 999:999 "$LAB/archive"
sudo docker exec -u postgres coralbay-drill sh -c 'test -w /archive && echo "Archive writable"'
sudo docker exec -u postgres coralbay-drill psql -U postgres -d postgres -c 'SELECT pg_switch_wal();'
sudo docker exec -u postgres coralbay-drill psql -U postgres -d postgres -c 'SELECT archived_count,last_archived_wal,last_archived_time,failed_count,last_failed_time FROM pg_stat_archiver;' | tee "$LAB/evidence/archiver_before.txt"
sudo docker exec -u postgres coralbay-drill psql -U postgres -d postgres -c 'SELECT pg_switch_wal();'
sudo docker exec -u postgres coralbay-drill psql -U postgres -d postgres -c 'SELECT archived_count,last_archived_wal,last_archived_time,failed_count,last_failed_time FROM pg_stat_archiver;' | tee "$LAB/evidence/archiver_after.txt"
```

Result: `archived_count` rose 2 to 3 with `failed_count` unchanged at 12; later 21 WAL segments archived with the failure count still 12.

## 4. Create schema and baseline counts

The original instructor-provided SQL scripts were uploaded to `$LAB/scripts` using WinSCP.

```bash
sudo docker exec -u postgres coralbay-drill createdb -U postgres drill
ls -lh "$LAB/scripts"
set -o pipefail
sudo docker exec -i -u postgres coralbay-drill psql -X -U postgres -d drill -v ON_ERROR_STOP=1 < "$LAB/scripts/w3_drill_setup.sql" 2>&1 | tee "$LAB/evidence/setup_output.txt"
sudo docker exec -u postgres coralbay-drill psql -U postgres -d drill -c '\dt drill.*'
sudo docker exec -i -u postgres coralbay-drill psql -X -U postgres -d drill -v ON_ERROR_STOP=1 < "$LAB/scripts/w3_count_all_tables.sql" 2>&1 | tee "$LAB/evidence/counts_before.txt"
```

Initial totals: 500 customers, 20,000 dispatches, 50,000 dispatch lines, zero activity batches. An earlier `psql -f /dev/stdin` attempt did not provide input and was retried with `docker exec -i`.

## 5. Take and verify initial base backup

```bash
export BASE_NAME=base_20261015T201306Z
echo "$BASE_NAME" > "$LAB/evidence/base_backup_name.txt"
date --iso-8601=seconds | tee "$LAB/evidence/base_backup_started.txt"
sudo docker exec -u postgres coralbay-drill pg_basebackup -U postgres -D "/backups/$BASE_NAME" -Fp -Xs -P 2>&1 | tee "$LAB/evidence/base_backup_output.txt"
```

The initial command failed with `/backups/...: Permission denied`; no partial backup directory existed. After correcting permissions, the backup succeeded:

```bash
sudo chown -R 999:999 "$LAB/backups"
sudo docker exec -u postgres coralbay-drill sh -c 'test -w /backups && echo "Backup directory writable"'
date --iso-8601=seconds | tee "$LAB/evidence/base_backup_started.txt"
sudo docker exec -u postgres coralbay-drill pg_basebackup -U postgres -D "/backups/$BASE_NAME" -Fp -Xs -P 2>&1 | tee "$LAB/evidence/base_backup_output.txt"
date --iso-8601=seconds | tee "$LAB/evidence/base_backup_finished.txt"
sudo docker exec -u postgres coralbay-drill pg_verifybackup "/backups/$BASE_NAME" 2>&1 | tee "$LAB/evidence/backup_verification.txt"
```

Backup started 20:14:57+00:00, finished 20:16:53+00:00; verification passed.

## 6. Run workload once and preserve evidence

```bash
date --iso-8601=seconds | tee "$LAB/evidence/workload_started.txt"
sha256sum "$LAB/scripts/w3_drill_incident.sql" | tee "$LAB/evidence/incident_script_checksum.txt"
sudo docker exec -i -u postgres coralbay-drill psql -X -U postgres -d drill -v ON_ERROR_STOP=1 < "$LAB/scripts/w3_drill_incident.sql" 2>&1 | tee "$LAB/evidence/workload_output.txt"
date --iso-8601=seconds | tee "$LAB/evidence/workload_finished.txt"
sudo docker logs --timestamps coralbay-drill > "$LAB/evidence/server_log_before.txt" 2>&1
sudo docker exec -u postgres coralbay-drill psql -U postgres -d postgres -c 'SELECT pg_switch_wal();'
sudo docker exec -u postgres coralbay-drill psql -U postgres -d postgres -c 'SELECT archived_count,failed_count,last_archived_time FROM pg_stat_archiver;'
```

All 14 batches committed. Workload ran from 20:19:44 to 20:29:42+00:00.

## 7. Investigate damaged data and incident transaction

```bash
sudo docker exec -u postgres coralbay-drill psql -U postgres -d drill -c 'SELECT batch_no,dispatches,lines,committed_at FROM drill.activity ORDER BY batch_no;' | tee "$LAB/evidence/activity_before.txt"
sudo docker exec -u postgres coralbay-drill psql -U postgres -d drill -c '\copy (SELECT * FROM drill.activity ORDER BY batch_no) TO STDOUT WITH CSV HEADER' > "$LAB/evidence/activity_before.csv"
sudo docker exec -u postgres coralbay-drill psql -U postgres -d drill -c "SELECT to_regclass('drill.customer') AS customer_table,to_regclass('drill.dispatch') AS dispatch_table,to_regclass('drill.dispatch_line') AS dispatch_line_table;" | tee "$LAB/evidence/table_status.txt"
sudo docker exec -u postgres coralbay-drill psql -U postgres -d drill -c 'SELECT COUNT(*) AS total_dispatches,COUNT(*) FILTER(WHERE freight_charge=0) AS zero_freight,SUM(freight_charge) AS total_freight FROM drill.dispatch;' | tee "$LAB/evidence/dispatch_investigation.txt"
sudo docker exec -u postgres coralbay-drill psql -U postgres -d drill -c 'SELECT COUNT(*) AS remaining_dispatch_lines FROM drill.dispatch_line;' | tee "$LAB/evidence/lines_investigation.txt"
sudo docker exec -u postgres coralbay-drill psql -U postgres -d drill -c '\copy (SELECT * FROM drill.dispatch_line) TO STDOUT WITH CSV HEADER' > "$LAB/evidence/dispatch_lines_before.csv"
for SEG in 0E 0F 10; do FILE="0000000100000000000000$SEG"; sudo docker exec -u postgres coralbay-drill pg_waldump -p /archive -r Transaction "$FILE"; done > "$LAB/evidence/incident_wal_candidates.txt" 2>&1
sudo docker exec -u postgres coralbay-drill pg_waldump -p /archive -s 0/0F038A50 -e 0/105C9D90 > "$LAB/evidence/incident_wal_detail.txt" 2>&1
```

An earlier `pg_waldump -p /archive -r Transaction` call lacked a start WAL location and failed; the segment-specific command corrected this. XID 825 at 20:25:33.643789+00:00 was identified from Heap DELETE records and commit evidence.

## 8. Preserve damaged directory, restore base backup, configure paused PITR

```bash
sudo docker exec -u postgres coralbay-drill psql -U postgres -d postgres -c 'SHOW data_directory;'
sudo docker stop coralbay-drill
export DAMAGED_NAME=damaged_20261015T203822Z
sudo mv "$LAB/data/18/docker" "$LAB/$DAMAGED_NAME"
echo "$DAMAGED_NAME" | tee "$LAB/evidence/damaged_directory_name.txt"
export BASE_NAME="$(cat "$LAB/evidence/base_backup_name.txt")"
sudo mkdir -p "$LAB/data/18/docker"
sudo cp -a "$LAB/backups/$BASE_NAME/." "$LAB/data/18/docker/"
sudo stat -c '%u:%g %n' "$LAB/data/18/docker"
sudo touch "$LAB/data/18/docker/recovery.signal"
sudo chown 999:999 "$LAB/data/18/docker/recovery.signal"
sudo tee -a "$LAB/data/18/docker/postgresql.auto.conf" > /dev/null <<'CONF'
restore_command = 'cp /archive/%f %p'
recovery_target_xid = '825'
recovery_target_inclusive = off
recovery_target_action = 'pause'
hot_standby = on
CONF
sudo tail -12 "$LAB/data/18/docker/postgresql.auto.conf"
```

The damaged cluster was preserved outside the active mount. The base backup was restored into PostgreSQL 18's version-specific data directory. Recovery target configuration lines were placed in PostgreSQL configuration, not executed as shell commands.

## 9. Pause, inspect, then complete recovery

```bash
date --iso-8601=seconds | tee "$LAB/evidence/recovery_started.txt"
sudo docker start coralbay-drill
sudo docker logs --tail 70 coralbay-drill
sudo docker logs --timestamps coralbay-drill > "$LAB/evidence/recovery_log.txt" 2>&1
sudo docker exec -u postgres coralbay-drill psql -U postgres -d postgres -c 'SELECT pg_is_in_recovery(),pg_get_wal_replay_pause_state(),pg_last_xact_replay_timestamp();'
sudo docker exec -u postgres coralbay-drill psql -U postgres -d drill -c 'SELECT batch_no,dispatches,lines,committed_at FROM drill.activity ORDER BY batch_no;'
sudo docker exec -u postgres coralbay-drill psql -U postgres -d drill -c 'SELECT (SELECT COUNT(*) FROM drill.customer) AS customers,(SELECT COUNT(*) FROM drill.dispatch) AS dispatches,(SELECT COUNT(*) FROM drill.dispatch_line) AS lines,(SELECT COUNT(*) FROM drill.activity) AS batches;' | tee "$LAB/evidence/recovered_counts.txt"
sudo docker exec -u postgres coralbay-drill psql -U postgres -d drill -c '\copy (SELECT * FROM drill.activity ORDER BY batch_no) TO STDOUT WITH CSV HEADER' > "$LAB/evidence/activity_after.csv"
date --iso-8601=seconds | tee "$LAB/evidence/recovery_verified_at.txt"
sudo docker exec -u postgres coralbay-drill psql -U postgres -d postgres -c 'SELECT pg_wal_replay_resume();'
sudo docker exec -u postgres coralbay-drill psql -U postgres -d postgres -c 'SELECT pg_is_in_recovery();'
date --iso-8601=seconds | tee "$LAB/evidence/recovery_completed.txt"
sudo docker logs --timestamps coralbay-drill > "$LAB/evidence/recovery_log_final.txt" 2>&1
```

Paused checks: `true`, `paused`, replayed through Batch 9; 500/21,350/52,700/9 table counts. Post-promotion: `pg_is_in_recovery() = false`. Recovery started 20:42:03 and finished 20:44:43+00:00.

## 10. Clear temporary recovery settings and restart

A single multi-statement `psql -c 'ALTER SYSTEM RESET ...; ...'` failed because `ALTER SYSTEM` cannot run inside a transaction block. Each setting was reset separately:

```bash
for PARAM in restore_command recovery_target_xid recovery_target_inclusive recovery_target_action; do
 sudo docker exec -u postgres coralbay-drill psql -X -v ON_ERROR_STOP=1 -U postgres -d postgres -c "ALTER SYSTEM RESET $PARAM;" || break
done
sudo docker exec -u postgres coralbay-drill psql -U postgres -d postgres -c 'SELECT pg_reload_conf();'
sudo docker exec -u postgres coralbay-drill psql -U postgres -d postgres -c "SELECT name,sourcefile,sourceline,applied,error FROM pg_file_settings WHERE name LIKE 'recovery_target%' OR name='restore_command';"
sudo docker restart coralbay-drill
sudo docker exec -u postgres coralbay-drill psql -U postgres -d postgres -c 'SELECT pg_is_in_recovery();'
sudo docker exec -u postgres coralbay-drill psql -U postgres -d postgres -c "SELECT name,setting,source FROM pg_settings WHERE name IN ('restore_command','recovery_target_xid','recovery_target_inclusive','recovery_target_action') ORDER BY name;"
```

Confirmed: no recovery-target entries in config; four relevant settings showed `source=default` after restart; normal `drill` row counts unchanged.

## 11. Take and verify fresh final backup; verify SQL

```bash
export FINAL_NAME=recovered_20261015T204843Z
echo "$FINAL_NAME" | tee "$LAB/evidence/final_backup_name.txt"
date --iso-8601=seconds | tee "$LAB/evidence/final_backup_started.txt"
sudo docker exec -u postgres coralbay-drill pg_basebackup -U postgres -D "/backups/$FINAL_NAME" -Fp -Xs -P 2>&1 | tee "$LAB/evidence/final_backup_output.txt"
date --iso-8601=seconds | tee "$LAB/evidence/final_backup_finished.txt"
sudo docker exec -u postgres coralbay-drill pg_verifybackup "/backups/$FINAL_NAME" 2>&1 | tee "$LAB/evidence/final_backup_verification.txt"
sudo docker exec -i -u postgres coralbay-drill psql -X -U postgres -d drill -v ON_ERROR_STOP=1 < "$LAB/scripts/verify.sql" 2>&1 | tee "$LAB/evidence/verification_after.txt"
```

Final backup completed 20:49:38+00:00 and verified successfully. Four post-recovery SQL assertions returned `t`.

## Submission and safety notes

Save terminal screenshots as `evidence/archiver.png` and `evidence/recovery_log.png`. Include the evidence directory and report in `week3/drill/`, but do not upload physical PostgreSQL clusters, raw full base backups, passwords, or other secrets. The full recovery lab remains on Azure.
