"""
=============================================================================
🔥 STRESS / LOAD TESTING — Sistem Rekomendasi Menu Diet "Fit Meal"
=============================================================================
Menguji kemampuan server menangani banyak request bersamaan (concurrent).

Skenario yang diuji:
  1. Baseline  : 1 user bersamaan
  2. Normal    : 5 user bersamaan
  3. Moderate  : 10 user bersamaan
  4. Heavy     : 20 user bersamaan
  5. Stress    : 50 user bersamaan

Metrik yang diukur:
  - Response Time (avg, min, max, p95)
  - Success Rate (%)
  - Throughput (requests/second)
  - Error Rate (%)

Cara menjalankan:
  1. Pastikan server berjalan: python main.py
  2. Jalankan: python test_stress.py
=============================================================================
"""

import requests
import time
import statistics
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime

# ==========================================
# ⚙️ KONFIGURASI
# ==========================================
BASE_URL = "http://127.0.0.1:9090"

# Warna terminal
GREEN  = "\033[92m"
RED    = "\033[91m"
YELLOW = "\033[93m"
CYAN   = "\033[96m"
BOLD   = "\033[1m"
RESET  = "\033[0m"
DIM    = "\033[2m"

# ==========================================
# 📊 PROFIL TEST UNTUK REKOMENDASI
# ==========================================
TEST_PROFILES = [
    {"berat": 55, "tinggi": 158, "umur": 28, "gender": "wanita", "goal": "cutting", "activity": "sedentary"},
    {"berat": 70, "tinggi": 170, "umur": 25, "gender": "pria", "goal": "maintain", "activity": "sedentary"},
    {"berat": 85, "tinggi": 180, "umur": 22, "gender": "pria", "goal": "bulking", "activity": "active"},
    {"berat": 60, "tinggi": 165, "umur": 30, "gender": "wanita", "goal": "maintain", "activity": "moderate"},
    {"berat": 80, "tinggi": 175, "umur": 35, "gender": "pria", "goal": "cutting", "activity": "moderate"},
]

SEARCH_KEYWORDS = ["nasi", "ayam", "tempe", "ikan", "bayam", "telur", "roti", "pisang", "kangkung", "jeruk"]


def send_request(request_type, index=0):
    """
    Mengirim satu request ke server dan mengukur response time.
    Returns: dict dengan status, response_time, status_code
    """
    start = time.time()
    try:
        if request_type == "root":
            r = requests.get(f"{BASE_URL}/", timeout=30)
        elif request_type == "search":
            keyword = SEARCH_KEYWORDS[index % len(SEARCH_KEYWORDS)]
            r = requests.get(f"{BASE_URL}/search", params={"q": keyword}, timeout=30)
        elif request_type == "rekomendasi":
            profile = TEST_PROFILES[index % len(TEST_PROFILES)]
            r = requests.post(f"{BASE_URL}/rekomendasi", json=profile, timeout=60)
        else:
            return {"success": False, "response_time": 0, "status_code": 0, "error": "Unknown type"}

        elapsed = (time.time() - start) * 1000  # ms
        return {
            "success": r.status_code == 200,
            "response_time": elapsed,
            "status_code": r.status_code,
            "error": None
        }
    except Exception as e:
        elapsed = (time.time() - start) * 1000
        return {
            "success": False,
            "response_time": elapsed,
            "status_code": 0,
            "error": str(e)
        }


def run_load_test(endpoint_type, concurrent_users, total_requests=None):
    """
    Menjalankan load test dengan jumlah concurrent users tertentu.
    Setiap user mengirim 1 request (atau total_requests dibagi rata).
    """
    if total_requests is None:
        total_requests = concurrent_users

    results = []
    start_time = time.time()

    with ThreadPoolExecutor(max_workers=concurrent_users) as executor:
        futures = []
        for i in range(total_requests):
            future = executor.submit(send_request, endpoint_type, i)
            futures.append(future)

        for future in as_completed(futures):
            results.append(future.result())

    total_time = (time.time() - start_time) * 1000  # ms

    # --- Hitung metrik ---
    success_count = sum(1 for r in results if r["success"])
    fail_count = total_requests - success_count
    response_times = [r["response_time"] for r in results if r["success"]]

    if response_times:
        avg_time = statistics.mean(response_times)
        min_time = min(response_times)
        max_time = max(response_times)
        p95_time = sorted(response_times)[int(len(response_times) * 0.95)] if len(response_times) > 1 else response_times[0]
        median_time = statistics.median(response_times)
    else:
        avg_time = min_time = max_time = p95_time = median_time = 0

    throughput = (success_count / (total_time / 1000)) if total_time > 0 else 0
    success_rate = (success_count / total_requests * 100) if total_requests > 0 else 0
    error_rate = 100 - success_rate

    errors = [r["error"] for r in results if r["error"]]

    return {
        "concurrent_users": concurrent_users,
        "total_requests": total_requests,
        "success_count": success_count,
        "fail_count": fail_count,
        "success_rate": success_rate,
        "error_rate": error_rate,
        "avg_time": avg_time,
        "min_time": min_time,
        "max_time": max_time,
        "p95_time": p95_time,
        "median_time": median_time,
        "total_time": total_time,
        "throughput": throughput,
        "errors": errors[:3],  # Simpan max 3 error
    }


