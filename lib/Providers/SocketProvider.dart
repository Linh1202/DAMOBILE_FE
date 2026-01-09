import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Services/SocketService.dart';
import '../Models/Api/SocketMessage.dart';
import '../Utils/Constants/AppEnums.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService.instance;
});

final socketConnectedProvider = StateProvider<bool>((ref) {
  return SocketService.instance.isConnected;
});

final userOnlineStatusProvider = StateNotifierProvider<UserOnlineNotifier, Map<String, bool>>((ref) {
  return UserOnlineNotifier();
});

final socketMessageStreamProvider = StreamProvider<SocketMessage>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final onlineNotifier = ref.watch(userOnlineStatusProvider.notifier);
  
  final subscription = socketService.messageStream.listen((message) {
    ref.read(socketConnectedProvider.notifier).state = socketService.isConnected;
    
    if (message.type == MessageType.notification && message.isOnline != null) {
      if (message.senderId != null) {
        onlineNotifier.setUserOnline(message.senderId!, message.isOnline!);
      }
    }
  });

  ref.onDispose(() {
    subscription.cancel();
  });

  return socketService.messageStream;
});

final socketStatusProvider = StreamProvider<bool>((ref) async* {
  final socketService = ref.watch(socketServiceProvider);
  
  yield socketService.isConnected;

  await for (final _ in socketService.messageStream) {
    yield socketService.isConnected;
  }
});

class UserOnlineNotifier extends StateNotifier<Map<String, bool>> {
  UserOnlineNotifier() : super({});

  void setUserOnline(String userId, bool isOnline) {
    state = {
      ...state,
      userId: isOnline,
    };
  }

  void setMultipleUsersOnline(Map<String, bool> userStatuses) {
    state = {
      ...state,
      ...userStatuses,
    };
  }

  bool isUserOnline(String userId) {
    return state[userId] ?? false;
  }

  void clearUserStatus(String userId) {
    final newState = Map<String, bool>.from(state);
    newState.remove(userId);
    state = newState;
  }

  void clearAllStatuses() {
    state = {};
  }
}