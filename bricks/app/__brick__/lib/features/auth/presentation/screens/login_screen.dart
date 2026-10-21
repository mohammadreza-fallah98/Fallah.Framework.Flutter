import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_network/fallah_network.dart';
import 'package:fallah_ui/fallah_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:{{project_name.snakeCase()}}/core/auth/auth_providers.dart';
import 'package:{{project_name.snakeCase()}}/core/error/failure_message.dart';
import 'package:{{project_name.snakeCase()}}/core/l10n/l10n_extension.dart';

enum _LoginMode { password, otp }

/// Sign in with username + password or with a one-time code sent by SMS.
/// Remove the mode you do not need. On success the session changes and the
/// router moves to the home page by itself.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _mobile = TextEditingController();
  final _code = TextEditingController();

  _LoginMode _mode = _LoginMode.password;
  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _mobile.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);

    final api = ref.read(authApiProvider);
    final mobile = Validators.normalizeDigits(_mobile.text.trim());
    Result<AuthTokens>? tokens;
    Failure? failure;

    if (_mode == _LoginMode.password) {
      tokens = await api.login(
        username: _username.text.trim(),
        password: _password.text,
      );
    } else if (!_codeSent) {
      failure = (await api.requestOtp(mobile)).failureOrNull;
    } else {
      tokens = await api.verifyOtp(
        mobile: mobile,
        code: Validators.normalizeDigits(_code.text.trim()),
      );
    }

    failure ??= tokens?.failureOrNull;
    final granted = tokens?.valueOrNull;
    if (granted != null) {
      // The router redirects to home when the session becomes authenticated.
      await ref.read(sessionManagerProvider).signIn(granted);
    }
    if (!mounted) return;

    setState(() {
      _busy = false;
      if (failure == null && tokens == null) _codeSent = true;
    });
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failureMessage(context.l10n, failure))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String? required(String? v) =>
        Validators.isNotBlank(v) ? null : l10n.requiredField;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.loginTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              shrinkWrap: true,
              children: [
                SegmentedButton<_LoginMode>(
                  segments: [
                    ButtonSegment(
                      value: _LoginMode.password,
                      label: Text(l10n.loginTabPassword),
                    ),
                    ButtonSegment(
                      value: _LoginMode.otp,
                      label: Text(l10n.loginTabOtp),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: _busy
                      ? null
                      : (s) => setState(() {
                            _mode = s.first;
                            _codeSent = false;
                          }),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_mode == _LoginMode.password) ...[
                  AppTextField(
                    label: l10n.loginUsername,
                    controller: _username,
                    enabled: !_busy,
                    ltr: true,
                    textInputAction: TextInputAction.next,
                    validator: required,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: l10n.loginPassword,
                    controller: _password,
                    enabled: !_busy,
                    obscureText: true,
                    ltr: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: required,
                  ),
                ] else ...[
                  AppTextField(
                    label: l10n.loginMobile,
                    controller: _mobile,
                    enabled: !_busy && !_codeSent,
                    ltr: true,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (v) => Validators.isMobile(v ?? '')
                        ? null
                        : l10n.invalidMobile,
                  ),
                  if (_codeSent) ...[
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: l10n.loginCode,
                      controller: _code,
                      enabled: !_busy,
                      ltr: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: required,
                    ),
                  ],
                ],
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: _mode == _LoginMode.otp && !_codeSent
                      ? l10n.loginSendCode
                      : l10n.loginSubmit,
                  isLoading: _busy,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
