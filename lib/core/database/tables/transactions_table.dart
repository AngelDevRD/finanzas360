import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'categories_table.dart';

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get type => text()(); // income, expense
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get paymentMethod => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get receiptPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
