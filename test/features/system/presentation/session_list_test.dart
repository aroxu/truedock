import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/domain/data_message.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/system/domain/system_resources.dart';
import 'package:true_dock/features/system/presentation/session_list.dart';
import 'package:true_dock/l10n/app_localizations.dart';

final _now = DateTime.utc(2026, 8, 12, 12);

NasSession _session({
  String id = 's1',
  bool current = false,
  bool internal = false,
  String origin = '10.0.0.5:51234',
  String credentials = 'LOGIN_PASSWORD',
  String? username = 'truenas_admin',
  DateTime? createdAt,
  bool secureTransport = true,
}) => NasSession(
  id: id,
  current: current,
  internal: internal,
  origin: origin,
  credentials: credentials,
  username: username,
  createdAt: createdAt,
  secureTransport: secureTransport,
);

Future<List<String>> _pump(
  WidgetTester tester, {
  required ResourceSection<NasSession> section,
  bool canTerminate = true,
  Set<String> busyIds = const {},
}) async {
  final ended = <String>[];
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
          child: SessionList(
            section: section,
            canTerminate: canTerminate,
            busyIds: busyIds,
            onTerminate: (session) => ended.add(session.id),
            now: _now,
          ),
        ),
      ),
    ),
  );
  // Not pumpAndSettle: a busy row renders a CircularProgressIndicator, whose
  // animation never ends, so settling would time out rather than fail on
  // anything meaningful.
  await tester.pump();
  return ended;
}

void main() {
  test('parses the shape auth.sessions actually returns', () {
    // Taken from a live 25.10.5 response: the account lives inside
    // `credentials_data`, not at the top level, and the timestamp is wrapped.
    final session = NasSession.fromJson(const {
      'id': '87781c8f-599b-4af7-a214-0018daf47d54',
      'current': true,
      'internal': false,
      'origin': '10.24.20.112:52317',
      'credentials': 'LOGIN_PASSWORD',
      'credentials_data': {
        'username': 'truenas_admin',
        'login_at': {r'$date': 1786503681000},
      },
      'created_at': {r'$date': 1786503681000},
      'secure_transport': true,
    });

    expect(session.username, 'truenas_admin');
    expect(session.current, isTrue);
    expect(session.isUserSession, isTrue);
    expect(session.createdAt, isNotNull);
  });

  test('a missing secure_transport is not assumed to be secure', () {
    // Defaulting an unknown to "encrypted" would hide exactly the case the UI
    // flags in red.
    final session = NasSession.fromJson(const {'id': 'x', 'origin': 'y'});
    expect(session.secureTransport, isFalse);
  });

  testWidgets('hides internal middleware connections but reports the count', (
    tester,
  ) async {
    // The server counts its own UNIX-socket connections here. Listing them as
    // root logins would be alarming and wrong; hiding them silently would
    // make the visible count disagree with the server.
    await _pump(
      tester,
      section: ResourceSection(
        items: [
          _session(),
          _session(
            id: 'i1',
            internal: true,
            origin: 'UNIX socket (pid=1 uid=0 gid=0)',
            credentials: 'UNIX_SOCKET',
            username: 'root',
          ),
          _session(
            id: 'i2',
            internal: true,
            origin: 'UNIX socket (pid=2 uid=0 gid=0)',
            credentials: 'UNIX_SOCKET',
            username: 'root',
          ),
        ],
      ),
    );

    expect(find.text('root'), findsNothing);
    expect(
      find.textContaining('2 internal middleware connections are hidden'),
      findsOneWidget,
    );
  });

  testWidgets('marks this device and refuses to offer ending it', (
    tester,
  ) async {
    // Ending TrueDock's own session just signs the app out, which "Sign out"
    // does more clearly. Offering it beside other sessions invites a mis-tap
    // that disconnects the user instead of the intruder.
    final ended = await _pump(
      tester,
      section: ResourceSection(items: [_session(current: true)]),
    );

    expect(find.text('This device'), findsOneWidget);
    expect(find.byTooltip('End session'), findsNothing);
    expect(ended, isEmpty);
  });

  testWidgets('offers to end another session', (tester) async {
    final ended = await _pump(
      tester,
      section: ResourceSection(
        items: [
          _session(current: true),
          _session(id: 'other'),
        ],
      ),
    );

    await tester.tap(find.byTooltip('End session'));
    await tester.pumpAndSettle();

    expect(ended, ['other']);
  });

  testWidgets('flags a session that is not encrypted', (tester) async {
    await _pump(
      tester,
      section: ResourceSection(items: [_session(secureTransport: false)]),
    );

    expect(find.textContaining('Not encrypted'), findsOneWidget);
  });

  testWidgets('reports age coarsely rather than as an exact timestamp', (
    tester,
  ) async {
    // Phone and server clocks differ, so a precise time would invite being
    // read as authoritative.
    await _pump(
      tester,
      section: ResourceSection(
        items: [_session(createdAt: _now.subtract(const Duration(hours: 3)))],
      ),
    );

    expect(find.textContaining('Started 3 hours ago'), findsOneWidget);
  });

  testWidgets('withholds the action when the server does not allow it', (
    tester,
  ) async {
    await _pump(
      tester,
      section: ResourceSection(items: [_session()]),
      canTerminate: false,
    );

    expect(find.byTooltip('End session'), findsNothing);
  });

  testWidgets('shows a spinner while a terminate is in flight', (tester) async {
    await _pump(
      tester,
      section: ResourceSection(items: [_session()]),
      busyIds: const {'s1'},
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byTooltip('End session'), findsNothing);
  });

  testWidgets('explains a permission error instead of rendering empty', (
    tester,
  ) async {
    await _pump(
      tester,
      section: const ResourceSection(
        error: DataMessage(
          DataMessageCode.methodUnavailable,
          method: 'auth.sessions',
          fallback: 'auth.sessions is not available on this TrueNAS version.',
        ),
      ),
    );

    expect(find.textContaining('auth.sessions'), findsOneWidget);
  });

  testWidgets('explains an empty list', (tester) async {
    await _pump(tester, section: const ResourceSection(items: []));

    expect(find.textContaining('No user sessions'), findsOneWidget);
  });
}
