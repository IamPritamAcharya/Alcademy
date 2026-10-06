import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';

class CustomSnackBar {
  static SnackBar build({
    String message =
        'You have used too many refreshes.\n• Your refresh will work again in 1 hour.\n• This limitation is due to the app being free of cost.\n• I apologize for the inconvenience.',
    bool isCooldown = false,
    BuildContext? context,
  }) => SnackBar(
    content: Text(
      message,
      style: const TextStyle(
        color: AppStyle.text,
        fontFamily: 'ProductSans',
        fontSize: 14,
        height: 1.5,
      ),
    ),
    backgroundColor: AppStyle.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: AppStyle.radius,
      side: BorderSide(color: isCooldown ? AppStyle.danger : AppStyle.rule),
    ),
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 3),
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  );
}
