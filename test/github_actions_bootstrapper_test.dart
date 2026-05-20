import 'dart:io';

import 'package:flutter_firebase_agent_testing/flutter_firebase_agent_testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _flutterPubspec = '''
name: tmp_app
environment:
  sdk: ^3.5.0
dependencies:
  flutter:
    sdk: flutter
''';

void main() {
  test('findFlutterProjectRoot walks up', () async {
    final root = await Directory.systemTemp.createTemp('ffb_root_');
    final nested = Directory(p.join(root.path, 'a', 'b'));
    await nested.create(recursive: true);
    await File(p.join(root.path, 'pubspec.yaml'))
        .writeAsString(_flutterPubspec);
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    final found =
        await GitHubActionsBootstrapper.findFlutterProjectRoot(nested);
    expect(found, root.path);
  });

  test('bootstrap writes workflow', () async {
    final root = await Directory.systemTemp.createTemp('ffb_ci_');
    await File(p.join(root.path, 'pubspec.yaml'))
        .writeAsString(_flutterPubspec);
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    final b = GitHubActionsBootstrapper();
    final cfg = b.buildWorkflowConfig(
      firebaseProjectIdForConsoleLink: 'proj-x',
      emailTo: 'a@b.com',
      includeEmailStep: false,
    );

    final result = await b.bootstrap(
      projectRoot: root.path,
      workflowConfig: cfg,
      workflowFileName: 'firebase-app-testing-agent.yml',
      dryRun: false,
    );

    expect(result.wroteWorkflow, isTrue);
    final wf = File(result.workflowFile);
    expect(await wf.exists(), isTrue);
    final body = await wf.readAsString();
    expect(body, contains('firebase apptesting:execute'));
    expect(body, contains('secrets.FIREBASE_APP_ID'));
    expect(body, contains("tags:"));
    expect(body, contains("'v*'"));
    expect(body, contains('console.firebase.google.com/project/proj-x/'));
  });

  test('bootstrap refuses overwrite without force', () async {
    final root = await Directory.systemTemp.createTemp('ffb_ci2_');
    await File(p.join(root.path, 'pubspec.yaml'))
        .writeAsString(_flutterPubspec);
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    final b = GitHubActionsBootstrapper();
    final cfg = b.buildWorkflowConfig(
      firebaseProjectIdForConsoleLink: 'p',
      emailTo: 'a@b.com',
      includeEmailStep: false,
    );

    await b.bootstrap(projectRoot: root.path, workflowConfig: cfg);
    expect(
      () => b.bootstrap(projectRoot: root.path, workflowConfig: cfg),
      throwsStateError,
    );
  });
}
