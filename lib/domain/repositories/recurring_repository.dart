import '../entities/recurring_rule.dart';

abstract class RecurringRepository {
  Future<List<RecurringRuleEntity>> getAllRules();
  Future<RecurringRuleEntity?> getRuleById(String id);
  Future<void> createRule(RecurringRuleEntity rule);
  Future<void> updateRule(RecurringRuleEntity rule);
  Future<void> deactivateRule(String id);
}
