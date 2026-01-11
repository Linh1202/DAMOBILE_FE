import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../Utils/Constants/AppColors.dart';

class CodeInputBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;
  final FocusNode? previousFocusNode;
  final double width;
  final double height;

  const CodeInputBox({
    Key? key,
    required this.controller,
    required this.focusNode,
    this.nextFocusNode,
    this.previousFocusNode,
    this.width = 56,
    this.height = 56,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty &&
              previousFocusNode != null) {
            previousFocusNode!.requestFocus();
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          expands: true,
          maxLines: null,
          minLines: null,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            counterText: "",
            filled: true,
            fillColor: AppColors.inputBackground,
            contentPadding: EdgeInsets.zero,
            isDense: false,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderFocused, width: 2),
            ),
          ),
          onChanged: (value) {
            if (value.length == 1 && nextFocusNode != null) {
              nextFocusNode!.requestFocus();
            }
          },
        ),
      ),
    );
  }
}
