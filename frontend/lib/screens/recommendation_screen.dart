import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fit_meal/config/api_config.dart';
import 'package:fit_meal/config/app_strings.dart';
import 'package:fit_meal/models/food_item.dart';
import 'package:fit_meal/providers/user_profile_provider.dart';
import 'package:fit_meal/utils/nutrition_targets.dart';
import 'package:fit_meal/providers/daily_log_provider.dart';
import 'package:fit_meal/providers/food_preference_provider.dart';
import 'package:fit_meal/providers/language_provider.dart';
import 'package:fit_meal/screens/food_preferences_screen.dart';
import 'package:fit_meal/widgets/tactile_scale_effect.dart';

// ============================================================
// BLACKLIST: Makanan tidak sehat yang TIDAK BOLEH muncul
// di halaman Rekomendasi (Otomatis maupun Pilih Sendiri).
// Makanan ini tetap bisa dicari lewat tab Pencarian Umum.
// ============================================================
const List<String> _blacklistKeywords = [
  // Fast Food & Jajanan
  "kfc", "mcd", "mcdonalds", "burger", "pizza", "hokben", "solaria",
  "a&w", "wendys", "fast food", "junk food", "french fries", "kentang goreng",
  "hotdog", "corndog", "chicken wings", "chicken nugget", "nugget",
  "kebab", "shawarma", "doner", "taco", "burrito",
  "sushi", "ramen", "tempura", "dimsum", "takoyaki",
  "croffle", "cromboloni", "toast", "dessert box",

  // Olahan Minyak & Gorengan
  "gorengan", "crispy", "penyet", "geprek", "kulit ayam", "kulit",
  "fried chicken", "ayam goreng", "bebek goreng", "lele goreng",
  "bakwan", "bala-bala", "cireng", "cimol", "cilok", "batagor", "pempek",
  "kerupuk", "krupuk", "rempeyek", "emping", "mendoan", "risol", "lumpia",
  "pastel", "basreng", "kripik", "keripik", "chiki", "seblak", "cuanki",
  "maklor", "cilor",

  // Lemak Tinggi & Jeroan
  "santan", "gulai", "rendang", "tongseng", "opor", "soto betawi",
  "jeroan", "usus", "babat", "kikil", "tunjang", "otak", "paru", "ati ampela",
  "sate kambing", "sate padang", "sate kulit",
  "gajih", "lemak", "minyak",

  // Karbo Olahan & Mie
  "indomie", "mie instan", "mie goreng", "mie rebus", "sosis", "kornet",
  "kaleng",
  "kwetiau", "bihun goreng", "ifumie", "nasgor", "nasi goreng",
  "nasi uduk", "nasi kuning", "nasi liwet", "nasi hainam", "nasi kebuli",
  "martabak", "roti bakar", "kue", "gacoan", "bakso", "baso", "mie ayam",
  "pangsit",
  "biskuit", "wafer", "cake", "pudding", "crepes", "pukis", "pancong",
  "kue cubit",

  // Minuman Manis
  "boba", "bubble", "milk tea", "chatime", "starbucks",
  "kopi susu", "cappucino", "latte", "frappe", "smoothie", "kopi", "teh",
  "es teh manis", "teh tarik", "es campur", "es teler", "es doger", "es krim",
  "ice cream",
  "coklat", "chocolate", "brown sugar", "gula aren", "sirup", "soda",
  "susu kental manis", "skm", "full cream",
];

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});
  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen>
    with TickerProviderStateMixin {
  static const String _recommendationCacheKey = 'recommendation_cache_v1';

  late TabController _tabController;

  // ========== TAB 1: Otomatis ==========
  bool _isLoading = false;
  bool _hasData = false;
  bool _hasError = false;
  String _errorMsg = '';
  Map<String, dynamic>? _userInfo;
  Map<String, dynamic>? _hasilGenerasi;
  List<dynamic> _menu = [];
  final Set<String> _addedMeals = {};

  // ========== TAB 2: Pilih Sendiri ==========
  int _selectedCategoryIndex = 0;
  bool _isCategoryLoading = false;
  List<dynamic> _categoryResults = [];
  int _categoryPage = 0;
  bool _isCategoryLoadingMore = false;
  bool _hasMoreCategoryFoods = true;
  final ScrollController _categoryScrollController = ScrollController();
  int _categoryFetchId = 0; // Generation counter to cancel stale fetches

  // Per-category cache: avoids re-fetching when switching tabs
  final Map<int, List<dynamic>> _categoryCacheResults = {};
  final Map<int, int> _categoryCachePage = {};
  final Map<int, bool> _categoryCacheHasMore = {};

  static const List<Map<String, dynamic>> _categories = [
    {
      'label': 'category_protein',
      'icon': Icons.egg_alt_rounded,
      'queries': ['ayam', 'telur', 'ikan', 'tempe', 'tahu', 'daging', 'udang']
    },
    {
      'label': 'category_carbs',
      'icon': Icons.rice_bowl,
      'queries': ['nasi', 'roti', 'mie', 'kentang', 'oatmeal', 'jagung']
    },
    {
      'label': 'category_veggies',
      'icon': Icons.eco_rounded,
      'queries': ['bayam', 'brokoli', 'kangkung', 'wortel', 'sayur', 'sop']
    },
    {
      'label': 'category_fruits',
      'icon': Icons.apple,
      'queries': ['pisang', 'apel', 'jeruk', 'mangga', 'semangka', 'pepaya']
    },
  ];

  late AnimationController _shimmerController;
  String? _activeProfileSignature;
  bool _didAttemptCacheRestore = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _categoryScrollController.addListener(() {
      final pixels = _categoryScrollController.position.pixels;
      final maxExtent = _categoryScrollController.position.maxScrollExtent;
      if (pixels >= maxExtent - 200) {
        debugPrint(
            '[InfiniteScroll] Near bottom: pixels=$pixels, max=$maxExtent, loading=$_isCategoryLoading, loadingMore=$_isCategoryLoadingMore, hasMore=$_hasMoreCategoryFoods');
        if (!_isCategoryLoading &&
            !_isCategoryLoadingMore &&
            _hasMoreCategoryFoods) {
          debugPrint('[InfiniteScroll] Triggering loadMore...');
          _fetchCategoryFoods(isLoadMore: true);
        }
      }
    });

    // Load first category on init
    _fetchCategoryFoods();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final currentProfileSignature = _getCurrentProfileSignature();
    if (!_didAttemptCacheRestore) {
      _didAttemptCacheRestore = true;
      _activeProfileSignature = currentProfileSignature;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          final restored = await _restoreCachedRecommendation();
          if (!restored && mounted) {
            await _restoreCachedRecommendation(allowAnyDate: true);
          }
        }
      });
      return;
    }

    if (_activeProfileSignature != currentProfileSignature) {
      _activeProfileSignature = currentProfileSignature;
      _handleProfileChanged();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _shimmerController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  // ========================================
  // TAB 1: AUTO RECOMMENDATION LOGIC
  // ========================================
  Future<void> _fetchRecommendation() async {
    final profileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final logProvider = Provider.of<DailyLogProvider>(context, listen: false);
    final profile = profileProvider.profile;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _hasData = false;
      _addedMeals.clear();
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.rekomendasiUrl),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'berat': profile.berat,
          'tinggi': profile.tinggi,
          'umur': profile.umur,
          'gender': profile.gender,
          'goal': profile.goal,
          'activity': profile.activity,
          'preferred_foods':
              Provider.of<FoodPreferenceProvider>(context, listen: false)
                  .whitelistNames,
          'excluded_foods':
              Provider.of<FoodPreferenceProvider>(context, listen: false)
                  .blacklistNames,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(jsonDecode(response.body));
        final userInfo = data['user_info'] is Map
            ? Map<String, dynamic>.from(data['user_info'])
            : null;
        final hasilGenerasi = data['hasil_generasi'] is Map
            ? Map<String, dynamic>.from(data['hasil_generasi'])
            : null;
        final menu = (data['menu'] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        await _syncTargetsToDashboard(logProvider, userInfo);
        await _saveRecommendationCacheWithData(
          userInfo: userInfo,
          hasilGenerasi: hasilGenerasi,
          menu: menu,
          addedMeals: const <String>{},
          profileSignature: _getCurrentProfileSignature(),
        );

        if (!mounted) return;

        setState(() {
          _userInfo = userInfo;
          _hasilGenerasi = hasilGenerasi;
          _menu = menu;
          _hasData = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          final hasBlacklist =
              Provider.of<FoodPreferenceProvider>(context, listen: false)
                  .blacklistNames
                  .isNotEmpty;
          _errorMsg = hasBlacklist
              ? 'Server error: ${response.statusCode}\n\nBatasan preferensi makanan Anda mungkin terlalu ketat sehingga algoritma tidak menemukan kombinasi yang pas. Coba kurangi makanan yang dihindari.'
              : 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      // Hasilkan rekomendasi otomatis secara lokal (Offline Engine)
      final offlineData = _generateOfflineRecommendationData();
      final userInfo =
          Map<String, dynamic>.from(offlineData['user_info'] as Map);
      final hasilGenerasi =
          Map<String, dynamic>.from(offlineData['hasil_generasi'] as Map);
      final menu = List<dynamic>.from(offlineData['menu'] as List);

      await _syncTargetsToDashboard(logProvider, userInfo);
      await _saveRecommendationCacheWithData(
        userInfo: userInfo,
        hasilGenerasi: hasilGenerasi,
        menu: menu,
        addedMeals: const <String>{},
        profileSignature: _getCurrentProfileSignature(),
      );

      if (!mounted) return;
      setState(() {
        _userInfo = userInfo;
        _hasilGenerasi = hasilGenerasi;
        _menu = menu;
        _hasData = true;
        _hasError = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "⚡ Mode Offline: Menu disusun menggunakan Constraint-Based Filtering lokal."),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Map<String, dynamic> _generateOfflineRecommendationData() {
    final profileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final profile = profileProvider.profile;
    final prefProvider =
        Provider.of<FoodPreferenceProvider>(context, listen: false);
    final blacklist = prefProvider.blacklistNames.toSet();

    final targets = calculateNutritionTargets(
      weightKg: profile.berat,
      heightCm: profile.tinggi,
      ageYears: profile.umur,
      gender: profile.gender,
      goal: profile.goal,
      activity: profile.activity,
    );
    final targetCal = targets.effectiveCalories;
    final targetPro = targets.protein;
    final targetCarb = targets.carbs;
    final targetFat = targets.fat;

    final List<Map<String, dynamic>> allOfflinePool = [
      {
        'nama_makanan': 'Dada Ayam Kukus (100g)',
        'kalori': 165.0,
        'protein': 31.0,
        'karbo': 0.0,
        'lemak': 3.6
      },
      {
        'nama_makanan': 'Nasi Merah (150g)',
        'kalori': 165.0,
        'protein': 3.8,
        'karbo': 35.0,
        'lemak': 1.4
      },
      {
        'nama_makanan': 'Telur Rebus (2 butir)',
        'kalori': 156.0,
        'protein': 12.6,
        'karbo': 1.1,
        'lemak': 10.6
      },
      {
        'nama_makanan': 'Oatmeal Polos (50g)',
        'kalori': 190.0,
        'protein': 6.5,
        'karbo': 34.0,
        'lemak': 3.0
      },
      {
        'nama_makanan': 'Tempe Bacem (2 potong)',
        'kalori': 130.0,
        'protein': 9.0,
        'karbo': 11.0,
        'lemak': 5.5
      },
      {
        'nama_makanan': 'Tahu Kukus (2 potong)',
        'kalori': 90.0,
        'protein': 9.0,
        'karbo': 3.0,
        'lemak': 5.0
      },
      {
        'nama_makanan': 'Sayur Bening Bayam (1 porsi)',
        'kalori': 45.0,
        'protein': 2.5,
        'karbo': 8.0,
        'lemak': 0.5
      },
      {
        'nama_makanan': 'Brokoli Kukus (100g)',
        'kalori': 35.0,
        'protein': 2.8,
        'karbo': 7.0,
        'lemak': 0.4
      },
      {
        'nama_makanan': 'Ikan Kembung Panggang (1 ekor)',
        'kalori': 180.0,
        'protein': 22.0,
        'karbo': 0.0,
        'lemak': 10.0
      },
      {
        'nama_makanan': 'Tumis Kangkung (1 porsi)',
        'kalori': 65.0,
        'protein': 2.2,
        'karbo': 6.5,
        'lemak': 3.8
      },
      {
        'nama_makanan': 'Pisang Ambon (1 buah)',
        'kalori': 105.0,
        'protein': 1.3,
        'karbo': 27.0,
        'lemak': 0.3
      },
      {
        'nama_makanan': 'Apel Merah (1 buah)',
        'kalori': 95.0,
        'protein': 0.5,
        'karbo': 25.0,
        'lemak': 0.3
      },
      {
        'nama_makanan': 'Kentang Rebus (150g)',
        'kalori': 130.0,
        'protein': 3.0,
        'karbo': 30.0,
        'lemak': 0.2
      },
      {
        'nama_makanan': 'Sop Sayuran Sehat (1 porsi)',
        'kalori': 85.0,
        'protein': 3.5,
        'karbo': 12.0,
        'lemak': 2.0
      },
      {
        'nama_makanan': 'Ikan Gurame Bakar (100g)',
        'kalori': 140.0,
        'protein': 19.0,
        'karbo': 0.0,
        'lemak': 7.0
      },
    ];

    final filteredPool = allOfflinePool.where((item) {
      final nameLower = (item['nama_makanan'] as String).toLowerCase();
      return !blacklist.any((b) => nameLower.contains(b.toLowerCase()));
    }).toList();

    final pool = List<Map<String, dynamic>>.from(
        filteredPool.isNotEmpty ? filteredPool : allOfflinePool)
      ..sort((a, b) => (b['kalori'] as num)
          .toDouble()
          .compareTo((a['kalori'] as num).toDouble()));
    final usedNames = <String>{};

    List<Map<String, dynamic>> buildMeal(double calorieLimit) {
      final meal = <Map<String, dynamic>>[];
      var total = 0.0;
      for (final item in pool) {
        final name = item['nama_makanan'] as String;
        final calories = (item['kalori'] as num).toDouble();
        if (!usedNames.contains(name) &&
            total + calories <= calorieLimit &&
            meal.length < 3) {
          meal.add(item);
          usedNames.add(name);
          total += calories;
        }
      }
      return meal;
    }

    final sarapan = buildMeal(targetCal * 0.30);
    final siang = buildMeal(targetCal * 0.40);
    final malam = buildMeal(targetCal * 0.30);
    final selectedItems = [...sarapan, ...siang, ...malam];

    double sumMacro(String key) => selectedItems.fold(
        0.0, (sum, item) => sum + (item[key] as num).toDouble());
    double accuracy(double achieved, double target) {
      if (target <= 0) return 100.0;
      return ((1 - (target - achieved).abs() / target) * 100).clamp(0.0, 100.0);
    }

    final achievedCal = sumMacro('kalori');
    final achievedPro = sumMacro('protein');
    final achievedCarb = sumMacro('karbo');
    final achievedFat = sumMacro('lemak');

    return {
      'user_info': {
        'target_kalori': targetCal,
        'target_protein': targetPro,
        'target_karbo': targetCarb,
        'target_lemak': targetFat,
      },
      'hasil_generasi': {
        'algorithm': 'Constraint-Based Filtering (Lokal)',
        'candidate_count': filteredPool.length,
        'rules_applied': 4,
        'target_macros': {
          'kalori': targetCal,
          'protein': targetPro,
          'karbo': targetCarb,
          'lemak': targetFat
        },
        'achieved_macros': {
          'kalori': achievedCal,
          'protein': achievedPro,
          'karbo': achievedCarb,
          'lemak': achievedFat
        },
        'accuracy_pct': {
          'kalori': accuracy(achievedCal, targetCal),
          'protein': accuracy(achievedPro, targetPro),
          'karbo': accuracy(achievedCarb, targetCarb),
          'lemak': accuracy(achievedFat, targetFat)
        },
      },
      'menu': [
        {'waktu': 'Sarapan', 'isi': sarapan},
        {'waktu': 'Makan Siang', 'isi': siang},
        {'waktu': 'Makan Malam', 'isi': malam},
      ]
    };
  }

  String _mapWaktuToMealType(String waktu) {
    final lower = waktu.toLowerCase();
    if (lower.contains('sarapan') || lower.contains('pagi')) return 'breakfast';
    if (lower.contains('siang')) return 'lunch';
    if (lower.contains('malam')) return 'dinner';
    return 'snacks';
  }

  void _addMealToLog(Map<String, dynamic> mealData) {
    final logProvider = Provider.of<DailyLogProvider>(context, listen: false);
    final mealType = _mapWaktuToMealType(mealData['waktu'] ?? '');
    final List items = mealData['isi'] ?? [];
    for (final item in items) {
      logProvider.addFood(
          mealType,
          FoodItem(
            name: item['nama_makanan'] ?? '',
            calories: (item['kalori'] ?? 0).toDouble(),
            protein: (item['protein'] ?? 0).toDouble(),
            carbs: (item['karbo'] ?? 0).toDouble(),
            fat: (item['lemak'] ?? 0).toDouble(),
          ));
    }
    setState(() => _addedMeals.add(mealData['waktu']));
    _saveRecommendationCache();

    final lang = Provider.of<LanguageProvider>(context, listen: false).locale;
    final mealName = AppStrings.get(mealType, lang);
    final addedMsg = AppStrings.get('added_to_log', lang);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("$mealName $addedMsg"),
      backgroundColor: Theme.of(context).primaryColor,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  void _addAllToLog() {
    for (final meal in _menu) {
      if (!_addedMeals.contains(meal['waktu'])) _addMealToLog(meal);
    }
  }

  String _getCurrentProfileSignature() {
    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).profile;
    return profile.toEncodedString();
  }

  String _todayStamp() {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<bool> _restoreCachedRecommendation({bool allowAnyDate = false}) async {
    final logProvider = Provider.of<DailyLogProvider>(context, listen: false);
    final currentProfileSignature = _getCurrentProfileSignature();
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_recommendationCacheKey);
    if (encoded == null) return false;

    try {
      final cache = Map<String, dynamic>.from(jsonDecode(encoded));
      final cacheDate = cache['date']?.toString();
      final cacheProfileSignature = cache['profile_signature']?.toString();

      if (!allowAnyDate &&
          (cacheDate != _todayStamp() ||
              cacheProfileSignature != currentProfileSignature)) {
        await _clearRecommendationCache();
        return false;
      }

      final userInfo = cache['user_info'] is Map
          ? Map<String, dynamic>.from(cache['user_info'])
          : null;
      final hasilGenerasi = cache['hasil_generasi'] is Map
          ? Map<String, dynamic>.from(cache['hasil_generasi'])
          : null;
      final menu = (cache['menu'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      final addedMeals = (cache['added_meals'] as List? ?? const [])
          .map((item) => item.toString())
          .toSet();

      await _syncTargetsToDashboard(logProvider, userInfo);

      if (!mounted) return false;
      setState(() {
        _userInfo = userInfo;
        _hasilGenerasi = hasilGenerasi;
        _menu = menu;
        _addedMeals
          ..clear()
          ..addAll(addedMeals);
        _hasData = userInfo != null || menu.isNotEmpty;
        _hasError = false;
        _errorMsg = '';
        _isLoading = false;
      });
      return _hasData;
    } catch (_) {
      await _clearRecommendationCache();
      return false;
    }
  }

  Future<void> _handleProfileChanged() async {
    await _clearRecommendationCache();
    if (!mounted) return;

    setState(() {
      _resetAutoRecommendationState();
    });
  }

  void _resetAutoRecommendationState() {
    _isLoading = false;
    _hasData = false;
    _hasError = false;
    _errorMsg = '';
    _userInfo = null;
    _hasilGenerasi = null;
    _menu = [];
    _addedMeals.clear();
  }

  Future<void> _saveRecommendationCache() async {
    await _saveRecommendationCacheWithData(
      userInfo: _userInfo,
      hasilGenerasi: _hasilGenerasi,
      menu: _menu,
      addedMeals: _addedMeals,
      profileSignature: _getCurrentProfileSignature(),
    );
  }

  Future<void> _saveRecommendationCacheWithData({
    required Map<String, dynamic>? userInfo,
    required Map<String, dynamic>? hasilGenerasi,
    required List<dynamic> menu,
    required Set<String> addedMeals,
    required String profileSignature,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'date': _todayStamp(),
      'profile_signature': profileSignature,
      'user_info': userInfo,
      'hasil_generasi': hasilGenerasi,
      'menu': menu,
      'added_meals': addedMeals.toList(),
    };
    await prefs.setString(_recommendationCacheKey, jsonEncode(payload));
  }

  Future<void> _clearRecommendationCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recommendationCacheKey);
  }

  Future<void> _syncTargetsToDashboard(
    DailyLogProvider logProvider,
    Map<String, dynamic>? userInfo,
  ) async {
    if (userInfo == null) return;

    final targetCal = (userInfo['target_kalori'] ?? 2000).toDouble();
    final targetPro = (userInfo['target_protein'] ?? 150).toDouble();

    // Gunakan target dari backend jika tersedia, fallback ke 55/45 split sisa
    final double remainingCal =
        (targetCal - (targetPro * 4)).clamp(0, targetCal);
    final targetCarbs =
        (userInfo['target_karbo'] ?? (remainingCal * 0.55 / 4)).toDouble();
    final targetFat =
        (userInfo['target_lemak'] ?? (remainingCal * 0.45 / 9)).toDouble();

    await logProvider.updateTargets(
      calories: targetCal,
      protein: targetPro,
      carbs: targetCarbs,
      fat: targetFat,
    );
  }

  // ========================================
  // TAB 2: CATEGORY BROWSING LOGIC
  // ========================================
  Future<void> _fetchCategoryFoods({bool isLoadMore = false}) async {
    // Increment generation counter to invalidate any in-flight fetches
    if (!isLoadMore) _categoryFetchId++;
    final myFetchId = _categoryFetchId;
    final myCategoryIndex = _selectedCategoryIndex;

    if (isLoadMore) {
      if (_isCategoryLoadingMore || !_hasMoreCategoryFoods) return;
      setState(() => _isCategoryLoadingMore = true);
    } else {
      setState(() {
        _isCategoryLoading = true;
        _categoryPage = 0;
        _categoryResults = [];
        _hasMoreCategoryFoods = true;
      });
    }

    final cat = _categories[myCategoryIndex];
    final List<String> queries = List<String>.from(cat['queries']);
    final List<dynamic> allNewResults = [];
    int totalRawCount = 0;

    try {
      final futures = queries.map((q) async {
        try {
          final url = Uri.parse(ApiConfig.searchUrl(q, _categoryPage, 10));
          final resp = await http.get(url, headers: {
            'ngrok-skip-browser-warning': 'true'
          }).timeout(const Duration(seconds: 15));
          if (resp.statusCode == 200) {
            final data = jsonDecode(resp.body);
            final results = data['results'] ?? [];
            return results;
          }
        } catch (e) {
          debugPrint('[RecommendationScreen] Error fetching query "$q": $e');
        }
        return [];
      });

      final results = await Future.wait(futures);

      // Check if this fetch is still relevant
      if (_categoryFetchId != myFetchId ||
          _selectedCategoryIndex != myCategoryIndex) {
        debugPrint(
            '[InfiniteScroll] Discarding stale fetch for category $myCategoryIndex (current: $_selectedCategoryIndex)');
        return;
      }

      for (final r in results) {
        totalRawCount += (r as List).length;
        allNewResults.addAll(r);
      }

      // Build seen set from existing results
      final seen = <String>{};
      final prefProvider =
          Provider.of<FoodPreferenceProvider>(context, listen: false);

      for (final item in _categoryResults) {
        seen.add((item['nama_makanan'] ?? '').toString().toLowerCase());
      }

      // Filter new results
      final newUnique = <dynamic>[];
      for (final item in allNewResults) {
        final name = (item['nama_makanan'] ?? '').toString();
        final nameLower = name.toLowerCase();
        final isCustomBlacklisted = prefProvider.isBlacklisted(name);
        if (!seen.contains(nameLower) &&
            name.isNotEmpty &&
            !_isBlacklisted(name) &&
            !isCustomBlacklisted) {
          seen.add(nameLower);
          newUnique.add(item);
        }
      }

      if (!mounted) return;
      // Double-check staleness after filtering
      if (_categoryFetchId != myFetchId) return;

      final bool hasMore = totalRawCount > 0;

      // If we got raw results but all were duplicates, auto-advance
      if (newUnique.isEmpty && hasMore) {
        _categoryPage++;
        setState(() {
          _isCategoryLoading = false;
          _isCategoryLoadingMore = false;
        });
        _fetchCategoryFoods(isLoadMore: true);
        return;
      }

      setState(() {
        if (isLoadMore) {
          _categoryResults = [..._categoryResults, ...newUnique];
        } else {
          _categoryResults = newUnique;
        }
        _isCategoryLoading = false;
        _isCategoryLoadingMore = false;
        _hasMoreCategoryFoods = hasMore;
        _categoryPage++;

        // Update cache for this category
        _categoryCacheResults[myCategoryIndex] = _categoryResults;
        _categoryCachePage[myCategoryIndex] = _categoryPage;
        _categoryCacheHasMore[myCategoryIndex] = _hasMoreCategoryFoods;
      });
    } catch (e) {
      debugPrint('[InfiniteScroll] ERROR: $e');
      if (!mounted || _categoryFetchId != myFetchId) return;
      setState(() {
        _isCategoryLoading = false;
        _isCategoryLoadingMore = false;
        if (!isLoadMore) _categoryResults = [];
      });
    }
  }

  /// Check if a food name contains any blacklisted keyword
  static bool _isBlacklisted(String foodName) {
    final lower = foodName.toLowerCase();
    for (final keyword in _blacklistKeywords) {
      if (lower.contains(keyword)) return true;
    }
    return false;
  }

  void _showAddToMealSheet(Map<String, dynamic> item) {
    final food = FoodItem.fromJson(item);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1E293B);
    final lang = Provider.of<LanguageProvider>(context, listen: false).locale;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Tambah \"${food.name}\"",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "${food.calories.toInt()} kkal • P: ${food.protein.toStringAsFixed(0)}g • K: ${food.carbs.toStringAsFixed(0)}g • L: ${food.fat.toStringAsFixed(0)}g",
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              _buildMealSlotOption(ctx, AppStrings.get('breakfast', lang),
                  Icons.wb_sunny_rounded, 'breakfast', food),
              _buildMealSlotOption(ctx, AppStrings.get('lunch', lang),
                  Icons.light_mode_rounded, 'lunch', food),
              _buildMealSlotOption(ctx, AppStrings.get('dinner', lang),
                  Icons.nightlight_round, 'dinner', food),
              _buildMealSlotOption(ctx, AppStrings.get('snacks', lang),
                  Icons.cookie_rounded, 'snacks', food),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMealSlotOption(BuildContext ctx, String label, IconData icon,
      String mealType, FoodItem food) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final lang = Provider.of<LanguageProvider>(ctx, listen: false).locale;
    return InkWell(
      onTap: () {
        Provider.of<DailyLogProvider>(ctx, listen: false)
            .addFood(mealType, food);
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "${food.name} ${AppStrings.get('added_to_meal_snack', lang)} $label ✅"),
          backgroundColor: Theme.of(context).primaryColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(ctx).primaryColor),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFFE0E0E0)
                      : const Color(0xFF1E293B),
                )),
            const Spacer(),
            Icon(Icons.add_rounded,
                size: 20, color: Theme.of(ctx).primaryColor),
          ],
        ),
      ),
    );
  }

  // ========================================
  // BUILD
  // ========================================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final lang = Provider.of<LanguageProvider>(context).locale;

    return Column(
      children: [
        // Tab Bar
        Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(12),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            padding: const EdgeInsets.all(4),
            tabs: [
              Tab(
                  text: AppStrings.get('tab_auto', lang),
                  icon: const Icon(Icons.auto_awesome, size: 20)),
              Tab(
                  text: AppStrings.get('tab_manual', lang),
                  icon: const Icon(Icons.touch_app_rounded, size: 20)),
            ],
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAutoTab(),
              _buildManualTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ========================================
  // TAB 1: OTOMATIS
  // ========================================
  Widget _buildAutoTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1E293B);
    final subColor = isDark ? Colors.grey[500] : Colors.grey[500];
    final primary = Theme.of(context).primaryColor;

    if (_isLoading) return _buildLoadingState(isDark);
    if (_hasData)
      return _buildResultState(isDark, titleColor, subColor, primary);
    if (_hasError)
      return _buildErrorState(isDark, titleColor, subColor, primary);
    return _buildEmptyState(isDark, titleColor, subColor, primary);
  }

  Widget _buildEmptyState(
      bool isDark, Color titleColor, Color? subColor, Color primary) {
    final lang = Provider.of<LanguageProvider>(context).locale;
    final profile = Provider.of<UserProfileProvider>(context).profile;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child:
                  Icon(Icons.restaurant_menu_rounded, size: 48, color: primary),
            ),
            const SizedBox(height: 24),
            Text(AppStrings.get('auto_recommendation', lang),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                )),
            const SizedBox(height: 8),
            Text(
              "${AppStrings.get('auto_desc_prefix', lang)}${_getGoalLabel(profile.goal)} ${lang == 'en' ? 'target!' : 'kamu!'}",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: subColor, height: 1.5),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildChip("${profile.berat.toInt()} kg",
                    Icons.monitor_weight_outlined, isDark),
                _buildChip("${profile.tinggi.toInt()} cm", Icons.height_rounded,
                    isDark),
                _buildChip(
                    _getGoalLabel(profile.goal), Icons.flag_rounded, isDark),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: TactileScaleEffect(
                enabled: !_isLoading,
                scaleDownTo: 0.96,
                child: ElevatedButton.icon(
                  onPressed: _fetchRecommendation,
                  icon: const Icon(Icons.auto_awesome, size: 20),
                  label: Text(AppStrings.get('get_recommendation', lang),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: primary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Consumer<FoodPreferenceProvider>(
              builder: (context, prefProvider, _) {
                final count = prefProvider.whitelistItems.length +
                    prefProvider.blacklistItems.length;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, a, b) => const FoodPreferencesScreen(),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(opacity: anim, child: child),
                        transitionDuration: const Duration(milliseconds: 250),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 16, color: primary),
                      const SizedBox(width: 6),
                      Text(
                        count > 0
                            ? "${AppStrings.get('manage_preferences_count', lang)} ($count)"
                            : AppStrings.get('manage_preferences', lang),
                        style: TextStyle(
                          fontSize: 13,
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    final lang = Provider.of<LanguageProvider>(context).locale;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, _) {
                final v = _shimmerController.value;
                final opacity =
                    0.3 + (0.4 * (0.5 + 0.5 * (1 - (2 * v - 1).abs())));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBlock(200, 22, opacity, isDark),
                    const SizedBox(height: 16),
                    _shimmerBlock(double.infinity, 100, opacity, isDark),
                    const SizedBox(height: 16),
                    _shimmerBlock(double.infinity, 140, opacity, isDark),
                    const SizedBox(height: 16),
                    _shimmerBlock(double.infinity, 140, opacity, isDark),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),
            Center(
                child: Text(
              AppStrings.get('loading_recommendation', lang),
              style: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey, fontSize: 14),
            )),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBlock(double w, double h, double opacity, bool isDark) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color:
            (isDark ? Colors.white : Colors.grey).withOpacity(opacity * 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _buildErrorState(
      bool isDark, Color titleColor, Color? subColor, Color primary) {
    final lang = Provider.of<LanguageProvider>(context).locale;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(AppStrings.get('failed_to_load', lang),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                )),
            const SizedBox(height: 8),
            Text(_errorMsg,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: subColor)),
            const SizedBox(height: 24),
            TactileScaleEffect(
              scaleDownTo: 0.95,
              child: ElevatedButton.icon(
                onPressed: _fetchRecommendation,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(AppStrings.get('retry', lang)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultState(
      bool isDark, Color titleColor, Color? subColor, Color primary) {
    final lang = Provider.of<LanguageProvider>(context).locale;
    final targetCal = (_userInfo?['target_kalori'] ?? 2000).toDouble();
    final targetPro = (_userInfo?['target_protein'] ?? 150).toDouble();
    final remainingCal = (targetCal - (targetPro * 4)).clamp(0.0, targetCal);
    final targetCarb = (remainingCal * 0.60) / 4;
    final targetFat = (remainingCal * 0.40) / 9;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.get('meal_plan', lang),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        )),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.get('long_press_hint', lang),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _fetchRecommendation,
                icon: Icon(Icons.refresh_rounded, color: primary),
                tooltip: AppStrings.get('reload', lang),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(AppStrings.get('algorithm_label', lang),
              style: TextStyle(
                  fontSize: 12,
                  color: primary.withOpacity(0.85),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          // Target Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF047857), const Color(0xFF065F46)]
                    : [const Color(0xFF10B981), const Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(isDark ? 0.15 : 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.get('daily_nutrition_target', lang),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                "${targetCal.toInt()}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppStrings.get('kkal', lang),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.restaurant_rounded,
                              color: Colors.white, size: 22),
                          const SizedBox(height: 4),
                          Text(
                            "${_menu.length} ${AppStrings.get('meals_count', lang)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Segmented Macro Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 6,
                    width: double.infinity,
                    child: Row(
                      children: [
                        Expanded(
                          flex: ((targetPro * 4) / targetCal * 100)
                              .round()
                              .clamp(1, 100),
                          child: Container(color: Colors.blue[300]),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          flex: ((targetCarb * 4) / targetCal * 100)
                              .round()
                              .clamp(1, 100),
                          child: Container(color: Colors.cyan[300]),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          flex: ((targetFat * 9) / targetCal * 100)
                              .round()
                              .clamp(1, 100),
                          child: Container(color: Colors.amber[300]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Macro values label row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMacroIndicatorInsideCard(
                        "P", "${targetPro.toInt()}g", Colors.blue[300]!),
                    _buildMacroIndicatorInsideCard(
                        "K", "${targetCarb.toInt()}g", Colors.cyan[300]!),
                    _buildMacroIndicatorInsideCard(
                        "L", "${targetFat.toInt()}g", Colors.amber[300]!),
                  ],
                ),
              ],
            ),
          ),

          // Constraint-Based Filtering status banner
          if (_hasilGenerasi != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TactileScaleEffect(
                scaleDownTo: 0.98,
                child: GestureDetector(
                  onTap: _showAlgorithmDetailsSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF132A24)
                          : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF10B981).withOpacity(0.3)
                            : const Color(0xFF10B981).withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        const _PulsingDot(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    AppStrings.get(
                                        'constraint_filter_active', lang),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: titleColor,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981)
                                          .withOpacity(isDark ? 0.2 : 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      AppStrings.get('active_label', lang),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppStrings.get(
                                    'constraint_filter_success', lang),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_right_rounded,
                          size: 20,
                          color: primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Add All Button
          if (_addedMeals.length < _menu.length)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: TactileScaleEffect(
                  scaleDownTo: 0.96,
                  child: OutlinedButton.icon(
                    onPressed: _addAllToLog,
                    icon:
                        Icon(Icons.playlist_add_check_rounded, color: primary),
                    label: Text(AppStrings.get('add_all_to_log', lang),
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: primary)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ),

          // Meal Cards
          ..._menu.map(
              (m) => _buildMealCard(m, isDark, titleColor, subColor, primary)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMacroIndicatorInsideCard(
      String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          "$label: ",
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showAlgorithmDetailsSheet() {
    if (_hasilGenerasi == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1E293B);
    final primary = Theme.of(context).primaryColor;
    final lang = Provider.of<LanguageProvider>(context).locale;

    final rawAlg = _hasilGenerasi!['algorithm']?.toString() ?? '';
    final algorithm = rawAlg.isEmpty ? 'Constraint-Based Filtering' : rawAlg;
    final candidateCount = _hasilGenerasi!['candidate_count'] ?? 0;
    final rulesApplied = _hasilGenerasi!['rules_applied'] ?? 0;

    final targets =
        Map<String, dynamic>.from(_hasilGenerasi!['target_macros'] ?? {});
    final achieved =
        Map<String, dynamic>.from(_hasilGenerasi!['achieved_macros'] ?? {});
    final accuracy =
        Map<String, dynamic>.from(_hasilGenerasi!['accuracy_pct'] ?? {});

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.auto_awesome_rounded,
                        color: primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get('filtering_stats', lang),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        Text(
                          AppStrings.get('filtered_instantly', lang),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Algoritma Meta Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isDark ? Colors.white.withOpacity(0.03) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey[200]!,
                  ),
                ),
                child: Column(
                  children: [
                    _buildMetaRow(AppStrings.get('main_algorithm', lang),
                        algorithm, isDark, titleColor),
                    const Divider(height: 20, color: Colors.white10),
                    _buildMetaRow(
                        AppStrings.get('candidate_count', lang),
                        "$candidateCount ${AppStrings.get('items', lang)}",
                        isDark,
                        titleColor),
                    const Divider(height: 20, color: Colors.white10),
                    _buildMetaRow(
                        AppStrings.get('rules_applied', lang),
                        "$rulesApplied ${AppStrings.get('rules', lang)}",
                        isDark,
                        titleColor),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                AppStrings.get('macro_accuracy', lang),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 12),

              // Macro accuracy list
              _buildMacroAccuracyProgress(
                AppStrings.get('calories_label', lang),
                "${(achieved['kalori'] ?? 0).toInt()} / ${(targets['kalori'] ?? 0).toInt()} ${AppStrings.get('kkal', lang)}",
                (accuracy['kalori'] ?? 0.0).toDouble(),
                const Color(0xFF10B981),
                isDark,
              ),
              const SizedBox(height: 12),
              _buildMacroAccuracyProgress(
                "Protein",
                "${(achieved['protein'] ?? 0).toInt()}g / ${(targets['protein'] ?? 0).toInt()}g",
                (accuracy['protein'] ?? 0.0).toDouble(),
                const Color(0xFF3B82F6),
                isDark,
              ),
              const SizedBox(height: 12),
              _buildMacroAccuracyProgress(
                AppStrings.get('carbs_label', lang),
                "${(achieved['karbo'] ?? 0).toInt()}g / ${(targets['karbo'] ?? 0).toInt()}g",
                (accuracy['karbo'] ?? 0.0).toDouble(),
                const Color(0xFF06B6D4),
                isDark,
              ),
              const SizedBox(height: 12),
              _buildMacroAccuracyProgress(
                AppStrings.get('fat_label', lang),
                "${(achieved['lemak'] ?? 0).toInt()}g / ${(targets['lemak'] ?? 0).toInt()}g",
                (accuracy['lemak'] ?? 0.0).toDouble(),
                const Color(0xFFF59E0B),
                isDark,
              ),
              const SizedBox(height: 20),

              // Edu Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: const Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.get('algorithm_edu', lang),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFF065F46),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetaRow(
      String label, String value, bool isDark, Color titleColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroAccuracyProgress(
      String label, String detail, double pct, Color color, bool isDark) {
    final progress = (pct / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
            Text(
              "$detail (${pct.toStringAsFixed(1)}%)",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(Map<String, dynamic> data, bool isDark,
      Color titleColor, Color? subColor, Color primary) {
    final List items = data['isi'] ?? [];
    final String waktu = data['waktu'] ?? '';
    final lang = Provider.of<LanguageProvider>(context).locale;
    final mealType = _mapWaktuToMealType(waktu);
    final localizedWaktu = AppStrings.get(mealType, lang);
    double totalKalori =
        items.fold(0.0, (sum, item) => sum + (item['kalori'] ?? 0));
    double totalProtein =
        items.fold(0.0, (sum, item) => sum + (item['protein'] ?? 0));
    double totalCarbs =
        items.fold(0.0, (sum, item) => sum + (item['karbo'] ?? 0));
    double totalFat =
        items.fold(0.0, (sum, item) => sum + (item['lemak'] ?? 0));
    final bool isAdded = _addedMeals.contains(waktu);

    IconData mealIcon;
    final lower = waktu.toLowerCase();
    if (lower.contains('sarapan') || lower.contains('pagi')) {
      mealIcon = Icons.wb_sunny_rounded;
    } else if (lower.contains('siang')) {
      mealIcon = Icons.light_mode_rounded;
    } else if (lower.contains('malam')) {
      mealIcon = Icons.nightlight_round;
    } else {
      mealIcon = Icons.cookie_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(mealIcon, size: 20, color: primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            localizedWaktu,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome,
                                    size: 10, color: Colors.amber),
                                SizedBox(width: 3),
                                Text(
                                  "AI Pick",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withOpacity(isDark ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF10B981).withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              "${totalKalori.toInt()} ${AppStrings.get('kkal', lang)}",
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "P: ${totalProtein.toInt()}g  •  K: ${totalCarbs.toInt()}g  •  L: ${totalFat.toInt()}g",
                        style: TextStyle(
                          fontSize: 11,
                          color: subColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                isAdded
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded,
                                size: 14, color: const Color(0xFF10B981)),
                            SizedBox(width: 4),
                            Text(
                              AppStrings.get('added_label', lang),
                              style: TextStyle(
                                fontSize: 11,
                                color: const Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : TactileScaleEffect(
                        scaleDownTo: 0.94,
                        child: SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: () => _addMealToLog(data),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              AppStrings.get('log_btn', lang),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey[200]),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Consumer<FoodPreferenceProvider>(
              builder: (context, prefProvider, _) {
                return Column(
                  children: items.map<Widget>((item) {
                    final name = item['nama_makanan'] ?? '';
                    final isWhitelisted = prefProvider.isWhitelisted(name);
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPress: () {
                        HapticFeedback.mediumImpact();
                        _showPreferenceSheet(name);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Left accent bar (gradient, like dashboard)
                              Container(
                                width: 3.5,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [primary, primary.withOpacity(0.2)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _getFoodCategoryIcon(name, primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: titleColor,
                                            ),
                                          ),
                                        ),
                                        if (isWhitelisted) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981)
                                                  .withOpacity(
                                                      isDark ? 0.2 : 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.favorite_rounded,
                                                    size: 9,
                                                    color: Color(0xFF10B981)),
                                                SizedBox(width: 2),
                                                Text(
                                                  AppStrings.get(
                                                      'favorite', lang),
                                                  style: TextStyle(
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF10B981),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      "P: ${_fmt(item['protein'])}g • K: ${_fmt(item['karbo'])}g • L: ${_fmt(item['lemak'])}g",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Calorie column
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${(item['kalori'] ?? 0).toInt()}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: titleColor,
                                    ),
                                  ),
                                  Text(
                                    AppStrings.get('kkal', lang),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  Icons.more_vert_rounded,
                                  size: 20,
                                  color: isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[400],
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  _showPreferenceSheet(name);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPreferenceSheet(String foodName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final titleColor =
        isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1E293B);
    final lang = Provider.of<LanguageProvider>(context).locale;
    final prefProvider =
        Provider.of<FoodPreferenceProvider>(context, listen: false);
    final isWhitelisted = prefProvider.isWhitelisted(foodName);
    final isBlacklisted = prefProvider.isBlacklisted(foodName);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                foodName,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.get('set_preference_hint', lang),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              // Whitelist option
              _buildPreferenceOption(
                ctx: ctx,
                icon: Icons.thumb_up_rounded,
                title: AppStrings.get('show_more_often', lang),
                subtitle: AppStrings.get('algorithm_will_prioritize', lang),
                color: const Color(0xFF10B981),
                isActive: isWhitelisted,
                isDark: isDark,
                titleColor: titleColor,
                onTap: () {
                  Navigator.pop(ctx);
                  if (isWhitelisted) {
                    prefProvider.removePreference(foodName);
                    _showPrefSnack(
                        "\"$foodName\" ${AppStrings.get('removed_from_priority', lang)}",
                        primary);
                  } else {
                    prefProvider.addPreference(foodName, 'whitelist');
                    _showPrefSnack(
                        "\"$foodName\" ${AppStrings.get('prioritized', lang)}",
                        const Color(0xFF10B981));
                  }
                  setState(() {});
                  Future.delayed(const Duration(milliseconds: 350), () {
                    if (mounted) {
                      if (_tabController.index == 0) {
                        _fetchRecommendation();
                      } else {
                        _fetchCategoryFoods();
                      }
                    }
                  });
                },
              ),
              const SizedBox(height: 8),
              // Blacklist option
              _buildPreferenceOption(
                ctx: ctx,
                icon: Icons.block_rounded,
                title: AppStrings.get('dont_show_again', lang),
                subtitle: AppStrings.get('food_wont_appear', lang),
                color: Colors.red[400]!,
                isActive: isBlacklisted,
                isDark: isDark,
                titleColor: titleColor,
                onTap: () {
                  Navigator.pop(ctx);
                  if (isBlacklisted) {
                    prefProvider.removePreference(foodName);
                    _showPrefSnack(
                        "\"$foodName\" ${AppStrings.get('removed_from_avoid', lang)}",
                        primary);
                  } else {
                    prefProvider.addPreference(foodName, 'blacklist');
                    _showPrefSnack(
                        "\"$foodName\" ${AppStrings.get('wont_be_shown', lang)}",
                        Colors.red[400]!);
                  }
                  setState(() {});
                  Future.delayed(const Duration(milliseconds: 350), () {
                    if (mounted) {
                      if (_tabController.index == 0) {
                        _fetchRecommendation();
                      } else {
                        _fetchCategoryFoods();
                      }
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreferenceOption({
    required BuildContext ctx,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isActive,
    required bool isDark,
    required Color titleColor,
    required VoidCallback onTap,
  }) {
    final lang = Provider.of<LanguageProvider>(ctx, listen: false).locale;
    return TactileScaleEffect(
      scaleDownTo: 0.97,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isActive
                ? color.withOpacity(isDark ? 0.15 : 0.08)
                : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50]),
            borderRadius: BorderRadius.circular(14),
            border: isActive
                ? Border.all(color: color.withOpacity(0.4), width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(isActive ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppStrings.get('active_label', lang),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrefSnack(String message, Color color) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _getFoodCategoryIcon(String foodName, Color primary) {
    final lower = foodName.toLowerCase();
    IconData icon;
    Color color;

    if (lower.contains('nasi') ||
        lower.contains('roti') ||
        lower.contains('oat') ||
        lower.contains('kentang') ||
        lower.contains('ubi') ||
        lower.contains('singkong') ||
        lower.contains('jagung') ||
        lower.contains('lontong') ||
        lower.contains('ketupat') ||
        lower.contains('havermout') ||
        lower.contains('talas')) {
      icon = Icons.rice_bowl_rounded;
      color = const Color(0xFF06B6D4); // Cyan for Carbs
    } else if (lower.contains('ayam') ||
        lower.contains('telur') ||
        lower.contains('daging') ||
        lower.contains('sapi') ||
        lower.contains('ikan') ||
        lower.contains('salmon') ||
        lower.contains('tuna') ||
        lower.contains('tongkol') ||
        lower.contains('kembung') ||
        lower.contains('mujair') ||
        lower.contains('nila') ||
        lower.contains('gurame') ||
        lower.contains('patin') ||
        lower.contains('bandeng') ||
        lower.contains('bawal') ||
        lower.contains('udang') ||
        lower.contains('cumi') ||
        lower.contains('kerang')) {
      icon = Icons.egg_alt_rounded;
      color = const Color(0xFF3B82F6); // Blue for Protein
    } else if (lower.contains('tempe') ||
        lower.contains('tahu') ||
        lower.contains('edamame') ||
        lower.contains('oncom') ||
        lower.contains('kedelai') ||
        lower.contains('kacang')) {
      icon = Icons.grass_rounded;
      color = const Color(0xFF10B981); // Emerald for Nabati
    } else if (lower.contains('bayam') ||
        lower.contains('kangkung') ||
        lower.contains('brokoli') ||
        lower.contains('buncis') ||
        lower.contains('wortel') ||
        lower.contains('sawi') ||
        lower.contains('selada') ||
        lower.contains('toge') ||
        lower.contains('pare') ||
        lower.contains('timun') ||
        lower.contains('terong') ||
        lower.contains('sop') ||
        lower.contains('capcay') ||
        lower.contains('sayur') ||
        lower.contains('asem') ||
        lower.contains('gado') ||
        lower.contains('karedok') ||
        lower.contains('tumis')) {
      icon = Icons.eco_rounded;
      color = const Color(0xFF10B981); // Green for Sayur
    } else if (lower.contains('apel') ||
        lower.contains('pisang') ||
        lower.contains('jeruk') ||
        lower.contains('pepaya') ||
        lower.contains('semangka') ||
        lower.contains('melon') ||
        lower.contains('mangga') ||
        lower.contains('alpukat') ||
        lower.contains('salak') ||
        lower.contains('rambutan') ||
        lower.contains('anggur') ||
        lower.contains('duku') ||
        lower.contains('nanas') ||
        lower.contains('pir') ||
        lower.contains('buah')) {
      icon = Icons.apple_rounded;
      color = const Color(0xFFF59E0B); // Amber for Fruit
    } else {
      icon = Icons.restaurant_menu_rounded;
      color = primary;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  // ========================================
  // TAB 2: PILIH SENDIRI
  // ========================================
  Widget _buildManualTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final titleColor =
        isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1E293B);
    final lang = Provider.of<LanguageProvider>(context, listen: false).locale;

    return Column(
      children: [
        // Calorie Progress Bar
        Consumer<DailyLogProvider>(
          builder: (context, logProvider, _) {
            final log = logProvider.todayLog;
            final consumed = log.totalCalories;
            final target = log.targetCalories;
            final remaining = (target - consumed).clamp(0, target);
            final progress =
                target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

            return Container(
              margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.get('remaining_calories_today', lang),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          )),
                      Text("${remaining.toInt()} / ${target.toInt()} kkal",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        consumed > target ? Colors.red[400]! : primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("P: ${log.totalProtein.toInt()}g",
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[500] : Colors.grey)),
                      Text("K: ${log.totalCarbs.toInt()}g",
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[500] : Colors.grey)),
                      Text("L: ${log.totalFat.toInt()}g",
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[500] : Colors.grey)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),

        // Category Chips
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = index == _selectedCategoryIndex;
              return GestureDetector(
                onTap: () {
                  if (index == _selectedCategoryIndex) return;
                  // Save current category state to cache
                  _categoryCacheResults[_selectedCategoryIndex] =
                      _categoryResults;
                  _categoryCachePage[_selectedCategoryIndex] = _categoryPage;
                  _categoryCacheHasMore[_selectedCategoryIndex] =
                      _hasMoreCategoryFoods;

                  setState(() => _selectedCategoryIndex = index);

                  // Restore from cache if available, otherwise fetch
                  if (_categoryCacheResults.containsKey(index)) {
                    setState(() {
                      _categoryResults = _categoryCacheResults[index]!;
                      _categoryPage = _categoryCachePage[index] ?? 0;
                      _hasMoreCategoryFoods =
                          _categoryCacheHasMore[index] ?? true;
                      _isCategoryLoading = false;
                    });
                  } else {
                    _fetchCategoryFoods();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primary
                        : (isDark ? Colors.transparent : Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: isDark ? Colors.white24 : Colors.grey[300]!),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: primary.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat['icon'],
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.grey[400] : Colors.grey[700])),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.get(cat['label'], lang),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.grey[400] : Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Food List
        Expanded(
          child: _isCategoryLoading
              ? Center(
                  child: CircularProgressIndicator(
                      color: primary, strokeWidth: 2.5))
              : _categoryResults.isEmpty
                  ? Center(
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 48,
                            color:
                                isDark ? Colors.grey[600] : Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(AppStrings.get('no_food_found', lang),
                            style: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey,
                              fontSize: 14,
                            )),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _fetchCategoryFoods,
                          child: Text(AppStrings.get('retry', lang),
                              style: TextStyle(color: primary)),
                        ),
                      ],
                    ))
                  : NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollEndNotification ||
                            notification is ScrollUpdateNotification) {
                          final metrics = notification.metrics;
                          if (metrics.pixels >= metrics.maxScrollExtent - 200) {
                            if (!_isCategoryLoading &&
                                !_isCategoryLoadingMore &&
                                _hasMoreCategoryFoods) {
                              debugPrint(
                                  '[InfiniteScroll] Triggered loadMore from NotificationListener');
                              _fetchCategoryFoods(isLoadMore: true);
                            }
                          }
                        }
                        return false;
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: _categoryResults.length +
                            (_isCategoryLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _categoryResults.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: primary, strokeWidth: 2.5)),
                            );
                          }
                          final item = Map<String, dynamic>.from(
                              _categoryResults[index]);
                          return _buildFoodTile(
                              item, isDark, titleColor, primary);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFoodTile(
      Map<String, dynamic> item, bool isDark, Color titleColor, Color primary) {
    final name = item['nama_makanan'] ?? '';
    final cal = (item['kalori'] ?? 0).toDouble();
    final pro = (item['protein'] ?? 0).toDouble();
    final carb = (item['karbo'] ?? 0).toDouble();
    final fat = (item['lemak'] ?? 0).toDouble();
    final lang = Provider.of<LanguageProvider>(context, listen: false).locale;

    // Calculate remaining for smart badge
    final logParams =
        Provider.of<DailyLogProvider>(context, listen: false).todayLog;
    final remainingCal = (logParams.targetCalories - logParams.totalCalories)
        .clamp(0, logParams.targetCalories);

    // AI Badge logic
    IconData badgeIcon = Icons.balance;
    String badgeText = AppStrings.get('badge_balanced_label', lang);
    Color badgeColor = const Color(0xFFF59E0B);

    if (pro >= 15 && fat <= 5) {
      badgeIcon = Icons.star_rounded;
      badgeText = AppStrings.get('badge_high_protein_good_label', lang);
      badgeColor = const Color(0xFF8B5CF6);
    } else if (pro >= 10) {
      badgeIcon = Icons.fitness_center;
      badgeText = AppStrings.get('badge_rich_protein_label', lang);
      badgeColor = const Color(0xFF3B82F6);
    } else if (cal > 0 && cal <= remainingCal * 0.4 && cal >= 50) {
      badgeIcon = Icons.track_changes_rounded;
      badgeText = AppStrings.get('badge_fits_remaining_label', lang);
      badgeColor = primary;
    } else if (fat <= 3 && cal < 200) {
      badgeIcon = Icons.eco_rounded;
      badgeText = AppStrings.get('badge_low_fat_label', lang);
      badgeColor = const Color(0xFF10B981);
    }

    return Consumer<FoodPreferenceProvider>(
      builder: (context, prefProvider, child) {
        final isWhitelisted = prefProvider.isWhitelisted(name);
        return GestureDetector(
          onTap: () => _showAddToMealSheet(item),
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _showPreferenceSheet(name);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Gradient accent bar (like dashboard)
                  Container(
                    width: 3.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary, primary.withOpacity(0.15)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Food info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: titleColor,
                                  )),
                            ),
                            if (isWhitelisted) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981)
                                      .withOpacity(isDark ? 0.2 : 0.12),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.favorite_rounded,
                                        size: 9, color: Color(0xFF10B981)),
                                    SizedBox(width: 2),
                                    Text(
                                      AppStrings.get('favorite', lang),
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                              color: badgeColor.withOpacity(isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(badgeIcon,
                                  size: 12,
                                  color: isDark
                                      ? Colors.white
                                      : Color.lerp(
                                          badgeColor, Colors.black, 0.3)!),
                              const SizedBox(width: 4),
                              Text(badgeText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : Color.lerp(
                                            badgeColor, Colors.black, 0.3)!,
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(children: [
                          _buildMacroChip("P", "${_fmt(pro)}g",
                              const Color(0xFF3B82F6), isDark),
                          const SizedBox(width: 6),
                          _buildMacroChip("K", "${_fmt(carb)}g",
                              const Color(0xFF10B981), isDark),
                          const SizedBox(width: 6),
                          _buildMacroChip("L", "${_fmt(fat)}g",
                              const Color(0xFFF59E0B), isDark),
                        ]),
                      ],
                    ),
                  ),
                  // Calories + add hint
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("${cal is double ? cal.toInt() : cal}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          )),
                      Text(AppStrings.get('kkal', lang),
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[500] : Colors.grey)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showPreferenceSheet(name);
                    },
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.add_circle_rounded, color: primary, size: 28),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMacroChip(String label, String value, Color color, bool isDark) {
    final textColor = isDark
        ? Color.lerp(color, Colors.white, 0.4)!
        : Color.lerp(color, Colors.black, 0.35)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        "$label: $value",
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }

  // ========================================
  // HELPERS
  // ========================================
  Widget _buildChip(String label, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon,
            size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            )),
      ]),
    );
  }

  String _getGoalLabel(String goal) {
    switch (goal) {
      case 'cutting':
        return 'Cutting';
      case 'maintain':
        return 'Maintain';
      case 'bulking':
        return 'Bulking';
      default:
        return goal;
    }
  }

  String _fmt(dynamic val) {
    if (val == null) return '0';
    if (val is int) return val.toString();
    if (val is double) return val.toStringAsFixed(1);
    return val.toString();
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF10B981)
                .withOpacity(0.2 + 0.8 * _pulseController.value),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981)
                    .withOpacity(0.4 * _pulseController.value),
                blurRadius: 6,
                spreadRadius: 2,
              )
            ],
          ),
        );
      },
    );
  }
}
