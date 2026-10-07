"""
=============================================================================
📊 KALKULATOR SUS (System Usability Scale) — Fit Meal
=============================================================================
Script untuk menghitung skor SUS dari data kuesioner responden.

Cara pakai:
  1. Isi data responden di variabel RESPONDEN_DATA di bawah
  2. Jalankan: python hitung_sus.py
  3. Hasil otomatis dihitung dan disimpan ke file

Referensi: Brooke, J. (1996). SUS - A Quick and Dirty Usability Scale.
=============================================================================
"""

from datetime import datetime

# Warna terminal
GREEN  = "\033[92m"
RED    = "\033[91m"
YELLOW = "\033[93m"
CYAN   = "\033[96m"
BOLD   = "\033[1m"
RESET  = "\033[0m"
DIM    = "\033[2m"

# ==========================================
# 📝 DATA RESPONDEN
# ==========================================
# Isi jawaban 10 pernyataan SUS (skala 1-5) untuk setiap responden.
# Pernyataan:
#   Q1:  Saya pikir saya akan sering menggunakan aplikasi ini
#   Q2:  Saya merasa aplikasi ini terlalu rumit
#   Q3:  Saya merasa aplikasi ini mudah digunakan
#   Q4:  Saya perlu bantuan teknis untuk menggunakan aplikasi ini
#   Q5:  Fitur-fitur terintegrasi dengan baik
#   Q6:  Terlalu banyak ketidakkonsistenan
#   Q7:  Kebanyakan orang akan cepat belajar
#   Q8:  Aplikasi ini sangat sulit digunakan
#   Q9:  Saya sangat percaya diri menggunakan aplikasi ini
#   Q10: Perlu belajar banyak sebelum menggunakan aplikasi ini

RESPONDEN_DATA = [
    # Contoh data (GANTI dengan data asli responden Anda):
    #        Q1  Q2  Q3  Q4  Q5  Q6  Q7  Q8  Q9  Q10
    {"nama": "Responden 1", "jawaban": [4, 2, 5, 1, 4, 2, 5, 1, 4, 1]},
    {"nama": "Responden 2", "jawaban": [5, 1, 4, 2, 5, 1, 4, 1, 5, 2]},
    {"nama": "Responden 3", "jawaban": [4, 2, 4, 1, 5, 2, 4, 2, 4, 1]},
    {"nama": "Responden 4", "jawaban": [3, 2, 5, 1, 4, 1, 5, 1, 5, 1]},
    {"nama": "Responden 5", "jawaban": [5, 1, 5, 1, 5, 1, 5, 1, 5, 1]},
    # Tambahkan responden lain di sini...
]


def hitung_sus_score(jawaban):
    """
    Menghitung SUS score dari 10 jawaban (skala 1-5).

    Rumus:
    - Pernyataan ganjil (1,3,5,7,9) → positif: skor = jawaban - 1
    - Pernyataan genap (2,4,6,8,10) → negatif: skor = 5 - jawaban
    - Total skor × 2.5 = SUS Score (0-100)
    """
    if len(jawaban) != 10:
        raise ValueError("Harus ada 10 jawaban!")

    total = 0
    for i in range(10):
        if (i + 1) % 2 == 1:  # Ganjil (1,3,5,7,9)
            total += (jawaban[i] - 1)
        else:  # Genap (2,4,6,8,10)
            total += (5 - jawaban[i])

    return total * 2.5


def get_grade(score):
    """Konversi SUS score ke grade."""
    if score >= 90: return "A+", "Best Imaginable", GREEN
    elif score >= 80: return "A", "Excellent", GREEN
    elif score >= 70: return "B", "Good", GREEN
    elif score >= 60: return "C", "OK / Acceptable", YELLOW
    elif score >= 50: return "D", "Marginal", YELLOW
    else: return "F", "Not Acceptable", RED


