import 'package:flutter/foundation.dart';
import '../models/reservation.dart';
import '../services/api_client.dart';

class ReservationProvider with ChangeNotifier {
  final List<Reservation> _reservations = [];
  bool _isLoading = false;
  String? _lastError;

  List<Reservation> get reservations => [..._reservations];
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  List<Reservation> get pendingReservations {
    return _reservations.where((r) => r.pending).toList();
  }

  List<Reservation> get approvedReservations {
    return _reservations.where((r) => r.approved).toList();
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
      _reservations[index].approved = true;
      _reservations[index].pending = false;
      notifyListeners();
    }
  }

  void rejectReservation(int id) {
    _reservations.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  List<DateTime> getBookedDates() {
    return _reservations.map((r) => DateTime(r.dateTime.year, r.dateTime.month, r.dateTime.day)).toList();
  }

  Future<void> loadReservations() async {
    _setError(null);
    _setLoading(true);
    try {
      final list = await ApiClient.instance.getReservations();
      setReservations(list);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
