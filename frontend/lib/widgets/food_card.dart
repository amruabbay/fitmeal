import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fit_meal/main.dart' show FMColors;
import 'package:fit_meal/models/food_item.dart';
import 'package:fit_meal/widgets/nutrient_badge.dart';
import 'package:fit_meal/providers/daily_log_provider.dart';
import 'package:fit_meal/providers/language_provider.dart';
import 'package:fit_meal/config/app_strings.dart';

class FoodCard extends StatelessWidget {
  final FoodItem food;
  final Widget? trailing;
  final VoidCallback? onTap;

  const FoodCard({
    super.key,
    required this.food,
    this.trailing,
    this.onTap,
  });

  factory FoodCard.fromMap(Map item, {Widget? trailing, VoidCallback? onTap}) {
    return FoodCard(
      food: FoodItem.fromJson(item.cast<String, dynamic>()),
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? FMColors.titleDark : FMColors.titleLight;
    final subColor   = isDark ? FMColors.subDark   : FMColors.subLight;
    final primary = Theme.of(context).primaryColor;
    final lang = Provider.of<LanguageProvider>(context).locale;

    // AI Badge logic
    final logParams = Provider.of<DailyLogProvider>(context, listen: false).todayLog;
    final remainingCal = (logParams.targetCalories - logParams.totalCalories)
        .clamp(0, logParams.targetCalories);

    IconData badgeIcon  = Icons.balance_rounded;
    String   badgeText  = AppStrings.get('badge_balanced_label', lang);
    Color    badgeColor = FMColors.fatColor;

    if (food.protein >= 15 && food.fat <= 5) {
      badgeIcon = Icons.star_rounded;
      badgeText = AppStrings.get('badge_high_protein_good_label', lang);
      badgeColor = const Color(0xFF8B5CF6);
    } else if (food.protein >= 10) {
      badgeIcon = Icons.fitness_center_rounded;
      badgeText = AppStrings.get('badge_rich_protein_label', lang);
      badgeColor = FMColors.proteinColor;
    } else if (food.calories > 0 &&
        food.calories <= remainingCal * 0.4 &&
        food.calories >= 50) {
      badgeIcon = Icons.track_changes_rounded;
      badgeText = AppStrings.get('badge_fits_remaining_label', lang);
      badgeColor = primary;
    } else if (food.fat <= 3 && food.calories < 200) {
      badgeIcon = Icons.eco_rounded;
      badgeText = AppStrings.get('badge_low_fat_label', lang);
      badgeColor = FMColors.carbsColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? FMColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? FMColors.borderDark : FMColors.borderLight,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: primary.withOpacity(0.08),
          highlightColor: primary.withOpacity(0.04),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Left accent bar
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [badgeColor, badgeColor.withOpacity(0.3)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                // Food info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: badgeColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(badgeIcon, size: 11,
                                color: isDark
                                    ? Colors.white
                                    : Color.lerp(badgeColor, Colors.black, 0.3)!),
                            const SizedBox(width: 4),
                            Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : Color.lerp(badgeColor, Colors.black, 0.3)!,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Macro badges row
                      Row(
                        children: [
                          NutrientBadge(
                            label: "P",
                            value: "${food.protein.toStringAsFixed(1)}g",
                            color: Colors.blue,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 5),
                          NutrientBadge(
                            label: "K",
                            value: "${food.carbs.toStringAsFixed(1)}g",
                            color: Colors.green,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 5),
                          NutrientBadge(
                            label: "L",
                            value: "${food.fat.toStringAsFixed(1)}g",
                            color: Colors.orange,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Trailing — calorie box
                if (trailing != null)
                  trailing!
                else
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primary.withOpacity(0.12),
                          primary.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${food.calories.toInt()}",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: primary,
                          ),
                        ),
                        Text(
                          AppStrings.get('kkal', lang),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: subColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
