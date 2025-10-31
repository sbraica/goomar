import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/reservation.dart';
import '../services/api_client.dart';

class ReservationProvider with ChangeNotifier {
  final List<Reservation> _reservations = [];
  bool _isLoading = false;
  String? _lastError;

  // UI state moved to provider
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  TimeOfDay? selectedTime;

  List<Reservation> get reservations => [..._reservations];
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  List<Reservation> get pendingReservations {
    return _reservations.where((r) => r.pending).toList();
  }

  List<Reservation> get approvedReservations {
    return _reservations.where((r) => r.confirmed).toList();
  }

  void _setLoading(bool v) {
    if (_isLoading == v) return;
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? err) {
    _lastError = err;
    notifyListeners();
  }

  void setReservations(List<Reservation> list) {
    _reservations
      ..clear()
      ..addAll(list);
    notifyListeners();
  }

  void addReservation(Reservation reservation) {
    _reservations.add(reservation);
    notifyListeners();
  }

  void approveReservation(int id) {
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reservations[index].confirmed = true;
      _reservations[index].pending = false;
      notifyListeners();
    }
  }

  void setApproved(int id, bool value) {
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reservations[index].confirmed = value;
      // if approved => not pending; if unapproved => pending
      _reservations[index].pending = !value;
      notifyListeners();
    }
  }

  /// Toggle approved state and call backend PATCH to persist.
  /// Uses optimistic update; reverts on error and sets lastError.
  Future<void> setApprovedRemote(int id, bool value) async {
    _setError(null);
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index == -1) return;
    final prevApproved = _reservations[index].confirmed;
    final prevPending = _reservations[index].pending;

    // Optimistic local update
    setApproved(id, value);

    try {
      final eventId = (_reservations[index].event_id ?? _reservations[index].id.toString());
      await ApiClient.instance.setAppointmentApproved(eventId, value);
    } catch (e) {
      // Revert on error and expose message
      _reservations[index].confirmed = prevApproved;
      _reservations[index].pending = prevPending;
      _setError(e.toString());
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a reservation locally and remotely via DELETE endpoint.
  /// Uses optimistic removal; reinserts on failure and sets lastError.
  Future<void> deleteReservationRemote(int id) async {
    _setError(null);
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index == -1) return;
    final removed = _reservations[index];

    // Optimistic remove
    _reservations.removeAt(index);
    notifyListeners();

    try {
      final eventId = (removed.event_id ?? removed.id.toString());
      await ApiClient.instance.deleteAppointment(eventId);
    } catch (e) {
      // Reinsert on error
      _reservations.insert(index, removed);
      _setError(e.toString());
      notifyListeners();
      rethrow;
    }
  }

  void rejectReservation(int id) {
    _reservations.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  List<DateTime> getBookedDates() {
    return _reservations.map((r) => DateTime(r.date_time.year, r.date_time.month, r.date_time.day)).toList();
  }

  // UI setters for screens
  void setFocusedDay(DateTime d) {
    focusedDay = d;
    notifyListeners();
  }

  void setSelectedSlot(DateTime slot) {
    selectedDay = DateTime(slot.year, slot.month, slot.day);
    selectedTime = TimeOfDay(hour: slot.hour, minute: slot.minute);
    notifyListeners();
  }

  void clearSelectedSlot() {
    selectedDay = null;
    selectedTime = null;
    notifyListeners();
  }

  Future<void> loadReservations({required DateTime weekStart}) async {
    _setError(null);
    _setLoading(true);
    try {
      final list = await ApiClient.instance.getReservations(weekStart);
      setReservations(list);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
