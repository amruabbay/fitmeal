# Laporan Evaluasi Metrik Presisi Berbasis Relevansi
**Proyek Skripsi: Sistem Rekomendasi Menu Diet "Fit Meal"**
*Waktu Pengujian: 2026-08-18 10:32:56*

---

## 1. Pendahuluan

Evaluasi ini menggunakan metrik **Presisi** (*Precision*) yang umum digunakan dalam domain *Information Retrieval* dan Sistem Rekomendasi. Berbeda dengan matriks konfusi (*Confusion Matrix*) tradisional yang memerlukan perhitungan *True Negative* (TN) dan *False Negative* (FN), metrik presisi berbasis relevansi lebih tepat digunakan pada sistem rekomendasi karena hanya berfokus pada kualitas item yang disajikan kepada pengguna.

### Rumus Presisi

$$Precision = \frac{\text{Jumlah Item Relevan yang Direkomendasikan}}{\text{Total Item yang Direkomendasikan}} \times 100\%$$

### Kriteria Relevansi

Sebuah item makanan yang direkomendasikan dinyatakan **relevan** apabila memenuhi seluruh kriteria berikut:

1. **Lolos Filter Eliminasi Gizi Pakar** — Item bukan termasuk kategori *Ultra-Processed Food* / *junk food* / gorengan berdasarkan daftar *blacklist* yang telah dikurasi.
2. **Kontribusi Nutrisi Wajar** — Kalori individu item tidak melebihi 50% dari target kalori harian pengguna (mencegah porsi tunggal yang tidak proporsional).

### Metodologi Pengujian

Pengujian dilakukan terhadap **6 profil pengguna fiktif** dengan variasi karakteristik antropometri, tingkat aktivitas, dan tujuan diet. Setiap profil diuji sebanyak **5 kali** untuk memeriksa konsistensi penerapan aturan *Constraint-Based Filtering*. Total pengujian: **6 × 5 = 30 sesi rekomendasi**.

---

## 2. Profil Pengguna Uji

| No | Nama Skenario | Gender | BB (kg) | TB (cm) | Umur | Aktivitas | Goal | Target Kalori (kkal) |
|:---:|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | Wanita Cutting Sedentary | Wanita | 55 | 158 | 28 | Sedentary | Cutting | 984 |
| 2 | Pria Maintain Sedentary | Pria | 70 | 170 | 25 | Sedentary | Maintain | 1971 |
| 3 | Pria Bulking Active | Pria | 85 | 180 | 22 | Active | Bulking | 3626 |
| 4 | Wanita Maintain Moderate | Wanita | 60 | 165 | 30 | Moderate | Maintain | 2046 |
| 5 | Pria Cutting Moderate | Pria | 80 | 175 | 35 | Moderate | Cutting | 2172 |
| 6 | Wanita Bulking Moderate | Wanita | 50 | 155 | 20 | Moderate | Bulking | 2272 |

---

## 3. Hasil Pengujian Per Profil

### 3.1 Profil 1: Wanita Cutting Sedentary

**Deskripsi:** Wanita, 55 kg, 158 cm, 28 thn, Sedentary, Cutting  
**Target Kalori Harian:** 984 kkal  
**Target Protein:** 110g  
**Batas Toleransi Kalori (+5%):** 1033 kkal

| Iterasi | Total Item | Item Relevan | Item Tidak Relevan | Precision (%) | Total Kalori Menu | Status Kalori |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | 14 | 14 | 0 | 100.0% | 983 kkal | ✅ Sesuai |
| 2 | 12 | 12 | 0 | 100.0% | 984 kkal | ✅ Sesuai |
| 3 | 14 | 14 | 0 | 100.0% | 985 kkal | ✅ Sesuai |
| 4 | 10 | 10 | 0 | 100.0% | 984 kkal | ✅ Sesuai |
| 5 | 14 | 14 | 0 | 100.0% | 984 kkal | ✅ Sesuai |
| **Rata-rata** | | | | **100.0%** | | |

### 3.2 Profil 2: Pria Maintain Sedentary

**Deskripsi:** Pria, 70 kg, 170 cm, 25 thn, Sedentary, Maintain  
**Target Kalori Harian:** 1971 kkal  
**Target Protein:** 140g  
**Batas Toleransi Kalori (+5%):** 2070 kkal

| Iterasi | Total Item | Item Relevan | Item Tidak Relevan | Precision (%) | Total Kalori Menu | Status Kalori |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | 14 | 14 | 0 | 100.0% | 1969 kkal | ✅ Sesuai |
| 2 | 12 | 12 | 0 | 100.0% | 1971 kkal | ✅ Sesuai |
| 3 | 12 | 12 | 0 | 100.0% | 1971 kkal | ✅ Sesuai |
| 4 | 12 | 12 | 0 | 100.0% | 1967 kkal | ✅ Sesuai |
| 5 | 12 | 12 | 0 | 100.0% | 1970 kkal | ✅ Sesuai |
| **Rata-rata** | | | | **100.0%** | | |

### 3.3 Profil 3: Pria Bulking Active

**Deskripsi:** Pria, 85 kg, 180 cm, 22 thn, Active, Bulking  
**Target Kalori Harian:** 3626 kkal  
**Target Protein:** 170g  
**Batas Toleransi Kalori (+5%):** 3807 kkal

