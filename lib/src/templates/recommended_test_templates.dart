import '../models/app_agent_test_case.dart';
import '../models/app_agent_test_step.dart';

/// Suggested [AppAgentTestCase] instances aligned with Firebase App Testing Agent guides.
abstract final class RecommendedAppAgentTestTemplates {
  static AppAgentTestCase locationPermissionFlow({
    List<String>? devices,
  }) {
    return AppAgentTestCase(
      displayName: 'Location Permission Flow',
      filename: 'location_permission_flow.yaml',
      devices: devices,
      steps: const [
        AppAgentTestStep(
          goal: 'Open the app and navigate to the location permission screen',
        ),
        AppAgentTestStep(
          goal: 'Tap Allow on the location permission dialog',
          hint:
              'If the system dialog does not appear, tap Enable Location button first',
        ),
        AppAgentTestStep(
          goal: 'Verify the main map view loads with a location pin',
          assertion: 'The map screen should be visible and show user location',
        ),
      ],
    );
  }

  static AppAgentTestCase onboardingSmoke({List<String>? devices}) {
    return AppAgentTestCase(
      displayName: 'Onboarding Smoke Test',
      filename: 'onboarding_smoke.yaml',
      devices: devices,
      steps: const [
        AppAgentTestStep(
          goal:
              'Launch the app from cold start and verify splash screen appears',
        ),
        AppAgentTestStep(
          goal:
              'Complete the onboarding flow by tapping through all intro screens',
          hint: 'Swipe left or tap Next to advance each onboarding slide',
        ),
        AppAgentTestStep(
          goal: 'Verify the Get Started or Sign In screen is shown at the end',
          assertion: 'A login or registration option should be visible',
        ),
      ],
    );
  }

  static AppAgentTestCase coreNavigation({List<String>? devices}) {
    return AppAgentTestCase(
      displayName: 'Core Navigation Test',
      filename: 'core_navigation.yaml',
      devices: devices,
      steps: const [
        AppAgentTestStep(
          goal: 'Navigate to each main tab in the bottom navigation bar',
        ),
        AppAgentTestStep(
          goal: 'Open the Settings or Profile screen',
          assertion: 'Settings screen should load without crashing',
        ),
        AppAgentTestStep(
          goal: 'Navigate back to the home screen using back button or tab',
          assertion: 'Home screen should be visible and functional',
        ),
      ],
    );
  }

  static AppAgentTestCase crashRegression({List<String>? devices}) {
    return AppAgentTestCase(
      displayName: 'Crash Regression Test',
      filename: 'crash_regression.yaml',
      devices: devices,
      steps: const [
        AppAgentTestStep(
          goal: 'Rapidly switch between all main screens multiple times',
          hint: 'Tap each bottom tab 3 times quickly then move to next',
        ),
        AppAgentTestStep(
          goal:
              'Attempt to perform the main app action without granting permissions',
          assertion: 'App should show an error message, not crash',
        ),
        AppAgentTestStep(
          goal: 'Put the app in background for 5 seconds then foreground it',
          assertion:
              'App should resume correctly without any crash or blank screen',
        ),
      ],
    );
  }

  static AppAgentTestCase exampleAppSmoke() {
    return const AppAgentTestCase(
      displayName: 'Example app smoke test',
      id: 'example-app-smoke',
      filename: 'smoke_example.yaml',
      steps: [
        AppAgentTestStep(
          goal: 'Launch the app and verify the home screen is visible',
        ),
        AppAgentTestStep(
          goal:
              'Confirm the screen shows Android only and firebase_agent_ci setup instructions',
          assertion: 'Main screen loads without crashing',
        ),
      ],
    );
  }

  static List<AppAgentTestCase> all({List<String>? devices}) => [
        exampleAppSmoke(),
        locationPermissionFlow(devices: devices),
        onboardingSmoke(devices: devices),
        coreNavigation(devices: devices),
        crashRegression(devices: devices),
      ];
}
