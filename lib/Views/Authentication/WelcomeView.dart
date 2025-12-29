import 'package:flutter/material.dart';
import '../../Utils/Handlers/NavigationHandler.dart';
import '../../Utils/Constants/AppColors.dart';
import '../../Utils/Constants/AppStrings.dart';
import '../../Widgets/Buttons/PrimaryButton.dart';

class WelcomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryBackground,
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 60),
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: AppColors.teal,
                  image: DecorationImage(
                    image: AssetImage("Assets/Images/anh2.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 50),
              Text(
                AppStrings.welcomeTitle,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  AppStrings.welcomeSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              Expanded(child: SizedBox()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: PrimaryButton(
                  text: AppStrings.registerFree,
                  onPressed: NavigationHandler.goToRegister,
                  borderRadius: 30,
                ),
              ),
              SizedBox(height: 15),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: OutlinedButton(
                  onPressed: NavigationHandler.goToLogin,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    minimumSize: Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    side: BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    AppStrings.login,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(text: "Bằng cách tiếp tục, bạn đồng ý với "),
                    TextSpan(
                      text: AppStrings.termsAndPolicy,
                      style: TextStyle(
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