def main():
    print(f"\n{BOLD}{CYAN}")
    print("╔═══════════════════════════════════════════════════════════════╗")
    print("║       📊 KALKULATOR SUS — SYSTEM USABILITY SCALE            ║")
    print("║       Sistem Rekomendasi Menu Diet Fit Meal                 ║")
    print("╚═══════════════════════════════════════════════════════════════╝")
    print(f"{RESET}")

    if not RESPONDEN_DATA:
        print(f"  {RED}❌ Belum ada data responden! Isi RESPONDEN_DATA di script.{RESET}")
        return

    print(f"  Jumlah Responden: {BOLD}{len(RESPONDEN_DATA)}{RESET}\n")

    # Header tabel
    print(f"  {'No':<5} {'Nama':<20} {'Q1':>3} {'Q2':>3} {'Q3':>3} {'Q4':>3} {'Q5':>3} {'Q6':>3} {'Q7':>3} {'Q8':>3} {'Q9':>3} {'Q10':>4} │ {'SUS':>6} {'Grade':>6} {'Keterangan'}")
    print(f"  {'─'*110}")

    scores = []
    grade_results = []

    for idx, resp in enumerate(RESPONDEN_DATA, 1):
        try:
            sus = hitung_sus_score(resp["jawaban"])
            grade, desc, color = get_grade(sus)
            scores.append(sus)
            grade_results.append({"nama": resp["nama"], "score": sus, "grade": grade, "desc": desc})

            j = resp["jawaban"]
            print(f"  {idx:<5} {resp['nama']:<20} "
                  f"{j[0]:>3} {j[1]:>3} {j[2]:>3} {j[3]:>3} {j[4]:>3} "
                  f"{j[5]:>3} {j[6]:>3} {j[7]:>3} {j[8]:>3} {j[9]:>4} │ "
                  f"{color}{sus:>5.1f}{RESET}  {color}{grade:>4}{RESET}   {desc}")
        except Exception as e:
            print(f"  {idx:<5} {resp['nama']:<20} → {RED}Error: {e}{RESET}")

    # Ringkasan
    if scores:
        avg_score = sum(scores) / len(scores)
        min_score = min(scores)
        max_score = max(scores)
        avg_grade, avg_desc, avg_color = get_grade(avg_score)

        print(f"\n  {'─'*110}")
        print(f"\n  {BOLD}📊 RINGKASAN HASIL SUS{RESET}")
        print(f"  {'─'*40}")
        print(f"  Jumlah Responden : {len(scores)}")
        print(f"  Skor Minimum     : {min_score:.1f}")
        print(f"  Skor Maksimum    : {max_score:.1f}")
        print(f"  {BOLD}Rata-rata SUS      : {avg_color}{avg_score:.1f}{RESET}")
        print(f"  {BOLD}Grade              : {avg_color}{avg_grade} — {avg_desc}{RESET}")

        # Benchmark
        print(f"\n  {DIM}📌 Benchmark: Rata-rata SUS global = 68.0{RESET}")
        if avg_score >= 68:
            print(f"  {GREEN}✅ Skor aplikasi Fit Meal DI ATAS rata-rata global!{RESET}")
        else:
            print(f"  {YELLOW}⚠️ Skor aplikasi Fit Meal DI BAWAH rata-rata global.{RESET}")

    # Export ke file
    export_results(scores, grade_results)


def export_results(scores, grade_results):
    """Simpan hasil ke file."""
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"hasil_sus_score_{ts}.txt"
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    try:
        with open(filename, "w", encoding="utf-8") as f:
            f.write("=" * 70 + "\n")
            f.write("  LAPORAN HASIL SUS (SYSTEM USABILITY SCALE)\n")
            f.write("  Sistem Rekomendasi Menu Diet Fit Meal\n")
            f.write("=" * 70 + "\n\n")
            f.write(f"  Waktu Pengujian    : {timestamp}\n")
            f.write(f"  Jumlah Responden   : {len(scores)}\n\n")

            f.write(f"  {'No':<5} {'Nama':<25} {'SUS Score':>10} {'Grade':>7} {'Keterangan'}\n")
            f.write(f"  {'-'*65}\n")

            for idx, r in enumerate(grade_results, 1):
                f.write(f"  {idx:<5} {r['nama']:<25} {r['score']:>9.1f} {r['grade']:>7} {r['desc']}\n")

            if scores:
                avg = sum(scores) / len(scores)
                grade, desc, _ = get_grade(avg)
                f.write(f"\n  {'-'*65}\n")
                f.write(f"  {'':>5} {'RATA-RATA':<25} {avg:>9.1f} {grade:>7} {desc}\n")
                f.write(f"\n  Benchmark global SUS: 68.0\n")
                f.write(f"  Status: {'DI ATAS' if avg >= 68 else 'DI BAWAH'} rata-rata global\n")

            f.write(f"\n  Interpretasi Skor SUS:\n")
            f.write(f"  90-100 = A+ (Best Imaginable)\n")
            f.write(f"  80-89  = A  (Excellent)\n")
            f.write(f"  70-79  = B  (Good)\n")
            f.write(f"  60-69  = C  (OK/Acceptable)\n")
            f.write(f"  50-59  = D  (Marginal)\n")
            f.write(f"  <50    = F  (Not Acceptable)\n")

            f.write(f"\n  Referensi: Brooke, J. (1996). SUS - A Quick and Dirty Usability Scale.\n")
            f.write(f"\n  [END OF REPORT]\n")

        print(f"\n  📄 Laporan disimpan ke: {CYAN}{filename}{RESET}")
    except Exception as e:
        print(f"  ⚠️ Gagal simpan: {e}")


if __name__ == "__main__":
    main()
