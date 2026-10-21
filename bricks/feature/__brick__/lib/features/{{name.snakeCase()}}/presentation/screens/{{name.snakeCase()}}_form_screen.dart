import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_ui/fallah_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:{{package.snakeCase()}}/core/error/failure_message.dart';
import 'package:{{package.snakeCase()}}/core/l10n/l10n_extension.dart';

import '../providers/{{name.snakeCase()}}_providers.dart';
import '../widgets/{{name.snakeCase()}}_form.dart';

/// Create (`id == null`) or edit screen.
class {{name.pascalCase()}}FormScreen extends ConsumerWidget {
  const {{name.pascalCase()}}FormScreen({super.key, this.id});

  final int? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final id = this.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(id == null ? l10n.{{name.camelCase()}}New : l10n.{{name.camelCase()}}EditTitle),
      ),
      body: id == null
          ? const {{name.pascalCase()}}Form()
          : ref.watch({{name.camelCase()}}DetailProvider(id)).when(
                loading: () => const AppSkeleton.list(itemCount: 3),
                error: (error, _) {
                  final failure = error is Failure
                      ? error
                      : UnknownFailure('$error', error);
                  return AppErrorView(
                    failure: failure,
                    message: failureMessage(l10n, failure),
                    retryLabel: l10n.retry,
                    onRetry: () =>
                        ref.invalidate({{name.camelCase()}}DetailProvider(id)),
                  );
                },
                data: (entity) => {{name.pascalCase()}}Form(initial: entity),
              ),
    );
  }
}
