import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/core/security/credential_vault.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/domain/auth_credential.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';
import 'package:true_dock/features/connection/presentation/connection_controller.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Answers every JSON-RPC request from a canned map so a full connect can be
/// driven without a server, while recording the methods that were sent.
class _ScriptedChannel extends StreamChannelMixin<Object?>
    implements WebSocketChannel {
  _ScriptedChannel(this.responses)
    : _inbound = StreamController<Object?>(),
      _sink = _ReplyingSink();

  final Map<String, Object?> responses;
  final StreamController<Object?> _inbound;
  final _ReplyingSink _sink;

  List<String> get sentMethods => _sink.methods;
  bool get closed => _sink.closed;

  void wire() => _sink.onRequest = (id, method) {
    _inbound.add(
      jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': responses[method]}),
    );
  };

  @override
  Stream<Object?> get stream => _inbound.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReplyingSink implements WebSocketSink {
  void Function(int id, String method)? onRequest;
  final List<String> methods = [];
  bool closed = false;

  @override
  void add(Object? data) {
    final decoded = jsonDecode(data! as String) as Map<String, dynamic>;
    final id = decoded['id'];
    final method = decoded['method'];
    if (id is int && method is String) {
      methods.add(method);
      scheduleMicrotask(() => onRequest?.call(id, method));
    }
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    closed = true;
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future<void> addStream(Stream<Object?> stream) async {}
  @override
  Future<void> get done => Future<void>.value();
}

/// Holds one credential per profile, so a switch that unlocks the wrong
/// server's entry is observable.
class _MapVault implements CredentialVault {
  _MapVault(this.credentials);

  final Map<String, AuthCredential> credentials;
  final List<String> unlocked = [];
  final List<String> deleted = [];

  @override
  Future<BiometricVaultAvailability> availability() async =>
      const BiometricVaultAvailability(BiometricVaultStatus.available);

  @override
  Future<void> save(ServerProfile profile, AuthCredential credential) async {
    credentials[profile.id] = credential;
  }

  @override
  Future<AuthCredential?> unlock(ServerProfile profile) async {
    unlocked.add(profile.id);
    return credentials[profile.id];
  }

  @override
  Future<void> delete(ServerProfile profile) async {
    credentials.remove(profile.id);
    deleted.add(profile.id);
  }
}

class _StubSavedServerRepository extends SavedServerRepository {
  _StubSavedServerRepository(this.mapVault) : super(vault: mapVault);

  final _MapVault mapVault;
  final List<ServerProfile> registered = [];

  @override
  Future<void> register(
    ServerProfile profile,
    AuthCredential credential, {
    required bool saveCredential,
    String? appPassword,
    bool enableBiometricUnlock = false,
  }) async {
    registered.add(profile);
  }

  @override
  Future<void> delete(ServerProfile profile) async {
    await mapVault.delete(profile);
  }
}

final _primary = ServerProfile(
  name: 'primary',
  baseUri: Uri.parse('https://nas-a.local'),
);
final _secondary = ServerProfile(
  name: 'secondary',
  baseUri: Uri.parse('https://nas-b.local'),
  pinnedCertificateSha256: 'bb:bb',
);

Map<String, Object?> _responsesFor(String hostname) => {
  'auth.login_ex': {
    'response_type': 'SUCCESS',
    'user_info': {'pw_name': 'admin-$hostname'},
  },
  'system.info': {
    'hostname': hostname,
    'version': 'TrueNAS-SCALE-25.10.2',
    'uptime': '1 day',
    'uptime_seconds': 86400,
    'physmem': 8589934592,
    'model': 'CPU',
    'cores': 4,
  },
  'system.product_type': 'COMMUNITY_EDITION',
  'core.get_methods': {
    'auth.login_ex': <String, Object?>{},
    'system.info': <String, Object?>{},
    'pool.query': <String, Object?>{},
  },
  'auth.logout': true,
};

SavedServer _saved(ServerProfile profile, {bool hasSavedCredential = true}) =>
    SavedServer(
      profile: profile,
      username: 'admin',
      authMethod: AuthMethod.apiKey,
      hasSavedCredential: hasSavedCredential,
    );

/// Connects to [_primary], then hands back the pieces needed to switch.
Future<
  ({
    ConnectionController controller,
    List<_ScriptedChannel> channels,
    List<Uri> connectedUris,
    _MapVault vault,
  })
>
_connectedToPrimary() async {
  final channels = <_ScriptedChannel>[];
  final connectedUris = <Uri>[];
  final client = TrueNasJsonRpcClient(
    connector: (profile) async {
      connectedUris.add(profile.baseUri);
      final channel = _ScriptedChannel(_responsesFor(profile.baseUri.host))
        ..wire();
      channels.add(channel);
      return channel;
    },
  );
  final vault = _MapVault({
    _primary.id: const ApiKeyCredential(username: 'admin', apiKey: 'key-a'),
    _secondary.id: const ApiKeyCredential(username: 'admin', apiKey: 'key-b'),
  });
  final controller = ConnectionController(
    client,
    _StubSavedServerRepository(vault),
  );
  await controller.connect(
    _primary,
    const ApiKeyCredential(username: 'admin', apiKey: 'key-a'),
  );
  return (
    controller: controller,
    channels: channels,
    connectedUris: connectedUris,
    vault: vault,
  );
}

void main() {
  test('switching connects to the newly selected server', () async {
    final session = await _connectedToPrimary();
    addTearDown(session.controller.dispose);
    expect(session.controller.state.profile?.id, _primary.id);

    await session.controller.switchToSaved(_saved(_secondary));

    expect(session.controller.state.stage, ConnectionStage.connected);
    expect(session.controller.state.profile?.id, _secondary.id);
    expect(session.controller.state.systemInfo?.hostname, 'nas-b.local');
    expect(session.connectedUris, [_primary.baseUri, _secondary.baseUri]);
  });

  test(
    'switching ends the previous session instead of abandoning it',
    () async {
      final session = await _connectedToPrimary();
      addTearDown(session.controller.dispose);

      await session.controller.switchToSaved(_saved(_secondary));

      // Dropping the socket alone would leave the old session authenticated on
      // the first server until it timed out.
      expect(session.channels.first.sentMethods, contains('auth.logout'));
      expect(session.channels.first.closed, isTrue);
    },
  );

  test('switching uses the target server\'s own saved credential', () async {
    final session = await _connectedToPrimary();
    addTearDown(session.controller.dispose);

    await session.controller.switchToSaved(_saved(_secondary));

    expect(session.vault.unlocked, [_secondary.id]);
  });

  test('switching carries the target profile\'s pinned certificate', () async {
    final session = await _connectedToPrimary();
    addTearDown(session.controller.dispose);

    await session.controller.switchToSaved(_saved(_secondary));

    expect(session.controller.state.profile?.pinnedCertificateSha256, 'bb:bb');
  });

  test('selecting the already active server is a no-op', () async {
    final session = await _connectedToPrimary();
    addTearDown(session.controller.dispose);

    await session.controller.switchToSaved(_saved(_primary));

    // No reconnect, and above all no sign-out of the session in use.
    expect(session.channels, hasLength(1));
    expect(session.channels.single.sentMethods, isNot(contains('auth.logout')));
    expect(session.controller.state.isConnected, isTrue);
  });

  test(
    'a switch to a server with no saved credential fails without keeping the '
    'old session',
    () async {
      final session = await _connectedToPrimary();
      addTearDown(session.controller.dispose);
      session.vault.credentials.remove(_secondary.id);

      await session.controller.switchToSaved(_saved(_secondary));

      expect(session.controller.state.stage, ConnectionStage.failure);
      expect(session.controller.state.profile?.id, _secondary.id);
      expect(session.controller.state.isConnected, isFalse);
      expect(session.channels.first.closed, isTrue);
    },
  );

  test('forgetting a server removes its stored credential', () async {
    final session = await _connectedToPrimary();
    addTearDown(session.controller.dispose);

    await session.controller.forgetSavedServer(_secondary);

    expect(session.vault.deleted, [_secondary.id]);
    expect(session.vault.credentials.containsKey(_secondary.id), isFalse);
  });
}
