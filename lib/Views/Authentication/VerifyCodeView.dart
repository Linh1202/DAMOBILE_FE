import 'package:flutter/material.dart';
import 'dart:async';
import '../../Utils/Handlers/NavigationHandler.dart';
import '../../Utils/Handlers/DialogHandler.dart';
import '../../Utils/Constants/AppColors.dart';
import '../../Utils/Constants/AppStrings.dart';
import '../../Widgets/Buttons/PrimaryButton.dart';
import '../../Widgets/Inputs/CodeInputBox.dart';
import '../../Services/AuthService.dart';

class VerifyCodeView extends StatefulWidget {
  @override
  State<VerifyCodeView> createState() => _VerifyCodeViewState();
}

class _VerifyCodeViewState extends State<VerifyCodeView> {
  TextEditingController txtCode1 = TextEditingController();
  TextEditingController txtCode2 = TextEditingController();
  TextEditingController txtCode3 = TextEditingController();
  TextEditingController txtCode4 = TextEditingController();
  TextEditingController txtCode5 = TextEditingController();
  TextEditingController txtCode6 = TextEditingController();

  FocusNode focusNode1 = FocusNode();
  FocusNode focusNode2 = FocusNode();
  FocusNode focusNode3 = FocusNode();
  FocusNode focusNode4 = FocusNode();
  FocusNode focusNode5 = FocusNode();
  FocusNode focusNode6 = FocusNode();

  int _secondsRemaining = 119;
  Timer? _timer;
  String email = "";
  String maskedEmail = "";
  bool isLoading = false;
  bool isResending = false;

  AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['email'] != null) {
      email = args['email'];
      maskedEmail = _maskEmail(email);
    }
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return "";
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return email;
    return "${name.substring(0, 2)}***@$domain";
  }

  @override
  void dispose() {
    _timer?.cancel();
    txtCode1.dispose();
    txtCode2.dispose();
    txtCode3.dispose();
    txtCode4.dispose();
    txtCode5.dispose();
    txtCode6.dispose();
    focusNode1.dispose();
    focusNode2.dispose();
    focusNode3.dispose();
    focusNode4.dispose();
    focusNode5.dispose();
    focusNode6.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  String get _formattedTime {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  String get _otpCode {
    return txtCode1.text + txtCode2.text + txtCode3.text + 
           txtCode4.text + txtCode5.text + txtCode6.text;
  }

  void clickXacNhan() {
    // Validate OTP
    if (_otpCode.isEmpty) {
      DialogHandler.showError("Vui lòng nhập mã xác thực");
      return;
    }
    if (_otpCode.length != 6) {
      DialogHandler.showError("Mã xác thực phải có 6 chữ số");
      return;
    }

    // Check if timer expired
    if (_secondsRemaining <= 0) {
      DialogHandler.showError("Mã xác thực đã hết hạn. Vui lòng gửi lại mã mới.");
      return;
    }

    Navigator.pushNamed(
      context,
      '/reset-password',
      arguments: {
        'email': email,
        'otp': _otpCode,
      },
    );
  }

  Future<void> clickGuiLaiMa() async {
    if (email.isEmpty) {
      DialogHandler.showError("Không tìm thấy email. Vui lòng quay lại và thử lại.");
      return;
    }

    setState(() => isResending = true);

    try {
      var response = await authService.forgotPassword(email);

      if (response.success) {
        setState(() {
          _secondsRemaining = 119;
          txtCode1.clear();
          txtCode2.clear();
          txtCode3.clear();
          txtCode4.clear();
          txtCode5.clear();
          txtCode6.clear();
        });
        _timer?.cancel();
        _startTimer();
        focusNode1.requestFocus();
        DialogHandler.showSuccess("Mã xác thực mới đã được gửi!");
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
      if (mounted) setState(() => isResending = false);
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
                AppStrings.verifyCodeTitle,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(text: "Chúng tôi đã gửi mã gồm 6 chữ số đến email\n"),
                    TextSpan(
                      text: maskedEmail.isNotEmpty ? maskedEmail : "us***@gmail.com",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CodeInputBox(controller: txtCode1, focusNode: focusNode1, nextFocusNode: focusNode2, width: 50, height: 70),
                    CodeInputBox(controller: txtCode2, focusNode: focusNode2, nextFocusNode: focusNode3, previousFocusNode: focusNode1, width: 50, height: 70),
                    CodeInputBox(controller: txtCode3, focusNode: focusNode3, nextFocusNode: focusNode4, previousFocusNode: focusNode2, width: 50, height: 70),
                    CodeInputBox(controller: txtCode4, focusNode: focusNode4, nextFocusNode: focusNode5, previousFocusNode: focusNode3, width: 50, height: 70),
                    CodeInputBox(controller: txtCode5, focusNode: focusNode5, nextFocusNode: focusNode6, previousFocusNode: focusNode4, width: 50, height: 70),
                    CodeInputBox(controller: txtCode6, focusNode: focusNode6, previousFocusNode: focusNode5, width: 50, height: 70),
                  ],
                ),
              ),
              SizedBox(height: 20),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(text: "Mã sẽ hết hạn sau "),
                    TextSpan(
                      text: _formattedTime,
                      style: TextStyle(
                        color: _secondsRemaining <= 30 ? AppColors.error : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              PrimaryButton(
                text: AppStrings.verify,
                onPressed: isLoading ? null : clickXacNhan,
                isLoading: isLoading,
              ),
              SizedBox(height: 25),
              Text(
                AppStrings.noCode,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: isResending ? null : clickGuiLaiMa,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isResending)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    else
                      Icon(
                        Icons.refresh,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    SizedBox(width: 8),
                    Text(
                      AppStrings.resendCode,
                      style: TextStyle(
                        color: isResending ? AppColors.textSecondary : AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