def print_result_table(endpoint_name, results_list):
    """Cetak tabel hasil load test."""
    print(f"\n  {BOLD}📊 Hasil Load Test: {endpoint_name}{RESET}")
    print(f"  {'─'*90}")
    print(f"  {'Users':>6} │ {'Requests':>8} │ {'Success':>8} │ {'Rate':>7} │ {'Avg(ms)':>9} │ {'Min(ms)':>8} │ {'Max(ms)':>9} │ {'P95(ms)':>9} │ {'RPS':>6}")
    print(f"  {'─'*90}")

    for r in results_list:
        rate_color = GREEN if r['success_rate'] >= 95 else (YELLOW if r['success_rate'] >= 80 else RED)
        avg_color = GREEN if r['avg_time'] < 1000 else (YELLOW if r['avg_time'] < 5000 else RED)

        print(f"  {r['concurrent_users']:>6} │ "
              f"{r['total_requests']:>8} │ "
              f"{r['success_count']:>8} │ "
              f"{rate_color}{r['success_rate']:>6.1f}%{RESET} │ "
              f"{avg_color}{r['avg_time']:>8.1f}{RESET} │ "
              f"{r['min_time']:>7.1f} │ "
              f"{r['max_time']:>8.1f} │ "
              f"{r['p95_time']:>8.1f} │ "
              f"{r['throughput']:>5.1f}")

    print(f"  {'─'*90}")


def run_full_stress_test():
    """Jalankan stress test lengkap untuk semua endpoint."""

    print(f"\n{BOLD}{CYAN}")
    print("╔═══════════════════════════════════════════════════════════════╗")
    print("║       🔥 STRESS / LOAD TESTING — FIT MEAL API               ║")
    print("║       Pengujian Beban & Ketahanan Server                     ║")
    print("╚═══════════════════════════════════════════════════════════════╝")
    print(f"{RESET}")

    # Cek koneksi server
    print(f"  {DIM}Menghubungi server di {BASE_URL}...{RESET}")
    try:
        r = requests.get(f"{BASE_URL}/", timeout=5)
        print(f"  {GREEN}✅ Server aktif!{RESET}\n")
    except:
        print(f"  {RED}❌ Server tidak aktif! Jalankan: python main.py{RESET}")
        sys.exit(1)

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    concurrent_levels = [1, 5, 10, 20, 50]

    all_results = {}

    # ==========================================
    # TEST 1: GET / (Root — Baseline)
    # ==========================================
    print(f"\n{'='*65}")
    print(f"  {BOLD}{CYAN}TEST 1: GET / — Health Check (Baseline){RESET}")
    print(f"{'='*65}")

    root_results = []
    for users in concurrent_levels:
        total_req = max(users, 10)  # Minimal 10 requests
        print(f"  {DIM}Testing {users} concurrent users ({total_req} requests)...{RESET}", end=" ", flush=True)
        result = run_load_test("root", users, total_req)
        root_results.append(result)
        icon = f"{GREEN}✅{RESET}" if result['success_rate'] >= 95 else f"{RED}❌{RESET}"
        print(f"{icon} Rate={result['success_rate']:.0f}% | Avg={result['avg_time']:.1f}ms")

    print_result_table("GET /", root_results)
    all_results["GET /"] = root_results

    # ==========================================
    # TEST 2: GET /search
    # ==========================================
    print(f"\n{'='*65}")
    print(f"  {BOLD}{CYAN}TEST 2: GET /search — Pencarian Makanan{RESET}")
    print(f"{'='*65}")

    search_results = []
    for users in concurrent_levels:
        total_req = max(users, 10)
        print(f"  {DIM}Testing {users} concurrent users ({total_req} requests)...{RESET}", end=" ", flush=True)
        result = run_load_test("search", users, total_req)
        search_results.append(result)
        icon = f"{GREEN}✅{RESET}" if result['success_rate'] >= 95 else f"{RED}❌{RESET}"
        print(f"{icon} Rate={result['success_rate']:.0f}% | Avg={result['avg_time']:.1f}ms")

    print_result_table("GET /search", search_results)
    all_results["GET /search"] = search_results

    # ==========================================
    # TEST 3: POST /rekomendasi
    # ==========================================
    print(f"\n{'='*65}")
    print(f"  {BOLD}{CYAN}TEST 3: POST /rekomendasi — Generate Menu{RESET}")
    print(f"{'='*65}")

    rekom_results = []
    for users in concurrent_levels:
        total_req = users  # 1 request per user (karena heavy)
        print(f"  {DIM}Testing {users} concurrent users ({total_req} requests)...{RESET}", end=" ", flush=True)
        result = run_load_test("rekomendasi", users, total_req)
        rekom_results.append(result)
        icon = f"{GREEN}✅{RESET}" if result['success_rate'] >= 95 else f"{RED}❌{RESET}"
        print(f"{icon} Rate={result['success_rate']:.0f}% | Avg={result['avg_time']:.1f}ms")

    print_result_table("POST /rekomendasi", rekom_results)
    all_results["POST /rekomendasi"] = rekom_results

    # ==========================================
    # 📋 LAPORAN AKHIR
    # ==========================================
    print(f"\n{'='*65}")
    print(f"  {BOLD}{CYAN}📋 RINGKASAN STRESS TEST{RESET}")
    print(f"{'='*65}")
    print(f"  Waktu Pengujian : {timestamp}")
    print(f"  Server          : {BASE_URL}")
    print(f"  Level Beban     : {concurrent_levels}")

    for endpoint, results in all_results.items():
        max_passed = 0
        for r in results:
            if r['success_rate'] >= 95:
                max_passed = r['concurrent_users']
        print(f"\n  {BOLD}{endpoint}{RESET}")
        print(f"    Max concurrent (≥95% success): {GREEN}{max_passed} users{RESET}")
        if results:
            best = results[0]
            worst = results[-1]
            print(f"    Avg response (1 user)        : {best['avg_time']:.1f}ms")
            print(f"    Avg response ({worst['concurrent_users']} users)      : {worst['avg_time']:.1f}ms")

    # Export ke file
    export_stress_results(all_results, timestamp)


