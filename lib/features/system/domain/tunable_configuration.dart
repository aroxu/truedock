import 'package:meta/meta.dart';

enum TunableType { sysctl, udev, zfs }

extension TunableTypeApi on TunableType {
  String get apiValue => switch (this) {
    TunableType.sysctl => 'SYSCTL',
    TunableType.udev => 'UDEV',
    TunableType.zfs => 'ZFS',
  };

  static TunableType fromApi(Object? value) => switch (value) {
    'UDEV' => TunableType.udev,
    'ZFS' => TunableType.zfs,
    _ => TunableType.sysctl,
  };
}

enum TunableValidationCode { variableRequired, valueRequired }

@immutable
class TunableValidationIssue {
  const TunableValidationIssue(this.code);

  final TunableValidationCode code;
}

/// Editable data accepted by the TrueNAS 25.10 `tunable.*` API.
@immutable
class TunableConfiguration {
  const TunableConfiguration({
    required this.variable,
    required this.value,
    this.type = TunableType.sysctl,
    this.comment = '',
    this.enabled = true,
    this.updateInitramfs = true,
  });

  factory TunableConfiguration.fromJson(Map<String, dynamic> json) =>
      TunableConfiguration(
        type: TunableTypeApi.fromApi(json['type']),
        variable: json['var'] is String ? json['var'] as String : '',
        value: json['value'] is String ? json['value'] as String : '',
        comment: json['comment'] is String ? json['comment'] as String : '',
        enabled: json['enabled'] != false,
        updateInitramfs: json['update_initramfs'] != false,
      );

  final TunableType type;
  final String variable;
  final String value;
  final String comment;
  final bool enabled;
  final bool updateInitramfs;

  List<TunableValidationIssue> validate() => [
    if (variable.trim().isEmpty)
      const TunableValidationIssue(TunableValidationCode.variableRequired),
    if (value.trim().isEmpty)
      const TunableValidationIssue(TunableValidationCode.valueRequired),
  ];

  Map<String, Object?> toCreateApiJson() => {
    'type': type.apiValue,
    'var': variable.trim(),
    'value': value.trim(),
    'comment': comment.trim(),
    'enabled': enabled,
    'update_initramfs': updateInitramfs,
  };

  /// TrueNAS does not permit changing `type` or `var` after creation.
  Map<String, Object?> toUpdateApiJson() => {
    'value': value.trim(),
    'comment': comment.trim(),
    'enabled': enabled,
    'update_initramfs': updateInitramfs,
  };

  TunableConfiguration copyWith({
    TunableType? type,
    String? variable,
    String? value,
    String? comment,
    bool? enabled,
    bool? updateInitramfs,
  }) => TunableConfiguration(
    type: type ?? this.type,
    variable: variable ?? this.variable,
    value: value ?? this.value,
    comment: comment ?? this.comment,
    enabled: enabled ?? this.enabled,
    updateInitramfs: updateInitramfs ?? this.updateInitramfs,
  );
}

@immutable
class Tunable {
  const Tunable({
    required this.id,
    required this.configuration,
    this.originalValue,
  });

  factory Tunable.fromJson(Map<String, dynamic> json) => Tunable(
    id: json['id'] is int ? json['id'] as int : -1,
    configuration: TunableConfiguration.fromJson(json),
    originalValue: json['orig_value'] is String
        ? json['orig_value'] as String
        : null,
  );

  final int id;
  final TunableConfiguration configuration;
  final String? originalValue;
}
