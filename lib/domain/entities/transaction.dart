class TransactionEntity {
  final String id;
  final String type; // income, expense, transfer
  final int amount; // minor units
  final String? categoryId;
  final String accountId;
  final String? destinationAccountId;
  final DateTime transactionDate;
  final String? time;
  final String? note;
  final String? paymentMethod;
  final String? recurringRuleId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const TransactionEntity({
    required this.id,
    required this.type,
    required this.amount,
    this.categoryId,
    required this.accountId,
    this.destinationAccountId,
    required this.transactionDate,
    this.time,
    this.note,
    this.paymentMethod,
    this.recurringRuleId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
}
