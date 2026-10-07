"""
=============================================================================
🧪 BLACKBOX TESTING — Sistem Rekomendasi Menu Diet "Fit Meal"
=============================================================================
Skrip ini melakukan pengujian blackbox (tanpa melihat kode internal)
terhadap seluruh endpoint API FastAPI backend Fit Meal.

Teknik yang digunakan:
  1. Equivalence Partitioning (EP)  — Membagi input ke kelas valid & invalid
  2. Boundary Value Analysis (BVA)  — Menguji batas-batas input
  3. Error Guessing (EG)            — Menguji kasus error yang mungkin terjadi

Endpoint yang diuji:
  - GET  /              → Health check
  - GET  /search?q=...  → Pencarian makanan
  - POST /rekomendasi   → Generate menu diet harian

Cara menjalankan:
  1. Pastikan server berjalan: python main.py
  2. Jalankan tes: python test_blackbox.py
=============================================================================
"""

import requests
import json
import time
import sys
from datetime import datetime

# ==========================================
# ⚙️ KONFIGURASI
# ==========================================
BASE_URL = "http://127.0.0.1:9090"

# Warna terminal (ANSI)
GREEN  = "\033[92m"
RED    = "\033[91m"
YELLOW = "\033[93m"
CYAN   = "\033[96m"
BOLD   = "\033[1m"
RESET  = "\033[0m"
DIM    = "\033[2m"

# ==========================================
# 📊 COUNTER HASIL
# ==========================================
total_tests  = 0
passed_tests = 0
failed_tests = 0
skipped_tests = 0
results_log  = []


def log_result(test_id, kategori, deskripsi, expected, actual, status, detail=""):
    """Catat hasil setiap test case."""
    global total_tests, passed_tests, failed_tests, skipped_tests

    total_tests += 1

    if status == "PASS":
        passed_tests += 1
        icon = f"{GREEN}✅ PASS{RESET}"
    elif status == "FAIL":
        failed_tests += 1
        icon = f"{RED}❌ FAIL{RESET}"
    else:
        skipped_tests += 1
        icon = f"{YELLOW}⚠️ SKIP{RESET}"

    results_log.append({
        "id": test_id,
        "kategori": kategori,
        "deskripsi": deskripsi,
        "expected": expected,
        "actual": actual,
        "status": status,
        "detail": detail,
    })

    print(f"  {icon}  [{test_id}] {deskripsi}")
    if status == "FAIL" and detail:
        print(f"       {DIM}→ Expected: {expected}{RESET}")
        print(f"       {DIM}→ Actual  : {actual}{RESET}")
        if detail:
            print(f"       {DIM}→ Detail  : {detail}{RESET}")


def print_section(title):
    """Header untuk setiap section pengujian."""
    print(f"\n{'='*65}")
    print(f"  {BOLD}{CYAN}{title}{RESET}")
    print(f"{'='*65}")


# ==========================================
# 🧪 TEST SUITE 1: ENDPOINT GET / (Root)
# ==========================================
def test_root_endpoint():
    print_section("TEST SUITE 1: GET / — Health Check")

    # TC-01: Root endpoint harus merespons 200
    try:
        r = requests.get(f"{BASE_URL}/", timeout=5)
        status = "PASS" if r.status_code == 200 else "FAIL"
        log_result("TC-01", "Root", "Root endpoint merespons HTTP 200",
                   "status_code=200", f"status_code={r.status_code}", status)
    except Exception as e:
        log_result("TC-01", "Root", "Root endpoint merespons HTTP 200",
                   "status_code=200", str(e), "FAIL", "Server tidak bisa dihubungi")

    # TC-02: Response body berisi field 'message'
    try:
        r = requests.get(f"{BASE_URL}/", timeout=5)
        body = r.json()
        has_message = "message" in body
        status = "PASS" if has_message else "FAIL"
        log_result("TC-02", "Root", "Response body memiliki field 'message'",
                   "ada field 'message'", f"keys={list(body.keys())}", status)
    except Exception as e:
        log_result("TC-02", "Root", "Response body memiliki field 'message'",
                   "ada field 'message'", str(e), "FAIL")

    # TC-03: Response format JSON valid
    try:
        r = requests.get(f"{BASE_URL}/", timeout=5)
        content_type = r.headers.get("content-type", "")
        is_json = "application/json" in content_type
        status = "PASS" if is_json else "FAIL"
        log_result("TC-03", "Root", "Content-Type adalah application/json",
                   "application/json", content_type, status)
    except Exception as e:
        log_result("TC-03", "Root", "Content-Type adalah application/json",
                   "application/json", str(e), "FAIL")


