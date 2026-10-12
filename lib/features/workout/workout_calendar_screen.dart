import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/formatting.dart';
import '../../core/prefs/week_start_provider.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/fitpack_icon.dart';
import '../../shared/widgets/glass.dart';
import '../calendar/calendar_day_cell.dart';
import '../calendar/calendar_logic.dart';
import '../calendar/month_grid.dart';
import 'history_card.dart';
import 'history_providers.dart';

/// Antrenman takvimi (docs/45 §4) — Antrenman sekmesinin takvim düğmesi.
///
/// **Neden var.** Eski takvim düğmesi "Geçmiş antrenman ekle"ydi: seçilen
/// gün için BOŞ bir kayıt formu açıyordu, o günün kayıtlarını hiç okumuyordu
/// (Samet, 2026-10-11: "kaydım olan günü seçince ekran boş"). Burada ay
/// ızgarasında antrenman günleri işaretli; güne dokununca o günün seansları
/// (dokununca detay: hareketler + setler). Kayıtsız günde boş durum + o güne
/// antrenman ekleme. Veri [workoutHistoryProvider]'dan — reaktif, Geçmiş
/// ekranıyla aynı kaynak.
class WorkoutCalendarScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;

  /// Testler için "şimdi"; verilmezse gerçek saat.
  final DateTime? now;

  const WorkoutCalendarScreen({super.key, this.initialDate, this.now});

  @override
  ConsumerState<WorkoutCalendarScreen> createState() =>
      _WorkoutCalendarScreenState();
}

class _WorkoutCalendarScreenState extends ConsumerState<WorkoutCalendarScreen> {
  late DateTime _selected;
  late DateTime _month;

  DateTime get _now => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    final init = widget.initialDate;
    _selected =
        dateOnly(init == null || isFutureDay(init, _now) ? _now : init);
    _month = DateTime(_selected.year, _selected.month, 1);
  }

  bool get _isCurrentMonth =>
      _month.year == _now.year && _month.month == _now.month;

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta, 1));

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.colors;
    final now = _now;
    final weekStart = ref.watch(weekStartProvider);
    final historyAsync = ref.watch(workoutHistoryProvider);
    final entries = historyAsync.valueOrNull?.entries ?? const <HistoryEntry>[];
    final workoutDays = workoutDaysInMonth(entries, _month);
    final monthTitle = _cap(context.dateFmt('MMMM yyyy').format(_month));

    return Scaffold(
      appBar: AppBar(
        title: Text(l.wcalTitle),
        actions: [
          IconButton(
            key: const ValueKey('wcal.addPast'),
            tooltip: l.workoutAddPast,
            icon: const FitPackIcon.material(Icons.edit_calendar_rounded),
            onPressed: () =>
                context.push(AppRoutes.workoutLogPastAt(_selected)),
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          GlassCard(
            radius: AppRadius.xl,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      key: const ValueKey('wcal.prev'),
                      tooltip: l.calPrevMonth,
                      icon: const FitPackIcon.material(
                          Icons.chevron_left_rounded),
                      onPressed: () => _shiftMonth(-1),
                    ),
                    Expanded(
                      child: Text(monthTitle,
                          textAlign: TextAlign.center,
                          style: context.texts.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      key: const ValueKey('wcal.next'),
                      tooltip: l.calNextMonth,
                      icon: const FitPackIcon.material(
                          Icons.chevron_right_rounded),
                      onPressed: _isCurrentMonth ? null : () => _shiftMonth(1),
                    ),
                  ],
                ),
                CalendarWeekdayRow(
                    days: weekDays(startOfWeek(_month, weekStart))),
                AppSpacing.vGapXs,
                MonthGrid(
                  month: _month,
                  weekStart: weekStart,
                  now: now,
                  selected: _selected,
                  markOf: (day) => workoutDays.contains(day)
                      ? DayMark.workout
                      : DayMark.none,
                  onSelect: (d) => setState(() => _selected = d),
                ),
                AppSpacing.vGapSm,
                Text(
                  l.wcalMonthCount(workoutDays.length),
                  style: context.texts.labelSmall
                      ?.copyWith(color: c.onSurfaceVariant),
                ),
              ],
            ),
          ),
          AppSpacing.vGapXl,
          Text(_cap(context.dateFmt('d MMMM EEEE').format(_selected)),
              style: context.texts.titleLarge),
          AppSpacing.vGapMd,
          historyAsync.when(
            loading: () => Skeleton.card(height: 150),
            error: (_, _) => ErrorState(
              message: l.whLoadError,
              onRetry: () => ref.invalidate(workoutHistoryProvider),
            ),
            data: (h) => _DaySessions(
              day: _selected,
              entries: entriesOnDay(h.entries, _selected),
              history: h,
            ),
          ),
        ],
      ),
    );
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _DaySessions extends StatelessWidget {
  final DateTime day;
  final List<HistoryEntry> entries;
  final WorkoutHistory history;

  const _DaySessions(
      {required this.day, required this.entries, required this.history});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    if (entries.isEmpty) {
      return Column(
        key: const ValueKey('wcal.empty'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.wcalEmpty,
              style: context.texts.bodyMedium
                  ?.copyWith(color: context.colors.onSurfaceVariant)),
          AppSpacing.vGapMd,
          OutlinedButton.icon(
            key: const ValueKey('wcal.addForDay'),
            onPressed: () => context.push(AppRoutes.workoutLogPastAt(day)),
            icon: const FitPackIcon.material(Icons.add_rounded,
                size: AppIconSize.sm),
            label: Text(l.wcalAddForDay),
          ),
        ],
      );
    }
    return Column(
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: HistoryCard(
              key: ValueKey(e.session.id),
              entry: e,
              exercisesById: history.exercisesById,
            ),
          ),
      ],
    );
  }
}
