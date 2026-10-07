import sqlite3
import time
import statistics

DB_NAME = "skripsi_diet.db"
KATA_KUNCI_UJI = [
    "nasi", "ayam", "tempe", "bayam", "pisang",
    "ikan", "roti", "telur", "kangkung", "jeruk"
]
ITERASI_PER_QUERY = 10

def uji_response_time_offline():
    print("=" * 70)
    print("  💾 UJI LATENSI PENCARIAN OFFLINE (SQLite Lokal via Python)")
    print("=" * 70)
    print(f"  Database  : {DB_NAME}")
    print(f"  Iterasi   : {ITERASI_PER_QUERY}× per kata kunci")
    print()

    hasil_offline = {}
    total_waktu_semua = []

    for keyword in KATA_KUNCI_UJI:
        waktu_list = []
        jumlah_hasil = 0

        for i in range(ITERASI_PER_QUERY):
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
                elapsed_ms = (end - start) * 1000
                waktu_list.append(elapsed_ms)
                if i == 0:
                    jumlah_hasil = len(rows)
            except Exception as e:
                print(f"  ⚠️ Error '{keyword}': {e}")
                continue

        if waktu_list:
            mean_ms = statistics.mean(waktu_list)
            total_waktu_semua.append(mean_ms)
            hasil_offline[keyword] = {
                "mean_ms": mean_ms,
                "min_ms": min(waktu_list),
                "max_ms": max(waktu_list),
                "jumlah_hasil": jumlah_hasil
            }
            print(f"  ✅ '{keyword:<8}' → Rata-rata: {mean_ms:6.2f} ms | Min: {min(waktu_list):6.2f} ms | Max: {max(waktu_list):6.2f} ms | Hasil: {jumlah_hasil} item")

    if total_waktu_semua:
        print("\n" + "=" * 70)
        print("  📈 KESIMPULAN PERFORMA OFFLINE:")
        print("=" * 70)
        print(f"  Rata-rata Latensi Global : {statistics.mean(total_waktu_semua):.2f} ms")
        print(f"  Pencarian Tercepat       : {min(total_waktu_semua):.2f} ms")
        print(f"  Pencarian Terlambat      : {max(total_waktu_semua):.2f} ms")
        print("=" * 70)

if __name__ == "__main__":
    uji_response_time_offline()
