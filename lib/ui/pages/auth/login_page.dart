import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/utils/app_scope.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final scope = AppScope.of(context);
    final email = _emailController.text.trim();
    final name = email.split('@').first;
    scope.profileController.name.value = name.isEmpty ? 'User' : name;
    scope.sessionController.signIn(name: scope.profileController.name.value);
    AppRouter.navigator(context)
        .pushNamedAndRemoveUntil(AppRouter.home, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('authSignIn'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: l10n.translate('authEmail')),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) {
                      return l10n.translate('authRequiredField');
                    }
                    if (!email.contains('@') || !email.contains('.')) {
                      return l10n.translate('authInvalidEmail');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('authPassword'),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                      tooltip: _obscure
                          ? l10n.translate('passwordShow')
                          : l10n.translate('passwordHide'),
                    ),
                  ),
                  obscureText: _obscure,
                  validator: (value) {
                    final password = value ?? '';
                    if (password.isEmpty) {
                      return l10n.translate('authRequiredField');
                    }
                    if (password.length < 6) {
                      return l10n.translate('authPasswordWeak');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(AppRouter.forgotPassword),
                    child: Text(l10n.translate('authForgotPassword')),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: Text(l10n.translate('authSignIn')),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed(AppRouter.signup),
                  child: Text(l10n.translate('authNeedAccount')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
