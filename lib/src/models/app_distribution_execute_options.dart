import 'package:meta/meta.dart';

/// Options for `firebase appdistribution:distribute` with test case IDs (Method B).
@immutable
class AppDistributionDistributeOptions {
  const AppDistributionDistributeOptions({
    required this.apkPath,
    required this.appId,
    this.testCaseIds = const [],
    this.testDevices = const [],
    this.releaseNotes,
    this.groups,
  });

  final String apkPath;

  /// Firebase Android App ID, e.g. `1:123:android:abc`.
  final String appId;

  final List<String> testCaseIds;

  /// Same format as YAML `devices` entries.
  final List<String> testDevices;

  final String? releaseNotes;

  final String? groups;
}