| Iterasi | Total Item | Item Relevan | Item Tidak Relevan | Precision (%) | Total Kalori Menu | Status Kalori |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | 14 | 14 | 0 | 100.0% | 3512 kkal | ✅ Sesuai |
| 2 | 12 | 12 | 0 | 100.0% | 3604 kkal | ✅ Sesuai |
| 3 | 13 | 13 | 0 | 100.0% | 3612 kkal | ✅ Sesuai |
| 4 | 15 | 15 | 0 | 100.0% | 3624 kkal | ✅ Sesuai |
| 5 | 13 | 13 | 0 | 100.0% | 3620 kkal | ✅ Sesuai |
| **Rata-rata** | | | | **100.0%** | | |

### 3.4 Profil 4: Wanita Maintain Moderate

**Deskripsi:** Wanita, 60 kg, 165 cm, 30 thn, Moderate, Maintain  
**Target Kalori Harian:** 2046 kkal  
**Target Protein:** 120g  
**Batas Toleransi Kalori (+5%):** 2149 kkal

| Iterasi | Total Item | Item Relevan | Item Tidak Relevan | Precision (%) | Total Kalori Menu | Status Kalori |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | 12 | 12 | 0 | 100.0% | 2038 kkal | ✅ Sesuai |
| 2 | 15 | 15 | 0 | 100.0% | 2046 kkal | ✅ Sesuai |
| 3 | 12 | 12 | 0 | 100.0% | 2047 kkal | ✅ Sesuai |
| 4 | 14 | 14 | 0 | 100.0% | 2044 kkal | ✅ Sesuai |
| 5 | 10 | 10 | 0 | 100.0% | 2046 kkal | ✅ Sesuai |
| **Rata-rata** | | | | **100.0%** | | |

### 3.5 Profil 5: Pria Cutting Moderate

**Deskripsi:** Pria, 80 kg, 175 cm, 35 thn, Moderate, Cutting  
**Target Kalori Harian:** 2172 kkal  
**Target Protein:** 160g  
**Batas Toleransi Kalori (+5%):** 2280 kkal

| Iterasi | Total Item | Item Relevan | Item Tidak Relevan | Precision (%) | Total Kalori Menu | Status Kalori |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | 13 | 13 | 0 | 100.0% | 2172 kkal | ✅ Sesuai |
| 2 | 14 | 14 | 0 | 100.0% | 2172 kkal | ✅ Sesuai |
| 3 | 12 | 12 | 0 | 100.0% | 2169 kkal | ✅ Sesuai |
| 4 | 13 | 13 | 0 | 100.0% | 2169 kkal | ✅ Sesuai |
| 5 | 11 | 11 | 0 | 100.0% | 2171 kkal | ✅ Sesuai |
| **Rata-rata** | | | | **100.0%** | | |

### 3.6 Profil 6: Wanita Bulking Moderate

**Deskripsi:** Wanita, 50 kg, 155 cm, 20 thn, Moderate, Bulking  
**Target Kalori Harian:** 2272 kkal  
**Target Protein:** 100g  
**Batas Toleransi Kalori (+5%):** 2386 kkal

| Iterasi | Total Item | Item Relevan | Item Tidak Relevan | Precision (%) | Total Kalori Menu | Status Kalori |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | 12 | 12 | 0 | 100.0% | 2254 kkal | ✅ Sesuai |
| 2 | 12 | 12 | 0 | 100.0% | 2274 kkal | ✅ Sesuai |
| 3 | 12 | 12 | 0 | 100.0% | 2272 kkal | ✅ Sesuai |
| 4 | 13 | 13 | 0 | 100.0% | 2271 kkal | ✅ Sesuai |
| 5 | 10 | 10 | 0 | 100.0% | 2267 kkal | ✅ Sesuai |
| **Rata-rata** | | | | **100.0%** | | |

---

## 4. Ringkasan Presisi Per Profil

| No | Nama Skenario | Jumlah Iterasi | Total Item Direkomendasikan | Total Item Relevan | Rata-rata Precision (%) |
|:---:|---|:---:|:---:|:---:|:---:|
| 1 | Wanita Cutting Sedentary | 5 | 64 | 64 | 100.0% |
| 2 | Pria Maintain Sedentary | 5 | 62 | 62 | 100.0% |
| 3 | Pria Bulking Active | 5 | 67 | 67 | 100.0% |
| 4 | Wanita Maintain Moderate | 5 | 63 | 63 | 100.0% |
| 5 | Pria Cutting Moderate | 5 | 63 | 63 | 100.0% |
| 6 | Wanita Bulking Moderate | 5 | 59 | 59 | 100.0% |
| | **RATA-RATA KESELURUHAN** | | **378** | **378** | **100.0%** |

---

## 5. Kesimpulan

### Perhitungan Presisi Keseluruhan

$$Precision = \frac{378}{378} \times 100\% = 100.0\%$$

### Interpretasi Hasil

> Algoritma *Constraint-Based Filtering* mencapai **Precision 100%** pada definisi relevansi operasional pengujian. Seluruh item yang dihitung relevan lolos aturan kategori dan batas energi yang ditetapkan.

### Ringkasan Metrik

| Metrik | Nilai |
|---|---|
| Total Sesi Pengujian | 30 sesi |
| Total Item yang Dievaluasi | 378 item |
| Total Item Relevan | 378 item |
| Total Item Tidak Relevan | 0 item |
| **Precision Keseluruhan** | **100.0%** |

> **Catatan:** Pengujian dilakukan secara otomatis menggunakan profil pengguna fiktif. Pengulangan pada profil yang sama digunakan untuk memeriksa konsistensi penerapan aturan yang deterministik.
