import '../entities/transaction.dart';

abstract class TransactionRepository {
  Future<List<TransactionEntity>> getAllTransactions();
  Future<TransactionEntity?> getTransactionById(String id);
  Future<void> createTransaction(TransactionEntity transaction);
  Future<void> updateTransaction(TransactionEntity transaction);
  Future<void> deleteTransaction(String id); // soft delete
  Future<int> getSumOfTransactionsByType(String type);
}
