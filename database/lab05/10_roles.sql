-- Групові ролі (без входу), кожна наслідує права попередньої
CREATE ROLE hotel_user NOLOGIN;
CREATE ROLE hotel_moderator NOLOGIN;
CREATE ROLE hotel_admin NOLOGIN;

GRANT hotel_user TO hotel_moderator;
GRANT hotel_moderator TO hotel_admin;

-- Звичайний користувач: перегляд довідників і безпечних представлень
GRANT CONNECT ON DATABASE hotel_booking TO hotel_user;
GRANT USAGE ON SCHEMA public TO hotel_user;
GRANT SELECT ON room_types, rooms, services,
                v_active_bookings, v_room_type_performance, mv_monthly_revenue
    TO hotel_user;

-- Модератор: працює з гостями, бронюваннями, оплатами
GRANT SELECT, INSERT, UPDATE ON guests, bookings, booking_services, payments TO hotel_moderator;
GRANT UPDATE ON rooms TO hotel_moderator;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO hotel_moderator;

-- Адміністратор: повний доступ, включно з видаленням і журналом аудиту
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO hotel_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO hotel_admin;

-- Конкретні користувачі
CREATE USER guest_viewer WITH PASSWORD 'Gv#2026_hotel';
GRANT hotel_user TO guest_viewer;

CREATE USER hotel_manager WITH PASSWORD 'Hm#2026_hotel';
GRANT hotel_moderator TO hotel_manager;

CREATE USER hotel_owner WITH PASSWORD 'Ho#2026_hotel';
GRANT hotel_admin TO hotel_owner;