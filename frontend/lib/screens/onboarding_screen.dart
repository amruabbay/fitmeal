import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fit_meal/models/user_profile.dart';
import 'package:fit_meal/providers/user_profile_provider.dart';
import 'package:fit_meal/utils/nutrition_targets.dart';
import 'package:fit_meal/providers/daily_log_provider.dart';
import 'package:fit_meal/screens/main_screen.dart';
import 'package:fit_meal/widgets/tactile_scale_effect.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form data
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _beratController = TextEditingController();
  final TextEditingController _tinggiController = TextEditingController();
  final TextEditingController _umurController = TextEditingController();

  // Focus nodes for visual feedback
  final FocusNode _namaFocus = FocusNode();
  final FocusNode _beratFocus = FocusNode();
  final FocusNode _tinggiFocus = FocusNode();
  final FocusNode _umurFocus = FocusNode();

  String _gender = 'pria';
  String _goal = 'cutting';
  String _activity = 'sedentary';

  bool _isLoading = false;
  bool _hasTriedSubmitPage2 =
      false; // Track if user tried to proceed from page 2

  // Validation error messages
  String? _beratError;
  String? _tinggiError;
  String? _umurError;

  @override
  void initState() {
    super.initState();
    // Add listeners for focus changes to trigger rebuilds
    _namaFocus.addListener(_onFocusChange);
    _beratFocus.addListener(_onFocusChange);
    _tinggiFocus.addListener(_onFocusChange);
    _umurFocus.addListener(_onFocusChange);

    // Add listeners for text changes to clear errors and validate
    _namaController.addListener(_validateOnChange);
    _beratController.addListener(_validateOnChange);
    _tinggiController.addListener(_validateOnChange);
    _umurController.addListener(_validateOnChange);
  }

  void _onFocusChange() {
    setState(() {});
  }

  void _validateOnChange() {
    if (_hasTriedSubmitPage2) {
      _validateFields();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    _namaController.dispose();
    _beratController.dispose();
    _tinggiController.dispose();
    _umurController.dispose();
    _namaFocus.dispose();
    _beratFocus.dispose();
    _tinggiFocus.dispose();
    _umurFocus.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 1) {
      // Validate before moving from page 2
      setState(() => _hasTriedSubmitPage2 = true);
      if (!_validateFields()) return;
    }
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateFields() {
    bool isValid = true;

    // Validate berat
    final berat = double.tryParse(_beratController.text);
    if (_beratController.text.isEmpty) {
      _beratError = 'Wajib diisi';
      isValid = false;
    } else if (berat == null) {
      _beratError = 'Masukkan angka valid';
      isValid = false;
    } else if (berat < 20 || berat > 300) {
      _beratError = 'Rentang: 20–300 kg';
      isValid = false;
    } else {
      _beratError = null;
    }

    // Validate tinggi
    final tinggi = double.tryParse(_tinggiController.text);
    if (_tinggiController.text.isEmpty) {
      _tinggiError = 'Wajib diisi';
      isValid = false;
    } else if (tinggi == null) {
      _tinggiError = 'Masukkan angka valid';
      isValid = false;
    } else if (tinggi < 80 || tinggi > 250) {
      _tinggiError = 'Rentang: 80–250 cm';
      isValid = false;
    } else {
      _tinggiError = null;
    }

    // Validate umur
    final umur = int.tryParse(_umurController.text);
    if (_umurController.text.isEmpty) {
      _umurError = 'Wajib diisi';
      isValid = false;
    } else if (umur == null) {
      _umurError = 'Masukkan angka valid';
      isValid = false;
    } else if (umur < 5 || umur > 120) {
      _umurError = 'Rentang: 5–120 thn';
      isValid = false;
    } else {
      _umurError = null;
    }

    setState(() {});
    return isValid;
  }

  bool _isDataDiriFormValid() {
    if (_namaController.text.trim().isEmpty) return false;
    if (_gender.isEmpty) return false;

    final berat = double.tryParse(_beratController.text);
    final tinggi = double.tryParse(_tinggiController.text);
    final umur = int.tryParse(_umurController.text);

    return berat != null &&
        berat >= 20 &&
        berat <= 300 &&
        tinggi != null &&
        tinggi >= 80 &&
        tinggi <= 250 &&
        umur != null &&
        umur >= 5 &&
        umur <= 120;
  }

  bool _isStep2Valid() {
    final berat = double.tryParse(_beratController.text);
    final tinggi = double.tryParse(_tinggiController.text);
    final umur = int.tryParse(_umurController.text);

    return berat != null &&
        berat >= 20 &&
        berat <= 300 &&
        tinggi != null &&
        tinggi >= 80 &&
        tinggi <= 250 &&
        umur != null &&
        umur >= 5 &&
        umur <= 120;
  }

  Future<void> _completeOnboarding() async {
    if (!_isStep2Valid()) return;

    setState(() => _isLoading = true);
    final profileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final logProvider = Provider.of<DailyLogProvider>(context, listen: false);

    final profile = UserProfile(
      nama: _namaController.text.trim(),
      berat: double.tryParse(_beratController.text) ?? 0,
      tinggi: double.tryParse(_tinggiController.text) ?? 0,
      umur: int.tryParse(_umurController.text) ?? 0,
      gender: _gender,
      goal: _goal,
      activity: _activity,
    );

    // Save profile
    await profileProvider.saveProfile(profile);

    final targets = calculateNutritionTargets(
      weightKg: profile.berat,
      heightCm: profile.tinggi,
      ageYears: profile.umur,
      gender: profile.gender,
      goal: profile.goal,
      activity: profile.activity,
    );

    await logProvider.updateTargets(
      calories: targets.effectiveCalories,
      protein: targets.protein,
      carbs: targets.carbs,
      fat: targets.fat,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [
                _buildWelcomePage(),
                _buildDataDiriPage(),
                _buildTargetPage(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroIllustration(Color primary, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background glowing circles for rich depth
          Positioned(
            left: 50,
            top: 20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primary.withValues(alpha: 0.25),
                    primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 50,
            bottom: 20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                    const Color(0xFF0EA5E9).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // A beautiful background radial progress ring (representing Ring Activity)
          Positioned(
            top: 15,
            child: Opacity(
              opacity: 0.15,
              child: SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: 0.75,
                  strokeWidth: 12,
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                  backgroundColor: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ),
          ),

          // Central mockup card: Food Log Mockup
          Container(
            width: 200,
            height: 120,
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 60,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Icon(Icons.check_circle_rounded, color: primary, size: 16),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.restaurant_rounded,
                          color: primary, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 80,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFFF1F5F9)
                                  : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            width: 50,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Tiny progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.72,
                    minHeight: 5,
                    backgroundColor: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                  ),
                ),
              ],
            ),
          ),

          // Left floating glass badge: Calories
          Positioned(
            left: 15,
            bottom: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: Color(0xFFEF4444), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "450 kkal",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right floating glass badge: Target
          Positioned(
            right: 15,
            top: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: primary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    "Target AI",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // PAGE 1: WELCOME
  // ================================================================
  Widget _buildWelcomePage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
    final primary = Theme.of(context).primaryColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // ---- Hero Banner (reduced height with smooth curved wave transition) ----
                  ClipPath(
                    clipper: SmoothHeaderClipper(),
                    child: Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF065F46),
                                  const Color(0xFF047857)
                                ]
                              : [
                                  const Color(0xFF86EFAC),
                                  const Color(0xFF22C55E)
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Background pattern
                          Positioned(
                            top: -20,
                            right: -20,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            left: -60,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                          // Text Content
                          Positioned(
                            bottom: 50, // adjusted for clipper depth
                            left: 32,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "FitMeal",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "NUTRISI CERDAS, HIDUP SEHAT",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ---- Middle Content (Centered) ----
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHeroIllustration(primary, isDark),
                          const SizedBox(height: 16),
                          Text(
                            "Selamat Datang\ndi FitMeal",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              "Transformasi gaya hidup sehat Anda dimulai dari sini. Pantau nutrisi, atur jadwal makan, dan capai target kebugaran harian Anda.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF334155),
                                height: 1.55,
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),

                          // ---- CTA Button ----
                          Center(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withValues(alpha: 0.16),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                    spreadRadius: -4,
                                  ),
                                ],
                              ),
                              child: TactileScaleEffect(
                                scaleDownTo: 0.96,
                                child: ElevatedButton(
                                  onPressed: _nextPage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 48, vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Mari Mulai",
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.rocket_launch_rounded,
                                          size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ---- Bottom Trust Badges ----
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40, top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTrustBadgeInline(
                            Icons.verified_rounded, "100% GRATIS"),
                        const SizedBox(width: 32),
                        _buildTrustBadgeInline(
                            Icons.auto_awesome_rounded, "AI NUTRISI"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrustBadgeInline(IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // PAGE 2: DATA DIRI (Profil Kesehatan)
  // ================================================================
  Widget _buildDataDiriPage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primary = Theme.of(context).primaryColor;
    final inputColor =
        isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
    final hintColor =
        isDark ? const Color(0xFF555555) : const Color(0xFF94A3B8);

    final formValid = _isDataDiriFormValid();

    return Column(
      children: [
        // AppBar-like header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                onPressed: _prevPage,
                icon: Icon(Icons.arrow_back_rounded, color: titleColor),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text("LANGKAH 1/2",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: primary,
                      letterSpacing: 0.5,
                    )),
              ),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
        ),

        // Scrollable content
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),

                        // Title with green accent
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                              height: 1.2,
                            ),
                            children: [
                              const TextSpan(text: "Mari Mengenal "),
                              TextSpan(
                                text: "Anda",
                                style: TextStyle(
                                  color: primary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const TextSpan(text: "."),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Informasi ini membantu kami menghitung kebutuhan kalori harian Anda dengan akurat.",
                          style: TextStyle(
                              fontSize: 13, color: subColor, height: 1.5),
                        ),
                        const SizedBox(height: 36), // Increased from 24

                        // ---- Nama Panggilan Card ----
                        _buildNameCard(
                          primary: primary,
                          isDark: isDark,
                          titleColor: titleColor,
                          inputColor: inputColor,
                          hintColor: hintColor,
                        ),
                        const SizedBox(height: 36), // Increased from 24

                        // ---- Jenis Kelamin ----
                        Text("Jenis Kelamin",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            )),
                        const SizedBox(height: 14), // Increased from 12
                        Row(
                          children: [
                            Expanded(
                              child: _buildGenderCard(
                                "Pria",
                                Icons.male_rounded,
                                "pria",
                                primary,
                                isDark,
                                titleColor,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildGenderCard(
                                "Wanita",
                                Icons.female_rounded,
                                "wanita",
                                primary,
                                isDark,
                                titleColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 38), // Increased from 28

                        // ---- Ukuran Tubuh & Usia ----
                        Text("Ukuran Tubuh & Usia",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            )),
                        const SizedBox(height: 14), // Increased from 12
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildBodyMetricCard(
                                label: "BERAT",
                                unit: "kg",
                                hintText: "65",
                                icon: Icons.fitness_center_rounded,
                                controller: _beratController,
                                focusNode: _beratFocus,
                                errorText: _beratError,
                                isDark: isDark,
                                titleColor: titleColor,
                                subColor: subColor,
                                inputColor: inputColor,
                                primary: primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildBodyMetricCard(
                                label: "TINGGI",
                                unit: "cm",
                                hintText: "170",
                                icon: Icons.height_rounded,
                                controller: _tinggiController,
                                focusNode: _tinggiFocus,
                                errorText: _tinggiError,
                                isDark: isDark,
                                titleColor: titleColor,
                                subColor: subColor,
                                inputColor: inputColor,
                                primary: primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildBodyMetricCard(
                                label: "USIA",
                                unit: "thn",
                                hintText: "25",
                                icon: Icons.cake_rounded,
                                controller: _umurController,
                                focusNode: _umurFocus,
                                errorText: _umurError,
                                isDark: isDark,
                                titleColor: titleColor,
                                subColor: subColor,
                                inputColor: inputColor,
                                primary: primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 36), // Increased from 24

                        // ---- Progress Dots ----
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildDot(true, primary, isDark),
                              const SizedBox(width: 8),
                              _buildDot(false, primary, isDark),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),

        // ---- Bottom Button ----
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: TactileScaleEffect(
              scaleDownTo: formValid ? 0.96 : 1.0,
              child: ElevatedButton(
                onPressed: formValid ? _nextPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFFE2E8F0),
                  disabledForegroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : const Color(0xFF94A3B8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Lanjut",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---- Name input card ----
  Widget _buildNameCard({
    required Color primary,
    required bool isDark,
    required Color titleColor,
    required Color inputColor,
    required Color hintColor,
  }) {
    final isFocused = _namaFocus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFocused
              ? primary
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0)),
          width: isFocused ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isFocused
                ? primary.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: isFocused ? 16 : 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.person_rounded, size: 20, color: primary),
              ),
              const SizedBox(width: 12),
              Text("Nama Panggilan",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _namaController,
            focusNode: _namaFocus,
            keyboardType: TextInputType.text,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500, color: inputColor),
            decoration: InputDecoration(
              isDense: true,
              filled: false,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              hintText: "Masukkan nama Anda",
              hintStyle: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w400, color: hintColor),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCard(String label, IconData icon, String value,
      Color primary, bool isDark, Color titleColor) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 28,
                  color: isSelected ? Colors.white : primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : titleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Redesigned body metric card with focus, unit suffix, hint ----
  Widget _buildBodyMetricCard({
    required String label,
    required String unit,
    required String hintText,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String? errorText,
    required bool isDark,
    required Color titleColor,
    required Color? subColor,
    required Color inputColor,
    required Color primary,
  }) {
    final isFocused = focusNode.hasFocus;
    final hasError = errorText != null;
    const errorColor = Color(0xFFEF4444);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasError
              ? errorColor
              : isFocused
                  ? primary
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFE2E8F0)),
          width: (isFocused || hasError) ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: hasError
                ? errorColor.withValues(alpha: 0.1)
                : isFocused
                    ? primary.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: isFocused ? 16 : 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: hasError ? errorColor : subColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: hasError ? errorColor : subColor,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: inputColor),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    hintText: hintText,
                    hintStyle: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFF3A3A3A)
                            : const Color(0xFFD1D5DB)),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isFocused
                        ? primary
                        : (isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8)),
                  ),
                ),
              ),
            ],
          ),
          // Error message
          if (hasError) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.error_outline_rounded,
                      size: 10, color: Color(0xFFEF4444)),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorText,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFEF4444),
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDot(bool isActive, Color primary, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 28 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive
            ? primary
            : (isDark
                ? Colors.white.withValues(alpha: 0.12)
                : const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  // ================================================================
  // PAGE 3: TARGET & ACTIVITY
  // ================================================================
  Widget _buildTargetPage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primary = Theme.of(context).primaryColor;

    return Column(
      children: [
        // AppBar-like header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                onPressed: _prevPage,
                icon: Icon(Icons.arrow_back_rounded, color: titleColor),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text("LANGKAH 2/2",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: primary,
                      letterSpacing: 0.5,
                    )),
              ),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
        ),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Title
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                      height: 1.2,
                    ),
                    children: [
                      const TextSpan(text: "Tentukan "),
                      TextSpan(
                        text: "Langkahmu",
                        style: TextStyle(
                          color: primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Pilih target nutrisi dan aktivitas harian untuk personalisasi paket makanmu.",
                  style: TextStyle(fontSize: 13, color: subColor, height: 1.5),
                ),
                const SizedBox(height: 24),

                // ---- Target Fitness ----
                Text("Target Fitness",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    )),
                const SizedBox(height: 14),

                // Goal cards — consistent style with activity options
                _buildSelectionCard(
                  title: "Cutting",
                  subtitle: "Fokus pada penurunan lemak tubuh.",
                  icon: Icons.local_fire_department_rounded,
                  value: "cutting",
                  groupValue: _goal,
                  onTap: () => setState(() => _goal = "cutting"),
                  primary: primary,
                  isDark: isDark,
                  titleColor: titleColor,
                  subColor: subColor,
                ),
                _buildSelectionCard(
                  title: "Maintain",
                  subtitle: "Jaga berat badan ideal.",
                  icon: Icons.balance_rounded,
                  value: "maintain",
                  groupValue: _goal,
                  onTap: () => setState(() => _goal = "maintain"),
                  primary: primary,
                  isDark: isDark,
                  titleColor: titleColor,
                  subColor: subColor,
                ),
                _buildSelectionCard(
                  title: "Bulking",
                  subtitle: "Membangun massa otot secara intensif.",
                  icon: Icons.fitness_center_rounded,
                  value: "bulking",
                  groupValue: _goal,
                  onTap: () => setState(() => _goal = "bulking"),
                  primary: primary,
                  isDark: isDark,
                  titleColor: titleColor,
                  subColor: subColor,
                ),
                const SizedBox(height: 20),

                // ---- Aktivitas Harian ----
                Text("Aktivitas Harian",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    )),
                const SizedBox(height: 14),

                _buildSelectionCard(
                  title: "Jarang Gerak",
                  subtitle: "Bekerja di meja, aktivitas fisik minimal.",
                  icon: Icons.desktop_windows_rounded,
                  value: "sedentary",
                  groupValue: _activity,
                  onTap: () => setState(() => _activity = "sedentary"),
                  primary: primary,
                  isDark: isDark,
                  titleColor: titleColor,
                  subColor: subColor,
                ),
                _buildSelectionCard(
                  title: "Cukup Aktif",
                  subtitle: "Olahraga 1-3 kali seminggu.",
                  icon: Icons.directions_run_rounded,
                  value: "moderate",
                  groupValue: _activity,
                  onTap: () => setState(() => _activity = "moderate"),
                  primary: primary,
                  isDark: isDark,
                  titleColor: titleColor,
                  subColor: subColor,
                ),
                _buildSelectionCard(
                  title: "Sangat Aktif",
                  subtitle: "Olahraga rutin setiap hari atau fisik berat.",
                  icon: Icons.bolt_rounded,
                  value: "active",
                  groupValue: _activity,
                  onTap: () => setState(() => _activity = "active"),
                  primary: primary,
                  isDark: isDark,
                  titleColor: titleColor,
                  subColor: subColor,
                ),
                const SizedBox(height: 16),

                // ---- Info Banner ----
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9)
                        .withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.info_outline_rounded,
                            size: 16, color: Color(0xFF0EA5E9)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Pilihan ini akan membantu sistem AI kami menghitung kebutuhan kalori harianmu secara akurat.",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF475569),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ---- Progress Dots ----
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDot(false, primary, isDark),
                      const SizedBox(width: 8),
                      _buildDot(true, primary, isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // ---- Bottom Button ----
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: _isLoading
                ? Container(
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      ),
                    ),
                  )
                : TactileScaleEffect(
                    enabled: _isStep2Valid(),
                    scaleDownTo: 0.96,
                    child: ElevatedButton(
                      onPressed: _isStep2Valid() ? _completeOnboarding : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        disabledBackgroundColor:
                            isDark ? Colors.grey[800] : Colors.grey[300],
                        disabledForegroundColor:
                            isDark ? Colors.grey[600] : Colors.grey[500],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Selesai",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.check_circle_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // UNIFIED SELECTION CARD — used for both Goal & Activity
  // ================================================================
  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required String groupValue,
    required VoidCallback onTap,
    required Color primary,
    required bool isDark,
    required Color titleColor,
    required Color? subColor,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.08)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? primary
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? primary.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: isDark ? 0.1 : 0.02),
              blurRadius: isSelected ? 10 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon in container (left side)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? primary.withValues(alpha: 0.15)
                    : primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  size: 22,
                  color: isSelected
                      ? primary
                      : (isDark
                          ? primary.withValues(alpha: 0.8)
                          : primary.withValues(alpha: 0.7))),
            ),
            const SizedBox(width: 14),
            // Title & subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? primary : titleColor,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: subColor,
                      )),
                ],
              ),
            ),
            // Radio indicator (right side)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? primary
                      : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class SmoothHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);

    final controlPoint = Offset(size.width / 2, size.height);
    final endPoint = Offset(size.width, size.height - 30);

    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
