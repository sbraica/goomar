class Reservation {
  final int id;
  final String? event_id; // backend event identifier for PATCH operations
  final String username;
  final String email;
  final String phone;
  final String registration;
  final bool longService;
  bool pending;
  bool confirmed;
  final DateTime date_time;

  Reservation({
    required this.id,
    this.event_id,
    required this.username,
    required this.email,
    required this.phone,
    required this.registration,
    required this.longService,
    required this.pending,
    required this.confirmed,
    required this.date_time,
  });

  /// Backend-to-app converter. Accepts both `date` and `dateTime` ISO strings.
  factory Reservation.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is String) return DateTime.parse(v);
      throw const FormatException('Invalid date format');
    }

    // Some backends may omit pending/approved; default to pending=true unless explicitly approved.
    final bool approved = json['approved'] == true;
    final bool pending = json.containsKey('pending') ? (json['pending'] == true) : !approved;

    return Reservation(
      id: (json['id'] ?? 0) is int ? json['id'] as int : int.tryParse('${json['id'] ?? '0'}') ?? 0,
      event_id: (json['event_id'] ?? json['event_id'] ?? json['event_id'])?.toString(),
      username: (json['username'] ?? json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      registration: (json['registration'] ?? json['plate'] ?? '') as String,
      longService: json['longService'] == true,
      pending: pending,
      confirmed: json['confirmed'] == true,
      date_time: parseDate(json['date_time']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (event_id != null) 'event_id': event_id,
      'username': username,
      'email': email,
      'phone': phone,
      'registration': registration,
      'longService': longService,
      'confirmed': confirmed,
      'date_time': date_time.toIso8601String(),
    };
  }
}
