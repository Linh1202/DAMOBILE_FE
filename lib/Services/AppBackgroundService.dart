import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:doanmobile/Services/SocketService.dart';
import 'package:doanmobile/Services/LocalNotificationService.dart';
import 'package:doanmobile/Services/AuthStorage.dart';
import 'package:doanmobile/Models/Api/SocketMessage.dart';
import 'package:doanmobile/Utils/Constants/AppEnums.dart';

class AppBackgroundService {
  static final AppBackgroundService _instance = AppBackgroundService._internal();
  factory AppBackgroundService() => _instance;
  AppBackgroundService._internal();

  /// Initialize the background service
  /// This should be called in main() before runApp()
  Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        // This function will be executed when the service starts
        onStart: onStart,

        // Auto start service
        autoStart: true,
        isForegroundMode: true,

        notificationChannelId: 'background_service',
        initialNotificationTitle: 'Doan Mobile',
        initialNotificationContent: 'Đang duy trì kết nối...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    service.startService();
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Initialize core services inside the background isolate
    final socketService = SocketService.instance;
    final notificationService = LocalNotificationService();
    
    // We need to initialize notification service again in this isolate
    await notificationService.init();

    await socketService.connect();

    // Listen to messages in background
    socketService.messageStream.listen((SocketMessage message) async {
      if (message.type == MessageType.chatMessage) {
        final user = await AuthStorage.readUser();
        final currentUserId = user?['id']?.toString() ?? user?['_id']?.toString() ?? "";

        // Only show notification if it's not our own message
        if (message.senderId != currentUserId) {
          notificationService.showNotification(
            title: message.senderName ?? message.chatName ?? "Tin nhắn mới",
            body: (message.content != null && message.content!.isNotEmpty)
                ? message.content!
                : "[Hình ảnh/Tệp tin]",
            payload: message.roomId,
          );
        }
      }
      
      // Update background notification content to show it's alive
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          service.setForegroundNotificationInfo(
            title: "Doan Mobile",
            content: "Ứng dụng đang chạy ngầm",
          );
        }
      }
    });

    // Handle reconnects
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!socketService.isConnected) {
        await socketService.connect();
      }
    });
  }

  /// Stop the background service
  void stopService() {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }
}