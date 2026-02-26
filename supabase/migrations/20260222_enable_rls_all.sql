-- Enable Row Level Security on all tables
-- This ensures that even for a single-user app, the database has a basic safety layer.
-- For now, we allow ALL operations for the 'anon' role since the user is the only one using the app.

-- Products
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous all access on products" ON products FOR ALL TO anon USING (true)
WITH
    CHECK (true);

-- Customers
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous all access on customers" ON customers FOR ALL TO anon USING (true)
WITH
    CHECK (true);

-- Categories
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous all access on categories" ON categories FOR ALL TO anon USING (true)
WITH
    CHECK (true);

-- Orders
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous all access on orders" ON orders FOR ALL TO anon USING (true)
WITH
    CHECK (true);

-- Order Items
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous all access on order_items" ON order_items FOR ALL TO anon USING (true)
WITH
    CHECK (true);

-- Suppliers
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous all access on suppliers" ON suppliers FOR ALL TO anon USING (true)
WITH
    CHECK (true);

-- Raw Materials
ALTER TABLE raw_materials ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous all access on raw_materials" ON raw_materials FOR ALL TO anon USING (true)
WITH
    CHECK (true);

-- Raw Material Purchases
ALTER TABLE material_purchases ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous all access on material_purchases" ON material_purchases FOR ALL TO anon USING (true)
WITH
    CHECK (true);

-- Purchase Items
ALTER TABLE purchase_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous all access on purchase_items" ON purchase_items FOR ALL TO anon USING (true)
WITH
    CHECK (true);

-- Production Logs
ALTER TABLE production_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous all access on production_logs" ON production_logs FOR ALL TO anon USING (true)
WITH
    CHECK (true);

-- Product Recipes (Already fixed in previous migration, but ensuring RLS is enabled)
ALTER TABLE product_recipes ENABLE ROW LEVEL SECURITY;
-- Note: Policy for product_recipes was already created in 20260219 migration.