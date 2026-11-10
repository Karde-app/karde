# Karde

An offline vault for bank cards and identity documents, built with Flutter for Android.

Karde keeps card details, passports, ID cards and driving licences on the user's own
phone — encrypted, behind the device's fingerprint or screen lock, and reachable with no
network connection. It has no account, no server and **no internet permission at all**.

Published on Google Play as `com.karde.app`.

---

## The central constraint

The `INTERNET` permission is stripped from the merged manifest:

```xml
<uses-permission android:name="android.permission.INTERNET" tools:node="remove"/>
```

This is the decision everything else follows from. Android refuses any network request the
app makes, so stored data cannot leave the device through Karde — not through a bug, not
through a future dependency. It also rules out whole categories of feature:

- **No crash reporting**, so a silent failure is invisible to the developer. Startup is
  wrapped and a failure shows a plain screen that says so; Flutter's own red error screen
  is replaced; and a test forbids any `error:` branch that renders an empty box.
- **No "check for updates" over the network.** The app opens its own Play Store page
  instead and lets the store do the network work.
- **Backups never upload.** Karde writes one encrypted file to a folder the user chooses.
  If that folder happens to belong to a cloud service, that service syncs it — and what it
  holds is unreadable without the user's passphrase.

## Features

- **Cards and documents** — card numbers, CVVs, passports, ID cards, licences, private
  notes, and photographs of documents
- **Expiry reminders** — a ladder of local notifications at 90, 60, 30, 14, 7, 3 and 1 days
  before expiry, and the day after. A reminder names nothing, because notifications appear
  on a lock screen
- **A built-in camera** — frames and crops a document without the image passing through
  another app, and strips the GPS coordinates a phone writes into photographs
- **Encrypted backup** — one file, one passphrase, a folder the user picks
- **Share a document** — hands one copy to an app of the user's choosing, then deletes the
  temporary copy. Deliberately no "save to gallery": galleries sync to cloud photo services
- **Three languages** — English, French and Arabic, 571 translated keys each

## Security design

| Concern | Approach |
|---|---|
| Data at rest | AES-256-GCM, key generated in the hardware-backed Android Keystore and marked non-exportable |
| Key access | Per-use authentication — the fingerprint or screen lock is required each time the key is used, not once per session |
| PIN and recovery answers | Stored as one-way hashes, never in readable form |
| Screen capture | `FLAG_SECURE` by default, so screenshots and the recent-apps preview are blocked |
| Android cloud backup | `allowBackup="false"` — the vault cannot be swept into a Google backup |
| Photographs | EXIF stripped before storage, including GPS |
| Release build | R8 minification, resource shrinking, and Dart obfuscation with split debug symbols |

One consequence is stated plainly in the app: removing the device's screen lock destroys
the Keystore key and makes stored items permanently unreadable. An encrypted backup is the
only thing that survives it.

## Architecture

```
lib/
  app/            application shell, startup guard, error panel
  core/
    security/     encryption, authentication, window security, image handling
    storage/      sqflite database, settings, vault reset
    notifications/expiry scheduling and delivery
    platform/     method-channel services (files, backup folder, store listing)
    widgets/      shared widgets, including the secure photo viewer
  features/
    cards/ ids/ backup/ home/ settings/ onboarding/
  l10n/           ARB files for en, fr, ar
```

- **State** — Riverpod
- **Persistence** — sqflite, with payloads encrypted before they reach the database
- **Native work** — Kotlin method channels for the Keystore, the document picker, image
  capture and EXIF stripping
- ~21,400 lines of Dart across 77 files, excluding generated localisations

## Testing

274 tests across 10 files. Alongside the usual unit coverage, several enforce rules that
are easy to regress and hard to notice:

- **No engineering jargon in user-facing text** — a test scans every translated string
- **Every `IconButton` has a tooltip** — screen readers announce "button" otherwise
- **No feature may fail silently** — bans `error: (_, __) => const SizedBox()`
- **Every screen fits or scrolls** — a fixed key size once overflowed a 360×640 phone and
  hid "Forgot PIN?" below the fold
- **Flutter's error widget is never shown**, and its replacement cannot itself throw
- **The camera is declared optional**, or Play hides the app from tablets without one

```bash
flutter test
flutter analyze
```

## Building

```bash
flutter pub get
flutter run

# release bundle
flutter build appbundle --release --obfuscate \
  --split-debug-info=build/debug-info \
  --extra-gen-snapshot-options=--strip
```

Signing is described in [RELEASE_SIGNING.md](RELEASE_SIGNING.md). `key.properties` and the
keystore are deliberately not in this repository.

Minimum SDK 24 — Android 7.0. The floor is set by the Keystore AES-256-GCM and `local_auth`
requirements, not by preference.

## A note on the package name

The Dart package is still `ibank`, the name the project was started under. Renaming it would
rewrite every import for no user-visible gain — the application id, the launcher label and
every string the user sees are all Karde.

---

Built by Temesgen. Published under the developer name Axumora.
