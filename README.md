<p align="center">
  <img src="assets/branding/logo.jpeg" width="128" alt="Kabbas logo" />
</p>

<h1 align="center">Kabbas · كبّاس</h1>

<p align="center">HVAC services, pipe installation, scrap collection and spare parts.<br />An Arabic-first Flutter app with a Firebase backend.</p>

<p align="center">
  <a href="https://github.com/amreahmed/kabbas-app/actions/workflows/ci.yml"><img src="https://github.com/amreahmed/kabbas-app/actions/workflows/ci.yml/badge.svg" alt="CI status" /></a>
  <img src="https://img.shields.io/badge/Flutter-3.47.2-02569B?logo=flutter" alt="Flutter 3.47.2" />
  <img src="https://img.shields.io/badge/Backend-Firebase-DD2C00?logo=firebase" alt="Firebase backend" />
  <img src="https://img.shields.io/badge/Android-API%2036-3DDC84?logo=android" alt="Android target API 36" />
</p>

## Overview

Kabbas connects customers with air-conditioning and refrigeration services. Customers submit service requests, attach an optional photo or location, and follow their request status. Authorized administrators manage requests and the spare-parts catalog from the same app.

**Android is the verified release target.** The repository retains the existing iOS, web and desktop platform scaffolding, but those platforms are not release-tested and may need plugin and platform-specific work.

## Features

| Area | Capabilities |
| --- | --- |
| Pipe installation | Inspection requests with an address, number of AC units, notes and optional attachments |
| Maintenance | Fault descriptions, contact information, optional photos and user-requested GPS location |
| Scrap collection | Scrap type, estimated weight and collection requests |
| Spare parts | Product browsing, a cart and a WhatsApp message the customer reviews and sends |
| Customer account | Email/password and Google sign-in, profile editing, request history and account deletion |
| Administration | Separate request tabs, status updates and product management, protected by Firebase custom claims |

The interface uses Arabic and right-to-left layouts. Checkout concerns physical goods and services; the app does not process in-app payments.

## Technology

- **Flutter and Dart** for the client, with Material widgets and the Cairo font through Google Fonts.
- **Firebase Authentication** for accounts and **Cloud Firestore** for profiles, products and service requests.
- **Provider** for the in-memory shopping cart.
- **Geolocator, Image Picker and URL Launcher** for optional location, photos and external actions.
- **Flutter tests and the Firestore emulator** for UI, validation and authorization checks.

Order photos are stored in their protected Firestore documents. The current client does not use Firebase Storage; its rules deny client access.

## Getting started

### Prerequisites

- Flutter **3.47.2**; the package requires Dart **3.12.2 or newer within Dart 3**.
- An Android SDK with API 36, Android build tools and NDK **27.3.13750724** for the pinned release configuration.
- A compatible JDK; the verified local toolchain uses **JDK 21**.
- Your own Firebase project to run connected application features.
- Node.js **22** and Java **21** for Firestore emulator tests. Python **3** is needed for repository and native-library checks.

```bash
git clone https://github.com/amreahmed/kabbas-app.git
cd kabbas-app
flutter pub get
```

### Configure Firebase

Production Firebase configuration is intentionally excluded. Use the [Firebase CLI](https://firebase.google.com/docs/cli) and [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup) to configure a project you own:

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
flutterfire configure --project=YOUR_PROJECT_ID --platforms=android
```

Register the Android app as `com.kabbas.app`. Confirm that configuration generates `lib/firebase_options.dart` and that your downloaded `google-services.json` is in `android/app/`.

In Firebase Console:

1. Enable Email/Password authentication and, if needed, Google sign-in. Register the relevant Android signing-certificate fingerprints for Google sign-in.
2. Create a Firestore database, then deploy the repository rules to **your** project:

   ```bash
   firebase deploy --only firestore:rules --project=YOUR_PROJECT_ID
   ```

3. Grant the `admin: true` custom claim to the intended administrator using the Firebase Admin SDK in a trusted server environment. A writable profile role does not grant access. Sign in again to refresh the token.
4. Create catalog products through the administrator interface. No production accounts or sample catalog data are included.

Start a connected device or emulator and run:

```bash
flutter run
```

### Analyze and test without a backend

Copy `lib/firebase_options.example.dart` to `lib/firebase_options.dart` if you have not configured Firebase. The placeholders allow static analysis and mocked tests; they do not enable live authentication or orders. Do not overwrite an existing working configuration.

```bash
flutter analyze
flutter test
```

To test database permissions locally:

```bash
npm ci --prefix tooling
npx --yes firebase-tools@15.33.0 emulators:exec --only firestore --project demo-kabbas "node --test tooling/rules.test.cjs"
```

The `demo-kabbas` emulator project does not use production credentials. CI runs these checks with a non-production configuration template and no deployment permissions.

## Project structure

```text
lib/
  screens/             Customer flows and administrator dashboard
  services/            Account deletion, user profiles and order helpers
  providers/           Cart state
  theme/               Shared colors
  widgets/             Shared UI components
assets/branding/       Current application logo
android/               Verified Android release configuration
test/                  Flutter unit and widget tests
tooling/               Firestore rule tests and an opt-in live smoke test
scripts/               Tool discovery, signing and release verification
public/                Privacy and account-deletion web pages
play-store/            Listing copy, release notes and Data safety worksheet
.github/workflows/     Automated Flutter and Firestore checks
firestore.rules        Database authorization and request validation
storage.rules          Deny-by-default Storage policy
```

### Data model and access

| Collection | Purpose | Access |
| --- | --- | --- |
| `users` | Account profile and deletion state | Owner or administrator reads; restricted owner writes |
| `products` | Spare-parts catalog | Public reads; administrator writes |
| `maintenance_orders` | Maintenance requests | Owner or administrator reads; administrator status updates |
| `scrap_orders` | Collection requests | Owner or administrator reads; administrator status updates |
| `pipe_installation_orders` | Installation inspections | Owner or administrator reads; validated address and unit count |

Customer histories are filtered by `userId`. Account deletion freezes new requests, removes the user's orders and profile, then removes the authentication identity. Failed cleanup keeps the identity available so deletion can be retried.

## Android releases

The current app version is **1.0.3+4**, with package ID **`com.kabbas.app`** and target API **36**.

1. Configure Firebase and release signing locally. Use `android/key.properties.example` as a reference and preserve the existing upload key for updates.
2. Run analysis and tests.
3. Build the Android App Bundle:

   ```bash
   flutter build appbundle --release
   ```

The bundle is written to `build/app/outputs/bundle/release/app-release.aab`. On Windows, `./build-release-bundle.ps1` runs analysis and tests before building. Optional machine-specific SDK paths belong in the ignored `scripts/local-settings.ps1`; see its example file.

See [PLAY_RELEASE.md](PLAY_RELEASE.md) for signing, bundle verification, 16 KB checks and the Play Console checklist. Build outputs and signing material are never tracked in this repository.

## Documentation

- [Contributing](CONTRIBUTING.md)
- [Security](SECURITY.md)
- [Android release guide](PLAY_RELEASE.md)
- [Arabic store listing](play-store/listing-ar.md)
- [Data safety worksheet](play-store/data-safety.md)
- [Privacy policy](https://c00l-market.web.app/privacy.html)
- [Account deletion](https://c00l-market.web.app/delete-account.html)

The public policy pages describe the Kabbas service. Forks should supply their own business details, support channels and policies before publishing.

## Usage rights

No open-source license has been granted for this repository. Public visibility does not grant permission to redistribute the source, the Kabbas name or its artwork. Third-party dependencies retain their respective licenses.
