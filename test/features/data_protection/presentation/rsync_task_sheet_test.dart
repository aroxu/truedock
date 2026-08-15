import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/data_protection/domain/rsync_configuration.dart';
import 'package:true_dock/features/data_protection/domain/task_schedule.dart';
import 'package:true_dock/features/data_protection/presentation/rsync_task_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

/// Delegates the app installs, so the sheet resolves the same generated
/// strings it uses in production.
const _delegates = <LocalizationsDelegate<Object>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

const _blank = RsyncConfiguration(
  path: '',
  user: '',
  direction: RsyncDirection.push,
  mode: RsyncMode.ssh,
);

const _credentials = [SshCredential(id: 4, name: 'Offsite backup')];

const _users = ['root', 'backup'];

Widget _harness({
  RsyncConfiguration baseline = _blank,
  List<String> users = _users,
  List<SshCredential> sshCredentials = _credentials,
  bool sshCredentialsFailed = false,
}) {
  return MaterialApp(
    localizationsDelegates: _delegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: RsyncTaskSheet(
        baseline: baseline,
        users: users,
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
  testWidgets('blocks review when required fields are empty', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a local path.'), findsOneWidget);
    expect(find.text('Review rsync task'), findsNothing);
  });

  testWidgets('rejects a relative local path', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'tank/media');
    await tester.pump();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.text('Use an absolute path starting with /.'), findsOneWidget);
  });

  testWidgets('SSH mode shows the remote path and SSH picker', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Remote'));
    expect(find.widgetWithText(TextField, 'Remote path'), findsOneWidget);
    expect(find.text('SSH connection'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Remote module'), findsNothing);
  });

  testWidgets('module mode swaps to the module field and drops SSH', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(baseline: _blank.copyWith(mode: RsyncMode.module)),
    );
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Remote'));
    expect(find.widgetWithText(TextField, 'Remote module'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Remote path'), findsNothing);
    expect(find.text('SSH connection'), findsNothing);
  });

  testWidgets('the port helper shows 22 for SSH mode', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.textContaining('default (22)'));
    expect(find.textContaining('default (22)'), findsOneWidget);
  });

  testWidgets('the port helper shows 873 for module mode', (tester) async {
    await tester.pumpWidget(
      _harness(baseline: _blank.copyWith(mode: RsyncMode.module)),
    );
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.textContaining('default (873)'));
    expect(find.textContaining('default (873)'), findsOneWidget);
  });

  testWidgets('shows guidance when no SSH connections exist', (tester) async {
    await tester.pumpWidget(_harness(sshCredentials: const []));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.textContaining('No saved SSH connections'));
    expect(find.textContaining('No saved SSH connections'), findsOneWidget);
  });

  testWidgets('seeds fields from an existing task when editing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        baseline: const RsyncConfiguration(
          id: 12,
          path: '/mnt/tank/media',
          user: 'backup',
          direction: RsyncDirection.pull,
          mode: RsyncMode.module,
          remoteHost: 'offsite.example',
          remoteModule: 'media',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Edit rsync task'), findsOneWidget);
    expect(find.text('/mnt/tank/media'), findsOneWidget);
    await _scrollTo(tester, find.text('offsite.example'));
    expect(find.text('offsite.example'), findsOneWidget);
  });

  testWidgets('returns a complete SSH configuration on Save task', (
    tester,
  ) async {
    final completer = Completer<RsyncConfiguration?>();
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
    showModalBottomSheet<RsyncConfiguration>(
      context: capturedContext,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const RsyncTaskSheet(
        baseline: _blank,
        users: _users,
        sshCredentials: _credentials,
      ),
    ).then(completer.complete);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '/mnt/tank/media');
    await tester.pump();
    await _scrollTo(tester, find.text('User'));
    await tester.tap(find.text('User'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('backup').last);
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.widgetWithText(TextField, 'Remote host'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Remote host'),
      'offsite.example',
    );
    await tester.pump();
    await _scrollTo(tester, find.widgetWithText(TextField, 'Remote path'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Remote path'),
      '/srv/media',
    );
    await tester.pump();
    await _scrollTo(tester, find.text('SSH connection'));
    await tester.tap(find.text('SSH connection'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Offsite backup').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.text('Review rsync task'), findsOneWidget);
    await tester.tap(find.text('Save task'));
    await tester.pumpAndSettle();

    final result = await completer.future;
    expect(result, isNotNull);
    final json = result!.toApiJson();
    expect(json['path'], '/mnt/tank/media');
    expect(json['user'], 'backup');
    expect(json['mode'], 'SSH');
    expect(json['remotehost'], 'offsite.example');
    expect(json['remotepath'], '/srv/media');
    expect(json['ssh_credentials'], 4);
    expect(json['remoteport'], 22);
    expect(json.containsKey('remotemodule'), isFalse);
  });
}
