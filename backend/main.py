import sqlite3
import requests
import uvicorn
from typing import List, Optional
from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware

# Pastikan file algoritma.py ada di satu folder
from algoritma import DB_NAME, jalankan_algoritma, hitung_macro_targets

# ==========================================
# ⚠️ KUNCI FATSECRET (OAUTH 2.0)
# ==========================================
CLIENT_ID = "3539cf685adc4153b5d9b5fa48cbe582"
CLIENT_SECRET = "2f111c0b7f8c4eb393148ec5f543c610"

app = FastAPI()

# ==========================================
# 🔥 IZIN CORS
# ==========================================
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- MODEL DATA ---
class UserData(BaseModel):
    berat: float
    tinggi: float
    umur: int
    gender: str
    goal: str
    activity: str
    preferred_foods: Optional[List[str]] = None
    excluded_foods: Optional[List[str]] = None

# --- AUTHENTICATION ---
_oauth_token = None
_oauth_failed = False

def dapatkan_token_oauth2():
    global _oauth_token, _oauth_failed
    if _oauth_failed:
        return None
    if _oauth_token:
        return _oauth_token
    try:
        url = "https://oauth.fatsecret.com/connect/token"
        payload = {'grant_type': 'client_credentials', 'scope': 'premier'}
        response = requests.post(url, data=payload, auth=(CLIENT_ID, CLIENT_SECRET), timeout=1.5)
        if response.status_code == 200:
            _oauth_token = response.json().get('access_token')
            return _oauth_token
        else:
            _oauth_failed = True
    except:
        _oauth_failed = True
    return None

# --- FUNGSI PARSE HASIL API ---
def parse_fatsecret_items(foods, query):
    """Parse list of food items dari response FatSecret API."""
    hasil = []
    for item in foods:
        nama = item.get('food_name', '')
        brand = item.get('brand_name', '')
        desc = item.get('food_description', '')
        
        makanan = {
            "id": int(item['food_id']),
            "nama_makanan": f"{nama} ({brand})" if brand else nama,
            "kalori": 0, "protein": 0, "karbo": 0, "lemak": 0,
            "sumber": "api"
        }
        try:
            if 'Calories:' in desc:
                makanan['kalori'] = float(desc.split('Calories: ')[1].split('kcal')[0])
            if 'Protein:' in desc:
                makanan['protein'] = float(desc.split('Protein: ')[1].split('g')[0])
            if 'Carbs:' in desc:
                makanan['karbo'] = float(desc.split('Carbs: ')[1].split('g')[0])
            if 'Fat:' in desc:
                makanan['lemak'] = float(desc.split('Fat: ')[1].split('g')[0])
        except: pass
        hasil.append(makanan)
    return hasil

# --- FUNGSI BULK (DUAL SEARCH: REGIONAL + GLOBAL) ---
def cari_di_fatsecret_bulk(query):
    token = dapatkan_token_oauth2()
    if not token: return []

    url = "https://platform.fatsecret.com/rest/server.api"
    headers = {'Authorization': f'Bearer {token}'}
    
    seen_ids = set()
    hasil_bulk = []
    
    # Konfigurasi pencarian: Coba regional dulu, lalu global
    search_configs = [
        {"region": "ID", "language": "id"},   # 1. Cari di database Indonesia
        {},                                     # 2. Cari di database Global
    ]
    
    try:
        for config in search_configs:
            for api_page in range(3):  # max 3 halaman per search
                params = {
                    "method": "foods.search",
                    "search_expression": query,
                    "format": "json",
                    "max_results": 50,
                    "page_number": api_page,
                    **config  # Tambahkan region/language jika ada
                }
                response = requests.get(url, headers=headers, params=params, timeout=2.0)
                
                if response.status_code == 200:
                    data = response.json()
                    foods = data.get("foods", {}).get("food", [])
                    if isinstance(foods, dict): foods = [foods]
                    if not foods: break 
                    
                    items = parse_fatsecret_items(foods, query)
                    for item in items:
                        if item['id'] not in seen_ids:
                            seen_ids.add(item['id'])
                            hasil_bulk.append(item)
                else: break
                    
        return hasil_bulk
    except: return []

