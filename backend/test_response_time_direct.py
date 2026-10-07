"""
==========================================================================
 ⏱️ SKRIP UJI RESPONSE TIME (DIRECT IN-MEMORY) — Performa Arsitektur Hybrid
==========================================================================

 Tujuan   : Mengukur latensi pencarian data secara in-memory (tanpa port bind):
              - Bagian 1 (Endpoint API)  : Memanggil cari_makanan() langsung.
              - Bagian 2 (Query SQLite)   : Melakukan raw query langsung.

 Output   : Perbandingan kecepatan rata-rata (ms) pemanggilan fungsi.
 Cara Jalan: python test_response_time_direct.py

 Author   : Auto-generated untuk penelitian skripsi Fit Meal
==========================================================================
"""

import time
import sqlite3
import statistics
import sys

try:
    from main import cari_makanan
except ImportError as e:
    print(f"❌ Gagal mengimpor modul main.py: {e}")
    sys.exit(1)

DB_NAME = "skripsi_diet.db"
KATA_KUNCI_UJI = [
    "nasi", "ayam", "tempe", "bayam", "pisang",
    "ikan", "roti", "telur", "kangkung", "jeruk"
]
ITERASI_PER_QUERY = 10

def uji_response_time_online_direct():
    print("=" * 70)
    print("  🌐 BAGIAN 1: UJI LATENSI ENDPOINT CARI MAKANAN (IN-MEMORY)")
    print("=" * 70)
    
    hasil_online = {}
    for keyword in KATA_KUNCI_UJI:
        waktu_list = []
        jumlah_hasil = 0
        for _ in range(ITERASI_PER_QUERY):
            start = time.perf_counter()
            try:
                # Memanggil endpoint handler python langsung tanpa TCP HTTP request
                data = cari_makanan(q=keyword, page=0, limit=10)
                end = time.perf_counter()
                waktu_list.append((end - start) * 1000)
                jumlah_hasil = data.get("total_found", 0)
            except Exception as e:
                print(f"  ⚠️ Error '{keyword}': {e}")
                
        if waktu_list:
            hasil_online[keyword] = {
                "mean_ms": statistics.mean(waktu_list),
                "jumlah_hasil": jumlah_hasil
            }
            print(f"  ✅ '{keyword:<8}' → Rata-rata: {hasil_online[keyword]['mean_ms']:6.2f} ms | Hasil: {jumlah_hasil} item")
    return hasil_online

def uji_response_time_offline_direct():
    print("\n" + "=" * 70)
    print("  💾 BAGIAN 2: UJI LATENSI RAW SQLITE QUERY (OFFLINE MODE)")
    print("=" * 70)
    
    hasil_offline = {}
    for keyword in KATA_KUNCI_UJI:
        waktu_list = []
        jumlah_hasil = 0
        for _ in range(ITERASI_PER_QUERY):
            start = time.perf_counter()
            try:
                conn = sqlite3.connect(DB_NAME)
                conn.row_factory = sqlite3.Row
                cursor = conn.cursor()
                
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
                
                end = time.perf_counter()
                waktu_list.append((end - start) * 1000)
                jumlah_hasil = len(rows)
            except Exception as e:
                print(f"  ⚠️ Error '{keyword}': {e}")
                
        if waktu_list:
            hasil_offline[keyword] = {
                "mean_ms": statistics.mean(waktu_list),
                "jumlah_hasil": jumlah_hasil
            }
            print(f"  ✅ '{keyword:<8}' → Rata-rata: {hasil_offline[keyword]['mean_ms']:6.2f} ms | Hasil: {jumlah_hasil} item")
    return hasil_offline

def cetak_perbandingan(online, offline):
    print("\n")
    print("═" * 75)
    print("  📊 HASIL PERBANDINGAN LATENSI: ENDPOINT PROFILING VS RAW DATABASE QUERY")
    print("═" * 75)
    print(f"  {'Kata Kunci':<12} │ {'Endpoint API (ms)':>18} │ {'Raw SQLite (ms)':>16} │ {'Overhead':>10}")
    print(f"  {'─' * 12}─┼─{'─' * 18}─┼─{'─' * 16}─┼─{'─' * 10}")
    
    total_on = []
    total_off = []
    
    for kw in KATA_KUNCI_UJI:
        on = online.get(kw)
        off = offline.get(kw)
        if on and off:
            on_ms = on["mean_ms"]
            off_ms = off["mean_ms"]
            overhead = on_ms - off_ms
            total_on.append(on_ms)
            total_off.append(off_ms)
            print(f"  {kw:<12} │ {on_ms:>16.2f} ms │ {off_ms:>14.2f} ms │ {overhead:>8.2f} ms")
            
    print(f"  {'─' * 12}─┼─{'─' * 18}─┼─{'─' * 16}─┼─{'─' * 10}")
    avg_on = statistics.mean(total_on)
    avg_off = statistics.mean(total_off)
    print(f"  {'RATA-RATA':<12} │ {avg_on:>16.2f} ms │ {avg_off:>14.2f} ms │ {avg_on - avg_off:>8.2f} ms")
    print("═" * 75)

if __name__ == "__main__":
    on_res = uji_response_time_online_direct()
    off_res = uji_response_time_offline_direct()
    cetak_perbandingan(on_res, off_res)
