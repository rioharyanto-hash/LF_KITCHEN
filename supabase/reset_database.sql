-- ============================================
-- LF KITCHEN - Database Reset Script
-- ============================================
-- PERINGATAN: Script ini akan MENGHAPUS SEMUA DATA!
-- Jalankan di Supabase SQL Editor
-- ============================================

-- 1. Disable triggers temporarily
SET session_replication_role = 'replica';

-- 2. Truncate all tables (order matters due to foreign keys)

-- Order related
TRUNCATE TABLE order_items CASCADE;

TRUNCATE TABLE orders CASCADE;

-- Invoice
TRUNCATE TABLE invoices CASCADE;

-- Purchase related
TRUNCATE TABLE purchase_items CASCADE;

TRUNCATE TABLE purchases CASCADE;

-- Master data
TRUNCATE TABLE products CASCADE;

TRUNCATE TABLE categories CASCADE;

TRUNCATE TABLE customers CASCADE;

TRUNCATE TABLE raw_materials CASCADE;

TRUNCATE TABLE suppliers CASCADE;

-- 3. Re-enable triggers
SET session_replication_role = 'origin';

-- 4. Verify all tables are empty
SELECT 'orders' as table_name, COUNT(*) as count
FROM orders
UNION ALL
SELECT 'order_items', COUNT(*)
FROM order_items
UNION ALL
SELECT 'invoices', COUNT(*)
FROM invoices
UNION ALL
SELECT 'purchases', COUNT(*)
FROM purchases
UNION ALL
SELECT 'purchase_items', COUNT(*)
FROM purchase_items
UNION ALL
SELECT 'products', COUNT(*)
FROM products
UNION ALL
SELECT 'categories', COUNT(*)
FROM categories
UNION ALL
SELECT 'customers', COUNT(*)
FROM customers
UNION ALL
SELECT 'raw_materials', COUNT(*)
FROM raw_materials
UNION ALL
SELECT 'suppliers', COUNT(*)
FROM suppliers;

-- ============================================
-- Setelah reset, Anda bisa import data baru
-- menggunakan fitur import Excel di aplikasi
-- ============================================