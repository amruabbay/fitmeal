import sqlite3

DB_NAME = "skripsi_diet.db"

# Blacklist from recommendation_screen.dart
BLACKLIST_KEYWORDS = [
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
    for kw in BLACKLIST_KEYWORDS:
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
        print(f"\n=================== CATEGORY: {cat['label']} ===================")
        total_found = 0
        total_after_blacklist = 0
        blacklisted_examples = []
        allowed_examples = []
        
        for q in cat['queries']:
            keywords = q.lower().split()
            q_results = []
            for item in all_local:
                nama_db = item['nama_makanan'].lower()
                if any(k in nama_db for k in keywords):
                    q_results.append(item['nama_makanan'])
            
            total_found += len(q_results)
            
            for r in q_results:
                blocked, kw = is_blacklisted(r)
                if blocked:
                    blacklisted_examples.append((r, kw))
                else:
                    total_after_blacklist += 1
                    allowed_examples.append(r)
                    
        print(f"Total found from DB matching queries: {total_found}")
        print(f"Total after frontend blacklist filter: {total_after_blacklist}")
        if allowed_examples:
            print("Allowed examples:")
            for e in allowed_examples[:10]:
                print(f"  - {e}")
        else:
            print("NO ALLOWED FOODS FOUND!")
            if blacklisted_examples:
                print("Examples of blacklisted foods (with matched keyword):")
                for e, kw in blacklisted_examples[:10]:
                    print(f"  - '{e}' blacklisted by keyword '{kw}'")

if __name__ == '__main__':
    simulate()
