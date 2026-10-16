# CIT 408 — Module 3 Assignment 3.2 submission

Submit the GitHub URL to `week3/drill/`. `incident_report.md`, `commands.md`, `verify.sql`, `evidence/`, and `screenshots/` are included. `instructor_scripts/` contains the original supplied SQL files for reproducibility, **not** for rerunning on the recovered server.

**Safety:** No credentials, live PostgreSQL data directory, or physical backups are included. The preserved damaged directory and physical backups remain on Azure.

**Evidence notes:** The archiver initially recorded 12 permission-denied failures; the failure count remained 12 while archived_count increased from 2 to 3. This is zero *new* failures, not a historical failed_count of zero. Incident detection time was not separately recorded; workload completion provides a documented upper bound. The 2m40s recovery execution interval excludes investigation.

**Remaining:** Check GitHub file sizes and inclusion of the screenshots; verify repository commits and submit the URL.
