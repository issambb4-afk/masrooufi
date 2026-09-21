import 'get_monthly_summary.dart';

class GetSavingsRateUseCase {
  final GetMonthlySummaryUseCase _getMonthlySummaryUseCase;

  GetSavingsRateUseCase(this._getMonthlySummaryUseCase);

  Future<double?> execute(int year, int month) async {
    final summary = await _getMonthlySummaryUseCase.execute(year, month);
    if (summary.income == 0) return null;
    return (summary.net / summary.income) * 100;
  }
}
