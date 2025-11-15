import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tyre_reservation_app/models/update_reservation.dart';
import '../models/reservation.dart';
import '../services/api_client.dart';

class ReservationProvider with ChangeNotifier {
  final List<Reservation> _reservations = [];
  bool _isLoading = false;
  String? _lastError;

  // UI state moved to provider
  DateTime focusedDay = DateTime.now();
  //DateTime? selectedDay;
  //TimeOfDay? selectedTime;

  int _filterMask = 0;

  int get filterMask => _filterMask;

  bool get filterInvalid => (_filterMask & 0x1) != 0;

  bool get filterUnconfirmed => (_filterMask & 0x2) != 0;

  bool get filterConfirmed => (_filterMask & 0x4) != 0;

  void _setFilterMask(int value) {
    if (_filterMask == value) return;
    _filterMask = value;
    notifyListeners();
    // Refresh on filter change
    final monday = _mondayOf(focusedDay);
    loadReservations(weekStart: monday);
  }

  void setFilterInvalid(bool v) {
    // When Invalid is checked, disable (and clear) the other two filters to avoid conflicting states.
    const bitInvalid = 0x1;
    const bitUnconfirmed = 0x2;
    const bitConfirmed = 0x4;
    int next;
    if (v) {
      next = (_filterMask | bitInvalid) & ~(bitUnconfirmed | bitConfirmed);
    } else {
      next = (_filterMask & ~bitInvalid);
    }
    _setFilterMask(next);
  }

  void setFilterUnconfirmed(bool v) {
    final bit = 0x2;
    final next = v ? (_filterMask | bit) : (_filterMask & ~bit);
    _setFilterMask(next);
  }

  void setFilterConfirmed(bool v) {
    final bit = 0x4;
    final next = v ? (_filterMask | bit) : (_filterMask & ~bit);
    _setFilterMask(next);
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _mondayOf(DateTime d) => _dateOnly(d).subtract(Duration(days: d.weekday - DateTime.monday));

  List<Reservation> get reservations => [..._reservations];

  bool get isLoading => _isLoading;

  String? get lastError => _lastError;

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

  void setApproved(String id, bool value) {
    final index = _reservations.indexWhere((r) => r.id != null && r.id == id);
    if (index != -1) {
      _reservations[index].confirmed = value;
      // if approved => not pending; if unapproved => pending
      _reservations[index].pending = !value;
      notifyListeners();
    }
  }

  /// Toggle approved state and call backend PATCH to persist.
  /// Uses optimistic update; reverts on error and sets lastError.
  Future<void> setApprovedRemote(String id, bool value) async {
    _setError(null);
    final index = _reservations.indexWhere((r) => r.id != null && r.id == id);
    if (index == -1) return;
    final prevApproved = _reservations[index].confirmed;
    final prevPending = _reservations[index].pending;

    // Optimistic local update
    setApproved(id, value);

    try {
      final eventId = (_reservations[index].id ?? _reservations[index].id);
      if (eventId == null || eventId.isEmpty) throw Exception('Missing event id for appointment update');
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
  Future<void> deleteReservationRemote(String id) async {
    _setError(null);
    final index = _reservations.indexWhere((r) => r.id != null && r.id == id);
    if (index == -1) return;
    final removed = _reservations[index];

    // Optimistic remove
    _reservations.removeAt(index);
    notifyListeners();

    try {
      final eventId = (removed.id ?? removed.id);
      if (eventId == null || eventId.isEmpty) throw Exception('Missing event id for appointment deletion');
      await ApiClient.instance.deleteAppointment(eventId);
    } catch (e) {
      // Reinsert on error
      _reservations.insert(index, removed);
      _setError(e.toString());
      notifyListeners();
      rethrow;
    }
  }

  /// Update reservation both remotely and locally.
  Future<void> updateReservationRemote(UpdateReservation ur) async {
    _setError(null);
    final index = _reservations.indexWhere((r) => r.id != null && r.id == ur.id);
    if (index == -1) throw Exception('Reservation not found');
    try {
      await ApiClient.instance.updateReservation(ur);
      final r = _reservations[index];
      _reservations[index] = Reservation(
          id: r.id,
          name: r.name,
          email: ur.email ?? r.email,
          phone: r.phone,
          registration: r.registration,
          long: r.long,
          pending: r.pending,
          confirmed: ur.approved,
          emailOk: r.emailOk,
          date_time: r.date_time);
      loadReservations(weekStart: focusedDay);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }


  void setFocusedDay(DateTime d) {
    focusedDay = d;
    notifyListeners();
  }

  Future<void> loadReservations({required DateTime weekStart}) async {
    _setError(null);
    _setLoading(true);
    try {
      final list = await ApiClient.instance.getReservations(weekStart, filter: _filterMask);
      setReservations(list);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
