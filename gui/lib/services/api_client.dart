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

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  /// Posts a reservation to the backend as JSON body.
  /// Throws [ApiException] on non-2xx or network errors.
  Future<void> postReservation(Reservation reservation) async {
    final url = _uri('/V1/reservation');
    final body = jsonEncode(reservation.toJson());
    try {
      final resp = await http.post(url, headers: {'Content-Type': 'application/json'}, body: body).timeout(const Duration(seconds: 10));
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
