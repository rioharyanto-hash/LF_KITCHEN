-- ============================================
-- LF KITCHEN - Database Reset Script
-- ============================================
-- PERINGATAN: Script ini akan MENGHAPUS SEMUA DATA!
-- Jalankan di Supabase SQL Editor
-- ============================================

-- Hapus data dari tabel yang ada
-- Jalankan hanya untuk tabel yang ada di database Anda

-- Tabel utama (sesuaikan dengan database Anda)
DELETE FROM order_items;

DELETE FROM orders;

DELETE FROM invoices;

DELETE FROM products;

DELETE FROM categories;

DELETE FROM customers;

-- Jika Anda memiliki tabel ini juga:
-- DELETE FROM purchase_items;
-- DELETE FROM purchases;
-- DELETE FROM raw_materials;
-- DELETE FROM suppliers;

-- Konfirmasi
SELECT 'Database berhasil direset!' as status;