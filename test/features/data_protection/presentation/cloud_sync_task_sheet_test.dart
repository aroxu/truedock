import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/data_protection/domain/cloud_sync_configuration.dart';
import 'package:true_dock/features/data_protection/presentation/cloud_sync_task_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

/// Delegates the app installs, so the sheet resolves the same generated
/// strings it uses in production.
const _delegates = <LocalizationsDelegate<Object>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

const _blank = CloudSyncConfiguration(
  description: '',
  direction: CloudSyncDirection.push,
  transferMode: CloudSyncTransferMode.copy,
  path: '',
);

const _credentials = [
  CloudCredential(id: 3, name: 'Backblaze', provider: 'S3'),
  CloudCredential(id: 4, name: 'My Drive', provider: 'GOOGLE_DRIVE'),
];

Widget _harness({
  CloudSyncConfiguration baseline = _blank,
  List<CloudCredential> credentials = _credentials,
  bool credentialsFailed = false,
}) {
  return MaterialApp(
    localizationsDelegates: _delegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: CloudSyncTaskSheet(
        baseline: baseline,
        credentials: credentials,
        credentialsFailed: credentialsFailed,
      ),
    ),
  );
}

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

/// The default 800x600 test surface squeezes the sheet so rows collide with
/// the bottom action bar. Use a realistic phone surface instead.
void _usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('blocks review and reports missing required fields', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a task name.'), findsOneWidget);
    expect(find.text('Review cloud sync'), findsNothing);
  });

  testWidgets('shows guidance when no cloud credentials exist', (tester) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(_harness(credentials: const []));
    await tester.pumpAndSettle();
    expect(find.textContaining('No saved cloud credentials'), findsOneWidget);
  });

  testWidgets('distinguishes a failed credential load from none configured', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(
      _harness(credentials: const [], credentialsFailed: true),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Could not load saved cloud credentials'),
      findsOneWidget,
    );
    expect(find.textContaining('No saved cloud credentials'), findsNothing);
  });

  testWidgets('a bucket provider shows the bucket field', (tester) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(
      _harness(baseline: _blank.copyWith(credentialId: 3)),
    );
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Remote location'));
    expect(find.widgetWithText(TextField, 'Bucket'), findsOneWidget);
  });

  testWidgets('a bucket-less provider hides the bucket field', (tester) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(
      _harness(baseline: _blank.copyWith(credentialId: 4)),
    );
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Remote location'));
    expect(find.widgetWithText(TextField, 'Bucket'), findsNothing);
    expect(find.widgetWithText(TextField, 'Folder'), findsOneWidget);
  });

  testWidgets('storage class appears only for S3', (tester) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(
      _harness(baseline: _blank.copyWith(credentialId: 3)),
    );
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Remote location'));
    expect(
      find.widgetWithText(TextField, 'Storage class (optional)'),
      findsOneWidget,
    );
  });

  testWidgets('encryption fields appear only when encryption is on', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Encrypt files'));
    expect(find.text('Encrypt file names'), findsNothing);
    await tester.tap(find.widgetWithText(SwitchListTile, 'Encrypt files'));
    await tester.pumpAndSettle();
    expect(find.text('Encrypt file names'), findsOneWidget);
    await _scrollTo(
      tester,
      find.widgetWithText(TextField, 'Encryption password'),
    );
    expect(
      find.widgetWithText(TextField, 'Encryption password'),
      findsOneWidget,
    );
  });

  testWidgets('a new encrypted task requires a password', (tester) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(
      _harness(
        baseline: _blank.copyWith(
          description: 'Nightly',
          path: '/mnt/tank/media',
          credentialId: 4,
          encryption: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await _scrollTo(
      tester,
      find.textContaining('Enter an encryption password'),
    );
    expect(find.textContaining('Enter an encryption password'), findsOneWidget);
  });

  testWidgets('review spells out that SYNC deletes at the destination', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(
      _harness(
        baseline: _blank.copyWith(
          description: 'Nightly',
          path: '/mnt/tank/media',
          credentialId: 4,
          folder: 'media',
          transferMode: CloudSyncTransferMode.sync,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.text('Review cloud sync'), findsOneWidget);
    expect(find.textContaining('deleted from the cloud'), findsOneWidget);
  });

  testWidgets('review spells out that MOVE deletes the source', (tester) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(
      _harness(
        baseline: _blank.copyWith(
          description: 'Nightly',
          path: '/mnt/tank/media',
          credentialId: 4,
          folder: 'media',
          transferMode: CloudSyncTransferMode.move,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.textContaining('deletes them from'), findsOneWidget);
  });

  testWidgets('review reassures that COPY deletes nothing', (tester) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(
      _harness(
        baseline: _blank.copyWith(
          description: 'Nightly',
          path: '/mnt/tank/media',
          credentialId: 4,
          folder: 'media',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.textContaining('never deletes anything'), findsOneWidget);
  });

  testWidgets('notes that preserved advanced settings round-trip', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(
      _harness(
        baseline: _blank.copyWith(
          id: 20,
          preservedFields: const {'pre_script': 'echo hi'},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.textContaining('pre_script'));
    expect(find.textContaining('pre_script'), findsOneWidget);
    expect(find.textContaining('sent back unchanged'), findsOneWidget);
  });

  testWidgets('returns a configuration carrying the documented payload', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    final completer = Completer<CloudSyncConfiguration?>();
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: _delegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    showModalBottomSheet<CloudSyncConfiguration>(
      context: capturedContext,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) =>
          const CloudSyncTaskSheet(baseline: _blank, credentials: _credentials),
    ).then(completer.complete);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Nightly offsite');
    await tester.pump();
    await _scrollTo(tester, find.text('Credential'));
    await tester.tap(find.text('Credential'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Backblaze').last);
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.widgetWithText(TextField, 'Local path'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Local path'),
      '/mnt/tank/media',
    );
    await tester.pump();
    await _scrollTo(tester, find.widgetWithText(TextField, 'Bucket'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Bucket'),
      'my-bucket',
    );
    await tester.pump();
    await _scrollTo(tester, find.widgetWithText(TextField, 'Folder'));
    await tester.enterText(find.widgetWithText(TextField, 'Folder'), 'media');
    await tester.pump();

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.text('Review cloud sync'), findsOneWidget);
    await tester.tap(find.text('Save task'));
    await tester.pumpAndSettle();

    final result = await completer.future;
    expect(result, isNotNull);
    const s3 = CloudCredential(id: 3, name: 'Backblaze', provider: 'S3');
    final json = result!.toApiJson(s3);
    expect(json['description'], 'Nightly offsite');
    expect(json['path'], '/mnt/tank/media');
    expect(json['credentials'], 3);
    expect(json['transfer_mode'], 'COPY');
    final attributes = json['attributes']! as Map<String, Object?>;
    expect(attributes['bucket'], 'my-bucket');
    expect(attributes['folder'], 'media');
  });
}
