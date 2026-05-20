import 'package:yaml/yaml.dart';

import '../models/app_agent_test_case.dart';
import '../models/app_agent_test_step.dart';

/// Encode/decode Firebase App Testing Agent YAML test files.
///
/// Format matches Firebase docs:
/// https://firebase.google.com/docs/app-distribution/android/app-testing-agent
class AppAgentYamlCodec {
  const AppAgentYamlCodec();

  /// Serializes [testCase] to Firebase-compatible YAML.
  String encode(AppAgentTestCase testCase, {bool validate = true}) {
    if (validate) testCase.validate();
    final buf = StringBuffer('tests:\n');
    _writeTestCase(buf, testCase);
    return buf.toString();
  }

  void _writeTestCase(StringBuffer buf, AppAgentTestCase testCase) {
    buf.writeln('- displayName: ${_yamlScalar(testCase.displayName.trim())}');
    buf.writeln('  id: ${testCase.resolveId()}');

    final prereq = testCase.prerequisiteTestCaseId?.trim();
    if (prereq != null && prereq.isNotEmpty) {
      buf.writeln('  prerequisiteTestCaseId: $prereq');
    }

    buf.writeln('  steps:');
    for (final step in testCase.validSteps) {
      buf.writeln('  - goal: ${_yamlScalar(step.goal.trim())}');
      final hint = step.hint?.trim();
      if (hint != null && hint.isNotEmpty) {
        buf.writeln('    hint: ${_yamlScalar(hint)}');
      }
      final assertion = step.assertion?.trim();
      if (assertion != null && assertion.isNotEmpty) {
        buf.writeln('    finalScreenAssertion: ${_yamlScalar(assertion)}');
      }
    }
  }

  /// Parses YAML into [AppAgentTestCase] (first entry when file uses `tests:` array).
  AppAgentTestCase decode(String yamlText, {String? filename}) {
    final dynamic root = loadYaml(yamlText);
    if (root is! YamlMap) {
      throw FormatException('Root YAML must be a map');
    }

    final YamlMap testMap;
    if (root['tests'] is YamlList) {
      final list = root['tests'] as YamlList;
      if (list.isEmpty) {
        throw FormatException('tests array must not be empty');
      }
      final first = list.first;
      if (first is! YamlMap) {
        throw FormatException('Each test entry must be a map');
      }
      testMap = first;
    } else {
      testMap = root;
    }

    return _parseTestCaseMap(testMap, filename: filename);
  }

  AppAgentTestCase _parseTestCaseMap(YamlMap root, {String? filename}) {
    final name = root['displayName'];
    if (name is! String || name.trim().isEmpty) {
      throw FormatException('Missing or invalid displayName');
    }

    final id = root['id'] is String ? root['id'] as String : null;
    final prereq = root['prerequisiteTestCaseId'] is String
        ? root['prerequisiteTestCaseId'] as String
        : null;

    List<String>? devices;
    final devNode = root['devices'];
    if (devNode is YamlList) {
      devices = devNode
          .map((e) => e.toString())
          .where((s) => s.trim().isNotEmpty)
          .toList();
      if (devices.isEmpty) devices = null;
    }

    final stepsNode = root['steps'];
    if (stepsNode is! YamlList) {
      throw FormatException('steps must be a list');
    }

    final steps = <AppAgentTestStep>[];
    for (final item in stepsNode) {
      if (item is YamlMap) {
        final goal = item['goal'];
        if (goal is! String) continue;
        final hint = item['hint'] is String ? item['hint'] as String : null;
        final assertion = item['finalScreenAssertion'] is String
            ? item['finalScreenAssertion'] as String
            : item['assertion'] is String
                ? item['assertion'] as String
                : null;
        steps.add(
            AppAgentTestStep(goal: goal, hint: hint, assertion: assertion));
      } else if (item is String) {
        steps.add(AppAgentTestStep(goal: item));
      }
    }

    return AppAgentTestCase(
      displayName: name.trim(),
      id: id,
      prerequisiteTestCaseId: prereq,
      devices: devices,
      steps: steps,
      filename: filename,
    );
  }

  /// Plain scalar when safe; double-quoted when needed.
  static String _yamlScalar(String s) {
    if (s.isEmpty) return '""';
    if (RegExp(r'^[a-zA-Z0-9 _./-]+$').hasMatch(s)) return s;
    final escaped = s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    return '"$escaped"';
  }
}
