import 'package:flutter/material.dart';
import 'package:doanmobile/Utils/Constants/AppColors.dart';
import 'package:doanmobile/Views/Search/SearchView.dart';
import 'package:doanmobile/Views/Notifications/NotificationsView.dart';
import 'package:doanmobile/Views/Group/CreateGroupView.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int notificationCount;
  final VoidCallback? onNotificationCountChanged;

  HomeAppBar({
    Key? key,
    required this.title,
    this.notificationCount = 0,
    this.onNotificationCountChanged,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: AppColors.textPrimary),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SearchView()),
            );
          },
        ),
        Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: AppColors.textPrimary,
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationsView()),
                );
                onNotificationCountChanged?.call();
              },
            ),
            if (notificationCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    notificationCount > 99 ? '99+' : '$notificationCount',
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
    );
  }
}
