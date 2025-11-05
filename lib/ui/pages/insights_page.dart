import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.l10n.translate('insightsEmpty'),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
