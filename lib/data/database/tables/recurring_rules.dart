import 'package:drift/drift.dart';
import 'accounts.dart';
import 'categories.dart';

@TableIndex(name: 'idx_recurring_next', columns: {#nextOccurrence})
class RecurringRules extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get amount => integer()();
  TextColumn get type => text()(); // income, expense, transfer
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get destinationAccountId => text().nullable().references(Accounts, #id)(); // for transfers
  TextColumn get frequency => text()(); // daily, weekly, monthly, yearly, custom
  IntColumn get interval => integer().withDefault(const Constant(1))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get nextOccurrence => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
