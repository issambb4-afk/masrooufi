import '../entities/category.dart';

abstract class CategoryRepository {
  Future<List<CategoryEntity>> getAllCategories();
  Future<CategoryEntity?> getCategoryById(String id);
  Future<void> createCategory(CategoryEntity category);
  Future<void> updateCategory(CategoryEntity category);
  Future<void> deactivateCategory(String id);
}
