import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fit_meal/config/api_config.dart';
import 'package:fit_meal/config/app_strings.dart';
import 'package:fit_meal/models/food_item.dart';
import 'package:fit_meal/providers/daily_log_provider.dart';
import 'package:fit_meal/providers/language_provider.dart';
import 'package:fit_meal/widgets/food_card.dart';
import 'package:fit_meal/widgets/tactile_scale_effect.dart';


class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List _results = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  List<String> _history = [];
  bool _isSearching = false;

  // Track which item is currently being added (for loading spinner & double-tap prevention)
  int? _addingItemIndex;

  int _page = 0;
  bool _hasNext = false;
  final int _limit = 15;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(() {
      setState(() {
        _isSearching = _searchController.text.isNotEmpty;
      });
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasNext) {
      _loadMore();
    }
  }

  // --- History Logic ---
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _addToHistory(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (_history.contains(query)) _history.remove(query);
    _history.insert(0, query);
    if (_history.length > 10) _history.removeLast();
    await prefs.setStringList('search_history', _history);
    _loadHistory();
  }

  Future<void> _removeFromHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history.remove(query);
    });
    await prefs.setStringList('search_history', _history);
  }

  /// Initial search — clears old results and loads from page 0
  Future<void> cariMakanan() async {
    final keyword = _searchController.text;
    if (keyword.isEmpty) return;

    _addToHistory(keyword);

    setState(() {
      _isLoading = true;
      _results = [];
      _page = 0;
      _hasNext = false;
    });

    try {
      final url = Uri.parse(ApiConfig.searchUrl(keyword, 0, _limit));
      final response = await http.get(url,
          headers: {'ngrok-skip-browser-warning': 'true'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List newItems = data['results'] ?? [];
        final bool serverHasNext = data['has_next'] ?? false;

        setState(() {
          _results = newItems;
          _hasNext = serverHasNext;
          _page = 0;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Load more results — appends to existing list
  Future<void> _loadMore() async {
    final keyword = _searchController.text;
    if (keyword.isEmpty || !_hasNext) return;

    setState(() => _isLoadingMore = true);

    final nextPage = _page + 1;

    try {
      final url = Uri.parse(ApiConfig.searchUrl(keyword, nextPage, _limit));
      final response = await http.get(url,
          headers: {'ngrok-skip-browser-warning': 'true'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List newItems = data['results'] ?? [];
        final bool serverHasNext = data['has_next'] ?? false;

        setState(() {
          _results.addAll(newItems);
          _hasNext = serverHasNext;
          _page = nextPage;
        });
      }
    } catch (e) {
      debugPrint("Error loading more: $e");
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  /// Show bottom sheet to pick meal type, then add the food
  /// Includes loading state, error handling, and double-tap prevention.
  Future<void> _showAddToMealSheet(Map item, int index) async {
    // Double-tap prevention: if already processing an item, ignore
    if (_addingItemIndex != null) return;

    setState(() => _addingItemIndex = index);
    final lang = Provider.of<LanguageProvider>(context, listen: false).locale;

    try {
      final food = FoodItem.fromJson(item.cast<String, dynamic>());
      final isDark = Theme.of(context).brightness == Brightness.dark;

      // Small delay to show loading state before opening sheet
      await Future.delayed(const Duration(milliseconds: 200));

      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
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
                  "${AppStrings.get('add_food_title', lang)} \"${food.name}\"",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFE0E0E0)
                        : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${food.calories.toInt()} ${AppStrings.get('kkal', lang)} • P: ${food.protein.toStringAsFixed(0)}g • K: ${food.carbs.toStringAsFixed(0)}g • L: ${food.fat.toStringAsFixed(0)}g",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                _buildMealOption(ctx, AppStrings.get('breakfast', lang), Icons.wb_sunny_rounded,
                    'breakfast', food, lang),
                _buildMealOption(ctx, AppStrings.get('lunch', lang),
                    Icons.light_mode_rounded, 'lunch', food, lang),
                _buildMealOption(ctx, AppStrings.get('dinner', lang),
                    Icons.nightlight_round, 'dinner', food, lang),
                _buildMealOption(ctx, AppStrings.get('snacks', lang), Icons.cookie_rounded,
                    'snacks', food, lang),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      );
    } catch (e) {
      // Error handling: show snackbar on failure
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get('add_failed', lang)),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: AppStrings.get('retry', lang),
              textColor: Colors.white,
              onPressed: () => _showAddToMealSheet(item, index),
            ),
          ),
        );
      }
    } finally {
      // Always reset loading state
      if (mounted) {
        setState(() => _addingItemIndex = null);
      }
    }
  }

  Widget _buildMealOption(BuildContext ctx, String label, IconData icon,
      String mealType, FoodItem food, String lang) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        final logProvider =
            Provider.of<DailyLogProvider>(ctx, listen: false);
        logProvider.addFood(mealType, food);
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${food.name} ${AppStrings.get('added_to_meal', lang)} $label"),
            backgroundColor: Theme.of(context).primaryColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
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
            Icon(icon,
                size: 20,
                color: Theme.of(ctx).primaryColor),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? const Color(0xFFE0E0E0)
                    : const Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            Icon(Icons.add_rounded,
                size: 20,
                color: Theme.of(ctx).primaryColor),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1E293B);
    final hintColor = isDark ? Colors.grey[600] : Colors.grey[400];
    final lang = Provider.of<LanguageProvider>(context).locale;

    return Scaffold(
      body: Column(
        children: [
          // 1. INPUT SEARCH
          Container(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color:
                          Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2))
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(fontSize: 16, color: textColor),
                decoration: InputDecoration(
                  hintText: AppStrings.get('search_hint', lang),
                  hintStyle: TextStyle(color: hintColor),
                  prefixIcon: Icon(Icons.search, color: hintColor),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon:
                              const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _results = [];
                              _isSearching = false;
                            });
                          })
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 15),
                ),
                onSubmitted: (_) => cariMakanan(),
              ),
            ),
          ),

          // 2. LIST CONTENT
          Expanded(
            child: !_isSearching
                ? (_history.isEmpty
                    ? Center(
                        child: Text(AppStrings.get('no_search_history', lang),
                            style: TextStyle(
                                color: hintColor, fontSize: 14)))
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final item = _history[index];
                          return ListTile(
                            leading: Icon(Icons.history,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey),
                            title: Text(item,
                                style: TextStyle(color: textColor)),
                            trailing: IconButton(
                              icon: const Icon(Icons.close,
                                  size: 18, color: Colors.grey),
                              onPressed: () =>
                                  _removeFromHistory(item),
                            ),
                            onTap: () {
                              _searchController.text = item;
                              setState(() => _isSearching = true);
                              cariMakanan();
                            },
                          );
                        },
                      ))
                : (_isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (_results.isEmpty
                        ? Center(
                            child: Text(AppStrings.get('food_not_found', lang),
                                style: TextStyle(
                                    color: hintColor, fontSize: 14)))
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20),
                            // +1 for the loading indicator at the bottom
                            itemCount:
                                _results.length + (_hasNext || _isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Loading indicator at the bottom
                              if (index == _results.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 24),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color:
                                            Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final item = _results[index];
                              final isAdding = _addingItemIndex == index;
                              return FoodCard.fromMap(
                                item,
                                trailing: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981)
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "${(item['kalori'] ?? 0).toInt()}",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                          ),
                                          Text(
                                            AppStrings.get('kkal', lang),
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: isDark
                                                  ? Colors.grey[400]
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // "+ Tambah" button with loading state and tap handler
                                    TactileScaleEffect(
                                      enabled: !isAdding,
                                      scaleDownTo: 0.90,
                                      child: GestureDetector(
                                        onTap: () => _showAddToMealSheet(item, index),
                                        behavior: HitTestBehavior.opaque,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: 60,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: isAdding
                                                ? Theme.of(context)
                                                    .primaryColor
                                                    .withOpacity(0.25)
                                                : Theme.of(context)
                                                    .primaryColor
                                                    .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: isAdding
                                              ? Center(
                                                  child: SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                    ),
                                                  ),
                                                )
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.add_rounded,
                                                      size: 14,
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                    ),
                                                    Text(
                                                      AppStrings.get('add', lang),
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w600,
                                                        color: Theme.of(context)
                                                            .primaryColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ))),
          ),
        ],
      ),
    );
  }
}
