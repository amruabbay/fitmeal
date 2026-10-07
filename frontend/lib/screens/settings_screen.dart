import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fit_meal/models/user_profile.dart';
import 'package:fit_meal/providers/user_profile_provider.dart';
import 'package:fit_meal/utils/nutrition_targets.dart';
import 'package:fit_meal/providers/daily_log_provider.dart';
import 'package:fit_meal/providers/theme_provider.dart';
import 'package:fit_meal/providers/language_provider.dart';
import 'package:fit_meal/config/app_strings.dart';
import 'package:fit_meal/screens/onboarding_screen.dart';
import 'package:fit_meal/widgets/sliding_segmented_control.dart';
import 'package:fit_meal/widgets/tactile_scale_effect.dart';
import 'package:fit_meal/screens/food_preferences_screen.dart';
import 'package:fit_meal/providers/food_preference_provider.dart';
import 'package:fit_meal/widgets/profile_avatar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fit_meal/screens/crop_screen.dart';
import 'package:fit_meal/utils/image_helper_stub.dart'
    if (dart.library.html) 'package:fit_meal/utils/image_helper_web.dart'
    if (dart.library.io) 'package:fit_meal/utils/image_helper_io.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isEditing = false;
  bool _isSaving = false;

  // Editing controllers
  late TextEditingController _namaController;
  late TextEditingController _beratController;
  late TextEditingController _tinggiController;
  late TextEditingController _umurController;
  late String _gender;
  late String _goal;
  late String _activity;

  // Initial values for change detection (disabled/enabled button state)
  String _initialNama = '';
  String _initialBerat = '';
  String _initialTinggi = '';
  String _initialUmur = '';
  String _initialGender = '';
  String _initialGoal = '';
  String _initialActivity = '';

  /// Returns true if any field has been modified from its initial value
  bool get _hasChanges {
    if (!_isEditing) return false;
    return _namaController.text != _initialNama ||
        _beratController.text != _initialBerat ||
        _tinggiController.text != _initialTinggi ||
        _umurController.text != _initialUmur ||
        _gender != _initialGender ||
        _goal != _initialGoal ||
        _activity != _initialActivity;
  }

  @override
  void initState() {
    super.initState();
    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).profile;
    _namaController = TextEditingController(text: profile.nama);
    _beratController = TextEditingController(
        text: profile.berat > 0 ? '${profile.berat}' : '');
    _tinggiController = TextEditingController(
        text: profile.tinggi > 0 ? '${profile.tinggi}' : '');
    _umurController =
        TextEditingController(text: profile.umur > 0 ? '${profile.umur}' : '');
    _gender = profile.gender;
    _goal = profile.goal;
    _activity = profile.activity;

    // Add listeners to detect changes for button state validation
    _namaController.addListener(_onFieldChanged);
    _beratController.addListener(_onFieldChanged);
    _tinggiController.addListener(_onFieldChanged);
    _umurController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    // Rebuild to re-evaluate _hasChanges
    setState(() {});
  }

  @override
  void dispose() {
    _namaController.removeListener(_onFieldChanged);
    _beratController.removeListener(_onFieldChanged);
    _tinggiController.removeListener(_onFieldChanged);
    _umurController.removeListener(_onFieldChanged);
    _namaController.dispose();
    _beratController.dispose();
    _tinggiController.dispose();
    _umurController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    final profileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final logProvider = Provider.of<DailyLogProvider>(context, listen: false);

    final updatedProfile = UserProfile(
      nama: _namaController.text.trim(),
      berat: double.tryParse(_beratController.text) ?? 0,
      tinggi: double.tryParse(_tinggiController.text) ?? 0,
      umur: int.tryParse(_umurController.text) ?? 0,
      gender: _gender,
      goal: _goal,
      activity: _activity,
      profileImagePath: profileProvider.profile.profileImagePath,
    );

    await profileProvider.updateProfile(updatedProfile);

    final targets = calculateNutritionTargets(
      weightKg: updatedProfile.berat,
      heightCm: updatedProfile.tinggi,
      ageYears: updatedProfile.umur,
      gender: updatedProfile.gender,
      goal: updatedProfile.goal,
      activity: updatedProfile.activity,
    );

    await logProvider.updateTargets(
      calories: targets.effectiveCalories,
      protein: targets.protein,
      carbs: targets.carbs,
      fat: targets.fat,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.get('profile_updated',
            Provider.of<LanguageProvider>(context, listen: false).locale)),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showResetDialog(String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppStrings.get('reset_dialog_title', lang)),
        content: Text(AppStrings.get('reset_dialog_content', lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.get('cancel', lang)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final profileProvider =
                  Provider.of<UserProfileProvider>(context, listen: false);
              await profileProvider.resetProfile();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                (route) => false,
              );
            },
            child: Text(AppStrings.get('reset', lang),
                style: TextStyle(
                    color: Colors.red[400], fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1E293B);
    final subColor = isDark ? Colors.grey[500] : Colors.grey[500];
    final profile = Provider.of<UserProfileProvider>(context).profile;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final lang = langProvider.locale;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.get('settings', lang)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Profile Card ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              ProfileAvatar(
                                name: profile.nama,
                                size: 48,
                                imagePath: profile.profileImagePath,
                                showEditBadge: true,
                                onTap: () => _showPhotoPicker(
                                  context,
                                  Provider.of<UserProfileProvider>(context,
                                      listen: false),
                                  lang,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.nama.isNotEmpty
                                        ? profile.nama
                                        : "User",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: titleColor,
                                    ),
                                  ),
                                  Text(
                                    _getGoalLabel(profile.goal),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () {
                              final newEditing = !_isEditing;
                              setState(() {
                                _isEditing = newEditing;
                                if (newEditing) {
                                  // Snapshot initial values when entering edit mode
                                  _initialNama = _namaController.text;
                                  _initialBerat = _beratController.text;
                                  _initialTinggi = _tinggiController.text;
                                  _initialUmur = _umurController.text;
                                  _initialGender = _gender;
                                  _initialGoal = _goal;
                                  _initialActivity = _activity;
                                }
                              });
                            },
                            icon: Icon(
                              _isEditing
                                  ? Icons.close_rounded
                                  : Icons.edit_rounded,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),

                      if (!_isEditing) ...[
                        const SizedBox(height: 20),
                        _buildInfoRow(
                            AppStrings.get('weight', lang),
                            "${profile.berat} ${AppStrings.get('weight_unit', lang)}",
                            Icons.monitor_weight_outlined,
                            isDark,
                            titleColor),
                        _buildInfoRow(
                            AppStrings.get('height', lang),
                            "${profile.tinggi} ${AppStrings.get('height_unit', lang)}",
                            Icons.height_rounded,
                            isDark,
                            titleColor),
                        _buildInfoRow(
                            AppStrings.get('age', lang),
                            "${profile.umur} ${AppStrings.get('age_unit', lang)}",
                            Icons.cake_outlined,
                            isDark,
                            titleColor),
                        _buildInfoRow(
                            AppStrings.get('gender', lang),
                            profile.gender == 'pria'
                                ? AppStrings.get('male', lang)
                                : AppStrings.get('female', lang),
                            Icons.wc_rounded,
                            isDark,
                            titleColor),
                        _buildInfoRow(
                            AppStrings.get('activity', lang),
                            _getActivityLabel(profile.activity, lang),
                            Icons.directions_run_rounded,
                            isDark,
                            titleColor),
                        _buildInfoRow(
                            AppStrings.get('bmi', lang),
                            "${profile.bmi.toStringAsFixed(1)} (${profile.bmiCategory})",
                            Icons.speed_rounded,
                            isDark,
                            titleColor),
                      ],

                      // Edit mode
                      if (_isEditing) ...[
                        const SizedBox(height: 20),
                        _buildEditField(
                            AppStrings.get('your_name', lang),
                            _namaController,
                            TextInputType.text,
                            isDark,
                            titleColor),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: _buildEditField(
                                    AppStrings.get('your_weight', lang),
                                    _beratController,
                                    TextInputType.number,
                                    isDark,
                                    titleColor)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildEditField(
                                    AppStrings.get('your_height', lang),
                                    _tinggiController,
                                    TextInputType.number,
                                    isDark,
                                    titleColor)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildEditField(
                                    AppStrings.get('your_age', lang),
                                    _umurController,
                                    TextInputType.number,
                                    isDark,
                                    titleColor)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SlidingSegmentedControl(
                          values: const ['pria', 'wanita'],
                          labels: [
                            AppStrings.get('male', lang),
                            AppStrings.get('female', lang)
                          ],
                          selectedValue: _gender,
                          onChanged: (val) => setState(() => _gender = val),
                        ),
                        const SizedBox(height: 12),
                        SlidingSegmentedControl(
                          values: const ['cutting', 'maintain', 'bulking'],
                          labels: const ['Cutting', 'Maintain', 'Bulking'],
                          selectedValue: _goal,
                          onChanged: (val) => setState(() => _goal = val),
                        ),
                        const SizedBox(height: 12),
                        _buildActivityDropdown(isDark, titleColor, lang),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            child: TactileScaleEffect(
                              enabled: !_isSaving && _hasChanges,
                              scaleDownTo: 0.96,
                              child: ElevatedButton(
                                onPressed: (_isSaving || !_hasChanges)
                                    ? null
                                    : _saveChanges,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _hasChanges
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[400],
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: isDark
                                      ? Colors.grey[800]
                                      : Colors.grey[300],
                                  disabledForegroundColor: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[500],
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5))
                                    : Text(
                                        _hasChanges
                                            ? AppStrings.get(
                                                'save_changes', lang)
                                            : AppStrings.get(
                                                'no_changes', lang),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- Theme Toggle ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.get('appearance', lang),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: titleColor.withOpacity(0.6),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isDark
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
                                color: Theme.of(context).primaryColor,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                AppStrings.get('dark_mode', lang),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: titleColor,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: isDark,
                            onChanged: (_) => themeProvider.toggleTheme(),
                            activeColor: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- Language Selector ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.get('language_section', lang),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: titleColor.withOpacity(0.6),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.translate_rounded,
                                color: Theme.of(context).primaryColor,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                AppStrings.get('language', lang),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: titleColor,
                                ),
                              ),
                            ],
                          ),
                          _LanguageToggle(
                            currentLang: lang,
                            onChanged: (val) => langProvider.setLocale(val),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- Food Preferences ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.get('recommendation_section', lang),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: titleColor.withOpacity(0.6),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, a, b) =>
                                  const FoodPreferencesScreen(),
                              transitionsBuilder: (_, anim, __, child) =>
                                  FadeTransition(opacity: anim, child: child),
                              transitionDuration:
                                  const Duration(milliseconds: 250),
                            ),
                          );
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              color: Theme.of(context).primaryColor,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.get('food_preferences', lang),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: titleColor,
                                    ),
                                  ),
                                  Consumer<FoodPreferenceProvider>(
                                    builder: (context, pref, _) {
                                      final count = pref.whitelistItems.length +
                                          pref.blacklistItems.length;
                                      return Text(
                                        count > 0
                                            ? "$count ${AppStrings.get('food_customized', lang)}"
                                            : AppStrings.get(
                                                'no_preferences', lang),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: subColor,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: subColor,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- App Info & Reset ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.get('others', lang),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: titleColor.withOpacity(0.6),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  color: subColor, size: 20),
                              const SizedBox(width: 12),
                              Text(AppStrings.get('app_version', lang),
                                  style: TextStyle(
                                      fontSize: 15, color: titleColor)),
                            ],
                          ),
                          Text("1.0.0",
                              style: TextStyle(fontSize: 14, color: subColor)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(
                          height: 1,
                          color: isDark ? Colors.white10 : Colors.grey[200]),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _showResetDialog(lang),
                        child: Row(
                          children: [
                            Icon(Icons.restart_alt_rounded,
                                color: Colors.red[400], size: 20),
                            const SizedBox(width: 12),
                            Text(
                              AppStrings.get('reset_all_data', lang),
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.red[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================
  // Helpers
  // ============================
  Widget _buildInfoRow(String label, String value, IconData icon, bool isDark,
      Color titleColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? Colors.grey[500] : Colors.grey),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600])),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: titleColor)),
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller,
      TextInputType type, bool isDark, Color titleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            keyboardType: type,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: titleColor),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityDropdown(bool isDark, Color titleColor, String lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(AppStrings.get('daily_activity', lang),
            style: TextStyle(
                fontSize: 15, color: titleColor, fontWeight: FontWeight.w500)),
        DropdownButton<String>(
          value: _activity,
          underline: const SizedBox(),
          dropdownColor: Theme.of(context).cardColor,
          icon: Icon(Icons.keyboard_arrow_down,
              color: Theme.of(context).primaryColor),
          style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 15),
          onChanged: (val) => setState(() => _activity = val!),
          items: [
            DropdownMenuItem(
                value: 'sedentary',
                child: Text(AppStrings.get('sedentary', lang),
                    style: TextStyle(color: titleColor))),
            DropdownMenuItem(
                value: 'moderate',
                child: Text(AppStrings.get('moderate', lang),
                    style: TextStyle(color: titleColor))),
            DropdownMenuItem(
                value: 'active',
                child: Text(AppStrings.get('active', lang),
                    style: TextStyle(color: titleColor))),
          ],
        ),
      ],
    );
  }

  // _buildLangChip removed — replaced by _LanguageToggle widget below

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

  String _getActivityLabel(String activity, String lang) {
    switch (activity) {
      case 'sedentary':
        return AppStrings.get('sedentary', lang);
      case 'moderate':
        return AppStrings.get('moderate', lang);
      case 'active':
        return AppStrings.get('active', lang);
      default:
        return activity;
    }
  }

  void _showPhotoPicker(
      BuildContext context, UserProfileProvider provider, String lang) {
    final bool hasCustomPhoto = provider.profile.profileImagePath != null &&
        provider.profile.profileImagePath!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final pickerBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
        final primaryTextColor =
            isDark ? Colors.white : const Color(0xFF0F172A);

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: pickerBgColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  AppStrings.get('change_photo', lang),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  title: Text(
                    AppStrings.get('take_photo', lang),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                    ),
                  ),
                  onTap: () async {
                    try {
                      final XFile? pickedFile = await pickImagePlatform(true);
                      if (pickedFile != null && context.mounted) {
                        Navigator.pop(
                            context); // Pop sheet after successful selection
                        final XFile? croppedFile = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CropScreen(imageFile: pickedFile),
                          ),
                        );
                        if (croppedFile != null) {
                          await provider.updateProfileImage(croppedFile.path);
                        }
                      } else {
                        if (context.mounted) {
                          Navigator.pop(context); // Pop sheet if cancelled
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                      debugPrint('Error picking image from camera: $e');
                    }
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: Color(0xFF0EA5E9),
                    ),
                  ),
                  title: Text(
                    AppStrings.get('choose_from_gallery', lang),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                    ),
                  ),
                  onTap: () async {
                    try {
                      final XFile? pickedFile = await pickImagePlatform(false);
                      if (pickedFile != null && context.mounted) {
                        Navigator.pop(
                            context); // Pop sheet after successful selection
                        final XFile? croppedFile = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CropScreen(imageFile: pickedFile),
                          ),
                        );
                        if (croppedFile != null) {
                          await provider.updateProfileImage(croppedFile.path);
                        }
                      } else {
                        if (context.mounted) {
                          Navigator.pop(context); // Pop sheet if cancelled
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                      debugPrint('Error picking image from gallery: $e');
                    }
                  },
                ),
                if (hasCustomPhoto) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    title: Text(
                      AppStrings.get('remove_photo', lang),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await provider.updateProfileImage('');
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// =========================================================
// Modern Language Toggle — Sliding pill indicator
// =========================================================
class _LanguageToggle extends StatelessWidget {
  final String currentLang;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const _LanguageToggle({
    required this.currentLang,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isID = currentLang == 'id';
    const itemWidth = 44.0;
    const itemHeight = 32.0;
    const padding = 3.0;

    return Container(
      width: (itemWidth * 2) + (padding * 2),
      height: itemHeight + (padding * 2),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Sliding indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            left: isID ? padding : padding + itemWidth,
            top: padding,
            child: Container(
              width: itemWidth,
              height: itemHeight,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.12) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
            ),
          ),
          // Buttons
          Padding(
            padding: const EdgeInsets.all(padding),
            child: Row(
              children: [
                _LangOption(
                  label: 'ID',
                  isSelected: isID,
                  isDark: isDark,
                  width: itemWidth,
                  height: itemHeight,
                  onTap: () => onChanged('id'),
                ),
                _LangOption(
                  label: 'EN',
                  isSelected: !isID,
                  isDark: isDark,
                  width: itemWidth,
                  height: itemHeight,
                  onTap: () => onChanged('en'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final double width;
  final double height;
  final VoidCallback onTap;

  const _LangOption({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: height,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF1E293B))
                  : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
              letterSpacing: 0.3,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
