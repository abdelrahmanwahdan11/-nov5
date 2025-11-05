import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/utils/app_scope.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  double get _strength {
    final password = _passwordController.text;
    double score = 0;
    if (password.length >= 6) score += 0.3;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 0.2;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 0.2;
    if (RegExp(r'[!@#%^&*()]').hasMatch(password)) score += 0.3;
    return score.clamp(0, 1).toDouble();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final scope = AppScope.of(context);
    scope.profileController.name.value = _nameController.text.trim();
    scope.profileController.phone.value = _phoneController.text.trim();
    scope.sessionController.signIn(name: scope.profileController.name.value);
    AppRouter.navigator(context)
        .pushNamedAndRemoveUntil(AppRouter.home, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('authSignUp'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.translate('authName')),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return l10n.translate('authRequiredField');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: l10n.translate('authPhone')),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) {
                      return l10n.translate('authRequiredField');
                    }
                    if (phone.length < 7) {
                      return l10n.translate('authInvalidPhone');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _passwordController,
                  builder: (context, value, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: l10n.translate('authPassword'),
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          obscureText: _obscurePassword,
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
                        _StrengthMeter(strength: _strength, theme: theme, l10n: l10n),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('authConfirmPassword'),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  obscureText: _obscureConfirm,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return l10n.translate('authPasswordMismatch');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: Text(l10n.translate('authSignUp')),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed(AppRouter.login),
                  child: Text(l10n.translate('authHaveAccount')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({
    required this.strength,
    required this.theme,
    required this.l10n,
  });

  final double strength;
  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    if (strength < 0.4) {
      color = Colors.red;
      label = l10n.translate('authPasswordWeak');
    } else if (strength < 0.7) {
      color = Colors.orange;
      label = l10n.translate('authPasswordMedium');
    } else {
      color = Colors.green;
      label = l10n.translate('authPasswordStrong');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: strength,
          minHeight: 6,
          backgroundColor: theme.colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
      ],
    );
  }
}
