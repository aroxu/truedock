import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/app/true_dock_app.dart';
import 'package:true_dock/core/security/security_providers.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/domain/auth_credential.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('registered servers open a picker without login fields', (
    tester,
  ) async {
    final server = SavedServer(
      profile: ServerProfile(
        name: 'TrueNAS Demo',
        baseUri: Uri.parse('https://10.24.30.81'),
      ),
      username: 'truenas_admin',
      authMethod: AuthMethod.password,
      hasSavedCredential: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savedServersProvider.overrideWith((ref) async => [server]),
        ],
        child: const TrueDockApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('서버 선택'), findsOneWidget);
    expect(find.text('TrueNAS Demo'), findsOneWidget);
    expect(find.text('서버 등록하기'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);

    await tester.tap(find.byKey(const ValueKey('register-server-button')));
    await tester.pumpAndSettle();

    expect(find.text('TrueNAS 서버 추가'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });
}
