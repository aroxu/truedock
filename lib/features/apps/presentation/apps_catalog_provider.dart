import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/truenas_client_provider.dart';
import '../../connection/presentation/connection_controller.dart';
import '../data/apps_catalog_repository.dart';
import '../domain/apps_catalog.dart';

final appsCatalogRepositoryProvider = Provider<AppsCatalogRepository>((ref) {
  return AppsCatalogRepository(ref.watch(trueNasClientProvider));
});

final appsCatalogProvider = FutureProvider<AppsCatalogSnapshot>((ref) async {
  final hasSession = ref.watch(
    connectionControllerProvider.select((state) => state.hasRetainedSession),
  );
  if (!hasSession) return const AppsCatalogSnapshot();
  final connection = ref.read(connectionControllerProvider);
  return ref
      .watch(appsCatalogRepositoryProvider)
      .load(supportedMethods: connection.capabilities?.methods);
});

void refreshAppsCatalog(WidgetRef ref) {
  ref.invalidate(appsCatalogProvider);
}
