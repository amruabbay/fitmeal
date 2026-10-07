"""
=============================================================================
🗄️ DATABASE INTEGRITY TESTING — Sistem Fit Meal
=============================================================================
Menguji kualitas dan integritas data di database SQLite (skripsi_diet.db).

Yang diuji:
  1. Struktur tabel (field wajib ada)
  2. Data null / kosong
  3. Data duplikat
  4. Nilai nutrisi valid (tidak negatif, tidak absurd)
  5. Kategori valid
  6. Konsistensi ID
  7. Whitelist coverage

Cara menjalankan:
  python test_database.py
=============================================================================
"""

import sqlite3
import os
from datetime import datetime

DB_NAME = "skripsi_diet.db"

# Warna terminal
GREEN  = "\033[92m"
RED    = "\033[91m"
YELLOW = "\033[93m"
CYAN   = "\033[96m"
BOLD   = "\033[1m"
RESET  = "\033[0m"
DIM    = "\033[2m"

total_tests  = 0
passed_tests = 0
failed_tests = 0
results_log  = []


def assert_test(test_id, deskripsi, condition, expected="", actual="", detail=""):
    global total_tests, passed_tests, failed_tests
    total_tests += 1

    if condition:
        passed_tests += 1
        icon = f"{GREEN}✅ PASS{RESET}"
        status = "PASS"
    else:
        failed_tests += 1
        icon = f"{RED}❌ FAIL{RESET}"
        status = "FAIL"

    results_log.append({
        "id": test_id, "deskripsi": deskripsi, "status": status,
        "expected": str(expected), "actual": str(actual), "detail": detail
    })

    print(f"  {icon}  [{test_id}] {deskripsi}")
    if status == "FAIL":
        print(f"       {DIM}→ Expected: {expected}{RESET}")
        print(f"       {DIM}→ Actual  : {actual}{RESET}")
        if detail:
            print(f"       {DIM}→ Detail  : {detail}{RESET}")


def print_section(title):
    print(f"\n{'='*65}")
    print(f"  {BOLD}{CYAN}{title}{RESET}")
    print(f"{'='*65}")


