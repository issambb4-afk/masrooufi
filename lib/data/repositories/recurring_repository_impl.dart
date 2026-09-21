import 'package:drift/drift.dart';
import '../../domain/entities/recurring_rule.dart';
import '../../domain/repositories/recurring_repository.dart';
import '../database/app_database.dart';

class RecurringRepositoryImpl implements RecurringRepository {
  final AppDatabase _db;

  RecurringRepositoryImpl(this._db);

  RecurringRuleEntity _mapToEntity(RecurringRule rule) {
    return RecurringRuleEntity(
      id: rule.id,
      name: rule.name,
      amount: rule.amount,
      type: rule.type,
      categoryId: rule.categoryId,
      accountId: rule.accountId,
      destinationAccountId: rule.destinationAccountId,
      frequency: rule.frequency,
      interval: rule.interval,
      startDate: rule.startDate,
      endDate: rule.endDate,
      nextOccurrence: rule.nextOccurrence,
      isActive: rule.isActive,
      createdAt: rule.createdAt,
      updatedAt: rule.updatedAt,
    );
  }

  RecurringRulesCompanion _mapToCompanion(RecurringRuleEntity entity) {
    return RecurringRulesCompanion(
      id: Value(entity.id),
      name: Value(entity.name),
      amount: Value(entity.amount),
      type: Value(entity.type),
      categoryId: Value(entity.categoryId),
      accountId: Value(entity.accountId),
      destinationAccountId: Value(entity.destinationAccountId),
      frequency: Value(entity.frequency),
      interval: Value(entity.interval),
      startDate: Value(entity.startDate),
      endDate: Value(entity.endDate),
      nextOccurrence: Value(entity.nextOccurrence),
      isActive: Value(entity.isActive),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
    );
  }

  @override
  Future<List<RecurringRuleEntity>> getAllRules() async {
    final rules = await _db.select(_db.recurringRules).get();
    return rules.map(_mapToEntity).toList();
  }

  @override
  Future<RecurringRuleEntity?> getRuleById(String id) async {
    final rule = await (_db.select(_db.recurringRules)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return rule != null ? _mapToEntity(rule) : null;
  }

  @override
  Future<void> createRule(RecurringRuleEntity rule) =>
      _db.into(_db.recurringRules).insert(_mapToCompanion(rule));

  @override
  Future<void> updateRule(RecurringRuleEntity rule) =>
      _db.update(_db.recurringRules).replace(_mapToCompanion(rule));

  @override
  Future<void> deactivateRule(String id) async {
    await (_db.update(_db.recurringRules)..where((tbl) => tbl.id.equals(id)))
        .write(const RecurringRulesCompanion(isActive: Value(false)));
  }
}
