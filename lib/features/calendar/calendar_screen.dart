import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/formatting.dart';
import '../../core/prefs/week_start_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/glass.dart';
import '../activity/activity_providers.dart';
import 'calendar_day_cell.dart';
import 'calendar_logic.dart';
import 'day_records.dart';

/// Takvim — ay görünümü (docs/24 §2). Ana sayfa şeridinin başlığından açılır.
///
/// Aylar oklarla gezilir (gelecek ay yok); güne dokununca o günün kayıtları
/// altta görünür. Seçili gün bugün değilse "Bugüne dön". Bu ekran yalnız
/// okur — ana sayfadaki bugünün eylemine dokunmaz.
class CalendarScreen extends ConsumerStatefulWidget {
  /// Açılışta seçili gün (şeritteki haftadan gelir); yoksa bugün.
  final DateTime? initialDate;

  /// Testler için "şimdi"; verilmezse gerçek saat.
  final DateTime? now;

  const CalendarScreen({super.key, this.initialDate, this.now});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selected;
  late DateTime _month; // gösterilen ayın ilk günü

  DateTime get _now => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    final now = _now;
    final init = widget.initialDate;
    // Gelecekten bir gün istenirse (bozuk bağlantı) bugüne düş.
    _selected = dateOnly(init == null || isFutureDay(init, now) ? now : init);
    _month = DateTime(_selected.year, _selected.month, 1);
  }

  bool get _isCurrentMonth =>
      _month.year == _now.year && _month.month == _now.month;

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta, 1));

  void _backToToday() {
    final now = _now;
    setState(() {
      _selected = dateOnly(now);
      _month = DateTime(now.year, now.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.colors;
    final now = _now;
    final weekStart = ref.watch(weekStartProvider);
    final async = ref.watch(monthActivityProvider(_month));
    final activity = async.valueOrNull ?? const <int, DayActivity>{};

    final monthTitle = _cap(context.dateFmt('MMMM yyyy').format(_month));
    final selectedInMonth = _selected.year == _month.year &&
        _selected.month == _month.month;
    // Seçili günün verisi: gösterilen aydaysa elde; değilse o ayın verisi.
    final selectedAct = selectedInMonth
        ? activity[_selected.day]
        : ref
            .watch(monthActivityProvider(
                DateTime(_selected.year, _selected.month, 1)))
            .valueOrNull?[_selected.day];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xxl),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.calTitle,
                          style: context.texts.labelSmall?.copyWith(
                            color: c.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          )),
                      const SizedBox(height: 4),
                      Text(monthTitle, style: context.texts.headlineMedium),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l.commonClose,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
            AppSpacing.vGapLg,
            GlassCard(
              radius: AppRadius.xl,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.md),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        key: const ValueKey('calendar.prev'),
                        tooltip: l.calPrevMonth,
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () => _shiftMonth(-1),
                      ),
                      Expanded(
                        child: Text(monthTitle,
                            textAlign: TextAlign.center,
                            style: context.texts.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800)),
                      ),
                      IconButton(
                        key: const ValueKey('calendar.next'),
                        tooltip: l.calNextMonth,
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: _isCurrentMonth ? null : () => _shiftMonth(1),
                      ),
                    ],
                  ),
                  CalendarWeekdayRow(
                      days: weekDays(startOfWeek(_month, weekStart))),
                  AppSpacing.vGapXs,
                  _MonthGrid(
                    month: _month,
                    weekStart: weekStart,
                    now: now,
                    selected: _selected,
                    activity: activity,
                    onSelect: (d) => setState(() => _selected = d),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: Divider(color: c.outlineVariant, height: 20),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    // Wrap: dar ekranda / büyük yazıda satır taşmasın,
                    // sığmayan parça alt satıra insin.
                    child: Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _LegendDot(
                            color: context.semantic.success,
                            label: l.navWorkout),
                        _LegendDot(
                            color: recordDotColor(context),
                            label: l.calLegendRecord),
                        Text(
                          l.calSelected(
                              context.dateFmt('d MMM').format(_selected)),
                          style: context.texts.labelSmall?.copyWith(
                              color: c.primary, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.vGapXl,
            Text(_cap(context.dateFmt('d MMMM EEEE').format(_selected)),
                style: context.texts.titleLarge),
            const SizedBox(height: 2),
            Text(l.calDayRecords,
                style: context.texts.bodySmall
                    ?.copyWith(color: c.onSurfaceVariant)),
            AppSpacing.vGapMd,
            DayRecords(activity: selectedAct),
            if (!isSameDay(_selected, now) || !_isCurrentMonth) ...[
              AppSpacing.vGapLg,
              FilledButton.icon(
                key: const ValueKey('calendar.today'),
                style: FilledButton.styleFrom(
                  backgroundColor: c.surfaceContainerHighest,
                  foregroundColor: c.onSurface,
                  minimumSize: const Size.fromHeight(AppA11y.minTapTarget),
                ),
                onPressed: _backToToday,
                icon: const Icon(Icons.today_rounded, size: AppIconSize.sm),
                label: Text(l.calBackToToday),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final int weekStart;
  final DateTime now;
  final DateTime selected;
  final Map<int, DayActivity> activity;
  final ValueChanged<DateTime> onSelect;

  const _MonthGrid({
    required this.month,
    required this.weekStart,
    required this.now,
    required this.selected,
    required this.activity,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Ayın ilk gününden önceki boş hücre sayısı (hafta başı tercihine göre).
    final lead = (month.weekday - weekStart) % 7;
    final cells = lead + daysInMonth;
    final rows = (cells / 7).ceil();

    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(child: _cell(r * 7 + col - lead + 1, daysInMonth)),
            ],
          ),
      ],
    );
  }

  Widget _cell(int day, int daysInMonth) {
    if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
    final d = DateTime(month.year, month.month, day);
    return CalendarDayCell(
      day: d,
      mark: dayMarkOf(activity[day]),
      isToday: isSameDay(d, now),
      isSelected: isSameDay(d, selected),
      isFuture: isFutureDay(d, now),
      onTap: () => onSelect(d),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        AppSpacing.hGapXs,
        Text(label,
            style: context.texts.labelSmall
                ?.copyWith(color: context.colors.onSurfaceVariant)),
      ],
    );
  }
}
