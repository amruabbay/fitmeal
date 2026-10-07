# Laporan Hasil Pengujian Metrik Keberhasilan Penelitian
**Proyek Skripsi: Sistem Rekomendasi Menu Diet "Fit Meal"**
*Waktu Pengujian: 2026-08-03 09:22:46*

---

Laporan ini menyajikan hasil pengujian otomatis kuantitatif untuk dua metrik keberhasilan utama pada sistem rekomendasi diet **Fit Meal** (arsitektur *Client-Server* dengan Flutter frontend, SQLite lokal, dan FastAPI Python backend).

---

## 1. Metrik Keberhasilan 1: Akurasi Algoritma (Precision)

### A. Metodologi Pengujian
Pengujian dilakukan menggunakan skrip simulasi profil fiktif dengan variasi karakteristik antropometri, tingkat aktivitas, dan target *Total Daily Energy Expenditure* (TDEE). Algoritma dievaluasi terhadap dua batasan kritis (*constraints*):
1. **Constraint Eliminasi:** Tidak boleh ada satu pun menu rekomendasi (Pagi, Siang, Malam) yang mengandung makanan berkategori *junk food* atau gorengan.
2. **Constraint Nutrisi (Kalori):** Total akumulasi kalori menu rekomendasi harian harus memenuhi batasan <= target TDEE fiktif yang telah disesuaikan dengan goal (*toleransi batas atas maksimal 5%*).

### B. Profil Uji Skenario
Berikut adalah 5 profil uji fiktif yang digunakan dalam pengujian:
* **Profil 1:** Wanita, 55 kg, 158 cm, 28 tahun, Sedentary, Goal: Cutting (Target: 984 kkal).
* **Profil 2:** Pria, 70 kg, 170 cm, 25 tahun, Sedentary, Goal: Maintain (Target: 1971 kkal).
* **Profil 3:** Pria, 85 kg, 180 cm, 22 tahun, Active, Goal: Bulking (Target: 3626 kkal).
* **Profil 4:** Wanita, 60 kg, 165 cm, 30 tahun, Moderate, Goal: Maintain (Target: 2046 kkal).
* **Profil 5:** Pria, 80 kg, 175 cm, 35 tahun, Moderate, Goal: Cutting (Target: 2172 kkal).

### C. Tabel Hasil Pengujian Precision
| No | Skenario Profil | Target Kalori (TDEE) | Akumulasi Kalori Menu | Jumlah Item Menu | Lolos Filter Junk/Gorengan | Validasi Kalori | Status Kelolosan |
|---|---|---|---|---|---|---|---|
| 1 | Wanita Cutting (Rendah) | 984 kkal | 985 kkal | 13 item | ✅ Lolos | ✅ <= 1033 kkal | **LOLOS (Pass)** |
| 2 | Pria Sedentary (Sedang) | 1971 kkal | 1971 kkal | 12 item | ✅ Lolos | ✅ <= 2070 kkal | **LOLOS (Pass)** |
| 3 | Pria Active Bulking (Tinggi) | 3626 kkal | 3627 kkal | 13 item | ✅ Lolos | ✅ <= 3807 kkal | **LOLOS (Pass)** |
| 4 | Wanita Moderate (Sedang) | 2046 kkal | 2041 kkal | 13 item | ✅ Lolos | ✅ <= 2148 kkal | **LOLOS (Pass)** |
| 5 | Pria Moderate Cutting (Tinggi) | 2172 kkal | 2170 kkal | 14 item | ✅ Lolos | ✅ <= 2281 kkal | **LOLOS (Pass)** |

### D. Ringkasan Precision Score
Rumus Perhitungan Precision:
$$\text{Precision} = \left( \frac{\text{Jumlah Skenario Lolos}}{\text{Total Skenario Uji}} \right) \times 100\%$$

Perhitungan:
$$\text{Precision} = \left( \frac{5}{5} \right) \times 100\% = 100.0\%$$

> [!NOTE]
> Algoritma *Constraint-Based Filtering* memiliki **Precision Score 100.0%** pada definisi relevansi operasional pengujian. Item yang dinilai relevan lolos aturan kategori dan batas energi yang ditetapkan.

---

## 2. Metrik Keberhasilan 2: Latensi Akses Data (Response Time)

### A. Metodologi Pengujian
Mengukur rata-rata kecepatan eksekusi pencarian data makanan berdasarkan kata kunci pencarian umum dengan menggunakan 10 iterasi per kata kunci. Pengujian membandingkan dua metode pengambilan data (*Hybrid Retrieval*):
1. **Endpoint API (FastAPI):** Profiling pemrosesan query pencarian pada handler API server (termasuk validasi input, pencarian database, pengurutan skor relevansi, dan filtering blacklist).
2. **Raw Database (SQLite):** Profiling query SELECT langsung ke database lokal SQLite (mensimulasikan performa pada skenario luring/offline di Flutter).

### B. Tabel Perbandingan Response Time
| Kata Kunci Pencarian | Frekuensi Iterasi | Rata-rata Latensi Endpoint API (ms) | Rata-rata Latensi Raw SQLite (ms) | Selisih / Overhead Pemrosesan (ms) | Total Data Ditemukan |
|---|---|---|---|---|---|
| **nasi** | 10× | 1.95 ms | 0.55 ms | +1.40 ms | 27 item |
| **ayam** | 10× | 0.90 ms | 0.57 ms | +0.33 ms | 43 item |
| **tempe** | 10× | 0.76 ms | 0.52 ms | +0.24 ms | 25 item |
| **bayam** | 10× | 0.67 ms | 0.51 ms | +0.16 ms | 7 item |
| **pisang** | 10× | 0.77 ms | 0.51 ms | +0.26 ms | 25 item |
| **ikan** | 10× | 1.18 ms | 0.61 ms | +0.57 ms | 119 item |
| **roti** | 10× | 0.68 ms | 0.52 ms | +0.17 ms | 11 item |
| **telur** | 10× | 0.78 ms | 0.53 ms | +0.25 ms | 33 item |
| **kangkung** | 10× | 0.70 ms | 0.54 ms | +0.16 ms | 7 item |
| **jeruk** | 10× | 0.66 ms | 0.51 ms | +0.15 ms | 8 item |
| **RATA-RATA** | **100× total** | **0.91 ms** | **0.54 ms** | **+0.37 ms** | **30.5 item** |

### C. Kesimpulan Metrik Response Time
* **Efisiensi Struktur Lokal:** Proses pencarian data secara offline (SQLite) berjalan sangat cepat dengan rata-rata latensi global **0.54 milidetik**.
* **Overhead Pemrosesan Minimal:** Rata-rata overhead pemrosesan backend (FastAPI routing, filtering, scoring relevansi) hanya sebesar **+0.37 milidetik** di atas waktu raw query database murni.
* **Kelayakan UX:** Berdasarkan standar batas responsivitas antarmuka (UX), kecepatan di bawah 100 ms dikategorikan sebagai *instant*. Latensi pemrosesan sistem Fit Meal (~0.91 ms untuk API, ~0.54 ms untuk SQLite) jauh di bawah batas tersebut, sehingga memberikan performa yang sangat responsif.
