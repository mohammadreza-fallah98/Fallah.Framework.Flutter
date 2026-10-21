import 'package:fallah_api/fallah_api.dart';
import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_ui/fallah_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:{{project_name.snakeCase()}}/core/api/api_providers.dart';
import 'package:{{project_name.snakeCase()}}/core/auth/can.dart';
import 'package:{{project_name.snakeCase()}}/core/l10n/l10n_extension.dart';
import 'package:{{project_name.snakeCase()}}/core/widgets/async_body.dart';
import 'package:{{project_name.snakeCase()}}/core/widgets/dialogs.dart';

/// Provinces and cities (two tabs). Editing needs `province:*` / `city:*`.
class RegionsScreen extends ConsumerWidget {
  const RegionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.regionsTitle),
          bottom: TabBar(
            tabs: [Tab(text: l10n.provincesTab), Tab(text: l10n.citiesTab)],
          ),
        ),
        body: const TabBarView(children: [_ProvincesTab(), _CitiesTab()]),
      ),
    );
  }
}

Future<void> _run(
  BuildContext context,
  Future<Result<Object?>> Function() action,
  VoidCallback onDone,
) async {
  final failure = (await action()).failureOrNull;
  if (!context.mounted) return;
  if (failure != null) return showFailure(context, failure);
  onDone();
}

class _ProvincesTab extends ConsumerWidget {
  const _ProvincesTab();

  Future<void> _edit(BuildContext context, WidgetRef ref, [Province? p]) async {
    final l10n = context.l10n;
    final values = await showFieldsDialog(
      context,
      title: p == null ? l10n.provinceNew : l10n.provinceEdit,
      fields: [DialogField(l10n.regionName, initial: p?.name ?? '')],
    );
    if (values == null || !context.mounted) return;
    final repo = ref.read(provinceRepositoryProvider);
    await _run(
      context,
      () => p == null
          ? repo.add(Province(id: 0, name: values[0]))
          : repo.edit(
              Province(id: p.id, name: values[0], audit: p.audit),
            ),
      () => ref.invalidate(provincesLookupProvider),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Province p) async {
    if (!await confirmDelete(context) || !context.mounted) return;
    await _run(
      context,
      () => ref.read(provinceRepositoryProvider).remove(p.id),
      () => ref.invalidate(provincesLookupProvider),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      floatingActionButton: ref.can('province:create')
          ? FloatingActionButton(
              tooltip: l10n.add,
              onPressed: () => _edit(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
      body: AsyncBody<List<Province>>(
        value: ref.watch(provincesLookupProvider),
        onRetry: () => ref.invalidate(provincesLookupProvider),
        data: (items) => items.isEmpty
            ? AppEmptyView(message: l10n.regionsEmpty)
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  for (final p in items)
                    Card(
                      child: ListTile(
                        title: Text(p.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (ref.can('province:update'))
                              IconButton(
                                tooltip: l10n.edit,
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _edit(context, ref, p),
                              ),
                            if (ref.can('province:delete'))
                              IconButton(
                                tooltip: l10n.delete,
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _delete(context, ref, p),
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

class _CitiesTab extends ConsumerStatefulWidget {
  const _CitiesTab();

  @override
  ConsumerState<_CitiesTab> createState() => _CitiesTabState();
}

class _CitiesTabState extends ConsumerState<_CitiesTab> {
  int? _provinceId;

  Future<void> _edit([City? c]) async {
    final provinceId = _provinceId;
    if (provinceId == null) return;
    final l10n = context.l10n;
    final values = await showFieldsDialog(
      context,
      title: c == null ? l10n.cityNew : l10n.cityEdit,
      fields: [DialogField(l10n.regionName, initial: c?.name ?? '')],
    );
    if (values == null || !mounted) return;
    final repo = ref.read(cityRepositoryProvider);
    await _run(
      context,
      () => c == null
          ? repo.add(City(id: 0, name: values[0], provinceId: provinceId))
          : repo.edit(
              City(
                id: c.id,
                name: values[0],
                provinceId: c.provinceId,
                audit: c.audit,
              ),
            ),
      () => ref.invalidate(citiesLookupProvider(provinceId)),
    );
  }

  Future<void> _delete(City c) async {
    if (!await confirmDelete(context) || !mounted) return;
    await _run(
      context,
      () => ref.read(cityRepositoryProvider).remove(c.id),
      () => ref.invalidate(citiesLookupProvider(c.provinceId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provinces =
        ref.watch(provincesLookupProvider).value ?? const <Province>[];
    final provinceId = _provinceId;

    return Scaffold(
      floatingActionButton: provinceId != null && ref.can('city:create')
          ? FloatingActionButton(
              tooltip: l10n.add,
              onPressed: _edit,
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: DropdownButtonFormField<int>(
              initialValue:
                  provinces.any((p) => p.id == provinceId) ? provinceId : null,
              decoration: InputDecoration(labelText: l10n.selectProvince),
              items: [
                for (final p in provinces)
                  DropdownMenuItem(value: p.id, child: Text(p.name)),
              ],
              onChanged: (v) => setState(() => _provinceId = v),
            ),
          ),
          Expanded(
            child: provinceId == null
                ? AppEmptyView(message: l10n.selectProvince)
                : AsyncBody<List<City>>(
                    value: ref.watch(citiesLookupProvider(provinceId)),
                    onRetry: () =>
                        ref.invalidate(citiesLookupProvider(provinceId)),
                    data: (items) => items.isEmpty
                        ? AppEmptyView(message: l10n.regionsEmpty)
                        : ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            children: [
                              for (final c in items)
                                Card(
                                  child: ListTile(
                                    title: Text(c.name),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (ref.can('city:update'))
                                          IconButton(
                                            tooltip: l10n.edit,
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                            ),
                                            onPressed: () => _edit(c),
                                          ),
                                        if (ref.can('city:delete'))
                                          IconButton(
                                            tooltip: l10n.delete,
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                            onPressed: () => _delete(c),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
