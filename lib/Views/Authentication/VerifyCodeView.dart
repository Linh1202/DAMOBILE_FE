import 'package:flutter/material.dart';
import 'dart:async';
import '../../Utils/Handlers/NavigationHandler.dart';
import '../../Utils/Handlers/ValidationHandler.dart';
import '../../Utils/Handlers/DialogHandler.dart';
import '../../Utils/Constants/AppColors.dart';
import '../../Utils/Constants/AppStrings.dart';
import '../../Widgets/Buttons/PrimaryButton.dart';
import '../../Widgets/Inputs/CodeInputBox.dart';

class VerifyCodeView extends StatefulWidget {
  @override
  State<VerifyCodeView> createState() => _VerifyCodeViewState();
}

class _VerifyCodeViewState extends State<VerifyCodeView> {
  TextEditingController txtCode1 = TextEditingController();
  TextEditingController txtCode2 = TextEditingController();
  TextEditingController txtCode3 = TextEditingController();
  TextEditingController txtCode4 = TextEditingController();

  FocusNode focusNode1 = FocusNode();
  FocusNode focusNode2 = FocusNode();
  FocusNode focusNode3 = FocusNode();
  FocusNode focusNode4 = FocusNode();

  int _secondsRemaining = 119;
  Timer? _timer;
  String maskedEmail = "us***@gmail.com";

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    txtCode1.dispose();
    txtCode2.dispose();
    txtCode3.dispose();
    txtCode4.dispose();
    focusNode1.dispose();
    focusNode2.dispose();
    focusNode3.dispose();
    focusNode4.dispose();
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

  void clickXacNhan() {
    String code = txtCode1.text + txtCode2.text + txtCode3.text + txtCode4.text;
    
    // Validate OTP
    if (code.isEmpty) {
      DialogHandler.showError("Vui lòng nhập mã xác thực");
      return;
    }
    if (!ValidationHandler.isValidOTP(code)) {
      DialogHandler.showError("Mã xác thực phải có 4 chữ số");
      return;
    }

    // Check if timer expired
    if (_secondsRemaining <= 0) {
      DialogHandler.showError("Mã xác thực đã hết hạn. Vui lòng gửi lại mã mới.");
      return;
    }

    // Success - proceed to reset password
    DialogHandler.showSuccess("Xác thực thành công!");
    NavigationHandler.goToResetPassword();
  }

  void clickGuiLaiMa() {
    setState(() {
      _secondsRemaining = 119;
      txtCode1.clear();
      txtCode2.clear();
      txtCode3.clear();
      txtCode4.clear();
    });
    _timer?.cancel();
    _startTimer();
    focusNode1.requestFocus();
    DialogHandler.showSuccess("Mã xác thực mới đã được gửi!");
  }

  void clickLienHeHoTro() {
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
                    TextSpan(text: "Chúng tôi đã gửi mã gồm 4 chữ số đến email "),
                    TextSpan(
                      text: maskedEmail,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CodeInputBox(controller: txtCode1, focusNode: focusNode1, nextFocusNode: focusNode2),
                  SizedBox(width: 15),
                  CodeInputBox(controller: txtCode2, focusNode: focusNode2, nextFocusNode: focusNode3),
                  SizedBox(width: 15),
                  CodeInputBox(controller: txtCode3, focusNode: focusNode3, nextFocusNode: focusNode4),
                  SizedBox(width: 15),
                  CodeInputBox(controller: txtCode4, focusNode: focusNode4),
                ],
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
                onPressed: clickXacNhan,
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
                onTap: clickGuiLaiMa,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      AppStrings.resendCode,
                      style: TextStyle(
                        color: AppColors.primary,
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
