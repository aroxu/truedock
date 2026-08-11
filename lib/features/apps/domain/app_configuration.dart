typedef AppConfigJson = Map<String, dynamic>;

/// Live configuration of an installed app, returned by `app.config`.
///
/// Carries the catalog reference (`catalogApp`, `train`, `version`) so the
/// reconfiguration flow can fetch the matching questions, plus the current
/// `values` to seed the editor. Custom apps have no catalog reference and
/// cannot be reconfigured through the catalog question schema.
class AppConfiguration {
  const AppConfiguration({
    required this.appId,
    required this.name,
    required this.catalogApp,
    required this.train,
    required this.version,
    required this.values,
    this.customComposeConfig,
  });

  factory AppConfiguration.fromJson(AppConfigJson json) {
    final values = json['values'];
    return AppConfiguration(
      appId: _string(json['app_id'] ?? json['id'], fallback: ''),
      name: _string(json['name'], fallback: 'App'),
      catalogApp: _nullableString(json['catalog_app'] ?? json['app_catalog']),
      train: _nullableString(json['train']),
      version: _nullableString(json['app_version'] ?? json['version']),
      values: values is Map<String, dynamic>
          ? Map<String, Object?>.from(values)
          : const <String, Object?>{},
      customComposeConfig: json['custom_compose_config'] is Map
          ? Map<String, Object?>.from(json['custom_compose_config'] as Map)
          : null,
    );
  }

  factory AppConfiguration.forInstalledApp(
    AppConfigJson json, {
    required String appId,
    required String name,
    String? catalogApp,
    String? train,
    String? version,
  }) {
    final parsed = AppConfiguration.fromJson(json);
    final isWrapped = json.containsKey('values');
    final liveValues = isWrapped
        ? parsed.values
        : catalogApp == null
        ? const <String, Object?>{}
        : Map<String, Object?>.from(json);
    return AppConfiguration(
      appId: parsed.appId.isEmpty ? appId : parsed.appId,
      name: parsed.name == 'App' ? name : parsed.name,
      catalogApp: parsed.catalogApp ?? catalogApp,
      train: parsed.train ?? train,
      version: parsed.version ?? version,
      values: liveValues,
      customComposeConfig:
          parsed.customComposeConfig ??
          (!isWrapped && catalogApp == null
              ? Map<String, Object?>.from(json)
              : null),
    );
  }

  final String appId;
  final String name;
  final String? catalogApp;
  final String? train;
  final String? version;
  final Map<String, Object?> values;
  final Map<String, Object?>? customComposeConfig;

  /// A catalog app with a name, train, and version can be reconfigured
  /// through the question schema. Custom apps cannot.
  bool get canReconfigure =>
      catalogApp != null && train != null && version != null;
}

String _string(Object? value, {required String fallback}) =>
    value is String && value.isNotEmpty ? value : fallback;

String? _nullableString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;
