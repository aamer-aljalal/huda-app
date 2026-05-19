import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<bool> ExitConfirmationDialog(BuildContext context) async {
  final shouldExit = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: const Text(
        'خروج من التطبيق',
        textAlign: TextAlign.right,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: const Text(
        'هل أنت متأكد أنك تريد الخروج من التطبيق؟',
        textAlign: TextAlign.right,
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'إلغاء',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 0,
          ),
          child: const Text(
            'خروج',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
  return shouldExit ?? false;
}
