import '../repositories/transaction_repository.dart';

class DailySummary {
  final int income;
  final int expense;
  int get net => income - expense;

  const DailySummary({required this.income, required this.expense});
}

class GetDailySummaryUseCase {
  final TransactionRepository _transactionRepo;

  GetDailySummaryUseCase(this._transactionRepo);

  Future<DailySummary> execute(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    final income = await _transactionRepo.getSumOfTransactionsByTypeAndDate('income', startOfDay, endOfDay);
    final expense = await _transactionRepo.getSumOfTransactionsByTypeAndDate('expense', startOfDay, endOfDay);

    return DailySummary(income: income, expense: expense);
  }
}
