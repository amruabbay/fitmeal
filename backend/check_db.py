import sqlite3

DB_NAME = "skripsi_diet.db"

def check_db():
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    
    # 1. Check tables and counts
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = cursor.fetchall()
    print("Tables:", tables)
    
    for table in tables:
        tname = table[0]
        cursor.execute(f"SELECT COUNT(*) FROM {tname}")
        count = cursor.fetchone()[0]
        print(f"Table {tname}: {count} records")
        
    # 2. Check categories in food_cache
    cursor.execute("SELECT kategori, COUNT(*) FROM food_cache GROUP BY kategori")
    categories = cursor.fetchall()
    print("\nCategories in food_cache:")
    for cat, cnt in categories:
        print(f"  {cat}: {cnt}")
        
    # 3. Print some sample foods for each category
    for cat in ['Karbo', 'Hewani', 'Nabati', 'Sayur', 'Buah']:
        print(f"\nSamples in {cat}:")
        cursor.execute("SELECT nama_makanan, kalori, protein, karbo, lemak FROM food_cache WHERE kategori=? LIMIT 5", (cat,))
        for row in cursor.fetchall():
            print(f"  {row}")

    conn.close()

if __name__ == '__main__':
    check_db()
