CREATE INDEX idx_guests_last_name ON guests(last_name);
CREATE INDEX idx_payments_paid_at ON payments(paid_at);
CREATE INDEX idx_booking_services_service ON booking_services(service_id);
ANALYZE;й