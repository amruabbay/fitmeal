import threading
import time
from main import cari_makanan

QUERIES = ['nasi', 'roti', 'mie', 'kentang', 'oatmeal', 'jagung']

results = {}
errors = {}

def fetch(q):
    start = time.time()
    try:
        data = cari_makanan(q=q, page=0, limit=10)
        items = data.get('results', [])
        dur = time.time() - start
        results[q] = {
            'count': len(items),
            'total_found': data.get('total_found'),
            'dur': f"{dur:.2f}s"
        }
    except Exception as e:
        dur = time.time() - start
        errors[q] = f"Error: {e} after {dur:.2f}s"

def test_concurrent():
    threads = []
    print("Executing concurrent calls to cari_makanan...")
    for q in QUERIES:
        t = threading.Thread(target=fetch, args=(q,))
        threads.append(t)
        t.start()
        
    for t in threads:
        t.join()
        
    print("\n--- RESULTS ---")
    for q, res in results.items():
        print(f"Query '{q}': received {res['count']} items (total_found={res['total_found']}) in {res['dur']}")
        
    if errors:
        print("\n--- ERRORS ---")
        for q, err in errors.items():
            print(f"Query '{q}': {err}")

if __name__ == '__main__':
    test_concurrent()
