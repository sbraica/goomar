import 'package:flutter/foundation.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;

  User? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  // Mock login - Replace with your backend logic
  Future<bool> login(String username, String password) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Mock validation
    if (username == 'operator' && password == 'password') {
      _currentUser = User(id: '1', username: username, role: 'operator');
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
