import 'package:fallah_api/fallah_api.dart';
import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_ui/fallah_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:{{project_name.snakeCase()}}/core/api/api_providers.dart';
import 'package:{{project_name.snakeCase()}}/core/l10n/l10n_extension.dart';
import 'package:{{project_name.snakeCase()}}/core/widgets/async_body.dart';
import 'package:{{project_name.snakeCase()}}/l10n/app_localizations.dart';

part 'audit_logs_screen.g.dart';

/// Audit log pages, optionally filtered by entity name (empty = all).
@riverpod
class AuditLogList extends _$AuditLogList {
  @override
  Future<PagedState<AuditLog>> build(String entityName) async =>
      PagedState(await _fetch(const PageQuery()));

  Future<PagedList<AuditLog>> _fetch(PageQuery query) async =>
      (await ref.read(auditLogRepositoryProvider).list(
                query: query,
                entityName: entityName.isEmpty ? null : entityName,
              ))
          .getOrThrow();

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;
    state = AsyncData(current.loadingMore());
    state = AsyncData(await nextPage(current, _fetch));
  }
}

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  final _filter = TextEditingController();
  String _entity = '';

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  String _actionLabel(AppLocalizations l10n, String action) =>
      switch (action) {
        'Added' => l10n.auditAdded,
        'Modified' => l10n.auditModified,
        'Deleted' => l10n.auditDeleted,
        _ => action,
      };

  void _showDetail(AuditLog log) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              '${log.entityName} #${log.entityId ?? '-'}  '
              '${_actionLabel(l10n, log.action)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (log.createdAt != null)
              Text(formatJalali(log.createdAt!, withTime: true)),
            const SizedBox(height: AppSpacing.lg),
            if (log.before != null) ...[
              Text(l10n.auditBefore),
              SelectableText(log.before!, textDirection: TextDirection.ltr),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (log.after != null) ...[
              Text(l10n.auditAfter),
              SelectableText(log.after!, textDirection: TextDirection.ltr),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = auditLogListProvider(_entity);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.auditTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppTextField(
              label: l10n.auditEntityFilter,
              controller: _filter,
              ltr: true,
              textInputAction: TextInputAction.search,
              onFieldSubmitted: (v) => setState(() => _entity = v.trim()),
            ),
          ),
          Expanded(
            child: PagedAsyncList<AuditLog>(
              value: ref.watch(provider),
              emptyMessage: l10n.auditEmpty,
              onLoadMore: ref.read(provider.notifier).loadMore,
              onRefresh: () => ref.refresh(provider.future),
              itemBuilder: (context, log) => Card(
                child: ListTile(
                  title: Text('${log.entityName} #${log.entityId ?? '-'}'),
                  subtitle: Text(
                    [
                      _actionLabel(l10n, log.action),
                      if (log.createdAt != null)
                        formatJalali(log.createdAt!, withTime: true),
                    ].join(' - '),
                  ),
                  onTap: () => _showDetail(log),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
