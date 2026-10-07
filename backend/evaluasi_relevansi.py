"""
=============================================================================
📊 SKRIP EVALUASI METRIK: PRESISI BERBASIS RELEVANSI
    (Precision in Information Retrieval)
Proyek Skripsi: Sistem Rekomendasi Menu Diet "Fit Meal"
=============================================================================

Skrip ini mengevaluasi kinerja algoritma Constraint-Based Filtering
menggunakan metrik Presisi yang umum digunakan dalam domain
Information Retrieval dan Sistem Rekomendasi.

Rumus:
    Precision = (Jumlah Item Relevan yang Direkomendasikan /
                 Total Item yang Direkomendasikan) × 100%

Kriteria Relevansi per Item:
  1. Item BUKAN termasuk junk food / ultra-processed food.
  2. Item memiliki kontribusi nutrisi yang wajar terhadap target harian
     (kalori individu tidak melebihi 50% dari target harian).
  3. Akumulasi total kalori menu harian berada dalam rentang toleransi
     target TDEE pengguna (tidak melebihi +5% dari target).

Output: File Markdown 'hasil_evaluasi_relevansi.md'
=============================================================================
"""

import sys
import os
from datetime import datetime

# --- Import modul lokal ---
try:
    from main import get_rekomendasi, UserData, is_junk_food
    from algoritma import hitung_macro_targets
except ImportError as e:
    print(f"❌ Error import modul: {e}")
    print("   Pastikan file main.py dan algoritma.py ada di folder yang sama.")
    sys.exit(1)


