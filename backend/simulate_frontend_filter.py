import sqlite3

DB_NAME = "skripsi_diet.db"

# Blacklist keywords from recommendation_screen.dart
blacklist_keywords = [
  "kfc", "mcd", "mcdonalds", "burger", "pizza", "hokben", "solaria",
  "a&w", "wendys", "fast food", "junk food", "french fries", "kentang goreng",
  "hotdog", "corndog", "chicken wings", "chicken nugget", "nugget",
  "kebab", "shawarma", "doner", "taco", "burrito",
  "sushi", "ramen", "tempura", "dimsum", "takoyaki",
  "croffle", "cromboloni", "toast", "dessert box",
  "gorengan", "crispy", "penyet", "geprek", "kulit ayam", "kulit",
  "fried chicken", "ayam goreng", "bebek goreng", "lele goreng",
  "bakwan", "bala-bala", "cireng", "cimol", "cilok", "batagor", "pempek",
  "kerupuk", "krupuk", "rempeyek", "emping", "mendoan", "risol", "lumpia",
  "pastel", "basreng", "kripik", "keripik", "chiki", "seblak", "cuanki", "maklor", "cilor",
  "santan", "gulai", "rendang", "tongseng", "opor", "soto betawi",
  "jeroan", "usus", "babat", "kikil", "tunjang", "otak", "paru", "ati ampela",
  "sate kambing", "sate padang", "sate kulit",
  "gajih", "lemak", "minyak",
  "indomie", "mie instan", "mie goreng", "mie rebus", "sosis", "kornet", "kaleng",
  "kwetiau", "bihun goreng", "ifumie", "nasgor", "nasi goreng",
  "nasi uduk", "nasi kuning", "nasi liwet", "nasi hainam", "nasi kebuli",
  "martabak", "roti bakar", "kue", "gacoan", "bakso", "baso", "mie ayam", "pangsit",
  "biskuit", "wafer", "cake", "pudding", "crepes", "pukis", "pancong", "kue cubit",
  "boba", "bubble", "milk tea", "chatime", "starbucks",
  "kopi susu", "cappucino", "latte", "frappe", "smoothie", "kopi", "teh",
  "es teh manis", "teh tarik", "es campur", "es teler", "es doger", "es krim", "ice cream",
  "coklat", "chocolate", "brown sugar", "gula aren", "sirup", "soda",
  "susu kental manis", "skm", "full cream"
]

def is_blacklisted(food_name):
    lower = food_name.lower()
    for kw in blacklist_keywords:
        if kw in lower:
            return True, kw
    return False, None

categories = [
    {'label': 'Protein', 'queries': ['ayam', 'telur', 'ikan', 'tempe', 'tahu', 'daging', 'udang']},
    {'label': 'Karbohidrat', 'queries': ['nasi', 'roti', 'mie', 'kentang', 'oatmeal', 'jagung']},
    {'label': 'Sayuran', 'queries': ['bayam', 'brokoli', 'kangkung', 'wortel', 'sayur', 'sop']},
    {'label': 'Buah', 'queries': ['pisang', 'apel', 'jeruk', 'mangga', 'semangka', 'pepaya']},
]

def simulate():
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM food_cache")
    all_local = [dict(row) for row in cursor.fetchall()]
    conn.close()
    
    print("=== SIMULASI FILTER BLACKLIST FRONTEND ===")
    for cat in categories:
        print(f"\nKategori: {cat['label']}")
        combined_results = []
        for q in cat['queries']:
            keywords = q.lower().split()
            for item in all_local:
                nama_db = item['nama_makanan'].lower()
                if any(k in nama_db for k in keywords):
                    combined_results.append(item['nama_makanan'])
        
        # Unique names
        unique_names = list(set(combined_results))
        total_found = len(unique_names)
        
        # Filter with blacklist
        passed = []
        blocked = {}
        for name in unique_names:
            black, kw = is_blacklisted(name)
            if not black:
                passed.append(name)
            else:
                blocked[kw] = blocked.get(kw, 0) + 1
        
        print(f"  Total ditemukan (sebelum filter): {total_found}")
        print(f"  Lolos filter: {len(passed)}")
        print(f"  Terblokir filter: {total_found - len(passed)}")
        if blocked:
            print("  Alasan terblokir (keyword & jumlah):")
            for kw, count in sorted(blocked.items(), key=lambda x: x[1], reverse=True)[:5]:
                print(f"    - '{kw}': {count} makanan")
        if passed:
            print("  Contoh makanan lolos:")
            for name in passed[:5]:
                print(f"    - {name}")
        else:
            print("  ❌ TIDAK ADA MAKANAN YANG LOLOS FILTER!")

if __name__ == '__main__':
    simulate()
