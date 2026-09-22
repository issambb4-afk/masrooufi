import '../repositories/transaction_repository.dart';

class GetCategoryTotalsUseCase {
  final TransactionRepository _transactionRepo;

  GetCategoryTotalsUseCase(this._transactionRepo);

  Future<int> execute(String categoryId, DateTime start, DateTime end) async {
    return _transactionRepo.getSumOfTransactionsByCategoryAndDate(categoryId, start, end);
  }
}
