import 'package:flutter_firebase_agent_testing/flutter_firebase_agent_testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const codec = AppAgentYamlCodec();

  test('encode then decode round-trip', () {
    const original = AppAgentTestCase(
      displayName: 'Login Flow',
      id: 'login',
      filename: 'login.yaml',
      steps: [
        AppAgentTestStep(goal: 'Open login'),
        AppAgentTestStep(
          goal: 'Sign in',
          hint: 'Dismiss keyboard first',
        ),
        AppAgentTestStep(
          goal: 'See home',
          assertion: 'User name visible',
        ),
      ],
    );

    final yaml = codec.encode(original);
    expect(yaml, contains('tests:'));
    expect(yaml, contains('displayName: Login Flow'));
    expect(yaml, contains('id: login'));
    expect(yaml, contains('finalScreenAssertion: User name visible'));

    final parsed = codec.decode(yaml, filename: 'login.yaml');
    expect(parsed.displayName, 'Login Flow');
    expect(parsed.id, 'login');
    expect(parsed.validSteps.length, 3);
    expect(parsed.validSteps[1].hint, 'Dismiss keyboard first');
  });

  test('validate rejects empty steps', () {
    const bad = AppAgentTestCase(displayName: 'X', steps: []);
    expect(() => codec.encode(bad), throwsStateError);
  });

  test('GitHubActionsWorkflowConfig generates jobs block', () {
    const cfg = GitHubActionsWorkflowConfig(
      workflowName: 'Firebase App Testing Agent CI',
      firebaseProjectIdForConsoleLink: 'my-project',
      emailTo: 'a@b.com',
      emailFromDisplayName: 'CI Bot',
      includeEmailStep: false,
      includeArtifactUpload: false,
    );
    final y = cfg.generateYaml();
    expect(y, contains('name: Firebase App Testing Agent CI'));
    expect(y, contains('firebase apptesting:execute'));
    expect(y, contains('--test-dir=./tests'));
    expect(y, isNot(contains('Send Email Report')));
  });
}
