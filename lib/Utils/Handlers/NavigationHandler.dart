import 'package:flutter/material.dart';
import '../AppGlobals.dart';

/// Handler xử lý điều hướng trong ứng dụng
class NavigationHandler {
  static BuildContext get _context => AppGlobals.navigatorKey.currentContext!;

  // Authentication routes
  static void goToWelcome() {
    Navigator.pushNamedAndRemoveUntil(_context, '/welcome', (route) => false);
  }

  static void goToLogin() {
    Navigator.pushNamed(_context, '/login');
  }

  static void goToRegister() {
    Navigator.pushNamed(_context, '/register');
  }

  static void goToForgotPassword() {
    Navigator.pushNamed(_context, '/forgot-password');
  }

  static void goToVerifyCode() {
    Navigator.pushNamed(_context, '/verify-code');
  }

  static void goToResetPassword() {
    Navigator.pushNamed(_context, '/reset-password');
  }

  static void goToSuccess() {
    Navigator.pushNamed(_context, '/success');
  }

  // Main app routes
  static void goToHome() {
    Navigator.pushNamedAndRemoveUntil(_context, '/home', (route) => false);
  }

  // Navigation actions
  static void goBack() {
    Navigator.pop(_context);
  }

  static void goBackToFirst() {
    Navigator.popUntil(_context, (route) => route.isFirst);
  }

  static void goBackToLogin() {
    Navigator.popUntil(_context, (route) => route.isFirst);
    Navigator.pushNamed(_context, '/login');
  }
}
