import 'package:flutter/material.dart';

class ApprovalUiProvider with ChangeNotifier {
  int selectedIndex = 0; // 0 = Pending, 1 = Approved

  void selectTab(int index) {
    if (index == selectedIndex) return;
    selectedIndex = index;
    notifyListeners();
  }
}