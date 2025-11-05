import 'package:flutter/material.dart';

class StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  StickyHeaderDelegate({
    required this.child,
    this.minExtentHeight = 48,
    this.maxExtentHeight = 48,
  });

  final Widget child;
  final double minExtentHeight;
  final double maxExtentHeight;

  @override
  double get minExtent => minExtentHeight;

  @override
  double get maxExtent => maxExtentHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.96),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant StickyHeaderDelegate oldDelegate) {
    return child != oldDelegate.child ||
        minExtentHeight != oldDelegate.minExtentHeight ||
        maxExtentHeight != oldDelegate.maxExtentHeight;
  }
}
