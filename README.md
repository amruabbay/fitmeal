# FitMeal - Diet & Nutrition Recommendation System

Aplikasi pelacak nutrisi, kalkulator kalori harian (TDEE/BMR), dan sistem rekomendasi menu makanan berbasis *Constraint-Based Filtering*.

---

## 📁 Struktur Monorepo

```text
fitmeal/
├── frontend/               # Mobile Client (Flutter & Dart)
│   ├── lib/                # Source code aplikasi (Providers, Screens, Widgets)
│   ├── pubspec.yaml        # Dependensi Flutter
│   └── ...
├── backend/                # REST API Server (Python & FastAPI)
│   ├── main.py             # Entry point API server
│   ├── algoritma.py        # Algoritma rekomendasi makanan
│   ├── requirements.txt    # Dependensi Python
│   └── ...
└── README.md
```

---

## 🚀 Panduan Menjalankan

### 1. Backend (FastAPI)
Masuk ke direktori backend:
```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # atau venv\Scripts\activate di Windows
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```
Server backend akan berjalan di `http://127.0.0.1:8000`. Dokumentasi Swagger API interaktif dapat diakses di `http://127.0.0.1:8000/docs`.

### 2. Frontend (Flutter)
Pastikan Flutter SDK sudah terpasang di komputer Anda:
```bash
cd frontend
flutter pub get
flutter run
```

---

## 🛠️ Tech Stack
* **Frontend**: Flutter 3.x, Dart, Provider (State Management), Material 3, FL Chart, Google Fonts.
* **Backend**: Python 3.12, FastAPI, Uvicorn, SQLAlchemy, Pandas.
* **Database**: SQLite / PostgreSQL.
* **Deployment**:
  * Backend API: Render (`https://fitmeal-2y91.onrender.com`)
  * Mobile/Web Client: Flutter Build (APK/Web)

---

## 👤 Author
* **Amru Abbay**
