import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/features/actions/data/server_actions_repository.dart';
import 'package:true_dock/features/actions/presentation/server_action_controller.dart';
import 'package:true_dock/features/system/presentation/network_commit_sheet.dart';
import 'package:true_dock/features/connection/domain/connection_message.dart';
import 'package:true_dock/l10n/app_localizations.dart';

class _StubClient extends TrueNasJsonRpcClient {
  _StubClient({this.responses = const {}});

  final Map<String, Object?> responses;
  String? lastMethod;

  @override
  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 20),
  }) async {
    lastMethod = method;
    return responses[method] ?? 42;
  }
}

void main() {
  testWidgets('pending stage shows commit guidance and Commit button', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        serverActionsRepositoryProvider.overrideWithValue(
          ServerActionsRepository(_StubClient()),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: NetworkCommitSheet(
              serverName: 'nas-test',
              serverAddress: 'https://10.0.0.1',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Apply network changes'), findsOneWidget);
    expect(find.text('Commit changes'), findsOneWidget);
    expect(
      find.textContaining('briefly disrupts connectivity'),
      findsOneWidget,
    );
  });

  testWidgets('commit moves to verifying stage on success', (tester) async {
    final client = _StubClient(responses: {'interface.commit': 99});
    final container = ProviderContainer(
      overrides: [
        serverActionsRepositoryProvider.overrideWithValue(
          ServerActionsRepository(client),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: NetworkCommitSheet(
              serverName: 'nas-test',
              serverAddress: 'https://10.0.0.1',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Commit changes'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Verify the connection'), findsOneWidget);
    expect(find.text('Check in'), findsOneWidget);
    expect(find.text('Roll back'), findsOneWidget);
  });

  testWidgets('check in moves to done stage', (tester) async {
    final client = _StubClient(
      responses: {'interface.commit': 1, 'interface.checkin': 2},
    );
    final container = ProviderContainer(
      overrides: [
        serverActionsRepositoryProvider.overrideWithValue(
          ServerActionsRepository(client),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: NetworkCommitSheet(
              serverName: 'nas-test',
              serverAddress: 'https://10.0.0.1',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Commit changes'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Check in'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Changes applied'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('roll back moves to rolledBack stage', (tester) async {
    final client = _StubClient(
      responses: {'interface.commit': 1, 'interface.rollback': 2},
    );
    final container = ProviderContainer(
      overrides: [
        serverActionsRepositoryProvider.overrideWithValue(
          ServerActionsRepository(client),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: NetworkCommitSheet(
              serverName: 'nas-test',
              serverAddress: 'https://10.0.0.1',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Commit changes'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Roll back'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Changes rolled back'), findsOneWidget);
  });

  testWidgets('changed address must pass a connection test before check-in', (
    tester,
  ) async {
    final client = _StubClient(
      responses: {'interface.commit': 1, 'interface.checkin': 2},
    );
    final testedAddresses = <String>[];
    var confirmedAddress = false;
    final container = ProviderContainer(
      overrides: [
        serverActionsRepositoryProvider.overrideWithValue(
          ServerActionsRepository(client),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: NetworkCommitSheet(
              serverName: 'nas-test',
              serverAddress: 'https://10.0.0.1',
              testChangedAddress: (address) async {
                testedAddresses.add(address);
                return null;
              },
              confirmChangedAddress: () async => confirmedAddress = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Commit changes'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('network-address-changed')));
    await tester.pump();
    expect(find.widgetWithText(FilledButton, 'Check in'), findsOneWidget);
    final disabled = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Check in'),
    );
    expect(disabled.onPressed, isNull);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('network-new-server-address')),
      160,
    );
    await tester.enterText(
      find.byKey(const ValueKey('network-new-server-address')),
      'https://10.0.0.22',
    );
    await tester.tap(find.byKey(const ValueKey('test-network-address')));
    await tester.pumpAndSettle();

    expect(testedAddresses, ['https://10.0.0.22']);
    final enabled = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Check in'),
    );
    expect(enabled.onPressed, isNotNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Check in'));
    await tester.pumpAndSettle();
    expect(confirmedAddress, isTrue);
  });

  testWidgets('failed new-address test keeps check-in disabled', (
    tester,
  ) async {
    final client = _StubClient(responses: {'interface.commit': 1});
    final container = ProviderContainer(
      overrides: [
        serverActionsRepositoryProvider.overrideWithValue(
          ServerActionsRepository(client),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: NetworkCommitSheet(
              serverName: 'nas-test',
              serverAddress: 'https://10.0.0.1',
              testChangedAddress: (_) async =>
                  const ConnectionMessage.raw('Could not reach new address.'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Commit changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('network-address-changed')));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('network-new-server-address')),
      160,
    );
    await tester.enterText(
      find.byKey(const ValueKey('network-new-server-address')),
      'https://10.0.0.99',
    );
    await tester.tap(find.byKey(const ValueKey('test-network-address')));
    await tester.pumpAndSettle();

    expect(find.text('Could not reach new address.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Check in'))
          .onPressed,
      isNull,
    );
  });
}
