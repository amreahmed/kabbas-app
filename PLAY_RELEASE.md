# Android release guide

Package: `com.kabbas.app` · Current version: `1.0.3+4` · Target SDK: `36`

## Local configuration

Follow the Firebase setup in [README.md](README.md). Production configuration is not included in Git. Before building, confirm that `android/app/google-services.json` contains the correct package and that `lib/firebase_options.dart` points to the same project.

Windows scripts discover Flutter on PATH or through `FLUTTER_ROOT`, and Java through `JAVA_HOME`/PATH. Set `ANDROID_HOME` to your SDK. You can copy `scripts/local-settings.example.ps1` to the ignored `scripts/local-settings.ps1` for machine-specific settings. Use PowerShell 7 for these scripts.

## Signing

For an existing Play app, use its existing upload key. **Do not create a replacement key for routine updates.**

For a new app only, `./scripts/setup-signing.ps1` creates an upload keystore, local properties and a public certificate. It refuses to overwrite existing signing files. Alternatively, create your own keystore and copy `android/key.properties.example` to `android/key.properties` with the correct local values.

Back up signing material securely. Keystores, properties, certificates and passwords are ignored by Git. Never put them in issues, pull requests or public releases.

## Build and verify

```powershell
./build-release-bundle.ps1
```

The script checks Firebase package configuration, runs analysis and Flutter tests, and builds `build/app/outputs/bundle/release/app-release.aab`. Use `./build-release-apk.ps1` for a directly installable release APK.

For extra validation, download [bundletool](https://github.com/google/bundletool/releases) and set `BUNDLETOOL_JAR` to its JAR file, or place it at `.tools/bundletool.jar`. Install Android Build Tools 36.0.0 and make Python 3 available on PATH, then run:

```powershell
./scripts/verify-bundle.ps1
```

This checks bundle structure, package/version/target SDK, signatures, 64-bit native-library alignment and the ZIP alignment of a signed universal APK generated from the bundle. Password files are temporary and removed after APK generation. Preserve the keystore and alias specified in your own signing properties.

The checked-in NDK pin is 27.3.13750724, used for the verified release. Some plugins request a newer NDK; changing the pin requires rebuilding and repeating the native-alignment checks. Passing static alignment checks does not replace testing on devices.

## Backend changes

Run the Firestore emulator suite before deploying rule changes:

```powershell
npm ci --prefix tooling
npx --yes firebase-tools@15.33.0 emulators:exec --only firestore --project demo-kabbas 'node --test tooling/rules.test.cjs'
firebase deploy --only firestore:rules --project YOUR_PROJECT_ID
```

If privacy or deletion pages change, review `public/` and deploy Hosting to the intended project. Do not copy production credentials into the repository. The current app stores order photos in Firestore documents; Firebase Storage is unused and its rules deny client access.

`node tooling/live-smoke.cjs --pipe-installation` creates a temporary account and order using your local Android Firebase configuration, checks owner isolation, and removes its test data. Run it only against an authorized project. Normal CI never runs this live test.

## Play Console checklist

- Increment the version code in `pubspec.yaml` for each uploaded update.
- Upload the signed AAB to internal testing and test the Play-installed app.
- Register the Play **app-signing** certificate fingerprints in Firebase for Google sign-in; these can differ from the upload certificate.
- Update the store icon, release notes, screenshots and feature graphic. Store assets live under `play-store/`; the current icon is `graphics/kabbas-app-icon-512.png`.
- Review `play-store/data-safety.md` against actual business practices, including required inspection addresses and optional photos/location.
- Complete the applicable account, app access, content rating, audience and testing requirements shown by Play Console. Provide a regular reviewer account without administrator privileges.
- Test registration, sign-in, all three service requests, history isolation, catalog management, WhatsApp checkout, denied location permissions and account deletion.
- Review the pre-launch report and current [target API](https://developer.android.com/google/play/requirements/target-sdk) and [16 KB page-size](https://developer.android.com/guide/practices/page-sizes) requirements before production rollout.

Building locally does not upload or publish the app. GitHub CI also does not deploy Firebase rules or produce signed store releases.
