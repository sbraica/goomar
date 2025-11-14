class UpdateReservation {
  final String id;
  final bool sendMail;
  final String? eventId;
  final String? email;

  UpdateReservation({required this.id, required this.sendMail, this.eventId, this.email});

  factory UpdateReservation.fromJson(Map<String, dynamic> json) {
    return UpdateReservation(id: json['id'], sendMail: (json['sendMail'] == true), email: json['email'] as String?, eventId: json['email'] as String?);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'sendMail': sendMail, 'eventId': eventId, 'email': email};
  }
}
