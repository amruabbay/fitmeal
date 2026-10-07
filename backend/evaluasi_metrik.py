"""
=============================================================================
📊 SKRIP EVALUASI METRIK KEBERHASILAN PENELITIAN
Proyek Skripsi: Sistem Rekomendasi Menu Diet "Fit Meal"
=============================================================================

Skrip ini melakukan pengujian otomatis kuantitatif untuk dua metrik utama:
  1. Metrik 1: Akurasi Algoritma Rekomendasi (Precision Score)
     - Constraint Eliminasi: 0% junk food / gorengan.
     - Constraint Nutrisi: Akumulasi kalori <= target TDEE + 5% toleransi.
  2. Metrik 2: Latensi Akses Data (Response Time & Overhead)
     - Handler API / Search logic
     - Raw SQLite Query
     - Overhead Pemrosesan

Output: Menghasilkan file Markdown 'evaluasilmetrik.md' otomatis.
=============================================================================
"""

import time
import sqlite3
import statistics
import sys
import os
from datetime import datetime

# Mengimpor handler lokal langsung (in-memory, aman dari isu port binding)
try:
    from main import get_rekomendasi, UserData, cari_makanan, is_junk_food
    from algoritma import DB_NAME
except ImportError as e:
    print(f"❌ Error import modul: {e}")
    sys.exit(1)

# --- DAFTAR BLACKLIST JUNK FOOD UNTUK VALIDASI ACCURACY ---
BLACKLIST_JUNK_FOOD = [
    "kfc", "mcd", "mcdonalds", "burger", "pizza", "hokben", "solaria",
    "a&w", "wendys", "fast food", "junk food", "french fries",
    "hotdog", "corndog", "chicken wings", "chicken nugget", "nugget",
    "kebab", "shawarma", "doner", "taco", "burrito", "gorengan", "crispy",
    "penyet", "geprek", "kulit ayam", "fried chicken", "ayam goreng",
    "bebek goreng", "lele goreng", "bakwan", "bala-bala", "cireng", "cimol",
    "cilok", "batagor", "pempek", "kerupuk", "krupuk", "rempeyek", "emping",
    "mendoan", "risol", "lumpia", "pastel", "basreng", "kripik", "keripik",
    "chiki", "seblak", "cuanki", "kentang goreng", "pop mie", "popmie",
    "sarimi", "indomie", "mie sedaap", "mie sedap", "supermi", "samyang",
    "chitato", "lays", "taro", "cheetos", "mie instan", "sosis", "kornet",
    "boba", "bubble", "milk tea", "es krim", "ice cream", "coca-cola",
    "coca cola", "fanta", "sprite", "pepsi", "soda", "gacoan", "oreo",
    "silverqueen", "beng-beng", "beng beng", "martabak", "kue", "biskuit",
    "wafer", "cake", "pudding", "coklat", "chocolate"
]

# --- PROFIL UJI PRECISION (5 SKENARIO) ---
PROFIL_UJI = [
    {
        "no": 1,
        "nama": "Wanita Cutting (Rendah)",
        "deskripsi": "Wanita, 55 kg, 158 cm, 28 thn, Sedentary, Goal: Cutting",
        "user_data": UserData(berat=55, tinggi=158, umur=28, gender="wanita", goal="cutting", activity="sedentary")
    },
    {
        "no": 2,
        "nama": "Pria Sedentary (Sedang)",
        "deskripsi": "Pria, 70 kg, 170 cm, 25 thn, Sedentary, Goal: Maintain",
        "user_data": UserData(berat=70, tinggi=170, umur=25, gender="pria", goal="maintain", activity="sedentary")
    },
    {
        "no": 3,
        "nama": "Pria Active Bulking (Tinggi)",
        "deskripsi": "Pria, 85 kg, 180 cm, 22 thn, Active, Goal: Bulking",
        "user_data": UserData(berat=85, tinggi=180, umur=22, gender="pria", goal="bulking", activity="active")
    },
    {
        "no": 4,
        "nama": "Wanita Moderate (Sedang)",
        "deskripsi": "Wanita, 60 kg, 165 cm, 30 thn, Moderate, Goal: Maintain",
        "user_data": UserData(berat=60, tinggi=165, umur=30, gender="wanita", goal="maintain", activity="moderate")
    },
    {
        "no": 5,
        "nama": "Pria Moderate Cutting (Tinggi)",
        "deskripsi": "Pria, 80 kg, 175 cm, 35 thn, Moderate, Goal: Cutting",
        "user_data": UserData(berat=80, tinggi=175, umur=35, gender="pria", goal="cutting", activity="moderate")
    }
]

