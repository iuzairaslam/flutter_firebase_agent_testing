import 'package:yaml/yaml.dart';

import '../models/app_agent_test_case.dart';
import '../models/app_agent_test_step.dart';

/// Encode/decode Firebase App Testing Agent YAML test files.
class AppAgentYamlCodec {
  const AppAgentYamlCodec();

  /// Serializes [testCase] to YAML text. Calls [testCase.validate] when [validate] is true.
  String encode(AppAgentTestCase testCase, {bool validate = true}) {
    if (validate) testCase.validate();
    final buf = StringBuffer();
    buf.writeln('displayName: ${_yamlQuoted(testCase.displayName.trim())}');

    final devices = testCase.devices;
    if (devices != null && devices.isNotEmpty) {
      buf.writeln('devices:');
      for (final d in devices) {
        final t = d.trim();
        if (t.isNotEmpty) buf.writeln('  - $t');
      }
    }

    buf.writeln('steps:');
    for (final step in testCase.validSteps) {
      buf.writeln('  - goal: ${_yamlQuoted(step.goal.trim())}');
      final hint = step.hint?.trim();
      if (hint != null && hint.isNotEmpty) {
        buf.writeln('    hint: ${_yamlQuoted(hint)}');
      }
      final assertion = step.assertion?.trim();
      if (assertion != null && assertion.isNotEmpty) {
        buf.writeln('    assertion: ${_yamlQuoted(assertion)}');
      }
    }
    return buf.toString();
  }

  /// Parses YAML document into [AppAgentTestCase]. [filename] is stored on the result only.
  AppAgentTestCase decode(String yamlText, {String? filename}) {
    final dynamic root = loadYaml(yamlText);
    if (root is! YamlMap) {
      throw FormatException('Root YAML must be a map');
    }

    final name = root['displayName'];
    if (name is! String || name.trim().isEmpty) {
      throw FormatException('Missing or invalid displayName');
    }

    List<String>? devices;
    final devNode = root['devices'];
    if (devNode != null) {
      if (devNode is! YamlList) {
        throw FormatException('devices must be a list');
      }
      devices = devNode.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
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
        final assertion =
            item['assertion'] is String ? item['assertion'] as String : null;
        steps.add(AppAgentTestStep(goal: goal, hint: hint, assertion: assertion));
      } else if (item is String) {
        steps.add(AppAgentTestStep(goal: item));
      }
    }

    return AppAgentTestCase(
      displayName: name.trim(),
      devices: devices,
      steps: steps,
      filename: filename,
    );
  }

  static String _yamlQuoted(String s) {
    final escaped = s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    return '"$escaped"';
  }
}
