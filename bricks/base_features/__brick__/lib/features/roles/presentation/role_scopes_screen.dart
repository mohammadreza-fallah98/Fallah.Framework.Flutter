import 'package:fallah_api/fallah_api.dart';
import 'package:fallah_ui/fallah_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:{{project_name.snakeCase()}}/core/api/api_providers.dart';
import 'package:{{project_name.snakeCase()}}/core/auth/can.dart';
import 'package:{{project_name.snakeCase()}}/core/l10n/l10n_extension.dart';
import 'package:{{project_name.snakeCase()}}/core/widgets/async_body.dart';
import 'package:{{project_name.snakeCase()}}/core/widgets/dialogs.dart';
import 'package:{{project_name.snakeCase()}}/l10n/app_localizations.dart';

part 'role_scopes_screen.g.dart';

/// All scopes of one role.
@riverpod
Future<List<RoleScope>> roleScopes(Ref ref, int roleId) async {
  final page = await ref.watch(roleScopeRepositoryProvider).byRole(roleId);
  return page.getOrThrow().items;
}

/// Matrix of entity x (read, create, update, delete) + row visibility for a
/// role. Every change is saved immediately. Needs `role-scope:update`.
class RoleScopesScreen extends ConsumerWidget {
  const RoleScopesScreen({required this.roleId, super.key});

  final int roleId;

  RoleScope _copy(
    RoleScope s, {
    bool? canRead,
    bool? canCreate,
    bool? canUpdate,
    bool? canDelete,
    int? visibilityLevel,
  }) =>
      RoleScope(
        id: s.id,
        roleId: s.roleId,
        entityName: s.entityName,
        canRead: canRead ?? s.canRead,
        canCreate: canCreate ?? s.canCreate,
        canUpdate: canUpdate ?? s.canUpdate,
        canDelete: canDelete ?? s.canDelete,
        visibilityLevel: visibilityLevel ?? s.visibilityLevel,
        audit: s.audit,
      );

  Future<void> _save(BuildContext context, WidgetRef ref, RoleScope s) async {
    final failure =
        (await ref.read(roleScopeRepositoryProvider).edit(s)).failureOrNull;
    if (!context.mounted) return;
    if (failure != null) showFailure(context, failure);
    // Reload either way so a conflict shows the server's current values.
    ref.invalidate(roleScopesProvider(roleId));
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final values = await showFieldsDialog(
      context,
      title: l10n.scopeNew,
      fields: [DialogField(l10n.scopeEntity, ltr: true)],
    );
    if (values == null || !context.mounted) return;
    final failure = (await ref.read(roleScopeRepositoryProvider).add(
              RoleScope(id: 0, roleId: roleId, entityName: values[0]),
            ))
        .failureOrNull;
    if (!context.mounted) return;
    if (failure != null) return showFailure(context, failure);
    ref.invalidate(roleScopesProvider(roleId));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, int id) async {
    if (!await confirmDelete(context) || !context.mounted) return;
    final failure =
        (await ref.read(roleScopeRepositoryProvider).remove(id)).failureOrNull;
    if (!context.mounted) return;
    if (failure != null) return showFailure(context, failure);
    ref.invalidate(roleScopesProvider(roleId));
  }

  String _visibilityLabel(AppLocalizations l10n, int level) =>
      switch (VisibilityLevel.fromCode(level)) {
        VisibilityLevel.own => l10n.visibilityOwn,
        VisibilityLevel.roles => l10n.visibilityRoles,
        VisibilityLevel.assigned => l10n.visibilityAssigned,
        VisibilityLevel.all => l10n.visibilityAll,
        null => '$level',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final editable = ref.can('role-scope:update');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.roleScopesTitle)),
      floatingActionButton: ref.can('role-scope:create')
          ? FloatingActionButton(
              tooltip: l10n.add,
              onPressed: () => _add(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
      body: AsyncBody<List<RoleScope>>(
        value: ref.watch(roleScopesProvider(roleId)),
        onRetry: () => ref.invalidate(roleScopesProvider(roleId)),
        data: (scopes) => scopes.isEmpty
            ? AppEmptyView(message: l10n.scopesEmpty)
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  for (final s in scopes)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    s.entityName,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                if (ref.can('role-scope:delete'))
                                  IconButton(
                                    tooltip: l10n.delete,
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () =>
                                        _delete(context, ref, s.id),
                                  ),
                              ],
                            ),
                            Wrap(
                              spacing: AppSpacing.sm,
                              children: [
                                FilterChip(
                                  label: Text(l10n.scopeRead),
                                  selected: s.canRead,
                                  onSelected: editable
                                      ? (v) => _save(
                                            context,
                                            ref,
                                            _copy(s, canRead: v),
                                          )
                                      : null,
                                ),
                                FilterChip(
                                  label: Text(l10n.scopeCreate),
                                  selected: s.canCreate,
                                  onSelected: editable
                                      ? (v) => _save(
                                            context,
                                            ref,
                                            _copy(s, canCreate: v),
                                          )
                                      : null,
                                ),
                                FilterChip(
                                  label: Text(l10n.scopeUpdate),
                                  selected: s.canUpdate,
                                  onSelected: editable
                                      ? (v) => _save(
                                            context,
                                            ref,
                                            _copy(s, canUpdate: v),
                                          )
                                      : null,
                                ),
                                FilterChip(
                                  label: Text(l10n.scopeDelete),
                                  selected: s.canDelete,
                                  onSelected: editable
                                      ? (v) => _save(
                                            context,
                                            ref,
                                            _copy(s, canDelete: v),
                                          )
                                      : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            DropdownButtonFormField<int>(
                              initialValue: s.visibilityLevel,
                              decoration: InputDecoration(
                                labelText: l10n.scopeVisibility,
                              ),
                              items: [
                                for (final code in {
                                  ...VisibilityLevel.values.map((v) => v.code),
                                  s.visibilityLevel,
                                })
                                  DropdownMenuItem(
                                    value: code,
                                    child: Text(_visibilityLabel(l10n, code)),
                                  ),
                              ],
                              onChanged: editable
                                  ? (v) => v == null
                                      ? null
                                      : _save(
                                          context,
                                          ref,
                                          _copy(s, visibilityLevel: v),
                                        )
                                  : null,
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
