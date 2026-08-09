import '../../../l10n/app_localizations.dart';
import '../domain/dataset_configuration.dart';
import '../domain/smb_acl_configuration.dart';
import '../domain/nfs_share_configuration.dart';
import '../domain/iscsi_auth_configuration.dart';
import '../domain/iscsi_extent_configuration.dart';
import '../domain/iscsi_target_extent_configuration.dart';
import '../domain/iscsi_configuration.dart';
import '../../actions/data/server_actions_repository.dart';

/// Localizes client-owned fallback values used when TrueNAS omits disk
/// identity fields. Real model and serial values are returned unchanged.
extension StorageDiskLocalizations on AppLocalizations {
  String diskModelLabel(String value) =>
      value.trim().isEmpty || value == 'Unknown model'
      ? storageDiskUnknownModel
      : value;

  String diskSerialLabel(String value) =>
      value.trim().isEmpty || value == 'No serial'
      ? storageDiskNoSerial
      : value;
}

/// Maps dataset configuration codes onto ARB-localized strings.
extension StorageDatasetLocalizations on AppLocalizations {
  String datasetConfigurationMessage(DatasetConfigurationCode code) =>
      switch (code) {
        DatasetConfigurationCode.renameEmpty => storageRenameCodeRenameEmpty,
        DatasetConfigurationCode.renameContainsSlash =>
          storageRenameCodeRenameContainsSlash,
        DatasetConfigurationCode.renamePoolRoot =>
          storageRenameCodeRenamePoolRoot,
        DatasetConfigurationCode.renameUnchanged =>
          storageRenameCodeRenameUnchanged,
        DatasetConfigurationCode.editNothingChanged =>
          storageDatasetCodeEditNothingChanged,
      };
}

/// Maps SMB ACL permission enums onto ARB-localized labels.
extension StorageSmbAclLocalizations on AppLocalizations {
  String smbSharePermissionLabel(SmbSharePermission permission) =>
      switch (permission) {
        SmbSharePermission.none => storageSmbAclPermRead,
        SmbSharePermission.read => storageSmbAclPermRead,
        SmbSharePermission.change => storageSmbAclPermChange,
        SmbSharePermission.full => storageSmbAclPermFull,
      };
}

/// Maps NFS share validation codes and security enum labels onto ARB-localized
/// strings.
extension StorageNfsLocalizations on AppLocalizations {
  String nfsValidationMessage(NfsValidationCode code) => switch (code) {
    NfsValidationCode.path => storageNfsValidationPath,
    NfsValidationCode.networksCount => storageNfsValidationNetworksCount,
    NfsValidationCode.networksFormat => storageNfsValidationNetworksFormat,
    NfsValidationCode.hosts => storageNfsValidationHosts,
    NfsValidationCode.mapping => storageNfsValidationMapping,
  };

  String nfsSecurityLabel(NfsSecurity security) => switch (security) {
    NfsSecurity.sys => storageNfsSecuritySys,
    NfsSecurity.krb5 => storageNfsSecurityKrb5,
    NfsSecurity.krb5i => storageNfsSecurityKrb5i,
    NfsSecurity.krb5p => storageNfsSecurityKrb5p,
  };
}

/// Maps iSCSI CHAP validation codes onto ARB-localized strings.
extension StorageIscsiAuthLocalizations on AppLocalizations {
  String iscsiAuthValidationMessage(IscsiAuthValidationCode code) =>
      switch (code) {
        IscsiAuthValidationCode.userRequired =>
          storageIscsiAuthValidationUserRequired,
        IscsiAuthValidationCode.secretRequired =>
          storageIscsiAuthValidationSecretRequired,
        IscsiAuthValidationCode.secretMismatch =>
          storageIscsiAuthValidationSecretMismatch,
        IscsiAuthValidationCode.peerUserRequired =>
          storageIscsiAuthValidationPeerUserRequired,
        IscsiAuthValidationCode.peerSecretRequired =>
          storageIscsiAuthValidationPeerSecretRequired,
        IscsiAuthValidationCode.peerSecretMismatch =>
          storageIscsiAuthValidationPeerSecretMismatch,
      };
}

