-- ================================================
-- LF Kitchen - Invoice Table Migration
-- Jalankan SQL ini di Supabase SQL Editor
-- ================================================

-- Tabel Invoices (Tagihan Pelanggan)
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    order_id UUID REFERENCES orders (id) ON DELETE SET NULL,
    customer_id UUID REFERENCES customers (id) ON DELETE SET NULL,
    customer_name VARCHAR(255),
    total_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
    paid_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
    remaining_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
    due_date DATE,
    status payment_status NOT NULL DEFAULT 'UNPAID', -- UNPAID, PARTIAL, PAID
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- Index untuk filter
CREATE INDEX IF NOT EXISTS idx_invoices_customer_id ON invoices (customer_id);

CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices (status);

CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON invoices (due_date);

-- Trigger untuk update timestamp
DROP TRIGGER IF EXISTS update_invoices_updated_at ON invoices;

CREATE TRIGGER update_invoices_updated_at
    BEFORE UPDATE ON invoices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS Policy
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all for invoices" ON invoices FOR ALL USING (true)
WITH
    CHECK (true);