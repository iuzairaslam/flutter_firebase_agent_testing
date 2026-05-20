import 'package:firebase_agent_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home shows welcome and entry buttons', (tester) async {
    await tester.pumpWidget(const FirebaseAgentExampleApp());
    expect(find.text('Welcome to the Agent Demo'), findsOneWidget);
    expect(find.text('Open Counter'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });

  testWidgets('counter increments and resets', (tester) async {
    await tester.pumpWidget(const FirebaseAgentExampleApp());
    await tester.tap(find.byKey(const Key('btn_open_counter')));
    await tester.pumpAndSettle();

    expect(find.text('Counter: 0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_increment')));
    await tester.tap(find.byKey(const Key('btn_increment')));
    await tester.pump();
    expect(find.text('Counter: 2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_reset')));
    await tester.pump();
    expect(find.text('Counter: 0'), findsOneWidget);
  });

  testWidgets('sign up form shows welcome on submit', (tester) async {
    await tester.pumpWidget(const FirebaseAgentExampleApp());
    await tester.tap(find.byKey(const Key('btn_open_signup')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('field_name')), 'Test User');
    await tester.enterText(
      find.byKey(const Key('field_email')),
      'test@example.com',
    );
    await tester.tap(find.byKey(const Key('btn_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Welcome, Test User!'), findsOneWidget);
  });
}
