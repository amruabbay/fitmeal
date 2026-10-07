import 'dart:convert';
import 'package:fit_meal/models/food_item.dart';

class DailyLog {
  final String date; // "2026-03-31"
  final List<FoodItem> breakfast;
  final List<FoodItem> lunch;
  final List<FoodItem> dinner;
  final List<FoodItem> snacks;
  int waterGlasses; // 0–8

  // Targets (auto-saved from calculator)
  double targetCalories;
  double targetProtein;
  double targetCarbs;
  double targetFat;

  DailyLog({
    required this.date,
    List<FoodItem>? breakfast,
    List<FoodItem>? lunch,
    List<FoodItem>? dinner,
    List<FoodItem>? snacks,
    this.waterGlasses = 0,
    this.targetCalories = 2000,
    this.targetProtein = 150,
    this.targetCarbs = 250,
    this.targetFat = 65,
  })  : breakfast = breakfast ?? [],
        lunch = lunch ?? [],
        dinner = dinner ?? [],
        snacks = snacks ?? [];

  // --- Computed totals ---
  double get totalCalories =>
      _sumField(breakfast) +
      _sumField(lunch) +
      _sumField(dinner) +
      _sumField(snacks);

  double get totalProtein =>
      _sumProtein(breakfast) +
      _sumProtein(lunch) +
      _sumProtein(dinner) +
      _sumProtein(snacks);

  double get totalCarbs =>
      _sumCarbs(breakfast) +
      _sumCarbs(lunch) +
      _sumCarbs(dinner) +
      _sumCarbs(snacks);

  double get totalFat =>
      _sumFat(breakfast) +
      _sumFat(lunch) +
      _sumFat(dinner) +
      _sumFat(snacks);

  double _sumField(List<FoodItem> items) =>
      items.fold(0, (sum, item) => sum + item.calories);
  double _sumProtein(List<FoodItem> items) =>
      items.fold(0, (sum, item) => sum + item.protein);
  double _sumCarbs(List<FoodItem> items) =>
      items.fold(0, (sum, item) => sum + item.carbs);
  double _sumFat(List<FoodItem> items) =>
      items.fold(0, (sum, item) => sum + item.fat);

  List<FoodItem> getMealItems(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return breakfast;
      case 'lunch':
        return lunch;
      case 'dinner':
        return dinner;
      case 'snacks':
        return snacks;
      default:
        return [];
    }
  }

  // --- Serialization ---
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'breakfast': breakfast.map((e) => e.toJson()).toList(),
      'lunch': lunch.map((e) => e.toJson()).toList(),
      'dinner': dinner.map((e) => e.toJson()).toList(),
      'snacks': snacks.map((e) => e.toJson()).toList(),
      'waterGlasses': waterGlasses,
      'targetCalories': targetCalories,
      'targetProtein': targetProtein,
      'targetCarbs': targetCarbs,
      'targetFat': targetFat,
    };
  }

  factory DailyLog.fromJson(Map<String, dynamic> json) {
    return DailyLog(
      date: json['date'],
      breakfast: (json['breakfast'] as List?)
              ?.map((e) => FoodItem.fromJson(e))
              .toList() ??
          [],
      lunch: (json['lunch'] as List?)
              ?.map((e) => FoodItem.fromJson(e))
              .toList() ??
          [],
      dinner: (json['dinner'] as List?)
              ?.map((e) => FoodItem.fromJson(e))
              .toList() ??
          [],
      snacks: (json['snacks'] as List?)
              ?.map((e) => FoodItem.fromJson(e))
              .toList() ??
          [],
      waterGlasses: json['waterGlasses'] ?? 0,
      targetCalories: (json['targetCalories'] ?? 2000).toDouble(),
      targetProtein: (json['targetProtein'] ?? 150).toDouble(),
      targetCarbs: (json['targetCarbs'] ?? 250).toDouble(),
      targetFat: (json['targetFat'] ?? 65).toDouble(),
    );
  }

  String toEncodedString() => jsonEncode(toJson());

  factory DailyLog.fromEncodedString(String encoded) {
    return DailyLog.fromJson(jsonDecode(encoded));
  }
}
