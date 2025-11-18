import 'package:flutter/material.dart';
import 'auth_provider.dart';

class LoginUiProvider with ChangeNotifier {
  bool isLoading = false;
  bool obscurePassword = true;
  String username = '';
  String password = '';

  void toggleObscure() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void setUsername(String v) {
    if (v == username) return;
    username = v;
    notifyListeners();
  }

  void setPassword(String v) {
    if (v == password) return;
    password = v;
    notifyListeners();
  }

  Future<bool> login(String username, String password, AuthProvider auth) async {
    isLoading = true;
    notifyListeners();
    final success = await auth.login(username, password);
    isLoading = false;
    notifyListeners();
    return success;
  }
}