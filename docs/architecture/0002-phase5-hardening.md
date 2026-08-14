# 0002 — Phase 5 hardening audit

Status: in progress
Date: 2026-08-11

Records what the Phase 5 hardening pass verified, what it changed, and what
remains before a release can be cut. Phases 0–4 closed every capability gap in
`docs/api/capability-matrix.md`; this document covers the review work that
AGENTS.md requires on top of feature completeness.

## Secret and log audit

Enumerated every field TrueDock sends that can carry a secret, then probed the
redactor against each one. Two leaked in plaintext:

- `key`, sent by `pool.dataset.unlock` as a raw hex encryption key.
- `encryption_salt`, sent by `cloudsync.create` / `cloudsync.update`.

Neither matched the redactor's exact-name allowlist. The long-hex rule covered
`key` only by coincidence, when the value happened to be 32+ hex characters; a
shorter or non-hex key was written verbatim.

The allowlist is replaced by a suffix rule: a field name ending in `password`,
`passphrase`, `secret`, `token`, `key`, `salt`, `otp`, `session`, or
`two_factor_code` is redacted, with or without a prefix. This fails safe for
fields added later, and an over-redacted ordinary field is far cheaper than a
leaked secret. A regression test asserts every secret-bearing field TrueDock
sends is redacted.

Verified with no change required:

- `SavedServer.toJson` persists only the profile, username, auth method, and a
  boolean saying whether a separate protected vault entry exists.
- Biometric sign-in explicitly invokes `local_auth.authenticate` before reading
  a reusable credential from the Keychain/Keystore. An Android device that
  cannot offer a usable biometric flow instead uses the opt-in TrueDock PIN
  vault documented in ADR 0001; its Argon2id and AES-256-GCM envelope is covered
  by round-trip, wrong-password, server-binding, tamper, and global-reset tests.
- The credential types declare no `toString` override, so the Dart default
  prints the type name rather than field values.
- No logger call receives a credential or secret variable.
- Only theme preferences reach ordinary (non-secure) storage.

The TrueDock PIN dialogs are covered separately from the configuration
editors because they are reached during onboarding rather than administration.
The creation dialog renders in English at 2x text scale without overflow, and the
unlock dialog passes Android/iOS tap-target, labelled-target, and text-contrast
guidelines. This closes the keyboard-and-dynamic-type risk for the only new
credential entry surface introduced by the fallback vault.

## Accessibility audit

`test/accessibility/editor_accessibility_test.dart` runs Flutter's built-in
guideline checks against the five configuration editors (replication, rsync,
cloud sync, interface, static route), seeded with realistic values and the
shipped `#2E999C` scheme:

- `androidTapTargetGuideline` and `iOSTapTargetGuideline`;
- `labeledTapTargetGuideline`, so screen readers announce every tappable;
- `textContrastGuideline` in both light and dark schemes;
- a 2x text-scale render per editor, proving the layout absorbs dynamic type
  without a `RenderFlex` overflow.

All 15 checks pass with no production change required.

## Runtime verification

Previous turns verified `flutter build ios --simulator` only, which proves
compilation rather than behaviour. The app is now installed and launched on a
booted simulator (iPhone 17 Pro, iOS 26.5):

- it boots and renders the connected shell with all six destinations;
- the seeded Material 3 theme is applied;
- the simulator log shows no exception, assertion, or crash;
- `LocalAuthentication` reports `No identities are enrolled` and the app
  degrades gracefully instead of failing. The iOS Simulator cannot exercise the
  Android hardware-backed PIN/biometric path, whose hardware pass remains a
  manual release gate.

## Connection resilience

Reviewing the reconnect path turned up a bug rather than a gap. The client
detected a dead transport, but nothing told the app: every screen gates on
`NasConnectionState.isConnected`, which is derived purely from the last stage
the controller set. After a dropped socket the UI kept rendering as though the
server were reachable — stale data with no indication it was stale, and
controls that could not work.

The client now exposes a `connectionLost` stream, emitted from both the socket
error and socket close handlers, and clears its channel on an error as well as
a close so `isConnected` cannot be left stale. A deliberate `close()` clears
the subscription first, so an intentional disconnect can never be mistaken for
a drop.

The controller subscribes to that stream and moves to a new
`ConnectionStage.connectionLost`, distinct from `failure` (a connection that
never succeeded). It keeps the profile and username so the user can reconnect
in one tap, and discards capabilities and system info, which describe a dead
session; stale capabilities would let the UI keep offering gated actions.

The app shell renders a persistent banner for that state, placed in the shell
because a drop affects every destination and the user may be anywhere when it
happens. The banner names the server, states that the visible data is the last
TrueDock received, offers Reconnect using the in-memory credential, and leaves
navigation intact.

The first banner implementation exposed a second bug: successful login cleared
the credential that `reconnect()` claimed to reuse, and the widget test only
asserted that the banner disappeared. A failed retry changed state away from
`connectionLost`, so that weak assertion still passed. The active credential is
now retained only in process memory, cleared on explicit sign-out and controller
disposal, and copied into the pending authentication flow only for a reconnect.
The regression test requires a second socket, a second `auth.login_ex`, and a
terminal `connected` state. Failed retries remain in `connectionLost` so the
retry affordance stays visible.

Covered by tests at both layers: the client transport (in-flight calls fail on
a clean close and on an error, concurrent calls all fail, `isConnected` flips,
a later call fails fast, listeners see the drop) and the controller and shell
(a drop leaves the connected state, retains the profile, discards
capabilities, a deliberate disconnect is not reported as a loss, and the
banner appears, warns about stale data, preserves navigation, and clears on
reconnect).

## Background and resume

The shell now observes the Flutter application lifecycle. On resume it probes
the established session with `system.info`; only a successful probe invalidates
the shared server-resource, reporting, app-catalog, and system-resource
snapshots. A failed probe discards capabilities and system information and moves
to the recoverable lost-connection state, so values read before suspension are
never presented as current.

A widget test drives the complete paused-hidden-inactive-resumed transition and
asserts the second `system.info` health probe. Physical-device suspension,
sustained network flapping, and performance profiling remain manual gates.

## Localization readiness

Added Flutter's ARB-based localization pipeline, generated localization classes,
and all Material, Widgets, and Cupertino delegates. The adaptive navigation,
lost-connection surface, Overview dashboard, connection form, saved-server
picker, certificate review, OTP dialog, System landing screen, general-settings
confirmation, and Appearance controls now consume generated strings,
proving that both application and framework strings follow the active locale.
Generated classes are committed so a clean clone can analyze and build without
a separate code-generation step.

Only English is supported, and the user-facing string migration is
complete: every screen, sheet, confirmation, snackbar, and validation message
resolves through the generated `AppLocalizations` family rather than an inline
literal.

## Application entry

The root route is now a connection-aware entry gate. While disconnected it
shows the dedicated server registration screen, including protected saved
sign-ins when present; it does not construct the six-destination shell or an
empty Overview dashboard. After authentication reaches `connected`, the same
root route swaps to the administrative shell. Explicit disconnect returns to
the entry screen automatically, and `/servers/new` remains available for adding
another server from an active session.

Server registration is separate from credential persistence. After a successful
connection, TrueDock always stores the non-secret profile, username, and auth
method, while the vault receives the reusable secret only when “Keep me signed
in” is selected. Metadata records whether a vault entry exists; legacy entries
default to true because the old format was written only alongside a credential.
A registered profile without a secret is labelled “Sign in required” and
prefills the server, account, and auth method before asking for a fresh secret.
This profile model supports the implemented App Settings server manager and
active-server switcher without weakening the per-server credential policy or
trusted certificate fingerprint.

The route layer also listens to connection-stage changes. Any non-public deep
link (currently the System administration routes) redirects to the root entry
screen while disconnected, and an open administration route is evicted as soon
as a live session is lost. This extends the no-empty-shell rule beyond ordinary
startup navigation and prevents stale privileged detail screens from surviving
a disconnect.

## Active-server switching

The Settings server row previously led only to a fresh registration screen, so a
second server could be registered but never selected: the profile model
supported switching while the UI did not. A dedicated switcher
(`/settings/servers`) now lists every registered profile and marks the active one.

A switch ends the previous session with `auth.logout` before authenticating
elsewhere. Closing the socket alone would leave the old session authenticated on
the first server until it timed out. Each target reconnects through its own
vault entry and trusted certificate fingerprint rather than mutating the live connection,
because per-server credential and TLS-trust isolation is the whole point of the
profile model. The active row is not selectable, so a stray tap cannot sign the
user out of the session in use, and forgetting the active server disconnects it
before clearing its credential. A transport failure during sign-out no longer
blocks the local teardown: TrueDock's own authenticated state is cleared
regardless, so a failed `logout` cannot leave the app believing it is still
connected.