def export_stress_results(all_results, timestamp):
    """Simpan hasil stress test ke file."""
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"hasil_stress_testing_{ts}.txt"

    try:
        with open(filename, "w", encoding="utf-8") as f:
            f.write("=" * 70 + "\n")
            f.write("  LAPORAN HASIL STRESS / LOAD TESTING — SISTEM FIT MEAL\n")
            f.write("=" * 70 + "\n\n")
            f.write(f"  Waktu      : {timestamp}\n")
            f.write(f"  Server     : {BASE_URL}\n\n")

            for endpoint, results in all_results.items():
                f.write(f"\n{'─'*70}\n")
                f.write(f"  ENDPOINT: {endpoint}\n")
                f.write(f"{'─'*70}\n")
                f.write(f"  {'Users':>6} | {'Requests':>8} | {'Success':>8} | {'Rate':>7} | {'Avg(ms)':>9} | {'Min(ms)':>8} | {'Max(ms)':>9} | {'P95(ms)':>9} | {'RPS':>6}\n")
                f.write(f"  {'-'*90}\n")

                for r in results:
                    f.write(f"  {r['concurrent_users']:>6} | "
                            f"{r['total_requests']:>8} | "
                            f"{r['success_count']:>8} | "
                            f"{r['success_rate']:>6.1f}% | "
                            f"{r['avg_time']:>8.1f} | "
                            f"{r['min_time']:>7.1f} | "
                            f"{r['max_time']:>8.1f} | "
                            f"{r['p95_time']:>8.1f} | "
                            f"{r['throughput']:>5.1f}\n")

                # Kesimpulan per endpoint
                max_passed = 0
                for r in results:
                    if r['success_rate'] >= 95:
                        max_passed = r['concurrent_users']
                f.write(f"\n  Kapasitas maksimal (success rate >= 95%): {max_passed} concurrent users\n")

            f.write("\n" + "=" * 70 + "\n")
            f.write("  KETERANGAN METRIK\n")
            f.write("=" * 70 + "\n")
            f.write("  Users     : Jumlah pengguna simultan (concurrent)\n")
            f.write("  Requests  : Total request yang dikirim\n")
            f.write("  Success   : Jumlah request yang berhasil (HTTP 200)\n")
            f.write("  Rate      : Persentase keberhasilan\n")
            f.write("  Avg(ms)   : Rata-rata response time (milidetik)\n")
            f.write("  Min(ms)   : Response time tercepat\n")
            f.write("  Max(ms)   : Response time terlambat\n")
            f.write("  P95(ms)   : 95th percentile response time\n")
            f.write("  RPS       : Requests Per Second (throughput)\n")
            f.write("\n  [END OF REPORT]\n")

        print(f"\n  📄 Laporan disimpan ke: {CYAN}{filename}{RESET}")
    except Exception as e:
        print(f"\n  ⚠️ Gagal simpan: {e}")


if __name__ == "__main__":
    run_full_stress_test()
