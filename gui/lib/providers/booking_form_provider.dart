import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reservation.dart';
import '../services/api_client.dart';

class BookingFormProvider with ChangeNotifier {
  // Booking selections
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  TimeOfDay? selectedTime;
  bool selectedService = false; // false = Small, true = Big (long)

  // Slots cache and loading state
  final Map<String, List<TimeOfDay>> _slotsCache = {};
  bool isLoadingSlots = false;

  String _cacheKey(DateTime day, bool isLong) => '${day.year}-${day.month}-${day.day}-L$isLong';

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
    // trigger fetching slots for this day/service
    _ensureSlots();
    notifyListeners();
  }

  void selectService(bool serviceType) {
    selectedService = serviceType;
    // reset time when service changes
    selectedTime = null;
    // trigger fetching slots for current date/service
    _ensureSlots();
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
    _slotsCache.clear();
    isLoadingSlots = false;
    notifyListeners();
  }

  // Helpers
  String formatTimeOfDay(TimeOfDay t) {
    final dt = DateTime(0, 1, 1, t.hour, t.minute);
    return DateFormat('HH:mm').format(dt);
  }

  // Public API for UI: returns cached slots if available, otherwise triggers fetch
  // and returns an empty list until data arrives.
  List<TimeOfDay> generateTimeSlots() {
    if (selectedDay == null) return [];
    final key = _cacheKey(selectedDay!, selectedService);
    final cached = _slotsCache[key];
    if (cached != null) return cached;

    // If we don't have data, start fetching in background
    _ensureSlots();
    return [];
  }

  void _ensureSlots() {
    final day = selectedDay;
    if (day == null) return;
    final key = _cacheKey(day, selectedService);
    if (_slotsCache.containsKey(key) || isLoadingSlots) return;
    _fetchSlots(day, selectedService);
  }

  Future<void> _fetchSlots(DateTime day, bool isLong) async {
    isLoadingSlots = true;
    notifyListeners();
    try {
      final slots = await ApiClient.instance.getFreeSlots(day, isLong: isLong);
      _slotsCache[_cacheKey(day, isLong)] = slots;
    } catch (_) {
      // On error, keep empty (no cache entry), UI will show a message
    } finally {
      isLoadingSlots = false;
      notifyListeners();
    }
  }
}