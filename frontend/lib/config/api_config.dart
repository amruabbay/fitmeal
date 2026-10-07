class ApiConfig {
  /// Base URL for the backend API.
  /// Update this single value when the Ngrok URL changes.
  static const String baseUrl =
      'https://fitmeal-2y91.onrender.com'; // Production backend Render

  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };

  static String get rekomendasiUrl => '$baseUrl/rekomendasi';
  static String searchUrl(String query, int page, int limit) =>
      '$baseUrl/search?q=$query&page=$page&limit=$limit';
}
