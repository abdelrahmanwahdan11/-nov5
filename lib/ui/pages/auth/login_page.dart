import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../controllers/session_controller.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/routing/app_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.sessionController,
  });

  final SessionController sessionController;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final ValueNotifier<bool> _obscure = ValueNotifier<bool>(true);
  bool _isLoading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _obscure.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await widget.sessionController.signIn();
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).translate('welcomeBack'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('login')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.translate('loginHeadline'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(duration: 360.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: t.translate('email'),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return t.translate('required');
                    }
                    if (!value.contains('@')) {
                      return t.translate('invalidEmail');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<bool>(
                  valueListenable: _obscure,
                  builder: (context, obscure, _) {
                    return TextFormField(
                      controller: _password,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: t.translate('password'),
                        suffixIcon: IconButton(
                          onPressed: () => _obscure.value = !obscure,
                          icon: Icon(obscure
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return t.translate('weakPassword');
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(t.translate('login')),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(t.translate('noAccountPrompt')),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed(AppRouter.signup);
                      },
                      child: Text(t.translate('createAccount')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
