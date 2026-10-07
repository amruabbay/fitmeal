"""
==========================================================================
 ⏱️ SKRIP UJI METRIK RESPONSE TIME — Performa Arsitektur Hybrid Fit Meal
==========================================================================

 Tujuan   : Mengukur latensi (ms) akses data pada arsitektur Hybrid:
              - Bagian 1 (Online)  : Looping request ke endpoint /search FastAPI
              - Bagian 2 (Offline) : Simulasi query SQLite lokal (pengganti Dart)

 Output   : Tabel perbandingan kecepatan rata-rata (ms) antara:
              → Akses ONLINE  (API server) 
              → Akses OFFLINE (SQLite lokal)

 Cara Jalan: python test_response_time.py
              (pastikan server FastAPI berjalan di localhost:8000)

 Author   : Auto-generated untuk penelitian skripsi Fit Meal
==========================================================================
"""

import requests
import sqlite3
import time
import statistics
import sys
from datetime import datetime

# ==========================================================================
# ⚙️ KONFIGURASI
# ==========================================================================

BASE_URL = "http://127.0.0.1:8000"
ENDPOINT_SEARCH = f"{BASE_URL}/search"
DB_NAME = "skripsi_diet.db"

# Kata kunci pencarian yang diuji (merepresentasikan penggunaan nyata)
KATA_KUNCI_UJI = [
    "nasi",       # Karbohidrat — sangat umum
    "ayam",       # Protein hewani — populer
    "tempe",      # Protein nabati
    "bayam",      # Sayuran
    "pisang",     # Buah
    "ikan",       # Protein hewani — banyak variasi
    "roti",       # Karbohidrat
    "telur",      # Protein — sedikit variasi
    "kangkung",   # Sayuran
    "jeruk",      # Buah
]

# Jumlah iterasi per kata kunci (untuk mendapat rata-rata stabil)
ITERASI_PER_QUERY = 10


# ==========================================================================
# 🌐 BAGIAN 1: UJI RESPONSE TIME — ONLINE (API Server)
# ==========================================================================

def uji_response_time_online() -> dict:
    """
    Melakukan looping request ke endpoint /search FastAPI untuk setiap
    kata kunci, lalu menghitung rata-rata waktu respons dalam milidetik.
    
    Metrik yang dihitung per kata kunci:
      - Rata-rata (mean) response time
      - Minimum response time
      - Maksimum response time
      - Standard Deviation
    
    Returns: dict {keyword: {mean_ms, min_ms, max_ms, std_ms, jumlah_hasil}}
    """
    print("\n" + "=" * 70)
    print("  🌐 BAGIAN 1: UJI RESPONSE TIME — ONLINE (API Server)")
    print("=" * 70)
    print(f"  Endpoint  : {ENDPOINT_SEARCH}")
    print(f"  Iterasi   : {ITERASI_PER_QUERY}× per kata kunci")
    print(f"  Kata kunci: {len(KATA_KUNCI_UJI)} jenis")
    print()

    hasil_online = {}

    for keyword in KATA_KUNCI_UJI:
        waktu_list = []
        jumlah_hasil = 0

        for i in range(ITERASI_PER_QUERY):
            # Ukur waktu mulai
            start = time.perf_counter()

            try:
                response = requests.get(
                    ENDPOINT_SEARCH,
                    params={"q": keyword, "page": 0, "limit": 10},
                    timeout=15
                )
                # Ukur waktu selesai
                end = time.perf_counter()

                elapsed_ms = (end - start) * 1000  # detik → milidetik
                waktu_list.append(elapsed_ms)

                # Ambil jumlah hasil dari response pertama
                if i == 0 and response.status_code == 200:
                    data = response.json()
                    jumlah_hasil = data.get("total_found", 0)

            except requests.exceptions.RequestException as e:
                print(f"  ⚠️ Error pada '{keyword}' iterasi {i+1}: {e}")
                continue

        if waktu_list:
            hasil_online[keyword] = {
                "mean_ms": round(statistics.mean(waktu_list), 2),
                "min_ms": round(min(waktu_list), 2),
                "max_ms": round(max(waktu_list), 2),
                "std_ms": round(statistics.stdev(waktu_list), 2) if len(waktu_list) > 1 else 0,
                "jumlah_hasil": jumlah_hasil,
                "iterasi_berhasil": len(waktu_list),
            }
            print(f"  ✅ '{keyword}' → mean: {hasil_online[keyword]['mean_ms']:.2f} ms "
                  f"(min: {hasil_online[keyword]['min_ms']:.2f}, "
                  f"max: {hasil_online[keyword]['max_ms']:.2f}, "
                  f"hasil: {jumlah_hasil})")
        else:
            hasil_online[keyword] = None
            print(f"  ❌ '{keyword}' → Semua iterasi gagal")

    return hasil_online


# ==========================================================================
# 💾 BAGIAN 2: UJI RESPONSE TIME — OFFLINE (SQLite Lokal)
# ==========================================================================

