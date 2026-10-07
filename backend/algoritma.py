import sqlite3

DB_NAME = "skripsi_diet.db"

# ===========================================================
# ✅ SISTEM WHITELIST — Hanya Makanan Familiar yang Diizinkan
# ===========================================================
# Pendekatan: "Semua DILARANG, kecuali yang secara eksplisit
# terdaftar di bawah ini." Daftar ini menjadi hard constraint kandidat lokal.
#
# Format: list of keyword tuples → (keyword_match, display_name)
#   - keyword_match : substring yang harus ada di nama makanan (lowercase)
#   - display_name  : nama yang ditampilkan ke user (dengan porsi)
#
# Jika display_name = None, maka nama asli dari database dipakai.
# ===========================================================

WHITELIST = {
    "Karbo": [
        # --- Nasi ---
        ("nasi putih (1 piring sedang)", None),
        ("nasi merah (1 piring sedang)", None),
        ("nasi hitam (1 piring)", None),
        ("nasi jagung (1 piring)", None),
        ("nasi beras merah", "Nasi Beras Merah (1 piring)"),
        ("nasi jagung", "Nasi Jagung (1 piring)"),
        ("nasi putih", "Nasi Putih (1 centong)"),
        # --- Umbi & Kentang ---
        ("kentang rebus (1 sedang)", None),
        ("kentang rebus", "Kentang Rebus (1 buah sedang)"),
        ("ubi cilembu oven", None),
        ("ubi cilembu", "Ubi Cilembu Panggang (1 buah sedang)"),
        ("ubi jalar merah", "Ubi Jalar Merah Kukus (1 buah)"),
        ("ubi jalar putih", "Ubi Jalar Putih Kukus (1 buah)"),
        ("ubi jalar kuning", "Ubi Jalar Kuning Kukus (1 buah)"),
        ("singkong rebus (1 potong)", None),
        ("singkong rebus", "Singkong Rebus (1 potong)"),
        ("singkong kukus", "Singkong Kukus (1 potong)"),
        ("ketela pohon/singkong kukus", "Singkong Kukus (1 potong)"),
        # --- Jagung ---
        ("jagung rebus (1 bonggol)", None),
        ("jagung rebus", "Jagung Rebus (1 bonggol)"),
        ("jagung muda rebus", "Jagung Muda Rebus (1 bonggol)"),
        ("jagung kuning pipil rebus", "Jagung Pipil Rebus (100g)"),
        # --- Roti & Oat ---
        ("roti tawar putih (1 lembar)", None),
        ("roti gandum (1 lembar)", None),
        ("roti putih", "Roti Tawar Putih (1 lembar)"),
        ("sari roti tawar", "Roti Tawar (1 lembar)"),
        ("havermout", "Havermut / Oatmeal (1 mangkok)"),
        # --- Lontong & Ketupat ---
        ("lontong polos (1 buah)", None),
        ("ketupat (1 buah)", None),
        # --- Talas ---
        ("talas bogor kukus", "Talas Bogor Kukus (100g)"),
        ("belitung talas kukus", "Talas Belitung Kukus (100g)"),
        ("bentul talas kukus", "Talas Bentul Kukus (100g)"),
        # --- Papeda ---
        ("papeda", "Papeda (1 porsi)"),
    ],

    "Hewani": [
        # --- Ayam ---
        ("dada ayam rebus (100g)", None),
        ("dada ayam bakar", "Dada Ayam Bakar (100g)"),
        ("ayam bakar taliwang", None),
        ("sate ayam madura", None),
        # --- Ikan (familiar) ---
        ("ikan kembung bakar", "Ikan Kembung Bakar (1 ekor)"),
        ("ikan kembung", "Ikan Kembung (1 ekor)"),
        ("ikan mas pepes", "Ikan Mas Pepes (1 ekor)"),
        ("ikan mas", "Ikan Mas (1 ekor)"),
        ("ikan salmon pan seared", None),
        ("ikan patin pindang", None),
        ("ikan patin bakar", "Ikan Patin Bakar (1 potong)"),
        ("ikan bandeng", "Ikan Bandeng (1 potong)"),
        ("ikan bawal", "Ikan Bawal (1 ekor)"),
        ("ikan mujair pepes", "Ikan Mujair Pepes (1 ekor)"),
        ("ikan nila", "Ikan Nila (1 ekor)"),
        ("ikan gurame", "Ikan Gurame (1 potong)"),
        ("gurame asem manis", "Gurame Asam Manis (1 porsi)"),
        ("ikan tongkol", "Ikan Tongkol (1 potong)"),
        ("ikan tuna", "Ikan Tuna (1 potong)"),
        ("ikan layang", "Ikan Layang (1 ekor)"),
        ("ikan lemuru", "Ikan Lemuru (1 ekor)"),
        ("ikan baung bakar", "Ikan Baung Bakar (1 potong)"),
        ("ikan lais bakar", "Ikan Lais Bakar (1 potong)"),
        ("ikan papuyu bakar", "Ikan Papuyu Bakar (1 potong)"),
        ("ikan ekor kuning", "Ikan Ekor Kuning (1 potong)"),
        ("sate bandeng", "Sate Bandeng (1 potong)"),
        ("pindang ikan", "Pindang Ikan (1 potong)"),
        ("peda ikan", "Peda Ikan (1 potong)"),
        # --- Udang, Cumi, Kerang ---
        ("kerang rebus (1 porsi)", None),
        ("udang rebus", "Udang Rebus (100g)"),
        ("cumi rebus", "Cumi Rebus (100g)"),
        # --- Telur ---
        ("telur rebus (1 butir)", None),
        ("telur puyuh rebus", None),
        ("sate telur puyuh", None),
        ("telur ayam bagian putih", "Putih Telur Ayam (1 butir)"),
        ("telur bebek bagian putih", "Putih Telur Bebek (1 butir)"),
        ("telur bebek ceplok", "Telur Bebek Ceplok (1 butir)"),
        ("kalio telur", "Telur Kalio (1 butir)"),
        # --- Olahan ikan masakan ---
        ("ikan asar merah masakan", "Ikan Asar Merah (1 potong)"),
        ("ikan sanggang masakan", "Ikan Sanggang (1 potong)"),
    ],

    "Nabati": [
        # --- Tahu ---
        ("pepes tahu (1 bungkus)", None),
        ("tahu putih (1 potong besar)", None),
        ("tahu rebus", "Tahu Rebus (1 potong)"),
        ("tahu kukus", "Tahu Kukus (1 potong)"),
        # --- Tempe ---
        ("tempe rebus/kukus (100g)", None),
        ("tempe gembus", "Tempe Gembus (1 potong)"),
        ("tempe kacang belimbing", "Tempe Kacang (1 potong)"),
        # --- Edamame ---
        ("edamame rebus (1 mangkok)", None),
        # --- Kacang-kacangan ---
        ("kacang merah", "Kacang Merah Rebus (100g)"),
        ("kacang kedelai rebus", "Kacang Kedelai Rebus (100g)"),
        ("kacang kedelai kukus", "Kacang Kedelai Kukus (100g)"),
        ("kacang bogor rebus", "Kacang Bogor Rebus (100g)"),
        ("kacang gude rebus", "Kacang Gude Rebus (100g)"),
        ("kacang tolo rebus", "Kacang Tolo Rebus (100g)"),
        ("kacang tunggak rebus", "Kacang Tunggak Rebus (100g)"),
        ("kacang belimbing tempe", "Tempe Kacang Belimbing (100g)"),
        # --- Oncom ---
        ("oncom kacang tanah pepes", "Pepes Oncom Kacang (1 bungkus)"),
        ("oncom kedele", "Oncom Kedelai (1 potong)"),
        ("oncom pepes", "Pepes Oncom (1 bungkus)"),
        ("oncom", "Oncom (1 potong)"),
        # --- Kembang Tahu ---
        ("kembang tahu", "Kembang Tahu (1 lembar)"),
        # --- Toge ---
        ("toge kacang ijo", "Toge Kacang Hijau (100g)"),
        ("toge kacang tunggak", "Toge Kacang Tunggak (100g)"),
        ("tempe gembus yogya", "Tempe Gembus Yogya (1 potong)"),
    ],

    "Sayur": [
        # --- Masakan jadi (seeded) ---
        ("sayur asem (1 mangkok)", None),
        ("sayur bayam bening (1 mangkok)", None),
        ("sayur sop (1 mangkok)", None),
        ("capcay kuah (1 porsi)", None),
        ("capcay goreng (1 porsi)", None),
        ("gado-gado (1 porsi lengkap)", None),
        ("karedok (1 porsi)", None),
        ("brokoli rebus (100g)", None),
        ("sayur asem jakarta (1 mangkok)", None),
        ("tumis sawi putih (1 porsi)", None),
        ("ulukutek leunca (1 porsi)", None),
        ("cah kailan (1 porsi)", None),
        # --- Sayuran dari CSV (bahan siap masak) ---
        ("bayam kukus", "Bayam Kukus (100g)"),
        ("kangkung", "Kangkung (100g)"),
        ("kangkung kukus", "Kangkung Kukus (100g)"),
        ("kangkung rebus", "Kangkung Rebus (100g)"),
        ("kangkung tondano", "Kangkung (100g)"),
        ("buncis rebus", "Buncis Rebus (100g)"),
        ("buncis asam", "Buncis Asam (100g)"),
        ("buncis", "Buncis (100g)"),
        ("wortel kukus", "Wortel Kukus (100g)"),
        ("wortel rebus", "Wortel Rebus (100g)"),
        ("sawi", "Sawi (100g)"),
        ("kacang panjang kukus", "Kacang Panjang Kukus (100g)"),
        ("kacang panjang", "Kacang Panjang (100g)"),
        ("labu siam", "Labu Siam (100g)"),
        ("terong kukus", "Terong Kukus (100g)"),
        ("terong asam", "Terong Asam (100g)"),
        ("terong belanda", "Terong Belanda (100g)"),
        ("terong", "Terong (100g)"),
        ("ketimun", "Ketimun (100g)"),
        ("selada", "Selada (100g)"),
        ("taoge seduh", "Toge Seduh (100g)"),
        ("toge seduh", "Toge Seduh (100g)"),
        ("toge kedelai", "Toge Kedelai (100g)"),
        ("pare", "Pare (100g)"),
        ("paria (pare)", "Pare (100g)"),
        ("paria putih kukus", "Pare Putih Kukus (100g)"),
        ("gambas (oyong)", "Oyong (100g)"),
        ("nangka muda", "Nangka Muda (100g)"),
        ("pepaya muda", "Pepaya Muda (100g)"),
        ("rebung", "Rebung (100g)"),
        ("daun katuk", "Daun Katuk (100g)"),
        ("daun katuk rebus", "Daun Katuk Rebus (100g)"),
        ("daun kelor", "Daun Kelor (100g)"),
        ("daun kelor rebus", "Daun Kelor Rebus (100g)"),
        ("daun kacang panjang kukus", "Daun Kacang Panjang Kukus (100g)"),
        ("daun kacang panjang", "Daun Kacang Panjang (100g)"),
        ("daun labu siam", "Daun Labu Siam (100g)"),
        ("daun oyong", "Daun Oyong (100g)"),
        ("cap cai sayur", "Cap Cai Sayur (1 porsi)"),
        ("gado-gado", "Gado-Gado (1 porsi)"),
        ("karedok sayur", "Karedok (1 porsi)"),
        ("karedok", "Karedok (1 porsi)"),
        ("sayur asem", "Sayur Asem (1 mangkok)"),
        ("pelecing kangkung", "Pelecing Kangkung (1 porsi)"),
        ("sop kool dan wortel", "Sop Kol Wortel (1 mangkok)"),
        ("lema/ rebung asam", "Rebung Asam (100g)"),
        ("mostarda metan -sawi", "Sawi Hijau (100g)"),
        ("brokoli", "Brokoli (100g)"),
        ("tomat merah", "Tomat Merah (100g)"),
    ],

    "Buah": [
        # --- Seeded (sudah punya format bagus) ---
        ("pisang ambon (1 buah)", None),
        ("apel merah (1 buah)", None),
        ("pepaya potong (1 mangkok)", None),
        ("jeruk medan (1 buah)", None),
        ("mangga harum manis (1 buah)", None),
        ("semangka potong (1 mangkok)", None),
        ("melon potong (1 mangkok)", None),
        ("salak (1 buah)", None),
        ("buah naga (1 buah sedang)", None),
        ("rambutan (5 buah)", None),
        ("duku (5 buah)", None),
        ("sawo (1 buah)", None),
        ("manggis (1 buah)", None),
        ("kelengkeng (5 buah)", None),
        # --- Dari CSV ---
        ("apel malang", "Apel Malang (1 buah)"),
        ("apel", "Apel (1 buah)"),
        ("pisang ambon", "Pisang Ambon (1 buah)"),
        ("pisang mas", "Pisang Mas (1 buah)"),
        ("pisang raja", "Pisang Raja (1 buah)"),
        ("pisang lampung", "Pisang Lampung (1 buah)"),
        ("pisang kepok", "Pisang Kepok (1 buah)"),
        ("jeruk manis", "Jeruk Manis (1 buah)"),
        ("jeruk bali", "Jeruk Bali (1 potong)"),
        ("jeruk garut", "Jeruk Garut (1 buah)"),
        ("jeruk nipis", "Jeruk Nipis (1 buah)"),
        ("mangga gedong", "Mangga Gedong (1 buah)"),
        ("mangga golek", "Mangga Golek (1 buah)"),
        ("mangga harum manis", "Mangga Harum Manis (1 buah)"),
        ("mangga indramayu", "Mangga Indramayu (1 buah)"),
        ("mangga kopek", "Mangga Kopek (1 buah)"),
        ("mangga muda", "Mangga Muda (1 buah)"),
        ("mangga", "Mangga (1 buah)"),
        ("buah naga merah", "Buah Naga Merah (1 buah)"),
        ("buah naga putih", "Buah Naga Putih (1 buah)"),
        ("semangka", "Semangka (1 potong)"),
        ("melon", "Melon (1 potong)"),
        ("pepaya", "Pepaya (1 potong)"),
        ("nanas", "Nanas (1 potong)"),
        ("alpukat", "Alpukat (1/2 buah)"),
        ("salak bali", "Salak Bali (1 buah)"),
        ("salak medan", "Salak Medan (1 buah)"),
        ("salak pondoh", "Salak Pondoh (1 buah)"),
        ("salak", "Salak (1 buah)"),
        ("rambutan aceh", "Rambutan Aceh (5 buah)"),
        ("rambutan", "Rambutan (5 buah)"),
        ("duku", "Duku (5 buah)"),
        ("sawo", "Sawo (1 buah)"),
        ("jambu air", "Jambu Air (1 buah)"),
        ("jambu bol", "Jambu Bol (1 buah)"),
        ("kedondong", "Kedondong (1 buah)"),
        ("markisa", "Markisa (1 buah)"),
    ],
}


