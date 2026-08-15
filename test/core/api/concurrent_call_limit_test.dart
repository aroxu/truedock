import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A socket that holds every request open until the test releases it, so the
/// number of calls in flight at once is directly observable.
class _HoldingChannel extends StreamChannelMixin<Object?>
    implements WebSocketChannel {
  _HoldingChannel() : _inbound = StreamController<Object?>(), _sink = _Sink();

  final StreamController<Object?> _inbound;
  final _Sink _sink;

  List<int> get openIds => _sink.openIds;
  int get received => _sink.received;

  /// Answers the oldest outstanding request.
  void answerOne() {
    final id = _sink.openIds.removeAt(0);
    _inbound.add(jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': true}));
  }

  Future<void> drop() => _inbound.close();

  @override
  Stream<Object?> get stream => _inbound.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Sink implements WebSocketSink {
  final List<int> openIds = [];
  int received = 0;

  @override
  void add(Object? data) {
    final decoded = jsonDecode(data! as String) as Map<String, dynamic>;
    final id = decoded['id'];
    if (id is int) {
      openIds.add(id);
      received++;
    }
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final profile = ServerProfile.parse(
    name: 'Lab',
    address: 'https://truenas.local',
  );

  Future<(TrueNasJsonRpcClient, _HoldingChannel)> connected() async {
    final channel = _HoldingChannel();
    final client = TrueNasJsonRpcClient(connector: (_) async => channel);
    await client.connect(profile);
    return (client, channel);
  }

  test('never puts more than the server limit of calls on the wire', () async {
    // TrueNAS answers the 21st concurrent call on a connection with
    // "Maximum number of concurrent calls (20) has exceeded". Overview fans out
    // more than twenty section reads, so exceeding the limit is not a
    // hypothetical.
    final (client, channel) = await connected();
    final calls = [for (var i = 0; i < 40; i++) client.call('pool.query')];
    await pumpEventQueue();

    expect(
      channel.received,
      lessThan(20),
      reason: 'more than the server limit reached the socket at once',
    );

    // Draining one admits exactly one more, so the queue makes progress
    // without ever exceeding the cap.
    final admitted = channel.received;
    channel.answerOne();
    await pumpEventQueue();
    expect(channel.received, admitted + 1);

    while (channel.openIds.isNotEmpty) {
      channel.answerOne();
      await pumpEventQueue();
    }
    await Future.wait(calls);
    expect(channel.received, 40, reason: 'every queued call must still run');

    await client.close();
  });

  test('queued calls fail instead of hanging when the socket drops', () async {
    // Calls waiting for a slot were never written to the socket, so the
    // pending-request map does not hold them; without explicit release they
    // would await forever and the UI would sit on a spinner.
    final (client, channel) = await connected();
    // Attach the error handler at creation. A call already on the wire fails
    // the instant the socket drops, so awaiting later would see it as an
    // unhandled error rather than a test assertion.
    var failures = 0;
    final calls = [
      for (var i = 0; i < 30; i++)
        client
            .call('pool.query')
            .then<void>(
              (_) {},
              onError: (Object error) {
                expect(error, isA<TrueNasRpcException>());
                failures++;
              },
            ),
    ];
    await pumpEventQueue();
    expect(channel.received, lessThan(20));

    await channel.drop();
    await pumpEventQueue();
    await Future.wait(calls);

    expect(failures, 30, reason: 'every call should surface the lost socket');
  });
}
