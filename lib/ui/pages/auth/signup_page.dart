import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../controllers/session_controller.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/routing/app_router.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({
    super.key,
    required this.sessionController,
  });

  final SessionController sessionController;

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  final ValueNotifier<bool> _obscure = ValueNotifier<bool>(true);
  final ValueNotifier<double> _strength = ValueNotifier<double>(0);
  bool _isLoading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _obscure.dispose();
    _strength.dispose();
    super.dispose();
  }

  void _updateStrength(String value) {
    double score = 0;
    if (value.length >= 6) score += 0.3;
    if (RegExp(r'[A-Z]').hasMatch(value)) score += 0.3;
    if (RegExp(r'[0-9]').hasMatch(value)) score += 0.2;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) score += 0.2;
    _strength.value = score.clamp(0, 1);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await widget.sessionController.signIn();
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).translate('accountCreated'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.translate('createAccount'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.translate('signupHeadline'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(duration: 360.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: t.translate('fullName')),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return t.translate('required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: t.translate('email')),
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
                      onChanged: _updateStrength,
                      decoration: InputDecoration(
                        labelText: t.translate('password'),
                        suffixIcon: IconButton(
                          onPressed: () => _obscure.value = !obscure,
                          icon: Icon(
                            obscure
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
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
                const SizedBox(height: 12),
                ValueListenableBuilder<double>(
                  valueListenable: _strength,
                  builder: (context, strength, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: strength,
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                        minHeight: 8,
                      ),
                    ).animate().fadeIn(duration: 280.ms);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPassword,
                  obscureText: true,
                  decoration:
                      InputDecoration(labelText: t.translate('confirmPassword')),
                  validator: (value) {
                    if (value != _password.text) {
                      return t.translate('passwordMismatch');
                    }
                    return null;
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
                        : Text(t.translate('createAccount')),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(t.translate('haveAccountPrompt')),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pushReplacementNamed(AppRouter.login);
                      },
                      child: Text(t.translate('login')),
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
