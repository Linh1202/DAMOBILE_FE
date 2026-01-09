import '../Models/Notification.dart';
import '../Repositories/NotificationRepository.dart';

class NotificationService {
  final NotificationRepository _repository = NotificationRepository();

  Future<List<AppNotification>> getNotifications() async {
    final notifications = await _repository.getNotifications();
    return notifications
        .where((n) => n.notificationType != null)
        .toList();
  }

  Future<int> getUnreadCount() async {
    return await _repository.getUnreadCount();
  }

  Future<bool> markAsRead(String id) async {
    return await _repository.markAsRead(id);
  }

  Future<bool> markAllAsRead() async {
    return await _repository.markAllAsRead();
  }
}
