# Template Kuesioner & Pengujian Non-Teknis — Sistem Fit Meal

## 1. Kuesioner SUS (System Usability Scale)

### Petunjuk Pengisian
Berikan penilaian Anda terhadap aplikasi **Fit Meal** dengan memilih angka **1 sampai 5** untuk setiap pernyataan berikut:

| Skala | Keterangan |
|-------|-----------|
| 1 | Sangat Tidak Setuju |
| 2 | Tidak Setuju |
| 3 | Netral |
| 4 | Setuju |
| 5 | Sangat Setuju |

### Daftar Pernyataan SUS

| No | Pernyataan | 1 | 2 | 3 | 4 | 5 |
|----|-----------|---|---|---|---|---|
| 1 | Saya pikir saya akan sering menggunakan aplikasi ini | ☐ | ☐ | ☐ | ☐ | ☐ |
| 2 | Saya merasa aplikasi ini terlalu rumit untuk digunakan | ☐ | ☐ | ☐ | ☐ | ☐ |
| 3 | Saya merasa aplikasi ini mudah digunakan | ☐ | ☐ | ☐ | ☐ | ☐ |
| 4 | Saya pikir saya memerlukan bantuan orang teknis untuk menggunakan aplikasi ini | ☐ | ☐ | ☐ | ☐ | ☐ |
| 5 | Saya merasa fitur-fitur dalam aplikasi ini terintegrasi dengan baik | ☐ | ☐ | ☐ | ☐ | ☐ |
| 6 | Saya merasa terlalu banyak ketidakkonsistenan dalam aplikasi ini | ☐ | ☐ | ☐ | ☐ | ☐ |
| 7 | Saya rasa kebanyakan orang akan cepat belajar menggunakan aplikasi ini | ☐ | ☐ | ☐ | ☐ | ☐ |
| 8 | Saya merasa aplikasi ini sangat sulit untuk digunakan | ☐ | ☐ | ☐ | ☐ | ☐ |
| 9 | Saya merasa sangat percaya diri saat menggunakan aplikasi ini | ☐ | ☐ | ☐ | ☐ | ☐ |
| 10 | Saya perlu belajar banyak hal sebelum bisa menggunakan aplikasi ini | ☐ | ☐ | ☐ | ☐ | ☐ |

### Cara Menghitung Skor SUS

```
Langkah 1: Untuk pernyataan GANJIL (1, 3, 5, 7, 9):
           Skor = (Nilai jawaban - 1)

Langkah 2: Untuk pernyataan GENAP (2, 4, 6, 8, 10):
           Skor = (5 - Nilai jawaban)

Langkah 3: Jumlahkan semua skor (total dari 10 pernyataan)

Langkah 4: Kalikan total dengan 2.5

Hasil SUS Score = Total × 2.5 (skala 0-100)
```

### Interpretasi Skor SUS

| Skor SUS | Grade | Keterangan |
|----------|-------|-----------|
| 90 - 100 | A+ | Best Imaginable |
| 80 - 89 | A | Excellent |
| 70 - 79 | B | Good |
| 60 - 69 | C | OK / Acceptable |
| 50 - 59 | D | Marginal |
| < 50 | F | Not Acceptable |

> **Standar**: Rata-rata SUS score global adalah **68**. Skor di atas 68 berarti di atas rata-rata.

---

## 2. User Acceptance Testing (UAT)

### Data Responden

| Field | Isi |
|-------|-----|
| Nama | _________________ |
| Usia | _________________ |
| Pekerjaan | _________________ |
| Pengalaman Aplikasi Diet | ☐ Belum pernah ☐ Pernah 1-2 ☐ Sering |
| Tanggal Pengujian | _________________ |

### Skenario Pengujian UAT