# ==========================================
# 🧪 TEST SUITE 2: ENDPOINT GET /search
# ==========================================
def test_search_endpoint():
    print_section("TEST SUITE 2: GET /search — Pencarian Makanan")

    # ------ EQUIVALENCE PARTITIONING: Input Valid ------

    # TC-04: Pencarian dengan kata kunci umum "nasi"
    try:
        r = requests.get(f"{BASE_URL}/search", params={"q": "nasi"}, timeout=10)
        body = r.json()
        has_results = body.get("status") == "success" and len(body.get("results", [])) > 0
        status = "PASS" if has_results else "FAIL"
        count = len(body.get("results", []))
        log_result("TC-04", "Search", "Pencarian 'nasi' mengembalikan hasil",
                   "results > 0", f"results={count}", status)
    except Exception as e:
        log_result("TC-04", "Search", "Pencarian 'nasi' mengembalikan hasil",
                   "results > 0", str(e), "FAIL")

    # TC-05: Pencarian dengan kata kunci "ayam"
    try:
        r = requests.get(f"{BASE_URL}/search", params={"q": "ayam"}, timeout=10)
        body = r.json()
        has_results = body.get("status") == "success" and len(body.get("results", [])) > 0
        status = "PASS" if has_results else "FAIL"
        count = len(body.get("results", []))
        log_result("TC-05", "Search", "Pencarian 'ayam' mengembalikan hasil",
                   "results > 0", f"results={count}", status)
    except Exception as e:
        log_result("TC-05", "Search", "Pencarian 'ayam' mengembalikan hasil",
                   "results > 0", str(e), "FAIL")

    # TC-06: Pencarian dengan kata kunci "tempe"
    try:
        r = requests.get(f"{BASE_URL}/search", params={"q": "tempe"}, timeout=10)
        body = r.json()
        has_results = body.get("status") == "success" and len(body.get("results", [])) > 0
        status = "PASS" if has_results else "FAIL"
        count = len(body.get("results", []))
        log_result("TC-06", "Search", "Pencarian 'tempe' mengembalikan hasil",
                   "results > 0", f"results={count}", status)
    except Exception as e:
        log_result("TC-06", "Search", "Pencarian 'tempe' mengembalikan hasil",
                   "results > 0", str(e), "FAIL")

    # ------ EQUIVALENCE PARTITIONING: Input Kosong / Tidak Valid ------

    # TC-07: Pencarian tanpa query (q kosong)
    try:
        r = requests.get(f"{BASE_URL}/search", params={"q": ""}, timeout=10)
        body = r.json()
        empty_results = len(body.get("results", [])) == 0
        status = "PASS" if r.status_code == 200 and empty_results else "FAIL"
        log_result("TC-07", "Search", "Query kosong ('') mengembalikan array kosong",
                   "results=[]", f"results count={len(body.get('results', []))}", status)
    except Exception as e:
        log_result("TC-07", "Search", "Query kosong ('') mengembalikan array kosong",
                   "results=[]", str(e), "FAIL")

    # TC-08: Pencarian tanpa parameter q sama sekali
    try:
        r = requests.get(f"{BASE_URL}/search", timeout=10)
        body = r.json()
        empty_results = len(body.get("results", [])) == 0
        status = "PASS" if r.status_code == 200 and empty_results else "FAIL"
        log_result("TC-08", "Search", "Tanpa parameter 'q' mengembalikan array kosong",
                   "results=[]", f"status={r.status_code}, results={len(body.get('results', []))}", status)
    except Exception as e:
        log_result("TC-08", "Search", "Tanpa parameter 'q' mengembalikan array kosong",
                   "results=[]", str(e), "FAIL")

    # TC-09: Pencarian kata kunci tidak ditemukan
    try:
        r = requests.get(f"{BASE_URL}/search", params={"q": "xyzabcdef12345"}, timeout=10)
        body = r.json()
        empty_results = len(body.get("results", [])) == 0
        status = "PASS" if r.status_code == 200 and empty_results else "FAIL"
        log_result("TC-09", "Search", "Kata kunci random (tidak ada) mengembalikan array kosong",
                   "results=[]", f"results count={len(body.get('results', []))}", status)
    except Exception as e:
        log_result("TC-09", "Search", "Kata kunci random (tidak ada) mengembalikan array kosong",
                   "results=[]", str(e), "FAIL")

    # ------ VALIDASI STRUKTUR RESPONSE ------

    # TC-10: Response search memiliki field wajib (status, results, has_next)
    try:
        r = requests.get(f"{BASE_URL}/search", params={"q": "nasi"}, timeout=10)
        body = r.json()
        required_fields = {"status", "results", "has_next"}
        actual_fields = set(body.keys())
        has_all = required_fields.issubset(actual_fields)
        status = "PASS" if has_all else "FAIL"
        missing = required_fields - actual_fields
        log_result("TC-10", "Search", "Response memiliki field wajib (status, results, has_next)",
                   str(required_fields), str(actual_fields), status,
                   f"Missing: {missing}" if missing else "")
    except Exception as e:
        log_result("TC-10", "Search", "Response memiliki field wajib",
                   "status, results, has_next", str(e), "FAIL")

    # TC-11: Setiap item hasil search punya field nutrisi (kalori, protein, karbo, lemak)
    try:
        r = requests.get(f"{BASE_URL}/search", params={"q": "nasi"}, timeout=10)
        body = r.json()
        results = body.get("results", [])
        if not results:
            log_result("TC-11", "Search", "Item search punya field nutrisi",
                       "kalori, protein, karbo, lemak", "No results", "SKIP")
        else:
            required_item_fields = {"nama_makanan", "kalori", "protein", "karbo", "lemak"}
            all_valid = True
            for item in results:
                if not required_item_fields.issubset(set(item.keys())):
                    all_valid = False
                    break
            status = "PASS" if all_valid else "FAIL"
            log_result("TC-11", "Search", "Item search punya field nutrisi lengkap",
                       str(required_item_fields), f"sample keys={list(results[0].keys())}", status)
    except Exception as e:
        log_result("TC-11", "Search", "Item search punya field nutrisi",
                   "kalori, protein, karbo, lemak", str(e), "FAIL")

    # ------ FILTER JUNK FOOD ------

    # TC-12: Hasil search TIDAK mengandung junk food (Indomie, Chitato, dll)
    try:
        junk_keywords = ["indomie", "chitato", "pop mie", "coca-cola", "samyang"]
        all_clean = True
        failed_keyword = ""

        for keyword in junk_keywords:
            r = requests.get(f"{BASE_URL}/search", params={"q": keyword}, timeout=10)
            body = r.json()
            results = body.get("results", [])
            for item in results:
                nama = item.get("nama_makanan", "").lower()
                if any(jk in nama for jk in junk_keywords):
                    all_clean = False
                    failed_keyword = f"{keyword} → {nama}"
                    break
            if not all_clean:
                break

        status = "PASS" if all_clean else "FAIL"
        log_result("TC-12", "Search", "Hasil search tidak mengandung junk food (blacklist)",
                   "Tidak ada junk food di results", "Bersih" if all_clean else failed_keyword, status)
    except Exception as e:
        log_result("TC-12", "Search", "Hasil search tidak mengandung junk food",
                   "Tidak ada junk food", str(e), "FAIL")

    # ------ PAGINATION (BOUNDARY VALUE ANALYSIS) ------

    # TC-13: Pagination page=0 (halaman pertama) valid
    try:
        r = requests.get(f"{BASE_URL}/search", params={"q": "ikan", "page": 0, "limit": 5}, timeout=10)
        body = r.json()
        status = "PASS" if r.status_code == 200 and body.get("page") == 0 else "FAIL"
        log_result("TC-13", "Search", "Pagination page=0 merespons normal",
                   "page=0, status=200", f"page={body.get('page')}, status={r.status_code}", status)
    except Exception as e:
        log_result("TC-13", "Search", "Pagination page=0 merespons normal",
                   "status=200", str(e), "FAIL")

    # TC-14: Pagination page negatif ditolak (page=-1)
    try:
        r = requests.get(f"{BASE_URL}/search", params={"q": "ikan", "page": -1}, timeout=10)
        # FastAPI dengan ge=0 seharusnya menolak page negatif (422)
        status = "PASS" if r.status_code == 422 else "FAIL"
        log_result("TC-14", "Search", "Pagination page=-1 ditolak (422 Validation Error)",
                   "status_code=422", f"status_code={r.status_code}", status)
    except Exception as e:
        log_result("TC-14", "Search", "Pagination page=-1 ditolak",
                   "status_code=422", str(e), "FAIL")

    # TC-15: Limit melebihi maksimum (limit=100, max=50)
    try:
        r = requests.get(f"{BASE_URL}/search", params={"q": "ikan", "limit": 100}, timeout=10)
        # FastAPI dengan le=50 seharusnya menolak limit > 50 (422)
        status = "PASS" if r.status_code == 422 else "FAIL"
        log_result("TC-15", "Search", "Limit=100 ditolak (melebihi max 50)",
                   "status_code=422", f"status_code={r.status_code}", status)
    except Exception as e:
        log_result("TC-15", "Search", "Limit=100 ditolak",
                   "status_code=422", str(e), "FAIL")

    # TC-16: Limit=0 (BVA — batas bawah)
    try:
        r = requests.get(f"{BASE_URL}/search", params={"q": "nasi", "limit": 0}, timeout=10)
        body = r.json()
        empty_results = len(body.get("results", [])) == 0
        status = "PASS" if r.status_code == 200 and empty_results else "FAIL"
        log_result("TC-16", "Search", "Limit=0 mengembalikan array kosong",
                   "results=[]", f"results count={len(body.get('results', []))}", status)
    except Exception as e:
        log_result("TC-16", "Search", "Limit=0 mengembalikan array kosong",
                   "results=[]", str(e), "FAIL")

    # ------ SKOR RELEVANSI ------

    # TC-17: Hasil pencarian terurut — exact match di posisi atas
    try:
        r = requests.get(f"{BASE_URL}/search", params={"q": "nasi putih"}, timeout=10)
        body = r.json()
        results = body.get("results", [])
        if results:
            first_name = results[0].get("nama_makanan", "").lower()
            is_relevant = "nasi putih" in first_name or "nasi" in first_name
            status = "PASS" if is_relevant else "FAIL"
            log_result("TC-17", "Search", "Hasil pertama 'nasi putih' relevan dengan query",
                       "Mengandung 'nasi putih'", first_name, status)
        else:
            log_result("TC-17", "Search", "Hasil pertama relevan",
                       "Mengandung 'nasi putih'", "Tidak ada hasil", "SKIP")
    except Exception as e:
        log_result("TC-17", "Search", "Hasil pertama relevan", "nasi putih", str(e), "FAIL")

    # ------ ERROR GUESSING: Input Spesial ------

    # TC-18: Query dengan karakter spesial (SQL Injection attempt)
    try:
        r = requests.get(f"{BASE_URL}/search", params={"q": "'; DROP TABLE food_cache;--"}, timeout=10)
        status = "PASS" if r.status_code == 200 else "FAIL"
        log_result("TC-18", "Search", "SQL Injection attempt ditangani aman (tidak crash)",
                   "status=200 (tidak crash)", f"status={r.status_code}", status)
    except Exception as e:
        log_result("TC-18", "Search", "SQL Injection attempt ditangani aman",
                   "Tidak crash", str(e), "FAIL", "Server mungkin crash!")

    # TC-19: Query dengan Unicode/Emoji
    try:
        r = requests.get(f"{BASE_URL}/search", params={"q": "🍚🥩"}, timeout=10)
        status = "PASS" if r.status_code == 200 else "FAIL"
        log_result("TC-19", "Search", "Query dengan emoji tidak menyebabkan error",
                   "status=200", f"status={r.status_code}", status)
    except Exception as e:
        log_result("TC-19", "Search", "Query dengan emoji tidak error",
                   "status=200", str(e), "FAIL")

    # TC-20: Query sangat panjang (1000 karakter)
    try:
        long_query = "nasi " * 200  # ~1000 karakter
        r = requests.get(f"{BASE_URL}/search", params={"q": long_query}, timeout=10)
        status = "PASS" if r.status_code in [200, 422] else "FAIL"
        log_result("TC-20", "Search", "Query sangat panjang (1000 char) tidak crash",
                   "status=200 atau 422", f"status={r.status_code}", status)
    except Exception as e:
        log_result("TC-20", "Search", "Query sangat panjang tidak crash",
                   "Tidak crash", str(e), "FAIL")


