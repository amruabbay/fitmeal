import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fit_meal/providers/theme_provider.dart';
import 'package:fit_meal/providers/daily_log_provider.dart';
import 'package:fit_meal/providers/user_profile_provider.dart';
import 'package:fit_meal/providers/food_preference_provider.dart';
import 'package:fit_meal/providers/language_provider.dart';
import 'package:fit_meal/screens/main_screen.dart';
import 'package:fit_meal/screens/onboarding_screen.dart';
import 'package:fit_meal/screens/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await initializeDateFormatting('en_US', null);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DailyLogProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => FoodPreferenceProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const FitMealApp(),
    ),
  );
}

// ============================================================
// CLEAN & MINIMAL DESIGN SYSTEM
// Premium, minimalist, lots of whitespace, soft borders
// ============================================================

class FMColors {
  // Primary — Premium Emerald
  static const primaryLight = Color(0xFF10B981);
  static const primaryDark  = Color(0xFF10B981); // Keep vibrant in dark mode

  // Secondary
  static const secondary    = Color(0xFF0EA5E9);

  // Backgrounds — Light
  static const bgLight      = Color(0xFFF8FAFC); // Slate 50 background
  static const surfaceLight = Color(0xFFFFFFFF);
  static const cardLight    = Color(0xFFFFFFFF);
  static const canvasLight  = Color(0xFFF8FAFC); // Very light gray for inputs

  // Backgrounds — Dark
  static const bgDark       = Color(0xFF0F172A); // Slate 900
  static const surfaceDark  = Color(0xFF1E293B); // Slate 800
  static const cardDark     = Color(0xFF1E293B);
  static const canvasDark   = Color(0xFF0F172A);

  // Text — Light
  static const titleLight   = Color(0xFF0F172A); // Slate 900
  static const bodyLight    = Color(0xFF334155); // Slate 700
  static const subLight     = Color(0xFF64748B); // Slate 500

  // Text — Dark
  static const titleDark    = Color(0xFFF8FAFC);
  static const bodyDark     = Color(0xFFCBD5E1);
  static const subDark      = Color(0xFF94A3B8);

  // Borders
  static const borderLight  = Color(0xFFE2E8F0); // Slate 200
  static const borderDark   = Color(0xFF334155); // Slate 700

  // Macro accents
  static const proteinColor = Color(0xFF3B82F6);  // Blue
  static const carbsColor   = Color(0xFF10B981);  // Green
  static const fatColor     = Color(0xFFF59E0B);  // Amber
  static const info         = Color(0xFF0EA5E9);  // Water
  static const danger       = Color(0xFFEF4444);  // Red

  // Dedicated Meal accents
  static const breakfastColor = Color(0xFF0EA5E9); // Morning Sky Blue
  static const lunchColor     = Color(0xFF10B981); // Noon Emerald Green
  static const dinnerColor    = Color(0xFF3B82F6); // Twilight Royal Blue
  static const snackColor     = Color(0xFFF59E0B); // Cookie Amber
}

class FitMealApp extends StatelessWidget {
  const FitMealApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Clean, modern typography
    final displayFont = GoogleFonts.plusJakartaSans();
    final bodyFont = GoogleFonts.interTextTheme();

    return Consumer<ThemeProvider>(
      builder: (_, themeProvider, __) {
        return MaterialApp(
          title: 'FitMeal',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,

          // ==================== LIGHT THEME ====================
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            primaryColor: FMColors.primaryLight,
            scaffoldBackgroundColor: FMColors.bgLight,
            cardColor: FMColors.cardLight,
            canvasColor: FMColors.canvasLight,
            splashFactory: InkRipple.splashFactory, // Subtle ripple
            colorScheme: ColorScheme.fromSeed(
              seedColor: FMColors.primaryLight,
              primary: FMColors.primaryLight,
              secondary: FMColors.secondary,
              surface: FMColors.surfaceLight,
              brightness: Brightness.light,
            ),
            textTheme: bodyFont.copyWith(
              displayLarge: displayFont.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 36,
                letterSpacing: -1,
                color: FMColors.titleLight,
              ),
              headlineLarge: displayFont.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 28,
                letterSpacing: -0.5,
                color: FMColors.titleLight,
              ),
              titleLarge: displayFont.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: FMColors.titleLight,
              ),
              titleMedium: displayFont.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: FMColors.titleLight,
              ),
              bodyLarge: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: FMColors.bodyLight,
                height: 1.5,
              ),
              bodyMedium: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: FMColors.subLight,
                height: 1.5,
              ),
              labelLarge: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: FMColors.primaryLight,
              ),
            ).apply(
              bodyColor: FMColors.bodyLight,
              displayColor: FMColors.titleLight,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: FMColors.bgLight,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              titleTextStyle: displayFont.copyWith(
                color: FMColors.titleLight,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              iconTheme: const IconThemeData(color: FMColors.titleLight),
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
              ),
            ),
            cardTheme: CardThemeData(
              color: FMColors.cardLight,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: FMColors.borderLight, width: 1.5), // Soft border instead of shadow
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: FMColors.titleLight, // Black button for modern feel
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: displayFont.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: FMColors.canvasLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: FMColors.primaryLight,
                  width: 2,
                ),
              ),
            ),
            dividerTheme: const DividerThemeData(
              color: FMColors.borderLight,
              thickness: 1,
            ),
          ),

          // ==================== DARK THEME ====================
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primaryColor: FMColors.primaryDark,
            scaffoldBackgroundColor: FMColors.bgDark,
            cardColor: FMColors.cardDark,
            canvasColor: FMColors.canvasDark,
            splashFactory: InkRipple.splashFactory,
            colorScheme: ColorScheme.fromSeed(
              seedColor: FMColors.primaryDark,
              primary: FMColors.primaryDark,
              secondary: FMColors.secondary,
              surface: FMColors.surfaceDark,
              brightness: Brightness.dark,
            ),
            textTheme: bodyFont.copyWith(
              displayLarge: displayFont.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 36,
                letterSpacing: -1,
                color: FMColors.titleDark,
              ),
              headlineLarge: displayFont.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 28,
                letterSpacing: -0.5,
                color: FMColors.titleDark,
              ),
              titleLarge: displayFont.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: FMColors.titleDark,
              ),
              titleMedium: displayFont.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: FMColors.titleDark,
              ),
              bodyLarge: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: FMColors.bodyDark,
                height: 1.5,
              ),
              bodyMedium: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: FMColors.subDark,
                height: 1.5,
              ),
              labelLarge: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: FMColors.primaryDark,
              ),
            ).apply(
              bodyColor: FMColors.bodyDark,
              displayColor: FMColors.titleDark,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: FMColors.bgDark,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              titleTextStyle: displayFont.copyWith(
                color: FMColors.titleDark,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              iconTheme: const IconThemeData(color: FMColors.titleDark),
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              ),
            ),
            cardTheme: CardThemeData(
              color: FMColors.cardDark,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: FMColors.borderDark, width: 1.5),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: FMColors.primaryDark,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: displayFont.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: FMColors.surfaceDark,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: FMColors.primaryDark,
                  width: 2,
                ),
              ),
            ),
            dividerTheme: const DividerThemeData(
              color: FMColors.borderDark,
              thickness: 1,
            ),
          ),
          home: const _AppRouter(),
        );
      },
    );
  }
}

class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (_, profileProvider, __) {
        if (!profileProvider.isLoaded) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
                strokeWidth: 3,
              ),
            ),
          );
        }

        final destination = profileProvider.isOnboardingComplete
            ? const MainScreen()
            : const OnboardingScreen();

        return SplashScreen(destination: destination);
      },
    );
  }
}
