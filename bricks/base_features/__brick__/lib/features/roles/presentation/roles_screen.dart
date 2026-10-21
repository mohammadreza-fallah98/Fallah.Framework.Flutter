import 'package:fallah_api/fallah_api.dart';
import 'package:fallah_ui/fallah_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:{{project_name.snakeCase()}}/core/api/api_providers.dart';
import 'package:{{project_name.snakeCase()}}/core/auth/can.dart';
import 'package:{{project_name.snakeCase()}}/core/l10n/l10n_extension.dart';
import 'package:{{project_name.snakeCase()}}/core/widgets/async_body.dart';
import 'package:{{project_name.snakeCase()}}/core/widgets/dialogs.dart';
import 'package:{{project_name.snakeCase()}}/features/base_routes.dart';

class RolesScreen extends ConsumerWidget {
  const RolesScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, [Role? role]) async {
    final l10n = context.l10n;
    final values = await showFieldsDialog(
      context,
      title: role == null ? l10n.roleNew : l10n.roleEdit,
      fields: [
        DialogField(l10n.roleName, initial: role?.name ?? ''),
        DialogField(
          l10n.roleDescription,
          initial: role?.description ?? '',
          required: false,
        ),
      ],
    );
    if (values == null || !context.mounted) return;

    final repo = ref.read(roleRepositoryProvider);
    final description = values[1].isEmpty ? null : values[1];
    final failure = (role == null
            ? await repo.add(
                Role(id: 0, name: values[0], description: description),
              )
            : await repo.edit(
                Role(
                  id: role.id,
                  name: values[0],
                  description: description,
                  audit: role.audit,
                ),
              ))
        .failureOrNull;
    if (!context.mounted) return;
    if (failure != null) return showFailure(context, failure);
    ref.invalidate(rolesLookupProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Role role) async {
    if (!await confirmDelete(context) || !context.mounted) return;
    final failure =
        (await ref.read(roleRepositoryProvider).remove(role.id)).failureOrNull;
    if (!context.mounted) return;
    if (failure != null) return showFailure(context, failure);
    ref.invalidate(rolesLookupProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.rolesTitle)),
      floatingActionButton: ref.can('role:create')
          ? FloatingActionButton(
              tooltip: l10n.add,
              onPressed: () => _edit(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
      body: AsyncBody<List<Role>>(
        value: ref.watch(rolesLookupProvider),
        onRetry: () => ref.invalidate(rolesLookupProvider),
        data: (roles) => roles.isEmpty
            ? AppEmptyView(message: l10n.rolesEmpty)
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  for (final role in roles)
                    Card(
                      child: ListTile(
                        title: Text(role.name),
                        subtitle: role.description == null
                            ? null
                            : Text(role.description!),
                        onTap: ref.can('role-scope:read')
                            ? () => context.push(BaseRoutes.roleScopes(role.id))
                            : null,
                        trailing: role.id == Role.adminId
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (ref.can('role:update'))
                                    IconButton(
                                      tooltip: l10n.edit,
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _edit(context, ref, role),
                                    ),
                                  if (ref.can('role:delete'))
                                    IconButton(
                                      tooltip: l10n.delete,
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () =>
                                          _delete(context, ref, role),
                                    ),
                                ],
                              ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
