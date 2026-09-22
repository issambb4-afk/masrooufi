import 'package:drift/drift.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../database/app_database.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase _db;

  TransactionRepositoryImpl(this._db);

  TransactionEntity _mapToEntity(Transaction transaction) {
    return TransactionEntity(
      id: transaction.id,
      type: transaction.type,
      amount: transaction.amount,
      categoryId: transaction.categoryId,
      accountId: transaction.accountId,
      destinationAccountId: transaction.destinationAccountId,
      transactionDate: transaction.transactionDate,
      time: transaction.time,
      note: transaction.note,
      paymentMethod: transaction.paymentMethod,
      recurringRuleId: transaction.recurringRuleId,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
      deletedAt: transaction.deletedAt,
    );
  }

  TransactionsCompanion _mapToCompanion(TransactionEntity entity) {
    return TransactionsCompanion(
      id: Value(entity.id),
      type: Value(entity.type),
      amount: Value(entity.amount),
      categoryId: Value(entity.categoryId),
      accountId: Value(entity.accountId),
      destinationAccountId: Value(entity.destinationAccountId),
      transactionDate: Value(entity.transactionDate),
      time: Value(entity.time),
      note: Value(entity.note),
      paymentMethod: Value(entity.paymentMethod),
      recurringRuleId: Value(entity.recurringRuleId),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
      deletedAt: Value(entity.deletedAt),
    );
  }

  @override
  Future<List<TransactionEntity>> getAllTransactions() async {
    final query = _db.select(_db.transactions)..where((tbl) => tbl.deletedAt.isNull());
    final txns = await query.get();
    return txns.map(_mapToEntity).toList();
  }

  @override
  Future<TransactionEntity?> getTransactionById(String id) async {
    final txn = await (_db.select(_db.transactions)
          ..where((tbl) => tbl.id.equals(id))
          ..where((tbl) => tbl.deletedAt.isNull()))
        .getSingleOrNull();
    return txn != null ? _mapToEntity(txn) : null;
  }

  @override
  Future<void> createTransaction(TransactionEntity transaction) =>
      _db.into(_db.transactions).insert(_mapToCompanion(transaction));

  @override
  Future<void> updateTransaction(TransactionEntity transaction) =>
      _db.update(_db.transactions).replace(_mapToCompanion(transaction));

  @override
  Future<void> deleteTransaction(String id) async {
    await (_db.update(_db.transactions)..where((tbl) => tbl.id.equals(id)))
        .write(TransactionsCompanion(deletedAt: Value(DateTime.now())));
  }

  @override
  Future<int> getSumOfTransactionsByType(String type) async {
    final amountSum = _db.transactions.amount.sum();
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([amountSum])
      ..where(_db.transactions.type.equals(type))
      ..where(_db.transactions.deletedAt.isNull());

    final result = await query.map((row) => row.read(amountSum)).getSingle();
    return result ?? 0;
  }

  @override
  Future<List<TransactionEntity>> getTransactionsBetweenDates(DateTime start, DateTime end) async {
    final query = _db.select(_db.transactions)
      ..where((tbl) => tbl.transactionDate.isBetweenValues(start, end))
      ..where((tbl) => tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.transactionDate)]);
    final txns = await query.get();
    return txns.map(_mapToEntity).toList();
  }

  @override
  Future<List<TransactionEntity>> getTransactionsByAccount(String accountId) async {
    final query = _db.select(_db.transactions)
      ..where((tbl) => tbl.accountId.equals(accountId) | tbl.destinationAccountId.equals(accountId))
      ..where((tbl) => tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.transactionDate)]);
    final txns = await query.get();
    return txns.map(_mapToEntity).toList();
  }

  @override
  Future<List<TransactionEntity>> getTransactionsByCategory(String categoryId) async {
    final query = _db.select(_db.transactions)
      ..where((tbl) => tbl.categoryId.equals(categoryId))
      ..where((tbl) => tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.transactionDate)]);
    final txns = await query.get();
    return txns.map(_mapToEntity).toList();
  }

  @override
  Future<int> getSumOfTransactionsByTypeAndDate(String type, DateTime start, DateTime end) async {
    final amountSum = _db.transactions.amount.sum();
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([amountSum])
      ..where(_db.transactions.type.equals(type))
      ..where(_db.transactions.transactionDate.isBetweenValues(start, end))
      ..where(_db.transactions.deletedAt.isNull());

    final result = await query.map((row) => row.read(amountSum)).getSingle();
    return result ?? 0;
  }

  @override
  Future<int> getSumOfTransactionsByCategoryAndDate(String categoryId, DateTime start, DateTime end) async {
    final amountSum = _db.transactions.amount.sum();
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([amountSum])
      ..where(_db.transactions.type.equals('expense')) // Usually categories are expenses
      ..where(_db.transactions.categoryId.equals(categoryId))
      ..where(_db.transactions.transactionDate.isBetweenValues(start, end))
      ..where(_db.transactions.deletedAt.isNull());

    final result = await query.map((row) => row.read(amountSum)).getSingle();
    return result ?? 0;
  }

  @override
  Future<int> getAccountBalanceOffset(String accountId) async {
    // 1. Calculate Income (added to account)
    final incSum = _db.transactions.amount.sum();
    var q = _db.selectOnly(_db.transactions)
      ..addColumns([incSum])
      ..where(_db.transactions.accountId.equals(accountId))
      ..where(_db.transactions.type.equals('income'))
      ..where(_db.transactions.deletedAt.isNull());
    final income = (await q.map((r) => r.read(incSum)).getSingle()) ?? 0;

    // 2. Calculate Expense (deducted from account)
    final expSum = _db.transactions.amount.sum();
    q = _db.selectOnly(_db.transactions)
      ..addColumns([expSum])
      ..where(_db.transactions.accountId.equals(accountId))
      ..where(_db.transactions.type.equals('expense'))
      ..where(_db.transactions.deletedAt.isNull());
    final expense = (await q.map((r) => r.read(expSum)).getSingle()) ?? 0;

    // 3. Calculate Transfers IN (added to account)
    final tInSum = _db.transactions.amount.sum();
    q = _db.selectOnly(_db.transactions)
      ..addColumns([tInSum])
      ..where(_db.transactions.destinationAccountId.equals(accountId))
      ..where(_db.transactions.type.equals('transfer'))
      ..where(_db.transactions.deletedAt.isNull());
    final transferIn = (await q.map((r) => r.read(tInSum)).getSingle()) ?? 0;

    // 4. Calculate Transfers OUT (deducted from account)
    final tOutSum = _db.transactions.amount.sum();
    q = _db.selectOnly(_db.transactions)
      ..addColumns([tOutSum])
      ..where(_db.transactions.accountId.equals(accountId))
      ..where(_db.transactions.type.equals('transfer'))
      ..where(_db.transactions.deletedAt.isNull());
    final transferOut = (await q.map((r) => r.read(tOutSum)).getSingle()) ?? 0;

    return income - expense + transferIn - transferOut;
  }
}
