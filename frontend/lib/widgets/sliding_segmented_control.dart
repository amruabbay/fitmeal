import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fit_meal/main.dart' show FMColors;

class SlidingSegmentedControl extends StatelessWidget {
  final List<String> values;
  final List<String> labels;
  final String selectedValue;
  final Function(String) onChanged;

  const SlidingSegmentedControl({
    super.key,
    required this.values,
    required this.labels,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    int selectedIndex = values.indexOf(selectedValue);

    double alignX = -1.0;
    if (values.length > 1) {
      alignX = -1.0 + (2.0 * selectedIndex / (values.length - 1));
    }

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : const Color(0xFFF1F5F9), // Slate 100 background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? FMColors.borderDark
              : FMColors.borderLight, // Neutral borders from theme
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Sliding indicator
          AnimatedAlign(
            alignment: Alignment(alignX, 0),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 1 / values.length,
              heightFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withOpacity(0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Labels
          Row(
            children: List.generate(values.length, (index) {
              final isSelected = selectedValue == values[index];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(values[index]);
                  },
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? FMColors.subDark
                                : FMColors.subLight),
                      ),
                      child: Text(labels[index]),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
