import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'truenas_json_rpc_client.dart';

final trueNasClientProvider = Provider<TrueNasJsonRpcClient>((ref) {
  final client = TrueNasJsonRpcClient();
  ref.onDispose(() => unawaited(client.close()));
  return client;
});
