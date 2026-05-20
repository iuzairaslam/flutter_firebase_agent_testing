import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// Runs `firebase apptesting:execute` on the host machine (requires Firebase CLI + auth).
@immutable
class FirebaseAppTestingExecuteRequest {
  const FirebaseAppTestingExecuteRequest({
    required this.appId,
    required this.apkPath,
    this.testDir = 'tests',
    this.firebaseExecutable = 'firebase',
    this.workingDirectory,
    this.environment,
    this.extraArgs = const [],
  });

  final String appId;
  final String apkPath;

  /// Directory containing YAML tests (relative to [workingDirectory] or absolute).
  final String testDir;

  final String firebaseExecutable;
  final String? workingDirectory;
  final Map<String, String>? environment;

  /// Appended after built-in flags (e.g. `--non-interactive` if your CLI needs it).
  final List<String> extraArgs;
}

/// Result of a local CLI invocation.
@immutable
class FirebaseAppTestingExecuteResult {
  const FirebaseAppTestingExecuteResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;

  bool get isSuccess => exitCode == 0;
}

class FirebaseAppTestingExecutor {
  FirebaseAppTestingExecutor({ProcessRunner? processRunner})
      : _run = processRunner ?? _defaultRun;

  final Future<ProcessResult> Function(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) _run;

  static Future<ProcessResult> _defaultRun(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) {
    return Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: false,
    );
  }

  List<String> buildArguments(FirebaseAppTestingExecuteRequest r) {
    final apk = p.isAbsolute(r.apkPath)
        ? r.apkPath
        : (r.workingDirectory != null
            ? p.normalize(p.join(r.workingDirectory!, r.apkPath))
            : r.apkPath);

    final testDir = r.testDir;

    return [
      'apptesting:execute',
      '--app=${r.appId}',
      '--test-dir=$testDir',
      apk,
      ...r.extraArgs,
    ];
  }

  Future<FirebaseAppTestingExecuteResult> execute(
    FirebaseAppTestingExecuteRequest request,
  ) async {
    final result = await _run(
      request.firebaseExecutable,
      buildArguments(request),
      workingDirectory: request.workingDirectory,
      environment: request.environment,
    );
    return FirebaseAppTestingExecuteResult(
      exitCode: result.exitCode,
      stdout: result.stdout is String
          ? result.stdout as String
          : '${result.stdout}',
      stderr: result.stderr is String
          ? result.stderr as String
          : '${result.stderr}',
    );
  }
}

typedef ProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
});
