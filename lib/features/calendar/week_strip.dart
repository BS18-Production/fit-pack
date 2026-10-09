import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/formatting.dart';
import '../../core/prefs/week_start_provider.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../l10n/app_l10n.dart';
import '../../shared/widgets/glass.dart';
import '../activity/activity_providers.dart';
import 'calendar_day_cell.dart';
import 'calendar_logic.dart';
import 'day_records.dart';
import '../../shared/widgets/fitpack_icon.dart';

/// Ana sayfanın haftalık şeridi (docs/24 §2).
///
/// Oklar haftalar arasında gezer (gelecek hafta yok); başlığa dokununca ay
/// görünümü, güne dokununca o günün kayıtları açılır. Gezinme durumu YALNIZ
/// bu widget'ta yaşar: bugünün antrenman eylemi buna bakmaz, geçmiş bir
/// haftayı incelemek onu değiştirmez.
class WeekStrip extends ConsumerStatefulWidget {
  /// Testler için "şimdi"; verilmezse gerçek saat.
  final DateTime? now;

  const WeekStrip({super.key, this.now});

  @override
  ConsumerState<WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends ConsumerState<WeekStrip> {
  /// Bu haftadan kaç hafta geride (0 = bu hafta, eksi = geçmiş).
  int _offset = 0;

  DateTime get _now => widget.now ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final now = _now;
    final weekStart = ref.watch(weekStartProvider);
    final start = shiftWeek(startOfWeek(now, weekStart), _offset);
    final days = weekDays(start);

    // Hafta iki aya taşabilir: her ayın verisi ayrı istenir, birleştirilir.
    // Yüklenirken ya da hata olursa günler işaretsiz çizilir, gezinme sürer.
    final activity = <DateTime, DayActivity>{};
    for (final m in monthsOf(days)) {
      final byDay = ref.watch(monthActivityProvider(m)).valueOrNull;
      byDay?.forEach(
          (d, act) => activity[DateTime(m.year, m.month, d)] = act);
    }

    final isCurrentWeek = _offset == 0;

    return GlassCard(
      radius: AppRadius.xl,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.xs),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                key: const ValueKey('weekStrip.prev'),
                tooltip: l.calPrevWeek,
                icon: const FitPackIcon.material(Icons.chevron_left_rounded),
                onPressed: () => setState(() => _offset--),
              ),
              Expanded(
                child: InkWell(
                  key: const ValueKey('weekStrip.title'),
                  borderRadius: AppRadius.brMd,
                  onTap: () => context.push(AppRoutes.calendarAt(
                      isCurrentWeek ? now : days.last)),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Semantics(
                      hint: l.calOpenMonth,
                      child: Text(
                        _rangeLabel(context, days, now),
                        textAlign: TextAlign.center,
                        style: context.texts.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('weekStrip.next'),
                tooltip: l.calNextWeek,
                icon: const FitPackIcon.material(Icons.chevron_right_rounded),
                onPressed:
                    isCurrentWeek ? null : () => setState(() => _offset++),
              ),
            ],
          ),
          CalendarWeekdayRow(days: days),
          Row(
            children: [
              for (final d in days)
                Expanded(
                  child: CalendarDayCell(
                    day: d,
                    mark: dayMarkOf(activity[d]),
                    isToday: isSameDay(d, now),
                    isSelected: false,
                    isFuture: isFutureDay(d, now),
                    onTap: () => showDayRecordsSheet(context,
                        day: d, activity: activity[d]),
                  ),
                ),
            ],
          ),
          if (!isCurrentWeek)
            TextButton.icon(
              key: const ValueKey('weekStrip.today'),
              onPressed: () => setState(() => _offset = 0),
              icon: const FitPackIcon.material(Icons.today_rounded, size: AppIconSize.sm),
              label: Text(l.calBackToToday),
            ),
        ],
      ),
    );
  }

  /// "21–27 Eylül" · ay taşarsa "28 Eyl – 4 Eki" · başka yılsa yıl eklenir.
  String _rangeLabel(BuildContext context, List<DateTime> days, DateTime now) {
    final a = days.first, b = days.last;
    final year = b.year != now.year ? ' ${b.year}' : '';
    if (a.month == b.month) {
      return '${a.day}–${context.dateFmt('d MMMM').format(b)}$year';
    }
    final f = context.dateFmt('d MMM');
    return '${f.format(a)} – ${f.format(b)}$year';
  }
}
