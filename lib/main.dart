import 'package:doanmobile/Views/Authentication/WelcomeView.dart';
import 'package:doanmobile/Views/Authentication/RegisterView.dart';
import 'package:doanmobile/Views/Authentication/LoginView.dart';
import 'package:doanmobile/Views/Authentication/ForgotPasswordView.dart';
import 'package:doanmobile/Views/Authentication/VerifyCodeView.dart';
import 'package:doanmobile/Views/Authentication/ResetPasswordView.dart';
import 'package:doanmobile/Views/Authentication/SuccessView.dart';
import 'package:doanmobile/Views/Main/HomeView.dart';
import 'Utils/AppGlobals.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    navigatorKey: AppGlobals.navigatorKey,
    debugShowCheckedModeBanner: false,
    initialRoute: '/welcome',
    routes: {
      '/welcome': (context) => WelcomeView(),
      '/register': (context) => RegisterView(),
      '/login': (context) => LoginView(),
      '/forgot-password': (context) => ForgotPasswordView(),
      '/verify-code': (context) => VerifyCodeView(),
      '/reset-password': (context) => ResetPasswordView(),
      '/success': (context) => SuccessView(),
      '/home': (context) => HomeView(),
    },
  ));
}