import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/formatting.dart';
import '../../core/prefs/week_start_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import '../home/providers/home_providers.dart';
import 'activity_providers.dart';

/// Aktivite Takvimi (docs/10-activity-calendar.md) — İlerleme sekmesi.
/// Aylık takvim; her günde 4 eş-merkezli halka (Kalori/Protein/Antrenman/Su).
/// Güne dokun → gün özeti alt paneli.
class ActivityCalendar extends ConsumerStatefulWidget {
  const ActivityCalendar({super.key});

  @override
  ConsumerState<ActivityCalendar> createState() => _ActivityCalendarState();
}

class _ActivityCalendarState extends ConsumerState<ActivityCalendar> {
  late DateTime _month; // gösterilen ayın ilk günü

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta, 1));
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  ({int kcal, int protein, int water}) _goals() {
    final p = ref.watch(userProfileProvider).valueOrNull;
    return (
      kcal: p?.kcalGoal ?? 2200,
      protein: p?.proteinGoal ?? 180,
      water: p?.waterGoalMl ?? 2500,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activityAsync = ref.watch(monthActivityProvider(_month));
    final goals = _goals();
    final weekStart = ref.watch(weekStartProvider);
    final monthLabel = context.dateFmt('MMMM yyyy').format(_month);
    final cap = monthLabel[0].toUpperCase() + monthLabel.substring(1);

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ay başlığı + gezinme
            Row(
              children: [
                Text(AppL10n.of(context).actTitle,
                    style: context.texts.titleMedium),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => _shiftMonth(-1),
                ),
                Text(cap,
                    style: context.texts.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_right_rounded),
                  // gelecek aya geçişi engelle
                  onPressed: _isCurrentMonth ? null : () => _shiftMonth(1),
                ),
              ],
            ),
            AppSpacing.vGapSm,
            _WeekdayLabels(weekStart: weekStart),
            AppSpacing.vGapXs,
            activityAsync.when(
              loading: () => const SizedBox(
                  height: 240,
                  child: Center(child: CircularProgressIndicator())),
              error: (_, _) => SizedBox(
                height: 120,
                child: Center(
                  child: Text(AppL10n.of(context).actLoadError,
                      style: context.texts.bodySmall),
                ),
              ),
              data: (activity) => _MonthGrid(
                month: _month,
                activity: activity,
                weekStart: weekStart,
                kcalGoal: goals.kcal,
                proteinGoal: goals.protein,
                waterGoal: goals.water,
                onTapDay: (day, act) =>
                    _showDaySummary(context, day, act),
              ),
            ),
            AppSpacing.vGapSm,
            const _RingLegend(),
          ],
        ),
      ),
    );
  }

  void _showDaySummary(BuildContext context, DateTime day, DayActivity? act) {
    final goals = _goals();
    // Kök navigator (C-1): sekme içinden açılınca alt çubuğun arkasında kalmasın.
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (_) => _DaySummarySheet(
        day: day,
        activity: act,
        kcalGoal: goals.kcal,
        proteinGoal: goals.protein,
        waterGoal: goals.water,
      ),
    );
  }
}

// ───────────────────────────────────────────── Hafta günü başlıkları

class _WeekdayLabels extends StatelessWidget {
  final int weekStart;
  const _WeekdayLabels({required this.weekStart});

  @override
  Widget build(BuildContext context) {
    // Adlar locale'den (docs/14); sıra hafta başı tercihine göre (docs/16).
    final days = [
      for (var i = 0; i < 7; i++)
        context.weekdayShort((weekStart - 1 + i) % 7 + 1)
    ];
    return Row(
      children: days
          .map((d) => Expanded(
                child: Center(
                  child: Text(d,
                      style: context.texts.labelSmall?.copyWith(
                          color: context.colors.onSurfaceVariant
                              .withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600)),
                ),
              ))
          .toList(),
    );
  }
}

// ───────────────────────────────────────────── Ay ızgarası

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final Map<int, DayActivity> activity;
  final int weekStart;
  final int kcalGoal, proteinGoal, waterGoal;
  final void Function(DateTime day, DayActivity? act) onTapDay;
  const _MonthGrid({
    required this.month,
    required this.activity,
    required this.weekStart,
    required this.kcalGoal,
    required this.proteinGoal,
    required this.waterGoal,
    required this.onTapDay,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;
    // Ayın 1'i, hafta başı tercihine göre kaçıncı sütuna düşer (0..6).
    final leadingBlanks = (firstWeekday - weekStart) % 7;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final cells = <Widget>[];
    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final isFuture = date.isAfter(today);
      final isToday = date == today;
      final act = activity[day];
      cells.add(_DayCell(
        day: day,
        activity: act,
        kcalGoal: kcalGoal,
        proteinGoal: proteinGoal,
        waterGoal: waterGoal,
        isToday: isToday,
        isFuture: isFuture,
        onTap: isFuture ? null : () => onTapDay(date, act),
      ));
    }

    return GridView.count(
      // Sıfır padding (C-7 ile aynı kök): verilmezse iç ızgara buzlu alt
      // çubuğun yüksekliğini kendi altına ekliyor → takvimin altında boşluk.
      padding: EdgeInsets.zero,
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 2,
      children: cells,
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final DayActivity? activity;
  final int kcalGoal, proteinGoal, waterGoal;
  final bool isToday, isFuture;
  final VoidCallback? onTap;
  const _DayCell({
    required this.day,
    required this.activity,
    required this.kcalGoal,
    required this.proteinGoal,
    required this.waterGoal,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
  });

  double _p(double v, num goal) =>
      goal <= 0 ? 0 : (v / goal).clamp(0, 1).toDouble();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.semantic;
    final a = activity;
    final progresses = a == null
        ? const [0.0, 0.0, 0.0, 0.0]
        : [
            _p(a.kcal, kcalGoal),
            _p(a.protein, proteinGoal),
            a.hasWorkout ? 1.0 : 0.0,
            _p(a.waterMl.toDouble(), waterGoal),
          ];

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brSm,
      child: Opacity(
        opacity: isFuture ? 0.35 : 1,
        child: CustomPaint(
          painter: _RingsPainter(
            progresses: progresses,
            colors: [s.macroCalories, s.macroProtein, s.success, s.info],
            track: c.onSurface.withValues(alpha: 0.08),
            show: !isFuture,
          ),
          child: Center(
            child: Container(
              width: 22,
              height: 22,
              decoration: isToday
                  ? BoxDecoration(
                      color: c.primary.withValues(alpha: 0.14),
                      shape: BoxShape.circle)
                  : null,
              alignment: Alignment.center,
              child: Text('$day',
                  style: context.texts.labelSmall?.copyWith(
                    color: isToday ? c.primary : c.onSurface,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                  )),
            ),
          ),
        ),
      ),
    );
  }
}