def main():
    print(f"\n{BOLD}{CYAN}")
    print("╔═══════════════════════════════════════════════════════════════╗")
    print("║       🗄️ DATABASE INTEGRITY TESTING — FIT MEAL              ║")
    print("║       Validasi Kualitas Data SQLite                         ║")
    print("╚═══════════════════════════════════════════════════════════════╝")
    print(f"{RESET}")

    # Cek file database
    if not os.path.exists(DB_NAME):
        print(f"  {RED}❌ File database '{DB_NAME}' tidak ditemukan!{RESET}")
        return

    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    # ==========================================
    # TEST 1: STRUKTUR DATABASE
    # ==========================================
    print_section("TEST 1: Struktur Database")

    # DB-01: Tabel food_cache ada
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='food_cache'")
    table_exists = cursor.fetchone() is not None
    assert_test("DB-01", "Tabel 'food_cache' ada di database",
                table_exists, "ada", "ada" if table_exists else "tidak ada")

    if not table_exists:
        print(f"  {RED}Tabel tidak ada, menghentikan pengujian.{RESET}")
        conn.close()
        return

    # DB-02: Field wajib ada
    cursor.execute("PRAGMA table_info(food_cache)")
    columns = [col['name'] for col in cursor.fetchall()]
    required_cols = ['fatsecret_id', 'nama_makanan', 'kalori', 'protein', 'karbo', 'lemak', 'kategori']
    missing = [c for c in required_cols if c not in columns]
    assert_test("DB-02", "Semua field wajib ada (fatsecret_id, nama_makanan, kalori, dll)",
                len(missing) == 0, str(required_cols), str(columns),
                f"Missing: {missing}" if missing else "")

    # DB-03: Total data > 0
    cursor.execute("SELECT COUNT(*) as cnt FROM food_cache")
    total_rows = cursor.fetchone()['cnt']
    assert_test("DB-03", f"Database memiliki data (total: {total_rows} rows)",
                total_rows > 0, "> 0", total_rows)

    # ==========================================
    # TEST 2: DATA NULL / KOSONG
    # ==========================================
    print_section("TEST 2: Data Null / Kosong")

    # DB-04: Tidak ada nama_makanan NULL
    cursor.execute("SELECT COUNT(*) as cnt FROM food_cache WHERE nama_makanan IS NULL")
    null_names = cursor.fetchone()['cnt']
    assert_test("DB-04", "Tidak ada nama_makanan NULL",
                null_names == 0, "0 null", f"{null_names} null")

    # DB-05: Tidak ada nama_makanan kosong ('')
    cursor.execute("SELECT COUNT(*) as cnt FROM food_cache WHERE TRIM(nama_makanan) = ''")
    empty_names = cursor.fetchone()['cnt']
    assert_test("DB-05", "Tidak ada nama_makanan kosong ('')",
                empty_names == 0, "0 kosong", f"{empty_names} kosong")

    # DB-06: Tidak ada kalori NULL
    cursor.execute("SELECT COUNT(*) as cnt FROM food_cache WHERE kalori IS NULL")
    null_kal = cursor.fetchone()['cnt']
    assert_test("DB-06", "Tidak ada kalori NULL",
                null_kal == 0, "0 null", f"{null_kal} null")

    # DB-07: Tidak ada kategori NULL
    cursor.execute("SELECT COUNT(*) as cnt FROM food_cache WHERE kategori IS NULL")
    null_kat = cursor.fetchone()['cnt']
    assert_test("DB-07", "Tidak ada kategori NULL",
                null_kat == 0, "0 null", f"{null_kat} null")

    # ==========================================
    # TEST 3: DATA DUPLIKAT
    # ==========================================
    print_section("TEST 3: Data Duplikat")

    # DB-08: Tidak ada fatsecret_id duplikat
    cursor.execute("""
        SELECT fatsecret_id, COUNT(*) as cnt 
        FROM food_cache 
        GROUP BY fatsecret_id 
        HAVING cnt > 1
    """)
    dup_ids = cursor.fetchall()
    assert_test("DB-08", "Tidak ada fatsecret_id duplikat",
                len(dup_ids) == 0, "0 duplikat", f"{len(dup_ids)} duplikat",
                f"IDs: {[d['fatsecret_id'] for d in dup_ids[:5]]}" if dup_ids else "")

    # DB-09: Tidak ada nama_makanan + kategori duplikat
    cursor.execute("""
        SELECT nama_makanan, kategori, COUNT(*) as cnt 
        FROM food_cache 
        GROUP BY nama_makanan, kategori 
        HAVING cnt > 1
    """)
    dup_names = cursor.fetchall()
    assert_test("DB-09", "Tidak ada duplikat nama_makanan+kategori",
                len(dup_names) == 0, "0 duplikat", f"{len(dup_names)} duplikat",
                f"Contoh: {[d['nama_makanan'] for d in dup_names[:3]]}" if dup_names else "")

    # ==========================================
    # TEST 4: NILAI NUTRISI VALID
    # ==========================================
    print_section("TEST 4: Nilai Nutrisi Valid")

    # DB-10: Tidak ada kalori negatif
    cursor.execute("SELECT COUNT(*) as cnt FROM food_cache WHERE kalori < 0")
    neg_kal = cursor.fetchone()['cnt']
    assert_test("DB-10", "Tidak ada kalori negatif",
                neg_kal == 0, "0 negatif", f"{neg_kal} negatif")

    # DB-11: Tidak ada protein negatif
    cursor.execute("SELECT COUNT(*) as cnt FROM food_cache WHERE protein < 0")
    neg_prot = cursor.fetchone()['cnt']
    assert_test("DB-11", "Tidak ada protein negatif",
                neg_prot == 0, "0 negatif", f"{neg_prot} negatif")

    # DB-12: Tidak ada karbo negatif
    cursor.execute("SELECT COUNT(*) as cnt FROM food_cache WHERE karbo < 0")
    neg_carb = cursor.fetchone()['cnt']
    assert_test("DB-12", "Tidak ada karbo negatif",
                neg_carb == 0, "0 negatif", f"{neg_carb} negatif")

    # DB-13: Tidak ada lemak negatif
    cursor.execute("SELECT COUNT(*) as cnt FROM food_cache WHERE lemak < 0")
    neg_fat = cursor.fetchone()['cnt']
    assert_test("DB-13", "Tidak ada lemak negatif",
                neg_fat == 0, "0 negatif", f"{neg_fat} negatif")

    # DB-14: Tidak ada kalori absurd (> 2000 per item)
    cursor.execute("SELECT COUNT(*) as cnt FROM food_cache WHERE kalori > 2000")
    absurd_kal = cursor.fetchone()['cnt']
    assert_test("DB-14", "Tidak ada kalori absurd (> 2000 kkal per item)",
                absurd_kal == 0, "0 absurd", f"{absurd_kal} items",
                "Makanan per porsi tidak seharusnya > 2000 kkal")

    # DB-15: Tidak ada item dengan semua nutrisi = 0
    cursor.execute("""
        SELECT COUNT(*) as cnt FROM food_cache 
        WHERE kalori = 0 AND protein = 0 AND karbo = 0 AND lemak = 0
    """)
    all_zero = cursor.fetchone()['cnt']
    assert_test("DB-15", "Tidak ada item dengan semua nutrisi = 0",
                all_zero == 0, "0 items", f"{all_zero} items",
                "Data tanpa nutrisi tidak berguna")

    # DB-16: Rata-rata kalori dalam range wajar (50-500 per item)
    cursor.execute("SELECT AVG(kalori) as avg_kal FROM food_cache")
    avg_kal = cursor.fetchone()['avg_kal']
    assert_test("DB-16", f"Rata-rata kalori dalam range wajar ({avg_kal:.1f} kkal)",
                50 <= avg_kal <= 500, "50-500 kkal", f"{avg_kal:.1f} kkal")

    # ==========================================
    # TEST 5: KATEGORI VALID
    # ==========================================
    print_section("TEST 5: Kategori Valid")

    valid_categories = {'Karbo', 'Hewani', 'Nabati', 'Sayur', 'Buah'}

    # DB-17: Semua kategori yang ada di DB termasuk valid
    cursor.execute("SELECT DISTINCT kategori FROM food_cache")
    db_categories = set(row['kategori'] for row in cursor.fetchall())
    invalid_cats = db_categories - valid_categories
    assert_test("DB-17", "Semua kategori di DB adalah valid",
                len(invalid_cats) == 0, str(valid_categories), str(db_categories),
                f"Invalid: {invalid_cats}" if invalid_cats else "")

    # DB-18: Distribusi kategori tidak kosong
    for cat in valid_categories:
        cursor.execute("SELECT COUNT(*) as cnt FROM food_cache WHERE kategori = ?", (cat,))
        cat_count = cursor.fetchone()['cnt']
        assert_test(f"DB-18-{cat[:3].upper()}", f"Kategori '{cat}' memiliki data ({cat_count} items)",
                    cat_count > 0, "> 0", cat_count)

    # ==========================================
    # TEST 6: KONSISTENSI DATA
    # ==========================================
    print_section("TEST 6: Konsistensi Data")

    # DB-19: Semua fatsecret_id > 0
    cursor.execute("SELECT COUNT(*) as cnt FROM food_cache WHERE fatsecret_id <= 0")
    bad_ids = cursor.fetchone()['cnt']
    assert_test("DB-19", "Semua fatsecret_id > 0",
                bad_ids == 0, "0 invalid", f"{bad_ids} invalid")

    # DB-20: Panjang nama_makanan wajar (3-200 karakter)
    cursor.execute("""
        SELECT COUNT(*) as cnt FROM food_cache 
        WHERE LENGTH(nama_makanan) < 3 OR LENGTH(nama_makanan) > 200
    """)
    bad_names = cursor.fetchone()['cnt']
    assert_test("DB-20", "Panjang nama_makanan antara 3-200 karakter",
                bad_names == 0, "0 invalid", f"{bad_names} invalid")

    # DB-21: Ukuran file database wajar (< 50MB)
    db_size = os.path.getsize(DB_NAME) / (1024 * 1024)  # MB
    assert_test("DB-21", f"Ukuran database wajar ({db_size:.2f} MB, limit 50MB)",
                db_size < 50, "< 50 MB", f"{db_size:.2f} MB")

    # ==========================================
    # STATISTIK DATABASE
    # ==========================================
    print_section("📊 Statistik Database")

    cursor.execute("SELECT COUNT(*) as cnt FROM food_cache")
    total = cursor.fetchone()['cnt']
    print(f"  Total data      : {total} rows")

    cursor.execute("SELECT kategori, COUNT(*) as cnt FROM food_cache GROUP BY kategori ORDER BY cnt DESC")
    for row in cursor.fetchall():
        print(f"  {row['kategori']:<15}: {row['cnt']} items")

    cursor.execute("SELECT AVG(kalori) as a, MIN(kalori) as mi, MAX(kalori) as ma FROM food_cache")
    stats = cursor.fetchone()
    print(f"\n  Kalori — Avg: {stats['a']:.1f} | Min: {stats['mi']:.1f} | Max: {stats['ma']:.1f}")

    cursor.execute("SELECT AVG(protein) as a, MIN(protein) as mi, MAX(protein) as ma FROM food_cache")
    stats = cursor.fetchone()
    print(f"  Protein — Avg: {stats['a']:.1f} | Min: {stats['mi']:.1f} | Max: {stats['ma']:.1f}")

    print(f"\n  Ukuran file     : {db_size:.2f} MB")

    conn.close()

    # Laporan Akhir
    print_final_report()


