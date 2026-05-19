import 'package:meta/meta.dart';

/// Predefined virtual/physical device specs for `--test-devices` / YAML `devices:`.
@immutable
class AppTestingDevicePreset {
  const AppTestingDevicePreset({
    required this.id,
    required this.label,
    required this.spec,
  });

  final String id;
  final String label;

  /// Value placed under `devices:` or passed to Firebase CLI.
  final String spec;

  static const List<AppTestingDevicePreset> defaults = [
    AppTestingDevicePreset(
      id: 'pixel6_api35_portrait_en',
      label: 'Pixel 6 class (API 35, EN, portrait)',
      spec: 'model=MediumPhone.arm,version=35,locale=en,orientation=portrait',
    ),
    AppTestingDevicePreset(
      id: 'pixel8_api34_portrait_en',
      label: 'Pixel 8 (API 34, EN, portrait)',
      spec: 'model=Pixel8,version=34,locale=en,orientation=portrait',
    ),
    AppTestingDevicePreset(
      id: 'pixel6_landscape_en',
      label: 'Pixel 6 landscape',
      spec: 'model=Pixel6,version=33,locale=en,orientation=landscape',
    ),
    AppTestingDevicePreset(
      id: 'pixel6_api32_portrait_en',
      label: 'Pixel 6 / oriole (API 32)',
      spec: 'model=oriole,version=32,locale=en,orientation=portrait',
    ),
    AppTestingDevicePreset(
      id: 'pixel6_api35_portrait_ar',
      label: 'Pixel 6 class (API 35, Arabic)',
      spec: 'model=MediumPhone.arm,version=35,locale=ar,orientation=portrait',
    ),
  ];

  static AppTestingDevicePreset? byId(String id) {
    for (final p in defaults) {
      if (p.id == id) return p;
    }
    return null;
  }
}
