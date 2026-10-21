import 'package:fallah_api/fallah_api.dart';
import 'package:fallah_ui/fallah_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:{{project_name.snakeCase()}}/core/auth/auth_providers.dart';
import 'package:{{project_name.snakeCase()}}/core/l10n/l10n_extension.dart';
import 'package:{{project_name.snakeCase()}}/core/l10n/locale_provider.dart';
import 'package:{{project_name.snakeCase()}}/core/widgets/async_body.dart';
import 'package:{{project_name.snakeCase()}}/core/widgets/dialogs.dart';

part 'profile_screen.g.dart';

/// The signed-in user (`GET users/me`).
@riverpod
Future<User> profile(Ref ref) async =>
    (await ref.watch(authApiProvider).me()).getOrThrow();

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final values = await showFieldsDialog(
      context,
      title: l10n.changePassword,
      fields: [
        DialogField(l10n.currentPassword, ltr: true, obscure: true),
        DialogField(l10n.newPassword, ltr: true, obscure: true),
        DialogField(l10n.confirmPassword, ltr: true, obscure: true),
      ],
    );
    if (values == null || !context.mounted) return;
    if (values[1] != values[2]) {
      return showMessage(context, l10n.passwordMismatch);
    }

    final result = await ref.read(authApiProvider).changePassword(
          currentPassword: values[0],
          newPassword: values[1],
        );
    if (!context.mounted) return;
    final failure = result.failureOrNull;
    if (failure != null) return showFailure(context, failure);
    showMessage(context, l10n.passwordChanged);
  }

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
    final locale = ref.watch(localeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: AsyncBody<User>(
        value: ref.watch(profileProvider),
        onRetry: () => ref.invalidate(profileProvider),
        data: (user) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(user.fullName.isEmpty ? user.username : user.fullName),
              subtitle: Text(user.mobile ?? user.username),
            ),
            const Divider(),
            ListTile(
              title: Text(l10n.profileLanguage),
              trailing: SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'fa', label: Text(l10n.languageFa)),
                  ButtonSegment(value: 'en', label: Text(l10n.languageEn)),
                ],
                selected: {locale.languageCode},
                onSelectionChanged: (s) => ref
                    .read(localeControllerProvider.notifier)
                    .setLocale(Locale(s.first)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.changePassword),
              onTap: () => _changePassword(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l10n.logout),
              onTap: () => _logout(ref),
            ),
          ],
        ),
      ),
    );
  }
}
