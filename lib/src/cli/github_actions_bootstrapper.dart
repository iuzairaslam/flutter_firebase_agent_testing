import 'dart:io';

import 'package:path/path.dart' as p;

import '../ci/github_actions_workflow.dart';
import '../io/app_agent_test_case_writer.dart';
import '../templates/recommended_test_templates.dart';

/// Result of [GitHubActionsBootstrapper.bootstrap].
class GitHubActionsBootstrapResult {
  GitHubActionsBootstrapResult({
    required this.projectRoot,
    required this.workflowFile,
    required this.workflowYaml,
    required this.createdWorkflowDirs,
    required this.wroteWorkflow,
    required this.wroteSampleTests,
    required this.sampleTestPaths,
  });

  final String projectRoot;

  /// Absolute path to the workflow file (whether written or not).
  final String workflowFile;

  /// Generated workflow contents (for `--dry-run` or logs).
  final String workflowYaml;
  final bool createdWorkflowDirs;
  final bool wroteWorkflow;
  final bool wroteSampleTests;
  final List<String> sampleTestPaths;
}

/// Writes GitHub Actions workflow (and optionally sample YAML tests) into a Flutter app repo.
class GitHubActionsBootstrapper {
  GitHubActionsBootstrapper({
    GitHubActionsWorkflowConfig? workflowDefaults,
  }) : _workflowDefaults = workflowDefaults;

  final GitHubActionsWorkflowConfig? _workflowDefaults;

  /// Finds `pubspec.yaml` by walking up from [startDir] if needed.
  static Future<String?> findFlutterProjectRoot(Directory startDir) async {
    Directory dir = startDir.absolute;
    while (true) {
      final pub = File(p.join(dir.path, 'pubspec.yaml'));
      if (await pub.exists()) {
        final text = await pub.readAsString();
        if (text.contains('sdk: flutter') ||
            text.contains('sdk:flutter') ||
            RegExp(r'flutter:\s*\n\s*sdk:\s*flutter', multiLine: true)
                .hasMatch(text)) {
          return dir.path;
        }
      }
      final parent = dir.parent;
      if (parent.path == dir.path) return null;
      dir = parent;
    }
  }

  Future<GitHubActionsBootstrapResult> bootstrap({
    required String projectRoot,
    required GitHubActionsWorkflowConfig workflowConfig,
    String workflowFileName = 'firebase-app-testing-agent.yml',
    bool writeSampleTests = false,
    List<String>? sampleTestDevices,
    bool overwriteWorkflow = false,
    bool dryRun = false,
  }) async {
    final rootDir = Directory(projectRoot);
    if (!await rootDir.exists()) {
      throw ArgumentError.value(
          projectRoot, 'projectRoot', 'Directory does not exist');
    }

    final pubspec = File(p.join(rootDir.path, 'pubspec.yaml'));
    if (!await pubspec.exists()) {
      throw StateError(
          'Not a Dart/Flutter project (missing pubspec.yaml): ${rootDir.path}');
    }

    final workflowDir = Directory(p.join(rootDir.path, '.github', 'workflows'));
    var createdDirs = false;
    final dirExisted = await workflowDir.exists();
    if (!dirExisted) {
      createdDirs = true;
      if (!dryRun) await workflowDir.create(recursive: true);
    }

    final normalizedName =
        workflowFileName.endsWith('.yml') || workflowFileName.endsWith('.yaml')
            ? workflowFileName
            : '$workflowFileName.yml';
    final workflowPath = p.join(workflowDir.path, normalizedName);
    final workflowFileEntity = File(workflowPath);

    final yaml = '${workflowConfig.generateYaml().trimRight()}\n';
    var wroteWorkflow = false;
    if (!dryRun) {
      if (await workflowFileEntity.exists() && !overwriteWorkflow) {
        throw StateError(
          'Workflow already exists: $workflowPath\n'
          'Use --force to overwrite or pass a different --workflow-file name.',
        );
      }
      await workflowFileEntity.writeAsString(yaml);
      wroteWorkflow = true;
    }

    final samples = <String>[];
    if (writeSampleTests && !dryRun) {
      final writer = AppAgentTestCaseWriter();
      final testsDir = p.join(rootDir.path, 'tests');
      for (final tc in RecommendedAppAgentTestTemplates.all(
        devices: sampleTestDevices,
      )) {
        final f = await writer.write(testCase: tc, testsDirectory: testsDir);
        samples.add(f.path);
      }
    }

    return GitHubActionsBootstrapResult(
      projectRoot: rootDir.path,
      workflowFile: workflowPath,
      workflowYaml: yaml,
      createdWorkflowDirs: createdDirs,
      wroteWorkflow: wroteWorkflow,
      wroteSampleTests: writeSampleTests && !dryRun && samples.isNotEmpty,
      sampleTestPaths: samples,
    );
  }

  /// Builds [GitHubActionsWorkflowConfig] from discrete fields when you do not construct it yourself.
  GitHubActionsWorkflowConfig buildWorkflowConfig({
    required String firebaseProjectIdForConsoleLink,
    required String emailTo,
    String emailFromDisplayName = 'Firebase App Testing CI',
    String workflowName = 'Firebase App Testing Agent CI',
    List<String> tagPatterns = const ['v*'],
    bool includeEmailStep = true,
    bool includeArtifactUpload = true,
  }) {
    final base = _workflowDefaults;
    return GitHubActionsWorkflowConfig(
      workflowName: workflowName,
      firebaseProjectIdForConsoleLink: firebaseProjectIdForConsoleLink,
      emailTo: emailTo,
      emailFromDisplayName: emailFromDisplayName,
      tagPatterns: tagPatterns,
      javaVersion: base?.javaVersion ?? '17',
      javaDistribution: base?.javaDistribution ?? 'temurin',
      flutterVersion: base?.flutterVersion ?? '3.x',
      flutterChannel: base?.flutterChannel ?? 'stable',
      cacheKeyHashFiles: base?.cacheKeyHashFiles ?? '**/pubspec.lock',
      apkArtifactPath: base?.apkArtifactPath ??
          'build/app/outputs/flutter-apk/app-release.apk',
      testDirRelative: base?.testDirRelative ?? './tests',
      serviceAccountSecretName:
          base?.serviceAccountSecretName ?? 'FIREBASE_SERVICE_ACCOUNT_JSON',
      firebaseAppIdSecretName:
          base?.firebaseAppIdSecretName ?? 'FIREBASE_APP_ID',
      gmailUserSecretName: base?.gmailUserSecretName ?? 'GMAIL_USER',
      gmailAppPasswordSecretName:
          base?.gmailAppPasswordSecretName ?? 'GMAIL_APP_PASSWORD',
      serviceAccountFileName: base?.serviceAccountFileName ?? 'sa.json',
      runTestsStepId: base?.runTestsStepId ?? 'run_tests',
      includeEmailStep: includeEmailStep,
      includeArtifactUpload: includeArtifactUpload,
      cachePaths:
          base?.cachePaths ?? const ['~/.pub-cache', '~/.gradle/caches'],
      testDevices: base?.testDevices ??
          'model=MediumPhone.arm,version=36,locale=en_US,orientation=portrait',
    );
  }
}
