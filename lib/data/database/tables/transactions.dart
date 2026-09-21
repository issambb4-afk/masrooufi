import 'package:drift/drift.dart';
import 'accounts.dart';
import 'categories.dart';
import 'recurring_rules.dart';

@TableIndex(name: 'idx_transactions_date', columns: {#transactionDate})
@TableIndex(name: 'idx_transactions_category', columns: {#categoryId})
@TableIndex(name: 'idx_transactions_account', columns: {#accountId})
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // income, expense, transfer
  IntColumn get amount => integer()(); // minor units
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get destinationAccountId => text().nullable().references(Accounts, #id)(); // for transfers
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get time => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get recurringRuleId => text().nullable().references(RecurringRules, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
