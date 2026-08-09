import '../../resources/domain/server_resources.dart';

/// Tri-state used by editable ZFS properties: inherit from the parent, or set
/// an explicit value. TrueNAS distinguishes "inherit" from an explicit value
/// that happens to match the parent, so TrueDock keeps them separate.
enum DatasetPropertyMode { inherit, explicit }

enum DatasetCompression { off, lz4, zstd, gzip }

extension DatasetCompressionApi on DatasetCompression {
  String get apiValue => switch (this) {
    DatasetCompression.off => 'OFF',
    DatasetCompression.lz4 => 'LZ4',
    DatasetCompression.zstd => 'ZSTD',
    DatasetCompression.gzip => 'GZIP',
  };

  String get label => switch (this) {
    DatasetCompression.off => 'Off',
    DatasetCompression.lz4 => 'LZ4 (recommended)',
    DatasetCompression.zstd => 'ZSTD',
    DatasetCompression.gzip => 'GZIP',
  };

  static DatasetCompression? parse(String? value) => switch (value) {
    'OFF' => DatasetCompression.off,
    'LZ4' => DatasetCompression.lz4,
    'ZSTD' => DatasetCompression.zstd,
    'GZIP' => DatasetCompression.gzip,
    _ => null,
  };
}

enum DatasetSync { standard, always, disabled }

extension DatasetSyncApi on DatasetSync {
  String get apiValue => switch (this) {
    DatasetSync.standard => 'STANDARD',
    DatasetSync.always => 'ALWAYS',
    DatasetSync.disabled => 'DISABLED',
  };

  String get label => switch (this) {
    DatasetSync.standard => 'Standard',
    DatasetSync.always => 'Always',
    DatasetSync.disabled => 'Disabled',
  };

  /// Extra guidance shown beneath the selector rather than inside it.
  String? get warning => switch (this) {
    DatasetSync.disabled =>
      'Disabling sync risks losing recent writes if the server loses power.',
    _ => null,
  };

  static DatasetSync? parse(String? value) => switch (value) {
    'STANDARD' => DatasetSync.standard,
    'ALWAYS' => DatasetSync.always,
    'DISABLED' => DatasetSync.disabled,
    _ => null,
  };
}

/// Stable validation/configuration codes for dataset operations. The
/// presentation layer maps each code to a localized message; the domain keeps
/// an English fallback [message] for logs and tests.
enum DatasetConfigurationCode {
  renameEmpty,
  renameContainsSlash,
  renamePoolRoot,
  renameUnchanged,
  editNothingChanged,
}

enum DatasetChangeCode {
  commentsInherited,
  commentsCleared,
  commentsSet,
  quotaInherited,
  quotaRemoved,
  quotaSet,
  refquotaInherited,
  refquotaRemoved,
  refquotaSet,
  readOnlyInherited,
  readOnlyEnabled,
  readOnlyDisabled,
  compressionInherited,
  compressionSet,
  syncInherited,
  syncSet,
  propertyUpdated,
}

class DatasetChange {
  const DatasetChange(this.code, {this.value});

  final DatasetChangeCode code;
  final String? value;
}

class DatasetConfigurationException implements Exception {
  const DatasetConfigurationException(this.message, {this.code});

  final String message;
  final DatasetConfigurationCode? code;

  @override
  String toString() => message;
}

/// A validated `pool.dataset.update` payload.
///
/// Only properties the user actually changed are sent, because TrueNAS treats
/// every present key as an explicit local override.
class DatasetUpdateConfiguration {
  const DatasetUpdateConfiguration({
    required this.commentsMode,
    required this.comments,
    required this.quotaMode,
    required this.quotaBytes,
    required this.refquotaMode,
    required this.refquotaBytes,
    required this.readOnlyMode,
    required this.readOnly,
    required this.compressionMode,
    required this.compression,
    required this.syncMode,
    required this.sync,
  });

