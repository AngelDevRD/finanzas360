import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency.dart';
import '../../../core/formatting.dart';
import '../../../core/icon_map.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../../categories/data/categories_repository.dart';
import '../../transactions/data/transactions_repository.dart';
import '../data/budgets_repository.dart';
import 'budget_form_sheet.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(currentMonthBudgetsProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final currency = ref.watch(currencyProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text('Presupuestos · ${formatMonthYear(now)}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showBudgetFormSheet(context),
        child: const Icon(Icons.add),
      ),
      body: budgetsAsync.when(
        data: (budgets) {
          if (budgets.isEmpty) {
            return EmptyState(
              icon: Icons.pie_chart_outline,
              message: 'No tienes presupuestos para este mes.',
              actionLabel: 'Crear presupuesto',
              onAction: () => showBudgetFormSheet(context),
            );
          }
          return categoriesAsync.when(
            data: (categories) {
              final categoryById = {for (final c in categories) c.id: c};
              return transactionsAsync.when(
                data: (transactions) {
                  final monthSpend = <String, double>{};
                  for (final t in transactions) {
                    if (t.type != 'expense') continue;
                    if (t.date.month != now.month || t.date.year != now.year) {
                      continue;
                    }
                    monthSpend[t.categoryId] =
                        (monthSpend[t.categoryId] ?? 0) + t.amount;
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: budgets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final budget = budgets[index];
                      final category = categoryById[budget.categoryId];
                      final spent = monthSpend[budget.categoryId] ?? 0;
                      final progress = budget.limitAmount == 0
                          ? 0.0
                          : spent / budget.limitAmount;
                      final color = category != null
                          ? Color(category.color)
                          : Theme.of(context).colorScheme.primary;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    category != null
                                        ? iconForKey(category.icon)
                                        : Icons.category,
                                    color: color,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      category?.name ?? 'Categoría',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () => showBudgetFormSheet(
                                      context,
                                      existing: budget,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                    ),
                                    onPressed: () => ref
                                        .read(budgetsRepositoryProvider)
                                        .delete(budget.id),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LabeledProgressBar(
                                progress: progress,
                                color: color,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${formatCurrency(spent, currency)} de ${formatCurrency(budget.limitAmount, currency)}'
                                ' (${(progress * 100).clamp(0, 999).toStringAsFixed(0)}%)',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: progress > 1
                                          ? Colors.red
                                          : Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.color,
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
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
