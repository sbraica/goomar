import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tyre_reservation_app/models/update_reservation.dart';
import '../providers/reservation_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/week_time_grid.dart';
import '../widgets/edit_email_dialog.dart';

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({Key? key}) : super(key: key);

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
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
        Provider.of<ReservationProvider>(context, listen: false).setFocusedDay(monday);
      } catch (e) {
        if (!mounted) return;
        final msg = e.toString().toLowerCase();
        final isAuthError = msg.contains('unauthorized') || msg.contains('expired');
        if (isAuthError) {
          Provider.of<AuthProvider>(context, listen: false).logout();
          if (!mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        } else {
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
    final DateTime focusedDay = reservationProvider.focusedDay;

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

    final daySlots = _daySlots();

    for (final r in reservationProvider.reservations) {
      final dt = r.date_time;
      print(dt);
      if (dt.isBefore(weekStart) || !dt.isBefore(weekEnd)) continue;

      spans.add(ReservationSpan(
          id: r.id!, start: DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute), long: r.long, label: r.name, phone: r.phone, approved: r.confirmed, emailOk: r.emailOk));
      final DateTime resStart = DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
      final DateTime resEnd = resStart.add(Duration(minutes: r.long ? 30 : 15));
      for (final tod in daySlots) {
        final slotStart = DateTime(dt.year, dt.month, dt.day, tod.hour, tod.minute);
        final slotEnd = slotStart.add(Duration(minutes: slotMinutes));
        if (resStart.isBefore(slotEnd) && resEnd.isAfter(slotStart)) {
          occupied.add(slotStart);
        }
      }
    }

    final firstDay = DateTime.now();
    final lastDay = DateTime.now().add(const Duration(days: 90));

    return Scaffold(
        appBar: AppBar(title: const Text('Bosnić - rezervacija termina servisa'), actions: [
          IconButton(
              onPressed: () async {
                try {
                  final currentMonday = _mondayOf(focusedDay);
                  await reservationProvider.loadReservations(weekStart: currentMonday);
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to refresh reservations'), backgroundColor: Colors.red));
                  }
                }
              },
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh)),
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () {
                authProvider.logout();
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              })
        ]),
        body: Column(children: [
          if (reservationProvider.isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Expanded(
                        child: WeekTimeGrid(
                            weekStart: weekStart,
                            onPrevWeek: () async {
                              if (reservationProvider.isLoading) return;
                              final base = _mondayOf(reservationProvider.focusedDay);
                              final prev = DateTime(base.year, base.month, base.day - 7);
                              reservationProvider.setFocusedDay(DateTime(prev.year, prev.month, prev.day));
                              reservationProvider.loadReservations(weekStart: prev).catchError((_) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Greška učitavanja rezervacija!'), backgroundColor: Colors.red));
                                }
                              });
                            },
                            onNextWeek: () async {
                              if (reservationProvider.isLoading) return;
                              final base = _mondayOf(reservationProvider.focusedDay);
                              final next = DateTime(base.year, base.month, base.day + 7);
                              reservationProvider.setFocusedDay(DateTime(next.year, next.month, next.day));
                              reservationProvider.loadReservations(weekStart: next).catchError((_) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Greška učitavanja rezervacija!'), backgroundColor: Colors.red));
                                }
                              });
                            },
                            onEdit: (span) async {
                              final rp = Provider.of<ReservationProvider>(context, listen: false);
                              final existing =
                                  rp.reservations.firstWhere((r) => r.id == span.id, orElse: () => rp.reservations.isNotEmpty ? rp.reservations.first : null as dynamic);
                              final initialEmail = (existing is dynamic && existing?.email is String) ? existing.email as String : '';

                              await showDialog(
                                  context: context,
                                  builder: (ctx) => EditEmailDialog(
                                      initialEmail: initialEmail,
                                      onSave: (value) => rp.updateReservationRemote(UpdateReservation(id: span.id!, sendMail: true, email: value, approved: false)),
                                      onConfirm: (value) => rp.updateReservationRemote(UpdateReservation(id: span.id!, sendMail: false, approved: true))));
                            },
                            onCheck: (span) async {
                              try {
                                await Provider.of<ReservationProvider>(context, listen: false)
                                    .updateReservationRemote(UpdateReservation(id: span.id, sendMail: true, approved: true));
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update approval: $e'), backgroundColor: Colors.red));
                                }
                              }
                            },
                            onDelete: (span) async {
                              _showConfirmDialog(context, 'Delete appointment', 'Are you sure you want to delete this appointment?', () async {
                                try {
                                  await Provider.of<ReservationProvider>(context, listen: false).deleteReservationRemote(span.id!);
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete appointment: $e'), backgroundColor: Colors.red));
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