def uji_response_time_offline() -> dict:
    """
    Melakukan query SELECT pencarian data makanan langsung ke SQLite lokal.
    Ini mensimulasikan apa yang dilakukan Flutter saat mode offline.
    
    Query yang digunakan sama persis dengan logika di main.py:
      SELECT * FROM food_cache WHERE lower(nama_makanan) LIKE '%keyword%'
    
    Metrik yang dihitung per kata kunci:
      - Rata-rata (mean) query time
      - Minimum query time
      - Maksimum query time
      - Standard Deviation
    
    Returns: dict {keyword: {mean_ms, min_ms, max_ms, std_ms, jumlah_hasil}}
    """
    print("\n" + "=" * 70)
    print("  💾 BAGIAN 2: UJI RESPONSE TIME — OFFLINE (SQLite Lokal)")
    print("=" * 70)
    print(f"  Database  : {DB_NAME}")
    print(f"  Iterasi   : {ITERASI_PER_QUERY}× per kata kunci")
    print(f"  Kata kunci: {len(KATA_KUNCI_UJI)} jenis")
    print()

    hasil_offline = {}

    for keyword in KATA_KUNCI_UJI:
        waktu_list = []
        jumlah_hasil = 0

        for i in range(ITERASI_PER_QUERY):
            # Ukur waktu mulai
            start = time.perf_counter()

            try:
                # Buka koneksi baru setiap iterasi (realistis seperti Flutter)
                conn = sqlite3.connect(DB_NAME)
                conn.row_factory = sqlite3.Row
                cursor = conn.cursor()

                # Query pencarian — sama dengan logika di main.py
                keywords = keyword.lower().split()
                clauses = []
                params = []
                for k in keywords:
                    clauses.append("lower(nama_makanan) LIKE ?")
                    params.append(f"%{k}%")

                sql_query = "SELECT * FROM food_cache WHERE " + " OR ".join(clauses)
                cursor.execute(sql_query, params)
                rows = cursor.fetchall()

                conn.close()

                # Ukur waktu selesai
                end = time.perf_counter()

                elapsed_ms = (end - start) * 1000
                waktu_list.append(elapsed_ms)

                # Ambil jumlah hasil dari iterasi pertama
                if i == 0:
                    jumlah_hasil = len(rows)

            except Exception as e:
                print(f"  ⚠️ Error pada '{keyword}' iterasi {i+1}: {e}")
                continue

        if waktu_list:
            hasil_offline[keyword] = {
                "mean_ms": round(statistics.mean(waktu_list), 2),
                "min_ms": round(min(waktu_list), 2),
                "max_ms": round(max(waktu_list), 2),
                "std_ms": round(statistics.stdev(waktu_list), 2) if len(waktu_list) > 1 else 0,
                "jumlah_hasil": jumlah_hasil,
                "iterasi_berhasil": len(waktu_list),
            }
            print(f"  ✅ '{keyword}' → mean: {hasil_offline[keyword]['mean_ms']:.2f} ms "
                  f"(min: {hasil_offline[keyword]['min_ms']:.2f}, "
                  f"max: {hasil_offline[keyword]['max_ms']:.2f}, "
                  f"hasil: {jumlah_hasil})")
        else:
            hasil_offline[keyword] = None
            print(f"  ❌ '{keyword}' → Semua iterasi gagal")

    return hasil_offline


# ==========================================================================
# 📊 CETAK TABEL PERBANDINGAN
# ==========================================================================

