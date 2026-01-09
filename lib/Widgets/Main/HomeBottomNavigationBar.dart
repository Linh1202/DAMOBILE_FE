import 'package:flutter/material.dart';
import 'package:doanmobile/Utils/Constants/AppColors.dart';

class HomeBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int friendRequestCount;

  const HomeBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.friendRequestCount = 0,
  }) : super(key: key);

  Widget _buildFriendIcon({required IconData icon}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (friendRequestCount > 0)
          Positioned(
            right: -6,
            top: -3,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 14,
                minHeight: 14,
              ),
              child: Text(
                friendRequestCount > 99 ? '99+' : '$friendRequestCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: _buildFriendIcon(icon: Icons.people_outline),
            activeIcon: _buildFriendIcon(icon: Icons.people),
            label: 'Bạn bè',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
        currentIndex: currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.iconGrey,
        onTap: onTap,
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
    );
  }
}
