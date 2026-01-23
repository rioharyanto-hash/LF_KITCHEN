-- =============================================
-- LF Kitchen v1.2.0 - Production Management
-- Database Migration: Add production tracking
-- =============================================

-- 1. Tambah kolom produced_qty di order_items untuk track produksi parsial
-- Default 0 artinya belum diproduksi
ALTER TABLE order_items
ADD COLUMN IF NOT EXISTS produced_qty INTEGER DEFAULT 0;

-- 2. Buat tabel production_logs untuk history produksi
CREATE TABLE IF NOT EXISTS production_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

-- Referensi ke order & item
order_id UUID NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
order_item_id UUID REFERENCES order_items (id) ON DELETE SET NULL,

-- Info produk
product_id UUID REFERENCES products (id) ON DELETE SET NULL,
product_name VARCHAR(255) NOT NULL,
product_size VARCHAR(50),

-- Info pemesan
customer_name VARCHAR(255), delivery_date DATE,

-- Qty yang diproduksi dalam log ini
quantity INTEGER NOT NULL DEFAULT 1,

-- Siapa yang input produksi
produced_by VARCHAR(255),

-- Timestamp
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

-- Notes opsional
notes TEXT );

-- 3. Index untuk performa query laporan
CREATE INDEX IF NOT EXISTS idx_production_logs_created_at ON production_logs (created_at);

CREATE INDEX IF NOT EXISTS idx_production_logs_product_id ON production_logs (product_id);

CREATE INDEX IF NOT EXISTS idx_production_logs_order_id ON production_logs (order_id);

CREATE INDEX IF NOT EXISTS idx_production_logs_delivery_date ON production_logs (delivery_date);

-- 4. RLS Policy (sesuaikan dengan policy yang sudah ada)
ALTER TABLE production_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all operations for authenticated users" ON production_logs FOR ALL USING (true);

-- =============================================
-- CONTOH QUERY UNTUK LAPORAN:
-- =============================================

-- Laporan produksi berdasarkan tanggal ambil:
-- SELECT * FROM production_logs WHERE delivery_date BETWEEN '2026-01-01' AND '2026-01-31';

-- Laporan produksi berdasarkan nama pemesan:
-- SELECT * FROM production_logs WHERE customer_name ILIKE '%Siti%';

-- Laporan produksi berdasarkan nama produk:
-- SELECT * FROM production_logs WHERE product_name ILIKE '%Brownies%';

-- Laporan produksi berdasarkan ukuran:
-- SELECT * FROM production_logs WHERE product_size = '22 cm';

-- =============================================
-- RPC FUNCTIONS untuk atomic updates
-- =============================================

-- Function untuk increment produced_qty di order_items
CREATE OR REPLACE FUNCTION increment_produced_qty(item_id UUID, qty INTEGER)
RETURNS void AS $$
BEGIN
  UPDATE order_items 
  SET produced_qty = COALESCE(produced_qty, 0) + qty
  WHERE id = item_id;
END;
$$ LANGUAGE plpgsql;

-- Function untuk increment stock di products
CREATE OR REPLACE FUNCTION increment_stock(p_id UUID, qty INTEGER)
RETURNS void AS $$
BEGIN
  UPDATE products 
  SET stock_qty = COALESCE(stock_qty, 0) + qty,
      updated_at = NOW()
  WHERE id = p_id;
END;
$$ LANGUAGE plpgsql;

-- Function untuk decrement stock di products
CREATE OR REPLACE FUNCTION decrement_stock(p_id UUID, qty INTEGER)
RETURNS void AS $$
BEGIN
  UPDATE products 
  SET stock_qty = COALESCE(stock_qty, 0) - qty,
      updated_at = NOW()
  WHERE id = p_id;
END;
$$ LANGUAGE plpgsql;