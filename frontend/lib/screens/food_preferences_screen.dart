import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fit_meal/providers/food_preference_provider.dart';
import 'package:fit_meal/providers/language_provider.dart';
import 'package:fit_meal/config/app_strings.dart';
import 'package:fit_meal/models/food_preference.dart';
import 'package:fit_meal/widgets/tactile_scale_effect.dart';

class FoodPreferencesScreen extends StatefulWidget {
  const FoodPreferencesScreen({super.key});
  @override
  State<FoodPreferencesScreen> createState() => _FoodPreferencesScreenState();
}

class _FoodPreferencesScreenState extends State<FoodPreferencesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddSheet(String defaultType) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final titleColor = isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1E293B);
    final lang = Provider.of<LanguageProvider>(context).locale;
    final addController = TextEditingController();
    String selectedType = defaultType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
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
                        width: 40, height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppStrings.get('add_food_preference', lang),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.get('add_food_pref_desc', lang),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Food name input
                    TextField(
                      controller: addController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(
                        fontSize: 15,
                        color: titleColor,
                      ),
                      decoration: InputDecoration(
                        hintText: AppStrings.get('food_name_hint', lang),
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        prefixIcon: Icon(
                          Icons.restaurant_rounded,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Type toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setSheetState(() => selectedType = 'whitelist'),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedType == 'whitelist'
                                      ? const Color(0xFF10B981)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.thumb_up_rounded,
                                      size: 16,
                                      color: selectedType == 'whitelist'
                                          ? Colors.white
                                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      AppStrings.get('prioritize', lang),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: selectedType == 'whitelist'
                                            ? Colors.white
                                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setSheetState(() => selectedType = 'blacklist'),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedType == 'blacklist'
                                      ? Colors.red[400]
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.block_rounded,
                                      size: 16,
                                      color: selectedType == 'blacklist'
                                          ? Colors.white
                                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      AppStrings.get('avoid', lang),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: selectedType == 'blacklist'
                                            ? Colors.white
                                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Add button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TactileScaleEffect(
                        scaleDownTo: 0.96,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final name = addController.text.trim();
                            if (name.isEmpty) return;
                            Provider.of<FoodPreferenceProvider>(context, listen: false)
                                .addPreference(name, selectedType);
                            Navigator.pop(ctx);
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  selectedType == 'whitelist'
                                      ? "\"$name\" ${AppStrings.get('added_to_priority', lang)}"
                                      : "\"$name\" ${AppStrings.get('added_to_avoid', lang)}",
                                ),
                                backgroundColor: selectedType == 'whitelist'
                                    ? primary
                                    : Colors.red[400],
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: Text(
                            AppStrings.get('add_button', lang),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedType == 'whitelist' ? primary : Colors.red[400],
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showClearDialog() {
    final lang = Provider.of<LanguageProvider>(context).locale;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppStrings.get('reset_all_preferences', lang)),
        content: Text(
          AppStrings.get('reset_pref_content', lang),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.get('cancel', lang)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<FoodPreferenceProvider>(context, listen: false).clearAll();
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.get('all_preferences_reset', lang)),
                  backgroundColor: Theme.of(context).primaryColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              "Reset",
              style: TextStyle(color: Colors.red[400], fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final titleColor = isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1E293B);
    final subColor = isDark ? Colors.grey[500] : Colors.grey[500];
    final lang = Provider.of<LanguageProvider>(context).locale;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.get('food_preferences_title', lang)),
            centerTitle: true,
          ),
          body: Consumer<FoodPreferenceProvider>(
            builder: (context, prefProvider, _) {
              final whitelist = prefProvider.whitelistItems;
              final blacklist = prefProvider.blacklistItems;
              final hasAny = whitelist.isNotEmpty || blacklist.isNotEmpty;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF132A24), const Color(0xFF1A2E38)]
                              : [const Color(0xFFF0FDF4), const Color(0xFFECFDF5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primary.withOpacity(isDark ? 0.2 : 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.tune_rounded, color: primary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.get('customize_recommendation', lang),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  AppStrings.get('customize_rec_desc', lang),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Whitelist Section
                    _buildSectionHeader(
                      AppStrings.get('prioritize_section', lang),
                      AppStrings.get('prioritize_desc', lang),
                      Icons.thumb_up_rounded,
                      primary,
                      titleColor,
                      subColor,
                      () => _showAddSheet('whitelist'),
                    ),
                    const SizedBox(height: 10),
                    if (whitelist.isEmpty)
                      _buildEmptySection(
                        AppStrings.get('no_prioritized_yet', lang),
                        AppStrings.get('tap_to_add', lang),
                        primary,
                        isDark,
                      )
                    else
                      ...whitelist.map((pref) => _buildPreferenceItem(
                            pref, primary, isDark, titleColor, prefProvider)),

                    const SizedBox(height: 28),

                    // Blacklist Section
                    _buildSectionHeader(
                      AppStrings.get('avoid_section', lang),
                      AppStrings.get('avoid_desc', lang),
                      Icons.block_rounded,
                      Colors.red[400]!,
                      titleColor,
                      subColor,
                      () => _showAddSheet('blacklist'),
                    ),
                    const SizedBox(height: 10),
                    if (blacklist.isEmpty)
                      _buildEmptySection(
                        AppStrings.get('no_avoided_yet', lang),
                        AppStrings.get('tap_to_add', lang),
                        Colors.red[400]!,
                        isDark,
                      )
                    else
                      ...blacklist.map((pref) => _buildPreferenceItem(
                            pref, Colors.red[400]!, isDark, titleColor, prefProvider)),

                    // Reset Button
                    if (hasAny) ...[
                      const SizedBox(height: 32),
                      Center(
                        child: TextButton.icon(
                          onPressed: _showClearDialog,
                          icon: Icon(Icons.restart_alt_rounded, color: Colors.red[400], size: 18),
                          label: Text(
                            AppStrings.get('reset_all_pref_btn', lang),
                            style: TextStyle(
                              color: Colors.red[400],
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddSheet('whitelist'),
            backgroundColor: primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              AppStrings.get('add', lang),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Color titleColor,
    Color? subColor,
    VoidCallback onAdd,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 1,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: subColor),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.add_rounded, size: 18, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySection(String title, String subtitle, Color color, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey[200]!,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_menu_rounded,
            size: 28,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem(
    FoodPreference pref,
    Color accentColor,
    bool isDark,
    Color titleColor,
    FoodPreferenceProvider provider,
  ) {
    final isWhitelist = pref.type == 'whitelist';
    final lang = Provider.of<LanguageProvider>(context).locale;

    return Dismissible(
      key: Key(pref.foodName),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        provider.removePreference(pref.foodName);
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("\"${pref.foodName}\" ${AppStrings.get('item_removed', lang)}"),
            backgroundColor: Theme.of(context).primaryColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: AppStrings.get('cancel', lang),
              textColor: Colors.white,
              onPressed: () {
                provider.addPreference(pref.foodName, pref.type);
              },
            ),
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Color indicator
            Container(
              width: 4, height: 36,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Icon
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isWhitelist ? Icons.favorite_rounded : Icons.not_interested_rounded,
                size: 16,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 12),
            // Food name
            Expanded(
              child: Text(
                pref.foodName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ),
            // Toggle type button
            GestureDetector(
              onTap: () {
                provider.toggleType(pref.foodName);
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isWhitelist ? Colors.red[400]! : const Color(0xFF10B981)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: 14,
                      color: isWhitelist ? Colors.red[400] : const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isWhitelist ? AppStrings.get('toggle_avoid', lang) : AppStrings.get('toggle_priority', lang),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isWhitelist ? Colors.red[400] : const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Delete button
            GestureDetector(
              onTap: () {
                provider.removePreference(pref.foodName);
                HapticFeedback.lightImpact();
              },
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
