import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Pulsing placeholder shown while content loads.
/// `AppSkeleton()` is one bar; `AppSkeleton.list()` is a list of row bars.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({super.key, this.height = 16, this.width})
      : itemCount = null;

  const AppSkeleton.list({super.key, this.itemCount = 6})
      : height = 64,
        width = null;

  final double height;
  final double? width;
  final int? itemCount;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bar(Color color, double? width) => Container(
        height: widget.height,
        width: width,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    final count = widget.itemCount;

    final content = count == null
        ? _bar(color, widget.width)
        : ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: count,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, __) => _bar(color, null),
          );

    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1).animate(_controller),
      child: content,
    );
  }
}
