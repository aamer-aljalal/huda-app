import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';

class AppSnackBar {
  static void show(
    BuildContext context, {
    required Object message,
    bool success = false,
  }) {
    final cleanedMessage = _cleanMessage(message);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        content: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: success
                    ? [
                        Color.fromARGB(255, 53, 131, 55),
                        Color.fromARGB(255, 80, 170, 84),
                      ]
                    : [
                        Color.fromARGB(255, 232, 175, 3),
                        Color.fromARGB(255, 255, 162, 0),
                      ],
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Text(
                cleanedMessage, //  نعرض الرسالة بعد تنظيفها
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp,
                ),
              ),
            ),
          ),
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 100, left: 16, right: 16),
      ),
    );
  }

  static String _cleanMessage(Object error) {
    String message = error.toString();

    // إزالة كلمة Exception:
    if (message.startsWith('Exception: ')) {
      message = message.replaceFirst('Exception: ', '');
    }

    return message;
  }
}
