import 'package:fallah_api/fallah_api.dart';
import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_ui/fallah_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:{{project_name.snakeCase()}}/core/api/api_providers.dart';
import 'package:{{project_name.snakeCase()}}/core/l10n/l10n_extension.dart';
import 'package:{{project_name.snakeCase()}}/core/widgets/async_body.dart';
import 'package:{{project_name.snakeCase()}}/core/widgets/dialogs.dart';
import 'package:{{project_name.snakeCase()}}/features/users/presentation/providers/user_providers.dart';

/// Create (`id == null`) or edit a user.
class UserFormScreen extends ConsumerWidget {
  const UserFormScreen({this.id, super.key});

  final int? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final id = this.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(id == null ? l10n.userNew : l10n.userEditTitle),
      ),
      body: id == null
          ? const _UserForm()
          : AsyncBody<User>(
              value: ref.watch(userDetailProvider(id)),
              onRetry: () => ref.invalidate(userDetailProvider(id)),
              data: (user) => _UserForm(initial: user),
            ),
    );
  }
}

class _UserForm extends ConsumerStatefulWidget {
  const _UserForm({this.initial});

  final User? initial;

  @override
  ConsumerState<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends ConsumerState<_UserForm> {
  final _formKey = GlobalKey<FormState>();
  late final _username = TextEditingController(text: widget.initial?.username);
  final _password = TextEditingController();
  late final _firstName =
      TextEditingController(text: widget.initial?.firstName);
  late final _lastName = TextEditingController(text: widget.initial?.lastName);
  late final _mobile = TextEditingController(text: widget.initial?.mobile);
  late final _nationalCode =
      TextEditingController(text: widget.initial?.nationalCode);
  late final _email = TextEditingController(text: widget.initial?.email);

  late int? _roleId = widget.initial?.roleId;
  late int? _provinceId = widget.initial?.provinceId;
  late int? _cityId = widget.initial?.cityId;
  late bool _isActive = widget.initial?.isActive ?? true;

  bool get _isNew => widget.initial == null;

  @override
  void dispose() {
    for (final c in [
      _username,
      _password,
      _firstName,
      _lastName,
      _mobile,
      _nationalCode,
      _email,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _text(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final initial = widget.initial;

    final user = User(
      id: initial?.id ?? 0,
      roleId: _roleId!,
      username: _username.text.trim(),
      provinceId: _provinceId,
      cityId: _cityId,
      firstName: _text(_firstName),
      lastName: _text(_lastName),
      mobile: _text(_mobile) == null
          ? null
          : Validators.normalizeDigits(_mobile.text.trim()),
      nationalCode: _text(_nationalCode) == null
          ? null
          : Validators.normalizeDigits(_nationalCode.text.trim()),
      email: _text(_email),
      gender: initial?.gender,
      phone: initial?.phone,
      address: initial?.address,
      postalCode: initial?.postalCode,
      isActive: _isActive,
      audit: initial?.audit ?? AuditInfo.none,
    );

    final failure = await ref
        .read(userMutationProvider.notifier)
        .save(user, password: _isNew ? _password.text : null);
    if (!mounted) return;
    if (failure != null) return showFailure(context, failure);
    showMessage(context, context.l10n.saved);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final saving = ref.watch(userMutationProvider).isLoading;
    final roles = ref.watch(rolesLookupProvider).value ?? const <Role>[];
    final provinces =
        ref.watch(provincesLookupProvider).value ?? const <Province>[];
    final cities = _provinceId == null
        ? const <City>[]
        : ref.watch(citiesLookupProvider(_provinceId!)).value ?? const <City>[];

    String? required(String? v) =>
        Validators.isNotBlank(v) ? null : l10n.requiredField;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppTextField(
            label: l10n.userUsername,
            controller: _username,
            enabled: !saving,
            ltr: true,
            validator: required,
          ),
          if (_isNew) ...[
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: l10n.userPassword,
              controller: _password,
              enabled: !saving,
              obscureText: true,
              ltr: true,
              validator: required,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<int>(
            initialValue: roles.any((r) => r.id == _roleId) ? _roleId : null,
            decoration: InputDecoration(labelText: l10n.userRole),
            items: [
              for (final r in roles)
                DropdownMenuItem(value: r.id, child: Text(r.name)),
            ],
            onChanged: saving ? null : (v) => setState(() => _roleId = v),
            validator: (v) => v == null ? l10n.requiredField : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: l10n.userFirstName,
            controller: _firstName,
            enabled: !saving,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: l10n.userLastName,
            controller: _lastName,
            enabled: !saving,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: l10n.userMobile,
            controller: _mobile,
            enabled: !saving,
            ltr: true,
            keyboardType: TextInputType.phone,
            validator: (v) => !Validators.isNotBlank(v) || Validators.isMobile(v!)
                ? null
                : l10n.invalidMobile,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: l10n.userNationalCode,
            controller: _nationalCode,
            enabled: !saving,
            ltr: true,
            keyboardType: TextInputType.number,
            validator: (v) =>
                !Validators.isNotBlank(v) || Validators.isNationalCode(v!)
                    ? null
                    : l10n.invalidNationalCode,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: l10n.userEmail,
            controller: _email,
            enabled: !saving,
            ltr: true,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<int>(
            initialValue:
                provinces.any((p) => p.id == _provinceId) ? _provinceId : null,
            decoration: InputDecoration(labelText: l10n.userProvince),
            items: [
              for (final p in provinces)
                DropdownMenuItem(value: p.id, child: Text(p.name)),
            ],
            onChanged: saving
                ? null
                : (v) => setState(() {
                      _provinceId = v;
                      _cityId = null;
                    }),
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<int>(
            // Rebuild when the province changes so the old city is dropped.
            key: ValueKey(_provinceId),
            initialValue: cities.any((c) => c.id == _cityId) ? _cityId : null,
            decoration: InputDecoration(labelText: l10n.userCity),
            items: [
              for (final c in cities)
                DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: saving ? null : (v) => setState(() => _cityId = v),
          ),
          SwitchListTile(
            title: Text(l10n.userActive),
            value: _isActive,
            onChanged: saving ? null : (v) => setState(() => _isActive = v),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: l10n.save, isLoading: saving, onPressed: _submit),
        ],
      ),
    );
  }
}
