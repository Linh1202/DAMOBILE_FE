import 'package:doanmobile/Services/AuthStorage.dart';
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

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int selectedIndex = 0;
  @override
  void initState() {
    super.initState();
    selectedIndex = AppGlobals.itemBarIndex;
    SocketService.instance.connect();
    _listenForCalls();
  }

  void _listenForCalls() {
    SocketService.instance.messageStream.listen((data) {
      final msgType = MessageType.fromString(data['type'] ?? "");

      if (msgType == MessageType.directCall || msgType == MessageType.call) {
        final senderId = data['sender_id']?.toString();
        final senderName = data['sender_name']?.toString();
        final roomId = data['room_id']?.toString();
        final payload = data['payload'];
        if (payload == null || senderId == null) return;

        final sigType = SignalingType.fromString(payload['type'] ?? "");
        final innerPayload = payload['payload'];
        final isRoom = msgType == MessageType.call;

        switch (sigType) {
          case SignalingType.offer:
            _handleIncomingCall(
              senderId: senderId,
              senderName: senderName,
              sdp: innerPayload,
              isRoom: isRoom,
              roomId: roomId,
            );
            break;
          case SignalingType.answer:
            WebRTCService.instance.handleAnswer(innerPayload);
            break;
          case SignalingType.iceCandidate:
            WebRTCService.instance.handleIceCandidate(innerPayload);
            break;
          case SignalingType.end:
            WebRTCService.instance.endCall();
            break;
          default:
            break;
        }
      }
    });
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
              WebRTCService.instance.endCall(senderId);
            },
            child: const Text("Từ chối", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
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
    await AuthStorage.deleteToken();
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
