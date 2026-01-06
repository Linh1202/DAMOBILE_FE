import 'package:flutter/material.dart';
import '../../Utils/Constants/AppColors.dart';

class UserAvatar extends StatelessWidget {
  final String? imagePath;
  final String name;
  final double size;
  final bool isOnline;
  final bool isGroup;
  final bool showOnlineIndicator;

  const UserAvatar({
    Key? key,
    this.imagePath,
    required this.name,
    this.size = 48,
    this.isOnline = false,
    this.isGroup = false,
    this.showOnlineIndicator = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryLight,
          ),
          child: ClipOval(
            child: imagePath != null
                ? Image.asset(
                    imagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildFallback();
                    },
                  )
                : _buildFallback(),
          ),
        ),
        if (showOnlineIndicator && isOnline && !isGroup)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        if (isGroup)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.groups,
                color: Colors.white,
                size: size * 0.25,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : "?",
        style: TextStyle(
          color: AppColors.primary,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