  factory DatasetUpdateConfiguration.fromDataset(Dataset dataset) {
    DatasetPropertyMode modeFor(String property) => dataset.inherits(property)
        ? DatasetPropertyMode.inherit
        : DatasetPropertyMode.explicit;

    return DatasetUpdateConfiguration(
      commentsMode: modeFor('comments'),
      comments: dataset.comments ?? '',
      quotaMode: modeFor('quota'),
      quotaBytes: dataset.quotaBytes == 0 ? null : dataset.quotaBytes,
      refquotaMode: modeFor('refquota'),
      refquotaBytes: dataset.refquotaBytes == 0 ? null : dataset.refquotaBytes,
      readOnlyMode: modeFor('readonly'),
      readOnly: dataset.readOnly,
      compressionMode: modeFor('compression'),
      compression:
          DatasetCompressionApi.parse(dataset.compression) ??
          DatasetCompression.lz4,
      syncMode: modeFor('sync'),
      sync: DatasetSyncApi.parse(dataset.sync) ?? DatasetSync.standard,
    );
  }

  final DatasetPropertyMode commentsMode;
  final String comments;
  final DatasetPropertyMode quotaMode;
  final int? quotaBytes;
  final DatasetPropertyMode refquotaMode;
  final int? refquotaBytes;
  final DatasetPropertyMode readOnlyMode;
  final bool readOnly;
  final DatasetPropertyMode compressionMode;
  final DatasetCompression compression;
  final DatasetPropertyMode syncMode;
  final DatasetSync sync;

  DatasetUpdateConfiguration copyWith({
    DatasetPropertyMode? commentsMode,
    String? comments,
    DatasetPropertyMode? quotaMode,
    int? quotaBytes,
    bool clearQuota = false,
    DatasetPropertyMode? refquotaMode,
    int? refquotaBytes,
    bool clearRefquota = false,
    DatasetPropertyMode? readOnlyMode,
    bool? readOnly,
    DatasetPropertyMode? compressionMode,
    DatasetCompression? compression,
    DatasetPropertyMode? syncMode,
    DatasetSync? sync,
  }) {
    return DatasetUpdateConfiguration(
      commentsMode: commentsMode ?? this.commentsMode,
      comments: comments ?? this.comments,
      quotaMode: quotaMode ?? this.quotaMode,
      quotaBytes: clearQuota ? null : quotaBytes ?? this.quotaBytes,
      refquotaMode: refquotaMode ?? this.refquotaMode,
      refquotaBytes: clearRefquota ? null : refquotaBytes ?? this.refquotaBytes,
      readOnlyMode: readOnlyMode ?? this.readOnlyMode,
      readOnly: readOnly ?? this.readOnly,
      compressionMode: compressionMode ?? this.compressionMode,
      compression: compression ?? this.compression,
      syncMode: syncMode ?? this.syncMode,
      sync: sync ?? this.sync,
    );
  }

  /// Builds the payload, omitting anything unchanged from [original].
  ///
  /// Throws [DatasetConfigurationException] when the request would be a no-op
  /// so the UI never sends an empty update the server would reject.
  Map<String, Object?> toApiJson(Dataset original) {
    final baseline = DatasetUpdateConfiguration.fromDataset(original);
    final payload = <String, Object?>{};

    void apply(
      String key,
      DatasetPropertyMode mode,
      DatasetPropertyMode baseMode,
      Object? value,
      Object? baseValue,
    ) {
      if (mode == DatasetPropertyMode.inherit) {
        // TrueNAS clears a local override when the property is sent as
        // INHERIT; sending it again when already inherited is a no-op.
        if (baseMode != DatasetPropertyMode.inherit) payload[key] = 'INHERIT';
        return;
      }
      if (baseMode != mode || value != baseValue) payload[key] = value;
    }

    apply(
      'comments',
      commentsMode,
      baseline.commentsMode,
      comments.trim(),
      baseline.comments.trim(),
    );
    apply(
      'quota',
      quotaMode,
      baseline.quotaMode,
      quotaBytes ?? 0,
      baseline.quotaBytes ?? 0,
    );
    apply(
      'refquota',
      refquotaMode,
      baseline.refquotaMode,
      refquotaBytes ?? 0,
      baseline.refquotaBytes ?? 0,
    );
    apply(
      'readonly',
      readOnlyMode,
      baseline.readOnlyMode,
      readOnly ? 'ON' : 'OFF',
      baseline.readOnly ? 'ON' : 'OFF',
    );
    apply(
      'compression',
      compressionMode,
      baseline.compressionMode,
      compression.apiValue,
      baseline.compression.apiValue,
    );
    apply(
      'sync',
      syncMode,
      baseline.syncMode,
      sync.apiValue,
      baseline.sync.apiValue,
    );

    if (payload.isEmpty) {
      throw const DatasetConfigurationException(
        'Nothing has changed for this dataset.',
        code: DatasetConfigurationCode.editNothingChanged,
      );
    }
    return payload;
  }

