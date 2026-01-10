-- ================================================
-- LF Kitchen - Supabase Database Schema
-- Jalankan SQL ini di Supabase SQL Editor
-- ================================================

-- ===============================
-- 1. MASTER DATA TABLES
-- ===============================

-- Tabel Products (Produk Kue)
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    unit_price NUMERIC(12, 2) NOT NULL DEFAULT 0,
    special_price NUMERIC(12, 2) DEFAULT 0,
    cost_price NUMERIC(12, 2),
    stock_qty INTEGER NOT NULL DEFAULT 0,
    category VARCHAR(100),
    image_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- Index untuk search
CREATE INDEX IF NOT EXISTS idx_products_name ON products (name);

CREATE INDEX IF NOT EXISTS idx_products_category ON products (category);

-- Tabel Customers (Pelanggan)
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    address TEXT,
    notes TEXT,
    is_special_price BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- Index untuk search
CREATE INDEX IF NOT EXISTS idx_customers_name ON customers (name);

CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers (phone);

-- Tabel Suppliers (Pemasok Bahan)
CREATE TABLE IF NOT EXISTS suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    contact_person VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- Tabel Raw Materials (Bahan Baku)
CREATE TABLE IF NOT EXISTS raw_materials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    name VARCHAR(255) NOT NULL,
    unit VARCHAR(20) NOT NULL DEFAULT 'pcs', -- kg, gr, pcs, liter
    stock_qty NUMERIC(12, 2) NOT NULL DEFAULT 0,
    min_stock_alert NUMERIC(12, 2) DEFAULT 10,
    last_purchase_price NUMERIC(12, 2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- ===============================
-- 2. TRANSACTION TABLES
-- ===============================

-- Custom Types (Enum)
DO $$ BEGIN
    CREATE TYPE order_type AS ENUM ('PO', 'DIRECT');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE order_status AS ENUM ('DRAFT', 'CONFIRMED', 'PROCESSING', 'READY', 'COMPLETED', 'CANCELLED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_status AS ENUM ('UNPAID', 'PARTIAL', 'PAID');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Tabel Orders (Pesanan PO & Direct Sales)
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    customer_id UUID REFERENCES customers (id) ON DELETE SET NULL,
    order_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    order_type order_type NOT NULL DEFAULT 'DIRECT',
    status order_status NOT NULL DEFAULT 'DRAFT',
    total_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
    dp_amount NUMERIC(12, 2) DEFAULT 0,
    payment_status payment_status NOT NULL DEFAULT 'UNPAID',
    delivery_date DATE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- Index untuk filter
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders (status);

CREATE INDEX IF NOT EXISTS idx_orders_order_type ON orders (order_type);

CREATE INDEX IF NOT EXISTS idx_orders_delivery_date ON orders (delivery_date);

CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders (customer_id);

-- Tabel Order Items (Detail Pesanan)
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    order_id UUID NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products (id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price NUMERIC(12, 2) NOT NULL,
    subtotal NUMERIC(12, 2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items (order_id);

CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items (product_id);

-- Tabel Material Purchases (Pembelian Bahan Baku)
CREATE TABLE IF NOT EXISTS material_purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    supplier_id UUID REFERENCES suppliers (id) ON DELETE SET NULL,
    purchase_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    total_cost NUMERIC(12, 2) NOT NULL DEFAULT 0,
    invoice_number VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_material_purchases_supplier_id ON material_purchases (supplier_id);

CREATE INDEX IF NOT EXISTS idx_material_purchases_purchase_date ON material_purchases (purchase_date);

-- Tabel Purchase Items (Detail Pembelian)
CREATE TABLE IF NOT EXISTS purchase_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    purchase_id UUID NOT NULL REFERENCES material_purchases (id) ON DELETE CASCADE,
    material_id UUID NOT NULL REFERENCES raw_materials (id) ON DELETE RESTRICT,
    quantity NUMERIC(12, 2) NOT NULL,
    unit_cost NUMERIC(12, 2) NOT NULL,
    subtotal NUMERIC(12, 2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase_id ON purchase_items (purchase_id);

CREATE INDEX IF NOT EXISTS idx_purchase_items_material_id ON purchase_items (material_id);

-- ===============================
-- 3. TRIGGERS (Auto-update timestamps)
-- ===============================

-- Function untuk update timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger untuk setiap tabel
DROP TRIGGER IF EXISTS update_products_updated_at ON products;

CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_customers_updated_at ON customers;

CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_suppliers_updated_at ON suppliers;

CREATE TRIGGER update_suppliers_updated_at
    BEFORE UPDATE ON suppliers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_raw_materials_updated_at ON raw_materials;

CREATE TRIGGER update_raw_materials_updated_at
    BEFORE UPDATE ON raw_materials
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_orders_updated_at ON orders;

CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_material_purchases_updated_at ON material_purchases;

CREATE TRIGGER update_material_purchases_updated_at
    BEFORE UPDATE ON material_purchases
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===============================
-- 4. ROW LEVEL SECURITY (RLS)
-- Aktifkan jika perlu autentikasi
-- ===============================

-- Untuk saat ini, disable RLS untuk development
-- Aktifkan RLS saat production
-- ALTER TABLE products ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
-- etc...

-- ===============================
-- 5. SAMPLE DATA (Opsional)
-- ===============================

-- Contoh data Products
INSERT INTO
    products (
        name,
        description,
        unit_price,
        cost_price,
        stock_qty,
        category
    )
VALUES (
        'Nastar Premium',
        'Nastar lembut dengan selai nanas homemade',
        85000,
        45000,
        10,
        'Kue Kering'
    ),
    (
        'Kastengel Keju',
        'Kastengel dengan keju premium',
        90000,
        50000,
        8,
        'Kue Kering'
    ),
    (
        'Putri Salju',
        'Kue putri salju renyah',
        80000,
        40000,
        12,
        'Kue Kering'
    ),
    (
        'Brownies Coklat',
        'Brownies fudgy dengan coklat Belgia',
        120000,
        65000,
        5,
        'Kue Basah'
    ),
    (
        'Lapis Legit',
        'Kue lapis premium 20 lapis',
        350000,
        180000,
        3,
        'Kue Basah'
    ) ON CONFLICT DO NOTHING;

-- Contoh data Customers
INSERT INTO
    customers (name, phone, address)
VALUES (
        'Bu Ani',
        '08123456789',
        'Jl. Mawar No. 10, Jakarta'
    ),
    (
        'Pak Budi',
        '08234567890',
        'Jl. Melati No. 5, Jakarta'
    ),
    (
        'Ibu Citra',
        '08345678901',
        'Jl. Anggrek No. 15, Bekasi'
    ) ON CONFLICT DO NOTHING;

-- Done!
-- Jalankan query ini di Supabase SQL Editor