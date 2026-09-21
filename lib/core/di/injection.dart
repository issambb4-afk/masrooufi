import 'package:get_it/get_it.dart';

import '../../data/database/app_database.dart';
import '../../data/database/database_connection.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/recurring_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/recurring_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  // Database setup
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase(openConnection()));

  // Repositories
  sl.registerLazySingleton<AccountRepository>(() => AccountRepositoryImpl(sl()));
  sl.registerLazySingleton<BudgetRepository>(() => BudgetRepositoryImpl(sl()));
  sl.registerLazySingleton<CategoryRepository>(() => CategoryRepositoryImpl(sl()));
  sl.registerLazySingleton<RecurringRepository>(() => RecurringRepositoryImpl(sl()));
  sl.registerLazySingleton<TransactionRepository>(() => TransactionRepositoryImpl(sl()));
}
