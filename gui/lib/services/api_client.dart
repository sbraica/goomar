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

  /// Absolute time when the current access token expires. If null, the token
  /// is considered non-expiring (or expiry unknown).
  DateTime? _tokenExpiry;

  /// Set or clear the auth token. When set, all subsequent requests include
  /// `Authorization: Bearer <token>` automatically.
  void setAuthToken(String? token) {
    _authToken = token;
    // When token is cleared, also clear expiry.
    if (token == null || token.isEmpty) {
      _tokenExpiry = null;
    }
  }

  /// Optionally set/clear token expiry timestamp.
  void setTokenExpiry(DateTime? expiry) {
    _tokenExpiry = expiry;
  }

  /// Whether the client currently holds a non-empty token that is not expired.
  bool get hasValidToken {
    if (_authToken == null || _authToken!.isEmpty) return false;
    if (_tokenExpiry == null) return true;
    return DateTime.now().isBefore(_tokenExpiry!);
  }

  bool get isTokenExpired {
    if (_authToken == null || _authToken!.isEmpty) return false;
    if (_tokenExpiry == null) return false;
    return !hasValidToken;
  }

  Map<String, String> _headers({Map<String, String>? extra, bool json = false}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (_authToken != null && _authToken!.isNotEmpty) {
      // If we have a token but it is expired, fail fast so UI can re-auth.
      if (isTokenExpired) {
        throw ApiException('Authentication token expired');
      }
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
      int? expiresInSeconds;
      try {
        final decoded = jsonDecode(resp.body);
        if (decoded is String) {
          token = decoded;
        } else if (decoded is Map<String, dynamic>) {
          // Support common field names and the provided BR format
          token = (decoded['access_token'] ?? decoded['token'] ?? decoded['accessToken'] ?? decoded['jwt'] ?? '').toString();
          final dynamic expVal = decoded['expires_in'] ?? decoded['expiresIn'];
          if (expVal is int) {
            expiresInSeconds = expVal;
          } else if (expVal is String) {
            expiresInSeconds = int.tryParse(expVal);
          }
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
      // Compute and store expiry if available, subtract a small skew to refresh earlier.
      if (expiresInSeconds != null && expiresInSeconds! > 0) {
        final skew = 5; // seconds
        final effective = expiresInSeconds! > skew ? expiresInSeconds! - skew : expiresInSeconds!;
        setTokenExpiry(DateTime.now().add(Duration(seconds: effective)));
      } else {
        setTokenExpiry(null);
      }
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
    final d = weekStart.day; // start-of-week (Monday)
    final url = _uri('/V1/reservations/$y/$m/$d');
    try {
      final resp = await http.get(url, headers: _headers()).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 401) {
        throw ApiException('Unauthorized — token invalid or expired', resp.body);
      }
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

  /// Posts a reservation to the backend as JSON body.
  /// Throws [ApiException] on non-2xx or network errors.
  Future<void> postReservation(Reservation reservation) async {
    final url = _uri('/V1/reservation');
    final body = jsonEncode(reservation.toJson());
    try {
      final resp = await http.post(url, headers: _headers(json: true), body: body).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 401) {
        throw ApiException('Unauthorized — token invalid or expired', resp.body);
      }
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
    final url = _uri('/V1/reservation?eventId=$eventId');
    try {
      final resp = await http.patch(url, headers: _headers(json: true)).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 401) {
        throw ApiException('Unauthorized — token invalid or expired', resp.body);
      }
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
  Future<void> deleteAppointment(String id) async {
    final url = _uri('/V1/reservation?id=$id');
    try {
      final resp = await http.delete(url, headers: _headers()).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 401) {
        throw ApiException('Unauthorized — token invalid or expired', resp.body);
      }
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