Covered at both layers: the controller (the target server is connected, the
previous session is logged out, the target's own credential is unlocked, its
certificate pin is carried, selecting the active server is a no-op, and a target
with no saved credential fails without silently keeping the old session) and the
screen (the active server is labelled and untappable, a fresh-sign-in server is
labelled, switching and forgetting each require confirmation, and forgetting the
active server disconnects first).

## Service start-on-boot

Services exposed start/stop but not the persisted boot setting, so a service
could be started without surviving a reboot. `service.control` changes only the
current run state; the boot setting is a separate `service.update` mutation
keyed by the service record id rather than its name.

The two mutations use independent busy keys so a boot change and a start/stop on
the same row cannot mask each other's progress. The boot change routes through
the shared high-impact confirmation, which states that the setting takes effect
at the next boot and that the service is neither started nor stopped now — the
failure mode worth preventing is a user believing they just restarted something.
The control is capability-gated on `service.update`, and when the method is
absent the boot state remains visible as information rather than disappearing.

## Disk thermals

The Storage screen advertised "Inventory, SMART, temperatures" while the app read
neither: nothing in the codebase called any thermal or SMART method. 25.10
removed the entire `smart.*` namespace, so the promise could not be kept as
written, and `disk.temperatures` is the supported replacement.

Temperatures are now read for the disks the inventory actually returned. The
device list matters: calling with an empty list makes the server poll every disk
it knows about, so the call is skipped when no disks were found. It runs after
the inventory rather than inside the parallel batch because it depends on that
result, and a failure, permission error, or missing method degrades to an
unavailable reading without touching the disk list.

Judging the reading needed care. A fixed warning threshold would be wrong across
HDD, SSD, and NVMe, so the drive's own reported maximum and critical values are
used and a drive that reports neither is never shown as alarming. A drive TrueNAS
could not read reports null, which is not zero: it renders as "Unavailable" in
the detail sheet and as nothing in the list, because 0 °C would read as a very
cold disk. The over-temperature state is carried by weight and an explicit
screen-reader label as well as colour. The response parser accepts both a bare
temperature and a per-drive object, since guessing one shape would silently drop
every reading on the other.

The screen subtitle now says "Inventory, capacity, temperatures", which is what
TrueDock actually shows on 25.10.

## Boot environments

The Updates section could install an update and reboot the server but offered no
way to inspect or select a boot environment, so the one real recovery path from a
bad update was missing. `boot.environment.query` is now read into the system
resources, with activate, keep, and destroy each gated on its own method.

The distinction that mattered here is `active` versus `activated`: the
environment currently running versus the one selected for the next boot. They
differ exactly when an activation is pending, which means the server is not
running what it will run after a restart. Collapsing them into one "current" flag
would have hidden that state entirely, so the list labels both and shows a banner
naming the environment that will boot next. A legacy payload without `activated`
is treated as also selected, because assuming false would claim every server has
a pending activation.

Activation says plainly that nothing changes until the next restart and that
TrueDock does not reboot for you; the risk is a user believing they have already
rolled back. Destroy is a typed critical confirmation and is never offered for the
running or next-boot environment, since removing either would break the server's
ability to boot. Both confirmations note that pools, datasets, and share data are
not part of a boot environment.

One bug surfaced while wiring this up: the shared mutation helper invalidates the
server resources provider, but boot environments live in the system resources
provider. Without an explicit invalidation a pending activation would not appear
after activating it, so each of the three mutations invalidates that provider.

Covered by tests at three layers: the parser (pending activation, superseded
environment, settled state, legacy payload, both date serializations, id
fallback), the repository (loaded alongside update status, capability-gated, and a
denied read that keeps the update status), and the list widget (running versus
next-boot labelling, the pending banner, activation offered only where valid,
destroy withheld for the running and next-boot environments, keep toggling in the
direction it is not already in, every mutation hidden when ungated, per-row busy
state, permission error, and empty inventory).

## Clone promotion

Snapshots could be cloned into a new dataset, but the clone could never be
detached from its origin. That left a dead end: the origin snapshot and its
dataset cannot be deleted while a clone depends on them, so a restore-by-clone
workflow had no way to finish. `pool.dataset.promote` closes it.

Detecting a clone needed care. ZFS reports `origin` as an empty string for an
ordinary dataset rather than omitting the property, so a plain null check would
have labelled every dataset a clone. Only a non-empty value counts, and the
action is offered only when the dataset is actually a clone and the server
exposes the method.

Promotion is not destructive, but it is not obvious either, so it uses the shared
high-impact confirmation rather than firing on tap. The confirmation names the
origin snapshot, states that the dependency reverses so the origin dataset
becomes the dependent one and the origin snapshot becomes deletable, and notes
that no data is copied or deleted while space accounting moves to the promoted
dataset.

The dataset row was extracted into `DatasetTile` so its gating is directly
testable. Two of the first tests for it asserted `PopupMenuItem.enabled` through
a type matcher that could not match the privately-typed menu entries, so they
failed for a reason unrelated to the behaviour under test. They now tap the entry
and assert no callback fires, with a companion test proving an ordinary dataset
does fire, so a menu that never worked at all could not pass.

## API key management

`AGENTS.md` prefers API keys in onboarding guidance specifically because a key
can be revoked independently of the account password. The app made that
recommendation without offering any way to see or revoke a key, so the reason for
the recommendation was not actually available to the user. `api_key.query` is now
read into the account section and `api_key.delete` revokes a key.

The model deliberately has no field for key material. TrueNAS returns the secret
only once, at creation, so the only honest thing TrueDock can do is identify a
key and withdraw it. Tests assert that a `key` field present in the payload
cannot survive into the model, and that nothing key-shaped is rendered.

Revoked and expired are kept as separate facts. One was withdrawn deliberately,
the other simply ran out; both mean the key cannot authenticate, but conflating
them would misreport why. An already revoked key does not get a revoke control at
all, rather than one that would be a no-op, while an expired key keeps it so the
list can be tidied.

Revocation uses a typed critical confirmation. It names the consequence that
matters and is easy to overlook: every client still using the key stops being
able to sign in immediately, including TrueDock itself if it is the key in use.
It also states that the key cannot be recovered.

Key creation is intentionally not implemented. The resulting secret is shown once
and would have to be surfaced, copied, and stored somewhere, which is exactly the
handling this app avoids; that flow stays in the web UI.

Like boot environments, API keys live in the system resources provider, so the
revoke mutation invalidates that provider explicitly rather than relying on the
shared server-resources refresh.

## Zvol creation

`pool.dataset.create` was hardcoded to `FILESYSTEM`, so TrueDock could not create
a volume at all. That left the iSCSI extent editor able to attach a zvol but never
to produce one: a disk extent needs a volume, so the only usable backing stores
were those created in the web UI.

Volume creation is a separate repository call rather than a flag on the existing
one, because the payloads barely overlap. A volume sends `volsize` and `sparse`
and must not send `share_type`, which is a filesystem-only concept the server
rejects on a volume. The sheet reflects that: choosing Volume replaces the
workload-optimization control with a size and a sparse switch, so the wrong field
cannot be sent, and a test asserts each payload carries only its own keys.

Two smaller decisions. The size field is in GiB and converted to bytes on submit,
because a byte count is not something anyone can type correctly on a phone. And
`volblocksize` is omitted unless explicitly chosen, so the server keeps the
default appropriate to the pool geometry rather than TrueDock guessing one.

The sheet was extracted into `CreateDatasetSheet` to make the two payloads
testable. The first run of those tests failed for a reason unrelated to the code:
the volume form is taller than the default 600px test viewport, so the submit
button was off-screen and the tap silently missed, producing a "no validation
error found" failure that looked like a validation bug. The tests now scroll the
button into view before tapping, which is also what a real user does.

## Definition of Done review

Checked the shipped features against the AGENTS.md checklist:

- Material 3 loading/empty/error/permission states are present in the Data
  Protection and System screens.
- Every new mutation is capability-gated on its own method
  (`replication.create`/`update`, `rsynctask.create`/`update`,
  `cloudsync.create`/`update`, `interface.update`, `staticroute.*`,
  `pool.create`).
- Every new mutation routes through the shared high-impact confirmation.
- Edition and version gating rejects non-Community editions and anything below
  25.10, and checks for required methods.
