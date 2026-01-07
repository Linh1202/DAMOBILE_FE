import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../Utils/Constants/AppColors.dart';
import '../../Utils/AppGlobals.dart';
import '../../Services/AuthStorage.dart';
import '../../Services/UserService.dart';
import '../../Services/ApiService.dart';
import '../../Utils/Constants/ApiEndpoints.dart';
import '../../Models/User.dart';
import '../../Widgets/Avatars/UserAvatar.dart';
import 'ProfileView.dart';

class SettingsView extends StatefulWidget {
  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final UserService _userService = UserService();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  User? _currentUser;
  bool _isLoadingProfile = true;
  bool notificationsEnabled = true;
  String currentLanguage = "Tiếng Việt";

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _userService.getProfile();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoadingProfile = false;
          AppGlobals.userName = user.fullName;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đang tải ảnh lên...')),
      );

      final response = await _apiService.postMultipartWithAuth(
        ApiEndpoints.uploadMedia,
        image.path,
      );

      if (response['success'] == true && response['data'] != null) {
        final avatarUrl = response['data']['url'];
        
        await _userService.updateProfile(avatarUrl: avatarUrl);
        
        await _loadProfile();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cập nhật ảnh đại diện thành công')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi cập nhật ảnh: $e')),
        );
      }
    }
  }

  Future<void> _navigateToProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileView()),
    );
    
    if (result == true) {
      _loadProfile();
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Đăng xuất"),
        content: Text("Bạn có chắc chắn muốn đăng xuất?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Đăng xuất",
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthStorage.deleteToken();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Section
          _buildProfileSection(),
          
          SizedBox(height: 16),
          
          // Tài khoản Section
          _buildSectionHeader("Tài khoản"),
          _buildSettingItem(
            icon: Icons.camera_alt_outlined,
            title: "Thay đổi ảnh đại diện",
            onTap: _pickAndUploadAvatar,
          ),
          _buildSettingItem(
            icon: Icons.lock_outline,
            title: "Bảo mật và quyền riêng tư",
            onTap: () {
              // TODO: Mở màn hình bảo mật
            },
          ),
          
          SizedBox(height: 16),
          
          // Tùy chọn Section
          _buildSectionHeader("Tùy chọn"),
          _buildSettingItem(
            icon: Icons.notifications_outlined,
            title: "Thông báo",
            trailing: Switch(
              value: notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  notificationsEnabled = value;
                });
              },
              activeColor: AppColors.primary,
            ),
          ),
          _buildSettingItem(
            icon: Icons.palette_outlined,
            title: "Giao diện",
            onTap: () {
              // TODO: Mở màn hình chọn giao diện
            },
          ),
          _buildSettingItem(
            icon: Icons.language_outlined,
            title: "Ngôn ngữ",
            trailing: Text(
              currentLanguage,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
              ),
            ),
            onTap: () {
              // TODO: Mở màn hình chọn ngôn ngữ
            },
          ),
          
          SizedBox(height: 16),
          
          // Hỗ trợ Section
          _buildSectionHeader("Hỗ trợ"),
          _buildSettingItem(
            icon: Icons.help_outline,
            title: "Trợ giúp",
            onTap: () {
              // TODO: Mở màn hình trợ giúp
            },
          ),
          
          SizedBox(height: 32),
          
          // Nút Đăng xuất
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: Icon(Icons.logout, color: AppColors.error),
                label: Text(
                  "Đăng xuất",
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          
          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    if (_isLoadingProfile) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Stack(
            children: [
              UserAvatar(
                imagePath: _currentUser?.avatarUrl,
                name: _currentUser?.fullName ?? (AppGlobals.userName.isNotEmpty ? AppGlobals.userName : "Bạn"),
                size: 64,
                isOnline: true,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadAvatar,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 16),
          // Thông tin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser?.fullName ?? (AppGlobals.userName.isNotEmpty ? AppGlobals.userName : "Bạn"),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                GestureDetector(
                  onTap: _navigateToProfile,
                  child: Text(
                    "Xem hồ sơ",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: trailing ?? (onTap != null
          ? Icon(Icons.chevron_right, color: AppColors.textSecondary)
          : null),
    );
  }
}
