import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/injection.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/repositories/category_repository.dart';

final categoriesProvider = FutureProvider.autoDispose<List<CategoryEntity>>((ref) async {
  final repo = sl<CategoryRepository>();
  final categories = await repo.getAllCategories();
  return categories.where((c) => c.isActive).toList();
});
