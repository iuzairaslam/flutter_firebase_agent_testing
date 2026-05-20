import 'dart:io';

import 'package:flutter_firebase_agent_testing/flutter_firebase_agent_testing.dart';

Future<void> main() async {
  const codec = AppAgentYamlCodec();
  final writer = AppAgentTestCaseWriter(codec: codec);
  for (final tc in RecommendedAppAgentTestTemplates.all()) {
    await writer.write(testCase: tc, testsDirectory: 'example/tests');
    stdout.writeln('wrote ${tc.filename}');
  }
}
