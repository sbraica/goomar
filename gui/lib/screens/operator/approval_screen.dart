import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/reservation_card.dart';
import '../../widgets/week_time_grid.dart';

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
        await Provider.of<ReservationProvider>(context, listen: false).loadReservations();
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
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final reservationProvider = Provider.of<ReservationProvider>(context);

    // Week bounds
    final weekStart = _mondayOf(focusedDay);
    final weekEnd = weekStart.add(const Duration(days: 7));

    // Build occupied set using current slotMinutes.
    final occupied = <DateTime>{};
    for (final r in reservationProvider.reservations) {
      final dt = r.dateTime;
      if (dt.isBefore(weekStart) || !dt.isBefore(weekEnd)) continue;
      // Determine reservation duration by type: longService = 30 min, else 15 min
      final int duration = r.longService ? 30 : 15;
      // Number of grid slots to block under current granularity
      final int blocks = (duration + slotMinutes - 1) ~/ slotMinutes; // ceil div
      DateTime cur = DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
      for (int i = 0; i < blocks; i++) {
        occupied.add(cur);
        cur = cur.add(Duration(minutes: slotMinutes));
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
                  await reservationProvider.loadReservations();
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
                        onPrevWeek: () {
                          final prev = weekStart.subtract(const Duration(days: 7));
                          setState(() => focusedDay = DateTime(prev.year, prev.month, prev.day));
                        },
                        onNextWeek: () {
                          final next = weekStart.add(const Duration(days: 7));
                          setState(() => focusedDay = DateTime(next.year, next.month, next.day));
                        },
                        selectedDay: selectedDay,
                        selectedTime: selectedTime,
                        onSelectSlot: onSelectSlot,
                        dayStart: const TimeOfDay(hour: 8, minute: 0),
                        dayEnd: const TimeOfDay(hour: 16, minute: 0),
                        slotMinutes: slotMinutes,
                        lunchStart: const TimeOfDay(hour: 12, minute: 0),
                        lunchEnd: const TimeOfDay(hour: 13, minute: 0),
                        occupied: occupied,
                        firstDay: firstDay,
                        lastDay: lastDay),
                  ),
                  if (selectedDay != null && selectedTime != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('Selected: ${DateFormat('EEE d.MM.').format(selectedDay!)} ${selectedTime!.format(context)}', style: TextStyle(color: Colors.grey[700])))
                ])),
          )
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
