import 'package:drift/drift.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';
import '../database/app_database.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AppDatabase _db;

  AccountRepositoryImpl(this._db);

  AccountEntity _mapToEntity(Account account) {
    return AccountEntity(
      id: account.id,
      name: account.name,
      type: account.type,
      currency: account.currency,
      openingBalance: account.openingBalance,
      isActive: account.isActive,
      createdAt: account.createdAt,
      updatedAt: account.updatedAt,
    );
  }

  AccountsCompanion _mapToCompanion(AccountEntity entity) {
    return AccountsCompanion(
      id: Value(entity.id),
      name: Value(entity.name),
      type: Value(entity.type),
      currency: Value(entity.currency),
      openingBalance: Value(entity.openingBalance),
      isActive: Value(entity.isActive),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
    );
  }

  @override
  Future<List<AccountEntity>> getAllAccounts() async {
    final accounts = await _db.select(_db.accounts).get();
    return accounts.map(_mapToEntity).toList();
  }

  @override
  Future<AccountEntity?> getAccountById(String id) async {
    final account = await (_db.select(_db.accounts)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return account != null ? _mapToEntity(account) : null;
  }

  @override
  Future<void> createAccount(AccountEntity account) =>
      _db.into(_db.accounts).insert(_mapToCompanion(account));

  @override
  Future<void> updateAccount(AccountEntity account) =>
      _db.update(_db.accounts).replace(_mapToCompanion(account));

  @override
  Future<void> deactivateAccount(String id) async {
    await (_db.update(_db.accounts)..where((tbl) => tbl.id.equals(id)))
        .write(const AccountsCompanion(isActive: Value(false)));
  }
}