# --- LOGIKA HITUNG KALORI ---
def hitung_kalori_user(data: UserData):
    """Hitung target nutrisi dengan batas bawah BMR (safety floor)."""
    if data.gender.lower() == "pria":
        bmr = (10 * data.berat) + (6.25 * data.tinggi) - (5 * data.umur) + 5
    else:
        bmr = (10 * data.berat) + (6.25 * data.tinggi) - (5 * data.umur) - 161
    
    faktor = 1.2
    if data.activity == "moderate": faktor = 1.55
    elif data.activity == "active": faktor = 1.725
    
    tdee = bmr * faktor
    
    if data.goal == "cutting":
        target_diet = tdee - 500
    elif data.goal == "bulking":
        target_diet = tdee + 400
    else: 
        target_diet = tdee

    # Safety floor: target rekomendasi tidak boleh berada di bawah BMR.
    target_efektif = max(target_diet, bmr)
    
    # Protein = 2× berat badan (gram)
    target_protein = round(data.berat * 2.0)
        
    return target_efektif, target_protein

# --- ENDPOINT REKOMENDASI ---
@app.post("/rekomendasi")
def get_rekomendasi(user: UserData):
    target_kalori, target_protein = hitung_kalori_user(user)

    # --- Parse preferensi makanan (backward compatible) ---
    preferred_list = user.preferred_foods if user.preferred_foods else []
    excluded_list = user.excluded_foods if user.excluded_foods else []

    preferred_set = set(f.lower().strip() for f in preferred_list if f)
    excluded_set = set(f.lower().strip() for f in excluded_list if f)

    menu_terbaik, stats = jalankan_algoritma(
        target_kalori, target_protein,
        preferred_set=preferred_set,
        excluded_set=excluded_set
    )
    
    if not menu_terbaik: 
        raise HTTPException(status_code=404, detail="Gagal generate menu.")

    # Hitung macro targets lengkap untuk dikirim ke frontend
    macro_targets = hitung_macro_targets(target_kalori, target_protein)

    return {
        "status": "success", 
        "user_info": {
            # Pertahankan satu angka desimal agar nilai x.5 tidak dibulatkan
            # ke bawah dan melanggar safety floor pada tampilan klien.
            "target_kalori": round(target_kalori, 1),
            "target_protein": round(macro_targets['protein']),
            "target_karbo": round(macro_targets['karbo']),
            "target_lemak": round(macro_targets['lemak']),
        }, 
        "hasil_generasi": stats, 
        "menu": menu_terbaik
    }

# --- FUNGSI SCORING RELEVANSI PENCARIAN ---
def hitung_skor_relevansi(nama_makanan: str, query: str) -> int:
    """
    Menghitung skor relevansi sebuah makanan terhadap kata kunci pencarian.
    Skor LEBIH TINGGI = LEBIH RELEVAN (ditampilkan lebih atas).
    
    Sistem Poin:
    - Nama persis sama dengan query          → +1000
    - Nama diawali dengan query              → +500
    - Semua kata kunci ada di nama            → +200
    - Setiap kata kunci yang cocok            → +50
    - Kata kunci muncul sebagai kata utuh     → +30 per kata
    - Posisi kata kunci lebih awal di nama    → +20
    - Nama lebih pendek (lebih spesifik)      → +10
    """
    nama_lower = nama_makanan.lower().strip()
    query_lower = query.lower().strip()
    keywords = query_lower.split()
    
    skor = 0
    
    # 1. EXACT MATCH — nama persis sama
    if nama_lower == query_lower:
        skor += 1000
    
    # 2. STARTS WITH — nama diawali query lengkap
    if nama_lower.startswith(query_lower):
        skor += 500
    
    # 3. ALL KEYWORDS MATCH — semua kata kunci ada
    matches = sum(1 for k in keywords if k in nama_lower)
    if matches == len(keywords):
        skor += 200
    
    # 4. PER-KEYWORD MATCH — setiap kata yang cocok
    skor += matches * 50
    
    # 5. WHOLE WORD MATCH — kata kunci muncul sebagai kata utuh
    nama_words = nama_lower.split()
    for k in keywords:
        if k in nama_words:
            skor += 30
    
    # 6. POSISI AWAL — kata kunci muncul di awal nama
    for k in keywords:
        pos = nama_lower.find(k)
        if pos >= 0 and pos < 5:  # Muncul di 5 karakter pertama
            skor += 20
    
    # 7. NAMA PENDEK BONUS — nama yang lebih pendek biasanya lebih spesifik
    if len(nama_lower) < 25:
        skor += 10
    
    return skor
