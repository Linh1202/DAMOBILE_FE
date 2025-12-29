import 'package:flutter/material.dart';
import '../../Utils/AppGlobals.dart';
import '../../Utils/Handlers/NavigationHandler.dart';
import '../../Utils/Handlers/ValidationHandler.dart';
import '../../Utils/Handlers/DialogHandler.dart';
import '../../Utils/Constants/AppColors.dart';
import '../../Utils/Constants/AppStrings.dart';
import '../../Widgets/Buttons/PrimaryButton.dart';
import '../../Widgets/Buttons/GoogleSignInButton.dart';
import '../../Widgets/Inputs/CustomTextField.dart';

class RegisterView extends StatelessWidget {
  TextEditingController txtHoTen = TextEditingController();
  TextEditingController txtEmail = TextEditingController();
  TextEditingController txtPassword = TextEditingController();
  TextEditingController txtConfirmPassword = TextEditingController();

  void clickDangKy() {
    // Validate họ tên
    if (!ValidationHandler.isValidName(txtHoTen.text)) {
      DialogHandler.showError("Vui lòng nhập họ và tên");
      return;
    }

    // Validate email
    if (txtEmail.text.isEmpty) {
      DialogHandler.showError("Vui lòng nhập email");
      return;
    }
    if (!ValidationHandler.isValidEmail(txtEmail.text)) {
      DialogHandler.showError("Email không hợp lệ");
      return;
    }

    // Validate password
    if (txtPassword.text.isEmpty) {
      DialogHandler.showError("Vui lòng nhập mật khẩu");
      return;
    }
    if (!ValidationHandler.isValidPassword(txtPassword.text)) {
      DialogHandler.showError("Mật khẩu phải có ít nhất 6 ký tự");
      return;
    }

    // Validate confirm password
    if (txtConfirmPassword.text.isEmpty) {
      DialogHandler.showError("Vui lòng xác nhận mật khẩu");
      return;
    }
    if (!ValidationHandler.isPasswordMatch(txtPassword.text, txtConfirmPassword.text)) {
      DialogHandler.showError("Mật khẩu xác nhận không khớp");
      return;
    }

    // Success - proceed to home
    AppGlobals.userName = txtHoTen.text;
    DialogHandler.showSuccess("Đăng ký thành công!");
    NavigationHandler.goToHome();
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Text(
                AppStrings.registerTitle,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 30),
              Text(
                AppStrings.fullName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              CustomTextField(
                controller: txtHoTen,
                hintText: AppStrings.namePlaceholder,
                prefixIcon: Icons.person_outline,
              ),
              SizedBox(height: 20),
              Text(
                "Nhập email của bạn",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              CustomTextField(
                controller: txtEmail,
                hintText: AppStrings.emailPlaceholder,
                prefixIcon: Icons.mail_outline,
              ),
              SizedBox(height: 20),
              Text(
                AppStrings.password,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              CustomTextField(
                controller: txtPassword,
                hintText: AppStrings.passwordPlaceholder,
                prefixIcon: Icons.lock_outline,
                suffixIcon: Icons.visibility_off_outlined,
                obscureText: true,
              ),
              SizedBox(height: 20),
              Text(
                AppStrings.confirmPassword,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              CustomTextField(
                controller: txtConfirmPassword,
                hintText: AppStrings.passwordPlaceholder,
                prefixIcon: Icons.lock_outline,
                suffixIcon: Icons.visibility_off_outlined,
                obscureText: true,
              ),
              SizedBox(height: 20),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(text: "Bằng việc đăng ký, bạn đồng ý với "),
                    TextSpan(
                      text: "Điều khoản dịch vụ",
                      style: TextStyle(
                        color: AppColors.primary,
                      ),
                    ),
                    TextSpan(text: " và "),
                    TextSpan(
                      text: "Chính sách bảo mật",
                      style: TextStyle(
                        color: AppColors.primary,
                      ),
                    ),
                    TextSpan(text: " của chúng tôi."),
                  ],
                ),
              ),
              SizedBox(height: 25),
              PrimaryButton(
                text: AppStrings.register,
                onPressed: clickDangKy,
              ),
              SizedBox(height: 25),
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      AppStrings.orRegisterWith,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              SizedBox(height: 25),
              GoogleSignInButton(
                onTap: () {
                  DialogHandler.showInfo("Tính năng đang phát triển");
                },
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.hasAccount,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: NavigationHandler.goToLogin,
                    child: Text(
                      AppStrings.login,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
