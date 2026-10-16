# Command Log: Superstore Backup and Restore

**Student:** Mohamed Salem Maidan  
**University:** Atlantis University  
**Course:** CIT 408 — Database Management Operations and Optimization  
**Assignment:** Module 3, Assignment 3.1  
**Date:** October 14–15, 2026

> This log puts the steps in chronological order based on the provided terminal screenshots and conversation. If a command was not fully shown in the screenshots, it is identified as an explanatory or reproducible example rather than being presented as confirmed activity. No passwords are recorded. Commands beginning with `sudo docker` were run on the Linux host. The `pg_dump`, `pg_restore`, and `psql` commands without `sudo docker` were run inside the `pg18` container.

## A. Prepare the Linux PostgreSQL instance

This setup was needed before the migration and backup work.

```bash
sudo docker ps
```

The output confirmed that the PostgreSQL 18 container named `pg18` was running. An earlier attempt to run `docker ps` without `sudo` failed because the current user did not have permission to access the Docker socket.

```bash
ls -lh ~/cit408-coralbay/week2/superstore_migration_2026-10-14.backup
mkdir -p ~/db_backups
mv ~/cit408-coralbay/week2/superstore_migration_2026-10-14.backup ~/db_backups/
ls -lh ~/db_backups/
sudo docker cp ~/db_backups/superstore_migration_2026-10-14.backup pg18:/tmp/
sudo docker exec pg18 ls -lh /tmp/superstore_migration_2026-10-14.backup
sudo docker exec pg18 createdb -U postgres superstore
sudo docker exec pg18 pg_restore -U postgres -d superstore --no-owner --no-acl --exit-on-error /tmp/superstore_migration_2026-10-14.backup
sudo docker exec -it pg18 psql -U postgres -d superstore -c "\dt"
sudo docker exec -it pg18 psql -U postgres -d superstore -c "SELECT COUNT(*) FROM public.order_lines;"
```

The 848 KB migration backup was moved to the Linux host and copied into the container. A new `superstore` database was created and restored. The verification query showed 9,994 records in `order_lines`. This migration archive was separate from the three backup files assessed for Week 3.

## B. Create a backup account with limited permissions

```bash
sudo docker exec -it pg18 psql -U postgres -d superstore
```

This opened `psql` inside PostgreSQL 18 using an administrative account.

```sql
CREATE ROLE backup_operator WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;
\password backup_operator
GRANT CONNECT ON DATABASE superstore TO backup_operator;
GRANT USAGE ON SCHEMA public TO backup_operator;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO backup_operator;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO backup_operator;
\du
```

I created the `backup_operator` login and set its password interactively. The account received permission to connect to the database, use the `public` schema, and read tables and sequences. It was not given superuser, database-creation, role-creation, or replication privileges.

```sql
SELECT
 has_table_privilege('backup_operator', 'public.order_lines', 'SELECT') AS can_read,
 has_table_privilege('backup_operator', 'public.order_lines', 'INSERT') AS can_insert,
 has_table_privilege('backup_operator', 'public.order_lines', 'UPDATE') AS can_update,
 has_table_privilege('backup_operator', 'public.order_lines', 'DELETE') AS can_delete;
\q
```

The permission check showed that `SELECT` was allowed, while `INSERT`, `UPDATE`, and `DELETE` were not. I then exited `psql`.

## C. Create the three required backup files

```bash
sudo docker exec pg18 mkdir -p /tmp/week3_backups
sudo docker exec -it pg18 bash
umask 077
```

I created a directory inside the container for the Week 3 backups, opened a shell in the container, and set restrictive default permissions for newly created files.

```bash
time pg_dump -h 127.0.0.1 -U backup_operator -d superstore -Fc -f /tmp/week3_backups/superstore_2026-10-14.dump
ls -lh /tmp/week3_backups/
```

This created a custom-format logical backup using the limited-permission `backup_operator` account. The recorded real time was **0.329 seconds**, and the archive was approximately **851 KiB**.

```bash
time pg_dump -h 127.0.0.1 -U backup_operator -d superstore -Fp -f /tmp/week3_backups/superstore_2026-10-14.sql
```

This created a plain-SQL logical backup. The recorded real time was **0.180 seconds**.

```bash
time pg_dumpall -U postgres --roles-only -f /tmp/week3_backups/roles_2026-10-14.sql
ls -lh /tmp/week3_backups/
pg_restore -l /tmp/week3_backups/superstore_2026-10-14.dump | grep -E 'TABLE DATA.*order_lines'
```

I exported the cluster roles using the administrative account. The recorded real time was **0.080 seconds**. I checked the sizes of the three files and reviewed the custom archive's contents to confirm that it included the `order_lines` table data.

## D. Copy the backups outside the container and server

```bash
exit
mkdir -p ~/db_backups/week3
sudo docker cp pg18:/tmp/week3_backups/. ~/db_backups/week3/
sudo chown -R azureuser:azureuser ~/db_backups/week3
chmod 700 ~/db_backups/week3
chmod 600 ~/db_backups/week3/*
ls -lh ~/db_backups/week3/
```

