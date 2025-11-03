import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import '../models/reservation.dart';

/// Simple API client wrapping HTTP calls to the backend.
class ApiClient {
  ApiClient._(this.baseUrl);

  /// Base URL of the backend, e.g. http://localhost:8080
  final String baseUrl;

  /// Global singleton configured from environment with a sensible default.
  /// Lazily initialized to ensure .env is loaded in main() before reading.
  static ApiClient get instance => _instance ??= ApiClient._(_resolveBaseUrl());
  static ApiClient? _instance;

  static String _resolveBaseUrl() {
    try {
      final fromEnv = dotenv.dotenv.env['HOST'];
      if (fromEnv != null && fromEnv.isNotEmpty) {
        return fromEnv;
      }
    } catch (_) {
      // dotenv may not be loaded; fall back to dart-define/default
    }
    return const String.fromEnvironment('HOST', defaultValue: '');
  }

  /// Bearer token for authenticated requests (set after login).
  String? _authToken;

  /// Set or clear the auth token. When set, all subsequent requests include
  /// `Authorization: Bearer <token>` automatically.
  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> _headers({Map<String, String>? extra, bool json = false}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${_authToken!}';
    }
    if (extra != null) headers.addAll(extra);
    return headers;
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  /// Login using plain username/password and return the received bearer token.
  /// Sends credentials as JSON body without hashing (plain fields as requested).
  Future<String> login(String username, String password) async {
    final url = _uri('/V1/token');
    try {
      final body = jsonEncode({'username': username, 'password': password});
      final resp = await http
          .post(url, headers: _headers(json: true), body: body)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw ApiException('Login failed: HTTP ${resp.statusCode}', resp.body);
      }
      // Try to parse either a raw token string or a JSON object with common keys
      String token;
      try {
        final decoded = jsonDecode(resp.body);
        if (decoded is String) {
          token = decoded;
        } else if (decoded is Map<String, dynamic>) {
          token = (decoded['token'] ?? decoded['accessToken'] ?? decoded['jwt'] ?? '').toString();
        } else {
          throw const FormatException('Unexpected login response format');
        }
      } catch (_) {
        // If not JSON, treat entire body as token
        token = resp.body.trim();
      }
      if (token.isEmpty) {
        throw ApiException('Login succeeded but no token was returned');
      }
      setAuthToken(token);
      return token;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error during login', e.toString());
    }
  }

  /// Fetch reservations for a specific week.
  /// Backend expects path: /V1/appointments/{year}/{month}/{day} where the day
  /// is the Monday (start of week). All path parts are integers (no leading zeros).
  /// Throws [ApiException] on non-2xx or network errors.
  Future<List<Reservation>> getReservations(DateTime weekStart) async {
    final y = weekStart.year;
    final m = weekStart.month; // integers in path
    final d = weekStart.day;   // start-of-week (Monday)
    final url = _uri('/V1/reservations/$y/$m/$d');
    try {
      final resp = await http.get(url, headers: _headers()).timeout(const Duration(seconds: 10));
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw ApiException('Failed to fetch reservations: HTTP ${resp.statusCode}', resp.body);
      }
      final decoded = jsonDecode(resp.body);
      if (decoded is List) {
        return decoded.map<Reservation>((e) => Reservation.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        throw ApiException('Unexpected response format when fetching reservations', resp.body);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error while fetching reservations', e.toString());
    }
  }

  /// Fetch free slots (start-end pairs) for a given day and service length.
  /// Endpoint: /V1/freeslots/{year}/{month}/{day}?long=true|false
  /// Returns a list of TimeOfDay representing the START times of available slots.
  Future<List<TimeOfDay>> getFreeSlots(DateTime day, {required bool isLong}) async {
    final y = day.year;
    final m = day.month;
    final d = day.day;
    final query = isLong ? 'true' : 'false';
    final url = _uri('/V1/freeslots/$y/$m/$d?long=$query');
    try {
      final resp = await http.get(url, headers: _headers()).timeout(const Duration(seconds: 10));
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw ApiException('Failed to fetch free slots: HTTP ${resp.statusCode}', resp.body);
      }
      final decoded = jsonDecode(resp.body);
      return _parseFreeSlots(decoded);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error while fetching free slots', e.toString());
    }
  }

  List<TimeOfDay> _parseFreeSlots(dynamic decoded) {
    final List<TimeOfDay> starts = [];

    TimeOfDay? parseTime(dynamic v) {
      if (v == null) return null;
      if (v is String) {
        final s = v.trim();
        // Try HH:mm first
        final hhmm = RegExp(r'^\d{1,2}:\d{2}$');
        if (hhmm.hasMatch(s)) {
          final parts = s.split(':');
          final h = int.tryParse(parts[0]) ?? 0;
          final m = int.tryParse(parts[1]) ?? 0;
          return TimeOfDay(hour: h, minute: m);
        }
        // Try to parse an ISO date string and extract time
        DateTime? dt;
        try { dt = DateTime.parse(s); } catch (_) {}
        if (dt != null) {
          return TimeOfDay(hour: dt.hour, minute: dt.minute);
        }
      } else if (v is num) {
        // minutes since midnight
        final minutes = v.toInt();
        final h = (minutes ~/ 60) % 24;
        final m = minutes % 60;
        return TimeOfDay(hour: h, minute: m);
      }
      return null;
    }

    if (decoded is List) {
      for (final item in decoded) {
        if (item is List && item.length >= 1) {
          final t = parseTime(item[0]);
          if (t != null) starts.add(t);
        } else if (item is Map) {
          final t = parseTime(item['start'] ?? item['from'] ?? item['s']);
          if (t != null) starts.add(t);
        } else {
          final t = parseTime(item);
          if (t != null) starts.add(t);
        }
      }
    }

    // Sort ascending
    starts.sort((a, b) => (a.hour*60+a.minute).compareTo(b.hour*60+b.minute));
    return starts;
  }

  /// Posts a reservation to the backend as JSON body.
  /// Throws [ApiException] on non-2xx or network errors.
  Future<void> postReservation(Reservation reservation) async {
    final url = _uri('/V1/reservation');
    final body = jsonEncode(reservation.toJson());
    try {
      final resp = await http.post(url, headers: _headers(json: true), body: body).timeout(const Duration(seconds: 10));
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw ApiException('Failed to create reservation: HTTP ${resp.statusCode}', resp.body);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error while creating reservation', e.toString());
    }
  }

  /// Set appointment approved/unapproved by eventId via PATCH.
  /// Endpoint: /V1/appointment?eventId=<id>
  /// Sends JSON body { "approved": true|false } for clarity, although backend may ignore it.
  Future<void> setAppointmentApproved(String eventId, bool approved) async {
    final url = _uri('/V1/appointment?eventId=$eventId');
    try {
      final resp = await http.patch(url, headers: _headers(json: true)).timeout(const Duration(seconds: 10));
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw ApiException('Failed to update appointment approval: HTTP ${resp.statusCode}', resp.body);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error while updating appointment', e.toString());
    }
  }

  /// Delete an appointment by eventId via DELETE.
  /// Endpoint: /V1/appointment?eventId=<id>
  Future<void> deleteAppointment(String eventId) async {
    final url = _uri('/V1/appointment?eventId=$eventId');
    try {
      final resp = await http.delete(url, headers: _headers()).timeout(const Duration(seconds: 10));
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw ApiException('Failed to delete appointment: HTTP ${resp.statusCode}', resp.body);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error while deleting appointment', e.toString());
    }
  }
}

class ApiException implements Exception {
  final String message;
  final String? details;
  ApiException(this.message, [this.details]);
  @override
  String toString() => 'ApiException: $message${details != null ? ' — $details' : ''}';
}
