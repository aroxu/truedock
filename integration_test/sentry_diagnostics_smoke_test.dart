import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:true_dock/core/diagnostics/sentry_diagnostics.dart';

const _dsn = String.fromEnvironment('TRUEDOCK_SENTRY_DSN');
const _mode = String.fromEnvironment(
  'TRUEDOCK_SENTRY_SMOKE_MODE',
  defaultValue: 'reports',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Sentry diagnostics smoke test ($_mode)', (tester) async {
    expect(
      _dsn,
      isNotEmpty,
      reason: 'Pass TRUEDOCK_SENTRY_DSN to run the live Sentry smoke test.',
    );

    final backend = SentryDiagnosticsBackend(
      dsn: _dsn,
      environment: 'smoke-test',
      debug: true,
      tracesSampleRate: 1,
    );
    await backend.setCollectionEnabled(true);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Sentry smoke test'))),
      ),
    );
    await tester.pumpAndSettle();

    if (_mode == 'native-crash') {
      // The process must terminate here. The next smoke-test launch initializes
      // Sentry again and uploads the native crash envelope.
      await Future<void>.delayed(const Duration(seconds: 1));
      await SentryFlutter.nativeCrash();
      fail('SentryFlutter.nativeCrash() returned without terminating the app.');
    }

    if (_mode == 'flush') {
      await Future<void>.delayed(const Duration(seconds: 8));
      await Sentry.close();
      return;
    }

    final eventId = await Sentry.captureException(
      StateError('TrueDock Sentry handled-error smoke test'),
      stackTrace: StackTrace.current,
    );

    final transaction = Sentry.startTransactionWithContext(
      SentryTransactionContext('truedock.sentry.smoke', 'ui.load'),
      bindToScope: true,
    );
    expect(transaction.runtimeType.toString(), isNot('NoOpSentrySpan'));
    final child = transaction.startChild(
      'ui.render',
      description: 'Sentry smoke-test child span',
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await child.finish(status: const SpanStatus.ok());
    await transaction.finish(status: const SpanStatus.ok());
    // Sentry's native transport sends asynchronously. Keep the process alive
    // long enough for URLSession to finish instead of cancelling the request
    // when the integration-test runner tears the app down.
    await Future<void>.delayed(const Duration(seconds: 8));
    await Sentry.close();

    expect(eventId, isNot(SentryId.empty()));
    // Printed ID is safe and lets the live verification locate the exact
    // sanitized event without placing server or user data in the test.
    // ignore: avoid_print
    print('TRUEDOCK_SENTRY_HANDLED_EVENT_ID=$eventId');
  });
}
