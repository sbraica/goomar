import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/week_time_grid.dart';

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({Key? key}) : super(key: key);

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  // UI state moved to provider: focusedDay, selectedDay, selectedTime
  final int slotMinutes = 15;
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _mondayOf(DateTime d) => _dateOnly(d).subtract(Duration(days: d.weekday - DateTime.monday));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final monday = _mondayOf(DateTime.now());
        await Provider.of<ReservationProvider>(context, listen: false).loadReservations(weekStart: monday);
        // also set focusedDay in provider
        Provider.of<ReservationProvider>(context, listen: false).setFocusedDay(monday);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load reservations from server'), backgroundColor: Colors.red));
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

    // Read UI state from provider
    final DateTime focusedDay = reservationProvider.focusedDay;
    final DateTime? selectedDay = reservationProvider.selectedDay;
    final TimeOfDay? selectedTime = reservationProvider.selectedTime;

    final weekStart = _mondayOf(focusedDay);
    final weekEnd = weekStart.add(const Duration(days: 7));

    final occupied = <DateTime>{};
    final spans = <ReservationSpan>[];

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

      final int duration = r.longService ? 30 : 15;
      spans.add(ReservationSpan(id: r.id, start: DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute), durationMinutes: duration, label: r.username, approved: r.confirmed));

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
      // set via provider
      Provider.of<ReservationProvider>(context, listen: false).setSelectedSlot(slot);
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
                      backgroundColor: Theme.of(context).primaryColor.withAlpha((0.8 * 255).round())))),
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
                              // update provider-focused day instead of setState
                              reservationProvider.setFocusedDay(DateTime(prev.year, prev.month, prev.day));
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
                              reservationProvider.setFocusedDay(DateTime(next.year, next.month, next.day));
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
                            onSpanIconPressed: (span) async {
                              if (span.id == null) return;
                              final makeApproved = !span.approved;
                              try {
                                await Provider.of<ReservationProvider>(context, listen: false).setApprovedRemote(span.id!, makeApproved);
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to update approval: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            onDeleteIconPressed: (span) async {
                              if (span.id == null) return;
                              _showConfirmDialog(context, 'Delete appointment', 'Are you sure you want to delete this appointment?', () async {
                                try {
                                  await Provider.of<ReservationProvider>(context, listen: false).deleteReservationRemote(span.id!);
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to delete appointment: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              });
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
