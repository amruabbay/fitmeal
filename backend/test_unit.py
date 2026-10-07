"""
=============================================================================
🧪 WHITEBOX / UNIT TESTING — Algoritma Fit Meal
=============================================================================
Pengujian langsung fungsi-fungsi internal algoritma (tanpa melalui API).

Yang diuji:
  1. hitung_macro_targets() — Perhitungan target macro nutrisi
  2. susun_menu_berdasarkan_batasan() — Aturan komposisi menu
  3. ambil_data_lokal()     — Whitelist filter dari database
  4. hitung_kalori_user()   — Perhitungan BMR & TDEE
  5. jalankan_algoritma()   — Integrasi Constraint-Based Filtering
  6. hitung_skor_relevansi()— Scoring relevansi pencarian

Cara menjalankan:
  python test_unit.py
=============================================================================
"""

import sys
import os
import math

# Import modul yang diuji
from algoritma import (
    hitung_macro_targets, susun_menu_berdasarkan_batasan,
    ambil_data_lokal, jalankan_algoritma, WHITELIST
)
from main import hitung_kalori_user, hitung_skor_relevansi, is_junk_food, UserData
from utils import parsing_deskripsi_fatsecret

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
    """Helper untuk mencatat hasil test."""
    global total_tests, passed_tests, failed_tests
    total_tests += 1

    if condition:
        passed_tests += 1
        status = "PASS"
        icon = f"{GREEN}✅ PASS{RESET}"
    else:
        failed_tests += 1
        status = "FAIL"
        icon = f"{RED}❌ FAIL{RESET}"

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


# ==========================================
# UNIT TEST 1: hitung_macro_targets
# ==========================================
def test_hitung_macro_targets():
    print_section("UNIT TEST 1: hitung_macro_targets()")

    # UT-01: Target macro untuk 2000 kkal, protein 140g
    result = hitung_macro_targets(2000, 140)
    assert_test("UT-01", "Kalori target tetap 2000",
                result['kalori'] == 2000, 2000, result['kalori'])

    # UT-02: Protein target tetap 140
    assert_test("UT-02", "Protein target tetap 140g",
                result['protein'] == 140, 140, result['protein'])

    # UT-03: Karbo + Lemak + Protein = Total Kalori (approx)
    total_from_macro = (result['protein'] * 4) + (result['karbo'] * 4) + (result['lemak'] * 9)
    diff = abs(total_from_macro - 2000)
    assert_test("UT-03", f"Rekalkulasi macro ≈ 2000 kkal (diff={diff:.1f})",
                diff < 10, "< 10 kkal diff", f"{total_from_macro:.1f} kkal")

    # UT-04: Karbo > 0 (harus positif)
    assert_test("UT-04", "Karbo > 0",
                result['karbo'] > 0, "> 0", result['karbo'])

    # UT-05: Lemak > 0 (harus positif)
    assert_test("UT-05", "Lemak > 0",
                result['lemak'] > 0, "> 0", result['lemak'])

    # UT-06: Edge case — kalori 0
    result_zero = hitung_macro_targets(0, 0)
    assert_test("UT-06", "Kalori 0 → semua macro = 0",
                result_zero['kalori'] == 0 and result_zero['karbo'] == 0,
                "semua 0", str(result_zero))

    # UT-07: Edge case — protein sangat tinggi (melebihi kalori)
    result_high = hitung_macro_targets(500, 200)
    assert_test("UT-07", "Protein > kalori → karbo & lemak ≥ 0 (tidak negatif)",
                result_high['karbo'] >= 0 and result_high['lemak'] >= 0,
                ">= 0", f"karbo={result_high['karbo']}, lemak={result_high['lemak']}")


# ==========================================
# UNIT TEST 2: Constraint-Based Filtering
# ==========================================
def test_constraint_based_filtering():
    print_section("UNIT TEST 2: susun_menu_berdasarkan_batasan()")
    dataset = ambil_data_lokal()
    menu = susun_menu_berdasarkan_batasan(dataset, 2000)
    items = [item for meal in menu for item in meal['isi']]
    total = sum(item['kalori'] for item in items)
    ids = [item['id'] for item in items]

    assert_test("UT-08", "Menghasilkan tiga waktu makan",
                len(menu) == 3, 3, len(menu))
    assert_test("UT-09", "Total energi tidak melampaui target",
                total <= 2000, "<= 2000", total)
    assert_test("UT-10", "Item menu tidak berulang",
                len(ids) == len(set(ids)), "unique", ids)

    menu_repeat = susun_menu_berdasarkan_batasan(dataset, 2000)
    repeat_ids = [item['id'] for meal in menu_repeat for item in meal['isi']]
    assert_test("UT-11", "Aturan menghasilkan keluaran deterministik",
                ids == repeat_ids, ids, repeat_ids)


