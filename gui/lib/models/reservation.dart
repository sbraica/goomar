class Reservation {
  final int id;
  final String username;
  final String email;
  final String phone;
  final String registration;
  final bool longService;
  bool pending;
  bool approved;
  final DateTime dateTime;

  Reservation(
      {required this.id,
      required this.username,
      required this.email,
      required this.phone,
      required this.registration,
      required this.longService,
      required this.pending,
      required this.approved,
      required this.dateTime});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'registration': registration,
      'longService': longService,
      'date': dateTime.toIso8601String(),
    };
  }
}
