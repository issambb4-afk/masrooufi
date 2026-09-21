class BudgetEntity {
  final String id;
  final String period; // e.g. 2026-09
  final String type; // global, category
  final String? categoryId;
  final int amount; // minor units
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BudgetEntity({
    required this.id,
    required this.period,
    required this.type,
    this.categoryId,
    required this.amount,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });
}
