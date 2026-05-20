import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/app_agent_test_case.dart';
import '../yaml/app_agent_yaml_codec.dart';

/// Writes [AppAgentTestCase] files to a directory (e.g. repo `tests/`).
class AppAgentTestCaseWriter {
  AppAgentTestCaseWriter({
    AppAgentYamlCodec codec = const AppAgentYamlCodec(),
  }) : _codec = codec;

  final AppAgentYamlCodec _codec;

  /// Returns the path written. Uses [testCase.filename] or derives from [displayName].
  Future<File> write({
    required AppAgentTestCase testCase,
    required String testsDirectory,
    bool validate = true,
  }) async {
    testCase.validate();
    final name = testCase.filename?.trim().isNotEmpty == true
        ? testCase.filename!.trim()
        : _defaultFileName(testCase.displayName);
    final dir = Directory(testsDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file =
        File(p.join(dir.path, name.endsWith('.yaml') ? name : '$name.yaml'));
    await file.writeAsString(_codec.encode(testCase, validate: validate));
    return file;
  }

  static String _defaultFileName(String displayName) {
    final slug = displayName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return '${slug.isEmpty ? 'test_case' : slug}.yaml';
  }
}
