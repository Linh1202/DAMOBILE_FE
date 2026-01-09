import '../Models/Notification.dart';
import '../Services/ApiService.dart';
import '../Utils/Constants/ApiEndpoints.dart';

class NotificationRepository {
  final ApiService _apiService = ApiService();

  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await _apiService.getWithAuth(ApiEndpoints.notification);
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> notificationsJson = response['data']['notifications'] ?? [];
        return notificationsJson
            .map((json) => AppNotification.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi lấy thông báo: $e');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.getWithAuth(ApiEndpoints.notificationUnreadCount);
      print('DEBUG getUnreadCount response: $response');
      if (response['success'] == true && response['data'] != null) {
        final countValue = response['data']['count'];
        print('DEBUG count value: $countValue, type: ${countValue.runtimeType}');
        if (countValue is int) return countValue;
        if (countValue is double) return countValue.toInt();
        if (countValue is String) return int.tryParse(countValue) ?? 0;
        return 0;
      }
      return 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      final response = await _apiService.putWithAuth(
        ApiEndpoints.notificationMarkRead(id),
        {},
      );
      return response['success'] == true;
    } catch (e) {
      throw Exception('Lỗi đánh dấu đã đọc: $e');
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiService.putWithAuth(
        ApiEndpoints.notificationReadAll,
        {},
      );
      return response['success'] == true;
    } catch (e) {
      throw Exception('Lỗi đánh dấu tất cả đã đọc: $e');
    }
  }
}
