import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/presentation/dataset_unlock_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  testWidgets('asks for a passphrase when the key format is PASSPHRASE', (
    tester,
  ) async {
    await _open(tester);

    expect(find.widgetWithText(TextField, 'Passphrase'), findsOneWidget);
    expect(find.textContaining('does not store it'), findsOneWidget);
  });

  testWidgets('asks for a hex key when the key format is HEX', (tester) async {
    await _open(tester, passphrase: false);

    expect(find.widgetWithText(TextField, 'Hex key'), findsOneWidget);
  });

  testWidgets('returns the secret and child option', (tester) async {
    DatasetUnlockRequest? request;
    await _open(tester, onResult: (value) => request = value);

    await tester.enterText(find.byType(TextField), 'correct horse');
    await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
    await tester.pumpAndSettle();

    expect(request?.secret, 'correct horse');
    expect(request?.usePassphrase, isTrue);
    expect(request?.unlockChildren, isTrue);
  });

  testWidgets('refuses an empty secret', (tester) async {
    DatasetUnlockRequest? request;
    await _open(tester, onResult: (value) => request = value);

    await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Enter the passphrase'), findsOneWidget);
    expect(request, isNull);
  });

  testWidgets('rejects a hex key containing non-hex characters', (
    tester,
  ) async {
    DatasetUnlockRequest? request;
    await _open(
      tester,
      passphrase: false,
      onResult: (value) => request = value,
    );

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
    await tester.pumpAndSettle();

    expect(find.textContaining('only 0-9 and a-f'), findsOneWidget);
    expect(request, isNull);

    await tester.enterText(find.byType(TextField), 'abc123');
    await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
    await tester.pumpAndSettle();

    expect(request?.secret, 'abc123');
    expect(request?.usePassphrase, isFalse);
  });

  testWidgets('obscures the secret by default', (tester) async {
    await _open(tester);

    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isTrue,
    );

    await tester.tap(find.byTooltip('Show'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isFalse,
    );
  });
}

Future<void> _open(
  WidgetTester tester, {
  bool passphrase = true,
  ValueChanged<DatasetUnlockRequest?>? onResult,
}) async {
  tester.view.physicalSize = const Size(430, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final dataset = Dataset.fromJson({
    'id': 'tank/secure',
    'name': 'tank/secure',
    'type': 'FILESYSTEM',
    'encrypted': true,
    'locked': true,
    'encryption_root': 'tank/secure',
    'key_format': {'value': passphrase ? 'PASSPHRASE' : 'HEX'},
  });

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
              final result = await showModalBottomSheet<DatasetUnlockRequest>(
                context: context,
                isScrollControlled: true,
                builder: (context) => DatasetUnlockSheet(dataset: dataset),
              );
              onResult?.call(result);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}
