import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/truenas_client_provider.dart';
import '../../connection/presentation/connection_controller.dart';
import '../data/reporting_repository.dart';
import '../domain/reporting_series.dart';

final reportingRepositoryProvider = Provider<ReportingRepository>((ref) {
  return ReportingRepository(ref.watch(trueNasClientProvider));
});

/// Last complete overview sample retained across refreshes and reconnects.
/// This is intentionally scoped to the active ProviderScope/session and is
/// cleared when there is no retained connection.
final _overviewReportingCacheProvider = Provider<_OverviewReportingCache>((
  ref,
) {
  return _OverviewReportingCache();
});

class _OverviewReportingCache {
  String? serverId;
  ReportingSnapshot? value;

  void clear() {
    serverId = null;
    value = null;
  }
}

/// Window of history the Overview charts display.
const overviewReportingWindow = Duration(hours: 1);

/// Shortest window a refresh will ask for.
///
/// A one-second tick only needs the last second, but Netdata rounds sample
/// times to its collection interval, so an over-tight window can return
/// nothing at all. Asking for a couple of minutes keeps every tick overlapping
/// the retained history while staying ~30x smaller than the displayed hour.
const _overviewTailWindow = Duration(minutes: 2);

final overviewReportingProvider = FutureProvider<ReportingSnapshot>((
  ref,
) async {
  final hasSession = ref.watch(
    connectionControllerProvider.select((state) => state.hasRetainedSession),
  );
  final cache = ref.read(_overviewReportingCacheProvider);
  if (!hasSession) {
    cache.clear();
    return const ReportingSnapshot();
  }
  final connection = ref.read(connectionControllerProvider);
  final serverId = connection.profile?.id;
  if (cache.serverId != serverId) cache.clear();

  // Ask only for the time that has elapsed since the samples already on
  // screen. The first load after a connect, a server switch, or a long
  // suspension has nothing to extend and falls back to the full window.
  final retained = cache.value;
  final latest = retained?.latestSampleTime;
  final elapsed = latest == null
      ? null
      : DateTime.now().toUtc().difference(latest);
  final window = elapsed == null || elapsed >= overviewReportingWindow
      ? overviewReportingWindow
      : (elapsed < _overviewTailWindow ? _overviewTailWindow : elapsed);

  final loaded = await ref
      .watch(reportingRepositoryProvider)
      .loadOverview(
        supportedMethods: connection.capabilities?.methods,
        totalMemoryBytes: connection.systemInfo?.physicalMemoryBytes,
        window: window,
      );
  final merged = window == overviewReportingWindow
      ? loaded.retainMissingDevicesFrom(retained)
      : loaded
            .appendTo(retained, keep: overviewReportingWindow)
            .retainMissingDevicesFrom(retained);
  if (!merged.hasError && !merged.isEmpty) {
    cache.serverId = serverId;
    cache.value = merged;
  }
  return merged;
});

enum ReportingHistoryRange {
  hour(Duration(hours: 1)),
  day(Duration(hours: 24)),
  week(Duration(days: 7));

  const ReportingHistoryRange(this.duration);
  final Duration duration;
}

final _reportingHistoryCacheProvider = Provider<_ReportingHistoryCache>((_) {
  return _ReportingHistoryCache();
});

class _ReportingHistoryCache {
  String? serverId;
  final values = <ReportingHistoryRange, ReportingSnapshot>{};

  void resetFor(String? nextServerId) {
    if (serverId == nextServerId) return;
    serverId = nextServerId;
    values.clear();
  }

  void clear() {
    serverId = null;
    values.clear();
  }
}

final reportingHistoryProvider = FutureProvider.autoDispose
    .family<ReportingSnapshot, ReportingHistoryRange>((ref, range) async {
      final connection = ref.watch(connectionControllerProvider);
      final cache = ref.read(_reportingHistoryCacheProvider);
      if (!connection.isConnected) {
        cache.clear();
        return const ReportingSnapshot();
      }
      cache.resetFor(connection.profile?.id);
      final retained = cache.values[range];
      final latest = retained?.latestSampleTime;
      final elapsed = latest == null
          ? null
          : DateTime.now().toUtc().difference(latest);
      final window = elapsed == null || elapsed >= range.duration
          ? range.duration
          : (elapsed < _overviewTailWindow ? _overviewTailWindow : elapsed);
      final loaded = await ref
          .watch(reportingRepositoryProvider)
          .loadOverview(
            supportedMethods: connection.capabilities?.methods,
            totalMemoryBytes: connection.systemInfo?.physicalMemoryBytes,
            window: window,
          );
      final merged = window == range.duration
          ? loaded.retainMissingDevicesFrom(retained)
          : loaded
                .appendTo(retained, keep: range.duration)
                .retainMissingDevicesFrom(retained);
      if (!merged.hasError && !merged.isEmpty) cache.values[range] = merged;
      return merged;
    });

void refreshOverviewReporting(WidgetRef ref) {
  ref.invalidate(overviewReportingProvider);
}
