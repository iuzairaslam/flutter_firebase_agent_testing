# flutter_firebase_agent_testing

**AI-powered testing for Flutter Android apps — write plain English, push a tag, watch Gemini test your app on a real phone.**

![flutter_firebase_agent_testing cover](https://raw.githubusercontent.com/iuzairaslam/flutter_firebase_agent_testing/main/doc/cover.png)

[![pub.dev](https://img.shields.io/pub/v/flutter_firebase_agent_testing?color=blue&logo=dart)](https://pub.dev/packages/flutter_firebase_agent_testing)
[![Android](https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white)](https://pub.dev/packages/flutter_firebase_agent_testing)
[![Powered by Gemini](https://img.shields.io/badge/AI-Gemini-4285F4?logo=google&logoColor=white)](https://pub.dev/packages/flutter_firebase_agent_testing)
[![Preview](https://img.shields.io/badge/status-preview-orange)](https://pub.dev/packages/flutter_firebase_agent_testing)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](#license)

---

## What is this?

Firebase's **App Testing Agent** lets you describe what your app should do in plain English, and Google's Gemini AI runs it on a real Android device in the cloud — returning screenshots, video, and a pass/fail result.

This package removes all the setup friction. One command scaffolds everything: the GitHub Actions workflow, YAML test files, and CI configuration. You focus on writing tests, not plumbing.

---

## How it works

```
 ┌─────────────────────────────────────────────────────────────┐
 │                                                             │
 │   1. You push a version tag  →  git tag v1.0.0 && git push │
 │                                                             │
 │   2. GitHub Actions builds your release APK automatically   │
 │                                                             │
 │   3. APK is uploaded to Firebase App Distribution          │
 │                                                             │
 │   4. Gemini opens your app on a real cloud Android device   │
 │                                                             │
 │   5. It follows your plain-English test steps              │
 │                                                             │
 │   6. You get pass/fail + screenshots in Firebase Console   │
 │                                                             │
 └─────────────────────────────────────────────────────────────┘
```

Your tests look like this — no Appium, no Espresso, no selectors:

```yaml
tests:
  - displayName: Sign up flow succeeds
    id: signup-flow
    steps:
      - goal: From the home screen, open the Sign Up form
        finalScreenAssertion: A text field labeled "Name" is visible
      - goal: Enter "Test User" in the Name field and submit
        finalScreenAssertion: The text "Welcome, Test User!" is visible
```

---

## Step 1 — One-time Firebase setup

> Skip any step you have already completed.

### 1.1 · Create a Firebase project

Go to [console.firebase.google.com](https://console.firebase.google.com), create a project, and register your Android app using the same `applicationId` from `android/app/build.gradle.kts`.

### 1.2 · Opt in to App Testing Agent (preview)

```
Firebase Console → App Distribution → App Testing Agent → Enable Preview
```

> Without this step every test will return `403 PERMISSION_DENIED`.

### 1.3 · Create a service account key

```
Firebase Console → Project Settings → Service Accounts → Generate new private key
```

Save the downloaded JSON file — you will need it shortly.

### 1.4 · Grant IAM roles to the service account

Open [GCP IAM Console](https://console.cloud.google.com/iam-admin/iam) and grant the service account all three roles:

| Role | Required for |
|------|-------------|
| **Editor** | App Testing API |
| **Firebase App Distribution Admin** | Uploading APKs |
| **Firebase Quality Admin** | Running AI tests |

### 1.5 · Find your Firebase App ID

```
Firebase Console → Project Settings → General → Your apps
```

It looks like `1:1234567890:android:abc123...`. Copy it.

---

## Step 2 — Install the package

Add to your Flutter project's `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_firebase_agent_testing: ^1.0.0
```

Then run:

```bash
flutter pub get
```

---

## Step 3 — Scaffold your CI in one command

From your Flutter project root:

```bash
dart run flutter_firebase_agent_testing:firebase_agent_ci setup \
  --firebase-project-id=YOUR_FIREBASE_PROJECT_ID \
  --no-email \
  --with-sample-tests
```

This generates two things:

```
your-flutter-project/
├── .github/
│   └── workflows/
│       └── firebase-app-testing-agent.yml   ← CI pipeline (auto-generated)
└── tests/
    ├── home_navigation.yaml                  ← sample test
    ├── counter_increment.yaml                ← sample test
    └── signup_form.yaml                      ← sample test
```

---

## Step 4 — Add GitHub Secrets

In your GitHub repository go to **Settings → Secrets and variables → Actions** and add:

| Secret name | Value |
|-------------|-------|
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Full contents of the JSON key file from Step 1.3 |
| `FIREBASE_APP_ID` | Your App ID from Step 1.5, e.g. `1:1234567890:android:abc123...` |

---

## Step 5 — Push your first test run

```bash
git add .
git commit -m "Add Firebase App Testing Agent"
git tag v0.1.0
git push origin main --tags
```

Then open:
- **GitHub → Actions tab** to watch the build
- **Firebase Console → App Distribution → your release → App Testing Agent** to see screenshots and results

> **Why version tags, not every push?**  
> Each AI test run counts against your quota (200 free tests/month). Tag-based triggers mean CI runs only when you decide a build is ready — not on every work-in-progress commit. You can also trigger it manually from GitHub Actions → **Run workflow** any time.

---

## Writing tests

Each test file lives in `tests/`. Create one file per user flow:

```
tests/
├── home_navigation.yaml
├── counter_increment.yaml
└── signup_form.yaml
```

### Test file format

```yaml
tests:
  - displayName: Human-readable name shown in the Firebase dashboard
    id: lowercase-hyphenated-id
    steps:
      - goal: What the AI agent should do, written in plain English
        hint: Optional — add context like button labels or dialogs to dismiss
        finalScreenAssertion: Something specific and visible on screen after this step
```

### Tips for reliable tests

| Do | Don't |
|----|-------|
| `The text "Welcome" is visible on screen` | `the home screen looks good` |
| One concrete action per step | Chain multiple actions in one step |
| `Tap the Submit button at the bottom of the screen` | `Tap Submit` (ambiguous if there are two) |
| Use text that literally appears on screen | Say "home screen" unless it's labeled that |

Keep each test under **5 minutes total** — that is the agent's step limit.

---

## Optional — Write tests in Dart

Prefer Dart over hand-editing YAML? The package includes a typed API:

```dart
import 'package:flutter_firebase_agent_testing/flutter_firebase_agent_testing.dart';

const codec = AppAgentYamlCodec();

final test = AppAgentTestCase(
  displayName: 'Login as guest',
  id: 'login-as-guest',
  filename: 'login_guest.yaml',
  steps: const [
    AppAgentTestStep(
      goal: 'Tap "Continue as Guest"',
      finalScreenAssertion: 'The home screen is visible',
    ),
  ],
);

final yaml = codec.encode(test); // ready to write to tests/login_guest.yaml
```

There is also a built-in template library for common flows:

```dart
final smoke = RecommendedAppAgentTestTemplates.onboardingSmoke();
final perms = RecommendedAppAgentTestTemplates.locationPermissionFlow();
```

---

## Optional — Run tests locally without CI

If you have the Firebase CLI installed:

```bash
flutter build apk --release

firebase apptesting:execute \
  --app="YOUR_APP_ID" \
  --test-dir=./tests \
  --test-devices="model=MediumPhone.arm,version=36,locale=en_US,orientation=portrait" \
  ./build/app/outputs/flutter-apk/app-release.apk
```

---

## CLI reference

```bash
dart run flutter_firebase_agent_testing:firebase_agent_ci setup [options]
```

| Flag | Default | Description |
|------|---------|-------------|
| `--firebase-project-id` | *(required)* | Your project ID from the Firebase Console |
| `--no-email` | — | Skip email notification on completion |
| `--email-to` | — | Comma-separated emails for test reports |
| `--with-sample-tests` | — | Write starter YAML tests into `tests/` |
| `--tag-pattern` | `v*` | Git tag globs that trigger CI |
| `--workflow-file` | `firebase-app-testing-agent.yml` | Output filename under `.github/workflows/` |
| `--force` | — | Overwrite an existing workflow file |
| `--dry-run` | — | Print generated YAML without writing files |
| `--test-device` | — | Device spec for sample tests (repeatable) |

---

## FAQ

<details>
<summary><strong>Does my app need the Firebase SDK installed?</strong></summary>

No. The App Testing Agent runs your APK in the cloud. You do not add any Firebase SDK code to your app — you only need a Firebase project registered to the same package name.
</details>

<details>
<summary><strong>Will this cost money?</strong></summary>

During the preview period, **200 AI tests per month per project are free**. The Spark (free) plan generally works, though Firebase may prompt you to upgrade to Blaze later. Each device × test combination counts separately — 2 tests on 2 devices equals 4 runs.
</details>

<details>
<summary><strong>My test is failing with 403 PERMISSION_DENIED — what do I do?</strong></summary>

The service account is missing the **Editor** role. The Firebase App Distribution Admin role alone is not enough. Add Editor in GCP IAM and wait about 5 minutes for it to propagate.
</details>

<details>
<summary><strong>Why did the AI fail my test?</strong></summary>

Open **Firebase Console → App Distribution → your release → App Testing Agent → View details**. The agent explains exactly what it saw and why it stopped. The fix is usually rewording an assertion to match text that actually appears on screen.
</details>

<details>
<summary><strong>Is iOS supported?</strong></summary>

Not yet. Firebase App Testing Agent is Android-only at the time of writing. iOS support is on Firebase's roadmap and this package will add it when available.
</details>

<details>
<summary><strong>Can I trigger a test run without waiting for a tag push?</strong></summary>

Yes — go to **GitHub → Actions → firebase-app-testing-agent → Run workflow** to trigger a run manually at any time.
</details>

---

## License

MIT — use freely in any project.
