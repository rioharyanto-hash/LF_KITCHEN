# LF Kitchen - Changelog

Semua perubahan dan peningkatan fitur aplikasi akan didokumentasikan di sini.

---

## [Unreleased]

### ✨ Fitur Baru
- **Snack Box Redesign** - Sistem pemesanan snack box untuk order besar
  - Pilih 2-4 macam kue per box
  - Tambah air mineral (dari produk kategori "Minuman")
  - Harga kemasan/box bisa diubah
  - Minimum order 30 box (warning only)
  - Total = (Harga isi + kemasan) × jumlah box
  - Nama pemesan wajib diisi
  
- **Cetak Kwitansi** - Print receipt untuk pesanan
  - Logo LF Kitchen
  - Nomor surat format: urut/bulan romawi/tahun
  - Tanggal bisa dirubah
  - Total dengan pemisah ribuan
  - Terbilang otomatis
  - Info bank dan tanda tangan
  - Tombol aksi status (Konfirmasi, Proses, Siap Ambil, Selesai)
  
- **Fitur Pembayaran**
  - Dialog pembayaran dengan pilihan metode (Tunai, Transfer, QRIS)
  - Validasi pesanan belum lunas saat mau diselesaikan
  - Auto-complete pesanan setelah lunas
  - Status pembayaran: Belum Bayar, DP, Lunas

- **Modul Kasir (POS)**
  - Grid produk dengan tampilan card
  - Keranjang belanja dengan quantity control (+/-)
  - Proses pembayaran langsung
  - Order otomatis completed setelah bayar

- **Modul Pembelian Bahan**
  - Manajemen Supplier (CRUD)
  - Manajemen Bahan Baku dengan alert stok rendah
  - Pencatatan pembelian dengan multi-item
  - Auto-update stok saat pembelian

- **Modul Produk**
  - Daftar produk dengan grid view
  - Form produk dengan gambar URL
  - Kategori produk

- **Modul Pelanggan**
  - Daftar pelanggan
  - Form pelanggan

- **Dashboard**
  - Summary cards (Total Penjualan, Pesanan Hari Ini, dll)
  - Daftar pesanan terbaru

- **Modul Produksi**
  - Dashboard produksi harian
  - Agregasi pesanan per tanggal

### 🔧 Perbaikan
- Fix overflow di product card grid
- Fix AsyncState.when usage untuk state management
- Fix payment status validation sebelum order completion

---

## [Unreleased]

### 🚧 Dalam Pengembangan
- Fitur Snack Box dengan isi box yang bisa dipilih
- Laporan penjualan dan keuangan
- Export data ke Excel/PDF
