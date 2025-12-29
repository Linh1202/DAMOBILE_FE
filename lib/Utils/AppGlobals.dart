import 'package:flutter/material.dart';

/// Class chứa các biến global của ứng dụng
class AppGlobals {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static String userName = "";
  static int itemBarIndex = 0;
}