- Degraded conditions are covered for the mutation controller: permission
  denied surfaces the server's reason, transport loss is reported in TrueDock's
  own words, editor-seeding reads degrade to null instead of throwing, a
 duplicate mutation fired while the first is in flight is dropped, and busy
 state clears after a failure so the control stays retryable.
- 685 automated tests pass; `flutter analyze` is clean; iOS Simulator and
  Android debug builds succeed; the iOS app boots on the simulator.

## app.rollback version-awareness

Audit caught that `rollbackApp` sent only `[appId]` to `app.rollback`, but the
TrueNAS 25.10 middleware expects `[appId, {'app_version': version}]`. Every
rollback would have failed against a real server, and the existing repository
test only asserted the method name, not the params, so the bug passed silently.

Fixed by making the repository send the documented two-argument shape, threading
an `appVersion` through the controller, and replacing the inline confirmation
with a version-picker sheet that loads the same `app.upgrade_summary` the
upgrade sheet uses. The sheet seeds the picker on the first non-current
advertised version (so a real rollback target is preselected), flags the
current running version in the list, shows the chosen target's release notes,
and then routes through the shared high-impact confirmation before
submitting. The repository test now asserts the params object. No
`rollback_snapshot` option is sent because the middleware documents only
`app_version` for `app.rollback`; an undocumented field would risk a server
rejection and is avoided.

## Remaining before release

1. **Live-server verification.** Closed. This was the largest outstanding risk:
   every result came from fixtures and unit/widget tests, so payload shapes were
   documentation-verified rather than server-verified — and seven defects were
   hiding behind fixtures that asserted the same wrong shape the app was
   sending.

   Five probes, an integration test, and a schema audit now cover it against a
   real TrueNAS-25.10.5 Community Edition VM: 15/15 reads, 41/41 mutation
   shapes, 19/19 app lifecycle, 9/9 restart, 8/8 authentication, a clean
   four-dimension schema audit, and the shipped app itself driven on a simulator.
   Re-run them per server release family; the sections below record what each
   one found.

   The read coverage began with `tool/live_server_probe.dart` against that VM. The probe authenticates with
   `auth.login_ex` (PASSWORD_PLAIN, login_options.user_info), then exercises
   the highest-risk read paths and call shapes: `system.info`/`version`/
   `product_type` (returned `COMMUNITY_EDITION`), `core.get_methods`
   (769 advertised, backs capability discovery), `pool.query`,
   `disk.temperatures` with a device-name list (returned a Map<String,...>,
   confirming the parser's bare-number-OR-object handling and the app's
   call shape), `app.query`, `boot.environment.query`, `api_key.query`,
   `service.query`, `user.query`, `vm.query`, and the
   `app.upgrade_summary` params shape `[appId, {'app_version': 'latest'}]`
   (the middleware accepted the shape and ran the lookup, failing only on
   the nonexistent app id — which is the same shape the rollback/upgrade
   sheets use). 15/15 checks pass. The probe is excluded from analysis and
   reads credentials only from argv; it never persists them.

   The storage mutation shapes are now server-verified too, by a second probe
   (`tool/live_mutation_probe.dart`). It builds a scratch pool from disks the
   server reports as unused, exercises the mutating calls inside it, and
   exports the pool with `destroy_data` afterwards. It refuses to run unless
   every disk it would consume is currently unused and never touches an
   existing pool. 41/41 checks pass against TrueNAS-25.10.5, covering
   `pool.create`, `pool.dataset.create` (filesystem and zvol),
   `pool.dataset.update`, `pool.snapshot.create`/`rollback`/`delete`/`clone`,
   `pool.dataset.promote`, `pool.scrub.scrub`, `pool.dataset.delete`,
   `pool.export`, the SMB and NFS share create/update/delete and ACL calls,
   the iSCSI portal, initiator, extent, target, and LUN-association shapes,
   and the `user`, `group`, and `staticroute` create/update/delete shapes.
   The server was verified clean afterwards: 0 pools, all disks free, and no
   leftover shares, accounts, or routes.

   The probe's first check now sweeps leftovers from an interrupted earlier
   run before it formats anything, because the `finally` teardown only runs if
   the process survives. It removes the probe SMB and NFS shares, the iSCSI
   chain in dependency order, the probe static routes, the probe user and
   group, and finally exports the scratch pool.

   This immediately paid for itself: `pool.create` had four payload defects
   that fixtures could not catch, because the fixtures asserted the same wrong
   shape the app was sending. Vdevs must send `disks` (`devices` is rejected
   as an extra input); the spare category is `spares`, not `spare`;
   `encryption_options: null` is rejected, the flag is `encryption` and the
   options object must be omitted unless encryption is on; and
   `enable_auto_trim` is not part of the schema at all — auto-TRIM lives on
   `pool.update` as `autotrim` (ON/OFF), so opting out is now a follow-up call
   once the pool exists. Pool creation with a non-default auto-TRIM setting
   could not have succeeded before this.

   To keep that class of drift from recurring, the probe builds its payload
   from the app's own `PoolConfiguration` rather than a copy of it; the copy
   is what let the divergence go unnoticed. `pool_configuration.dart` imports
   `meta` instead of `flutter/foundation` so the domain type loads on the Dart
   VM.

   Extending the probe to the share and iSCSI shapes found a second, larger
   defect: the SMB share ACL could never have worked. The middleware exposes
   `sharing.smb.getacl` and `sharing.smb.setacl`; TrueDock called `get_acl`
   and `set_acl`, which are not advertised, so capability discovery silently
   hid the ACL editor rather than failing loudly — the button could not
   appear. Behind the wrong names sat four more defects: both methods are
   keyed by share *name* rather than id, `getacl` answers an object wrapping
   `share_acl` rather than a bare list, an entry uses `ae_type` and a scalar
   `ae_perm` (there is no `perm_type`, `permset` list, or
   `ae_qualified_name`), and the principal must be identified by
   `ae_who_sid` or `ae_who_id` (`{id_type, id}`) and must be an SMB account.
   Passing only `ae_who_str` makes the middleware raise a Python `TypeError`
   rather than a validation error. `SmbAclEntry` now carries the principal's
   Unix id alongside its SID, and the editor takes `SmbAclPrincipal` values
   so every entry it produces is sendable.

   The account and static-route shapes were accepted exactly as the app
   builds them, so nothing needed fixing there. That is a useful negative
   result: the probe distinguishes surfaces that were already correct from
   surfaces that only looked correct because their fixtures agreed with them.

   The app and system surfaces are now verified too, closing the last of the
   fixture-only paths. Three more tools cover them:

   `tool/schema_audit.py` compares every call TrueDock makes against the
   schema the server advertises, in four dimensions: methods that are not
   advertised at all, payload keys absent from a method's `accepts`, objects
   passed where a positional scalar is required, and required keys the call
   site never sends. It resolves domain `toApiJson`/`changedFields` bodies, so
   payloads assembled outside the repository are audited too. It is clean
   against 25.10.5 after the fixes below, and it is the cheapest of these
   checks to re-run when a server release changes.

   `tool/live_app_lifecycle_probe.dart` builds the chain those surfaces need
   and then exercises it: `pool.create` for a real mirrored data pool,
   `pool.dataset.create`, `pool.snapshot.create`, `docker.update` to point the
   app platform at that pool, a catalog sync, `app.create`, and then
   `app.stop`/`start`/`config`/`update`/`redeploy`/`upgrade_summary`/
   `rollback_versions`/`rollback`/`delete`. 19/19 pass, and the installed app's
   published portal answered HTTP 200, so the verification covers a working
   deployment rather than only accepted payloads. It restores the previous
   Docker pool setting and removes what it created unless `--keep` is passed.

   `tool/live_reboot_probe.dart` covers the disruptive lifecycle: it submits
   `system.reboot`, waits for the server to stop answering, reconnects,
   confirms the boot time changed and uptime reset, and then waits for the
   pool to import and the installed app to return to `RUNNING`. 9/9 pass. It
   deliberately does not submit `system.shutdown` — recovering from that needs
   physical access — and instead asserts that method's advertised signature
   matches what TrueDock sends.

   Four more defects surfaced, all of the same class: a payload the fixtures
   agreed with and the server did not.

   `app.delete` could never have worked. TrueDock sent `keep_volumes`, which is
   not in the schema at all; the object rejects unknown keys, so every delete
   was refused. The real fields are `remove_ix_volumes` and
   `force_remove_ix_volumes`, and the polarity is inverted, so the repository
   now translates the user's "keep volumes" choice rather than pushing the
   inversion out to the call sites.

   `system.reboot` and `system.shutdown` could never have worked either.
   TrueDock wrapped the reason as `{'reason': ...}`, but 25.10 declares
   `reason` as a required *positional* string and the second argument is an
   options object accepting only `delay`. Restart and power off are exactly the
   actions a user cannot work around from a phone, so this was the most
   expensive of the four to leave broken.

   `interface.commit_node` is not advertised by 25.10 at all, and nothing
   called it — dead code behind a method that does not exist. The three reads
   that do exist replace it: `interface.has_pending_changes`,
   `interface.checkin_waiting`, and
   `interface.network_config_to_be_removed`. The commit sheet now previews what
   is actually staged and, importantly, names the settings a check-in will
   clear; clearing a gateway or nameserver can sever the very session TrueDock
   is connected over. The same review found `interface.commit`/`checkin`/
   `rollback` are plain calls returning `null` rather than jobs, so the sheet
   drives its own stages, and `rollback`/`checkin_timeout` are now sent
   explicitly because those defaults are the safety mechanism it depends on.

   Rollback was unreachable. The picker was filled from `app.upgrade_summary`,
   which describes *upgrade* targets and raises `[EFAULT] No upgrade available`
   once the app is on the newest version — precisely when a user wants to roll
   back. 25.10 exposes `app.rollback_versions` for this. The sheet now lists
   those versions, excludes the running one, and disables the action when the
   server reports no prior deployment. Confirmed live: a freshly installed app
   answers with an empty list where the summary errored outright.
   Running the real app against that server also exposed a defect no payload
   audit could find: the dashboard showed *Maximum number of concurrent calls
   (20) has exceeded*. TrueNAS caps concurrent calls per connection, and
   Overview alone fans out more than twenty section reads through
   `Future.wait`. The cap is now enforced in `TrueNasJsonRpcClient`, which
   admits at most 16 in flight and queues the rest FIFO. Enforcing it there
   rather than by trimming each screen's parallelism matters: otherwise adding
   a section to one screen silently breaks a different screen that happens to
   refresh at the same time. Queued calls are also released when the socket
   drops — they never reached the pending-request map, so they would otherwise
   await forever behind a spinner.

   `integration_test/live_server_test.dart` is what found it. It drives the
   shipped widget tree on a simulator: registers the server through the
   onboarding form, approves the self-signed certificate (asserting the app
   does not connect without that decision), and walks every top-level
   destination asserting none renders a failure state. Credentials come from
   `--dart-define`, and the group skips unless `TRUEDOCK_LIVE=1`, so the file
   is safe for contributors with no test server. Verified visually as well:
   Storage listed the probe's real pool and datasets with correct capacities,
   and Apps listed the installed app as `RUNNING` alongside live Docker status
   and catalog trains.

   One product default changed as a result. Registration defaulted to API-key
   authentication, but an API key has to be created in the web UI first, so a
   new user's first attempt failed with a rejected-credential error. Ordinary
   login is now the default; the API-key segment stays one tap away and remains
   the better choice for a long-lived registration because it can be revoked on
   its own.

