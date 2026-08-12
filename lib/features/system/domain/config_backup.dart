import 'package:meta/meta.dart';

/// What a configuration backup includes beyond the database itself.
///
/// Each option adds material that makes the archive far more sensitive: the
/// secret seed decrypts stored credentials, and the pool keys unlock encrypted
/// datasets. A backup carrying either is equivalent to the server's secrets, so
/// the UI has to say so rather than presenting three neutral checkboxes.
@immutable
class ConfigBackupOptions {
  const ConfigBackupOptions({
    this.secretSeed = false,
    this.poolKeys = false,
    this.rootAuthorizedKeys = false,
  });

  /// Includes the seed used to encrypt stored credentials. Without it, a
  /// restored configuration cannot decrypt saved passwords and API keys.
  final bool secretSeed;

  /// Includes ZFS encryption keys for the pools, which unlock the data itself.
  final bool poolKeys;

  /// Includes root's SSH `authorized_keys`.
  final bool rootAuthorizedKeys;

  Map<String, Object?> toApiJson() => <String, Object?>{
    'secretseed': secretSeed,
    'pool_keys': poolKeys,
    'root_authorized_keys': rootAuthorizedKeys,
  };

  /// True when the archive would carry material that unlocks data or
  /// credentials, so the confirmation can name that consequence.
  bool get carriesSecrets => secretSeed || poolKeys || rootAuthorizedKeys;

  /// A suggested filename. The server only uses it for `Content-Disposition`,
  /// but a dated name is what makes a folder of backups usable later.
  ///
  /// The extension follows what the server actually sends, verified live: a
  /// plain backup is the SQLite settings database itself, and only the
  /// secret-seed or pool-key options make it bundle several files into a tar.
  /// Naming a bare database `.tar` would leave the file unopenable by the tool
  /// its own name suggests.
  String suggestedFilename(String hostname, DateTime now) {
    final stamp =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '-${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';
    final safeHost = hostname.trim().isEmpty
        ? 'truenas'
        : hostname.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-');
    return '$safeHost-config-$stamp.${carriesSecrets ? 'tar' : 'db'}';
  }

  ConfigBackupOptions copyWith({
    bool? secretSeed,
    bool? poolKeys,
    bool? rootAuthorizedKeys,
  }) => ConfigBackupOptions(
    secretSeed: secretSeed ?? this.secretSeed,
    poolKeys: poolKeys ?? this.poolKeys,
    rootAuthorizedKeys: rootAuthorizedKeys ?? this.rootAuthorizedKeys,
  );
}

/// A prepared configuration download.
///
/// `config.save` writes to a job pipe, which a JSON-RPC client cannot read, so
/// it cannot be called directly — the server answers `Pipe 'output' is not
/// open`. `core.download` wraps such a method and returns a job id plus a
/// relative HTTPS path carrying a single-use token, which is the only way to
/// reach the archive from a client like TrueDock.
@immutable
class ConfigBackupDownload {
  const ConfigBackupDownload({
    required this.jobId,
    required this.path,
    required this.filename,
  });

  /// Parses the `[jobId, path]` pair `core.download` returns.
  factory ConfigBackupDownload.fromApi(
    Object? response, {
    required String filename,
  }) {
    if (response is! List || response.length < 2) {
      throw const FormatException(
        'core.download returned an unexpected shape.',
      );
    }
    final jobId = response[0];
    final path = response[1];
    if (jobId is! int || path is! String || path.isEmpty) {
      throw const FormatException(
        'core.download returned an unexpected shape.',
      );
    }
    return ConfigBackupDownload(jobId: jobId, path: path, filename: filename);
  }

  final int jobId;

  /// Server-relative path including the auth token, for example
  /// `/_download/1079?auth_token=...`.
  final String path;
  final String filename;

  /// Absolute URL against the connected server.
  ///
  /// Resolved rather than concatenated so a server reached on a non-default port
  /// or a path prefix still produces a valid URL.
  Uri resolve(Uri baseUri) => baseUri.resolve(path);

  /// True when the path carries a token, which it always should: the download
  /// is unauthenticated otherwise and would fail.
  bool get isTokenized => path.contains('auth_token=');
}
