-- ===== Складне представлення (JOIN двох таблиць) з правилами UPDATE =====
CREATE OR REPLACE VIEW v_room_catalog AS
SELECT r.room_id, r.room_number, r.floor, r.status,
       rt.name AS room_type, rt.base_price
FROM rooms r
JOIN room_types rt ON rt.room_type_id = r.room_type_id;

-- UPDATE через представлення змінює лише статус і поверх номера
CREATE OR REPLACE RULE v_room_catalog_update AS
ON UPDATE TO v_room_catalog
DO INSTEAD
    UPDATE rooms
    SET status = NEW.status,
        floor  = NEW.floor
    WHERE room_id = OLD.room_id;

-- ===== Часткові індекси =====
-- Лише активні бронювання (їх мало порівняно з архівом)
CREATE INDEX idx_bookings_active_dates ON bookings(check_in, check_out)
WHERE status IN ('confirmed', 'checked_in');

-- Лише скасовані бронювання
CREATE INDEX idx_bookings_cancelled ON bookings(guest_id)
WHERE status = 'cancelled';

ANALYZE;