<p align="center">
  <img src=".github/assets/Brand%20Img/AppIcon.png" width="128" height="128" alt="TrueDock icon">
</p>

<h1 align="center">TrueDock</h1>

<p align="center">
  <strong>Dock your TrueNAS.</strong>
  <br>
  A mobile-first, open-source administration client for TrueNAS SCALE Community Edition.
</p>

<p align="center">
  <a href="README.KO.md">한국어</a> | English
</p>

<p align="center">
  <a href="https://github.com/aroxu/truedock/releases/latest"><img src="https://img.shields.io/github/v/release/aroxu/truedock?style=flat-square" alt="Latest release"></a>
  <a href="https://github.com/aroxu/truedock/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/aroxu/truedock/ci.yml?branch=main&amp;style=flat-square" alt="Build status"></a>
  <a href="https://github.com/aroxu/truedock/releases"><img src="https://img.shields.io/github/downloads/aroxu/truedock/total?style=flat-square" alt="Total downloads"></a>
  <a href="https://github.com/aroxu/truedock/stargazers"><img src="https://img.shields.io/github/stars/aroxu/truedock?style=flat-square" alt="GitHub stars"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/aroxu/truedock?style=flat-square" alt="License"></a>
  <img src="https://img.shields.io/badge/TrueNAS-SCALE%2025.10%2B-0095D5?style=flat-square" alt="TrueNAS SCALE 25.10 or later">
</p>

<h3 align="center">Android</h3>

<p align="center">
  <a href="https://github.com/aroxu/truedock/releases/latest"><img src="https://i.ibb.co/q0mdc4Z/get-it-on-github.png" width="200" alt="Get it on GitHub"></a>
  <a href="https://apps.obtainium.imranr.dev/redirect?r=obtainium://app/%7B%22id%22%3A%22me.aroxu.truedock%22%2C%22url%22%3A%22https%3A%2F%2Fgithub.com%2Faroxu%2Ftruedock%22%2C%22author%22%3A%22aroxu%22%2C%22name%22%3A%22TrueDock%22%2C%22overrideSource%22%3A%22GitHub%22%7D"><img src="https://github.com/user-attachments/assets/119e7ff4-2636-43cb-ab7f-1b6a58ac3570" width="200" alt="Get it on Obtainium"></a>
</p>

<h3 align="center">iOS &amp; iPadOS</h3>

<p align="center">
  <a href="https://github.com/aroxu/truedock/releases/latest"><img src="https://i.ibb.co/q0mdc4Z/get-it-on-github.png" width="200" alt="Get it on GitHub"></a>
</p>

### Not working? copy and paste this link into AltStore: `https://truedock.aroxu.me/altstore.json`

<p align="center">
  <a href="docs/support/getting-started.md"><strong>Getting started</strong></a>
</p>

<p align="center">
  <img src=".github/assets/Brand%20Img/Feature%20Image%20-%20EN.png" width="900" alt="TrueDock mobile TrueNAS administration overview">
</p>

## Highlights

- **Live server overview:** Follow system health, alerts, CPU, memory, network traffic, disk I/O, uptime, and active jobs.
- **Storage administration:** Manage pools, disks, datasets, Zvols, snapshots, quotas, permissions, and POSIX1E or NFS4 ACLs.
- **Data protection:** Configure periodic snapshots, replication, cloud tasks, Rsync, and pool scrub schedules.
- **Apps and workloads:** Browse the catalog, install or reconfigure apps, and control services, virtual machines, and supported containers.
- **System control:** Manage accounts, networking, shares, updates, boot environments, alerts, mail, cron jobs, and power actions.
- **Direct and secure:** Connect straight to your NAS over JSON-RPC 2.0 via WSS—without a TrueDock account or intermediary backend.
- **Protected credentials:** Use Keychain or Keystore, a TrueDock PIN, optional biometric unlock, OTP, and per-server certificate review.
- **Built for every screen:** Material Design 3, light and dark themes, custom colors, dynamic type, phones, tablets, and adaptive navigation.

For method-level support, see the [capability matrix](docs/api/capability-matrix.md). Current implementation and release readiness are tracked in [project status](docs/project-status.md).

## Screenshots

<p align="center">
  <img src=".github/assets/Screenshots/Mobile/EN/Mobile%20-%201.png" width="22%" alt="TrueDock overview on a phone">
  <img src=".github/assets/Screenshots/Mobile/EN/Mobile%20-%202.png" width="22%" alt="TrueDock storage screen on a phone">
  <img src=".github/assets/Screenshots/Mobile/EN/Mobile%20-%203.png" width="22%" alt="TrueDock apps screen on a phone">
  <img src=".github/assets/Screenshots/Mobile/EN/Mobile%20-%204.png" width="22%" alt="TrueDock system screen on a phone">
</p>

