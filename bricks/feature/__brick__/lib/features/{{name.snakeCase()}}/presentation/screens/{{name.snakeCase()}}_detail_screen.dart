import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_ui/fallah_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:{{package.snakeCase()}}/core/auth/can.dart';
import 'package:{{package.snakeCase()}}/core/error/failure_message.dart';
import 'package:{{package.snakeCase()}}/core/l10n/l10n_extension.dart';

import '../{{name.snakeCase()}}_routes.dart';
import '../providers/{{name.snakeCase()}}_providers.dart';

class {{name.pascalCase()}}DetailScreen extends ConsumerWidget {
  const {{name.pascalCase()}}DetailScreen({super.key, required this.id});

  final int id;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteConfirmTitle),
        content: Text(l10n.deleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final failure =
        await ref.read({{name.camelCase()}}MutationProvider.notifier).remove(id);
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (failure == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.deleted)));
      context.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, failure))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final item = ref.watch({{name.camelCase()}}DetailProvider(id));
    final isBusy = ref.watch({{name.camelCase()}}MutationProvider).isLoading;
    final canUpdate = ref.can('{{name.paramCase()}}:update');
    final canDelete = ref.can('{{name.paramCase()}}:delete');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.{{name.camelCase()}}DetailTitle),
        actions: [
          if (canUpdate)
            IconButton(
              tooltip: l10n.edit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: isBusy
                  ? null
                  : () => context.push({{name.pascalCase()}}Routes.edit(id)),
            ),
          if (canDelete)
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: isBusy ? null : () => _confirmDelete(context, ref),
            ),
        ],
      ),
      body: item.when(
        loading: () => const AppSkeleton.list(itemCount: 3),
        error: (error, _) {
          final failure =
              error is Failure ? error : UnknownFailure('$error', error);
          return AppErrorView(
            failure: failure,
            message: failureMessage(l10n, failure),
            retryLabel: l10n.retry,
            onRetry: () => ref.invalidate({{name.camelCase()}}DetailProvider(id)),
          );
        },
        data: (entity) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            ListTile(
              title: Text(l10n.{{name.camelCase()}}FieldTitle),
              subtitle: Text(entity.title),
            ),
            if (entity.createdByName != null)
              ListTile(
                title: Text(entity.createdByName!),
                subtitle: entity.createdAt == null
                    ? null
                    : Text(entity.createdAt!.toLocal().toString()),
              ),
          ],
        ),
      ),
    );
  }
}
