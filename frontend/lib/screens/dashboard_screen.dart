import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fit_meal/main.dart' show FMColors;
import 'package:fit_meal/providers/daily_log_provider.dart';
import 'package:fit_meal/providers/language_provider.dart';
import 'package:fit_meal/config/app_strings.dart';
import 'package:fit_meal/widgets/macro_ring_chart.dart';
import 'package:fit_meal/widgets/water_tracker_widget.dart';
import 'package:fit_meal/widgets/meal_section_card.dart';
import 'package:fit_meal/widgets/tactile_scale_effect.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onNavigateToSearch;

  const DashboardScreen({
    super.key,
    required this.onNavigateToSearch,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? FMColors.titleDark : FMColors.titleLight;
    final subColor   = isDark ? FMColors.subDark   : FMColors.subLight;
    final lang = Provider.of<LanguageProvider>(context).locale;

    return Consumer<DailyLogProvider>(
      builder: (context, logProvider, _) {
        final log = logProvider.todayLog;

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // =========================================
                // HERO CALORIE CARD (Clean & Minimal)
                // =========================================
                _HeroCalorieCard(
                  log: log, 
                  isDark: isDark,
                  streak: logProvider.currentStreak,
                ),

                const SizedBox(height: 32),

                // =========================================
                // MACRO PROGRESS BARS
                // =========================================
                _SectionHeader(title: AppStrings.get('macronutrients', lang), subColor: subColor, titleColor: titleColor),
                const SizedBox(height: 16),
                MacroProgressBar(
                  label: AppStrings.get('protein', lang),
                  icon: Icons.egg_rounded,
                  consumed: log.totalProtein,
                  target: log.targetProtein,
                  color: FMColors.proteinColor,
                ),
                const SizedBox(height: 10),
                MacroProgressBar(
                  label: AppStrings.get('carbs', lang),
                  icon: Icons.grain_rounded,
                  consumed: log.totalCarbs,
                  target: log.targetCarbs,
                  color: FMColors.carbsColor,
                ),
                const SizedBox(height: 10),
                MacroProgressBar(
                  label: AppStrings.get('fat', lang),
                  icon: Icons.water_drop_rounded,
                  consumed: log.totalFat,
                  target: log.targetFat,
                  color: FMColors.fatColor,
                ),

                const SizedBox(height: 32),

                // =========================================
                // WATER TRACKER
                // =========================================
                WaterTrackerWidget(
                  currentGlasses: log.waterGlasses,
                  onAdd: () => logProvider.addWater(),
                  onRemove: () => logProvider.removeWater(),
                ),

                const SizedBox(height: 32),

                // =========================================
                // CATATAN MAKAN HEADER
                // =========================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SectionHeader(title: AppStrings.get('food_log', lang), subColor: subColor, titleColor: titleColor),
                    TactileScaleEffect(
                      scaleDownTo: 0.94,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onNavigateToSearch();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? FMColors.surfaceDark : FMColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.add_rounded, size: 16, color: isDark ? FMColors.titleDark : Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                AppStrings.get('add', lang),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? FMColors.titleDark : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // =========================================
                // MEAL CARDS
                // =========================================
                MealSectionCard(
                  title: AppStrings.get('breakfast', lang),
                  icon: Icons.wb_sunny_rounded,
                  accentColor: FMColors.breakfastColor,
                  items: log.breakfast,
                  onAddPressed: onNavigateToSearch,
                  onRemoveItem: (i) => logProvider.removeFood('breakfast', i),
                ),
                MealSectionCard(
                  title: AppStrings.get('lunch', lang),
                  icon: Icons.light_mode_rounded,
                  accentColor: FMColors.lunchColor,
                  items: log.lunch,
                  onAddPressed: onNavigateToSearch,
                  onRemoveItem: (i) => logProvider.removeFood('lunch', i),
                ),
                MealSectionCard(
                  title: AppStrings.get('dinner', lang),
                  icon: Icons.nightlight_round,
                  accentColor: FMColors.dinnerColor,
                  items: log.dinner,
                  onAddPressed: onNavigateToSearch,
                  onRemoveItem: (i) => logProvider.removeFood('dinner', i),
                ),
                MealSectionCard(
                  title: AppStrings.get('snacks', lang),
                  icon: Icons.cookie_rounded,
                  accentColor: FMColors.snackColor,
                  items: log.snacks,
                  onAddPressed: onNavigateToSearch,
                  onRemoveItem: (i) => logProvider.removeFood('snacks', i),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =========================================================
// HERO CALORIE CARD (Minimalist)
// =========================================================
class _HeroCalorieCard extends StatelessWidget {
  final dynamic log;
  final bool isDark;
  final int streak;

  const _HeroCalorieCard({
    required this.log,
    required this.isDark,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).locale;
    final pct = log.targetCalories > 0
        ? (log.totalCalories / log.targetCalories).clamp(0.0, 1.0)
        : 0.0;
    final isOver = log.totalCalories > log.targetCalories;

    final titleColor = isDark ? FMColors.titleDark : FMColors.titleLight;
    final subColor   = isDark ? FMColors.subDark   : FMColors.subLight;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? FMColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? FMColors.borderDark : FMColors.borderLight,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('calorie_summary', lang),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.get('today', lang),
                      style: TextStyle(
                        fontSize: 14,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
                // Minimal badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: FMColors.primaryLight.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          color: FMColors.primaryLight, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "$streak ${AppStrings.get('day_streak', lang)}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? FMColors.titleDark : FMColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Calorie ring — centered
            Center(
              child: MacroRingChart(
                consumed: log.totalCalories,
                target: log.targetCalories,
                color: FMColors.primaryLight,
                label: AppStrings.get('kkal', lang),
                size: 200,
              ),
            ),

            const SizedBox(height: 32),

            // Bottom status row (Minimal)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? FMColors.canvasDark : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatPill(
                    label: AppStrings.get('consumed', lang),
                    value: "${log.totalCalories.toInt()}",
                    unit: AppStrings.get('kkal', lang),
                    titleColor: titleColor,
                    subColor: subColor,
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: isDark ? FMColors.borderDark : FMColors.borderLight,
                  ),
                  _StatPill(
                    label: isOver ? AppStrings.get('exceeded', lang) : AppStrings.get('remaining', lang),
                    value: "${(log.targetCalories - log.totalCalories).abs().toInt()}",
                    unit: AppStrings.get('kkal', lang),
                    valueColor: isOver ? const Color(0xFFEF4444) : FMColors.primaryLight,
                    titleColor: titleColor,
                    subColor: subColor,
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: isDark ? FMColors.borderDark : FMColors.borderLight,
                  ),
                  _StatPill(
                    label: AppStrings.get('progress', lang),
                    value: "${(pct * 100).toInt()}%",
                    unit: AppStrings.get('target', lang),
                    titleColor: titleColor,
                    subColor: subColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? valueColor;
  final Color titleColor;
  final Color subColor;

  const _StatPill({
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor,
    required this.titleColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: subColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: valueColor ?? titleColor,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 10,
            color: subColor,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// =========================================================
// SECTION HEADER
// =========================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  final Color subColor;
  final Color titleColor;

  const _SectionHeader({
    required this.title,
    required this.subColor,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: titleColor,
        letterSpacing: -0.3,
      ),
    );
  }
}
