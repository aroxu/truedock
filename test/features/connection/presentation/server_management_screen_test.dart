import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:true_dock/app/true_dock_app.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/core/navigation/app_router.dart';
import 'package:true_dock/core/security/credential_vault.dart';
import 'package:true_dock/core/security/security_providers.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/domain/auth_credential.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';
import 'package:true_dock/features/connection/presentation/connection_controller.dart';
import 'package:true_dock/features/connection/presentation/server_management_screen.dart';

class _NoopVault implements CredentialVault {
  @override
  Future<BiometricVaultAvailability> availability() async =>
      const BiometricVaultAvailability(BiometricVaultStatus.unsupported);
  @override
  Future<void> save(ServerProfile profile, AuthCredential credential) async {}
  @override
  Future<AuthCredential?> unlock(ServerProfile profile) async => null;
  @override
  Future<void> delete(ServerProfile profile) async {}
}

/// Reports a live session for a chosen profile and records the switch and
/// forget calls the screen makes, so navigation is not driven by a real socket.
class _FakeConnectionController extends ConnectionController {
  _FakeConnectionController()
    : super(TrueNasJsonRpcClient(), SavedServerRepository(vault: _NoopVault()));

  final List<String> switched = [];
  final List<String> forgotten = [];
  final List<(String, String)> renamed = [];
  int disconnects = 0;

  void connectTo(ServerProfile profile) {
    state = NasConnectionState(
      stage: ConnectionStage.connected,
      profile: profile,
      username: 'admin',
    );
  }

  @override
  Future<void> switchToSaved(SavedServer server) async {
    switched.add(server.profile.id);
  }

  @override
  Future<void> disconnect() async {
    disconnects++;
  }

  @override
  Future<void> forgetSavedServer(ServerProfile profile) async {
    forgotten.add(profile.id);
  }

  @override
  Future<void> renameSavedServer(ServerProfile profile, String name) async {
    renamed.add((profile.id, name));
  }
}

final _active = ServerProfile(
  name: 'Home NAS',
  baseUri: Uri.parse('https://nas-a.local'),
);
final _other = ServerProfile(
  name: 'Rack NAS',
  baseUri: Uri.parse('https://nas-b.local'),
);

SavedServer _saved(ServerProfile profile, {bool hasSavedCredential = true}) =>
    SavedServer(
      profile: profile,
      username: 'admin',
      authMethod: AuthMethod.apiKey,
      hasSavedCredential: hasSavedCredential,
    );

/// Opens the Settings server switcher on a connected session.
Future<_FakeConnectionController> _openSwitcher(
  WidgetTester tester, {
  required List<SavedServer> servers,
}) async {
  final controller = _FakeConnectionController()..connectTo(_active);
  final container = ProviderContainer(
    overrides: [
      connectionControllerProvider.overrideWith((ref) => controller),
      biometricVaultAvailabilityProvider.overrideWith(
        (ref) async =>
            const BiometricVaultAvailability(BiometricVaultStatus.unsupported),
      ),
      savedServersProvider.overrideWith((ref) async => servers),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const TrueDockApp()),
  );
  await tester.pumpAndSettle();

  container.read(appRouterProvider).go('/system/servers');
  await tester.pumpAndSettle();
  expect(find.byType(ServerManagementScreen), findsOneWidget);
  return controller;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('lists every registered server and marks the active one', (
    tester,
  ) async {
    await _openSwitcher(tester, servers: [_saved(_active), _saved(_other)]);

    expect(find.widgetWithText(ListTile, 'Home NAS'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Rack NAS'), findsOneWidget);
    expect(find.textContaining('Active server'), findsOneWidget);
  });

  testWidgets('a server needing a fresh sign-in is labelled as such', (
    tester,
  ) async {
    await _openSwitcher(
      tester,
      servers: [_saved(_active), _saved(_other, hasSavedCredential: false)],
    );

    expect(find.textContaining('Sign in required'), findsOneWidget);
  });

  testWidgets('renames a registered server from its options', (tester) async {
    final controller = await _openSwitcher(
      tester,
      servers: [_saved(_active), _saved(_other)],
    );

    await tester.tap(find.byIcon(Icons.more_vert).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename').last);
    await tester.pumpAndSettle();

    expect(find.text('Rename server'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Backup NAS');
    await tester.tap(find.widgetWithText(FilledButton, 'Rename'));
    await tester.pumpAndSettle();

    expect(controller.renamed, [(_other.id, 'Backup NAS')]);
  });

  testWidgets('the active server is not tappable, so it cannot be dropped', (
    tester,
  ) async {
    final controller = await _openSwitcher(
      tester,
      servers: [_saved(_active), _saved(_other)],
    );

    await tester.tap(find.widgetWithText(ListTile, 'Home NAS'));
    await tester.pumpAndSettle();

    expect(find.text('Switch server?'), findsNothing);
    expect(controller.switched, isEmpty);
    expect(find.byType(ServerManagementScreen), findsOneWidget);
  });

  testWidgets('switching asks first and names the target server', (
    tester,
  ) async {
    final controller = await _openSwitcher(
      tester,
      servers: [_saved(_active), _saved(_other)],
    );

    await tester.tap(find.widgetWithText(ListTile, 'Rack NAS'));
    await tester.pumpAndSettle();

    expect(find.text('Switch server?'), findsOneWidget);
    expect(find.textContaining('Rack NAS'), findsWidgets);

    // Cancelling must leave the current session untouched.
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(controller.switched, isEmpty);
    expect(controller.disconnects, 0);
    expect(find.byType(ServerManagementScreen), findsOneWidget);
  });

  testWidgets('confirming a switch uses the saved authentication directly', (
    tester,
  ) async {
    final controller = await _openSwitcher(
      tester,
      servers: [_saved(_active), _saved(_other)],
    );

    await tester.tap(find.widgetWithText(ListTile, 'Rack NAS'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Switch server'));
    await tester.pumpAndSettle();

    expect(controller.switched, [_other.id]);
    expect(find.text('Add TrueNAS server'), findsNothing);
    expect(find.text('Server name'), findsNothing);
    expect(find.text('TrueNAS Server Address'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('forgetting a server requires confirmation', (tester) async {
    final controller = await _openSwitcher(
      tester,
      servers: [_saved(_active), _saved(_other)],
    );

    await tester.tap(find.byIcon(Icons.more_vert).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forget server').last);
    await tester.pumpAndSettle();

    expect(find.text('Forget this server?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(controller.forgotten, isEmpty);

    await tester.tap(find.byIcon(Icons.more_vert).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forget server').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Forget server'));
    await tester.pumpAndSettle();

    expect(controller.forgotten, [_other.id]);
    // A non-active server must not end the live session.
    expect(controller.disconnects, 0);
  });

  testWidgets('forgetting the active server disconnects it first', (
    tester,
  ) async {
    final controller = await _openSwitcher(
      tester,
      servers: [_saved(_active), _saved(_other)],
    );

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forget server').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Disconnect from Home NAS'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Forget server'));
    await tester.pumpAndSettle();

    expect(controller.disconnects, 1);
    expect(controller.forgotten, [_active.id]);
  });
}
