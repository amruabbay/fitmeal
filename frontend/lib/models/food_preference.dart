import 'dart:convert';

/// Represents a single food preference entry (whitelist or blacklist).
class FoodPreference {
  final String foodName;
  final String type; // 'whitelist' or 'blacklist'
  final DateTime createdAt;

  FoodPreference({
    required this.foodName,
    required this.type,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'foodName': foodName,
        'type': type,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FoodPreference.fromJson(Map<String, dynamic> json) {
    return FoodPreference(
      foodName: json['foodName'] ?? '',
      type: json['type'] ?? 'blacklist',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Container that holds all user food preferences.
class FoodPreferences {
  List<FoodPreference> items;

  FoodPreferences({List<FoodPreference>? items})
      : items = items ?? [];

  List<String> get whitelistNames => items
      .where((p) => p.type == 'whitelist')
      .map((p) => p.foodName)
      .toList();

  List<String> get blacklistNames => items
      .where((p) => p.type == 'blacklist')
      .map((p) => p.foodName)
      .toList();

  List<FoodPreference> get whitelistItems =>
      items.where((p) => p.type == 'whitelist').toList();

  List<FoodPreference> get blacklistItems =>
      items.where((p) => p.type == 'blacklist').toList();

  bool isWhitelisted(String foodName) =>
      items.any((p) => p.type == 'whitelist' &&
          p.foodName.toLowerCase() == foodName.toLowerCase());

  bool isBlacklisted(String foodName) =>
      items.any((p) => p.type == 'blacklist' &&
          p.foodName.toLowerCase() == foodName.toLowerCase());

  bool hasPreference(String foodName) =>
      items.any((p) => p.foodName.toLowerCase() == foodName.toLowerCase());

  String toEncodedString() =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  factory FoodPreferences.fromEncodedString(String encoded) {
    final List<dynamic> list = jsonDecode(encoded);
    return FoodPreferences(
      items: list
          .map((e) => FoodPreference.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
