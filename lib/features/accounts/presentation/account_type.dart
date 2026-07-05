import 'package:flutter/material.dart';

enum AccountType { cash, bank, savings, debit, credit, wallet }

extension AccountTypeX on AccountType {
  String get id => name;

  String get label => switch (this) {
    AccountType.cash => 'Efectivo',
    AccountType.bank => 'Cuenta bancaria',
    AccountType.savings => 'Cuenta de ahorro',
    AccountType.debit => 'Tarjeta de débito',
    AccountType.credit => 'Tarjeta de crédito',
    AccountType.wallet => 'Wallet digital',
  };

  IconData get icon => switch (this) {
    AccountType.cash => Icons.payments,
    AccountType.bank => Icons.account_balance,
    AccountType.savings => Icons.savings,
    AccountType.debit => Icons.credit_card,
    AccountType.credit => Icons.credit_card,
    AccountType.wallet => Icons.account_balance_wallet,
  };

  static AccountType fromId(String id) => AccountType.values.firstWhere(
    (t) => t.id == id,
    orElse: () => AccountType.cash,
  );
}
