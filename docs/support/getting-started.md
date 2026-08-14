# Getting started with TrueDock

On first launch, TrueDock opens the dedicated server registration screen when
no server has been registered. The six-destination administration shell is
shown only after a live server connection succeeds, so an empty dashboard is
never presented as useful server state. If registered profiles already exist,
the same entry screen offers them above the new-server form. Profiles remain
registered even when “Keep me signed in” is off; in that case TrueDock asks for
the credential again and never stores the secret.

TrueDock manages a TrueNAS SCALE Community Edition server from your phone. It
talks to your server directly; there is no TrueDock account and no service in
between.

## Before you connect

You need:

- **TrueNAS SCALE Community Edition 25.10 or newer.** TrueDock refuses to
  connect to older releases and to non-Community editions, because it is built
  and tested against the Community Edition API only.
- **Network access to the server** from your phone. TrueDock connects to your
  server directly, so the two must be able to reach each other — usually the
  same network, or a VPN back to it.
- **HTTPS enabled on the server.** TrueDock requires a secure `wss://`
  connection and will not fall back to plain HTTP.

## Choosing how to sign in

TrueDock supports two methods. Both are equally protected inside the app.

**API key (recommended).** Create one in the TrueNAS web UI under
Credentials → Local Users → your user → API Keys. An API key can be revoked on
the server without changing your password, so if you lose your phone you can cut
off access from anywhere.

**Username and password.** Use your normal TrueNAS login. If the account has
two-factor authentication, TrueDock prompts for the code during sign-in.

Treat an API key like a password: anyone holding it can act as your account.

## The first connection

1. Enter the server address, for example `https://nas.local` or
   `https://192.168.1.10`.
2. If the server uses a self-signed certificate, TrueDock shows the
   certificate's identity and SHA-256 fingerprint and asks you to approve it.
   **Compare that fingerprint against the one shown in the TrueNAS web UI
   before approving.** Approving pins that exact certificate to that server.
3. Sign in with your API key or username and password.
4. TrueDock reads the server version and available features, then opens the
   Overview.

If the certificate later changes, TrueDock asks again rather than silently
accepting the new one. That is deliberate: an unexpected change can mean the
certificate was renewed, or that something is impersonating your server.

## Staying signed in

"Keep me signed in" is off by default. Turning it on stores your credential in
protected device storage and asks for Face ID, Touch ID, fingerprint, or device
unlock before a saved sign-in is released.

TrueDock can protect reusable sign-ins with one separate app-wide TrueDock PIN
and optionally use Face ID, Touch ID, or fingerprint for Biometric Unlock. The
PIN-derived vault encrypts every opted-in server independently; the PIN itself
is never stored or synced. Forgetting it opens the device-data reset flow, which
erases all local TrueDock profiles, saved sign-ins, trusted certificates, PIN
data, biometric copies, and app settings. TrueNAS server data is never changed.

TrueDock never uploads your credential anywhere, and never writes it to logs,
ordinary app storage, or crash reports.

## Finding your way around

Six destinations:

- **Overview** — health, alerts, capacity, and recent activity at a glance.
- **Storage** — pools, disks, datasets, and snapshots.
- **Protection** — replication, snapshot tasks, cloud sync, rsync, and scrubs.
- **Apps** — installed apps, the catalog, virtual machines, and containers.
- **System** — accounts, network, updates, jobs, and settings.
- **App Settings** — appearance, app PIN, Biometric Unlock, trusted
  certificates, registered servers, and local device data.

## How TrueDock handles risky actions

Anything that can lose data, interrupt a workload, or change credentials shows a
confirmation sheet naming the server, the target, and what will actually happen.
The most destructive actions, such as destroying a pool, require you to type the
name first.

TrueDock never reports success before the server confirms it. Long operations
appear as jobs you can follow, and a failure shows what the server said rather
than a generic error.

## When the connection drops

If the connection drops, TrueDock keeps the last confirmed data visible and
tries to recover silently. If recovery has not succeeded within seven seconds,
a banner appears with a Reconnect button. Treat visible values as a snapshot
rather than live state until the connection is restored.

## Features your server does not have

TrueDock checks which methods your server exposes and hides what it cannot do.
If an action is missing, it usually means either the server version does not
support it, or the account you signed in with lacks the required role. When the
server refuses an action, TrueDock shows the server's own explanation.
