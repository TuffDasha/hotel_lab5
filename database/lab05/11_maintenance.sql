CREATE TABLE IF NOT EXISTS maintenance_log (
    log_id      SERIAL PRIMARY KEY,
    operation   TEXT NOT NULL,
    executed_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE maintain_database()
LANGUAGE plpgsql
AS $$
DECLARE
    tbl RECORD;
BEGIN
    ANALYZE;

    FOR tbl IN
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        EXECUTE format('REINDEX TABLE public.%I', tbl.tablename);
        INSERT INTO maintenance_log (operation)
        VALUES ('REINDEX ' || tbl.tablename);
    END LOOP;

    INSERT INTO maintenance_log (operation) VALUES ('ANALYZE (вся база)');
    RAISE NOTICE 'Обслуговування бази завершено';
END;
$$;