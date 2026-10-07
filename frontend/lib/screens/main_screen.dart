import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fit_meal/main.dart' show FMColors;
import 'package:fit_meal/providers/user_profile_provider.dart';
import 'package:fit_meal/providers/language_provider.dart';
import 'package:fit_meal/config/app_strings.dart';
import 'package:fit_meal/screens/dashboard_screen.dart';
import 'package:fit_meal/screens/statistics_screen.dart';
import 'package:fit_meal/screens/recommendation_screen.dart';
import 'package:fit_meal/screens/search_screen.dart';
import 'package:fit_meal/screens/settings_screen.dart';
import 'package:fit_meal/widgets/profile_avatar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _navAnimController;

  void _navigateToSearch() {
    setState(() => _currentIndex = 3);
  }

  String _getGreeting(String lang) {
    final hour = DateTime.now().hour;
    if (hour < 11) return AppStrings.get('greeting_morning', lang);
    if (hour < 15) return AppStrings.get('greeting_afternoon', lang);
    if (hour < 18) return AppStrings.get('greeting_evening', lang);
    return AppStrings.get('greeting_night', lang);
  }

  @override
  void initState() {
    super.initState();
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _navAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final profile = Provider.of<UserProfileProvider>(context).profile;
    final lang = Provider.of<LanguageProvider>(context).locale;

    final List<Widget> pages = [
      DashboardScreen(onNavigateToSearch: _navigateToSearch),
      const StatisticsScreen(),
      const RecommendationScreen(),
      const SearchScreen(),
    ];

    // ---- nav items config ----
    final navItems = [
      (Icons.home_rounded,        Icons.home_outlined,         AppStrings.get('nav_home', lang)),
      (Icons.bar_chart_rounded,   Icons.bar_chart_outlined,    AppStrings.get('nav_stats', lang)),
      (Icons.auto_awesome_rounded,Icons.auto_awesome_outlined, AppStrings.get('nav_recommendation', lang)),
      (Icons.search_rounded,      Icons.search_outlined,       AppStrings.get('nav_search', lang)),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          // ---- App Bar ----
          appBar: AppBar(
            titleSpacing: 20,
            title: Row(
              children: [
                // Avatar container
                ProfileAvatar(
                  name: profile.nama,
                  size: 38,
                  imagePath: profile.profileImagePath,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, a, b) => const SettingsScreen(),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(opacity: anim, child: child),
                        transitionDuration: const Duration(milliseconds: 250),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(lang).toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Barlow',
                        fontSize: 10,
                        color: isDark ? FMColors.subDark : FMColors.subLight,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      profile.nama.isNotEmpty ? profile.nama : "Guest",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? FMColors.titleDark : FMColors.titleLight,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Settings button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, a, b) => const SettingsScreen(),
                      transitionsBuilder: (_, anim, __, child) =>
                          FadeTransition(opacity: anim, child: child),
                      transitionDuration: const Duration(milliseconds: 250),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: isDark ? FMColors.subDark : FMColors.subLight,
                  ),
                ),
              ),
            ],
          ),

          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),

          // ---- Floating Pill Bottom Nav ----
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: isDark ? FMColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark ? FMColors.borderDark : FMColors.borderLight,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(navItems.length, (i) {
                  final (filledIcon, outlinedIcon, label) = navItems[i];
                  final isSelected = _currentIndex == i;
                  return _buildNavItem(
                    index: i,
                    filledIcon: filledIcon,
                    outlinedIcon: outlinedIcon,
                    label: label,
                    isSelected: isSelected,
                    primary: primary,
                    isDark: isDark,
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData filledIcon,
    required IconData outlinedIcon,
    required String label,
    required bool isSelected,
    required Color primary,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [primary, primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? filledIcon : outlinedIcon,
                key: ValueKey(isSelected),
                size: 22,
                color: isSelected
                    ? Colors.white
                    : (isDark ? FMColors.subDark : FMColors.subLight),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
