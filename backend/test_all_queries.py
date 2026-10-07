import sqlite3
import time
import requests

# Let's test the main.py local search endpoint directly by calling the Python function
from main import cari_makanan

def test_queries():
    categories = [
        {'label': 'Protein', 'queries': ['ayam', 'telur', 'ikan', 'tempe', 'tahu', 'daging', 'udang']},
        {'label': 'Karbohidrat', 'queries': ['nasi', 'roti', 'mie', 'kentang', 'oatmeal', 'jagung']},
        {'label': 'Sayuran', 'queries': ['bayam', 'brokoli', 'kangkung', 'wortel', 'sayur', 'sop']},
        {'label': 'Buah', 'queries': ['pisang', 'apel', 'jeruk', 'mangga', 'semangka', 'pepaya']},
    ]

    for cat in categories:
        print(f"\nCategory: {cat['label']}")
        for q in cat['queries']:
            start = time.time()
            try:
                res = cari_makanan(q=q, page=0, limit=10)
                dur = time.time() - start
                print(f"  Query '{q}': found {res.get('total_found')} items in {dur:.2f}s")
            except Exception as e:
                dur = time.time() - start
                print(f"  Query '{q}': FAILED after {dur:.2f}s: {e}")

if __name__ == '__main__':
    test_queries()
