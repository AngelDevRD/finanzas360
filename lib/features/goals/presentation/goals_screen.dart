import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency.dart';
import '../../../core/database/app_database.dart';
import '../../../core/formatting.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../data/goals_repository.dart';
import 'goal_form_sheet.dart';

const _icons = {
  'savings': Icons.savings,
  'flight': Icons.flight,
  'directions_car_filled': Icons.directions_car_filled,
  'house': Icons.house,
  'computer': Icons.computer,
};

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsStreamProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Metas de ahorro')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showGoalFormSheet(context),
        child: const Icon(Icons.add),
      ),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return EmptyState(
              icon: Icons.flag_outlined,
              message: 'No tienes metas de ahorro todavía.',
              actionLabel: 'Crear meta',
              onAction: () => showGoalFormSheet(context),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final goal = goals[index];
              final progress = goal.targetAmount == 0
                  ? 0.0
                  : goal.currentAmount / goal.targetAmount;
              final color = Color(goal.color);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.15),
                            child: Icon(
                              _icons[goal.icon] ?? Icons.savings,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              goal.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () =>
                                showGoalFormSheet(context, existing: goal),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => ref
                                .read(goalsRepositoryProvider)
                                .delete(goal.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LabeledProgressBar(progress: progress, color: color),
                      const SizedBox(height: 8),
                      Text(
                        '${formatCurrency(goal.currentAmount, currency)} de ${formatCurrency(goal.targetAmount, currency)}'
                        ' (${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Aportar'),
                          onPressed: () =>
                              _showContributeDialog(context, ref, goal),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showContributeDialog(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal goal,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar aporte'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Monto'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                ref
                    .read(goalsRepositoryProvider)
                    .addContribution(goal.id, amount);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Aportar'),
          ),
        ],
      ),
    );
  }
}
