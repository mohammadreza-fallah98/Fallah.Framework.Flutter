import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_ui/fallah_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:{{package.snakeCase()}}/core/error/failure_message.dart';
import 'package:{{package.snakeCase()}}/core/l10n/l10n_extension.dart';

import '../../domain/entities/{{name.snakeCase()}}.dart';
import '../providers/{{name.snakeCase()}}_providers.dart';

/// Create (`initial == null`) or edit form.
class {{name.pascalCase()}}Form extends ConsumerStatefulWidget {
  const {{name.pascalCase()}}Form({super.key, this.initial});

  final {{name.pascalCase()}}? initial;

  @override
  ConsumerState<{{name.pascalCase()}}Form> createState() => _{{name.pascalCase()}}FormState();
}

class _{{name.pascalCase()}}FormState extends ConsumerState<{{name.pascalCase()}}Form> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title);
  String? _serverTitleError;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _serverTitleError = null);
    if (!_formKey.currentState!.validate()) return;

    final initial = widget.initial;
    final entity = initial == null
        ? {{name.pascalCase()}}(id: 0, title: _title.text.trim())
        : initial.copyWith(title: _title.text.trim());

    final failure = await ref
        .read({{name.camelCase()}}MutationProvider.notifier)
        .save(entity, isNew: initial == null);
    if (!mounted) return;

    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (failure == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.saved)));
      context.pop();
      return;
    }
    if (failure is ValidationFailure) {
      setState(() => _serverTitleError = failure.errorsFor('title').firstOrNull);
    }
    messenger.showSnackBar(SnackBar(content: Text(failureMessage(l10n, failure))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isSaving = ref.watch({{name.camelCase()}}MutationProvider).isLoading;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppTextField(
            label: l10n.{{name.camelCase()}}FieldTitle,
            controller: _title,
            enabled: !isSaving,
            serverError: _serverTitleError,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            validator: (value) =>
                Validators.isNotBlank(value) ? null : l10n.requiredField,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: l10n.save, isLoading: isSaving, onPressed: _submit),
        ],
      ),
    );
  }
}
