import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class AutoText extends StatelessWidget {
  final String content;
  final Color? color;
  final double? maxFontSize;

  const AutoText({
    super.key,
    required this.content,
    this.color,
    this.maxFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // width: double.infinity,
      child: Center(
        child: AutoSizeText(
          content,
          textAlign: TextAlign.center,
          maxLines: 8,
          minFontSize: 12,
          maxFontSize: maxFontSize ?? 28,
          stepGranularity: 0.5,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontWeight: FontWeight.bold,
            height: 1.8.h,
            color: color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
