import sqlite3

DB_NAME = "skripsi_diet.db"

# Exact blacklist from recommendation_screen.dart
_blacklistKeywords = [
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
  "susu kental manis", "skm", "full cream",
]

def is_blacklisted(name):
    lower = name.lower()
    for kw in _blacklistKeywords:
        if kw in lower:
            return True, kw
    return False, None

def simulate():
    categories = [
        {'label': 'Protein', 'queries': ['ayam', 'telur', 'ikan', 'tempe', 'tahu', 'daging', 'udang']},
        {'label': 'Karbohidrat', 'queries': ['nasi', 'roti', 'mie', 'kentang', 'oatmeal', 'jagung']},
        {'label': 'Sayuran', 'queries': ['bayam', 'brokoli', 'kangkung', 'wortel', 'sayur', 'sop']},
        {'label': 'Buah', 'queries': ['pisang', 'apel', 'jeruk', 'mangga', 'semangka', 'pepaya']},
    ]

    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM food_cache")
    all_local = [dict(row) for row in cursor.fetchall()]
    conn.close()

    for cat in categories:
        print(f"\nCategory: {cat['label']}")
        # Frontend logic: query each word, get all results, then filter
        seen = set()
        new_unique = []
        
        for q in cat['queries']:
            # Search logic in main.py
            keywords = q.lower().split()
            local_results = []
            for item in all_local:
                nama_db = item['nama_makanan'].lower()
                if any(k in nama_db for k in keywords):
                    local_results.append(item)
            
            # Slicing page=0, limit=10 in backend
            # Note: since the frontend queries with page=0, limit=10, the backend returns the first 10 items for that query.
            # Wait! The backend slices per query!
            sliced_results = local_results[0:10]
            
            for item in sliced_results:
                name = item['nama_makanan']
                name_lower = name.toLowerCase() if hasattr(name, 'toLowerCase') else name.lower()
                blocked, kw = is_blacklisted(name)
                
                # Check seen and blacklist
                if name_lower not in seen and name != "" and not blocked:
                    seen.add(name_lower)
                    new_unique.append(name)
                elif blocked:
                    # Print why it was blacklisted
                    pass
        
        print(f"  Final Unique count on frontend: {len(new_unique)}")
        print(f"  Items: {new_unique[:15]}")

if __name__ == '__main__':
    simulate()
