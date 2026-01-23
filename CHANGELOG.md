# LF Kitchen - Changelog

Semua perubahan dan peningkatan fitur aplikasi akan didokumentasikan di sini.

---

## [Unreleased]
- Laporan Keuangan Detail
- Integrasi Printer Thermal Bluetooth

---

## [v1.1.2] - 2026-01-20
### 🐛 Bug Fixes
- **Ongkos Kirim**: Shipping cost sekarang tersimpan ke database dan masuk ke `grandTotal`
- **Laporan Status**: Status pembayaran tampil "Lunas/DP/Belum Bayar" (bukan "partial")
- **Menu Pesanan**: Ditambahkan badge jumlah produk dan kontrol +/−

### ✨ Fitur Baru
- **Dark Mode Toggle**: Switch di sidebar (Desktop) dan menu Lainnya (Mobile)
- **Tombol Batal**: Tersedia di form Edit Order untuk cancel perubahan
- **Info Pembayaran**: Kolom metode bayar dan tanggal update di laporan penjualan

### 🔧 Perbaikan
- **Default Jenis Produk**: Sekarang ASIN, MANIS, LAINNYA
- **App Icon**: Logo LF Kitchen untuk Windows dan Web
- **Dark Mode Text**: Perbaikan warna teks di pilihan air mineral Snack Box

---

## [v1.1.1] - 2026-01-18
### ✨ Fitur Baru
- **Mobile Navigation**: Bottom bar baru (Dashboard, Pesanan, Snackbox, Paketan, Lainnya)
- **Menu Lainnya**: Ditambahkan menu Pelanggan
- **Tombol Batal**: Tersedia di semua status pesanan (Draft, Confirmed, Processing, Ready)
- **PDF Mobile/Web**: Download PDF kwitansi di browser/mobile

### 🔧 Perbaikan
- **Ukuran Produk**: Badge ukuran tampil di semua halaman (Pesanan, Snack Box, Paketan, Master Produk, Kasir)
- **Gambar Produk**: Paketan desktop sekarang menampilkan gambar
- **Nama Produk Mobile**: 2 baris untuk nama lengkap
- **Layout Harga**: Form produk mobile menggunakan layout 2×2 agar lebih lebar
- **Bottom Nav**: Paketan dihapus dari menu Lainnya (sudah di button bar)

---

## [v1.1.0] - 2026-01-17
### ✨ Fitur Baru
- **Modul Paketan**: Pemesanan paket bundling (Nasi Box, Tumpeng, dll) dengan perhitungan harga otomatis dan input catatan.
- **Kwitansi Cerdas**:
  - Auto-increment nomor surat (KW/PO/SB/PK) reset bulanan.
  - Format khusus untuk Snack Box dan Paketan (isi paket tampil detail).
  - Simpan PDF dengan penamaan file otomatis (`Kwitansi_Nama_Nomor.pdf`).
- **Web Support**: Kompatibilitas penuh untuk upload gambar di browser (Netlify) dan Windows.
- **App Icon**: Ikon aplikasi baru untuk Desktop Windows.

### 🔧 Perbaikan
- **Fix Product Form**: Dropdown ukuran kini muncul sesuai pengaturan.
- **Fix Image Upload**: Menggunakan memory bytes untuk dukungan lintas platform (Web/Desktop).
- **Fix Duplicate Dash**: Tampilan item snack box di kwitansi lebih rapi.


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
