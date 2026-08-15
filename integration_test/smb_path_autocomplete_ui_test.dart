import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/domain/smb_share_configuration.dart';
import 'package:true_dock/features/storage/presentation/smb_share_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SMB form keeps labels visible and autocompletes paths', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ko'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SmbShareSheet(
            datasets: [
              Dataset(
                id: 'truedock_data/media',
                name: 'truedock_data/media',
                type: 'FILESYSTEM',
              ),
              Dataset(
                id: 'truedock_data/movies',
                name: 'truedock_data/movies',
                type: 'FILESYSTEM',
              ),
            ],
            presets: [
              SmbSharePreset(
                purpose: SmbSharePurpose.defaultShare,
                label: 'Default',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('용도'), findsOneWidget);
    expect(tester.getTopLeft(find.text('용도')).dy, greaterThan(100));
    final path = find.byKey(const ValueKey('smb-share-path-field'));
    await tester.tap(path);
    await tester.enterText(path, 'media');
    await tester.pump();
    expect(
      find.byKey(const ValueKey('smb-share-path-suggestions')),
      findsOneWidget,
    );
    expect(find.text('/mnt/truedock_data/media'), findsWidgets);
  });
}
