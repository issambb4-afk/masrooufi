import 'package:drift/drift.dart';

import 'tables/accounts.dart';
import 'tables/budgets.dart';
import 'tables/categories.dart';
import 'tables/recurring_rules.dart';
import 'tables/transactions.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Accounts,
  Categories,
  RecurringRules,
  Transactions,
  Budgets,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle migrations incrementally in the future
      },
      beforeOpen: (details) async {
        // Enforce foreign keys
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}
