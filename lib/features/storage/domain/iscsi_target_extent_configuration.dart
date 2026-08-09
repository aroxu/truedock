import '../../resources/domain/server_resources.dart';

/// Stable validation codes for iSCSI target-extent associations. The
/// presentation layer maps each code to a localized message.
enum IscsiTargetExtentValidationCode {
  targetInvalid,
  targetUnavailable,
  extentInvalid,
  extentUnavailable,
  lunidNegative,
  lunidEmpty,
  lunidWholeNumber,
}

class IscsiTargetExtentConfiguration {
  const IscsiTargetExtentConfiguration({
    required this.targetId,
    required this.extentId,
    required this.lunId,
  });

  factory IscsiTargetExtentConfiguration.defaults({
    required int targetId,
    required int extentId,
  }) => IscsiTargetExtentConfiguration(
    targetId: targetId,
    extentId: extentId,
    lunId: null,
  );

  factory IscsiTargetExtentConfiguration.fromTargetExtent(
    IscsiTargetExtent targetExtent,
  ) => IscsiTargetExtentConfiguration(
    targetId: targetExtent.targetId,
    extentId: targetExtent.extentId,
    lunId: targetExtent.lunId,
  );

  final int targetId;
  final int extentId;
  final int? lunId;

  Map<String, Object?> toCreateApiJson() => {
    'target': targetId,
    'extent': extentId,
    'lunid': lunId,
  };

  Map<String, Object?> toUpdateApiJson() => {
    'target': targetId,
    'extent': extentId,
    if (lunId != null) 'lunid': lunId,
  };

  Map<String, IscsiTargetExtentValidationCode> validate({
    List<int> availableTargetIds = const [],
    List<int> availableExtentIds = const [],
  }) {
    final errors = <String, IscsiTargetExtentValidationCode>{};
    if (targetId < 0) {
      errors['target'] = IscsiTargetExtentValidationCode.targetInvalid;
    } else if (availableTargetIds.isNotEmpty &&
        !availableTargetIds.contains(targetId)) {
      errors['target'] = IscsiTargetExtentValidationCode.targetUnavailable;
    }
    if (extentId < 0) {
      errors['extent'] = IscsiTargetExtentValidationCode.extentInvalid;
    } else if (availableExtentIds.isNotEmpty &&
        !availableExtentIds.contains(extentId)) {
      errors['extent'] = IscsiTargetExtentValidationCode.extentUnavailable;
    }
    if (lunId != null && lunId! < 0) {
      errors['lunid'] = IscsiTargetExtentValidationCode.lunidNegative;
    }
    return errors;
  }
}
