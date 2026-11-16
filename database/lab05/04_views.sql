CREATE OR REPLACE VIEW v_active_bookings AS
SELECT b.booking_id,
       g.first_name || ' ' || g.last_name AS guest_name,
       r.room_number,
       rt.name AS room_type,
       b.check_in, b.check_out, b.status, b.total_price
FROM bookings b
JOIN guests g      ON g.guest_id = b.guest_id
JOIN rooms r       ON r.room_id = b.room_id
JOIN room_types rt ON rt.room_type_id = r.room_type_id
WHERE b.status IN ('confirmed', 'checked_in');

CREATE OR REPLACE VIEW v_room_type_performance AS
SELECT rt.room_type_id,
       rt.name AS room_type,
       COUNT(DISTINCT r.room_id) AS rooms_cnt,
       COUNT(b.booking_id) AS bookings_cnt,
       COUNT(b.booking_id) FILTER (WHERE b.status = 'cancelled') AS cancelled_cnt,
       ROUND(100.0 * COUNT(b.booking_id) FILTER (WHERE b.status = 'cancelled')
             / NULLIF(COUNT(b.booking_id), 0), 1) AS cancel_pct,
       COALESCE(SUM(b.total_price) FILTER (WHERE b.status <> 'cancelled'), 0) AS revenue
FROM room_types rt
LEFT JOIN rooms r    ON r.room_type_id = rt.room_type_id
LEFT JOIN bookings b ON b.room_id = r.room_id
GROUP BY rt.room_type_id, rt.name;