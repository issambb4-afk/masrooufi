import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:masrooufi/data/database/app_database.dart';
import 'package:masrooufi/features/recurring/application/recurring_engine.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  late RecurringEngine engine;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    engine = RecurringEngine(db);

    // Setup basic relational data
    await db.into(db.accounts).insert(AccountsCompanion.insert(
      id: 'acc1',
      name: 'Bank',
      type: 'bank',
      currency: 'TND',
      openingBalance: 0,
    ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
      id: 'cat1',
      name: 'Netflix',
      type: 'expense',
    ));
  });

  tearDown(() async {
    await db.close();
  });

  test('Recurring engine generates transactions for due rules', () async {
    // Insert a rule due 5 days ago
    final pastDate = DateTime.now().subtract(const Duration(days: 5));

    await db.into(db.recurringRules).insert(RecurringRulesCompanion.insert(
      id: const Uuid().v4(),
      name: 'Monthly Sub',
      amount: 15000,
      type: 'expense',
      accountId: 'acc1',
      categoryId: const Value('cat1'),
      frequency: 'monthly',
      startDate: pastDate,
      nextOccurrence: pastDate,
    ));

    final count = await engine.processDueRules();
    expect(count, 1);

    final txns = await db.select(db.transactions).get();
    expect(txns.length, 1);
    expect(txns.first.amount, 15000);
    expect(txns.first.note!.contains('Auto-generated'), isTrue);

    final rules = await db.select(db.recurringRules).get();
    expect(rules.first.nextOccurrence.isAfter(DateTime.now()), isTrue);
  });

  test('Recurring engine is idempotent (does not generate duplicates for future rules)', () async {
    // Insert a rule due TOMORROW
    final futureDate = DateTime.now().add(const Duration(days: 1));

    await db.into(db.recurringRules).insert(RecurringRulesCompanion.insert(
      id: const Uuid().v4(),
      name: 'Future Sub',
      amount: 15000,
      type: 'expense',
      accountId: 'acc1',
      categoryId: const Value('cat1'),
      frequency: 'monthly',
      startDate: futureDate,
      nextOccurrence: futureDate,
    ));

    final count = await engine.processDueRules();
    expect(count, 0); // Not due yet

    final txns = await db.select(db.transactions).get();
    expect(txns.isEmpty, isTrue);
  });
}
