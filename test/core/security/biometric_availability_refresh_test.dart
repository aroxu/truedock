import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/app/true_dock_app.dart';
import 'package:true_dock/core/security/credential_vault.dart';
import 'package:true_dock/core/security/security_providers.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';

void main() {
  testWidgets('rechecks biometric enrollment when the app resumes', (
    tester,
  ) async {
    var checks = 0;
    final container = ProviderContainer(
      overrides: [
        savedServersProvider.overrideWith((ref) async => const <SavedServer>[]),
        biometricVaultAvailabilityProvider.overrideWith((ref) async {
          checks++;
          return BiometricVaultAvailability(
            checks == 1
                ? BiometricVaultStatus.notEnrolled
                : BiometricVaultStatus.available,
          );
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TrueDockApp(),
      ),
    );
    await tester.pumpAndSettle();
    final checksBeforeResume = checks;
    expect(checksBeforeResume, greaterThanOrEqualTo(1));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(checks, greaterThan(checksBeforeResume));
  });
}
