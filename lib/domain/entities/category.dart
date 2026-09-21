class CategoryEntity {
  final String id;
  final String name;
  final String? icon;
  final String? color;
  final String type; // income, expense
  final bool isDefault;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    required this.type,
    required this.isDefault,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
}
