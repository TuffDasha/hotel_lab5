-- ===== 1. Тригер валідації гостя (відхиляє некоректні значення) =====
CREATE OR REPLACE FUNCTION validate_guest_data() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        RAISE EXCEPTION 'Некоректний email: %', NEW.email
            USING ERRCODE = 'check_violation';
    END IF;
    IF NEW.phone IS NOT NULL AND NEW.phone !~ '^\+?[0-9\s\-()]{7,20}$' THEN
        RAISE EXCEPTION 'Некоректний телефон: %', NEW.phone
            USING ERRCODE = 'check_violation';
    END IF;
    IF NEW.birth_date IS NOT NULL AND NEW.birth_date < DATE '1900-01-01' THEN
        RAISE EXCEPTION 'Дата народження занадто рання: %', NEW.birth_date
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_guest_validate
BEFORE INSERT OR UPDATE ON guests
FOR EACH ROW EXECUTE FUNCTION validate_guest_data();

-- ===== 2. Повне логування INSERT / UPDATE / DELETE (універсальне) =====
-- Первинний ключ береться з першого стовпця рядка, тому функція підходить будь-якій таблиці
CREATE OR REPLACE FUNCTION audit_all_changes() RETURNS TRIGGER AS $$
DECLARE
    v_id INT;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_id := (to_jsonb(OLD) ->> TG_ARGV[0])::INT;
        INSERT INTO audit_log (table_name, operation, record_id, old_values)
        VALUES (TG_TABLE_NAME, 'DELETE', v_id, to_jsonb(OLD));
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        v_id := (to_jsonb(NEW) ->> TG_ARGV[0])::INT;
        INSERT INTO audit_log (table_name, operation, record_id, old_values, new_values)
        VALUES (TG_TABLE_NAME, 'UPDATE', v_id, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSE
        v_id := (to_jsonb(NEW) ->> TG_ARGV[0])::INT;
        INSERT INTO audit_log (table_name, operation, record_id, new_values)
        VALUES (TG_TABLE_NAME, 'INSERT', v_id, to_jsonb(NEW));
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- guests: замінюємо простий тригер рівня 1 на повний (інакше INSERT/UPDATE логувалися б двічі)
DROP TRIGGER trg_guest_log ON guests;

CREATE TRIGGER trg_guests_audit
AFTER INSERT OR UPDATE OR DELETE ON guests
FOR EACH ROW EXECUTE FUNCTION audit_all_changes('guest_id');

CREATE TRIGGER trg_rooms_audit
AFTER INSERT OR UPDATE OR DELETE ON rooms
FOR EACH ROW EXECUTE FUNCTION audit_all_changes('room_id');