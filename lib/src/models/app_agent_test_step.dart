import 'package:meta/meta.dart';

/// One natural-language step for the App Testing Agent.
@immutable
class AppAgentTestStep {
  const AppAgentTestStep({
    required this.goal,
    this.hint,
    this.assertion,
  });

  /// What the agent should try to accomplish.
  final String goal;

  /// Optional guidance (e.g. dismiss keyboard, alternate path).
  final String? hint;

  /// Optional expected outcome description.
  final String? assertion;

  AppAgentTestStep copyWith({
    String? goal,
    String? hint,
    String? assertion,
    bool clearHint = false,
    bool clearAssertion = false,
  }) {
    return AppAgentTestStep(
      goal: goal ?? this.goal,
      hint: clearHint ? null : (hint ?? this.hint),
      assertion: clearAssertion ? null : (assertion ?? this.assertion),
    );
  }

  /// Validates non-empty goal after trim.
  bool get isValid => goal.trim().isNotEmpty;
}
