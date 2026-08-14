# TrueDock Agent Guide

## Mission

TrueDock is a mobile-first Material Design 3 administration client for TrueNAS
SCALE Community Edition. It replaces routine use of the web UI with a focused,
responsive native app while preserving the server's real state, permissions,
validation, warnings, and long-running job semantics.

“Full control” means capability-complete relative to the supported TrueNAS API.
It never means embedding, scraping, or visually cloning the TrueNAS web UI.

Current scope, verification results, and release readiness are a moving target
and are tracked in `docs/project-status.md`,
not here — this file holds rules and conventions, not a dated status log. Exact
API coverage belongs in `docs/api/capability-matrix.md`
. Do not add dated status entries to
this file; update `docs/project-status.md` instead.

## Non-Negotiable Product Scope

- Server family: TrueNAS SCALE Community Edition only.
- Minimum version: 25.10.
- Authentication: ordinary username/password login first in the UI, API key
  second, and OTP continuation for general login.
- Server profiles: support multiple registered servers, per-server credentials,
  per-server TLS trust, server renaming, and authenticated switching.
- Unsupported editions, legacy CORE, and Enterprise-only behaviour remain out of
  scope unless the user explicitly expands scope.
- Version- or permission-dependent features must be hidden, disabled, or
  explained. Never pretend support and never substitute demo data.

## Approved Architecture

Keep work inside the established layers:

- `presentation`: Material 3 screens, sheets, adaptive navigation, view state;
- `domain`: typed models, validation, change descriptions, impact policy;
- `data`: JSON-RPC repositories, DTO mapping, version/capability adapters;
- `platform`/`core`: routing, theme, secure storage, biometrics, TLS, logging,
  connectivity, localization, shared widgets, and dependency injection.

Approved foundations include Flutter, Material 3, Riverpod, go_router,
WebSocket JSON-RPC 2.0, Dio, flutter_secure_storage, local_auth,
shared_preferences for non-secrets, dynamic_color, fl_chart, cryptography,
flutter_svg, and url_launcher. New major dependencies require a user checkpoint.

Prefer immutable models, explicit state transitions, centralized repositories,
and injected platform/network boundaries. Screens must not construct ad hoc API
payloads when a typed configuration or repository method exists.

## Current Product Behaviour

### Entry, authentication, and server switching

- With no registered server, launch directly into the dedicated registration
  page. Never show an empty dashboard.
- With registered servers, show the server picker and a separate “register
  another server” action.
- Opening an existing server uses the dedicated authentication route. Do not
  reopen the registration form or ask for server metadata again.
- Login and switching use simple full-page progress states: “Signing in…” or
  “Switching…”. Once device authentication succeeds, acknowledge it while the
  TrueNAS login continues.
- “Forgot PIN?” leads to the full-page device-data reset flow. Reset requires a
  random `XXXX-XXXX` alphanumeric confirmation code, uses a non-dismissible
  completion dialog, clears local state immediately, and returns to first use.
- A device reset must not wait indefinitely for `auth.logout`; server logout and
  transport close are best-effort after local state becomes authoritative.

### Credential protection

- Reusable credential persistence is always opt-in through “Keep me signed in”.
- “TrueDock PIN” is the product term. Do not reintroduce “app password”.
- Biometric Unlock is optional and controlled in App Settings and onboarding.
- iOS uses Keychain plus Face ID/Touch ID where available.
- Android uses the system biometric prompt and Keystore when secure device
  authentication is available. Without it, biometric controls are disabled and
  the TrueDock PIN vault is the fallback.
- The PIN is never stored or synced. It derives the app-vault key using Argon2id;
  saved credentials are protected with authenticated encryption.
- PIN changes, PIN removal, biometric state, and saved-server credential policy
  must remain consistent across onboarding, login, switching, and App Settings.

### TLS trust

- Connect only over HTTPS/WSS.
- Show certificate identity and fingerprint during registration for both
  system-trusted and untrusted certificates.
- An untrusted certificate requires explicit opt-in before continuing.
- Persist trust per server profile. A changed certificate requires a new
  decision and must never silently replace the saved fingerprint.
- User-facing terminology is “Trusted Certificate”, not “pinned certificate”.

### Navigation and lifecycle

The adaptive shell has six destinations:

1. Overview
2. Storage
3. Data Protection
4. Apps
5. System
6. App Settings

Use bottom navigation on phones and a navigation rail at wide widths. On Android,
Back from any non-Overview destination returns to Overview; Back again exits.
Preserve iOS back gestures, safe areas, Dynamic Island clearance, keyboard
avoidance, and sheet behaviour.