2. **Physical-device hardening.** Narrowed. Sustained flapping no longer needs a
   device: `connection_loss_controller_test.dart` drops and reconnects ten times
   in a row and asserts the app reports every drop, recovers every time, and
   opens exactly one socket per cycle. The accumulation bugs that hide in a
   flaky network — a listener, stale socket, or pending completer kept per cycle
   — would surface on the tenth drop rather than the first, which a single-drop
   test cannot catch. A companion test asserts a call issued as the socket dies
   fails rather than hanging, since the screens read on a timer and would
   otherwise sit on a spinner with no way out.

   Still needs a physical device: real app suspension (the simulator's
   background handling is not equivalent) and performance profiling under a
   release build. Android hardware verification is the user's own pass.
3. **Localization.** Complete for the shipped surface. English and English are
   2380 messages in the English template, including ICU plural forms (English
   embeds the count as a noun-count phrase rather than pluralizing) and
   preserved placeholders. A parity test enforces key-set and placeholder
   equality from the ARB `@` metadata. `flutter gen-l10n` regenerates the
   `AppLocalizations` family; iOS Info.plist declares `CFBundleLocalizations`

   No user-facing widget string remains inline. Three categories are English
   by design: `MaterialApp.router(title:)`, which is the OS task-switcher
   label for a proper noun; `TrueNasRpcException` messages, which are
   transport diagnostics for logs; and `BiometricPromptStrings.fallback`,
   the documented default before a locale resolves.

   Layers without a `BuildContext` cannot resolve strings, so three of them
   record a stable code that the presentation layer renders:
   `ConnectionMessage` for connection failures and notices, `DataMessage` for
   repository failures, and per-feature validation codes (for example
   `AppValidationIssue`, which carries a numeric bound to substitute into the
   localized text). In each case text the server produced is wrapped verbatim
   rather than given a code, so a server's own explanation still reaches the
   user as written.

   Two structural changes were needed beyond string replacement. The storage
   result helpers took verb fragments (`action: 'delete <share name>'`)
   composed into `'TrueNAS could not <action>.'`; that cannot produce
   grammatical English, so they now take whole `failure:`/`success:` sentences
   per call site. And the Android biometric prompt is drawn by the OS from
   strings supplied when the vault is constructed, so the localized values are
   published into the root provider container — a nested `ProviderScope`
   override would have silently no-opped, since `credentialVaultProvider`
   declares no `dependencies`.

   The migration also removed two latent bugs it exposed: both the storage
   shares list and the apps catalog decided whether a section was unsupported
   by matching the English substring `is not available on this TrueNAS
   version.`, which under English would have reported an absent surface as a
   real error. Both now match on `DataMessageCode.methodUnavailable`.

   Tests assert the English locale is registered, translates the navigation
   destinations, keeps English plural copy distinct from English, preserves
   placeholders in the connection-lost copy, and that the full `AppShell`
   inverse). Widget coverage for the migrated sheets pumps them with the
   localization delegates installed. Adding a third locale is now an ARB file
   plus an Info.plist entry.

4. **Signed release automation.** Done. `tool/release_archive.sh` runs the
   local gate, archives, exports a signed IPA, and optionally validates and
   uploads it.

   Two decisions are worth recording. It refuses to archive without
   `TRUEDOCK_TEAM_ID` and without a code-signing identity in the keychain,
   checked before anything is built: Xcode's own failure for a missing identity
   arrives after a full release build and buries the cause under provisioning
   advice. And it uploads with an App Store Connect API key rather than an
   account password, because a key can be revoked on its own; the key is copied
   into App Store Connect's conventional location only when it is not already
   there, and that copy is removed on exit even when validation or upload fails.

   Export options are generated per run from the team identifier instead of
   being committed, since a team id is environment-specific.

   Validation runs before upload. That is what turns a reused build number or an
   unregistered privacy manifest into an immediate local failure rather than a
   rejection email hours later.

   The gate itself now includes the schema audit, asserted positively: the audit
   prints its findings and still exits zero, so the script requires all four
   "no ... found" markers and fails on any unadvertised method. It runs against
   `tool/fixtures/methods.json`, a captured 25.10.5 schema holding method
   signatures only — no address, credential, or server data — so the check works
   offline. Without that dump the audit is skipped with a warning rather than
   silently passing.

   Not automated: the archive itself could not be produced here, because this
   machine has no code-signing identity (`security find-identity` reports zero).
   Every step up to signing is verified, along with each refusal path; the
   signed archive and upload need an Apple Developer account to confirm.

