import 'package:flutter/material.dart';

/// Global navigator key used for navigation outside of widget context
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void navigateToLoginClearingStack() {
  rootNavigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
}