# --- BLACKLIST INSTANT & JUNK FOOD (UNTUK SEARCH) ---
JUNK_FOOD_KEYWORDS = [
    "pop mie", "popmie", "sarimi", "indomie", "mie sedaap", "mie sedap",
    "supermi", "samyang", "chitato", "lays", "taro", "cheetos", "seblak",
    "oreo", "silverqueen", "beng-beng", "beng beng", "coca-cola", "coca cola",
    "fanta", "sprite", "pepsi", "gacoan"
]

def is_junk_food(nama_makanan: str) -> bool:
    nama_lower = nama_makanan.lower()
    return any(keyword in nama_lower for keyword in JUNK_FOOD_KEYWORDS)

# --- ENDPOINT SEARCH (SERVER SIDE PAGINATION) ---
@app.get("/search")
def cari_makanan(
    q: str = "", 
    page: int = Query(0, ge=0),    # Halaman (0, 1, 2...)
    limit: int = Query(7, le=50)   # Jumlah item per load (Default 7)
):
    if not q: 
        return {"status": "success", "results": [], "has_next": False}

    # 1. AMBIL DATABASE LOKAL
    local_results = []
    try:
        conn = sqlite3.connect(DB_NAME)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        keywords = q.lower().split()
        if keywords:
            clauses = []
            params = []
            for k in keywords:
                clauses.append("lower(nama_makanan) LIKE ?")
                params.append(f"%{k}%")
            sql_query = "SELECT * FROM food_cache WHERE " + " OR ".join(clauses)
            cursor.execute(sql_query, params)
        else:
            cursor.execute("SELECT * FROM food_cache")
            
        all_local = [dict(row) for row in cursor.fetchall()]
        conn.close()
        
        for item in all_local:
            local_results.append({
                "id": int(item['fatsecret_id']),
                "nama_makanan": item['nama_makanan'],
                "kalori": float(item['kalori']), 
                "protein": float(item['protein']),
                "karbo": float(item['karbo']), 
                "lemak": float(item['lemak']),
                "sumber": "lokal"
            })
    except Exception as e:
        print(f"Error DB Lokal: {e}")

    # 2. AMBIL DARI API (Bulk Fetch)
    api_results = cari_di_fatsecret_bulk(q)
    
    # 3. GABUNGKAN SEMUA HASIL DAN FILTER JUNK FOOD
    master_list = [
        item for item in (local_results + api_results)
        if not is_junk_food(item['nama_makanan'])
    ]
    
    # 4. URUTKAN BERDASARKAN SKOR RELEVANSI (TINGGI → RENDAH)
    master_list.sort(
        key=lambda item: hitung_skor_relevansi(item['nama_makanan'], q),
        reverse=True
    )
    
    # 5. POTONG DATA (SLICING) SESUAI PAGE & LIMIT
    start_index = page * limit
    end_index = start_index + limit
    
    final_results = []
    has_next = False

    if len(master_list) > start_index:
        final_results = master_list[start_index:end_index]
        has_next = len(master_list) > end_index
    
    return {
        "status": "success",
        "page": page,
        "limit": limit,
        "total_found": len(master_list),
        "results": final_results,
        "has_next": has_next
    }

@app.get("/")
def read_root(): 
    return {"message": "Server Ready", "cors": "enabled"}

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=9090)
