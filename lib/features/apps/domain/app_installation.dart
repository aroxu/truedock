typedef AppInstallJson = Map<String, dynamic>;

/// Stable validation codes for app installation/reconfiguration sheets. The
/// presentation layer maps each code to a localized message. Codes that carry
/// a numeric bound use placeholders resolved by the presentation helper.
enum AppValidationCode {
  nameFormat,
  unsupportedField,
  fieldRequired,
  wholeNumber,
  minimumValue,
  maximumValue,
  minimumLength,
  maximumLength,
  absolutePath,
  uriScheme,
  ipAddress,
  chooseOption,
  minimumItems,
  maximumItems,
  listNoSchema,
  itemRequired,
  itemWholeNumber,
}

/// A validation failure carrying its stable [code] and, when the message
/// interpolates a bound (minimum/maximum value, length, or item count), the
/// [bound] the presentation layer substitutes into the localized string.
class AppValidationIssue {
  const AppValidationIssue(this.code, {this.bound});

  final AppValidationCode code;
  final num? bound;

  @override
  bool operator ==(Object other) =>
      other is AppValidationIssue && other.code == code && other.bound == bound;

  @override
  int get hashCode => Object.hash(code, bound);

  @override
  String toString() => bound == null ? '$code' : '$code($bound)';
}

enum AppQuestionType {
  string,
  text,
  integer,
  boolean,
  ipAddress,
  uri,
  path,
  hostPath,
  dictionary,
  list,
  unsupported,
}

class AppQuestionOption {
  const AppQuestionOption({required this.value, required this.label});

  factory AppQuestionOption.fromJson(AppInstallJson json) => AppQuestionOption(
    value: json['value'],
    label: _string(json['description']) ?? '${json['value'] ?? ''}',
  );

  final Object? value;
  final String label;
}

class AppQuestion {
  const AppQuestion({
    required this.variable,
    required this.label,
    required this.type,
    required this.required,
    required this.private,
    required this.hidden,
    required this.nullable,
    required this.options,
    required this.children,
    required this.showIf,
    this.description,
    this.group,
    this.defaultValue,
    this.minimum,
    this.maximum,
    this.minimumLength,
    this.maximumLength,
    this.listItem,
  });

  factory AppQuestion.fromJson(AppInstallJson json) {
    final schema = _map(json['schema']);
    final type = _questionType(schema['type']);
    final attrs = _listOfMaps(schema['attrs']);
    final items = _listOfMaps(schema['items']);
    return AppQuestion(
      variable: _string(json['variable']) ?? 'value',
      label:
          _string(json['label']) ??
          _string(schema['title']) ??
          _humanize(_string(json['variable']) ?? 'value'),
      description:
          _string(json['description']) ?? _string(schema['description']),
      group: _string(json['group']),
      type: type,
      required: schema['required'] == true,
      private: schema['private'] == true,
      hidden: schema['hidden'] == true,
      nullable: schema['null'] == true,
      defaultValue: _copyValue(schema['default']),
      minimum: _number(schema['min']),
      maximum: _number(schema['max']),
      minimumLength: _integer(schema['min_length']),
      maximumLength: _integer(schema['max_length']),
      options: _listOfMaps(
        schema['enum'],
      ).map(AppQuestionOption.fromJson).toList(growable: false),
      children: attrs.map(AppQuestion.fromJson).toList(growable: false),
      listItem: items.isEmpty ? null : AppQuestion.fromJson(items.first),
      showIf: _showIf(schema['show_if']),
    );
  }

  final String variable;
  final String label;
  final String? description;
  final String? group;
  final AppQuestionType type;
  final bool required;
  final bool private;
  final bool hidden;
  final bool nullable;
  final Object? defaultValue;
  final num? minimum;
  final num? maximum;
  final int? minimumLength;
  final int? maximumLength;
  final List<AppQuestionOption> options;
  final List<AppQuestion> children;
  final AppQuestion? listItem;
  final List<List<Object?>> showIf;

  bool isVisible(Map<String, Object?> siblingValues) {
    if (showIf.isEmpty) return true;
    return showIf.every((condition) {
      if (condition.length < 3) return false;
      final actual = _valueAtPath(siblingValues, '${condition[0]}');
      final operator = '${condition[1]}'.toLowerCase();
      final expected = condition[2];
      return switch (operator) {
        '=' || '==' => actual == expected,
        '!=' => actual != expected,
        'in' => expected is List<Object?> && expected.contains(actual),
        'nin' ||
        'not in' => expected is List<Object?> && !expected.contains(actual),
        '>' => _compare(actual, expected, (a, b) => a > b),
        '>=' => _compare(actual, expected, (a, b) => a >= b),
        '<' => _compare(actual, expected, (a, b) => a < b),
        '<=' => _compare(actual, expected, (a, b) => a <= b),
        _ => false,
      };
    });
  }

