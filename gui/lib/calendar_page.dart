import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  void _removeUserSelectedSlots() {
    _appointments.removeWhere((a) => a.subject == 'Team sync');
    _dataSource.appointments = _appointments;
  }
  DateTime? _selectedDate;
  late List<Appointment> _appointments;
  late _SampleDataSource _dataSource;
  late CalendarController _calendarController;

  // Form state
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _vehicleController = TextEditingController();
  bool _formValid = false;

  @override
  void initState() {
    super.initState();
    _appointments = _getSampleAppointments();
    _dataSource = _SampleDataSource(_appointments);
    _calendarController = CalendarController();
    _calendarController.view = CalendarView.workWeek;

    void listener() {
      final nowValid = _formKey.currentState?.validate() ?? false;
      if (nowValid != _formValid) {
        setState(() {
          _formValid = nowValid;
        });
      }
    }

    _nameController.addListener(listener);
    _emailController.addListener(listener);
    _vehicleController.addListener(listener);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  void _jumpMonths(int months) {
    final base = _calendarController.displayDate ?? DateTime.now();
    // Move to the first day of target month, then clamp original day into valid range
    final DateTime firstOfTarget = DateTime(base.year, base.month + months, 1, base.hour, base.minute, base.second);
    final int targetMonthDays = DateTime(firstOfTarget.year, firstOfTarget.month + 1, 0).day;
    final int clampedDay = base.day.clamp(1, targetMonthDays);
    final DateTime target = DateTime(firstOfTarget.year, firstOfTarget.month, clampedDay, base.hour, base.minute, base.second);
    setState(() {
      _calendarController.displayDate = target;
    });
  }

  void _jumpToday() {
    setState(() {
      _calendarController.displayDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Barron's Timeslot Calendar"),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.always,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'User name',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'User email',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Email is required';
                      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _vehicleController,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle registration',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    textInputAction: TextInputAction.done,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Vehicle registration is required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(_formValid ? Icons.check_circle : Icons.info, color: _formValid ? Colors.green : Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formValid
                              ? 'Form complete. You can select a time slot.'
                              : 'Fill all fields to enable timeslot selection.',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Previous month',
                            icon: const Icon(Icons.keyboard_double_arrow_left),
                            onPressed: () => _jumpMonths(-1),
                          ),
                          IconButton(
                            tooltip: 'Next month',
                            icon: const Icon(Icons.keyboard_double_arrow_right),
                            onPressed: () => _jumpMonths(1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Stack(
              children: [
                SfCalendar(
                  controller: _calendarController,
                  view: CalendarView.workWeek,
                  timeSlotViewSettings: const TimeSlotViewSettings(
                    startHour: 8,
                    endHour: 16,
                    timeInterval: Duration(minutes: 30),
                    timeFormat: 'HH:mm',
                    nonWorkingDays: <int>[DateTime.saturday, DateTime.sunday],
                  ),
                  appointmentBuilder: (context, details) {
                    final Appointment appt = details.appointments.first as Appointment;
                    final bool isUserSlot = appt.subject == 'Team sync';
                    return Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: appt.color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              appt.subject,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isUserSlot)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _appointments.remove(appt);
                                    _dataSource.appointments = _appointments;
                                    _dataSource.notifyListeners(CalendarDataSourceAction.remove, <Appointment>[appt]);
                                  });
                                },
                                child: const Icon(Icons.close, size: 18, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                  onSelectionChanged: (CalendarSelectionDetails details) {
                    if (!_formValid) return; // gate selection when form invalid
                    setState(() {
                      _selectedDate = details.date;
                    });
                  },
                  onTap: (CalendarTapDetails details) {
                    if (!_formValid) return; // prevent adding when form invalid

                    // Add a "Team sync" appointment when user taps a timeslot/day cell
                    final DateTime? tapped = details.date;
                    if (tapped == null) return;

                    // Only react to tapping on calendar cells (not existing appointments)
                    if (details.targetElement == CalendarElement.calendarCell ||
                        details.targetElement == CalendarElement.agenda ||
                        details.targetElement == CalendarElement.allDayPanel ||
                        details.targetElement == CalendarElement.viewHeader) {
                      final DateTime start = DateTime(tapped.year, tapped.month, tapped.day, tapped.hour, tapped.minute);
                      // Enforce working hours: 08:00 <= start < 16:00
                      if (start.hour < 8 || start.hour >= 16) {
                        return;
                      }
                      final DateTime end = start.add(const Duration(minutes: 30));

                      // Prevent exact duplicate for the same slot and subject
                      final bool exists = _appointments.any((a) =>
                          a.startTime == start && a.endTime == end && a.subject == 'Team sync');
                      if (!exists) {
                        // Enforce single-slot selection: remove any previous user-added slots (keep other subjects if needed)
                        _removeUserSelectedSlots();
                        setState(() {
                          _appointments.add(Appointment(
                            startTime: start,
                            endTime: end,
                            subject: 'Team sync',
                            color: Colors.blue,
                          ));
                          // Notify data source about change
                          _dataSource.appointments = _appointments;
                          _dataSource.notifyListeners(CalendarDataSourceAction.add, _appointments);
                        });
                      }
                    }
                  },
                  monthViewSettings: const MonthViewSettings(
                    appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
                  ),
                  dataSource: _dataSource,
                ),
                if (!_formValid)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.05),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: const Text('Complete the form above to enable the calendar'),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
                ),
              ),
            ),
          ),
      bottomNavigationBar: _selectedDate != null
          ? Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Selected: ${_selectedDate!.toLocal()}',
                textAlign: TextAlign.center,
              ),
            )
          : null,
    );
  }
}

List<Appointment> _getSampleAppointments() {
  final List<Appointment> meetings = <Appointment>[];
  final DateTime today = DateTime.now();
  final DateTime startTime = DateTime(today.year, today.month, today.day, 9, 0, 0);
  final DateTime endTime = startTime.add(const Duration(hours: 1));
  meetings.add(Appointment(
    startTime: startTime,
    endTime: endTime,
    subject: 'Team sync',
    color: Colors.blue,
  ));
  return meetings;
}


class _SampleDataSource extends CalendarDataSource {
  _SampleDataSource(List<Appointment> source) {
    appointments = source;
  }
}