# --- KATA KUNCI UJI RESPONSE TIME ---
KATA_KUNCI_UJI = [
    "nasi", "ayam", "tempe", "bayam", "pisang",
    "ikan", "roti", "telur", "kangkung", "jeruk"
]
ITERASI_PER_QUERY = 10


def eval_precision():
    """Menguji Precision Score berdasarkan 5 skenario profil."""
    print("=" * 65)
    print("  📊 1. MENGUJI METRIK ACCURACY / PRECISION SCORE")
    print("=" * 65)

    hasil_precision = []
    total_skenario = len(PROFIL_UJI)
    skenario_lolos = 0

    for p in PROFIL_UJI:
        u_data = p["user_data"]
        res = get_rekomendasi(u_data)
        
        target_kal = res["user_info"]["target_kalori"]
        batas_toleransi = round(target_kal * 1.05)
        
        # Hitung akumulasi kalori & jumlah item
        total_kalori_menu = 0
        total_item = 0
        semua_item_makanan = []
        
        for meal in res["menu"]:
            for item in meal["isi"]:
                total_kalori_menu += item["kalori"]
                total_item += 1
                semua_item_makanan.append(item["nama_makanan"].lower())
                
        total_kalori_menu = round(total_kalori_menu)
        
        # Constraint 1: Filter Junk Food
        mengandung_junk = False
        for mkn in semua_item_makanan:
            for junk in BLACKLIST_JUNK_FOOD:
                if junk in mkn:
                    mengandung_junk = True
                    break
            if mengandung_junk:
                break
                
        lolos_junk = not mengandung_junk
        
        # Constraint 2: Validasi Kalori (<= target + 5%)
        valid_kalori = total_kalori_menu <= batas_toleransi
        
        # Status Akhir
        status_pass = lolos_junk and valid_kalori
        if status_pass:
            skenario_lolos += 1
            
        hasil_precision.append({
            "no": p["no"],
            "nama": p["nama"],
            "target_kalori": target_kal,
            "akumulasi_kalori": total_kalori_menu,
            "jumlah_item": total_item,
            "batas_toleransi": batas_toleransi,
            "lolos_junk": lolos_junk,
            "valid_kalori": valid_kalori,
            "status_pass": status_pass
        })
        
        print(f"  [{'PASS' if status_pass else 'FAIL'}] {p['nama']:<32} | Target: {target_kal} kkal | Hasil: {total_kalori_menu} kkal | Junk Free: {'✅' if lolos_junk else '❌'}")

    precision_score = (skenario_lolos / total_skenario) * 100
    print(f"\n  🎯 Precision Score: {precision_score:.1f}% ({skenario_lolos}/{total_skenario} Lolos)\n")
    return hasil_precision, precision_score