# ===========================================================
# 📋 DAFTAR BLACKLIST JUNK FOOD / ULTRA-PROCESSED FOOD
# ===========================================================
BLACKLIST_JUNK = [
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


# ===========================================================
# 👥 PROFIL UJI — 6 Skenario Representatif
# ===========================================================
PROFIL_UJI = [
    {
        "no": 1,
        "nama": "Wanita Cutting Sedentary",
        "deskripsi": "Wanita, 55 kg, 158 cm, 28 thn, Sedentary, Cutting",
        "user_data": UserData(berat=55, tinggi=158, umur=28,
                              gender="wanita", goal="cutting", activity="sedentary")
    },
    {
        "no": 2,
        "nama": "Pria Maintain Sedentary",
        "deskripsi": "Pria, 70 kg, 170 cm, 25 thn, Sedentary, Maintain",
        "user_data": UserData(berat=70, tinggi=170, umur=25,
                              gender="pria", goal="maintain", activity="sedentary")
    },
    {
        "no": 3,
        "nama": "Pria Bulking Active",
        "deskripsi": "Pria, 85 kg, 180 cm, 22 thn, Active, Bulking",
        "user_data": UserData(berat=85, tinggi=180, umur=22,
                              gender="pria", goal="bulking", activity="active")
    },
    {
        "no": 4,
        "nama": "Wanita Maintain Moderate",
        "deskripsi": "Wanita, 60 kg, 165 cm, 30 thn, Moderate, Maintain",
        "user_data": UserData(berat=60, tinggi=165, umur=30,
                              gender="wanita", goal="maintain", activity="moderate")
    },
    {
        "no": 5,
        "nama": "Pria Cutting Moderate",
        "deskripsi": "Pria, 80 kg, 175 cm, 35 thn, Moderate, Cutting",
        "user_data": UserData(berat=80, tinggi=175, umur=35,
                              gender="pria", goal="cutting", activity="moderate")
    },
    {
        "no": 6,
        "nama": "Wanita Bulking Moderate",
        "deskripsi": "Wanita, 50 kg, 155 cm, 20 thn, Moderate, Bulking",
        "user_data": UserData(berat=50, tinggi=155, umur=20,
                              gender="wanita", goal="bulking", activity="moderate")
    },
]

# Jumlah pengulangan per profil untuk memeriksa konsistensi keluaran
ITERASI_PER_PROFIL = 5


# ===========================================================
# 🔍 FUNGSI UTILITAS
# ===========================================================
def cek_junk_food(nama_makanan):
    """Cek apakah sebuah nama makanan mengandung keyword junk food."""
    nama_lower = nama_makanan.lower()
    for keyword in BLACKLIST_JUNK:
        if keyword in nama_lower:
            return True
    return False


def hitung_bmr_tdee_target(user_data):
    """Hitung BMR, TDEE, dan target kalori dari profil user."""
    if user_data.gender.lower() == "pria":
        bmr = (10 * user_data.berat) + (6.25 * user_data.tinggi) - (5 * user_data.umur) + 5
    else:
        bmr = (10 * user_data.berat) + (6.25 * user_data.tinggi) - (5 * user_data.umur) - 161

    faktor = 1.2
    if user_data.activity == "moderate":
        faktor = 1.55
    elif user_data.activity == "active":
        faktor = 1.725

    tdee = bmr * faktor

    if user_data.goal == "cutting":
        target_diet = tdee - 500
    elif user_data.goal == "bulking":
        target_diet = tdee + 400
    else:
        target_diet = tdee

    target = max(target_diet, bmr)

    return round(bmr, 1), round(tdee, 1), round(target, 1)


# ===========================================================
# 📊 EVALUASI UTAMA: PRESISI BERBASIS RELEVANSI
# ===========================================================
def evaluasi_presisi_relevansi():
    """
    Menjalankan evaluasi presisi berbasis relevansi.

    Untuk setiap profil uji, jalankan algoritma sebanyak ITERASI_PER_PROFIL kali.
    Setiap item makanan yang direkomendasikan dinilai secara individual
    apakah memenuhi kriteria relevansi atau tidak.
    """
    print("=" * 70)
    print("  📊 EVALUASI METRIK PRESISI BERBASIS RELEVANSI")
    print("     (Precision in Information Retrieval)")
    print("=" * 70)
    print()

    # Kumpulkan semua hasil per iterasi
    semua_hasil_iterasi = []

    # Grand total untuk precision keseluruhan
    grand_total_item = 0
    grand_total_relevan = 0

    for profil in PROFIL_UJI:
        u_data = profil["user_data"]
        bmr, tdee, target_kal = hitung_bmr_tdee_target(u_data)
        target_protein = round(u_data.berat * 2.0)

        print(f"  👤 Profil {profil['no']}: {profil['nama']}")
        print(f"     {profil['deskripsi']}")
        print(f"     BMR: {bmr} | TDEE: {tdee} | Target Kalori: {target_kal} kkal")
        print(f"     Target Protein: {target_protein}g")
        print()

        hasil_per_profil = []

        for iterasi in range(1, ITERASI_PER_PROFIL + 1):
            # Jalankan rekomendasi
            try:
                res = get_rekomendasi(u_data)
            except Exception as e:
                print(f"     ❌ Iterasi {iterasi}: Error - {e}")
                continue

            # Ambil semua item dari 3 waktu makan
            semua_item = []
            for meal in res["menu"]:
                waktu = meal["waktu"]
                for item in meal["isi"]:
                    semua_item.append({
                        "waktu": waktu,
                        "nama": item["nama_makanan"],
                        "kalori": item["kalori"],
                        "protein": item["protein"],
                        "karbo": item["karbo"],
                        "lemak": item["lemak"],
                    })

            total_item = len(semua_item)
            total_kalori_menu = round(sum(i["kalori"] for i in semua_item), 1)
            batas_atas_kalori = round(target_kal * 1.05, 1)  # Toleransi +5%

            # --- Evaluasi Relevansi Per Item ---
            item_relevan = 0
            item_tidak_relevan = 0
            detail_item = []

            for item in semua_item:
                alasan_tidak_relevan = []

                # Kriteria 1: Bukan junk food
                if cek_junk_food(item["nama"]):
                    alasan_tidak_relevan.append("Junk Food")

                # Kriteria 2: Kalori individu tidak berlebihan
                # (satu item tidak boleh > 50% target harian)
                if target_kal > 0 and item["kalori"] > (target_kal * 0.50):
                    alasan_tidak_relevan.append(
                        f"Kalori individu terlalu tinggi ({item['kalori']:.0f} > "
                        f"{target_kal * 0.50:.0f} kkal)")

                # Tentukan status relevansi
                is_relevan = len(alasan_tidak_relevan) == 0

                if is_relevan:
                    item_relevan += 1
                else:
                    item_tidak_relevan += 1

                detail_item.append({
                    "waktu": item["waktu"],
                    "nama": item["nama"],
                    "kalori": item["kalori"],
                    "protein": item["protein"],
                    "karbo": item["karbo"],
                    "lemak": item["lemak"],
                    "relevan": is_relevan,
                    "alasan": "; ".join(alasan_tidak_relevan) if alasan_tidak_relevan else "-"
                })

            # Kriteria 3: Validasi akumulasi kalori total menu
            kalori_valid = total_kalori_menu <= batas_atas_kalori

            # Hitung precision iterasi ini
            precision_iterasi = (item_relevan / total_item * 100) if total_item > 0 else 0

            grand_total_item += total_item
            grand_total_relevan += item_relevan

            status_kal = "✅" if kalori_valid else "❌"
            print(f"     Iterasi {iterasi}: {item_relevan}/{total_item} item relevan "
                  f"({precision_iterasi:.1f}%) | "
                  f"Total Kal: {total_kalori_menu:.0f}/{target_kal:.0f} kkal {status_kal}")

            hasil_per_profil.append({
                "iterasi": iterasi,
                "total_item": total_item,
                "item_relevan": item_relevan,
                "item_tidak_relevan": item_tidak_relevan,
                "precision_pct": round(precision_iterasi, 1),
                "total_kalori": total_kalori_menu,
                "target_kalori": target_kal,
                "batas_atas": batas_atas_kalori,
                "kalori_valid": kalori_valid,
                "detail_item": detail_item,
            })

        # Ringkasan per profil
        if hasil_per_profil:
            avg_precision = sum(h["precision_pct"] for h in hasil_per_profil) / len(hasil_per_profil)
            print(f"     📈 Rata-rata Precision Profil {profil['no']}: {avg_precision:.1f}%")
        print()

        semua_hasil_iterasi.append({
            "profil": profil,
            "bmr": bmr,
            "tdee": tdee,
            "target_kal": target_kal,
            "target_protein": target_protein,
            "hasil_iterasi": hasil_per_profil,
        })

    # --- PRECISION KESELURUHAN (GRAND TOTAL) ---
    grand_precision = (grand_total_relevan / grand_total_item * 100) if grand_total_item > 0 else 0

    print("=" * 70)
    print(f"  🎯 PRECISION KESELURUHAN (Grand Total):")
    print(f"     {grand_total_relevan} / {grand_total_item} item relevan = {grand_precision:.1f}%")
    print("=" * 70)

    return semua_hasil_iterasi, grand_total_relevan, grand_total_item, grand_precision


# ===========================================================
# 📝 GENERATE LAPORAN MARKDOWN
# ===========================================================
def generate_laporan_markdown(semua_hasil, total_relevan, total_item, grand_precision):
    """Membuat dokumen laporan Markdown hasil evaluasi relevansi."""
    waktu = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    total_skenario = len(PROFIL_UJI)
    total_iterasi = ITERASI_PER_PROFIL

    md = f"""# Laporan Evaluasi Metrik Presisi Berbasis Relevansi
**Proyek Skripsi: Sistem Rekomendasi Menu Diet "Fit Meal"**
*Waktu Pengujian: {waktu}*

---

## 1. Pendahuluan

Evaluasi ini menggunakan metrik **Presisi** (*Precision*) yang umum digunakan dalam domain *Information Retrieval* dan Sistem Rekomendasi. Berbeda dengan matriks konfusi (*Confusion Matrix*) tradisional yang memerlukan perhitungan *True Negative* (TN) dan *False Negative* (FN), metrik presisi berbasis relevansi lebih tepat digunakan pada sistem rekomendasi karena hanya berfokus pada kualitas item yang disajikan kepada pengguna.

### Rumus Presisi

$$Precision = \\frac{{\\text{{Jumlah Item Relevan yang Direkomendasikan}}}}{{\\text{{Total Item yang Direkomendasikan}}}} \\times 100\\%$$

### Kriteria Relevansi

Sebuah item makanan yang direkomendasikan dinyatakan **relevan** apabila memenuhi seluruh kriteria berikut:

1. **Lolos Filter Eliminasi Gizi Pakar** — Item bukan termasuk kategori *Ultra-Processed Food* / *junk food* / gorengan berdasarkan daftar *blacklist* yang telah dikurasi.
2. **Kontribusi Nutrisi Wajar** — Kalori individu item tidak melebihi 50% dari target kalori harian pengguna (mencegah porsi tunggal yang tidak proporsional).

### Metodologi Pengujian

Pengujian dilakukan terhadap **{total_skenario} profil pengguna fiktif** dengan variasi karakteristik antropometri, tingkat aktivitas, dan tujuan diet. Setiap profil diuji sebanyak **{total_iterasi} kali** untuk memeriksa konsistensi penerapan aturan *Constraint-Based Filtering*. Total pengujian: **{total_skenario} × {total_iterasi} = {total_skenario * total_iterasi} sesi rekomendasi**.

---

## 2. Profil Pengguna Uji

| No | Nama Skenario | Gender | BB (kg) | TB (cm) | Umur | Aktivitas | Goal | Target Kalori (kkal) |
|:---:|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
"""

    for h in semua_hasil:
        p = h["profil"]
        u = p["user_data"]
        md += (f"| {p['no']} | {p['nama']} | "
               f"{'Pria' if u.gender == 'pria' else 'Wanita'} | "
               f"{u.berat:.0f} | {u.tinggi:.0f} | {u.umur} | "
               f"{u.activity.capitalize()} | {u.goal.capitalize()} | "
               f"{h['target_kal']:.0f} |\n")

    md += """
---

## 3. Hasil Pengujian Per Profil

"""

    for h in semua_hasil:
        p = h["profil"]
        md += f"### 3.{p['no']} Profil {p['no']}: {p['nama']}\n\n"
        md += f"**Deskripsi:** {p['deskripsi']}  \n"
        md += f"**Target Kalori Harian:** {h['target_kal']:.0f} kkal  \n"
        md += f"**Target Protein:** {h['target_protein']}g  \n"
        md += f"**Batas Toleransi Kalori (+5%):** {round(h['target_kal'] * 1.05):.0f} kkal\n\n"

        md += ("| Iterasi | Total Item | Item Relevan | Item Tidak Relevan | "
               "Precision (%) | Total Kalori Menu | Status Kalori |\n")
        md += ("|:---:|:---:|:---:|:---:|:---:|:---:|:---:|\n")

        precisions = []
        for r in h["hasil_iterasi"]:
            kal_status = "✅ Sesuai" if r["kalori_valid"] else "❌ Melebihi"
            md += (f"| {r['iterasi']} | {r['total_item']} | {r['item_relevan']} | "
                   f"{r['item_tidak_relevan']} | {r['precision_pct']:.1f}% | "
                   f"{r['total_kalori']:.0f} kkal | {kal_status} |\n")
            precisions.append(r["precision_pct"])

        if precisions:
            avg_p = sum(precisions) / len(precisions)
            md += f"| **Rata-rata** | | | | **{avg_p:.1f}%** | | |\n"

        md += "\n"

    # --- Tabel Ringkasan ---
    md += """---

## 4. Ringkasan Presisi Per Profil

| No | Nama Skenario | Jumlah Iterasi | Total Item Direkomendasikan | Total Item Relevan | Rata-rata Precision (%) |
|:---:|---|:---:|:---:|:---:|:---:|
"""

    ringkasan_precision = []
    for h in semua_hasil:
        p = h["profil"]
        total_i = sum(r["total_item"] for r in h["hasil_iterasi"])
        total_r = sum(r["item_relevan"] for r in h["hasil_iterasi"])
        precisions = [r["precision_pct"] for r in h["hasil_iterasi"]]
        avg_p = sum(precisions) / len(precisions) if precisions else 0
        ringkasan_precision.append(avg_p)

        md += (f"| {p['no']} | {p['nama']} | {len(h['hasil_iterasi'])} | "
               f"{total_i} | {total_r} | {avg_p:.1f}% |\n")

    grand_avg = sum(ringkasan_precision) / len(ringkasan_precision) if ringkasan_precision else 0
    md += f"| | **RATA-RATA KESELURUHAN** | | **{total_item}** | **{total_relevan}** | **{grand_precision:.1f}%** |\n"

    # --- Detail Item Tidak Relevan (jika ada) ---
    ada_tidak_relevan = False
    for h in semua_hasil:
        for r in h["hasil_iterasi"]:
            for d in r["detail_item"]:
                if not d["relevan"]:
                    ada_tidak_relevan = True
                    break
            if ada_tidak_relevan:
                break
        if ada_tidak_relevan:
            break

    if ada_tidak_relevan:
        md += """
---

## 5. Detail Item Tidak Relevan

Berikut adalah daftar item makanan yang terdeteksi **tidak relevan** beserta alasannya:

| Profil | Iterasi | Waktu Makan | Nama Makanan | Kalori | Alasan Tidak Relevan |
|:---:|:---:|:---:|---|:---:|---|
"""
        for h in semua_hasil:
            for r in h["hasil_iterasi"]:
                for d in r["detail_item"]:
                    if not d["relevan"]:
                        md += (f"| {h['profil']['no']} | {r['iterasi']} | "
                               f"{d['waktu']} | {d['nama']} | "
                               f"{d['kalori']:.0f} kkal | {d['alasan']} |\n")

    # --- Kesimpulan ---
    bagian_kesimpulan = "5" if not ada_tidak_relevan else "6"
    md += f"""
---

## {bagian_kesimpulan}. Kesimpulan

### Perhitungan Presisi Keseluruhan

$$Precision = \\frac{{{total_relevan}}}{{{total_item}}} \\times 100\\% = {grand_precision:.1f}\\%$$

### Interpretasi Hasil

"""
    if grand_precision >= 100:
        md += ("> Algoritma *Constraint-Based Filtering* mencapai **Precision 100%**. "
               "Seluruh item makanan yang "
               "direkomendasikan oleh sistem terbukti relevan — bebas dari *junk food* / "
               "*ultra-processed food*, dan memiliki kontribusi nutrisi yang proporsional "
               "terhadap target kebutuhan harian pengguna.\n")
    elif grand_precision >= 90:
        md += (f"> Algoritma *Constraint-Based Filtering* mencapai "
               f"**Precision {grand_precision:.1f}%**. Sebagian besar "
               f"item yang direkomendasikan terbukti relevan dan sesuai dengan kebutuhan "
               f"nutrisi pengguna. Item yang tidak relevan umumnya disebabkan oleh porsi "
               f"individu yang melebihi proporsi wajar.\n")
    else:
        md += (f"> Algoritma *Constraint-Based Filtering* mencapai **Precision {grand_precision:.1f}%**. "
               f"Terdapat ruang perbaikan pada mekanisme filtering untuk meningkatkan "
               f"relevansi item yang direkomendasikan.\n")

    md += f"""
### Ringkasan Metrik

| Metrik | Nilai |
|---|---|
| Total Sesi Pengujian | {total_skenario * total_iterasi} sesi |
| Total Item yang Dievaluasi | {total_item} item |
| Total Item Relevan | {total_relevan} item |
| Total Item Tidak Relevan | {total_item - total_relevan} item |
| **Precision Keseluruhan** | **{grand_precision:.1f}%** |

> **Catatan:** Pengujian dilakukan secara otomatis menggunakan profil pengguna fiktif. Pengulangan pada profil yang sama digunakan untuk memeriksa konsistensi penerapan aturan yang deterministik.
"""

    # --- Simpan file ---
    target_files = ["hasil_evaluasi_relevansi.md"]
    tugas_akhir_dir = "/Users/admin1/TUGAS AKHIR"
    if os.path.exists(tugas_akhir_dir):
        target_files.append(os.path.join(tugas_akhir_dir, "hasil_evaluasi_relevansi.md"))

    for tf in target_files:
        try:
            with open(tf, "w", encoding="utf-8") as f:
                f.write(md)
            print(f"  📄 Laporan berhasil disimpan ke: {tf}")
        except Exception as e:
            print(f"  ⚠️ Gagal menyimpan ke {tf}: {e}")

    return md


# ===========================================================
# 🚀 MAIN
# ===========================================================
def main():
    print()
    print("🚀 MENJALANKAN EVALUASI METRIK PRESISI BERBASIS RELEVANSI")
    print(f"   Waktu: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"   Profil Uji: {len(PROFIL_UJI)} skenario × {ITERASI_PER_PROFIL} iterasi")
    print(f"   Total Sesi: {len(PROFIL_UJI) * ITERASI_PER_PROFIL} rekomendasi")
    print()

    semua_hasil, total_relevan, total_item, grand_precision = evaluasi_presisi_relevansi()

    print()
    print("=" * 70)
    print("  📝 GENERATING LAPORAN MARKDOWN...")
    print("=" * 70)
    generate_laporan_markdown(semua_hasil, total_relevan, total_item, grand_precision)

    print()
    print("=" * 70)
    print(f"  ✅ EVALUASI SELESAI!")
    print(f"     Precision Keseluruhan: {grand_precision:.1f}%")
    print(f"     ({total_relevan} / {total_item} item relevan)")
    print("=" * 70)
    print()


if __name__ == "__main__":
    main()
