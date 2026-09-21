import 'package:drift/drift.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../database/app_database.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final AppDatabase _db;

  CategoryRepositoryImpl(this._db);

  CategoryEntity _mapToEntity(Category category) {
    return CategoryEntity(
      id: category.id,
      name: category.name,
      icon: category.icon,
      color: category.color,
      type: category.type,
      isDefault: category.isDefault,
      isActive: category.isActive,
      sortOrder: category.sortOrder,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
    );
  }

  CategoriesCompanion _mapToCompanion(CategoryEntity entity) {
    return CategoriesCompanion(
      id: Value(entity.id),
      name: Value(entity.name),
      icon: Value(entity.icon),
      color: Value(entity.color),
      type: Value(entity.type),
      isDefault: Value(entity.isDefault),
      isActive: Value(entity.isActive),
      sortOrder: Value(entity.sortOrder),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
    );
  }

  @override
  Future<List<CategoryEntity>> getAllCategories() async {
    final categories = await _db.select(_db.categories).get();
    return categories.map(_mapToEntity).toList();
  }

  @override
  Future<CategoryEntity?> getCategoryById(String id) async {
    final category = await (_db.select(_db.categories)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return category != null ? _mapToEntity(category) : null;
  }

  @override
  Future<void> createCategory(CategoryEntity category) =>
      _db.into(_db.categories).insert(_mapToCompanion(category));

  @override
  Future<void> updateCategory(CategoryEntity category) =>
      _db.update(_db.categories).replace(_mapToCompanion(category));

  @override
  Future<void> deactivateCategory(String id) async {
    await (_db.update(_db.categories)..where((tbl) => tbl.id.equals(id)))
        .write(const CategoriesCompanion(isActive: Value(false)));
  }
}
