import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: notifier.setStep,
                children: [
                  _WelcomeStep(onNext: _nextPage),
                  _CurrencyStep(onNext: _nextPage),
                  _AccountStep(onNext: _nextPage),
                  _BudgetStep(
                    onComplete: () async {
                      await notifier.completeOnboarding();
                      final currentState = ref.read(onboardingControllerProvider);
                      if (mounted && currentState.error == null) {
                        context.go('/home');
                      } else if (mounted && currentState.error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(currentState.error!)),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomeStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Welcome to Masrooufi',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'The simplest way to manage your personal finances offline.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onNext,
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }
}

class _CurrencyStep extends ConsumerWidget {
  final VoidCallback onNext;
  const _CurrencyStep({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);

    final currencies = ['TND', 'USD', 'EUR', 'GBP'];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Select your currency',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ...currencies.map((c) => RadioListTile<String>(
            title: Text(c),
            value: c,
            groupValue: state.selectedCurrency,
            onChanged: (val) {
              if (val != null) notifier.setCurrency(val);
            },
          )),
          const Spacer(),
          ElevatedButton(
            onPressed: onNext,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _AccountStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const _AccountStep({required this.onNext});

  @override
  ConsumerState<_AccountStep> createState() => _AccountStepState();
}

class _AccountStepState extends ConsumerState<_AccountStep> {
  final _nameController = TextEditingController(text: 'Main Account');
  final _balanceController = TextEditingController(text: '0');

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create your first account',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Account Name'),
            onChanged: (val) => notifier.setAccountDetails(
              val,
              double.tryParse(_balanceController.text) ?? 0,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _balanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Initial Balance',
              suffixText: state.selectedCurrency,
            ),
            onChanged: (val) => notifier.setAccountDetails(
              _nameController.text,
              double.tryParse(val) ?? 0,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: widget.onNext,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _BudgetStep extends ConsumerStatefulWidget {
  final VoidCallback onComplete;
  const _BudgetStep({required this.onComplete});

  @override
  ConsumerState<_BudgetStep> createState() => _BudgetStepState();
}

class _BudgetStepState extends ConsumerState<_BudgetStep> {
  final _budgetController = TextEditingController(text: '0');

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Set a monthly budget (Optional)',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'You can leave this at 0 if you do not want to set a budget right now.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _budgetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Monthly Budget',
              suffixText: state.selectedCurrency,
            ),
            onChanged: (val) => notifier.setBudget(
              double.tryParse(val) ?? 0,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: state.isSubmitting ? null : widget.onComplete,
            child: state.isSubmitting
                ? const CircularProgressIndicator()
                : const Text('Finish Setup'),
          ),
        ],
      ),
    );
  }
}
