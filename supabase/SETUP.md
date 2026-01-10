# LF Kitchen - Supabase Setup Guide

## Langkah 1: Buat Project Supabase

1. Buka [supabase.com](https://supabase.com) dan login/register
2. Klik **New Project**
3. Isi:
   - **Project Name**: `lf-kitchen`
   - **Database Password**: (catat password ini!)
   - **Region**: Southeast Asia (Singapore)
4. Klik **Create new project** dan tunggu ~2 menit

## Langkah 2: Jalankan Schema SQL

1. Di dashboard Supabase, buka **SQL Editor** (icon database di sidebar)
2. Klik **New query**
3. Copy-paste isi file `supabase/schema.sql` ke editor
4. Klik **Run** (atau Ctrl+Enter)
5. Pastikan muncul "Success. No rows returned"

## Langkah 3: Ambil Kredensial

1. Buka **Project Settings** → **API**
2. Catat:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbG...` (panjang)

## Langkah 4: Konfigurasi Flutter

Buka file `lib/core/config/supabase_config.dart` dan isi:

```dart
class SupabaseConfig {
  // Ganti dengan URL dan Key dari Supabase dashboard
  static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIs...YOUR_ANON_KEY';
  
  static bool get isConfigured =>
      supabaseUrl != 'YOUR_SUPABASE_URL' &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';
}
```

## Langkah 5: Test Koneksi

Restart aplikasi Flutter:
```bash
# Tekan 'r' untuk hot reload, atau 'R' untuk hot restart
# Atau jalankan ulang:
flutter run -d windows
```

Jika sukses, warning banner "Supabase belum dikonfigurasi" akan hilang.

## Struktur Tabel

| Tabel | Deskripsi |
|-------|-----------|
| `products` | Daftar produk kue |
| `customers` | Data pelanggan |
| `suppliers` | Data pemasok |
| `raw_materials` | Bahan baku |
| `orders` | Pesanan (PO & Direct) |
| `order_items` | Detail item pesanan |
| `material_purchases` | Pembelian bahan |
| `purchase_items` | Detail item pembelian |

## Troubleshooting

**Error "Invalid API key"**
- Pastikan `supabaseAnonKey` benar (bukan service_role key)

**Error "relation does not exist"**
- Jalankan ulang schema.sql di SQL Editor

**Data tidak muncul**
- Cek apakah sample data sudah ter-insert di Table Editor