5. **API coverage.** A gap the payload audits could not see: they check the
   calls TrueDock *makes*, not the surfaces it never calls at all. Comparing the
   769 methods a 25.10.5 server advertises against the 166 TrueDock referenced
   found `virt.*` — 33 methods, the entire container and VM surface — with zero
   coverage, while the app gated its container UI on `container.query`, which
   25.10 does not advertise. The section could never appear on a supported
   server.

   `virt.*` is now implemented and verified: `tool/live_instances_probe.dart`
   initializes the platform, creates a real container from a catalog image, and
   exercises query, device_list, start, stop, restart, forced stop, and a partial
   update. 11/11 pass, with the instance reaching `RUNNING` on a live server.

   Three shape details are worth recording because they differ from the older
   surfaces and from what the docs imply. Identifiers are instance *names*, not
   numbers. `status` is a bare string, unlike the nested object `vm.query`
   returns, and `cpu` is a string because it accepts a pinned set such as `0-3`
   as well as a core count. And `virt.instance.update` merges a partial object,
   so the editor emits only changed fields — resending everything would overwrite
   `raw` and the userns idmap that TrueDock does not surface. The probe asserts
   that preservation explicitly rather than assuming it.

   The platform is also gated on state, not just on method discovery.
   `virt.global.config` reports `NO_POOL` until a storage pool is chosen, and in
   that state the server answers an empty instance list — indistinguishable from
   "none created" unless the config is read. TrueDock reads it first and offers
   pool selection behind a confirmation naming the pool, because the hidden
   `.ix-virt` dataset lands there and moving it later means recreating every
   instance.

   Building the UI surfaced three defects of its own, all caught by tests rather
   than by inspection: the create and edit sheets overflowed their action rows
   (12px on a narrow phone, 212px at a 2x text scale), and `DropdownMenu`'s
   trailing button ships without a semantic label, so a screen reader announced
   an unnamed tappable control. The accessibility suite now covers both
   Instances editors.

   The same audit surfaced a second, smaller gap with a sharper edge: the
   commit sheet warns that a check-in can clear the gateway or nameservers, yet
   `network.configuration.*` was uncovered, so the app could neither show those
   values nor fix them. That is now implemented and verified by
   `tool/live_network_probe.dart` (7/7), which is deliberately self-reverting: it
   edits only `httpproxy`, because clearing a gateway on a DHCP server would
   sever the probe's own connection with no commit window to roll it back.

   The read has to distinguish two things the response conflates by shape. The
   top-level fields are what an administrator configured; the nested `state`
   object is what is in effect. On the test server the configured gateway is an
   empty string while `state` reports `10.24.30.254` from DHCP — so showing only
   the configured side would render a working server as unconfigured. Both are
   labelled, and a DHCP-derived configuration says so explicitly.

   Unlike an interface edit, `network.configuration.update` applies immediately;
   there is no commit-and-check-in window to fall back on. An edit that would
   clear a routing value the server is actually using therefore escalates from a
   high-impact confirmation to a typed critical one, because the failure mode is
   losing the session with no automatic rollback.

   Scheduled commands (`cronjob.*`) are implemented too, verified by
   `tool/live_cron_probe.dart` (7/7) against a probe job running `/usr/bin/true`.
   Two details are recorded because both are easy to get backwards. The API
   states its output flags negatively — `stdout: true` suppresses stdout from the
   report — so the domain type stores "capture" and inverts on the wire; a
   passthrough would make the switch mean the opposite of its label, and the
   probe asserts the round trip rather than trusting the read. And `cronjob.run`
   sends `skip_disabled: false`, because the server default silently does nothing
   for a disabled job, which TrueDock would then report as a successful run.

   Alert email (`mail.*`) is implemented, verified by `tool/live_mail_probe.dart`
   (6/6). It never sends a test message: that would deliver mail to whatever
   address the server is configured with, which is not a probe's to touch.

   The live run corrected two assumptions the schema did not express. First,
   `mail.update` rejects the entire call with "fromemail: this field is required"
   when that field is absent *and* not already stored — so a first-time
   configuration cannot be a pure partial update, and the payload builder now
   always includes it in that case. Second, the server refuses an empty
   `fromemail`, so once set it cannot be unset from the app; the probe's own
   cleanup had to be rewritten around that, and the demo server was left with an
   inert `root@localhost` rather than the blank it started with.

   `MailConfiguration` deliberately models no password. `mail.config` does return
   `pass`, so a field for it would create a leak surface for logs, screenshots,
   and state dumps, while TrueDock only needs the value for the single update
   that sets it. Enabling authentication with a username and no stored password
   is rejected locally, because the server accepts that and then silently fails
   to authenticate — alerts would stop arriving with no error anywhere.

   Configuration backup is implemented, verified by
   `tool/live_config_backup_probe.dart` (6/6). This one needed a live server to
   design at all, not just to check.

   `config.save` cannot be called by a JSON-RPC client: it writes to a job pipe,
   and the server answers `Pipe 'output' is not open`. The probe asserts that
   failure deliberately, so if a future release makes the direct call work, the
   wrapper stops being necessary and the probe says so. The route that does work
   is `core.download`, which wraps a pipe-writing method and returns a tokenized
   HTTPS path.

   Two live findings changed the implementation. `buffered: true` is required in
   practice because the unbuffered mode blocks the job until a client reads or 60
   seconds elapse, and TrueDock hands the URL to the user rather than reading it.
   And the payload is not an archive: a plain backup is the SQLite settings
   database itself — 835 KB with a `SQLite format 3` header — and only the
   secret-seed or pool-key options make the server bundle several files into a
   tar. The first version of the probe asserted a tar magic and failed on exactly
   the safe case; the suggested filename now uses `.db` unless those options are
   set, because naming a bare database `.tar` leaves it unopenable by the tool its
   name implies. The token also proved single-use: a second fetch answers 401.

   `config.reset` is never invoked by the probe — it would wipe the server's
   entire configuration — so its signature is asserted instead. In the app it is
   the most destructive non-storage action available and takes a typed
   confirmation, with `reboot` sent explicitly rather than left to the server's
   default of true.

   Privileges (`privilege.*`) are implemented, verified by
   `tool/live_privilege_probe.dart` (8/8). The probe never touches the three
   built-in privileges: narrowing one is how an administrator removes their own
   access, and the privilege it creates grants a single read-only role and no
   groups, so it cannot widen anyone's access even if cleanup fails.

   Two shape details matter. `local_groups` is expanded into group objects on
   read but takes bare gids on write, so both are kept and the probe asserts the
   ids and names stay in step. And roles compose: 74 of the 141 roles the test
   server advertises declare `includes`, so a privilege listing only
   `ACCOUNT_WRITE` also grants `ACCOUNT_READ`. Showing the literal list would
   understate the grant, so the catalog is read alongside and the effective set
   resolved — with cycle protection, since nothing guarantees the catalog is a
   tree.

   The web shell is treated as equivalent to `FULL_ADMIN` rather than as one more
   toggle, because it runs as root and bypasses whatever the role list restricts.
   Either one escalates the confirmation to a typed one.

   Cloud backup (`cloud_backup.*`) is implemented, verified by
   `tool/live_cloud_backup_probe.dart` (5/5). A real backup needs cloud provider
   credentials, which a disposable test server has none of and which are not a
   probe's to create — so the probe proves what can be proven without them: the
   read path parses, and a create built from the app's own domain types is
   rejected for the *credential* rather than for any field. That distinction is
   the point: every payload defect this project found surfaced as a field error,
   so getting past validation is evidence the shape is right even when the call
   cannot succeed. It also checks the payload's keys and required set against the
   advertised schema directly.

   The repository password is the only field in the app that is required on
   create and means "unchanged" when blank on an edit. `cloud_backup.query`
   returns it, but seeding the editor would put a credential on screen and risk
   sending a placeholder as the real password — which would leave the repository
   unreadable. So the stored value is held on the task solely to resend it, and
   deliberately kept out of `CloudBackupConfiguration` so it cannot reach an
   editor, a screenshot, or a state dump.

   Alert policies complete that pair, verified by
   `tool/live_alert_class_probe.dart` (7/7). A destination is only half the
   mechanism: a class set to `NEVER` reaches no destination at all, and nothing
   else in the app revealed that.

   The surface needs two reads merged. `alert.list_categories` is the catalog —
   115 classes across 15 categories on the test server — while
   `alertclasses.config` returns only what an administrator overrode, which is an
   empty map on a stock system. Listing the override map alone would have shown a
   blank screen while hiding every class that could be changed, so the effective
   policy is computed per class with a missing entry meaning "at its default".

   `alertclasses.update` replaces the whole map, so the editor returns the full
   merged configuration and the payload is rebuilt from it. The payload carries
   only classes that differ from their default, and the probe asserts both
   directions: the override lands, and no stock class is stored alongside it.
   Without the second check a save would gradually pin all 115 classes as
   overrides.

   Alert destinations (`alertservice.*`) are implemented for all ten types the
   schema declares, verified by `tool/live_alert_service_probe.dart` (7/7).

   The live run overturned the design's central assumption. The editor never
   prefills a credential, so a blank field was meant to mean "unchanged" and the
   payload omitted it — which `alertservice.update` rejects outright with
   `attributes.PagerDuty.service_key: Field required`. Worse, `alertservice.query`
   returns secrets in plaintext, so the value *is* available: a blank field now
   substitutes the stored one. The probe proves it by re-reading the entry the
   way the app does and checking the stored secret survived an unrelated edit.

   The attribute form is generated from a per-type field table because the API
   discriminates `attributes` on a `type` string and validates against one exact
   variant. A key from the wrong variant fails the whole call, so switching type
   discards the previous attributes instead of carrying them.

   That discriminated union also exposed a blind spot in the schema audit: it
   followed `anyOf` but not `oneOf`, so it reported the correctly-nested `type`
   as a rejected key. Fixed, and checked against negative controls — the audit
   still reports `keep_volumes`, `devices`, and `commit_node`, the three payload
   defects it originally caught — so the relaxation did not simply make it pass.

   Per-service configuration (`ssh`, `smb`, `nfs`, `ftp`, `snmp`) is implemented
   as a single generated editor, verified by
   `tool/live_service_config_probe.dart` (16/16). Two properties are asserted per
   service rather than assumed: every field TrueDock offers exists in the
   server's response, so the editor cannot render a control for something that is
   not there; and after a one-field update, every *other* exposed field is
   compared before and after, which is what proves these updates really are
   partial.

   Auditing that surface found a second redaction gap in the same class as the
   mail one: SNMP authenticates v1/v2c with the `community` string, which is a
   shared secret whose name says nothing about it. It is now redacted, and the
   editor treats it — along with the v3 password and privacy passphrase — as
   write-only: never prefilled from the response, and sent only when typed, so a
   stored secret is never overwritten with a blank and none reaches the screen.

   Auditing the mail surface before implementing it found a redaction hole worth
   more than the feature: `mail.update` sends the SMTP password as a bare `pass`,
   which does not end in any word the redactor's suffix rule matched, so it would
   have reached the logs verbatim. Both `pass` and `pw` are now covered as whole
   names or suffixes, with a test pinning that `bypass_count` and
   `password_age_days` still survive — over-redaction hides operational detail.

   The remaining zero-coverage namespaces are deliberate rather than missed:
   `nvmet`, `fc`/`fcport`, `jbof`, and `failover` are Enterprise or
   fibre-channel surfaces outside the Community Edition scope in `AGENTS.md`;
   `kerberos`, `directoryservices`, `idmap`, and `kmip` are directory-service
   integration; `vmware`, `truecommand`, and `tn_connect` are third-party
   integrations. None of them belong in a first release aimed at day-to-day
   administration.

