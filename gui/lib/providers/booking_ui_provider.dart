import 'package:flutter/material.dart';

class BookingUiProvider with ChangeNotifier {
  // Form key moved here so BookingScreen can be stateless
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Text controllers owned by the provider so we can notify UI on changes
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController registrationController = TextEditingController();

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  BookingUiProvider() {
    // Notify listeners when any field changes so dependent UI (e.g., button enable) updates
    nameController.addListener(_notify);
    emailController.addListener(_notify);
    phoneController.addListener(_notify);
    registrationController.addListener(_notify);
  }

  void _notify() => notifyListeners();

  set isSubmitting(bool v) {
    if (_isSubmitting == v) return;
    _isSubmitting = v;
    notifyListeners();
  }

  String get name => nameController.text;
  String get email => emailController.text;
  String get phone => phoneController.text;
  String get registration => registrationController.text;

  bool get isEmailValid => email.contains('@');

  bool get areTextFieldsComplete {
    return name.isNotEmpty && email.isNotEmpty && isEmailValid && phone.isNotEmpty && registration.isNotEmpty;
  }

  void clearInputs() {
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    registrationController.clear();
    // notifyListeners will be called by the controllers' listeners
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    registrationController.dispose();
    super.dispose();
  }
}