# ==========================================
# 🧪 TEST SUITE 3: ENDPOINT POST /rekomendasi
# ==========================================
def test_rekomendasi_endpoint():
    print_section("TEST SUITE 3: POST /rekomendasi — Generate Menu Diet")

    # ------ EP: PROFIL VALID (Berbagai Variasi) ------

    valid_profiles = [
        {
            "id": "TC-21",
            "desc": "Profil valid — Wanita, Cutting, Sedentary",
            "payload": {
                "berat": 55, "tinggi": 158, "umur": 28,
                "gender": "wanita", "goal": "cutting", "activity": "sedentary"
            }
        },
        {
            "id": "TC-22",
            "desc": "Profil valid — Pria, Maintain, Sedentary",
            "payload": {
                "berat": 70, "tinggi": 170, "umur": 25,
                "gender": "pria", "goal": "maintain", "activity": "sedentary"
            }
        },
        {
            "id": "TC-23",
            "desc": "Profil valid — Pria, Bulking, Active",
            "payload": {
                "berat": 85, "tinggi": 180, "umur": 22,
                "gender": "pria", "goal": "bulking", "activity": "active"
            }
        },
        {
            "id": "TC-24",
            "desc": "Profil valid — Wanita, Maintain, Moderate",
            "payload": {
                "berat": 60, "tinggi": 165, "umur": 30,
                "gender": "wanita", "goal": "maintain", "activity": "moderate"
            }
        },
        {
            "id": "TC-25",
            "desc": "Profil valid — Pria, Cutting, Moderate",
            "payload": {
                "berat": 80, "tinggi": 175, "umur": 35,
                "gender": "pria", "goal": "cutting", "activity": "moderate"
            }
        },
    ]

    for profile in valid_profiles:
        try:
            r = requests.post(f"{BASE_URL}/rekomendasi", json=profile["payload"], timeout=30)
            body = r.json()

            if r.status_code == 200 and body.get("status") == "success":
                menu = body.get("menu", [])
                has_3_meals = len(menu) == 3
                meal_names = [m.get("waktu") for m in menu]
                correct_meals = meal_names == ["Pagi", "Siang", "Malam"]
                all_have_items = all(len(m.get("isi", [])) > 0 for m in menu)

                if has_3_meals and correct_meals and all_have_items:
                    status = "PASS"
                    detail = ""
                else:
                    status = "FAIL"
                    detail = f"meals={meal_names}, items={[len(m.get('isi',[])) for m in menu]}"

                log_result(profile["id"], "Rekomendasi", profile["desc"],
                           "3 meals (Pagi/Siang/Malam) + isi > 0",
                           f"meals={len(menu)}, names={meal_names}", status, detail)
            else:
                log_result(profile["id"], "Rekomendasi", profile["desc"],
                           "status=200, success", f"status={r.status_code}", "FAIL",
                           body.get("detail", ""))
        except Exception as e:
            log_result(profile["id"], "Rekomendasi", profile["desc"],
                       "status=200", str(e), "FAIL")

    # ------ VALIDASI STRUKTUR RESPONSE ------

    # TC-26: Response rekomendasi memiliki field wajib
    try:
        payload = {"berat": 70, "tinggi": 170, "umur": 25,
                   "gender": "pria", "goal": "maintain", "activity": "sedentary"}
        r = requests.post(f"{BASE_URL}/rekomendasi", json=payload, timeout=30)
        body = r.json()
        required = {"status", "user_info", "hasil_generasi", "menu"}
        actual = set(body.keys())
        has_all = required.issubset(actual)
        status = "PASS" if has_all else "FAIL"
        missing = required - actual
        log_result("TC-26", "Rekomendasi", "Response memiliki field wajib (status, user_info, hasil_generasi, menu)",
                   str(required), str(actual), status, f"Missing: {missing}" if missing else "")
    except Exception as e:
        log_result("TC-26", "Rekomendasi", "Response memiliki field wajib",
                   "status, user_info, hasil_generasi, menu", str(e), "FAIL")

    # TC-27: user_info memiliki target macro lengkap
    try:
        payload = {"berat": 70, "tinggi": 170, "umur": 25,
                   "gender": "pria", "goal": "maintain", "activity": "sedentary"}
        r = requests.post(f"{BASE_URL}/rekomendasi", json=payload, timeout=30)
        body = r.json()
        user_info = body.get("user_info", {})
        required_info = {"target_kalori", "target_protein", "target_karbo", "target_lemak"}
        actual_info = set(user_info.keys())
        has_all = required_info.issubset(actual_info)
        status = "PASS" if has_all else "FAIL"
        log_result("TC-27", "Rekomendasi", "user_info memiliki target kalori/protein/karbo/lemak",
                   str(required_info), str(actual_info), status)
    except Exception as e:
        log_result("TC-27", "Rekomendasi", "user_info memiliki target macro",
                   "target_kalori, target_protein, dll", str(e), "FAIL")

    # TC-28: Setiap item menu punya nutrisi lengkap (nama, kalori, protein, karbo, lemak)
    try:
        payload = {"berat": 70, "tinggi": 170, "umur": 25,
                   "gender": "pria", "goal": "maintain", "activity": "sedentary"}
        r = requests.post(f"{BASE_URL}/rekomendasi", json=payload, timeout=30)
        body = r.json()
        menu = body.get("menu", [])
        required_fields = {"nama_makanan", "kalori", "protein", "karbo", "lemak"}
        all_valid = True
        bad_item = None

        for meal in menu:
            for item in meal.get("isi", []):
                if not required_fields.issubset(set(item.keys())):
                    all_valid = False
                    bad_item = item
                    break

        status = "PASS" if all_valid else "FAIL"
        log_result("TC-28", "Rekomendasi", "Setiap item menu punya field nutrisi lengkap",
                   str(required_fields),
                   f"keys={list(bad_item.keys()) if bad_item else 'all valid'}", status)
    except Exception as e:
        log_result("TC-28", "Rekomendasi", "Item menu punya field nutrisi",
                   str(required_fields), str(e), "FAIL")

    # ------ CONSTRAINT: KALORI TIDAK MELEBIHI TARGET ------

    # TC-29: Total kalori menu <= target TDEE + toleransi 5%
    try:
        payload = {"berat": 70, "tinggi": 170, "umur": 25,
                   "gender": "pria", "goal": "maintain", "activity": "sedentary"}
        r = requests.post(f"{BASE_URL}/rekomendasi", json=payload, timeout=30)
        body = r.json()

        target_kal = body.get("user_info", {}).get("target_kalori", 0)
        menu = body.get("menu", [])
        total_kal = sum(
            item.get("kalori", 0) for meal in menu for item in meal.get("isi", [])
        )
        batas_atas = target_kal * 1.05
        within_limit = total_kal <= batas_atas

        status = "PASS" if within_limit else "FAIL"
        log_result("TC-29", "Rekomendasi",
                   f"Total kalori ({round(total_kal)} kkal) <= target+5% ({round(batas_atas)} kkal)",
                   f"<= {round(batas_atas)} kkal", f"{round(total_kal)} kkal", status)
    except Exception as e:
        log_result("TC-29", "Rekomendasi", "Total kalori <= target+5%",
                   "Di bawah limit", str(e), "FAIL")

    # ------ CONSTRAINT: TIDAK ADA JUNK FOOD DI MENU ------

    # TC-30: Menu rekomendasi bebas junk food & gorengan
    try:
        payload = {"berat": 65, "tinggi": 168, "umur": 27,
                   "gender": "pria", "goal": "maintain", "activity": "moderate"}
        r = requests.post(f"{BASE_URL}/rekomendasi", json=payload, timeout=30)
        body = r.json()
        menu = body.get("menu", [])

        junk_keywords = ["indomie", "mie instant", "pop mie", "chitato", "coca-cola",
                         "fanta", "gorengan", "samyang", "lays", "cheetos"]
        found_junk = None

        for meal in menu:
            for item in meal.get("isi", []):
                nama = item.get("nama_makanan", "").lower()
                for jk in junk_keywords:
                    if jk in nama:
                        found_junk = nama
                        break

        status = "PASS" if not found_junk else "FAIL"
        log_result("TC-30", "Rekomendasi", "Menu bebas junk food/gorengan",
                   "Tidak ada junk food", found_junk if found_junk else "Bersih", status)
    except Exception as e:
        log_result("TC-30", "Rekomendasi", "Menu bebas junk food",
                   "Tidak ada junk food", str(e), "FAIL")

    # ------ EP: INPUT TIDAK VALID (Missing / Wrong Type) ------

    # TC-31: Request tanpa body (empty)
    try:
        r = requests.post(f"{BASE_URL}/rekomendasi", timeout=10)
        status = "PASS" if r.status_code == 422 else "FAIL"
        log_result("TC-31", "Rekomendasi", "Request tanpa body ditolak (422)",
                   "status=422", f"status={r.status_code}", status)
    except Exception as e:
        log_result("TC-31", "Rekomendasi", "Request tanpa body ditolak",
                   "status=422", str(e), "FAIL")

    # TC-32: Request dengan field kurang (tanpa 'berat')
    try:
        payload = {"tinggi": 170, "umur": 25,
                   "gender": "pria", "goal": "maintain", "activity": "sedentary"}
        r = requests.post(f"{BASE_URL}/rekomendasi", json=payload, timeout=10)
        status = "PASS" if r.status_code == 422 else "FAIL"
        log_result("TC-32", "Rekomendasi", "Tanpa field 'berat' ditolak (422)",
                   "status=422", f"status={r.status_code}", status)
    except Exception as e:
        log_result("TC-32", "Rekomendasi", "Tanpa field 'berat' ditolak",
                   "status=422", str(e), "FAIL")

    # TC-33: Request dengan tipe data salah (berat = string)
    try:
        payload = {"berat": "abc", "tinggi": 170, "umur": 25,
                   "gender": "pria", "goal": "maintain", "activity": "sedentary"}
        r = requests.post(f"{BASE_URL}/rekomendasi", json=payload, timeout=10)
        status = "PASS" if r.status_code == 422 else "FAIL"
        log_result("TC-33", "Rekomendasi", "Berat = string ('abc') ditolak (422)",
                   "status=422", f"status={r.status_code}", status)
    except Exception as e:
        log_result("TC-33", "Rekomendasi", "Tipe data salah ditolak",
                   "status=422", str(e), "FAIL")

    # TC-34: Request dengan umur = string
    try:
        payload = {"berat": 70, "tinggi": 170, "umur": "dua puluh",
                   "gender": "pria", "goal": "maintain", "activity": "sedentary"}
        r = requests.post(f"{BASE_URL}/rekomendasi", json=payload, timeout=10)
        status = "PASS" if r.status_code == 422 else "FAIL"
        log_result("TC-34", "Rekomendasi", "Umur = string ('dua puluh') ditolak (422)",
                   "status=422", f"status={r.status_code}", status)
    except Exception as e:
        log_result("TC-34", "Rekomendasi", "Umur string ditolak",
                   "status=422", str(e), "FAIL")

    # ------ BVA: BOUNDARY VALUES ------

    # TC-35: Berat sangat rendah (berat=20)
    try:
        payload = {"berat": 20, "tinggi": 150, "umur": 18,
                   "gender": "wanita", "goal": "maintain", "activity": "sedentary"}
        r = requests.post(f"{BASE_URL}/rekomendasi", json=payload, timeout=30)
        status = "PASS" if r.status_code in [200, 422] else "FAIL"
        log_result("TC-35", "Rekomendasi", "Berat rendah (20 kg) tidak crash",
                   "status=200 atau 422", f"status={r.status_code}", status)
    except Exception as e:
        log_result("TC-35", "Rekomendasi", "Berat rendah tidak crash",
                   "Tidak crash", str(e), "FAIL")

    # TC-36: Berat sangat tinggi (berat=200)
    try:
        payload = {"berat": 200, "tinggi": 190, "umur": 30,
                   "gender": "pria", "goal": "bulking", "activity": "active"}
        r = requests.post(f"{BASE_URL}/rekomendasi", json=payload, timeout=30)
        status = "PASS" if r.status_code in [200, 404] else "FAIL"
        log_result("TC-36", "Rekomendasi", "Berat tinggi (200 kg) tidak crash",
                   "status=200 atau 404", f"status={r.status_code}", status)
    except Exception as e:
        log_result("TC-36", "Rekomendasi", "Berat tinggi tidak crash",
                   "Tidak crash", str(e), "FAIL")

    # TC-37: Umur sangat muda (umur=10)
    try:
        payload = {"berat": 35, "tinggi": 140, "umur": 10,
                   "gender": "pria", "goal": "maintain", "activity": "sedentary"}
        r = requests.post(f"{BASE_URL}/rekomendasi", json=payload, timeout=30)
        status = "PASS" if r.status_code in [200, 422] else "FAIL"
        log_result("TC-37", "Rekomendasi", "Umur sangat muda (10) tidak crash",
                   "status=200 atau 422", f"status={r.status_code}", status)
    except Exception as e:
        log_result("TC-37", "Rekomendasi", "Umur muda tidak crash",
                   "Tidak crash", str(e), "FAIL")

    # TC-38: Umur sangat tua (umur=80)
    try:
        payload = {"berat": 65, "tinggi": 165, "umur": 80,
                   "gender": "wanita", "goal": "maintain", "activity": "sedentary"}
        r = requests.post(f"{BASE_URL}/rekomendasi", json=payload, timeout=30)
        status = "PASS" if r.status_code in [200, 422] else "FAIL"
        log_result("TC-38", "Rekomendasi", "Umur sangat tua (80) tidak crash",
                   "status=200 atau 422", f"status={r.status_code}", status)
    except Exception as e:
        log_result("TC-38", "Rekomendasi", "Umur tua tidak crash",
                   "Tidak crash", str(e), "FAIL")

    # TC-39: Berat = 0 (BVA zero)
    try:
        payload = {"berat": 0, "tinggi": 170, "umur": 25,
                   "gender": "pria", "goal": "maintain", "activity": "sedentary"}
        r = requests.post(f"{BASE_URL}/rekomendasi", json=payload, timeout=30)
        status = "PASS" if r.status_code in [200, 404, 422] else "FAIL"
        log_result("TC-39", "Rekomendasi", "Berat = 0 tidak crash server",
                   "status=200/404/422", f"status={r.status_code}", status)
    except Exception as e:
        log_result("TC-39", "Rekomendasi", "Berat = 0 tidak crash",
                   "Tidak crash", str(e), "FAIL")

    # TC-40: Berat negatif (berat=-50)
    try:
        payload = {"berat": -50, "tinggi": 170, "umur": 25,
                   "gender": "pria", "goal": "maintain", "activity": "sedentary"}
        r = requests.post(f"{BASE_URL}/rekomendasi", json=payload, timeout=30)
        status = "PASS" if r.status_code in [200, 404, 422] else "FAIL"
        log_result("TC-40", "Rekomendasi", "Berat negatif (-50) tidak crash server",
                   "status=200/404/422", f"status={r.status_code}", status)
    except Exception as e:
        log_result("TC-40", "Rekomendasi", "Berat negatif tidak crash",
                   "Tidak crash", str(e), "FAIL")

    # ------ FITUR PREFERENSI MAKANAN ------

    # TC-41: Rekomendasi dengan preferred_foods
    try:
        payload = {"berat": 70, "tinggi": 170, "umur": 25,
                   "gender": "pria", "goal": "maintain", "activity": "sedentary",
                   "preferred_foods": ["nasi putih (1 centong)", "dada ayam bakar (100g)"]}
        r = requests.post(f"{BASE_URL}/rekomendasi", json=payload, timeout=30)
        body = r.json()
        status = "PASS" if r.status_code == 200 and body.get("status") == "success" else "FAIL"
        log_result("TC-41", "Rekomendasi", "Rekomendasi dengan preferred_foods berhasil",
                   "status=200, success", f"status={r.status_code}", status)
    except Exception as e:
        log_result("TC-41", "Rekomendasi", "Preferred foods berhasil",
                   "status=200", str(e), "FAIL")

    # TC-42: Rekomendasi dengan excluded_foods
    try:
        payload = {"berat": 70, "tinggi": 170, "umur": 25,
                   "gender": "pria", "goal": "maintain", "activity": "sedentary",
                   "excluded_foods": ["nasi putih (1 centong)"]}
        r = requests.post(f"{BASE_URL}/rekomendasi", json=payload, timeout=30)
        body = r.json()

        if r.status_code == 200 and body.get("status") == "success":
            menu = body.get("menu", [])
            excluded_found = False
            for meal in menu:
                for item in meal.get("isi", []):
                    if "nasi putih (1 centong)" in item.get("nama_makanan", "").lower():
                        excluded_found = True

            status = "PASS" if not excluded_found else "FAIL"
            log_result("TC-42", "Rekomendasi", "Excluded food tidak muncul di menu",
                       "Tidak ada 'nasi putih (1 centong)'",
                       "Tidak ditemukan" if not excluded_found else "Ditemukan!", status)
        else:
            log_result("TC-42", "Rekomendasi", "Excluded food tidak muncul",
                       "status=200", f"status={r.status_code}", "FAIL")
    except Exception as e:
        log_result("TC-42", "Rekomendasi", "Excluded foods",
                   "Berfungsi", str(e), "FAIL")

    # TC-43: preferred_foods dan excluded_foods array kosong
    try:
        payload = {"berat": 70, "tinggi": 170, "umur": 25,
                   "gender": "pria", "goal": "maintain", "activity": "sedentary",
                   "preferred_foods": [], "excluded_foods": []}
        r = requests.post(f"{BASE_URL}/rekomendasi", json=payload, timeout=30)
        body = r.json()
        status = "PASS" if r.status_code == 200 and body.get("status") == "success" else "FAIL"
        log_result("TC-43", "Rekomendasi", "preferred_foods=[] dan excluded_foods=[] tetap berhasil",
                   "status=200", f"status={r.status_code}", status)
    except Exception as e:
        log_result("TC-43", "Rekomendasi", "Array kosong tetap berhasil",
                   "status=200", str(e), "FAIL")


