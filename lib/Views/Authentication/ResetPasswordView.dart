import 'package:flutter/material.dart';
import '../../Utils/Handlers/NavigationHandler.dart';
import '../../Utils/Handlers/ValidationHandler.dart';
import '../../Utils/Handlers/DialogHandler.dart';
import '../../Utils/Constants/AppColors.dart';
import '../../Utils/Constants/AppStrings.dart';
import '../../Widgets/Buttons/PrimaryButton.dart';
import '../../Widgets/Inputs/CustomTextField.dart';

class ResetPasswordView extends StatelessWidget {
  TextEditingController txtNewPassword = TextEditingController();
  TextEditingController txtConfirmPassword = TextEditingController();

  void clickDatLaiMatKhau() {
    // Validate new password
    if (txtNewPassword.text.isEmpty) {
      DialogHandler.showError("Vui lòng nhập mật khẩu mới");
      return;
    }
    if (!ValidationHandler.isValidPassword(txtNewPassword.text)) {
      DialogHandler.showError("Mật khẩu phải có ít nhất 6 ký tự");
      return;
    }

    // Validate confirm password
    if (txtConfirmPassword.text.isEmpty) {
      DialogHandler.showError("Vui lòng xác nhận mật khẩu mới");
      return;
    }
    if (!ValidationHandler.isPasswordMatch(txtNewPassword.text, txtConfirmPassword.text)) {
      DialogHandler.showError("Mật khẩu xác nhận không khớp");
      return;
    }

    // Success - proceed to success screen
    DialogHandler.showSuccess("Đặt lại mật khẩu thành công!");
    NavigationHandler.goToSuccess();
  }

  void clickLienHeHoTro() {
    DialogHandler.showInfo("Liên hệ: support@hangt1.com");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: NavigationHandler.goBack,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              SizedBox(height: 30),
              Text(
                AppStrings.resetPasswordTitle,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  AppStrings.resetPasswordSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 35),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.newPassword,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: 8),
              CustomTextField(
                controller: txtNewPassword,
                hintText: AppStrings.passwordPlaceholder,
                prefixIcon: Icons.lock_outline,
                suffixIcon: Icons.visibility_off_outlined,
                obscureText: true,
              ),
              SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.confirmNewPassword,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: 8),
              CustomTextField(
                controller: txtConfirmPassword,
                hintText: AppStrings.passwordPlaceholder,
                prefixIcon: Icons.check_circle_outline,
                suffixIcon: Icons.visibility_off_outlined,
                obscureText: true,
              ),
              SizedBox(height: 30),
              PrimaryButton(
                text: AppStrings.resetPassword,
                onPressed: clickDatLaiMatKhau,
              ),
              SizedBox(height: 30),
              GestureDetector(
                onTap: NavigationHandler.goBackToLogin,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      AppStrings.backToLogin,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.needHelp,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  GestureDetector(
                    onTap: clickLienHeHoTro,
                    child: Text(
                      AppStrings.contactSupport,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
