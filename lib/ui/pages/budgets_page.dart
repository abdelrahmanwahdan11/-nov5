import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/utils/app_scope.dart';
import '../../data/models/budget.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.translate('budgetsTitle'),
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Expanded(
                child: ValueListenableBuilder<List<BudgetModel>>(
                  valueListenable: scope.budgetsController.budgets,
                  builder: (context, budgets, _) {
                    if (budgets.isEmpty) {
                      return Center(child: Text(l10n.translate('budgetsEmpty')));
                    }
                    return ListView.separated(
                      itemCount: budgets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final budget = budgets[index];
                        final progress = (budget.spent / budget.limit).clamp(0, 1).toDouble();
                        return Card(
                          child: ListTile(
                            title: Text(budget.label),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                LinearProgressIndicator(value: progress),
                                const SizedBox(height: 8),
                                Text('${budget.spent.toStringAsFixed(0)} / ${budget.limit.toStringAsFixed(0)}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => scope.budgetsController.delete(budget.id),
                            ),
                            onTap: () => _showBudgetDialog(context, budget: budget),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBudgetDialog(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.translate('budgetsCreate')),
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, {BudgetModel? budget}) {
    final scope = AppScope.of(context);
    final l10n = context.l10n;
    final nameController = TextEditingController(text: budget?.label ?? '');
    final limitController = TextEditingController(text: budget?.limit.toStringAsFixed(0) ?? '');
    final spentController = TextEditingController(text: budget?.spent.toStringAsFixed(0) ?? '');
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(budget == null
              ? l10n.translate('budgetsCreate')
              : l10n.translate('walletSave')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.translate('walletLabel')),
              ),
              TextField(
                controller: limitController,
                decoration: const InputDecoration(labelText: 'Limit'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: spentController,
                decoration: const InputDecoration(labelText: 'Spent'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.translate('walletCancel')),
            ),
            ElevatedButton(
              onPressed: () {
                final id = budget?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
                final model = BudgetModel(
                  id: id,
                  label: nameController.text.isEmpty
                      ? l10n.translate('walletLabel')
                      : nameController.text,
                  limit: double.tryParse(limitController.text) ?? 0,
                  spent: double.tryParse(spentController.text) ?? 0,
                );
                scope.budgetsController.upsert(model);
                Navigator.of(context).pop();
              },
              child: Text(l10n.translate('walletSave')),
            ),
          ],
        );
      },
    );
  }
}
