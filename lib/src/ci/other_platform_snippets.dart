import 'package:meta/meta.dart';

import '../models/app_distribution_execute_options.dart';

/// Shell snippets for Bitrise, Codemagic, and Fastlane (from Firebase automation docs).
@immutable
class CiPlatformSnippets {
  const CiPlatformSnippets();

  String bitriseAppTestingExecute({
    required String firebaseAppIdEnvVar,
    String testDir = './tests',
    String apkRelative = 'app/build/outputs/apk/debug/app-debug.apk',
  }) {
    return '''
npm install -g firebase-tools
export GOOGLE_APPLICATION_CREDENTIALS="\$BITRISE_SOURCE_DIR/service-account.json"
firebase apptesting:execute \\
  --app=\$$firebaseAppIdEnvVar \\
  --test-dir=$testDir \\
  \$BITRISE_SOURCE_DIR/$apkRelative
'''
        .trim();
  }

  String codemagicAppTestingExecute({
    required String firebaseAppIdEnvVar,
    String testDir = './tests',
    String apkPath = 'build/app/outputs/flutter-apk/app-debug.apk',
    String credentialsPath = '/tmp/firebase-sa.json',
  }) {
    return '''
npm install -g firebase-tools
export GOOGLE_APPLICATION_CREDENTIALS="$credentialsPath"
firebase apptesting:execute \\
  --app=\$$firebaseAppIdEnvVar \\
  --test-dir=$testDir \\
  $apkPath
'''
        .trim();
  }

  String fastlaneLaneBody({
    required String firebaseAppIdEnv,
    String testDir = './tests',
    String apkRelative = '../app/build/outputs/apk/debug/app-debug.apk',
  }) {
    return '''
sh("firebase apptesting:execute \\\\
--app=#{ENV['$firebaseAppIdEnv']} \\\\
--test-dir=$testDir \\\\
$apkRelative")
'''
        .trim();
  }

  /// `firebase appdistribution:distribute` with optional test case IDs (Method B).
  String firebaseAppDistributionDistributeCommand(
      AppDistributionDistributeOptions o) {
    final parts = <String>[
      'firebase appdistribution:distribute',
      _shellQuote(o.apkPath),
      '--app',
      _shellQuote(o.appId),
    ];
    if (o.releaseNotes != null && o.releaseNotes!.trim().isNotEmpty) {
      parts.addAll(['--release-notes', _shellQuote(o.releaseNotes!.trim())]);
    }
    if (o.groups != null && o.groups!.trim().isNotEmpty) {
      parts.addAll(['--groups', _shellQuote(o.groups!.trim())]);
    }
    if (o.testCaseIds.isNotEmpty) {
      parts.addAll([
        '--test-case-ids',
        _shellQuote(o.testCaseIds.join(',')),
      ]);
    }
    if (o.testDevices.isNotEmpty) {
      parts.addAll([
        '--test-devices',
        _shellQuote(o.testDevices.join(';')),
      ]);
    }
    return parts.join(' ');
  }

  static String _shellQuote(String s) {
    if (s.isEmpty) return "''";
    if (!RegExp(r'''[^\w@%+=:,./-]''').hasMatch(s)) return s;
    return "'${s.replaceAll("'", "'\\''")}'";
  }
}
