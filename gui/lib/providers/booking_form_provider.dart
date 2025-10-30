import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_client.dart';

class BookingFormProvider with ChangeNotifier {
  // Booking selections
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  TimeOfDay? selectedTime;
  bool selectedService = false; // false = Small, true = Big (long)

  // Slots state and loading flag (no caching)
  final List<TimeOfDay> _slots = [];
  bool isLoadingSlots = false;

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
    // always fetch fresh slots for this day/service
    _slots.clear();
    _fetchSlots(day, selectedService);
    notifyListeners();
  }

  void selectService(bool serviceType) {
    selectedService = serviceType;
    // reset time when service changes
    selectedTime = null;
    // always fetch fresh slots for current date/service
    final day = selectedDay;
    _slots.clear();
    if (day != null) {
      _fetchSlots(day, selectedService);
    }
    notifyListeners();
  }

  void selectTime(TimeOfDay time) {
    selectedTime = time;
    notifyListeners();
  }

  // Reset all selections to initial defaults
  void reset() {
    focusedDay = DateTime.now();
    selectedDay = null;
    selectedTime = null;
    selectedService = false;
    _slots.clear();
    isLoadingSlots = false;
    notifyListeners();
  }

  // Helpers
  String formatTimeOfDay(TimeOfDay t) {
    final dt = DateTime(0, 1, 1, t.hour, t.minute);
    return DateFormat('HH:mm').format(dt);
  }

  // Public API for UI: returns current slots (no caching)
  List<TimeOfDay> generateTimeSlots() {
    if (selectedDay == null) return [];
    return List.unmodifiable(_slots);
  }

  Future<void> _fetchSlots(DateTime day, bool isLong) async {
    isLoadingSlots = true;
    notifyListeners();
    try {
      final slots = await ApiClient.instance.getFreeSlots(day, isLong: isLong);
      // Only apply if still on the same selection to avoid race conditions
      if (selectedDay != null &&
          selectedDay!.year == day.year &&
          selectedDay!.month == day.month &&
          selectedDay!.day == day.day &&
          selectedService == isLong) {
        _slots
          ..clear()
          ..addAll(slots);
      }
    } catch (_) {
      // On error, keep slots empty; UI will show a message
      _slots.clear();
    } finally {
      isLoadingSlots = false;
      notifyListeners();
    }
  }
}