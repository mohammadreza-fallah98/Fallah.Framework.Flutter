import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_ui/fallah_ui.dart';
import 'package:flutter/material.dart';

import 'package:{{project_name.snakeCase()}}/core/error/failure_message.dart';
import 'package:{{project_name.snakeCase()}}/core/l10n/l10n_extension.dart';

/// One text field of [showFieldsDialog].
class DialogField {
  const DialogField(
    this.label, {
    this.initial = '',
    this.required = true,
    this.ltr = false,
    this.obscure = false,
  });

  final String label;
  final String initial;
  final bool required;
  final bool ltr;
  final bool obscure;
}

/// Shows a small form; returns the entered values (same order as [fields])
/// or null when cancelled.
Future<List<String>?> showFieldsDialog(
  BuildContext context, {
  required String title,
  required List<DialogField> fields,
}) =>
    showDialog<List<String>>(
      context: context,
      builder: (_) => _FieldsDialog(title: title, fields: fields),
    );

class _FieldsDialog extends StatefulWidget {
  const _FieldsDialog({required this.title, required this.fields});

  final String title;
  final List<DialogField> fields;

  @override
  State<_FieldsDialog> createState() => _FieldsDialogState();
}

class _FieldsDialogState extends State<_FieldsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controllers = [
    for (final f in widget.fields) TextEditingController(text: f.initial),
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.fields.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: widget.fields[i].label,
                controller: _controllers[i],
                ltr: widget.fields[i].ltr,
                obscureText: widget.fields[i].obscure,
                validator: widget.fields[i].required
                    ? (v) => Validators.isNotBlank(v) ? null : l10n.requiredField
                    : null,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop([
              for (final c in _controllers) c.text.trim(),
            ]);
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// Asks "delete this record?"; true when confirmed.
Future<bool> confirmDelete(BuildContext context) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.deleteConfirmTitle),
      content: Text(l10n.deleteConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Snackbar with the user-facing text of [failure].
void showFailure(BuildContext context, Failure failure) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(failureMessage(context.l10n, failure))),
  );
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
