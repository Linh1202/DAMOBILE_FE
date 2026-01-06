import 'package:flutter/material.dart';
import '../../Utils/Constants/AppColors.dart';
import '../../Widgets/Friends/FriendListItem.dart';
import '../../Widgets/Friends/FriendRequestItem.dart';
import '../../Widgets/Friends/SearchUserItem.dart';

class FriendsView extends StatefulWidget {
  @override
  _FriendsViewState createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController txtSearch = TextEditingController();

  // Mock data - Danh sách bạn bè
  final List<Map<String, dynamic>> _friends = [
    {"id": "1", "name": "Minh Anh", "avatarUrl": "Assets/Images/anh1.png", "isOnline": true, "lastSeen": ""},
    {"id": "2", "name": "Tuấn Kiệt", "avatarUrl": "Assets/Images/anh1.png", "isOnline": false, "lastSeen": "5 phút trước"},
    {"id": "3", "name": "Hương Giang", "avatarUrl": "Assets/Images/anh1.png", "isOnline": true, "lastSeen": ""},
    {"id": "4", "name": "Đức Anh", "avatarUrl": "Assets/Images/anh1.png", "isOnline": false, "lastSeen": "2 giờ trước"},
    {"id": "5", "name": "Thu Thảo", "avatarUrl": "Assets/Images/anh1.png", "isOnline": true, "lastSeen": ""},
    {"id": "6", "name": "Hoàng Long", "avatarUrl": "Assets/Images/anh1.png", "isOnline": false, "lastSeen": "1 ngày trước"},
  ];

  // Mock data - Lời mời kết bạn
  final List<Map<String, dynamic>> _friendRequests = [
    {"id": "7", "name": "Thu Thảo", "avatarUrl": "Assets/Images/anh1.png", "requestDate": "29/12/2025"},
    {"id": "8", "name": "Hoàng Long", "avatarUrl": "Assets/Images/anh1.png", "requestDate": "28/12/2025"},
  ];

  // Kết quả tìm kiếm
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    txtSearch.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // TODO: Gọi API tìm kiếm
    // Mock search results
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchResults = [
            {"id": "10", "name": "Nguyễn Văn A", "avatarUrl": "Assets/Images/anh1.png", "email": "nguyenvana@gmail.com", "status": FriendStatus.none},
            {"id": "11", "name": "Trần Thị B", "avatarUrl": "Assets/Images/anh1.png", "email": "tranthib@gmail.com", "status": FriendStatus.pending},
            {"id": "12", "name": "Lê Văn C", "avatarUrl": "Assets/Images/anh1.png", "email": "levanc@gmail.com", "status": FriendStatus.friend},
          ];
          _isSearching = false;
        });
      }
    });
  }

  void _onAcceptFriendRequest(String id) {
    // TODO: Gọi API chấp nhận lời mời
    setState(() {
      _friendRequests.removeWhere((req) => req["id"] == id);
    });
  }

  void _onRejectFriendRequest(String id) {
    // TODO: Gọi API từ chối lời mời
    setState(() {
      _friendRequests.removeWhere((req) => req["id"] == id);
    });
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

  /// Tab 1: Danh sách bạn bè
  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        message: "Chưa có bạn bè nào",
      );
    }

    return ListView.separated(
      itemCount: _friends.length,
      separatorBuilder: (context, index) => Divider(height: 1, indent: 80),
      itemBuilder: (context, index) {
        final friend = _friends[index];
        return FriendListItem(
          name: friend["name"],
          avatarUrl: friend["avatarUrl"],
          isOnline: friend["isOnline"],
          lastSeen: friend["lastSeen"],
          onChatTap: () {
            // TODO: Mở chat với bạn
          },
        );
      },
    );
  }

  /// Tab 2: Lời mời kết bạn
  Widget _buildFriendRequests() {
    if (_friendRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.mail_outline,
        message: "Không có lời mời kết bạn",
      );
    }

    return ListView.separated(
      itemCount: _friendRequests.length,
      separatorBuilder: (context, index) => Divider(height: 1, indent: 80),
      itemBuilder: (context, index) {
        final request = _friendRequests[index];
        return FriendRequestItem(
          name: request["name"],
          avatarUrl: request["avatarUrl"],
          requestDate: request["requestDate"],
          onAccept: () => _onAcceptFriendRequest(request["id"]),
          onReject: () => _onRejectFriendRequest(request["id"]),
        );
      },
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
            decoration: InputDecoration(
              hintText: "Tìm kiếm người dùng...",
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
        icon: Icons.search,
        message: "Nhập tên để tìm kiếm",
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
          onAddFriend: () {
            // TODO: Gọi API gửi lời mời kết bạn
            setState(() {
              _searchResults[index]["status"] = FriendStatus.pending;
            });
          },
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
