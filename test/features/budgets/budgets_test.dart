import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masrooufi/core/di/injection.dart';
import 'package:masrooufi/domain/entities/budget.dart';
import 'package:masrooufi/domain/repositories/budget_repository.dart';
import 'package:masrooufi/features/budgets/application/budget_form_controller.dart';

class MockBudgetRepository implements BudgetRepository {
  final List<BudgetEntity> budgets = [];
  @override Future<void> createBudget(BudgetEntity budget) async { budgets.add(budget); }
  @override Future<void> deleteBudget(String id) async { budgets.removeWhere((b) => b.id == id); }
  @override Future<List<BudgetEntity>> getAllBudgets() async => budgets;
  @override Future<BudgetEntity?> getBudgetById(String id) async => null;
  @override Future<void> updateBudget(BudgetEntity budget) async {}
}

void main() {
  late ProviderContainer container;
  late MockBudgetRepository repo;

  setUp(() async {
    repo = MockBudgetRepository();
    await sl.reset();
    sl.registerLazySingleton<BudgetRepository>(() => repo);

    container = ProviderContainer(
      overrides: [
        budgetFormControllerProvider.overrideWith(() => BudgetFormController()..injectDependencies(repo)),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('BudgetFormController ensures category is set for category budgets', () async {
    final controller = container.read(budgetFormControllerProvider.notifier);
    controller.setType('category');
    controller.setAmount(100);
    final res = await controller.saveBudget();
    expect(res, isFalse);
    expect(container.read(budgetFormControllerProvider).error, 'Category must be selected');
  });

  test('BudgetFormController creates budget matching minor units', () async {
    final controller = container.read(budgetFormControllerProvider.notifier);
    controller.setAmount(500); // 500 TND
    final res = await controller.saveBudget();
    expect(res, isTrue);
    expect(repo.budgets.length, 1);
    expect(repo.budgets.first.amount, 500000);
  });
}
