import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Services/SocketService.dart';
import '../Models/Api/SocketMessage.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService.instance;
});

final socketConnectedProvider = StateProvider<bool>((ref) {
  return SocketService.instance.isConnected;
});

final socketMessageStreamProvider = StreamProvider<SocketMessage>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  
  final subscription = socketService.messageStream.listen((message) {
    ref.read(socketConnectedProvider.notifier).state = socketService.isConnected;
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