6. **Authentication paths.** `tool/live_auth_probe.dart` closes what the release
   checklist previously asked a human to do by hand. It issues a real API key,
   authenticates with the exact payload `ApiKeyCredential` builds, revokes the
   key, and proves the revoked key is refused — so both supported mechanisms are
   server-verified rather than fixture-verified. 8/8 pass.

   It also asserts the certificate fingerprint is stable across connections.
   That is worth checking before trusting a pin at all: a server presenting a
   different certificate per connection would make TrueDock's trust prompt fire
   constantly, and the cause would look like an app defect.

   Two auth checks stay manual for reasons no probe can remove. Completing a 2FA
   challenge needs an authenticator, so the probe only verifies the app can read
   whether the server has it enabled; the `OTP_REQUIRED` branch stays
   widget-tested. And proving a *changed* certificate forces a new trust decision
   needs the server's certificate to actually be replaced, which cannot be done
   without disrupting the test system.

7. **Audit log.** Added as the closing surface of the administrative work
   rather than another mutation: it is the server's own record of everything the
   rest of the app does, so `tool/live_audit_probe.dart` verifies a loop no other
   probe can. It performs a known administrative call and then finds that call in
   the log, which proves the query shape, the filters, and the parsing all agree
   with what the server actually recorded. 8/8 pass.

   The filter check is deliberately stronger than "the server accepted the
   payload". A server that ignored `query-filters` entirely would still answer,
   and a healthy window containing no failures would still look like a pass, so
   an unfiltered window and a filtered one are taken at the same limit and
   compared: no successful row may appear in the filtered result, and whenever
   the unfiltered window contained successes the filtered window has to be
   strictly smaller. Against the test server that is 200 rows with 189 successes
   narrowing to 55 — equal counts would have meant the filter was ignored and the
   same rows were being read twice.

   Two API details are worth recording because they are unique in the surface.
   `audit.query` nests everything in one object with hyphenated keys rather than
   taking the usual positional `[filters, options]`, so it cannot share the
   common query helper. And a `METHOD_CALL` splits its own description across two
   levels — `method`, `description`, `authenticated`, and `authorized` sit inside
   `event_data` while `success` is top level — so reading only the top level would
   silently lose what the call actually was. Denial is kept distinct from failure
   throughout: being refused permission and attempting something that broke are
   different answers to the question the log exists to answer.

8. **Provisioning, end to end.** The per-namespace probes each prove one
   surface in isolation, which leaves the question they cannot answer: do the
   surfaces compose the way an administrator actually uses them? Storage has to
   exist before an app can be installed onto it, and an app is only really
   installed if something answers on its port.
   `tool/live_provisioning_probe.dart` runs that whole chain — create a mirrored
   pool from unused disks, add a dataset, snapshot it, install Immich from the
   community catalog, and then make an ordinary HTTP request to the port the
   server published. 13/13 pass, ending in `HTTP 200 on port 30041`.

   Every payload is built by the app's own domain types (`PoolConfiguration`,
   `CatalogAppVersion.installationValues`) rather than hand-written JSON, so a
   divergence between what TrueDock sends and what the server accepts fails in
   the probe instead of in front of a user. Two things this caught worth
   recording: the pool comes back as `MIRROR` in the topology, which is asserted
   directly because a mirror that silently degraded to a stripe would still
   report ONLINE and healthy; and Immich ships `db_password`/`redis_password` as
   *required* fields with empty-string defaults, so accepting the schema defaults
   unchanged has to be refused. The probe asserts that refusal, because a sheet
   that let those through would install an app that cannot start.

   The probe is destructive by nature, so it takes disks only from
   `disk.get_unused`, re-checks `disk.query` to confirm none of them is claimed
   by a pool, and tears down both the app and the pool unless `--keep` is passed.

   The live integration walk was extended in the same direction. It previously
   only asserted the *absence* of error text, which a screen that quietly
   rendered an empty list would also satisfy. `TRUEDOCK_EXPECT` now names
   resources that must appear somewhere in the UI, turning it into a positive
   assertion; a negative control with a non-existent name fails as expected,
   which is what proves the check is doing work rather than iterating an empty
   list.

9. **Mutation through the shipped UI.** Every other mutation check in the
   repository sits one layer below the user: the probes in `tool/` send the
   app's payloads over a raw socket, and the widget tests drive the sheets
   against fakes. Neither proves the path a person actually takes. A screen that
   built a correct payload but never wired its submit button to the controller
   would pass both and still be broken.

   `integration_test/live_mutation_ui_test.dart` closes that: on a simulator it
   registers the server, opens Storage, taps the section action, fills the
   create-dataset sheet, submits, then taps the new dataset and snapshots it —
   and confirms each result by reading the server back through the app's own
   resource provider rather than trusting the UI's own success message. It
   cleans up both objects afterwards, and names them with a run-specific suffix
   so a failed run cannot masquerade as a bug on the next one.

   Writing it surfaced a modelling detail worth recording: `SnapshotEntry.name`
   is the leaf the server returns in `snapshot_name`, while the full
   `dataset@snapshot` path is `id`. Asserting against `name` fails even though
   the snapshot was created correctly, which is exactly the sort of thing that
   is invisible until something reads the value back.

10. **Duplicate translation keys.** A defect no existing gate could see.
    `storageSnapshotCreated` was defined twice in both ARB files; duplicate keys
    are valid JSON, so the last one silently wins and `gen-l10n`, `analyze`, and
    the test suite all pass. In English the two definitions did not even agree, so
    the string a reviewer read in the file was not the string the app shipped.

    `tool/arb_lint.py` now runs before `gen-l10n` in the release gate. It tracks
    brace depth instead of regex-matching every quoted key, so keys that are
    legitimately repeated inside `@meta` objects (`description`, `placeholders`,
    `type`) are not reported, and it additionally requires both locales to define
    the same key set, since a key present in only one locale falls back and reads
    as untranslated. Both behaviours are verified with negative controls:
    reintroducing the exact duplicate fails, and removing a key from one locale
    fails.

