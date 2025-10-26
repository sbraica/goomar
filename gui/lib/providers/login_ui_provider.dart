import 'package:flutter/material.dart';
import 'auth_provider.dart';

class LoginUiProvider with ChangeNotifier {
  bool isLoading = false;
  bool obscurePassword = true;

  void toggleObscure() {
    obscurePassword = !obscurePassword;
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