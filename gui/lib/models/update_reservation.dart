class UpdateReservation {
  final String id;
  final bool sendMail;
  final bool approved;
  final String? email;

  UpdateReservation({required this.id, required this.sendMail, required this.approved, this.email});

  factory UpdateReservation.fromJson(Map<String, dynamic> json) {
    return UpdateReservation(id: json['id'], sendMail: (json['sendMail'] == true), approved: (json['approved'] == true), email: json['email'] as String?);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'sendMail': sendMail, 'email': email, 'approved': approved};
  }
}
