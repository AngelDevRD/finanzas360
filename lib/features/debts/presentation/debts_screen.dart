import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency.dart';
import '../../../core/database/app_database.dart';
import '../../../core/formatting.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../data/debts_repository.dart';
import 'debt_form_sheet.dart';

const _icons = {
  'credit_card': Icons.credit_card,
  'house': Icons.house,
  'directions_car_filled': Icons.directions_car_filled,
  'school': Icons.school,
  'receipt_long': Icons.receipt_long,
};

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(debtsStreamProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Deudas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDebtFormSheet(context),
        child: const Icon(Icons.add),
      ),
      body: debtsAsync.when(
        data: (debts) {
          if (debts.isEmpty) {
            return EmptyState(
              icon: Icons.money_off_outlined,
              message: 'No tienes deudas registradas.',
              actionLabel: 'Registrar deuda',
              onAction: () => showDebtFormSheet(context),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: debts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final debt = debts[index];
              final paid = debt.totalAmount - debt.remainingAmount;
              final progress = debt.totalAmount == 0
                  ? 0.0
                  : paid / debt.totalAmount;
              final color = Color(debt.color);
              final isPaidOff = debt.remainingAmount <= 0;

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
                              _icons[debt.icon] ?? Icons.credit_card,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              debt.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () =>
                                showDebtFormSheet(context, existing: debt),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => ref
                                .read(debtsRepositoryProvider)
                                .delete(debt.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LabeledProgressBar(
                        progress: progress,
                        color: isPaidOff ? Colors.green : color,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isPaidOff
                            ? 'Pagada por completo (${formatCurrency(debt.totalAmount, currency)})'
                            : '${formatCurrency(debt.remainingAmount, currency)} pendientes de ${formatCurrency(debt.totalAmount, currency)}'
                                  ' (${(progress * 100).clamp(0, 100).toStringAsFixed(0)}% pagado)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (!isPaidOff) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.payments_outlined),
                            label: const Text('Registrar pago'),
                            onPressed: () =>
                                _showPaymentDialog(context, ref, debt),
                          ),
                        ),
                      ],
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

  void _showPaymentDialog(BuildContext context, WidgetRef ref, Debt debt) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar pago'),
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
                    .read(debtsRepositoryProvider)
                    .registerPayment(debt.id, amount);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Pagar'),
          ),
        ],
      ),
    );
  }
}
