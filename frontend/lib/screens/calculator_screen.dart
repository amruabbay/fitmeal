import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:fit_meal/config/api_config.dart';
import 'package:fit_meal/providers/daily_log_provider.dart';
import 'package:fit_meal/providers/user_profile_provider.dart';
import 'package:fit_meal/widgets/result_sheet.dart';
import 'package:fit_meal/widgets/sliding_segmented_control.dart';
import 'package:fit_meal/widgets/tactile_scale_effect.dart';


class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController _beratController = TextEditingController();
  final TextEditingController _tinggiController = TextEditingController();
  final TextEditingController _umurController = TextEditingController();

  String _gender = 'pria';
  String _goal = 'cutting';
  String _activity = 'sedentary';
  bool _isLoading = false;
  bool _isButtonActive = false;

  @override
  void initState() {
    super.initState();
    _beratController.addListener(_updateButtonState);
    _tinggiController.addListener(_updateButtonState);
    _umurController.addListener(_updateButtonState);

    // Auto-fill from saved profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile =
          Provider.of<UserProfileProvider>(context, listen: false).profile;
      if (profile.berat > 0) {
        _beratController.text = profile.berat.toString();
      }
      if (profile.tinggi > 0) {
        _tinggiController.text = profile.tinggi.toString();
      }
      if (profile.umur > 0) {
        _umurController.text = profile.umur.toString();
      }
      setState(() {
        _gender = profile.gender;
        _goal = profile.goal;
        _activity = profile.activity;
      });
    });
  }

  void _updateButtonState() {
    setState(() {
      _isButtonActive = _beratController.text.isNotEmpty &&
          _tinggiController.text.isNotEmpty &&
          _umurController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _beratController.dispose();
    _tinggiController.dispose();
    _umurController.dispose();
    super.dispose();
  }

  Future<void> hitungNutrisi() async {
    if (!_isButtonActive) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.rekomendasiUrl),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'berat': double.parse(_beratController.text),
          'tinggi': double.parse(_tinggiController.text),
          'umur': int.parse(_umurController.text),
          'gender': _gender,
          'goal': _goal,
          'activity': _activity,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['user_info'] != null) {
          data['user_info']['berat_input'] =
              double.parse(_beratController.text);
          data['user_info']['tinggi_input'] =
              double.parse(_tinggiController.text);

          // ✅ Auto-save targets to DailyLogProvider
          if (mounted) {
            final userInfo = data['user_info'];
            final logProvider =
                Provider.of<DailyLogProvider>(context, listen: false);

            // Estimate carbs and fat from calories and protein
            final targetCal =
                (userInfo['target_kalori'] ?? 2000).toDouble();
            final targetPro =
                (userInfo['target_protein'] ?? 150).toDouble();
            // Rough split: remaining cals -> 55% carbs, 45% fat
            final remainingCal = targetCal - (targetPro * 4);
            final targetCarbs = (remainingCal * 0.55) / 4;
            final targetFat = (remainingCal * 0.45) / 9;

            logProvider.updateTargets(
              calories: targetCal,
              protein: targetPro,
              carbs: targetCarbs,
              fat: targetFat,
            );
          }
        }

        if (!mounted) return;

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ResultSheet(resultData: data),
        );
      } else {
        _showError('Gagal: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Koneksi Gagal. Cek Link Ngrok.');
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1E293B);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // CARD 1 — DATA DIRI
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("DATA DIRI",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: titleColor.withOpacity(0.6),
                          letterSpacing: 1)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                          child: _buildCleanInput(
                              "Berat (kg)", _beratController, context)),
                      Container(
                          width: 1,
                          height: 40,
                          color:
                              isDark ? Colors.white10 : Colors.grey.shade300,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 15)),
                      Expanded(
                          child: _buildCleanInput(
                              "Tinggi (cm)", _tinggiController, context)),
                      Container(
                          width: 1,
                          height: 40,
                          color:
                              isDark ? Colors.white10 : Colors.grey.shade300,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 15)),
                      Expanded(
                          child: _buildCleanInput(
                              "Umur (th)", _umurController, context)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SlidingSegmentedControl(
                      values: const ['pria', 'wanita'],
                      labels: const ['Pria', 'Wanita'],
                      selectedValue: _gender,
                      onChanged: (val) => setState(() => _gender = val)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // CARD 2 — TARGET & AKTIVITAS
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TARGET & AKTIVITAS",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: titleColor.withOpacity(0.6),
                          letterSpacing: 1)),
                  const SizedBox(height: 15),
                  SlidingSegmentedControl(
                      values: const ['cutting', 'maintain', 'bulking'],
                      labels: const ['Cutting', 'Maintain', 'Bulking'],
                      selectedValue: _goal,
                      onChanged: (val) => setState(() => _goal = val)),
                  const SizedBox(height: 20),
                  Divider(
                      height: 1,
                      color: isDark ? Colors.white10 : Colors.grey[200]),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Aktivitas Harian",
                          style: TextStyle(
                              fontSize: 15,
                              color: titleColor,
                              fontWeight: FontWeight.w500)),
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
                        onChanged: (val) =>
                            setState(() => _activity = val!),
                        items: [
                          DropdownMenuItem(
                              value: 'sedentary',
                              child: Text("Jarang Gerak",
                                  style: TextStyle(color: titleColor))),
                          DropdownMenuItem(
                              value: 'moderate',
                              child: Text("Cukup Aktif",
                                  style: TextStyle(color: titleColor))),
                          DropdownMenuItem(
                              value: 'active',
                              child: Text("Sangat Aktif",
                                  style: TextStyle(color: titleColor))),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            // BUTTON
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: _isButtonActive && !_isLoading
                    ? [
                        BoxShadow(
                          color: Theme.of(context)
                              .primaryColor
                              .withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ]
                    : [],
              ),
              child: TactileScaleEffect(
                enabled: _isButtonActive && !_isLoading,
                scaleDownTo: 0.96,
                child: ElevatedButton(
                  onPressed:
                      (_isButtonActive && !_isLoading) ? hitungNutrisi : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    disabledBackgroundColor:
                        isDark ? Colors.grey[800] : Colors.grey[300],
                    foregroundColor: Colors.white,
                    disabledForegroundColor:
                        isDark ? Colors.grey[600] : Colors.grey[500],
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    splashFactory: InkRipple.splashFactory,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text(
                          "HITUNG KEBUTUHAN",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            fontFamily: 'Segoe UI',
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanInput(
      String label, TextEditingController controller, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputColor =
        isDark ? const Color(0xFFEEEEEE) : const Color(0xFF1E293B);
    final hintColor =
        isDark ? const Color(0xFF555555) : const Color(0xFF94A3B8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: inputColor),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.zero,
            hintText: "0",
            hintStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: hintColor),
            border: InputBorder.none,
          ),
        )
      ],
    );
  }
}
