import '../../resources/domain/server_resources.dart';
import '../../../core/domain/data_message.dart';

class ResourceValue<T> {
  const ResourceValue({this.value, this.error});

  final T? value;

  /// The failure to show, as a code the presentation layer localizes.
  final DataMessage? error;

  /// English text for logs and tests. The UI renders [error] through
  /// `DataMessageLocalizations` instead.
  String? get errorMessage => error?.fallback;

  bool get hasError => error != null;
}

class SystemResources {
  const SystemResources({
    this.users = const ResourceSection(),
    this.groups = const ResourceSection(),
    this.interfaces = const ResourceSection(),
    this.routes = const ResourceSection(),
    this.updateStatus = const ResourceValue(),
    this.bootEnvironments = const ResourceSection(),
    this.apiKeys = const ResourceSection(),
    this.sessions = const ResourceSection(),
  });

  final ResourceSection<NasUser> users;
  final ResourceSection<NasGroup> groups;
  final ResourceSection<NetworkInterface> interfaces;
  final ResourceSection<StaticRoute> routes;
  final ResourceValue<SystemUpdateStatus> updateStatus;

  /// Bootable system snapshots. This is the only real way back after a bad
  /// update, so it belongs next to the update controls rather than hidden away.
  final ResourceSection<BootEnvironment> bootEnvironments;

  /// API keys registered on the server. TrueDock recommends API-key auth
  /// precisely because a key can be revoked independently, so listing and
  /// revoking them belongs in the app.
  final ResourceSection<NasApiKey> apiKeys;

  /// Sessions currently authenticated against the server. API keys describe
  /// what *could* connect; this describes what is connected now.
  final ResourceSection<NasSession> sessions;
}

/// One bootable TrueNAS system image, as returned by `boot.environment.query`.
///
/// `active` means the environment currently running; `activated` means the one
/// selected for the next boot. They differ exactly when an activation is
/// pending, which is the state a user most needs to see before rebooting.
class BootEnvironment {
  const BootEnvironment({
    required this.id,
    required this.active,
    required this.activated,
    required this.keep,
    this.sizeBytes,
    this.created,
  });

  factory BootEnvironment.fromJson(JsonObject json) => BootEnvironment(
    id: _string(json['id'] ?? json['name'], fallback: 'boot environment'),
    active: json['active'] == true,
    // Older payloads report only `active`; treat that as also selected for the
    // next boot rather than claiming an activation is pending.
    activated: json.containsKey('activated')
        ? json['activated'] == true
        : json['active'] == true,
    keep: json['keep'] == true,
    sizeBytes: _nullableInteger(json['used_bytes'] ?? json['rawspace']),
    created: _bootEnvironmentCreated(json['created']),
  );

  final String id;
  final bool active;
  final bool activated;

  /// True when the environment is marked to survive automatic pruning.
  final bool keep;
  final int? sizeBytes;
  final DateTime? created;

  /// True when rebooting would leave the currently running environment.
  bool get activationPending => activated && !active;

  /// True when this environment is running but a different one is queued.
  bool get supersededByPendingActivation => active && !activated;
}