| No | Skenario Pengujian | Langkah-langkah | Hasil yang Diharapkan | Hasil Aktual | Status |
|----|-------------------|-----------------|----------------------|-------------|--------|
| UAT-01 | Registrasi / Login | 1. Buka aplikasi<br>2. Isi data diri (berat, tinggi, umur)<br>3. Pilih gender<br>4. Submit | Data tersimpan, masuk ke halaman utama | _________________ | ☐ Pass ☐ Fail |
| UAT-02 | Input Profil Lengkap | 1. Masukkan berat badan<br>2. Masukkan tinggi badan<br>3. Masukkan umur<br>4. Pilih tingkat aktivitas<br>5. Pilih goal (cutting/maintain/bulking) | Semua input diterima tanpa error | _________________ | ☐ Pass ☐ Fail |
| UAT-03 | Generate Rekomendasi Menu | 1. Lengkapi profil<br>2. Tekan tombol "Dapatkan Rekomendasi"<br>3. Tunggu loading | Muncul menu Pagi, Siang, Malam dengan detail nutrisi | _________________ | ☐ Pass ☐ Fail |
| UAT-04 | Melihat Detail Nutrisi Menu | 1. Generate menu<br>2. Lihat detail per makanan<br>3. Cek kalori, protein, karbo, lemak | Setiap makanan menampilkan info nutrisi lengkap | _________________ | ☐ Pass ☐ Fail |
| UAT-05 | Pencarian Makanan | 1. Masuk ke fitur pencarian<br>2. Ketik "nasi"<br>3. Lihat hasil | Muncul daftar makanan yang mengandung "nasi" | _________________ | ☐ Pass ☐ Fail |
| UAT-06 | Pencarian dengan Kata Kunci Spesifik | 1. Ketik "ayam bakar"<br>2. Lihat urutan hasil | Hasil paling relevan muncul di atas | _________________ | ☐ Pass ☐ Fail |
| UAT-07 | Menu Tidak Mengandung Junk Food | 1. Generate rekomendasi<br>2. Periksa semua item menu<br>3. Pastikan tidak ada mie instan, gorengan | Tidak ada junk food (Indomie, Chitato, dll) di menu | _________________ | ☐ Pass ☐ Fail |
| UAT-08 | Kalori Sesuai Target | 1. Generate menu<br>2. Bandingkan total kalori menu dengan target | Total kalori ≤ target ± 5% | _________________ | ☐ Pass ☐ Fail |
| UAT-09 | Generate Ulang Menu | 1. Tekan tombol generate ulang<br>2. Bandingkan dengan menu sebelumnya | Muncul menu baru yang berbeda dari sebelumnya | _________________ | ☐ Pass ☐ Fail |
| UAT-10 | Preferensi Makanan | 1. Tambahkan makanan favorit<br>2. Generate rekomendasi<br>3. Periksa apakah makanan favorit muncul | Makanan favorit diprioritaskan muncul di menu | _________________ | ☐ Pass ☐ Fail |
| UAT-11 | Blacklist Makanan | 1. Tambahkan makanan yang tidak disukai<br>2. Generate rekomendasi<br>3. Periksa menu | Makanan yang di-blacklist tidak muncul | _________________ | ☐ Pass ☐ Fail |
| UAT-12 | Responsivitas Aplikasi | 1. Gunakan aplikasi selama 5 menit<br>2. Navigasi antar halaman<br>3. Perhatikan kecepatan | Aplikasi responsif, tidak ada lag signifikan | _________________ | ☐ Pass ☐ Fail |
| UAT-13 | Tampilan UI Menarik | 1. Perhatikan desain keseluruhan<br>2. Cek konsistensi warna & font<br>3. Nilai estetika | Tampilan menarik dan konsisten | _________________ | ☐ Pass ☐ Fail |
| UAT-14 | Informasi Mudah Dipahami | 1. Baca informasi nutrisi<br>2. Baca rekomendasi menu<br>3. Pahami instruksi | Informasi jelas dan mudah dipahami | _________________ | ☐ Pass ☐ Fail |
| UAT-15 | Error Handling | 1. Coba input data tidak valid<br>2. Coba koneksi lambat | Aplikasi menampilkan pesan error yang jelas | _________________ | ☐ Pass ☐ Fail |

