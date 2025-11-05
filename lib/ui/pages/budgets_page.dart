import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../controllers/budgets_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/models/budget.dart';
import '../widgets/budget_card.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key, required this.budgetsController});

  final BudgetsController budgetsController;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('budgetsTitle')),
        actions: [
          IconButton(
            tooltip: t.translate('addBudget'),
            onPressed: () => _showBudgetSheet(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBudgetSheet(context),
        icon: const Icon(Icons.add_chart_rounded),
        label: Text(t.translate('addBudget')),
      ),
      body: ValueListenableBuilder<List<BudgetModel>>(
        valueListenable: budgetsController.budgetsNotifier,
        builder: (context, budgets, _) {
          if (budgets.isEmpty) {
            return _BudgetEmptyState(onCreate: () => _showBudgetSheet(context));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              final budget = budgets[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () => _showBudgetSheet(context, budget: budget),
                  onLongPress: () => _showBudgetActions(context, budget),
                  child: BudgetCard(budget: budget)
                      .animate()
                      .fadeIn(duration: 320.ms)
                      .slideY(begin: 0.15, end: 0),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showBudgetActions(BuildContext context, BudgetModel budget) async {
    final t = AppLocalizations.of(context);
    final controller = ScaffoldMessenger.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: Text(t.translate('edit')),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded),
              title: Text(t.translate('delete')),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );

    switch (action) {
      case 'edit':
        await _showBudgetSheet(context, budget: budget);
        break;
      case 'delete':
        await budgetsController.deleteBudget(budget.id);
        controller.showSnackBar(
          SnackBar(
            content: Text(t.translate('budgetDeleted')),
            action: SnackBarAction(
              label: t.translate('undo'),
              onPressed: () => budgetsController.addBudget(budget),
            ),
          ),
        );
        break;
      default:
        break;
    }
  }

  Future<void> _showBudgetSheet(BuildContext context, {BudgetModel? budget}) async {
    final t = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    final categoryController = TextEditingController(text: budget?.category ?? '');
    final limitController = TextEditingController(
      text: budget != null ? budget.limit.toStringAsFixed(0) : '',
    );
    final spentController = TextEditingController(
      text: budget != null ? budget.spent.toStringAsFixed(0) : '',
    );
    int color = budget?.color ?? 0xFF2BAA7D;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget == null
                              ? t.translate('createBudget')
                              : t.translate('editBudget'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: categoryController,
                          decoration: InputDecoration(
                            labelText: t.translate('category'),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? t.translate('required')
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: limitController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            labelText: t.translate('limit'),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return t.translate('required');
                            }
                            if (double.tryParse(value) == null) {
                              return t.translate('invalidNumber');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: spentController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            labelText: t.translate('spent'),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return t.translate('required');
                            }
                            if (double.tryParse(value) == null) {
                              return t.translate('invalidNumber');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          t.translate('selectColor'),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final option in [
                              0xFF2BAA7D,
                              0xFF4C7AF0,
                              0xFFFA7A55,
                              0xFFFFC857,
                              0xFF9B5DE5,
                              0xFF2C3333,
                            ])
                              GestureDetector(
                                onTap: () => setState(() => color = option),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 240),
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Color(option),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: color == option
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              final model = BudgetModel(
                                id: budget?.id ??
                                    DateTime.now().millisecondsSinceEpoch.toString(),
                                category: categoryController.text.trim(),
                                limit: double.parse(limitController.text),
                                spent: double.parse(spentController.text),
                                color: color,
                              );
                              if (budget == null) {
                                await budgetsController.addBudget(model);
                              } else {
                                await budgetsController.updateBudget(model);
                              }
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: Text(budget == null
                                ? t.translate('create')
                                : t.translate('save')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    categoryController.dispose();
    limitController.dispose();
    spentController.dispose();
  }
}

class _BudgetEmptyState extends StatelessWidget {
  const _BudgetEmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_chart_rounded, size: 96),
          const SizedBox(height: 12),
          Text(
            t.translate('noBudgets'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onCreate,
            child: Text(t.translate('createBudget')),
          ),
        ],
      ),
    );
  }
}
