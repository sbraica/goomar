import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
const double tcw = 40.0;
class _WeekGridPainter extends CustomPainter {
  final int rows;
  final double rowHeight;
  final double timeColWidth;
  final double totalWidth;
  final int dayCount;
  final double dayWidth;

  // Visual enhancements
  final int slotMinutes;
  final Color bandColorOdd; // subtle horizontal striping
  final Color bandColorEven;
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
    required this.bandColorOdd,
    required this.bandColorEven,
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
        bandColorOdd != old.bandColorOdd ||
        bandColorEven != old.bandColorEven ||
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
  final String id;
  final DateTime start;
  final bool long;
  final String label;

  final String phone;
  final bool approved;

  final bool emailOk;

  const ReservationSpan({required this.id, required this.start, required this.long, required this.label, required this.phone, this.approved = false, this.emailOk = true});
}

class WeekTimeGrid extends StatelessWidget {
  final DateTime weekStart;
  final VoidCallback? onPrevWeek;
  final VoidCallback? onNextWeek;

  final void Function(ReservationSpan span)? onCheck;
  final void Function(ReservationSpan span)? onDelete;
  final void Function(ReservationSpan span)? onEdit;

  final TimeOfDay dayStart;
  final TimeOfDay dayEnd;
  final int slotMinutes; // e.g., 15 or 30

  final TimeOfDay? lunchStart;
  final TimeOfDay? lunchEnd;

  final Set<DateTime> occupied;

  final DateTime firstDay;
  final DateTime lastDay;

  final List<ReservationSpan> spans;

  const WeekTimeGrid(
      {Key? key,
      required this.weekStart,
      required this.onPrevWeek,
      required this.onNextWeek,
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
    final days = List<DateTime>.generate(5, (i) => weekStart.add(Duration(days: i)));
    final times = _buildTimes();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevWeek,
            tooltip: 'Previous week',
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            iconSize: 22),
        Expanded(
            child: Text('${DateFormat('d. MMMM').format(days.first)} – ${DateFormat('d. MMMM y.').format(days.last)}',
                textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, height: 1.1))),
        IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNextWeek,
            tooltip: 'Next week',
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            iconSize: 22)
      ]),
      const SizedBox(height: 4),
      Row(children: [
        const SizedBox(width: tcw), // time column width
        for (final d in days)
          Expanded(
              child: Column(children: [
            Text(DateFormat('EEE').format(d), style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(DateFormat('d.MM.').format(d), style: const TextStyle(fontSize: 12))
          ]))
      ]),
      const SizedBox(height: 8),
      Expanded(child: LayoutBuilder(builder: (context, constraints) {
        final double availableHeight = constraints.maxHeight;
        final bool isNarrow = constraints.maxWidth < 600;
        final double minRowHeight = isNarrow ? 24.0 : 30.0;
        final double maxRowHeight = isNarrow ? 32.0 : 38.0;

        double rowHeight = (availableHeight / times.length).clamp(minRowHeight, maxRowHeight);
        double totalHeight = times.length * rowHeight;

        Widget buildRow(TimeOfDay t) {
          var dtf = DateFormat('HH:mm');
          return SizedBox(
              height: rowHeight,
              child: Row(children: [
                SizedBox(width: tcw, child: Align(alignment: Alignment.topLeft, child: Text(dtf.format(DateTime(0, 1, 1, t.hour, t.minute)), style: TextStyle(fontSize: 11))))
              ]));
        }

        int toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
        int dayStartMin = toMinutes(dayStart);
        int dayEndMin = toMinutes(dayEnd);
        final int? lunchS = lunchStart != null ? toMinutes(lunchStart!) : null;
        final int? lunchE = lunchEnd != null ? toMinutes(lunchEnd!) : null;

        double? fractionalRowIndex(DateTime dt) {
          int m = dt.hour * 60 + dt.minute;
          if (m >= dayEndMin) return null;
          if (m < dayStartMin) m = dayStartMin;
          if (lunchS != null && lunchE != null && m >= lunchS && m < lunchE) {
            m = lunchE;
            if (m >= dayEndMin) return null;
          }
          int minutesFromStart = m - dayStartMin;
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

        double spanRows(DateTime start, int durationMin) {
          int s = start.hour * 60 + start.minute;
          int e = s + durationMin;
          if (e <= dayStartMin) return 0;
          if (s < dayStartMin) s = dayStartMin;
          if (e > dayEndMin) e = dayEndMin;
          if (s >= e) return 0;
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

        final double gridWidth = constraints.maxWidth - tcw;
        final double dayWidth = gridWidth / 5.0;

        List<Widget> buildOverlayBlocks() {
          final List<Widget> blocks = [];
          for (final span in spans) {
            final d = DateTime(span.start.year, span.start.month, span.start.day);
            final dayIndex = d.difference(weekStart).inDays;
            if (dayIndex < 0 || dayIndex > 4) continue;

            final idx = fractionalRowIndex(span.start);
            if (idx == null) continue; // outside visible working hours (or fully in lunch at end)

            final rows = spanRows(span.start, span.long ? 30 : 15);
            if (rows <= 0) continue;

            final top = idx * rowHeight + 2.0;
            final left = tcw + dayIndex * dayWidth + 2.0;
            final height = rows * rowHeight - 4.0;
            final width = dayWidth - 4.0;

            const spanTextStyle = TextStyle(fontSize: 12, shadows: [Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black26)]);
            const ei = EdgeInsets.all(2);
            const bc = BoxConstraints(minWidth: 28, minHeight: 28);
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
                      if (span.label!.isNotEmpty && span.phone!.isNotEmpty)
                        Center(
                            child: Padding(
                                padding: EdgeInsets.zero,
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

        final theme = Theme.of(context);
        final bool isDark = theme.brightness == Brightness.dark;
        // Subtle background banding to improve readability and professional look
        final Color primary = theme.colorScheme.primary;
        final Color bandOdd = primary.withOpacity(isDark ? 0.06 : 0.04);
        final Color bandEven = theme.colorScheme.surfaceVariant.withOpacity(isDark ? 0.10 : 0.06);
        final Color hourLineColor = isDark ? Colors.white.withAlpha((0.28 * 255).round()) : Colors.black.withAlpha((0.20 * 255).round());
        final Color minorLineColor = isDark ? Colors.white.withAlpha((0.12 * 255).round()) : Colors.black.withAlpha((0.10 * 255).round());

        final double? lunchSplitRowIndex = (lunchS != null) ? ((lunchS - dayStartMin) / slotMinutes) : null;

        final Widget gridPaint = SizedBox(
            height: totalHeight,
            width: constraints.maxWidth,
            child: CustomPaint(
                painter: _WeekGridPainter(
                    rows: times.length,
                    rowHeight: rowHeight,
                    timeColWidth: tcw,
                    totalWidth: constraints.maxWidth,
                    dayCount: 5,
                    dayWidth: dayWidth,
                    slotMinutes: slotMinutes,
                    bandColorOdd: bandOdd,
                    bandColorEven: bandEven,
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
