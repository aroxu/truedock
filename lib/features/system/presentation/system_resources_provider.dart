import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/truenas_client_provider.dart';
import '../../connection/presentation/connection_controller.dart';
import '../data/system_resources_repository.dart';
import '../domain/system_resources.dart';

final systemResourcesRepositoryProvider = Provider<SystemResourcesRepository>((
  ref,
) {
  return SystemResourcesRepository(ref.watch(trueNasClientProvider));
});

final systemResourcesProvider = FutureProvider<SystemResources>((ref) async {
  final hasSession = ref.watch(
    connectionControllerProvider.select((state) => state.hasRetainedSession),
  );
  if (!hasSession) {
    return const SystemResources();
  }
  final connection = ref.read(connectionControllerProvider);
  return ref
      .watch(systemResourcesRepositoryProvider)
      .load(supportedMethods: connection.capabilities?.methods);
});

final systemUpdateStatusProvider =
    FutureProvider<ResourceValue<SystemUpdateStatus>>((ref) async {
      if (!ref.watch(connectionControllerProvider).isConnected) {
        return const ResourceValue();
      }
      return ref.watch(systemResourcesRepositoryProvider).loadUpdateStatus();
    });

final systemUpdateProfilesProvider = FutureProvider<SystemUpdateProfiles>((
  ref,
) {
  if (!ref.watch(connectionControllerProvider).isConnected) {
    return const SystemUpdateProfiles(currentId: null, items: []);
  }
  return ref.watch(systemResourcesRepositoryProvider).loadUpdateProfiles();
});

void refreshSystemResources(WidgetRef ref) {
  ref.invalidate(systemResourcesProvider);
}
