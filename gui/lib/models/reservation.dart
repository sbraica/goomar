enum ServiceType { small, big }

class Reservation {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final ServiceType serviceType;

  // reservationDate now represents the START date & time of the appointment
  final DateTime reservationDate;

  // duration of the appointment in minutes (15 for small, 30 for big)
  final int durationMinutes;
  final DateTime createdAt;
  bool isApproved;
  bool isPending;

  Reservation(
      {required this.id,
      required this.name,
      required this.email,
      required this.phoneNumber,
      required this.serviceType,
      required this.reservationDate,
      required this.durationMinutes,
      required this.createdAt,
      this.isApproved = false,
      this.isPending = true});

  String get serviceTypeName {
    return serviceType == ServiceType.small ? 'Small Service' : 'Big Service';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'serviceType': serviceType.toString(),
      'reservationDate': reservationDate.toIso8601String(),
      'durationMinutes': durationMinutes,
      'createdAt': createdAt.toIso8601String(),
      'isApproved': isApproved,
      'isPending': isPending
    };
  }
}
