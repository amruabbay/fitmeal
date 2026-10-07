"""Regresi safety floor BMR untuk skenario Black Box TC-019."""

from main import UserData, get_rekomendasi, hitung_kalori_user


TC_019 = UserData(
    berat=55,
    tinggi=158,
    umur=28,
    gender="wanita",
    goal="cutting",
    activity="sedentary",
)


def test_tc_019_target_efektif_tidak_di_bawah_bmr():
    bmr = (10 * TC_019.berat) + (6.25 * TC_019.tinggi) - (5 * TC_019.umur) - 161
    tdee = bmr * 1.2
    target_diet = tdee - 500
    target_efektif, _ = hitung_kalori_user(TC_019)

    assert bmr == 1236.5
    assert round(target_diet, 1) == 983.8
    assert target_efektif == max(target_diet, bmr)
    assert target_efektif == 1236.5


def test_tc_019_endpoint_menggunakan_target_efektif():
    response = get_rekomendasi(TC_019)

    assert response["status"] == "success"
    assert response["user_info"]["target_kalori"] == 1236.5
    assert response["hasil_generasi"]["target_macros"]["kalori"] == 1236.5

