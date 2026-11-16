-- ===== 1. Матеріалізоване представлення: виручка по місяцях =====
CREATE MATERIALIZED VIEW mv_monthly_revenue AS
SELECT date_trunc('month', check_in)::date AS month,
       COUNT(*)                            AS bookings_cnt,
       SUM(total_price)                    AS revenue,
       ROUND(AVG(total_price), 2)          AS avg_booking
FROM bookings
WHERE status <> 'cancelled'
GROUP BY 1;

-- унікальний індекс потрібен для REFRESH ... CONCURRENTLY
CREATE UNIQUE INDEX idx_mv_monthly_revenue_month ON mv_monthly_revenue(month);

-- ===== 2. Автооновлення через тригер =====
CREATE OR REPLACE FUNCTION refresh_mv_monthly_revenue() RETURNS TRIGGER AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_monthly_revenue;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trg_refresh_mv_revenue
AFTER INSERT OR UPDATE OR DELETE ON bookings
FOR EACH STATEMENT EXECUTE FUNCTION refresh_mv_monthly_revenue();

-- ===== 3. Каскад, крок 2: скасування бронювання видаляє його послуги =====
CREATE OR REPLACE FUNCTION cascade_booking_cancel() RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM booking_services WHERE booking_id = NEW.booking_id;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trg_booking_cancel_cascade
AFTER UPDATE OF status ON bookings
FOR EACH ROW
WHEN (NEW.status = 'cancelled' AND OLD.status IS DISTINCT FROM 'cancelled')
EXECUTE FUNCTION cascade_booking_cancel();

-- ===== 4. Каскад, крок 3: зміни в booking_services потрапляють в audit_log =====
CREATE TRIGGER trg_booking_services_audit
AFTER INSERT OR UPDATE OR DELETE ON booking_services
FOR EACH ROW EXECUTE FUNCTION audit_all_changes('booking_id');

-- ===== 5. Каскад, крок 1: номер на ремонті скасовує його майбутні бронювання =====
CREATE OR REPLACE FUNCTION cascade_room_maintenance() RETURNS TRIGGER AS $$
BEGIN
    UPDATE bookings
    SET status = 'cancelled'
    WHERE room_id = NEW.room_id
      AND status = 'confirmed'
      AND check_in > CURRENT_DATE;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trg_room_maintenance_cascade
AFTER UPDATE OF status ON rooms
FOR EACH ROW
WHEN (NEW.status = 'maintenance' AND OLD.status IS DISTINCT FROM 'maintenance')
EXECUTE FUNCTION cascade_room_maintenance();