# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-05-20

### Added

- `firebase_agent_ci setup` CLI to scaffold GitHub Actions and optional sample YAML tests.
- `AppAgentYamlCodec` for Firebase App Testing Agent YAML encode/decode.
- `GitHubActionsWorkflowConfig` and `GitHubActionsBootstrapper` for CI workflow generation.
- `FirebaseAppTestingExecutor` for local `firebase apptesting:execute` invocations.
- Recommended test templates and device presets.
- Example Android app with three working agent test cases (home, counter, sign-up form).

### Changed

- CI workflow triggers on version tags (`v*`) instead of branch pushes.
- CI builds release APKs and passes the binary directly to `apptesting:execute`.
- Version/build numbers are derived from the git tag and GitHub run number so each tagged release creates a new Firebase App Distribution row.

### Fixed

- Workflow generator aligned with the tested production GitHub Actions workflow.
- App ID validation and service-account JSON handling in generated workflows.
- Test YAML guidance: concrete `finalScreenAssertion` text for reliable agent runs.

[1.0.0]: https://github.com/iuzairaslam/agent-testing-repo/releases/tag/v1.0.0