When the app resumes, keep the last confirmed data visible. Probe and reconnect
silently; show the reconnect banner only if recovery has not succeeded within the
seven-second grace period. Never clear whole screens merely because the app was
briefly backgrounded.

### Refresh and jobs

- Use pull-to-refresh inside the safe area for manual refresh.
- Overview live reporting refreshes every second while visible and connected.
- Update status refreshes every second while the update screen is active.
- Show active jobs through the global FAB, list sheet, and detail sheet. All
  three must update progress, stage, state, and terminal results live.
- Long-running mutations are jobs. Do not report success until the API response
  or terminal job state confirms it.

### Design and presentation

- Use Material Design 3 consistently. Default source color is `#2E999C`.
- Generate light/dark schemes from the source color. Appearance supports presets,
  a six-digit HEX value, a color picker, and optional Android dynamic color.
- Use compact, scannable administrative layouts. Avoid oversized cards and
  excessive top padding.
- Dropdowns use the shared Material choice sheet, approximately 60% of the
  screen, with search when the option set warrants it.
- Text fields and dropdowns must not render floating labels protruding through
  their outlines. Long text wraps instead of being clipped.
- Preserve deliberate motion: page slides, animated expansion arrows, dataset
  trees, category expansion, ripple/pressed feedback, and reduced-motion support.

### Reporting charts

- Use `fl_chart` and the shared chart styling.
- Charts are smooth line charts, theme-aware, and use a logarithmic display
  transform where required to reduce extreme visual gaps.
- Keep up to 100 samples and avoid animation when new samples arrive.
- CPU is whole-machine utilization on a 0–100% scale, not summed per-core usage.
- Overview includes CPU, memory, disk I/O, and naturally sorted network series.
- Do not show redundant minimum/maximum labels at the two ends of a chart.
- Charts must remain understandable without color alone and expose exact values.

### Storage and Apps UX decisions

- Sort disk and interface identifiers naturally (`sda`, `sdb`, `nvme0p1`,
  `enp6s18`, `enp6s19`, `enp6s20`).
- Dataset trees are recursively expandable at every level. Parents toggle their
  children with an animated indicator left of the folder icon; leaf taps do
  nothing unless a contextual action explicitly owns the tap.
- Dataset ACL supports owner/group changes, POSIX1E and NFS4 conversion with a
  warning, searchable principal pickers, and independent POSIX read/write/execute
  checks.
- App install/reconfigure forms are recursively grouped and expanded by default;
  every category can collapse independently.
- App details show live CPU, memory, network, disk, workload, and configured
  resource information. Reconfiguration must use the current server config.
- WebShare remains read-only on 25.10 because the supported API exposes query but
  no create/update method.
- Custom firmware upload and file-picker support were deliberately removed.
  System update uses the server's DEVELOPER, EARLY_ADOPTER, and GENERAL profiles,
  localized as Developer Beta, Early Adopter, and General.
- System tunables are deliberately not exposed in the UI.

## API and Data Rules

- Use documented JSON-RPC 2.0 over `wss://HOST/api/current`; do not add REST API
  authentication or REST fallbacks.
- Discover product type, server version, methods, permissions, and optional
  capabilities after connecting.
- Treat 25.10 as the baseline and gate newer surfaces instead of assuming forward
  compatibility.
- Preserve server validation detail. Stable client-owned errors use typed codes
  and ARB localization; raw client exception strings must not reach widgets.
- Server-provided identifiers, paths, proper nouns, and app-specific catalog text
  are data, not client copy. Translate known TrueNAS catalog strings without
  inventing translations for unknown server content.
- Never retry a non-idempotent mutation unless retry safety is proven.
- Keep WebSocket/event updates where supported and use bounded polling only where
  necessary.
- Keep contract fixtures and tests aligned with every supported release family.

## Security and Privacy Rules

- Never commit real server addresses, credentials, API keys, certificates,
  personal data, generated reset codes, or build artifacts.
- Official builds may use Sentry for anonymous crash, error, and sampled
  performance diagnostics. Collection is opt-out, disclosed on first use, and
  immediately controllable under App Settings > Privacy.
- Builds without `TRUEDOCK_SENTRY_DSN` must run normally and send no diagnostics.
  Never commit Sentry management tokens or upload credentials.
- Keep Sentry PII, logs, user-interaction analytics, automatic sessions,
  screenshots, view hierarchy, feedback, attachments, and Session Replay off.
  Never send TrueNAS addresses, server/resource/account names, certificates,
  API methods or payloads, credentials, breadcrumbs, or original error text.
- Retain only crash type and stack location, anonymous app/platform metadata,
  and sampled app-start, screen-load, and frame-performance data. Disabling
  collection must close the SDK immediately, and diagnostic envelopes must not
  be persisted on the device.