<table align="center">
  <tr>
    <td align="center">
      <img src=".github/assets/Screenshots/Tablet/10Inch/EN/10Inch%20Landscape%20Screen%201.png" width="440" alt="TrueDock overview on a tablet"><br>
      <sub>Adaptive tablet overview</sub>
    </td>
    <td align="center">
      <img src=".github/assets/Screenshots/Tablet/10Inch/EN/10Inch%20Landscape%20Screen%202.png" width="440" alt="TrueDock administration on a tablet"><br>
      <sub>More room for administration</sub>
    </td>
  </tr>
</table>

## Why TrueDock?

| | TrueDock | TrueNAS web interface on mobile |
| --- | --- | --- |
| Interface | Native, touch-first Material 3 UI | Full desktop administration UI |
| Connection | Direct to your TrueNAS server | Direct to your TrueNAS server |
| Mobile security | PIN vault, biometrics, Keychain/Keystore | Browser credential handling |
| Multiple servers | Saved profiles with authenticated switching | Separate browser sessions |
| Long-running jobs | Global live job center | Web UI job feedback |
| Risky actions | Native, consequence-aware confirmations | Web UI confirmations |

The web interface remains the authoritative fallback for newly introduced or unsupported server capabilities. TrueDock checks the connected server's version, methods, and permissions instead of presenting unavailable controls as functional.

## Installation

TrueDock requires **TrueNAS SCALE Community Edition 25.10 or later** and a secure HTTPS/WSS connection to the server.

### Android

1. Open the [latest GitHub release](https://github.com/aroxu/truedock/releases/latest).
2. Download the APK matching your device. Most current Android devices use `arm64-v8a`.
3. Allow installation from your browser or file manager when Android asks, then install the APK.

The `.aab` asset is intended for store distribution and cannot be installed directly.

### iOS and iPadOS

1. Tap the **Add to AltStore** badge above to add the TrueDock source, then install TrueDock from AltStore.
2. Alternatively, download `truedock.ipa` from the [latest GitHub release](https://github.com/aroxu/truedock/releases/latest) and install it with a compatible sideloading tool.

Availability and refresh limits depend on the signing method and Apple account used by your sideloading tool.

## Quick start

1. Launch TrueDock and enter your TrueNAS HTTPS address.
2. Review the server certificate identity and SHA-256 fingerprint.
3. Sign in with your username and password, or choose API key authentication. TrueDock continues with OTP when the account requires it.
4. Optionally enable **Keep me signed in**, a TrueDock PIN, and biometric unlock.
5. Use the adaptive navigation to open Overview, Storage, Data Protection, Apps, System, or App Settings.

Read the full [Getting Started guide](docs/support/getting-started.md) before approving an unfamiliar certificate or performing destructive operations.

## Privacy

TrueDock connects directly to the server you configure. It has no TrueDock account and no intermediary backend.

Official builds may send anonymous, opt-out crash, error, and sampled performance diagnostics to Sentry. Diagnostics exclude server addresses, resource and account names, certificates, API payloads, credentials, screenshots, and original server error text. Collection can be disabled immediately under **App Settings → Privacy**. Builds without a Sentry DSN send nothing.

See [Anonymous Diagnostics](docs/privacy/diagnostics.md) for the exact collection policy.

## Build from source

### Requirements

- A recent stable [Flutter SDK](https://flutter.dev)
- Xcode for iOS builds
- Android Studio or the Android SDK for Android builds
- A reachable TrueNAS SCALE Community Edition 25.10+ server for live testing

```bash
git clone https://github.com/aroxu/truedock.git
cd truedock
flutter pub get
flutter run
```

Before submitting a change:

```bash
flutter analyze
flutter test
./tool/release_check.sh
```

Use a disposable TrueNAS VM for mutation testing. Never place real server addresses, credentials, API keys, or certificates in source control.

## Tech stack

| Component | Technology |
| --- | --- |
| Application | Flutter and Dart |
| Interface | Material Design 3 with adaptive phone and tablet layouts |
| State and routing | Riverpod and go_router |
| TrueNAS transport | JSON-RPC 2.0 over WebSocket Secure |
| Secure storage | Keychain/Keystore, Argon2id, and AES-256-GCM |
| Local authentication | Face ID, Touch ID, and Android biometrics |
| Reporting | Netdata-backed metrics with fl_chart |
| Diagnostics | Opt-out Sentry crash and sampled performance reporting |
| Supported server | TrueNAS SCALE Community Edition 25.10+ |

## Contributing

Contributions are welcome. Before opening a pull request:

1. Read [AGENTS.md](AGENTS.md) for product scope, architecture, security rules, and the definition of done.
2. Keep changes focused and include tests for changed behavior.
3. Run the verification commands above.
4. Open an [issue](https://github.com/aroxu/truedock/issues/new/choose) before proposing a major architecture, security, or product-scope change.

Bug reports should include the TrueNAS version, relevant permissions, expected behavior, and observed behavior. Reports containing credentials, full server addresses, certificates, or other sensitive information may be removed without notice.

## License

TrueDock is available under the [GNU General Public License v3.0](LICENSE).

<p align="center">
  If TrueDock is useful to you, consider starring the repository.
</p>