# ==========================================
# 🧪 TEST SUITE 4: ENDPOINT TIDAK ADA (404)
# ==========================================
def test_unknown_endpoint():
    print_section("TEST SUITE 4: Endpoint Tidak Dikenal (404)")

    # TC-44: GET endpoint yang tidak ada
    try:
        r = requests.get(f"{BASE_URL}/api/v2/makanan", timeout=5)
        status = "PASS" if r.status_code == 404 else "FAIL"
        log_result("TC-44", "404", "GET endpoint tidak ada → 404",
                   "status=404", f"status={r.status_code}", status)
    except Exception as e:
        log_result("TC-44", "404", "GET endpoint tidak ada → 404",
                   "status=404", str(e), "FAIL")

    # TC-45: POST endpoint yang tidak ada
    try:
        r = requests.post(f"{BASE_URL}/api/delete-all", timeout=5)
        status = "PASS" if r.status_code in [404, 405] else "FAIL"
        log_result("TC-45", "404", "POST endpoint tidak ada → 404/405",
                   "status=404 atau 405", f"status={r.status_code}", status)
    except Exception as e:
        log_result("TC-45", "404", "POST endpoint tidak ada → 404/405",
                   "status=404/405", str(e), "FAIL")

    # TC-46: Method salah — POST ke endpoint GET (/)
    try:
        r = requests.post(f"{BASE_URL}/", timeout=5)
        status = "PASS" if r.status_code == 405 else "FAIL"
        log_result("TC-46", "404", "POST ke GET-only endpoint (/) → 405 Method Not Allowed",
                   "status=405", f"status={r.status_code}", status)
    except Exception as e:
        log_result("TC-46", "404", "Method salah → 405",
                   "status=405", str(e), "FAIL")


