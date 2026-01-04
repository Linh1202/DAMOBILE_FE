import 'package:flutter/material.dart';

/// Class chứa các biến global của ứng dụng
class AppGlobals {
  static const BASE_API_URL = "http://localhost:8080/api";
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static String userName = "";
  static int itemBarIndex = 0;
}
