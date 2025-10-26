import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A compact month calendar that shows only working days (Mon–Fri).
/// - Renders full month across 5 columns (Mon–Fri) and 4–6 rows.
/// - Provides prev/next navigation by months.
/// - Highlights today and selected day.
/// - Disables dates outside [firstDay, lastDay].
class WeekdayTwoWeekCalendar extends StatelessWidget {
  final DateTime firstDay;
  final DateTime lastDay;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback? onPrevPage;
  final VoidCallback? onNextPage;

  // Scale factor for the size of each day button within its grid cell (1.0 = default).
  final double dayButtonScale;
  // Spacing between day chips in the grid.
  final double gridSpacing;

  const WeekdayTwoWeekCalendar(
      {Key? key,
      required this.firstDay,
      required this.lastDay,
      required this.focusedDay,
      required this.selectedDay,
      required this.onDaySelected,
      this.onPrevPage,
      this.onNextPage,
      this.dayButtonScale = 1.0,
      this.gridSpacing = 6.0})
      : super(key: key);

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _mondayOfWeek(DateTime day) {
    // weekday: Mon=1..Sun=7 → subtract (weekday-1) to get Monday
    return DateTime(day.year, day.month, day.day).subtract(Duration(days: day.weekday - DateTime.monday));
  }

  DateTime _fridayOfWeek(DateTime day) {
    // move to Friday of the same week
    return _mondayOfWeek(day).add(const Duration(days: 4));
  }

  /// Build grid days for a full month view (Mon–Fri columns).
  List<DateTime> _buildMonthGridDays() {
    final monthStart = DateTime(focusedDay.year, focusedDay.month, 1);
    final monthEnd = DateTime(focusedDay.year, focusedDay.month + 1, 0);

    // Grid spans from Monday on/before monthStart to Friday on/after monthEnd
    final gridStart = _mondayOfWeek(monthStart);
    final gridEnd = _fridayOfWeek(monthEnd);

    final int weeks = 1 + gridEnd.difference(gridStart).inDays ~/ 7;
    final List<DateTime> days = [];
    for (int w = 0; w < weeks; w++) {
      final monday = gridStart.add(Duration(days: w * 7));
      for (int i = 0; i < 5; i++) {
        days.add(monday.add(Duration(days: i))); // Mon..Fri
      }
    }
    return days;
  }

  bool _isOutsideRange(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    final startOnly = DateTime(firstDay.year, firstDay.month, firstDay.day);
    final endOnly = DateTime(lastDay.year, lastDay.month, lastDay.day);
    return dateOnly.isBefore(startOnly) || dateOnly.isAfter(endOnly);
  }

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(focusedDay.year, focusedDay.month, 1);
    final title = DateFormat('LLLL y.', 'hr').format(monthStart);

    final days = _buildMonthGridDays();

    // Determine availability of prev/next month
    final prevMonthStart = DateTime(focusedDay.year, focusedDay.month - 1, 1);
    final nextMonthStart = DateTime(focusedDay.year, focusedDay.month + 1, 1);
    final firstAllowedMonth = DateTime(firstDay.year, firstDay.month, 1);
    final lastAllowedMonth = DateTime(lastDay.year, lastDay.month, 1);
    final canPrev = !DateTime(prevMonthStart.year, prevMonthStart.month, 1).isBefore(firstAllowedMonth);
    final canNext = !DateTime(nextMonthStart.year, nextMonthStart.month, 1).isAfter(lastAllowedMonth);

    final weeks = (days.length / 5).ceil();

    // Month view without keyboard navigation
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          IconButton(onPressed: canPrev ? onPrevPage : null, icon: const Icon(Icons.chevron_left)),
          Expanded(child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
          IconButton(onPressed: canNext ? onNextPage : null, icon: const Icon(Icons.chevron_right))
        ]),
        const SizedBox(height: 8),
        // Day-of-week header (Mon..Fri)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [_DowLabel('Pon'), _DowLabel('Uto'), _DowLabel('Sri'), _DowLabel('Čet'), _DowLabel('Pet')],
        ),
        const SizedBox(height: 8),
        // 4–6 rows x 5 columns grid
        AspectRatio(
          aspectRatio: 10 / 5.0, // default ratio; height adjusts below via LayoutBuilder
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellSpacing = gridSpacing;
              final totalSpacingHeight = cellSpacing * (weeks - 1);
              final cellHeight = (constraints.maxHeight - totalSpacingHeight) / weeks;
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: cellSpacing,
                  crossAxisSpacing: cellSpacing,
                  mainAxisExtent: cellHeight,
                ),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final day = days[index];
                  final isOutOfMonth = day.month != focusedDay.month;
                  final disabled = _isOutsideRange(day) || isOutOfMonth;
                  final isSelected = _isSameDay(day, selectedDay);

                  return Opacity(
                    opacity: disabled ? 0.5 : 1.0,
                    child: Center(
                      child: ChoiceChip(
                        label: Text(
                          DateFormat('d').format(day),
                          style: TextStyle(
                            color: isSelected ? Colors.white : null,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                        selected: isSelected,
                        showCheckmark: false,
                        selectedColor: Theme.of(context).primaryColor,
                        onSelected: disabled ? null : (_) => onDaySelected(day),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DowLabel extends StatelessWidget {
  final String text;

  const _DowLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Center(child: Text(text, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600))));
  }
}