11. **App lifecycle through the shipped UI.** The dataset test covers a create
    flow: a sheet plus a submit button. A lifecycle action has a different
    shape - it passes through a confirmation dialog, it is a long-running server
    job rather than an immediate write, and the tile it lives on re-renders from
    server state while the job runs. Each of those is somewhere the wiring can be
    wrong without a unit test noticing.
    `integration_test/live_app_lifecycle_ui_test.dart` stops an installed app
    from the Apps screen and starts it again, asserting each state by reading the
    server back.

    It also asserts the asymmetry between the two directions: stopping
    interrupts a workload and must raise a confirmation, while starting is not
    destructive and must not. Checking only that "the action worked" would pass
    even if both paths had been wired identically.

    Two defects in the test itself are worth recording, because both produced
    the same misleading message and neither was a bug in the app.
    `find.byIcon(...).first` was wrong twice over: the tile's leading avatar
    displays state using the same two icons, so the first match within a tile is
    a decoration rather than a control, and every other installed app has its
    own tile, so the first match on screen may belong to a different app. It
    stopped the wrong app while reporting `syncthing never reached STOPPED` -
    caught only by querying the server, which showed the *other* app had
    changed state. The finder is now scoped to the `ListTile` carrying the app's
    name.

    The second was the polling loop. It invalidated the resources provider on a
    timer and read `valueOrNull`, but that provider fans out a large batch of
    reads, so each invalidation restarted the load before it could finish and
    the cached value never advanced. It polled for a full three minutes against
    a server that had settled in two seconds. Awaiting
    `container.refresh(provider.future)` fixed it, taking the run from 3m51s to
    1m04s. The general lesson applies to any live assertion in this repository:
    invalidate-then-read races a batched provider, and the failure looks exactly
    like the server never changing.

12. **Confirmation coverage, audited statically.** The confirmation widget has
    widget tests and individual flows have integration tests, but neither
    answers the question the safety policy actually asks: is there a *call site*
    anywhere that reaches a destructive controller method without asking first?
    That gap cannot be closed by testing, because it concerns code that may not
    exist yet - a new screen calling `deleteDataset` directly would fail no
    existing test, since there would simply be no test for it.

    `tool/confirmation_audit.py` walks the presentation layer instead, finds
    every call into a destructive controller method, and requires
    `confirmDestructiveAction` in the same function or in a helper it calls.
    Methods classified irreversible must additionally use
    `MutationImpact.critical`, which is what forces the user to type the target
    name. 38 destructive call sites, all confirmed. Negative controls verify it
    works: a screen calling `deleteDataset` with no confirmation fails, and one
    confirming an irreversible action as merely `high` fails.

    Delegation has to be followed to make this usable. Restart and shut down
    both funnel through `_powerAction`, where their confirmation actually lives,
    so a check limited to the calling function would report them as unguarded.
    An early version did exactly that - but for a subtler reason worth
    recording: the body extractor took the first `{` after the function name,
    which for `_powerAction(ctx, ref, {required String title})` is the
    *named-parameter* block. Its body was read as a parameter list containing no
    confirmation. The extractor now skips the signature's parentheses first.

    **The audit found a real defect.** `_replacePoolDisk` offers a force switch,
    and its confirmation warns that forcing removes a disk still being read -
    but `ServerActionController.replacePoolDisk` had no `force` parameter, so
    the repository default of `false` was always sent. The app promised a forced
    replacement and quietly performed an ordinary one, which fails on exactly
    the degraded pool the option exists for. The flag is now threaded through,
    and forcing escalates the confirmation to `critical`, since detaching a live
    member is not undoable the way an ordinary resilver is. Two controller tests
    pin the payload: `force: true` must reach the wire, and the default must
    stay `false` so forcing can never be inherited by a user who did not ask.

13. **Dropped options, audited across the layer seam.** The `pool.replace`
    defect had a shape worth generalising rather than just fixing: the
    repository exposed `force` with a safe default, the UI collected it and
    warned about it, and the controller between them simply had no parameter for
    it. Every layer was correct in isolation, so nothing failed - the flag
    evaporated in the seam. Nothing catches that class of bug. The analyzer sees
    a legal call using a default; repository tests pass the flag directly; sheet
    tests assert the switch flips local state.

    `tool/parameter_drop_audit.py` compares the two signatures directly. For
    every repository method the controller wraps, any optional parameter the
    repository accepts but the controller neither declares nor forwards is
    reported. Deliberate omissions go in `ALLOWED` with a written reason, which
    forces the decision to be recorded instead of silently assumed. Twelve
    wrapped methods carry optional parameters; four omissions are recorded as
    intentional.

    Judging those four is the substance of the check, and the reasoning differs
    per case. `commitInterfaceChanges.checkInTimeoutSeconds` is safe to fix
    because the sheet never echoes the value it sent - it displays the remaining
    time from `interface.checkin_waiting`, the server's own count, so a fixed
    60s cannot disagree with what the user sees. `attachPoolDisk`'s
    `allowDuplicateSerials` is the instructive contrast with `force`: no part of
    the attach sheet offers it, so the app never makes a promise it fails to
    keep. Duplicate serials mean two disks claiming the same identity, which is a
    hardware fault worth refusing by default rather than a phone-sized choice.

    The audit shipped broken first, in a way worth recording because it is the
    second instance of the same mistake. Its body extractor took the first `{`
    after the method name, which for a signature ending in named parameters is
    the parameter block. Every body therefore read as a parameter list,
    `_repository.<name>` was never found in it, and eleven of twelve candidates
    were skipped as "not a wrapper" - while the run printed a confident green
    `clean`. Only the implausible count (2 checked, against 138 repository
    methods) gave it away. Bodies are now paired with signatures at parse time
    rather than re-derived, and methods that parse but do not look like wrappers
    are *reported* instead of dropped, so a future extractor bug degrades loudly
    rather than into a green run that checked nothing. Verified by reintroducing
    the exact `force` defect: the audit fails, and passes again once restored.

14. **The audit's own blind spot.** `confirmation_audit.py` checks call sites
    against hand-maintained CRITICAL and HIGH lists, which makes it only as
    complete as someone's memory. A new `deletePolicy` would be compared against
    nothing and pass - and nothing about that failure is visible, because the
    audit still prints a green line, just for fewer methods. A checker that
    silently narrows its own scope is worse than no checker, since it is trusted.

    The lists are now checked against the controller itself: every
    `Future<OperationReceipt?>` whose name begins with a destructive verb must
    appear in CRITICAL or HIGH, or be excused in UNCLASSIFIED with a reason. The
    reverse is also caught - a name left in a list after being removed from the
    controller makes the audit look like it covers something it does not.

    **This found two more gaps immediately.** `abortCloudBackup` ran with no
    confirmation at all, which was plainly inconsistent: *starting* that backup
    already asked, so throwing the transfer away on a single menu tap was
    stranger than the omission itself. An aborted run keeps whatever was already
    uploaded but produces no usable snapshot, and backing up again re-sends the
    data at the provider's expense, so it now confirms with both consequences
    named.

    `abortJob` did confirm, but through its own `AlertDialog`. It asked a
    reasonable question, yet being a bespoke surface it never named the server -
    and the job center can be looking at any registered one. Aborting a job on
    the wrong server is precisely the mistake naming it prevents. It now uses the
    shared confirmation like every other disruptive action.

    Only `rollbackInterfaceChanges` is excused. It undoes staged network changes
    that were never applied, so confirming it would ask permission to change
    nothing - and it is the escape hatch from a commit that broke the session,
    where an extra prompt is actively harmful.

    One implementation note worth keeping: the two abort methods were first
    added via `HIGH |= {...}` placed *after* `GUARDED = CRITICAL | HIGH` had
    already been computed, so the set never changed and the audit kept reporting
    them. Classification now lives in the literal. Both directions are verified
    by negative control: removing `deleteDataset` from CRITICAL fails the audit,
    and adding a name the controller does not define fails it too.

15. **Bespoke confirmation dialogs, reviewed.** Fixing `abortJob` raised the
    obvious follow-up: where else does a screen ask its own question instead of
    using the shared surface? Nine `showDialog<bool>` sites exist. Most are
    correct and should stay that way - the server management screen names the
    server because the server *is* the target, `_showCatalogDetails` is an
    information sheet rather than a confirmation, and the instance and app
    lifecycle prompts describe a reversible start/stop on a named resource.

    One was not. `_editSnapshotTask` reads the real consequence from
    `pool.snapshottask.update_will_change_retention_for` - the server's own count
    of existing snapshots whose retention deadline the edit would move - and then
    presented it in a plain dialog titled like a schedule tweak, without naming
    the server. Shortening a lifetime makes ZFS prune snapshots that already
    exist, and nothing brings them back.

    It now routes through the shared confirmation *when the server reports
    affected snapshots*, listing the per-dataset counts as consequences. When the
    count is zero the edit really is only a schedule change, so the plain dialog
    stays: escalating unconditionally would train users to dismiss the serious
    case along with the routine one, which is the failure mode the impact
    classes in AGENTS.md exist to avoid.

