import 'package:doanmobile/Services/AuthStorage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doanmobile/Providers/SocketProvider.dart';
import 'package:doanmobile/Providers/CallProvider.dart';
import 'package:doanmobile/Services/SocketService.dart';
import 'package:doanmobile/Services/WebRTCService.dart';
import 'package:doanmobile/Views/Main/CallView.dart';
import 'package:doanmobile/Views/Friends/FriendsView.dart';
import 'package:doanmobile/Views/Settings/SettingsView.dart';
import 'package:doanmobile/Widgets/Main/HomeAppBar.dart';
import 'package:doanmobile/Widgets/Main/HomeBottomNavigationBar.dart';
import 'package:doanmobile/Widgets/Main/ChatList.dart';
import 'package:doanmobile/Utils/AppGlobals.dart';
import 'package:doanmobile/Utils/Constants/AppEnums.dart';
import 'package:doanmobile/Utils/Constants/AppColors.dart';
import 'package:flutter/material.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> with WidgetsBindingObserver {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    selectedIndex = AppGlobals.itemBarIndex;
    
    // Connect to socket via provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(socketServiceProvider).connect();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(socketServiceProvider).connect();
    }
  }

  void _handleIncomingCall({
    required String senderId,
    String? senderName,
    required Map<String, dynamic> sdp,
    bool isRoom = false,
    String? roomId,
  }) {
    final displayName = senderName ?? senderId;
    final callType = isRoom ? "Cuộc gọi nhóm" : "Cuộc gọi đến";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(callType),
        content: Text("$displayName đang gọi cho bạn"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(callProvider.notifier).rejectCall();
            },
            child: const Text("Từ chối", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              
              ref.read(callProvider.notifier).acceptCall();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CallView(
                    targetUserId: senderId,
                    userName: senderName,
                    isIncoming: true,
                  ),
                ),
              );

              Future.delayed(const Duration(milliseconds: 500), () {
                WebRTCService.instance.handleOffer(
                  senderId,
                  sdp,
                  isRoom: isRoom,
                  roomId: roomId,
                );
              });
            },
            child: const Text("Chấp nhận"),
          ),
        ],
      ),
    );
  }

  static List<Widget> _buildWidgetOptions() {
    return <Widget>[ChatList(), FriendsView(), SettingsView()];
  }

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  Future<void> clickLogout() async {
    ref.read(socketServiceProvider).close();
    await AuthStorage.deleteToken();
    await AuthStorage.deleteUser();
    if (mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/welcome', (route) => false);
    }
  }

  String _getTitle() {
    switch (selectedIndex) {
      case 0:
        return "Tin nhắn";
      case 1:
        return "Bạn bè";
      case 2:
        return "Cài đặt";
      default:
        return "Tin nhắn";
    }
  }

  @override
  Widget build(BuildContext context) {
    final widgetOptions = _buildWidgetOptions();

    ref.listen(callProvider, (previous, next) {
      if (next.status == CallStatus.ringing && 
          (previous == null || previous.status != CallStatus.ringing)) {
        _handleIncomingCall(
          senderId: next.callerId!,
          senderName: next.callerName,
          sdp: next.offerSdp!,
          isRoom: next.isRoom,
          roomId: next.roomId,
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: HomeAppBar(title: _getTitle()),
      body: widgetOptions.elementAt(selectedIndex),
      bottomNavigationBar: HomeBottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onItemTapped,
      ),
    );
  }
}
