import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:huda/Model/AccessListModel.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/core/theme/app_radius.dart';

class AccessListGrid extends StatelessWidget {
  final List<AccessListModel> actions;
  final AnimationController controller;

  const AccessListGrid({
    super.key,
    required this.actions,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),

      itemCount: actions.length,
      itemBuilder: (context, index) {
        final item = actions[index];

        // 🔥 نفس فكرة صفحة الأذكار
        final animationDelay = index * 0.05;

        final animation = CurvedAnimation(
          parent: controller,
          curve: Interval(animationDelay, 1.0, curve: Curves.easeOutCubic),
        );

        return FadeTransition(
          opacity: animation,

          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.6),
              end: Offset.zero,
            ).animate(animation),

            child: GestureDetector(
              onTap: () {
                // Navigator.pushNamed(context, item.route);
                Navigator.pushNamed(
                  context,
                  item.route,
                  arguments: item.arguments,
                );
              },

              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: brightness == Brightness.dark
                        ? AppColors.greenBorder.withOpacity(0.50)
                        : AppColors.disabled,
                    width: 2.w,
                  ),

                  // gradient: LinearGradient(
                  //   end: Alignment.bottomRight,
                  //   begin: Alignment.centerLeft,
                  //   colors: [Color(gradient[0]), Color(gradient[1])],
                  // ),
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lightSecondaryText.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(2, 3),
                    ),
                  ],
                ),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    SizedBox(height: 12.h),

                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: brightness == Brightness.dark
                            ? AppColors.primary.withOpacity(0.25)
                            : AppColors.primary.withOpacity(0.22),
                        shape: BoxShape.circle,
                      ),

                      child: Icon(
                        item.icon,
                        size: 30.sp,
                        color: AppColors.greenBorder,
                      ),
                    ),

                    SizedBox(height: 5.h),
                    Expanded(
                      child: AutoSizeText(
                        item.title,
                        maxLines: 2,
                        minFontSize: 4,
                        stepGranularity: 0.1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
