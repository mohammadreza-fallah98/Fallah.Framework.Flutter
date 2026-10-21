import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:{{project_name.snakeCase()}}/core/auth/can.dart';
import 'package:{{project_name.snakeCase()}}/core/l10n/l10n_extension.dart';
import 'package:{{project_name.snakeCase()}}/core/widgets/async_body.dart';
import 'package:{{project_name.snakeCase()}}/features/base_routes.dart';
import 'package:{{project_name.snakeCase()}}/features/users/presentation/providers/user_providers.dart';

class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(userListProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.usersTitle)),
      floatingActionButton: ref.can('user:create')
          ? FloatingActionButton(
              tooltip: l10n.add,
              onPressed: () => context.push(BaseRoutes.userNew),
              child: const Icon(Icons.add),
            )
          : null,
      body: PagedAsyncList(
        value: ref.watch(userListProvider),
        emptyMessage: l10n.usersEmpty,
        onLoadMore: notifier.loadMore,
        onRefresh: () => ref.refresh(userListProvider.future),
        itemBuilder: (context, user) => Card(
          child: ListTile(
            title: Text(user.fullName.isEmpty ? user.username : user.fullName),
            subtitle: Text(user.mobile ?? user.username),
            trailing: user.isActive
                ? null
                : Tooltip(
                    message: l10n.userInactive,
                    child: const Icon(Icons.block, size: 20),
                  ),
            onTap: () => context.push(BaseRoutes.user(user.id)),
          ),
        ),
      ),
    );
  }
}
