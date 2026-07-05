import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'seed/default_categories.dart';
import 'tables/accounts_table.dart';
import 'tables/budgets_table.dart';
import 'tables/categories_table.dart';
import 'tables/savings_goals_table.dart';
import 'tables/transactions_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Accounts, Categories, Transactions, Budgets, SavingsGoals],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedDefaultCategories();
    },
  );

  Future<void> _seedDefaultCategories() async {
    await batch((b) {
      b.insertAll(
        categories,
        kAllDefaultCategories.map(
          (c) => CategoriesCompanion.insert(
            id: c.id,
            name: c.name,
            type: c.type,
            parentId: Value(c.parentId),
            icon: c.icon,
            color: c.color,
            isDefault: const Value(true),
          ),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'gestor_personal.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