# ===========================================================
# 🧮 HITUNG TARGET MACRO (Kalori → Protein, Karbo, Lemak)
# ===========================================================
# Protein = 2× berat badan (dihitung oleh caller/main.py)
# Sisa kalori setelah protein dibagi: 55% Karbo, 45% Lemak

def hitung_macro_targets(target_kalori, target_protein):
    """
    Menghitung target 4 macro dari total kalori.
    Protein sudah dihitung oleh caller (2× berat badan).
    Sisa kalori setelah protein dibagi 55% Karbo dan 45% Lemak.
    """
    protein_kal = target_protein * 4  # 1g protein = 4 kcal
    remaining_kal = max(target_kalori - protein_kal, 0)

    carb_kal = remaining_kal * 0.55   # 55% sisa → karbo
    fat_kal  = remaining_kal * 0.45   # 45% sisa → lemak

    return {
        'kalori':  target_kalori,
        'protein': target_protein,
        'karbo':   round(carb_kal / 4, 1),  # 1g karbo = 4 kcal
        'lemak':   round(fat_kal / 9, 1),   # 1g lemak = 9 kcal
    }


# ===========================================================
# 📦 AMBIL DATA LOKAL (WHITELIST FILTER)
# ===========================================================
def ambil_data_lokal():
    """
    Mengambil data dari database lalu memfilter menggunakan sistem WHITELIST.
    Hanya makanan yang secara eksplisit terdaftar di WHITELIST yang akan lolos.
    """
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM food_cache")
    raw_data = cursor.fetchall()
    conn.close()

    dataset = {
        'Karbo': [],
        'Hewani': [],
        'Nabati': [],
        'Sayur': [],
        'Buah': [],
    }

    # Set untuk mencegah duplikat berdasarkan display name
    seen_names = {kat: set() for kat in dataset}

    for row in raw_data:
        try:
            nama_makanan = row['nama_makanan']
            nama_lower = nama_makanan.lower().strip()
            kategori = row['kategori']

            # Skip kategori yang tidak ada di whitelist
            if kategori not in WHITELIST:
                continue

            kalori = float(row['kalori'])
            protein = float(row['protein'])
            karbo = float(row['karbo'])
            lemak = float(row['lemak'])

            # --- FILTER NUTRISI DASAR ---
            # Skip makanan terlalu tinggi kalori
            if kalori > 600:
                continue

            # Skip makanan sangat berlemak (> 60% kalori dari lemak)
            if kalori > 0:
                fat_ratio = (lemak * 9) / kalori
                if fat_ratio > 0.60:
                    continue

            # --- WHITELIST MATCHING ---
            # Cek apakah nama makanan cocok dengan salah satu entry di whitelist
            display_name = None
            matched = False

            for keyword, override_name in WHITELIST[kategori]:
                # Exact match OR prefix match with word boundary
                # (keyword harus diikuti spasi, tanda baca, atau akhir string)
                if nama_lower == keyword:
                    matched = True
                    display_name = override_name if override_name else nama_makanan
                    break
                if nama_lower.startswith(keyword):
                    # Pastikan keyword tidak memotong di tengah kata
                    next_char = nama_lower[len(keyword)] if len(nama_lower) > len(keyword) else ''
                    if next_char == '' or next_char in ' (/,-':
                        matched = True
                        display_name = override_name if override_name else nama_makanan
                        break

            if not matched:
                continue  # Tidak ada di whitelist → skip

            # --- DEDUPLIKASI ---
            display_lower = display_name.lower()
            if display_lower in seen_names[kategori]:
                continue
            seen_names[kategori].add(display_lower)

            clean_id = int(row['fatsecret_id'])

            item = {
                'id': clean_id,
                'nama_makanan': display_name,
                'kalori': kalori,
                'protein': protein,
                'karbo': karbo,
                'lemak': lemak
            }

            dataset[kategori].append(item)

        except (ValueError, KeyError):
            continue

    return dataset


