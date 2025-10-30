import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_client.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;

  bool get isAuthenticated => _currentUser != null && _token != null && _token!.isNotEmpty;

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
    notifyListeners();
  }
}