/// 4 eş-merkezli halka çizen painter. progresses[i] ∈ [0,1].
class _RingsPainter extends CustomPainter {
  final List<double> progresses;
  final List<Color> colors;
  final Color track;
  final bool show;
  _RingsPainter({
    required this.progresses,
    required this.colors,
    required this.track,
    required this.show,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!show) return;
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) / 2 - 1;
    const stroke = 2.6;
    const gap = 1.6;
    const startAngle = -math.pi / 2; // tepeden başla

    for (var i = 0; i < 4; i++) {
      final r = maxR - i * (stroke + gap);
      if (r <= 0) continue;
      final rect = Rect.fromCircle(center: center, radius: r);
      // track
      final trackPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = track;
      canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);
      // ilerleme
      final p = progresses[i].clamp(0.0, 1.0);
      if (p > 0) {
        final pPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = colors[i];
        canvas.drawArc(rect, startAngle, 2 * math.pi * p, false, pPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.progresses != progresses ||
      old.colors != colors ||
      old.show != show;
}

// ───────────────────────────────────────────── Halka açıklaması

class _RingLegend extends StatelessWidget {
  const _RingLegend();

  @override
  Widget build(BuildContext context) {
    final s = context.semantic;
    Widget dot(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(label,
                style: context.texts.labelSmall
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        );
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        dot(s.macroCalories, AppL10n.of(context).macroCalories),
        dot(s.macroProtein, AppL10n.of(context).macroProtein),
        dot(s.success, AppL10n.of(context).navWorkout),
        dot(s.info, AppL10n.of(context).homeWaterTitle),
      ],
    );
  }
}

// ───────────────────────────────────────────── Gün özeti alt paneli

class _DaySummarySheet extends StatelessWidget {
  final DateTime day;
  final DayActivity? activity;
  final int kcalGoal, proteinGoal, waterGoal;
  const _DaySummarySheet({
    required this.day,
    required this.activity,
    required this.kcalGoal,
    required this.proteinGoal,
    required this.waterGoal,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final title = context.dateFmt('d MMMM, EEEE').format(day);
    final a = activity;
    final s = context.semantic;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.texts.titleMedium),
            AppSpacing.vGapLg,
            if (a == null || a.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(l.actNoEntry,
                    style: context.texts.bodyMedium
                        ?.copyWith(color: context.colors.onSurfaceVariant)),
              )
            else ...[
              // Beslenme
              _SummaryRow(
                color: s.macroCalories,
                label: l.macroCalories,
                value: '${a.kcal.round()} / $kcalGoal kcal',
              ),
              _SummaryRow(
                color: s.macroProtein,
                label: l.macroProtein,
                value: '${a.protein.round()} / $proteinGoal g',
              ),
              _SummaryRow(
                color: s.macroCarbs,
                label: l.macroCarbs,
                value: '${a.carb.round()} g',
              ),
              _SummaryRow(
                color: s.macroFat,
                label: l.macroFat,
                value: '${a.fat.round()} g',
              ),
              const Divider(height: AppSpacing.xl),
              // Antrenman
              _SummaryRow(
                color: s.success,
                label: l.navWorkout,
                value: a.hasWorkout
                    ? '${a.workoutName ?? l.navWorkout} · ${l.workoutSetCount(a.setCount)} · ${a.volumeKg} kg'
                    : l.commonNone,
              ),
              // Su
              _SummaryRow(
                color: s.info,
                label: l.homeWaterTitle,
                value:
                    '${(a.waterMl / 1000).toStringAsFixed(1)} / ${(waterGoal / 1000).toStringAsFixed(1)} L',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final Color color;
  final String label, value;
  const _SummaryRow(
      {required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 1),
      child: Row(
        children: [
          Container(
              width: 9,
              height: 9,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          AppSpacing.hGapMd,
          Text(label, style: context.texts.bodyMedium),
          const Spacer(),
          Text(value,
              style: context.texts.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
