import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/truenas_client_provider.dart';
import '../../connection/presentation/connection_controller.dart';
import '../data/server_resources_repository.dart';
import '../domain/server_resources.dart';

final serverResourcesRepositoryProvider = Provider<ServerResourcesRepository>((
  ref,
) {
  return ServerResourcesRepository(ref.watch(trueNasClientProvider));
});

final serverResourcesProvider = FutureProvider<ServerResources>((ref) async {
  final hasSession = ref.watch(
    connectionControllerProvider.select((state) => state.hasRetainedSession),
  );
  if (!hasSession) return const ServerResources();
  final connection = ref.read(connectionControllerProvider);
  return ref
      .watch(serverResourcesRepositoryProvider)
      .load(supportedMethods: connection.capabilities?.methods);
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
