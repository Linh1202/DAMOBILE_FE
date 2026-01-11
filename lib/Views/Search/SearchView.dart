import 'package:flutter/material.dart';
import '../../Utils/Constants/AppColors.dart';
import '../../Widgets/Chat/ChatListItem.dart';
import '../../Services/ChatService.dart';
import '../../Services/AuthStorage.dart';
import '../../Models/Chat.dart';
import '../Chat/ChatDetailView.dart';

class SearchView extends StatefulWidget {
  @override
  _SearchViewState createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController txtSearch = TextEditingController();
  
  final ChatService _chatService = ChatService();
  
  bool _isSearching = false;
  bool _isLoading = false;
  String _searchQuery = "";
  String _currentUserId = "";
  
  List<Chat> _allChats = [];
  List<Chat> _privateChats = [];
  List<Chat> _groupChats = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthStorage.readUser();
    if (mounted && user != null) {
      setState(() {
        _currentUserId = user['id']?.toString() ?? user['_id']?.toString() ?? '';
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    txtSearch.dispose();
    super.dispose();
  }

  Future<void> _onSearch(String query) async {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });

    if (query.isEmpty) {
      setState(() {
        _allChats = [];
        _privateChats = [];
        _groupChats = [];
      });
      return;
    }

    if (query.length < 2) return;

    setState(() => _isLoading = true);

    try {
      // Search all chats
      final results = await _chatService.searchChats(query, type: 'all');
      
      if (mounted) {
        setState(() {
          _allChats = results;
          _privateChats = results.where((c) => c.type == ChatType.private).toList();
          _groupChats = results.where((c) => c.type == ChatType.group).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
        ],
      ),
    );
  }

  Widget _buildAllTab() {
    if (!_isSearching) {
      return _buildEmptyState("Nhập từ khóa để tìm kiếm");
    }

    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_allChats.isEmpty) {
      return _buildEmptyState("Không tìm thấy kết quả");
    }

    return ListView.builder(
      itemCount: _allChats.length,
      itemBuilder: (context, index) {
        final chat = _allChats[index];
        return _buildChatItem(chat);
      },
    );
  }

  Widget _buildChatItem(Chat chat) {
    final isGroup = chat.type == ChatType.group;
    String name;
    String avatar;

    if (isGroup) {
      name = chat.name ?? "Nhóm";
      avatar = "Assets/Images/anh1.png";
    } else {
      if (chat.participantDetails != null && chat.participantDetails!.isNotEmpty) {
        final otherUser = chat.participantDetails!.firstWhere(
          (u) => u.id != _currentUserId,
          orElse: () => chat.participantDetails!.first,
        );
        name = otherUser.fullName;
        avatar = otherUser.avatarUrl ?? "Assets/Images/anh1.png";
      } else {
        name = chat.name ?? "Chat";
        avatar = "Assets/Images/anh1.png";
      }
    }

    return ChatListItem(
      name: name,
      avatarUrl: avatar,
      content: chat.lastMessage ?? "",
      updatedAt: "",
      unreadCount: 0,
      isGroup: isGroup,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailView(
              chatId: chat.id,
              name: name,
              avatarUrl: avatar,
              isOnline: false,
              isGroup: isGroup,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeopleTab() {
    if (!_isSearching) {
      return _buildEmptyState("Nhập tên để tìm người dùng");
    }

    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_privateChats.isEmpty) {
      return _buildEmptyState("Không tìm thấy người dùng");
    }

    return ListView.builder(
      itemCount: _privateChats.length,
      itemBuilder: (context, index) {
        final chat = _privateChats[index];
        return _buildChatItem(chat);
      },
    );
  }

  Widget _buildGroupsTab() {
    if (!_isSearching) {
      return _buildEmptyState("Nhập tên để tìm nhóm");
    }

    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_groupChats.isEmpty) {
      return _buildEmptyState("Không tìm thấy nhóm");
    }

    return ListView.builder(
      itemCount: _groupChats.length,
      itemBuilder: (context, index) {
        final chat = _groupChats[index];
        return _buildChatItem(chat);
      },
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
