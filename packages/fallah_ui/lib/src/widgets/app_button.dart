import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Filled button with a built-in loading state. While [isLoading] it is
/// disabled, which also prevents double submits.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(child: Text(label)),
            ],
          );

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: child,
    );
  }
}
