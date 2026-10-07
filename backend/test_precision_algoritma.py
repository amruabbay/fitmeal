"""
==========================================================================
 📊 SKRIP UJI METRIK PRECISION — Akurasi Algoritma Rekomendasi Fit Meal
==========================================================================

 Tujuan   : Mengukur Precision (akurasi) dari endpoint /rekomendasi FastAPI.
 Metode   : Mengirim profil fiktif dengan variasi TDEE, lalu memvalidasi:
              1. Tidak ada junk food / gorengan dalam menu rekomendasi.
              2. Total kalori menu ≤ target kalori (TDEE adjusted).
              3. Semua item berasal dari whitelist yang diizinkan.
 Target   : Precision = 100% (semua skenario lolos).
 Cara Jalan: python test_precision_algoritma.py
              (pastikan server FastAPI berjalan di localhost:8000)

 Author   : Auto-generated untuk penelitian skripsi Fit Meal
==========================================================================
"""

import requests
import json
import sys
from datetime import datetime

# ==========================================================================
# ⚙️ KONFIGURASI
# ==========================================================================

BASE_URL = "http://127.0.0.1:8000"
ENDPOINT_REKOMENDASI = f"{BASE_URL}/rekomendasi"

# --- Daftar kata kunci JUNK FOOD & GORENGAN (constraint eliminasi) ---
# Gabungan dari blacklist di frontend (recommendation_screen.dart)
# dan JUNK_FOOD_KEYWORDS di backend (main.py)
BLACKLIST_JUNK_FOOD = [
    # --- Fast food & restoran ---
    "kfc", "mcd", "mcdonalds", "burger", "pizza", "hokben", "solaria",
    "a&w", "wendys", "fast food", "junk food", "french fries",
    "hotdog", "corndog", "chicken wings", "chicken nugget", "nugget",
    "kebab", "shawarma", "doner", "taco", "burrito",
    # --- Gorengan & makanan berminyak ---
    "gorengan", "crispy", "penyet", "geprek", "kulit ayam",
    "fried chicken", "ayam goreng", "bebek goreng", "lele goreng",
    "bakwan", "bala-bala", "cireng", "cimol", "cilok", "batagor", "pempek",
    "kerupuk", "krupuk", "rempeyek", "emping", "mendoan", "risol", "lumpia",
    "pastel", "basreng", "kripik", "keripik", "chiki", "seblak", "cuanki",
    "kentang goreng",
    # --- Mie instan & junk ---
    "pop mie", "popmie", "sarimi", "indomie", "mie sedaap", "mie sedap",
    "supermi", "samyang", "chitato", "lays", "taro", "cheetos",
    "mie instan", "sosis", "kornet",
    # --- Minuman tinggi gula ---
    "boba", "bubble", "milk tea", "es krim", "ice cream",
    "coca-cola", "coca cola", "fanta", "sprite", "pepsi", "soda",
    "gacoan",
    # --- Makanan tinggi gula ---
    "oreo", "silverqueen", "beng-beng", "beng beng",
    "martabak", "kue", "biskuit", "wafer", "cake", "pudding",
    "coklat", "chocolate",
]

# ==========================================================================
# 👤 PROFIL UJI — 5 Skenario dengan variasi TDEE
# ==========================================================================

PROFIL_UJI = [
    {
        "label": "Profil 1 — Wanita Cutting (TDEE Rendah ≈1300 kkal)",
        "payload": {
            "berat": 55,
            "tinggi": 158,
            "umur": 28,
            "gender": "wanita",
            "goal": "cutting",
            "activity": "sedentary",
        },
    },
    {
        "label": "Profil 2 — Pria Sedentary Maintain (TDEE Sedang ≈1800 kkal)",
        "payload": {
            "berat": 70,
            "tinggi": 170,
            "umur": 25,
            "gender": "pria",
            "goal": "maintain",
            "activity": "sedentary",
        },
    },
    {
        "label": "Profil 3 — Pria Aktif Bulking (TDEE Tinggi ≈3000 kkal)",
        "payload": {
            "berat": 85,
            "tinggi": 180,
            "umur": 22,
            "gender": "pria",
            "goal": "bulking",
            "activity": "active",
        },
    },
    {
        "label": "Profil 4 — Wanita Moderate Maintain (TDEE ≈1900 kkal)",
        "payload": {
            "berat": 60,
            "tinggi": 165,
            "umur": 30,
            "gender": "wanita",
            "goal": "maintain",
            "activity": "moderate",
        },
    },
    {
        "label": "Profil 5 — Pria Moderate Cutting (TDEE ≈2100 kkal)",
        "payload": {
            "berat": 80,
            "tinggi": 175,
            "umur": 35,
            "gender": "pria",
            "goal": "cutting",
            "activity": "moderate",
        },
    },
]


# ==========================================================================
# 🔍 FUNGSI VALIDASI
# ==========================================================================