  Object? initialValue() {
    if (defaultValue != null) return _copyValue(defaultValue);
    return switch (type) {
      AppQuestionType.dictionary => _defaultsFor(children),
      AppQuestionType.list => <Object?>[],
      _ => null,
    };
  }
}

class AppQuestionGroup {
  const AppQuestionGroup({required this.name, this.description});

  factory AppQuestionGroup.fromJson(AppInstallJson json) => AppQuestionGroup(
    name: _string(json['name']) ?? 'Configuration',
    description: _string(json['description']),
  );

  final String name;
  final String? description;
}

class CatalogAppVersion {
  const CatalogAppVersion({
    required this.version,
    required this.humanVersion,
    required this.healthy,
    required this.supported,
    required this.groups,
    required this.questions,
    required this.initialValues,
    this.healthError,
  });

  factory CatalogAppVersion.fromJson(String version, AppInstallJson json) {
    final schema = _map(json['schema']);
    final questions = _listOfMaps(
      schema['questions'],
    ).map(AppQuestion.fromJson).toList(growable: false);
    final suppliedValues = _objectMap(json['values']);
    return CatalogAppVersion(
      version: _string(json['version']) ?? version,
      humanVersion: _string(json['human_version']) ?? version,
      healthy: json['healthy'] != false,
      supported: json['supported'] != false,
      healthError: _string(json['healthy_error']),
      groups: _listOfMaps(
        schema['groups'],
      ).map(AppQuestionGroup.fromJson).toList(growable: false),
      questions: questions,
      initialValues: _deepMerge(_defaultsFor(questions), suppliedValues),
    );
  }

  final String version;
  final String humanVersion;
  final bool healthy;
  final bool supported;
  final String? healthError;
  final List<AppQuestionGroup> groups;
  final List<AppQuestion> questions;
  final Map<String, Object?> initialValues;

  bool get canInstall => healthy && supported;

  Map<String, Object?> installationValues(Map<String, Object?> values) =>
      _payloadFor(questions, values);
}

class CatalogAppInstallationDetails {
  const CatalogAppInstallationDetails({
    required this.name,
    required this.train,
    required this.latestVersion,
    required this.versions,
  });

  factory CatalogAppInstallationDetails.fromJson(
    AppInstallJson json, {
    required String fallbackName,
    required String train,
  }) {
    final versions = <CatalogAppVersion>[];
    for (final entry in _map(json['versions']).entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        versions.add(CatalogAppVersion.fromJson(entry.key, value));
      } else if (value is Map) {
        versions.add(
          CatalogAppVersion.fromJson(
            entry.key,
            Map<String, dynamic>.from(value),
          ),
        );
      }
    }
    versions.sort((a, b) => _compareVersions(b.version, a.version));
    return CatalogAppInstallationDetails(
      name: _string(json['name']) ?? fallbackName,
      train: train,
      latestVersion: _string(json['latest_version']),
      versions: List.unmodifiable(versions),
    );
  }

  final String name;
  final String train;
  final String? latestVersion;
  final List<CatalogAppVersion> versions;

  CatalogAppVersion? get preferredVersion {
    if (versions.isEmpty) return null;
    for (final version in versions) {
      if (version.version == latestVersion && version.canInstall) {
        return version;
      }
    }
    for (final version in versions) {
      if (version.canInstall) return version;
    }
    return versions.first;
  }
}

class AppInstallRequest {
  const AppInstallRequest({
    required this.appName,
    required this.catalogApp,
    required this.train,
    required this.version,
    required this.values,
  });

  final String appName;
  final String catalogApp;
  final String train;
  final String version;
  final Map<String, Object?> values;
}

/// Result of the reconfiguration sheet. Carries only the new `values` to send
/// to `app.update`; the app id is held by the caller.
class AppUpdateRequest {
  const AppUpdateRequest({required this.values});

  final Map<String, Object?> values;
}

/// Outcome of the install/reconfigure sheet.
sealed class AppSheetResult {
  const AppSheetResult();
}

class AppSheetInstall extends AppSheetResult {
  const AppSheetInstall(this.request);
  final AppInstallRequest request;
}

