import 'package:flutter/material.dart';
import '../../Utils/Constants/AppColors.dart';
import '../../Widgets/Avatars/UserAvatar.dart';
import '../../Widgets/Friends/FriendListItem.dart';
import '../../Widgets/Chat/ChatListItem.dart';
import '../Chat/ChatDetailView.dart';

class SearchView extends StatefulWidget {
  @override
  _SearchViewState createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController txtSearch = TextEditingController();
  
  bool _isSearching = false;
  String _searchQuery = "";

  // Mock data - Người dùng
  final List<Map<String, dynamic>> _users = [
    {"id": "1", "name": "Minh Anh", "avatarUrl": "Assets/Images/anh1.png", "isOnline": true, "lastSeen": "Đang hoạt động"},
    {"id": "2", "name": "Hương Giang", "avatarUrl": "Assets/Images/anh1.png", "isOnline": true, "lastSeen": "Đang hoạt động"},
    {"id": "3", "name": "Đức Anh", "avatarUrl": "Assets/Images/anh1.png", "isOnline": false, "lastSeen": "2 giờ trước"},
  ];

  // Mock data - Nhóm chat
  final List<Map<String, dynamic>> _groupChats = [
    {"id": "1", "name": "Minh Anh", "avatarUrl": "Assets/Images/anh1.png", "content": "Chiều nay đi cafe nhé!", "updatedAt": "", "type": "private"},
    {"id": "2", "name": "Team Dev Frontend", "avatarUrl": "Assets/Images/anh1.png", "content": "Đức Anh: Meeting lúc 2h nhé mọi người", "updatedAt": "", "type": "group"},
    {"id": "3", "name": "Hương Giang", "avatarUrl": "Assets/Images/anh1.png", "content": "Ok, hẹn gặp lại!", "updatedAt": "", "type": "private"},
  ];

  // Mock data - Tin nhắn (kết quả tìm kiếm trong nội dung tin nhắn)
  final List<Map<String, dynamic>> _messages = [
    {"id": "1", "senderName": "Minh Anh", "avatarUrl": "Assets/Images/anh1.png", "content": "Chiều nay đi cafe nhé!", "chatName": "Minh Anh"},
    {"id": "2", "senderName": "Đức Anh", "avatarUrl": "Assets/Images/anh1.png", "content": "Meeting lúc 2h nhé mọi người", "chatName": "Team Dev Frontend"},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    txtSearch.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });
    // TODO: Gọi API tìm kiếm
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return [];
    return _users.where((user) => 
      user["name"].toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  List<Map<String, dynamic>> get _filteredChats {
    if (_searchQuery.isEmpty) return [];
    return _groupChats.where((chat) => 
      chat["name"].toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  List<Map<String, dynamic>> get _filteredMessages {
    if (_searchQuery.isEmpty) return [];
    return _messages.where((msg) => 
      msg["content"].toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header với search input
            _buildSearchHeader(),
            // Tab bar
            _buildTabBar(),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllTab(),
                  _buildPeopleTab(),
                  _buildGroupsTab(),
                  _buildMessagesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Nút đóng
          IconButton(
            icon: Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          // Search input
          Expanded(
            child: TextField(
              controller: txtSearch,
              autofocus: true,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: "Tìm kiếm...",
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
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
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: "Tất cả"),
          Tab(text: "Người"),
          Tab(text: "Nhóm"),
          Tab(text: "Tin nhắn"),
        ],
      ),
    );
  }

  /// Tab Tất cả - Hiển thị tổng hợp kết quả
  Widget _buildAllTab() {
    if (!_isSearching) {
      return _buildEmptyState("Nhập từ khóa để tìm kiếm");
    }

    final users = _filteredUsers;
    final chats = _filteredChats;
    final messages = _filteredMessages;

    if (users.isEmpty && chats.isEmpty && messages.isEmpty) {
      return _buildEmptyState("Không tìm thấy kết quả");
    }

    return ListView(
      children: [
        // Section Người dùng
        if (users.isNotEmpty) ...[
          _buildSectionHeader("Người dùng"),
          ...users.map((user) => FriendListItem(
            name: user["name"],
            avatarUrl: user["avatarUrl"],
            isOnline: user["isOnline"],
            lastSeen: user["lastSeen"],
            onTap: () {
              // TODO: Mở profile người dùng
            },
          )),
        ],
        // Section Nhóm chat
        if (chats.isNotEmpty) ...[
          _buildSectionHeader("Nhóm chat"),
          ...chats.map((chat) => ChatListItem(
            name: chat["name"],
            avatarUrl: chat["avatarUrl"],
            content: chat["content"],
            updatedAt: chat["updatedAt"],
            unreadCount: 0,
            isGroup: chat["type"] == "group",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailView(
                    name: chat["name"],
                    avatarUrl: chat["avatarUrl"],
                    isOnline: false,
                    isGroup: chat["type"] == "group",
                  ),
                ),
              );
            },
          )),
        ],
      ],
    );
  }

  /// Tab Người - Chỉ hiển thị người dùng
  Widget _buildPeopleTab() {
    if (!_isSearching) {
      return _buildEmptyState("Nhập tên để tìm người dùng");
    }

    final users = _filteredUsers;
    if (users.isEmpty) {
      return _buildEmptyState("Không tìm thấy người dùng");
    }

    return ListView.separated(
      itemCount: users.length,
      separatorBuilder: (context, index) => Divider(height: 1, indent: 80),
      itemBuilder: (context, index) {
        final user = users[index];
        return FriendListItem(
          name: user["name"],
          avatarUrl: user["avatarUrl"],
          isOnline: user["isOnline"],
          lastSeen: user["lastSeen"],
        );
      },
    );
  }

  /// Tab Nhóm - Chỉ hiển thị nhóm chat
  Widget _buildGroupsTab() {
    if (!_isSearching) {
      return _buildEmptyState("Nhập tên để tìm nhóm");
    }

    final chats = _filteredChats;
    if (chats.isEmpty) {
      return _buildEmptyState("Không tìm thấy nhóm");
    }

    return ListView.separated(
      itemCount: chats.length,
      separatorBuilder: (context, index) => Divider(height: 1, indent: 80),
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ChatListItem(
          name: chat["name"],
          avatarUrl: chat["avatarUrl"],
          content: chat["content"],
          updatedAt: chat["updatedAt"],
          unreadCount: 0,
          isGroup: chat["type"] == "group",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailView(
                  name: chat["name"],
                  avatarUrl: chat["avatarUrl"],
                  isOnline: false,
                  isGroup: chat["type"] == "group",
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Tab Tin nhắn - Tìm trong nội dung tin nhắn
  Widget _buildMessagesTab() {
    if (!_isSearching) {
      return _buildEmptyState("Nhập nội dung để tìm tin nhắn");
    }

    final messages = _filteredMessages;
    if (messages.isEmpty) {
      return _buildEmptyState("Không tìm thấy tin nhắn");
    }

    return ListView.separated(
      itemCount: messages.length,
      separatorBuilder: (context, index) => Divider(height: 1, indent: 80),
      itemBuilder: (context, index) {
        final msg = messages[index];
        return ListTile(
          leading: UserAvatar(
            imagePath: msg["avatarUrl"],
            name: msg["senderName"],
            size: 50,
          ),
          title: Text(
            msg["chatName"],
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              children: [
                TextSpan(
                  text: "${msg["senderName"]}: ",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(text: msg["content"]),
              ],
            ),
          ),
          onTap: () {
            // TODO: Mở chat và highlight tin nhắn
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.inputBackground,
      width: double.infinity,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
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
