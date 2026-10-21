import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_ui/fallah_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:{{package.snakeCase()}}/core/auth/can.dart';
import 'package:{{package.snakeCase()}}/core/error/failure_message.dart';
import 'package:{{package.snakeCase()}}/core/l10n/l10n_extension.dart';

import '../../domain/entities/{{name.snakeCase()}}.dart';
import '../{{name.snakeCase()}}_routes.dart';
import '../providers/{{name.snakeCase()}}_providers.dart';
import '../widgets/{{name.snakeCase()}}_card.dart';

class {{name.pascalCase()}}ListScreen extends ConsumerWidget {
  const {{name.pascalCase()}}ListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch({{name.camelCase()}}ListProvider);
    final canCreate = ref.can('{{name.paramCase()}}:create');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.{{plural.camelCase()}}Title)),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              tooltip: l10n.add,
              onPressed: () => context.push({{name.pascalCase()}}Routes.create),
              child: const Icon(Icons.add),
            )
          : null,
      body: state.when(
        loading: () => const AppSkeleton.list(),
        error: (error, _) {
          final failure =
              error is Failure ? error : UnknownFailure('$error', error);
          return AppErrorView(
            failure: failure,
            message: failureMessage(l10n, failure),
            retryLabel: l10n.retry,
            onRetry: () => ref.invalidate({{name.camelCase()}}ListProvider),
          );
        },
        data: (list) => list.items.isEmpty
            ? AppEmptyView(message: l10n.{{plural.camelCase()}}Empty)
            : AppPagedList<{{name.pascalCase()}}>(
                items: list.items,
                hasMore: list.hasMore,
                isLoadingMore: list.isLoadingMore,
                onLoadMore: () =>
                    ref.read({{name.camelCase()}}ListProvider.notifier).loadMore(),
                onRefresh: () => ref.refresh({{name.camelCase()}}ListProvider.future),
                itemBuilder: (context, item) => {{name.pascalCase()}}Card(
                  item: item,
                  onTap: () => context.push({{name.pascalCase()}}Routes.detail(item.id)),
                ),
              ),
      ),
    );
  }
}