# ==========================================
# 🧪 TEST SUITE 5: RESPONSE TIME (Non-Fungsional)
# ==========================================
def test_response_time():
    print_section("TEST SUITE 5: Response Time (Non-Fungsional)")

    # TC-47: Root endpoint < 500ms
    try:
        start = time.time()
        r = requests.get(f"{BASE_URL}/", timeout=5)
        elapsed = (time.time() - start) * 1000
        status = "PASS" if elapsed < 500 else "FAIL"
        log_result("TC-47", "Performance", f"GET / response time = {elapsed:.1f}ms (limit: 500ms)",
                   "< 500ms", f"{elapsed:.1f}ms", status)
    except Exception as e:
        log_result("TC-47", "Performance", "GET / response time < 500ms",
                   "< 500ms", str(e), "FAIL")

    # TC-48: Search response time < 5 detik
    try:
        start = time.time()
        r = requests.get(f"{BASE_URL}/search", params={"q": "ayam"}, timeout=15)
        elapsed = (time.time() - start) * 1000
        status = "PASS" if elapsed < 5000 else "FAIL"
        log_result("TC-48", "Performance", f"GET /search response time = {elapsed:.1f}ms (limit: 5s)",
                   "< 5000ms", f"{elapsed:.1f}ms", status)
    except Exception as e:
        log_result("TC-48", "Performance", "GET /search response time < 5s",
                   "< 5000ms", str(e), "FAIL")

    # TC-49: Rekomendasi response time < 10 detik
    try:
        payload = {"berat": 70, "tinggi": 170, "umur": 25,
                   "gender": "pria", "goal": "maintain", "activity": "sedentary"}
        start = time.time()
        r = requests.post(f"{BASE_URL}/rekomendasi", json=payload, timeout=30)
        elapsed = (time.time() - start) * 1000
        status = "PASS" if elapsed < 10000 else "FAIL"
        log_result("TC-49", "Performance",
                   f"POST /rekomendasi response time = {elapsed:.1f}ms (limit: 10s)",
                   "< 10000ms", f"{elapsed:.1f}ms", status)
    except Exception as e:
        log_result("TC-49", "Performance", "POST /rekomendasi response time < 10s",
                   "< 10000ms", str(e), "FAIL")


