import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/data_protection/domain/replication_configuration.dart';
import 'package:true_dock/features/data_protection/domain/task_schedule.dart';
import 'package:true_dock/features/data_protection/presentation/replication_task_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

const _blank = ReplicationConfiguration(
  name: '',
  direction: ReplicationDirection.push,
  transport: ReplicationTransport.ssh,
  sourceDatasets: [],
  targetDataset: '',
);

const _credentials = [
  SshCredential(id: 3, name: 'Offsite backup'),
  SshCredential(id: 4, name: 'Lab server'),
];

Widget _harness({
  ReplicationConfiguration baseline = _blank,
  List<String> datasets = const ['tank/media', 'tank/docs'],
  List<SshCredential> sshCredentials = _credentials,
  bool sshCredentialsFailed = false,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ReplicationTaskSheet(
        baseline: baseline,
        datasets: datasets,
        sshCredentials: sshCredentials,
        sshCredentialsFailed: sshCredentialsFailed,
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

void main() {
  testWidgets('blocks review and reports every missing required field', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a task name.'), findsOneWidget);
    expect(find.text('Review replication'), findsNothing);
  });

  testWidgets('shows a guidance notice when no SSH connections exist', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(sshCredentials: const []));
    await tester.pumpAndSettle();
    expect(find.textContaining('No saved SSH connections'), findsOneWidget);
  });

  testWidgets('distinguishes a failed credential load from none configured', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(sshCredentials: const [], sshCredentialsFailed: true),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Could not load saved SSH connections'),
      findsOneWidget,
    );
    expect(find.textContaining('No saved SSH connections'), findsNothing);
  });

  testWidgets('hides the SSH picker for a LOCAL transport', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    expect(find.text('SSH connection'), findsOneWidget);
    await tester.tap(find.text('SSH').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Local (same system)').last);
    await tester.pumpAndSettle();
    expect(find.text('SSH connection'), findsNothing);
  });

  testWidgets('seeds fields from an existing task when editing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        baseline: const ReplicationConfiguration(
          id: 11,
          name: 'Nightly offsite',
          direction: ReplicationDirection.push,
          transport: ReplicationTransport.ssh,
          sshCredentialId: 3,
          sourceDatasets: ['tank/media'],
          targetDataset: 'backup/media',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Edit replication'), findsOneWidget);
    expect(find.text('Nightly offsite'), findsOneWidget);
    expect(find.text('Offsite backup'), findsWidgets);
  });

  testWidgets('returns a complete configuration on Save task', (tester) async {
    final completer = Completer<ReplicationConfiguration?>();
    late BuildContext capturedContext;
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
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    showModalBottomSheet<ReplicationConfiguration>(
      context: capturedContext,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const ReplicationTaskSheet(
        baseline: _blank,
        datasets: ['tank/media', 'tank/docs'],
        sshCredentials: _credentials,
      ),
    ).then(completer.complete);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Nightly offsite');
    await tester.pump();
    // Pick the SSH connection.
    await tester.tap(find.text('SSH connection'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Offsite backup').last);
    await tester.pumpAndSettle();
    // Select a source dataset.
    await _scrollTo(tester, find.text('tank/media'));
    await tester.tap(find.text('tank/media'));
    await tester.pumpAndSettle();
    // Enter the target dataset.
    await _scrollTo(tester, find.widgetWithText(TextField, 'Target dataset'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Target dataset'),
      'backup/media',
    );
    await tester.pump();

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.text('Review replication'), findsOneWidget);
    await tester.tap(find.text('Save task'));
    await tester.pumpAndSettle();

    final result = await completer.future;
    expect(result, isNotNull);
    expect(result!.name, 'Nightly offsite');
    expect(result.sourceDatasets, ['tank/media']);
    expect(result.targetDataset, 'backup/media');
    expect(result.sshCredentialId, 3);
    // The payload must carry the documented replication.create shape.
    expect(result.toApiJson()['transport'], 'SSH');
    expect(result.toApiJson()['ssh_credentials'], 3);
  });

  testWidgets('custom retention reveals the lifetime fields', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Same as source'));
    await tester.tap(find.text('Same as source'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom retention').last);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Keep for'), findsOneWidget);
  });

  testWidgets('turning off the schedule hides the preset picker', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Run on a schedule'));
    expect(find.text('Hourly'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    expect(find.text('Hourly'), findsNothing);
  });
}
