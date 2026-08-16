import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/api/truenas_client_provider.dart';
import '../../connection/presentation/connection_controller.dart';
import '../data/server_resources_repository.dart';
import '../domain/server_resources.dart';

final serverResourcesRepositoryProvider = Provider<ServerResourcesRepository>((
  ref,
) {
  return ServerResourcesRepository(ref.watch(trueNasClientProvider));
});

/// Resource subset needed by the destination that is actually on screen.
///
/// [ServerResourceScope.all] remains the default for provider-only tools and
/// tests that load resources without mounting the adaptive shell. The shell
/// switches this to a narrower scope as soon as it becomes visible.
final activeServerResourceScopeProvider = StateProvider<ServerResourceScope>(
  (_) => ServerResourceScope.all,
);

final serverResourcesProvider = FutureProvider<ServerResources>((ref) async {
  final hasSession = ref.watch(
    connectionControllerProvider.select((state) => state.hasRetainedSession),
  );
  if (!hasSession) return const ServerResources();
  final connection = ref.read(connectionControllerProvider);
  final scope = ref.watch(activeServerResourceScopeProvider);
  return ref
      .watch(serverResourcesRepositoryProvider)
      .load(supportedMethods: connection.capabilities?.methods, scope: scope);
});

final activeJobsProvider = FutureProvider<ResourceSection<SystemJob>>((
  ref,
) async {
  final hasSession = ref.watch(
    connectionControllerProvider.select((state) => state.hasRetainedSession),
  );
  if (!hasSession) return const ResourceSection();
  final connection = ref.read(connectionControllerProvider);
  return ref
      .watch(serverResourcesRepositoryProvider)
      .loadActiveJobs(supportedMethods: connection.capabilities?.methods);
});

final jobDetailProvider = FutureProvider.autoDispose.family<SystemJob?, int>((
  ref,
  id,
) async {
  final hasSession = ref.watch(
    connectionControllerProvider.select((state) => state.hasRetainedSession),
  );
  if (!hasSession) return null;
  final connection = ref.read(connectionControllerProvider);
  return ref
      .watch(serverResourcesRepositoryProvider)
      .loadJob(id, supportedMethods: connection.capabilities?.methods);
});

void refreshServerResources(WidgetRef ref) {
  ref.invalidate(serverResourcesProvider);
}
