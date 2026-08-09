import '../../resources/domain/server_resources.dart';

/// Stable validation codes for iSCSI extent configuration. The presentation
/// layer maps each code to a localized message.
enum IscsiExtentValidationCode {
  nameLength,
  diskRequired,
  diskUnavailable,
  diskPathConflict,
  pathRequired,
  fileDiskConflict,
  fileSizeNegative,
  fileSizeWholeNumber,
  blockSize,
  thresholdRange,
  thresholdWholeNumber,
  productIdLength,
}

enum IscsiExtentType { disk, file }

extension IscsiExtentTypeApi on IscsiExtentType {
  String get apiValue => name.toUpperCase();

  String get label => switch (this) {
    IscsiExtentType.disk => 'Device',
    IscsiExtentType.file => 'File',
  };

  static IscsiExtentType fromApi(String value) => switch (value) {
    'FILE' => IscsiExtentType.file,
    _ => IscsiExtentType.disk,
  };
}

enum IscsiExtentRpm { unknown, ssd, rpm5400, rpm7200, rpm10000, rpm15000 }

extension IscsiExtentRpmApi on IscsiExtentRpm {
  String get apiValue => switch (this) {
    IscsiExtentRpm.unknown => 'UNKNOWN',
    IscsiExtentRpm.ssd => 'SSD',
    IscsiExtentRpm.rpm5400 => '5400',
    IscsiExtentRpm.rpm7200 => '7200',
    IscsiExtentRpm.rpm10000 => '10000',
    IscsiExtentRpm.rpm15000 => '15000',
  };

  String get label => switch (this) {
    IscsiExtentRpm.unknown => 'Unknown',
    IscsiExtentRpm.ssd => 'SSD',
    IscsiExtentRpm.rpm5400 => '5,400 RPM',
    IscsiExtentRpm.rpm7200 => '7,200 RPM',
    IscsiExtentRpm.rpm10000 => '10,000 RPM',
    IscsiExtentRpm.rpm15000 => '15,000 RPM',
  };

  static IscsiExtentRpm fromApi(String value) => switch (value) {
    'SSD' => IscsiExtentRpm.ssd,
    '5400' => IscsiExtentRpm.rpm5400,
    '7200' => IscsiExtentRpm.rpm7200,
    '10000' => IscsiExtentRpm.rpm10000,
    '15000' => IscsiExtentRpm.rpm15000,
    _ => IscsiExtentRpm.unknown,
  };
}

class IscsiExtentConfiguration {
  const IscsiExtentConfiguration({
    required this.name,
    required this.type,
    required this.disk,
    required this.serial,
    required this.path,
    required this.fileSize,
    required this.blockSize,
    required this.physicalBlockSize,
    required this.availableThreshold,
    required this.comment,
    required this.insecureTpc,
    required this.xen,
    required this.rpm,
    required this.readOnly,
    required this.enabled,
    required this.productId,
  });

  factory IscsiExtentConfiguration.defaults() => const IscsiExtentConfiguration(
    name: '',
    type: IscsiExtentType.disk,
    disk: null,
    serial: null,
    path: null,
    fileSize: 0,
    blockSize: 512,
    physicalBlockSize: false,
    availableThreshold: null,
    comment: '',
    insecureTpc: true,
    xen: false,
    rpm: IscsiExtentRpm.ssd,
    readOnly: false,
    enabled: true,
    productId: null,
  );

  factory IscsiExtentConfiguration.fromExtent(IscsiExtent extent) =>
      IscsiExtentConfiguration(
        name: extent.name,
        type: IscsiExtentTypeApi.fromApi(extent.type),
        disk: extent.disk,
        serial: extent.serial,
        path: extent.path,
        fileSize: extent.sizeBytes ?? 0,
        blockSize: extent.blockSize,
        physicalBlockSize: extent.physicalBlockSize,
        availableThreshold: extent.availableThreshold,
        comment: extent.comment,
        insecureTpc: extent.insecureTpc,
        xen: extent.xen,
        rpm: IscsiExtentRpmApi.fromApi(extent.rpm),
        readOnly: extent.readOnly,
        enabled: extent.enabled,
        productId: extent.productId,
      );

  static const supportedBlockSizes = <int>{512, 1024, 2048, 4096};

  final String name;
  final IscsiExtentType type;
  final String? disk;
  final String? serial;
  final String? path;
  final int fileSize;
  final int blockSize;
  final bool physicalBlockSize;
  final int? availableThreshold;
  final String comment;
  final bool insecureTpc;
  final bool xen;
  final IscsiExtentRpm rpm;
  final bool readOnly;
  final bool enabled;
  final String? productId;

  Map<String, Object?> toApiJson() => {
    'name': name,
    'type': type.apiValue,
    'disk': type == IscsiExtentType.disk ? disk : null,
    'serial': serial,
    'path': type == IscsiExtentType.file ? path : null,
    'filesize': fileSize,
    'blocksize': blockSize,
    'pblocksize': physicalBlockSize,
    'avail_threshold': availableThreshold,
    'comment': comment,
    'insecure_tpc': insecureTpc,
    'xen': xen,
    'rpm': rpm.apiValue,
    'ro': readOnly,
    'enabled': enabled,
    'product_id': productId,
  };

  Map<String, IscsiExtentValidationCode> validate({
    Map<String, String> availableDiskChoices = const {},
  }) {
    final errors = <String, IscsiExtentValidationCode>{};
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || trimmedName.length > 64) {
      errors['name'] = IscsiExtentValidationCode.nameLength;
    }

    if (type == IscsiExtentType.disk) {
      if (disk == null || disk!.isEmpty) {
        errors['disk'] = IscsiExtentValidationCode.diskRequired;
      } else if (!availableDiskChoices.containsKey(disk)) {
        errors['disk'] = IscsiExtentValidationCode.diskUnavailable;
      }
      if (path != null) {
        errors['path'] = IscsiExtentValidationCode.diskPathConflict;
      }
    } else {
      if (path == null || !path!.startsWith('/mnt/')) {
        errors['path'] = IscsiExtentValidationCode.pathRequired;
      }
      if (disk != null) {
        errors['disk'] = IscsiExtentValidationCode.fileDiskConflict;
      }
    }

    if (fileSize < 0) {
      errors['filesize'] = IscsiExtentValidationCode.fileSizeNegative;
    }
    if (!supportedBlockSizes.contains(blockSize)) {
      errors['blocksize'] = IscsiExtentValidationCode.blockSize;
    }
    final threshold = availableThreshold;
    if (threshold != null && (threshold < 1 || threshold > 99)) {
      errors['avail_threshold'] = IscsiExtentValidationCode.thresholdRange;
    }
    final id = productId;
    if (id != null && (id.isEmpty || id.length > 16)) {
      errors['product_id'] = IscsiExtentValidationCode.productIdLength;
    }
    return errors;
  }
}
