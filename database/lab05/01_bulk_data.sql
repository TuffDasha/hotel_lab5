\timing on
BEGIN;

ALTER TABLE payments DISABLE TRIGGER trg_payment_check;

INSERT INTO guests (first_name, last_name, email, phone, birth_date)
SELECT
    (ARRAY['Олександр','Марія','Андрій','Ольга','Іван','Наталія','Дмитро','Софія','Василь','Тетяна'])[1 + g % 10],
    (ARRAY['Ковал','Шевч','Бонд','Ткач','Мельн','Кравч','Олійн','Лисе','Петр','Гриц',
           'Мороз','Савч','Рома','Іван','Попов','Кучер','Лебед','Мазур','Бойк','Тимош'])[1 + g % 20]
    || (ARRAY['енко','ук','ський','чук','ов'])[1 + (g / 20) % 5],
    'guest' || g || '@example.com',
    CASE WHEN g % 10 = 0 THEN NULL
         ELSE '+38050' || lpad((1000000 + g)::text, 7, '0') END,
    DATE '1950-01-01' + (random() * 20000)::int
FROM generate_series(1, 50000) AS g;

INSERT INTO rooms (room_number, floor, room_type_id, status)
SELECT 'R' || g, 1 + g % 20, 1 + g % 10, 'available'
FROM generate_series(1, 300) AS g;

INSERT INTO bookings (guest_id, room_id, check_in, check_out, guests_count, status)
SELECT
    13 + floor(random() * 50000)::int,
    r.room_id,
    DATE '2019-01-01' + k * 4,
    DATE '2019-01-01' + k * 4 + (1 + floor(random() * 3))::int,
    1,
    CASE WHEN random() < 0.12 THEN 'cancelled' ELSE 'checked_out' END
FROM rooms r
CROSS JOIN generate_series(0, 599) AS k
WHERE r.room_number LIKE 'R%';

INSERT INTO payments (booking_id, amount, method, paid_at)
SELECT b.booking_id, b.total_price,
       (ARRAY['card','cash','transfer'])[1 + floor(random() * 3)::int],
       b.check_out + TIME '12:00'
FROM bookings b
JOIN rooms r ON r.room_id = b.room_id
WHERE r.room_number LIKE 'R%' AND b.status = 'checked_out';

INSERT INTO booking_services (booking_id, service_id, quantity)
SELECT b.booking_id,
       1 + floor(power(random(), 4) * 10)::int,
       1 + floor(random() * 3)::int
FROM bookings b
JOIN rooms r ON r.room_id = b.room_id
WHERE r.room_number LIKE 'R%' AND b.status = 'checked_out' AND random() < 0.5
ON CONFLICT DO NOTHING;

ALTER TABLE payments ENABLE TRIGGER trg_payment_check;

COMMIT;
ANALYZE;

SELECT 'guests' AS t, COUNT(*) FROM guests UNION ALL
SELECT 'rooms', COUNT(*) FROM rooms UNION ALL
SELECT 'bookings', COUNT(*) FROM bookings UNION ALL
SELECT 'payments', COUNT(*) FROM payments UNION ALL
SELECT 'booking_services', COUNT(*) FROM booking_services;