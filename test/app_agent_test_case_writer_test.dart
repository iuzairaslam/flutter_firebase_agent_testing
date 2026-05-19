import 'dart:io';

import 'package:flutter_firebase_agent_testing/flutter_firebase_agent_testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('write creates yaml file', () async {
    final dir = await Directory.systemTemp.createTemp('agent_tests_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    const tc = AppAgentTestCase(
      displayName: 'Smoke',
      filename: 'smoke.yaml',
      steps: [AppAgentTestStep(goal: 'Launch app')],
    );

    final file = await AppAgentTestCaseWriter().write(
      testCase: tc,
      testsDirectory: dir.path,
    );

    expect(await file.exists(), isTrue);
    expect(p.basename(file.path), 'smoke.yaml');
    final body = await file.readAsString();
    expect(body, contains('displayName: "Smoke"'));
    expect(body, contains('goal: "Launch app"'));
  });
}
