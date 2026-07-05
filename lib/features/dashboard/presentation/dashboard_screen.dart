import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency.dart';
import '../../../core/database/app_database.dart';
import '../../../core/formatting.dart';
import '../../../core/icon_map.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../../../shared/widgets/summary_card.dart';
import '../../accounts/data/accounts_repository.dart';
import '../../categories/data/categories_repository.dart';
import '../../charts/category_pie_chart.dart';
import '../../goals/data/goals_repository.dart';
import '../../goals/presentation/goals_screen.dart';
import '../../transactions/data/transactions_repository.dart';
import '../../transactions/presentation/transaction_form_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final goalsAsync = ref.watch(goalsStreamProvider);
    final currency = ref.watch(currencyProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text('Resumen · ${formatMonthYear(now)}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showTransactionFormSheet(context),
        child: const Icon(Icons.add),
      ),
      body: accountsAsync.when(
        data: (accounts) => transactionsAsync.when(
          data: (transactions) => categoriesAsync.when(
            data: (categories) {
              final categoryById = {for (final c in categories) c.id: c};
              final balance = accounts.fold<double>(
                0,
                (s, a) => s + a.currentBalance,
              );

              final monthTx = transactions
                  .where(
                    (t) => t.date.month == now.month && t.date.year == now.year,
                  )
                  .toList();
              final incomeMonth = monthTx
                  .where((t) => t.type == 'income')
                  .fold<double>(0, (s, t) => s + t.amount);
              final expenseMonth = monthTx
                  .where((t) => t.type == 'expense')
                  .fold<double>(0, (s, t) => s + t.amount);
              final savingsPct = incomeMonth == 0
                  ? 0.0
                  : ((incomeMonth - expenseMonth) / incomeMonth) * 100;

              final spendByCategory = <String, double>{};
              for (final t in monthTx) {
                if (t.type != 'expense') continue;
                spendByCategory[t.categoryId] =
                    (spendByCategory[t.categoryId] ?? 0) + t.amount;
              }
              final slices = spendByCategory.entries.map((e) {
                final cat = categoryById[e.key];
                return CategorySlice(
                  label: cat?.name ?? 'Otro',
                  amount: e.value,
                  color: cat != null ? Color(cat.color) : Colors.grey,
                );
              }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

              final recent = transactions.take(5).toList();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      SummaryCard(
                        label: 'Balance actual',
                        value: formatCurrency(balance, currency),
                        icon: Icons.account_balance_wallet,
                        color: Colors.blue,
                      ),
                      SummaryCard(
                        label: 'Ingresos del mes',
                        value: formatCurrency(incomeMonth, currency),
                        icon: Icons.trending_up,
                        color: Colors.green,
                      ),
                      SummaryCard(
                        label: 'Gastos del mes',
                        value: formatCurrency(expenseMonth, currency),
                        icon: Icons.trending_down,
                        color: Colors.red,
                      ),
                      SummaryCard(
                        label: '% ahorrado este mes',
                        value: '${savingsPct.toStringAsFixed(0)}%',
                        icon: Icons.savings,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Gastos por categoría',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CategoryPieChart(slices: slices),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ahorros',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const GoalsScreen(),
                          ),
                        ),
                        child: const Text('Ver todas'),
                      ),
                    ],
                  ),
                  goalsAsync.when(
                    data: (goals) {
                      if (goals.isEmpty) {
                        return const EmptyState(
                          icon: Icons.flag_outlined,
                          message: 'No tienes metas de ahorro todavía.',
                        );
                      }
                      return Column(
                        children: [
                          for (final goal in goals)
                            _GoalProgressCard(goal: goal, currency: currency),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Movimientos recientes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (recent.isEmpty)
                    const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      message: 'Sin movimientos todavía.',
                    )
                  else
                    ...recent.map((t) {
                      final cat = categoryById[t.categoryId];
                      final isIncome = t.type == 'income';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: cat != null
                                ? Color(cat.color).withValues(alpha: 0.15)
                                : null,
                          ),
                          title: Text(
                            t.description.isNotEmpty
                                ? t.description
                                : (cat?.name ?? ''),
                          ),
                          subtitle: Text(formatDate(t.date)),
                          trailing: Text(
                            '${isIncome ? '+' : '-'}${formatCurrency(t.amount, currency)}',
                            style: TextStyle(
                              color: isIncome ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _GoalProgressCard extends StatelessWidget {
  const _GoalProgressCard({required this.goal, required this.currency});

  final SavingsGoal goal;
  final AppCurrency currency;

  @override
  Widget build(BuildContext context) {
    final progress = goal.targetAmount == 0
        ? 0.0
        : goal.currentAmount / goal.targetAmount;
    final remaining = (goal.targetAmount - goal.currentAmount).clamp(
      0,
      goal.targetAmount,
    );
    final color = Color(goal.color);

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(iconForKey(goal.icon), color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    goal.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LabeledProgressBar(progress: progress, color: color),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                Text(
                  'Objetivo: ${formatCurrency(goal.targetAmount, currency)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Ahorrado: ${formatCurrency(goal.currentAmount, currency)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Restante: ${formatCurrency(remaining.toDouble(), currency)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
