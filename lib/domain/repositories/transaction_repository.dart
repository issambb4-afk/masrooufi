import '../entities/transaction.dart';

abstract class TransactionRepository {
  Future<List<TransactionEntity>> getAllTransactions();
  Future<TransactionEntity?> getTransactionById(String id);
  Future<void> createTransaction(TransactionEntity transaction);
  Future<void> updateTransaction(TransactionEntity transaction);
  Future<void> deleteTransaction(String id); // soft delete
  Future<int> getSumOfTransactionsByType(String type);

  // Phase 3 requirements
  Future<List<TransactionEntity>> getTransactionsBetweenDates(DateTime start, DateTime end);
  Future<List<TransactionEntity>> getTransactionsByAccount(String accountId);
  Future<List<TransactionEntity>> getTransactionsByCategory(String categoryId);
  Future<int> getSumOfTransactionsByTypeAndDate(String type, DateTime start, DateTime end);
  Future<int> getSumOfTransactionsByCategoryAndDate(String categoryId, DateTime start, DateTime end);
}
