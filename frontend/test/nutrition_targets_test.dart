import 'package:fit_meal/utils/nutrition_targets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TC-019 memakai BMR sebagai safety floor', () {
    final targets = calculateNutritionTargets(
      weightKg: 55,
      heightCm: 158,
      ageYears: 28,
      gender: 'wanita',
      goal: 'cutting',
      activity: 'sedentary',
    );

    expect(targets.bmr, closeTo(1236.5, 0.001));
    expect(targets.dietTarget, closeTo(983.8, 0.001));
    expect(targets.effectiveCalories, closeTo(1236.5, 0.001));
    expect(targets.effectiveCalories, greaterThanOrEqualTo(targets.bmr));
    expect(targets.safetyFloorApplied, isTrue);
  });

  test('target di atas BMR tidak diubah', () {
    final targets = calculateNutritionTargets(
      weightKg: 70,
      heightCm: 170,
      ageYears: 25,
      gender: 'pria',
      goal: 'maintain',
      activity: 'sedentary',
    );

    expect(targets.effectiveCalories, closeTo(targets.dietTarget, 0.001));
    expect(targets.safetyFloorApplied, isFalse);
  });
}
