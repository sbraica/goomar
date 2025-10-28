import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_client.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;

  bool get isAuthenticated => _currentUser != null && _token != null && _token!.isNotEmpty;

  /// Real login using backend. Sends username/password in plain text (JSON fields)
  /// and expects a bearer token in response. The token is stored and attached
  /// to subsequent API requests by [ApiClient].
  Future<bool> login(String username, String password) async {
    try {
      final token = await ApiClient.instance.login(username, password);
      _token = token;
      // We don't have user details endpoint yet; create a minimal user
      _currentUser = User(id: 'self', username: username, role: 'operator');
      notifyListeners();
      return true;
    } catch (_) {
      // Ensure token cleared on failure
      _token = null;
      _currentUser = null;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _token = null;
    _currentUser = null;
    ApiClient.instance.setAuthToken(null);
    notifyListeners();
  }
}