# ==========================================
# UNIT TEST 3: hitung_kalori_user (BMR & TDEE)
# ==========================================
def test_hitung_kalori_user():
    print_section("UNIT TEST 3: hitung_kalori_user() — BMR & TDEE")

    # UT-12: Pria sedentary maintain
    user = UserData(berat=70, tinggi=170, umur=25, gender="pria", goal="maintain", activity="sedentary")
    target, protein = hitung_kalori_user(user)
    # BMR = (10×70) + (6.25×170) - (5×25) + 5 = 700 + 1062.5 - 125 + 5 = 1642.5
    # TDEE = 1642.5 × 1.2 = 1971
    expected_tdee = round(((10 * 70) + (6.25 * 170) - (5 * 25) + 5) * 1.2)
    assert_test("UT-12", f"TDEE Pria Sedentary = {expected_tdee} kkal",
                abs(target - expected_tdee) < 5, expected_tdee, round(target))

    # UT-13: Protein = 2× berat badan
    assert_test("UT-13", "Protein = 2× berat badan (140g)",
                protein == 140, 140, protein)

    # UT-14: Cutting mengurangi 500 kkal
    user_cut = UserData(berat=70, tinggi=170, umur=25, gender="pria", goal="cutting", activity="sedentary")
    target_cut, _ = hitung_kalori_user(user_cut)
    expected_cut = max(expected_tdee - 500, 1642.5)
    assert_test("UT-14", "Cutting: max(TDEE - 500, BMR)",
                abs(target_cut - expected_cut) < 5,
                expected_cut, round(target_cut))

    # UT-15: Bulking menambah 400 kkal
    user_bulk = UserData(berat=70, tinggi=170, umur=25, gender="pria", goal="bulking", activity="sedentary")
    target_bulk, _ = hitung_kalori_user(user_bulk)
    assert_test("UT-15", "Bulking: TDEE + 400 kkal",
                abs(target_bulk - (expected_tdee + 400)) < 5,
                expected_tdee + 400, round(target_bulk))

    # UT-16: Wanita BMR lebih rendah dari Pria (sama BB/TB/Umur)
    user_w = UserData(berat=70, tinggi=170, umur=25, gender="wanita", goal="maintain", activity="sedentary")
    target_w, _ = hitung_kalori_user(user_w)
    assert_test("UT-16", "Wanita TDEE < Pria TDEE (input sama)",
                target_w < target, f"< {round(target)}", round(target_w))

    # UT-17: Active > Moderate > Sedentary
    user_mod = UserData(berat=70, tinggi=170, umur=25, gender="pria", goal="maintain", activity="moderate")
    user_act = UserData(berat=70, tinggi=170, umur=25, gender="pria", goal="maintain", activity="active")
    target_mod, _ = hitung_kalori_user(user_mod)
    target_act, _ = hitung_kalori_user(user_act)
    assert_test("UT-17", "Active > Moderate > Sedentary (TDEE ordering)",
                target_act > target_mod > target,
                f"{round(target_act)} > {round(target_mod)} > {round(target)}",
                f"Active={round(target_act)}, Moderate={round(target_mod)}, Sedentary={round(target)}")


# ==========================================
# UNIT TEST 4: susun menu & ambil_data_lokal
# ==========================================
def test_susun_piring():
    print_section("UNIT TEST 4: susun menu & ambil_data_lokal()")

    dataset = ambil_data_lokal()

    # UT-18: Dataset memiliki 5 kategori
    assert_test("UT-18", "Dataset memiliki 5 kategori (Karbo, Hewani, Nabati, Sayur, Buah)",
                len(dataset) == 5, 5, len(dataset))

    # UT-19: Setiap kategori punya minimal 1 item
    all_have_items = all(len(items) > 0 for items in dataset.values())
    counts = {k: len(v) for k, v in dataset.items()}
    assert_test("UT-19", "Setiap kategori memiliki ≥ 1 item",
                all_have_items, "semua > 0", str(counts))

    # UT-20: Menu yang disusun memiliki item
    menu = susun_menu_berdasarkan_batasan(dataset, 2000)
    piring = [item for meal in menu for item in meal['isi']]
    assert_test("UT-20", "Penyaringan menghasilkan ≥ 1 item",
                len(piring) >= 1, ">= 1 item", f"{len(piring)} item")

    # UT-21: Tidak ada duplikat ID di piring
    ids = [item['id'] for item in piring]
    assert_test("UT-21", "Tidak ada duplikat ID dalam satu piring",
                len(ids) == len(set(ids)), "unique IDs", f"total={len(ids)}, unique={len(set(ids))}")

    # UT-22: Semua item piring punya field nutrisi
    required = {'nama_makanan', 'kalori', 'protein', 'karbo', 'lemak'}
    all_valid = all(required.issubset(set(item.keys())) for item in piring)
    assert_test("UT-22", "Semua item piring punya field nutrisi lengkap",
                all_valid, str(required), "valid" if all_valid else "missing fields")

    # UT-23: Tidak ada item dengan kalori > 600 (whitelist filter)
    max_kal = max(item['kalori'] for item in piring) if piring else 0
    assert_test("UT-23", "Tidak ada item dengan kalori > 600 (whitelist filter)",
                max_kal <= 600, "<= 600 kkal", f"max={max_kal:.1f} kkal")


