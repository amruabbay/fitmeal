import 'package:flutter/material.dart';
import 'package:fit_meal/main.dart' show FMColors;
import 'package:provider/provider.dart';
import 'package:fit_meal/providers/language_provider.dart';
import 'package:fit_meal/config/app_strings.dart';

class ResultSheet extends StatelessWidget {
  final Map<String, dynamic> resultData;
  const ResultSheet({super.key, required this.resultData});

  String _hitungStatusBMI(double berat, double tinggi) {
    double tinggiM = tinggi / 100;
    double bmi = berat / (tinggiM * tinggiM);
    if (bmi < 18.5) return "underweight";
    if (bmi >= 18.5 && bmi < 25) return "normal";
    if (bmi >= 25 && bmi < 30) return "overweight";
    return "obese";
  }

  IconData _getBMIIcon(String statusKey) {
    if (statusKey == "underweight") return Icons.trending_down_rounded;
    if (statusKey == "normal") return Icons.check_circle_rounded;
    if (statusKey == "overweight") return Icons.trending_up_rounded;
    return Icons.warning_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = Provider.of<LanguageProvider>(context).locale;
    final userInfo = resultData['user_info'];
    final List menu = resultData['menu'];
    double berat = userInfo['berat_input'] ?? 0;
    double tinggi = userInfo['tinggi_input'] ?? 0;
    String statusKey = _hitungStatusBMI(berat, tinggi);
    String statusBMI = AppStrings.get(statusKey, lang);
    IconData statusIcon = _getBMIIcon(statusKey);
    final titleColor = isDark ? FMColors.titleDark : FMColors.titleLight;
    final subColor   = isDark ? FMColors.subDark   : FMColors.subLight;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? FMColors.bgDark : FMColors.bgLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: FMColors.primaryLight.withOpacity(isDark ? 0.15 : 0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              const SizedBox(height: 14),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.get('your_meal_plan', lang),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.get('based_on_body_data', lang),
                style: TextStyle(fontSize: 13, color: subColor),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    // ---- Hero summary card ----
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? FMColors.surfaceDark : FMColors.titleLight,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? FMColors.cardDark : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.get('daily_needs_title', lang),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "${userInfo['target_kalori'].toInt()} ${AppStrings.get('kkal', lang)}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${AppStrings.get('protein', lang)}: ${userInfo['target_protein'].toInt()}g",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // BMI Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(statusIcon, color: Colors.white, size: 22),
                                const SizedBox(height: 4),
                                Text(
                                  AppStrings.get('bmi_status_title', lang),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  statusBMI,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ---- Menu cards ----
                    ...menu.map((makan) => _buildMenuCard(makan, context)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuCard(Map<String, dynamic> data, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List isi = data['isi'];
    double totalKalori = isi.fold(0, (sum, item) => sum + (item['kalori'] ?? 0));
    final titleColor = isDark ? FMColors.titleDark : FMColors.titleLight;
    final subColor   = isDark ? FMColors.subDark   : FMColors.subLight;
    const primary = FMColors.primaryLight;
    final lang = Provider.of<LanguageProvider>(context).locale;

    // Time-based accent
    final waktu = (data['waktu'] as String).toLowerCase();
    Color accent = primary;
    IconData timeIcon = Icons.restaurant_rounded;
    String mealType = 'snacks';
    if (waktu.contains('sarapan') || waktu.contains('pagi')) {
      accent = FMColors.primaryLight;
      timeIcon = Icons.wb_sunny_rounded;
      mealType = 'breakfast';
    } else if (waktu.contains('siang')) {
      accent = FMColors.carbsColor;
      timeIcon = Icons.light_mode_rounded;
      mealType = 'lunch';
    } else if (waktu.contains('malam')) {
      accent = const Color(0xFF8B5CF6);
      timeIcon = Icons.nightlight_round;
      mealType = 'dinner';
    } else if (waktu.contains('cemilan') || waktu.contains('snack')) {
      accent = FMColors.fatColor;
      timeIcon = Icons.cookie_rounded;
      mealType = 'snacks';
    }
    final localizedWaktu = AppStrings.get(mealType, lang);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? FMColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? FMColors.borderDark : FMColors.borderLight,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent.withOpacity(0.15), accent.withOpacity(0.06)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accent.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(timeIcon, color: accent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    localizedWaktu,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accent.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    "${totalKalori.toInt()} ${AppStrings.get('kkal', lang)}",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: accent.withOpacity(isDark ? 0.1 : 0.08)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              children: isi.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent, accent.withOpacity(0.2)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['nama_makanan'],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "P: ${item['protein']}g · K: ${item['karbo']}g",
                            style: TextStyle(
                              fontSize: 12,
                              color: subColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${(item['kalori'] as num).toInt()}",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: accent,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