16. **Selecting audit targets by behaviour, not by filename.** The confirmation
    audit gathered its files from a list of suffixes - `*_screen.dart`,
    `*_section.dart`, `*_sheet.dart`, `*_sheets.dart`, `*_tile.dart`. That
    excluded `job_center.dart`, which calls `abortJob`, so the audit printed a
    confident green while never opening the one file whose confirmation had just
    been rewritten. A naming convention is a habit, not an enforcement
    mechanism, and nothing stops the next screen from being called something
    else.

    It now walks every Dart file and selects the ones that read
    `serverActionControllerProvider`, which is the actual precondition for
    reaching a destructive method. The controller itself is excluded because it
    defines those methods rather than calling them on a user's behalf. Coverage
    went from 39 call sites to 40 - a small number that matters because the
    missing one was the file most recently changed. Verified by negative
    control: stripping the confirmation from `job_center.dart`, previously
    invisible, now fails the audit.

17. **Checking an audit's own scope assumption.** Closing the confirmation
    audit's filename blind spot raised the same question about the
    parameter-drop audit, which hardcodes one `REPOSITORY`/`CONTROLLER` pair.
    That is correct today - a sweep of every Dart file for a `_repository.`
    forward finds exactly one wrapping layer, `server_action_controller` - but
    it is an assumption about the codebase, not a property of the audit. A
    second controller would appear and the audit would keep passing without ever
    looking at it.

    The assumption is now checked rather than assumed: any file outside the
    audited pair that forwards to a repository is reported. The summary line
    also states the scope it covered ("across 1 wrapping seam") instead of an
    unqualified `clean`, so a reader can see what was actually examined. Verified
    by negative control: adding a second forwarding controller fails the audit.

    The general rule these two turns arrived at is that a checker must fail when
    its own coverage shrinks. Both audits could previously cover less than they
    claimed while still printing green, which is the worst failure mode
    available to a tool that exists to be trusted.

18. **Method names the schema audit could not see.** The same scope question,
    asked of the oldest audit, found the largest gap. `schema_audit.py` matches
    `'some.method'` string literals, so a name assembled at runtime is invisible
    to all four of its checks. `ConfigurableService` builds `'$namespace.config'`
    and `'$namespace.update'` for five services - ten methods carrying 27 payload
    keys that the audit had never examined while printing its confident summary.

    Those 27 keys turn out to be correct against the 25.10 schema, which is the
    right outcome but the wrong kind of evidence: "we checked once by hand and it
    was fine" is not "it is checked". The audit now resolves the service table
    and validates it like any other payload, and separately reports *any* other
    interpolated method name, so a second dynamic call site cannot inherit the
    same blind spot. Both are wired into the release gate - the audit exits zero
    regardless, so a new marker and an explicit failure on unresolved names are
    what actually make the gate fail.

    Verified by negative control in both directions, and against the gate rather
    than the tool: adding a key the schema rejects removes the success marker,
    and a new interpolated name in an unrelated file is reported.

    Three audits have now been found covering less than they claimed - by
    filename, by hardcoded pair, and by string-literal matching. The common
    cause is that each selected its inputs by a syntactic proxy for the property
    it cared about. Where a proxy is unavoidable, the audit must at least report
    what fell outside it.

19. **Active sessions.** Coverage analysis over namespaces TrueDock already
    works in - rather than untouched ones, which are deliberate scope decisions -
    surfaced `auth.sessions` as a real product gap rather than another audit
    fix. It is the security surface the app was missing: the API key list says
    what *could* connect, and nothing said what *is* connected.

    `tool/live_session_probe.dart` opens a second real session and ends it from
    the first, which is the only way to prove the two properties that matter -
    that terminating hits exactly the intended connection, and that the caller's
    own session survives. A terminate that killed the wrong session would
    otherwise surface as a mysterious disconnect much later. 6/6 pass.

    Three modelling details came from the live response rather than the schema.
    The account name is nested in `credentials_data`, so reading the top level
    produces unlabelled sessions. The server mixes its own internal UNIX-socket
    connections into the list - five of six on an idle server - which are the
    middleware talking to itself; they are filtered out, but their count is
    reported so the visible list cannot silently disagree with the server. And
    `secure_transport` is treated as insecure when absent, since defaulting an
    unknown to "encrypted" would hide exactly the case the UI flags in red.

    The confirmation is `high`, not `critical`, and says the credential holder
    can sign in again. That wording is the point: ending a session is eviction,
    not lockout, and a user who believes otherwise would stop at the wrong step
    instead of revoking the key or changing the password.

20. **What a real restart found.** Restarting the demo server through the
    shipped UI - four times, each confirmed by uptime reset - surfaced two
    defects that nothing in the repository could have. Both concerned the
    connection-lost banner, and both were invisible precisely because the parts
    each had tests.

    First, `ServerEntryScreen` returned the shell only while `isConnected`.
    That flag and `isConnectionLost` are mutually exclusive, so the instant a
    socket dropped the gate swapped the entire shell for the registration
    screen, taking the banner with it. A restart read as being signed out. Six
    widget tests covered the banner and all passed: they mount `AppShell`
    directly, so they prove the banner renders *given* the shell and cannot see
    a gate that removes it. The controller tests likewise proved the stage
    reaches `connectionLost`. Nothing joined the two halves.

    Second - found only after fixing the first and restarting again - the banner
    lived inside the shell, but `/system/*` are separate routes pushed on top of
    it. A restart while the user sat on a detail screen left them looking at
    "connect to a server to see this section", with nothing naming the server
    and no way to retry. The banner now mounts from `MaterialApp.router`'s
    `builder` as `ConnectionLostHost`, above the router, so it covers every
    route rather than one subtree.

    The negative control for that second fix initially *passed*, which was the
    useful part: the new tests mounted `ConnectionLostHost` themselves, so
    removing it from `TrueDockApp` changed nothing they could observe. They
    proved the widget worked, not that the app used it. A test asserting
    against the real `TrueDockApp` now covers the wiring, and removing the host
    fails it. This is the same shape as the audit blind spots in items 16-18: a
    check that selects its own subject cannot see the subject going missing.

21. **Suspend/resume, and why the simulator cannot profile.** Two items were
    parked as "needs a physical device". One of them turned out to be reachable
    on a simulator and the other genuinely is not, and the distinction is worth
    recording.

    Release-build profiling is not possible on a simulator at all. Flutter
    refuses both modes outright - `Profile mode is not supported for simulators`
    and the same for release - because profile/release builds are AOT-compiled
    with precompiled shaders, and the simulator has neither pipeline. Even if
    the refusal could be worked around, the numbers would measure the Mac's CPU
    and GPU rather than a phone's, so they would answer a different question
    than the one profiling exists to answer, and would do it optimistically.
    This stays a physical-device task.

    Suspend/resume is different: the platform lifecycle transitions really are
    delivered on a simulator, so `integration_test/live_lifecycle_ui_test.dart`
    exercises them against a real server over a real socket. A widget test
    already covered the resume handler, but against a scripted fake that answers
    instantly and never dies. The live test asserts the thing that actually
    matters after a suspend: the session probe reaches the wire, proven by
    `system.info` uptime advancing rather than replaying a cached value.

    The second case is the one worth having. Instead of a debug hook that drops
    the transport, the test evicts TrueDock's own session from a *second*
    connection using `auth.terminate_session` - the same call the Sessions
    screen makes. A test-only backdoor would only prove the app handles a state
    the app itself produced; this proves it handles a session that died the way
    sessions actually die, and that the resulting stale data is labelled rather
    than left looking live.

    Writing it surfaced a testing hazard: pumping while the app is `paused`
    hangs rather than fails. A paused app produces no frames, so `pump` waits
    for one that never arrives - the first run sat for over six minutes before
    the harness gave up. Real elapsed time is both the fix and the more faithful
    model of a suspend.

Contract fixtures now pin both supported release families (25.10 as the
baseline and 26.04 for the container surface), asserting every method TrueDock
calls, the container gating, per-section degradation, and the rejection paths
for pre-25.10, non-Community, and incomplete servers.
