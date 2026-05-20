# flutter_firebase_agent_testing

> Plug-and-play setup for Firebase's **App Testing Agent** in any Flutter Android app — write a few lines of plain English, push to GitHub, and an AI actually opens your app on a real phone and tests it for you.

[![Android only](https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white)](#)
[![Powered by Gemini](https://img.shields.io/badge/AI-Gemini-4285F4?logo=google&logoColor=white)](#)
[![Status](https://img.shields.io/badge/status-preview-orange)](#)

---

## What is this, really?

Firebase recently released a feature called the **App Testing Agent**. You describe what your app should do in plain English ("open the app, tap Sign Up, enter a name…"), and Google's Gemini AI runs your app on a real Android device in the cloud and tries to follow those instructions. It then sends you back screenshots, video, and a pass/fail.

It's like hiring a very patient QA tester who works 24/7, except it's an AI.

The only catch: Firebase makes you write a YAML file, install a CLI, set up a GitHub Action, juggle IAM roles, opt into a preview feature, and so on. It's a couple of hours of plumbing before your first test runs.

**This package does all that plumbing for you.** One command and you're set up. Then you just write tests and push code.

---

## What you get

- **One CLI command** scaffolds the full setup (workflow, sample tests, instructions)
- **A working GitHub Actions workflow** that builds your APK and triggers the agent on every push
- **YAML helpers** so you can write tests in Dart or hand-edit YAML — both work
- **A real example app** with 3 passing test cases (Home → Counter → Sign-Up form) you can copy from
- **Sensible defaults** that actually pass Firebase's preview API on the first try

---

## How it works (the 30-second version)

```
You push a version tag (e.g. v1.0.0) to GitHub
        ↓
GitHub Actions builds your release APK
        ↓
APK uploaded to Firebase App Distribution
        ↓
Gemini opens the app on a real cloud device
        ↓
It follows your plain-English test steps
        ↓
You get pass/fail + screenshots in the Firebase Console
```

> CI only fires on **version tags** (default: `v*`) — not every commit. This avoids burning your monthly AI-test quota on work-in-progress pushes.

You write tests like this:

```yaml
tests:
- displayName: Sign up form succeeds
  id: signup-flow
  steps:
  - goal: From the home screen, open the Sign Up form
    finalScreenAssertion: A text field labeled "Name" is visible
  - goal: Enter "Test User" in the Name field and submit
    finalScreenAssertion: The text "Welcome, Test User!" is visible
```

That's it. No Appium, no XCTest, no Espresso, no flaky selectors.

---

## Before you start (one-time Firebase setup)

You need a Firebase project and a few things turned on. Skip any step you've already done.

1. **Create a Firebase project** at [console.firebase.google.com](https://console.firebase.google.com) and add your Android app (use the same `applicationId` from `android/app/build.gradle.kts`).

2. **Opt in to App Testing Agent preview**  
   Firebase Console → **App Distribution** → look for the preview opt-in. *Without this, every test will fail with `403 PERMISSION_DENIED`.*

3. **Create a service account key**  
   Firebase Console → **Project Settings** → **Service Accounts** → **Generate new private key** → save the JSON.

4. **Grant the service account three IAM roles** ([GCP IAM Console](https://console.cloud.google.com/iam-admin/iam)):
   - **Editor** (required — App Testing API needs it)
   - **Firebase App Distribution Admin**
   - **Firebase Quality Admin**

5. **Find your Firebase App ID**  
   Firebase Console → Project Settings → General → looks like `1:1234567890:android:abc123...`.

That's the boring part. From here on, this package does the work.

---

## Install

Add to your Flutter project's `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_firebase_agent_testing: ^1.0.0
```

Or from a local path / git:

```yaml
dev_dependencies:
  flutter_firebase_agent_testing:
    path: ../flutter_firebase_agent_testing
```

Then:

```bash
flutter pub get
```

---

## Quick start — one command

From your Flutter project root:

```bash
dart run flutter_firebase_agent_testing:firebase_agent_ci setup \
  --firebase-project-id=YOUR_FIREBASE_PROJECT_ID \
  --no-email \
  --with-sample-tests
```

This creates:

```
.github/workflows/firebase-app-testing-agent.yml   ← the CI pipeline
tests/                                              ← starter YAML tests
```

Then add **2 secrets** to your GitHub repository (Settings → Secrets → Actions):

| Secret | Value |
|--------|-------|
| `FIREBASE_SERVICE_ACCOUNT_JSON` | The full contents of the JSON file you downloaded in step 3 above |
| `FIREBASE_APP_ID` | Your App ID, e.g. `1:1234567890:android:abc123...` |

Now create a release tag and push it:

```bash
git add .
git commit -m "Set up Firebase App Testing Agent"
git tag v0.1.0
git push origin main --tags
```

Open the Actions tab — your first agent run is on its way. Open Firebase Console → App Distribution → your release → **App Testing agent** tab to see screenshots when it finishes.

> **Why tags, not every commit?** Each AI test run costs a slice of your monthly quota (200 free tests/month). Tag-based triggers mean CI runs when *you* decide a build is release-worthy — not on every WIP push. You can still run it manually from GitHub Actions → **Run workflow** any time.

---

## Writing tests (the part that actually matters)

A test case lives in `tests/your_test_name.yaml`. The format is straightforward:

```yaml
tests:
- displayName: Pick a name humans will read in the dashboard
  id: lowercase-hyphenated-id
  steps:
  - goal: What the agent should do, in plain English
    hint: Optional extra context — refer to button labels, dialogs to dismiss, etc.
    finalScreenAssertion: Something specific and visible on screen after this step
```

### Tips that come from actually shipping these

1. **Assert on visible text, not feelings.** ❌ "the home screen looks good" → ✅ `The text "Welcome" is visible on screen`
2. **One concrete goal per step.** Break complex flows into multiple short steps.
3. **Use hints to disambiguate.** If your screen has two "Submit" buttons, say *"Tap the Submit button at the bottom"*.
4. **Don't say "home screen" unless it's literally labeled that.** The agent takes you literally.
5. **Step limit:** 5 minutes total per test. Keep flows tight.

### Multiple test files

Put each flow in its own file under `tests/`. The CLI discovers them all recursively.

```
tests/
├── home_navigation.yaml
├── counter_increment.yaml
└── signup_form.yaml
```

The included [`example/tests/`](example/tests/) folder has 3 real, passing examples.

---

## Use the Dart API (optional)

Prefer writing tests in Dart instead of hand-editing YAML? You can.

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

final yaml = codec.encode(test);  // → ready to write to tests/login_guest.yaml
```

There's a small built-in template library too:

```dart
final smoke = RecommendedAppAgentTestTemplates.onboardingSmoke();
final perms = RecommendedAppAgentTestTemplates.locationPermissionFlow();
```

---

## Running tests locally (without CI)

If you have the Firebase CLI installed and want a faster feedback loop:

```bash
flutter build apk --release
firebase apptesting:execute \
  --app="YOUR_APP_ID" \
  --test-dir=./tests \
  --test-devices="model=MediumPhone.arm,version=36,locale=en_US,orientation=portrait" \
  ./build/app/outputs/flutter-apk/app-release.apk
```

(The GitHub Action does exactly this, but on Google's runners.)

---

## CLI reference

```bash
dart run flutter_firebase_agent_testing:firebase_agent_ci setup [options]
```

| Flag | Description |
|------|-------------|
| `--firebase-project-id` | **Required.** Your project ID from the Firebase Console URL |
| `--no-email` | Skip the email-on-completion step |
| `--email-to` | Comma-separated email addresses for the report (omit with `--no-email`) |
| `--with-sample-tests` | Drop starter YAML tests into `tests/` |
| `--tag-pattern` | Comma-separated git tag globs that trigger CI. Default: `v*` (e.g. `v1.0.0`, `v2.3.4-rc1`) |
| `--workflow-file` | Custom filename under `.github/workflows/`. Default: `firebase-app-testing-agent.yml` |
| `--force` | Overwrite an existing workflow |
| `--dry-run` | Print the workflow YAML instead of writing it |
| `--test-device` | Device spec for sample tests (repeatable) |

---

## Common questions

<details>
<summary><strong>Does my app need the Firebase SDK?</strong></summary>

No. The App Testing Agent runs your APK in the cloud — you don't add any Firebase code to your app for this. You only need a Firebase project registered to the same package name.
</details>

<details>
<summary><strong>Will it cost me money?</strong></summary>

During the preview, **200 AI tests/month per project are free**. Spark (free) plan generally works, though Firebase may ask you to upgrade to Blaze later. Each device × test counts separately — 2 tests on 2 devices = 4 runs.
</details>

<details>
<summary><strong>Why is my test getting `403 PERMISSION_DENIED`?</strong></summary>

The service account is missing the **Editor** role. Add it in GCP IAM and wait ~5 minutes. (Firebase App Distribution Admin alone is *not* enough — the App Testing API needs Editor.)
</details>

<details>
<summary><strong>Why did the AI fail my smoke test?</strong></summary>

Open Firebase Console → App Distribution → your release → **App Testing agent** → **View details**. The agent literally tells you what it saw and why it failed. Usually the fix is rewording an assertion to refer to text actually on screen.
</details>

<details>
<summary><strong>iOS support?</strong></summary>

Firebase App Testing Agent is **Android only** at the time of writing. iOS support is on Firebase's roadmap; this package will follow when it lands.
</details>

<details>
<summary><strong>Can I run tests without waiting for CI?</strong></summary>

Yes — use `--test-non-blocking` on the Firebase CLI (or edit the generated workflow). CI will return immediately and you'll find results in the Firebase Console when they finish.
</details>

---

## Project layout (in this repo)

| Path | What's in it |
|------|--------------|
| `lib/` | The package source (YAML codec, CI generator, CLI runner) |
| `bin/firebase_agent_ci.dart` | The `firebase_agent_ci` CLI |
| `example/` | A small 3-screen demo app with passing agent tests |
| `example/tests/` | Real, working YAML test cases |
| `.github/workflows/` | The repo's own CI (which also tests this package end-to-end) |

---

## Publishing to pub.dev

This package is intended for publication on [pub.dev](https://pub.dev/packages/flutter_firebase_agent_testing).

Maintainers: bump `version` in `pubspec.yaml`, update `CHANGELOG.md`, then:

```bash
dart pub publish
```

Users install with:

```bash
flutter pub add --dev flutter_firebase_agent_testing
```

---

## Contributing & feedback

This package is small on purpose — it does one thing: glue Flutter projects to Firebase App Testing Agent without you having to read 9 docs pages.

If something's confusing, file an issue. PRs welcome.

---

## License

MIT — do whatever you want with it.
