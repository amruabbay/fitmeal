import 'package:flutter/material.dart';
import 'package:fit_meal/main.dart' show FMColors;

/// FitMeal High-Fidelity Design Tokens & UI Wireframe Helpers
class WireframeTheme {
  static const Color primary = FMColors.primaryLight; // Emerald #10B981
  static const Color secondary = FMColors.secondary; // #0EA5E9
  static const Color background = FMColors.bgLight; // Slate #F8FAFC
  static const Color surface = FMColors.surfaceLight; // #FFFFFF
  static const Color border = FMColors.borderLight; // #E2E8F0
  static const Color textTitle = FMColors.titleLight; // #0F172A
  static const Color textBody = FMColors.bodyLight; // #334155
  static const Color textSub = FMColors.subLight; // #64748B
  static const Color disabled = Color(0xFFCBD5E1);

  // Macro accents
  static const Color protein = FMColors.proteinColor;
  static const Color carbs = FMColors.carbsColor;
  static const Color fat = FMColors.fatColor;
  static const Color error = FMColors.danger;
}

/// Generic High-Fidelity FitMeal Card Container
class FitMealCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Border? border;
  final double borderRadius;

  const FitMealCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.border,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? WireframeTheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: WireframeTheme.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// High-Fidelity FitMeal Button supporting Normal, Loading, Disabled, & Error States
enum FitMealButtonState { normal, loading, disabled, error }

class FitMealButton extends StatelessWidget {
  final String label;
  final FitMealButtonState state;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isFullWidth;
  final Color? color;

  const FitMealButton({
    super.key,
    required this.label,
    this.state = FitMealButtonState.normal,
    this.onPressed,
    this.icon,
    this.isFullWidth = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = state == FitMealButtonState.disabled;
    final bool isLoading = state == FitMealButtonState.loading;
    final bool isError = state == FitMealButtonState.error;

    final baseColor = color ?? WireframeTheme.primary;

    Color bg;
    Color fg;

    if (isDisabled) {
      bg = const Color(0xFFE2E8F0);
      fg = const Color(0xFF94A3B8);
    } else if (isError) {
      bg = WireframeTheme.error;
      fg = Colors.white;
    } else if (isLoading) {
      bg = baseColor.withOpacity(0.85);
      fg = Colors.white;
    } else {
      bg = baseColor;
      fg = Colors.white;
    }

    Widget content;

    if (isLoading) {
      content = const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      );
    }

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (isDisabled || isLoading) ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: content),
        ),
      ),
    );

    return isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// High Contrast FitMeal Badge / Pill Tag
class FitMealBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const FitMealBadge({
    super.key,
    required this.label,
    this.backgroundColor = const Color(0xFFECFDF5),
    this.textColor = const Color(0xFF047857),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
