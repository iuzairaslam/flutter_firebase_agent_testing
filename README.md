# agent-testing-repo

Flutter package and example app for **Firebase App Testing Agent** automation (Android only).

## Projects

| Path | Description |
|------|-------------|
| `lib/` | `flutter_firebase_agent_testing` package |
| `example/` | Android demo app wired to Firebase project `rebase-agent-testing` |
| `example/tests/` | YAML test cases for the App Testing Agent |
| `.github/workflows/` | GitHub Actions — builds APK and runs agent on push |

## Quick start (example app)

```bash
cd example
flutter pub get
flutter run
```

## CI setup

Add GitHub repository secrets:

- `FIREBASE_SERVICE_ACCOUNT_JSON`
- `FIREBASE_APP_ID` — `1:23964225660:android:80e257045351391730f9f9`

Push to `main` or `develop` to trigger the workflow.

## CLI

```bash
cd example
dart run flutter_firebase_agent_testing:firebase_agent_ci setup \
  --firebase-project-id=rebase-agent-testing \
  --no-email \
  --with-sample-tests
```
