import 'dart:convert';

class FoodItem {
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const FoodItem({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['nama_makanan'] ?? '',
      calories: (json['kalori'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['karbo'] ?? 0).toDouble(),
      fat: (json['lemak'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_makanan': name,
      'kalori': calories,
      'protein': protein,
      'karbo': carbs,
      'lemak': fat,
    };
  }

  /// For SharedPreferences persistence
  String toEncodedString() => jsonEncode(toJson());

  factory FoodItem.fromEncodedString(String encoded) {
    return FoodItem.fromJson(jsonDecode(encoded));
  }
}
