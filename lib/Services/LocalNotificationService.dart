import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Initialize the notification service for Android and iOS
  Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
    print('🔔 LocalNotificationService: Initialized success = $initialized');

    // Create a default channel for Android (required for Android 8.0+)
    await _createDefaultChannel();

    // Request permissions for Android 13+
    print('🔔 LocalNotificationService: Requesting permissions for Android 13+...');
    final granted = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    print('🔔 LocalNotificationService: Permission granted = $granted');
  }

  /// Create default notification channel for Android
  Future<void> _createDefaultChannel() async {
    print('🔔 LocalNotificationService: Creating Android channels...');
    
    const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
      'chat_messages',
      'Tin nhắn',
      description: 'Thông báo tin nhắn mới từ bạn bè và nhóm',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel backgroundChannel = AndroidNotificationChannel(
      'background_service',
      'Dịch vụ chạy ngầm',
      description: 'Duy trì kết nối socket để nhận tin nhắn',
      importance: Importance.low,
    );

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(chatChannel);
    await androidPlugin?.createNotificationChannel(backgroundChannel);
    
    print('🔔 LocalNotificationService: Android channels created');
  }

  /// Handle notification tap events
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload != null) {
      print('Notification payload: $payload');
      // Logic to navigate to specific chat room could go here
    }
  }

  /// Show a basic text notification
  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  }) async {
    print('🔔 LocalNotificationService: Showing notification id=$id, title=$title');
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'chat_messages',
        'Tin nhắn',
        channelDescription: 'Thông báo tin nhắn mới',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        ticker: 'ticker',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
      print('🔔 LocalNotificationService: Notification shown successfully');
    } catch (e) {
      print('🔔 LocalNotificationService ERROR: Failed to show notification: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}