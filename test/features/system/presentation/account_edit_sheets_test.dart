import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/system/domain/system_resources.dart';
import 'package:true_dock/features/system/presentation/account_edit_sheets.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  testWidgets('reviews and returns only the changed user fields', (
    tester,
  ) async {
    Map<String, Object?>? result;
    await _pumpUserSheet(tester, onResult: (value) => result = value);

    await tester.tap(find.text('Lock account'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review user changes'), findsOneWidget);
    expect(
      find.text('Account locked — the user can no longer sign in'),
      findsOneWidget,
    );
    expect(find.textContaining('immediately blocks sign-in'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Apply changes'));
    await tester.pumpAndSettle();

    expect(result, {'locked': true});
  });

  testWidgets('blocks review when the user is unchanged', (tester) async {
    await _pumpUserSheet(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.text('Nothing has changed for this user.'), findsOneWidget);
    expect(find.text('Review user changes'), findsNothing);
  });

  testWidgets('surfaces a malformed email instead of sending it', (
    tester,
  ) async {
    await _pumpUserSheet(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'not-an-address',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter a valid email address or leave it empty.'),
      findsOneWidget,
    );
  });

  testWidgets('toggles auxiliary group membership', (tester) async {
    Map<String, Object?>? result;
    await _pumpUserSheet(tester, onResult: (value) => result = value);

    await tester.tap(find.widgetWithText(FilterChip, 'operators'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Apply changes'));
    await tester.pumpAndSettle();

    expect(result, {
      'groups': [42, 43],
    });
  });

  testWidgets('returns a changed group membership list', (tester) async {
    Map<String, Object?>? result;
    await _pumpGroupSheet(tester, onResult: (value) => result = value);

    await tester.tap(find.widgetWithText(FilterChip, 'grace'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review group changes'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Apply changes'));
    await tester.pumpAndSettle();

    expect(result, {
      'users': [3, 4],
    });
  });

  testWidgets('warns that a renamed group breaks existing references', (
    tester,
  ) async {
    await _pumpGroupSheet(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Group name'),
      'platform',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.text('Group renamed to platform'), findsOneWidget);
    expect(find.textContaining('keep pointing at it'), findsOneWidget);
  });

  testWidgets('rejects a group name containing a space', (tester) async {
    await _pumpGroupSheet(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Group name'),
      'has space',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(
      find.text('A group name cannot contain spaces, colons, or commas.'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpUserSheet(
  WidgetTester tester, {
  ValueChanged<Map<String, Object?>?>? onResult,
}) => _pump(
  tester,
  (context) => UserEditSheet(user: _user, groups: _groups),
  onResult,
);

Future<void> _pumpGroupSheet(
  WidgetTester tester, {
  ValueChanged<Map<String, Object?>?>? onResult,
}) => _pump(
  tester,
  (context) => GroupEditSheet(group: _groups.first, users: _users),
  onResult,
);

Future<void> _pump(
  WidgetTester tester,
  WidgetBuilder builder,
  ValueChanged<Map<String, Object?>?>? onResult,
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
              onResult?.call(result);
            },
            child: const Text('Open sheet'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open sheet'));
  await tester.pumpAndSettle();
}

final _user = NasUser.fromJson(const {
  'id': 3,
  'username': 'ada',
  'full_name': 'Ada Lovelace',
  'uid': 3000,
  'local': true,
  'builtin': false,
  'smb': true,
  'password_disabled': false,
  'locked': false,
  'email': 'ada@example.invalid',
  'shell': '/usr/bin/zsh',
  'roles': <String>[],
  'group': {'id': 41},
  'groups': [42],
});

final _groups = [
  NasGroup.fromJson(const {
    'id': 42,
    'name': 'engineering',
    'gid': 3100,
    'local': true,
    'builtin': false,
    'smb': true,
    'roles': <String>[],
    'users': [3],
  }),
  NasGroup.fromJson(const {
    'id': 43,
    'name': 'operators',
    'gid': 3101,
    'local': true,
    'builtin': false,
    'smb': false,
    'roles': <String>[],
    'users': <int>[],
  }),
];

final _users = [
  _user,
  NasUser.fromJson(const {
    'id': 4,
    'username': 'grace',
    'full_name': 'Grace Hopper',
    'uid': 3001,
    'local': true,
    'builtin': false,
    'smb': true,
    'roles': <String>[],
    'group': {'id': 41},
    'groups': <int>[],
  }),
];
