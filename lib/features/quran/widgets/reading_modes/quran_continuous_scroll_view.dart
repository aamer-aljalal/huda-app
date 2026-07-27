import 'package:flutter/material.dart';

class QuranContinuousScrollView extends StatelessWidget {
  const QuranContinuousScrollView({
    super.key,
    required this.scrollController,
    required this.centerSliverKey,
    required this.centerPage,
    required this.totalPages,
    required this.buildPageSliver,
    required this.onScrollEnd,
  });

  final ScrollController scrollController;
  final GlobalKey centerSliverKey;
  final int centerPage;
  final int totalPages;
  final Widget Function(int index) buildPageSliver;
  final VoidCallback onScrollEnd;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          onScrollEnd();
        }
        return false;
      },
      child: CustomScrollView(
        controller: scrollController,
        center: centerSliverKey,
        physics: const ClampingScrollPhysics(),
        slivers: [
          if (centerPage > 0)
            SliverList(
              delegate: SliverChildBuilderDelegate((
                context,
                index,
              ) {
                final actualIndex = centerPage - 1 - index;
                return buildPageSliver(actualIndex);
              }, childCount: centerPage),
            ),
          SliverList(
            key: centerSliverKey,
            delegate: SliverChildBuilderDelegate((
              context,
              index,
            ) {
              final actualIndex = centerPage + index;
              return buildPageSliver(actualIndex);
            }, childCount: totalPages - centerPage),
          ),
        ],
      ),
    );
  }
}
