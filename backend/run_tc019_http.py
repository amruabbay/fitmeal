"""Jalankan TC-019 terhadap server HTTP Fit Meal yang aktif."""

import json
from datetime import datetime

import requests


payload = {
    "berat": 55,
    "tinggi": 158,
    "umur": 28,
    "gender": "wanita",
    "goal": "cutting",
    "activity": "sedentary",
}

bmr = (10 * payload["berat"]) + (6.25 * payload["tinggi"]) - (5 * payload["umur"]) - 161
target_diet = (bmr * 1.2) - 500

response = requests.post(
    "http://127.0.0.1:9090/rekomendasi",
    json=payload,
    timeout=30,
)
response.raise_for_status()
body = response.json()

actual_target = body["user_info"]["target_kalori"]
algorithm_target = body["hasil_generasi"]["target_macros"]["kalori"]
passed = actual_target >= bmr and algorithm_target >= bmr

print(
    json.dumps(
        {
            "waktu_uji": datetime.now().astimezone().isoformat(timespec="seconds"),
            "id_uji": "TC-019",
            "profil": payload,
            "target_diet_lama_kkal": round(target_diet, 1),
            "bmr_kkal": round(bmr, 1),
            "target_efektif_api_kkal": actual_target,
            "target_algoritma_kkal": algorithm_target,
            "status_http": response.status_code,
            "status_uji": "PASS" if passed else "FAIL",
        },
        indent=2,
        ensure_ascii=False,
    )
)

if not passed:
    raise SystemExit(1)
