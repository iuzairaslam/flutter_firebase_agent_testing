import 'package:meta/meta.dart';

import 'app_agent_test_step.dart';

/// A full YAML test file: [displayName], optional [devices], and [steps].
@immutable
class AppAgentTestCase {
  const AppAgentTestCase({
    required this.displayName,
    required this.steps,
    this.id,
    this.prerequisiteTestCaseId,
    this.devices,
    this.filename,
  });

  final String displayName;

  /// Stable id for Firebase YAML (used for prerequisiteTestCaseId links).
  final String? id;

  final String? prerequisiteTestCaseId;

  /// Device spec strings — use CLI `--test-devices`; not written to Firebase YAML.
  final List<String>? devices;

  final List<AppAgentTestStep> steps;

  /// Suggested filename when writing to disk (e.g. `login_flow.yaml`).
  final String? filename;

  List<AppAgentTestStep> get validSteps =>
      steps.where((s) => s.isValid).toList(growable: false);

  AppAgentTestCase copyWith({
    String? displayName,
    String? id,
    String? prerequisiteTestCaseId,
    List<String>? devices,
    List<AppAgentTestStep>? steps,
    String? filename,
    bool clearDevices = false,
    bool clearFilename = false,
    bool clearPrerequisite = false,
  }) {
    return AppAgentTestCase(
      displayName: displayName ?? this.displayName,
      id: id ?? this.id,
      prerequisiteTestCaseId: clearPrerequisite
          ? null
          : (prerequisiteTestCaseId ?? this.prerequisiteTestCaseId),
      devices: clearDevices ? null : (devices ?? this.devices),
      steps: steps ?? this.steps,
      filename: clearFilename ? null : (filename ?? this.filename),
    );
  }

  /// Firebase CLI requires an `id` per test case when using prerequisites.
  String resolveId() {
    if (id != null && id!.trim().isNotEmpty) return id!.trim();
    if (filename != null && filename!.trim().isNotEmpty) {
      final base = filename!.replaceAll(RegExp(r'\.ya?ml$'), '');
      if (base.isNotEmpty) return base;
    }
    return displayName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  void validate() {
    if (displayName.trim().isEmpty) {
      throw StateError('displayName must not be empty');
    }
    if (validSteps.isEmpty) {
      throw StateError('At least one step with a non-empty goal is required');
    }
  }
}
