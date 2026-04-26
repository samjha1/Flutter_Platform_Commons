import 'package:flutter/material.dart';

class StaggeredItem extends StatelessWidget {
  const StaggeredItem({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delay = (index % 10) * 40;
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + delay),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, c) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, (1 - value) * 14), child: c),
      ),
      child: child,
    );
  }
}
