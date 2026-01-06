import 'package:flutter/material.dart';
import '../../Utils/Handlers/NavigationHandler.dart';
import '../../Utils/Handlers/ValidationHandler.dart';
import '../../Utils/Handlers/DialogHandler.dart';
import '../../Utils/Constants/AppColors.dart';
import '../../Utils/Constants/AppStrings.dart';
import '../../Widgets/Buttons/PrimaryButton.dart';
import '../../Widgets/Inputs/CustomTextField.dart';
import '../../Services/AuthService.dart';

class ForgotPasswordView extends StatefulWidget {
  @override
  _ForgotPasswordViewState createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  TextEditingController txtEmail = TextEditingController();
  AuthService authService = AuthService();
  bool isLoading = false;

  @override
  void dispose() {
    txtEmail.dispose();
    super.dispose();
  }

  Future<void> clickGuiMaXacThuc() async {
    // Đóng bàn phím
    FocusScope.of(context).unfocus();

    // Validate email
    if (txtEmail.text.isEmpty) {
      DialogHandler.showError("Vui lòng nhập email");
      return;
    }
    if (!ValidationHandler.isValidEmail(txtEmail.text)) {
      DialogHandler.showError("Email không hợp lệ");
      return;
    }

    setState(() => isLoading = true);

    try {
      // Gọi API /user/forgot-password
      var response = await authService.forgotPassword(txtEmail.text.trim());

      if (response.success) {
        DialogHandler.showSuccess(
          response.message.isNotEmpty 
              ? response.message 
              : "Mã xác thực đã được gửi đến email của bạn!",
        );
        // Chuyển sang màn hình nhập OTP, truyền email qua arguments
        Navigator.pushNamed(
          context,
          '/verify-code',
          arguments: {'email': txtEmail.text.trim()},
        );
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
                AppStrings.forgotPasswordTitle,
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
                  AppStrings.forgotPasswordSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 40),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Email",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: 8),
              CustomTextField(
                controller: txtEmail,
                hintText: "user@gmail.com",
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 30),
              PrimaryButton(
                text: AppStrings.sendCode,
                onPressed: isLoading ? null : clickGuiMaXacThuc,
                isLoading: isLoading,
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
