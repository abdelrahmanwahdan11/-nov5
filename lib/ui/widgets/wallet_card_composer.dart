import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';

class WalletCardComposer extends StatefulWidget {
  const WalletCardComposer({
    super.key,
    required this.localization,
    required this.currencyOptions,
    required this.networkOptions,
    required this.onSubmit,
  });

  final AppLocalizations localization;
  final List<String> currencyOptions;
  final List<String> networkOptions;
  final bool Function(String title, double amount, String currency, String network)
      onSubmit;

  @override
  State<WalletCardComposer> createState() => _WalletCardComposerState();
}

class _WalletCardComposerState extends State<WalletCardComposer> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late String _currency;
  late String _network;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _currency = widget.currencyOptions.first;
    _network = widget.networkOptions.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final parsed = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.localization.translate('invalidAmount'))),
      );
      return;
    }

    final didAccept = widget.onSubmit(
      _titleController.text.trim(),
      parsed,
      _currency,
      _network,
    );

    if (didAccept && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = widget.localization;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.translate('walletAddTitle'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: t.translate('walletNameLabel'),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return t.translate('required');
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: t.translate('walletAmountLabel'),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return t.translate('required');
              }
              return double.tryParse(value.replaceAll(',', '.')) == null
                  ? t.translate('invalidAmount')
                  : null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _currency,
            decoration: InputDecoration(
              labelText: t.translate('walletCurrencyLabel'),
            ),
            items: widget.currencyOptions
                .map((code) => DropdownMenuItem(value: code, child: Text(code)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _currency = value);
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _network,
            decoration: InputDecoration(
              labelText: t.translate('walletNetworkLabel'),
            ),
            items: widget.networkOptions
                .map((network) => DropdownMenuItem(value: network, child: Text(network)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _network = value);
              }
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleSubmit,
              child: Text(t.translate('walletSaveCard')),
            ),
          ),
        ],
      ),
    );
  }
}
