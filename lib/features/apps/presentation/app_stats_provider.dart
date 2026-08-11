import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/truenas_client_provider.dart';
import '../data/app_stats_repository.dart';
import '../domain/app_stats.dart';

final appStatsRepositoryProvider = Provider<AppStatsRepository>(
  (ref) => AppStatsRepository(ref.watch(trueNasClientProvider)),
);

final appStatsProvider = StreamProvider.autoDispose.family<AppStats, String>(
  (ref, appName) => ref.watch(appStatsRepositoryProvider).watch(appName),
);