# ==========================================
# 📋 CETAK LAPORAN AKHIR
# ==========================================
def print_final_report():
    print(f"\n{'='*65}")
    print(f"  {BOLD}{CYAN}📋 LAPORAN HASIL BLACKBOX TESTING{RESET}")
    print(f"{'='*65}")

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"  Waktu Pengujian : {timestamp}")
    print(f"  Server Target   : {BASE_URL}")
    print(f"  Total Test Case : {total_tests}")
    print(f"  {GREEN}✅ PASS : {passed_tests}{RESET}")
    print(f"  {RED}❌ FAIL : {failed_tests}{RESET}")
    print(f"  {YELLOW}⚠️  SKIP : {skipped_tests}{RESET}")

    if total_tests > 0:
        pass_rate = (passed_tests / total_tests) * 100
        color = GREEN if pass_rate >= 90 else (YELLOW if pass_rate >= 70 else RED)
        print(f"\n  {BOLD}Pass Rate: {color}{pass_rate:.1f}%{RESET}")
    print(f"{'='*65}")

    # Tampilkan daftar yang FAIL
    fails = [r for r in results_log if r["status"] == "FAIL"]
    if fails:
        print(f"\n  {RED}{BOLD}⚠️  Test Case yang GAGAL:{RESET}")
        for f in fails:
            print(f"    {RED}• [{f['id']}] {f['deskripsi']}{RESET}")
            if f['detail']:
                print(f"      {DIM}→ {f['detail']}{RESET}")

    # Export ke file
    export_results_to_file()


