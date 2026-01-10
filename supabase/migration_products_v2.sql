-- Migration: Add new fields to products table
-- Fields: size, unit, product_type

-- Add new columns to products table
ALTER TABLE products ADD COLUMN IF NOT EXISTS size VARCHAR(50);

ALTER TABLE products
ADD COLUMN IF NOT EXISTS unit VARCHAR(20) DEFAULT 'pcs';

ALTER TABLE products
ADD COLUMN IF NOT EXISTS product_type VARCHAR(50);

-- Create index for faster filtering
CREATE INDEX IF NOT EXISTS idx_products_product_type ON products (product_type);

CREATE INDEX IF NOT EXISTS idx_products_size ON products (size);

-- Update existing products with default values
UPDATE products SET unit = 'pcs' WHERE unit IS NULL;

-- Example product types:
-- Cake, Pastry, Bread, Snack, Minuman

COMMENT ON COLUMN products.size IS 'Ukuran produk: 22cm, 24cm, slice, dll';

COMMENT ON COLUMN products.unit IS 'Satuan: pcs, box, slice, loyang';

COMMENT ON COLUMN products.product_type IS 'Jenis produk: Cake, Pastry, Bread, Snack, Minuman';