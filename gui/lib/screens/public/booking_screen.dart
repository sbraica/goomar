import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/weekday_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/reservation.dart';
import '../../providers/reservation_provider.dart';
import '../operator/login_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TimeOfDay? _selectedTime;
  ServiceType _selectedService = ServiceType.small;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  List<TimeOfDay> _generateTimeSlots() {
    if (_selectedDay == null) return [];
    final List<TimeOfDay> slots = [];
    final int step = _selectedService == ServiceType.small ? 15 : 30;

    // Working hours
    TimeOfDay start = const TimeOfDay(hour: 8, minute: 0);
    final TimeOfDay end = const TimeOfDay(hour: 16, minute: 0);

    // Lunch break [12:00, 13:00) — any slot overlapping this window is excluded
    const TimeOfDay lunchStart = TimeOfDay(hour: 12, minute: 0);
    const TimeOfDay lunchEnd = TimeOfDay(hour: 13, minute: 0);

    final bool isToday = DateUtils.isSameDay(_selectedDay, DateTime.now());
    final TimeOfDay now = TimeOfDay.fromDateTime(DateTime.now());

    // helper to compare TimeOfDay
    int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

    final int lunchStartMin = _toMinutes(lunchStart);
    final int lunchEndMin = _toMinutes(lunchEnd);

    while (_toMinutes(start) <= _toMinutes(end) - step) {
      final int s = _toMinutes(start);
      final int e = s + step;

      // Exclude slots that overlap lunch
      final bool overlapsLunch = s < lunchEndMin && e > lunchStartMin;

      // Hide past times if selected day is today and not overlapping lunch
      if (!overlapsLunch && (!isToday || s > _toMinutes(now))) {
        slots.add(start);
      }

      final int total = s + step;
      start = TimeOfDay(hour: total ~/ 60, minute: total % 60);
    }
    return slots;
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final dt = DateTime(0, 1, 1, t.hour, t.minute);
    return DateFormat('HH:mm').format(dt);
  }

  void _submitBooking() {
    if (_formKey.currentState!.validate() && _selectedDay != null && _selectedTime != null) {
      final duration = _selectedService == ServiceType.small ? 15 : 30;
      final start = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final reservation = Reservation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        serviceType: _selectedService,
        reservationDate: start,
        durationMinutes: duration,
        createdAt: DateTime.now(),
      );

      Provider.of<ReservationProvider>(context, listen: false).addReservation(reservation);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Success!'),
          content: const Text(
            'Your reservation has been submitted successfully. '
            'You will receive a confirmation once approved.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
    } else if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Book Appointment'),
          elevation: 0,
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.login),
              label: const Text('Operator Login'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: Icon(Icons.phone),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Registracija',
                                prefixIcon: Icon(Icons.text_increase_sharp),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter registration number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            // Horizontal service selector below phone number
                            Row(
                              children: [
                                const Icon(Icons.build_circle, size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                const Text(
                                  'Service:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      ChoiceChip(
                                        label: Text(
                                          'Small',
                                          style: TextStyle(
                                            color: _selectedService == ServiceType.small ? Colors.white : null,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        selected: _selectedService == ServiceType.small,
                                        showCheckmark: false,
                                        selectedColor: Theme.of(context).primaryColor,
                                        onSelected: (_) {
                                          setState(() {
                                            _selectedService = ServiceType.small;
                                            _selectedTime = null; // reset time when service changes
                                          });
                                        },
                                      ),
                                      ChoiceChip(
                                        label: Text(
                                          'Big',
                                          style: TextStyle(
                                            color: _selectedService == ServiceType.big ? Colors.white : null,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        selected: _selectedService == ServiceType.big,
                                        showCheckmark: false,
                                        selectedColor: Theme.of(context).primaryColor,
                                        onSelected: (_) {
                                          setState(() {
                                            _selectedService = ServiceType.big;
                                            _selectedTime = null; // reset time when service changes
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Combined Date & Time selection
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Date & Time',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth >= 700;
                                final calendarWidget = WeekdayTwoWeekCalendar(
                                  firstDay: DateTime.now(),
                                  lastDay: DateTime.now().add(const Duration(days: 90)),
                                  focusedDay: _focusedDay,
                                  selectedDay: _selectedDay,
                                  onDaySelected: (selectedDay) {
                                    setState(() {
                                      _selectedDay = selectedDay;
                                      _focusedDay = selectedDay;
                                      _selectedTime = null; // reset time when date changes
                                    });
                                  },
                                  onPrevPage: () {
                                    setState(() {
                                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                                    });
                                  },
                                  onNextPage: () {
                                    setState(() {
                                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                                    });
                                  },
                                  dayButtonScale: 1.0,
                                );

                                final timeWidget = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text(
                                    'Time',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (_selectedDay == null)
                                    Text(
                                      'Select a weekday to see slots',
                                      style: TextStyle(color: Colors.grey[700]),
                                    )
                                  else ...[
                                    Builder(builder: (context) {
                                      final slots = _generateTimeSlots();
                                      if (slots.isEmpty) {
                                        return Text(
                                          'No available time slots for the selected day.',
                                          style: TextStyle(color: Colors.red[700]),
                                        );
                                      }
                                      return Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          for (final t in slots)
                                            ChoiceChip(
                                              label: Text(
                                                _formatTimeOfDay(t),
                                                style: TextStyle(
                                                  color: _selectedTime == t ? Colors.white : null,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              selected: _selectedTime == t,
                                              showCheckmark: false,
                                              selectedColor: Theme.of(context).primaryColor,
                                              onSelected: (_) {
                                                setState(() => _selectedTime = t);
                                              },
                                            ),
                                        ],
                                      );
                                    })
                                  ]
                                ]);

                                if (isWide) {
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Calendar on the left
                                      Expanded(
                                        flex: 3,
                                        child: calendarWidget,
                                      ),
                                      const SizedBox(width: 16),
                                      // Time slots on the right
                                      Expanded(
                                        flex: 2,
                                        child: timeWidget,
                                      ),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      calendarWidget,
                                      const SizedBox(height: 16),
                                      timeWidget,
                                    ],
                                  );
                                }
                              },
                            ),
                            if (_selectedDay != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Text(
                                  'Selected: ${DateFormat('MMMM dd, yyyy').format(_selectedDay!)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitBooking,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Submit Reservation',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
