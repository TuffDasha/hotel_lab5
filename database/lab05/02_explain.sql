-- Запит A: гість за прізвищем і його витрати
EXPLAIN (ANALYZE, BUFFERS)
SELECT g.guest_id, g.first_name, g.last_name,
       COUNT(b.booking_id) AS bookings_cnt,
       SUM(b.total_price)  AS spent
FROM guests g
JOIN bookings b ON b.guest_id = g.guest_id AND b.status <> 'cancelled'
WHERE g.last_name = 'Коваленко'
GROUP BY g.guest_id, g.first_name, g.last_name
ORDER BY spent DESC;

-- Запит B: оплати за березень 2025
EXPLAIN (ANALYZE, BUFFERS)
SELECT date_trunc('day', p.paid_at) AS day,
       p.method,
       COUNT(*)      AS payments_cnt,
       SUM(p.amount) AS total
FROM payments p
WHERE p.paid_at >= '2025-03-01' AND p.paid_at < '2025-04-01'
GROUP BY 1, 2
ORDER BY 1, 2;

-- Запит C: виручка від послуги «Оренда велосипеда» по роках
EXPLAIN (ANALYZE, BUFFERS)
SELECT date_trunc('year', b.check_in) AS year,
       COUNT(*)                       AS uses,
       SUM(bs.quantity)               AS total_qty,
       SUM(bs.quantity * s.price)     AS revenue
FROM services s
JOIN booking_services bs ON bs.service_id = s.service_id
JOIN bookings b          ON b.booking_id = bs.booking_id
WHERE s.name = 'Оренда велосипеда'
GROUP BY 1
ORDER BY 1;