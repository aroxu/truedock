import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/system/domain/system_resources.dart';
import 'package:true_dock/features/system/presentation/user_password_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

NasUser _user() => const NasUser(
  id: 5,
  username: 'alice',
  fullName: 'Alice Example',
  uid: 1005,
  local: true,
  builtin: false,
  smb: true,
  passwordDisabled: false,
  roles: [],
  email: 'alice@example.com',
  shell: '/usr/bin/bash',
);

Future<void> pumpSheet(WidgetTester tester, {NasUser? user}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: UserPasswordSheet(user: user ?? _user())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('rejects an empty password before review', (tester) async {
    await pumpSheet(tester);
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Enter a new password.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Enter a new password.'), findsOneWidget);
  });

  testWidgets('rejects a short password', (tester) async {
    await pumpSheet(tester);
    await tester.enterText(find.byType(TextField).first, 'short');
    await tester.enterText(find.byType(TextField).at(1), 'short');
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Use at least 8 characters.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
  });

  testWidgets('requires the two passwords to match', (tester) async {
    await pumpSheet(tester);
    await tester.enterText(find.byType(TextField).first, 'good-pass-1');
    await tester.enterText(find.byType(TextField).at(1), 'good-pass-2');
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('The two passwords do not match.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('The two passwords do not match.'), findsOneWidget);
  });

  testWidgets('returns the chosen password after review', (tester) async {
    String? result;
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
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  showDragHandle: true,
                  builder: (_) => UserPasswordSheet(user: _user()),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'good-pass-1');
    await tester.enterText(find.byType(TextField).at(1), 'good-pass-1');
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set password'));
    await tester.pumpAndSettle();

    expect(result, 'good-pass-1');
  });
}
