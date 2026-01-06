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
import '../../Services/AuthService.dart';

class RegisterView extends StatefulWidget {
  @override
  _RegisterViewState createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  TextEditingController txtHoTen = TextEditingController();
  TextEditingController txtEmail = TextEditingController();
  TextEditingController txtPassword = TextEditingController();
  TextEditingController txtConfirmPassword = TextEditingController();
  TextEditingController txtPhoneNumber = TextEditingController();

  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  AuthService authService = AuthService();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    txtHoTen.dispose();
    txtEmail.dispose();
    txtPassword.dispose();
    txtConfirmPassword.dispose();
    super.dispose();
  }

  Future<void> clickDangKy() async {
    // Close keyboard
    FocusScope.of(context).unfocus();

    var form = formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() => isLoading = true);

    try {
      var response = await authService.register(
        email: txtEmail.text.trim(),
        password: txtPassword.text,
        fullName: txtHoTen.text.trim(),
      );

      if (response.success) {
        DialogHandler.showSuccess(
          response.message.isNotEmpty
              ? response.message
              : "Đăng ký thành công! Vui lòng đăng nhập.",
        );
        NavigationHandler.goToLogin();
      } else {
        DialogHandler.showError(response.message);
      }
    } catch (e) {
      var message = e.toString();
      if (message.startsWith("Exception: "))
        message = message.replaceFirst("Exception: ", "");
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
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
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
                  validator: (v) => ValidationHandler.getNameError(v ?? ''),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
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
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => ValidationHandler.getEmailError(v ?? ''),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
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
                  suffixIcon: obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  obscureText: obscurePassword,
                  onSuffixIconTap: () =>
                      setState(() => obscurePassword = !obscurePassword),
                  validator: (v) => ValidationHandler.getPasswordError(v ?? ''),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
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
                  suffixIcon: obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  obscureText: obscureConfirmPassword,
                  onSuffixIconTap: () => setState(
                    () => obscureConfirmPassword = !obscureConfirmPassword,
                  ),
                  validator: (v) => ValidationHandler.getConfirmPasswordError(
                    txtPassword.text,
                    v ?? '',
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => clickDangKy(),
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
                        style: TextStyle(color: AppColors.primary),
                      ),
                      TextSpan(text: " và "),
                      TextSpan(
                        text: "Chính sách bảo mật",
                        style: TextStyle(color: AppColors.primary),
                      ),
                      TextSpan(text: " của chúng tôi."),
                    ],
                  ),
                ),
                SizedBox(height: 25),
                PrimaryButton(
                  text: AppStrings.register,
                  onPressed: isLoading ? null : clickDangKy,
                  isLoading: isLoading,
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
      ),
    );
  }
}