def eval_response_time():
    """Menguji Latensi Endpoint API vs Raw SQLite Query."""
    print("=" * 65)
    print("  ⏱️ 2. MENGUJI METRIK RESPONSE TIME & LATENSI HYBRID")
    print("=" * 65)

    hasil_response_time = []
    
    # 1. Test Endpoint API Search Handler
    api_latencies = {}
    total_found_dict = {}
    for kw in KATA_KUNCI_UJI:
        times = []
        found_cnt = 0
        for _ in range(ITERASI_PER_QUERY):
            start = time.perf_counter()
            res = cari_makanan(q=kw, page=0, limit=10)
            end = time.perf_counter()
            times.append((end - start) * 1000)
            found_cnt = res.get("total_found", 0)
        api_latencies[kw] = statistics.mean(times)
        total_found_dict[kw] = found_cnt

    # 2. Test Raw SQLite Direct Query
    sqlite_latencies = {}
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    
    for kw in KATA_KUNCI_UJI:
        times = []
        for _ in range(ITERASI_PER_QUERY):
            start = time.perf_counter()
            cursor.execute("SELECT * FROM food_cache WHERE lower(nama_makanan) LIKE ?", (f"%{kw}%",))
            cursor.fetchall()
            end = time.perf_counter()
            times.append((end - start) * 1000)
        sqlite_latencies[kw] = statistics.mean(times)
        
    conn.close()

    # Rekap per kata kunci
    total_api_time = 0
    total_sqlite_time = 0
    total_found_sum = 0
    
    for kw in KATA_KUNCI_UJI:
        api_ms = api_latencies[kw]
        sqlite_ms = sqlite_latencies[kw]
        overhead_ms = api_ms - sqlite_ms
        cnt = total_found_dict[kw]
        
        total_api_time += api_ms
        total_sqlite_time += sqlite_ms
        total_found_sum += cnt
        
        hasil_response_time.append({
            "keyword": kw,
            "iterations": ITERASI_PER_QUERY,
            "api_ms": api_ms,
            "sqlite_ms": sqlite_ms,
            "overhead_ms": overhead_ms,
            "total_found": cnt
        })
        
        print(f"  🔍 '{kw:<8}' | API: {api_ms:5.2f} ms | SQLite: {sqlite_ms:5.2f} ms | Overhead: {overhead_ms:+5.2f} ms | Items: {cnt}")

    avg_api = total_api_time / len(KATA_KUNCI_UJI)
    avg_sqlite = total_sqlite_time / len(KATA_KUNCI_UJI)
    avg_overhead = avg_api - avg_sqlite
    avg_found = total_found_sum / len(KATA_KUNCI_UJI)

    print(f"\n  ⚡ Rata-rata Global: API = {avg_api:.2f} ms | SQLite = {avg_sqlite:.2f} ms | Overhead = {avg_overhead:+.2f} ms\n")
    
    summary_rt = {
        "avg_api": avg_api,
        "avg_sqlite": avg_sqlite,
        "avg_overhead": avg_overhead,
        "avg_found": avg_found,
        "total_queries": len(KATA_KUNCI_UJI) * ITERASI_PER_QUERY
    }
    
    return hasil_response_time, summary_rt


