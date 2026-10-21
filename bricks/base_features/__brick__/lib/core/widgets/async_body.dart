import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_ui/fallah_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:{{project_name.snakeCase()}}/core/error/failure_message.dart';
import 'package:{{project_name.snakeCase()}}/core/l10n/l10n_extension.dart';

/// Skeleton -> Error (with retry) -> content for an [AsyncValue].
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    required this.value,
    required this.data,
    this.onRetry,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return value.when(
      loading: () => const AppSkeleton.list(),
      error: (error, _) {
        final failure =
            error is Failure ? error : UnknownFailure('$error', error);
        return AppErrorView(
          failure: failure,
          message: failureMessage(l10n, failure),
          retryLabel: l10n.retry,
          onRetry: onRetry,
        );
      },
      data: data,
    );
  }
}

/// [AsyncBody] for a [PagedState]: empty view, infinite scroll, pull to
/// refresh.
class PagedAsyncList<T> extends StatelessWidget {
  const PagedAsyncList({
    required this.value,
    required this.itemBuilder,
    required this.emptyMessage,
    required this.onLoadMore,
    required this.onRefresh,
    super.key,
  });

  final AsyncValue<PagedState<T>> value;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyMessage;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => AsyncBody<PagedState<T>>(
        value: value,
        onRetry: onRefresh,
        data: (state) => state.items.isEmpty
            ? AppEmptyView(message: emptyMessage)
            : AppPagedList<T>(
                items: state.items,
                hasMore: state.hasMore,
                isLoadingMore: state.isLoadingMore,
                onLoadMore: onLoadMore,
                onRefresh: onRefresh,
                itemBuilder: itemBuilder,
              ),
      );
}
