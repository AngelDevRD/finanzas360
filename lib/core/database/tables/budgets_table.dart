import 'package:drift/drift.dart';

import 'categories_table.dart';

class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().references(Categories, #id)();
  IntColumn get month => integer()();
  IntColumn get year => integer()();
  RealColumn get limitAmount => real()();

  @override
  Set<Column> get primaryKey => {id};
}
