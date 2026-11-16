CREATE USER report_viewer WITH PASSWORD 'Rv#2026_hotel';

GRANT CONNECT ON DATABASE hotel_booking TO report_viewer;
GRANT USAGE ON SCHEMA public TO report_viewer;

GRANT SELECT ON room_types, rooms, services TO report_viewer;
GRANT SELECT (guest_id, first_name, last_name) ON guests TO report_viewer;
GRANT SELECT (booking_id, guest_id, room_id, check_in, check_out, guests_count, status) ON bookings TO report_viewer;
GRANT SELECT ON v_active_bookings, v_room_type_performance TO report_viewer;