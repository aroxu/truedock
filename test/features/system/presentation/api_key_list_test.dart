import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/system/domain/system_resources.dart';
import 'package:true_dock/features/system/presentation/api_key_list.dart';
import 'package:true_dock/l10n/app_localizations.dart';
import 'package:true_dock/core/domain/data_message.dart';

final _now = DateTime.utc(2026, 8, 11);

NasApiKey _key({
  int id = 1,
  String name = 'backup-runner',
  bool revoked = false,
  String? username = 'admin',
  DateTime? expiresAt,
  DateTime? createdAt,
}) => NasApiKey(
  id: id,
  name: name,
  revoked: revoked,
  username: username,
  expiresAt: expiresAt,
  createdAt: createdAt,
);

Future<List<int>> _pump(
  WidgetTester tester, {
  required ResourceSection<NasApiKey> section,
  bool canRevoke = true,
  Set<int> busyIds = const {},
}) async {
  final revoked = <int>[];
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ApiKeyList(
            section: section,
            canRevoke: canRevoke,
            busyIds: busyIds,
            onRevoke: (key) => revoked.add(key.id),
            now: _now,
          ),
        ),
      ),
    ),
  );
  return revoked;
}

void main() {
  testWidgets('lists a usable key with its owner and no-expiry state', (
    tester,
  ) async {
    await _pump(tester, section: ResourceSection(items: [_key()]));

    expect(find.text('backup-runner'), findsOneWidget);
    expect(find.textContaining('admin'), findsOneWidget);
    expect(find.textContaining('no expiry'), findsOneWidget);
  });

  testWidgets('never renders key material', (tester) async {
    // TrueNAS returns the secret only at creation; the model must not carry it.
    await _pump(tester, section: ResourceSection(items: [_key()]));

    expect(find.textContaining('-'), findsWidgets);
    expect(find.textContaining('1-'), findsNothing);
  });

  testWidgets('offers revocation for a usable key', (tester) async {
    final revoked = await _pump(
      tester,
      section: ResourceSection(items: [_key(id: 7)]),
    );

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();

    expect(revoked, [7]);
  });

  testWidgets('an already revoked key cannot be revoked again', (tester) async {
    await _pump(tester, section: ResourceSection(items: [_key(revoked: true)]));

    expect(find.textContaining('Revoked'), findsOneWidget);
    // Withholding the action beats showing a control that would be a no-op.
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
  });

  testWidgets('an expired key is labelled separately from a revoked one', (
    tester,
  ) async {
    await _pump(
      tester,
      section: ResourceSection(
        items: [_key(expiresAt: DateTime.utc(2026, 1, 1))],
      ),
    );

    // Expiry is not the same fact as deliberate withdrawal.
    expect(find.textContaining('Expired'), findsOneWidget);
    expect(find.textContaining('Revoked'), findsNothing);
    // It can still be deleted to tidy up.
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
  });

  testWidgets('a future expiry is shown as a date, not as expired', (
    tester,
  ) async {
    await _pump(
      tester,
      section: ResourceSection(
        items: [_key(expiresAt: DateTime.utc(2027, 3, 4))],
      ),
    );

    expect(find.textContaining('expires 2027-03-04'), findsOneWidget);
    expect(find.textContaining('Expired'), findsNothing);
  });

  testWidgets('hides revocation when the server lacks api_key.delete', (
    tester,
  ) async {
    await _pump(
      tester,
      section: ResourceSection(items: [_key()]),
      canRevoke: false,
    );

    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    // The inventory itself stays readable.
    expect(find.text('backup-runner'), findsOneWidget);
  });

  testWidgets('an in-flight revoke replaces that row\'s control', (
    tester,
  ) async {
    await _pump(
      tester,
      section: ResourceSection(
        items: [
          _key(id: 1),
          _key(id: 2, name: 'second'),
        ],
      ),
      busyIds: const {1},
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // The other row keeps its control.
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
  });

  testWidgets('surfaces a permission error instead of an empty list', (
    tester,
  ) async {
    await _pump(
      tester,
      section: const ResourceSection(error: DataMessage.raw('Not authorized')),
    );

    expect(find.text('Not authorized'), findsOneWidget);
  });

  testWidgets('explains an empty inventory', (tester) async {
    await _pump(tester, section: const ResourceSection());

    expect(
      find.text('No API keys are registered on this server.'),
      findsOneWidget,
    );
  });
}