# ==========================================
# UNIT TEST 5: hard constraints
# ==========================================
def test_hard_constraints():
    print_section("UNIT TEST 5: hard constraints")
    menu, stats = jalankan_algoritma(2000, 140)
    items = [item for meal in menu for item in meal['isi']]

    assert_test("UT-24", "Metadata algoritma hanya Constraint-Based Filtering",
                stats.get('algorithm') == 'Constraint-Based Filtering',
                'Constraint-Based Filtering', stats.get('algorithm'))
    assert_test("UT-25", "Hard constraint UPF tercatat aktif",
                stats.get('constraints', {}).get('upf_excluded') is True,
                True, stats.get('constraints'))
    assert_test("UT-26", "Total menu tidak melebihi batas energi harian",
                sum(item['kalori'] for item in items) <= 2000,
                '<= 2000', sum(item['kalori'] for item in items))


# ==========================================
# UNIT TEST 6: jalankan_algoritma (Integrasi)
# ==========================================
def test_jalankan_algoritma():
    print_section("UNIT TEST 6: jalankan_algoritma() — Constraint-Based Filtering")

    # UT-27: Algoritma menghasilkan menu (tidak kosong)
    menu, stats = jalankan_algoritma(2000, 140)
    assert_test("UT-27", "Algoritma menghasilkan menu (bukan [])",
                len(menu) == 3, "3 meals", f"{len(menu)} meals")

    # UT-28: Menu memiliki Pagi, Siang, Malam
    waktu_list = [m['waktu'] for m in menu]
    assert_test("UT-28", "Menu: Pagi, Siang, Malam",
                waktu_list == ["Pagi", "Siang", "Malam"],
                ["Pagi", "Siang", "Malam"], waktu_list)

    # UT-29: Stats memiliki accuracy_pct
    has_accuracy = 'accuracy_pct' in stats
    assert_test("UT-29", "Stats memiliki field 'accuracy_pct'",
                has_accuracy, "ada", "ada" if has_accuracy else "tidak ada")

    # UT-30: Akurasi kalori > 80%
    if has_accuracy:
        kal_acc = stats['accuracy_pct'].get('kalori', 0)
        assert_test("UT-30", f"Akurasi kalori = {kal_acc}% (harus > 80%)",
                    kal_acc > 80, "> 80%", f"{kal_acc}%")
    else:
        assert_test("UT-30", "Akurasi kalori > 80%", False, "> 80%", "N/A")

    # UT-31: Excluded foods benar-benar tidak muncul
    menu2, stats2 = jalankan_algoritma(2000, 140, excluded_set={"nasi putih (1 centong)"})
    all_items = []
    for m in menu2:
        all_items.extend(m.get('isi', []))
    found_excluded = any("nasi putih (1 centong)" in item['nama_makanan'].lower() for item in all_items)
    assert_test("UT-31", "Excluded food 'nasi putih (1 centong)' tidak muncul di menu",
                not found_excluded, "tidak ditemukan",
                "tidak ditemukan" if not found_excluded else "DITEMUKAN!")


# ==========================================
# UNIT TEST 7: Scoring Relevansi & Junk Food Filter
# ==========================================
def test_scoring_dan_filter():
    print_section("UNIT TEST 7: Scoring Relevansi & Filter")

    # UT-32: Exact match skor tertinggi
    score_exact = hitung_skor_relevansi("nasi putih", "nasi putih")
    score_partial = hitung_skor_relevansi("nasi putih goreng mentega", "nasi putih")
    assert_test("UT-32", "Exact match skor > partial match",
                score_exact > score_partial, f"> {score_partial}", score_exact)

    # UT-33: Starts with skor > random position
    score_starts = hitung_skor_relevansi("nasi goreng", "nasi")
    score_middle = hitung_skor_relevansi("bungkus nasi goreng", "nasi")
    assert_test("UT-33", "'nasi goreng' skor > 'bungkus nasi goreng' untuk query 'nasi'",
                score_starts > score_middle, f"> {score_middle}", score_starts)

    # UT-34: is_junk_food — detect junk food
    assert_test("UT-34", "is_junk_food('Indomie Goreng') = True",
                is_junk_food("Indomie Goreng") == True, True, is_junk_food("Indomie Goreng"))

    # UT-35: is_junk_food — healthy food
    assert_test("UT-35", "is_junk_food('Nasi Putih') = False",
                is_junk_food("Nasi Putih") == False, False, is_junk_food("Nasi Putih"))

    # UT-36: is_junk_food — semua keyword terdeteksi
    junk_samples = ["Pop Mie", "Chitato", "Coca-Cola", "Samyang", "Cheetos"]
    all_detected = all(is_junk_food(j) for j in junk_samples)
    assert_test("UT-36", "Semua junk food sample terdeteksi",
                all_detected, "semua True", "semua True" if all_detected else "ada yang lolos")


