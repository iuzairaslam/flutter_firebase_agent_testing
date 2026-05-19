import 'dart:io';

import 'package:flutter_firebase_agent_testing/flutter_firebase_agent_testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildArguments order and flags', () {
    final ex = FirebaseAppTestingExecutor(
      processRunner: (_, __, {workingDirectory, environment}) async {
        throw UnimplementedError();
      },
    );
    final args = ex.buildArguments(
      const FirebaseAppTestingExecuteRequest(
        appId: '1:2:android:abc',
        apkPath: 'build/app/outputs/flutter-apk/app-debug.apk',
        testDir: './tests',
        extraArgs: ['--non-interactive'],
      ),
    );
    expect(args.first, 'apptesting:execute');
    expect(args, contains('--app=1:2:android:abc'));
    expect(args, contains('--test-dir=./tests'));
    expect(args.last, '--non-interactive');
  });

  test('execute forwards to process runner', () async {
    List<String>? seenArgs;
    final ex = FirebaseAppTestingExecutor(
      processRunner: (executable, arguments,
          {workingDirectory, environment}) async {
        expect(executable, 'firebase');
        seenArgs = arguments;
        return ProcessResult(0, 0, 'ok', '');
      },
    );
    final r = await ex.execute(
      const FirebaseAppTestingExecuteRequest(
        appId: 'app',
        apkPath: 'out.apk',
      ),
    );
    expect(r.isSuccess, isTrue);
    expect(seenArgs, isNotNull);
    expect(seenArgs!.length, greaterThan(3));
  });
}
