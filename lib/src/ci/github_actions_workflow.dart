import 'package:meta/meta.dart';

/// All strings are injected as-is; escape secrets in GitHub, not here.
@immutable
class GitHubActionsWorkflowConfig {
  const GitHubActionsWorkflowConfig({
    required this.workflowName,
    required this.firebaseProjectIdForConsoleLink,
    required this.emailTo,
    required this.emailFromDisplayName,
    this.tagPatterns = const ['v*'],
    this.javaVersion = '17',
    this.javaDistribution = 'temurin',
    this.flutterVersion = '3.x',
    this.flutterChannel = 'stable',
    this.cacheKeyHashFiles = '**/pubspec.lock',
    this.apkArtifactPath = 'build/app/outputs/flutter-apk/app-release.apk',
    this.testDirRelative = './tests',
    this.serviceAccountSecretName = 'FIREBASE_SERVICE_ACCOUNT_JSON',
    this.firebaseAppIdSecretName = 'FIREBASE_APP_ID',
    this.gmailUserSecretName = 'GMAIL_USER',
    this.gmailAppPasswordSecretName = 'GMAIL_APP_PASSWORD',
    this.serviceAccountFileName = 'sa.json',
    this.runTestsStepId = 'run_tests',
    this.includeEmailStep = true,
    this.includeArtifactUpload = true,
    this.cachePaths = const ['~/.pub-cache', '~/.gradle/caches'],
    this.testDevices =
        'model=MediumPhone.arm,version=36,locale=en_US,orientation=portrait',
  });

  final String workflowName;
  final String firebaseProjectIdForConsoleLink;
  final String emailTo;
  final String emailFromDisplayName;

  /// Git tag glob patterns that trigger the workflow on push (e.g. `v*`, `release-*`).
  final List<String> tagPatterns;
  final String javaVersion;
  final String javaDistribution;
  final String flutterVersion;
  final String flutterChannel;
  final String cacheKeyHashFiles;
  final String apkArtifactPath;
  final String testDirRelative;
  final String serviceAccountSecretName;
  final String firebaseAppIdSecretName;
  final String gmailUserSecretName;
  final String gmailAppPasswordSecretName;
  final String serviceAccountFileName;
  final String runTestsStepId;
  final bool includeEmailStep;
  final bool includeArtifactUpload;
  final List<String> cachePaths;
  final String testDevices;

  /// Generates `.github/workflows/<fileName>` content (default file name: sanitized workflow name).
  String generateYaml({String? fileName}) {
    final tagsBlock = tagPatterns.map((t) => "      - '$t'").join('\n');
    final cachePathBlock = cachePaths.map((p) => '            $p').join('\n');

    final emailBlock = includeEmailStep
        ? '''

      - name: Send Email Report
        if: always()
        uses: dawidd6/action-send-mail@v3
        with:
          server_address: smtp.gmail.com
          server_port: 465
          secure: true
          username: \${{ secrets.$gmailUserSecretName }}
          password: \${{ secrets.$gmailAppPasswordSecretName }}
          to: $emailTo
          from: $emailFromDisplayName <\${{ secrets.$gmailUserSecretName }}>
          subject: "\${{ steps.$runTestsStepId.outcome == 'success' && 'Tests Passed' || 'Tests Failed' }} — \${{ github.repository }} \${{ github.ref_name }}"
          body: |
            Firebase App Testing Agent run complete.

            Result  : \${{ steps.$runTestsStepId.outcome == 'success' && 'ALL TESTS PASSED' || 'TESTS FAILED' }}
            Tag     : \${{ github.ref_name }}
            Commit  : \${{ github.sha }}
            Trigger : \${{ github.actor }}

            Console : https://console.firebase.google.com/project/$firebaseProjectIdForConsoleLink/appdistribution
            Run     : https://github.com/\${{ github.repository }}/actions/runs/\${{ github.run_id }}
'''
        : '';

    final artifactBlock = includeArtifactUpload
        ? '''

      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: app-release-apk
          path: $apkArtifactPath
'''
        : '';

    return '''
name: $workflowName

on:
  push:
    tags:
$tagsBlock
  workflow_dispatch:

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up JDK $javaVersion
        uses: actions/setup-java@v4
        with:
          java-version: '$javaVersion'
          distribution: '$javaDistribution'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '$flutterVersion'
          channel: '$flutterChannel'

      - name: Cache dependencies
        uses: actions/cache@v4
        with:
          path: |
$cachePathBlock
          key: \${{ runner.os }}-flutter-\${{ hashFiles('$cacheKeyHashFiles') }}

      - name: Flutter pub get
        run: flutter pub get

      - name: Resolve version from tag
        run: |
          if [[ "\${{ github.ref_type }}" == "tag" ]]; then
            echo "APP_VERSION=\${GITHUB_REF_NAME#v}" >> "\$GITHUB_ENV"
          else
            echo "APP_VERSION=0.0.0-\${{ github.run_number }}" >> "\$GITHUB_ENV"
          fi
          echo "BUILD_NUMBER=\${{ github.run_number }}" >> "\$GITHUB_ENV"

      - name: Build Release APK
        run: |
          flutter build apk --release --no-tree-shake-icons \\
            --build-name="\$APP_VERSION" \\
            --build-number="\$BUILD_NUMBER"

      - name: Verify APK exists
        run: ls -la $apkArtifactPath

      - name: Install Firebase CLI
        run: npm install -g firebase-tools

      - name: Write Firebase Service Account
        env:
          FIREBASE_SA_JSON: \${{ secrets.$serviceAccountSecretName }}
        run: printf '%s' "\$FIREBASE_SA_JSON" > $serviceAccountFileName

      - name: Validate Firebase App ID secret
        env:
          FIREBASE_APP_ID: \${{ secrets.$firebaseAppIdSecretName }}
        run: |
          APP_ID="\$(printf '%s' "\$FIREBASE_APP_ID" | tr -d '[:space:]')"
          if ! printf '%s' "\$APP_ID" | grep -Eq '^1:[0-9]+:android:[a-f0-9]+\$'; then
            echo "FIREBASE_APP_ID secret is invalid."
            echo "It must look like: 1:1234567890:android:abc123def456"
            exit 1
          fi
          printf '%s' "\$APP_ID" > .firebase_app_id

      - name: Run Firebase App Testing Agent
        id: $runTestsStepId
        env:
          GOOGLE_APPLICATION_CREDENTIALS: $serviceAccountFileName
        run: |
          APP_ID="\$(tr -d '[:space:]' < .firebase_app_id)"
          APK="./$apkArtifactPath"
          DEVICES='$testDevices'
          firebase apptesting:execute "\$APK" \\
            --app="\$APP_ID" \\
            --test-dir=$testDirRelative \\
            --test-devices "\$DEVICES" || {
              echo ""
              echo "=== App Testing Agent failed ==="
              echo "If 403 on POST .../releases/.../tests: add Editor + App Distribution Admin + Quality Admin to the service account."
              echo "If FAILED_AI_STEP: open App Distribution → release → App Testing agent tab for screenshots; use concrete finalScreenAssertion text visible on screen."
              exit 1
            }

      - name: Firebase App Distribution console
        if: always()
        run: echo "https://console.firebase.google.com/project/$firebaseProjectIdForConsoleLink/appdistribution"
$emailBlock$artifactBlock
''';
  }
}
