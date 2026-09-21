import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masrooufi/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MasrooufiApp()));
    // The first frame
    await tester.pumpAndSettle();

    // We expect the app title somewhere. However, with localization we have to be careful.
    // By default it should show "Dashboard" because it falls back to EN/fr/ar or something.
    expect(find.text('Masrooufi'), findsOneWidget);
  });
}
