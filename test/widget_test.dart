import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masrooufi/main.dart';
import 'package:masrooufi/shared/widgets/application_shell.dart';

void main() {
  testWidgets('App launches and displays the application shell', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MasrooufiApp()));
    // Wait for the initial routing to complete and animations to settle
    await tester.pumpAndSettle();

    // The home screen should be visible inside the application shell
    expect(find.byType(ApplicationShell), findsOneWidget);
    expect(find.text('Home Dashboard'), findsOneWidget);

    // Verify Bottom Navigation items exist (Home, Transactions, Reports, Settings)
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.list), findsOneWidget);
    expect(find.byIcon(Icons.pie_chart), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);

    // Verify FAB
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