class AppSheetUpdate extends AppSheetResult {
  const AppSheetUpdate(this.request);
  final AppUpdateRequest request;
}

Map<String, Object?> _defaultsFor(List<AppQuestion> questions) {
  final result = <String, Object?>{};
  for (final question in questions) {
    final value = question.initialValue();
    if (value != null || question.nullable) result[question.variable] = value;
  }
  return result;
}

Map<String, Object?> _payloadFor(
  List<AppQuestion> questions,
  Map<String, Object?> values,
) {
  final result = <String, Object?>{};
  for (final question in questions) {
    if (!question.isVisible(values)) continue;
    if (!values.containsKey(question.variable)) continue;
    final value = values[question.variable];
    result[question.variable] = switch (question.type) {
      AppQuestionType.dictionary when value is Map<String, Object?> =>
        _payloadFor(question.children, value),
      AppQuestionType.dictionary when value is Map => _payloadFor(
        question.children,
        Map<String, Object?>.from(value),
      ),
      AppQuestionType.list when value is List<Object?> =>
        value.map((item) => _listItemPayload(question.listItem, item)).toList(),
      _ => _copyValue(value),
    };
  }
  return result;
}

Object? _listItemPayload(AppQuestion? item, Object? value) {
  if (item?.type == AppQuestionType.dictionary && value is Map) {
    return _payloadFor(item!.children, Map<String, Object?>.from(value));
  }
  return _copyValue(value);
}

Map<String, Object?> _deepMerge(
  Map<String, Object?> defaults,
  Map<String, Object?> supplied,
) {
  final result = <String, Object?>{...defaults};
  for (final entry in supplied.entries) {
    final current = result[entry.key];
    if (current is Map && entry.value is Map) {
      result[entry.key] = _deepMerge(
        Map<String, Object?>.from(current),
        Map<String, Object?>.from(entry.value as Map),
      );
    } else {
      result[entry.key] = _copyValue(entry.value);
    }
  }
  return result;
}

Object? _copyValue(Object? value) {
  if (value is Map) {
    return value.map<String, Object?>(
      (key, value) => MapEntry('$key', _copyValue(value)),
    );
  }
  if (value is List) return value.map(_copyValue).toList();
  return value;
}

Object? _valueAtPath(Map<String, Object?> values, String path) {
  Object? value = values;
  for (final segment in path.split('.')) {
    if (value is! Map || !value.containsKey(segment)) return null;
    value = value[segment];
  }
  return value;
}

bool _compare(
  Object? actual,
  Object? expected,
  bool Function(num a, num b) test,
) {
  if (actual is num && expected is num) return test(actual, expected);
  return false;
}

AppQuestionType _questionType(Object? value) => switch (value) {
  'string' => AppQuestionType.string,
  'text' => AppQuestionType.text,
  'int' => AppQuestionType.integer,
  'boolean' => AppQuestionType.boolean,
  'ipaddr' => AppQuestionType.ipAddress,
  'uri' => AppQuestionType.uri,
  'path' => AppQuestionType.path,
  'hostpath' => AppQuestionType.hostPath,
  'dict' => AppQuestionType.dictionary,
  'list' => AppQuestionType.list,
  _ => AppQuestionType.unsupported,
};

List<List<Object?>> _showIf(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<List>()
      .map((condition) => condition.cast<Object?>())
      .toList(growable: false);
}

List<AppInstallJson> _listOfMaps(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false)
    : const [];

AppInstallJson _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

Map<String, Object?> _objectMap(Object? value) => value is Map
    ? value.map<String, Object?>((key, value) => MapEntry('$key', value))
    : <String, Object?>{};

String? _string(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;

num? _number(Object? value) => value is num ? value : null;

int? _integer(Object? value) => value is int ? value : null;

String _humanize(String value) => value
    .split('_')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

int _compareVersions(String a, String b) {
  final left = a.split(RegExp(r'[._-]'));
  final right = b.split(RegExp(r'[._-]'));
  for (var index = 0; index < left.length || index < right.length; index++) {
    final leftPart = index < left.length ? left[index] : '0';
    final rightPart = index < right.length ? right[index] : '0';
    final leftNumber = int.tryParse(leftPart);
    final rightNumber = int.tryParse(rightPart);
    final result = leftNumber != null && rightNumber != null
        ? leftNumber.compareTo(rightNumber)
        : leftPart.compareTo(rightPart);
    if (result != 0) return result;
  }
  return 0;
}
