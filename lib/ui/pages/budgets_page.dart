import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../controllers/budgets_controller.dart';
import '../../controllers/goals_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/app_constants.dart';
import '../../data/models/budget.dart';
import '../../data/models/savings_goal.dart';
import '../widgets/budget_card.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({
    super.key,
    required this.budgetsController,
    required this.privacyListenable,
    required this.goalsController,
  });

  final BudgetsController budgetsController;
  final ValueListenable<bool> privacyListenable;
  final GoalsController goalsController;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('budgetsTitle')),
        actions: [
          IconButton(
            tooltip: t.translate('addGoal'),
            onPressed: () => _showGoalSheet(context),
            icon: const Icon(Icons.savings_rounded),
          ),
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
      body: ValueListenableBuilder<List<SavingsGoalModel>>(
        valueListenable: goalsController.goalsNotifier,
        builder: (context, goals, _) {
          return ValueListenableBuilder<List<BudgetModel>>(
            valueListenable: budgetsController.budgetsNotifier,
            builder: (context, budgets, __) {
              final children = <Widget>[
                _GoalsSection(
                  goals: goals,
                  onCreate: () => _showGoalSheet(context),
                  onAdjust: (goal, amount) =>
                      goalsController.adjustProgress(goal.id, amount),
                  onEdit: (goal) => _showGoalSheet(context, goal: goal),
                  onMore: (goal) => _showGoalActions(context, goal),
                ),
                const SizedBox(height: 32),
              ];

              if (budgets.isEmpty) {
                children.add(
                  _BudgetEmptyState(onCreate: () => _showBudgetSheet(context)),
                );
              } else {
                children.add(
                  Text(
                    t.translate('activeBudgets'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                );
                children.add(const SizedBox(height: 16));
                for (final budget in budgets) {
                  children.add(
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () => _showBudgetSheet(context, budget: budget),
                        onLongPress: () => _showBudgetActions(context, budget),
                        child: BudgetCard(
                          budget: budget,
                          privacyListenable: privacyListenable,
                        )
                            .animate()
                            .fadeIn(duration: 320.ms)
                            .slideY(begin: 0.12, end: 0),
                      ),
                    ),
                  );
                }
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                children: children,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showGoalActions(
      BuildContext context, SavingsGoalModel goal) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.local_fire_department_rounded),
              title: Text(t.translate('goalDeposit')),
              subtitle: Text(t.translate('goalDepositSubtitle')),
              onTap: () => Navigator.pop(context, 'deposit'),
            ),
            ListTile(
              leading: const Icon(Icons.south_east_rounded),
              title: Text(t.translate('goalWithdraw')),
              subtitle: Text(t.translate('goalWithdrawSubtitle')),
              onTap: () => Navigator.pop(context, 'withdraw'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: Text(t.translate('editGoal')),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded),
              title: Text(t.translate('deleteGoal')),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );

    switch (action) {
      case 'deposit':
        final amount = await _showAdjustDialog(context, goal, true);
        if (amount != null && amount > 0) {
          await goalsController.adjustProgress(goal.id, amount);
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                t.translate('goalBoosted', params: {
                  'goal': goal.name,
                }),
              ),
            ),
          );
        }
        break;
      case 'withdraw':
        final amount = await _showAdjustDialog(context, goal, false);
        if (amount != null && amount > 0) {
          await goalsController.adjustProgress(goal.id, -amount);
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                t.translate('goalReduced', params: {
                  'goal': goal.name,
                }),
              ),
            ),
          );
        }
        break;
      case 'edit':
        await _showGoalSheet(context, goal: goal);
        break;
      case 'delete':
        await goalsController.deleteGoal(goal.id);
        messenger.showSnackBar(
          SnackBar(
            content: Text(t.translate('goalDeleted')),
            action: SnackBarAction(
              label: t.translate('undo'),
              onPressed: () => goalsController.addGoal(goal),
            ),
          ),
        );
        break;
      default:
        break;
    }
  }

  Future<double?> _showAdjustDialog(
    BuildContext context,
    SavingsGoalModel goal,
    bool deposit,
  ) async {
    final t = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: deposit
          ? (goal.targetAmount * 0.08).clamp(25, 400).toStringAsFixed(0)
          : (goal.currentAmount * 0.1).clamp(10, goal.currentAmount).toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            deposit
                ? t.translate('goalDeposit')
                : t.translate('goalWithdraw'),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: t.translate('amount'),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return t.translate('required');
                }
                final parsed = double.tryParse(value);
                if (parsed == null) {
                  return t.translate('invalidNumber');
                }
                if (!deposit && parsed > goal.currentAmount) {
                  return t.translate('goalWithdrawLimit');
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.translate('cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(context, double.parse(controller.text));
                }
              },
              child: Text(t.translate('confirm')),
            ),
          ],
        );
      },
    );

    return result;
  }

  Future<void> _showGoalSheet(BuildContext context,
      {SavingsGoalModel? goal}) async {
    final t = AppLocalizations.of(context);
    final nameController = TextEditingController(text: goal?.name ?? '');
    final targetController = TextEditingController(
      text: goal != null ? goal.targetAmount.toStringAsFixed(0) : '',
    );
    final currentController = TextEditingController(
      text: goal != null ? goal.currentAmount.toStringAsFixed(0) : '',
    );
    final imageController = TextEditingController(text: goal?.imageUrl ?? '');
    DateTime dueDate = goal?.dueDate ??
        DateTime.now().add(const Duration(days: 90));
    int color = goal?.color ?? AppConstants.primarySwatches.first.value;
    final formKey = GlobalKey<FormState>();

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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal == null
                                ? t.translate('createGoal')
                                : t.translate('editGoal'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: t.translate('goalName'),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? t.translate('required')
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: targetController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: t.translate('goalTarget'),
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
                            controller: currentController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: t.translate('goalCurrent'),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return t.translate('required');
                              }
                              final parsed = double.tryParse(value);
                              if (parsed == null) {
                                return t.translate('invalidNumber');
                              }
                              if (parsed >
                                  double.tryParse(targetController.text) ??
                                      double.infinity) {
                                return t.translate('goalCurrentLimit');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: imageController,
                            decoration: InputDecoration(
                              labelText: t.translate('goalImage'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.translate('goalDueDate', params: {
                                    'date': '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
                                  }),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: dueDate,
                                    firstDate: DateTime.now(),
                                    lastDate:
                                        DateTime.now().add(const Duration(days: 720)),
                                  );
                                  if (picked != null) {
                                    setState(() => dueDate = picked);
                                  }
                                },
                                child: Text(t.translate('change')),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            t.translate('goalColor'),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            children: [
                              for (final swatch in AppConstants.primarySwatches)
                                GestureDetector(
                                  onTap: () => setState(() => color = swatch.value),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(swatch.value),
                                      border: Border.all(
                                        color: color == swatch.value
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                                .withOpacity(0.9)
                                            : Colors.transparent,
                                        width: 3,
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
                                if (!(formKey.currentState?.validate() ?? false)) {
                                  return;
                                }
                                final target = double.parse(targetController.text);
                                final current = double.parse(currentController.text);
                                final updated = (goal ??
                                    SavingsGoalModel(
                                      id:
                                          'goal_${DateTime.now().millisecondsSinceEpoch}',
                                      name: nameController.text.trim(),
                                      targetAmount: target,
                                      currentAmount: current,
                                      color: color,
                                      imageUrl: imageController.text.trim(),
                                      dueDate: dueDate,
                                    ))
                                    .copyWith(
                                      name: nameController.text.trim(),
                                      targetAmount: target,
                                      currentAmount: current,
                                      color: color,
                                      imageUrl: imageController.text.trim().isEmpty
                                          ? goal?.imageUrl ??
                                              'https://images.unsplash.com/photo-1455849318743-b2233052fcff?auto=format&fit=crop&w=800&q=60'
                                          : imageController.text.trim(),
                                      dueDate: dueDate,
                                    );

                                if (goal == null) {
                                  await goalsController.addGoal(updated);
                                } else {
                                  await goalsController.updateGoal(updated);
                                }

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        goal == null
                                            ? t.translate('goalCreated')
                                            : t.translate('goalUpdated'),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text(t.translate('save')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
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
class _GoalsSection extends StatelessWidget {
  const _GoalsSection({
    required this.goals,
    required this.onCreate,
    required this.onAdjust,
    required this.onEdit,
    required this.onMore,
  });

  final List<SavingsGoalModel> goals;
  final VoidCallback onCreate;
  final void Function(SavingsGoalModel goal, double delta) onAdjust;
  final void Function(SavingsGoalModel goal) onEdit;
  final void Function(SavingsGoalModel goal) onMore;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (goals.isEmpty) {
      return _GoalsEmptyState(onCreate: onCreate);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              t.translate('savingsGoalsTitle'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: Text(t.translate('addGoal')),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: goals.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final goal = goals[index];
              return _GoalCard(
                goal: goal,
                onEdit: () => onEdit(goal),
                onMore: () => onMore(goal),
                onQuickAdjust: (delta) => onAdjust(goal, delta),
              )
                  .animate(delay: (index * 60).ms)
                  .fadeIn(duration: 320.ms)
                  .slideX(
                    begin: Directionality.of(context) == TextDirection.ltr
                        ? 0.12
                        : -0.12,
                    end: 0,
                    curve: Curves.fastOutSlowIn,
                  );
            },
          ),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.onEdit,
    required this.onMore,
    required this.onQuickAdjust,
  });

  final SavingsGoalModel goal;
  final VoidCallback onEdit;
  final VoidCallback onMore;
  final void Function(double delta) onQuickAdjust;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final progress = goal.progress;
    final remaining =
        (goal.targetAmount - goal.currentAmount).clamp(0, goal.targetAmount);
    final quickBoostBase = (goal.targetAmount * 0.07).clamp(10, 500).toDouble();
    final quickBoost = remaining <= 0
        ? 0
        : math.min(remaining, math.max(10, quickBoostBase));
    final available = goal.currentAmount.clamp(0, goal.targetAmount);
    final quickPullBase = (goal.targetAmount * 0.04).clamp(8, 400).toDouble();
    final quickPull = available <= 0
        ? 0
        : math.min(available, math.max(8, quickPullBase));
    final daysLeft = goal.dueDate.difference(DateTime.now()).inDays;
    final dueLabel = daysLeft <= 0
        ? t.translate('goalDueToday')
        : t.translate('goalDueIn', params: {'days': daysLeft.toString()});

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              Color(goal.color).withOpacity(0.92),
              Color(goal.color).withOpacity(0.72),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(goal.color).withOpacity(0.28),
              blurRadius: 26,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.05),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: Image.network(
                    goal.imageUrl,
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.08),
                    colorBlendMode: BlendMode.darken,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onMore,
                      icon: const Icon(Icons.more_horiz_rounded),
                      color: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${goal.currentAmount.toStringAsFixed(0)} / ${goal.targetAmount.toStringAsFixed(0)}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 420),
                  builder: (context, value, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: Colors.white24,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  dueLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: _GoalPillButton(
                        icon: Icons.trending_up_rounded,
                        label: t.translate('goalQuickBoost'),
                        onTap: quickBoost <= 0
                            ? null
                            : () => onQuickAdjust(quickBoost),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GoalPillButton(
                        icon: Icons.trending_down_rounded,
                        label: t.translate('goalQuickPause'),
                        onTap: quickPull <= 0
                            ? null
                            : () => onQuickAdjust(-quickPull),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalPillButton extends StatelessWidget {
  const _GoalPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.16),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: 0,
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _GoalsEmptyState extends StatelessWidget {
  const _GoalsEmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.translate('goalEmptyTitle'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              t.translate('goalEmptySubtitle'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onCreate,
              child: Text(t.translate('createGoal')),
            ),
          ],
        ),
      ),
    );
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
