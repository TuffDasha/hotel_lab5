CREATE TABLE audit_log (
    log_id     SERIAL PRIMARY KEY,
    table_name VARCHAR(50)  NOT NULL,
    operation  VARCHAR(10)  NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    record_id  INT,
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(100) NOT NULL DEFAULT current_user,
    changed_at TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION log_guest_changes() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, operation, record_id, new_values)
        VALUES ('guests', 'INSERT', NEW.guest_id, to_jsonb(NEW));
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, operation, record_id, old_values, new_values)
        VALUES ('guests', 'UPDATE', NEW.guest_id, to_jsonb(OLD), to_jsonb(NEW));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_guest_log
AFTER INSERT OR UPDATE ON guests
FOR EACH ROW EXECUTE FUNCTION log_guest_changes();