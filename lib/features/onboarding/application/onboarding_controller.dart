import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/injection.dart';
import '../../../data/services/preferences_service.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/budget.dart';
import '../../../domain/repositories/account_repository.dart';
import '../../../domain/repositories/budget_repository.dart';

class OnboardingState {
  final int currentStep;
  final String selectedCurrency;
  final String accountName;
  final double initialBalance;
  final double budgetAmount;
  final bool isSubmitting;
  final String? error;

  OnboardingState({
    this.currentStep = 0,
    this.selectedCurrency = 'TND',
    this.accountName = '',
    this.initialBalance = 0.0,
    this.budgetAmount = 0.0,
    this.isSubmitting = false,
    this.error,
  });

  OnboardingState copyWith({
    int? currentStep,
    String? selectedCurrency,
    String? accountName,
    double? initialBalance,
    double? budgetAmount,
    bool? isSubmitting,
    String? error,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      accountName: accountName ?? this.accountName,
      initialBalance: initialBalance ?? this.initialBalance,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error, // Can be null
    );
  }
}

class OnboardingController extends Notifier<OnboardingState> {
  PreferencesService? _prefs;
  AccountRepository? _accountRepo;
  BudgetRepository? _budgetRepo;

  @override
  OnboardingState build() {
    return OnboardingState();
  }

  PreferencesService get prefs => _prefs ?? sl<PreferencesService>();
  AccountRepository get accountRepo => _accountRepo ?? sl<AccountRepository>();
  BudgetRepository get budgetRepo => _budgetRepo ?? sl<BudgetRepository>();

  // Exposed for tests overrides if needed
  void injectDependencies(PreferencesService prefs, AccountRepository accountRepo, BudgetRepository budgetRepo) {
    _prefs = prefs;
    _accountRepo = accountRepo;
    _budgetRepo = budgetRepo;
  }

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void setCurrency(String currency) {
    state = state.copyWith(selectedCurrency: currency);
  }

  void setAccountDetails(String name, double balance) {
    state = state.copyWith(accountName: name, initialBalance: balance);
  }

  void setBudget(double budget) {
    state = state.copyWith(budgetAmount: budget);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      await prefs.setDefaultCurrency(state.selectedCurrency);

      int minorUnitsBalance = 0;
      int minorUnitsBudget = 0;
      if (state.selectedCurrency == 'TND') {
        minorUnitsBalance = (state.initialBalance * 1000).round();
        minorUnitsBudget = (state.budgetAmount * 1000).round();
      } else {
        minorUnitsBalance = (state.initialBalance * 100).round();
        minorUnitsBudget = (state.budgetAmount * 100).round();
      }

      final account = AccountEntity(
        id: const Uuid().v4(),
        name: state.accountName.isEmpty ? 'Main Account' : state.accountName,
        type: 'bank',
        currency: state.selectedCurrency,
        openingBalance: minorUnitsBalance,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await accountRepo.createAccount(account);

      if (state.budgetAmount > 0) {
        final now = DateTime.now();
        final budget = BudgetEntity(
          id: const Uuid().v4(),
          period: '${now.year}-${now.month.toString().padLeft(2, '0')}',
          type: 'global',
          amount: minorUnitsBudget,
          currency: state.selectedCurrency,
          createdAt: now,
          updatedAt: now,
        );
        await budgetRepo.createBudget(budget);
      }

      await prefs.setHasCompletedOnboarding(true);

      state = state.copyWith(isSubmitting: false);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }
}

final onboardingControllerProvider = NotifierProvider<OnboardingController, OnboardingState>(() {
  return OnboardingController();
});
