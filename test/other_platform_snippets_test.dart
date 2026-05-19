import 'package:flutter_firebase_agent_testing/flutter_firebase_agent_testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('distribute command joins test case ids and devices', () {
    const o = AppDistributionDistributeOptions(
      apkPath: 'app-debug.apk',
      appId: '1:2:android:x',
      testCaseIds: ['a', 'b'],
      testDevices: [
        'model=Pixel6,version=33,locale=en,orientation=portrait',
      ],
      releaseNotes: 'CI build',
    );
    final cmd = const CiPlatformSnippets().firebaseAppDistributionDistributeCommand(o);
    expect(cmd, contains('appdistribution:distribute'));
    expect(cmd, contains('--test-case-ids'));
    expect(cmd, contains('a,b'));
    expect(cmd, contains('--test-devices'));
    expect(cmd, contains('Pixel6'));
  });
}
