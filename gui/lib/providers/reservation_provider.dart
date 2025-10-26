import 'package:flutter/foundation.dart';
import '../models/reservation.dart';

class ReservationProvider with ChangeNotifier {
  final List<Reservation> _reservations = [];

  List<Reservation> get reservations => [..._reservations];

  List<Reservation> get pendingReservations {
    return _reservations.where((r) => r.isPending).toList();
  }

  List<Reservation> get approvedReservations {
    return _reservations.where((r) => r.isApproved).toList();
  }

  void addReservation(Reservation reservation) {
    _reservations.add(reservation);
    notifyListeners();
  }

  void approveReservation(String id) {
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reservations[index].isApproved = true;
      _reservations[index].isPending = false;
      notifyListeners();
    }
  }

  void rejectReservation(String id) {
    _reservations.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  List<DateTime> getBookedDates() {
    return _reservations
        .map((r) => DateTime(
      r.reservationDate.year,
      r.reservationDate.month,
      r.reservationDate.day,
    ))
        .toList();
  }
}