def cetak_perbandingan(hasil_online: dict, hasil_offline: dict):
    """
    Mencetak tabel perbandingan response time Online vs Offline
    dalam format yang rapi dan informatif.
    """
    print("\n")
    print("═" * 90)
    print("  📊 TABEL PERBANDINGAN RESPONSE TIME: ONLINE vs OFFLINE")
    print(f"  Waktu Pengujian: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("═" * 90)

    # Header tabel
    header = (
        f"  {'Kata Kunci':<12} │ "
        f"{'Online (ms)':>12} │ "
        f"{'Offline (ms)':>12} │ "
        f"{'Rasio':>8} │ "
        f"{'Selisih (ms)':>12} │ "
        f"{'Hasil':>6}"
    )
    print(header)
    print(f"  {'─' * 12}─┼─{'─' * 12}─┼─{'─' * 12}─┼─{'─' * 8}─┼─{'─' * 12}─┼─{'─' * 6}")

    total_online_ms = []
    total_offline_ms = []

    for keyword in KATA_KUNCI_UJI:
        online = hasil_online.get(keyword)
        offline = hasil_offline.get(keyword)

        if online and offline:
            on_ms = online["mean_ms"]
            off_ms = offline["mean_ms"]
            rasio = on_ms / off_ms if off_ms > 0 else float("inf")
            selisih = on_ms - off_ms

            total_online_ms.append(on_ms)
            total_offline_ms.append(off_ms)

            print(
                f"  {keyword:<12} │ "
                f"{on_ms:>10.2f}  │ "
                f"{off_ms:>10.2f}  │ "
                f"{rasio:>6.1f}×  │ "
                f"{selisih:>+10.2f}  │ "
                f"{online['jumlah_hasil']:>5}"
            )
        else:
            status = "ERR" if not online else "ERR"
            print(f"  {keyword:<12} │ {'ERR':>12} │ {'ERR':>12} │ {'N/A':>8} │ {'N/A':>12} │ {'N/A':>6}")

    # Garis penutup tabel
    print(f"  {'─' * 12}─┼─{'─' * 12}─┼─{'─' * 12}─┼─{'─' * 8}─┼─{'─' * 12}─┼─{'─' * 6}")

    # Rata-rata keseluruhan
    if total_online_ms and total_offline_ms:
        avg_on = statistics.mean(total_online_ms)
        avg_off = statistics.mean(total_offline_ms)
        avg_rasio = avg_on / avg_off if avg_off > 0 else float("inf")
        avg_selisih = avg_on - avg_off

        print(
            f"  {'RATA-RATA':<12} │ "
            f"{avg_on:>10.2f}  │ "
            f"{avg_off:>10.2f}  │ "
            f"{avg_rasio:>6.1f}×  │ "
            f"{avg_selisih:>+10.2f}  │ "
            f"{'':>6}"
        )

    # ============================================
    # RINGKASAN STATISTIK
    # ============================================
    print("\n")
    print("═" * 90)
    print("  📈 RINGKASAN STATISTIK")
    print("═" * 90)

    if total_online_ms:
        print(f"\n  🌐 ONLINE (API Server):")
        print(f"     Rata-rata : {statistics.mean(total_online_ms):>10.2f} ms")
        print(f"     Minimum   : {min(total_online_ms):>10.2f} ms")
        print(f"     Maksimum  : {max(total_online_ms):>10.2f} ms")
        if len(total_online_ms) > 1:
            print(f"     Std Dev    : {statistics.stdev(total_online_ms):>10.2f} ms")

    if total_offline_ms:
        print(f"\n  💾 OFFLINE (SQLite Lokal):")
        print(f"     Rata-rata : {statistics.mean(total_offline_ms):>10.2f} ms")
        print(f"     Minimum   : {min(total_offline_ms):>10.2f} ms")
        print(f"     Maksimum  : {max(total_offline_ms):>10.2f} ms")
        if len(total_offline_ms) > 1:
            print(f"     Std Dev    : {statistics.stdev(total_offline_ms):>10.2f} ms")

    if total_online_ms and total_offline_ms:
        speedup = statistics.mean(total_online_ms) / statistics.mean(total_offline_ms)
        print(f"\n  ⚡ KESIMPULAN:")
        print(f"     Akses offline (SQLite) rata-rata {speedup:.1f}× lebih cepat")
        print(f"     daripada akses online (API Server).")
        
        if speedup > 10:
            print(f"     → Perbedaan SANGAT SIGNIFIKAN. Hybrid approach terbukti efektif.")
        elif speedup > 3:
            print(f"     → Perbedaan SIGNIFIKAN. Offline mode memberikan UX yang lebih baik.")
        else:
            print(f"     → Perbedaan MODERAT. Kedua metode cukup responsif.")

    print("\n" + "═" * 90)


# ==========================================================================
# 🚀 MAIN — Eksekusi Pengujian
# ==========================================================================

if __name__ == "__main__":
    print("\n⏱️  Memulai pengujian Response Time arsitektur Hybrid Fit Meal...\n")

    # --- Cek koneksi server ---
    try:
        resp = requests.get(BASE_URL, timeout=5)
        print(f"✅ Server terdeteksi: {resp.json()}")
    except Exception as e:
        print(f"❌ Server tidak terdeteksi di {BASE_URL}")
        print(f"   Error: {e}")
        print(f"\n💡 Jalankan server terlebih dahulu:")
        print(f"   python main.py")
        sys.exit(1)

    # --- Cek database lokal ---
    try:
        conn = sqlite3.connect(DB_NAME)
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM food_cache")
        count = cursor.fetchone()[0]
        conn.close()
        print(f"✅ Database lokal terdeteksi: {count} item di food_cache")
    except Exception as e:
        print(f"❌ Database lokal tidak ditemukan: {e}")
        sys.exit(1)

    # --- Warming up (1 request untuk inisialisasi koneksi) ---
    print("\n🔥 Warming up server...")
    try:
        requests.get(ENDPOINT_SEARCH, params={"q": "nasi"}, timeout=10)
        print("   Server siap.\n")
    except:
        pass

    # --- Jalankan pengujian ---
    hasil_online = uji_response_time_online()
    hasil_offline = uji_response_time_offline()

    # --- Cetak perbandingan ---
    cetak_perbandingan(hasil_online, hasil_offline)

    print("\n✅ Pengujian Response Time selesai.\n")
