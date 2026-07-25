import 'package:drift/drift.dart';

class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // cash, bank, savings, debit, credit, wallet
  TextColumn get icon => text()();
  IntColumn get color => integer()();
  RealColumn get initialBalance => real().withDefault(const Constant(0))();
  RealColumn get currentBalance => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
