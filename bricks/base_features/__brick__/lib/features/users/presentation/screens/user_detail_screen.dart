import 'package:fallah_api/fallah_api.dart';
import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_ui/fallah_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:{{project_name.snakeCase()}}/core/auth/can.dart';
import 'package:{{project_name.snakeCase()}}/core/l10n/l10n_extension.dart';
import 'package:{{project_name.snakeCase()}}/core/widgets/async_body.dart';
import 'package:{{project_name.snakeCase()}}/core/widgets/dialogs.dart';
import 'package:{{project_name.snakeCase()}}/features/base_routes.dart';
import 'package:{{project_name.snakeCase()}}/features/users/presentation/providers/user_providers.dart';

class UserDetailScreen extends ConsumerWidget {
  const UserDetailScreen({required this.id, super.key});

  final int id;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (!await confirmDelete(context)) return;
    final failure = await ref.read(userMutationProvider.notifier).remove(id);
    if (!context.mounted) return;
    if (failure != null) return showFailure(context, failure);
    showMessage(context, context.l10n.deleted);
    context.pop();
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref, {
    required bool isActive,
  }) async {
    final failure = await ref
        .read(userMutationProvider.notifier)
        .setActive(id, isActive: isActive);
    if (!context.mounted) return;
    if (failure != null) showFailure(context, failure);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(userDetailProvider(id));
    final busy = ref.watch(userMutationProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.userDetailTitle),
        actions: [
          if (ref.can('user:update'))
            IconButton(
              tooltip: l10n.edit,
              icon: const Icon(Icons.edit_outlined),
              onPressed:
                  busy ? null : () => context.push(BaseRoutes.userEdit(id)),
            ),
          if (ref.can('user:delete'))
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: busy ? null : () => _delete(context, ref),
            ),
        ],
      ),
      body: AsyncBody<User>(
        value: user,
        onRetry: () => ref.invalidate(userDetailProvider(id)),
        data: (u) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _Row(l10n.userUsername, u.username),
            _Row(l10n.userFirstName, u.firstName),
            _Row(l10n.userLastName, u.lastName),
            _Row(l10n.userMobile, u.mobile),
            _Row(l10n.userNationalCode, u.nationalCode),
            _Row(l10n.userEmail, u.email),
            if (ref.can('user:update'))
              SwitchListTile(
                title: Text(l10n.userActive),
                value: u.isActive,
                onChanged: busy
                    ? null
                    : (v) => _toggleActive(context, ref, isActive: v),
              ),
            if (u.audit.createdAt != null)
              _Row(l10n.userCreatedAt, formatJalali(u.audit.createdAt!)),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = value;
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return ListTile(title: Text(label), subtitle: Text(text));
  }
}
