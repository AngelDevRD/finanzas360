import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency.dart';
import '../../../core/database/app_database.dart';
import '../../../core/formatting.dart';
import '../../../core/icon_map.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../categories/data/categories_repository.dart';
import '../data/transactions_repository.dart';
import 'transaction_form_sheet.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _filterType = 'all';

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _filterType,
            onSelected: (v) => setState(() => _filterType = v),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'all', child: Text('Todos')),
              PopupMenuItem(value: 'income', child: Text('Solo ingresos')),
              PopupMenuItem(value: 'expense', child: Text('Solo gastos')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showTransactionFormSheet(context),
        child: const Icon(Icons.add),
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          final filtered = _filterType == 'all'
              ? transactions
              : transactions.where((t) => t.type == _filterType).toList();

          if (filtered.isEmpty) {
            return EmptyState(
              icon: Icons.swap_horiz,
              message: 'No hay movimientos registrados todavía.',
              actionLabel: 'Agregar movimiento',
              onAction: () => showTransactionFormSheet(context),
            );
          }

          return categoriesAsync.when(
            data: (categories) {
              final categoryById = {for (final c in categories) c.id: c};
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final t = filtered[index];
                  final category = categoryById[t.categoryId];
                  final isIncome = t.type == 'income';
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: category != null
                            ? Color(category.color).withValues(alpha: 0.15)
                            : null,
                        child: Icon(
                          category != null
                              ? iconForKey(category.icon)
                              : Icons.category,
                          color: category != null
                              ? Color(category.color)
                              : null,
                        ),
                      ),
                      title: Text(
                        t.description.isNotEmpty
                            ? t.description
                            : (category?.name ?? ''),
                      ),
                      subtitle: Text(
                        '${category?.name ?? ''} · ${formatDate(t.date)}',
                      ),
                      trailing: Text(
                        '${isIncome ? '+' : '-'}${formatCurrency(t.amount, currency)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: isIncome ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      onTap: () =>
                          showTransactionFormSheet(context, existing: t),
                      onLongPress: () => _confirmDelete(context, ref, t),
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
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Transaction t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(transactionsRepositoryProvider).delete(t);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
