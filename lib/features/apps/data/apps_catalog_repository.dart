import '../../../core/api/truenas_json_rpc_client.dart';
import '../domain/app_installation.dart';
import '../domain/apps_catalog.dart';
import '../../../core/domain/data_message.dart';

class AppsCatalogRepository {
  const AppsCatalogRepository(this._client);

  final TrueNasJsonRpcClient _client;

  Future<CatalogValue<CatalogAppInstallationDetails>> getInstallationDetails(
    CatalogApp app, {
    Set<String>? supportedMethods,
  }) async {
    const method = 'catalog.get_app_details';
    if (!_isSupported(method, supportedMethods)) {
      return CatalogValue(error: _unavailable(method));
    }
    try {
      final response = await _client.call(
        method,
        params: [
          app.name,
          {'train': app.train},
        ],
      );
      if (response is! CatalogJson) {
        return const CatalogValue(
          error: DataMessage(
            DataMessageCode.invalidData,
            method: 'catalog.get_app_details',
            fallback: 'catalog.get_app_details returned invalid data.',
          ),
        );
      }
      final details = CatalogAppInstallationDetails.fromJson(
        response,
        fallbackName: app.name,
        train: app.train,
      );
      if (details.versions.isEmpty) {
        return const CatalogValue(
          error: DataMessage(
            DataMessageCode.noInstallableVersions,
            fallback: 'No installable app versions were returned.',
          ),
        );
      }
      return CatalogValue(value: details);
    } on TrueNasRpcException catch (error) {
      return CatalogValue(error: DataMessage.raw(error.displayMessage));
    } on Object {
      return const CatalogValue(
        error: DataMessage(
          DataMessageCode.decodeAppDetails,
          fallback: 'Could not decode catalog.get_app_details.',
        ),
      );
    }
  }

  Future<AppsCatalogSnapshot> load({Set<String>? supportedMethods}) async {
    final results = await Future.wait<Object>([
      _loadApps(supportedMethods),
      _loadTrains(supportedMethods),
      _loadObject(
        'docker.status',
        DockerStatus.fromJson,
        supportedMethods: supportedMethods,
      ),
      _loadObject(
        'docker.config',
        DockerConfiguration.fromJson,
        supportedMethods: supportedMethods,
      ),
    ]);

    return AppsCatalogSnapshot(
      apps: results[0] as CatalogValue<List<CatalogApp>>,
      trains: results[1] as CatalogValue<List<String>>,
      dockerStatus: results[2] as CatalogValue<DockerStatus>,
      dockerConfiguration: results[3] as CatalogValue<DockerConfiguration>,
    );
  }

  Future<CatalogValue<List<CatalogApp>>> _loadApps(
    Set<String>? supportedMethods,
  ) async {
    const method = 'catalog.apps';
    if (!_isSupported(method, supportedMethods)) {
      return CatalogValue(error: _unavailable(method));
    }
    try {
      final response = await _client.call(
        method,
        params: const [
          {
            'cache': true,
            'cache_only': false,
            'retrieve_all_trains': true,
            'trains': <String>[],
          },
        ],
      );
      if (response is! CatalogJson) {
        return const CatalogValue(
          error: DataMessage(
            DataMessageCode.invalidData,
            method: 'catalog.apps',
            fallback: 'catalog.apps returned invalid data.',
          ),
        );
      }
      final apps = <CatalogApp>[];
      for (final trainEntry in response.entries) {
        final trainApps = trainEntry.value;
        if (trainApps is! CatalogJson) continue;
        for (final appEntry in trainApps.entries) {
          final app = appEntry.value;
          if (app is! CatalogJson) continue;
          apps.add(
            CatalogApp.fromJson({
              ...app,
              'name': app['name'] ?? appEntry.key,
            }, train: trainEntry.key),
          );
        }
      }
      apps.sort((a, b) {
        if (a.recommended != b.recommended) return a.recommended ? -1 : 1;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
      return CatalogValue(value: List.unmodifiable(apps));
    } on TrueNasRpcException catch (error) {
      return CatalogValue(error: DataMessage.raw(error.displayMessage));
    } on Object {
      return const CatalogValue(
        error: DataMessage(
          DataMessageCode.decodeCatalogApps,
          fallback: 'Could not decode catalog.apps.',
        ),
      );
    }
  }

  Future<CatalogValue<List<String>>> _loadTrains(
    Set<String>? supportedMethods,
  ) async {
    const method = 'catalog.trains';
    if (!_isSupported(method, supportedMethods)) {
      return CatalogValue(error: _unavailable(method));
    }
    try {
      final response = await _client.call(method);
      if (response is! List<Object?>) {
        return const CatalogValue(
          error: DataMessage(
            DataMessageCode.invalidData,
            method: 'catalog.trains',
            fallback: 'catalog.trains returned invalid data.',
          ),
        );
      }
      return CatalogValue(
        value: response.whereType<String>().toList(growable: false),
      );
    } on TrueNasRpcException catch (error) {
      return CatalogValue(error: DataMessage.raw(error.displayMessage));
    } on Object {
      return const CatalogValue(
        error: DataMessage(
          DataMessageCode.decodeCatalogTrains,
          fallback: 'Could not decode catalog.trains.',
        ),
      );
    }
  }

  Future<CatalogValue<T>> _loadObject<T>(
    String method,
    T Function(CatalogJson json) decode, {
    Set<String>? supportedMethods,
  }) async {
    if (!_isSupported(method, supportedMethods)) {
      return CatalogValue(error: _unavailable(method));
    }
    try {
      final response = await _client.call(method);
      if (response is! CatalogJson) {
        return CatalogValue(
          error: DataMessage(
            DataMessageCode.invalidData,
            method: method,
            fallback: '$method returned invalid data.',
          ),
        );
      }
      return CatalogValue(value: decode(response));
    } on TrueNasRpcException catch (error) {
      return CatalogValue(error: DataMessage.raw(error.displayMessage));
    } on Object {
      return CatalogValue(
        error: DataMessage(
          DataMessageCode.decodeFailed,
          method: method,
          fallback: 'Could not decode $method.',
        ),
      );
    }
  }

  bool _isSupported(String method, Set<String>? supportedMethods) =>
      supportedMethods == null || supportedMethods.contains(method);

  DataMessage _unavailable(String method) => DataMessage(
    DataMessageCode.methodUnavailable,
    method: method,
    fallback: '$method is not available on this TrueNAS version.',
  );
}
