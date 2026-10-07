import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fit_meal/providers/language_provider.dart';
import 'package:fit_meal/config/app_strings.dart';

class MacroRingChart extends StatelessWidget {
  final double consumed;
  final double target;
  final Color color;
  final String label;
  final double size;

  const MacroRingChart({
    super.key,
    required this.consumed,
    required this.target,
    required this.color,
    this.label = '',
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = Provider.of<LanguageProvider>(context).locale;
    final percentage = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final double remainingCal = (target - consumed).clamp(0.0, target).toDouble();
    final isOver = consumed > target;
    final effectiveColor = isOver ? const Color(0xFFEF4444) : color;

    final strokeWidth = size * 0.075;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft outer glow
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: effectiveColor.withOpacity(isDark ? 0.12 : 0.15),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

          // Custom painted ring
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: percentage),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, animatedPct, _) {
              return CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  percentage: animatedPct,
                  color: isOver ? const Color(0xFFEF4444) : color,
                  strokeWidth: strokeWidth,
                  isDark: isDark,
                ),
              );
            },
          ),

          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Big number
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: remainingCal),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return Text(
                    "${value.toInt()}",
                    style: TextStyle(
                      fontSize: size * 0.17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      height: 1,
                      letterSpacing: -1,
                    ),
                  );
                },
              ),
              const SizedBox(height: 2),
              Text(
                label.isNotEmpty ? label : AppStrings.get('kkal', lang),
                style: TextStyle(
                  fontSize: size * 0.065,
                  color: isDark
                      ? Colors.white.withOpacity(0.5)
                      : const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              // Subtle status text
              Text(
                isOver ? AppStrings.get('exceeded_over', lang) : AppStrings.get('remaining_over', lang),
                style: TextStyle(
                  fontSize: size * 0.05,
                  fontWeight: FontWeight.w700,
                  color: isOver
                      ? const Color(0xFFEF4444).withOpacity(0.8)
                      : color.withOpacity(0.7),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom ring painter with rounded stroke caps and gradient
class _RingPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final double strokeWidth;
  final bool isDark;

  _RingPainter({
    required this.percentage,
    required this.color,
    required this.strokeWidth,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track
    final bgPaint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.06)
          : color.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (percentage <= 0) return;

    // Foreground arc with gradient
    final sweepAngle = 2 * math.pi * percentage;
    const startAngle = -math.pi / 2;

    final gradientPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [
          color.withOpacity(0.5),
          color,
        ],
        stops: const [0.0, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);

    canvas.drawArc(rect, startAngle, sweepAngle, false, gradientPaint);

    // Glow dot at the tip
    if (percentage > 0.02) {
      final tipAngle = startAngle + sweepAngle;
      final tipX = center.dx + radius * math.cos(tipAngle);
      final tipY = center.dy + radius * math.sin(tipAngle);

      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(Offset(tipX, tipY), strokeWidth * 0.6, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark;
  }
}

// ==========================================================
// MACRO PROGRESS BAR — horizontal animated bar per nutrient
// ==========================================================
class MacroProgressBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final double consumed;
  final double target;
  final Color color;
  final String unit;

  const MacroProgressBar({
    super.key,
    required this.label,
    required this.icon,
    required this.consumed,
    required this.target,
    required this.color,
    this.unit = 'g',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentage = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final titleColor = isDark ? const Color(0xFFFFF7ED) : const Color(0xFF1C0A00);
    final subColor   = isDark ? const Color(0xFFFED7AA) : const Color(0xFF78350F);
    final isOver = consumed > target;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.12 : 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icon container
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: consumed),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "${value.toInt()}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isOver ? const Color(0xFFEF4444) : color,
                          ),
                        ),
                        TextSpan(
                          text: " / ${target.toInt()}$unit",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: subColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar with rounded gradient fill
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: percentage),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Stack(
                  children: [
                    // Background track
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // Filled gradient bar
                    FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isOver
                                ? [const Color(0xFFFCA5A5), const Color(0xFFEF4444)]
                                : [color.withOpacity(0.6), color],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
