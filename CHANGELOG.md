# LF Kitchen - Changelog

Semua perubahan dan peningkatan fitur aplikasi akan didokumentasikan di sini.

---

## [v2.2.1] - 2026-02-22
### 🐛 Bug Fix
- **AI Quota Fix**: Pindah model ke `gemini-1.5-flash` untuk kuota free tier yang lebih stabil (menghindari error "limit 0" di 2.0-flash).
- **Better Error Messages**: Pesan error yang lebih jelas saat kuota Gemini habis (Rate Limit).

### 🛠️ Cleanup & Hardening
- **Security**: Mengaktifkan Row Level Security (RLS) di semua tabel Supabase.
- **Dead Code Removal**: Menghapus layer API yang tidak digunakan (`ApiService`, `ApiConfig`, dll).
- **Dependency Cleanup**: Menghapus package `http` yang sudah tidak diperlukan.

---

## [v2.2.0] - 2026-02-21
### ✨ Fitur Baru
- **Scan Struk Belanja**: Foto struk supermarket → AI (Gemini) otomatis extract item → review & edit → simpan sebagai pembelian bahan baku.
- **Auto-Match Bahan Baku**: Item dari struk otomatis dihubungkan ke bahan baku yang sudah terdaftar.
- **Tombol Scan Struk**: Tombol "Scan Struk" baru di halaman Pembelian Bahan.

---

## [v2.1.0] - 2026-02-19
### 🐛 Bug Fix
- **[CRITICAL] Recipe Persistence**: Tabel `product_recipes` belum dibuat di Supabase — semua operasi simpan resep gagal diam-diam. Tabel sekarang sudah dibuat dengan RLS permissive.

### 🎨 UI Improvement
- **Tombol Tambah Lebih Jelas**: Tombol "Tambah Produk", "Tambah Bahan", dan "Catat Pembelian" di AppBar diganti dari `IconButton` kecil menjadi `FilledButton.icon` berlabel teks agar lebih mudah ditemukan.

---

## [v2.0.0] - 2026-02-17
### ✨ Fitur Baru
- **Supplier Management**: Kelola data supplier (Tambah, Edit, Hapus, Cari, Hubungi).
- **Purchase Integration**: Pintasan "Tambah Supplier" langsung dari form pembelian.
- **Supplier Navigation**: Menu akses cepat Supplier di sidebar/drawer.
- **Kalkulasi HPP (COGS)**: Sistem otomatis menghitung harga modal produk berdasarkan resep.
- **Recipe Yield (Hasil Jadi)**: Dukungan perhitungan HPP per unit berdasarkan hasil produksi batch.
- **Konversi Unit Bahan**: Konversi otomatis dari unit pembelian (misal: kg) ke unit resep (misal: gram/butir).
- **Global HPP Sync**: Fitur untuk sinkronisasi harga modal semua produk secara massal berdasarkan harga pembelian terbaru.

### 🔧 Perbaikan
- **Raw Material UI**: Penambahan spesifikasi fisik (unit resep & konversi) di form bahan baku.
- **Unit Management**: Perluasan daftar satuan standar (kg, gr, ml, ikat, sdm, dll) dan fleksibilitas konversi antar satuan.
- **Recipe UI Hint**: Penambahan petunjuk konversi otomatis (misal: 1 kg = 1000 gr) saat menambah bahan ke resep.
- **Product Recipe UI**: Peningkatan form resep dengan input yield dan estimasi HPP real-time.
- **Recipe Repository**: Refaktor logika perhitungan HPP agar lebih akurat dan robust.
- **[2026-02-18] [FIX] Recipe Save**: Perbaikan bug resep tidak tersimpan saat menyimpan dari tab Resep. Penyebab: Form validation hanya membungkus Tab 1.
- **[2026-02-18] [FIX] Layout Crash**: Perbaikan crash "RenderBox was not laid out" pada halaman Bahan Baku di mobile, disebabkan oleh `Spacer()` dalam grid.
- **[2026-02-18] [UI] Tombol Aksi ke AppBar**: Tombol "Tambah Produk", "Tambah Bahan", "Tambah Pelanggan", dan "Catat Pembelian" dipindahkan dari FAB ke AppBar untuk akses lebih cepat.

---

## [v1.0.0+1] - 2026-02-16
### ✨ Fitur Baru
- **Filter & Sort Invoice**: Filter tanggal dan sorting berdasarkan nama, nominal, dan jatuh tempo.
- **Order Date Customization**: Tanggal pesanan dapat diatur manual dan pembatasan tanggal pengambilan dihapus.

### 🔧 Perbaikan
- **Deployment**: Konfigurasi Firebase Hosting selesai dan aplikasi deploy live.
- **Form UI**: Perbaikan penempatan field tanggal di form Pesanan, Snack Box, dan Paketan.

---

## [Unreleased]
### Added
- [2026-02-25] [FEATURE] Fitur akumulasi tagihan belum dibayar per pelanggan dengan perincian produk di halaman Tagihan.
- [2026-02-26] [FEATURE] Dynamic Pricing: Harga item pada form pesanan dan snack box akan otomatis menyesuaikan dengan `specialPrice` jika "NAMA PEMESAN" memiliki status pelanggan prioritas (harga khusus).
- Laporan Keuangan Detail
- Integrasi Printer Thermal Bluetooth

### Fixed
- [2026-02-26] [FIX] Layout cetak kwitansi PDF: perataan angka (Rp dan nominal) sekarang sejajar sempurna.
- [2026-02-26] [FIX] Sanitasi karakter Unicode (hyphen/dash) pada nama produk di PDF cetak.
- [2026-02-26] [FIX] Mengganti gambar tanda tangan manual dengan QR Code pada kwitansi PDF.
- [2026-02-26] [FIX] Field "Catatan Tambahan" yang hilang di tampilan mobile (halaman Pesanan & Snack Box) telah dimunculkan kembali.
- [2026-02-26] [UI/UX] Memindahkan dropdown "NAMA PEMESAN" ke bagian paling atas form pada tampilan mobile agar alur (Who -> What -> Kapan) menjadi lebih intuitif dan memicu perubahan harga dinamis secara langsung.


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
