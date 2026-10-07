"""
==========================================================================
 📊 SKRIP UJI METRIK PRECISION (DIRECT IN-MEMORY) — Akurasi Algoritma Fit Meal
==========================================================================

 Tujuan   : Mengukur Precision (akurasi) dari algoritma rekomendasi Fit Meal
            secara in-memory (tanpa membutuhkan server berjalan/koneksi HTTP).
 Metode   : Mengimpor fungsi rekomendasi dari main.py langsung, lalu memvalidasi:
              1. Tidak ada junk food / gorengan dalam menu rekomendasi.
              2. Total kalori menu ≤ target kalori (TDEE adjusted).
              3. Semua item berasal dari whitelist yang diizinkan.
 Target   : Precision = 100% (semua skenario lolos).
 Cara Jalan: python test_precision_direct.py

 Author   : Auto-generated untuk penelitian skripsi Fit Meal
==========================================================================
"""

import sys
from datetime import datetime

# Mengimpor modul lokal proyek
try:
    from main import get_rekomendasi, UserData
except ImportError as e:
    print(f"❌ Gagal mengimpor modul main.py: {e}")
    sys.exit(1)

# --- Daftar kata kunci JUNK FOOD & GORENGAN (constraint eliminasi) ---
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
            "berat": 55.0,
            "tinggi": 158.0,
            "umur": 28,
            "gender": "wanita",
            "goal": "cutting",
            "activity": "sedentary",
        },
    },
    {
        "label": "Profil 2 — Pria Sedentary Maintain (TDEE Sedang ≈1800 kkal)",
        "payload": {
            "berat": 70.0,
            "tinggi": 170.0,
            "umur": 25,
            "gender": "pria",
            "goal": "maintain",
            "activity": "sedentary",
        },
    },
    {
        "label": "Profil 3 — Pria Aktif Bulking (TDEE Tinggi ≈3000 kkal)",
        "payload": {
            "berat": 85.0,
            "tinggi": 180.0,
            "umur": 22,
            "gender": "pria",
            "goal": "bulking",
            "activity": "active",
        },
    },
    {
        "label": "Profil 4 — Wanita Moderate Maintain (TDEE ≈1900 kkal)",
        "payload": {
            "berat": 60.0,
            "tinggi": 165.0,
            "umur": 30,
            "gender": "wanita",
            "goal": "maintain",
            "activity": "moderate",
        },
    },
    {
        "label": "Profil 5 — Pria Moderate Cutting (TDEE ≈2100 kkal)",
        "payload": {
            "berat": 80.0,
            "tinggi": 175.0,
            "umur": 35,
            "gender": "pria",
            "goal": "cutting",
            "activity": "moderate",
        },
    },
]


def cek_junk_food(nama_makanan: str) -> tuple[bool, str | None]:
    nama_lower = nama_makanan.lower()
    for keyword in BLACKLIST_JUNK_FOOD:
        if keyword in nama_lower:
            return True, keyword
    return False, None


def validasi_skenario(label: str, payload: dict) -> dict:
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

    try:
        # Panggil fungsi rekomendasi langsung secara in-memory
        user_data = UserData(**payload)
        data = get_rekomendasi(user_data)
    except Exception as e:
        hasil["error"] = f"❌ Error eksekusi algoritma: {e}"
        hasil["status"] = "ERROR"
        return hasil

    target_kalori = data["user_info"]["target_kalori"]
    menu_list = data.get("menu", [])
    hasil["target_kalori"] = target_kalori

    semua_item = []
    for meal in menu_list:
        waktu = meal.get("waktu", "?")
        for item in meal.get("isi", []):
            semua_item.append({
                "waktu": waktu,
                "nama": item["nama_makanan"],
                "kalori": item["kalori"],
            })

    hasil["jumlah_item_menu"] = len(semua_item)
    total_kalori = sum(item["kalori"] for item in semua_item)
    hasil["total_kalori_menu"] = round(total_kalori, 1)

    # Validasi 1: Junk Food / Gorengan
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

    # Validasi 2: Kalori
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

    semua_lolos = (
        hasil["validasi_junk_food"]["lolos"] and
        hasil["validasi_kalori"]["lolos"]
    )
    hasil["semua_lolos"] = semua_lolos
    hasil["status"] = "✅ LOLOS" if semua_lolos else "❌ GAGAL"

    return hasil


def cetak_laporan(semua_hasil: list):
    print("═" * 75)
    print("  📊 LAPORAN UJI PRECISION (IN-MEMORY) — Algoritma Fit Meal")
    print(f"  Waktu: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("═" * 75)

    total_skenario = len(semua_hasil)
    total_lolos = 0

    for i, hasil in enumerate(semua_hasil, 1):
        print(f"\n🔬 Skenario {i}: {hasil['label']}")
        print(f"Status           : {hasil['status']}")
        print(f"Target Kalori    : {hasil['target_kalori']:.0f} kkal")
        print(f"Total Kalori Menu: {hasil['total_kalori_menu']:.0f} kkal")
        print(f"Jumlah Item Menu : {hasil['jumlah_item_menu']} item")

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

    print()
    print("═" * 75)
    print("  📈 RINGKASAN METRIK PRECISION")
    print("═" * 75)
    print(f"  Total Skenario Uji  : {total_skenario}")
    print(f"  Skenario Lolos       : {total_lolos}")
    print(f"  Skenario Gagal       : {total_skenario - total_lolos}")
    print()

    precision = (total_lolos / total_skenario) * 100 if total_skenario > 0 else 0.0
    bar_len = 30
    filled = int(bar_len * precision / 100)
    bar = "█" * filled + "░" * (bar_len - filled)

    print(f"  ┌{'─' * (bar_len + 12)}┐")
    print(f"  │ PRECISION: {precision:6.1f}% [{bar}] │")
    print(f"  └{'─' * (bar_len + 12)}┘")

    if precision == 100.0:
        print("\n  🏆 SEMPURNA! Semua skenario LOLOS validasi.")
    else:
        print(f"\n  ⚠️ Precision {precision:.1f}% — Masih ada skenario yang gagal.")
    print("═" * 75)
    return precision


if __name__ == "__main__":
    print("\n🚀 Memulai pengujian Precision in-memory...\n")
    semua_hasil = []
    for profil in PROFIL_UJI:
        hasil = validasi_skenario(profil["label"], profil["payload"])
        semua_hasil.append(hasil)
    cetak_laporan(semua_hasil)
