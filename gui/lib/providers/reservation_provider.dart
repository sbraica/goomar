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
  bool _initDone = false;

  DateTime day = DateTime.now();

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

  Future<void> approve(String id, bool value) async {
    _setError(null);
    final index = _reservations.indexWhere((r) => r.id != null && r.id == id);
    if (index == -1) return;
    final prevApproved = _reservations[index].confirmed;
    final prevPending = _reservations[index].pending;

    final index2 = _reservations.indexWhere((r) => r.id != null && r.id == id);
    if (index2 != -1) {
      _reservations[index2].confirmed = value;
      _reservations[index2].pending = !value;
      notifyListeners();
    }

    try {
      final eventId = (_reservations[index].id ?? _reservations[index].id);
      if (eventId == null || eventId.isEmpty) throw Exception('Missing event id for appointment update');
      await ApiClient.instance.setAppointmentApproved(eventId, value);
    } catch (e) {
      _reservations[index].confirmed = prevApproved;
      _reservations[index].pending = prevPending;
      _setError(e.toString());
      notifyListeners();
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    _setError(null);
    final index = _reservations.indexWhere((r) => r.id != null && r.id == id);
    if (index == -1) return;
    final removed = _reservations[index];

    _reservations.removeAt(index);
    notifyListeners();

    try {
      final eventId = (removed.id ?? removed.id);
      if (eventId == null || eventId.isEmpty) throw Exception('Missing event id for appointment deletion');
      await ApiClient.instance.deleteAppointment(eventId);
    } catch (e) {
      _reservations.insert(index, removed);
      _setError(e.toString());
      notifyListeners();
      rethrow;
    }
  }

  Future<void> update(UpdateReservation ur) async {
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
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  void setDay(DateTime d) {
    day = d;
    notifyListeners();
  }

  Future<void> ensureInitialLoad() async {
    if (_initDone) return;
    _initDone = true;
    final monday = _mondayOf(DateTime.now());
    day = monday;
    notifyListeners();
    await load(weekStart: monday);
  }

  Future<void> load({required DateTime weekStart}) async {
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
