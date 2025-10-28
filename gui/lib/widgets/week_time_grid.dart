import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReservationSpan {
  final DateTime start;
  final int durationMinutes;
  final String? label;
  const ReservationSpan({required this.start, required this.durationMinutes, this.label});
}

class WeekTimeGrid extends StatelessWidget {
  final DateTime weekStart; // Monday of the shown week (date-only)
  final VoidCallback? onPrevWeek;
  final VoidCallback? onNextWeek;

  final DateTime? selectedDay;
  final TimeOfDay? selectedTime;
  final ValueChanged<DateTime> onSelectSlot; // returns exact DateTime for the slot

  // Working hours
  final TimeOfDay dayStart;
  final TimeOfDay dayEnd;
  final int slotMinutes; // e.g., 15 or 30

  // Optional lunch break to skip
  final TimeOfDay? lunchStart;
  final TimeOfDay? lunchEnd;

  // Existing occupied slots (start times) to mark/disable
  final Set<DateTime> occupied;

  // Limit navigation (inclusive)
  final DateTime firstDay;
  final DateTime lastDay;

  final List<ReservationSpan> spans;

  const WeekTimeGrid({
    Key? key,
    required this.weekStart,
    required this.onPrevWeek,
    required this.onNextWeek,
    required this.selectedDay,
    required this.selectedTime,
    required this.onSelectSlot,
    required this.dayStart,
    required this.dayEnd,
    required this.slotMinutes,
    this.lunchStart,
    this.lunchEnd,
    required this.occupied,
    required this.firstDay,
    required this.lastDay,
    this.spans = const [],
  }) : super(key: key);

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _sameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isWithinBounds(DateTime day) {
    final d = _dateOnly(day);
    final f = _dateOnly(firstDay);
    final l = _dateOnly(lastDay);
    return !d.isBefore(f) && !d.isAfter(l);
  }

  List<TimeOfDay> _buildTimes() {
    int toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
    TimeOfDay fromMinutes(int m) => TimeOfDay(hour: m ~/ 60, minute: m % 60);

    final times = <TimeOfDay>[];
    int cur = toMinutes(dayStart);
    final endM = toMinutes(dayEnd);
    final lunchS = lunchStart != null ? toMinutes(lunchStart!) : null;
    final lunchE = lunchEnd != null ? toMinutes(lunchEnd!) : null;
    while (cur <= endM - slotMinutes) {
      final next = cur + slotMinutes;
      final overlapsLunch = lunchS != null && lunchE != null && cur < lunchE && next > lunchS;
      if (!overlapsLunch) {
        times.add(fromMinutes(cur));
      }
      cur = next;
    }
    return times;
  }

