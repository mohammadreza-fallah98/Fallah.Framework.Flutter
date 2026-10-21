import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Infinite-scroll list. The caller owns paging state: append items and flip
/// [hasMore] / [isLoadingMore]; this widget asks for more near the end, once
/// per list length (so rebuilds never fire duplicate requests).
class AppPagedList<T> extends StatefulWidget {
  const AppPagedList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.onRefresh,
    this.loadMoreThreshold = 3,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final Future<void> Function()? onRefresh;
  final int loadMoreThreshold;
  final EdgeInsetsGeometry padding;

  @override
  State<AppPagedList<T>> createState() => _AppPagedListState<T>();
}

class _AppPagedListState<T> extends State<AppPagedList<T>> {
  /// List length for which a load-more was already requested.
  int? _requestedAtLength;

  @override
  void didUpdateWidget(AppPagedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A refresh shrinks/replaces the list: allow requesting again.
    if (widget.items.length < (oldWidget.items.length)) {
      _requestedAtLength = null;
    }
  }

  void _maybeLoadMore(int index) {
    final w = widget;
    if (!w.hasMore || w.isLoadingMore || w.onLoadMore == null) return;
    if (index < w.items.length - w.loadMoreThreshold) return;
    if (_requestedAtLength == w.items.length) return;
    _requestedAtLength = w.items.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) w.onLoadMore?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final showFooter = w.hasMore || w.isLoadingMore;

    final list = ListView.separated(
      padding: w.padding,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: w.items.length + (showFooter ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index >= w.items.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        _maybeLoadMore(index);
        return w.itemBuilder(context, w.items[index]);
      },
    );

    return w.onRefresh == null
        ? list
        : RefreshIndicator(onRefresh: w.onRefresh!, child: list);
  }
}
