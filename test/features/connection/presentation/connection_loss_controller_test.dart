import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/core/security/credential_vault.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/domain/auth_credential.dart';
import 'package:true_dock/features/connection/domain/server_capabilities.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';
import 'package:true_dock/features/connection/presentation/connection_controller.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Answers every JSON-RPC request from a canned map, so a full connect can be
/// driven without a server, and can then be dropped on demand.
class _ScriptedChannel extends StreamChannelMixin<Object?>
    implements WebSocketChannel {
  _ScriptedChannel(this.responses)
    : _inbound = StreamController<Object?>(),
      _sink = _ReplyingSink();

  final Map<String, Object?> responses;
  final StreamController<Object?> _inbound;
  final _ReplyingSink _sink;

  /// Every method the client actually sent, in order.
  List<String> get sentMethods => _sink.methods;

  void wire() => _sink.onRequest = (id, method) {
    _inbound.add(
      jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': responses[method]}),
    );
  };

  Future<void> drop() => _inbound.close();

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

  @override
  void add(Object? data) {
    final decoded = jsonDecode(data! as String) as Map<String, dynamic>;
    final id = decoded['id'];
    final method = decoded['method'];
    if (id is int && method is String) {
      methods.add(method);
      // Reply asynchronously, as a real socket would.
      scheduleMicrotask(() => onRequest?.call(id, method));
    }
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future<void> addStream(Stream<Object?> stream) async {}
  @override
  Future<void> get done => Future<void>.value();
}

class _StubVault implements CredentialVault {
  @override
  Future<BiometricVaultAvailability> availability() async =>
      const BiometricVaultAvailability(BiometricVaultStatus.available);
  @override
  Future<void> save(ServerProfile profile, AuthCredential credential) async {}
  @override
  Future<AuthCredential?> unlock(ServerProfile profile) async => null;
  @override
  Future<void> delete(ServerProfile profile) async {}
}

class _RecordingSavedServerRepository extends SavedServerRepository {
  _RecordingSavedServerRepository() : super(vault: _StubVault());

  ServerProfile? registeredProfile;
  bool? savedCredential;

  @override
  Future<void> register(
    ServerProfile profile,
    AuthCredential credential, {
    required bool saveCredential,
    String? appPassword,
    bool enableBiometricUnlock = false,
  }) async {
    registeredProfile = profile;
    savedCredential = saveCredential;
  }
}

class _HangingLogoutClient extends TrueNasJsonRpcClient {
  final logoutStarted = Completer<void>();

  @override
  Future<void> logout() {
    if (!logoutStarted.isCompleted) logoutStarted.complete();
    return Completer<void>().future;
  }
}

final _profile = ServerProfile(
  name: 'nas',
  baseUri: Uri.parse('https://nas.local'),
);

/// A 25.10 Community Edition server that satisfies discovery.
final _responses = <String, Object?>{
  'auth.login_ex': {
    'response_type': 'SUCCESS',
    'user_info': {'pw_name': 'admin'},
  },
  'system.info': {
    'hostname': 'nas',
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
};

Future<
  ({
    ConnectionController controller,
    TrueNasJsonRpcClient client,
    _ScriptedChannel channel,
    List<_ScriptedChannel> channels,
    _RecordingSavedServerRepository savedServers,
  })
>
_connected({
  Map<String, Object?>? responses,
  Map<String, Object?>? reconnectResponses,
  bool keepSignedIn = false,
  List<Duration> automaticReconnectDelays = const [],
}) async {
  final channels = <_ScriptedChannel>[];
  final client = TrueNasJsonRpcClient(
    connector: (_) async {
      final channel = _ScriptedChannel(
        channels.isEmpty
            ? responses ?? _responses
            : reconnectResponses ?? responses ?? _responses,
      )..wire();
      channels.add(channel);
      return channel;
    },
  );
  final savedServers = _RecordingSavedServerRepository();
  final controller = ConnectionController(
    client,
    savedServers,
    automaticReconnectDelays: automaticReconnectDelays,
  );
  await controller.connect(
    _profile,
    const ApiKeyCredential(username: 'admin', apiKey: 'k'),
    keepSignedIn: keepSignedIn,
  );
  return (
    controller: controller,
    client: client,
    channel: channels.single,
    channels: channels,
    savedServers: savedServers,
  );
}

void main() {
  test('a successful connect reaches the connected stage', () async {
    final session = await _connected();
    addTearDown(session.controller.dispose);
    expect(session.controller.state.stage, ConnectionStage.connected);
    expect(session.controller.state.isConnected, isTrue);
  });

  test(
    'a successful connect registers the server without saving the secret',
    () async {
      final session = await _connected();
      addTearDown(session.controller.dispose);

      expect(session.savedServers.registeredProfile?.name, 'nas');
      expect(session.savedServers.savedCredential, isFalse);
    },
  );

  test(
    'keep signed in opts the credential into protected persistence',
    () async {
      final session = await _connected(keepSignedIn: true);
      addTearDown(session.controller.dispose);

      expect(session.savedServers.registeredProfile?.name, 'nas');
      expect(session.savedServers.savedCredential, isTrue);
    },
  );

  test('a dropped socket moves the app out of the connected state', () async {
    final session = await _connected();
    addTearDown(session.controller.dispose);
    expect(session.controller.state.isConnected, isTrue);

    await session.channel.drop();
    await Future<void>.delayed(Duration.zero);

    // Before the fix this stayed `connected`, so every screen kept rendering
    // as though the server were still reachable.
    expect(session.controller.state.isConnected, isFalse);
    expect(session.controller.state.stage, ConnectionStage.connectionLost);
    expect(session.controller.state.isConnectionLost, isTrue);
  });

  test(
    'the drop keeps the profile so the user can reconnect in one tap',
    () async {
      final session = await _connected();
      addTearDown(session.controller.dispose);

      await session.channel.drop();
      await Future<void>.delayed(Duration.zero);

      expect(session.controller.state.profile?.name, 'nas');
      expect(session.controller.state.errorMessage, isNotNull);
    },
  );

  test(
    'reconnect opens a new socket and authenticates with the in-memory credential',
    () async {
      final session = await _connected();
      addTearDown(session.controller.dispose);

      await session.channel.drop();
      await Future<void>.delayed(Duration.zero);
      await session.controller.reconnect();

      expect(session.channels, hasLength(2));
      expect(session.channels.last.sentMethods, contains('auth.login_ex'));
      expect(session.controller.state.stage, ConnectionStage.connected);
    },
  );

  test('a dropped socket automatically reconnects immediately', () async {
    final session = await _connected(
      automaticReconnectDelays: const [Duration.zero],
    );
    addTearDown(session.controller.dispose);

    await session.channel.drop();
    for (var tick = 0; tick < 20 && session.channels.length < 2; tick++) {
      await Future<void>.delayed(Duration.zero);
    }
    for (
      var tick = 0;
      tick < 20 && !session.controller.state.isConnected;
      tick++
    ) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(session.channels, hasLength(2));
    expect(session.channels.last.sentMethods, contains('auth.login_ex'));
    expect(session.controller.state.stage, ConnectionStage.connected);
  });

  test('automatic reconnect failure remains recoverable and retries', () async {
    final session = await _connected(
      reconnectResponses: {
        ..._responses,
        'auth.login_ex': {'response_type': 'AUTH_ERR'},
      },
      automaticReconnectDelays: const [Duration.zero, Duration(hours: 1)],
    );
    addTearDown(session.controller.dispose);

    await session.channel.drop();
    for (var tick = 0; tick < 20 && session.channels.length < 2; tick++) {
      await Future<void>.delayed(Duration.zero);
    }
    await Future<void>.delayed(Duration.zero);

    expect(session.channels, hasLength(2));
    expect(session.controller.state.stage, ConnectionStage.connectionLost);
    expect(session.controller.state.profile?.name, 'nas');
    expect(session.controller.state.errorMessage, isNotNull);
  });

  test('a failed reconnect keeps the retry banner state available', () async {
    final session = await _connected(
      reconnectResponses: {
        ..._responses,
        'auth.login_ex': {'response_type': 'AUTH_ERR'},
      },
    );
    addTearDown(session.controller.dispose);

    await session.channel.drop();
    await Future<void>.delayed(Duration.zero);
    await session.controller.reconnect();

    expect(session.controller.state.stage, ConnectionStage.connectionLost);
    expect(session.controller.state.profile?.name, 'nas');
    expect(session.controller.state.username, 'admin');
    expect(session.controller.state.errorMessage, isNotNull);
  });

  test('the drop retains read-only layout state during recovery', () async {
    final session = await _connected();
    addTearDown(session.controller.dispose);
    expect(session.controller.state.capabilities, isNotNull);

    await session.channel.drop();
    await Future<void>.delayed(Duration.zero);

    // The layout remains stable; mutation dispatch separately requires a live
    // connection and cannot use this retained capability snapshot.
    expect(session.controller.state.capabilities, isNotNull);
    expect(
      session.controller.state.systemInfo,
      isNotNull,
      reason: 'resume UX keeps the last confirmed read-only snapshot visible',
    );
  });

  test(
    'a deliberate disconnect is not reported as a lost connection',
    () async {
      final session = await _connected();
      addTearDown(session.controller.dispose);

      await session.controller.disconnect();
      await Future<void>.delayed(Duration.zero);

      expect(session.controller.state.stage, ConnectionStage.disconnected);
      expect(session.controller.state.isConnectionLost, isFalse);
      expect(session.controller.state.errorMessage, isNull);
    },
  );

  test('device reset does not wait for an unresponsive logout', () async {
    final client = _HangingLogoutClient();
    final controller = ConnectionController(
      client,
      _RecordingSavedServerRepository(),
    );
    addTearDown(controller.dispose);

    await controller.clearSessionForDeviceReset().timeout(
      const Duration(milliseconds: 100),
    );

    expect(controller.state.stage, ConnectionStage.disconnected);
    await client.logoutStarted.future;
  });

  test(
    'disconnecting ends the session on the server, not just locally',
    () async {
      final session = await _connected();
      addTearDown(session.controller.dispose);
      expect(session.channel.sentMethods, contains('auth.login_ex'));

      await session.controller.disconnect();
      await Future<void>.delayed(Duration.zero);

      // Closing the socket alone would leave the authenticated session alive on
      // the server until it timed out, so a "sign out" that skips this is not
      // really a sign out.
      expect(session.channel.sentMethods, contains('auth.logout'));
    },
  );

  test(
    'a lost connection does not attempt a logout over the dead socket',
    () async {
      final session = await _connected();
      addTearDown(session.controller.dispose);

      await session.channel.drop();
      await Future<void>.delayed(Duration.zero);
      await session.controller.disconnect();
      await Future<void>.delayed(Duration.zero);

      // There is no transport left to carry it, so the client must skip the
      // call rather than hang waiting for a reply that cannot arrive.
      expect(session.channel.sentMethods, isNot(contains('auth.logout')));
      expect(session.controller.state.stage, ConnectionStage.disconnected);
    },
  );

  test(
    'the account name comes from login_ex when it carries user_info',
    () async {
      final session = await _connected();
      addTearDown(session.controller.dispose);

      expect(session.controller.state.username, 'admin');
      // No fallback call is needed when login_ex already answered.
      expect(session.channel.sentMethods, isNot(contains('auth.me')));
    },
  );

  test('falls back to auth.me when login_ex omits user_info', () async {
    // An API-key login can return SUCCESS without user_info, which would
    // otherwise leave the saved-server row unlabelled.
    final responses = <String, Object?>{
      ..._responses,
      'auth.login_ex': {'response_type': 'SUCCESS'},
      'auth.me': {'pw_name': 'apiuser'},
    };
    final session = await _connected(responses: responses);
    addTearDown(session.controller.dispose);

    expect(session.channel.sentMethods, contains('auth.me'));
    expect(session.controller.state.username, 'apiuser');
  });

  test(
    'a missing account name never fails an otherwise good connection',
    () async {
      final responses = <String, Object?>{
        ..._responses,
        'auth.login_ex': {'response_type': 'SUCCESS'},
        'auth.me': null,
      };
      final session = await _connected(responses: responses);
      addTearDown(session.controller.dispose);

      expect(session.controller.state.stage, ConnectionStage.connected);
      expect(session.controller.state.username, isNull);
    },
  );

  test('survives sustained connection flapping', () async {
    // A single drop and reconnect is covered above. What a flaky network
    // actually does is drop repeatedly, and the failure mode that hides there is
    // accumulation: a listener, a stale socket, or a pending completer kept per
    // cycle would leave the app connected-looking or leaking after the tenth
    // drop rather than the first.
    final session = await _connected();
    addTearDown(session.controller.dispose);

    for (var cycle = 0; cycle < 10; cycle++) {
      await session.channels.last.drop();
      await Future<void>.delayed(Duration.zero);
      expect(
        session.controller.state.stage,
        ConnectionStage.connectionLost,
        reason: 'cycle $cycle did not report the drop',
      );

      await session.controller.reconnect();
      expect(
        session.controller.state.stage,
        ConnectionStage.connected,
        reason: 'cycle $cycle did not recover',
      );
    }

    // One socket for the initial connect plus one per reconnect, and no more:
    // a retry loop that opened a spare channel per cycle would show up here.
    expect(session.channels, hasLength(11));
    expect(session.controller.state.profile?.name, 'nas');
    expect(session.controller.state.username, 'admin');
  });

  test('reconnect re-reads capabilities instead of reusing the old ones', () async {
    // A drop is usually a network blip, but the one TrueDock causes itself is a
    // restart - and a server can come back different. It may have been updated
    // between the reboot and the reconnect, so the method list and version that
    // described the pre-restart session must not be carried over.
    final session = await _connected(
      reconnectResponses: {
        ..._responses,
        'system.info': {
          'hostname': 'nas',
          'version': 'TrueNAS-SCALE-26.04.0',
          'uptime': '1 minute',
          'uptime_seconds': 60,
          'physmem': 8589934592,
          'model': 'CPU',
          'cores': 4,
        },
      },
    );
    addTearDown(session.controller.dispose);
    expect(session.controller.state.capabilities?.version.major, 25);

    await session.channel.drop();
    await Future<void>.delayed(Duration.zero);
    await session.controller.reconnect();

    expect(session.controller.state.stage, ConnectionStage.connected);
    expect(
      session.controller.state.capabilities?.version,
      const TrueNasVersion(26, 4, 0),
      reason: 'the restarted server was rediscovered, not remembered',
    );
    // Uptime is the clearest evidence the box actually restarted, so it has to
    // come from the new session rather than the cached one.
    expect(session.controller.state.systemInfo?.uptimeSeconds, 60);
  });

  test('a server that comes back unsupported is refused on reconnect', () async {
    // The dangerous version of the above: an update during the restart lands on
    // a build TrueDock cannot drive. Reconnecting has to fail loudly. Silently
    // keeping the old capabilities would leave every gated screen offering
    // actions the server no longer exposes.
    final session = await _connected(
      reconnectResponses: {
        ..._responses,
        'core.get_methods': {
          'auth.login_ex': <String, Object?>{},
          'system.info': <String, Object?>{},
          // pool.query is gone, so discovery must reject the server.
        },
      },
    );
    addTearDown(session.controller.dispose);

    await session.channel.drop();
    await Future<void>.delayed(Duration.zero);
    await session.controller.reconnect();

    expect(session.controller.state.stage, ConnectionStage.connectionLost);
    expect(session.controller.state.capabilities, isNotNull);
    expect(session.controller.state.errorMessage, isNotNull);
  });

  test('a call made while the socket is down fails rather than hangs', () async {
    // The screens issue reads on a timer, so a drop can land between a call
    // being made and the socket going away. That call must surface an error; a
    // silent pending future leaves the UI on a spinner with no way out.
    final session = await _connected();
    addTearDown(session.controller.dispose);

    await session.channels.last.drop();
    await Future<void>.delayed(Duration.zero);

    await expectLater(
      session.client.call('pool.query'),
      throwsA(isA<TrueNasRpcException>()),
    );
  });
}
