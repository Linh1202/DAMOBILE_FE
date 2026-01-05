import 'package:doanmobile/Services/AuthStorage.dart';
import 'package:doanmobile/Services/SocketService.dart';
import 'package:doanmobile/Services/WebRTCService.dart';
import 'package:doanmobile/Views/Main/CallView.dart';
import 'package:doanmobile/Utils/AppGlobals.dart';
import 'package:doanmobile/Utils/Constants/AppEnums.dart';
import 'package:doanmobile/Utils/Constants/AppColors.dart';
import 'package:doanmobile/Utils/Constants/AppStrings.dart';
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

  static const List<Widget> widgetOptions = <Widget>[
    Center(
      child: Text(
        'Trang chủ',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
    Center(
      child: Text(
        'Tin nhắn',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
    Center(
      child: Text(
        'Thông báo',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
    Center(
      child: Text(
        'Cá nhân',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.appName,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (AppGlobals.userName.isNotEmpty)
              Text(
                "Chào, ${AppGlobals.userName}",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () {
              // Xử lý tìm kiếm
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: AppColors.textPrimary),
            onPressed: clickLogout,
          ),
        ],
      ),
      body: widgetOptions.elementAt(selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Tin nhắn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Thông báo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Cá nhân',
            ),
          ],
          currentIndex: selectedIndex,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.iconGrey,
          onTap: onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.background,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
