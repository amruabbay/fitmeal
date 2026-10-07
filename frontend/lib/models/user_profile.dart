import 'dart:convert';

class UserProfile {
  String nama;
  double berat;     // kg
  double tinggi;    // cm
  int umur;         // tahun
  String gender;    // 'pria' / 'wanita'
  String goal;      // 'cutting' / 'maintain' / 'bulking'
  String activity;  // 'sedentary' / 'moderate' / 'active'
  bool onboardingComplete;
  String? profileImagePath;

  UserProfile({
    this.nama = '',
    this.berat = 0,
    this.tinggi = 0,
    this.umur = 0,
    this.gender = 'pria',
    this.goal = 'cutting',
    this.activity = 'sedentary',
    this.onboardingComplete = false,
    this.profileImagePath = '',
  });

  Map<String, dynamic> toJson() => {
        'nama': nama,
        'berat': berat,
        'tinggi': tinggi,
        'umur': umur,
        'gender': gender,
        'goal': goal,
        'activity': activity,
        'onboardingComplete': onboardingComplete,
        'profileImagePath': profileImagePath,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      nama: json['nama'] ?? '',
      berat: (json['berat'] ?? 0).toDouble(),
      tinggi: (json['tinggi'] ?? 0).toDouble(),
      umur: (json['umur'] ?? 0).toInt(),
      gender: json['gender'] ?? 'pria',
      goal: json['goal'] ?? 'cutting',
      activity: json['activity'] ?? 'sedentary',
      onboardingComplete: json['onboardingComplete'] ?? false,
      profileImagePath: json['profileImagePath'] as String? ?? '',
    );
  }

  String toEncodedString() => jsonEncode(toJson());

  factory UserProfile.fromEncodedString(String encoded) {
    return UserProfile.fromJson(jsonDecode(encoded));
  }

  double get bmi {
    if (tinggi <= 0 || berat <= 0) return 0.0;
    final tinggiMeter = tinggi / 100.0;
    return berat / (tinggiMeter * tinggiMeter);
  }

  String get bmiCategory {
    final val = bmi;
    if (val <= 0) return 'Tidak Diketahui';
    if (val < 18.5) return 'Kurus (Underweight)';
    if (val < 25.0) return 'Normal';
    if (val < 30.0) return 'Kelebihan Berat Badan (Overweight)';
    return 'Obesitas';
  }
}
