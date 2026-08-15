import 'package:sentry_flutter/sentry_flutter.dart';

import 'diagnostics_backend.dart';

const _sentryDsn = String.fromEnvironment('TRUEDOCK_SENTRY_DSN');
const _sentryEnvironment = String.fromEnvironment(
  'TRUEDOCK_SENTRY_ENVIRONMENT',
  defaultValue: 'production',
);
const _sentryRelease = String.fromEnvironment('TRUEDOCK_SENTRY_RELEASE');
const _sentryDist = String.fromEnvironment('TRUEDOCK_SENTRY_DIST');

/// Ratio of profiled transactions out of the sampled traces.
///
/// Profiling is relative to [SentryDiagnosticsBackend.tracesSampleRate], so the
/// effective profiled share of all app sessions is the product of both rates.
const _sentryProfilesSampleRateRaw = String.fromEnvironment(
  'TRUEDOCK_SENTRY_PROFILES_SAMPLE_RATE',
);
final double _sentryProfilesSampleRate =
    double.tryParse(_sentryProfilesSampleRateRaw) ?? 0.2;

final SentryDiagnosticsBackend sentryDiagnosticsBackend =
    SentryDiagnosticsBackend(dsn: _sentryDsn, environment: _sentryEnvironment);

/// Privacy-first Sentry bridge used by official TrueDock builds.
///
/// Open-source and local builds omit [dsn], so the app remains fully functional
/// without creating a Sentry project or sending any network traffic.
class SentryDiagnosticsBackend implements DiagnosticsBackend {
  SentryDiagnosticsBackend({
    required this.dsn,
    required this.environment,
    this.debug = false,
    this.tracesSampleRate = 0.1,
    double? profilesSampleRate,
  }) : profilesSampleRate = (profilesSampleRate ?? _sentryProfilesSampleRate)
           .clamp(0.0, 1.0);

  final String dsn;
  final String environment;
  final bool debug;
  final double tracesSampleRate;

  /// Profiled share of sampled traces. Native profiling currently runs on iOS
  /// and macOS only; other platforms silently ignore the value.
  final double profilesSampleRate;
  bool _started = false;

  @override
  bool get isConfigured => dsn.trim().isNotEmpty;

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    if (!enabled || !isConfigured) {
      if (_started) await Sentry.close();
      _started = false;
      return;
    }
    if (_started) return;

    await SentryFlutter.init((options) {
      options
        ..dsn = dsn
        ..environment = environment
        ..debug = debug
        ..diagnosticLevel = debug ? SentryLevel.debug : SentryLevel.warning
        ..sendDefaultPii = false
        // Performance data is useful, but a low sample rate limits collection.
        ..tracesSampleRate = tracesSampleRate
        // Profiling samples call stacks for traces that are already sampled,
        // so it never widens the amount of collected sessions.
        // ignore: experimental_member_use
        ..profilesSampleRate = profilesSampleRate
        ..enableAutoPerformanceTracing = true
        ..enableFramesTracking = true
        ..enableUserInteractionTracing = false
        ..enableUserInteractionBreadcrumbs = false
        ..enableAutoSessionTracking = false
        ..enableLogs = false
        ..attachScreenshot = false
        // ignore: experimental_member_use
        ..attachViewHierarchy = false
        ..reportViewHierarchyIdentifiers = false
        // Native crash reports need a bounded envelope cache to survive until
        // the next launch. Collection is still stopped immediately on opt-out.
        ..maxCacheItems = 30
        ..maxBreadcrumbs = 0
        ..beforeSend = _sanitizeErrorEvent
        ..beforeSendTransaction = _sanitizeTransaction;
      if (_sentryRelease.isNotEmpty) options.release = _sentryRelease;
      if (_sentryDist.isNotEmpty) options.dist = _sentryDist;
      options.beforeBreadcrumb = (_, _) => null;
      options.replay
        ..sessionSampleRate = 0
        ..onErrorSampleRate = 0;
    });
    _started = true;
  }

  static SentryEvent? _sanitizeErrorEvent(SentryEvent event, Hint hint) {
    event
      ..user = null
      ..request = null
      ..serverName = null
      ..breadcrumbs = null
      ..tags = null
      // ignore: deprecated_member_use
      ..extra = null
      ..culprit = null;
    event.contexts
      ..response = null
      ..feedback = null
      ..flags = null;
    final device = event.contexts.device;
    if (device != null) {
      device
        ..name = null
        ..deviceUniqueIdentifier = null;
    }
    final message = event.message;
    if (message != null) {
      message
        ..formatted = 'Error details redacted by TrueDock.'
        ..template = null
        ..params = null;
    }
    for (final exception in event.exceptions ?? const <SentryException>[]) {
      exception
        ..value = 'Exception details redacted by TrueDock.'
        ..throwable = null;
    }
    return event;
  }

  static SentryTransaction? _sanitizeTransaction(
    SentryTransaction transaction,
    Hint hint,
  ) {
    transaction
      ..user = null
      ..request = null
      ..serverName = null
      ..breadcrumbs = null
      ..tags = null
      // ignore: deprecated_member_use
      ..extra = null;
    transaction.contexts
      ..response = null
      ..feedback = null
      ..flags = null;
    final device = transaction.contexts.device;
    if (device != null) {
      device
        ..name = null
        ..deviceUniqueIdentifier = null;
    }
    for (final span in transaction.spans) {
      span
        ..data.clear()
        ..tags.clear();
    }
    return transaction;
  }
}
