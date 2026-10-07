import 'dart:math' as math;

class NutritionTargets {
  const NutritionTargets({
    required this.bmr,
    required this.tdee,
    required this.dietTarget,
    required this.effectiveCalories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double bmr;
  final double tdee;
  final double dietTarget;
  final double effectiveCalories;
  final double protein;
  final double carbs;
  final double fat;

  bool get safetyFloorApplied => dietTarget < bmr;
}

NutritionTargets calculateNutritionTargets({
  required double weightKg,
  required double heightCm,
  required int ageYears,
  required String gender,
  required String goal,
  required String activity,
}) {
  final normalizedGender = gender.toLowerCase();
  final normalizedGoal = goal.toLowerCase();
  final normalizedActivity = activity.toLowerCase();

  final bmr = normalizedGender == 'pria' || normalizedGender == 'male'
      ? (10 * weightKg) + (6.25 * heightCm) - (5 * ageYears) + 5
      : (10 * weightKg) + (6.25 * heightCm) - (5 * ageYears) - 161;

  var activityFactor = 1.2;
  if (normalizedActivity == 'moderate' ||
      normalizedActivity.contains('sedang')) {
    activityFactor = 1.55;
  } else if (normalizedActivity == 'active' ||
      normalizedActivity.contains('tinggi')) {
    activityFactor = 1.725;
  }

  final tdee = bmr * activityFactor;
  var dietTarget = tdee;
  if (normalizedGoal == 'cutting' ||
      normalizedGoal.contains('turun') ||
      normalizedGoal.contains('loss')) {
    dietTarget -= 500;
  } else if (normalizedGoal == 'bulking' ||
      normalizedGoal.contains('naik') ||
      normalizedGoal.contains('gain')) {
    dietTarget += 400;
  }

  // Safety floor: rekomendasi tidak boleh menggunakan target di bawah BMR.
  final effectiveCalories = math.max(dietTarget, bmr);
  final protein = weightKg > 0 ? weightKg * 2.0 : 150.0;
  final remainingCalories = math.max(effectiveCalories - (protein * 4), 0.0);
  final carbs = (remainingCalories * 0.55) / 4;
  final fat = (remainingCalories * 0.45) / 9;

  return NutritionTargets(
    bmr: bmr,
    tdee: tdee,
    dietTarget: dietTarget,
    effectiveCalories: effectiveCalories,
    protein: protein,
    carbs: carbs,
    fat: fat,
  );
}
