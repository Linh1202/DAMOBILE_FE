import 'package:flutter/material.dart';
import '../../Utils/Constants/AppColors.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double borderRadius;
  final Widget? icon;
  final bool isLoading;

  const PrimaryButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.borderRadius = 12,
    this.icon,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;

    final ButtonStyle style = ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
        if (states.contains(MaterialState.disabled)) {
          return AppColors.primary.withOpacity(0.6);
        }
        return AppColors.primary;
      }),
      foregroundColor: MaterialStateProperty.all(AppColors.textWhite),
      minimumSize: MaterialStateProperty.all(Size(double.infinity, 55)),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      elevation: MaterialStateProperty.all(0),
    );

    return ElevatedButton(
      onPressed: disabled ? null : onPressed,
      style: style,
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                strokeWidth: 2,
              ),
            )
          : (icon != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      icon!,
                    ],
                  )
                : Text(
                    text,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  )),
    );
  }
}
