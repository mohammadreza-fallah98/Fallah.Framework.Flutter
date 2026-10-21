import 'package:fallah_core/fallah_core.dart';
import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Full-area error state for a [Failure]. Texts come from the caller so this
/// package stays independent of the app's l10n.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.failure,
    this.message,
    this.onRetry,
    this.retryLabel = 'Retry',
  });

  final Failure failure;

  /// Localized text to show. When null, `failure.message` is used (server
  /// messages are already localized; local ones are English fallbacks, so
  /// apps should map `failure.code` to their ARB strings and pass it here).
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;

  IconData get _icon => switch (failure) {
        NetworkFailure() => Icons.wifi_off_rounded,
        ForbiddenFailure() ||
        UnauthorizedFailure() =>
          Icons.lock_outline_rounded,
        NotFoundFailure() => Icons.search_off_rounded,
        _ => Icons.error_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 48, color: scheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              message ?? failure.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
            ],
          ],
        ),
      ),
    );
  }
}