  /// Human-readable summary of what will change, used by the review step.
  List<DatasetChange> describeChanges(Dataset original) {
    final payload = toApiJson(original);
    return [
      for (final entry in payload.entries)
        switch (entry.key) {
          'comments' =>
            entry.value == 'INHERIT'
                ? const DatasetChange(DatasetChangeCode.commentsInherited)
                : (entry.value as String).isEmpty
                ? const DatasetChange(DatasetChangeCode.commentsCleared)
                : DatasetChange(
                    DatasetChangeCode.commentsSet,
                    value: '${entry.value}',
                  ),
          'quota' => _describeQuota(
            entry.value,
            inherited: DatasetChangeCode.quotaInherited,
            removed: DatasetChangeCode.quotaRemoved,
            set: DatasetChangeCode.quotaSet,
          ),
          'refquota' => _describeQuota(
            entry.value,
            inherited: DatasetChangeCode.refquotaInherited,
            removed: DatasetChangeCode.refquotaRemoved,
            set: DatasetChangeCode.refquotaSet,
          ),
          'readonly' =>
            entry.value == 'INHERIT'
                ? const DatasetChange(DatasetChangeCode.readOnlyInherited)
                : entry.value == 'ON'
                ? const DatasetChange(DatasetChangeCode.readOnlyEnabled)
                : const DatasetChange(DatasetChangeCode.readOnlyDisabled),
          'compression' =>
            entry.value == 'INHERIT'
                ? const DatasetChange(DatasetChangeCode.compressionInherited)
                : DatasetChange(
                    DatasetChangeCode.compressionSet,
                    value: '${entry.value}',
                  ),
          'sync' =>
            entry.value == 'INHERIT'
                ? const DatasetChange(DatasetChangeCode.syncInherited)
                : DatasetChange(
                    DatasetChangeCode.syncSet,
                    value: '${entry.value}',
                  ),
          final other => DatasetChange(
            DatasetChangeCode.propertyUpdated,
            value: other,
          ),
        },
    ];
  }

  static DatasetChange _describeQuota(
    Object? value, {
    required DatasetChangeCode inherited,
    required DatasetChangeCode removed,
    required DatasetChangeCode set,
  }) {
    if (value == 'INHERIT') return DatasetChange(inherited);
    if (value == 0) return DatasetChange(removed);
    return DatasetChange(set, value: formatBytes(value as int));
  }
}

/// A validated `pool.dataset.rename` request.
class DatasetRenameRequest {
  const DatasetRenameRequest({required this.newName, required this.recursive});

  /// Validates a new leaf name against the dataset's existing parent path.
  factory DatasetRenameRequest.forDataset(
    Dataset dataset, {
    required String newLeafName,
    required bool recursive,
  }) {
    final leaf = newLeafName.trim();
    if (leaf.isEmpty) {
      throw const DatasetConfigurationException(
        'Enter a new dataset name.',
        code: DatasetConfigurationCode.renameEmpty,
      );
    }
    if (leaf.contains('/')) {
      throw const DatasetConfigurationException(
        'A dataset name cannot contain "/".',
        code: DatasetConfigurationCode.renameContainsSlash,
      );
    }
    if (dataset.isPoolRoot) {
      throw const DatasetConfigurationException(
        'A pool root dataset cannot be renamed.',
        code: DatasetConfigurationCode.renamePoolRoot,
      );
    }
    if (leaf == dataset.leafName) {
      throw const DatasetConfigurationException(
        'Enter a name different from the current one.',
        code: DatasetConfigurationCode.renameUnchanged,
      );
    }
    final segments = dataset.name.split('/')..removeLast();
    return DatasetRenameRequest(
      newName: [...segments, leaf].join('/'),
      recursive: recursive,
    );
  }

  final String newName;
  final bool recursive;

  Map<String, Object?> toApiJson() => {
    'new_name': newName,
    'recursive': recursive,
  };
}
