import 'package:doanmobile/Services/AuthStorage.dart';
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

class LoginView extends StatefulWidget {
  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  TextEditingController txtEmail = TextEditingController();
  TextEditingController txtPassword = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  AuthService authService = AuthService();

  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    txtEmail.dispose();
    txtPassword.dispose();
    super.dispose();
  }

  Future<void> clickDangNhap() async {
    FocusScope.of(context).unfocus();

    var form = formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() => isLoading = true);

    try {
      var response = await authService.login(
        txtEmail.text.trim(),
        txtPassword.text,
      );

      if (response.success) {
        AppGlobals.userName = response.data.user.fullName.isNotEmpty
            ? response.data.user.fullName
            : response.data.user.email;
        await AuthStorage.saveToken(response.data.token);

        DialogHandler.showSuccess(
          response.message.isNotEmpty
              ? response.message
              : "Đăng nhập thành công!",
        );
        NavigationHandler.goToHome();
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
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                SizedBox(height: 30),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.teal,
                    image: DecorationImage(
                      image: AssetImage("Assets/Images/anh1.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  AppStrings.loginSubtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 35),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppStrings.email,
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
                  hintText: "nhập email",
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => ValidationHandler.getEmailError(v ?? ''),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppStrings.password,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                CustomTextField(
                  controller: txtPassword,
                  hintText: "nhập mật khẩu",
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  obscureText: obscurePassword,
                  onSuffixIconTap: () =>
                      setState(() => obscurePassword = !obscurePassword),
                  validator: (v) => ValidationHandler.getPasswordError(v ?? ''),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => clickDangNhap(),
                ),
                SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: NavigationHandler.goToForgotPassword,
                    child: Text(
                      AppStrings.forgotPassword,
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                PrimaryButton(
                  text: AppStrings.login,
                  onPressed: isLoading ? null : clickDangNhap,
                  icon: Icon(Icons.arrow_forward, size: 20),
                  isLoading: isLoading,
                ),
                SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Text(
                        AppStrings.orContinueWith,
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
                SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.noAccount,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: NavigationHandler.goToRegister,
                      child: Text(
                        AppStrings.registerNow,
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
