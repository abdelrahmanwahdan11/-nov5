import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../controllers/tools_controller.dart';
import '../../core/localization/app_localizations.dart';

class CalculatorsPage extends StatefulWidget {
  const CalculatorsPage({
    super.key,
    required this.toolsController,
  });

  final ToolsController toolsController;

  @override
  State<CalculatorsPage> createState() => _CalculatorsPageState();
}

class _CalculatorsPageState extends State<CalculatorsPage> {
  late final TextEditingController _feeAmountController;
  late final TextEditingController _feeRateController;
  late final TextEditingController _interestPrincipalController;
  late final TextEditingController _interestRateController;
  late final TextEditingController _interestPeriodsController;

  @override
  void initState() {
    super.initState();
    _feeAmountController = TextEditingController(
      text: widget.toolsController.feeAmountNotifier.value.toStringAsFixed(0),
    );
    _feeRateController = TextEditingController(
      text: widget.toolsController.feeRateNotifier.value.toStringAsFixed(1),
    );
    _interestPrincipalController = TextEditingController(
      text:
          widget.toolsController.interestPrincipalNotifier.value.toStringAsFixed(0),
    );
    _interestRateController = TextEditingController(
      text: widget.toolsController.interestRateNotifier.value.toStringAsFixed(2),
    );
    _interestPeriodsController = TextEditingController(
      text: widget.toolsController.interestPeriodsNotifier.value.toString(),
    );
  }

  @override
  void dispose() {
    _feeAmountController.dispose();
    _feeRateController.dispose();
    _interestPrincipalController.dispose();
    _interestRateController.dispose();
    _interestPeriodsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('calculatorsTitle')),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          _CalculatorCard(
            title: t.translate('calculatorFeeTitle'),
            subtitle: t.translate('calculatorFeeSubtitle'),
            child: Column(
              children: [
                TextField(
                  controller: _feeAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: t.translate('calculatorAmount'),
                  ),
                  onChanged: (value) {
                    final parsed = double.tryParse(value);
                    if (parsed != null) {
                      widget.toolsController.updateFeeAmount(parsed);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _feeRateController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: t.translate('calculatorRate'),
                  ),
                  onChanged: (value) {
                    final parsed = double.tryParse(value);
                    if (parsed != null) {
                      widget.toolsController.updateFeeRate(parsed);
                    }
                  },
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<double>(
                  valueListenable: widget.toolsController.feeResultNotifier,
                  builder: (context, result, _) {
                    return Text(
                      t.translate('calculatorFeeResult',
                          params: {'value': result.toStringAsFixed(2)}),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _CalculatorCard(
            title: t.translate('calculatorInterestTitle'),
            subtitle: t.translate('calculatorInterestSubtitle'),
            child: Column(
              children: [
                TextField(
                  controller: _interestPrincipalController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: t.translate('calculatorPrincipal'),
                  ),
                  onChanged: (value) {
                    final parsed = double.tryParse(value);
                    if (parsed != null) {
                      widget.toolsController.updateInterestPrincipal(parsed);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _interestRateController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: t.translate('calculatorRate'),
                  ),
                  onChanged: (value) {
                    final parsed = double.tryParse(value);
                    if (parsed != null) {
                      widget.toolsController.updateInterestRate(parsed);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _interestPeriodsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: t.translate('calculatorPeriods'),
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null) {
                      widget.toolsController.updateInterestPeriods(parsed);
                    }
                  },
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<double>(
                  valueListenable: widget.toolsController.interestResultNotifier,
                  builder: (context, result, _) {
                    return Text(
                      t.translate('calculatorInterestResult',
                          params: {'value': result.toStringAsFixed(2)}),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalculatorCard extends StatelessWidget {
  const _CalculatorCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    ).animate().fadeIn(duration: 240.ms).slideY(begin: 0.1, end: 0);
  }
}
