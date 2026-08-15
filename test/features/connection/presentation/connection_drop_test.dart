import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A channel whose inbound stream and sink are driven by the test, so a
/// dropped or erroring socket can be simulated deterministically.
class _FakeChannel extends StreamChannelMixin<Object?>
    implements WebSocketChannel {
  _FakeChannel()
    : _inbound = StreamController<Object?>(),
      _outbound = _RecordingSink();

  final StreamController<Object?> _inbound;
  final _RecordingSink _outbound;

  void emit(Object? message) => _inbound.add(message);
  void dropWithError(Object error) => _inbound.addError(error);
  Future<void> dropCleanly() => _inbound.close();

  List<Object?> get sent => _outbound.sent;

  @override
  Stream<Object?> get stream => _inbound.stream;

  @override
  WebSocketSink get sink => _outbound;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingSink implements WebSocketSink {
  final List<Object?> sent = [];
  bool closed = false;

  @override
  void add(Object? data) => sent.add(data);

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

final _profile = ServerProfile(
  name: 'nas',
  baseUri: Uri.parse('https://nas.local'),
);

void main() {
  group('in-flight requests when the socket drops', () {
    test('a clean close fails the pending call instead of hanging', () async {
      final channel = _FakeChannel();
      final client = TrueNasJsonRpcClient(connector: (_) async => channel);
      await client.connect(_profile);

      final pending = client.call('pool.query');
      await Future<void>.delayed(Duration.zero);
      await channel.dropCleanly();

      // Without this, the UI would spin on a future that never completes.
      await expectLater(
        pending,
        throwsA(
          isA<TrueNasRpcException>().having(
            (e) => e.message,
            'message',
            contains('closed'),
          ),
        ),
      );
    });

    test('a socket error fails the pending call', () async {
      final channel = _FakeChannel();
      final client = TrueNasJsonRpcClient(connector: (_) async => channel);
      await client.connect(_profile);

      final pending = client.call('pool.query');
      await Future<void>.delayed(Duration.zero);
      channel.dropWithError(const SocketDropped());

      await expectLater(pending, throwsA(isA<TrueNasRpcException>()));
    });

    test('every concurrent request fails, not just the first', () async {
      final channel = _FakeChannel();
      final client = TrueNasJsonRpcClient(connector: (_) async => channel);
      await client.connect(_profile);

      final a = client.call('pool.query');
      final b = client.call('disk.query');
      final c = client.call('app.query');
      await Future<void>.delayed(Duration.zero);
      await channel.dropCleanly();

      await expectLater(a, throwsA(isA<TrueNasRpcException>()));
      await expectLater(b, throwsA(isA<TrueNasRpcException>()));
      await expectLater(c, throwsA(isA<TrueNasRpcException>()));
    });
  });

  group('connection liveness', () {
    test('isConnected turns false once the socket closes', () async {
      final channel = _FakeChannel();
      final client = TrueNasJsonRpcClient(connector: (_) async => channel);
      await client.connect(_profile);
      expect(client.isConnected, isTrue);

      await channel.dropCleanly();
      await Future<void>.delayed(Duration.zero);

      // A stale `true` here is what lets the UI keep claiming "connected".
      expect(client.isConnected, isFalse);
    });

    test(
      'a call after the drop fails fast rather than waiting for a timeout',
      () async {
        final channel = _FakeChannel();
        final client = TrueNasJsonRpcClient(connector: (_) async => channel);
        await client.connect(_profile);
        await channel.dropCleanly();
        await Future<void>.delayed(Duration.zero);

        await expectLater(
          client.call('pool.query'),
          throwsA(
            isA<TrueNasRpcException>().having(
              (e) => e.message,
              'message',
              contains('Not connected'),
            ),
          ),
        );
      },
    );
  });

  group('notification stream', () {
    test(
      'surfaces a socket error so listeners can react to the drop',
      () async {
        final channel = _FakeChannel();
        final client = TrueNasJsonRpcClient(connector: (_) async => channel);
        await client.connect(_profile);

        final errors = <Object>[];
        client.notifications.listen((_) {}, onError: errors.add);

        channel.dropWithError(const SocketDropped());
        await Future<void>.delayed(Duration.zero);

        expect(
          errors,
          isNotEmpty,
          reason: 'a dropped socket must reach notification listeners',
        );
      },
    );

    test('delivers server-pushed events to listeners', () async {
      final channel = _FakeChannel();
      final client = TrueNasJsonRpcClient(connector: (_) async => channel);
      await client.connect(_profile);

      final received = <RpcNotification>[];
      client.notifications.listen(received.add);

      channel.emit(
        jsonEncode({
          'jsonrpc': '2.0',
          'method': 'collection_update',
          'params': {'collection': 'core.get_jobs'},
        }),
      );
      await Future<void>.delayed(Duration.zero);

      expect(received.single.method, 'collection_update');
    });
  });
}

class SocketDropped implements Exception {
  const SocketDropped();
  @override
  String toString() => 'SocketDropped';
}
