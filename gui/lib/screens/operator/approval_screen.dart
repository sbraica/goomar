import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/reservation_card.dart';
import '../../widgets/week_time_grid.dart';
import '../../models/reservation.dart';

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({Key? key}) : super(key: key);

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  // Local state for operator scheduler view
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  TimeOfDay? selectedTime;
  final int slotMinutes = 15; // fixed 15-minute slots

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _mondayOf(DateTime d) => _dateOnly(d).subtract(Duration(days: d.weekday - DateTime.monday));

  @override
  void initState() {
    super.initState();
    // Load reservations when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final monday = _mondayOf(DateTime.now());
        await Provider.of<ReservationProvider>(context, listen: false).loadReservations(weekStart: monday);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load reservations from server'), backgroundColor: Colors.red),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final reservationProvider = Provider.of<ReservationProvider>(context);

    // Week bounds
    final weekStart = _mondayOf(focusedDay);
    final weekEnd = weekStart.add(const Duration(days: 7));

    // Build occupied set and visual spans for reservations in the visible week.
    final occupied = <DateTime>{};
    final spans = <ReservationSpan>[];

    // Helpers to compute 15-min slots for a given day, skipping lunch
    List<TimeOfDay> _daySlots() {
      final List<TimeOfDay> slots = [];
      TimeOfDay t = const TimeOfDay(hour: 8, minute: 0);
      int toMin(TimeOfDay x) => x.hour * 60 + x.minute;
      TimeOfDay fromMin(int m) => TimeOfDay(hour: m ~/ 60, minute: m % 60);
      const int step = 15;
      final int endM = toMin(const TimeOfDay(hour: 16, minute: 0));
      const lunchS = TimeOfDay(hour: 12, minute: 0);
      const lunchE = TimeOfDay(hour: 13, minute: 0);
      final int lunchStartMin = toMin(lunchS);
      final int lunchEndMin = toMin(lunchE);
      while (toMin(t) <= endM - step) {
        final int s = toMin(t);
        final int e = s + step;
        final overlapsLunch = s < lunchEndMin && e > lunchStartMin;
        if (!overlapsLunch) slots.add(t);
        t = fromMin(e);
      }
      return slots;
    }

    bool _intervalsOverlap(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
      return aStart.isBefore(bEnd) && aEnd.isAfter(bStart);
    }

    final daySlots = _daySlots();

    for (final r in reservationProvider.reservations) {
      final dt = r.date_time;
      if (dt.isBefore(weekStart) || !dt.isBefore(weekEnd)) continue;

      // Visual span uses exact start (can be off-grid) and duration from service type
      final int duration = r.longService ? 30 : 15;
      spans.add(ReservationSpan(id: r.id, start: DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute), durationMinutes: duration, label: r.username, approved: r.approved));

      // Disable taps on any 15-min grid cell that overlaps with the reservation interval
      final DateTime resStart = DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
      final DateTime resEnd = resStart.add(Duration(minutes: duration));
      for (final tod in daySlots) {
        final slotStart = DateTime(dt.year, dt.month, dt.day, tod.hour, tod.minute);
        final slotEnd = slotStart.add(Duration(minutes: slotMinutes));
        if (_intervalsOverlap(resStart, resEnd, slotStart, slotEnd)) {
          occupied.add(slotStart);
        }
      }
    }

    void onSelectSlot(DateTime slot) {
      setState(() {
        selectedDay = slot;
        selectedTime = TimeOfDay(hour: slot.hour, minute: slot.minute);
      });
    }

    final firstDay = DateTime.now();
    final lastDay = DateTime.now().add(const Duration(days: 90));

    return Scaffold(
        appBar: AppBar(title: const Text('Reservation Management'), actions: [
          IconButton(
              onPressed: () async {
                try {
                  final currentMonday = _mondayOf(focusedDay);
                  await reservationProvider.loadReservations(weekStart: currentMonday);
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to refresh reservations'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh)),
          Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                  child: Chip(
                      avatar: const Icon(Icons.person, size: 16, color: Colors.white),
                      label: Text(authProvider.currentUser?.username ?? 'Operator', style: const TextStyle(color: Colors.white)),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8)))),
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () {
                _showConfirmDialog(context, 'Logout', 'Are you sure you want to logout?', () {
                  authProvider.logout();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                });
              })
        ]),
        body: Column(children: [
          if (reservationProvider.isLoading) const LinearProgressIndicator(minHeight: 2),
          // Operator week scheduler (fixed 15-minute slots)
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    // The grid below will expand to fill the remaining space
                    Expanded(
                        child: WeekTimeGrid(
                            weekStart: weekStart,
                            onPrevWeek: () async {
                              if (reservationProvider.isLoading) return;
                              final prev = weekStart.subtract(const Duration(days: 7));
                              setState(() => focusedDay = DateTime(prev.year, prev.month, prev.day));
                              try {
                                await reservationProvider.loadReservations(weekStart: prev);
                              } catch (_) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(content: Text('Failed to load reservations for previous week'), backgroundColor: Colors.red));
                                }
                              }
                            },
                            onNextWeek: () async {
                              if (reservationProvider.isLoading) return;
                              final next = weekStart.add(const Duration(days: 7));
                              setState(() => focusedDay = DateTime(next.year, next.month, next.day));
                              try {
                                await reservationProvider.loadReservations(weekStart: next);
                              } catch (_) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(content: Text('Failed to load reservations for next week'), backgroundColor: Colors.red));
                                }
                              }
                            },
                            selectedDay: selectedDay,
                            selectedTime: selectedTime,
                            onSelectSlot: onSelectSlot,
                            onSpanIconPressed: (span) {
                              if (span.id == null) return;
                              final makeApproved = !span.approved;
                              Provider.of<ReservationProvider>(context, listen: false).setApproved(span.id!, makeApproved);
                              final msg = makeApproved ? 'Marked as confirmed' : 'Marked as unconfirmed';
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                            },
                            dayStart: const TimeOfDay(hour: 8, minute: 0),
                            dayEnd: const TimeOfDay(hour: 16, minute: 0),
                            slotMinutes: slotMinutes,
                            lunchStart: const TimeOfDay(hour: 12, minute: 0),
                            lunchEnd: const TimeOfDay(hour: 13, minute: 0),
                            occupied: occupied,
                            firstDay: firstDay,
                            lastDay: lastDay,
                            spans: spans))
                  ])))
          // Lists (no tabs): Pending section then Approved section
        ]));
  }

  void _showConfirmDialog(BuildContext context, String title, String message, VoidCallback onConfirm) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(title: Text(title), content: Text(message), actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onConfirm();
                  },
                  child: const Text('Confirm'))
            ]));
  }
}