/// Maps iSCSI extent validation codes and enum labels onto ARB-localized
/// strings.
extension StorageIscsiExtentLocalizations on AppLocalizations {
  String iscsiExtentValidationMessage(IscsiExtentValidationCode code) =>
      switch (code) {
        IscsiExtentValidationCode.nameLength =>
          storageIscsiExtentValidationNameLength,
        IscsiExtentValidationCode.diskRequired =>
          storageIscsiExtentValidationDiskRequired,
        IscsiExtentValidationCode.diskUnavailable =>
          storageIscsiExtentValidationDiskUnavailable,
        IscsiExtentValidationCode.diskPathConflict =>
          storageIscsiExtentValidationDiskPathConflict,
        IscsiExtentValidationCode.pathRequired =>
          storageIscsiExtentValidationPathRequired,
        IscsiExtentValidationCode.fileDiskConflict =>
          storageIscsiExtentValidationFileDiskConflict,
        IscsiExtentValidationCode.fileSizeNegative =>
          storageIscsiExtentValidationFileSizeNegative,
        IscsiExtentValidationCode.fileSizeWholeNumber =>
          storageIscsiExtentValidationFileSizeWholeNumber,
        IscsiExtentValidationCode.blockSize =>
          storageIscsiExtentValidationBlockSize,
        IscsiExtentValidationCode.thresholdRange =>
          storageIscsiExtentValidationThresholdRange,
        IscsiExtentValidationCode.thresholdWholeNumber =>
          storageIscsiExtentValidationThresholdWholeNumber,
        IscsiExtentValidationCode.productIdLength =>
          storageIscsiExtentValidationProductIdLength,
      };

  String iscsiExtentTypeLabel(IscsiExtentType type) => switch (type) {
    IscsiExtentType.disk => storageIscsiExtentTypeDisk,
    IscsiExtentType.file => storageIscsiExtentTypeFile,
  };

  String iscsiExtentRpmLabel(IscsiExtentRpm rpm) => switch (rpm) {
    IscsiExtentRpm.unknown => storageIscsiExtentRpmUnknown,
    IscsiExtentRpm.ssd => storageIscsiExtentRpmSsd,
    IscsiExtentRpm.rpm5400 => storageIscsiExtentRpm5400,
    IscsiExtentRpm.rpm7200 => storageIscsiExtentRpm7200,
    IscsiExtentRpm.rpm10000 => storageIscsiExtentRpm10000,
    IscsiExtentRpm.rpm15000 => storageIscsiExtentRpm15000,
  };

  String storageIscsiExtentReviewYesNo(bool value) =>
      value ? storageIscsiExtentReviewYes : storageIscsiExtentReviewNo;
}

/// Maps iSCSI target-extent validation codes onto ARB-localized strings.
extension StorageIscsiTargetExtentLocalizations on AppLocalizations {
  String iscsiTargetExtentValidationMessage(
    IscsiTargetExtentValidationCode code,
  ) => switch (code) {
    IscsiTargetExtentValidationCode.targetInvalid =>
      storageIscsiTeValidationTargetInvalid,
    IscsiTargetExtentValidationCode.targetUnavailable =>
      storageIscsiTeValidationTargetUnavailable,
    IscsiTargetExtentValidationCode.extentInvalid =>
      storageIscsiTeValidationExtentInvalid,
    IscsiTargetExtentValidationCode.extentUnavailable =>
      storageIscsiTeValidationExtentUnavailable,
    IscsiTargetExtentValidationCode.lunidNegative =>
      storageIscsiTeValidationLunidNegative,
    IscsiTargetExtentValidationCode.lunidEmpty =>
      storageIscsiTeValidationLunidEmpty,
    IscsiTargetExtentValidationCode.lunidWholeNumber =>
      storageIscsiTeValidationLunidWholeNumber,
  };
}

/// Maps iSCSI portal/initiator validation codes onto ARB-localized strings.
extension StorageIscsiConfigLocalizations on AppLocalizations {
  String iscsiPortalValidationMessage(IscsiPortalValidationCode code) =>
      switch (code) {
        IscsiPortalValidationCode.listenRequired =>
          storageIscsiPortalValidationListenRequired,
        IscsiPortalValidationCode.listenFormat =>
          storageIscsiPortalValidationListenFormat,
        IscsiPortalValidationCode.listenUnavailable =>
          storageIscsiPortalValidationListenUnavailable,
      };

  String iscsiInitiatorValidationMessage(IscsiInitiatorValidationCode code) =>
      switch (code) {
        IscsiInitiatorValidationCode.format =>
          storageIscsiInitiatorValidationFormat,
      };
}

