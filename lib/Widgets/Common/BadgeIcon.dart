import 'package:flutter/material.dart';
import '../../Utils/Constants/AppColors.dart';

class BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  final double iconSize;
  final Color? iconColor;
  final VoidCallback? onTap;

  const BadgeIcon({
    Key? key,
    required this.icon,
    this.count = 0,
    this.iconSize = 24,
    this.iconColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              icon,
              size: iconSize,
              color: iconColor ?? AppColors.textPrimary,
            ),
          ),
          if (count > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  count > 99 ? "99+" : count.toString(),
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
    );
  }
}
