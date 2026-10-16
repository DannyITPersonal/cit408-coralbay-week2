Superstore Backup and Recovery Plan

Student: Daniel Zayas
University: Atlantis University
Course: CIT 408 — Database Management Operations and Optimization
Assignment: Module 3, Assignment 3.1
Report Date: October 15, 2026

1. Purpose of the Plan

The goal of this plan is to protect the superstore PostgreSQL 18 database from problems such as server failure, accidental deletion, or incorrect changes to the data. The database contains nine tables, including 9,994 order-line records, so having reliable backups is important.

For this assignment, I created backups, restored the database into superstore_restore, and checked the results to make sure the restored data matched the original. All recovery testing was done on superstore_restore to avoid changing the original superstore database.

2. Recommended Backup Schedule

I recommend using the following schedule to keep the database protected:

Every day at 1:00 a.m.: Create a custom-format backup using pg_dump -Fc and the restricted backup_operator account. Also create a plain SQL backup and a separate backup of the server roles.

After each backup: Check that the command completed successfully, confirm that the file was created, review its size, and verify the contents of the custom-format archive. Any failures should be reported and investigated.

Once a week: Check that the backup copies are available outside the database server and that the files can be read.

Once a month: Restore a backup into a separate test database. Compare the row counts for all nine tables, check total sales and profit, and test recovering only the order-line data.

This is my recommended schedule for future use. These automated backups and recurring checks have not been configured on the server as part of this assignment.

3. Backup Retention and Storage

To make sure backups are available when needed, I recommend keeping them for the following periods:

Daily backups: Keep the most recent 14 days.

Weekly backups: Keep eight weeks of backups.

Monthly backups: Keep six months of backups.

The backups should be stored securely, with one copy on the database server and another on a separate computer, such as the Windows workstation used for this assignment. At least one additional encrypted copy should be kept off-site in case the server and local computer are affected by the same incident.

Access to the backup folders should be limited to authorized users. The roles backup should also be protected because it may contain sensitive authentication information. Actual backup files, passwords, and other secrets should never be committed to GitHub.

Whenever practical, I would follow the 3-2-1 backup approach: maintain three copies of the data, use two different types of storage, and keep at least one copy off-site.

4. Backup and Restore Measurements

During testing on October 14–15, 2026, I recorded the following execution times:

Operation

Recorded time

Custom-format backup

0.329 seconds

Plain SQL backup

0.180 seconds

Roles-only backup

0.080 seconds

Full database restore

0.376 seconds

Single-table data recovery

0.335 seconds

The backup files had the following sizes according to the recorded output:

Backup file

Reported size

superstore_2026-10-14.dump

851 KiB

superstore_2026-10-14.sql

3.2 MiB

roles_2026-10-14.sql

952 bytes

The Windows file-transfer window showed approximately 851 KB, 3,251 KB, and 1 KB, respectively. These are rounded display values, so they may not match the exact file sizes in bytes.

The tests show that the backup and restore commands completed quickly for this database. However, these times only represent the operations measured during the assignment, not the time required to recover an entire production system.

5. Recovery Point and Recovery Time Objectives

Recovery Point Objective (RPO)

My proposed RPO is 24 hours. With a successful daily backup, this means the goal is to limit potential data loss to no more than one day's worth of changes.

This target assumes that daily backups are completed successfully and that a usable backup is available. If a backup fails or is missed, the actual amount of potential data loss could be greater than 24 hours. More frequent backups or point-in-time recovery would be needed to reduce that risk further.

Recovery Time Objective (RTO)

My proposed RTO is 60 minutes. The full database restore took 0.376 seconds during this test, but restoring a real system involves more than running one command.

The recovery process may also require identifying the problem, setting up or repairing a server, locating and transferring the backup, restoring the database, checking the results, and reconnecting applications.

For that reason, the 60-minute RTO is a target rather than a confirmed recovery time. A full recovery exercise would be needed to measure the entire process and determine whether the target is realistic.

6. Recovery Procedure

If the database needs to be recovered, I would follow these steps:

Identify the problem, determine which data is affected, and preserve relevant logs.

Locate the most recent successful backup and confirm that the file is available and usable.

Prepare PostgreSQL 18 and create a separate, empty target database.

Restore the custom-format backup with pg_restore, using an account with the necessary administrative permissions.

Run the verification queries against the original and restored databases when the original database is still available.

Compare the row counts of all nine tables and confirm that total sales and total profit match to the cent.

If only one table needs recovery, restore only the affected table's data instead of replacing the entire database.

Record the recovery time, verification results, and any problems encountered before closing the incident.

These checks help confirm that the recovery worked instead of assuming everything is correct simply because the restore command finished without errors.

7. Test Results and Conclusion

The full restore test successfully recovered all nine tables, including the 9,994 order-line records. The original and restored databases both showed total sales of $2,297,200.86 and total profit of $286,397.02.

I also tested recovering a single table. After deleting the order-line records from superstore_restore, I restored that table's data from the backup. The operation took 0.335 seconds and brought the table back to 9,994 records. The sales and profit totals also matched the expected values.

Finally, the comparison of all nine table counts displayed:

PASS: All nine table counts match

These results demonstrate that the full restore and the single-table recovery worked for the tested database.

8. Limitations and Future Improvements

The measured times do not include transferring the backup to the Windows computer, retrieving a copy from off-site storage, or preparing a replacement server. The row counts and financial totals provide useful evidence that the restored data matches, but they do not prove that every individual value is identical.

The backup schedule, retention periods, and RPO/RTO targets in this plan are recommendations. They have not been deployed as an automated backup system or tested through a complete disaster recovery exercise.

As a next step, I would schedule the backups, monitor their success, check the off-site copies regularly, and perform full recovery tests to make sure the plan works under realistic conditions.