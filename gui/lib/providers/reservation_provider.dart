import 'package:flutter/foundation.dart';
import '../models/reservation.dart';

class ReservationProvider with ChangeNotifier {
  final List<Reservation> _reservations = [];

  List<Reservation> get reservations => [..._reservations];

  List<Reservation> get pendingReservations {
    return _reservations.where((r) => r.pending).toList();
  }

  List<Reservation> get approvedReservations {
    return _reservations.where((r) => r.approved).toList();
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
}
