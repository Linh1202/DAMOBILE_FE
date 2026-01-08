import 'package:flutter/material.dart';
import '../../Utils/Constants/AppColors.dart';
import '../../Utils/Handlers/DialogHandler.dart';
import '../../Widgets/Friends/FriendListItem.dart';
import '../../Widgets/Friends/FriendRequestItem.dart';
import '../../Widgets/Friends/SearchUserItem.dart';
import '../../Services/FriendService.dart';
import '../../Services/ChatService.dart';
import '../../Repositories/UserRepository.dart';
import '../../Models/User.dart';
import '../../Models/FriendRequest.dart' as model;
import '../../Models/Chat.dart';
import '../../Views/Chat/ChatDetailView.dart';

class FriendsView extends StatefulWidget {
  @override
  _FriendsViewState createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController txtSearch = TextEditingController();

  final FriendService _friendService = FriendService();
  final ChatService _chatService = ChatService();

  // Data lists
  List<User> _friends = [];
  List<model.FriendRequest> _friendRequests = [];
  List<Map<String, dynamic>> _searchResults = [];

  // Loading states
  bool _isLoadingFriends = true;
  bool _isLoadingRequests = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    txtSearch.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadFriends(),
      _loadFriendRequests(),
    ]);
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await _friendService.getFriends();
      if (mounted) {
        setState(() {
          _friends = friends;
          _isLoadingFriends = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFriends = false);
        var message = e.toString();
        if (message.startsWith('Exception: ')) {
          message = message.replaceFirst('Exception: ', '');
        }
        DialogHandler.showError(message);
      }
    }
  }

  Future<void> _loadFriendRequests() async {
    try {
      final requests = await _friendService.getPendingRequests();
      if (mounted) {
        setState(() {
          _friendRequests = requests;
          _isLoadingRequests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRequests = false);
        var message = e.toString();
        if (message.startsWith('Exception: ')) {
          message = message.replaceFirst('Exception: ', '');
        }
        DialogHandler.showError(message);
      }
    }
  }

  void _onSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    // Kiểm tra định dạng email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(query)) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final users = await UserRepository().findUserByEmail(query);
      if (mounted) {
        setState(() {
          _searchResults = users.map((user) => {
            "id": user.id,
            "name": user.fullName,
            "avatarUrl": user.avatarUrl ?? "Assets/Images/anh1.png",
            "email": user.email,
            "status": FriendStatus.none, // TODO: Check actual friend status
          }).toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        var message = e.toString();
        if (message.startsWith('Exception: ')) {
          message = message.replaceFirst('Exception: ', '');
        }
        DialogHandler.showError(message);
      }
    }
  }

  Future<void> _onAcceptFriendRequest(String id) async {
    try {
      final response = await _friendService.acceptFriendRequest(id);
      if (response.success) {
        setState(() {
          _friendRequests.removeWhere((req) => req.id == id);
        });
        DialogHandler.showSuccess(response.message.isNotEmpty ? response.message : "Đã chấp nhận lời mời kết bạn");
        _loadFriends(); // Reload friend list
      } else {
        DialogHandler.showError(response.message);
      }
    } catch (e) {
      var message = e.toString();
      if (message.startsWith('Exception: ')) {
        message = message.replaceFirst('Exception: ', '');
      }
      DialogHandler.showError(message);
    }
  }

  Future<void> _onRejectFriendRequest(String id) async {
    try {
      final response = await _friendService.rejectFriendRequest(id);
      if (response.success) {
        setState(() {
          _friendRequests.removeWhere((req) => req.id == id);
        });
        DialogHandler.showSuccess(response.message.isNotEmpty ? response.message : "Đã từ chối lời mời");
      } else {
        DialogHandler.showError(response.message);
      }
    } catch (e) {
      var message = e.toString();
      if (message.startsWith('Exception: ')) {
        message = message.replaceFirst('Exception: ', '');
      }
      DialogHandler.showError(message);
    }
  }

  Future<void> _onSendFriendRequest(String userId, int index) async {
    try {
      final response = await _friendService.sendFriendRequest(userId);
      if (response.success) {
        setState(() {
          _searchResults[index]["status"] = FriendStatus.pending;
        });
        DialogHandler.showSuccess(response.message.isNotEmpty ? response.message : "Đã gửi lời mời kết bạn");
      } else {
        DialogHandler.showError(response.message);
      }
    } catch (e) {
      var message = e.toString();
      if (message.startsWith('Exception: ')) {
        message = message.replaceFirst('Exception: ', '');
      }
      DialogHandler.showError(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2,
            labelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(text: "Bạn bè"),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Lời mời"),
                    if (_friendRequests.isNotEmpty) ...[
                      SizedBox(width: 6),
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          "${_friendRequests.length}",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(text: "Tìm kiếm"),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFriendsList(),
              _buildFriendRequests(),
              _buildSearchTab(),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onUnfriend(String friendId, String friendName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Hủy kết bạn"),
        content: Text("Bạn có chắc chắn muốn hủy kết bạn với $friendName?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Đồng ý",
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _friendService.unfriend(friendId);
        if (response.success) {
          DialogHandler.showSuccess("Đã hủy kết bạn với $friendName");
          _loadFriends(); // Reload list
        } else {
          DialogHandler.showError(response.message);
        }
      } catch (e) {
        var message = e.toString();
        if (message.startsWith('Exception: ')) {
          message = message.replaceFirst('Exception: ', '');
        }
        DialogHandler.showError(message);
      }
    }
  }

  Future<void> _openChatWithFriend(User friend) async {
    try {
      // First, get existing chats to see if we already have a chat with this friend
      final chats = await _chatService.getChats();
      
      // Find existing direct chat with this friend
      Chat? existingChat;
      for (final chat in chats) {
        if (chat.type == ChatType.private && 
            chat.participants.contains(friend.id)) {
          existingChat = chat;
          break;
        }
      }

      String chatId;
      if (existingChat != null) {
        chatId = existingChat.id;
      } else {
        // Create new chat - BE doesn't return chat data, 
        // so we'll create then reload list to find it
        await _chatService.createChat(
          type: ChatType.private,
          participants: [friend.id],
        );
        
        // Reload chats to get the new one
        final updatedChats = await _chatService.getChats();
        final newChat = updatedChats.firstWhere(
          (c) => c.type == ChatType.private && c.participants.contains(friend.id),
          orElse: () => throw Exception('Không tìm thấy cuộc trò chuyện mới tạo'),
        );
        chatId = newChat.id;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailView(
              chatId: chatId,
              name: friend.fullName,
              avatarUrl: friend.avatarUrl ?? "Assets/Images/anh1.png",
              isOnline: false,
            ),
          ),
        );
      }
    } catch (e) {
      var message = e.toString();
      if (message.startsWith('Exception: ')) {
        message = message.replaceFirst('Exception: ', '');
      }
      DialogHandler.showError(message);
    }
  }

  /// Tab 1: Danh sách bạn bè
  Widget _buildFriendsList() {
    if (_isLoadingFriends) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_friends.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        message: "Chưa có bạn bè nào",
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFriends,
      child: ListView.separated(
        itemCount: _friends.length,
        separatorBuilder: (context, index) => Divider(height: 1, indent: 80),
        itemBuilder: (context, index) {
          final friend = _friends[index];
          return FriendListItem(
            name: friend.fullName,
            avatarUrl: friend.avatarUrl ?? "Assets/Images/anh1.png",
            isOnline: false, // TODO: Implement online status
            lastSeen: "",
            onTap: () => _openChatWithFriend(friend),
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz, color: AppColors.textSecondary),
              onSelected: (value) {
                if (value == 'unfriend') {
                  _onUnfriend(friend.id, friend.fullName);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'unfriend',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove_outlined, color: AppColors.error, size: 20),
                      SizedBox(width: 8),
                      Text("Hủy kết bạn", style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Tab 2: Lời mời kết bạn
  Widget _buildFriendRequests() {
    if (_isLoadingRequests) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_friendRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.mail_outline,
        message: "Không có lời mời kết bạn",
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFriendRequests,
      child: ListView.separated(
        itemCount: _friendRequests.length,
        separatorBuilder: (context, index) => Divider(height: 1, indent: 80),
        itemBuilder: (context, index) {
          final request = _friendRequests[index];
          return FriendRequestItem(
            name: request.senderName ?? "Người dùng",
            avatarUrl: request.senderAvatarUrl ?? "Assets/Images/anh1.png",
            requestDate: request.formattedDate,
            onAccept: () => _onAcceptFriendRequest(request.id),
            onReject: () => _onRejectFriendRequest(request.id),
          );
        },
      ),
    );
  }

  /// Tab 3: Tìm kiếm
  Widget _buildSearchTab() {
    return Column(
      children: [
        // Search input
        Container(
          padding: EdgeInsets.all(16),
          child: TextField(
            controller: txtSearch,
            onChanged: _onSearch,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: "Nhập email để tìm kiếm...",
              hintStyle: TextStyle(color: AppColors.textSecondary),
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        // Search results
        Expanded(
          child: _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (txtSearch.text.isEmpty) {
      return _buildEmptyState(
        icon: Icons.email_outlined,
        message: "Nhập email để tìm kiếm",
      );
    }

    // Kiểm tra format email để hiển thị message phù hợp
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(txtSearch.text) && !_isSearching) {
      return _buildEmptyState(
        icon: Icons.email_outlined,
        message: "Vui lòng nhập đúng định dạng email",
      );
    }

    if (_isSearching) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_search,
        message: "Không tìm thấy người dùng nào",
      );
    }

    return ListView.separated(
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => Divider(height: 1, indent: 80),
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return SearchUserItem(
          id: user["id"],
          name: user["name"],
          avatarUrl: user["avatarUrl"],
          email: user["email"],
          status: user["status"],
          onAddFriend: () => _onSendFriendRequest(user["id"], index),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
