import 'package:meta/meta.dart';

/// All strings are injected as-is; escape secrets in GitHub, not here.
@immutable
class GitHubActionsWorkflowConfig {
  const GitHubActionsWorkflowConfig({
    required this.workflowName,
    required this.firebaseProjectIdForConsoleLink,
    required this.emailTo,
    required this.emailFromDisplayName,
    this.pushBranches = const ['main', 'develop'],
    this.pullRequestBranches = const ['main'],
    this.javaVersion = '17',
    this.javaDistribution = 'temurin',
    this.flutterVersion = '3.x',
    this.flutterChannel = 'stable',
    this.cacheKeyHashFiles = "**/pubspec.lock",
    this.buildApkCommand = 'flutter build apk --release --no-tree-shake-icons',
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
        'model=MediumPhone.arm,version=35,locale=en,orientation=portrait',
  });

  final String workflowName;
  final String firebaseProjectIdForConsoleLink;
  final String emailTo;
  final String emailFromDisplayName;

  final List<String> pushBranches;
  final List<String> pullRequestBranches;
  final String javaVersion;
  final String javaDistribution;
  final String flutterVersion;
  final String flutterChannel;
  final String cacheKeyHashFiles;
  final String buildApkCommand;
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
    final branchesPush = pushBranches.map((b) => '      - $b').join('\n');
    final branchesPr = pullRequestBranches.map((b) => '      - $b').join('\n');
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
            Branch  : \${{ github.ref_name }}
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
    branches:
$branchesPush
  pull_request:
    branches:
$branchesPr

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

      - name: Build Release APK
        run: $buildApkCommand

      - name: Verify APK exists
        run: ls -la $apkArtifactPath

      - name: Install Firebase CLI
        run: npm install -g firebase-tools

      - name: Write Firebase Service Account
        env:
          FIREBASE_SA_JSON: \${{ secrets.$serviceAccountSecretName }}
        run: printf '%s' "\$FIREBASE_SA_JSON" > $serviceAccountFileName

      - name: Upload APK to App Distribution
        env:
          GOOGLE_APPLICATION_CREDENTIALS: $serviceAccountFileName
        run: |
          firebase appdistribution:distribute ./$apkArtifactPath \\
            --app="\${{ secrets.$firebaseAppIdSecretName }}" \\
            --release-notes "CI build \${GITHUB_SHA} on \${GITHUB_REF_NAME}"

      - name: Run Firebase App Testing Agent
        id: $runTestsStepId
        env:
          GOOGLE_APPLICATION_CREDENTIALS: $serviceAccountFileName
        run: |
          firebase apptesting:execute \\
            --app="\${{ secrets.$firebaseAppIdSecretName }}" \\
            --test-dir=$testDirRelative \\
            --test-devices "$testDevices"

      - name: Firebase App Distribution console
        if: always()
        run: echo "https://console.firebase.google.com/project/$firebaseProjectIdForConsoleLink/appdistribution"
$emailBlock$artifactBlock
''';
  }
}
