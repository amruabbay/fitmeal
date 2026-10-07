"""Benchmark response time pencarian Fit Meal dengan prosedur seragam.

Jalur online diukur dari sebelum permintaan HTTP hingga respons JSON selesai
diurai. Jalur offline diukur dari sebelum koneksi SQLite dibuka hingga daftar
hasil selesai difilter, diurutkan, dan dipotong sesuai batas tampilan.
"""

from __future__ import annotations

import json
import os
import platform
import sqlite3
import statistics
import time
from datetime import datetime
from pathlib import Path

import requests

from main import hitung_skor_relevansi, is_junk_food


BASE_URL = os.environ.get("FITMEAL_ONLINE_BASE_URL", "https://fitmeal-2y91.onrender.com")
SEARCH_URL = f"{BASE_URL.rstrip('/')}/search"
DB_PATH = Path(__file__).with_name("skripsi_diet.db")
KEYWORDS = [
    "nasi",
    "ayam",
    "tempe",
    "bayam",
    "pisang",
    "ikan",
    "roti",
    "telur",
    "kangkung",
    "jeruk",
]
ITERATIONS = 10
LIMIT = 15
TIMEOUT_SECONDS = 120


def _stats(samples_ms: list[float], result_count: int) -> dict[str, float | int]:
    return {
        "mean_ms": round(statistics.mean(samples_ms), 2),
        "min_ms": round(min(samples_ms), 2),
        "max_ms": round(max(samples_ms), 2),
        "std_ms": round(statistics.stdev(samples_ms), 2),
        "result_count": result_count,
        "successful_iterations": len(samples_ms),
    }


def search_online(session: requests.Session, keyword: str) -> tuple[int, list[dict]]:
    response = session.get(
        SEARCH_URL,
        params={"q": keyword, "page": 0, "limit": LIMIT},
        timeout=TIMEOUT_SECONDS,
    )
    response.raise_for_status()
    payload = response.json()
    results = [dict(item) for item in payload.get("results", [])]
    return int(payload.get("total_found", len(results))), results


def search_offline(keyword: str) -> tuple[int, list[dict]]:
    keywords = keyword.lower().split()
    clauses = ["lower(nama_makanan) LIKE ?" for _ in keywords]
    params = [f"%{part}%" for part in keywords]
    query = "SELECT * FROM food_cache WHERE " + " OR ".join(clauses)

    with sqlite3.connect(DB_PATH) as connection:
        connection.row_factory = sqlite3.Row
        rows = connection.execute(query, params).fetchall()

    materialized = []
    for row in rows:
        item = {
            "id": int(row["fatsecret_id"]),
            "nama_makanan": row["nama_makanan"],
            "kalori": float(row["kalori"]),
            "protein": float(row["protein"]),
            "karbo": float(row["karbo"]),
            "lemak": float(row["lemak"]),
            "sumber": "lokal",
        }
        if not is_junk_food(item["nama_makanan"]):
            materialized.append(item)

    materialized.sort(
        key=lambda item: hitung_skor_relevansi(item["nama_makanan"], keyword),
        reverse=True,
    )
    return len(materialized), materialized[:LIMIT]


def benchmark() -> dict:
    if not DB_PATH.exists():
        raise FileNotFoundError(DB_PATH)

    session = requests.Session()
    session.headers.update({"Accept": "application/json"})

    # Pemanasan tidak dicatat agar cold start satu kali tidak mendominasi hasil.
    search_online(session, KEYWORDS[0])
    search_offline(KEYWORDS[0])

    online = {}
    offline = {}
    all_online_samples = []
    all_offline_samples = []

    for keyword in KEYWORDS:
        print(f"Mengukur kata kunci online: {keyword}", flush=True)
        online_samples = []
        online_count = 0
        for _ in range(ITERATIONS):
            started = time.perf_counter_ns()
            online_count, _ = search_online(session, keyword)
            elapsed_ms = (time.perf_counter_ns() - started) / 1_000_000
            online_samples.append(elapsed_ms)
        online[keyword] = _stats(online_samples, online_count)
        all_online_samples.extend(online_samples)

        print(f"Mengukur kata kunci offline: {keyword}", flush=True)
        offline_samples = []
        offline_count = 0
        for _ in range(ITERATIONS):
            started = time.perf_counter_ns()
            offline_count, _ = search_offline(keyword)
            elapsed_ms = (time.perf_counter_ns() - started) / 1_000_000
            offline_samples.append(elapsed_ms)
        offline[keyword] = _stats(offline_samples, offline_count)
        all_offline_samples.extend(offline_samples)

    return {
        "test_time": datetime.now().astimezone().isoformat(timespec="seconds"),
        "device": {
            "system": platform.system(),
            "release": platform.release(),
            "machine": platform.machine(),
            "python": platform.python_version(),
        },
        "procedure": {
            "online_endpoint": SEARCH_URL,
            "offline_database": str(DB_PATH),
            "network": "Satu koneksi internet aktif selama sesi; jalur SQLite tidak memakai jaringan.",
            "keywords": KEYWORDS,
            "iterations_per_keyword": ITERATIONS,
            "total_iterations_per_path": len(KEYWORDS) * ITERATIONS,
            "unit": "ms",
            "limit_per_result": LIMIT,
            "warmup": "1 eksekusi per jalur, tidak dicatat",
        },
        "online": online,
        "offline": offline,
        "global": {
            "online_mean_ms": round(statistics.mean(all_online_samples), 2),
            "offline_mean_ms": round(statistics.mean(all_offline_samples), 2),
            "difference_ms": round(
                statistics.mean(all_online_samples) - statistics.mean(all_offline_samples),
                2,
            ),
            "online_successful_iterations": len(all_online_samples),
            "offline_successful_iterations": len(all_offline_samples),
        },
    }


if __name__ == "__main__":
    print(json.dumps(benchmark(), indent=2, ensure_ascii=False))
