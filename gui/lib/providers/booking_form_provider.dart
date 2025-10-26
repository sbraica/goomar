import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reservation.dart';

class BookingFormProvider with ChangeNotifier {
  // Booking selections
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  TimeOfDay? selectedTime;
  ServiceType selectedService = ServiceType.small;

  // Actions
  void setFocusedMonth(DateTime monthStart) {
    focusedDay = monthStart;
    notifyListeners();
  }

  void selectDay(DateTime day) {
    selectedDay = day;
    focusedDay = DateTime(day.year, day.month, day.day);
    // reset time when date changes
    selectedTime = null;
    notifyListeners();
  }

  void selectService(ServiceType serviceType) {
    selectedService = serviceType;
    // reset time when service changes
    selectedTime = null;
    notifyListeners();
  }

  void selectTime(TimeOfDay time) {
    selectedTime = time;
    notifyListeners();
  }

  // Helpers
  String formatTimeOfDay(TimeOfDay t) {
    final dt = DateTime(0, 1, 1, t.hour, t.minute);
    return DateFormat('HH:mm').format(dt);
  }

  List<TimeOfDay> generateTimeSlots() {
    if (selectedDay == null) return [];
    final List<TimeOfDay> slots = [];
    final int step = selectedService == ServiceType.small ? 15 : 30;

    // Working hours
    TimeOfDay start = const TimeOfDay(hour: 8, minute: 0);
    final TimeOfDay end = const TimeOfDay(hour: 16, minute: 0);

    // Lunch break [12:00, 13:00)
    const TimeOfDay lunchStart = TimeOfDay(hour: 12, minute: 0);
    const TimeOfDay lunchEnd = TimeOfDay(hour: 13, minute: 0);

    final bool isToday = DateUtils.isSameDay(selectedDay, DateTime.now());
    final TimeOfDay now = TimeOfDay.fromDateTime(DateTime.now());

    int toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

    final int lunchStartMin = toMinutes(lunchStart);
    final int lunchEndMin = toMinutes(lunchEnd);

    while (toMinutes(start) <= toMinutes(end) - step) {
      final int s = toMinutes(start);
      final int e = s + step;
      final bool overlapsLunch = s < lunchEndMin && e > lunchStartMin;
      if (!overlapsLunch && (!isToday || s > toMinutes(now))) {
        slots.add(start);
      }
      final int total = s + step;
      start = TimeOfDay(hour: total ~/ 60, minute: total % 60);
    }
    return slots;
  }

  int get durationMinutes => selectedService == ServiceType.small ? 15 : 30;
}