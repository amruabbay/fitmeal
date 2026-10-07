import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fit_meal/models/food_preference.dart';

/// Provider for managing user food preferences (whitelist / blacklist).
/// Persists data to SharedPreferences.
class FoodPreferenceProvider extends ChangeNotifier {
  static const String _storageKey = 'food_preferences_v1';

  FoodPreferences _preferences = FoodPreferences();
  bool _isLoaded = false;

  FoodPreferences get preferences => _preferences;
  bool get isLoaded => _isLoaded;

  List<String> get whitelistNames => _preferences.whitelistNames;
  List<String> get blacklistNames => _preferences.blacklistNames;
  List<FoodPreference> get whitelistItems => _preferences.whitelistItems;
  List<FoodPreference> get blacklistItems => _preferences.blacklistItems;

  bool get hasPreferences => _preferences.items.isNotEmpty;

  FoodPreferenceProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_storageKey);
    if (encoded != null && encoded.isNotEmpty) {
      try {
        _preferences = FoodPreferences.fromEncodedString(encoded);
      } catch (_) {
        _preferences = FoodPreferences();
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _preferences.toEncodedString());
  }

  /// Add a food to whitelist or blacklist.
  /// If the food already exists with a different type, it will be updated.
  Future<void> addPreference(String foodName, String type) async {
    final trimmed = foodName.trim();
    if (trimmed.isEmpty) return;

    // Remove existing entry for same food (case-insensitive)
    _preferences.items.removeWhere(
        (p) => p.foodName.toLowerCase() == trimmed.toLowerCase());

    _preferences.items.add(FoodPreference(
      foodName: trimmed,
      type: type,
    ));

    await _save();
    notifyListeners();
  }

  /// Remove a food preference by name.
  Future<void> removePreference(String foodName) async {
    _preferences.items.removeWhere(
        (p) => p.foodName.toLowerCase() == foodName.toLowerCase());
    await _save();
    notifyListeners();
  }

  /// Toggle a food preference between whitelist and blacklist.
  Future<void> toggleType(String foodName) async {
    final index = _preferences.items.indexWhere(
        (p) => p.foodName.toLowerCase() == foodName.toLowerCase());
    if (index == -1) return;

    final current = _preferences.items[index];
    final newType = current.type == 'whitelist' ? 'blacklist' : 'whitelist';

    _preferences.items[index] = FoodPreference(
      foodName: current.foodName,
      type: newType,
      createdAt: current.createdAt,
    );

    await _save();
    notifyListeners();
  }

  /// Check if a specific food is whitelisted.
  bool isWhitelisted(String foodName) =>
      _preferences.isWhitelisted(foodName);

  /// Check if a specific food is blacklisted.
  bool isBlacklisted(String foodName) =>
      _preferences.isBlacklisted(foodName);

  /// Check if a specific food has any preference set.
  bool hasPreference(String foodName) =>
      _preferences.hasPreference(foodName);

  /// Clear all preferences.
  Future<void> clearAll() async {
    _preferences = FoodPreferences();
    await _save();
    notifyListeners();
  }
}
