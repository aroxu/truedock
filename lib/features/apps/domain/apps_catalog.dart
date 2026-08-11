import '../../../core/domain/data_message.dart';

typedef CatalogJson = Map<String, dynamic>;

class CatalogValue<T> {
  const CatalogValue({this.value, this.error});

  final T? value;

  /// The failure to show, as a code the presentation layer localizes.
  final DataMessage? error;

  /// English text for logs and tests. The UI renders [error] through
  /// `DataMessageLocalizations` instead.
  String? get errorMessage => error?.fallback;

  bool get hasError => error != null;
}

class AppsCatalogSnapshot {
  const AppsCatalogSnapshot({
    this.apps = const CatalogValue(value: <CatalogApp>[]),
    this.trains = const CatalogValue(value: <String>[]),
    this.dockerStatus = const CatalogValue(),
    this.dockerConfiguration = const CatalogValue(),
  });

  final CatalogValue<List<CatalogApp>> apps;
  final CatalogValue<List<String>> trains;
  final CatalogValue<DockerStatus> dockerStatus;
  final CatalogValue<DockerConfiguration> dockerConfiguration;
}

class CatalogApp {
  const CatalogApp({
    required this.name,
    required this.title,
    required this.train,
    required this.description,
    required this.healthy,
    required this.recommended,
    required this.categories,
    required this.tags,
    this.latestVersion,
    this.iconUrl,
    this.homeUrl,
  });

  factory CatalogApp.fromJson(CatalogJson json, {required String train}) =>
      CatalogApp(
        name: _string(json['name'], fallback: 'app'),
        title: _string(json['title'] ?? json['name'], fallback: 'App'),
        train: train,
        description: _string(
          json['description'],
          fallback: 'No description provided.',
        ),
        healthy: json['healthy'] == true,
        recommended: json['recommended'] == true,
        categories: _stringList(json['categories']),
        tags: _stringList(json['tags']),
        latestVersion: _nullableString(
          json['latest_human_version'] ??
              json['latest_app_version'] ??
              json['latest_version'],
        ),
        iconUrl: _nullableString(json['icon_url']),
        homeUrl: _nullableString(json['home']),
      );

  final String name;
  final String title;
  final String train;
  final String description;
  final bool healthy;
  final bool recommended;
  final List<String> categories;
  final List<String> tags;
  final String? latestVersion;
  final String? iconUrl;
  final String? homeUrl;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return <String>[
      name,
      title,
      description,
      train,
      ...categories,
      ...tags,
    ].any((value) => value.toLowerCase().contains(normalized));
  }
}

class DockerStatus {
  const DockerStatus({required this.status, required this.description});

  factory DockerStatus.fromJson(CatalogJson json) => DockerStatus(
    status: _string(json['status'], fallback: 'UNKNOWN'),
    description: _string(
      json['description'],
      fallback: 'Docker status is unavailable.',
    ),
  );

  final String status;
  final String description;

  bool get isRunning => status == 'RUNNING';
}

class DockerConfiguration {
  const DockerConfiguration({
    required this.imageUpdatesEnabled,
    required this.nvidiaEnabled,
    required this.addressPoolCount,
    required this.secureMirrorCount,
    required this.insecureMirrorCount,
    this.pool,
    this.dataset,
  });

  factory DockerConfiguration.fromJson(CatalogJson json) => DockerConfiguration(
    imageUpdatesEnabled: json['enable_image_updates'] == true,
    nvidiaEnabled: json['nvidia'] == true,
    addressPoolCount: _listLength(json['address_pools']),
    secureMirrorCount: _listLength(json['secure_registry_mirrors']),
    insecureMirrorCount: _listLength(json['insecure_registry_mirrors']),
    pool: _nullableString(json['pool']),
    dataset: _nullableString(json['dataset']),
  );

  final bool imageUpdatesEnabled;
  final bool nvidiaEnabled;
  final int addressPoolCount;
  final int secureMirrorCount;
  final int insecureMirrorCount;
  final String? pool;
  final String? dataset;
}

String _string(Object? value, {required String fallback}) =>
    value is String && value.isNotEmpty ? value : fallback;

String? _nullableString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

List<String> _stringList(Object? value) => value is List<Object?>
    ? value.whereType<String>().toList(growable: false)
    : const [];

int _listLength(Object? value) => value is List<Object?> ? value.length : 0;