# ===========================================================
# CONSTRAINT-BASED FILTERING
# ===========================================================
MEAL_RATIOS = (("Pagi", 0.30), ("Siang", 0.40), ("Malam", 0.30))
CATEGORY_RATIOS = {
    "Karbo": 0.32,
    "Hewani": 0.30,
    "Nabati": 0.14,
    "Sayur": 0.12,
    "Buah": 0.12,
}


def _pilih_item_berdasarkan_batasan(
    items, batas_kategori, sisa_kalori, used_ids, preferred_set
):
    """Pilih satu kandidat secara deterministik dari item yang lolos batas."""
    batas_item = min(batas_kategori * 1.25, sisa_kalori)
    candidates = [
        item for item in items
        if item["id"] not in used_ids and 0 < item["kalori"] <= batas_item
    ]
    if not candidates:
        candidates = [
            item for item in items
            if item["id"] not in used_ids and 0 < item["kalori"] <= sisa_kalori
        ]
    if not candidates:
        return None

    # Preferensi hanya menjadi urutan prioritas setelah seluruh hard constraint
    # terpenuhi. Urutan berikutnya stabil: jarak terhadap alokasi dan nama.
    return min(
        candidates,
        key=lambda item: (
            item["nama_makanan"].lower().strip() not in preferred_set,
            abs(batas_kategori - item["kalori"]),
            item["nama_makanan"].casefold(),
            item["id"],
        ),
    )


