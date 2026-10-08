# Contributing

Start with the setup instructions in [README.md](README.md). Use your own Firebase project or the non-production configuration template for analysis and tests.

## Development workflow

1. Create a branch for one focused change.
2. Keep customer-facing copy in Arabic and check right-to-left layout on a narrow screen.
3. Add regression coverage when changing order flows, validation, authorization or account deletion.
4. Run `dart format lib test`, `flutter analyze` and `flutter test`.
5. Run the Firestore emulator tests when changing collections, ownership checks or rules.
6. Open a pull request describing the behavior change and the checks you ran. Include screenshots for UI changes.

Do not commit Firebase project configuration, service-account credentials, signing material, build outputs or customer data. Run `python scripts/check-repository.py` after staging changes. Keep `pubspec.lock` and `tooling/package-lock.json` committed for reproducible dependency resolution.

Live smoke tests create temporary accounts and orders. Run them only against a Firebase project you control and have permission to test. Normal CI uses the emulator and mocked Firebase services.

Public visibility does not grant a license to redistribute the app, its branding or its source. See the usage note in the README.
