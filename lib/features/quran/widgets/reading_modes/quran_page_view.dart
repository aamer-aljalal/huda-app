import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class QuranPageView extends StatefulWidget {
  const QuranPageView({
    super.key,
    required this.pageController,
    required this.totalPages,
    required this.buildPageSliver,
    required this.onPageChanged,
    this.initialPage = 0,
  });

  final PageController pageController;
  final int totalPages;
  final Widget Function(int pageIndex) buildPageSliver;
  final ValueChanged<int> onPageChanged;
  final int initialPage;

  @override
  State<QuranPageView> createState() => _QuranPageViewState();
}

class _QuranPageViewState extends State<QuranPageView> {
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: widget.pageController,
            itemCount: widget.totalPages,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              widget.onPageChanged(index);
            },
            itemBuilder: (context, index) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: widget.buildPageSliver(index),
              );
            },
          ),
        ),
        SizedBox(height: 8.h),
        // Sleek page indicator badge
        Text(
          '${_currentPage + 1}',
          style: TextStyle(
            color: Colors.black,
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            // fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}
