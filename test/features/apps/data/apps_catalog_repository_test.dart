import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/features/apps/data/apps_catalog_repository.dart';
import 'package:true_dock/features/apps/domain/apps_catalog.dart';

void main() {
  test('loads catalog apps, trains, and Docker state', () async {
    final client = _CatalogClient({
      'catalog.apps': {
        'stable': {
          'immich': {
            'title': 'Immich',
            'description': 'Photo management',
            'healthy': true,
            'recommended': true,
            'latest_human_version': '1.2.3',
            'categories': ['media'],
            'tags': ['photos'],
          },
          'syncthing': {
            'name': 'syncthing',
            'title': 'Syncthing',
            'description': 'File synchronization',
            'healthy': true,
            'recommended': false,
            'categories': ['storage'],
            'tags': ['sync'],
          },
        },
      },
      'catalog.trains': ['stable', 'community'],
      'docker.status': {
        'status': 'RUNNING',
        'description': 'Docker service is running.',
      },
      'docker.config': {
        'pool': 'tank',
        'dataset': 'tank/ix-apps',
        'enable_image_updates': true,
        'nvidia': false,
        'address_pools': const [],
        'secure_registry_mirrors': const [],
        'insecure_registry_mirrors': const [],
      },
    });
    final repository = AppsCatalogRepository(client);

    final snapshot = await repository.load();

    expect(snapshot.apps.value, hasLength(2));
    expect(snapshot.apps.value!.first.name, 'immich');
    expect(snapshot.apps.value!.first.recommended, isTrue);
    expect(snapshot.trains.value, ['stable', 'community']);
    expect(snapshot.dockerStatus.value!.isRunning, isTrue);
    expect(snapshot.dockerConfiguration.value!.pool, 'tank');
    expect(client.paramsFor('catalog.apps'), const [
      {
        'cache': true,
        'cache_only': false,
        'retrieve_all_trains': true,
        'trains': <String>[],
      },
    ]);
  });

  test('skips methods absent from capability discovery', () async {
    final client = _CatalogClient(const {});
    final repository = AppsCatalogRepository(client);

    final snapshot = await repository.load(
      supportedMethods: const {'docker.status'},
    );

    expect(client.calledMethods, ['docker.status']);
    expect(snapshot.apps.hasError, isTrue);
    expect(
      snapshot.apps.errorMessage,
      'catalog.apps is not available on this TrueNAS version.',
    );
    expect(snapshot.dockerStatus.hasError, isFalse);
  });

  test('keeps partial results when catalog access is denied', () async {
    final client = _CatalogClient(
      {
        'catalog.trains': ['stable'],
        'docker.status': {
          'status': 'UNCONFIGURED',
          'description': 'Choose an apps pool.',
        },
        'docker.config': {
          'pool': null,
          'dataset': null,
          'enable_image_updates': false,
          'nvidia': false,
          'address_pools': const [],
          'secure_registry_mirrors': const [],
          'insecure_registry_mirrors': const [],
        },
      },
      failures: const {
        'catalog.apps': TrueNasRpcException(
          code: -32001,
          message: 'Not authorized',
        ),
      },
    );
    final repository = AppsCatalogRepository(client);

    final snapshot = await repository.load();

    expect(snapshot.apps.errorMessage, 'Not authorized');
    expect(snapshot.trains.value, ['stable']);
    expect(snapshot.dockerStatus.value!.status, 'UNCONFIGURED');
  });

  test(
    'loads the selected catalog app installation schema on demand',
    () async {
      final client = _CatalogClient({
        'catalog.get_app_details': {
          'name': 'immich',
          'latest_version': '2.0.0',
          'versions': {
            '2.0.0': {
              'version': '2.0.0',
              'human_version': '2.0.0 release',
              'healthy': true,
              'supported': true,
              'values': const <String, Object?>{},
              'schema': {'groups': const [], 'questions': const []},
            },
          },
        },
      });
      final repository = AppsCatalogRepository(client);
      const app = CatalogApp(
        name: 'immich',
        title: 'Immich',
        train: 'stable',
        description: 'Photos',
        healthy: true,
        recommended: true,
        categories: [],
        tags: [],
      );

      final result = await repository.getInstallationDetails(app);

      expect(result.value!.preferredVersion!.version, '2.0.0');
      expect(client.paramsFor('catalog.get_app_details'), [
        'immich',
        {'train': 'stable'},
      ]);
    },
  );
}

class _CatalogClient extends TrueNasJsonRpcClient {
  _CatalogClient(this.responses, {this.failures = const {}});

  final Map<String, Object?> responses;
  final Map<String, Object> failures;
  final List<String> calledMethods = [];
  final Map<String, List<Object?>> _params = {};

  List<Object?>? paramsFor(String method) => _params[method];

  @override
  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 20),
  }) async {
    calledMethods.add(method);
    _params[method] = params;
    final failure = failures[method];
    if (failure != null) throw failure;
    return responses[method] ??
        switch (method) {
          'catalog.apps' => <String, Object?>{},
          'catalog.trains' => <Object?>[],
          _ => <String, Object?>{},
        };
  }
}