/// TrueNAS serializes this as `{"$date": <milliseconds>}` in most releases and
/// as an ISO string in others.
DateTime? _bootEnvironmentCreated(Object? value) {
  Object? raw = value;
  if (raw is JsonObject) raw = raw[r'$date'] ?? raw['date'];
  if (raw is num) {
    final milliseconds = raw.abs() > 100000000000
        ? raw.toInt()
        : raw.toInt() * 1000;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

class NasUser {
  const NasUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.uid,
    required this.local,
    required this.builtin,
    required this.smb,
    required this.passwordDisabled,
    required this.roles,
    this.email,
    this.shell,
    this.locked = false,
    this.sudoCommands = const [],
    this.primaryGroupId,
    this.auxiliaryGroupIds = const [],
  });

  factory NasUser.fromJson(JsonObject json) => NasUser(
    id: _integer(json['id']),
    username: _string(json['username'], fallback: 'User'),
    fullName: _string(json['full_name'], fallback: ''),
    uid: _integer(json['uid']),
    local: json['local'] != false,
    builtin: json['builtin'] == true,
    smb: json['smb'] == true,
    passwordDisabled: json['password_disabled'] == true,
    roles: _strings(json['roles']),
    email: _nullableString(json['email']),
    shell: _nullableString(json['shell']),
    locked: json['locked'] == true,
    sudoCommands: _strings(json['sudo_commands']),
    primaryGroupId: _groupId(json['group']),
    auxiliaryGroupIds: _integers(json['groups']),
  );

  final int id;
  final String username;
  final String fullName;
  final int uid;
  final bool local;
  final bool builtin;
  final bool smb;
  final bool passwordDisabled;
  final List<String> roles;
  final String? email;
  final String? shell;
  final bool locked;
  final List<String> sudoCommands;

  /// TrueNAS returns the primary group as a nested object on `user.query`
  /// but expects a bare group id on `user.update`.
  final int? primaryGroupId;
  final List<int> auxiliaryGroupIds;

  bool get isAdministrator => roles.isNotEmpty;

  /// Built-in accounts are managed by the system and must not be edited.
  bool get isEditable => !builtin && local;
}

class NasGroup {
  const NasGroup({
    required this.id,
    required this.name,
    required this.gid,
    required this.local,
    required this.builtin,
    required this.smb,
    required this.roles,
    required this.userIds,
  });

  factory NasGroup.fromJson(JsonObject json) => NasGroup(
    id: _integer(json['id']),
    name: _string(json['name'] ?? json['group'], fallback: 'Group'),
    gid: _integer(json['gid']),
    local: json['local'] != false,
    builtin: json['builtin'] == true,
    smb: json['smb'] == true,
    roles: _strings(json['roles']),
    userIds: _integers(json['users']),
  );

  final int id;
  final String name;
  final int gid;
  final bool local;
  final bool builtin;
  final bool smb;
  final List<String> roles;
  final List<int> userIds;

  /// Built-in groups are managed by the system and must not be edited.
  bool get isEditable => !builtin && local;
}

/// One API key, as returned by `api_key.query`.
///
/// The secret itself is returned only once, when the key is created, so this
/// model deliberately carries no key material: it exists so an existing key can
/// be identified and revoked.
class NasApiKey {
  const NasApiKey({
    required this.id,
    required this.name,
    required this.revoked,
    this.username,
    this.createdAt,
    this.expiresAt,
    this.localUser = true,
  });

  factory NasApiKey.fromJson(JsonObject json) => NasApiKey(
    id: _integer(json['id']),
    name: _string(json['name'], fallback: 'API key'),
    revoked: json['revoked'] == true,
    username: _nullableString(json['username']),
    createdAt: _apiKeyTimestamp(json['created_at']),
    expiresAt: _apiKeyTimestamp(json['expires_at']),
    localUser: json['local'] != false,
  );

  final int id;
  final String name;

  /// True once the server has revoked the key. A revoked key stays listed so
  /// the user can see it can no longer be used.
  final bool revoked;
  final String? username;
  final DateTime? createdAt;

  /// Null means the key does not expire.
  final DateTime? expiresAt;
  final bool localUser;

  bool get expires => expiresAt != null;

  /// True when the expiry has already passed. Distinct from [revoked]: an
  /// expired key was not deliberately withdrawn.
  bool isExpiredAt(DateTime now) =>
      expiresAt != null && expiresAt!.isBefore(now);

  /// True when the key can still authenticate.
  bool isUsableAt(DateTime now) => !revoked && !isExpiredAt(now);
}

/// A live authenticated session on the server, from `auth.sessions`.
///
/// API keys answer "what could connect"; this answers "what *is* connected
/// right now", which is the question that matters when an account may have been
/// compromised. TrueNAS also counts its own internal UNIX-socket sessions here,
/// and those are the middleware talking to itself rather than a person, so they
/// are classified separately instead of being listed as unexplained root logins.
class NasSession {
  const NasSession({
    required this.id,
    required this.current,
    required this.internal,
    required this.origin,
    required this.credentials,
    this.username,
    this.createdAt,
    this.secureTransport = true,
  });