# ==========================================
# UNIT TEST 8: parsing_deskripsi_fatsecret (utils)
# ==========================================
def test_parsing_utils():
    print_section("UNIT TEST 8: parsing_deskripsi_fatsecret()")

    # UT-37: Parsing normal
    desc = "Per 100g - Calories: 165kcal | Fat: 3.60g | Carbs: 0.00g | Protein: 31.00g"
    result = parsing_deskripsi_fatsecret(desc)
    assert_test("UT-37", "Parsing normal → kalori = 165.0",
                result['kalori'] == 165.0, 165.0, result['kalori'])

    # UT-38: Parsing protein
    assert_test("UT-38", "Parsing normal → protein = 31.0",
                result['protein'] == 31.0, 31.0, result['protein'])

    # UT-39: Parsing string kosong → default 0
    result_empty = parsing_deskripsi_fatsecret("")
    all_zero = all(v == 0.0 for v in result_empty.values())
    assert_test("UT-39", "String kosong → semua nutrisi = 0",
                all_zero, "semua 0", str(result_empty))

    # UT-40: Parsing string random → tidak crash, return default
    result_random = parsing_deskripsi_fatsecret("hello world random text 123")
    assert_test("UT-40", "String random → tidak crash, return dict",
                isinstance(result_random, dict), "dict", type(result_random).__name__)


# ==========================================
# 📋 LAPORAN AKHIR
# ==========================================
def print_final_report():
    from datetime import datetime

    print(f"\n{'='*65}")
    print(f"  {BOLD}{CYAN}📋 LAPORAN HASIL UNIT / WHITEBOX TESTING{RESET}")
    print(f"{'='*65}")

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
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
    filename = f"hasil_unit_testing_{ts}.txt"
    try:
        with open(filename, "w", encoding="utf-8") as f:
            f.write("=" * 70 + "\n")
            f.write("  LAPORAN HASIL UNIT / WHITEBOX TESTING — SISTEM FIT MEAL\n")
            f.write("=" * 70 + "\n\n")
            f.write(f"  Waktu      : {timestamp}\n")
            f.write(f"  Total Test : {total_tests}\n")
            f.write(f"  Pass       : {passed_tests}\n")
            f.write(f"  Fail       : {failed_tests}\n")
            if total_tests > 0:
                f.write(f"  Pass Rate  : {(passed_tests/total_tests)*100:.1f}%\n")

            f.write(f"\n{'='*70}\n  DETAIL TEST CASE\n{'='*70}\n\n")
            f.write(f"{'No':<5} {'ID':<8} {'Status':<8} {'Deskripsi'}\n")
            f.write("-" * 70 + "\n")

            for idx, r in enumerate(results_log, 1):
                f.write(f"{idx:<5} {r['id']:<8} {r['status']:<8} {r['deskripsi']}\n")
                if r['status'] == "FAIL":
                    f.write(f"{'':>5} {'':>8} → Expected: {r['expected']}\n")
                    f.write(f"{'':>5} {'':>8} → Actual  : {r['actual']}\n")

            f.write(f"\n  [END OF REPORT]\n")
        print(f"\n  📄 Laporan disimpan ke: {CYAN}{filename}{RESET}")
    except Exception as e:
        print(f"  ⚠️ Gagal simpan: {e}")


# ==========================================
# 🚀 MAIN
# ==========================================
def main():
    print(f"\n{BOLD}{CYAN}")
    print("╔═══════════════════════════════════════════════════════════════╗")
    print("║       🧪 WHITEBOX / UNIT TESTING — FIT MEAL ALGORITHM       ║")
    print("║       Pengujian Fungsi Internal Sistem                      ║")
    print("╚═══════════════════════════════════════════════════════════════╝")
    print(f"{RESET}")

    test_hitung_macro_targets()
    test_constraint_based_filtering()
    test_hitung_kalori_user()
    test_susun_piring()
    test_hard_constraints()
    test_jalankan_algoritma()
    test_scoring_dan_filter()
    test_parsing_utils()

    print_final_report()


if __name__ == "__main__":
    main()
