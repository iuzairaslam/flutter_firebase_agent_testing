# firebase_agent_example

Android-only example for [`flutter_firebase_agent_testing`](../).

## Run the app

```bash
cd example
flutter pub get
flutter run
```

## Scaffold CI (from `example/` or repo root)

From the **package repository root** (parent of `example/`):

```bash
dart run flutter_firebase_agent_testing:firebase_agent_ci setup \
  --firebase-project-id=YOUR_FIREBASE_PROJECT_ID \
  --no-email
```

From **`example/`** (resolves the example app as the Flutter project):

```bash
cd example
dart run flutter_firebase_agent_testing:firebase_agent_ci setup \
  --firebase-project-id=YOUR_FIREBASE_PROJECT_ID \
  --email-to=you@example.com
```

Add the GitHub secrets printed after setup, then push to `main` or `develop` to run the workflow.
