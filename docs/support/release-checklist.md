# TrueDock release checklist

Run through this before submitting a build. Items marked **blocking** must pass;
the rest are judgement calls to record rather than silently skip.

## Automated gates (blocking)

On macOS, run the complete local gate (including both platform builds and the
bundled iOS privacy-manifest check) with:

```sh
./tool/release_check.sh
```

The equivalent individual commands are:

```sh
flutter analyze          # must report no issues
flutter test             # must be fully green
flutter build apk --debug
flutter build ios --simulator --no-codesign
python3 tool/schema_audit.py tool/fixtures/methods.json lib
```

The schema audit compares every method name and payload key TrueDock sends
against a schema captured from a real server. It found four defects that no
fixture could catch, because the fixtures asserted the same wrong shape the app
was sending: `app.delete` sent a field that does not exist, `system.reboot` and
`system.shutdown` wrapped a positional argument in an object, and
`interface.commit_node` is not a method on 25.10 at all.

Refresh the captured schema when adding support for a new server release:

```sh
dart run tool/schema_dump.dart <host> <user> <password> tool/fixtures/methods.json
```

The dump holds only method signatures — no address, credential, or server data.

The test suite includes gates that are easy to lose by accident:

- `test/core/logging/redacted_logger_test.dart` asserts every secret-bearing
  field TrueDock sends is redacted. **If you add a field carrying a password,
  key, token, or salt, add it to that list.**
- `test/contract/release_family_contract_test.dart` pins the method surface for
  every supported release family. **If a feature depends on a new method, add it
  there and decide consciously which families support it.**
- `test/accessibility/editor_accessibility_test.dart` checks tap targets,
  labels, contrast, dynamic type, and dark mode for the configuration editors.
  **New editors belong in that list.**

## Runtime verification (blocking)

Building is not booting. Install and launch on a simulator or device and
confirm:

- the app reaches the Overview screen;
- no exception or assertion appears in the log;
- the six destinations navigate.

```sh
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
xcrun simctl launch booted me.aroxu.truedock
xcrun simctl spawn booted log show --predicate 'process == "Runner"' \
  --last 2m --style compact | grep -iE "error|exception|fatal|crash"
```

## Live-server verification (blocking for a public release)

Most of this is automated now. Against a disposable TrueNAS SCALE Community
Edition server:

```sh
dart run tool/live_server_probe.dart   <host> <user> <password>   # 15 reads
dart run tool/live_mutation_probe.dart <host> <user> <password>   # 41 writes
dart run tool/live_app_lifecycle_probe.dart <host> <user> <password> [app]
dart run tool/live_reboot_probe.dart   <host> <user> <password>   # restarts it
dart run tool/live_auth_probe.dart    <host> <user> <password>   # auth paths
```

The mutation and lifecycle probes are destructive: they consume disks the server
reports as unused, and the lifecycle probe repoints the server-wide Docker pool
setting (restoring it afterwards). The reboot probe actually restarts the
server. Never point them at a system anyone depends on.

Then drive the shipped app itself, which is what catches defects that live in
the widget tree rather than in a payload:

```sh
flutter test integration_test/live_server_test.dart -d <deviceId> \
  --dart-define=TRUEDOCK_LIVE=1 \
  --dart-define=TRUEDOCK_HOST=<host> \
  --dart-define=TRUEDOCK_USER=<user> \
  --dart-define=TRUEDOCK_PASSWORD=<password>
```

Uninstall the app first to exercise the certificate trust-on-first-use path;
otherwise the previously trusted certificate short-circuits it. This is how the concurrent
call limit was found: the server rejects the 21st concurrent call, and Overview
fans out more than twenty section reads, so the dashboard failed on a real
connection while every fixture passed.

The auth probe covers what used to be a manual sign-in pass: it issues a real
API key, authenticates with the exact payload `ApiKeyCredential` builds, revokes
the key, and proves the revoked key is then refused. It also confirms the
server's certificate fingerprint is stable across connections — worth checking
before trusting a pin at all, since a server rotating certificates per
connection would make the trust prompt fire constantly.

Still manual, because no probe covers them:

- sign in with 2FA enabled. The probe reports whether the server has it on, but
  completing the challenge needs an authenticator; the app's `OTP_REQUIRED`
  branch stays widget-tested.
- confirm a *changed* certificate forces a new trust decision **on a real
  server**. The transport-level behaviour is asserted by
  `test/core/security/tls_certificate_service_test.dart`, which pins one
  fingerprint, presents a different certificate, and requires the resulting
  error to report `isCertificateChange` with the previous fingerprint. What no
  test can cover is the server actually being re-keyed, so do that once against a
  disposable server before a public release.

Two items that used to sit on this list are covered by tests instead, and are
worth spot-checking rather than re-verifying by hand:

- multi-server registration and switching:
  `test/features/connection/presentation/server_switch_controller_test.dart`
  and `server_management_screen_test.dart` assert each server keeps its own
  credential and trusted certificate fingerprint, that switching confirms first and names the
  target, and that forgetting the active server disconnects it.
- destructive confirmations: `test/core/widgets/destructive_confirmation_test.dart`
  asserts the sheet names the server and target, that a critical action stays
  disabled until the name is typed, and that dismissing it does not confirm.

Record the server version tested.

## Android signing

Android release signing reads `android/key.properties`, which is ignored by
Git. Copy `android/key.properties.example`, keep the keystore outside the
repository, and fill in all four values:

```properties
storeFile=~/WorkSpace/Android/aroxu.jks
storePassword=<keystore password>
keyAlias=<key alias>
keyPassword=<key password>
```

Never commit the keystore or `key.properties`. The release build fails instead
of silently falling back to the Android debug key when any value is missing.

## iOS submission

- `ITSAppUsesNonExemptEncryption` is declared in `Info.plist`, so the upload
  does not stall on export compliance.
- `PrivacyInfo.xcprivacy` exists **and is registered in the Xcode project**.
  Verify it reaches the bundle, not just the source tree:

  ```sh
  ls build/ios/iphonesimulator/Runner.app/PrivacyInfo.xcprivacy
  ls build/ios/iphonesimulator/Runner.app/Frameworks/Sentry.framework/PrivacyInfo.xcprivacy
  ```

- Usage strings are present and truthful: `NSFaceIDUsageDescription`,
  `NSLocalNetworkUsageDescription`.
- `version:` in `pubspec.yaml` is bumped.

Then produce the signed build:

```sh
export TRUEDOCK_TEAM_ID=<team id>
./tool/release_archive.sh            # gates, archive, export a signed IPA
./tool/release_archive.sh --upload   # also validate and submit
```

Local Sentry values come from the gitignored `sentry.properties` generated by
the Sentry wizard (`url`, `org`, `project`, `dsn`, and `auth_token`). CI can use
`SENTRY_URL`, `SENTRY_ORG`, `SENTRY_PROJECT`, `TRUEDOCK_SENTRY_DSN`, and
`SENTRY_AUTH_TOKEN` instead. Never commit `sentry.properties`.

`release_archive.sh` runs the full local gate before it archives, so a build
that fails analysis, tests, or the schema audit cannot reach the store. Pass
`--skip-gates` only to re-export an already-verified tree.

Uploading uses an App Store Connect API key rather than an account password, so
the credential can be revoked on its own:

```sh
export TRUEDOCK_ASC_KEY_ID=<key id>
export TRUEDOCK_ASC_ISSUER_ID=<issuer id>
export TRUEDOCK_ASC_KEY_PATH=/secure/path/AuthKey_<key id>.p8
```

The script validates with App Store Connect before uploading — that is what
catches a reused build number or an unregistered privacy manifest now, instead
of an email hours later. It copies the key only if App Store Connect's
conventional location does not already hold it, and removes that copy on exit
even when the upload fails.

## App Store privacy answers

TrueDock connects to the user's own server and has no TrueDock account,
advertising, or user-behaviour analytics. Official builds use Sentry for the
opt-out anonymous diagnostics documented in `docs/privacy/diagnostics.md`.

| Question | Answer |
| --- | --- |
| Does the app collect data? | Yes: crash, performance, and other diagnostic data when anonymous diagnostics is enabled |
| Does the app track users? | No |
| Third-party diagnostics | Sentry, for App Functionality only |
| Third-party advertising | None |
| Data linked to the user | No |
| Data used for tracking | None |

Credentials are stored in the platform keychain on the user's own device and
transmitted only to the server the user configured. They never enter Sentry.
Sentry's bundled privacy manifest declares unlinked, non-tracking Crash Data,
Performance Data, and Other Diagnostic Data for App Functionality. Keep the
App Store Connect answers aligned with that manifest and the in-app opt-out.

## Security review

- No credential, passphrase, key, or salt appears in logs, ordinary storage, or
  crash reports.
- No real server address, credential, or personal data is committed.
- New mutations are capability-gated and routed through the shared confirmation.
- Destructive actions name the server, the target, and the consequence, and the
  irreversible ones require typed confirmation.

## Known gaps to disclose

Keep this honest in release notes rather than discovering it in review:

- resume health-check and refresh behaviour is widget-tested, sustained
  connection flapping is covered by a ten-cycle drop/reconnect test, and the
  read, write, app-lifecycle, restart, and authentication paths are verified
  against a live TrueNAS-25.10.5 server; real app suspension and performance
  profiling under a release build still need a physical device;
- the live probes cover one server release family at a time. A newer server may
  change a payload the captured schema no longer describes, so refresh
  `tool/fixtures/methods.json` and re-run the probes for each family you claim
  to support;
- Only English is supported.
