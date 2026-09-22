import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/injection.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/repositories/account_repository.dart';

final accountsProvider = FutureProvider.autoDispose<List<AccountEntity>>((ref) async {
  final repo = sl<AccountRepository>();
  final accounts = await repo.getAllAccounts();
  return accounts.where((a) => a.isActive).toList();
});
