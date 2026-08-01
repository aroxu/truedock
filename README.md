
# TrueDock

A mobile administration client for TrueNAS SCALE Community Edition.

TrueDock replaces routine use of the TrueNAS web UI on a phone with a focused, responsive native app. Built with Flutter and Material Design 3, it talks directly to your server over its own JSON-RPC API. There is no TrueDock account, no backend service, and no data collected beyond an opt-out anonymous diagnostics preference.

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL_3.0-blue.svg)](LICENSE)
[![Platform: iOS & Android](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey.svg)]()
[![TrueNAS: SCALE 25.10+](https://img.shields.io/badge/TrueNAS-SCALE%2025.10%2B-0095D5.svg)](https://www.truenas.com/truenas-scale/)

## Who is this for?

- You want to manage your TrueNAS server quickly from your phone without navigating a desktop-optimized web UI.
- You need to check pools, datasets, and apps status on the go.
- You want to safely execute critical actions with native confirmation dialogs.
- You prefer a direct, secure connection to your server without intermediary cloud services.

## Key Features

- **Secure Onboarding & Credentials**: Certificate identity/fingerprint review, API-key or password login, OTP, and multiple profiles.
- **Biometric & PIN Vault**: "Keep me signed in" backed by Keychain/Keystore, Argon2id + AES-256-GCM PIN vault, and Biometric Unlock.
- **Live Overview**: Real-time CPU, memory, disk I/O, and network reporting.
- **Storage Management**: Pools, topology, disks, datasets, zvols, ACLs, quotas, and snapshots.
- **Data Protection**: Periodic snapshots, replication, Cloud Sync/Backup, Rsync, and scrub scheduling.
- **Shares**: SMB, NFS, and iSCSI (portals, initiators, targets, extents, LUNs, CHAP).
- **Apps & VMs**: Catalog browsing, install, upgrade, reconfigure, VM, and standalone container lifecycle control.
- **System Administration**: Users, groups, privileges, network, alerts, mail, cron jobs, updates, and boot environments.
- **Safe & Responsive UI**: Consequence-aware confirmations for disruptive actions, English localization, dynamic type, and dark mode.

See the [capability matrix](docs/api/capability-matrix.md) for exact method-level coverage, and [project status](docs/project-status.md) for implementation status.

## Documentation

**For Users:**
- [Getting started](docs/support/getting-started.md) — Requirements, connection setup, certificate approval, and secure sign-in.
- [Troubleshooting](docs/support/troubleshooting.md) — Common connection, certificate, and feature visibility issues.

**For Developers:**
- [Project status](docs/project-status.md) — Current scope, implemented areas, and release readiness.
- [Release checklist](docs/support/release-checklist.md) — Automated gates, live-server verification, and submission requirements.
- [Foundation ADR](docs/architecture/0001-foundation.md) & [Phase 5 hardening](docs/architecture/0002-phase5-hardening.md) — Architecture decisions and security reviews.
- [Anonymous diagnostics](docs/privacy/diagnostics.md) — Sentry data collection details.

## Getting Started (Development)

Requirements: A recent [Flutter](https://flutter.dev) stable SDK (`flutter doctor` should be clean), Xcode for iOS, and Android Studio/SDK for Android.

```bash
flutter pub get
flutter run
```

Run against a real TrueNAS SCALE Community Edition 25.10+ server. A disposable VM is recommended for mutation testing.

### Verify your changes

```bash
flutter analyze
flutter test
./tool/release_check.sh
```

## Contributing

Contributions are welcome! Before opening a pull request:

1. Read [AGENTS.md](AGENTS.md) — it documents the product scope, architecture, security rules, and definition of done.
2. Keep changes small and add or update tests for behavior changes.
3. Run the verification steps above before pushing. Localization changes additionally need `python3 tool/arb_lint.py` and `flutter gen-l10n`.
4. Never commit real credentials, server addresses, certificates, or personal data.
5. Discuss major architecture or security changes in an issue first.

Bug reports should include the TrueNAS server version, whether the signed-in account is an admin, and what you expected versus what happened. Do not include API keys, passwords, encryption passphrases, or full server addresses in an issue or screenshot.

## Privacy

TrueDock talks **only** to the TrueNAS server you configure. Official builds may send anonymous, opt-out crash/error/performance diagnostics to Sentry (see [Anonymous diagnostics](docs/privacy/diagnostics.md)). Source and local builds send nothing unless a DSN is supplied at build time.