  factory NasSession.fromJson(JsonObject json) {
    final data = json['credentials_data'];
    final credentialData = data is JsonObject
        ? data
        : const <String, dynamic>{};
    return NasSession(
      id: _string(json['id'], fallback: 'session'),
      current: json['current'] == true,
      internal: json['internal'] == true,
      origin: _string(json['origin'], fallback: 'Unknown origin'),
      credentials: _string(json['credentials'], fallback: 'UNKNOWN'),
      username: _nullableString(credentialData['username']),
      createdAt: _apiKeyTimestamp(json['created_at']),
      // Absent means the server did not say; treating that as secure would be
      // the wrong default for something the UI flags as a risk.
      secureTransport: json['secure_transport'] == true,
    );
  }

  final String id;

  /// True for the session TrueDock itself is using. Ending it disconnects the
  /// app, so it is never offered as an ordinary "terminate" target.
  final bool current;

  /// True for the middleware's own internal connections, which are not user
  /// logins and cannot be terminated meaningfully.
  final bool internal;

  /// Where the session came from: an address and port, or a UNIX socket.
  final String origin;

  /// The mechanism used, e.g. `LOGIN_PASSWORD`, `API_KEY`, `UNIX_SOCKET`.
  final String credentials;
  final String? username;
  final DateTime? createdAt;

  /// False when the session is not on an encrypted transport, which is worth
  /// showing rather than hiding.
  final bool secureTransport;

  /// Sessions a person actually established, and which terminating affects.
  bool get isUserSession => !internal;

  /// True when this session authenticated with an API key rather than a
  /// password, which changes what revoking it requires.
  bool get usedApiKey => credentials.toUpperCase().contains('API_KEY');
}

