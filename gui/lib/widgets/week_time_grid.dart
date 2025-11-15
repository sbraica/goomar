import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class _WeekGridPainter extends CustomPainter {
  final int rows;
  final double rowHeight;
  final double timeColWidth;
  final double totalWidth;
  final int dayCount;
  final double dayWidth;

  // Visual enhancements
  final int slotMinutes;
  final int? todayIndex; // 0..dayCount-1 for Mon..Fri, or null if not in view
  final Color bandColorOdd; // subtle horizontal striping
  final Color bandColorEven;
  final Color todayTint; // soft background tint for today's column
  final Color hourLineColor;
  final Color minorLineColor;
  final double hourLineWidth;
  final double minorLineWidth;

  // Lunch split visual
  final double? lunchSplitRowIndex; // draw a red line between morning and afternoon, if provided
  final Color lunchLineColor;
  final double lunchLineWidth;

  _WeekGridPainter({
    required this.rows,
    required this.rowHeight,
    required this.timeColWidth,
    required this.totalWidth,
    required this.dayCount,
    required this.dayWidth,
    required this.slotMinutes,
    required this.todayIndex,
    required this.bandColorOdd,
    required this.bandColorEven,
    required this.todayTint,
    required this.hourLineColor,
    required this.minorLineColor,
    required this.hourLineWidth,
    required this.minorLineWidth,
    this.lunchSplitRowIndex,
    this.lunchLineColor = const Color(0xFFD32F2F),
    this.lunchLineWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double left = timeColWidth;
    final double right = timeColWidth + dayCount * dayWidth;
    final double height = rows * rowHeight;

    // Today column background tint (under everything in the grid area)
    if (todayIndex != null && todayIndex! >= 0 && todayIndex! < dayCount) {
      final double x0 = left + todayIndex! * dayWidth;
      final Rect todayRect = Rect.fromLTWH(x0, 0, dayWidth, height);
      final Paint todayPaint = Paint()..color = todayTint;
      canvas.drawRect(todayRect, todayPaint);
    }

    // Alternating row bands for readability (skip the time column)
    for (int r = 0; r < rows; r++) {
      final double y = r * rowHeight;
      final Rect bandRect = Rect.fromLTWH(left, y, right - left, rowHeight);
      final bool isOdd = r % 2 == 1;
      final Color c = isOdd ? bandColorOdd : bandColorEven;
      if (c.alpha > 0) {
        canvas.drawRect(bandRect, Paint()..color = c);
      }
    }

    // Vertical divider for time column
    final Paint minorLine = Paint()
      ..color = minorLineColor
      ..strokeWidth = minorLineWidth;
    final Paint hourLine = Paint()
      ..color = hourLineColor
      ..strokeWidth = hourLineWidth;

    canvas.drawLine(Offset(left, 0), Offset(left, height), minorLine);

    // Vertical day dividers
    for (int i = 0; i <= dayCount; i++) {
      final double x = left + i * dayWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, height), minorLine);
    }

    // Horizontal row dividers with stronger hour lines (every 60/slotMinutes rows)
    final int rowsPerHour = (60 ~/ slotMinutes);
    for (int r = 0; r <= rows; r++) {
      final double y = r * rowHeight;
      final bool isHour = r % rowsPerHour == 0;
      canvas.drawLine(Offset(left, y), Offset(right, y), isHour ? hourLine : minorLine);
    }

    // Extra red line to mark lunch split, if provided
    if (lunchSplitRowIndex != null) {
      final double y = lunchSplitRowIndex!.clamp(0, rows.toDouble()) * rowHeight;
      final Paint lunchPaint = Paint()
        ..color = lunchLineColor
        ..strokeWidth = lunchLineWidth;
      canvas.drawLine(Offset(left, y), Offset(right, y), lunchPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeekGridPainter old) {
    return rows != old.rows ||
        rowHeight != old.rowHeight ||
        timeColWidth != old.timeColWidth ||
        totalWidth != old.totalWidth ||
        dayCount != old.dayCount ||
        dayWidth != old.dayWidth ||
        slotMinutes != old.slotMinutes ||
        todayIndex != old.todayIndex ||
        bandColorOdd != old.bandColorOdd ||
        bandColorEven != old.bandColorEven ||
        todayTint != old.todayTint ||
        hourLineColor != old.hourLineColor ||
        minorLineColor != old.minorLineColor ||
        hourLineWidth != old.hourLineWidth ||
        minorLineWidth != old.minorLineWidth ||
        lunchSplitRowIndex != old.lunchSplitRowIndex ||
        lunchLineColor != old.lunchLineColor ||
        lunchLineWidth != old.lunchLineWidth;
  }
}

class ReservationSpan {
  final String id; // optional reservation id (UUID) to map actions
  final DateTime start;
  final bool long;
  final String label;

  final String phone;
  final bool approved;

  // Whether backend marked email as OK/valid. Used for coloring when filters are applied.
  final bool emailOk;

  const ReservationSpan({
    required this.id,
    required this.start,
    required this.long,
    required this.label,
    required this.phone,
    this.approved = false,
    this.emailOk = true,
  });
}

class WeekTimeGrid extends StatelessWidget {
  final DateTime weekStart; // Monday of the shown week (date-only)
  final VoidCallback? onPrevWeek;
  final VoidCallback? onNextWeek;

  final DateTime? selectedDay;
  final TimeOfDay? selectedTime;
  final ValueChanged<DateTime> onSelectSlot; // returns exact DateTime for the slot

  // New: simple icon action on each reservation span (no popup/menu).
  final void Function(ReservationSpan span)? onCheck;
  final void Function(ReservationSpan span)? onDelete;
  final void Function(ReservationSpan span)? onEdit;

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

  const WeekTimeGrid(
      {Key? key,
      required this.weekStart,
      required this.onPrevWeek,
      required this.onNextWeek,
      required this.selectedDay,
      required this.selectedTime,
      required this.onSelectSlot,
      required this.onEdit,
      this.onCheck,
      this.onDelete,
      required this.dayStart,
      required this.dayEnd,
      required this.slotMinutes,
      this.lunchStart,
      this.lunchEnd,
      required this.occupied,
      required this.firstDay,
      required this.lastDay,
      this.spans = const []})
      : super(key: key);

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

    final times = _buildTimes();

    // Build occupied lookup normalized to minute precision
    Set<String> occKeys = occupied.map((d) => DateTime(d.year, d.month, d.day, d.hour, d.minute)).map((d) => d.toIso8601String()).toSet();

    String keyFor(DateTime d) => DateTime(d.year, d.month, d.day, d.hour, d.minute).toIso8601String();

    bool isPast(DateTime slot) => slot.isBefore(DateTime.now());

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Header with navigation
      Row(children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrevWeek, tooltip: 'Previous week'),
        Expanded(child: Text(headerTitle(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNextWeek, tooltip: 'Next week')
      ]),
      const SizedBox(height: 8),
      // Day headers
      Row(children: [
        const SizedBox(width: 72), // time column width
        for (final d in days)
          Expanded(
              child: Column(children: [
            Text(DateFormat('EEE').format(d), style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(DateFormat('d.MM.').format(d), style: const TextStyle(fontSize: 12))
          ]))
      ]),
      const SizedBox(height: 8),
      // Grid (fills remaining space; scrolls internally only if needed)
      Expanded(child: LayoutBuilder(builder: (context, constraints) {
        // Available vertical space for the rows area
        final double availableHeight = constraints.maxHeight;

        // Adaptive row height based on width and available height
        final bool isNarrow = constraints.maxWidth < 600;
        final double minRowHeight = isNarrow ? 24.0 : 30.0;
        final double maxRowHeight = isNarrow ? 32.0 : 38.0;

        double rowHeight = (availableHeight / times.length).clamp(minRowHeight, maxRowHeight);
        double totalHeight = times.length * rowHeight;
        Color bg;
        Color fg = Colors.black;
        Color borderColor = Colors.transparent;
        const double timeColWidth = 40.0;
        Widget buildRow(TimeOfDay t) {
          return SizedBox(
              height: rowHeight,
              child: Row(children: [
                SizedBox(
                    width: timeColWidth,
                    child: Align(alignment: Alignment.topLeft, child: Text(DateFormat('HH:mm').format(DateTime(0, 1, 1, t.hour, t.minute)), style: TextStyle(fontSize: 11)))),
                for (final d in days)
                  Expanded(child: Builder(builder: (context) {
                    final slot = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                    final disabled = !_isWithinBounds(d) || isPast(slot);
                    final occupiedKey = occKeys.contains(keyFor(slot));
                    final selected =
                        selectedDay != null && selectedTime != null && _sameDate(slot, selectedDay!) && selectedTime!.hour == t.hour && selectedTime!.minute == t.minute;

                    if (selected) {
                      bg = Theme.of(context).colorScheme.primary;
                      fg = Colors.white;
                      borderColor = Theme.of(context).colorScheme.primary;
                    } else if (disabled) {
                      // Unavailable cells slightly darker gray
                      bg = Colors.grey.shade200;
                      fg = Colors.grey.shade500;
                      borderColor = Colors.transparent; // grid painter will show lines
                    } else if (occupiedKey) {
                      // Occupied cells use the same uniform background; overlay spans indicate reservations.
                      bg = Colors.grey.shade100;
                      fg = Colors.grey.shade800;
                    } else {
                      // Available cells also use the same uniform background (light gray)
                      bg = Colors.grey.shade100;
                      fg = Colors.grey.shade800;
                    }

                    return Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: InkWell(
                            onTap: (disabled || occupiedKey) ? null : () => onSelectSlot(slot),
                            child: Container(
                                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: borderColor)),
                                child: Center(child: Text(selected ? 'Selected' : '', style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12))))));
                  }))
              ]));
        }

        // Compute overlay positions for reservation spans (support off-grid start times)
        int toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
        int dayStartMin = toMinutes(dayStart);
        int dayEndMin = toMinutes(dayEnd);
        final int? lunchS = lunchStart != null ? toMinutes(lunchStart!) : null;
        final int? lunchE = lunchEnd != null ? toMinutes(lunchEnd!) : null;

        // Map a DateTime within the working day (excluding lunch) to a fractional row index
        double? fractionalRowIndex(DateTime dt) {
          int m = dt.hour * 60 + dt.minute;
          // Clip to working hours
          if (m >= dayEndMin) return null;
          if (m < dayStartMin) m = dayStartMin;
          // If inside lunch, move to lunch end
          if (lunchS != null && lunchE != null && m >= lunchS && m < lunchE) {
            m = lunchE;
            if (m >= dayEndMin) return null;
          }
          // Minutes from day start
          int minutesFromStart = m - dayStartMin;
          // Subtract lunch minutes that occur before m
          int lunchBefore = 0;
          if (lunchS != null && lunchE != null) {
            final int overlapStart = lunchS.clamp(dayStartMin, m);
            final int overlapEnd = lunchE.clamp(dayStartMin, m);
            final int delta = overlapEnd - overlapStart;
            if (delta > 0) lunchBefore = delta;
          }
          final int effective = minutesFromStart - lunchBefore;
          return effective / slotMinutes;
        }

        // Compute how many rows a span should cover after clipping to working hours and removing lunch
        double spanRows(DateTime start, int durationMin) {
          int s = start.hour * 60 + start.minute;
          int e = s + durationMin;
          // Clip to working hours
          if (e <= dayStartMin) return 0;
          if (s < dayStartMin) s = dayStartMin;
          if (e > dayEndMin) e = dayEndMin;
          if (s >= e) return 0;
          // Remove lunch overlap from [s, e)
          int visible = e - s;
          if (lunchS != null && lunchE != null) {
            final int os = s.clamp(lunchS, lunchE);
            final int oe = e.clamp(lunchS, lunchE);
            final int lunchOverlap = (oe - os).clamp(0, visible);
            visible -= lunchOverlap;
          }
          if (visible <= 0) return 0;
          return visible / slotMinutes;
        }

        // Layout metrics for overlay

        final double gridWidth = constraints.maxWidth - timeColWidth;
        final double dayWidth = gridWidth / 5.0;

        List<Widget> buildOverlayBlocks() {
          final List<Widget> blocks = [];
          for (final span in spans) {
            // Only render spans that fall within the visible Mon–Fri range
            final d = DateTime(span.start.year, span.start.month, span.start.day);
            final dayIndex = d.difference(weekStart).inDays;
            if (dayIndex < 0 || dayIndex > 4) continue;

            final idx = fractionalRowIndex(span.start);
            if (idx == null) continue; // outside visible working hours (or fully in lunch at end)

            final rows = spanRows(span.start, span.long ? 30 : 15);
            if (rows <= 0) continue;

            final top = idx * rowHeight + 2.0;
            final left = timeColWidth + dayIndex * dayWidth + 2.0;
            final height = rows * rowHeight - 4.0;
            final width = dayWidth - 4.0;

            const spanTextStyle =
                const TextStyle(color: Colors.black, fontWeight: FontWeight.normal, fontSize: 12, shadows: [Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black26)]);
            const ei = const EdgeInsets.all(2);
            const bc = const BoxConstraints(minWidth: 28, minHeight: 28);
            blocks.add(Positioned(
                top: top,
                left: left,
                width: width,
                height: height,
                child: Container(
                    decoration: BoxDecoration(
                        color: (!span.emailOk ? Colors.red.shade400 : (span.approved ? Colors.green.shade400 : Colors.amber.shade400)).withAlpha((0.85 * 255).round()),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: !span.emailOk ? Colors.red.shade700 : (span.approved ? Colors.green.shade700 : Colors.amber.shade700), width: 1)),
                    child: Stack(children: [
                      if ((span.label != null && span.label!.isNotEmpty) || (span.phone != null && span.phone!.isNotEmpty))
                        Center(
                            child: Padding(
                                // leave space so it doesn't collide with the top-right icon
                                padding: const EdgeInsets.only(right: 28.0, left: 6.0),
                                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
                                  if (span.label != null && span.label!.isNotEmpty)
                                    Text(span.long ? span.label! : "${span.label!} ${span.phone!}",
                                        maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, textAlign: TextAlign.center, style: spanTextStyle),
                                  if (span.long && span.phone != null && span.phone!.isNotEmpty) ...[
                                    Text(span.phone!, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, textAlign: TextAlign.center, style: spanTextStyle)
                                  ]
                                ]))),
                      // Icon-only action in the top-right corner
                      Positioned(
                          top: 0,
                          right: 0,
                          child: Row(children: [
                            if (!span.emailOk)
                              IconButton(padding: ei, constraints: bc, onPressed: () => onEdit!(span), icon: const Icon(Icons.email, size: 16, color: Colors.white)),
                            if (span.emailOk && !span.approved)
                              IconButton(padding: ei, constraints: bc, onPressed: () => onCheck!(span), icon: const Icon(Icons.check, size: 16, color: Colors.white)),
                            IconButton(padding: ei, constraints: bc, onPressed: () => onDelete!(span), icon: const Icon(Icons.delete, size: 16, color: Colors.white))
                          ]))
                    ]))));
          }
          return blocks;
        }

        // Background grid painter (draw lines under cells/spans)
        final DateTime now = DateTime.now();
        final DateTime todayOnly = DateTime(now.year, now.month, now.day);
        final int? todayIndex = (() {
          final int idx = todayOnly.difference(weekStart).inDays;
          return (idx >= 0 && idx < 5) ? idx : null;
        })();

        final theme = Theme.of(context);
        final bool isDark = theme.brightness == Brightness.dark;
        // Use no background tinting/striping: all cells will have the same light gray fill.
        const Color bandOdd = Colors.transparent;
        const Color bandEven = Colors.transparent;
        const Color todayTint = Colors.transparent;
        final Color hourLineColor = isDark ? Colors.white.withAlpha((0.28 * 255).round()) : Colors.black.withAlpha((0.28 * 255).round());
        final Color minorLineColor = isDark ? Colors.white.withAlpha((0.14 * 255).round()) : Colors.black.withAlpha((0.14 * 255).round());

        final double? lunchSplitRowIndex = (lunchS != null) ? ((lunchS - dayStartMin) / slotMinutes) : null;

        final Widget gridPaint = SizedBox(
            height: totalHeight,
            width: constraints.maxWidth,
            child: CustomPaint(
                painter: _WeekGridPainter(
                    rows: times.length,
                    rowHeight: rowHeight,
                    timeColWidth: timeColWidth,
                    totalWidth: constraints.maxWidth,
                    dayCount: 5,
                    dayWidth: dayWidth,
                    slotMinutes: slotMinutes,
                    todayIndex: todayIndex,
                    bandColorOdd: bandOdd,
                    bandColorEven: bandEven,
                    todayTint: todayTint,
                    hourLineColor: hourLineColor,
                    minorLineColor: minorLineColor,
                    hourLineWidth: 1.2,
                    minorLineWidth: 0.8,
                    lunchSplitRowIndex: lunchSplitRowIndex,
                    lunchLineColor: Colors.red,
                    lunchLineWidth: 2.0)));

        final overlay = Stack(children: [
          Positioned.fill(child: gridPaint),
          Positioned.fill(child: Column(children: [for (final t in times) buildRow(t)])),
          ...buildOverlayBlocks()
        ]);

        if (totalHeight > availableHeight) {
          return SingleChildScrollView(padding: EdgeInsets.zero, child: SizedBox(height: totalHeight, width: constraints.maxWidth, child: overlay));
        }

        return SizedBox(height: totalHeight, width: constraints.maxWidth, child: overlay);
      }))
    ]);
  }
}
