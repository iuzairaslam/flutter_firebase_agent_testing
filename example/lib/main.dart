import 'package:flutter/material.dart';
import 'package:flutter_firebase_agent_testing/flutter_firebase_agent_testing.dart';

void main() {
  runApp(const FirebaseAgentExampleApp());
}

/// Minimal Android demo that uses the package API (YAML preview + device presets).
class FirebaseAgentExampleApp extends StatelessWidget {
  const FirebaseAgentExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Agent Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const _DemoHome(),
    );
  }
}

class _DemoHome extends StatefulWidget {
  const _DemoHome();

  @override
  State<_DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<_DemoHome> {
  static const _codec = AppAgentYamlCodec();
  late final String _yamlPreview;

  @override
  void initState() {
    super.initState();
    final sample = RecommendedAppAgentTestTemplates.onboardingSmoke(
      devices: [AppTestingDevicePreset.defaults.first.spec],
    );
    _yamlPreview = _codec.encode(sample);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase App Testing Agent — Example'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Android only',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'This app depends on flutter_firebase_agent_testing. '
            'Scaffold GitHub Actions from the repo root:',
          ),
          const SizedBox(height: 8),
          SelectableText(
            'dart run flutter_firebase_agent_testing:firebase_agent_ci setup '
            '--firebase-project-id=YOUR_PROJECT_ID --no-email',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
          ),
          const SizedBox(height: 24),
          Text('Sample YAML (onboarding template)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                _yamlPreview,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
