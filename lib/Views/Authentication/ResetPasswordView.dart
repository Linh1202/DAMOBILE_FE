import 'package:flutter/material.dart';
import '../../Utils/Handlers/NavigationHandler.dart';
import '../../Utils/Handlers/ValidationHandler.dart';
import '../../Utils/Handlers/DialogHandler.dart';
import '../../Utils/Constants/AppColors.dart';
import '../../Utils/Constants/AppStrings.dart';
import '../../Widgets/Buttons/PrimaryButton.dart';
import '../../Widgets/Inputs/CustomTextField.dart';
import '../../Services/AuthService.dart';

class ResetPasswordView extends StatefulWidget {
  @override
  _ResetPasswordViewState createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  TextEditingController txtNewPassword = TextEditingController();
  TextEditingController txtConfirmPassword = TextEditingController();
  
  AuthService authService = AuthService();
  bool isLoading = false;
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;
  
  String email = "";
  String otp = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Nhận email và OTP từ màn hình VerifyCode
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      email = args['email'] ?? "";
      otp = args['otp'] ?? "";
    }
  }

  @override
  void dispose() {
    txtNewPassword.dispose();
    txtConfirmPassword.dispose();
    super.dispose();
  }

  Future<void> clickDatLaiMatKhau() async {
    // Đóng bàn phím
    FocusScope.of(context).unfocus();

    // Validate
    if (txtNewPassword.text.isEmpty) {
      DialogHandler.showError("Vui lòng nhập mật khẩu mới");
      return;
    }
    if (!ValidationHandler.isValidPassword(txtNewPassword.text)) {
      DialogHandler.showError("Mật khẩu phải có ít nhất 6 ký tự");
      return;
    }

    if (txtConfirmPassword.text.isEmpty) {
      DialogHandler.showError("Vui lòng xác nhận mật khẩu mới");
      return;
    }
    if (!ValidationHandler.isPasswordMatch(txtNewPassword.text, txtConfirmPassword.text)) {
      DialogHandler.showError("Mật khẩu xác nhận không khớp");
      return;
    }

    if (email.isEmpty || otp.isEmpty) {
      DialogHandler.showError("Thông tin xác thực không hợp lệ. Vui lòng thử lại từ đầu.");
      return;
    }

    setState(() => isLoading = true);

    try {
      // Gọi API /user/reset-password
      var response = await authService.resetPassword(
        email: email,
        newPassword: txtNewPassword.text,
        code: otp, // BE sẽ nhận field 'otp'
      );

      if (response.success) {
        DialogHandler.showSuccess(
          response.message.isNotEmpty 
              ? response.message 
              : "Đặt lại mật khẩu thành công!",
        );
        NavigationHandler.goToSuccess();
      } else {
        DialogHandler.showError(response.message);
      }
    } catch (e) {
      var message = e.toString();
      if (message.startsWith('Exception: ')) {
        message = message.replaceFirst('Exception: ', '');
      }
      DialogHandler.showError(message);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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
                suffixIcon: obscureNewPassword 
                    ? Icons.visibility_off_outlined 
                    : Icons.visibility_outlined,
                obscureText: obscureNewPassword,
                onSuffixIconTap: () {
                  setState(() => obscureNewPassword = !obscureNewPassword);
                },
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
                suffixIcon: obscureConfirmPassword 
                    ? Icons.visibility_off_outlined 
                    : Icons.visibility_outlined,
                obscureText: obscureConfirmPassword,
                onSuffixIconTap: () {
                  setState(() => obscureConfirmPassword = !obscureConfirmPassword);
                },
              ),
              SizedBox(height: 30),
              PrimaryButton(
                text: AppStrings.resetPassword,
                onPressed: isLoading ? null : clickDatLaiMatKhau,
                isLoading: isLoading,
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
                    onTap: () {
                      DialogHandler.showInfo("Liên hệ: support@hangt1.com");
                    },
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
