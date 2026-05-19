import 'package:flutter_test/flutter_test.dart';

import 'package:firebase_agent_example/main.dart';

void main() {
  testWidgets('home shows Android-only hint', (WidgetTester tester) async {
    await tester.pumpWidget(const FirebaseAgentExampleApp());
    expect(find.textContaining('Android only'), findsOneWidget);
    expect(find.textContaining('firebase_agent_ci'), findsOneWidget);
  });
}