After leaving the container, I copied the backup files to the Linux virtual machine, set restrictive permissions on the directory and files, and checked that the files were present.

**WinSCP / Windows GUI steps (not shell commands):** I connected using SFTP and transferred the three backup files from `/home/azureuser/db_backups/week3/` to `C:\Users\moham\Downloads\CIT408_Backup_Files\`. The screenshots showed all three files in both the remote and local panels.

## E. Restore the full database and record the time

```bash
sudo docker exec pg18 createdb -U postgres superstore_restore
sudo docker exec -it pg18 bash
time pg_restore -U postgres -d superstore_restore --no-owner --no-acl --exit-on-error /tmp/week3_backups/superstore_2026-10-14.dump
psql -U postgres -d superstore_restore -c "\dt"
psql -U postgres -d superstore_restore -c "SELECT COUNT(*) FROM public.order_lines;"
```

I created a separate database named `superstore_restore` and restored the custom-format archive into it. The recorded restore time was **0.376 seconds**. The table listing showed nine tables, and `order_lines` contained 9,994 records.

## F. Compare row counts and financial totals

The following equivalent queries were run against both `superstore` and `superstore_restore`. The full query used to compare the counts of all nine tables is saved in `verify.sql`.

```bash
psql -U postgres -d superstore -c "SELECT ROUND(SUM(sales)::numeric, 2) AS total_sales, ROUND(SUM(profit)::numeric, 2) AS total_profit FROM public.order_lines;"
psql -U postgres -d superstore_restore -c "SELECT ROUND(SUM(sales)::numeric, 2) AS total_sales, ROUND(SUM(profit)::numeric, 2) AS total_profit FROM public.order_lines;"
```

Both databases returned total sales of **$2,297,200.86** and total profit of **$286,397.02**. The row counts for all nine tables were also compared. See `verification_output.md` and `evidence/07_financial_totals.png`.

## G. Demonstrate recovery of a single table

```bash
psql -U postgres -d superstore_restore -c "DELETE FROM public.order_lines;"
psql -U postgres -d superstore_restore -c "SELECT COUNT(*) FROM public.order_lines;"
```

For the recovery demonstration, I deleted exactly **9,994** records from `order_lines` in `superstore_restore` only. The follow-up query confirmed that the table was empty. The original `superstore` database was not changed by this deletion.

```bash
time pg_restore -U postgres -d superstore_restore --data-only --schema=public --table=order_lines --no-owner --no-acl --exit-on-error /tmp/week3_backups/superstore_2026-10-14.dump
psql -U postgres -d superstore_restore -c "SELECT COUNT(*) AS order_lines, ROUND(SUM(sales)::numeric, 2) AS total_sales, ROUND(SUM(profit)::numeric, 2) AS total_profit FROM public.order_lines;"
```

I restored only the data for `order_lines` from the custom-format backup. The recorded recovery time was **0.335 seconds**. The table again contained 9,994 records, with **$2,297,200.86** in sales and **$286,397.02** in profit.

## H. Run the final table-count comparison

```bash
for db in superstore superstore_restore; do
  psql -U postgres -d "$db" -At -c "
    SELECT 'categories', COUNT(*) FROM public.categories
    UNION ALL SELECT 'customers', COUNT(*) FROM public.customers
    UNION ALL SELECT 'locations', COUNT(*) FROM public.locations
    UNION ALL SELECT 'order_lines', COUNT(*) FROM public.order_lines
    UNION ALL SELECT 'orders', COUNT(*) FROM public.orders
    UNION ALL SELECT 'products', COUNT(*) FROM public.products
    UNION ALL SELECT 'staging_superstore', COUNT(*) FROM public.staging_superstore
    UNION ALL SELECT 'states', COUNT(*) FROM public.states
    UNION ALL SELECT 'subcategories', COUNT(*) FROM public.subcategories
    ORDER BY 1;" > "/tmp/${db}_counts.txt"
done

diff -u /tmp/superstore_counts.txt /tmp/superstore_restore_counts.txt \
  && echo "PASS: All nine table counts match"
```

The output files matched, and the terminal displayed **`PASS: All nine table counts match`**.

## I. Incident Desk Activity 3.2

I completed all six simulator tickets. The shift report showed a score of **18/18**, with all six methods correct on the first attempt and both ordering questions correct on the first attempt. The supporting screenshot is `evidence/10_activity_3_2_shift_report.png`.

## J. Git upload — still needs to be done

The commands below are **instructions for submitting the work, not actions confirmed in the screenshots**.

```bash
cd ~/cit408-coralbay
mkdir -p week3/backup
# Copy the final documentation and evidence into week3/backup first.
git add week3/backup/
git status
# Check that no backup archives, role dumps, or passwords are staged.
git commit -m "CIT 408 Week 3 - backup and restore evidence"
git push origin main
```
