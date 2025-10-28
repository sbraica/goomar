import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reservation.dart';

/// Simple API client wrapping HTTP calls to the backend.
class ApiClient {
  ApiClient._(this.baseUrl);

  /// Base URL of the backend, e.g. http://localhost:8080
  final String baseUrl;

  /// Global singleton configured from environment with a sensible default.
  /// You can override by creating your own instance if needed.
  static final ApiClient instance = ApiClient._(
    const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080'),
  );

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

  /// Fetch all reservations.
  /// Throws [ApiException] on non-2xx or network errors.
  Future<List<Reservation>> getReservations() async {
    final url = _uri('/V1/appointments');
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

  /// Posts a reservation to the backend as JSON body.
  /// Throws [ApiException] on non-2xx or network errors.
  Future<void> postReservation(Reservation reservation) async {
    final url = _uri('/V1/reservation');
    final body = jsonEncode(reservation.toJson());
    try {
      final resp = await http
          .post(url, headers: _headers(json: true), body: body)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw ApiException('Failed to create reservation: HTTP ${resp.statusCode}', resp.body);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error while creating reservation', e.toString());
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
