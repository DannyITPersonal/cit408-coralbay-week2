# Verification Results: Superstore Backup and Restore

**Student:** Mohamed Salem Maidan  
**Institution:** Atlantis University  
**Course:** CIT 408 — Database Management Operations and Optimization  
**Assignment:** Week 3 — Backup and Restore Superstore

## Comparing the original and restored databases

The terminal screenshots show that the original database and the restored database had matching row counts for all nine tables. After the single-table recovery test, the final `diff -u` comparison displayed **`PASS: All nine table counts match`**.

| Table | Original | Restored |
|---|---:|---:|
| categories | 3 | 3 |
| customers | 793 | 793 |
| locations | 632 | 632 |
| order_lines | 9,994 | 9,994 |
| orders | 5,009 | 5,009 |
| products | 1,894 | 1,894 |
| staging_superstore | 9,994 | 9,994 |
| states | 49 | 49 |
| subcategories | 17 | 17 |

## Checking the financial totals

The sales and profit totals were also the same in both databases.

| Metric | Original `superstore` | Restored `superstore_restore` |
|---|---:|---:|
| Total sales | $2,297,200.86 | $2,297,200.86 |
| Total profit | $286,397.02 | $286,397.02 |

## Testing recovery of one table

For the recovery test, I deleted the records from `public.order_lines` in `superstore_restore` only. The command returned `DELETE 9994`, and a follow-up count confirmed that the table had zero rows.

I then restored just the `order_lines` data from the custom-format backup. The recovery took **0.335 seconds**. Afterward, the table contained 9,994 rows again, with total sales of **$2,297,200.86** and total profit of **$286,397.02**. A final comparison confirmed that the row counts in all nine tables matched the original database.

## Evidence files

- `evidence/07_financial_totals.png`
- `evidence/08_single_table_rescue.png`
- `evidence/09_table_counts_diff.png`

*Note: These results were transcribed from the supplied screenshots. The author of this document did not independently rerun the queries.*
