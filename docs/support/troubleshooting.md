# TrueDock troubleshooting

Symptoms are grouped by what you see. Each entry explains the likely cause
before the fix, because several of these look alike but have different roots.

## Connection

### "TrueDock requires a secure WSS connection"

The address is `http://` or the server has no HTTPS listener. TrueDock does not
fall back to plain HTTP: an API key is password-equivalent, and TrueNAS can
revoke a key that was submitted over an insecure transport. Enable HTTPS on the
server and connect to `https://`.

### The certificate sheet appears every time

A certificate is pinned per server. Seeing the sheet again means the certificate
TrueDock received is not the one you approved. Common causes:

- the certificate was renewed or reissued;
- you are reaching a different host than before, for example a reverse proxy or
  a captive network intercepting the connection.

Compare the SHA-256 fingerprint against the TrueNAS web UI before approving. If
it does not match what the server shows, stop and investigate rather than
approving.

### "TrueDock supports TrueNAS Community Edition only"

The server reports a different product type, such as Enterprise. TrueDock is
built and tested against the Community Edition API only, so it refuses rather
than guessing that another edition behaves the same way.

### "TrueDock requires TrueNAS Community Edition 25.10 or newer"

25.10 is the minimum baseline. Older releases differ enough in the API that
TrueDock cannot safely assume method shapes. Update the server.

### Sign-in fails with a correct password

Check whether the account has two-factor authentication. TrueDock prompts for a
code during sign-in; if the prompt never appears, the server may have rejected
the credential before reaching that step. Also confirm the account is not locked
or password-disabled in TrueNAS.

### The connection drops repeatedly

A banner with Reconnect means the transport went away. Usual causes are the
phone changing networks, sleeping, or a VPN dropping. Data on screen predates
the drop; reconnect before acting on it.

If it drops immediately after connecting, suspect an intermediate proxy that
does not keep WebSocket connections open.

## Missing features

### An action I expect is not shown

TrueDock hides what your server cannot do. Two causes:

1. **The server does not expose the method.** Older releases lack newer
   endpoints. Standalone containers, for example, need TrueNAS 26 or newer;
   on 25.10 only virtual machines appear.
2. **The account lacks the role.** TrueDock discovers available methods for the
   signed-in account. An account without a write role sees read-only views.

Sign in as an account with the required role, or perform the action in the web
UI.

### Some sections load and others show an error

Reads are independent by design: one failing section does not blank the rest.
A section-level message usually means the account cannot read that resource, or
the server does not expose it on this version. The message names the method so
you can check the role that covers it.

## Credentials

### "Keep me signed in" is unavailable

Saving requires an approved protection method. On iOS you need a passcode with
Face ID or Touch ID enrolled. On Android, a secure lock screen and enrolled
biometric use the system prompt; when those are absent, TrueDock offers a
separate app-wide TrueDock PIN. A temporary sensor or platform error does not create
a new fallback vault—retry after the system biometric service is available.

### I forgot my TrueDock PIN

TrueDock cannot recover or sync this PIN. Choose “Forgot PIN?” from the unlock
dialog. The full-page reset requires a random confirmation code and removes all
local TrueDock profiles, saved sign-ins, trusted certificates, PIN data,
biometric copies, and app settings. It never changes data or settings on the
TrueNAS servers. Register the server again and create a new TrueDock PIN.

### I forgot which credential is saved

TrueDock stores the username and method alongside the server so you can tell
saved servers apart, but never displays the secret. Forget the server and add it
again, or revoke the API key on the server and issue a new one.

### I lost my phone

Revoke the API key in the TrueNAS web UI under Credentials → Local Users →
API Keys. That cuts off the app immediately without changing your password. If
you signed in with a password, change it.

## Tasks and jobs

### A task was created but nothing happened

Several task types are staged rather than immediate:

- **Static routes and interface changes** are staged until you commit and check
  in the pending network changes. TrueDock offers those steps after saving.
- **Scheduled tasks** run on their schedule. Check that the task is enabled and
  that the schedule matches what you expected.

### A network change reverted itself

That is the safety mechanism working. Committing network changes starts a
rollback countdown; if the check-in does not arrive, the server restores the
previous configuration. This prevents a bad address from locking everyone out.

If TrueDock lost its connection during the commit, the change is rolled back
because the check-in could not be delivered. Reconnect and try again from a
network path that does not depend on the interface you are changing.

### A cloud sync deleted files I wanted to keep

Check the transfer mode. **Sync** makes the destination match the source, so
files missing from the source are deleted at the destination. **Move** deletes
the source after a successful transfer. Only **Copy** never deletes.

TrueDock states which side loses data in the confirmation before saving.

### A replication overwrote snapshots

Replication overwrites destination snapshots that conflict with the source, and
a custom retention policy destroys destination snapshots past its period. Both
are named in the confirmation before saving.

## Reporting a problem

Include the TrueNAS version, whether the account is an admin, what you expected,
and what happened. Do not include API keys, passwords, encryption passphrases,
or full server addresses. TrueDock redacts secrets from its own logs, but a
screenshot or hand-typed report can still expose them.