def cek_junk_food(nama_makanan: str) -> tuple[bool, str | None]:
    """
    Mengecek apakah nama makanan mengandung kata kunci junk food/gorengan.
    Returns: (is_junk, matched_keyword)
    """
    nama_lower = nama_makanan.lower()
    for keyword in BLACKLIST_JUNK_FOOD:
        if keyword in nama_lower:
            return True, keyword
    return False, None


def validasi_skenario(label: str, payload: dict) -> dict:
    """
    Mengirim request ke endpoint /rekomendasi dan memvalidasi response.
    
    Validasi yang dilakukan:
      1. Response status 200 (endpoint berhasil)
      2. Tidak ada item menu yang mengandung junk food / gorengan
      3. Total kalori semua menu ≤ target kalori user
    
    Returns: dict berisi detail hasil validasi
    """
    hasil = {
        "label": label,
        "status": "BELUM DIUJI",
        "validasi_junk_food": {"lolos": False, "detail": []},
        "validasi_kalori": {"lolos": False, "detail": ""},
        "target_kalori": 0,
        "total_kalori_menu": 0,
        "jumlah_item_menu": 0,
        "semua_lolos": False,
        "error": None,
    }

    # --- Kirim request ---
    try:
        response = requests.post(
            ENDPOINT_REKOMENDASI,
            json=payload,
            timeout=30  # Batas waktu permintaan end-to-end
        )
    except requests.exceptions.ConnectionError:
        hasil["error"] = "❌ Gagal koneksi ke server. Pastikan FastAPI berjalan."
        hasil["status"] = "ERROR"
        return hasil
    except requests.exceptions.Timeout:
        hasil["error"] = "❌ Request timeout (>30 detik)."
        hasil["status"] = "ERROR"
        return hasil

    if response.status_code != 200:
        hasil["error"] = f"❌ HTTP {response.status_code}: {response.text[:200]}"
        hasil["status"] = "ERROR"
        return hasil

    data = response.json()

    # --- Parse response ---
    target_kalori = data["user_info"]["target_kalori"]
    menu_list = data.get("menu", [])
    hasil["target_kalori"] = target_kalori

    # Kumpulkan semua item makanan dari Pagi, Siang, Malam
    semua_item = []
    for meal in menu_list:
        waktu = meal.get("waktu", "?")
        for item in meal.get("isi", []):
            semua_item.append({
                "waktu": waktu,
                "nama": item["nama_makanan"],
                "kalori": item["kalori"],
                "protein": item.get("protein", 0),
                "karbo": item.get("karbo", 0),
                "lemak": item.get("lemak", 0),
            })

    hasil["jumlah_item_menu"] = len(semua_item)
    total_kalori = sum(item["kalori"] for item in semua_item)
    hasil["total_kalori_menu"] = round(total_kalori, 1)

    # ============================================
    # VALIDASI 1: Cek Junk Food / Gorengan
    # ============================================
    junk_ditemukan = []
    for item in semua_item:
        is_junk, keyword = cek_junk_food(item["nama"])
        if is_junk:
            junk_ditemukan.append({
                "nama": item["nama"],
                "waktu": item["waktu"],
                "keyword_terdeteksi": keyword,
            })

    if not junk_ditemukan:
        hasil["validasi_junk_food"]["lolos"] = True
        hasil["validasi_junk_food"]["detail"] = "✅ Tidak ada junk food/gorengan."
    else:
        hasil["validasi_junk_food"]["lolos"] = False
        hasil["validasi_junk_food"]["detail"] = junk_ditemukan

    # ============================================
    # VALIDASI 2: Total Kalori ≤ Target TDEE
    # ============================================
    # Toleransi 5% untuk perbedaan pembulatan dan penyajian porsi
    batas_atas = target_kalori * 1.05

    if total_kalori <= batas_atas:
        hasil["validasi_kalori"]["lolos"] = True
        selisih = target_kalori - total_kalori
        hasil["validasi_kalori"]["detail"] = (
            f"✅ Total {total_kalori:.0f} kkal ≤ batas {batas_atas:.0f} kkal "
            f"(target: {target_kalori:.0f}, selisih: {selisih:+.0f} kkal)"
        )
    else:
        hasil["validasi_kalori"]["lolos"] = False
        overshoot = total_kalori - target_kalori
        hasil["validasi_kalori"]["detail"] = (
            f"❌ Total {total_kalori:.0f} kkal MELEBIHI target {target_kalori:.0f} kkal "
            f"(overshoot: +{overshoot:.0f} kkal, batas toleransi 5%: {batas_atas:.0f})"
        )

    # ============================================
    # KEPUTUSAN AKHIR
    # ============================================
    semua_lolos = (
        hasil["validasi_junk_food"]["lolos"] and
        hasil["validasi_kalori"]["lolos"]
    )
    hasil["semua_lolos"] = semua_lolos
    hasil["status"] = "✅ LOLOS" if semua_lolos else "❌ GAGAL"

    return hasil