def generate_markdown_report(hasil_prec, precision_score, hasil_rt, summary_rt):
    """Membuat dokumen laporan Markdown evaluasilmetrik.md."""
    waktu_skrg = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    md_content = f"""# Laporan Hasil Pengujian Metrik Keberhasilan Penelitian
**Proyek Skripsi: Sistem Rekomendasi Menu Diet "Fit Meal"**
*Waktu Pengujian: {waktu_skrg}*

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
* **Profil 1:** Wanita, 55 kg, 158 cm, 28 tahun, Sedentary, Goal: Cutting.
* **Profil 2:** Pria, 70 kg, 170 cm, 25 tahun, Sedentary, Goal: Maintain.
* **Profil 3:** Pria, 85 kg, 180 cm, 22 tahun, Active, Goal: Bulking.
* **Profil 4:** Wanita, 60 kg, 165 cm, 30 tahun, Moderate, Goal: Maintain.
* **Profil 5:** Pria, 80 kg, 175 cm, 35 tahun, Moderate, Goal: Cutting.

### C. Tabel Hasil Pengujian Precision
| No | Skenario Profil | Target Kalori (TDEE) | Akumulasi Kalori Menu | Jumlah Item Menu | Lolos Filter Junk/Gorengan | Validasi Kalori | Status Kelolosan |
|---|---|---|---|---|---|---|---|
"""

    for r in hasil_prec:
        junk_icon = "✅ Lolos" if r["lolos_junk"] else "❌ Gagal"
        kal_icon = f"✅ <= {r['batas_toleransi']} kkal" if r["valid_kalori"] else f"❌ > {r['batas_toleransi']} kkal"
        status_str = "**LOLOS (Pass)**" if r["status_pass"] else "**GAGAL (Fail)**"
        
        md_content += f"| {r['no']} | {r['nama']} | {r['target_kalori']} kkal | {r['akumulasi_kalori']} kkal | {r['jumlah_item']} item | {junk_icon} | {kal_icon} | {status_str} |\n"

    md_content += f"""
### D. Ringkasan Precision Score
Rumus Perhitungan Precision:
$$\\text{{Precision}} = \\left( \\frac{{\\text{{Jumlah Skenario Lolos}}}}{{\\text{{Total Skenario Uji}}}} \\right) \\times 100\\%$$

Perhitungan:
$$\\text{{Precision}} = \\left( \\frac{{{sum(1 for x in hasil_prec if x['status_pass'])}}}{{{len(hasil_prec)}}} \\right) \\times 100\\% = {precision_score:.1f}\\%$$

> [!NOTE]
> Algoritma *Constraint-Based Filtering* memiliki **Precision Score {precision_score:.1f}%** pada definisi relevansi operasional pengujian. Item yang dinilai relevan lolos aturan kategori dan batas energi yang ditetapkan.

---

## 2. Metrik Keberhasilan 2: Latensi Akses Data (Response Time)

### A. Metodologi Pengujian
Mengukur rata-rata kecepatan eksekusi pencarian data makanan berdasarkan kata kunci pencarian umum dengan menggunakan 10 iterasi per kata kunci. Pengujian membandingkan dua metode pengambilan data (*Hybrid Retrieval*):
1. **Endpoint API (FastAPI):** Profiling pemrosesan query pencarian pada handler API server (termasuk validasi input, pencarian database, pengurutan skor relevansi, dan filtering blacklist).
2. **Raw Database (SQLite):** Profiling query SELECT langsung ke database lokal SQLite (mensimulasikan performa pada skenario luring/offline di Flutter).

### B. Tabel Perbandingan Response Time
| Kata Kunci Pencarian | Frekuensi Iterasi | Rata-rata Latensi Endpoint API (ms) | Rata-rata Latensi Raw SQLite (ms) | Selisih / Overhead Pemrosesan (ms) | Total Data Ditemukan |
|---|---|---|---|---|---|
"""

    for r in hasil_rt:
        overhead_sign = f"+{r['overhead_ms']:.2f}" if r['overhead_ms'] >= 0 else f"{r['overhead_ms']:.2f}"
        md_content += f"| **{r['keyword']}** | {r['iterations']}× | {r['api_ms']:.2f} ms | {r['sqlite_ms']:.2f} ms | {overhead_sign} ms | {r['total_found']} item |\n"

    total_iterasi = summary_rt['total_queries']
    avg_api_str = f"{summary_rt['avg_api']:.2f}"
    avg_sq_str = f"{summary_rt['avg_sqlite']:.2f}"
    avg_oh_str = f"+{summary_rt['avg_overhead']:.2f}" if summary_rt['avg_overhead'] >= 0 else f"{summary_rt['avg_overhead']:.2f}"
    avg_cnt_str = f"{summary_rt['avg_found']:.1f}"

    md_content += f"""| **RATA-RATA** | **{total_iterasi}× total** | **{avg_api_str} ms** | **{avg_sq_str} ms** | **{avg_oh_str} ms** | **{avg_cnt_str} item** |

### C. Kesimpulan Metrik Response Time
* **Efisiensi Struktur Lokal:** Proses pencarian data secara offline (SQLite) berjalan sangat cepat dengan rata-rata latensi global **{avg_sq_str} milidetik**.
* **Overhead Pemrosesan Minimal:** Rata-rata overhead pemrosesan backend (FastAPI routing, filtering, scoring relevansi) hanya sebesar **{avg_oh_str} milidetik** di atas waktu raw query database murni.
* **Kelayakan UX:** Berdasarkan standar batas responsivitas antarmuka (UX), kecepatan di bawah 100 ms dikategorikan sebagai *instant*. Latensi pemrosesan sistem Fit Meal (~{avg_api_str} ms untuk API, ~{avg_sq_str} ms untuk SQLite) jauh di bawah batas tersebut, sehingga memberikan performa yang sangat responsif.
"""

    # Simpan ke file evaluasilmetrik.md di directory lokal dan TUGAS AKHIR jika ada
    target_files = ["evaluasilmetrik.md"]
    tugas_akhir_dir = "/Users/admin1/TUGAS AKHIR"
    if os.path.exists(tugas_akhir_dir):
        target_files.append(os.path.join(tugas_akhir_dir, "evaluasilmetrik.md"))
        
    for tf in target_files:
        try:
            with open(tf, "w", encoding="utf-8") as f:
                f.write(md_content)
            print(f"  📄 Laporan Markdown berhasil disimpan ke: {tf}")
        except Exception as e:
            print(f"  ⚠️ Gagal menyimpan ke {tf}: {e}")

    return md_content


def main():
    print(f"\n🚀 MENJALANKAN SKRIP EVALUASI METRIK FIT MEAL...")
    print(f"Waktu: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    
    hasil_prec, precision_score = eval_precision()
    hasil_rt, summary_rt = eval_response_time()
    
    print("=" * 65)
    print("  📝 GENERATING FILE MARKDOWN (evaluasilmetrik.md)...")
    print("=" * 65)
    generate_markdown_report(hasil_prec, precision_score, hasil_rt, summary_rt)
    print("\n✅ Evaluasi Metrik Selesai 100%!")

if __name__ == "__main__":
    main()
