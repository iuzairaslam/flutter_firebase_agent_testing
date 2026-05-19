import 'package:meta/meta.dart';

import 'app_agent_test_step.dart';

/// A full YAML test file: [displayName], optional [devices], and [steps].
@immutable
class AppAgentTestCase {
  const AppAgentTestCase({
    required this.displayName,
    required this.steps,
    this.devices,
    this.filename,
  });

  final String displayName;

  /// Device spec strings, e.g. `model=Pixel6,version=33,locale=en,orientation=portrait`.
  final List<String>? devices;

  final List<AppAgentTestStep> steps;

  /// Suggested filename when writing to disk (e.g. `login_flow.yaml`).
  final String? filename;

  List<AppAgentTestStep> get validSteps =>
      steps.where((s) => s.isValid).toList(growable: false);

  AppAgentTestCase copyWith({
    String? displayName,
    List<String>? devices,
    List<AppAgentTestStep>? steps,
    String? filename,
    bool clearDevices = false,
    bool clearFilename = false,
  }) {
    return AppAgentTestCase(
      displayName: displayName ?? this.displayName,
      devices: clearDevices ? null : (devices ?? this.devices),
      steps: steps ?? this.steps,
      filename: clearFilename ? null : (filename ?? this.filename),
    );
  }

  /// Throws [StateError] if [displayName] is blank or there are no valid steps.
  void validate() {
    if (displayName.trim().isEmpty) {
      throw StateError('displayName must not be empty');
    }
    if (validSteps.isEmpty) {
      throw StateError('At least one step with a non-empty goal is required');
    }
  }
}
