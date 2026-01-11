class ApiEndpoints {
  // Auth
  static const String signup = '/auth/signup';
  static const String signin = '/auth/signin';

  // User
  static const String forgotPassword = '/user/forgot-password';
  static const String resetPassword = '/user/reset-password';
  static const String userProfile = '/user/profile';
  static const String changePassword = '/user/change-password';
  static const String findUserByEmail = '/user/find-by-email';
  static const String findUserByName = '/user/find-by-name';

  // Chats
  static const String chat = '/chat';
  static String chatById(String id) => '/chat/$id';
  static String chatSearch(String query, String type) => '/chat/search?q=$query&type=$type';

  // Messages
  static String messagesByConversationId(String conversationId) => '/message/$conversationId';
  static const String uploadMedia = '/message/upload';

  // Friends
  static const String friendRequest = '/friend/request';
  static const String friendAccept = '/friend/accept';
  static const String friendReject = '/friend/reject';
  static const String friendCancel = '/friend/cancel';
  static const String friendUnfriend = '/friend/unfriend';
  static const String friendList = '/friend/list';
  static const String friendRequests = '/friend/requests';

  // Groups
  static const String group = '/group';
  static String groupById(String id) => '/group/$id';
  static String groupByCreator(String creatorId) => '/group/creator/$creatorId';
  static const String groupMember = '/group/member';
  static const String groupDissolve = '/group/dissolve';
  static const String groupLeave = '/group/leave';

  // Notifications
  static const String notification = '/notification';
  static const String notificationUnreadCount = '/notification/unread/count';
  static const String notificationReadAll = '/notification/read-all';
  static String notificationMarkRead(String id) => '/notification/$id/read';

  // WebSocket
  static const String ws = '/ws';
}