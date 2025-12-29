import 'package:flutter/material.dart';
import '../../Utils/Handlers/NavigationHandler.dart';
import '../../Utils/Constants/AppColors.dart';
import '../../Utils/Constants/AppStrings.dart';
import '../../Widgets/Buttons/PrimaryButton.dart';

class SuccessView extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 40),
                Text(
                  AppStrings.successTitle,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  AppStrings.passwordResetSuccess,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 50),
                PrimaryButton(
                  text: AppStrings.backToLogin,
                  onPressed: NavigationHandler.goBackToLogin,
                  borderRadius: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
