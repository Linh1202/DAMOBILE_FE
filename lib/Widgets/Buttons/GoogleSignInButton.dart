import 'package:flutter/material.dart';
import '../../Utils/Constants/AppColors.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;

  const GoogleSignInButton({
    Key? key,
    required this.onTap,
    this.text = "Google",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "Assets/Images/google.png",
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.g_mobiledata, size: 24, color: AppColors.textSecondary);
              },
            ),
            SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
