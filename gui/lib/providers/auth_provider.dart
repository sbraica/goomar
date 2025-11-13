import 'package:flutter/foundation.dart';
import '../navigation_service.dart';
import '../models/user.dart';
import '../services/api_client.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  String? _token;

  AuthProvider() {
    // Register a global auth failure hook so that when refresh is rejected
    // (e.g., HTTP 500 per requirement), we log out and navigate to login.
    ApiClient.instance.onAuthFailure = () {
      logout();
      navigateToLoginClearingStack();
    };
  }

  User? get currentUser => _currentUser;
  String? get token => _token;

  bool get isAuthenticated {
    // Consider token validity (including expiry) in addition to presence of a user
    return _currentUser != null && ApiClient.instance.hasValidToken;
  }

  Future<bool> login(String username, String password) async {
    try {
      final token = await ApiClient.instance.login(username, password);
      _token = token;
      _currentUser = User(id: 'self', username: username, role: 'operator');
      notifyListeners();
      return true;
    } catch (_) {
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
    ApiClient.instance.setRefreshToken(null);
    ApiClient.instance.setTokenExpiry(null);
    notifyListeners();
  }
}
