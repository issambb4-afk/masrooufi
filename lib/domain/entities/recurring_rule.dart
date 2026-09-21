class RecurringRuleEntity {
  final String id;
  final String name;
  final int amount; // minor units
  final String type; // income, expense, transfer
  final String? categoryId;
  final String accountId;
  final String? destinationAccountId;
  final String frequency; // daily, weekly, monthly, yearly, custom
  final int interval;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextOccurrence;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecurringRuleEntity({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    this.categoryId,
    required this.accountId,
    this.destinationAccountId,
    required this.frequency,
    required this.interval,
    required this.startDate,
    this.endDate,
    required this.nextOccurrence,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
}
