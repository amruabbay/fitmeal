import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fit_meal/config/api_config.dart';

class CalculatorProvider extends ChangeNotifier {
  bool _isLoading = false;
  Map<String, dynamic>? _resultData;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get resultData => _resultData;
  String? get errorMessage => _errorMessage;

  Future<void> hitungNutrisi({
    required double berat,
    required double tinggi,
    required int umur,
    required String gender,
    required String goal,
    required String activity,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.rekomendasiUrl),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'berat': berat,
          'tinggi': tinggi,
          'umur': umur,
          'gender': gender,
          'goal': goal,
          'activity': activity,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['user_info'] != null) {
          data['user_info']['berat_input'] = berat;
          data['user_info']['tinggi_input'] = tinggi;
        }
        _resultData = data;
        _errorMessage = null;
      } else {
        _errorMessage = 'Gagal: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Koneksi Gagal. Cek Link Ngrok.';
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearResult() {
    _resultData = null;
    _errorMessage = null;
    notifyListeners();
  }
}
