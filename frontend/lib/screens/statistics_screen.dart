import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fit_meal/main.dart' show FMColors;
import 'package:fit_meal/models/daily_log.dart';
import 'package:fit_meal/providers/daily_log_provider.dart';
import 'package:fit_meal/providers/language_provider.dart';
import 'package:fit_meal/config/app_strings.dart';
import 'package:fit_meal/widgets/tactile_scale_effect.dart';


class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});
  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<DailyLog> _weeklyLogs = [];
  bool _isLoading = true;

  late DailyLogProvider _dailyLogProvider;

  @override
  void initState() {
    super.initState();
    _dailyLogProvider = Provider.of<DailyLogProvider>(context, listen: false);
    _loadData();
    // Re-load data whenever the daily log provider changes (targets, food, etc.)
    _dailyLogProvider.addListener(_loadData);
  }

  @override
  void dispose() {
    _dailyLogProvider.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<DailyLogProvider>(context, listen: false);
    final logs = await provider.getWeeklyLogs();
    if (mounted) {
      setState(() {
        _weeklyLogs = logs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? FMColors.titleDark : FMColors.titleLight;
    final subColor   = isDark ? FMColors.subDark   : FMColors.subLight;
    final primary = Theme.of(context).primaryColor;
    final lang = Provider.of<LanguageProvider>(context).locale;

    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    // Calculate stats
    final totalCalories =
        _weeklyLogs.fold<double>(0, (sum, log) => sum + log.totalCalories);
    final avgCalories =
        _weeklyLogs.isNotEmpty ? totalCalories / _weeklyLogs.length : 0.0;
    final totalProtein =
        _weeklyLogs.fold<double>(0, (sum, log) => sum + log.totalProtein);
    final avgProtein =
        _weeklyLogs.isNotEmpty ? totalProtein / _weeklyLogs.length : 0.0;
    final double targetCalories =
        _weeklyLogs.isNotEmpty ? _weeklyLogs.last.targetCalories : 2000.0;

    // Best day
    double bestCompliance = 0;
    String bestDay = "-";
    for (final log in _weeklyLogs) {
      if (log.totalCalories > 0) {
        final compliance = log.targetCalories > 0
            ? (log.totalCalories / log.targetCalories)
            : 0.0;
        final distance = (1.0 - compliance).abs();
        if (bestCompliance == 0 || distance < (1.0 - bestCompliance).abs()) {
          bestCompliance = compliance;
          final date = DateTime.tryParse(log.date);
          if (date != null) {
            bestDay = DateFormat('EEEE', lang == 'en' ? 'en_US' : 'id_ID').format(date);
          }
        }
      }
    }

    final activeDays =
        _weeklyLogs.where((log) => log.totalCalories > 0).length;

    // Date range text
    String dateRange = "";
    if (_weeklyLogs.isNotEmpty) {
      final first = DateTime.tryParse(_weeklyLogs.first.date);
      final last = DateTime.tryParse(_weeklyLogs.last.date);
      if (first != null && last != null) {
        final dateLocale = lang == 'en' ? 'en_US' : 'id_ID';
        dateRange =
            "${AppStrings.get('from_to', lang)} ${DateFormat('EEEE', dateLocale).format(first)} ${AppStrings.get('until', lang)} ${DateFormat('EEEE', dateLocale).format(last)}";
      }
    }

    // Generate insight text
    final insightText = _generateInsight(
        avgCalories, targetCalories, activeDays, bestDay, lang);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==============================
            // HEADER
            // ==============================
            Text(
              AppStrings.get('weekly_stats', lang),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateRange.isNotEmpty
                  ? dateRange
                  : AppStrings.get('your_performance', lang),
              style: TextStyle(fontSize: 13, color: subColor),
            ),
            const SizedBox(height: 20),

            // ==============================
            // 4 SUMMARY CARDS (2×2)
            // ==============================
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    "AVG CALORIES",
                    "${avgCalories.toInt()}",
                    AppStrings.get('kkal_per_day', lang),
                    Icons.local_fire_department_rounded,
                    primary,
                    isDark,
                    titleColor,
                    subColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    "AVG PROTEIN",
                    "${avgProtein.toInt()}",
                    AppStrings.get('g_per_day', lang),
                    Icons.fitness_center_rounded,
                    FMColors.proteinColor,
                    isDark,
                    titleColor,
                    subColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    AppStrings.get('active_days', lang),
                    "$activeDays",
                    AppStrings.get('of_7_days', lang),
                    Icons.calendar_today_rounded,
                    FMColors.carbsColor,
                    isDark,
                    titleColor,
                    subColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    AppStrings.get('best_day', lang),
                    bestDay,
                    bestCompliance > 0
                        ? "${(bestCompliance * 100).toInt()}% ${AppStrings.get('target', lang)}"
                        : AppStrings.get('not_yet', lang),
                    Icons.star_rounded,
                    FMColors.fatColor,
                    isDark,
                    titleColor,
                    subColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ============================== BAR CHART
            // ==============================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? FMColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? FMColors.borderDark : FMColors.borderLight,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.get('daily_calories', lang),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppStrings.get('weekly_energy', lang),
                            style: TextStyle(
                              fontSize: 12,
                              color: subColor,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                      // Target badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "TARGET: ${targetCalories.toInt()}\nKCAL",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: primary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Chart
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: targetCalories * 1.3,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem:
                                (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                "${rod.toY.toInt()} kkal",
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 &&
                                    index < _weeklyLogs.length) {
                                  final date = DateTime.tryParse(
                                      _weeklyLogs[index].date);
                                  if (date != null) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        DateFormat('E', lang == 'en' ? 'en_US' : 'id_ID').format(date),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: subColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: targetCalories / 2,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: isDark
                                ? Colors.white.withOpacity(0.04)
                                : const Color(0xFFE2E8F0),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: targetCalories,
                              color: primary.withOpacity(0.4),
                              strokeWidth: 2,
                              dashArray: [8, 4],
                              label: HorizontalLineLabel(
                                show: true,
                                alignment: Alignment.topRight,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                labelResolver: (_) => AppStrings.get('goal_baseline', lang),
                              ),
                            ),
                          ],
                        ),
                        barGroups: List.generate(
                            _weeklyLogs.length, (index) {
                          final log = _weeklyLogs[index];
                          final cal = log.totalCalories;
                          final isToday = index == _weeklyLogs.length - 1;

                          LinearGradient? barGradient;
                          Color? barColorFallback;
                          if (cal == 0) {
                            barColorFallback = isDark
                                ? Colors.white.withOpacity(0.06)
                                : const Color(0xFFE2E8F0);
                          } else if (cal <= targetCalories) {
                            barGradient = LinearGradient(
                              colors: [primary.withOpacity(0.65), primary],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            );
                          } else {
                            barGradient = const LinearGradient(
                              colors: [FMColors.fatColor, Color(0xFFEA580C)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            );
                          }

                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: cal > 0
                                    ? cal
                                    : targetCalories * 0.03,
                                color: barGradient == null ? barColorFallback : null,
                                gradient: barGradient,
                                width: isToday ? 20 : 14,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6)),
                                backDrawRodData:
                                    BackgroundBarChartRodData(
                                  show: true,
                                  toY: targetCalories,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.03)
                                      : FMColors.borderLight,
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==============================
            // WEEKLY INSIGHT CARD
            // ==============================
            TactileScaleEffect(
              scaleDownTo: 0.98,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: 5,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF0EA5E9), Color(0xFF3B82F6)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [const Color(0xFF0E5A7A), const Color(0xFF073D54)]
                                      : [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0EA5E9).withOpacity(isDark ? 0.3 : 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 22,
                                color: Color(0xFF0EA5E9),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Weekly Insight",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: titleColor,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    insightText,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                      height: 1.6,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),


            const SizedBox(height: 16),

            // ==============================
            // HEALTH TIP CARD
            // ==============================
            TactileScaleEffect(
              scaleDownTo: 0.98,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF0F2E22), const Color(0xFF0F172A)]
                          : [const Color(0xFFECFDF5), const Color(0xFFF9FDFB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF065F46).withOpacity(0.5) : const Color(0xFFA7F3D0),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(isDark ? 0.08 : 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF10B981).withOpacity(isDark ? 0.06 : 0.08),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.lightbulb_outline_rounded,
                                        size: 14,
                                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        AppStrings.get('health_tip', lang),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.spa_rounded,
                                  size: 16,
                                  color: const Color(0xFF10B981).withOpacity(0.4),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _getHealthTip(activeDays, lang),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        AppStrings.get('read_guide', lang),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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

  // ==============================
  // STAT CARD
  // ==============================
  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    bool isDark,
    Color titleColor,
    Color subColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? FMColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? FMColors.borderDark : FMColors.borderLight,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: subColor,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: subColor,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================
  // INSIGHT GENERATOR
  // ==============================
  String _generateInsight(
      double avgCal, double target, int activeDays, String bestDay, String lang) {
    if (activeDays == 0) {
      return AppStrings.get('insight_no_data', lang);
    }

    final ratio = target > 0 ? avgCal / target : 0.0;
    final buffer = StringBuffer();

    if (ratio < 0.5) {
      buffer.write(AppStrings.get('insight_far_below', lang));
    } else if (ratio < 0.8) {
      buffer.write(AppStrings.get('insight_close', lang));
    } else if (ratio <= 1.1) {
      buffer.write(AppStrings.get('insight_great', lang));
    } else {
      buffer.write(AppStrings.get('insight_over', lang));
    }

    if (bestDay != "-") {
      buffer.write("$bestDay${AppStrings.get('insight_best_day', lang)}");
    }

    if (activeDays < 4) {
      buffer.write(AppStrings.get('insight_improve', lang));
    } else {
      buffer.write(AppStrings.get('insight_keep_up', lang));
    }

    return buffer.toString();
  }

  String _getHealthTip(int activeDays, String lang) {
    if (activeDays <= 2) {
      return AppStrings.get('health_tip_low', lang);
    } else if (activeDays <= 5) {
      return AppStrings.get('health_tip_mid', lang);
    } else {
      return AppStrings.get('health_tip_high', lang);
    }
  }
}