def print_final_report():
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    print(f"\n{'='*65}")
    print(f"  {BOLD}{CYAN}📋 LAPORAN HASIL DATABASE INTEGRITY TESTING{RESET}")
    print(f"{'='*65}")
    print(f"  Waktu Pengujian : {timestamp}")
    print(f"  Total Test Case : {total_tests}")
    print(f"  {GREEN}✅ PASS : {passed_tests}{RESET}")
    print(f"  {RED}❌ FAIL : {failed_tests}{RESET}")

    if total_tests > 0:
        pass_rate = (passed_tests / total_tests) * 100
        color = GREEN if pass_rate >= 90 else (YELLOW if pass_rate >= 70 else RED)
        print(f"\n  {BOLD}Pass Rate: {color}{pass_rate:.1f}%{RESET}")
    print(f"{'='*65}")

    fails = [r for r in results_log if r["status"] == "FAIL"]
    if fails:
        print(f"\n  {RED}{BOLD}⚠️ Test Case yang GAGAL:{RESET}")
        for f in fails:
            print(f"    {RED}• [{f['id']}] {f['deskripsi']}{RESET}")

    # Export
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"hasil_database_testing_{ts}.txt"
    try:
        with open(filename, "w", encoding="utf-8") as f:
            f.write("=" * 70 + "\n")
            f.write("  LAPORAN DATABASE INTEGRITY TESTING — SISTEM FIT MEAL\n")
            f.write("=" * 70 + "\n\n")
            f.write(f"  Waktu      : {timestamp}\n")
            f.write(f"  Database   : {DB_NAME}\n")
            f.write(f"  Total Test : {total_tests}\n")
            f.write(f"  Pass       : {passed_tests}\n")
            f.write(f"  Fail       : {failed_tests}\n")
            if total_tests > 0:
                f.write(f"  Pass Rate  : {(passed_tests/total_tests)*100:.1f}%\n")
            f.write(f"\n{'='*70}\n  DETAIL\n{'='*70}\n\n")
            f.write(f"{'No':<5} {'ID':<12} {'Status':<8} {'Deskripsi'}\n")
            f.write("-" * 70 + "\n")
            for idx, r in enumerate(results_log, 1):
                f.write(f"{idx:<5} {r['id']:<12} {r['status']:<8} {r['deskripsi']}\n")
                if r['status'] == "FAIL":
                    f.write(f"{'':>5} {'':>12} → Expected: {r['expected']}\n")
                    f.write(f"{'':>5} {'':>12} → Actual  : {r['actual']}\n")
            f.write(f"\n  [END OF REPORT]\n")
        print(f"\n  📄 Laporan disimpan ke: {CYAN}{filename}{RESET}")
    except Exception as e:
        print(f"  ⚠️ Gagal simpan: {e}")


if __name__ == "__main__":
    main()
