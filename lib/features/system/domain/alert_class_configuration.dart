import 'package:meta/meta.dart';

import 'alert_service_configuration.dart';

/// How often a class of alert is delivered to configured destinations.
enum AlertPolicy {
  immediately('IMMEDIATELY'),
  hourly('HOURLY'),
  daily('DAILY'),
  never('NEVER');

  const AlertPolicy(this.apiValue);

  final String apiValue;

  static AlertPolicy fromApi(Object? value) {
    for (final policy in values) {
      if (policy.apiValue == value) return policy;
    }
    return AlertPolicy.immediately;
  }
}

/// One alert class the server can raise, from `alert.list_categories`.
///
/// [level] and [proactiveSupport] are the server's *defaults*. The overrides an
/// administrator has saved live in `alertclasses.config`, which returns only the
/// classes that were changed — so an unlisted class is at its default rather
/// than unset, and the two have to be merged to show the effective policy.
@immutable
class AlertClassDefinition {
  const AlertClassDefinition({
    required this.id,
    required this.title,
    required this.category,
    required this.categoryTitle,
    required this.level,
    required this.proactiveSupport,
  });

  final String id;
  final String title;
  final String category;
  final String categoryTitle;

  /// Severity the server assigns by default.
  final AlertLevel level;
  final bool proactiveSupport;
}

/// An alert class's effective policy: the server default, plus any override.
@immutable
class AlertClassPolicy {
  const AlertClassPolicy({
    required this.definition,
    required this.level,
    required this.policy,
    this.overridden = false,
  });

  final AlertClassDefinition definition;

  /// Effective severity, which is the override when one exists.
  final AlertLevel level;

  /// Effective delivery policy. `IMMEDIATELY` is the server default for a class
  /// with no override.
  final AlertPolicy policy;

  /// Whether an administrator changed this class away from its default.
  final bool overridden;

  String get id => definition.id;
  String get title => definition.title;
  String get categoryTitle => definition.categoryTitle;

  /// True when the class is silenced entirely, which is worth surfacing: no
  /// destination hears about it, however severe it is.
  bool get isSilenced => policy == AlertPolicy.never;

  AlertClassPolicy copyWith({AlertLevel? level, AlertPolicy? policy}) =>
      AlertClassPolicy(
        definition: definition,
        level: level ?? this.level,
        policy: policy ?? this.policy,
        overridden: true,
      );

  /// Whether this differs from what the server would do without an override.
  bool get differsFromDefault =>
      level != definition.level || policy != AlertPolicy.immediately;
}

/// The merged view of every alert class and its effective policy.
@immutable
class AlertClassConfiguration {
  const AlertClassConfiguration({required this.policies});

  /// Merges the class catalog with the saved overrides.
  ///
  /// `alertclasses.config` returns only overridden classes, so a class missing
  /// from it is at its default. Presenting only the overrides would show an
  /// almost-empty list on a stock server and hide everything an administrator
  /// could actually change.
  factory AlertClassConfiguration.merge({
    required List<AlertClassDefinition> definitions,
    required Map<String, Object?> overrides,
  }) {
    final policies = <AlertClassPolicy>[];
    for (final definition in definitions) {
      final override = overrides[definition.id];
      final map = override is Map ? override : const {};
      policies.add(
        AlertClassPolicy(
          definition: definition,
          level: map['level'] == null
              ? definition.level
              : AlertLevel.fromApi(map['level']),
          policy: AlertPolicy.fromApi(map['policy']),
          overridden: override != null,
        ),
      );
    }
    return AlertClassConfiguration(policies: policies);
  }

  /// Parses `alert.list_categories`, which nests classes under categories.
  static List<AlertClassDefinition> parseCategories(List<Object?> response) {
    final definitions = <AlertClassDefinition>[];
    for (final entry in response) {
      if (entry is! Map) continue;
      final category = '${entry['id'] ?? ''}';
      final categoryTitle = entry['title'] is String
          ? entry['title'] as String
          : category;
      final classes = entry['classes'];
      if (classes is! List) continue;
      for (final item in classes) {
        if (item is! Map) continue;
        final id = '${item['id'] ?? ''}';
        if (id.isEmpty) continue;
        definitions.add(
          AlertClassDefinition(
            id: id,
            title: item['title'] is String ? item['title'] as String : id,
            category: category,
            categoryTitle: categoryTitle,
            level: AlertLevel.fromApi(item['level']),
            proactiveSupport: item['proactive_support'] == true,
          ),
        );
      }
    }
    return definitions;
  }

  final List<AlertClassPolicy> policies;

  /// Classes grouped by their category title, in server order.
  Map<String, List<AlertClassPolicy>> get byCategory {
    final grouped = <String, List<AlertClassPolicy>>{};
    for (final policy in policies) {
      grouped.putIfAbsent(policy.categoryTitle, () => []).add(policy);
    }
    return grouped;
  }

  /// Classes an administrator has silenced, which are the ones most worth
  /// reviewing: no destination hears about them, however severe they are.
  List<AlertClassPolicy> get silenced =>
      policies.where((policy) => policy.isSilenced).toList(growable: false);

  int get overriddenCount =>
      policies.where((policy) => policy.differsFromDefault).length;
}

/// A change to one or more alert classes, for `alertclasses.update`.
///
/// The method replaces the whole `classes` map, so an edit has to resend every
/// override that should survive — sending only the changed class would silently
/// reset every other one.
@immutable
class AlertClassEdit {
  const AlertClassEdit({required this.classes});

  /// Effective policies to persist, keyed by class id.
  final Map<String, AlertClassPolicy> classes;

  /// Builds the payload from the merged view, keeping only classes that differ
  /// from the server default so the stored map stays as small as the web UI's.
  factory AlertClassEdit.fromConfiguration(
    AlertClassConfiguration configuration,
  ) => AlertClassEdit(
    classes: {
      for (final policy in configuration.policies)
        if (policy.differsFromDefault) policy.id: policy,
    },
  );

  Map<String, Object?> toApiJson() => {
    'classes': {
      for (final entry in classes.entries)
        entry.key: {
          'level': entry.value.level.apiValue,
          'policy': entry.value.policy.apiValue,
        },
    },
  };
}
