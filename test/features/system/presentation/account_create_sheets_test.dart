import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/system/domain/system_resources.dart';
import 'package:true_dock/features/system/presentation/account_create_sheets.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  testWidgets('creates a user with a generated primary group', (tester) async {
    Map<String, Object?>? payload;
    await _openUser(tester, onResult: (value) => payload = value);

    await tester.enterText(find.widgetWithText(TextField, 'Username'), 'ada');
    await tester.enterText(
      find.widgetWithText(TextField, 'New password'),
      'pw',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create user'));
    await tester.pumpAndSettle();

    expect(payload?['username'], 'ada');
    expect(payload?['group_create'], isTrue);
    expect(payload?['password'], 'pw');
  });

  testWidgets('hides the password field when sign-in is disabled', (
    tester,
  ) async {
    Map<String, Object?>? payload;
    await _openUser(tester, onResult: (value) => payload = value);

    await tester.enterText(find.widgetWithText(TextField, 'Username'), 'svc');
    await tester.tap(find.text('Disable password sign-in'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'New password'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Create user'));
    await tester.pumpAndSettle();

    expect(payload?['password_disabled'], isTrue);
    expect(payload?.containsKey('password'), isFalse);
  });

  testWidgets('surfaces an invalid username instead of sending it', (
    tester,
  ) async {
    Map<String, Object?>? payload;
    await _openUser(tester, onResult: (value) => payload = value);

    await tester.enterText(
      find.widgetWithText(TextField, 'Username'),
      'Bad Name',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create user'));
    await tester.pumpAndSettle();

    expect(find.textContaining('must start with a letter'), findsOneWidget);
    expect(payload, isNull);
  });

  testWidgets('asks for a primary group when not creating one', (tester) async {
    Map<String, Object?>? payload;
    await _openUser(tester, onResult: (value) => payload = value);

    await tester.enterText(find.widgetWithText(TextField, 'Username'), 'ada');
    await tester.tap(find.text('Disable password sign-in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a matching primary group'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(DropdownButtonFormField<int>, ''), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Create user'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Choose a primary group'), findsOneWidget);
    expect(payload, isNull);
  });

  testWidgets('creates a group with selected members', (tester) async {
    Map<String, Object?>? payload;
    await _openGroup(tester, onResult: (value) => payload = value);

    await tester.enterText(
      find.widgetWithText(TextField, 'Group name'),
      'engineering',
    );
    await tester.tap(find.widgetWithText(FilterChip, 'ada'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Create group'));
    await tester.pumpAndSettle();

    expect(payload?['name'], 'engineering');
    expect(payload?['users'], [3]);
  });

  testWidgets('rejects a group name with a space', (tester) async {
    Map<String, Object?>? payload;
    await _openGroup(tester, onResult: (value) => payload = value);

    await tester.enterText(
      find.widgetWithText(TextField, 'Group name'),
      'has space',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create group'));
    await tester.pumpAndSettle();

    expect(find.textContaining('cannot contain spaces'), findsOneWidget);
    expect(payload, isNull);
  });
}

Future<void> _openUser(
  WidgetTester tester, {
  required ValueChanged<Map<String, Object?>?> onResult,
}) => _open(tester, (context) => UserCreateSheet(groups: _groups), onResult);

Future<void> _openGroup(
  WidgetTester tester, {
  required ValueChanged<Map<String, Object?>?> onResult,
}) => _open(tester, (context) => GroupCreateSheet(users: _users), onResult);

Future<void> _open(
  WidgetTester tester,
  WidgetBuilder builder,
  ValueChanged<Map<String, Object?>?> onResult,
) async {
  tester.view.physicalSize = const Size(430, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
              final result = await showModalBottomSheet<Map<String, Object?>>(
                context: context,
                isScrollControlled: true,
                builder: builder,
              );
              onResult(result);
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

final _groups = [
  NasGroup.fromJson(const {
    'id': 42,
    'name': 'engineering',
    'gid': 3100,
    'local': true,
    'builtin': false,
    'smb': true,
    'roles': <String>[],
    'users': <int>[],
  }),
];

final _users = [
  NasUser.fromJson(const {
    'id': 3,
    'username': 'ada',
    'full_name': 'Ada Lovelace',
    'uid': 3000,
    'local': true,
    'builtin': false,
    'smb': true,
    'roles': <String>[],
  }),
];
