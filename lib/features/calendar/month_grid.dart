import 'package:flutter/material.dart';

import 'calendar_day_cell.dart';
import 'calendar_logic.dart';

/// Ay ızgarası (docs/24 §2) — genel takvim ve antrenman takvimi (docs/45 §4)
/// aynı hücreyi kullanır. Günün işaretini çağıran verir ([markOf]: ayın günü
/// 1..31 → işaret); ızgara veri bilmez.
class MonthGrid extends StatelessWidget {
  final DateTime month;
  final int weekStart;
  final DateTime now;
  final DateTime selected;
  final DayMark Function(int day) markOf;
  final ValueChanged<DateTime> onSelect;

  const MonthGrid({
    super.key,
    required this.month,
    required this.weekStart,
    required this.now,
    required this.selected,
    required this.markOf,
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
    final future = isFutureDay(d, now);
    return CalendarDayCell(
      day: d,
      mark: markOf(day),
      isToday: isSameDay(d, now),
      isSelected: isSameDay(d, selected),
      isFuture: future,
      onTap: () => onSelect(d),
    );
  }
}
