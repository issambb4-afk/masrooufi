class AccountEntity {
  final String id;
  final String name;
  final String type; // cash, bank, creditCard, wallet, other
  final String currency; // e.g. TND
  final int openingBalance; // minor units
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AccountEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.openingBalance,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
}