def susun_menu_berdasarkan_batasan(dataset, target_kalori, preferred_set=None):
    """Susun tiga waktu makan dengan aturan eksplisit dan tanpa proses stokastik."""
    preferred_set = preferred_set or set()
    used_ids = set()
    menu = []

    for waktu, meal_ratio in MEAL_RATIOS:
        batas_makan = target_kalori * meal_ratio
        sisa_kalori = batas_makan
        isi = []

        for kategori, category_ratio in CATEGORY_RATIOS.items():
            item = _pilih_item_berdasarkan_batasan(
                dataset.get(kategori, []),
                batas_makan * category_ratio,
                sisa_kalori,
                used_ids,
                preferred_set,
            )
            if item is None:
                continue
            isi.append(item)
            used_ids.add(item["id"])
            sisa_kalori -= item["kalori"]

        menu.append({"waktu": waktu, "isi": isi})

    return menu


def jalankan_algoritma(target_kalori, target_protein, preferred_set=None, excluded_set=None):
    """Jalankan Constraint-Based Filtering untuk rekomendasi menu harian."""
    preferred_set = preferred_set or set()
    excluded_set = excluded_set or set()
    dataset = ambil_data_lokal()

    # Hard constraint: item yang dilarang pengguna tidak menjadi kandidat.
    if excluded_set:
        for kategori in dataset:
            dataset[kategori] = [
                item for item in dataset[kategori]
                if item["nama_makanan"].lower().strip() not in excluded_set
            ]

    # Karbohidrat dan protein hewani disyaratkan tersedia agar struktur menu
    # dasar dapat dibentuk. Kandidat sudah melalui whitelist Real Food lokal.
    if not dataset["Karbo"] or not dataset["Hewani"]:
        return [], {}

    targets = hitung_macro_targets(target_kalori, target_protein)
    menu = susun_menu_berdasarkan_batasan(dataset, target_kalori, preferred_set)
    all_items = [item for meal in menu for item in meal["isi"]]

    achieved = {
        "kalori": round(sum(item["kalori"] for item in all_items), 1),
        "protein": round(sum(item["protein"] for item in all_items), 1),
        "karbo": round(sum(item["karbo"] for item in all_items), 1),
        "lemak": round(sum(item["lemak"] for item in all_items), 1),
    }
    accuracy = {}
    for macro in ("kalori", "protein", "karbo", "lemak"):
        if targets[macro] > 0:
            difference = abs(targets[macro] - achieved[macro]) / targets[macro]
            accuracy[macro] = round(max(0.0, 1 - difference) * 100, 1)
        else:
            accuracy[macro] = 100.0

    candidate_count = sum(len(items) for items in dataset.values())
    stats = {
        "algorithm": "Constraint-Based Filtering",
        "candidate_count": candidate_count,
        "rules_applied": 4,
        "target_macros": targets,
        "achieved_macros": achieved,
        "accuracy_pct": accuracy,
        "constraints": {
            "real_food_only": True,
            "upf_excluded": True,
            "excluded_foods_applied": bool(excluded_set),
            "daily_calorie_upper_bound": round(target_kalori, 1),
        },
    }

    if preferred_set or excluded_set:
        stats["preferences_info"] = {
            "preferred_used": sum(
                1 for item in all_items
                if item["nama_makanan"].lower().strip() in preferred_set
            ),
            "preferred_total": len(preferred_set),
            "excluded_count": len(excluded_set),
            "excluded_applied": bool(excluded_set),
        }

    return menu, stats
