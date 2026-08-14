# ADR 0001: Flutter foundation

Status: accepted

Application identifier: `me.aroxu.truedock` on iOS and Android.

## Decision

- Flutter 3.44 / Dart 3.12, iOS first with an Android target retained.
- Material 3 with `#2E999C` as the default seed and Android dynamic color as an
  optional theme source.
- Riverpod for dependency/state boundaries and go_router for navigation.
- A persistent JSON-RPC 2.0 WebSocket connection via `/api/current`.
- Dio is reserved for API-supported file upload/download flows.
- Keychain/Keystore through flutter_secure_storage and system authentication through
  local_auth.
- SharedPreferences stores non-sensitive appearance preferences only.

## Boundaries

- `core`: API transport, routing, theme, shared UI and security infrastructure.
- `features/*/domain`: immutable application concepts with no Flutter dependency
  unless the type is intrinsically presentational.
- `features/*/data`: TrueNAS DTO mapping and repositories.
- `features/*/presentation`: screens, controllers and widgets.

No credential may enter SharedPreferences. API errors must be mapped before they
reach widgets. Version-specific API behavior stays behind adapters.

## API baseline

TrueNAS SCALE Community Edition 25.10 uses versioned JSON-RPC 2.0 over WebSocket.
TrueDock targets `wss://HOST/api/current`, keeps one authenticated connection alive,
and supports `auth.login_ex` with `API_KEY_PLAIN` and `PASSWORD_PLAIN`. OTP continues
through `auth.login_ex_continue` with `OTP_TOKEN`.

Plain credential mechanisms are allowed only over TLS. Self-signed certificates are
accepted only after an explicit server-specific fingerprint trust decision.

After authentication, TrueDock reads `system.product_type` and rejects anything
other than `COMMUNITY_EDITION`, parses the server version from `system.info`, and
requires 25.10 or newer. `core.get_methods(null, "WS")` becomes the authoritative
runtime capability set so newer features are exposed only when their exact methods
exist on the connected server.

## Implemented security boundary

- Every connection performs a TLS certificate preflight before any credential is
  sent. System-trusted certificates use normal platform validation.
- A self-signed or otherwise untrusted certificate pauses onboarding and shows its
  SHA-256 fingerprint, subject, issuer, and validity before the user can pin it.
- Pins are scoped to the normalized server authority. A different certificate,
  including a newly system-trusted certificate, is treated as a certificate change
  and requires a new explicit trust decision.
- Opt-in reusable credentials normally use Keychain/Keystore storage and require
  an explicit system authentication prompt before retrieval. iOS and Android
  both allow the platform's device-passcode/PIN fallback when biometrics are
  temporarily unavailable.
- One app-wide TrueDock PIN can protect every opted-in server credential and
  provide the fallback when usable biometric authentication is unavailable.
  Argon2id derives a 256-bit key using 19 MiB, two iterations, and parallelism
  one; AES-256-GCM encrypts and authenticates each server independently with a
  fresh 16-byte salt, random nonce, and server-bound associated data. Only the
  versioned envelope and a similarly protected verifier are stored. The
  PIN and derived key are never persisted or synced.
- Server metadata and certificate pins use separate secure-storage namespaces and
  never share the biometric credential vault.
- Android cloud backup is disabled so encrypted preferences cannot be restored
  without their device-bound Keystore keys.

The approved `cryptography` package supplies the RFC 9106 Argon2id and AES-GCM
implementations for the TrueDock PIN vault.
