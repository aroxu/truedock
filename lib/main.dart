import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app/true_dock_app.dart';
import 'core/diagnostics/diagnostics_controller.dart';
import 'core/diagnostics/sentry_diagnostics.dart';

Future<void> main() async {
  // Sentry's binding preserves native frame timing when diagnostics are
  // configured, and behaves as the regular Flutter binding in source builds.
  SentryWidgetsFlutterBinding.ensureInitialized();
  final diagnosticsEnabled = await DiagnosticsController.readPersistedSetting();
  await sentryDiagnosticsBackend.setCollectionEnabled(diagnosticsEnabled);
  runApp(const ProviderScope(child: TrueDockApp()));
}
