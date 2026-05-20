import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_firebase_agent_testing/flutter_firebase_agent_testing.dart';

Future<int> main(List<String> arguments) async {
  final runner = CommandRunner<int>(
    'firebase_agent_ci',
    'Scaffold Firebase App Testing Agent automation (GitHub Actions + optional tests/).',
  )..addCommand(_SetupCommand());

  try {
    final code = await runner.run(arguments);
    return code ?? 0;
  } on UsageException catch (e) {
    stderr.writeln(e);
    return 64;
  } catch (e, st) {
    stderr.writeln(e);
    stderr.writeln(st);
    return 1;
  }
}

class _SetupCommand extends Command<int> {
  _SetupCommand() {
    argParser
      ..addOption(
        'project',
        abbr: 'p',
        help:
            'Flutter project root (default: cwd, or nearest pubspec with Flutter).',
      )
      ..addOption(
        'firebase-project-id',
        help:
            'Firebase **project id** (console URL segment), e.g. my-app-12345. Required.',
        mandatory: true,
      )
      ..addOption(
        'email-to',
        help:
            'Comma-separated recipient addresses for the optional email step.',
      )
      ..addFlag(
        'no-email',
        help:
            'Skip the Gmail email report step (only CLI exit code + artifacts).',
        negatable: false,
      )
      ..addOption(
        'email-from-name',
        defaultsTo: 'Firebase App Testing CI',
        help:
            'Display name in the From header (email still uses secrets.GMAIL_USER).',
      )
      ..addOption(
        'workflow-file',
        defaultsTo: 'firebase-app-testing-agent.yml',
        help: 'Filename under .github/workflows/',
      )
      ..addOption(
        'tag-pattern',
        defaultsTo: 'v*',
        help:
            'Comma-separated git tag glob patterns that trigger the workflow on push. '
            'Examples: "v*", "release-*", "v*,beta-*". '
            'Push a matching tag (e.g. `git tag v1.0.0 && git push --tags`) to run CI.',
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Overwrite an existing workflow file with the same name.',
        negatable: false,
      )
      ..addFlag(
        'dry-run',
        help: 'Print the workflow YAML and do not write any files.',
        negatable: false,
      )
      ..addFlag(
        'with-sample-tests',
        help: 'Also write RecommendedAppAgentTestTemplates into tests/.',
        negatable: false,
      )
      ..addMultiOption(
        'test-device',
        help:
            'Device spec for sample tests (repeatable). Example: model=Pixel6,version=33,locale=en,orientation=portrait',
      );
  }

  @override
  String get name => 'setup';

  @override
  String get description =>
      'Create or update .github/workflows for Firebase App Testing Agent on push/PR.';

  @override
  Future<int> run() async {
    final projectArg = argResults!['project'] as String?;
    final firebaseProjectId = argResults!['firebase-project-id'] as String;
    final emailTo = argResults!['email-to'] as String?;
    final noEmail = argResults!['no-email'] as bool;
    final emailFromName = argResults!['email-from-name'] as String;
    final workflowFile = argResults!['workflow-file'] as String;
    final tagPatternRaw = argResults!['tag-pattern'] as String;
    final force = argResults!['force'] as bool;
    final dryRun = argResults!['dry-run'] as bool;
    final withSamples = argResults!['with-sample-tests'] as bool;
    final deviceOpts = argResults!['test-device'] as List<String>;

    if (!noEmail && (emailTo == null || emailTo.trim().isEmpty)) {
      stderr.writeln(
        'When email is enabled, pass --email-to (comma-separated) or use --no-email.',
      );
      return 64;
    }

    final startDir = Directory(projectArg ?? Directory.current.path);
    final resolved =
        await GitHubActionsBootstrapper.findFlutterProjectRoot(startDir);
    if (resolved == null) {
      stderr.writeln(
        'Could not find a Flutter pubspec.yaml (with sdk: flutter) starting from ${startDir.path}. '
        'Use --project.',
      );
      return 64;
    }

    final tagPatterns = _splitCsv(tagPatternRaw);
    if (tagPatterns.isEmpty) {
      stderr
          .writeln('--tag-pattern must list at least one tag glob (e.g. v*).');
      return 64;
    }

    final bootstrapper = GitHubActionsBootstrapper();
    final cfg = bootstrapper.buildWorkflowConfig(
      firebaseProjectIdForConsoleLink: firebaseProjectId.trim(),
      emailTo: noEmail ? 'not-used@example.invalid' : emailTo!.trim(),
      emailFromDisplayName: emailFromName,
      tagPatterns: tagPatterns,
      includeEmailStep: !noEmail,
    );

    final devices =
        deviceOpts.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final deviceList = devices.isEmpty ? null : devices;

    final result = await bootstrapper.bootstrap(
      projectRoot: resolved,
      workflowConfig: cfg,
      workflowFileName: workflowFile,
      writeSampleTests: withSamples,
      sampleTestDevices: deviceList,
      overwriteWorkflow: force,
      dryRun: dryRun,
    );

    if (dryRun) {
      stdout.writeln(result.workflowYaml);
      stdout.writeln('--- dry-run: no files written ---');
      return 0;
    }

    stdout.writeln('Project: ${result.projectRoot}');
    stdout.writeln('Workflow: ${result.workflowFile}');
    if (result.createdWorkflowDirs) {
      stdout.writeln('Created .github/workflows/');
    }
    if (result.wroteSampleTests) {
      stdout.writeln('Sample tests:');
      for (final p in result.sampleTestPaths) {
        stdout.writeln('  - $p');
      }
    }

    stdout.writeln('');
    stdout.writeln('Next: add these GitHub Actions repository secrets:');
    stdout
        .writeln('  - FIREBASE_SERVICE_ACCOUNT_JSON  (full JSON key contents)');
    stdout.writeln('  - FIREBASE_APP_ID                  (1:...:android:...)');
    if (!noEmail) {
      stdout.writeln('  - GMAIL_USER');
      stdout.writeln('  - GMAIL_APP_PASSWORD');
    }
    stdout.writeln('');
    stdout.writeln('Trigger a CI run by pushing a matching tag, for example:');
    stdout.writeln('  git tag v1.0.0');
    stdout.writeln('  git push origin v1.0.0');
    stdout.writeln('');
    stdout.writeln('Tag patterns: [${tagPatterns.join(', ')}]');
    stdout.writeln(
        'You can also run the workflow manually from the Actions tab.');
    return 0;
  }

  static List<String> _splitCsv(String raw) {
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