/// Maps pool scrub control actions onto ARB-localized labels. The repository
/// keeps [ScrubControlAction.label] as an English fallback for logs.
extension StorageScrubLocalizations on AppLocalizations {
  String scrubControlActionLabel(ScrubControlAction action) => switch (action) {
    ScrubControlAction.pause => storageScrubActionPause,
    ScrubControlAction.resume => storageScrubActionResume,
    ScrubControlAction.stop => storageScrubActionStop,
  };
}

/// Localizes errors emitted after a `filesystem.setacl` job has started.
///
/// TrueNAS' UI catalogs use the English source sentence as their lookup key.
/// The 25.10.6 catalog does not contain the middleware pool-mountpoint error,
/// so TrueDock owns that stable translation and retains unknown server detail.
extension StorageDatasetAclErrorLocalizations on AppLocalizations {
  String datasetAclSetAclError(String serverError) {
    final poolMountpoint = RegExp(
      r'The specified path is a ZFS pool mountpoint\s*"?\(([^)]+)\)"?',
      caseSensitive: false,
    ).firstMatch(serverError);
    final detail = poolMountpoint == null
        ? serverError
        : storageDatasetAclPoolMountpointError(poolMountpoint.group(1)!);
    return storageDatasetAclSetAclError(detail);
  }
}

extension StorageDatasetChangeLocalizations on AppLocalizations {
  String datasetChange(DatasetChange change) => switch (change.code) {
    DatasetChangeCode.commentsInherited => datasetChangeCommentsInherited,
    DatasetChangeCode.commentsCleared => datasetChangeCommentsCleared,
    DatasetChangeCode.commentsSet => datasetChangeCommentsSet(change.value!),
    DatasetChangeCode.quotaInherited => datasetChangeQuotaInherited,
    DatasetChangeCode.quotaRemoved => datasetChangeQuotaRemoved,
    DatasetChangeCode.quotaSet => datasetChangeQuotaSet(change.value!),
    DatasetChangeCode.refquotaInherited => datasetChangeRefquotaInherited,
    DatasetChangeCode.refquotaRemoved => datasetChangeRefquotaRemoved,
    DatasetChangeCode.refquotaSet => datasetChangeRefquotaSet(change.value!),
    DatasetChangeCode.readOnlyInherited => datasetChangeReadOnlyInherited,
    DatasetChangeCode.readOnlyEnabled => datasetChangeReadOnlyEnabled,
    DatasetChangeCode.readOnlyDisabled => datasetChangeReadOnlyDisabled,
    DatasetChangeCode.compressionInherited => datasetChangeCompressionInherited,
    DatasetChangeCode.compressionSet => datasetChangeCompressionSet(
      change.value!,
    ),
    DatasetChangeCode.syncInherited => datasetChangeSyncInherited,
    DatasetChangeCode.syncSet => datasetChangeSyncSet(change.value!),
    DatasetChangeCode.propertyUpdated => datasetChangePropertyUpdated(
      change.value!,
    ),
  };

  String datasetCompressionLabel(DatasetCompression value) => switch (value) {
    DatasetCompression.off => datasetCompressionOff,
    DatasetCompression.lz4 => datasetCompressionLz4,
    DatasetCompression.zstd => datasetCompressionZstd,
    DatasetCompression.gzip => datasetCompressionGzip,
  };

  String datasetSyncLabel(DatasetSync value) => switch (value) {
    DatasetSync.standard => datasetSyncStandard,
    DatasetSync.always => datasetSyncAlways,
    DatasetSync.disabled => datasetSyncDisabled,
  };
}

extension StorageServerValueLocalizations on AppLocalizations {
  String storageServerValue(String value) => switch (value.toUpperCase()) {
    'ONLINE' => storageValueOnline,
    'OFFLINE' => storageValueOffline,
    'DEGRADED' => storageValueDegraded,
    'FAULTED' => storageValueFaulted,
    'UNAVAIL' || 'UNAVAILABLE' => storageValueUnavailable,
    'DATA' => storageValueData,
    'CACHE' => storageValueCache,
    'LOG' => storageValueLog,
    'SPARE' => storageValueSpare,
    'SPECIAL' => storageValueSpecial,
    'DISK' => storageIscsiExtentTypeDisk,
    'FILE' => storageIscsiExtentTypeFile,
    'ISCSI' => storageIscsiTargetModeIscsi,
    _ => value,
  };
}
