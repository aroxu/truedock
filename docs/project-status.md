# TrueDock project status

Snapshot date: 2026-08-16

This is the concise current-state document. The capability matrix remains the
method-by-method source of truth; the Phase 5 audit preserves detailed evidence
and implementation history.

## Product baseline

- Flutter Material 3 application for iOS and Android.
- Application id: `me.aroxu.truedock`.
- App version: `1.0.3+6`.
- Supported server: TrueNAS SCALE Community Edition 25.10 or newer.
- Transport: JSON-RPC 2.0 over WebSocket at `/api/current`; no REST fallback.
- Languages: English and Korean.
- Default Material source color: `#2E999C`, with presets, custom HEX/color
  picker, light/dark schemes, and optional Android dynamic color.

## Navigation and entry

The connected shell has six adaptive destinations: Overview, Storage, Data
Protection, Apps, System, and App Settings. Phones use bottom navigation and
wide layouts use a rail.

Startup is connection-aware:

- no registered server: dedicated registration page;
- registered servers: server picker plus a separate registration action;
- existing server: dedicated authentication/progress page;
- active session: connected shell.

Android Back returns a non-Overview tab to Overview, then exits from Overview.
iOS safe areas, back gestures, keyboard avoidance, and sheets are preserved.

## Authentication and local security

- General username/password login is presented before API-key login.
- TrueNAS OTP continuation is supported.
- Server profiles are always non-secret metadata; saving the reusable secret is
  opt-in.
- Multiple profiles, profile rename, per-server TLS trust, and authenticated
  switching are implemented.
- Reusable credentials live in Keychain/Keystore or the encrypted TrueDock PIN
  vault. The PIN is not stored.
- Biometric Unlock can be enabled when the device supports it and is kept in
  sync between onboarding and App Settings.
- Certificate review is shown for both system-trusted and untrusted
  certificates. Untrusted trust requires explicit consent; changed fingerprints
  require a new decision.
- “Forgot PIN?” opens a full-page device reset. It requires a random
  `XXXX-XXXX` code, erases all local TrueDock data, shows a non-dismissible
  completion dialog, and returns to first use without waiting indefinitely for
  an unreachable server logout.

## Connection resilience

- Unexpected socket loss enters a recoverable connection-lost state.
- The last confirmed UI snapshot remains visible during resume recovery.
- Foreground resume probes the existing session and retries immediately.
- Reconnect remains silent for a seven-second grace period, then shows the
  reconnect banner if recovery still has not succeeded.
- Mutations remain disabled unless the transport is live, even while stale
  read-only data and capability layout are retained.

## Monitoring and jobs

- Overview shows CPU, memory, uptime, health, recent activity, alerts, and live
  reporting.
- Live reporting refreshes every second while Overview is visible. Each refresh
  requests only the elapsed tail (minimum two minutes) and stitches it onto the
  retained hour, so a tick decodes roughly 2,000 samples instead of 39,600. The
  full window is re-read on first load, server switch, resume after a gap, and
  pull-to-refresh.
- Decoded series memoise their derived projections (`totals`,
  `cpuUtilisation`, per-dimension values), so repainting a chart no longer
  rebuilds full-length lists on every frame.
- Charts use `fl_chart`, smooth theme-aware lines, a 100-sample window, no
  update animation, whole-system CPU on a 0–100% scale, and exact text values.
- Multiple network and disk series are swipeable and naturally sorted.
- Active jobs appear through a global FAB, live list, and live detail sheet;
  progress, stage, state, logs, and terminal results update automatically.
  A single reference-counted poller serves every mounted route, so a deep
  navigation stack no longer multiplies `core.get_jobs` traffic.
- Storage, Data Protection, Apps, System, and reporting-history data refreshes
  every second only while the corresponding page is visible and the app is in
  the foreground. The shared server snapshot loads only the active
  destination's API subset, slow reads never overlap, and automatic refresh is
  suspended while an editor/modal or server action is active so live data
  cannot overwrite in-progress input.

## Administration coverage

Implemented or capability-gated surfaces include:

- pools, topology, disks, temperatures, creation, attach/replace,
  online/offline, scrub, export/destruction;
- datasets, zvols, properties, quotas, snapshots, lock/unlock, clone promotion,
  POSIX1E/NFS4 ACLs, and recursive dataset trees;
- SMB/NFS shares and ACLs; WebShare inventory remains read-only on 25.10;
- iSCSI portals, initiators, targets, extents, LUN associations, and CHAP;
- periodic snapshots, replication, Cloud Sync, Cloud Backup, Rsync, and scrub
  tasks;
- installed apps, catalog discovery/install/update/reconfigure, live workload
  resources, services, virtual machines, and capability-gated containers;
- users, groups, privileges, API keys, sessions, audit log, cron jobs, network
  interfaces/routes/global settings, service settings, mail, alert destinations,
  and alert class policy;
- system general settings, configuration backup/reset, update profiles, power,
  and boot environments.

High-risk and critical actions use the shared consequence-aware confirmation
surface. Critical actions require typed confirmation.

## Deliberate product decisions

- System tunables are not exposed.
- Custom firmware upload and the file picker were removed. Updates use the
  server's DEVELOPER, EARLY_ADOPTER, and GENERAL profiles.
- Configuration backup opens the server-generated secure download URL with
  `url_launcher`.
- Unknown TrueNAS/app-catalog content remains server data; known catalog copy
  and all client-owned UI copy are localized.
- No real server address, credential, certificate, or personal test data belongs
  in source control.

## Primary references

- Agent rules: `AGENTS.md`
- API coverage: `docs/api/capability-matrix.md`
- Foundation ADR: `docs/architecture/0001-foundation.md`
- Hardening evidence: `docs/architecture/0002-phase5-hardening.md`
- Release gates: `docs/support/release-checklist.md`
