# Prompt Perbaikan Antarmuka (UI/UX) Dashboard & Interaksi FitMeal

Gunakan prompt di bawah ini untuk menginstruksikan AI, desainer UI, atau pengembang (developer) dalam memperbaiki interaksi mikro, manajemen state, dan penanganan kesalahan (error handling) pada core dashboard, halaman pencarian, dan pengaturan aplikasi FitMeal berdasarkan temuan dari rekaman pengujian sistem.

---

## 📋 CONTEXT & OBJECTIVE
Saya sedang mematangkan pengembangan aplikasi kesehatan dan nutrisi bernama **FitMeal**. Saat ini, core feature (Dashboard Kalori & Hidrasi, Rekomendasi Menu berbasis Constraint-Based Filtering, Pencarian Makanan, dan Pengaturan Profil) sudah berfungsi. 

Namun, hasil pengujian rekaman layar menunjukkan adanya beberapa *blind spot* interaksi, masalah aksesibilitas, *state* tombol yang kurang valid, serta sebuah *bug* kritis berupa pembekuan (*freeze*) respons tombol saat menambahkan makanan dari halaman pencarian.

Tolong bantu saya menyusun solusi perbaikan desain, logika interaksi mikro, serta arsitektur state untuk mengatasi masalah spesifik di bawah ini.

---

## 🛠️ DETAIL PERBAIKAN INTERAKSI & STATE

### 1. Penanganan Error & Loading State pada Tombol "+ Tambah" (Isu Kritis)
* **Masalah:** Pada halaman pencarian makanan (saat mencari "Dada Ayam"), ketika tombol "+ Tambah" diketuk berkali-kali, antarmuka tidak memberikan respons visual, tidak memunculkan *bottom sheet* pemilihan waktu makan, dan data tidak masuk ke beranda. Hal ini mengindikasikan adanya kegagalan *fetching* data latar belakang atau *unhandled API error*.
* **Tugas & Solusi UX:** * Implementasikan **Loading State**: Saat tombol "+ Tambah" diketuk, ubah tombol menjadi *circular progress indicator* kecil (spinner) untuk menunjukkan proses sedang berjalan.
    * Implementasikan **Error Handling**: Jika API gagal atau *timeout*, kembalikan tombol ke *state* semula dan tampilkan umpan balik berupa *Snackbar* atau *Toast* di bagian bawah layar bertuliskan: *"Gagal menambahkan makanan. Silakan coba lagi."*

### 2. Optimasi Interaksi Mikro Fitur Hidrasi Harian
* **Masalah:** Penambahan air minum dengan mengetuk ikon tetesan air sudah berfungsi dengan baik, namun interaksinya terasa sangat statis dan kurang memiliki proteksi terhadap kesalahan ketuk (*accidental tap*).
* **Tugas & Solusi UX:**
    * **Efek Keberhasilan:** Tambahkan animasi mikro (efek *pop* ringan atau *ripple effect*) saat ikon gelas air berubah menjadi biru solid untuk memberikan kepuasan psikologis (*rewarding feeling*) kepada pengguna.
    * **Mekanisme Undo/Pembatalan:** Sediakan cara bagi pengguna jika tidak sengaja mengetuk ikon gelas (misalnya, mengetuk kembali ikon gelas terakhir yang aktif akan mengurangi jumlah hidrasi atau membatalkan status terisi).

### 3. Validasi Kondisi (*State*) Tombol Pengaturan
* **Masalah:** Di halaman "Pengaturan" (saat mode edit profil terbuka), tombol *"Simpan Perubahan"* langsung berwarna hijau solid (aktif) sejak awal, meskipun pengguna belum mengubah data teks atau opsi apa pun. Ini berpotensi memicu *request/write update* yang tidak diperlukan ke *database*.
* **Tugas & Solusi UX:**
    * Ubah kondisi tombol menjadi **Disabled State** (berwarna abu-abu pucat dan tidak bisa diklik) secara *default* saat halaman edit dibuka.
    * Aktifkan tombol (*Enabled State* - berubah menjadi hijau solid) **hanya jika** sistem mendeteksi adanya perubahan karakter pada *input text* (Nama, Berat, Tinggi, Usia) atau perubahan seleksi pada *card target/aktivitas* dibandingkan dengan data awal.

### 4. Aksesibilitas Kontras Warna & Navigasi Bawah (Bottom Navigation)
* **Masalah Kontras:** Komponen *pill tags* (seperti label "Protein Tinggi", "Rendah Lemak & Ringan") menggunakan kombinasi warna teks dan *background* yang terlalu pudar, sehingga berisiko tidak lulus uji aksesibilitas kontras (WCAG AAA).
* **Masalah Navigasi:** Indikator *tab* yang aktif pada *Bottom Navigation Bar* saat ini hanya mengandalkan perubahan warna teks/ikon menjadi hijau. Bagi pengguna dengan keterbatasan penglihatan warna (buta warna), hal ini sulit diidentifikasi.
* **Tugas & Solusi UX:**
    * Gelapkan warna teks pada *pill tags* nutrisi untuk meningkatkan keterbacaan di bawah terik matahari.
    * Standarkan *state* aktif pada *Bottom Navigation Bar* menggunakan teknik **Dual-Coding**: Gunakan varian ikon tipe *solid* (terisi penuh) untuk *tab* yang sedang aktif (misal: Beranda, Stats, Rekomendasi, Cari) dan varian ikon tipe *outline* (hanya garis luar) untuk *tab* yang sedang tidak aktif.

---

## 📤 OUTPUT YANG DIHARAPKAN
Berikan panduan perbaikan yang mencakup:
1.  **Arsitektur Alur Logika (State Management Workflow):** Bagaimana variabel state harus dikelola ketika pengguna melakukan pencarian dan penambahan menu agar tidak terjadi *freeze*.
2.  **Rekomendasi Kode Komponen:** Contoh implementasi logika kondisional (misal: menggunakan Flutter `setState` atau React Native hooks) untuk mengontrol status tombol *disabled/enabled* pada form pengaturan.
3.  **Prinsip Desain Defensif (Defensive Design):** Cara mengamankan komponen UI dari ketukan ganda (*double-tap prevention*) pada fitur hidrasi dan tombol tambah.
