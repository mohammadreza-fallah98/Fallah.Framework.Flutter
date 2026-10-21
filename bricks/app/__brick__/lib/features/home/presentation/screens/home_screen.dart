import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:{{project_name.snakeCase()}}/core/auth/auth_providers.dart';
import 'package:{{project_name.snakeCase()}}/core/auth/can.dart';
import 'package:{{project_name.snakeCase()}}/core/l10n/l10n_extension.dart';

/// One tile of the home menu; shown when the user holds [permission]
/// (always when null).
class _HomeEntry {
  const _HomeEntry(this.icon, this.label, this.path, {this.permission});

  final IconData icon;
  final String label;
  final String path;
  final String? permission;
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Revokes the refresh token on the server (best effort), then signs out
  /// locally even when the server call fails.
  Future<void> _logout(WidgetRef ref) async {
    final tokens = await ref.read(tokenStoreProvider).read();
    if (tokens != null) {
      await ref.read(authApiProvider).logout(tokens.refreshToken);
    }
    await ref.read(sessionManagerProvider).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final entries = <_HomeEntry>[
      // fallah:home-entries
    ].where((e) => e.permission == null || ref.can(e.permission!)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            tooltip: l10n.logout,
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(ref),
          ),
        ],
      ),
      body: entries.isEmpty
          ? Center(child: Text(l10n.homeTitle))
          : ListView(
              children: [
                for (final e in entries)
                  ListTile(
                    leading: Icon(e.icon),
                    title: Text(e.label),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(e.path),
                  ),
              ],
            ),
    );
  }
}