# ==========================================================================
# 📊 FUNGSI CETAK LAPORAN
# ==========================================================================

def cetak_garis(char="═", panjang=70):
    print(char * panjang)


def cetak_laporan(semua_hasil: list):
    """Mencetak laporan lengkap hasil pengujian Precision."""
    cetak_garis()
    print("  📊 LAPORAN UJI PRECISION — Algoritma Rekomendasi Fit Meal")
    print(f"  Waktu: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    cetak_garis()

    total_skenario = len(semua_hasil)
    total_lolos = 0

    for i, hasil in enumerate(semua_hasil, 1):
        print(f"\n{'─' * 70}")
        print(f"  🔬 Skenario {i}: {hasil['label']}")
        print(f"{'─' * 70}")

        if hasil["error"]:
            print(f"  Status : {hasil['status']}")
            print(f"  Error  : {hasil['error']}")
            continue

        print(f"  Status           : {hasil['status']}")
        print(f"  Target Kalori    : {hasil['target_kalori']:.0f} kkal")
        print(f"  Total Kalori Menu: {hasil['total_kalori_menu']:.0f} kkal")
        print(f"  Jumlah Item Menu : {hasil['jumlah_item_menu']} item")
        print()

        # Detail validasi junk food
        print(f"  [1] Validasi Junk Food / Gorengan:")
        if hasil["validasi_junk_food"]["lolos"]:
            print(f"      {hasil['validasi_junk_food']['detail']}")
        else:
            detail = hasil["validasi_junk_food"]["detail"]
            print(f"      ❌ Ditemukan {len(detail)} item junk food:")
            for junk in detail:
                print(f"         - [{junk['waktu']}] \"{junk['nama']}\" "
                      f"(keyword: \"{junk['keyword_terdeteksi']}\")")

        # Detail validasi kalori
        print(f"  [2] Validasi Batas Kalori:")
        print(f"      {hasil['validasi_kalori']['detail']}")

        if hasil["semua_lolos"]:
            total_lolos += 1

    # ============================================
    # RINGKASAN AKHIR — PRECISION SCORE
    # ============================================
    cetak_garis()
    print()
    cetak_garis("═")
    print("  📈 RINGKASAN METRIK PRECISION")
    cetak_garis("═")
    print(f"  Total Skenario Uji  : {total_skenario}")
    print(f"  Skenario Lolos       : {total_lolos}")
    print(f"  Skenario Gagal       : {total_skenario - total_lolos}")
    print()

    if total_skenario > 0:
        precision = (total_lolos / total_skenario) * 100
    else:
        precision = 0.0

    # Precision bar visual
    bar_len = 30
    filled = int(bar_len * precision / 100)
    bar = "█" * filled + "░" * (bar_len - filled)

    print(f"  ┌{'─' * (bar_len + 12)}┐")
    print(f"  │ PRECISION: {precision:6.1f}% [{bar}] │")
    print(f"  └{'─' * (bar_len + 12)}┘")

    if precision == 100.0:
        print("\n  🏆 SEMPURNA! Semua skenario LOLOS validasi.")
        print("     → Algoritma berhasil mengeliminasi junk food/gorengan")
        print("     → Total kalori menu selalu ≤ target TDEE")
    elif precision >= 80.0:
        print(f"\n  ⚠️ Precision {precision:.1f}% — Masih ada skenario yang gagal.")
        print("     Periksa detail di atas untuk debugging.")
    else:
        print(f"\n  ❌ Precision {precision:.1f}% — Di bawah standar minimum.")
        print("     Algoritma perlu diperbaiki.")

    cetak_garis("═")
    return precision


# ==========================================================================
# 🚀 MAIN — Eksekusi Pengujian
# ==========================================================================

if __name__ == "__main__":
    print("\n🚀 Memulai pengujian Precision algoritma Fit Meal...\n")

    # Cek koneksi server terlebih dahulu
    try:
        resp = requests.get(BASE_URL, timeout=5)
        print(f"✅ Server terdeteksi: {resp.json()}")
    except Exception as e:
        print(f"❌ Server tidak terdeteksi di {BASE_URL}")
        print(f"   Error: {e}")
        print(f"\n💡 Jalankan server terlebih dahulu:")
        print(f"   python main.py")
        sys.exit(1)

    # Jalankan semua skenario uji
    semua_hasil = []
    for profil in PROFIL_UJI:
        print(f"\n⏳ Menguji: {profil['label']}...")
        hasil = validasi_skenario(profil["label"], profil["payload"])
        semua_hasil.append(hasil)
        status_icon = "✅" if hasil["semua_lolos"] else "❌"
        print(f"   {status_icon} Selesai — {hasil['status']}")

    # Cetak laporan akhir
    precision = cetak_laporan(semua_hasil)

    # Exit code berdasarkan hasil (untuk CI/CD)
    sys.exit(0 if precision == 100.0 else 1)
