import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fit_meal/models/daily_log.dart';
import 'package:fit_meal/models/food_item.dart';
import 'package:intl/intl.dart';

class DailyLogProvider extends ChangeNotifier {
  DailyLog _todayLog = DailyLog(
    date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );

  DailyLog get todayLog => _todayLog;

  int _currentStreak = 0;
  int get currentStreak => _currentStreak;

  /// Completer that resolves once the initial load from SharedPreferences is done.
  final Completer<void> _initCompleter = Completer<void>();

  DailyLogProvider() {
    _loadTodayLog();
  }

  String get _todayKey =>
      'daily_log_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';

  // --- Load / Save ---
  Future<void> _loadTodayLog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_todayKey);

      // Always fetch global target from SharedPreferences
      final targetCal = prefs.getDouble('target_calories') ?? 2000;
      final targetPro = prefs.getDouble('target_protein') ?? 150;
      final targetCarbs = prefs.getDouble('target_carbs') ?? 250;
      final targetFat = prefs.getDouble('target_fat') ?? 65;

      if (encoded != null) {
        _todayLog = DailyLog.fromEncodedString(encoded);
        // Override with global targets to prevent stale values
        _todayLog.targetCalories = targetCal;
        _todayLog.targetProtein = targetPro;
        _todayLog.targetCarbs = targetCarbs;
        _todayLog.targetFat = targetFat;
      } else {
        _todayLog = DailyLog(
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          targetCalories: targetCal,
          targetProtein: targetPro,
          targetCarbs: targetCarbs,
          targetFat: targetFat,
        );
      }
      await _calculateStreak();
      notifyListeners();
    } finally {
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_todayKey, _todayLog.toEncodedString());
    await _calculateStreak();
  }

  // --- Targets (saved from calculator) ---
  Future<void> updateTargets({
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    // 🔥 Wait for initial load to complete first to prevent race condition
    // where _loadTodayLog() overwrites our new targets after we set them.
    await _initCompleter.future;

    _todayLog.targetCalories = calories;
    _todayLog.targetProtein = protein;
    _todayLog.targetCarbs = carbs;
    _todayLog.targetFat = fat;

    // Also persist targets globally for future days
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('target_calories', calories);
    await prefs.setDouble('target_protein', protein);
    await prefs.setDouble('target_carbs', carbs);
    await prefs.setDouble('target_fat', fat);

    await _save();
    notifyListeners();
  }

  // --- Food Logging ---
  void addFood(String mealType, FoodItem food) {
    switch (mealType) {
      case 'breakfast':
        _todayLog.breakfast.add(food);
        break;
      case 'lunch':
        _todayLog.lunch.add(food);
        break;
      case 'dinner':
        _todayLog.dinner.add(food);
        break;
      case 'snacks':
        _todayLog.snacks.add(food);
        break;
    }
    _save();
    notifyListeners();
  }

  void removeFood(String mealType, int index) {
    final items = _todayLog.getMealItems(mealType);
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      _save();
      notifyListeners();
    }
  }

  // --- Water Tracking ---
  void addWater() {
    if (_todayLog.waterGlasses < 8) {
      _todayLog.waterGlasses++;
      _save();
      notifyListeners();
    }
  }

  void removeWater() {
    if (_todayLog.waterGlasses > 0) {
      _todayLog.waterGlasses--;
      _save();
      notifyListeners();
    }
  }

  void setWater(int glasses) {
    _todayLog.waterGlasses = glasses.clamp(0, 8);
    _save();
    notifyListeners();
  }

  // --- Historical Data ---
  Future<DailyLog> getLogForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'daily_log_${DateFormat('yyyy-MM-dd').format(date)}';
    final encoded = prefs.getString(key);

    // Always use current global targets so stats reflect the latest user settings
    final targetCal = prefs.getDouble('target_calories') ?? _todayLog.targetCalories;
    final targetPro = prefs.getDouble('target_protein') ?? _todayLog.targetProtein;
    final targetCarbs = prefs.getDouble('target_carbs') ?? _todayLog.targetCarbs;
    final targetFat = prefs.getDouble('target_fat') ?? _todayLog.targetFat;

    if (encoded != null) {
      final log = DailyLog.fromEncodedString(encoded);
      // Override with current global targets
      log.targetCalories = targetCal;
      log.targetProtein = targetPro;
      log.targetCarbs = targetCarbs;
      log.targetFat = targetFat;
      return log;
    }
    return DailyLog(
      date: DateFormat('yyyy-MM-dd').format(date),
      targetCalories: targetCal,
      targetProtein: targetPro,
      targetCarbs: targetCarbs,
      targetFat: targetFat,
    );
  }

  Future<List<DailyLog>> getWeeklyLogs() async {
    final List<DailyLog> logs = [];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final log = await getLogForDate(date);
      logs.add(log);
    }
    return logs;
  }

  // --- Streak Calculation ---
  Future<void> _calculateStreak() async {
    int streak = 0;
    final now = DateTime.now();
    
    // Check backwards from yesterday
    DateTime date = now.subtract(const Duration(days: 1));
    while (true) {
      final log = await getLogForDate(date);
      // Empty/not-found logs will have 0 calories, which breaks the loop
      if (log.totalCalories >= 0.8 * log.targetCalories && log.targetCalories > 0) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break; // Streak broken!
      }
    }
    
    // Check today (if today hasn't reached 80% yet, it doesn't break the streak, it just doesn't add to it)
    if (_todayLog.totalCalories >= 0.8 * _todayLog.targetCalories && _todayLog.targetCalories > 0) {
      streak++;
    }
    
    _currentStreak = streak;
  }
}
