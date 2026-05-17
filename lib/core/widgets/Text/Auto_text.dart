import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:auto_size_text/auto_size_text.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'package:huda/core/theme/app_theme.dart';

// class AutoText extends StatelessWidget {
//   final String content;
//   final Color? color;
//   const AutoText({super.key, required this.content, this.color});

//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: AutoSizeText(
//         content,
//         maxLines: 2,
//         minFontSize: 6,
//         stepGranularity: 0.1,
//         overflow: TextOverflow.ellipsis,
//         textAlign: TextAlign.center,
//         style: TextStyle(
//           fontWeight: FontWeight.bold,
//           color: color ?? Theme.of(context).colorScheme.onSurface,
//         ),
//       ),
//     );
//   }
// }

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class AutoText extends StatelessWidget {
  final String content;
  final Color? color;

  const AutoText({super.key, required this.content, this.color});

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
          maxFontSize: 28,
          stepGranularity: 0.5,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            height: 1.8.h,
            color: color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
