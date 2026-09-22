import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../data/database/app_database.dart';

class RecurringEngine {
  final AppDatabase _db;

  RecurringEngine(this._db);

  /// Processes all due recurring rules.
  /// Generates transactions and updates the next occurrence timestamp atomically to prevent duplicates.
  Future<int> processDueRules() async {
    final now = DateTime.now();
    int transactionsGenerated = 0;

    await _db.transaction(() async {
      // Fetch all active rules due for processing
      final dueRulesQuery = _db.select(_db.recurringRules)
        ..where((tbl) => tbl.isActive.equals(true))
        ..where((tbl) => tbl.nextOccurrence.isSmallerOrEqualValue(now));

      final dueRules = await dueRulesQuery.get();

      for (final rule in dueRules) {
        // Stop generating if we hit the end date
        if (rule.endDate != null && rule.nextOccurrence.isAfter(rule.endDate!)) {
          await _db.update(_db.recurringRules).replace(
            rule.copyWith(isActive: false)
          );
          continue;
        }

        // 1. Generate Transaction
        final newTxn = TransactionsCompanion.insert(
          id: const Uuid().v4(),
          type: rule.type,
          amount: rule.amount,
          accountId: rule.accountId,
          categoryId: rule.categoryId != null ? Value(rule.categoryId!) : const Value.absent(),
          destinationAccountId: rule.destinationAccountId != null ? Value(rule.destinationAccountId!) : const Value.absent(),
          transactionDate: rule.nextOccurrence,
          recurringRuleId: Value(rule.id),
          note: Value('${rule.name} (Auto-generated)'),
        );

        await _db.into(_db.transactions).insert(newTxn);
        transactionsGenerated++;

        // 2. Calculate next occurrence
        DateTime nextDate;
        switch (rule.frequency) {
          case 'daily':
            nextDate = rule.nextOccurrence.add(Duration(days: 1 * rule.interval));
            break;
          case 'weekly':
            nextDate = rule.nextOccurrence.add(Duration(days: 7 * rule.interval));
            break;
          case 'monthly':
            // Simple month addition, handling overflow naturally in Dart DateTime
            nextDate = DateTime(rule.nextOccurrence.year, rule.nextOccurrence.month + (1 * rule.interval), rule.nextOccurrence.day, rule.nextOccurrence.hour, rule.nextOccurrence.minute);
            break;
          case 'yearly':
            nextDate = DateTime(rule.nextOccurrence.year + (1 * rule.interval), rule.nextOccurrence.month, rule.nextOccurrence.day, rule.nextOccurrence.hour, rule.nextOccurrence.minute);
            break;
          default:
            nextDate = rule.nextOccurrence.add(Duration(days: 30 * rule.interval)); // Fallback
        }

        // 3. Update Rule
        await _db.update(_db.recurringRules).replace(
          rule.copyWith(nextOccurrence: nextDate)
        );
      }
    });

    return transactionsGenerated;
  }
}
