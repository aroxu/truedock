import 'dart:async';

import '../../../core/api/truenas_json_rpc_client.dart';
import '../domain/app_stats.dart';

class AppStatsRepository {
  const AppStatsRepository(this._client);

  final TrueNasJsonRpcClient _client;

  Stream<AppStats> watch(String appName) {
    late StreamController<AppStats> controller;
    StreamSubscription<RpcNotification>? notifications;
    String? subscriptionId;

    Future<void> start() async {
      notifications = _client.notifications.listen((notification) {
        if (notification.method != 'collection_update') return;
        for (final stats in appStatsFromNotification(notification.params)) {
          if (stats.appName == appName && !controller.isClosed) {
            controller.add(stats);
          }
        }
      }, onError: controller.addError);
      try {
        final result = await _client.call(
          'core.subscribe',
          params: const ['app.stats:{"interval":2}'],
        );
        if (result is String) subscriptionId = result;
      } on Object catch (error, stackTrace) {
        if (!controller.isClosed) controller.addError(error, stackTrace);
      }
    }

    Future<void> stop() async {
      await notifications?.cancel();
      final id = subscriptionId;
      if (id != null && _client.isConnected) {
        try {
          await _client.call('core.unsubscribe', params: [id]);
        } on Object {
          // The socket may close while the detail sheet is being dismissed.
        }
      }
    }

    controller = StreamController<AppStats>(onListen: start, onCancel: stop);
    return controller.stream;
  }
}
