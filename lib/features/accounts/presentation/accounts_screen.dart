import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency.dart';
import '../../../core/formatting.dart';
import '../data/accounts_repository.dart';
import '../../../shared/widgets/empty_state.dart';
import 'account_form_sheet.dart';
import 'account_type.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final currency = ref.watch(currencyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cuentas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAccountFormSheet(context),
        child: const Icon(Icons.add),
      ),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              message:
                  'Aún no tienes cuentas. Crea la primera para empezar a registrar movimientos.',
              actionLabel: 'Crear cuenta',
              onAction: () => showAccountFormSheet(context),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final account = accounts[index];
              final type = AccountTypeX.fromId(account.type);
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Icon(type.icon)),
                  title: Text(account.name),
                  subtitle: Text(type.label),
                  trailing: Text(
                    formatCurrency(account.currentBalance, currency),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  onTap: () => showAccountFormSheet(context, existing: account),
                  onLongPress: () => _confirmDelete(context, ref, account.id),
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

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          'Se eliminará la cuenta. Las transacciones asociadas no se borran automáticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(accountsRepositoryProvider).delete(id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