### Pertanyaan Tambahan UAT

| No | Pertanyaan | Jawaban |
|----|-----------|---------|
| 1 | Apakah aplikasi ini membantu Anda merencanakan menu diet? | ☐ Ya ☐ Tidak |
| 2 | Apakah rekomendasi menu yang diberikan masuk akal/realistis? | ☐ Ya ☐ Tidak |
| 3 | Apakah Anda akan menggunakan aplikasi ini untuk diet sehari-hari? | ☐ Ya ☐ Mungkin ☐ Tidak |
| 4 | Fitur apa yang paling Anda sukai? | _________________ |
| 5 | Fitur apa yang perlu ditingkatkan? | _________________ |
| 6 | Saran / Masukan tambahan: | _________________ |

### Rumus Perhitungan UAT

```
Acceptance Rate = (Jumlah Skenario PASS / Total Skenario) × 100%

Kriteria:
  ≥ 90% : Sangat Layak (Diterima)
  80-89% : Layak
  70-79% : Cukup Layak
  < 70%  : Tidak Layak (Perlu Revisi)
```

---

## 3. Compatibility Testing (Checklist)

### Pengujian Perangkat

| No | Perangkat / Emulator | Ukuran Layar | OS Version | Status | Catatan |
|----|---------------------|-------------|------------|--------|---------|
| CT-01 | Samsung Galaxy A14 | 6.6" (720×1600) | Android 13 | ☐ Pass ☐ Fail | _________________ |
| CT-02 | Xiaomi Redmi Note 12 | 6.67" (1080×2400) | Android 13 | ☐ Pass ☐ Fail | _________________ |
| CT-03 | Oppo A78 | 6.56" (720×1612) | Android 13 | ☐ Pass ☐ Fail | _________________ |
| CT-04 | Samsung Galaxy S23 | 6.1" (1080×2340) | Android 14 | ☐ Pass ☐ Fail | _________________ |
| CT-05 | Google Pixel 7 | 6.3" (1080×2400) | Android 14 | ☐ Pass ☐ Fail | _________________ |
| CT-06 | Emulator — Small (480×800) | 3.7" | Any | ☐ Pass ☐ Fail | _________________ |
| CT-07 | Emulator — Medium (1080×1920) | 5.5" | Any | ☐ Pass ☐ Fail | _________________ |
| CT-08 | Emulator — Large (1440×2560) | 6.5" | Any | ☐ Pass ☐ Fail | _________________ |
| CT-09 | Emulator — Tablet (1200×1920) | 10.1" | Any | ☐ Pass ☐ Fail | _________________ |

### Aspek yang Dicek per Perangkat

| No | Aspek Pengujian | Kriteria Lolos |
|----|----------------|---------------|
| 1 | Layout tidak overlap | Semua elemen terlihat jelas |
| 2 | Teks terbaca | Font tidak terlalu kecil/besar |
| 3 | Tombol bisa ditekan | Tap target ≥ 44×44 dp |
| 4 | Scroll berfungsi | List bisa di-scroll tanpa lag |
| 5 | Orientasi Portrait | Layout benar saat portrait |
| 6 | Loading indicator | Ada indikator saat loading |
| 7 | Keyboard tidak menutupi input | Input tetap terlihat saat keyboard muncul |

### Rumus Compatibility

```
Compatibility Rate = (Jumlah Perangkat PASS / Total Perangkat) × 100%
```

---

## Referensi

- Brooke, J. (1996). "SUS: A 'Quick and Dirty' Usability Scale." *Usability Evaluation in Industry*.
- ISO 25010:2011 — Systems and software quality models.
- Nielsen, J. (1993). *Usability Engineering*. Academic Press.