def export_results_to_file():
    """Simpan hasil pengujian ke file teks untuk lampiran skripsi."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"hasil_blackbox_testing_{timestamp}.txt"

    try:
        with open(filename, "w", encoding="utf-8") as f:
            f.write("=" * 70 + "\n")
            f.write("  LAPORAN HASIL BLACKBOX TESTING — SISTEM FIT MEAL\n")
            f.write("=" * 70 + "\n\n")
            f.write(f"  Waktu      : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"  Server     : {BASE_URL}\n")
            f.write(f"  Total Test : {total_tests}\n")
            f.write(f"  Pass       : {passed_tests}\n")
            f.write(f"  Fail       : {failed_tests}\n")
            f.write(f"  Skip       : {skipped_tests}\n")

            if total_tests > 0:
                pass_rate = (passed_tests / total_tests) * 100
                f.write(f"  Pass Rate  : {pass_rate:.1f}%\n")

            f.write("\n" + "=" * 70 + "\n")
            f.write("  DETAIL SETIAP TEST CASE\n")
            f.write("=" * 70 + "\n\n")

            # Tabel header
            f.write(f"{'No':<6} {'ID':<8} {'Kategori':<14} {'Status':<8} {'Deskripsi'}\n")
            f.write("-" * 70 + "\n")

            for idx, r in enumerate(results_log, 1):
                status_icon = "PASS" if r["status"] == "PASS" else ("FAIL" if r["status"] == "FAIL" else "SKIP")
                f.write(f"{idx:<6} {r['id']:<8} {r['kategori']:<14} {status_icon:<8} {r['deskripsi']}\n")
                if r["status"] == "FAIL":
                    f.write(f"{'':>6} {'':>8} → Expected: {r['expected']}\n")
                    f.write(f"{'':>6} {'':>8} → Actual  : {r['actual']}\n")
                    if r["detail"]:
                        f.write(f"{'':>6} {'':>8} → Detail  : {r['detail']}\n")

            f.write("\n" + "=" * 70 + "\n")
            f.write("  [END OF REPORT]\n")

        print(f"\n  📄 Laporan disimpan ke: {CYAN}{filename}{RESET}")
    except Exception as e:
        print(f"\n  ⚠️ Gagal simpan file laporan: {e}")


# ==========================================
# 🚀 MAIN
# ==========================================
def main():
    print(f"\n{BOLD}{CYAN}")
    print("╔═══════════════════════════════════════════════════════════════╗")
    print("║       🧪 BLACKBOX TESTING — FIT MEAL API SERVER             ║")
    print("║       Sistem Rekomendasi Menu Diet Harian                   ║")
    print("╚═══════════════════════════════════════════════════════════════╝")
    print(f"{RESET}")

    # Cek koneksi server dulu
    print(f"  {DIM}Menghubungi server di {BASE_URL}...{RESET}")
    try:
        r = requests.get(f"{BASE_URL}/", timeout=5)
        print(f"  {GREEN}✅ Server aktif! (status={r.status_code}){RESET}")
    except requests.ConnectionError:
        print(f"  {RED}❌ GAGAL: Server tidak aktif di {BASE_URL}")
        print(f"     Jalankan dulu: python main.py{RESET}")
        sys.exit(1)
    except Exception as e:
        print(f"  {RED}❌ GAGAL: {e}{RESET}")
        sys.exit(1)

    # Jalankan semua test suite
    test_root_endpoint()
    test_search_endpoint()
    test_rekomendasi_endpoint()
    test_unknown_endpoint()
    test_response_time()

    # Cetak laporan akhir
    print_final_report()


if __name__ == "__main__":
    main()
