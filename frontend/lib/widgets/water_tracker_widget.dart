import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fit_meal/main.dart' show FMColors;

class WaterTrackerWidget extends StatefulWidget {
  final int currentGlasses;
  final int maxGlasses;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const WaterTrackerWidget({
    super.key,
    required this.currentGlasses,
    this.maxGlasses = 8,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<WaterTrackerWidget> createState() => _WaterTrackerWidgetState();
}

class _WaterTrackerWidgetState extends State<WaterTrackerWidget>
    with TickerProviderStateMixin {
  // Debounce protection against accidental double-taps
  bool _isProcessing = false;

  // Pop animation for the last changed glass
  int? _lastAnimatedIndex;
  AnimationController? _popController;
  late Animation<double> _popAnimation;

  @override
  void initState() {
    super.initState();
    _initPopAnimation();
  }

  void _initPopAnimation() {
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _popAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_popController!);
  }

  @override
  void dispose() {
    _popController?.dispose();
    super.dispose();
  }

  /// Handles add with debounce protection and pop animation
  void _handleAdd() async {
    if (_isProcessing) return;
    if (widget.currentGlasses >= widget.maxGlasses) return;

    setState(() => _isProcessing = true);
    HapticFeedback.lightImpact();

    // Trigger pop animation on the glass that will become filled
    setState(() => _lastAnimatedIndex = widget.currentGlasses);
    _popController?.forward(from: 0.0);

    widget.onAdd();

    // Debounce: wait 300ms before allowing next tap
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  /// Handles remove with debounce protection and pop animation
  void _handleRemove() async {
    if (_isProcessing) return;
    if (widget.currentGlasses <= 0) return;

    setState(() => _isProcessing = true);
    HapticFeedback.lightImpact();

    // Trigger pop animation on the glass that will become unfilled
    setState(() => _lastAnimatedIndex = widget.currentGlasses - 1);
    _popController?.forward(from: 0.0);

    widget.onRemove();

    // Debounce: wait 300ms before allowing next tap
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? FMColors.titleDark : FMColors.titleLight;
    final subColor   = isDark ? FMColors.subDark   : FMColors.subLight;
    const waterColor = FMColors.info; // sky blue
    final pct = widget.maxGlasses > 0 ? widget.currentGlasses / widget.maxGlasses : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? FMColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? FMColors.borderDark : FMColors.borderLight,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Header ----
          Row(
            children: [
              // Icon container
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      waterColor.withOpacity(0.2),
                      waterColor.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: waterColor.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: waterColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hidrasi Harian",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      "Target ${widget.maxGlasses} gelas · 2 liter",
                      style: TextStyle(
                        fontSize: 12,
                        color: subColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Circular progress badge
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: pct),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (_, val, __) => CircularProgressIndicator(
                        value: val,
                        strokeWidth: 4,
                        backgroundColor: waterColor.withOpacity(0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(waterColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  ),
                  Text(
                    "${widget.currentGlasses}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: waterColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ---- Glass indicators with pop animation ----
          Row(
            children: [
              // Minus button
              _CircleButton(
                icon: Icons.remove_rounded,
                enabled: widget.currentGlasses > 0 && !_isProcessing,
                color: waterColor,
                isDark: isDark,
                onTap: _handleRemove,
              ),
              const SizedBox(width: 10),
              // Glass squares
              Expanded(
                child: Row(
                  children: List.generate(widget.maxGlasses, (i) {
                    final filled = i < widget.currentGlasses;
                    final isAnimating = i == _lastAnimatedIndex;

                    Widget glassWidget = AnimatedContainer(
                      duration: Duration(milliseconds: 180 + (i * 30)),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: filled
                            ? const LinearGradient(
                                colors: [FMColors.info, Color(0xFF38BDF8)],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              )
                            : null,
                        color: filled
                            ? null
                            : (isDark
                                ? Colors.white.withOpacity(0.05)
                                : const Color(0xFFE0F2FE)),
                        borderRadius: BorderRadius.circular(10),
                        border: filled
                            ? null
                            : Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : const Color(0xFFBAE6FD),
                                width: 1,
                              ),
                      ),
                      child: filled
                          ? const Center(
                              child: Icon(Icons.water_drop_rounded,
                                  size: 14, color: Colors.white))
                          : null,
                    );

                    // Apply pop animation to the last changed glass
                    if (isAnimating && _popController != null) {
                      glassWidget = AnimatedBuilder(
                        animation: _popAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _popAnimation.value,
                            child: child,
                          );
                        },
                        child: glassWidget,
                      );
                    }

                    return Expanded(child: glassWidget);
                  }),
                ),
              ),
              const SizedBox(width: 10),
              // Plus button
              _CircleButton(
                icon: Icons.add_rounded,
                enabled: widget.currentGlasses < widget.maxGlasses && !_isProcessing,
                color: waterColor,
                isDark: isDark,
                filled: true,
                onTap: _handleAdd,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ---- Progress bar ----
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: pct),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                minHeight: 5,
                backgroundColor: waterColor.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(waterColor),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.currentGlasses >= widget.maxGlasses
                ? "Target hidrasi tercapai! 🎯"
                : "${widget.maxGlasses - widget.currentGlasses} gelas lagi untuk mencapai target",
            style: TextStyle(
              fontSize: 11,
              color: widget.currentGlasses >= widget.maxGlasses ? waterColor : subColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatefulWidget {
  final IconData icon;
  final bool enabled;
  final Color color;
  final bool isDark;
  final bool filled;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.enabled,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.filled = false,
  });

  @override
  State<_CircleButton> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<_CircleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Premium contrasting design tokens
    final BoxBorder border;
    final List<BoxShadow> shadows;
    final Color iconColor;
    final Gradient? gradient;
    final Color? bgColor;

    if (widget.enabled) {
      if (widget.filled) {
        // Vibrant filled button (e.g. Plus button)
        gradient = const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        bgColor = null;
        border = Border.all(color: const Color(0xFF0EA5E9), width: 1);
        shadows = [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(widget.isDark ? 0.35 : 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ];
        iconColor = Colors.white;
      } else {
        // High-contrast outlined button (e.g. Minus button)
        gradient = null;
        bgColor = widget.isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
        border = Border.all(
          color: widget.isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
          width: 1.5,
        );
        shadows = [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.15 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ];
        iconColor = widget.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
      }
    } else {
      // Disabled button style
      gradient = null;
      bgColor = widget.isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF8FAFC);
      border = Border.all(
        color: widget.isDark ? const Color(0xFF334155).withOpacity(0.3) : const Color(0xFFE2E8F0),
        width: 1,
      );
      shadows = [];
      iconColor = widget.isDark ? Colors.white.withOpacity(0.15) : Colors.grey.withOpacity(0.35);
    }

    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onTap();
            }
          : null,
      onTapCancel: widget.enabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_isPressed ? 0.88 : 1.0),
        transformAlignment: Alignment.center,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bgColor,
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          border: border,
          boxShadow: shadows,
        ),
        child: Icon(
          widget.icon,
          size: 18,
          color: iconColor,
        ),
      ),
    );
  }
}
