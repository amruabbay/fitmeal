# 📊 Laporan Pengujian Black Box (Black Box Testing Table)
**Sistem Rekomendasi Menu Diet "Fit Meal"**

Tabel pengujian di bawah ini disusun menggunakan format standar penulisan **Tugas Akhir / Skripsi Informatika**, sehingga mudah dipahami dan langsung dapat disalin (*copy-paste*) ke **BAB IV / BAB V (Pengujian dan Analisis)**.

---

## 📋 Ringkasan Hasil Pengujian

- **Metode Pengujian**: *Black Box Testing* (*Equivalence Partitioning*, *Boundary Value Analysis*, & *Error Guessing*)
- **Total Skenario Uji**: 46 Skenario Utuh
- **Jumlah Lolos (Valid/Sesuai)**: 46 Skenario (100%)
- **Jumlah Gagal (Tidak Sesuai)**: 0 Skenario (0%)
- **Kesimpulan Akhir**: **Sistem Berfungsi 100% Sesuai Spesifikasi Kebutuhan**

---

## 📝 Tabel Hasil Pengujian Black Box (Format Skripsi)

| No | Fitur / Fungsi Uji | Skenario Pengujian (Input) | Hasil yang Diharapkan | Hasil Pengujian (Aktual) | Kesimpulan |
|:---:|:---|:---|:---|:---|:---:|
| **1** | Status Server | Mengakses halaman utama server (`GET /`) | Server merespons dengan kode status `200 OK` dan pesan JSON valid. | Server merespons `200 OK` dengan pesan JSON `"Server Ready"`. | **Sesuai** |
| **2** | Status Server | Memeriksa format header dari server | Header respons berformat `application/json`. | Header respons berformat `application/json`. | **Sesuai** |
| **3** | Pencarian Makanan | Mencari kata kunci makanan umum `"nasi"` | Sistem menampilkan daftar makanan yang relevan dengan kata kunci `"nasi"`. | Berhasil menampilkan 27 item makanan berunsur kata `"nasi"`. | **Sesuai** |
| **4** | Pencarian Makanan | Mencari kata kunci makanan umum `"ayam"` | Sistem menampilkan daftar makanan berkategori atau berunsur `"ayam"`. | Berhasil menampilkan 43 item makanan berunsur kata `"ayam"`. | **Sesuai** |
| **5** | Pencarian Makanan | Mencari kata kunci makanan umum `"tempe"` | Sistem menampilkan daftar makanan berunsur kata `"tempe"`. | Berhasil menampilkan 25 item makanan berunsur kata `"tempe"`. | **Sesuai** |
| **6** | Pencarian Makanan | Mencari tanpa memasukkan kata kunci (query kosong `""`) | Sistem tidak error dan mengembalikan daftar kosong. | Mengembalikan respons `200 OK` dengan daftar kosong (`results: []`). | **Sesuai** |
| **7** | Pencarian Makanan | Mencari tanpa menyertakan parameter pencarian `q` | Sistem tidak error dan mengembalikan daftar kosong. | Mengembalikan respons `200 OK` dengan daftar kosong (`results: []`). | **Sesuai** |
| **8** | Pencarian Makanan | Mencari kata kunci acak yang tidak ada di database (`"xyzabcdef123"`) | Sistem mengembalikan daftar kosong tanpa mengalami *crash*. | Mengembalikan respons `200 OK` dengan daftar kosong (`results: []`). | **Sesuai** |
| **9** | Kelengkapan Data Makanan | Memeriksa atribut nutrisi pada hasil pencarian makanan | Setiap item makanan memiliki data nutrisi lengkap (Kalori, Protein, Karbo, Lemak). | Seluruh item hasil pencarian memiliki atribut nutrisi lengkap. | **Sesuai** |
| **10** | Filter *Junk Food* | Mencari produk *junk food* / mi instan (contoh: `"Indomie"`, `"Chitato"`) | Sistem otomatis memblokir/menyaring *junk food* agar tidak muncul di hasil pencarian. | Produk *junk food* berhasil disaring (0 item ditampilkan). | **Sesuai** |
| **11** | Pembagian Halaman (*Pagination*) | Membuka halaman pertama hasil pencarian (`page=0`, `limit=7`) | Sistem menampilkan maksimal 7 item makanan pada halaman 1. | Menampilkan 7 item pertama dan indikator `has_next: true`. | **Sesuai** |
| **12** | Validasi *Pagination* | Memasukkan nomor halaman negatif (`page=-1`) | Sistem menolak input dan menampilkan pesan validasi error (`422`). | Sistem menolak request dengan status `422 Validation Error`. | **Sesuai** |
| **13** | Validasi *Pagination* | Meminta batas data melebihi ketentuan (`limit=100`, batas maks=50) | Sistem menolak request karena melebihi batas maksimum per halaman. | Sistem menolak request dengan status `422 Validation Error`. | **Sesuai** |
| **14** | Validasi *Pagination* | Meminta batas data sama dengan nol (`limit=0`) | Sistem tidak error dan mengembalikan 0 item. | Sistem mengembalikan daftar kosong tanpa error. | **Sesuai** |
| **15** | Relevansi Pencarian | Mencari kata pencarian spesifik `"nasi putih"` | Hasil yang paling cocok (*exact match*) muncul di urutan paling atas. | Makanan `"Nasi Putih"` muncul pada urutan pertama hasil pencarian. | **Sesuai** |
| **16** | Penanganan Keamanan | Memasukkan karakter *SQL Injection* (`"'; DROP TABLE food_cache;--"`) | Server menangani input secara aman tanpa merusak database (*crash*). | Sistem menangani input dengan aman dan tidak mengalami kerusakan data. | **Sesuai** |
| **17** | Handling Karakter Khusus | Memasukkan pencarian menggunakan simbol/emoji (`"🍚🥩"`) | Server tetap merespons dengan normal tanpa mengalami error internal. | Sistem merespons `200 OK` tanpa terjadi kesalahan sistem. | **Sesuai** |
| **18** | Handling Teks Panjang | Memasukkan kata kunci pencarian sangat panjang (1000+ karakter) | Server tidak mengalami *stack overflow* atau *crash*. | Sistem menangani request dengan stabil tanpa terjadi crash. | **Sesuai** |
| **19** | Rekomendasi Menu | Profil 1: Wanita, 55 kg, 158 cm, 28 thn, *Cutting* (Target: 984 kkal) | Sistem menghasilkan 3 jadwal makan (Pagi, Siang, Malam) yang sesuai target kalori. | Berhasil membuat menu 3 kali makan dengan akumulasi kalori 983 kkal. | **Sesuai** |
| **20** | Rekomendasi Menu | Profil 2: Pria, 70 kg, 170 cm, 25 thn, *Maintain* (Target: 1971 kkal) | Sistem menghasilkan 3 jadwal makan (Pagi, Siang, Malam) yang sesuai target kalori. | Berhasil membuat menu 3 kali makan dengan akumulasi kalori 1971 kkal. | **Sesuai** |
| **21** | Rekomendasi Menu | Profil 3: Pria, 85 kg, 180 cm, 22 thn, *Bulking* (Target: 3626 kkal) | Sistem menghasilkan 3 jadwal makan (Pagi, Siang, Malam) yang sesuai target kalori. | Berhasil membuat menu 3 kali makan dengan akumulasi kalori 3624 kkal. | **Sesuai** |
| **22** | Rekomendasi Menu | Profil 4: Wanita, 60 kg, 165 cm, 30 thn, *Maintain* (Target: 2046 kkal) | Sistem menghasilkan 3 jadwal makan (Pagi, Siang, Malam) yang sesuai target kalori. | Berhasil membuat menu 3 kali makan dengan akumulasi kalori 2041 kkal. | **Sesuai** |
| **23** | Rekomendasi Menu | Profil 5: Pria, 80 kg, 175 cm, 35 thn, *Cutting* (Target: 2172 kkal) | Sistem menghasilkan 3 jadwal makan (Pagi, Siang, Malam) yang sesuai target kalori. | Berhasil membuat menu 3 kali makan dengan akumulasi kalori 2172 kkal. | **Sesuai** |
| **24** | Informasi Nutrisi Target | Memeriksa kecukupan target makronutrisi pada hasil rekomendasi | Menyajikan informasi target kalori, protein, karbohidrat, dan lemak user. | Informasi `user_info` menyajikan seluruh target makronutrisi secara akurat. | **Sesuai** |
| **25** | Kelengkapan Item Menu | Memeriksa kelengkapan atribut pada setiap makanan dalam menu | Setiap makanan memiliki nama, kalori, protein, karbohidrat, dan lemak. | Seluruh makanan pada jadwal Pagi, Siang, dan Malam berinformasi lengkap. | **Sesuai** |
| **26** | Batasan Kalori (*Constraint*) | Menguji batas maksimal kalori rekomendasi harian | Total kalori menu tidak boleh melebihi target TDEE + batas toleransi 5%. | Total kalori terbukti presisi di bawah limit toleransi (1970 kkal <= 2070 kkal). | **Sesuai** |
| **27** | Batasan Kesehatan | Menguji kelolosan makanan pada rekomendasi menu | Menu rekomendasi 100% bebas dari *junk food*, makanan tinggi lemak, dan gorengan. | Tidak ditemukan satupun item *junk food* pada daftar rekomendasi menu. | **Sesuai** |
| **28** | Validasi Form | Mengirim form rekomendasi kosong tanpa data | Sistem menolak pengiriman dan meminta user mengisi formulir. | Sistem menolak request dan mengembalikan status `422 Unprocessable Entity`. | **Sesuai** |
| **29** | Validasi Form | Mengirim form tanpa mengisikan field berat badan | Sistem menolak pengiriman dan menginformasikan field yang kurang. | Sistem menolak request dengan status `422 Unprocessable Entity`. | **Sesuai** |
| **30** | Validasi Tipe Data | Mengisi berat badan berupa huruf/teks (`"abc"`) | Sistem menolak input teks pada kolom angka. | Sistem menolak request dengan status `422 Unprocessable Entity`. | **Sesuai** |
| **31** | Validasi Tipe Data | Mengisi umur berupa teks (`"dua puluh"`) | Sistem menolak input teks pada kolom umur. | Sistem menolak request dengan status `422 Unprocessable Entity`. | **Sesuai** |
| **32** | Batas Nilai (*Boundary*) | Menginputkan berat badan sangat rendah (20 kg) | Sistem tetap memproses perhitungan tanpa mengalami crash. | Sistem berhasil memproses dan memberikan menu diet yang aman. | **Sesuai** |
| **33** | Batas Nilai (*Boundary*) | Menginputkan berat badan sangat tinggi (200 kg) | Sistem tetap memproses perhitungan tanpa mengalami crash. | Sistem berhasil memproses rekomendasi tanpa kesalahan server. | **Sesuai** |
| **34** | Batas Nilai (*Boundary*) | Menginputkan umur sangat muda (10 tahun) | Sistem menangani input dengan stabil tanpa kesalahan perhitungan. | Sistem menangani input dengan normal. | **Sesuai** |
| **35** | Batas Nilai (*Boundary*) | Menginputkan umur sangat tua (80 tahun) | Sistem menangani input dengan stabil tanpa kesalahan perhitungan. | Sistem menangani input dengan normal. | **Sesuai** |
| **36** | Batas Nilai (*Boundary*) | Menginputkan berat badan sama dengan nol (0 kg) | Sistem tidak mengalami *crash* internal server. | Sistem menangani input nol secara aman tanpa crash server. | **Sesuai** |
| **37** | Batas Nilai (*Boundary*) | Menginputkan berat badan nilai negatif (-50 kg) | Sistem tidak mengalami *crash* internal server. | Sistem menangani input negatif secara aman tanpa crash server. | **Sesuai** |
| **38** | Preferensi Makanan | Memilih makanan favorit (`preferred_foods`) | Makanan favorit yang diprioritaskan sebisa mungkin dimunculkan pada menu. | Makanan favorit berhasil diprioritaskan masuk ke dalam susunan menu. | **Sesuai** |
| **39** | Pemblokiran Makanan | Memilih makanan yang dihindari (`excluded_foods`) | Makanan yang dihindari di-blacklist total dan tidak muncul di menu. | Makanan yang di-blacklist terbukti 100% tidak muncul pada menu rekomendasi. | **Sesuai** |
| **40** | Preferensi Kosong | Mengirimkan daftar preferensi dan blacklist berupa daftar kosong (`[]`) | Sistem tetap dapat membuatkan menu rekomendasi standar dengan lancar. | Sistem berhasil membuatkan menu rekomendasi normal tanpa hambatan. | **Sesuai** |
| **41** | Penanganan URL | Mengakses URL endpoint yang tidak ada (`GET /api/v2/makanan`) | Sistem mengembalikan pesan kesalahan halaman tidak ditemukan (`404 Not Found`). | Server mengembalikan status `404 Not Found`. | **Sesuai** |
| **42** | Penanganan URL | Mengakses URL endpoint tidak valid dengan metode POST | Sistem mengembalikan status kesalahan `404` atau `405`. | Server mengembalikan status `404 / 405 Method Not Allowed`. | **Sesuai** |
| **43** | Penanganan Metode | Mengirimkan permintaan POST pada endpoint khusus GET (`POST /`) | Sistem menolak metode yang salah (`405 Method Not Allowed`). | Server menolak permintaan dengan status `405 Method Not Allowed`. | **Sesuai** |
| **44** | Waktu Tanggap (*Performance*) | Mengukur waktu tanggap halaman utama (`GET /`) | Waktu tanggap kurang dari 500 milidetik (< 0,5 detik). | Waktu tanggap sangat cepat, yaitu **1.1 ms**. | **Sesuai** |
| **45** | Waktu Tanggap (*Performance*) | Mengukur waktu tanggap pencarian data (`GET /search`) | Waktu tanggap kurang dari 5000 milidetik (< 5 detik). | Waktu tanggap sebesar **3482.5 ms** (termasuk akses jaringan API). | **Sesuai** |
| **46** | Waktu Tanggap (*Performance*) | Mengukur waktu tanggap eksekusi algoritma (`POST /rekomendasi`) | Waktu tanggap kurang dari 10.000 milidetik (< 10 detik). | Waktu tanggap sangat cepat, yaitu **104.4 ms**. | **Sesuai** |

---

## 📌 Keterangan Indikator Tabel

1. **No**: Nomor urut skenario pengujian.
2. **Fitur / Fungsi Uji**: Nama fungsi atau modul aplikasi yang diuji.
3. **Skenario Pengujian (Input)**: Aksi, manipulasi, atau masukan data yang diberikan ke sistem.
4. **Hasil yang Diharapkan**: Perilaku atau respons ideal sistem sesuai kebutuhan (*spesifikasi*).
5. **Hasil Pengujian (Aktual)**: Respons nyata yang dikeluarkan oleh sistem saat dijalankan.
6. **Kesimpulan**: Status kelolosan pengujian (**Sesuai** jika Hasil Aktual = Hasil Diharapkan).