- Never place secrets in logs, analytics, crash reports, ordinary preferences,
  screenshots, model `toString` output, or UI state not designed for secrets.
- Keep sessions in memory where possible. Reauthenticate only from an approved
  secure source.
- Redact any field name ending in password, passphrase, secret, token, key, salt,
  OTP, session, two-factor code, or equivalent secret-bearing suffix.
- Write-only server secrets remain blank on edit and are sent only when the user
  intentionally changes them, unless an API requires retaining a server-returned
  secret internally. Such values must never enter presentation models or logs.
- Real NAS systems are high-value targets. Read-only inspection is preferred;
  mutation testing is allowed only against a server the user explicitly approved.

## Mutation Safety

Classify mutations by impact:

- **Low:** reversible preference or ordinary service/app action.
- **Medium:** resource creation or configuration with non-obvious consequences;
  show review when needed.
- **High:** pool/disk changes, credential changes, service interruptions, network
  changes, restart, shutdown, update, rollback, and similar disruptive actions;
  require a confirmation naming server, target, and consequences.
- **Critical:** irreversible destruction or forced data removal; require typed
  confirmation and an unambiguous final action label.

Never disable confirmation globally. Never hide API warnings or partial failures.
Never expose a stale control as usable merely because old capability data is still
being shown during reconnect.

## Localization, Accessibility, and Error Copy

- Translations are not supported; keep English strings in app_en.arb.
- No client-authored user-facing prose may be hardcoded in presentation, app,
  shared-widget, or security-prompt code.
- Preserve API names, protocol identifiers, units, and proper nouns when they are
  the actual data the user needs.
- Run `tool/arb_lint.py` after changing ARB files and regenerate localization
  sources with `flutter gen-l10n`.
- Dynamic text, 2x text scale, screen-reader labels, contrast, dark mode, small
  phones, tablets, and narrow sheets are requirements.
- Every async surface needs applicable loading, success, empty, stale/offline,
  permission, and error states.

## Verification Workflow

Before changing code:

1. Read nearby implementation and tests.
2. Check the dirty worktree and preserve unrelated user changes.
3. Check the capability matrix and official documentation when API behaviour is
   involved.

Before handing off code:

1. Format touched Dart files.
2. Run `flutter analyze`.
3. Run focused tests for the changed behaviour.
4. Run `python3 tool/arb_lint.py` for localization changes.
5. Run the full `flutter test` suite for broad or cross-cutting changes.
6. Build and install on the iOS Simulator for UI/runtime changes.
7. Use approved fixtures, integration tests, or an explicitly approved disposable
   TrueNAS server for API mutations.
8. Run `./tool/release_check.sh` before a release candidate.

Release APK helper:

```sh
tool/build_android_release.sh
```

This currently produces a release-optimized APK signed by the debug key. Do not
describe it as store-ready until production signing is configured and verified.

## Definition of Done

A feature is done only when it has:

- capability/version/permission gating;
- typed domain and repository handling;
- impact-appropriate validation, review, and confirmation;
- localized Material 3 UI for applicable states;
- tests for success and meaningful failure paths;
- accessible labels, dynamic-text resilience, and dark-mode review;
- redacted logging and no secret persistence regressions;
- simulator verification and, where applicable, fixture or approved live-server
  verification.

## Required User Checkpoints

Stop and ask before:

1. adding a major architecture dependency outside the approved set;
2. expanding beyond Community Edition 25.10+;
3. implementing a new irreversible/high-risk workflow not already approved;
4. mutating a real non-disposable server without explicit approval;
5. changing the six-destination navigation model;
6. changing credential, PIN, biometric, or TLS trust policy;
7. making a scope change that materially affects schedule or architecture.

Ordinary UI polish, localized copy corrections, tests, and safe implementation
details may proceed autonomously. If a real risk or ambiguous product decision is
encountered, stop immediately and ask rather than guessing.

## Documentation Map

- `README.md`: public project overview and basic commands.
- [`docs/project-status.md`](docs/project-status.md): current product, verification, and release snapshot.
- [`docs/architecture/0001-foundation.md`](docs/architecture/0001-foundation.md): approved foundation ADR.
- [`docs/architecture/0002-phase5-hardening.md`](docs/architecture/0002-phase5-hardening.md): hardening evidence and history.
- [`docs/api/capability-matrix.md`](docs/api/capability-matrix.md): method-by-method capability truth.
- [`docs/support/getting-started.md`](docs/support/getting-started.md): user onboarding.
- [`docs/support/troubleshooting.md`](docs/support/troubleshooting.md): user-facing failure guidance.
- [`docs/support/release-checklist.md`](docs/support/release-checklist.md): blocking automated and manual release gates.
