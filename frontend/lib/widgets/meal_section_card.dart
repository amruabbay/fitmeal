import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fit_meal/main.dart' show FMColors;
import 'package:fit_meal/models/food_item.dart';
import 'package:fit_meal/widgets/tactile_scale_effect.dart';

class MealSectionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<FoodItem> items;
  final VoidCallback onAddPressed;
  final Function(int) onRemoveItem;

  const MealSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.items,
    required this.onAddPressed,
    required this.onRemoveItem,
  });

  double get totalCalories =>
      items.fold(0, (sum, item) => sum + item.calories);

  String get _suggestedRange {
    switch (title.toLowerCase()) {
      case 'sarapan':
        return '450–600 kkal';
      case 'makan siang':
        return '700–900 kkal';
      case 'makan malam':
        return '600–800 kkal';
      case 'cemilan':
        return '200–300 kkal';
      default:
        return '';
    }
  }

  @override
  State<MealSectionCard> createState() => _MealSectionCardState();
}

class _MealSectionCardState extends State<MealSectionCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    HapticFeedback.selectionClick();
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? FMColors.titleDark : FMColors.titleLight;
    final subColor   = isDark ? FMColors.subDark   : FMColors.subLight;
    final accent = widget.accentColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? FMColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? FMColors.borderDark : FMColors.borderLight,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // ---- Left accent bar + header ----
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent bar
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withOpacity(0.4)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Header content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                      child: Row(
                        children: [
                          // Icon box
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accent.withOpacity(0.15),
                                  accent.withOpacity(0.06),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: accent.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Icon(widget.icon, color: accent, size: 22),
                          ),
                          const SizedBox(width: 12),
                          // Title + range
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: titleColor,
                                  ),
                                ),
                                if (widget._suggestedRange.isNotEmpty)
                                  Text(
                                    widget._suggestedRange,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: subColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Calories + expand toggle
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (widget.items.isNotEmpty)
                                Text(
                                  "${widget.totalCalories.toInt()} kkal",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: accent,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Add button
                                  TactileScaleEffect(
                                    scaleDownTo: 0.90,
                                    child: GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        widget.onAddPressed();
                                      },
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [accent, accent.withOpacity(0.8)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.add_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Expand toggle
                                  TactileScaleEffect(
                                    scaleDownTo: 0.90,
                                    enabled: widget.items.isNotEmpty,
                                    child: GestureDetector(
                                      onTap: widget.items.isNotEmpty ? _toggleExpand : null,
                                      child: AnimatedRotation(
                                        duration: const Duration(milliseconds: 280),
                                        turns: _expanded ? 0 : 0.5,
                                        child: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 20,
                                          color: widget.items.isNotEmpty
                                              ? subColor
                                              : subColor.withOpacity(0.3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ---- Collapsible Items List ----
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Column(
                children: [
                  if (widget.items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline_rounded,
                              size: 14, color: subColor.withOpacity(0.5)),
                          const SizedBox(width: 6),
                          Text(
                            "Belum ada makanan — ketuk + untuk menambah",
                            style: TextStyle(
                              fontSize: 12,
                              color: subColor.withOpacity(0.6),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: accent.withOpacity(isDark ? 0.1 : 0.08),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
                      child: Column(
                        children: List.generate(widget.items.length, (index) {
                          final food = widget.items[index];
                          return Dismissible(
                            key: ValueKey('${food.name}_$index'),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => widget.onRemoveItem(index),
                            background: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFCA5A5), Color(0xFFEF4444)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              child: const Icon(Icons.delete_rounded,
                                  color: Colors.white),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  // Accent dot
                                  Container(
                                    width: 4,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          accent.withOpacity(0.6),
                                          accent.withOpacity(0.1),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          food.name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: titleColor,
                                          ),
                                        ),
                                        Text(
                                          "P: ${food.protein.toStringAsFixed(0)}g · K: ${food.carbs.toStringAsFixed(0)}g · L: ${food.fat.toStringAsFixed(0)}g",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: subColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Calorie badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "${food.calories.toInt()}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: accent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  TactileScaleEffect(
                                    scaleDownTo: 0.88,
                                    child: GestureDetector(
                                      onTap: () => widget.onRemoveItem(index),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 14,
                                          color: subColor.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