  @override
  Widget build(BuildContext context) {
    // Build week days (Mon..Fri)
    final days = List<DateTime>.generate(5, (i) => weekStart.add(Duration(days: i)));

    // Header title like "28 Oct – 1 Nov 2025"
    String headerTitle() {
      final startFmt = DateFormat('d MMM');
      final endFmt = DateFormat('d MMM y');
      final startStr = startFmt.format(days.first);
      final endStr = endFmt.format(days.last);
      return '$startStr – $endStr';
    }

    // Navigation bounds: determine if prev/next week stays within [firstDay,lastDay]
    bool canPrev() {
      final prevMonday = _dateOnly(weekStart.subtract(const Duration(days: 7)));
      return !_dateOnly(prevMonday).isBefore(_dateOnly(DateTime(firstDay.year, firstDay.month, firstDay.day)));
    }

    bool canNext() {
      final nextMonday = _dateOnly(weekStart.add(const Duration(days: 7)));
      // Allow showing next if at least Monday is within range
      return !_dateOnly(nextMonday).isAfter(_dateOnly(lastDay));
    }

    final times = _buildTimes();

    // Build occupied lookup normalized to minute precision
    Set<String> occKeys = occupied
        .map((d) => DateTime(d.year, d.month, d.day, d.hour, d.minute))
        .map((d) => d.toIso8601String())
        .toSet();

    String keyFor(DateTime d) => DateTime(d.year, d.month, d.day, d.hour, d.minute).toIso8601String();

    bool isPast(DateTime slot) => slot.isBefore(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with navigation
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: canPrev() ? onPrevWeek : null,
              tooltip: 'Previous week',
            ),
            Expanded(
              child: Text(
                headerTitle(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: canNext() ? onNextWeek : null,
              tooltip: 'Next week',
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Day headers
        Row(
          children: [
            const SizedBox(width: 72), // time column width
            for (final d in days)
              Expanded(
                child: Column(
                  children: [
                    Text(DateFormat('EEE').format(d), style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(DateFormat('d.MM.').format(d), style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Grid (fills remaining space; scrolls internally only if needed)
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Available vertical space for the rows area
              final double availableHeight = constraints.maxHeight;

              // Adaptive row height based on width and available height
              final bool isNarrow = constraints.maxWidth < 600;
              final double minRowHeight = isNarrow ? 24.0 : 30.0;
              final double maxRowHeight = isNarrow ? 32.0 : 38.0;

              double rowHeight = (availableHeight / times.length).clamp(minRowHeight, maxRowHeight);
              double totalHeight = times.length * rowHeight;

              Widget buildRow(TimeOfDay t) {
                return SizedBox(
                  height: rowHeight,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            DateFormat('HH:mm').format(DateTime(0, 1, 1, t.hour, t.minute)),
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ),
                      for (final d in days)
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final slot = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                              final disabled = !_isWithinBounds(d) || isPast(slot);
                              final occupiedKey = occKeys.contains(keyFor(slot));
                              final selected = selectedDay != null &&
                                  selectedTime != null &&
                                  _sameDate(slot, selectedDay!) &&
                                  selectedTime!.hour == t.hour &&
                                  selectedTime!.minute == t.minute;

                              Color bg;
                              Color fg = Colors.black;
                              if (selected) {
                                bg = Theme.of(context).colorScheme.primary;
                                fg = Colors.white;
                              } else if (disabled) {
                                bg = Colors.grey.shade200;
                                fg = Colors.grey.shade500;
                              } else if (occupiedKey) {
                                bg = Colors.red.shade100;
                                fg = Colors.red.shade700;
                              } else {
                                bg = Colors.green.shade50;
                                fg = Colors.green.shade800;
                              }

                              return Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: InkWell(
                                  onTap: (disabled || occupiedKey) ? null : () => onSelectSlot(slot),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: bg,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Center(
                                      child: Text(
                                        selected
                                            ? 'Selected'
                                            : '',
                                        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              }

              // Compute overlay positions for reservation spans
              int timeIndexOf(TimeOfDay t) {
                for (int i = 0; i < times.length; i++) {
                  if (times[i].hour == t.hour && times[i].minute == t.minute) return i;
                }
                return -1;
              }

              // Layout metrics for overlay
              const double timeColWidth = 72.0;
              final double gridWidth = constraints.maxWidth - timeColWidth;
              final double dayWidth = gridWidth / 5.0;

              List<Widget> buildOverlayBlocks() {
                final List<Widget> blocks = [];
                for (final span in spans) {
                  // Only render spans that fall within the visible Mon–Fri range
                  final d = DateTime(span.start.year, span.start.month, span.start.day);
                  final dayIndex = d.difference(weekStart).inDays;
                  if (dayIndex < 0 || dayIndex > 4) continue;

                  final startTod = TimeOfDay(hour: span.start.hour, minute: span.start.minute);
                  final startIndex = timeIndexOf(startTod);
                  if (startIndex == -1) continue; // not aligned to visible grid (e.g., during lunch)

                  final rows = (span.durationMinutes / slotMinutes).round().clamp(1, 100);
                  final top = startIndex * rowHeight + 2.0;
                  final left = timeColWidth + dayIndex * dayWidth + 2.0;
                  final height = rows * rowHeight - 4.0;
                  final width = dayWidth - 4.0;

                  blocks.add(Positioned(
                    top: top,
                    left: left,
                    width: width,
                    height: height,
                    child: AbsorbPointer(
                      absorbing: true, // prevent taps on cells under the block
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade300.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade600, width: 1),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          span.label ?? 'Reserved',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ));
                }
                return blocks;
              }

              Widget background = Column(
                children: [
                  for (final t in times) buildRow(t),
                ],
              );

              final overlay = Stack(children: [
                // Background grid
                Positioned.fill(child: background),
                // Reservation blocks overlay
                ...buildOverlayBlocks(),
              ]);

              if (totalHeight > availableHeight) {
                // Scrollable stack to keep overlay aligned with rows while scrolling
                return SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: SizedBox(height: totalHeight, width: constraints.maxWidth, child: overlay),
                );
              }

              // Fits: no scroll necessary
              return SizedBox(height: totalHeight, width: constraints.maxWidth, child: overlay);
            },
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _legendSwatch(context, Colors.green.shade50, Colors.green.shade800, 'Available'),
            _legendSwatch(context, Colors.red.shade100, Colors.red.shade700, 'Reserved'),
            _legendSwatch(context, Theme.of(context).colorScheme.primary, Colors.white, 'Selected'),
            _legendSwatch(context, Colors.grey.shade200, Colors.grey.shade500, 'Unavailable'),
          ],
        )
      ],
    );
  }

  Widget _legendSwatch(BuildContext context, Color bg, Color fg, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: bg, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: fg, fontSize: 12)),
      ],
    );
  }
}