/// TrueNAS serializes these as `{"$date": <milliseconds>}`, and some releases
/// return an ISO string or a bare epoch instead.
DateTime? _apiKeyTimestamp(Object? value) {
  Object? raw = value;
  if (raw is JsonObject) raw = raw[r'$date'] ?? raw['date'];
  if (raw is num) {
    final ms = raw.abs() > 100000000000 ? raw.toInt() : raw.toInt() * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

class NetworkInterface {
  const NetworkInterface({
    required this.id,
    required this.name,
    required this.type,
    required this.linkState,
    required this.addresses,
    required this.dhcp,
    this.activeMediaSubtype,
    this.mtu,
  });

  factory NetworkInterface.fromJson(JsonObject json) {
    final state = _object(json['state']);
    final stateAliases = _objects(state?['aliases']);
    final configuredAliases = _objects(json['aliases']);
    final aliases = stateAliases.isNotEmpty ? stateAliases : configuredAliases;
    return NetworkInterface(
      id: _string(json['id'] ?? json['name'], fallback: 'interface'),
      name: _string(json['name'], fallback: 'Interface'),
      type: _string(json['type'], fallback: 'PHYSICAL'),
      linkState: _string(state?['link_state'], fallback: 'UNKNOWN'),
      addresses: aliases
          .map(NetworkAddress.fromJson)
          .where((address) => address.address.isNotEmpty)
          .toList(growable: false),
      dhcp: json['ipv4_dhcp'] == true,
      activeMediaSubtype: _nullableString(state?['active_media_subtype']),
      mtu: _nullableInteger(json['mtu']),
    );
  }

  final String id;
  final String name;
  final String type;
  final String linkState;
  final List<NetworkAddress> addresses;
  final bool dhcp;
  final String? activeMediaSubtype;
  final int? mtu;

  bool get isUp =>
      linkState.toUpperCase() == 'LINK_STATE_UP' ||
      linkState.toUpperCase() == 'UP';
}

class NetworkAddress {
  const NetworkAddress({
    required this.type,
    required this.address,
    this.netmask,
  });

  factory NetworkAddress.fromJson(JsonObject json) => NetworkAddress(
    type: _string(json['type'], fallback: 'INET'),
    address: _string(json['address'], fallback: ''),
    netmask: json['netmask']?.toString(),
  );

  final String type;
  final String address;
  final String? netmask;

  String get label => netmask == null ? address : '$address/$netmask';
}

class StaticRoute {
  const StaticRoute({
    required this.id,
    required this.destination,
    required this.gateway,
    this.description,
  });

  factory StaticRoute.fromJson(JsonObject json) => StaticRoute(
    id: _integer(json['id']),
    destination: _string(json['destination'], fallback: 'Unknown network'),
    gateway: _string(json['gateway'], fallback: 'Unknown gateway'),
    description: _nullableString(json['description']),
  );

  final int id;
  final String destination;
  final String gateway;
  final String? description;
}

class SystemUpdateStatus {
  const SystemUpdateStatus({
    required this.code,
    this.train,
    this.profile,
    this.newVersion,
    this.releaseNotesUrl,
    this.error,
    this.downloadPercent,
    this.downloadDescription,
  });

  factory SystemUpdateStatus.fromJson(JsonObject json) {
    final status = _object(json['status']);
    final current = _object(status?['current_version']);
    final next = _object(status?['new_version']);
    final error = _object(json['error']);
    final progress = _object(json['update_download_progress']);
    return SystemUpdateStatus(
      code: _string(json['code'], fallback: 'ERROR'),
      train: _nullableString(current?['train']),
      profile: _nullableString(current?['profile']),
      newVersion: _nullableString(next?['version']),
      releaseNotesUrl: _nullableString(next?['release_notes_url']),
      error: _nullableString(error?['reason']),
      downloadPercent: (progress?['percent'] as num?)?.toDouble(),
      downloadDescription: _nullableString(progress?['description']),
    );
  }

  final String code;
  final String? train;
  final String? profile;
  final String? newVersion;
  final String? releaseNotesUrl;
  final String? error;
  final double? downloadPercent;
  final String? downloadDescription;

  bool get updateAvailable => newVersion != null;
  bool get hasError => code == 'ERROR';
}

enum SystemUpdateChannel { developer, earlyAdopter, general }

class SystemUpdateProfile {
  const SystemUpdateProfile({
    required this.id,
    required this.name,
    required this.channel,
    required this.available,
    this.description,
  });

  factory SystemUpdateProfile.fromEntry(String id, Object? value) {
    final json = _object(value);
    final name = _nullableString(json?['name']) ?? id;
    final haystack = '$id $name ${json?['description'] ?? ''}'.toLowerCase();
    final normalizedId = id.trim().toUpperCase();
    final channel =
        normalizedId == 'DEVELOPER' ||
            normalizedId == 'NIGHTLY' ||
            haystack.contains('nightly') ||
            haystack.contains('developer')
        ? SystemUpdateChannel.developer
        : normalizedId == 'EARLY_ADOPTER' || haystack.contains('early adopter')
        ? SystemUpdateChannel.earlyAdopter
        : SystemUpdateChannel.general;
    return SystemUpdateProfile(
      id: id,
      name: name,
      channel: channel,
      available: json?['available'] != false,
      description: _nullableString(json?['description']),
    );
  }

  final String id;
  final String name;
  final SystemUpdateChannel channel;
  final bool available;
  final String? description;
}

class SystemUpdateProfiles {
  const SystemUpdateProfiles({required this.currentId, required this.items});

  final String? currentId;
  final List<SystemUpdateProfile> items;
}

int _integer(Object? value, {int fallback = 0}) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

int? _nullableInteger(Object? value) => value == null ? null : _integer(value);

String _string(Object? value, {required String fallback}) =>
    value is String && value.isNotEmpty ? value : fallback;

String? _nullableString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

JsonObject? _object(Object? value) => value is JsonObject ? value : null;

List<JsonObject> _objects(Object? value) => value is List<Object?>
    ? value.whereType<JsonObject>().toList(growable: false)
    : const [];

List<String> _strings(Object? value) => value is List<Object?>
    ? value.whereType<String>().toList(growable: false)
    : const [];

List<int> _integers(Object? value) => value is List<Object?>
    ? value.whereType<num>().map((item) => item.toInt()).toList(growable: false)
    : const [];

/// `user.query` nests the primary group as `{"id": .., "bsdgrp_gid": ..}`,
/// while older shapes return a bare id.
int? _groupId(Object? value) {
  if (value is JsonObject) {
    final id = value['id'];
    return id is num ? id.toInt() : null;
  }
  return value is num ? value.toInt() : null;
}
