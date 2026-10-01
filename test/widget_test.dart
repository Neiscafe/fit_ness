import 'package:fit_ness/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GymApp builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GymApp()));
    await tester.pump();

    expect(find.textContaining('NESS'), findsOneWidget);
  });
}
