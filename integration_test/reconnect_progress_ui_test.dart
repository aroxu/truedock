import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/core/widgets/connection_lost_banner.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';
import 'package:true_dock/features/connection/presentation/connection_controller.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows reconnect progress on the iOS runtime', (tester) async {
    final controller = _DelayedReconnectController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectionControllerProvider.overrideWith((ref) => controller),
        ],
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ConnectionLostHost(
            child: Scaffold(body: Center(child: Text('stale content'))),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('connection-reconnect-button')));
    await tester.pump();

    expect(find.text('재연결 중…'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('connection-reconnecting')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.byKey(const ValueKey('connection-reconnect-button')),
      findsNothing,
    );

    controller.finish();
    await tester.pumpAndSettle();

    expect(find.text('재연결 중…'), findsNothing);
    expect(controller.state.isConnected, isTrue);
  });
}

class _DelayedReconnectController extends ConnectionController {
  _DelayedReconnectController()
    : super(TrueNasJsonRpcClient(), SavedServerRepository()) {
    state = NasConnectionState(
      stage: ConnectionStage.connectionLost,
      profile: ServerProfile.parse(
        name: 'Demo NAS',
        address: 'https://truenas.local',
      ),
      username: 'truenas_admin',
    );
  }

  final _gate = Completer<void>();

  @override
  Future<void> reconnect() async {
    final profile = state.profile;
    state = NasConnectionState(
      stage: ConnectionStage.connecting,
      profile: profile,
      username: state.username,
      isReconnecting: true,
    );
    await _gate.future;
    state = NasConnectionState(
      stage: ConnectionStage.connected,
      profile: profile,
      username: state.username,
    );
  }

  void finish() => _gate.complete();
}
