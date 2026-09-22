import '../repositories/transaction_repository.dart';

class MonthlySummary {
  final int income;
  final int expense;
  int get net => income - expense;

  const MonthlySummary({required this.income, required this.expense});
}

class GetMonthlySummaryUseCase {
  final TransactionRepository _transactionRepo;

  GetMonthlySummaryUseCase(this._transactionRepo);

  Future<MonthlySummary> execute(int year, int month) async {
    final startOfMonth = DateTime(year, month, 1);
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    final endOfMonth = DateTime(nextYear, nextMonth, 1).subtract(const Duration(milliseconds: 1));

    final income = await _transactionRepo.getSumOfTransactionsByTypeAndDate('income', startOfMonth, endOfMonth);
    final expense = await _transactionRepo.getSumOfTransactionsByTypeAndDate('expense', startOfMonth, endOfMonth);

    return MonthlySummary(income: income, expense: expense);
  }
}
