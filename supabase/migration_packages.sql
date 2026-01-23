-- ================================================
-- LF Kitchen - Migration: Packages (Paketan)
-- Jalankan SQL ini di Supabase SQL Editor
-- ================================================

-- ===============================
-- 1. TABEL PACKAGES (Master Data Paket)
-- ===============================
CREATE TABLE IF NOT EXISTS packages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(12, 2) NOT NULL DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- Index untuk search
CREATE INDEX IF NOT EXISTS idx_packages_name ON packages (name);

CREATE INDEX IF NOT EXISTS idx_packages_is_active ON packages (is_active);

-- ===============================
-- 2. TABEL PACKAGE_ITEMS (Komponen Paket)
-- ===============================
CREATE TABLE IF NOT EXISTS package_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    package_id UUID NOT NULL REFERENCES packages (id) ON DELETE CASCADE,
    product_id UUID REFERENCES products (id) ON DELETE SET NULL,
    item_name VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price NUMERIC(12, 2) DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_package_items_package_id ON package_items (package_id);

CREATE INDEX IF NOT EXISTS idx_package_items_product_id ON package_items (product_id);

-- ===============================
-- 3. TRIGGER untuk updated_at
-- ===============================
DROP TRIGGER IF EXISTS update_packages_updated_at ON packages;

CREATE TRIGGER update_packages_updated_at
    BEFORE UPDATE ON packages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===============================
-- 4. SAMPLE DATA (Opsional)
-- ===============================
-- INSERT INTO packages (name, description, price) VALUES
--     ('Paket Nasi Tumpeng', 'Nasi tumpeng lengkap dengan lauk', 250000),
--     ('Paket Kue Nampan', 'Aneka kue dalam nampan', 150000);

-- Done!