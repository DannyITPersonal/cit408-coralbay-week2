-- Exact row count of every table in the current database.
-- Run it in the original and in the restored database, then compare the two lists.
SELECT table_schema,
       table_name,
       (xpath('/row/n/text()',
              query_to_xml(format('SELECT count(*) AS n FROM %I.%I', table_schema, table_name),
                           false, true, '')))[1]::text::bigint AS row_count
FROM   information_schema.tables
WHERE  table_type = 'BASE TABLE'
  AND  table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER  BY table_schema, table_name;
