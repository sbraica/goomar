
class Reservation {
  /// Reservation identifier is a UUID string provided by the backend.
  /// When creating a new reservation, this should be null (omit from payload).
  final String? id;
  final String name;
  final String email;
  final String phone;
  final String registration;
  final bool long;
  bool pending;
  bool confirmed;
  /// Indicates whether the email address is considered valid/OK by backend.
  /// Present when reservations are fetched with filter; defaults to true when absent.
  final bool emailOk;
  final DateTime date_time;

  Reservation({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.registration,
    required this.long,
    required this.pending,
    required this.confirmed,
    this.emailOk = true,
    required this.date_time,
  });

  /// Backend-to-app converter. Accepts both `date` and `date_time` ISO strings.
  factory Reservation.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is String) return DateTime.parse(v);
      throw const FormatException('Invalid date format');
    }

    // Some backends may omit pending/approved; default to pending=true unless explicitly approved.
    final bool approved = json['approved'] == true || json['confirmed'] == true;
    final bool pending = json.containsKey('pending') ? (json['pending'] == true) : !approved;

    // Prefer explicit `id` if present
    String? parseId(dynamic v) {
      if (v == null) return null;
      return v.toString().isEmpty ? null : v.toString();
    }

    return Reservation(
      id: parseId(json['id']),
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      registration: (json['registration'] ?? json['plate'] ?? '') as String,
      long: json['long'] == true,
      pending: pending,
      confirmed: json['confirmed'] == true || json['approved'] == true,
      emailOk: json.containsKey('email_ok') ? (json['email_ok'] == true) : true,
      date_time: parseDate(json['date_time'] ?? json['dateTime'] ?? json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'registration': registration,
      'long': long,
      'confirmed': confirmed,
      'date_time': date_time.toIso8601String(),
    };
  }
}
