import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/domain/iscsi_auth_configuration.dart';
import 'package:true_dock/features/storage/presentation/iscsi_auth_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

IscsiAuth _auth({bool mutual = false}) => IscsiAuth.fromJson({
  'id': 4,
  'tag': 1,
  'user': 'alice',
  if (mutual) 'peeruser': 'target-peer',
});

/// Pumps a host that opens the sheet on tap, and returns a [Completer] that
/// resolves with the sheet's popped value once the sheet closes.
Future<Completer<IscsiAuthConfiguration?>> _pumpOpener(
  WidgetTester tester, {
  required IscsiAuthSheet Function() buildSheet,
}) async {
  final completer = Completer<IscsiAuthConfiguration?>();
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
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final value = await showModalBottomSheet<IscsiAuthConfiguration>(
                context: context,
                isScrollControlled: true,
                builder: (_) => buildSheet(),
              );
              if (!completer.isCompleted) completer.complete(value);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return completer;
}

Future<void> _fillField(WidgetTester tester, String label, String text) async {
  final fields = find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );
  await tester.ensureVisible(fields.first);
  await tester.pumpAndSettle();
  await tester.enterText(fields.first, text);
  await tester.pump();
}

void main() {
  testWidgets('creates a one-way credential after review', (tester) async {
    final completer = await _pumpOpener(
      tester,
      buildSheet: () => const IscsiAuthSheet(nextTag: 1),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await _fillField(tester, 'CHAP user', 'alice');
    await _fillField(tester, 'Secret', 's3cret');
    await _fillField(tester, 'Confirm secret', 's3cret');

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    // Review confirms the secret was set (length shown, not the value).
    expect(find.textContaining('Set · 6 characters'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Create credential'));
    await tester.pumpAndSettle();

    final captured = await completer.future;
    expect(captured, isNotNull);
    expect(captured!.user, 'alice');
    expect(captured.secret, 's3cret');
    expect(captured.isMutual, isFalse);
    expect(captured.peerUser, isEmpty);
    expect(captured.peerSecret, isNull);
  });

  testWidgets('blocks review when secrets do not match', (tester) async {
    final completer = await _pumpOpener(
      tester,
      buildSheet: () => const IscsiAuthSheet(nextTag: 1),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await _fillField(tester, 'CHAP user', 'alice');
    await _fillField(tester, 'Secret', 's3cret');
    await _fillField(tester, 'Confirm secret', 'different');

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('The two secrets do not match.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    // Still on the form, review not shown.
    expect(find.text('Tag'), findsNothing);
    expect(completer.isCompleted, isFalse);
  });

  testWidgets('edit mode allows leaving the secret unchanged', (tester) async {
    final completer = await _pumpOpener(
      tester,
      buildSheet: () => IscsiAuthSheet(existingAuth: _auth()),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // On edit the secret fields are optional; submit with just the user.
    await _fillField(tester, 'CHAP user', 'alice');

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    expect(find.text('Unchanged'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    final captured = await completer.future;
    expect(captured, isNotNull);
    expect(captured!.user, 'alice');
    expect(captured.secret, isNull);
    expect(captured.isMutual, isFalse);
  });

  testWidgets('builds a mutual CHAP credential with peer fields', (
    tester,
  ) async {
    final completer = await _pumpOpener(
      tester,
      buildSheet: () => const IscsiAuthSheet(nextTag: 2),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await _fillField(tester, 'CHAP user', 'bob');
    await _fillField(tester, 'Secret', 's3cret');
    await _fillField(tester, 'Confirm secret', 's3cret');

    // Toggle mutual CHAP on.
    await tester.tap(find.text('Mutual CHAP'));
    await tester.pumpAndSettle();

    await _fillField(tester, 'Peer user', 'target-peer');
    await _fillField(tester, 'Peer secret', 'peers3cret');
    await _fillField(tester, 'Confirm peer secret', 'peers3cret');

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    expect(find.text('Yes'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Create credential'));
    await tester.pumpAndSettle();

    final captured = await completer.future;
    expect(captured, isNotNull);
    expect(captured!.user, 'bob');
    expect(captured.secret, 's3cret');
    expect(captured.isMutual, isTrue);
    expect(captured.peerUser, 'target-peer');
    expect(captured.peerSecret, 'peers3cret');
  });
}
