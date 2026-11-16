CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- 1. Використання індексів (від найменш до найбільш використовуваних)
CREATE OR REPLACE VIEW v_index_usage AS
SELECT s.relname AS table_name,
       s.indexrelname AS index_name,
       s.idx_scan AS scans,
       s.idx_tup_read AS tuples_read,
       pg_size_pretty(pg_relation_size(s.indexrelid)) AS size
FROM pg_stat_user_indexes s
ORDER BY s.idx_scan, pg_relation_size(s.indexrelid) DESC;

-- 2. Найповільніші запити
CREATE OR REPLACE VIEW v_slowest_queries AS
SELECT LEFT(regexp_replace(query, '\s+', ' ', 'g'), 80) AS query,
       calls,
       ROUND(total_exec_time::numeric, 1) AS total_ms,
       ROUND(mean_exec_time::numeric, 2)  AS mean_ms,
       ROUND(max_exec_time::numeric, 1)   AS max_ms
FROM pg_stat_statements
WHERE query NOT ILIKE '%pg_stat%'
ORDER BY mean_exec_time DESC
LIMIT 10;