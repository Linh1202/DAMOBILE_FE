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
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const envFile = String.fromEnvironment('ENV_FILE', defaultValue: '.env');
  try {
    await dotenv.load(fileName: envFile);
  } catch (e) {
    print("Error loading $envFile: $e");
    if (envFile != '.env') {
      await dotenv.load(fileName: '.env');
    }
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppGlobals.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Doan Mobile',
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => WelcomeView(),
        '/register': (context) => RegisterView(),
        '/login': (context) => LoginView(),
        '/forgot-password': (context) => ForgotPasswordView(),
        '/verify-code': (context) => VerifyCodeView(),
        '/reset-password': (context) => ResetPasswordView(),
        '/success': (context) => SuccessView(),
        '/home': (context) => const HomeView(),
      },
    );
  }
}