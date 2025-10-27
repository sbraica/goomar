import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/weekday_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/reservation.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/booking_form_provider.dart';
import '../../providers/booking_ui_provider.dart';
import '../operator/login_screen.dart';
import '../../services/api_client.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _submitBooking() async {
    final form = Provider.of<BookingFormProvider>(context, listen: false);
    final ui = Provider.of<BookingUiProvider>(context, listen: false);
    if (_formKey.currentState!.validate() && form.selectedDay != null && form.selectedTime != null) {
      final start = DateTime(form.selectedDay!.year, form.selectedDay!.month, form.selectedDay!.day, form.selectedTime!.hour, form.selectedTime!.minute);
      final random = Random();
      final reservation = Reservation(
          id: 0,
          pending: true,
          approved: false,
          username: ui.name,
          email: ui.email,
          phone: ui.phone,
          registration: ui.registration,
          longService: form.selectedService,
          dateTime: start);

      ui.isSubmitting = true;
      try {
        // Send to backend
        await ApiClient.instance.postReservation(reservation);
        // Optionally also keep local list up-to-date for operator view
        Provider.of<ReservationProvider>(context, listen: false).addReservation(reservation);

        if (!mounted) return;
        showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                    title: const Text('Success!'),
                    content: const Text('Your reservation has been submitted successfully. You will receive a confirmation once approved.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          // Close the dialog and clear the form & provider state
                          Navigator.of(ctx).pop();
                          _formKey.currentState?.reset();
                          ui.clearInputs();
                          Provider.of<BookingFormProvider>(context, listen: false).reset();
                        },
                        child: const Text('OK'),
                      )
                    ]));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit reservation. ${e.toString()}'), backgroundColor: Colors.red));
      } finally {
        if (mounted) ui.isSubmitting = false;
      }
    } else if (form.selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date')));
    } else if (form.selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a time slot')));
    }
  }

  bool _isValidEmail(String v) => v.contains('@');

  bool _isFormComplete(BookingFormProvider form, BookingUiProvider ui) {
    return ui.areTextFieldsComplete && form.selectedDay != null && form.selectedTime != null;
  }

  @override
  Widget build(BuildContext context) {
    final form = Provider.of<BookingFormProvider>(context);
    final ui = Provider.of<BookingUiProvider>(context);
    return Scaffold(
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                        key: _formKey,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: LayoutBuilder(builder: (context, constraints) {
                                    final double fieldWidth = constraints.maxWidth / 3;
                                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      const Text('Personal Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 16),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: FractionallySizedBox(
                                          widthFactor: 1 / 3,
                                          child: TextFormField(
                                              controller: ui.nameController,
                                              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter your name';
                                                }
                                                return null;
                                              }),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: fieldWidth,
                                        child: TextFormField(
                                            controller: ui.emailController,
                                            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                                            keyboardType: TextInputType.emailAddress,
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please enter your email';
                                              }
                                              if (!value.contains('@')) {
                                                return 'Please enter a valid email';
                                              }
                                              return null;
                                            }),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: fieldWidth,
                                        child: TextFormField(
                                            controller: ui.phoneController,
                                            decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
                                            keyboardType: TextInputType.phone,
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please enter your phone number';
                                              }
                                              return null;
                                            }),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: fieldWidth,
                                        child: TextFormField(
                                            controller: ui.registrationController,
                                            decoration: const InputDecoration(labelText: 'Registracija', prefixIcon: Icon(Icons.directions_car)),
                                            keyboardType: TextInputType.text,
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please enter registration number';
                                              }
                                              return null;
                                            }),
                                      ),
                                      const SizedBox(height: 12),
                                      // Horizontal service selector below phone number
                                      Row(children: [
                                        const Icon(Icons.build_circle, size: 18, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        const Text('Service:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                                        const SizedBox(width: 12),
                                        Expanded(
                                            child: Wrap(spacing: 8, runSpacing: 8, children: [
                                          ChoiceChip(
                                              label: Text('Small', style: TextStyle(color: form.selectedService ? null : Colors.white, fontWeight: FontWeight.w600)),
                                              selected: form.selectedService == false,
                                              showCheckmark: false,
                                              selectedColor: Theme.of(context).primaryColor,
                                              onSelected: (_) => form.selectService(false)),
                                          ChoiceChip(
                                              label: Text('Big', style: TextStyle(color: form.selectedService ? Colors.white : null, fontWeight: FontWeight.w600)),
                                              selected: form.selectedService == true,
                                              showCheckmark: false,
                                              selectedColor: Theme.of(context).primaryColor,
                                              onSelected: (_) => form.selectService(true))
                                        ]))
                                      ]),

                                      const SizedBox(height: 24),
                                      const Divider(height: 1),
                                      const SizedBox(height: 16),

                                      const Text('Select Date & Time', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 16),
                                      LayoutBuilder(builder: (context, constraints) {
                                        final isWide = constraints.maxWidth >= 700;
                                        final calendarWidget = WeekdayTwoWeekCalendar(
                                            firstDay: DateTime.now(),
                                            lastDay: DateTime.now().add(const Duration(days: 90)),
                                            focusedDay: form.focusedDay,
                                            selectedDay: form.selectedDay,
                                            onDaySelected: form.selectDay,
                                            onPrevPage: () => form.setFocusedMonth(DateTime(form.focusedDay.year, form.focusedDay.month - 1, 1)),
                                            onNextPage: () => form.setFocusedMonth(DateTime(form.focusedDay.year, form.focusedDay.month + 1, 1)),
                                            dayButtonScale: 1.0);

                                        final timeWidget = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          const Text('Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 12),
                                          if (form.selectedDay == null)
                                            Text('Select a weekday to see slots', style: TextStyle(color: Colors.grey[700]))
                                          else ...[
                                            Builder(builder: (context) {
                                              final slots = form.generateTimeSlots();
                                              if (slots.isEmpty) {
                                                return Text('No available time slots for the selected day.', style: TextStyle(color: Colors.red[700]));
                                              }
                                              return Wrap(spacing: 8, runSpacing: 8, children: [
                                                for (final t in slots)
                                                  ChoiceChip(
                                                      label: Text(form.formatTimeOfDay(t),
                                                          style: TextStyle(color: form.selectedTime == t ? Colors.white : null, fontWeight: FontWeight.w600)),
                                                      selected: form.selectedTime == t,
                                                      showCheckmark: false,
                                                      selectedColor: Theme.of(context).primaryColor,
                                                      onSelected: (_) => form.selectTime(t))
                                              ]);
                                            })
                                          ]
                                        ]);

                                        if (isWide) {
                                          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            // Calendar on the left
                                            Expanded(flex: 3, child: calendarWidget),
                                            const SizedBox(width: 16),
                                            // Time slots on the right
                                            Expanded(flex: 2, child: timeWidget)
                                          ]);
                                        } else {
                                          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [calendarWidget, const SizedBox(height: 16), timeWidget]);
                                        }
                                      })
                                    ]);
                                  }))),
                          const SizedBox(height: 24),
                          ElevatedButton(
                              onPressed: _isFormComplete(form, ui) && !ui.isSubmitting ? _submitBooking : null,
                              style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: ui.isSubmitting
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Submit Reservation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                          const SizedBox(height: 16),
                        ]))))));
  }
}
