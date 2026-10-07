import 'package:flutter/material.dart';

class NutrientBadge extends StatelessWidget {
  final String label;
  final String value;
  final MaterialColor color;
  final bool isDark;

  const NutrientBadge({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.15) : color[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? color.withOpacity(0.2) : color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$label ",
              style: TextStyle(
                color: isDark ? color[100] : color[900],
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: isDark ? color[200] : color[800],
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
