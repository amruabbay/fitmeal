import 'package:flutter/material.dart';
import 'package:fit_meal/wireframes/widgets/wireframe_components.dart';

class WireframeDashboardView extends StatefulWidget {
  const WireframeDashboardView({super.key});

  @override
  State<WireframeDashboardView> createState() => _WireframeDashboardViewState();
}

class _WireframeDashboardViewState extends State<WireframeDashboardView> {
  int _waterGlasses = 4;
  final int _maxGlasses = 8;
  bool _showUndo = false;
  int _lastTappedIndex = -1;

  void _tapGlass(int index) {
    if (index == _waterGlasses) {
      // Tap next glass -> Fill
      setState(() {
        _waterGlasses++;
        _lastTappedIndex = index;
        _showUndo = true;
      });
      _showFeedbackSnackBar("Hidrasi bertambah (+250ml)");
    } else if (index == _waterGlasses - 1) {
      // Tap last filled glass -> Undo/Reduce
      setState(() {
        _waterGlasses--;
        _lastTappedIndex = -1;
        _showUndo = false;
      });
      _showFeedbackSnackBar("Hidrasi dibatalkan (-250ml)");
    }
  }

  void _showFeedbackSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13)),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Profile & Date Section Wireframe
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const WireframeBox(
                    width: 48,
                    height: 48,
                    label: '',
                    icon: Icons.person_outline,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Halo, User! [WIREFRAME]',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: WireframeTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Rabu, 29 Juli 2026',
                        style: TextStyle(
                          fontSize: 12,
                          color: WireframeTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const WireframeBox(
                width: 36,
                height: 36,
                label: '',
                icon: Icons.notifications_none,
                padding: EdgeInsets.zero,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 2. Calorie Summary & Macro Ring Card Skeleton
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WireframeTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WireframeTheme.border, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Ringkasan Nutrisi Harian',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: WireframeTheme.textPrimary,
                      ),
                    ),
                    WireframePillTag(label: 'Target: 2.000 kcal', highContrast: true),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Skeleton Ring Chart
                    const WireframeBox(
                      width: 90,
                      height: 90,
                      label: 'Chart Ring',
                      icon: Icons.pie_chart_outline,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _buildMacroItem('Protein', '85g / 120g', 0.7),
                          const SizedBox(height: 8),
                          _buildMacroItem('Karbo', '150g / 250g', 0.6),
                          const SizedBox(height: 8),
                          _buildMacroItem('Lemak', '40g / 65g', 0.61),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. Water Tracker Interactive Wireframe (Interaksi Mikro & Undo)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WireframeTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WireframeTheme.border, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.water_drop_outlined, color: WireframeTheme.activeHighlight, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Hidrasi Harian (Water Tracker)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: WireframeTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${_waterGlasses * 250} / ${_maxGlasses * 250} ml',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: WireframeTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '💡 Ketuk gelas untuk menambah. Ketuk gelas terisi terakhir untuk membatalkan (Undo).',
                  style: TextStyle(fontSize: 11, color: WireframeTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_maxGlasses, (index) {
                    final bool isFilled = index < _waterGlasses;
                    final bool isLastFilled = index == _waterGlasses - 1;

                    return GestureDetector(
                      onTap: () => _tapGlass(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isFilled ? WireframeTheme.activeHighlight : WireframeTheme.placeholder,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isLastFilled && _showUndo
                                ? WireframeTheme.textPrimary
                                : WireframeTheme.border,
                            width: isLastFilled && _showUndo ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            isFilled ? Icons.water_drop : Icons.water_drop_outlined,
                            size: 18,
                            color: isFilled ? Colors.white : WireframeTheme.textDisabled,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 4. Meal Section Section Wireframes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Jadwal & Catatan Makan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: WireframeTheme.textPrimary,
                ),
              ),
              WireframePillTag(label: '4 Sesi Makan', highContrast: false),
            ],
          ),
          const SizedBox(height: 12),
          _buildMealSectionWireframe('Makan Pagi (Breakfast)', '350 kcal', 'Dada ayam grill + Nasi Merah'),
          const SizedBox(height: 10),
          _buildMealSectionWireframe('Makan Siang (Lunch)', '620 kcal', 'Salad Salmon + Sup Sayur'),
          const SizedBox(height: 10),
          _buildMealSectionWireframe('Makan Malam (Dinner)', 'Belum diisi', null),
          const SizedBox(height: 10),
          _buildMealSectionWireframe('Cemilan (Snack)', '120 kcal', 'Apel Merah'),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: WireframeTheme.textSecondary)),
            Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: WireframeTheme.placeholder,
            valueColor: const AlwaysStoppedAnimation<Color>(WireframeTheme.accentActive),
          ),
        ),
      ],
    );
  }

  Widget _buildMealSectionWireframe(String title, String kcal, String? foodDetail) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WireframeTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WireframeTheme.border, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const WireframeBox(
                width: 36,
                height: 36,
                label: '',
                icon: Icons.restaurant,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: WireframeTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    foodDetail ?? 'Belum ada makanan ditambahkan',
                    style: TextStyle(
                      fontSize: 11,
                      color: foodDetail != null
                          ? WireframeTheme.textSecondary
                          : WireframeTheme.textDisabled,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                kcal,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: WireframeTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Icon(Icons.add_circle_outline, size: 18, color: WireframeTheme.accentActive),
            ],
          ),
        ],
      ),
    );
  }
}
