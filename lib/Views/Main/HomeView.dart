import 'package:doanmobile/Services/AuthStorage.dart';
import 'package:doanmobile/Services/SocketService.dart';
import 'package:doanmobile/Services/WebRTCService.dart';
import 'package:doanmobile/Views/Main/CallView.dart';
import 'package:doanmobile/Views/Chat/ChatDetailView.dart';
import 'package:doanmobile/Views/Group/CreateGroupView.dart';
import 'package:doanmobile/Views/Friends/FriendsView.dart';
import 'package:doanmobile/Views/Settings/SettingsView.dart';
import 'package:doanmobile/Views/Search/SearchView.dart';
import 'package:doanmobile/Views/Notifications/NotificationsView.dart';
import 'package:doanmobile/Widgets/Chat/ChatListItem.dart';
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
    return <Widget>[
      // Tab 0: Chat - Sử dụng ChatListView (không có AppBar riêng)
      _ChatListBody(),
      // Tab 1: Bạn bè
      FriendsView(),
      // Tab 2: Cài đặt
      SettingsView(),
    ];
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

  // Lấy tiêu đề theo tab hiện tại
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Text(
          _getTitle(),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Nút 1: Tìm kiếm
          IconButton(
            icon: Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchView()),
              );
            },
          ),
          // Nút 2: Thông báo với badge
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationsView()),
                  );
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          // Nút 3: Tạo nhóm
          IconButton(
            icon: Icon(Icons.group_add_outlined, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateGroupView()),
              );
            },
          ),
        ],
      ),
      body: widgetOptions.elementAt(selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            // Tab Chat
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
            // Tab Bạn bè với badge
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.people_outline),
                  Positioned(
                    right: -6,
                    top: -3,
                    child: Container(
                      padding: EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              activeIcon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.people),
                  Positioned(
                    right: -6,
                    top: -3,
                    child: Container(
                      padding: EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              label: 'Bạn bè',
            ),
            // Tab Cài đặt
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Cài đặt',
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

// Widget hiển thị danh sách chat (không có AppBar riêng)
class _ChatListBody extends StatelessWidget {
  final List<Map<String, dynamic>> _conversations = [
    {
      "name": "Minh Anh",
      "avatarUrl": "Assets/Images/anh1.png",
      "content": "Chiều nay đi cafe nhé!",
      "updatedAt": "10:30",
      "unreadCount": 2,
      "type": "private",
    },
    {
      "name": "Team Dev Frontend",
      "avatarUrl": "Assets/Images/anh1.png",
      "content": "Đức Anh: Meeting lúc 2h nhé mọi người",
      "updatedAt": "Hôm qua",
      "unreadCount": 5,
      "type": "group",
    },
    {
      "name": "Hương Giang",
      "avatarUrl": "Assets/Images/anh1.png",
      "content": "Ok, hẹn gặp lại!",
      "updatedAt": "2 ngày trước",
      "unreadCount": 0,
      "type": "private",
    },
    {
      "name": "Nhóm Gia Đình",
      "avatarUrl": "Assets/Images/anh1.png",
      "content": "Chủ nhật đi ăn nhé!",
      "updatedAt": "3 ngày trước",
      "unreadCount": 0,
      "type": "group",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        final bool isGroup = conversation["type"] == "group";
        return ChatListItem(
          name: conversation["name"],
          avatarUrl: conversation["avatarUrl"],
          content: conversation["content"],
          updatedAt: conversation["updatedAt"],
          unreadCount: conversation["unreadCount"],
          isGroup: isGroup,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailView(
                  name: conversation["name"],
                  avatarUrl: conversation["avatarUrl"],
                  isOnline: !isGroup,
                  isGroup: isGroup,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
